-- --
-- -- Copyright (c) 2017, Jesse Freeman. All rights reserved.
-- --
-- -- Licensed under the Microsoft Public License (MS-PL) License.
-- -- See LICENSE file in the project root for full license information.
-- --
-- -- Contributors
-- -- --------------------------------------------------------
-- -- This is the official list of Pixel Vision 8 contributors:
-- --
-- -- Jesse Freeman - @JesseFreeman
-- -- Christina-Antoinette Neofotistou - @CastPixel
-- -- Christer Kaitila - @McFunkypants
-- -- Pedro Medeiros - @saint11
-- -- Shawn Rakowski - @shwany
-- --
--
function EditorUI:CreatePaletteButton(rect, spriteName, toolTip, colorOffset, totalColors, remapColorOffsets)

  totalColors = totalColors or 16

  -- Create the button's default data
  local data = self:CreateButton(rect, spriteName, toolTip, false)

  data.name = "Palette" .. data.name

  data.colorOffset = colorOffset or 0

  local defaultSprite = _G[spriteName]

  if(defaultSprite ~= nil) then

    local sprites = defaultSprite.spriteIDs

    -- Update the UI tile width and height
    data.tiles.width = defaultSprite.width
    data.tiles.height = math.floor(#sprites / defaultSprite.width)

    -- Update the rect width and height with the new sprite size
    data.rect.width = data.tiles.width * self.spriteSize.x
    data.rect.height = data.tiles.height * self.spriteSize.y

    data.cachedSpriteData = {
      disabled = {spriteIDs = sprites, width = data.tiles.width, colorOffset = data.colorOffset},
      up = {spriteIDs = sprites, width = data.tiles.width, colorOffset = data.colorOffset + totalColors},
      over = {spriteIDs = sprites, width = data.tiles.width, colorOffset = data.colorOffset + (totalColors * 2)},
      down = {spriteIDs = sprites, width = data.tiles.width, colorOffset = data.colorOffset + (totalColors * 3)},
      selectedup = {spriteIDs = sprites, width = data.tiles.width, colorOffset = data.colorOffset + (totalColors * 4)},
      selectedover = {spriteIDs = sprites, width = data.tiles.width, colorOffset = data.colorOffset + (totalColors * 5)},
      selecteddown = {spriteIDs = sprites, width = data.tiles.width, colorOffset = data.colorOffset + (totalColors * 6)}
    }

    if(remapColorOffsets ~= nil) then

      for k, v in pairs(remapColorOffsets) do

        if(data.cachedSpriteData[k] ~= nil) then
          data.cachedSpriteData[k].colorOffset = v
        end
      end
    end

    -- Rebuild the draw argument tables
    data.spriteDrawArgs = {sprites, 0, 0, defaultSprite.width, false, false, DrawMode.Sprite, 0, false, false}
    data.tileDrawArgs = {sprites, data.rect.x, data.rect.y, defaultSprite.width, false, false, DrawMode.TilemapCache, 0}

    -- Invalidate the button
    self:Invalidate(data)

  end

  return data
  --
end

function EditorUI:CreateTogglePaletteButton(rect, spriteName, toolTip, colorOffset, totalColors, remapColorOffsets)

  local data = self:CreatePaletteButton(rect, spriteName, toolTip, colorOffset, totalColors, remapColorOffsets)

  data.name = "Toggle" .. data.name

  -- Add the selected property to make this a toggle button
  data.selected = false

  data.onClick = function(tmpData)

    -- Only trigger the click action when the last pressed button name matches
    if(self.currentButtonDown == tmpData.name) then
      self:ToggleButton(tmpData)
    end

  end

  return data

end
