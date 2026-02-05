// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#include "attachwithclientdata.h"
#include <cstring>

// Expected client data: "TestClientData123" (17 bytes)
static const char* ExpectedClientData = "TestClientData123";
static const UINT ExpectedClientDataLength = 17;

AttachWithClientDataProfiler::AttachWithClientDataProfiler() :
    _failures(0),
    _detachSucceeded(false),
    _clientDataValidated(false)
{
}

AttachWithClientDataProfiler::~AttachWithClientDataProfiler()
{
    if (_failures == 0 && _detachSucceeded && _clientDataValidated)
    {
        printf("PROFILER TEST PASSES\n");
    }
    else
    {
        printf("Test failed: _failures=%d _detachSucceeded=%d _clientDataValidated=%d\n",
               _failures.load(), _detachSucceeded, _clientDataValidated);
    }

    fflush(stdout);

    NotifyManagedCodeViaCallback(pCorProfilerInfo);
}

GUID AttachWithClientDataProfiler::GetClsid()
{
    // {A6A1D362-63A2-44AD-A178-FE2CF2A46A94}
    GUID clsid = { 0xA6A1D362, 0x63A2, 0x44AD, { 0xA1, 0x78, 0xFE, 0x2C, 0xF2, 0xA4, 0x6A, 0x94 } };
    return clsid;
}

HRESULT AttachWithClientDataProfiler::InitializeForAttach(IUnknown* pICorProfilerInfoUnk, void* pvClientData, UINT cbClientData)
{
    HRESULT hr = Profiler::Initialize(pICorProfilerInfoUnk);
    if (FAILED(hr))
    {
        _failures++;
        printf("FAIL: Profiler::Initialize failed with hr=0x%x\n", hr);
        return hr;
    }

    printf("AttachWithClientDataProfiler::InitializeForAttach called\n");
    printf("  pvClientData=%p, cbClientData=%u\n", pvClientData, cbClientData);

    // Validate the client data
    if (cbClientData != ExpectedClientDataLength)
    {
        _failures++;
        printf("FAIL: cbClientData=%u, expected=%u\n", cbClientData, ExpectedClientDataLength);
    }
    else if (pvClientData == nullptr)
    {
        _failures++;
        printf("FAIL: pvClientData is null but cbClientData=%u\n", cbClientData);
    }
    else if (memcmp(pvClientData, ExpectedClientData, ExpectedClientDataLength) != 0)
    {
        _failures++;
        printf("FAIL: Client data content mismatch\n");
        printf("  Expected: ");
        for (UINT i = 0; i < ExpectedClientDataLength; i++)
        {
            printf("%02x ", (unsigned char)ExpectedClientData[i]);
        }
        printf("\n  Received: ");
        for (UINT i = 0; i < cbClientData; i++)
        {
            printf("%02x ", ((unsigned char*)pvClientData)[i]);
        }
        printf("\n");
    }
    else
    {
        printf("SUCCESS: Client data validated correctly\n");
        _clientDataValidated = true;
    }

    DWORD eventMaskLow = COR_PRF_MONITOR_MODULE_LOADS;
    DWORD eventMaskHigh = 0x0;
    if (FAILED(hr = pCorProfilerInfo->SetEventMask2(eventMaskLow, eventMaskHigh)))
    {
        _failures++;
        printf("FAIL: ICorProfilerInfo::SetEventMask2() failed hr=0x%x\n", hr);
        return hr;
    }

    return S_OK;
}

HRESULT AttachWithClientDataProfiler::Shutdown()
{
    Profiler::Shutdown();
    return S_OK;
}

HRESULT AttachWithClientDataProfiler::ProfilerAttachComplete()
{
    SHUTDOWNGUARD();

    printf("AttachWithClientDataProfiler::ProfilerAttachComplete - requesting detach\n");

    HRESULT hr = pCorProfilerInfo->RequestProfilerDetach(0);
    if (FAILED(hr))
    {
        _failures++;
        printf("FAIL: RequestProfilerDetach failed with hr=0x%x\n", hr);
    }
    else
    {
        printf("RequestProfilerDetach successful\n");
    }

    return S_OK;
}

HRESULT AttachWithClientDataProfiler::ProfilerDetachSucceeded()
{
    SHUTDOWNGUARD();

    printf("AttachWithClientDataProfiler::ProfilerDetachSucceeded\n");
    _detachSucceeded = true;
    return S_OK;
}
