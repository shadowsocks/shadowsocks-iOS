
#import <sys/socket.h>

#import "table.h"
#import "encrypt.h"

void encrypt(char *buf, int len) {
    table_encrypt(buf, len);
}

void decrypt(char *buf, int len) {
    table_decrypt(buf, len);
}

int send_encrypt(int sock, char *buf, int len, int flags) {
    char mybuf[4096];
    memcpy(mybuf, buf, len);
    encrypt(mybuf, len);
    return send(sock, mybuf, len, flags);
}

int recv_decrypt(int sock, char *buf, int len, int flags) {
    char mybuf[4096];
    int result = recv(sock, mybuf, len, flags);
    memcpy(buf, mybuf, len);
    decrypt(buf, len);
    return result;
}

void init_encryption(const char* password, const char*method) {
    
}