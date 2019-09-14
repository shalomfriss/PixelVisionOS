--[[
  Pixel Vision 8 - New Template Script
  Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
  Created by Jesse Freeman (@jessefreeman)

  This project was designed to display some basic instructions when you create
  a new game.  Simply delete the following code and implement your own Init(),
  Update() and Draw() logic.

  Learn more about making Pixel Vision 8 games at https://www.gitbook.com/@pixelvision8
]]--

local message = "SPRITE BLOCK DEMO\n\nThe DrawSpriteBlock() API allows you to create larger sprites from a 'block' of sprites in memory."

local mode = 0
local delay = 1
local time = 2

function Init()

  local display = Display()

  -- We are going to render the message in a box as tiles. To do this, we need to wrap the text, then split it into lines and draw each line.
  local wrap = WordWrap(message, (display.x / 8) - 2)
  local lines = SplitLines(wrap)
  local total = #lines
  local startY = 1

  -- We want to render the text from the bottom of the screen so we offset it and loop backwards.
  for i = total, 1, - 1 do
    DrawText(lines[i], 1, startY + (i - 1), DrawMode.Tile, "large")
  end

  -- Draw titles
  DrawText("Sprite Page 1", 1, 10, DrawMode.Tile, "large")
  DrawText("Sprite (2x2)", 19, 10, DrawMode.Tile, "large")
  DrawText("Sprite (2x3)", 19, 16, DrawMode.Tile, "large")
  DrawText("Sprite (4x4)", 19, 22, DrawMode.Tile, "large")

  -- Draw a single page of sprite memory to the tilemap
  DrawSpriteBlock(0, 1, 12, 16, 16, false, false, DrawMode.Tile, 0)

end

-- The Draw() method is part of the game's life cycle. It is called after Update() and is where all of our draw calls should go. We'll be using this to render sprites to the display.
function Draw()

  -- We can use the RedrawDisplay() method to clear the screen and redraw the tilemap in a single call.
  RedrawDisplay()

  -- Example 1 (2x2)
  DrawSpriteBlock(0, 19 * 8, 12 * 8, 2, 2, false, false, DrawMode.Sprite)

  -- Example 2 (2x3)
  DrawSpriteBlock(172, 19 * 8, 18 * 8, 2, 3, false, false, DrawMode.Sprite)

  -- Example 3 (4x4)
  DrawSpriteBlock(104, 19 * 8, 24 * 8, 4, 4, false, false, DrawMode.Sprite)

end
