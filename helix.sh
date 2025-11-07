#!/usr/bin/env bash

# Simple one-shot invocation to prepare (and attempt to send) Helix payloads for Android NativeAOT smoke tests.
# Intent: keep minimal; adjust arguments here if needed.


export ANDROID_SDK_ROOT="$HOME/src/maui-android-native/android-sdk/"
export ANDROID_NDK_ROOT="$HOME/src/maui-android-native/android-sdk/ndk/28.2.13676358"

# dotnet msbuild src/tests/Common/helixpublishwitharcade.proj \
#     /p:TargetArchitecture=x64 /p:TargetOS=android \
#     /p:TargetOSSubgroup= /p:Configuration=Release \
#     -p:_Scenarios=normal -p:_HelixTargetQueues=buntu.2204.Amd64.Open \
#     -p:_HelixType=test/nativeaot-smoketests \
#     -bl:helix.binlog

_Scenarios=normal \
_HelixTargetQueues=Ubuntu.2204.Amd64.Android.29.Open \
_PublishTestResults=false \
_HelixType=test/functional/cli \
_Creator=svbomer \
    ./eng/common/msbuild.sh --restore --ci --warnaserror false \
    src/tests/Common/helixpublishwitharcade.proj \
    /maxcpucount \
    /bl:artifacts/log/SendToHelix.binlog \
    /p:TargetArchitecture=x64 /p:TargetOS=android /p:TargetOSSubgroup= /p:Configuration=Release

