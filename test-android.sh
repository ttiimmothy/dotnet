#!/usr/bin/env bash

export ANDROID_SDK_ROOT="$HOME/src/maui-android-native/android-sdk/"
export ANDROID_NDK_ROOT="$HOME/src/maui-android-native/android-sdk/ndk/28.2.13676358"

. "$HOME/src/maui-android-native/env.sh"
export ADB_EXE_PATH="$(command -v adb)"

# export XHARNESS_CLI_PATH="$HOME/src/xharness/artifacts/bin/Microsoft.DotNet.XHarness.CLI/Release/net9.0/Microsoft.DotNet.XHarness.CLI.dll"

# ./build.sh mono+libs -os android -arch x64 -c Release
# ./build.sh clr+libs -os android -arch x64 -c Release
./dotnet.sh build -c Release \
    /t:Test -bl /p:TargetOS=android /p:TargetArchitecture=x64 \
    /p:RuntimeFlavor=coreclr \
    src/libraries/System.IO.Compression/tests


# run all libraries tests for android:
# ./build.sh libs+tests -os android -arch x64 -test

# Not run in CI I think, let's try mono AOT android tests:
# ./build.sh libs.tests -os android -arch x64 -test -p:RunAOTCompilation=true -p:MonoForceInterpreter=false

# Run in CI, best-supported mono configuration on android:
# ./build.sh libs.tests -os android -arch x64 -test -p:RuntimeFlavor=mono

# Same tests but using native AOT:
# ./build.sh libs.tests -os android -arch x64 -test -p:RuntimeFlavor=coreclr \
#     -p:UseNativeAOTRuntime=true /p:TestNativeAOT=true


# AOT
# /p:RunAOTCompilation=true /p:MonoForceInterpreter=false
# AOT-LLVM
# /p:RunAOTCompilation=true /p:MonoForceInterpreter=false /p:MonoEnableLLVM=true
# Interpreter
# /p:RunAOTCompilation=false /p:MonoForceInterpreter=true

# Notes:
# I don't think we run _ANY_ mono AOT tests on android.

# Android ci tests:
# - runtime innerloop tests (mono) (runtimeVariant: minijit)
# - runtime innerloop tests (mono interpreter) (runtimeVariant: monointerpreter)
# - runtime libraries innerloop tests (mono with libs+libs.tests) (no runtimeVariant)
# - runtime libraries innerlopp coreclr (runtime, alljits, corelib, tools, packages, libs, libs.tests, etc)
# - nativeaotfunctional tests (clr.aot+libs+libs.tests /p:RunSmokeTestsOnly /p:UseNativeAOTRuntime=true /p:TestNativeAOT=true

# Let's try building+running mono interpreter runtime tests on android.
# ./build.sh mono+libs -os android -arch x64 -c Release
# ./src/tests/build.sh os android x64 Release -mono /p:RuntimeVariant=minijit -p:LibrariesConfiguration=Release
# ./src/tests/run.sh android Release

# This test fails during the full mono aot build:
# ./dotnet.sh build -t:Test \
#     -p:TargetOS=android -p:TargetArchitecture=x64 -p:RuntimeFlavor=mono \
#     /p:RunAOTCompilation=true -p:MonoForceInterpreter=false \
#     src/libraries/System.Runtime/tests/System.Reflection.Tests/

# Android functional tests (not run in ci!?)
# I think this runs as part of libs build.
#

# OK let's get to parity with runtime libraries innerloop tests.
# Or... AOT functional tests?

# Build everything for android
# ./build.sh mono+libs -os android -arch x64

# Run libs tests for android
# time ./build.sh libs.tests -os android -arch x64 -test > test.log

# Run individual test
# ./dotnet.sh build /t:Test src/libraries/System.Net.WebSockets.Client/tests /p:TargetOS=android /p:TargetArchitecture=x64 /p:RuntimeFlavor=mono

# ./dotnet.sh build -c Release \
#     /t:Test \
#     -p:TargetOS=android -p:TargetArchitecture=x64 \
#     -p:RuntimeFlavor=mono \
#     src/libraries/Microsoft.Extensions.Hosting/tests/UnitTests
