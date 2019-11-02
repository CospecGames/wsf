
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.serialization;
public import wsf.serialization.serializer : serializeWSF;
public import wsf.serialization.deserializer : deserializeWSF;
public import wsf.ast.tag;

/**
    UDA

    Marks field to be ignored
*/
enum ignore;

/**
    UDA

    Marks field as optional
*/
enum optional;


//
// Unit-test territory
//

private struct TestStruct {
private:
    int privateTest = 128;

    struct iStruct {
        ubyte b = 0;
    }

public:

    enum TestEnum {
        A = 0,
        B = 1
    }

    @ignore
    int ignoredTest = 42;

    @optional
    string optionalTest = "optional value";

    @optional
    iStruct internalStruct;

    int intValue = 0;

    string stringValue = "Test";

    int[] arrA = [0, 0, 0, 0];
    int[][] matrix = [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0]
    ];

    string[string] aa;

    TestEnum enm;

}

unittest {
    import std.stdio : writeln;
    TestStruct* strct = new TestStruct;
    strct.matrix[0][0] = 1;
    strct.aa = [
        "Test": "test",
        "TestB": "test b"
    ];
    strct.enm = TestStruct.TestEnum.B;

    Tag serialized = serializeWSF(strct);
    TestStruct deserialized = deserializeWSF!TestStruct(serialized);
    assert(*strct == deserialized, "Outputs did not match!");
}