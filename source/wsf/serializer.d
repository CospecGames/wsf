module wsf.serializer;
import wsf.streams.stream;
import wsf.common;
import std.traits;
import std.range.primitives;
import std.bitmanip;
import std.conv;
import std.format;

/**
    Interfaces for classes implementing serialization
*/
interface ISerializable {
    /**
        Serializes using the specified serializer
    */
    void serialize(Serializer serializer);
}

/**
    The WSF serializer
*/
final class Serializer {
private:
    bool hasStarted = false;

    Stream stream;

    void writeTagForType(T)() {
        static if (is(T == ubyte) || is(T == byte)) {
            stream.write([WSFTag.Int8]);
        } else static if (is(T == ushort) || is(T == short)) {
            stream.write([WSFTag.Int16]);
        } else static if (is(T == uint) || is(T == int)) {
            stream.write([WSFTag.Int32]);
        } else static if (is(T == ulong) || is(T == long)) {
            stream.write([WSFTag.Int64]);
        } else static if (isFloatingPoint!T) {
            stream.write([WSFTag.Floating]);
        } else static if (is(T == bool)) {
            stream.write([WSFTag.Bool]);
        } else static if (is(T : string)) {
            stream.write([WSFTag.String]);
        }
    }

    void serializeBasicType(T, bool addTag = true)(T value) {

        if (addTag) writeTagForType!T;

        static if(isFloatingPoint!T) {

            // Only support doubles, floats get converted.
            stream.write(encode(cast(double)value));

        } else {

            // If type is longer than 1 byte we'll need to ensure endianess
            static if (T.sizeof > 1) stream.write(encode(value));
            else stream.write([cast(ubyte)value]);

        }
    }

    void serializeString(string text, bool addTag = true) {
        if (addTag) stream.write([WSFTag.String]);

        ubyte[] texBuff = cast(ubyte[])text;

        stream.write(encode!uint(cast(uint)texBuff.length));
        stream.write(texBuff);
    }

    void serializeType(T, bool addTag = true)(T value) {

        static if (is(T == class) || is(T == struct) || (is(PointerTarget!T == class) || is(PointerTarget!T == struct))) {

            static if (__traits(hasMember, T, "serialize")) {

                stream.write([WSFTag.CompoundStart]);

                static if (is(Parameters!(__traits(getMember, T, "serialize"))[0] : Serializer)) {
                    
                    value.serialize(this);
                
                } else {
                    
                    static assert(0, "Could not find a serialize(ref Serializer) function for "~value.stringof);
                
                }
                
                stream.write([WSFTag.CompoundEnd]);
            
            } else {

                static assert(0, "Could not find a serialize(ref WSFSerializer) function for "~value.stringof);
            
            }
        } else static if (is(T : string)) {
            if (value is null) {
                this.serializeNothing();
            } else {
                this.serializeString(value); 
            }   
        } else static if (isArray!T) {
            if (value is null) {
                this.serializeNothing();
            } else {
                this.serializeArray!T(value);
            }
        } else {
            static if (is(T == class) || isPointer!T) {
                if (value is null) {
                    this.serializeNothing();
                } else {
                    this.serializeBasicType!T(value);
                }
            } else {
                this.serializeBasicType!T(value);
            }
        }
    }

    void serializeArray(T)(T array, int depth = 0) if (isArray!T) {
        // Write type and length
        stream.write([WSFTag.Array]);
        stream.write(encode!uint(cast(uint)array.length));

        foreach(member; array) {

            this.serializeType!(ElementType!T, false)(member);
        }
    }

    void serializeEntry(T)(string key, T value) {
        stream.write([WSFTag.Entry]);

        if (key.length > 0) {
            this.serializeString(key, false);
        } else {
            // If key length is 0 then the format should take it as a sequential value
            // Sequential values should be able to be moved between with next/prev functions.
            stream.write(encode!uint(0));
        }
        this.serializeType!T(value);
    }

    void serializeNothing() {
        stream.write([WSFTag.Nothing]);
    }

public:
    /**
        The key used to sign this file.

        Leave empty to not sign the file, but just generate a hash
    */
    string signKey;

    this(string file) {
        import std.stdio : File;
        import wsf.streams.filestream : FileStream;
        this(new FileStream(File(file, "w")));
    }

    this(Stream stream) {
        this.stream = stream;
        stream.write(cast(ubyte[])WSF_MAGIC_BYTES);
    }

    ~this() {
        stream.close();
    }

    /**
        Serialize value, writing it to the stream
    */
    void serialize(T)(T value, string key = "") {
        if (!hasStarted) throw new Exception("Serialization hasn't begun! call begin() to start, end() to end.");

        this.serializeEntry!T(key, value);

    }

    /**
        Start serializing
    */
    void begin() {
        hasStarted = true;
        stream.write([WSFTag.CompoundStart]);
    }

    /**
        Finish the serialization off by writing down a signature/hash over the file's contents
    */
    void end() {
        stream.write([WSFTag.CompoundEnd]);
        stream.flush();
    }
}