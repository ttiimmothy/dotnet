#!/usr/bin/env bash

# NAOT libs (linux)
echo "NAOT libs linux build"
dotnet build ./src/libraries/System.Runtime/tests/System.IO.FileSystem.Tests /p:TestNativeAot=true
if [ $? -ne 0 ]; then
    echo "NativeAOT System.IO.FileSystem.Tests build failed on linux"
    exit 1
fi

. ./test-naot-android-common.sh

# NAOT libs (android)
echo "NAOT libs android build"
./dotnet.sh build -c Release \
    -t:Test \
    -bl /p:TargetOS=android /p:TargetArchitecture=x64 \
    -p:TestNativeAot=true \
    -p:UseNativeAOTRuntime=true \
    /p:CppCompilerAndLinker="$(command -v clang)" \
    src/libraries/System.Runtime/tests/System.IO.FileSystem.Tests
if [ $? -ne 0 ]; then
    echo "NativeAOT System.IO.FileSystem.Tests build failed on android"
    exit 1
fi

# NAOT Functional (android)
echo "NAOT FunctionalTests android build"
./dotnet.sh build -c Release \
    -bl /p:TargetOS=android /p:TargetArchitecture=x64 \
    -p:TestNativeAot=true \
    -p:UseNativeAOTRuntime=true \
    /p:CppCompilerAndLinker="$(command -v clang)" \
    src/tests/FunctionalTests/Android/Device_Emulator/NativeAOT/Android.Device_Emulator.NativeAOT.Test.csproj
if [ $? -ne 0 ]; then
    echo "NativeAOT FunctionalTests build failed on android"
    exit 1
fi

# NAOT runtime (android) (smoke)
echo "NAOT runtime android build"
./src/tests/build.sh os android x64 Release nativeaot tree nativeaot/SmokeTests /p:BuildNativeAOTRuntimePack=true /p:LibrariesConfiguration=Release
if [ $? -ne 0 ]; then
    echo "NativeAOT runtime build failed on android"
    exit 1
fi

echo "Sanitycheck build-sanitycheck.sh completed successfully"