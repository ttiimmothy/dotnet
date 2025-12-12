using System.ComponentModel;
using System.Text;
using static System.Net.Mime.MediaTypeNames;

namespace System.IO.StreamExtensions;

public static class StreamExtensions
{

    // Extension members for Stream type
    // To create Stream instances from different data types
    extension(Stream) {

        // Create a Stream from a read-only string with specified encoding
        public static Stream FromReadOnlyText(string text, Encoding encoding){
            ArgumentNullException.ThrowIfNull(text);
            ArgumentNullException.ThrowIfNull(encoding);

            // Convert string to bytes using the specified encoding
            byte[] bytes = encoding.GetBytes(text);
            return new MemoryStream(bytes, writable: false);
        }

        // Create a Stream from ReadOnlyMemory<char> with specified encoding
        public static Stream FromReadOnlyText(ReadOnlyMemory<char> text, Encoding encoding){
            ArgumentNullException.ThrowIfNull(encoding);

            // Get byte count needed for the character data
            ReadOnlySpan<char> span = text.Span;
            // GetByteCount calculates exact buffer size needed, avoiding over-allocation
            int byteCount = encoding.GetByteCount(span);
            // Allocate byte array with exact size for memory efficiency
            byte[] bytes = new byte[byteCount];
            // Encode characters directly into the allocated buffer
            encoding.GetBytes(span, bytes);

            byte[] bytes2 = encoding.GetBytes(text.ToString());
            // Return read-only stream to enforce immutability contract
            return new MemoryStream(bytes2, writable: false);
        }

        public static Stream FromReadOnlyData(ReadOnlyMemory<byte> data)
        {
            // Try to get the underlying array if available (zero-copy optimization)
            // This avoids copying data if the Memory<byte> is backed by an array
            if (System.Runtime.InteropServices.MemoryMarshal.TryGetArray(data, out var segment))
            {
                // Create read-only stream using the array segment
                // ArraySegment allows us to use a portion of an array without copying
                return new MemoryStream(segment.Array!, segment.Offset, segment.Count, writable: false);
            }

            // Fallback: copy data to a new array if we can't access the underlying array
            // This happens with certain Memory<byte> sources like pooled memory
            byte[] bytes = data.ToArray();
            return new MemoryStream(bytes, writable: false);
        }

        // Most intuitive case
        public static Stream FromData(byte[] data)
        {
            ArgumentNullException.ThrowIfNull(data);
            return new MemoryStream(data);
        }

        // -------------------------------- Writtable scenario for Memory<char> -----------------------
        // Option 1: Return a Stream plus the number of characters written
        public static (Stream Stream, int CharsWritten) FromText(Memory<char> text, Encoding encoding){
            ArgumentNullException.ThrowIfNull(encoding);
            Span<char> span = text.Span;
            //number of bytes written to the stream after encoding
            int byteCount = encoding.GetByteCount(span);
            byte[] bytes = new byte[byteCount];
            encoding.GetBytes(span, bytes);
            // Return stream and simple count
            return (new MemoryStream(bytes), text.Length);
        }

        //Option 2: Return a Stream and via an out parameter the number of characters written
        public static Stream FromText(Memory<char> text, Encoding encoding, out int byteCount){
            ArgumentNullException.ThrowIfNull(encoding);
            Span<char> span = text.Span;
            //number of bytes written to the stream after encoding
            byteCount = encoding.GetByteCount(span);
            byte[] bytes = new byte[byteCount];
            encoding.GetBytes(span, bytes);
            return new MemoryStream(bytes);
        }

        // Option 3: Return a Stream only  and via an out parameter the enconding status
        // Usage: var stream = Stream.FromText(memory, encoding, out var status);
        public static Stream FromTextWithStatus(Memory<char> text, Encoding encoding, out EncodingStatus status){

            ArgumentNullException.ThrowIfNull(encoding);
            // Get byte count needed for the character data
            Span<char> span = text.Span;
            int byteCount = encoding.GetByteCount(span);
            // Allocate byte array and encode characters
            byte[] bytes = new byte[byteCount];
            encoding.GetBytes(span, bytes);

            // Set out parameter with status information
            status = new EncodingStatus{
                CharsProcessed = text.Length,
                BytesWritten = byteCount,
                EncodingUsed = encoding.EncodingName,
            };

            // Status is provided through the out parameter
            return new MemoryStream(bytes);
        }

