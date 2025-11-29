local levelselect = {}

levelselect.levels = {
    "Level 1",
    "Level 2",
    "Level 3",
    "Level 4",
    "Level 5",
    "Level 6",
    "Level 7"
}
local levels = levelselect.levels
local selectedLevel = 1

local font = love.graphics.newFont(32)
local titleFont = love.graphics.newFont(48)

function levelselect:load()
end

function levelselect:update(dt)
end

function levelselect:draw()
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Select Level", 0, 50, 640, "center")

    love.graphics.setFont(font)
    for i, lvlName in ipairs(levels) do
        local y = 150 + i*50
        if i == selectedLevel then
            love.graphics.setColor(0,1,0) -- selected
        else
            love.graphics.setColor(1,1,1)
        end
        love.graphics.printf(lvlName, 0, y, 640, "center")
    end
end

function levelselect:keypressed(key)
    if key == "up" then
        selectedLevel = selectedLevel - 1
        if selectedLevel < 1 then selectedLevel = #levels end
    elseif key == "down" then
        selectedLevel = selectedLevel + 1
        if selectedLevel > #levels then selectedLevel = 1 end
    elseif key == "return" then
        local game = require "src.scenes.game"
        game:load(selectedLevel, self)
        currentScene = game
    elseif key == "escape" then
        local menu = require "src.scenes.menu"
        menu:load()
        currentScene = menu
    end
end

return levelselect