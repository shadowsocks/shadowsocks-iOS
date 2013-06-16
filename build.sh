#!/bin/bash

cd AppProxyCap/
git submodule init
git submodule update
cd ..
xcodebuild -sdk iphonesimulator
