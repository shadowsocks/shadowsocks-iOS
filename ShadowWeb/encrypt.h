#pragma once

#import <stdint.h>
#import <openssl/evp.h>

struct encryption_ctx {
    EVP_CIPHER_CTX* ctx;
    uint8_t status;
    unsigned char iv[16];
    size_t iv_len;
    size_t bytes_remaining; // only for libsodium
    uint64_t ic; // only for libsodium
    uint8_t cipher;
};

#define STATUS_EMPTY 0
#define STATUS_INIT 1
#define STATUS_DESTORYED 2

#define kShadowsocksMethods 13

const char *shadowsocks_encryption_names[];

void encrypt_buf(struct encryption_ctx* ctx, unsigned char *buf, size_t *len);
void decrypt_buf(struct encryption_ctx* ctx, unsigned char *buf, size_t *len);

int send_encrypt(struct encryption_ctx* ctx, int sock, unsigned char *buf, size_t *len, int flags);
int recv_decrypt(struct encryption_ctx* ctx, int sock, unsigned char *buf, size_t *len, int flags);

void init_encryption(struct encryption_ctx* ctx);
void cleanup_encryption(struct encryption_ctx* ctx);

void config_encryption(const char *password, const char *method);

unsigned char *shadowsocks_key;
