shadowsocks-iOS
===========

Current version: 0.2

[shadowsocks](https://github.com/clowwindy/shadowsocks) is a lightweight tunnel proxy which can help you get through
 firewalls. This is an iPhone/iPad client.

Since iOS don't support background daemons(without jailbreaking), this client integrated a web browser(iOS-OnionBrowser).
In other words, you can't let other apps go through this proxy.

If you've jailbroken your iPhone, you can use [Python](https://github.com/clowwindy/shadowsocks) /
[Go](https://github.com/shadowsocks/shadowsocks-go) version of shadowsocks directly on your iPhone.

install
-----------

First, clone the code:

    git clone --recurse-submodules git://github.com/shadowsocks/shadowsocks-iOS.git

Then you can build and install this App using XCode 4.5 or later.

known issues
-------------

* Can not play Youtube video. Seems like proxy settings are ignored by video streams. 
If you know any solutions, please file a issue.
