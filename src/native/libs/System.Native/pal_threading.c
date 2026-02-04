// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#include "pal_config.h"
#include "pal_errno.h"
#include "pal_threading.h"

#include <limits.h>
#include <sched.h>
#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/time.h>
#include <minipal/thread.h>
#if HAVE_SCHED_GETCPU
#include <sched.h>
#endif

#if defined(TARGET_OSX)
// So we can use the declaration of pthread_cond_timedwait_relative_np
#undef _XOPEN_SOURCE
#endif
#include <pthread.h>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LowLevelMonitor - Represents a non-recursive mutex and condition

struct LowLevelMonitor
{
    pthread_mutex_t Mutex;
    pthread_cond_t Condition;
#ifdef DEBUG
    bool IsLocked;
#endif
};

static void SetIsLocked(LowLevelMonitor* monitor, bool isLocked)
{
#ifdef DEBUG
    assert(monitor->IsLocked != isLocked);
    monitor->IsLocked = isLocked;
#else
    (void)monitor; // unused in release build
    (void)isLocked; // unused in release build
#endif
}

LowLevelMonitor* SystemNative_LowLevelMonitor_Create(void)
{
    LowLevelMonitor* monitor = (LowLevelMonitor *)malloc(sizeof(LowLevelMonitor));
    if (monitor == NULL)
    {
        return NULL;
    }

    int error;

    error = pthread_mutex_init(&monitor->Mutex, NULL);
    if (error != 0)
    {
        free(monitor);
        return NULL;
    }

#if HAVE_PTHREAD_CONDATTR_SETCLOCK && HAVE_CLOCK_MONOTONIC
    pthread_condattr_t conditionAttributes;
    error = pthread_condattr_init(&conditionAttributes);
    if (error != 0)
    {
        goto mutex_destroy;
    }

    error = pthread_condattr_setclock(&conditionAttributes, CLOCK_MONOTONIC);
    if (error != 0)
    {
        error = pthread_condattr_destroy(&conditionAttributes);
        assert(error == 0);
        goto mutex_destroy;
    }

    error = pthread_cond_init(&monitor->Condition, &conditionAttributes);

    int condAttrDestroyError;
    condAttrDestroyError = pthread_condattr_destroy(&conditionAttributes);
    assert(condAttrDestroyError == 0);
#else
    error = pthread_cond_init(&monitor->Condition, NULL);
#endif
    if (error != 0)
    {
        goto mutex_destroy;
    }

#ifdef DEBUG
    monitor->IsLocked = false;
#endif

    return monitor;

mutex_destroy:
    error = pthread_mutex_destroy(&monitor->Mutex);
    assert(error == 0);
    free(monitor);
    return NULL;
}

void SystemNative_LowLevelMonitor_Destroy(LowLevelMonitor* monitor)
{
    assert(monitor != NULL);

    int error;

    error = pthread_cond_destroy(&monitor->Condition);
    assert(error == 0);

    error = pthread_mutex_destroy(&monitor->Mutex);
    assert(error == 0);

    free(monitor);
}

void SystemNative_LowLevelMonitor_Acquire(LowLevelMonitor* monitor)
{
    assert(monitor != NULL);

    int error;

    error = pthread_mutex_lock(&monitor->Mutex);
    assert(error == 0);

    SetIsLocked(monitor, true);
}

void SystemNative_LowLevelMonitor_Release(LowLevelMonitor* monitor)
{
    assert(monitor != NULL);

    SetIsLocked(monitor, false);

    int error;

    error = pthread_mutex_unlock(&monitor->Mutex);
    assert(error == 0);
}

void SystemNative_LowLevelMonitor_Wait(LowLevelMonitor* monitor)
{
    assert(monitor != NULL);

    SetIsLocked(monitor, false);

    int error;

    error = pthread_cond_wait(&monitor->Condition, &monitor->Mutex);
    assert(error == 0);

    SetIsLocked(monitor, true);
}

