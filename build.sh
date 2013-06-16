#!/bin/bash

cd OpenSSL-for-iPhone/ && \
./build-libssl.sh && \
cd .. && \
./xcodebuild
