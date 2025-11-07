#!/usr/bin/env bash

run_step() {
  local name=$1
  local cmd=$2
  local marker=".done_${name}"
  
  if [ -f "$marker" ]; then
    echo "Skipping $name (already done)"
    return 0
  fi
  
  echo "Running $name..."
  if eval "$cmd"; then
    touch "$marker"
  else
    echo "❌ $name failed"
    return 1
  fi
}


# Build product
# ./build.sh -ci -arch x64 -os linux -cross -s clr.aot+libs -rc Debug -lc Release /p:RunAnalyzers=false
run_step build "./build.sh -s clr.aot+libs -rc Debug -lc Release /p:RunAnalyzers=false" || exit 1

# Build tests
# ./src/tests/build.sh -cross ci os linux x64 Debug    nativeaot tree nativeaot  /p:LibrariesConfiguration=Release
run_step build-tests "./src/tests/build.sh Debug nativeaot tree nativeaot /p:LibrariesConfiguration=Release" || exit 1

# Run tests


# ./dotnet.sh build -c Release \
#     /t:Test \
#     -p:TargetArchitecture=x64 -p:UseNativeAOTRuntime=true -p:TestNativeAOT=true \
#     src/libraries/Microsoft.Extensions.Hosting/tests/UnitTests
