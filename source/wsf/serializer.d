
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.serializer;
import wsf.ast;
import std.traits;
import std.format;

/**
    UDA

    Marks field to be ignored
*/
enum ignore;

private {
    void serializeClassOrStruct(T)(T data, ref Tag tag) {
        static if (__traits(hasMember, T, "serialize")) {
                alias serializerFunc = __traits(getMember, data, "serialize");
                static if (is(Parameters!serializerFunc[0] == Tag)) {
                    data.serialize(tag);
                } else {
                    static assert(0, "Invalid serialization function! "~typeof(serializerFunc).stringof);
                }
        } else {
            
            // Automatic serialization
            foreach(memberName; FieldNameTuple!T) {
                
                // Get member and protection level of that member
                alias member = __traits(getMember, data, memberName);
                enum protection = __traits(getProtection, member);

                // Only allow public members that aren't ignored
                static if (protection == "public" && !hasUDA!(member, ignore)) {
                    static if (memberName == "seq") {
                        static if (!is(typeof(member) : Tag[])) {
                            pragma(msg, "WARNING: %s %s collides with WSF seq tag, renaming to seq_".format(typeof(member).stringof, memberName));
                            tag["seq_"] = new Tag(__traits(getMember, data, memberName));
                        } else {
                            pragma(msg, "seq tag mapped to Tag[] array named 'seq'.");
                            tag[memberName] = new Tag(__traits(getMember, data, memberName));
                        }
                    } else {
                        tag[memberName] = new Tag(__traits(getMember, data, memberName));
                    }
                }
            }
        }
    }
}

/**
    Serializes a class or struct

    You can ignore a field with the @ignore UDA
    
    Properties will not be serialized.

    Create function with `void serialize(ref Tag tag)` signature to do custom serialization
*/
Tag serializeWSF(T)(T data) if (is(T == class) || is(T == struct)) {
    Tag tag = Tag.emptyCompound();
    serializeClassOrStruct!T(data, tag);
    return tag;
}