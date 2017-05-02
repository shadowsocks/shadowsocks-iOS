#!/bin/sh

#  install_helper.sh
#  shadowsocks
#
#  Created by clowwindy on 14-3-15.

cd `dirname "${BASH_SOURCE[0]}"`
sudo mkdir -p "/Library/Application Support/ShadowsocksX/"
sudo cp shadowsocks_sysconf "/Library/Application Support/ShadowsocksX/"
sudo chown root:admin "/Library/Application Support/ShadowsocksX/shadowsocks_sysconf"
sudo chmod +s "/Library/Application Support/ShadowsocksX/shadowsocks_sysconf"

echo done