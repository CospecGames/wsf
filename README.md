# WereShift Format
A D binary serialization format made for the game "Wereshift".
It can be used elsewhere as a small binary format.


## Parsing file
```d
Tag data = Tag.parseFile("file.wsf");
writeln(data["foo"]);
writeln(data.seq[0]);
```

## Building file
```d
Tag myData = Tag.emptyCompound();
myData["foo"] = "bar";
myData.seq ~= new Tag("baz");

// Note: this will overwrite the contents of the file
myData.buildFile("file.wsf");
```

## Serialize struct
```d
struct MyData {
    int x;
    string y;
}

// Works for: Structs, classes and pointers to structs
Tag tag = serializeWSF(MyData(42, "Meaning of Life"));
writeln(tag.toString());
```

## Deserialize
```d
struct MyData {
    int x;
    string y;
}

// Works for: Structs, classes and pointers to structs
MyData data = deserializeWSF!MyData(Tag.parseFile("importantData.wsf"));
```

## Notes
TODO
 * Memory based streams
 * C interface(?)