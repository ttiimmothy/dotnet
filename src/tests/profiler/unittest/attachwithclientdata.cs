// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

using System;
using System.IO;
using System.Text;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Threading;

namespace Profiler.Tests
{
    // Test that validates client_data (additionalData) is correctly passed through
    // the IPC AttachProfiler command and received by the profiler.
    // This exercises the client_data_len parsing code path in ds-profiler-protocol.c.
    class AttachWithClientData
    {
        private static readonly Guid AttachWithClientDataGuid = new Guid("A6A1D362-63A2-44AD-A178-FE2CF2A46A94");

        // This must match ExpectedClientData in the native profiler
        private static readonly byte[] TestClientData = Encoding.ASCII.GetBytes("TestClientData123");

        [DllImport("Profiler")]
        private static extern void PassCallbackToProfiler(ProfilerCallback callback);

        public static int RunTest(string[] args)
        {
            string profilerName;
            if (TestLibrary.Utilities.IsWindows)
            {
                profilerName = "Profiler.dll";
            }
            else if ((TestLibrary.Utilities.IsLinux) || (TestLibrary.Utilities.IsFreeBSD))
            {
                profilerName = "libProfiler.so";
            }
            else
            {
                profilerName = "libProfiler.dylib";
            }

            string rootPath = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            string profilerPath = Path.Combine(rootPath, profilerName);

            Console.WriteLine($"Attaching profiler {profilerPath} to self with client data.");
            Console.WriteLine($"Client data: \"{Encoding.ASCII.GetString(TestClientData)}\" ({TestClientData.Length} bytes)");

            // Attach profiler with client data - this exercises the client_data parsing code path
            ProfilerControlHelpers.AttachProfilerToSelfWithClientData(AttachWithClientDataGuid, profilerPath, TestClientData);

            ManualResetEvent profilerDone = new ManualResetEvent(false);
            ProfilerCallback profilerDoneDelegate = () => profilerDone.Set();
            PassCallbackToProfiler(profilerDoneDelegate);

            if (!profilerDone.WaitOne(TimeSpan.FromMinutes(5)))
            {
                Console.WriteLine("Profiler did not set the callback, test will fail.");
            }

            GC.KeepAlive(profilerDoneDelegate);
            return 100;
        }

        public static int Main(string[] args)
        {
            if (args.Length > 0 && args[0].Equals("RunTest", StringComparison.OrdinalIgnoreCase))
            {
                return RunTest(args);
            }

            return ProfilerTestRunner.Run(profileePath: System.Reflection.Assembly.GetExecutingAssembly().Location,
                                          testName: "UnitTestAttachWithClientData",
                                          profilerClsid: AttachWithClientDataGuid,
                                          profileeOptions: ProfileeOptions.NoStartupAttach);
        }
    }
}
