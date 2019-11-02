
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.ast.tag;
import taggedalgebraic.taggedunion;
import std.traits;
import wsf.ast.parser;
import wsf.ast.builder;


private alias TagValue = TaggedUnion!WSFTagValue;
private union WSFTagValue {
    ubyte byte_;
    ushort short_;
    uint int_;
    ulong long_;
    double double_;
    bool bool_;
    string string_;
    Tag[string] compound_;
    Tag[] array_;
}

/**
    The kind of WSF tag
*/
enum TagKind {
    byte_ = TagValue.Kind.byte_,
    short_ = TagValue.Kind.short_,
    int_ = TagValue.Kind.int_,
    long_ = TagValue.Kind.long_,
    double_ = TagValue.Kind.double_,
    bool_ = TagValue.Kind.bool_,
    string_ = TagValue.Kind.string_,
    compound_ = TagValue.Kind.compound_,
    array_ = TagValue.Kind.array_
}

class Tag {
private:
    TagValue value;

public:

    /**
        Parse from WSF file
    */
    static Tag parseFile(string file) {
        import wsf.streams.filestream : FileStream;
        import std.stdio : File;
        FileStream stream = new FileStream(File(file, "r"));
        scope(exit) stream.close();
        return parse(stream);
    }

    /**
        Parse from WSF file
    */
    void buildFile(string file) {
        import wsf.streams.filestream : FileStream;
        import std.stdio : File;
        FileStream stream = new FileStream(File(file, "w"));
        scope(exit) stream.close();
        return build(this, stream);
    }

    /**
        Gets wether this tag is a compound
    */
    @property
    bool isKindCompound() {
        return kind() == TagKind.compound_;
    }

    /**
        Gets wether this tag is an array
    */
    @property
    bool isKindArray() {
        return kind() == TagKind.array_;
    }

    /**
        Gets wether this tag is a value tag (not a compound or array)
    */
    @property
    bool isKindValue() {
        return !isKindCompound() && !isKindArray();
    }

    this(T)(T value) if (isNumeric!T || is(T == bool) || is(T : string)) {
        this.value = value;
    }

    this(T)(T value) if (is(T : Tag[])) {
        this.value = Tag[].init;
    }

    this(T)(T value) if (is(T : Tag[string])) {
        this.value = cast(Tag[string])value;
    }

    this(T)(T value) if (is(T : TagValue)) {
        this.value = value;
    }

    this(T)(T value) if (is(T : Tag)) {
        this.value = value.value;
    }

    /**
        Construct all other arrays
    */
    this(T)(T value) if (isArray!T && !is(T : Tag[]) && !is(T : string)) {
        this.value = cast(Tag[])[];
        foreach(tagval; value) {
            this.value.array_Value ~= new Tag(tagval);
        }
    }

    static {
        Tag emptyCompound() { return new Tag(cast(Tag[string])null); }
        Tag emptyArray() { return new Tag(cast(Tag[])[]); }
    }

    /**
        foreach for Tag param
    */
    int opApply(int delegate(ref Tag) operations) {
        size_t result = 0;

        if (kind == TagKind.array_) {
            foreach(Tag tag; this.value.array_Value) {
                result = operations(tag);

                if (result) {
                    break;
                }
            }
        } else if (kind == TagKind.compound_) {
            foreach(Tag tag; this.value.compound_Value) {
                result = operations(tag);

                if (result) {
                    break;
                }
            }
        } else {
            throw new Exception("Tag was neither an array or a compound.");
        }

        

        return 0;
    }

    /**
        foreach for int and Tag param
    */
    int opApply(int delegate(ref size_t, ref Tag) operations) {
        size_t result = 0;

        foreach(size_t i, Tag tag; this.value.array_Value) {
            result = operations(i, tag);

            if (result) {
                break;
            }
        }

        return 0;
    }

    /**
        foreach for int and Tag param
    */
    int opApply(int delegate(ref string, ref Tag) operations) {
        size_t result = 0;

        foreach(string i, Tag tag; this.value.compound_Value) {
            result = operations(i, tag);

            if (result) {
                break;
            }
        }

        return 0;
    }

