
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.streams.filestream;
import std.stdio;
import wsf.streams.stream;

/**
    A stream that reads/writes to a file
*/
class FileStream : Stream {
private:
    File file;
    size_t _length;
    bool open = true;

public:
    
    override {
        @property bool canRead() { return true; }
        @property bool canWrite() { return true; }
        @property bool canSeek() { return true; }
        @property bool canTell() { return true; }
        @property bool knowsLength() { return true; }
        @property size_t length() { return _length; }
        @property bool eof() { return file.eof; }
    }

    this(File file) {
        this.file = file;

        // Get length of file
        this.seek(0, StreamOrigin.End);
        this._length = position;

        // Rewind back
        this.rewind();
    }

    ~this() {
        if (file.isOpen) {
            flush();
            close();
        }
    }

    override {

        int read(ref ubyte[] buffer) {
            size_t len = file.rawRead(buffer).length;

            if (file.eof) return -1;
            return cast(int)len;
        }

        int read(size_t amount, ref ubyte[] buffer) {
            size_t len = file.rawRead(buffer[0..amount]).length;

            if (file.eof) return -1;
            return cast(int)len;
        }

        int peek(ref ubyte[] data) {
            
            // Seek back to origin after peek
            ulong pos = tell();
            scope(exit) seek(pos, StreamOrigin.Start);

            // Read and return the peek
            return this.read(data);
        }

        void write(ubyte[] buffer) {
            file.rawWrite(buffer);
        }

        void write(ubyte[] buffer, size_t start) {
            file.rawWrite(buffer[start..$]);
        }

        void write(ubyte[] buffer, size_t start, size_t length) {
            file.rawWrite(buffer[start..start+length]);
        }
        
        void seek(long position, StreamOrigin origin) {
            file.seek(position, origin);
        }

        ulong tell() {
            return file.tell();
        }

        void flush() {
            file.flush();
            file.sync();
        }

        void rewind() {
            file.rewind();
        }

        void close() {
            file.close();
        }

    }
}