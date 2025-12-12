// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.
using System.Text;

namespace System.IO.StreamExtensions;

internal sealed class StringStream : Stream
{
    private readonly string _source;
    private readonly Encoder _encoder;
    private int _charPosition;
    private readonly byte[] _byteBuffer;
    private int _byteBufferCount;
    private int _byteBufferPosition;


    internal StringStream(string source) // Default UTF8 encoding
        : this(source, Encoding.UTF8)
    {
    }

    public StringStream(string source, Encoding encoding, int bufferSize = 4096)
    {
        _source = source ?? throw new ArgumentNullException(nameof(source));
        _encoder = encoding.GetEncoder();
        _byteBuffer = new byte[bufferSize];
    }

    public override bool CanRead => true;

    public override bool CanSeek => false;

    public override bool CanWrite => false;

    public override long Length => throw new NotSupportedException();

    public override long Position
    {
        get => throw new NotSupportedException();
        set => throw new NotSupportedException();
    }

    // Read method encodes chunks of the underlying string into the provided buffer "on-the-fly"
    // with a 4KB window (_byteBuffer) for encoding
    public override int Read(byte[] user_buffer, int offset, int count)
    {
        int totalBytesRead = 0;

        while (totalBytesRead < count)
        {
            if (_byteBufferPosition >= _byteBufferCount)
            {
                if (_charPosition >= _source.Length) break;

                int charsToEncode = Math.Min(1024, _source.Length - _charPosition);
                bool flush = _charPosition + charsToEncode >= _source.Length;

#if NET || NETCOREAPP
                _byteBufferCount = _encoder.GetBytes(_source.AsSpan(_charPosition, charsToEncode), _byteBuffer.AsSpan(), flush);
#else
                // For .NET Standard 2.0 and .NET Framework, use char array approach
                char[] charBuffer = _source.ToCharArray(_charPosition, charsToEncode);
                _byteBufferCount = _encoder.GetBytes(charBuffer, 0, charsToEncode, _byteBuffer, 0, flush);
#endif

                _charPosition += charsToEncode;
                _byteBufferPosition = 0;

                if (_byteBufferCount == 0) break;
            }

            int bytesToCopy = Math.Min(count - totalBytesRead, _byteBufferCount - _byteBufferPosition);
            Array.Copy(_byteBuffer, _byteBufferPosition, user_buffer, offset + totalBytesRead, bytesToCopy);
            _byteBufferPosition += bytesToCopy;
            totalBytesRead += bytesToCopy;
        }

        return totalBytesRead;
    }

    public override void Flush() { }

    // Seek not supported - read-only stream. Data is read sequentially.
    public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();

    public override void SetLength(long value) => throw new NotSupportedException();

    // Not supported for String or ReadOnlyMemory scenarios
    public override void Write(byte[] buffer, int offset, int count) => throw new NotSupportedException();
}
