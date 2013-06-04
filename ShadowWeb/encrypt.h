#pragma once


void encrypt(char *buf, int len);
void decrypt(char *buf, int len);
void init_encryption(const char* password, const char*method);

int send_encrypt(int sock, char *buf, int len, int flags);
int recv_decrypt(int sock, char *buf, int len, int flags);