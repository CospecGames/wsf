
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.spec.scene;

// TODO: Implement

class Scene {
    Tileset[string] tilesets;
}

struct Tileset {
    uint width;
    uint height;
    ubyte[] data;
}

class Layer {
    
}

enum TileFlip : ubyte {
    None,
    Horizontal = 1,
    Vertical = 3
}

struct Tile {
    ubyte id;
    TileFlip flip;
}