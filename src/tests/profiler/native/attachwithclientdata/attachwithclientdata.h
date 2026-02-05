// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#pragma once

#include "../profiler.h"

#include <atomic>

// This profiler validates that client_data passed via IPC AttachProfiler command
// is correctly received by the profiler's InitializeForAttach callback.
// It exercises the client_data_len parsing code path in ds-profiler-protocol.c.
class AttachWithClientDataProfiler : public Profiler
{
public:
    AttachWithClientDataProfiler();
    virtual ~AttachWithClientDataProfiler();

    static GUID GetClsid();
    virtual HRESULT STDMETHODCALLTYPE InitializeForAttach(IUnknown* pCorProfilerInfoUnk, void* pvClientData, UINT cbClientData);
    virtual HRESULT STDMETHODCALLTYPE Shutdown();

    virtual HRESULT STDMETHODCALLTYPE ProfilerAttachComplete();
    virtual HRESULT STDMETHODCALLTYPE ProfilerDetachSucceeded();

private:
    std::atomic<int> _failures;
    bool _detachSucceeded;
    bool _clientDataValidated;
};
