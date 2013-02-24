#pragma once

#define SOCKS_VERSION 0x05
#define SOCKS_CMD_CONNECT 0x01
#define SOCKS_IPV4 0x01
#define SOCKS_DOMAIN 0x03
#define SOCKS_IPV6 0x04
#define SOCKS_CMD_NOT_SUPPORTED 0x07

#pragma pack(1)

struct method_select_request
{
	char ver;
	char nmethods;
	char methods[255];
};

struct method_select_response
{
	char ver;
	char method;
};

struct socks5_request
{
	char ver;
	char cmd;
	char rsv;
	char atyp;
};

struct socks5_response
{
	char ver;
	char rep;
	char rsv;
	char atyp;
};

#pragma pack()

