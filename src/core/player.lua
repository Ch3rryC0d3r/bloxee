local config = require "src.config"
local map = require "src.core.map"

local player = {}

-- Global API for blocks
BLOX = {
    PLR = player
}
BLOX.BOXES = {}
player.x = 1
player.y = 1
player.collectibles = 0
player.total_collectibles = 0
player.tilesetQuad = nil
TILE_SIZE = config.ui.tileSize
player.moves = 0
player.plat_moves = 0
player.hasWon = false
player.badge = nil
player.canMove = true
player.lastMoveDir = {0, 0}
player.slideTimer = 0
player.slidePath = {}
player.boxesToMove = {}
player.solidCol = false
local timers = {}

function delay(seconds, callback)
    table.insert(timers, {time=0, max=seconds, func=callback})
end

function updateTimers(dt)
    for i=#timers,1,-1 do
        local t = timers[i]
        t.time = t.time + dt
        if t.time >= t.max then
            t.func()
            table.remove(timers, i)
        end
    end
end

function player:load(map, level)
    self.map = map
    self.collectibles = 0
    self.total_collectibles = self.map:countCollectibles()
    self.level = level
    self.moves = 0
    self.hasWon = false
    self.badge = nil
    self.canMove = true
    self.slideTimer = 0
    self.slidePath = {}
    self.boxesToMove = {}
    self.solidCol = false
    
    local cols = self.map.tileset:getWidth()/TILE_SIZE
    self.tilesetQuad = self.map.quads[2*cols + 0 + 1]

    if map.playerSpawn then
        self.x = map.playerSpawn.x
        self.y = map.playerSpawn.y
    else
        self.x = 1
        self.y = 1
    end
end

function player:isBoxInList(box, list)
    for _, b in ipairs(list) do
        if b.x == box.x and b.y == box.y then
            return true
        end
    end
    return false
end

function player:update(dt)
    updateTimers(dt) -- handles scheduled delays
end


function player:draw()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(self.map.tileset, self.tilesetQuad, (self.x-1)*TILE_SIZE, (self.y-1)*TILE_SIZE)
end

function player:isBoxAt(x, y)
    for _, box in ipairs(self.map.boxes) do
        if box.x == x and box.y == y then
            return true
        end
    end
    return false
end

function player:move(dir, countMove)
    countMove = countMove == nil and true or countMove
    self.hitSolid = false

    local dx, dy = dir[1], dir[2]
    local targetX, targetY = self.x + dx, self.y + dy

    -- bounds check
    if not self.map.grid[targetY] or not self.map.grid[targetY][targetX] then
        self.hitSolid = true
        return
    end

    local targetTile = self.map.grid[targetY][targetX]
    if not self.map:isEmpty(targetX, targetY, {dx, dy}, true) then
        self.hitSolid = true
        return
    end

    -- check for box
    local boxAtTarget
    for _, box in ipairs(self.map.boxes) do
        if box.x == targetX and box.y == targetY then
            boxAtTarget = box
            break
        end
    end

    if boxAtTarget then
        -- tell map to slide the box
        self.map:moveBox(boxAtTarget, dir)
        if boxAtTarget.hitSolid then
            self.hitSolid = true
            return
        end
    end

    -- move player
    self.x = targetX
    self.y = targetY
    if countMove then self.moves = self.moves + 1 end

    -- trigger tile logic
    local tileDef = config.tiles[self.map.grid[self.y][self.x]]
    if tileDef and tileDef.on_col then
        tileDef.on_col()
    end
end

function player:keypressed(key)
    if self.hasWon or not self.canMove then return end

    local dx, dy = 0, 0
    if key == "up" then dy = -1
    elseif key == "down" then dy = 1
    elseif key == "left" then dx = -1
    elseif key == "right" then dx = 1
    else return end

    self.lastMoveDir = {dx, dy}
    local targetX, targetY = self.x + dx, self.y + dy

    -- check bounds
    if not self.map.grid[targetY] or not self.map.grid[targetY][targetX] then return end

    -- find box at target
    local boxAtTarget
    for _, box in ipairs(self.map.boxes) do
        if box.x == targetX and box.y == targetY then
            boxAtTarget = box
            break
        end
    end

    local moved = false
        
    if not boxAtTarget then
        -- normal move: player ignores boxSolid, only solid blocks matter
        local tile = self.map.grid[targetY][targetX]
        if self.map:isEmpty(targetX, targetY, {dx, dy}, true) then
            self.x = targetX
            self.y = targetY
            moved = true
        end

    else
        -- push attempt
        local pushX, pushY = targetX + dx, targetY + dy
        local blocked = false

        -- check bounds for push
        if not self.map.grid[pushY] or not self.map.grid[pushY][pushX] then
            blocked = true
        end

        -- check tile at push
        local pushTile = self.map.grid[pushY] and self.map.grid[pushY][pushX]
        if pushTile then
            local tileDef = config.tiles[pushTile]
            if not self.map:isEmpty(pushX, pushY, {dx, dy}) then
                blocked = true
            end

        end

        -- check for another box in the push spot
        for _, b in ipairs(self.map.boxes) do
            if b.x == pushX and b.y == pushY then blocked = true end
        end

        if not blocked then
            -- normal push works
            self.map:moveBox(boxAtTarget, {dx, dy})
            if not boxAtTarget.hitSolid then
                self.x = targetX
                self.y = targetY
                moved = true
            end
        else
            -- swap-push (push box backwards if possible)
            local backX, backY = self.x, self.y
            local backBlocked = false

            -- check bounds for back
            if not self.map.grid[backY] or not self.map.grid[backY][backX] then
                backBlocked = true
            end

            -- check tile behind
            local backTile = self.map.grid[backY] and self.map.grid[backY][backX]
            if backTile then
                local tileDef = config.tiles[backTile]
                if not self.map:isEmpty(backX, backY, {-dx, -dy}) then backBlocked = true end
            end

            -- check for box behind
            for _, b in ipairs(self.map.boxes) do
                if b.x == backX and b.y == backY then backBlocked = true end
            end

            if not backBlocked then
                self.map:moveBox(boxAtTarget, {-dx, -dy})
                self.x = targetX
                self.y = targetY
                moved = true
            end
        end
    end

    if moved then
        self.moves = self.moves + 1

        -- trigger tile logic
        local tileDef = config.tiles[self.map.grid[self.y][self.x]]
        if tileDef and tileDef.on_col then
            tileDef.on_col()
        end

        -- check win
        local allOnGoal = true
        for _, box in ipairs(self.map.boxes) do
            if self.map.grid[box.y][box.x] ~= 2 then
                allOnGoal = false
                break
            end
        end
        if allOnGoal then
            self.hasWon = true
            self:calculateBadge()
        end
    end
end

function player:calculateBadge()
    local platinum = config.badges[self.level] or 10
    self.plat_moves = platinum
    local gold = math.ceil(platinum * 1.12)
    local silver = math.ceil(platinum * 1.25)

    if self.moves <= platinum then
        self.badge = "platinum"
    elseif self.moves <= gold then
        self.badge = "gold"
    elseif self.moves <= silver then
        self.badge = "silver"
    else
        self.badge = "bronze"
    end
end

return player