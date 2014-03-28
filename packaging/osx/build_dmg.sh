#!/bin/bash

if [ $# -ne 1 ]
then
  echo 'build_dmg.sh version'
  exit 1
fi

dmgbuild -s settings.py 'Shadowsocks' ShadowsocksX-$1.dmg
rsync --progress -e ssh ShadowsocksX-$1.dmg frs.sourceforge.net:/home/frs/project/shadowsocksgui/dist/