int32_t SystemNative_LowLevelMonitor_TimedWait(LowLevelMonitor *monitor, int32_t timeoutMilliseconds)
{
    assert(timeoutMilliseconds >= 0);

    SetIsLocked(monitor, false);

    int error;

    // Calculate the time at which a timeout should occur, and wait. Older versions of OSX don't support clock_gettime with
    // CLOCK_MONOTONIC, so we instead compute the relative timeout duration, and use a relative variant of the timed wait.
    struct timespec timeoutTimeSpec;
#if HAVE_CLOCK_GETTIME_NSEC_NP
    timeoutTimeSpec.tv_sec = timeoutMilliseconds / 1000;
    timeoutTimeSpec.tv_nsec = (timeoutMilliseconds % 1000) * 1000 * 1000;

    error = pthread_cond_timedwait_relative_np(&monitor->Condition, &monitor->Mutex, &timeoutTimeSpec);
#else
#if HAVE_PTHREAD_CONDATTR_SETCLOCK && HAVE_CLOCK_MONOTONIC
    error = clock_gettime(CLOCK_MONOTONIC, &timeoutTimeSpec);
    assert(error == 0);

    uint64_t nanoseconds = (uint64_t)timeoutMilliseconds * 1000 * 1000 + (uint64_t)timeoutTimeSpec.tv_nsec;
    timeoutTimeSpec.tv_sec += nanoseconds / (1000 * 1000 * 1000);
    timeoutTimeSpec.tv_nsec = nanoseconds % (1000 * 1000 * 1000);

    error = pthread_cond_timedwait(&monitor->Condition, &monitor->Mutex, &timeoutTimeSpec);
#elif HAVE_CLOCK_MONOTONIC
    // The condition variable was not configured to use CLOCK_MONOTONIC (no pthread_condattr_setclock),
    // so pthread_cond_timedwait uses CLOCK_REALTIME by default. CLOCK_REALTIME is affected by system
    // time changes (e.g., NTP adjustments, manual time changes), which can cause waits to hang or
    // return prematurely. To work around this, we use a loop that:
    // 1. Tracks elapsed time using CLOCK_MONOTONIC (not affected by system time changes)
    // 2. Performs the actual wait using CLOCK_REALTIME with short intervals
    // 3. Rechecks the monotonic elapsed time after each wait to determine if the timeout has truly expired
    struct timespec startTime;
    error = clock_gettime(CLOCK_MONOTONIC, &startTime);
    assert(error == 0);

    int64_t remainingMilliseconds = timeoutMilliseconds;
    bool signaled = false;

    while (remainingMilliseconds > 0)
    {
        // Use a maximum wait interval of 100ms to limit exposure to clock adjustments
        // while not spinning too frequently for short waits
        int64_t waitMilliseconds = remainingMilliseconds < 100 ? remainingMilliseconds : 100;

        struct timeval tv;
        error = gettimeofday(&tv, NULL);
        assert(error == 0);

        timeoutTimeSpec.tv_sec = tv.tv_sec;
        timeoutTimeSpec.tv_nsec = tv.tv_usec * 1000;

        uint64_t nanoseconds = (uint64_t)waitMilliseconds * 1000 * 1000 + (uint64_t)timeoutTimeSpec.tv_nsec;
        timeoutTimeSpec.tv_sec += nanoseconds / (1000 * 1000 * 1000);
        timeoutTimeSpec.tv_nsec = nanoseconds % (1000 * 1000 * 1000);

        error = pthread_cond_timedwait(&monitor->Condition, &monitor->Mutex, &timeoutTimeSpec);

        if (error == 0)
        {
            // Signaled, return success
            signaled = true;
            break;
        }

        // Treat any error other than ETIMEDOUT as a timeout for safety
        // (EINVAL, EPERM, etc. should not happen with correct usage)

        // Calculate elapsed time using monotonic clock
        struct timespec currentTime;
        int clockError = clock_gettime(CLOCK_MONOTONIC, &currentTime);
        assert(clockError == 0);
        (void)clockError; // Suppress unused variable warning in release builds

        // Handle nanosecond wraparound correctly
        int64_t elapsedSeconds = currentTime.tv_sec - startTime.tv_sec;
        int64_t elapsedNanoseconds = currentTime.tv_nsec - startTime.tv_nsec;
        if (elapsedNanoseconds < 0)
        {
            elapsedSeconds -= 1;
            elapsedNanoseconds += 1000 * 1000 * 1000;
        }
        int64_t elapsedMilliseconds = elapsedSeconds * 1000 + elapsedNanoseconds / (1000 * 1000);

        remainingMilliseconds = timeoutMilliseconds - elapsedMilliseconds;
    }

    // Set error based on whether we were signaled or timed out
    error = signaled ? 0 : ETIMEDOUT;
#else
    struct timeval tv;

    error = gettimeofday(&tv, NULL);
    assert(error == 0);

    timeoutTimeSpec.tv_sec = tv.tv_sec;
    timeoutTimeSpec.tv_nsec = tv.tv_usec * 1000;

    uint64_t nanoseconds = (uint64_t)timeoutMilliseconds * 1000 * 1000 + (uint64_t)timeoutTimeSpec.tv_nsec;
    timeoutTimeSpec.tv_sec += nanoseconds / (1000 * 1000 * 1000);
    timeoutTimeSpec.tv_nsec = nanoseconds % (1000 * 1000 * 1000);

    error = pthread_cond_timedwait(&monitor->Condition, &monitor->Mutex, &timeoutTimeSpec);
#endif
#endif
    assert(error == 0 || error == ETIMEDOUT);

    SetIsLocked(monitor, true);

    return error == 0;
}

