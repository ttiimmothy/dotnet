// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.
using System.IO.Tests;
using System.Text;
using System.Threading.Tasks;
using Xunit;

namespace System.IO.StreamExtensions.Tests;

/// <summary>
/// 
/// Conformance tests for StringStream - a read-only, non-seekable stream
/// that encodes strings on-the-fly. 
/// </summary>
public class StringStreamConformanceTests : StandaloneStreamConformanceTests
{
    // StringStream is read-only and doesn't support seeking or length changes
    protected override bool CanSeek => false;
    protected override bool CanSetLength => false;
    protected override bool CanGetPositionWhenCanSeekIsFalse => false;

    // StringStream reads sequentially until the string is fully encoded
    protected override bool ReadsReadUntilSizeOrEof => true;

    // Synchronous No-op flush completes immediately since no buffering at Stream level
    protected override bool NopFlushCompletesSynchronously => true;

    /// <summary>
    /// Creates a read-only StringStream with the provided initial data. 
    /// </summary>
    protected override Task<Stream?> CreateReadOnlyStreamCore(byte[]? initialData)
    {
        if (initialData == null)
        {
            // Empty string for null data
            return Task.FromResult<Stream?>(new StringStream("", Encoding.UTF8));
        }

        // Convert byte array back to string using UTF8
        string sourceString = Encoding.UTF8.GetString(initialData);
        return Task.FromResult<Stream?>(new StringStream(sourceString, Encoding.UTF8));
    }

    /// <summary>
    /// StringStream is read-only, so write-only streams are not supported.
    /// </summary>
    protected override Task<Stream?> CreateWriteOnlyStreamCore(byte[]? initialData)
    {
        // Return null to indicate this stream type doesn't support write-only mode
        return Task.FromResult<Stream?>(null);
    }

    /// <summary>
    /// StringStream is read-only, so read-write streams are not supported. 
    /// </summary>
    protected override Task<Stream?> CreateReadWriteStreamCore(byte[]? initialData)
    {
        // Return null to indicate this stream type doesn't support read-write mode
        return Task.FromResult<Stream?>(null);
    }

    // Additional test to verify encoding behavior with different encodings
    [Theory]
    [InlineData("Hello, World! ")]
    [InlineData("")]
    [InlineData("Unicode: 你好世界 🌍")]
    [InlineData("Multi\nLine\r\nText")]
    public async Task StringStream_ReadsCorrectBytesForDifferentStrings(string input)
    {
        // Arrange
        byte[] expectedBytes = Encoding.UTF8.GetBytes(input);
        var stream = new StringStream(input, Encoding.UTF8);

        // Act
        byte[] actualBytes = new byte[expectedBytes.Length + 100]; // Extra space
        int totalRead = 0;
        int bytesRead;

        while ((bytesRead = await stream.ReadAsync(actualBytes.AsMemory(totalRead))) > 0)
        {
            totalRead += bytesRead;
        }

        // Assert
        Assert.Equal(expectedBytes.Length, totalRead);
        Assert.Equal(expectedBytes, actualBytes.AsSpan(0, totalRead).ToArray());
    }

    // Test chunked reading (important for your 4KB buffer design)
    [Fact]
    public async Task StringStream_HandlesChunkedReading()
    {
        // Arrange:  Create a string larger than internal buffer (4KB)
        string largeString = new string('A', 10000); // 10KB of 'A's
        byte[] expectedBytes = Encoding.UTF8.GetBytes(largeString);
        var stream = new StringStream(largeString, Encoding.UTF8);

        // Act: Read in small chunks (smaller than internal buffer)
        byte[] actualBytes = new byte[expectedBytes.Length];
        int totalRead = 0;
        int chunkSize = 512; // Read 512 bytes at a time

        while (totalRead < expectedBytes.Length)
        {
            int bytesRead = await stream.ReadAsync(
                actualBytes.AsMemory(totalRead, Math.Min(chunkSize, expectedBytes.Length - totalRead))
            );

            if (bytesRead == 0) break;
            totalRead += bytesRead;
        }

        // Assert
        Assert.Equal(expectedBytes.Length, totalRead);
        Assert.Equal(expectedBytes, actualBytes);
    }

