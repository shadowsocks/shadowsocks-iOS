#include <sys/socket.h>
#include <openssl/rand.h>
#include <strings.h>
#include <openssl/md5.h>
#include <sodium.h>
#include "local.h"
#include "table.h"
#include "encrypt.h"

#define CIPHER_TABLE 0
#define CIPHER_OPENSSL 1
#define CIPHER_SODIUM 2
static uint8_t cipher;

#define SODIUM_BLOCK_SIZE 64

static unsigned char sodium_buf[BUF_SIZE + SODIUM_BLOCK_SIZE + 16];

size_t encryption_iv_len[] = {
        0,
        16,
        8,
        8,
        16,
        16,
        16,
        8,
        8,
        8,
        8,
        0,
        16
};

const char *shadowsocks_encryption_names[] = {
        "table",
        "rc4-md5",
        "salsa20",
        "chacha20",
        "aes-256-cfb",
        "aes-192-cfb",
        "aes-128-cfb",
        "bf-cfb",
        "cast5-cfb",
        "des-cfb",
        "rc2-cfb",
        "rc4",
        "seed-cfb"
};

#define ENCRYPTION_TABLE 0
#define ENCRYPTION_RC4_MD5 1
#define ENCRYPTION_SALSA20 2
#define ENCRYPTION_CHACHA20 3

static int _method;
static int _key_len;
static const EVP_CIPHER *_cipher;
static unsigned char _key[EVP_MAX_KEY_LENGTH];
unsigned char *shadowsocks_key;

void init_cipher(struct encryption_ctx *ctx, const unsigned char *iv, size_t iv_len, int is_cipher);

int encryption_method_from_string(const char *name) {
    // TODO use an O(1) way
    for (int i = 0; i < kShadowsocksMethods; i++) {
        if (strcasecmp(name, shadowsocks_encryption_names[i]) == 0) {
            return i;
        }
    }
    return 0;
}

void cipher_update(struct encryption_ctx *ctx, unsigned char *out, size_t *outlen, unsigned char *in, size_t inlen) {
    if (ctx->cipher == CIPHER_OPENSSL) {
        EVP_CipherUpdate(ctx->ctx, out, (int *) outlen, in, inlen);
    } else if (ctx->cipher == CIPHER_SODIUM) {
        size_t padding = ctx->bytes_remaining;
        memcpy(sodium_buf + padding, in, inlen);
        if (_method == ENCRYPTION_SALSA20) {
            crypto_stream_salsa20_xor_ic(sodium_buf, sodium_buf, padding + inlen, ctx->iv, ctx->ic, _key);
        } else if (_method == ENCRYPTION_CHACHA20) {
            crypto_stream_chacha20_xor_ic(sodium_buf, sodium_buf, padding + inlen, ctx->iv, ctx->ic, _key);
        }
        *outlen = inlen;
        memcpy(out, sodium_buf + padding, inlen);
        padding += inlen;
        ctx->ic += padding / SODIUM_BLOCK_SIZE;
        ctx->bytes_remaining = padding % SODIUM_BLOCK_SIZE;
    }
}

void encrypt_buf(struct encryption_ctx *ctx, unsigned char *buf, size_t *len) {
    if (ctx->cipher == CIPHER_TABLE) {
        table_encrypt(buf, *len);
    } else {
        if (ctx->status == STATUS_EMPTY) {
            size_t iv_len = encryption_iv_len[_method];
            memset(ctx->iv, 0, iv_len);
            RAND_bytes(ctx->iv, iv_len);
            init_cipher(ctx, ctx->iv, iv_len, 1);
            size_t out_len = *len + ctx->iv_len;
            unsigned char *cipher_text = malloc(out_len);
            cipher_update(ctx, cipher_text, &out_len, buf, *len);
            memcpy(buf, ctx->iv, iv_len);
            memcpy(buf + iv_len, cipher_text, out_len);
            *len = iv_len + out_len;
            free(cipher_text);
        } else {
            size_t out_len = *len + ctx->iv_len;
            unsigned char *cipher_text = malloc(out_len);
            cipher_update(ctx, cipher_text, &out_len, buf, *len);
            memcpy(buf, cipher_text, out_len);
            *len = out_len;
            free(cipher_text);
        }
    }
}

