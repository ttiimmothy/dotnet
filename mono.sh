#!/usr/bin/env bash

export ANDROID_SDK_ROOT="$HOME/src/maui-android-native/android-sdk/"
export ANDROID_NDK_ROOT="$HOME/src/maui-android-native/android-sdk/ndk/28.2.13676358"

# ./build.sh -arch x64 -os android -s mono+libs -c Release

./src/tests/build.sh os android x64 Release -mono /p:RuntimeVariant=minijit /p:LibrariesConfiguration=Release