    ref Tag opIndex(T)(T index) {
        static if (is(T : string)) {
            if (kind != TagKind.compound_) throw new Exception("Tag is not a compound!");
            return this.value.compound_Value[index];
        } else static if (isNumeric!T) {
            if (kind != TagKind.array_) throw new Exception("Tag is not an array!");
            return this.value.array_Value[index];
        } else {
            throw new Exception("Type is not indexable!");
        }
    }

    Tag* opBinaryRight(string op = "in")(string index) {
        if (kind != TagKind.compound_) throw new Exception("Tag is not a compound!");
        return index in this.value.compound_Value;
    }

    /**
        Assign value at index
    */
    void opIndexAssign(T, Y)(T value, Y index) {
        static if (is(Y : string)) {
            if (kind != TagKind.compound_) throw new Exception("Tag is not a compound!");
            this.value.compound_Value[index] = new Tag(value);
        } else static if (isNumeric!Y) {
            if (kind != TagKind.array_) throw new Exception("Tag is not an array!");
            this.value.array_Value[index] = new Tag(value);
        } else {
            throw new Exception("Type is not indexable!");
        }
    }

    /**
        Assign value at index
    */
    void opOpAssign(string op = "~=", T)(T value) {
        if (kind == TagKind.array_) {
            static if (is (T : Tag)) {
                this.value.array_Value ~= value;
            } else {
                this.value.array_Value ~= new Tag(value);
            }
            return;
        }
        static if (is(T : string)) {
            if (kind == TagKind.string_) {
                this.value.string_Value ~= value;
            }
            return;
        }
        throw new Exception("Type not appendable! (not array or string)");
    }

    /**
        Gets the kind of the object
    */
    TagKind kind() {
        return cast(TagKind)value.kind;
    }

    /**
        Gets the value of the object
    */
    inout(T) get(T)() inout @property @trusted {
        static if (is(T == byte) || is(T == ubyte)) {
            return cast(T)value.byte_Value;
        } else static if (is(T == short) || is(T == ushort)) {
            return cast(T)value.short_Value;
        } else static if (is(T == int) || is(T == uint)) {
            return cast(T)value.int_Value;
        } else static if (is(T == long) || is(T == ulong)) {
            return cast(T)(value.long_Value);
        } else static if (isFloatingPoint!T) {
            return cast(T)value.double_Value;
        } else static if (isBoolean!T) {
            return cast(T)value.bool_Value;
        } else static if (is(T == Tag[])) {
            return cast(T)value.array_Value;
        } else static if (is(T == Tag[string])) {
            return cast(T)value.compound_Value;
        } else static if (is(T == string)) {
            return cast(T)value.string_Value;
        } else static if (is(T == enum)) {
            return cast(T)this.get!(OriginalType!T);
        } else {
            assert(0, "Unable to handle type!");
        }
    }

    /**
        Gets the compound's sequence
    */
    ref Tag[] seq() {
        if (kind != TagKind.compound_) throw new Exception("Tag is not a compound!");
        if ("seq" !in value.compound_Value) {
            this["seq"] = Tag.emptyArray();
        }
        return this["seq"].value.array_Value;
    }

    /**
        Gets the array for this tag
    */
    ref Tag[] array() {
        if (kind != TagKind.array_) throw new Exception("Tag is not an array!");
        return this.value.array_Value;
    }

    /**
        Gets the compound for this tag
    */
    ref Tag[string] compound() {
        if (kind != TagKind.compound_) throw new Exception("Tag is not a compound!");
        return this.value.compound_Value;
    }

    @property
    size_t length() {
        if (kind == TagKind.array_) {
            return get!(Tag[]).length;
        }
        if (kind == TagKind.compound_) {
            return get!(Tag[string]).length;
        }
        return 0;
    }

    override
    string toString() {
        import std.conv : text;
        switch(kind) {
            case TagKind.compound_:     return this.get!(Tag[string]).text;
            case TagKind.array_:        return this.get!(Tag[]).text;
            case TagKind.double_:       return this.get!double.text;
            case TagKind.string_:       return "\""~this.get!string~"\"";
            case TagKind.bool_:         return this.get!bool.text;
            case TagKind.byte_:         return (cast(long)this.get!byte).text;
            case TagKind.short_:        return (cast(long)this.get!short).text;
            case TagKind.int_:          return (cast(long)this.get!int).text;
            case TagKind.long_:         return (cast(long)this.get!long).text;
            default: return value.text;
        }
    }
}