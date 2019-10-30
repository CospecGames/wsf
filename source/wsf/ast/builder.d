
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.ast.builder;
import wsf.ast.tag;
import wsf.streams.stream;
import wsf.common;

/**
    Struct capable of writing a WSF Tag sequence in to a Stream
*/
struct Builder {
private:
    Stream stream;
    Tag root;

    void writeTagIdForKind(ref Tag tag) {
        switch(tag.kind) {
            case TagKind.byte_: writeTagId(WSFTag.Int8); return;
            case TagKind.short_: writeTagId(WSFTag.Int16); return;
            case TagKind.int_: writeTagId(WSFTag.Int32); return;
            case TagKind.long_: writeTagId(WSFTag.Int64); return;
            case TagKind.double_: writeTagId(WSFTag.Floating); return;
            case TagKind.bool_: writeTagId(WSFTag.Bool); return;
            case TagKind.string_: writeTagId(WSFTag.String); return;
            default: throw new Exception("Unexpected tag type!");
        }
    }

    void writeTagId(WSFTag id) {
        stream.write([cast(ubyte)id]);
    }

    void writeString(string text) {
        ubyte[] textBuf = cast(ubyte[])text;
        stream.write(encode!uint(cast(uint)textBuf.length));
        stream.write(textBuf);
    }

    void buildValue(ref Tag tag) {
        switch(tag.kind()) {
            case TagKind.compound_:
                buildCompound(tag);
                return;
            
            case TagKind.array_:
                buildArray(tag);
                return;
            
            case TagKind.string_:
                writeTagIdForKind(tag);
                writeString(tag.get!string);
                return;

            case TagKind.bool_:
                writeTagIdForKind(tag);
                stream.write([tag.get!bool]);
                return;

            case TagKind.byte_:
                writeTagIdForKind(tag);
                stream.write([tag.get!ubyte]);
                return;

            case TagKind.short_:
                writeTagIdForKind(tag);
                stream.write(encode!ushort(tag.get!ushort));
                return;

            case TagKind.int_:
                writeTagIdForKind(tag);
                stream.write(encode!uint(tag.get!uint));
                return;

            case TagKind.long_:
                writeTagIdForKind(tag);
                stream.write(encode!ulong(tag.get!ulong));
                return;

            case TagKind.double_:
                writeTagIdForKind(tag);
                stream.write(encode!double(tag.get!double));
                return;

            default: throw new Exception("Unexpected tag!");

        }
    }

    void buildArray(ref Tag tag) {
        writeTagId(WSFTag.Array);
        stream.write(encode!uint(cast(uint)tag.length));
        foreach(member; tag) {
            buildValue(member);
        }
    }

    void buildEntry(string key, ref Tag tag) {
        writeTagId(WSFTag.Entry);
        writeString(key);
        buildValue(tag);
    }

    void buildSeq(ref Tag[] seq) {
        foreach(child; seq) {
            writeTagId(WSFTag.Entry);
            stream.write(encode!uint(0));
            buildValue(child);
        }
    }

    void buildCompound(ref Tag tag) {
        if (!tag.isKindCompound) throw new Exception("Expected compound tag!");
        writeTagId(WSFTag.CompoundStart);

        foreach(string name, child; tag) {
            // Put sequential types AFTER the main types
            if (name == "seq") continue;

            buildEntry(name, child);

        }

        buildSeq(tag.seq);

        writeTagId(WSFTag.CompoundEnd);
    }

public:
    this(Stream stream, Tag root) {
        this.stream = stream;
        this.root = root;
    }

    void build() {
        stream.write(cast(ubyte[])WSF_MAGIC_BYTES);
        buildCompound(root);
        stream.flush();
    }
}

/**
    Builds the WSF sequence and writes it to the stream
*/
void build(Tag root, Stream toStream) {
    Builder(toStream, root).build();
}