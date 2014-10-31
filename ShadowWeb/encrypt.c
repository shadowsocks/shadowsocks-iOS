#include <sys/socket.h>
#include <openssl/rand.h>
#include <strings.h>
#include "table.h"
#include "encrypt.h"

size_t encryption_iv_len[] = {
        0,
        16,
        16,
        16,
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
        "aes-256-cfb",
        "aes-192-cfb",
        "aes-128-cfb",
        "bf-cfb",
        "camellia-128-cfb",
        "camellia-192-cfb",
        "camellia-256-cfb",
        "cast5-cfb",
        "des-cfb",
        "idea-cfb",
        "rc2-cfb",
        "rc4",
        "seed-cfb"
};

#define ENCRYPTION_TABLE 0

static int _method;
static int _key_len;
static const EVP_CIPHER *_cipher;
static char _key[EVP_MAX_KEY_LENGTH];
char *shadowsocks_key;

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

void encrypt_buf(struct encryption_ctx *ctx, unsigned char *buf, size_t *len) {
    if (_method == ENCRYPTION_TABLE) {
        table_encrypt(buf, *len);
    } else {
        if (ctx->status == STATUS_EMPTY) {
            size_t iv_len = encryption_iv_len[_method];
            unsigned char iv[EVP_MAX_IV_LENGTH];
            memset(iv, 0, iv_len);
            RAND_bytes(iv, iv_len);
            init_cipher(ctx, iv, iv_len, 1);
            size_t out_len = *len + EVP_CIPHER_CTX_block_size(ctx->ctx);
            unsigned char *cipher_text = malloc(out_len);
            EVP_CipherUpdate(ctx->ctx, cipher_text, (int *)&out_len, buf, *len);
            memcpy(buf, iv, iv_len);
            memcpy(buf + iv_len, cipher_text, out_len);
            *len = iv_len + out_len;
            free(cipher_text);
        } else {
            size_t out_len = *len + EVP_CIPHER_CTX_block_size(ctx->ctx);
            unsigned char *cipher_text = malloc(out_len);
            EVP_CipherUpdate(ctx->ctx, cipher_text, (int *)&out_len, buf, *len);
            memcpy(buf, cipher_text, out_len);
            *len = out_len;
            free(cipher_text);
        }
    }
}

void decrypt_buf(struct encryption_ctx *ctx, unsigned char *buf, size_t *len) {
    if (_method == ENCRYPTION_TABLE) {
        table_decrypt(buf, *len);
    } else {
        if (ctx->status == STATUS_EMPTY) {
            size_t iv_len = encryption_iv_len[_method];
            init_cipher(ctx, buf, iv_len, 0);
            size_t out_len = *len + EVP_CIPHER_CTX_block_size(ctx->ctx);
            out_len -= iv_len;
            unsigned char *cipher_text = malloc(out_len);
            EVP_CipherUpdate(ctx->ctx, cipher_text, (int *)&out_len, buf + iv_len, *len - iv_len);
            memcpy(buf, cipher_text, out_len);
            *len = out_len;
            free(cipher_text);
        } else {
            size_t out_len = *len + EVP_CIPHER_CTX_block_size(ctx->ctx);
            unsigned char *cipher_text = malloc(out_len);
            EVP_CipherUpdate(ctx->ctx, cipher_text, (int *)&out_len, buf, *len);
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
    if (_method != ENCRYPTION_TABLE) {
        EVP_CIPHER_CTX_init(ctx->ctx);
        EVP_CipherInit_ex(ctx->ctx, _cipher, NULL, NULL, NULL, is_cipher);
        if (!EVP_CIPHER_CTX_set_key_length(ctx->ctx, _key_len)) {
            cleanup_encryption(ctx);
//            NSLog(@"Invalid key length");
//            assert(0);
            // TODO free memory and report error
            return;
        }
        EVP_CIPHER_CTX_set_padding(ctx->ctx, 1);

        EVP_CipherInit_ex(ctx->ctx, NULL, NULL, (unsigned char *)_key, iv, is_cipher);

    }
}

void init_encryption(struct encryption_ctx *ctx) {
    ctx->status = STATUS_EMPTY;
    ctx->ctx = EVP_CIPHER_CTX_new();
}

void cleanup_encryption(struct encryption_ctx *ctx) {
    if (ctx->status == STATUS_INIT) {
        EVP_CIPHER_CTX_cleanup(ctx->ctx);
        ctx->status = STATUS_DESTORYED;
    }
}

void config_encryption(const char *password, const char *method) {
    SSLeay_add_all_algorithms();
    _method = encryption_method_from_string(method);
    if (_method != ENCRYPTION_TABLE) {
        const char *name = shadowsocks_encryption_names[_method];
        _cipher = EVP_get_cipherbyname(name);
        if (_cipher == NULL) {
//            assert(0);
            // TODO
            printf("_cipher is nil! \r\nThe %s doesn't supported!\r\n please chose anthor!",name);
        } else {
            unsigned char tmp[EVP_MAX_IV_LENGTH];
            _key_len = EVP_BytesToKey(_cipher, EVP_md5(), NULL, (unsigned char *)password,
                                      strlen(password), 1, (unsigned char *)_key, tmp);
            shadowsocks_key = _key;
        }

//        printf("%d\n", _key_len);
    } else {
        get_table((unsigned char *)password);
    }
}
