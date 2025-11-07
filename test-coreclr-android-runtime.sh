#!/usr/bin/env bash

. ./test-naot-android-common.sh

./build.sh -arch x64 -os android  -s clr.runtime+clr.alljits+clr.corelib+clr.nativecorelib+clr.tools+clr.packages+libs+host+packs -c Release /p:RunSmokeTestsOnly=true
# note: CI also includes libs.tests

./src/tests/build.sh os android x64 Release /p:LibrariesConfiguration=Release "$@"
