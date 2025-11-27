local menu = {}
local titleFont = love.graphics.newFont(64)
local menuFont = love.graphics.newFont(32)

local options = {"Play", "Quit"}
local selectedOption = 1

function menu:load()
    selectedOption = 1
end

function menu:update(dt)
end

function menu:draw()
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("BLOXEE", 0, 50, 640, "center")
    
    love.graphics.setFont(menuFont)
    for i,opt in ipairs(options) do
        local y = 250 + i*50
        love.graphics.setColor(i == selectedOption and {0,1,0} or {1,1,1})
        love.graphics.printf(opt, 0, y, 640, "center")
    end
end

function menu:keypressed(key)
    if key == "up" then
        selectedOption = selectedOption - 1
        if selectedOption < 1 then selectedOption = #options end
    elseif key == "down" then
        selectedOption = selectedOption + 1
        if selectedOption > #options then selectedOption = 1 end
    elseif key == "return" then
        if selectedOption == 1 then
            local levelselect = require "src.scenes.levelselect"
            levelselect:load()
            currentScene = levelselect
        elseif selectedOption == 2 then
            love.event.quit()
        end
    end
end

return menu
