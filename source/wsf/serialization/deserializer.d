
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.serialization.deserializer;
import wsf.serialization;
import wsf.ast;
import std.traits;
import std.format;
import std.range.primitives;
import std.stdio : writeln;

private {
    /*
        Creates empty class, struct or heap allocated struct
    */
    T newEmptyT(T)() {
        static if (isPointer!T) {
            static assert(is(PointerTarget!T == struct), "Pointer did not point to a struct!");
            return new PointerTarget!T;
        } else static if (is(T == class)) {
            pragma(msg, fullyQualifiedName!T);
            return new T();
        } else static if (is(T == struct)) {
            return *(new T);
        } else {
            static assert(0, "Cannot create empty "~T.stringof);
        }
    }

    void deserializeStructOrClass(T)(ref T object, ref Tag tag) {
        static if (hasStaticMember!(T, "deserialize")) {
            alias deserializerFunc = __traits(getMember, T, "deserialize");
            static if (is(Parameters!deserializerFunc[0] == T) && is(Parameters!deserializerFunc[1] == Tag)) {
                T.deserialize(object, tag);
            } else {
                static assert(0, "Invalid deserialization function! "~typeof(serializerFunc).stringof);
            }
        } else {
            foreach(memberName; FieldNameTuple!T) {

                alias member = __traits(getMember, object, memberName);
                enum protection = __traits(getProtection, member);
                static if (protection == "public" && !hasUDA!(member, ignore)) {
                    if (memberName !in tag) {
                        if (hasUDA!(member, optional)) continue;
                        else throw new Exception("Mandetory field "~memberName~" not present.");
                    }

                    // Handle sequences
                    static if (memberName == "seq") {
                        static if (is(member : Tag[])) {
                            __traits(getMember, object, memberName) = tag[memberName];
                        } else {
                            if ("seq_" !in tag) throw new Exception("A seq_ tag could not be found!");
                            deserializeArray!(typeof(member))(__traits(getMember, object, memberName), tag["seq_"]);
                        }
                    } else {
                        deserializeMember!(typeof(member))(__traits(getMember, object, memberName), tag[memberName]);
                    }
                }
            }
        }
    }

    void deserializeArray(T)(ref T object, ref Tag tag) {
        foreach(i; 0..object.length) {
            deserializeMember(object[i], tag[i]);
        }
    }

    void deserializeMember(T)(ref T object, ref Tag tag) {
        static if (is(T == class) || is(T == struct) || isPointer!T) {
            deserializeStructOrClass(object, tag);
        } else static if (isArray!T && !is(T : string)) {
            deserializeArray(object, tag);
        } else static if (is(object : Tag)) {
            object = tag;
        } else {
            object = tag.get!T;
        }
    }
}

/**
    Deserialize from a WSF tag
*/
T deserializeWSF(T)(Tag tag) {
    T val = newEmptyT!T;
    deserializeStructOrClass!T(val, tag);
    return val;
}