    // Test with different encodings
    [Theory]
    [InlineData("ASCII text")]
    [InlineData("Ñoño español")]
    public async Task StringStream_WorksWithDifferentEncodings(string input)
    {
        // Test with different encodings
        var encodings = new[] { Encoding.UTF8, Encoding.Unicode, Encoding.UTF32 };

        foreach (var encoding in encodings)
        {
            // Arrange
            byte[] expectedBytes = encoding.GetBytes(input);
            var stream = new StringStream(input, encoding);

            // Act
            byte[] actualBytes = new byte[expectedBytes.Length * 2];
            int totalRead = 0;
            int bytesRead;

            while ((bytesRead = await stream.ReadAsync(actualBytes.AsMemory(totalRead))) > 0)
            {
                totalRead += bytesRead;
            }

            // Assert
            Assert.Equal(expectedBytes.Length, totalRead);
            Assert.Equal(expectedBytes, actualBytes.AsSpan(0, totalRead).ToArray());
        }
    }

    // Test read behavior with exact buffer size match
    [Fact]
    public async Task StringStream_ReadsWithExactBufferSizeMatch()
    {
        // Arrange:  String that encodes to exactly 4096 bytes (internal buffer size)
        string input = new string('A', 4096);
        byte[] expectedBytes = Encoding.UTF8.GetBytes(input);
        var stream = new StringStream(input, Encoding.UTF8);

        // Act
        byte[] buffer = new byte[4096];
        int bytesRead = await stream.ReadAsync(buffer);

        // Assert
        Assert.Equal(4096, bytesRead);
        Assert.Equal(expectedBytes, buffer);
    }
}

/// <summary>
/// Additional specific tests for StringStream beyond conformance tests. 
/// </summary>
public class StringStreamSpecificTests
{
    [Fact]
    public void StringStream_ThrowsOnNullString()
    {
        Assert.Throws<ArgumentNullException>(() => new StringStream(null!));
    }

    [Fact]
    public void StringStream_CanReadPropertyReturnsTrue()
    {
        var stream = new StringStream("test");
        Assert.True(stream.CanRead);
    }

    [Fact]
    public void StringStream_CanSeekPropertyReturnsFalse()
    {
        var stream = new StringStream("test");
        Assert.False(stream.CanSeek);
    }

    [Fact]
    public void StringStream_CanWritePropertyReturnsFalse()
    {
        var stream = new StringStream("test");
        Assert.False(stream.CanWrite);
    }

    [Fact]
    public void StringStream_LengthThrowsNotSupportedException()
    {
        var stream = new StringStream("test");
        Assert.Throws<NotSupportedException>(() => stream.Length);
    }

    [Fact]
    public void StringStream_PositionGetThrowsNotSupportedException()
    {
        var stream = new StringStream("test");
        Assert.Throws<NotSupportedException>(() => stream.Position);
    }

    [Fact]
    public void StringStream_SeekThrowsNotSupportedException()
    {
        var stream = new StringStream("test");
        Assert.Throws<NotSupportedException>(() => stream.Seek(0, SeekOrigin.Begin));
    }

    [Fact]
    public void StringStream_WriteThrowsNotSupportedException()
    {
        var stream = new StringStream("test");
        Assert.Throws<NotSupportedException>(() => stream.Write(new byte[1], 0, 1));
    }

    [Fact]
    public void StringStream_SetLengthThrowsNotSupportedException()
    {
        var stream = new StringStream("test");
        Assert.Throws<NotSupportedException>(() => stream.SetLength(100));
    }

    [Fact]
    public async Task StringStream_MultipleReadsEventuallyReturnZero()
    {
        // Arrange
        var stream = new StringStream("small", Encoding.UTF8);
        byte[] buffer = new byte[100];

        // Act:  Read until EOF
        int totalRead = 0;
        int bytesRead;
        int readCount = 0;

        while ((bytesRead = await stream.ReadAsync(buffer.AsMemory(totalRead))) > 0 && readCount < 10)
        {
            totalRead += bytesRead;
            readCount++;
        }

        // Additional read should return 0
        int finalRead = await stream.ReadAsync(buffer.AsMemory(0));

        // Assert
        Assert.Equal(5, totalRead); // "small" = 5 bytes in UTF8
        Assert.Equal(0, finalRead);
    }
}
