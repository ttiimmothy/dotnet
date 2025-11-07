#!/usr/bin/env bash

# Source the environment setup from maui-android-native
. "$HOME/src/maui-android-native/env.sh"

# Set ADB_EXE_PATH to the adb that's now on the path after sourcing env.sh
export ADB_EXE_PATH=$(which adb)

# $HOME/src/xharness/artifacts/bin/Microsoft.DotNet.XHarness.CLI/Release/net9.0/Microsoft.DotNet.XHarness.CLI android test --instrumentation=net.dot.MonoRunner --package-name=net.dot.Android.Device_Emulator.NativeAOT.Test --app=/home/sven/src/runtime/artifacts/bin/Android.Device_Emulator.NativeAOT.Test/Debug/net10.0/android-x64/AppBundle/bin/Android.Device_Emulator.NativeAOT.Test.apk --output-directory=/home/sven/src/runtime/artifacts/bin/Android.Device_Emulator.NativeAOT.Test/Debug/net10.0/android-x64/AppBundle/xharness-output --timeout=1800 --expected-exit-code 42 -v

# xharness\
# NativeAOT smoke tests
# $HOME/src/xharness/artifacts/bin/Microsoft.DotNet.XHarness.CLI/Release/net9.0/Microsoft.DotNet.XHarness.CLI \
#     android test \
#     -v \
#     --app=./artifacts/tests/coreclr/android.x64.Release/nativeaot/SmokeTests/nativeaot_SmokeTests.apk \
#     --package-name=net.dot.nativeaot_SmokeTests \
#     --instrumentation=net.dot.MonoRunner \
#     --output-directory=local-xharness-out

TEST_CATEGORY="UnitTests"
TEST_NAME="UnitTests"
# Single native aot test
# echo "!!! TESTING ./artifacts/tests/coreclr/android.x64.Release/nativeaot/SmokeTests/$TEST_CATEGORY/$TEST_NAME/AppBundle/bin/$TEST_NAME.apk !!!"
$HOME/src/xharness/artifacts/bin/Microsoft.DotNet.XHarness.CLI/Release/net9.0/Microsoft.DotNet.XHarness.CLI \
    android test \
    -v \
    --package-name=net.dot.$TEST_NAME \
    --app=./artifacts/tests/coreclr/android.x64.Release/nativeaot/SmokeTests/$TEST_CATEGORY/$TEST_NAME/AppBundle/bin/$TEST_NAME.apk \
    --instrumentation=net.dot.MonoRunner \
    --output-directory=local-xharness-out \
    --expected-exit-code 100


# $HOME/src/xharness/artifacts/bin/Microsoft.DotNet.XHarness.CLI/Release/net9.0/Microsoft.DotNet.XHarness.CLI \
#     android test \
#     -v \
#     --package-name=net.dot.AttributeTrimming \
#     --app=./artifacts/tests/coreclr/android.x64.Release/nativeaot/SmokeTests/AttributeTrimming/AttributeTrimming/AppBundle/bin/AttributeTrimming.apk \
#     --instrumentation=net.dot.MonoRunner \
#     --output-directory=local-xharness-out \
#     --expected-exit-code 100


# naot smoke tests
# $HOME/src/xharness/artifacts/bin/Microsoft.DotNet.XHarness.CLI/Release/net9.0/Microsoft.DotNet.XHarness.CLI \
#     android test \
#     -v \
#     --app=./artifacts/tests/coreclr/android.x64.Release/nativeaot/SmokeTests/nativeaot_SmokeTests.apk \
#     --package-name=net.dot.nativeaot_SmokeTests \
#     --instrumentation=net.dot.MonoRunner \
#     --output-directory=local-xharness-out

# System.Reflection tests
# $HOME/src/xharness/artifacts/bin/Microsoft.DotNet.XHarness.CLI/Release/net9.0/Microsoft.DotNet.XHarness.CLI \
#     android test \
#     -v \
#     --app=$HOME/src/runtime/artifacts/bin/System.Reflection.Tests/Release/net10.0/android-x64/AppBundle/bin/System.Reflection.Tests.apk \
#     --package-name=net.dot.System.Reflection.Tests \
#     --instrumentation=net.dot.MonoRunner \
#     --output-directory=local-xharness-out
#
#
# adb install -r ./artifacts/tests/coreclr/android.x64.Release/nativeaot/SmokeTests/nativeaot_SmokeTests.apk
# /home/sven/src/maui-android-native/android-sdk/platform-tools/adb -s emulator-5554 shell am instrument \
#     -w net.dot.nativeaot_SmokeTests/net.dot.MonoRunner
# 10-21 16:54:07.870   688  1207 W ActivityManager: Invalid packageName: net.dot.Android.nativeaot.SmokeTests
