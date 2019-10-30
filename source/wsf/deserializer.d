module wsf.deserializer;
import wsf.streams.stream;
import wsf.common;
import wsf.tag;
import std.bitmanip;

/**
    Interface for deserializable classes
*/
interface IDeserializable {

    /**
        Deserialize object via deserialization stream
    */
    static IDeserializable deserialize(ref Deserializer deserializer);
}

final class Deserializer {
private:


public:
}