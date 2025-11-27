local menu = {}
local titleFont = love.graphics.newFont(64)
local menuFont = love.graphics.newFont(32)

function menu:load()
end

function menu:update(dt)
end

function menu:draw()
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("BLOXEE", 0, 50, 640, "center")
    
    love.graphics.setFont(menuFont)
    love.graphics.printf("Play", 0, 250, 640, "center")
end

function menu:keypressed(key)
    if key == "return" then
        local levelselect = require "src.scenes.levelselect"
        levelselect:load()
        currentScene = levelselect
    end
end

return menu
