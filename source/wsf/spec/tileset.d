module wsf.spec.tileset;
import wsf.serialization;

/**
    A region corrsponding to a file in the tileset
*/
struct TileRegion {
    /**
        The origin file
    */
    string file;

    /**
        Where the tile region starts
    */
    int x;

    /**
        Where the tile region starts
    */
    int y;

    /**
        Width of tile region
    */
    int width;

    /**
        Height of tile region
    */
    int height;
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

    /**
        Tile information
    */
    TileInfo[] info;

    /**
        Loaded tile regions
    */
    @optional
    TileRegion[] regions;

    /**
        Scrub the region of contents
    */
    void scrubRegions() {
        regions = [];
    }
}

/**
    Information about a tile
*/
struct TileInfo {
    /**
        Numeric id of tile
    */
    uint id;

    /**
        Human readable name
    */
    @optional
    string name = "%d";

    /**
        Collission data for tile
    */
    ubyte[][] collissionData;

}