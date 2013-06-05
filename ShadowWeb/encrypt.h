#pragma once

#import <stdint.h>
#import <openssl/evp.h>

typedef enum {
    EncryptionTable = 0,
    EncryptionRC4 = 1,
    EncryptionAES256CFB,
    EncryptionAES192CFB,
    EncryptionAES128CFB,
    EncryptionBFCFB
} EncryptionMethod;

struct encryption_ctx {
    EVP_CIPHER_CTX* ctx;
    EncryptionMethod method;
    const char* password;
    uint8_t status;
};

#define STATUS_EMPTY 0
#define STATUS_INIT 1
#define STATUS_DESTORYED 2

#define TOTAL_METHODS 6

void encrypt_buf(struct encryption_ctx* ctx, char *buf, int *len);
void decrypt_buf(struct encryption_ctx* ctx, char *buf, int *len);

int send_encrypt(struct encryption_ctx* ctx, int sock, char *buf, int *len, int flags);
int recv_decrypt(struct encryption_ctx* ctx, int sock, char *buf, int *len, int flags);

void init_encryption(struct encryption_ctx* ctx, const char *password, const char *method);
