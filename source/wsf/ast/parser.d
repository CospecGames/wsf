module wsf.ast.parser;
import wsf.ast.tag;
import wsf.streams.stream;
import wsf.common;

/**
    WSF parser
*/
struct Parser {
private:
    Stream stream;

    WSFTag readTag() {
        ubyte[] dat = new ubyte[1];
        stream.read(dat);
        return cast(WSFTag)dat[0];
    }

    WSFTag peekTag() {
        ubyte[] dat = new ubyte[1];
        stream.peek(dat);
        return cast(WSFTag)dat[0];
    }

    bool verifyMagicBytes() {
        ubyte[] strBuf = new ubyte[WSF_MAGIC_BYTES.length];
        stream.read(strBuf);
        return strBuf == WSF_MAGIC_BYTES;
    }

    uint parseLength() {
        ubyte[] len = new ubyte[4];
        stream.read(len);
        return decode!uint(len);
    }

    string parseEntryName() {
        uint len = parseLength();

        // Sequence entry value
        if (len == 0) return null;

        // Normal entry values
        ubyte[] strBuf = new ubyte[len];
        stream.read(strBuf);
        return cast(string)strBuf;
    }

    Tag parseValue() {
        switch(peekTag()) {
            case WSFTag.CompoundStart:
                Tag compound = Tag.emptyCompound();
                parseCompound(compound);
                return compound;

            case WSFTag.Array:
                Tag array = Tag.emptyArray();
                parseArray(array);
                return array;

            case WSFTag.String:
                readTag();
                uint len = parseLength();
                ubyte[] val = new ubyte[len];
                stream.read(val);
                return new Tag(cast(string)val);

            case WSFTag.Bool:
                readTag();
                ubyte[] val = new ubyte[1];
                stream.read(val);
                return new Tag(cast(bool)val[0]);

            case WSFTag.Int8:
                readTag();
                ubyte[] val = new ubyte[1];
                stream.read(val);
                return new Tag(val[0]);

            case WSFTag.Int16:
                readTag();
                ubyte[] val = new ubyte[2];
                stream.read(val);
                return new Tag(decode!ubyte(val));

            case WSFTag.Int32:
                readTag();
                ubyte[] val = new ubyte[4];
                stream.read(val);
                return new Tag(decode!uint(val));

            case WSFTag.Int64:
                readTag();
                ubyte[] val = new ubyte[8];
                stream.read(val);
                return new Tag(decode!ulong(val));

            case WSFTag.Floating:
                readTag();
                ubyte[] val = new ubyte[8];
                stream.read(val);
                return new Tag(decode!float(val));

            default: 
                throw new Exception("Unexpected tag");
        }
    }

    void parseEntry(ref Tag tag) {
        if (readTag() != WSFTag.Entry) throw new Exception("Expected entry!");

        string name = parseEntryName();
        if (name is null) {
            tag.seq() ~= parseValue();
        } else {
            tag[name] = parseValue();
        }
    }

    void parseArray(ref Tag tag) {
        if (readTag() != WSFTag.Array) throw new Exception("Expected entry!");
        uint len = parseLength();
        foreach(i; 0..len) {
            tag ~= parseValue();
        }
    }

    void parseCompound(ref Tag tag) {
        if (readTag() != WSFTag.CompoundStart) throw new Exception("Expected compound start!");
        while(peekTag() != WSFTag.CompoundEnd) {
            parseEntry(tag);
        }

        // Read end tag for compound
        readTag();
    }

public:
    this(Stream stream) {
        this.stream = stream;
        verifyMagicBytes();
    }

    /**
        Parse the WSF file from the stream
    */
    Tag parse() {
        Tag root = Tag.emptyCompound();
        parseCompound(root);
        return root;
    }
}


/**
    Parse the WSF file from the stream
*/
Tag parse(Stream stream) {
    return Parser(stream).parse();
}