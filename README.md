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

## Notes
TODO
 * Memory based streams
 * Proper struct/class serialization via interface
 * C interface(?)