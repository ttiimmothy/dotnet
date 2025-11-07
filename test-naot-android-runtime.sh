#!/usr/bin/env bash

. ./test-naot-android-common.sh


###
### Runtime tests
###
## What CI does...
# DONT RUN THIS (ci arg) build.sh -ci -arch x64 -os android  -s clr.aot+libs+libs.tests -c Release /p:ArchiveTests=true /p:UseNativeAOTRuntime=true /p:RuntimeFlavor=coreclr /p:TestNativeAOT=true
# ./build.sh -arch x64 -os android  -s clr.aot+libs+libs.tests -c Release /p:ArchiveTests=true /p:UseNativeAOTRuntime=true /p:RuntimeFlavor=coreclr /p:TestNativeAOT=true

# export BuildAllTestsAsStandalone=true
./src/tests/build.sh os android x64 Release nativeaot tree nativeaot/SmokeTests /p:BuildNativeAOTRuntimePack=true /p:LibrariesConfiguration=Release "$@"
#
# ./build.sh -arch x64 -os android -s clr.alljits+clr.tools+clr.nativeaotruntime+clr.nativeaotlibs+libs -c Release
# export BuildAllTestsAsStandalone=true
# DONT RUN THIS (ci arg) ./src/tests/build.sh ci os android x64 Release nativeaot tree nativeaot/SmokeTests /p:BuildNativeAOTRuntimePack=true /p:LibrariesConfiguration=Release
