#!/usr/bin/env bash

export ANDROID_SDK_ROOT="$HOME/src/maui-android-native/android-sdk/"
export ANDROID_NDK_ROOT="$HOME/src/maui-android-native/android-sdk/ndk/28.2.13676358"

./build.sh -s mono+libs -os android -arch x64




#!/usr/bin/env bash

# export ANDROID_SDK_ROOT="$HOME/src/maui-android-native/android-sdk/"
# export ANDROID_NDK_ROOT="$HOME/src/maui-android-native/android-sdk/ndk/28.2.13676358"

# # Prereq for nativeaot android tests
# # ./build.sh -s clr+clr.aot+libs+libs.tests -os android -arch x64

# # android.md instructions for building coreclr android
# # ./build.sh clr.runtime+clr.alljits+clr.corelib+clr.nativecorelib+clr.tools+clr.packages+libs -os android -arch x64
# # and android coreclr nuget packages:
# # ./build.sh clr.runtime+clr.alljits+clr.corelib+clr.nativecorelib+clr.tools+clr.packages+libs+host+packs -os android -arch x64
# # find packages at:
# # /artifacts/packages/<configuration>/Shipping/


# ./build.sh mono+libs -os android -arch x64
