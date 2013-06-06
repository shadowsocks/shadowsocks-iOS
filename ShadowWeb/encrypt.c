#include <sys/socket.h>
#include <openssl/rand.h>
#include <strings.h>
#include "table.h"
#include "encrypt.h"

int encryption_iv_len[] = {
        0,
        0,
        16,
        16,
        16,
        8
};

static const char *encryption_names[] = {
        "table",
        "rc4",
        "aes-256-cfb",
        "aes-192-cfb",
        "aes-128-cfb",
        "bf-cfb"
};

void init_cipher(struct encryption_ctx *ctx, const unsigned char *iv, int iv_len, int is_cipher);

EncryptionMethod encryption_method_from_string(const char *name) {
    // TODO use an O(1) way
    for (int i = 0; i < TOTAL_METHODS; i++) {
        if (strcasecmp(name, encryption_names[i]) == 0) {
            return (EncryptionMethod) i;
        }
    }
    return EncryptionTable;
}

void encrypt_buf(struct encryption_ctx *ctx, char *buf, int *len) {
    if (ctx->method == EncryptionTable) {
        table_encrypt(buf, *len);
    } else {
        if (ctx->status == STATUS_EMPTY) {
            int iv_len = encryption_iv_len[ctx->method];
            unsigned char iv[EVP_MAX_IV_LENGTH];
            memset(iv, 0, iv_len);
            RAND_bytes(iv, iv_len);
            init_cipher(ctx, iv, iv_len, 1);
            int out_len = *len + EVP_CIPHER_CTX_block_size(ctx->ctx);
            unsigned char *cipher_text = malloc(out_len);
            EVP_CipherUpdate(ctx->ctx, cipher_text, &out_len, buf, *len);
            memcpy(buf, iv, iv_len);
            memcpy(buf + iv_len, cipher_text, out_len);
            *len = iv_len + out_len;
            free(cipher_text);
        } else {
            int out_len = *len + EVP_CIPHER_CTX_block_size(ctx->ctx);
            unsigned char *cipher_text = malloc(out_len);
            EVP_CipherUpdate(ctx->ctx, cipher_text, &out_len, buf, *len);
            memcpy(buf, cipher_text, out_len);
            *len = out_len;
            free(cipher_text);
        }
    }
}

void decrypt_buf(struct encryption_ctx *ctx, char *buf, int *len) {
    if (ctx->method == EncryptionTable) {
        table_decrypt(buf, *len);
    } else {
        if (ctx->status == STATUS_EMPTY) {
            int iv_len = encryption_iv_len[ctx->method];
            init_cipher(ctx, buf, iv_len, 0);
            int out_len = *len + EVP_CIPHER_CTX_block_size(ctx->ctx);
            out_len -= iv_len;
            unsigned char *cipher_text = malloc(out_len);
            EVP_CipherUpdate(ctx->ctx, cipher_text, &out_len, buf + iv_len, *len - iv_len);
            memcpy(buf, cipher_text, out_len);
            *len = out_len;
            free(cipher_text);
        } else {
            int out_len = *len + EVP_CIPHER_CTX_block_size(ctx->ctx);
            unsigned char *cipher_text = malloc(out_len);
            EVP_CipherUpdate(ctx->ctx, cipher_text, &out_len, buf, *len);
            memcpy(buf, cipher_text, out_len);
            *len = out_len;
            free(cipher_text);
        }
    }
}

int send_encrypt(struct encryption_ctx *ctx, int sock, char *buf, int *len, int flags) {
    char mybuf[4096];
    memcpy(mybuf, buf, *len);
    encrypt_buf(ctx, mybuf, len);
    return send(sock, mybuf, *len, flags);
}

int recv_decrypt(struct encryption_ctx *ctx, int sock, char *buf, int *len, int flags) {
    char mybuf[4096];
    int result = recv(sock, mybuf, *len, flags);
    memcpy(buf, mybuf, *len);
    decrypt_buf(ctx, buf, len);
    return result;
}

void init_cipher(struct encryption_ctx *ctx, const unsigned char *iv, int iv_len, int is_cipher) {
    ctx->status = STATUS_INIT;
    if (ctx->method != EncryptionTable) {
//        assert(ctx->status == STATUS_EMPTY);
        const char* name = encryption_names[ctx->method];
        const EVP_CIPHER *cipher = EVP_get_cipherbyname(name);
        if (cipher == NULL) {
//            assert(0);
            // TODO
        }
        unsigned char key[EVP_MAX_KEY_LENGTH];
        unsigned char tmp[EVP_MAX_IV_LENGTH];
        int key_len = EVP_BytesToKey(cipher, EVP_md5(), NULL, ctx->password,
                strlen(ctx->password), 1, key, tmp);
        EVP_CIPHER_CTX_init(ctx->ctx);
        EVP_CipherInit_ex(ctx->ctx, cipher, NULL, NULL, NULL, is_cipher);
        if (!EVP_CIPHER_CTX_set_key_length(ctx->ctx, key_len)) {
            cleanup_encryption(ctx);
//            NSLog(@"Invalid key length");
//            assert(0);
            // TODO free memory and report error
            return;
        }
        EVP_CIPHER_CTX_set_padding(ctx->ctx, 1);

        EVP_CipherInit_ex(ctx->ctx, NULL, NULL, key, iv, is_cipher);

    }
}

void init_encryption(struct encryption_ctx *ctx, const char *password, const char *method) {
    SSLeay_add_all_algorithms();
    ctx->status = STATUS_EMPTY;
    ctx->password = password;
    ctx->method = encryption_method_from_string(method);
    ctx->ctx = EVP_CIPHER_CTX_new();
}

void cleanup_encryption(struct encryption_ctx* ctx) {
    if (ctx->status == STATUS_INIT) {
        EVP_CIPHER_CTX_cleanup(ctx->ctx);
        ctx->status = STATUS_DESTORYED;
    }
}
