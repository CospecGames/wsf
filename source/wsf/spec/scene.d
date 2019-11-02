
//          Copyright Luna & Cospec 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

module wsf.spec.scene;

/**
    The scene in-game
*/
class Scene {
    /**
        Contains all the tilesets for this scene
    */
    Tileset[string] tilesets;

    /**
        Width of tiles
    */
    uint tileWidth;

    /**
        Height of tiles
    */
    uint tileHeight;

    /**
        The amount of tile slots in the X axis
    */
    uint tilesX;

    /**
        The amount of tile slots on the Y axis
    */
    uint tilesY;

    /**
        Layers

        index 0 = main layer
    */
    Layer[] layers;
}

/**
    A tileset
*/
struct Tileset {
    /**
        Width of tileset texture
    */
    uint width;

    /**
        Height of tileset texture
    */
    uint height;

    /**
        8-bit RGBA color data
    */
    ubyte[] data;
}

/**
    A layer
*/
class Layer {
    /**
        Contains all the tiles for this layer
    */
    Tile[] tiles;

    /**
        Wether to draw the layer infront or behind the main layer
    */
    LayerOrder order;
}

/**
    Draw order for layer
*/
enum LayerOrder : ubyte {
    Auto = 0,
    Background = 1,
    Foreground = 2
}

/**
    Tile flip
*/
enum TileFlip : ubyte {
    None,
    Horizontal = 1,
    Vertical = 3
}

/**
    A tile
*/
struct Tile {
    /**
        X coordinate of tile
    */
    uint x;

    /**
        T coordinate of tile
    */
    uint y;

    /**
        ID of tile
    */
    ubyte id;

    /**
        Which direction to flip tile
    */
    TileFlip flip;
}