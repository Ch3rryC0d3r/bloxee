local menu = require "src.scenes.menu"
local levelselect = require "src.scenes.levelselect"
local game = require "src.scenes.game"

currentScene = menu
currentScene:load()

function love.update(dt)
    currentScene:update(dt)
end

function love.draw()
    currentScene:draw()
end

function love.keypressed(key)
    currentScene:keypressed(key)
end