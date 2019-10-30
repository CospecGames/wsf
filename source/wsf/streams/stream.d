module wsf.streams.stream;
import std.stdio : SEEK_SET,  SEEK_END, SEEK_CUR;

/**
    Origin for stream seek operations
*/
enum StreamOrigin {
    Start = SEEK_SET,
    Cursor = SEEK_CUR,
    End = SEEK_END
}

/**
    A stream
*/
abstract class Stream {
public:
    /**
        Gets the position of the stream

        Convenience property for tell()
    */
    @property
    size_t position() {
        return tell();
    }

abstract:

    /**
        Gets wether the stream can be read from
    */
    @property
    bool canRead();

    /**
        Gets wether the stream can be written to
    */
    @property
    bool canWrite();
    /**
        Gets wether the stream is seekable
    */
    @property
    bool canSeek();

    /**
        Gets wether the stream is tellable
    */
    @property
    bool canTell();

    /**
        Gets wether the stream knows its length
    */
    @property
    bool knowsLength();

    /**
        Gets the length of the stream (if possible)
    */
    @property
    size_t length();

    /**
        Gets wether the end has been reached
    */
    @property
    bool eof();

    /**
        Reads the specified amount out to the buffer

        Returns the amount read, -1 if at end of stream
    */
    int read(ref ubyte[] buffer);

    /**
        Reads the specified amount out to the buffer

        Returns the amount read, -1 if at end of stream
    */
    int read(size_t amount, ref ubyte[] buffer);

    /**
        Peek the X amount of bytes from the current position
    */
    int peek(ref ubyte[] data);

    /**
        Writes the buffer to the stream
    */
    void write(ubyte[] buffer);

    /**
        Writes the buffer to the stream from the start position
    */
    void write(ubyte[] buffer, size_t start);

    /**
        Writes the buffer to the stream from the start position to the specified length
    */
    void write(ubyte[] buffer, size_t start, size_t length);

    /**
        Seek to a specified position in the stream
    */
    void seek(long position, StreamOrigin origin);

    /**
        Returns the position of the stream the cursor is at
    */
    ulong tell();

    /**
        Flushes and syncronizes the stream
    */
    void flush();

    /**
        Seeks back to start of stream
    */
    void rewind();

    /**
        Closes the stream
    */
    void close();
}