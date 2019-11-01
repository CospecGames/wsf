
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.ast.common;
import std.bitmanip;

/**
    The magic bytes for the WSF format
*/
const(ubyte[]) WSF_MAGIC_BYTES = cast(ubyte[])"WSF_DATA";

/**
    Encodes the value to little endian
*/
ubyte[] encode(T)(T value) {
    ubyte[] ovalue = new ubyte[T.sizeof];
    ovalue[] = nativeToLittleEndian!T(value)[0..ovalue.length];
    return ovalue;
}

/**
    Decodes the value from little-endian
*/
T decode(T)(ubyte[] value) {
    return littleEndianToNative!(T, T.sizeof)(cast(ubyte[T.sizeof])value[0..T.sizeof]);
}

/**
    Tags for deserializer to know type of sequence
*/
enum WSFTag : ubyte {
    /**
        Equivalent to null
    */
    Nothing             = 0x00,

    /**
        A byte
    */
    Int8                = 0x01,

    /**
        A short
    */
    Int16               = 0x02,

    /**
        A short
    */
    Int32               = 0x03,

    /**
        A short
    */
    Int64               = 0x04,

    /**
        A floating point number
    */
    Floating            = 0x05,

    /**
        A boolean
    */
    Bool                = 0x06,

    /**
        A string
    */
    String              = 0x07,

    /**
        An array of values
    */
    Array               = 0x20,

    /**
        An entry (key-value pair)
    */
    Entry               = 0x21,

    /**
        The start of a compound
    */
    CompoundStart       = 0xC8,

    /**
        The end of a compound
    */
    CompoundEnd         = 0xDC,

    /**
        A deserialized compound
    */
    Compound            = 0xFF
}