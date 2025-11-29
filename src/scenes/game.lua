local mapModule = require "src.core.map"
local playerModule = require "src.core.player"
local levelselect = require "src.scenes.levelselect"
local config = require "src.config"

local game = {}

game.camX = 0
game.camY = 0

local paused = false
local pauseOptions = {"Resume", "Reset Level", "Quit to Menu", "Quit to Levels"}
local selectedPause = 1
local font = love.graphics.newFont(32)
local titleFont = love.graphics.newFont(48)
local badgeImage = nil
local badgeQuads = {}

function game:load(levelID, levelselectScene)
    self.map = mapModule
    self.player = playerModule
    self.level = levelID
    self.timer = 0
    self.map:load(levelselect.levels[levelID]) 
    self.player:load(self.map, self.level)    
    self.player.hasWon = false
    paused = false
    self.selectedWinOption = 1
    
    -- badge images
    if not badgeImage then
        badgeImage = love.graphics.newImage("assets/badges.png")
        badgeQuads = {}
        for i=1,4 do
            badgeQuads[i] = love.graphics.newQuad((i-1)*32, 0, 32, 32, badgeImage:getWidth(), badgeImage:getHeight())
        end
    end
end

function game:update(dt)
    if not paused and not self.player.hasWon then
        self.player:update(dt)

        local tileSize = config.ui.tileSize
        local camStepX = math.floor(config.ui.screenWidth / tileSize) * tileSize
        local camStepY = math.floor(config.ui.screenHeight / tileSize) * tileSize

        -- calculate which "camera block" player is in
        local playerPixelX = (self.player.x - 1) * tileSize
        local playerPixelY = (self.player.y - 1) * tileSize

        self.camX = math.floor(playerPixelX / camStepX) * camStepX
        self.camY = math.floor(playerPixelY / camStepY) * camStepY

        self.timer = self.timer + dt
    end

end

function game:draw()
    love.graphics.push()
    love.graphics.translate(-self.camX, -self.camY) -- camera offset

    self.map:draw()
    self.player:draw()

    love.graphics.pop() -- restore
    -- now draw UI on top
    love.graphics.setColor(1,1,1)    

    -- normal pause menu
    if paused and not self.player.hasWon then
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill",0,0,640,480)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(titleFont)
        love.graphics.printf("Paused",0,100,640,"center")
        love.graphics.setFont(font)
        for i,opt in ipairs(pauseOptions) do
            local y = 200 + i*50
            love.graphics.setColor(i == selectedPause and {0,1,0} or {1,1,1})
            love.graphics.printf(opt,0,y,640,"center")
        end
    end

    if self.player.hasWon then
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill",0,0,640,480)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(titleFont)
        love.graphics.printf("You Win!",0,50,640,"center")
        love.graphics.setFont(font)
        
        -- Collectibles counter
        love.graphics.setColor(0.6, 0.6, 0.6)
        local got = BLOX.PLR.collectibles
        local total = BLOX.PLR.total_collectibles
        if total > 0 then 
            love.graphics.printf(got .. "/" .. total .. " Strawbs Collected", 0, 250, 640, "center")
        end

        -- Moves
        local movesText = "Moves: "..self.player.moves
        love.graphics.printf(movesText,0,160,640,"center")
        love.graphics.setColor(0.4, 0.4, 0.4)
        local movesText = "(Plat. Moves): ".. self.player.plat_moves
        love.graphics.printf(movesText,0,240,640,"center")        
        
        -- draw badge next to moves
        local badgeIdx = ({platinum=1,gold=2,silver=3,bronze=4})[self.player.badge] or 0
        if badgeIdx > 0 and badgeImage and badgeQuads[badgeIdx] then
            local textWidth = font:getWidth(movesText)
            local centerX = (640 - textWidth) / 2
            local badgeX = centerX + textWidth + 10
            local badgeY = 150
            
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(badgeImage, badgeQuads[badgeIdx], badgeX, badgeY, 0, 2, 2)
            
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.setFont(love.graphics.newFont(16))
            local badgeLabel = self.player.badge:sub(1,1):upper()..self.player.badge:sub(2)
            love.graphics.printf(badgeLabel, badgeX-25, badgeY+68, 120, "center")
        end
        
        -- timer
        love.graphics.setFont(font)
        local timeText = string.format("Time: %.2f", self.timer)
        love.graphics.printf(timeText, 0, 200, 640, "center")
        
        -- win options
        local options = {"Retry","Next Level","Level Select","Quit to Menu"}
        for i,opt in ipairs(options) do
            local y = 300 + i*50
            love.graphics.setColor(i == self.selectedWinOption and {0,1,0} or {1,1,1})
            love.graphics.printf(opt,0,y,640,"center")
        end
    end

    
    love.graphics.setColor(1,1,1)
end

function game:keypressed(key)
    if self.player.hasWon then
        if key == "up" then
            self.selectedWinOption = self.selectedWinOption - 1
            if self.selectedWinOption < 1 then self.selectedWinOption = 4 end
        elseif key == "down" then
            self.selectedWinOption = self.selectedWinOption + 1
            if self.selectedWinOption > 4 then self.selectedWinOption = 1 end
        elseif key == "return" then
            if self.selectedWinOption == 1 then
                -- retry
                self:load(self.level, require "src.scenes.levelselect")
            elseif self.selectedWinOption == 2 then
                -- next level
                local nextLevel = self.level + 1
                local levelselect = require "src.scenes.levelselect"
                if nextLevel <= #levelselect.levels then
                    self:load(nextLevel, levelselect)
                else
                    local menu = require "src.scenes.menu"
                    menu:load()
                    currentScene = menu
                end
            elseif self.selectedWinOption == 3 then
                -- level select
                local levelselect = require "src.scenes.levelselect"
                levelselect:load()
                currentScene = levelselect
            elseif self.selectedWinOption == 4 then
                -- quit to menu
                local menu = require "src.scenes.menu"
                menu:load()
                currentScene = menu
            end
        end
        return
    end

    if paused then
        if key == "up" then
            selectedPause = selectedPause - 1
            if selectedPause < 1 then selectedPause = #pauseOptions end
        elseif key == "down" then
            selectedPause = selectedPause + 1
            if selectedPause > #pauseOptions then selectedPause = 1 end
        elseif key == "return" then
            if selectedPause == 1 then
                paused = false
            elseif selectedPause == 2 then
                -- reset level
                self:load(self.level, require "src.scenes.levelselect")
            elseif selectedPause == 3 then
                local menu = require "src.scenes.menu"
                menu:load()
                currentScene = menu
            elseif selectedPause == 4 then 
                local levelselect = require "src.scenes.levelselect"
                levelselect:load()
                currentScene = levelselect                
            end
        end
    else
        if key == "escape" then
            paused = true
            selectedPause = 1
        else
            self.player:keypressed(key)
        end
    end
end

return game