        // Option 4: Return a TrackedStream with initial status
        public static TrackedStream FromTextWithTracking(Memory<char> text, Encoding encoding){
            ArgumentNullException.ThrowIfNull(encoding);
            Span<char> span = text.Span;
            int byteCount = encoding.GetByteCount(span);
            byte[] bytes = new byte[byteCount];
            encoding.GetBytes(span, bytes);
            
            var initialStatus = new EncodingStatus{
                CharsProcessed = text.Length,
                BytesWritten = byteCount,
                EncodingUsed = encoding.EncodingName,
            };
            
            return new TrackedStream(new MemoryStream(bytes), initialStatus);
        }

        // Simple binary data method (no status)
        public static Stream FromDataSimple(byte[] data){
            ArgumentNullException.ThrowIfNull(data);
            return new MemoryStream(data);
        }

        // Binary data with status (tuple return)
        public static (Stream Stream, DataStatus Status) FromDataWithStatus(Memory<byte> data){
            bool isZeroCopy = System.Runtime.InteropServices.MemoryMarshal.TryGetArray(
                (ReadOnlyMemory<byte>)data, out var segment);
            
            Stream stream;
            if (isZeroCopy)
            {
                stream = new MemoryStream(segment.Array!, segment.Offset, segment.Count);
            }
            else
            {
                byte[] bytes = data.ToArray();
                stream = new MemoryStream(bytes);
            }
            
            var status = new DataStatus{
                BytesProcessed = data.Length,
                IsZeroCopy = isZeroCopy
            };
            
            return (stream, status);
        }

    }
}

//  Status classes
// Container objects for operation metadata

// Represents status information for text encoding operations
// Immutable after creation to prevent accidental modifications
public class EncodingStatus
{
    // Number of characters that were processed from the input
    public int CharsProcessed { get; init; }

    // Number of bytes written to the stream after encoding
    // NOTE: Will differ from CharsProcessed based on encoding (e.g., UTF-8 vs UTF-32)
    public int BytesWritten { get; init; }

    // Name of the encoding that was used
    public string EncodingUsed { get; init; } = string.Empty;


    // Logging/debugging representation
    // Human-readable summary of the encoding operation
    public override string ToString() =>
        $"Encoded {CharsProcessed} chars to {BytesWritten} bytes using {EncodingUsed}";
}

// Represents status information for binary data operations
public class DataStatus
{
    // Number of bytes that were processed from the input
    public int BytesProcessed { get; init; }

    // Whether zero-copy optimization was used
    public bool IsZeroCopy { get; init; }

    public override string ToString() =>
        $"Processed {BytesProcessed} bytes, ZeroCopy: {IsZeroCopy}";
}

// Represents current stream operation statistics
public class StreamStatus
{
    // Total number of bytes read from the stream
    public long TotalBytesRead { get; set; }

    // Total number of bytes written to the stream
    public long TotalBytesWritten { get; set; }

    // Number of read operations performed
    public int ReadOperations { get; set; }

    // Number of write operations performed
    public int WriteOperations { get; set; }

    public override string ToString() =>
        $"Read: {TotalBytesRead} bytes ({ReadOperations} ops), Written: {TotalBytesWritten} bytes ({WriteOperations} ops)";
}

// Wrapper stream that tracks read/write operations
public class TrackedStream : Stream
{
    private readonly Stream _innerStream;
    private readonly object _initialStatus;
    private readonly StreamStatus _currentStatus;

    public TrackedStream(Stream innerStream, object initialStatus)
    {
        _innerStream = innerStream ?? throw new ArgumentNullException(nameof(innerStream));
        _initialStatus = initialStatus;
        _currentStatus = new StreamStatus();
    }

    public object InitialStatus => _initialStatus;
    public StreamStatus CurrentStatus => _currentStatus;

    public override bool CanRead => _innerStream.CanRead;
    public override bool CanSeek => _innerStream.CanSeek;
    public override bool CanWrite => _innerStream.CanWrite;
    public override long Length => _innerStream.Length;
    public override long Position
    {
        get => _innerStream.Position;
        set => _innerStream.Position = value;
    }

    public override void Flush() => _innerStream.Flush();

    public override int Read(byte[] buffer, int offset, int count)
    {
        int bytesRead = _innerStream.Read(buffer, offset, count);
        _currentStatus.TotalBytesRead += bytesRead;
        _currentStatus.ReadOperations++;
        return bytesRead;
    }

    public override long Seek(long offset, SeekOrigin origin) => _innerStream.Seek(offset, origin);

    public override void SetLength(long value) => _innerStream.SetLength(value);

    public override void Write(byte[] buffer, int offset, int count)
    {
        _innerStream.Write(buffer, offset, count);
        _currentStatus.TotalBytesWritten += count;
        _currentStatus.WriteOperations++;
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _innerStream?.Dispose();
        }
        base.Dispose(disposing);
    }
}
