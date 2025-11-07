#!/usr/bin/env bash

. ./test-naot-android-common.sh

###
### Libraries tests
###


# Baseline build
# ./build.sh -arch x64 -os android -s libs -c Release
# command -v "/home/sven/src/maui-android-native/android-sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
# Seems TestNativeAOT doesn't do a complete build, need to run above first if I see missing PlatformManifest entries.
# ./build.sh -test -arch x64 -os android -s clr.aot+libs -c Release -p:UseNativeAOTRuntime=true -p:RuntimeFlavor=coreclr -p:TestNativeAOT=true
# no libs:
# ./build.sh -ci -test -arch x64 -os android -s clr.aot+libs+libs.tests -c Release -p:UseNativeAOTRuntime=true -p:RuntimeFlavor=coreclr -p:TestNativeAOT=true
# ./build.sh -arch x64 -os android -s libs -c Release


# Libs tests use UseNativeAOTRuntime.
# Runtime tests use TestBuildMode.
# which clang
    # /t:Test \
./dotnet.sh build -c Release \
    /t:Test \
    /p:TargetOS=android /p:TargetArchitecture=x64 \
    -p:TestNativeAot=true \
    -p:UseNativeAOTRuntime=true \
    -bl:testbuild.binlog \
    /p:CppCompilerAndLinker="$(command -v clang)" \
    src/libraries/System.Runtime/tests/System.Reflection.Tests
    # src/libraries/System.Security.Cryptography.Cose/tests/System.Security.Cryptography.Cose.Tests.csproj
    # src/libraries/System.Linq.Expressions/tests
    # -p:TestBuildMode=nativeaot \
    # src/libraries/System.Runtime/tests/System.Dynamic.Runtime.Tests
    # src/libraries/Microsoft.Extensions.DependencyModel/tests
    # src/libraries/System.Diagnostics.FileVersionInfo/tests/System.Diagnostics.FileVersionInfo.Tests
    # src/libraries/Microsoft.Extensions.Hosting/tests/UnitTests
    # src/libraries/System.Runtime/tests/System.Diagnostics.Debug.Tests
    # src/libraries/System.Runtime/tests/System.Reflection.Tests
    # src/tests/nativeaot/SmokeTests/AttributeTrimming/AttributeTrimming.csproj
    # -pp:libstest.xml
    # -pp:smoketest.xml
    # src/tests/FunctionalTests/Android/Device_Emulator/NativeAOT/Android.Device_Emulator.NativeAOT.Test.csproj
    # /t:BuildNativeAot \
    # /t:BuildAndroidApp \
    # -t:BuildNativeAot=true \
    # src/libraries/System.IO.Compression/tests
    # src/libraries/System.Net.Requests/tests/System.Net.Requests.Tests.csproj
    # src/libraries.System.Net.Security/tests/UnitTests/System.Net.Security.Unit.Tests.csproj
    # src/libraries/System.Net.WebSockets.Client/tests
    # src/tests/FunctionalTests/Android/Device_Emulator/NativeAOT/Android.Device_Emulator.NativeAOT.Test.csproj
    # src/libraries/System.IO.Compression/tests
    # src/libraries/Microsoft.Extensions.DependencyModel/tests
    # src/libraries/System.Data.Common/tests/System.Data.DataSetExtensions.Tests
    # src/libraries/Microsoft.Extensions.Configuration/tests/FunctionalTests
    # src/libraries/Microsoft.Bcl.Cryptography/tests \
#     -bl:runandroidtest.binlog
    # src/tests/FunctionalTests/Android/Device_Emulator/NativeAOT/Android.Device_Emulator.NativeAOT.Test.csproj \


