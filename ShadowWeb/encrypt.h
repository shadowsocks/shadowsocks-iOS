#pragma once

#import <stdint.h>
#import <openssl/evp.h>

struct encryption_ctx {
    EVP_CIPHER_CTX* ctx;
    uint8_t status;
};

#define STATUS_EMPTY 0
#define STATUS_INIT 1
#define STATUS_DESTORYED 2

#define TOTAL_METHODS 14

void encrypt_buf(struct encryption_ctx* ctx, char *buf, int *len);
void decrypt_buf(struct encryption_ctx* ctx, char *buf, int *len);

int send_encrypt(struct encryption_ctx* ctx, int sock, char *buf, int *len, int flags);
int recv_decrypt(struct encryption_ctx* ctx, int sock, char *buf, int *len, int flags);

void init_encryption(struct encryption_ctx* ctx);
void cleanup_encryption(struct encryption_ctx* ctx);

void config_encryption(const char *password, const char *method);
