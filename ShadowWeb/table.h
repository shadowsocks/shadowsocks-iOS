#pragma once


unsigned char encrypt_table[256];
unsigned char decrypt_table[256];
__deprecated void get_table(const char* key);
void table_encrypt(char *buf, int len);
void table_decrypt(char *buf, int len);

unsigned int _i;
unsigned long long _a;