# "/home/sven/src/runtime/dotnet.sh" msbuild /home/sven/src/runtime/src/tests/build.proj /t:Build "/p:TargetArchitecture=x64" "/p:ConfiguratRuntimeFlavorion=Release" "/p:LibrariesConfiguration=Release" "/p:TasksConfiguration=Release" "/p:TargetOS=android" "/p:ToolsOS=" "/p:PackageOS=" "/p:RuntimeFlavor=CoreCLR" "/p:RuntimeVariant=" "/p:CLRTestBuildAllTargets=" "/p:UseCodeFlowEnforcement=" "/p:__TestGroupToBuild=1" "/p:__SkipRestorePackages=1" /nodeReuse:false /maxcpucount /bl:/home/sven/src/runtime/artifacts//log/Release/InnerManagedTestBuild.1.binlog "/p:DevTeamProvisioning=-"
# "/home/sven/src/runtime/eng/common/msbuild.sh"  --warnAsError false /home/sven/src/runtime/src/tests/build.proj /t:TestBuild /p:TargetArchitecture=x64 /p:Configuration=Release /p:TargetOS=android /nodeReuse:false    /maxcpucount "/flp:Verbosity=normal;LogFile=/home/sven/src/runtime/artifacts/log/TestBuild.android.x64.Release.log" "/flp1:WarningsOnly;LogFile=/home/sven/src/runtime/artifacts/log/TestBuild.android.x64.Release.wrn" "/flp2:ErrorsOnly;LogFile=/home/sven/src/runtime/artifacts/log/TestBuild.android.x64.Release.err" "/bl:/home/sven/src/runtime/artifacts/log/TestBuild.android.x64.Release.binlog" /p:NUMBER_OF_PROCESSORS=32 /p:BuildNativeAOTRuntimePack=true /p:LibrariesConfiguration=Release

# ./src/tests/run.sh android --runnativeaottests Release

# ./dotnet.sh build -c Debug \
#     src/tests/FunctionalTests/Android/Device_Emulator/NativeAOT/Android.Device_Emulator.NativeAOT.Test.csproj \
#     /t:Test -bl /p:TargetOS=android /p:TargetArchitecture=x64 \
#     -p:TestNativeAot=true \
#     -bl:runandroidtest.binlog

# ./dotnet.sh build -c Release \
#     /t:Test \
#     -p:TargetOS=android -p:TargetArchitecture=x64 -p:UseNativeAOTRuntime=true -p:TestNativeAOT=true \
#     src/libraries/Microsoft.Extensions.Hosting/tests/UnitTests
#     src/libraries/System.Net.Http/tests/FunctionalTests
    # src/libraries/System.Runtime/tests/System.Diagnostics.Debug.Tests
    # src/libraries/System.Security.Cryptography.Cose/tests -bl:w.binlog
    # -p:VSTestTestCaseFilter="FullyQualifiedName~CreateDefaultBuilder_IncludesCommandLineArguments"
    # src/libraries/Microsoft.Extensions.Logging.EventSource/tests
    # src/libraries/System.Runtime.Caching/tests
    # src/libraries/System.Security.Cryptography.Cose.Tests



# /home/sven/src/runtime/src/tasks/AndroidAppBuilder/Templates/monodroid-nativeaot.cs(96,29): error CS8600: Converting null literal or possible null value to non-nullable type. [/home/sven/src/runtime/src/libraries/System.Security.Cryptography.Cose/tests/System.Security.Cryptography.Cose.Tests.csproj::TargetFramework=net10.0]
# /home/sven/src/runtime/src/tasks/AndroidAppBuilder/Templates/monodroid-nativeaot.cs(57,23): error CS8601: Possible null reference assignment. [/home/sven/src/runtime/src/libraries/System.Security.Cryptography.Cose/tests/System.Security.Cryptography.Cose.Tests.csproj::TargetFramework=net10.0]
# /home/sven/src/runtime/src/tasks/AndroidAppBuilder/Templates/monodroid-nativeaot.cs(61,44): error CS8604: Possible null reference argument for parameter 'path1' in 'string Path.Combine(string path1, string path2)'. [/home/sven/src/runtime/src/libraries/System.Security.Cryptography.Cose/tests/System.Security.Cryptography.Cose.Tests.csproj::TargetFramework=net10.0]
