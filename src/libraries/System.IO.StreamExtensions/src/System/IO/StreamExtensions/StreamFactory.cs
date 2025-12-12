using System;
using System.Collections.Generic;
using System.Text;

namespace System.IO.StreamExtensions;

public static class StreamFactory
{
    public static Stream StreamFromStringCopy(string text, Encoding? encoding = null)
    {
        encoding ??= Encoding.UTF8;
        return new MemoryStream(encoding.GetBytes(text));
    }
    public static Stream StreamFromString(string text, Encoding? encoding = null)
    {
        return new StringStream(text, encoding ?? Encoding.UTF8);
    }
}
