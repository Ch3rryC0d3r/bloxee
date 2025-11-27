local config = {}

config.tilesets = {
    default = "assets/tileset_1.png",
    -- modders can add: custom = "mods/my_tileset.png"
}

-- Format: [id] = { tileset_pos = {x,y}, tileset = "default", solid = bool, on_col = function }
config.tiles = {
    [0] = { tileset_pos = {0,0}, tileset = "default", solid = true, name = "bricks" },
    [1] = { tileset_pos = {1,0}, tileset = "default", solid = false, name = "box_1" },
    [2] = { tileset_pos = {2,0}, tileset = "default", solid = false, name = "goal" },
    [7] = { tileset_pos = {0,1}, tileset = "default", solid = false, name = "floor" },
    [9] = { tileset_pos = {2,1}, tileset = "default", solid = false, name = "spawn" },
    [6] = { tileset_pos = {1,1}, tileset = "default", solid = false, name = "box_2" },
    -- colored bricks --
    [24] = { tileset_pos = {3,3}, tileset = "default", solid = true, name = "purple_bricks" },
    [31] = { tileset_pos = {3,4}, tileset = "default", solid = true, name = "green_bricks" },
    [32] = { tileset_pos = {4,4}, tileset = "default", solid = true, name = "red_bricks" },
    [25] = { tileset_pos = {4,3}, tileset = "default", solid = true, name = "blue_bricks" },
    [26] = { tileset_pos = {5,3}, tileset = "default", solid = true, name = "orange_bricks" },
    [18] = { tileset_pos = {4,2}, tileset = "default", solid = true, name = "brown_bricks" },
    [19] = { tileset_pos = {5,2}, tileset = "default", solid = true, name = "cyan_bricks" },
    [12] = { tileset_pos = {5,1}, tileset = "default", solid = true, name = "pink_bricks" },
    [5] = { tileset_pos = {5,0}, tileset = "default", solid = true, name = "yellow_bricks" },
    -- colored floor --
    [35] = { tileset_pos = {0,5}, tileset = "default", solid = false, name = "orange_floor" },
    [36] = { tileset_pos = {1,5}, tileset = "default", solid = false, name = "brown_floor" },
    [37] = { tileset_pos = {2,5}, tileset = "default", solid = false, name = "yellow_floor" },    
    [38] = { tileset_pos = {3,5}, tileset = "default", solid = false, name = "purple_floor" },
    [39] = { tileset_pos = {4,5}, tileset = "default", solid = false, name = "blue_floor" },
    [40] = { tileset_pos = {5,5}, tileset = "default", solid = false, name = "pink_floor" },
    [41] = { tileset_pos = {6,5}, tileset = "default", solid = false, name = "green_floor" },
    [42] = { tileset_pos = {0,6}, tileset = "default", solid = false, name = "red_floor" },
    [43] = { tileset_pos = {1,6}, tileset = "default", solid = false, name = "cyan_floor" },
}

-- Load custom blocks from block_defs.lua
local blockDefs = require "src.core.block_defs"
for name, block in pairs(blockDefs) do
    local tilesetPos = block.pos
    config.tiles[block.csv_id] = {
        csv_id = block.csv_id,
        tileset_pos = { tilesetPos.x, tilesetPos.y },
        boxSolid = block.boxSolid or false,
        tileset = block.tileset or "default",
        solid = block.solid or false,
        name = name,
        on_col = block.on_col,
        on_signal = block.on_signal,
        load = block.load,
        activate = block.activate,
        wire = block.wire
    }
end

-- LEVEL PROGRESSION
config.levels = {
    total = 2,
}

-- BADGE THRESHOLDS (platinum moves per level)
config.badges = {
    [1] = 21,
}

-- UI SETTINGS
config.ui = {
    screenWidth = 850,
    screenHeight = 450,
    tileSize = 32,
    fonts = {
        title = 48,
        menu = 32,
        small = 16,
    },
    colors = {
        text = {1, 1, 1},
        selected = {0, 1, 0},
        disabled = {0.5, 0.5, 0.5},
        badge = {0.6, 0.6, 0.6},
    }
}

return config