local blocks = {}

local function validateBlock(block)
    if type(block.solid) == "table" and block.boxSolid then
        error("Block cannot have directional solid AND boxSolid at the same time!")
    end
    if type(block.boxSolid) == "table" and block.solid then
        error("Block cannot have directional boxSolid AND solid at the same time!")
    end
end

blocks.ice = {
    solid = false,
    tileset = "default",
    pos = { x = 1, y = 2 },

    on_col = function()
        BLOX.PLR.canMove = false
        local dir = {BLOX.PLR.lastMoveDir[1], BLOX.PLR.lastMoveDir[2]}

        local function slideStep()
            BLOX.PLR:move(dir, false)
            if BLOX.PLR.hitSolid then
                BLOX.PLR.canMove = true
                return
            end
            delay(0.1, slideStep)
        end

        delay(0.1, slideStep)
    end,
}

blocks.no_box = {
    solid = false,
    boxSolid = true,
    tileset = "default",
    pos = { x = 2, y = 2 },
}

blocks.only_up = {
    solid = {up=false, down=true, right=true, left=true},
    tileset = "default",
    pos = { x = 1, y = 3 },
}

blocks.only_down = {
    solid = {up=true, down=false, right=true, left=true},
    tileset = "default",
    pos = { x = 0, y = 3 },
}

blocks.only_left = {
    solid = {up=true, down=true, right=true, left=false},
    tileset = "default",
    pos = { x = 2, y = 3 },
}

blocks.only_right = {
    solid = {up=true, down=true, right=false, left=true},
    tileset = "default",
    pos = { x = 0, y = 4 },
}

blocks.button = {
    solid = false,
    pos = {x=0, y=8},
    on_col = function(self, map)
        local x, y = BLOX.PLR.x, BLOX.PLR.y
        map:activateWiresAt(x, y)
    end
}

-- DOORS
blocks.door_up = {
    solid = true,
    boxSolid = true,
    tileset = "default",
    pos = {x=1, y=10},
    activate = function(self, map)
        map.grid_front[self.y][self.x] = (0+(9*7))+1 
    end
}

blocks.door_left = {
    solid = false,
    boxSolid = false,
    tileset = "default",
    pos = {x=0, y=9},
    activate = function(self, map)
        map.grid_front[self.y][self.x] = (1+(10*7))+1 
    end
}

blocks.door_right = {
    solid = true,
    boxSolid = true,
    tileset = "default",
    pos = {x=1, y=9},
    activate = function(self, map)
        map.grid_front[self.y][self.x] = (0+(10*7))+1
    end
}

blocks.door_down = {
    solid = false,
    boxSolid = false,
    tileset = "default",
    pos = {x=0, y=10},
    activate = function(self, map)
        map.grid_front[self.y][self.x] = (1+(9*7))+1
    end
}
-- WIRES

blocks.wire_001 = {
    solid = false,
    tileset = "default",
    pos = {x=0, y=7},
    wire = {up=false, down=true, left=false, right=true}
}
blocks.wire_002 = {
    solid = false,
    tileset = "default",
    pos = {x=1, y=7},
    wire = {up=false, down=true, left=true, right=false}
}
blocks.wire_003 = {
    solid = false,
    tileset = "default",
    pos = {x=2, y=7},
    wire = {up=true, down=false, left=false, right=true}
}
blocks.wire_004 = {
    solid = false,
    tileset = "default",
    pos = {x=3, y=7},
    wire = {up=false, down=false, left=true, right=true}
}
blocks.wire_005 = {
    solid = false,
    tileset = "default",
    pos = {x=4, y=7},
    wire = {up=true, down=false, left=true, right=false}
}
blocks.wire_006 = {
    solid = false,
    tileset = "default",
    pos = {x=5, y=7},
    wire = {up=true, down=true, left=false, right=false}
}
blocks.wire_007 = {
    solid = false,
    tileset = "default",
    pos = {x=6, y=7},
    wire = {up=true, down=true, left=false, right=true}
}
blocks.wire_008 = {
    solid = false,
    tileset = "default",
    pos = {x=2, y=8},
    wire = {up=true, down=false, left=false, right=true}
}
blocks.wire_009 = {
    solid = false,
    tileset = "default",
    pos = {x=3, y=8},
    wire = {up=false, down=false, left=true, right=true}
}
blocks.wire_010 = {
    solid = false,
    tileset = "default",
    pos = {x=4, y=8},
    wire = {up=true, down=false, left=true, right=false}
}
blocks.wire_011 = {
    solid = false,
    tileset = "default",
    pos = {x=5, y=8},
    wire = {up=false, down=true, left=true, right=true}
}
blocks.wire_012 = {
    solid = false,
    tileset = "default",
    pos = {x=6, y=8},
    wire = {up=true, down=true, left=true, right=false}
}
blocks.wire_013 = {
    solid = false,
    tileset = "default",
    pos = {x=2, y=9},
    wire = {up=false, down=true, left=false, right=true}
}
blocks.wire_014 = {
    solid = false,
    tileset = "default",
    pos = {x=3, y=9},
    wire = {up=false, down=false, left=true, right=true}
}
blocks.wire_015 = {
    solid = false,
    tileset = "default",
    pos = {x=4, y=9},
    wire = {up=false, down=true, left=true, right=false}
}
blocks.wire_016 = {
    solid = false,
    tileset = "default",
    pos = {x=5, y=9},
    wire = {up=true, down=false, left=true, right=true}
}
blocks.wire_017 = {
    solid = false,
    tileset = "default",
    pos = {x=2, y=6},
    wire = {up=false, down=true, left=false, right=true}
}
blocks.wire_018 = {
    solid = false,
    tileset = "default",
    pos = {x=3, y=6},
    wire = {up=false, down=false, left=true, right=true}
}
blocks.wire_019 = {
    solid = false,
    tileset = "default",
    pos = {x=4, y=6},
    wire = {up=false, down=true, left=true, right=false}
}
blocks.wire_020 = {
    solid = false,
    tileset = "default",
    pos = {x=5, y=6},
    wire = {up=false, down=false, left=true, right=true}
}
blocks.wire_021 = {
    solid = false,
    tileset = "default",
    pos = {x=6, y=6},
    wire = {up=true, down=true, left=true, right=true}
}

blocks.activate_trigger = {
    solid = false,
    tileset = "default",
    pos = {x=1, y=8},
    on_signal = function(self, x, y, map)
        -- check tile below in front layer and call activate
        if map.grid_front and map.grid_front[y] then
            local tileBelow = map.grid_front[y][x]
            local tileDef = config.tiles[tileBelow]
            if tileDef and tileDef.activate then
                tileDef.activate(tileDef, map)
            end
        end
    end
}

for _, block in pairs(blocks) do validateBlock(block) end
for name, block in pairs(blocks) do
    if block.pos and not block.csv_id then
        block.csv_id = (block.pos.x + (block.pos.y * 7)) + 1
    end
end

return blocks
