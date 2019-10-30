module wsf.ast;
public import wsf.ast.builder;
public import wsf.ast.parser;
public import wsf.ast.tag;
import std.stdio;

unittest {
    Tag myTag = Tag.emptyCompound();
    myTag["test"] = "Test";
    myTag.buildFile("test.bin");

    Tag readTag = Tag.parseFile("test.bin");
    assert(myTag["test"] != readTag["test"], "Tags did not match!");
}