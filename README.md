Shadowsocks for iOS
=========
A better browser than Shadowsocks-iOS
[![Build Status](https://travis-ci.org/clowwindy/ShadowWeb.png?branch=master)](https://travis-ci.org/clowwindy/ShadowWeb)

Not stable yet. Use with caution.

How to Build
-------------

First, you have to update submodules:

    git submodule update --recursive --init
    open ShadowWeb.xcodeproj

Then build with XCode.

License
-------
The project is under the terms of [GPLv3](http://opensource.org/licenses/GPL-3.0),
except for the following parts:

- proxy.pac is generated from [cow](https://github.com/cyfdecyf/cow).
- [iProxy](https://github.com/tcurdt/iProxy)
- [GCDWebServer](https://github.com/swisspol/GCDWebServer)
- [AppProxyCap](https://github.com/freewizard/AppProxyCap)
