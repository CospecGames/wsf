
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
                    static if (protection == "public" && !hasUDA!(member, ignore)) {
                        static if (memberName == "seq") {

                            // WSF has a seq tag used for sequential data, if our types match up then we can just use the Tag[] array as a frontend to wsf seq
                            // Otherwise we should move it to a seq_ tag instead.
                            static if (is(typeof(member) : Tag[])) {
                                pragma(msg, "seq tag mapped to Tag[] array named 'seq'.");
                                tag[memberName] = __traits(getMember, data, memberName);
                            } else {
                                pragma(msg, "WARNING: %s %s collides with WSF seq tag, renaming to seq_".format(typeof(member).stringof, memberName));
                                tag["seq_"] = new Tag(__traits(getMember, data, memberName));
                            }
                        } else {
                            serializeMember!(typeof(member), memberName)(__traits(getMember, data, memberName), tag);
                        }
                    }
                }
            }
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

                serializeMember!(typeof(element), "", true)(element, tag);

            }

        }
    }

    void serializeMember(T, string memberName, bool array = false)(T data, ref Tag tag) {
        
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

                tag ~= new Tag(data);

            } else {

                tag[memberName] = new Tag(data);

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
    Tag tag = Tag.emptyCompound();
    serializeClassOrStruct!T(data, tag);
    return tag;
}