void SystemNative_LowLevelMonitor_Signal_Release(LowLevelMonitor* monitor)
{
    assert(monitor != NULL);

    int error;

    error = pthread_cond_signal(&monitor->Condition);
    assert(error == 0);

    SetIsLocked(monitor, false);

    error = pthread_mutex_unlock(&monitor->Mutex);
    assert(error == 0);
}

int32_t SystemNative_CreateThread(uintptr_t stackSize, void *(*startAddress)(void*), void *parameter)
{
    bool result = false;
    pthread_attr_t attrs;

    int error = pthread_attr_init(&attrs);
    if (error != 0)
    {
        // Do not call pthread_attr_destroy
        return false;
    }

    error = pthread_attr_setdetachstate(&attrs, PTHREAD_CREATE_DETACHED);
    assert(error == 0);

#ifdef HOST_APPLE
    // Match Windows stack size
    if (stackSize == 0)
    {
        stackSize = 1536 * 1024;
    }
#endif

    if (stackSize > 0)
    {
        if (stackSize < (uintptr_t)PTHREAD_STACK_MIN)
        {
            stackSize = (uintptr_t)PTHREAD_STACK_MIN;
        }

        error = pthread_attr_setstacksize(&attrs, stackSize);
        if (error != 0) goto CreateThreadExit;
    }

    pthread_t threadId;
    error = pthread_create(&threadId, &attrs, startAddress, parameter);
    if (error != 0) goto CreateThreadExit;

    result = true;

CreateThreadExit:
    error = pthread_attr_destroy(&attrs);
    assert(error == 0);

    return result;
}

int32_t SystemNative_SchedGetCpu(void)
{
#if HAVE_SCHED_GETCPU
    return sched_getcpu();
#else
    return -1;
#endif
}

__attribute__((noreturn))
void SystemNative_Exit(int32_t exitCode)
{
    exit(exitCode);
}

__attribute__((noreturn))
void SystemNative_Abort(void)
{
    abort();
}

// Gets a non-truncated OS thread ID that is also suitable for diagnostics, for platforms that offer a 64-bit ID
uint64_t SystemNative_GetUInt64OSThreadId(void)
{
    return (uint64_t)minipal_get_current_thread_id();
}

// Tries to get a non-truncated OS thread ID that is also suitable for diagnostics, for platforms that offer a 32-bit ID.
// Returns (uint32_t)-1 when the implementation does not know how to get the OS thread ID.
uint32_t SystemNative_TryGetUInt32OSThreadId(void)
{
    uint32_t result = (uint32_t)minipal_get_current_thread_id();
    return result == 0 ? (uint32_t)-1 : result;
}
