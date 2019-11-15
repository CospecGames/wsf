
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.serialization.serializer;
import wsf.serialization;
import wsf.ast;
import std.traits;
import std.format;
import std.range.primitives;

private {
    void serializeClassOrStruct(T)(T data, ref Tag tag) {

        static if (!is(T == class) && !is(T == struct) && !isPointer!T) {
            static assert(0, "Input value was not a class, a struct or a pointer to either.");
        }

        static if (is(T == class) || isPointer!T) {
            if (data is null) return;
        }

        static if (isPointer!T) {
            // Handle pointers
            serializeClassOrStruct!(PointerTarget!T)(*data, tag);
        } else {
            
            //Handle structs or classes
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
                    static if (!hasUDA!(member, ignore)) {
                        static if (memberName == "seq") {

                            // WSF has a seq tag used for sequential data, if our types match up then we can just use the Tag[] array as a frontend to wsf seq
                            // Otherwise we should move it to a seq_ tag instead.
                            static if (is(typeof(member) : Tag[])) {
                                pragma(msg, "seq tag mapped to Tag[] array named 'seq'.");
                                tag[memberName] = __traits(getMember, data, memberName);
                            } else {
                                pragma(msg, "WARNING: %s %s collides with WSF seq tag, renaming to seq_".format(typeof(member).stringof, memberName));
                                serializeMember!(typeof(member))(__traits(getMember, data, memberName), tag, "seq_");
                            }
                        } else {
                            serializeMember!(typeof(member))(__traits(getMember, data, memberName), tag, memberName);
                        }
                    }
                }
            }
        }
    }

    void serializeAA(T)(T array, ref Tag tag) {
        foreach(name, member; array) {
            static if (is(typeof(member) == class) || isPointer!(typeof(member)) || is(typeof(member) == string)) {
                if (member is null) continue;
            }
            serializeMember!(typeof(member))(member, tag, name);
        }
    }

    void serializeArray(T)(T array, ref Tag tag) {
        static if(isArray!(ElementType!T)){
            
            // Handle multidimensional arrays
            foreach(element; array) {
                //Serialize arrays
                Tag subTag = Tag.emptyArray();
                serializeArray(element, subTag);
                tag ~= subTag;
            }

        } else {

            // Handle final array values
            foreach(element; array) {
                static if (is(ElementType!T == class) || isPointer!(ElementType!T) || is(ElementType!T == string)) {
                    if (element is null) continue;
                }

                serializeMember!(typeof(element), true)(element, tag);

            }

        }
    }

    void serializeValue(T)(T data, ref Tag tag) {
        tag = new Tag(data);
    }

    void serializeMember(T, bool array = false)(T data, ref Tag tag, string memberName = "") {
        
        static if (isPointer!T) {

            // Handle pointers
            serializeMember!(PointerTarget!T, memberName, array)(*data, tag);

        } else static if (is(T == class) || is(T == struct) || isPointer!T) {

            // Serialize other class types
            Tag subTag = Tag.emptyCompound();
            serializeClassOrStruct(data, subTag);
            static if (array) {
                tag ~= subTag;
            } else {
                tag[memberName] = subTag;
            }

        } else static if (isAssociativeArray!T) {
            Tag subTag = Tag.emptyCompound();
            serializeAA(data, subTag);
            static if (array) {
                tag ~= subTag;
            } else {
                tag[memberName] = subTag;
            }
        } else static if(isArray!T && !is(T : string)) {

            //Serialize arrays
            Tag subTag = Tag.emptyArray();
            serializeArray(data, subTag);
            static if (array) {
                tag ~= subTag;
            } else {
                tag[memberName] = subTag;
            }

        } else {

            // Try to serialize everything else
            static if (array) {

                tag ~= new Tag();
                serializeValue(data, tag[tag.length-1]);

            } else {

                tag[memberName] = new Tag();
                serializeValue(data, tag[memberName]);

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
Tag serializeWSF(T)(T data) if (is(T == class) || is(T == struct) || isPointer!T) {
    Tag tag = new Tag();
    static if (is(T == class) || is(T == struct) || isPointer!T) {
        tag = Tag.emptyCompound();
        serializeClassOrStruct!T(data, tag);
    } else static if(isAssociativeArray!T) {
        tag = Tag.emptyCompound();
        serializeAA!T(data, tag);
    } else static if (isArray!T && !is(T : string)) {
        tag = Tag.emptyArray();
        serializeArray!T(data, tag);
    } else {
        serializeValue!T(data, tag);
    }
    return tag;
}