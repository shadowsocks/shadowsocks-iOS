#!/bin/bash

cd AppProxyCap/
git submodule init
git submodule update
cd ..
cd OpenSSL-for-iPhone/ && \
./build-libssl.sh && \
cd .. && \
./xcodebuild
