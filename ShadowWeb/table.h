#pragma once


unsigned char encrypt_table[256];
unsigned char decrypt_table[256];
void get_table(const unsigned char* key);
void table_encrypt(unsigned char *buf, size_t len);
void table_decrypt(unsigned char *buf, size_t len);

unsigned int _i;
unsigned long long _a;
