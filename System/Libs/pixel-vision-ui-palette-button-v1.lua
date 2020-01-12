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
function EditorUI:CreatePaletteButton(rect, spriteName, toolTip, colorOffset, totalColors)

  totalColors = totalColors or 16

  -- Create the button's default data
  local data = self:CreateButton(rect, spriteName, toolTip, false)

  data.colorOffset = colorOffset or 0

  local defaultSprite = _G[spriteName .. "up"]

  if(defaultSprite ~= nil) then

    local sprites = defaultSprite.spriteIDs

    -- Update the UI tile width and height
    data.tiles.width = #sprites / 2
    data.tiles.height = 2

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

  end

  return data
  --
end