void decrypt_buf(struct encryption_ctx *ctx, unsigned char *buf, size_t *len) {
    if (ctx->cipher == CIPHER_TABLE) {
        table_decrypt(buf, *len);
    } else {
        if (ctx->status == STATUS_EMPTY) {
            size_t iv_len = encryption_iv_len[_method];
            memcpy(ctx->iv, buf, iv_len);
            init_cipher(ctx, ctx->iv, iv_len, 0);
            size_t out_len = *len + ctx->iv_len;
            out_len -= iv_len;
            unsigned char *cipher_text = malloc(out_len);
            cipher_update(ctx, cipher_text, &out_len, buf + iv_len, *len - iv_len);
            memcpy(buf, cipher_text, out_len);
            *len = out_len;
            free(cipher_text);
        } else {
            size_t out_len = *len + ctx->iv_len;
            unsigned char *cipher_text = malloc(out_len);
            cipher_update(ctx, cipher_text, &out_len, buf, *len);
            memcpy(buf, cipher_text, out_len);
            *len = out_len;
            free(cipher_text);
        }
    }
}

int send_encrypt(struct encryption_ctx *ctx, int sock, unsigned char *buf, size_t *len, int flags) {
    unsigned char mybuf[4096];
    memcpy(mybuf, buf, *len);
    encrypt_buf(ctx, mybuf, len);
    return send(sock, mybuf, *len, flags);
}

int recv_decrypt(struct encryption_ctx *ctx, int sock, unsigned char *buf, size_t *len, int flags) {
    char mybuf[4096];
    int result = recv(sock, mybuf, *len, flags);
    memcpy(buf, mybuf, *len);
    decrypt_buf(ctx, buf, len);
    return result;
}

void init_cipher(struct encryption_ctx *ctx, const unsigned char *iv, size_t iv_len, int is_cipher) {
    ctx->status = STATUS_INIT;
    if (ctx->cipher == CIPHER_OPENSSL) {
        EVP_CIPHER_CTX_init(ctx->ctx);
        EVP_CipherInit_ex(ctx->ctx, _cipher, NULL, NULL, NULL, is_cipher);
        if (!EVP_CIPHER_CTX_set_key_length(ctx->ctx, _key_len)) {
            cleanup_encryption(ctx);
            return;
        }
        EVP_CIPHER_CTX_set_padding(ctx->ctx, 1);
        unsigned char *true_key;
        if (_method == ENCRYPTION_RC4_MD5) {
            unsigned char key_iv[32];
            memcpy(key_iv, _key, 16);
            memcpy(key_iv + 16, iv, 16);
            true_key = MD5(key_iv, 32, NULL);
        } else {
            true_key = _key;
        }
        EVP_CipherInit_ex(ctx->ctx, NULL, NULL, true_key, iv, is_cipher);
    } else if (ctx->cipher == CIPHER_SODIUM) {
        ctx->ic = 0;
        ctx->bytes_remaining = 0;
    }
    ctx->iv_len = encryption_iv_len[_method];
}

void init_encryption(struct encryption_ctx *ctx) {
    ctx->status = STATUS_EMPTY;
    ctx->ctx = EVP_CIPHER_CTX_new();
    ctx->cipher = cipher;
}

void cleanup_encryption(struct encryption_ctx *ctx) {
    if (ctx->status == STATUS_INIT) {
        if (ctx->cipher == CIPHER_OPENSSL) {
            EVP_CIPHER_CTX_cleanup(ctx->ctx);
        }
        ctx->status = STATUS_DESTORYED;
    }
}

void config_encryption(const char *password, const char *method) {
    SSLeay_add_all_algorithms();
    sodium_init();
    _method = encryption_method_from_string(method);
    if (_method == ENCRYPTION_TABLE) {
        get_table((unsigned char *) password);
        cipher = CIPHER_TABLE;
    } else if (_method == ENCRYPTION_SALSA20 || _method == ENCRYPTION_CHACHA20) {
        cipher = CIPHER_SODIUM;
        _key_len = 32;
        unsigned char tmp[EVP_MAX_IV_LENGTH];;
        EVP_BytesToKey(EVP_aes_256_cfb(), EVP_md5(), NULL, (unsigned char *)password,
                                strlen(password), 1, _key, tmp);
        shadowsocks_key = _key;
    } else {
        cipher = CIPHER_OPENSSL;
        const char *name = shadowsocks_encryption_names[_method];
        if (_method == ENCRYPTION_RC4_MD5) {
            name = "RC4";
        }
        _cipher = EVP_get_cipherbyname(name);
        if (_cipher == NULL) {
//            assert(0);
            // TODO
            printf("_cipher is nil! \r\nThe %s doesn't supported!\r\n please chose anthor!",name);
        } else {
            unsigned char tmp[EVP_MAX_IV_LENGTH];
            _key_len = EVP_BytesToKey(_cipher, EVP_md5(), NULL, (unsigned char *)password,
                                      strlen(password), 1, _key, tmp);
            shadowsocks_key = _key;
        }

//        printf("%d\n", _key_len);
    }
}
