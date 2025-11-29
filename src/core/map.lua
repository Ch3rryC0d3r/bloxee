local config = require "src.config"
local map = {}
TILE_SIZE = config.ui.tileSize

map.grid = {}
map.tilesets = {} -- store loaded tilesets
map.tileset = nil
map.quads = {}
map.playerSpawn = nil
map.boxes = {}

local function split(str, sep)
    local t={}
    for s in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(t, s)
    end
    return t
end

function map:moveBox(box, dir)
    box.hitSolid = false
    box.lastMoveDir = dir  -- track direction for sliding

    local targetX, targetY = box.x + dir[1], box.y + dir[2]

    -- bounds check
    if not self.grid[targetY] or not self.grid[targetY][targetX] then
        box.hitSolid = true
        box.isSliding = false
        return
    end

    local targetTile = self.grid[targetY][targetX]
    local tileDef = config.tiles[targetTile]

    -- check solid tile
    if tileDef and tileDef.boxSolid then
        box.hitSolid = true
        box.isSliding = false
        return
    end


    -- check other boxes
    for _, b in ipairs(self.boxes) do
        if b ~= box and b.x == targetX and b.y == targetY then
            box.hitSolid = true
            box.isSliding = false
            return
        end
    end

    -- move box
    box.x = targetX
    box.y = targetY
end


function map:loadTileset(name)
    if not self.tilesets[name] then
        local path = config.tilesets[name] or config.tilesets.default
        self.tilesets[name] = love.graphics.newImage(path)
    end
    self.tileset = self.tilesets[name]

    -- build quads
    self.quads = self:buildQuads(self.tileset)

    return self.tileset
end


function map:buildQuads(tileset)
    local tw, th = tileset:getWidth(), tileset:getHeight()
    local cols = tw / TILE_SIZE
    local rows = th / TILE_SIZE
    
    local quads = {}
    for y=0,rows-1 do
        for x=0,cols-1 do
            table.insert(quads, love.graphics.newQuad(x*TILE_SIZE, y*TILE_SIZE, TILE_SIZE, TILE_SIZE, tw, th))
        end
    end
    return quads
end

function map:countCollectibles()
    local count = 0
    for y,row in ipairs(self.grid) do
        for x,tile in ipairs(row) do
            if tile == 79 then
                count = count + 1
            end
        end
    end
    return count
end

function map:load(level)
    -- normal level
    local path = "levels/" .. level .. ".csv"
    if not love.filesystem.getInfo(path) then
        path = level -- mod level fallback
        if not love.filesystem.getInfo(path) then
            error("Level file not found: "..level)
        end
    end

    local contents = love.filesystem.read(path)
    if not contents then error("Failed to read level: "..path) end

    self.grid = {}
    self.playerSpawn = nil
    self.boxes = {}
    self.tilesets = {}
    self.quads = {}
    self.backgroundGrid = {} -- NEW: store back layer

    -- check for background CSV
    local backPath = "levels/" .. level .. "_back.csv"
    if love.filesystem.getInfo(backPath) then
        local backContents = love.filesystem.read(backPath)
        local y = 1
        for line in backContents:gmatch("[^\r\n]+") do
            self.backgroundGrid[y] = {}
            for s in string.gmatch(line, "([^,]+)") do
                table.insert(self.backgroundGrid[y], tonumber(s))
            end
            y = y + 1
        end
    end

    -- load main grid
    local y = 1
    for line in contents:gmatch("[^\r\n]+") do
        self.grid[y] = {}
        local cells = {}
        for s in string.gmatch(line, "([^,]+)") do
            table.insert(cells, s)
        end

        for x, cell in ipairs(cells) do
            local num = tonumber(cell)
            if num > -1 then 
                print(num)
            end
            if num == 9 or num == 10 then
                self.playerSpawn = {x=x, y=y}
                num = -1
            end
            if num == 1 then
                local box = {x=x, y=y, map=self}
                table.insert(self.boxes, box)
                num = -1
            end

            self.grid[y][x] = num
        end
        y = y + 1
    end

    -- load tilesets
    for name, _ in pairs(config.tilesets) do
        self:loadTileset(name)
    end
end

function map:isEmpty(x, y, dir, ignoreBoxSolid)
    if not self.grid[y] or not self.grid[y][x] then return false end

    for _, box in ipairs(self.boxes) do
        if box.x == x and box.y == y then return false end
    end

    local tile = self.grid[y][x]
    local tileDef = config.tiles[tile]
    if not tileDef then return true end

    -- handle normal solid
    if type(tileDef.solid) == "boolean" then
        if tileDef.solid then return false end
    elseif type(tileDef.solid) == "table" and dir then
        local dx, dy = dir[1], dir[2]
        if dx == 1 and tileDef.solid.right then return false end
        if dx == -1 and tileDef.solid.left then return false end
        if dy == 1 and tileDef.solid.down then return false end
        if dy == -1 and tileDef.solid.up then return false end
    end

    if not ignoreBoxSolid then
        if type(tileDef.boxSolid) == "boolean" and tileDef.boxSolid then
            return false
        elseif type(tileDef.boxSolid) == "table" and dir then
            local dx, dy = dir[1], dir[2]
            if dx == 1 and tileDef.boxSolid.right then return false end
            if dx == -1 and tileDef.boxSolid.left then return false end
            if dy == 1 and tileDef.boxSolid.down then return false end
            if dy == -1 and tileDef.boxSolid.up then return false end
        end
    end

    return true
end

function map:draw()
    if not self.tileset then return end
    local cols = self.tileset:getWidth()/TILE_SIZE

    -- draw background first if exists
    if self.backgroundGrid then
        for y,row in ipairs(self.backgroundGrid) do
            for x,num in ipairs(row) do
                if num ~= nil and num ~= -1 then
                    local tileDef = config.tiles[num]
                    if tileDef then
                        local tsName = tileDef.tileset or "default"
                        local ts = self.tilesets[tsName]
                        local pos = tileDef.tileset_pos or {0,0}
                        local quadIndex = pos[2]*cols + pos[1] + 1
                        if ts and self.quads[quadIndex] then
                            love.graphics.draw(ts, self.quads[quadIndex], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE)
                        end
                    end
                end
            end
        end
    end

    -- draw main grid
    for y,row in ipairs(self.grid) do
        for x,num in ipairs(row) do
            if num ~= nil and num ~= -1 then
                local tileDef = config.tiles[num]
                if tileDef then
                    local tsName = tileDef.tileset or "default"
                    local ts = self.tilesets[tsName]
                    local pos = tileDef.tileset_pos or {0,0}
                    local quadIndex = pos[2]*cols + pos[1] + 1
                    if ts and self.quads[quadIndex] then
                        love.graphics.draw(ts, self.quads[quadIndex], (x-1)*TILE_SIZE, (y-1)*TILE_SIZE)
                    end
                end
            end
        end
    end

    -- draw boxes
    for _, box in ipairs(self.boxes) do
        local drawNum = 1
        if self.grid[box.y][box.x] == 2 then drawNum = 6 end
        local tileDef = config.tiles[drawNum]
        if tileDef then
            local tsName = tileDef.tileset or "default"
            local ts = self.tilesets[tsName]
            local pos = tileDef.tileset_pos or {0,0}
            local quadIndex = pos[2]*cols + pos[1] + 1
            if ts and self.quads[quadIndex] then
                love.graphics.draw(ts, self.quads[quadIndex], (box.x-1)*TILE_SIZE, (box.y-1)*TILE_SIZE)
            end
        end
    end
end

return map