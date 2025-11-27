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

function map:getTileAt(x, y)
    local tile = nil
    if self.grid_front and self.grid_front[y] then tile = self.grid_front[y][x] end
    if self.grid_mid and self.grid_mid[y] and tile == nil then tile = self.grid_mid[y][x] end
    if self.grid_back and self.grid_back[y] and tile == nil then tile = self.grid_back[y][x] end
    return tile
end

function map:callTileLoad()
    for _, grid in pairs({self.grid_back, self.grid_mid, self.grid_front}) do
        if grid then
            for y,row in ipairs(grid) do
                for x,tileId in ipairs(row) do
                    local def = config.tiles[tileId]
                    if def and def.load then 
                        def.load({x=x, y=y, map=self}) 
                    end
                end
            end
        end
    end
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
    local cols = 7
    local rows = math.floor(th / TILE_SIZE)
    
    local quads = {}
    for y=0,rows-1 do
        for x=0,cols-1 do
            table.insert(quads, love.graphics.newQuad(x*TILE_SIZE, y*TILE_SIZE, TILE_SIZE, TILE_SIZE, tw, th))
        end
    end
    return quads
end


function map:activateWiresAt(x, y)
    if not self.grid_wires or not self.grid_wires[y] then return end
    
    local wireTileId = self.grid_wires[y][x]
    if not wireTileId or wireTileId == -1 then return end

    local tileDef = config.tiles[wireTileId]
    if not tileDef then return end

    -- call on_signal if it exists
    if tileDef.on_signal then
        tileDef.on_signal({x=x, y=y, map=self}, x, y, self)
    end

    -- propagate along wire connections
    if tileDef.wire then
        local dirNames = {up = {0,-1}, down = {0,1}, left = {-1,0}, right = {1,0}}
        
        for dirName, dir in pairs(dirNames) do
            if tileDef.wire[dirName] then
                local nx, ny = x + dir[1], y + dir[2]
                self:activateWiresAt(nx, ny)
            end
        end
    end
end

function map:load(level)
    local basePath = "levels/" .. level
    local frontPath = basePath .. "_front.csv"
    local midPath   = basePath .. "_mid.csv"
    local backPath  = basePath .. "_back.csv"
    local wiresPath  = basePath .. "_wires.csv"
    

    -- fallback if no _front exists
    if not love.filesystem.getInfo(frontPath) then frontPath = basePath end

    -- load layers
    local function loadLayer(path)
        if not love.filesystem.getInfo(path) then return nil end
        local layerGrid = {}
        local y = 1
        local contents = love.filesystem.read(path)
        for line in contents:gmatch("[^\r\n]+") do
            layerGrid[y] = {}
            for cell in line:gmatch("([^,]+)") do
                table.insert(layerGrid[y], tonumber(cell))
            end
            y = y + 1
        end
        return layerGrid
    end

    self.grid_back  = loadLayer(backPath)
    self.grid_mid   = loadLayer(midPath)
    self.grid_front = loadLayer(frontPath)
    self.grid_wires = loadLayer(wiresPath)


    self.playerSpawn = nil
    self.boxes = {}
    self.tilesets = {}
    self.quads = {}

    -- scan front layer for player spawn / boxes
    for y,row in ipairs(self.grid_front) do
        for x,num in ipairs(row) do
            if num == 9 then
                self.playerSpawn = {x=x, y=y}
                self.grid_front[y][x] = 7
            end
            if num == 1 then
                local box = {x=x, y=y, map=self}
                table.insert(self.boxes, box)
                self.grid_front[y][x] = 7
            end
        end
    end
    self:callTileLoad()
    -- load all tilesets from config
    for name,_ in pairs(config.tilesets) do
        self:loadTileset(name)
    end
end

function map:updateAnim(dt)
    for _, grid in pairs({self.grid_back, self.grid_mid, self.grid_front}) do
        if grid then
            for y,row in ipairs(grid) do
                for x,tileId in ipairs(row) do
                    local tile = config.tiles[tileId]
                    if tile and tile.anim then
                        tile.anim.timer = (tile.anim.timer or 0) + dt
                        local currentFrame = tile.anim.currentFrame or 1
                        local frameData = tile.anim.frames[currentFrame]
                        local frameTime = frameData[3] or tile.anim.speed
                        if tile.anim.timer >= frameTime then
                            tile.anim.timer = 0
                            currentFrame = currentFrame + 1
                            if currentFrame > #tile.anim.frames then currentFrame = 1 end
                            tile.anim.currentFrame = currentFrame
                        end
                    end
                end
            end
        end
    end
end

function map:isEmpty(x, y, dir, ignoreBoxSolid)
    local tile = self:getTileAt(x, y)
    if not tile or tile == -1 then return false end

    for _, box in ipairs(self.boxes) do
        if box.x == x and box.y == y then return false end
    end

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

    local function drawGrid(grid)
        if not grid then return end
        for y,row in ipairs(grid) do
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

    drawGrid(self.grid_back)
    drawGrid(self.grid_mid)
    drawGrid(self.grid_front)

    -- draw boxes (same as before)
    for _, box in ipairs(self.boxes) do
        local drawNum = 1
        if self.grid_front[box.y][box.x] == 2 then drawNum = 6 end
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