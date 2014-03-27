#!/bin/bash

if [ $# -ne 1 ]
then
  echo 'build_dmg.sh version'
  exit 1
fi

dmgbuild -s settings.py 'Shadowsocks' Shadowsocks-$1.dmg

