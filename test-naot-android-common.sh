set -euo pipefail

export ANDROID_SDK_ROOT="$HOME/src/maui-android-native/android-sdk/"
export ANDROID_NDK_ROOT="$HOME/src/maui-android-native/android-sdk/ndk/28.2.13676358"

# Basic sanity checks for required Android tooling
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
  echo "ANDROID_SDK_ROOT does not exist: $ANDROID_SDK_ROOT"
  exit 1
fi
if [ ! -d "$ANDROID_NDK_ROOT" ]; then
  echo "ANDROID_NDK_ROOT does not exist: $ANDROID_NDK_ROOT"
  exit 1
fi
if [ ! -f "$HOME/src/maui-android-native/env.sh" ]; then
  echo "Missing environment setup script: $HOME/src/maui-android-native/env.sh"
  exit 1
fi

# Ensure clang is available (NativeAOT publish step needs it)
CLANG_BIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
if [ ! -x "$CLANG_BIN" ]; then
    echo "clang not found at expected location: $CLANG_BIN"
    exit 1
fi
export PATH="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
# TODO: this needs to be fixed in our test scripts!
# export PATH="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"

. "$HOME/src/maui-android-native/env.sh"
export ADB_EXE_PATH="$(command -v adb)"

export XHARNESS_CLI_PATH="$HOME/src/xharness/artifacts/bin/Microsoft.DotNet.XHarness.CLI/Release/net9.0/Microsoft.DotNet.XHarness.CLI.dll"

