#!/usr/bin/env bash

export ANDROID_SDK_ROOT="$HOME/src/maui-android-native/android-sdk/"
export ANDROID_NDK_ROOT="$HOME/src/maui-android-native/android-sdk/ndk/28.2.13676358"

./build.sh -s clr+clr.aot+libs+libs.tests -os android -arch x64
