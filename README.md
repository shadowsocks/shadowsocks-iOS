Shadowsocks for iOS
=========
[![Build Status](https://travis-ci.org/shadowsocks/shadowsocks-iOS.png?branch=master)](https://travis-ci.org/shadowsocks/shadowsocks-iOS)

Shadowsocks is a cross-platform tunnel proxy which can help you get through firewalls.

This iOS version is for **non-jailbroken devices**. It has two features.

1. As a web browser
2. As a global PAC proxy, with some limitations

See [Help](https://github.com/shadowsocks/shadowsocks-iOS/wiki/Help) for more information.

Usage
-----
A complete guide is in the [Help](https://github.com/shadowsocks/shadowsocks-iOS/wiki/Help).

Build (For developers)
----------------------

First, you have to update submodules:

    git submodule update --recursive --init
    open shadowsocks.xcodeproj

Then build with XCode.

Please check [Help](https://github.com/shadowsocks/shadowsocks-iOS/wiki/Help), if you haven't.

License
-------
The project is under the terms of [GPLv3](http://opensource.org/licenses/GPL-3.0),
except for the following parts:

- proxy.pac is generated from [cow](https://github.com/cyfdecyf/cow).
- [iProxy](https://github.com/tcurdt/iProxy)
- [GCDWebServer](https://github.com/swisspol/GCDWebServer)
- [AppProxyCap](https://github.com/freewizard/AppProxyCap)
