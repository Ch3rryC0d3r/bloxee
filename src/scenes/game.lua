local mapModule = require "src.core.map"
local playerModule = require "src.core.player"
local levelselect = require "src.scenes.levelselect"

local game = {}

local paused = false
local pauseOptions = {"Resume", "Quit Level"}
local selectedPause = 1
local font = love.graphics.newFont(32)
local titleFont = love.graphics.newFont(48)
local badgeImage = nil
local badgeQuads = {}

function game:load(levelID, levelselectScene)
    self.map = mapModule
    self.player = playerModule
    self.level = levelID -- numeric
    self.map:load(levelselect.levels[levelID]) -- pass path to map
    self.player:load(self.map, self.level)     -- numeric level ID
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
    if not paused then
        self.player:update(dt)
        self.map:updateAnim(dt)
    end
end

function game:draw()
    self.map:draw()
    self.player:draw()

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
            if i == selectedPause then
                love.graphics.setColor(0,1,0)
            else
                love.graphics.setColor(1,1,1)
            end
            love.graphics.printf(opt,0,y,640,"center")
        end
    end

    -- You Win screen
    if self.player.hasWon then
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill",0,0,640,480)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(titleFont)
        love.graphics.printf("You Win!",0,50,640,"center")
        love.graphics.setFont(font)
        local movesText = "Moves: "..self.player.moves
        love.graphics.printf(movesText,0,150,640,"center")

        -- draw badge next to moves
        local badgeIdx = 0
        if self.player.badge == "platinum" then badgeIdx = 1
        elseif self.player.badge == "gold" then badgeIdx = 2
        elseif self.player.badge == "silver" then badgeIdx = 3
        elseif self.player.badge == "bronze" then badgeIdx = 4
        end

        if badgeIdx > 0 and badgeImage and badgeQuads[badgeIdx] then
            -- calculate text width to position badge after it
            local textWidth = font:getWidth(movesText)
            local centerX = (640 - textWidth) / 2
            local badgeX = centerX + textWidth + 10
            local badgeY = 150
            
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(badgeImage, badgeQuads[badgeIdx], badgeX, badgeY, 0, 2, 2)
            
            -- label below badge, half size, grayish
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.setFont(love.graphics.newFont(16))
            local badgeLabel = self.player.badge:sub(1,1):upper()..self.player.badge:sub(2)
            love.graphics.printf(badgeLabel, badgeX-10, badgeY+68, 120, "center")

        end

        -- buttons with selection
        local options = {"Next Level","Level Select","Quit to Menu"}
        for i,opt in ipairs(options) do
            local y = 300 + i*50
            if i == self.selectedWinOption then
                love.graphics.setColor(0,1,0)
            else
                love.graphics.setColor(1,1,1)
            end
            love.graphics.printf(opt,0,y,640,"center")
        end
    end
    love.graphics.setColor(1,1,1)
end


function game:keypressed(key)
    if self.player.hasWon then
        if key == "up" then
            self.selectedWinOption = self.selectedWinOption - 1
            if self.selectedWinOption < 1 then self.selectedWinOption = 3 end
        elseif key == "down" then
            self.selectedWinOption = self.selectedWinOption + 1
            if self.selectedWinOption > 3 then self.selectedWinOption = 1 end
        elseif key == "return" then
            if self.selectedWinOption == 1 then
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
            elseif self.selectedWinOption == 2 then
                -- level select
                local levelselect = require "src.scenes.levelselect"
                levelselect:load()
                currentScene = levelselect
            elseif self.selectedWinOption == 3 then
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
                local menu = require "src.scenes.menu"
                menu:load()
                currentScene = menu
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