--[[
	Pixel Vision 8 - Display Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

-- API Bridge
LoadScript("sb-sprites")
LoadScript("pixel-vision-os-v2")
LoadScript("pixel-vision-os-color-picker-v2")
LoadScript("pixel-vision-os-item-picker-v1")
LoadScript("pixel-vision-os-sprite-picker-v3")
LoadScript("pixel-vision-os-canvas-v2")
LoadScript("code-render-map-layer")
LoadScript("pixel-vision-os-tilemap-picker-v1")
LoadScript("pixel-vision-os-file-modal-v1")

local toolName = "Tilemap Tool"

local colorOffset = 0
local systemColorsPerPage = 64
local success = false
local viewport = {x = 8, y = 80, w = 224, h = 128}
local lastBGState = false
local currentTileSelection = nil
local mapSize = NewPoint()
local flagPicker = nil
local flagModeActive = false
local showBGColor = false
local spriteSize = 1
local maxSpriteSize = 4
local lastTileSelection = -1

local SaveShortcut, UndoShortcut, RedoShortcut, BGColorShortcut, QuitShortcut = 5, 10, 11, 15, 21

local tools = {"pointer", "pen", "eraser", "fill"}
local toolKeys = {Keys.v, Keys.P, Keys.E, Keys.F}

function InvalidateData()

  -- Only everything if it needs to be
  if(invalid == true)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle .."*", "toolbariconfile")

  pixelVisionOS:EnableMenuItem(SaveShortcut, true)

  invalid = true

end

function ResetDataValidation()

  -- Only everything if it needs to be
  if(invalid == false)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle, "toolbariconfile")

  pixelVisionOS:EnableMenuItem(SaveShortcut, false)

  -- if(tilePickerData ~= nil) then
  tilePickerData.mapInvalid = false
  -- end

  invalid = false

end

function Init()

  BackgroundColor(22)

  -- Disable the back key in this tool
  EnableBackKey(false)

  -- Create an instance of the Pixel Vision OS
  pixelVisionOS = PixelVisionOS:Init()

  -- Reset the undo history so it's ready for the tool
  pixelVisionOS:ResetUndoHistory()

  -- Get a reference to the Editor UI
  editorUI = pixelVisionOS.editorUI

  newFileModal = NewFileModal:Init(editorUI)
  newFileModal.editorUI = editorUI

  rootDirectory = ReadMetaData("directory", nil)

  if(rootDirectory ~= nil) then
    -- Load only the game data we really need
    success = gameEditor:Load(rootDirectory, {SaveFlags.System, SaveFlags.Meta, SaveFlags.Colors, SaveFlags.ColorMap, SaveFlags.Sprites, SaveFlags.Tilemap, SaveFlags.TilemapFlags})
  end

  -- Set the tool name with an error message
  pixelVisionOS:ChangeTitle(toolName .. " - Error Loading", "toolbariconfile")

  -- If data loaded activate the tool
  if(success == true) then

    local menuOptions = 
    {
      -- About ID 1
      {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName) end, toolTip = "Learn about PV8."},
      {divider = true},
      {name = "Edit Sprites", enabled = spriteEditorPath ~= nil, action = OnEditSprites, toolTip = "Open the sprite editor."},
      {name = "Export PNG", action = OnPNGExport, enabled = true, toolTip = "Generate a 'tilemap.png' file."}, -- Reset all the values
      {name = "Save", action = OnSave, enabled = false, key = Keys.S, toolTip = "Save changes made to the colors.png file."}, -- Reset all the values
      {divider = true},
      {name = "Clear", action = OnNewSound, enabled = false, key = Keys.D, toolTip = "Clear the currently selected color."}, -- Reset all the values
      {name = "Revert", action = nil, enabled = false, key = Keys.R, toolTip = "Revert the colors.png file to its previous state."}, -- Reset all the values
      {divider = true},
      {name = "Undo", action = OnUndo, enabled = false, key = Keys.Z, toolTip = "Undo the last action."}, -- Reset all the values
      {name = "Redo", action = OnRedo, enabled = false, key = Keys.Y, toolTip = "Redo the last undo."}, -- Reset all the values
      {name = "Copy", action = OnCopyColor, enabled = false, key = Keys.C, toolTip = "Copy the currently selected sound."}, -- Reset all the values
      {name = "Paste", action = OnPasteColor, enabled = false, key = Keys.V, toolTip = "Paste the last copied sound."}, -- Reset all the values
      {divider = true},
      {name = "BG Color", action = function() ToggleBackgroundColor(not showBGColor) end, key = Keys.B, toolTip = "Toggle background color."},
      {name = "Flag Mode", action = function() ChangeMode(not flagModeActive) end, key = Keys.F, toolTip = "Toggle flag mode for collision."},
      {divider = true},
      {name = "Flip H", action = OnFlipH, enabled = false, key = Keys.Z, toolTip = "Flip the current tile horizontally."}, -- Reset all the values
      {name = "Flip V", action = OnFlipV, enabled = false, key = Keys.X, toolTip = "Flip the current tile vertically."}, -- Reset all the values
      {divider = true},
      {name = "Quit", key = Keys.Q, action = OnQuit, toolTip = "Quit the current game."}, -- Quit the current game
    }

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

    -- The first thing we need to do is rebuild the tool's color table to include the game's system and game colors.

    pixelVisionOS:ImportColorsFromGame()

    _G["flagpickerover"] = {spriteIDs = spriteselection1x.spriteIDs, width = spriteselection1x.width, colorOffset = 28}

    _G["flagpickerselectedup"] = {spriteIDs = spriteselection1x.spriteIDs, width = spriteselection1x.width, colorOffset = (_G["flagpickerover"].colorOffset + 2)}

    ConfigureSpritePickerSelector(1)

    sizeBtnData = editorUI:CreateButton({x = 160, y = 16}, "sprite1x", "Pick the sprite size.")
    sizeBtnData.onAction = function() OnNextSpriteSize() end

    toolBtnData = editorUI:CreateToggleGroup()
    toolBtnData.onAction = OnSelectTool

    for i = 1, #tools do
      local offsetX = ((i - 1) * 16) + 160
      local rect = {x = offsetX, y = 56, w = 16, h = 16}
      editorUI:ToggleGroupButton(toolBtnData, rect, tools[i], "Select the '" .. tools[i] .. "' (".. tostring(toolKeys[i]) .. ") tool.")
    end

    flagBtnData = editorUI:CreateToggleButton({x = 232, y = 56}, "flag", "Toggle between tilemap and flag layers.")

    flagBtnData.onAction = ChangeMode

    -- Get sprite texture dimensions
    local totalSprites = gameEditor:TotalSprites()
    -- This is fixed size at 16 cols (128 pixels wide)
    local spriteColumns = 16
    local spriteRows = math.ceil(totalSprites / 16)

    spritePickerData = pixelVisionOS:CreateSpritePicker(
      {x = 8, y = 24, w = 128, h = 32 },
      {x = 8, y = 8},
      spriteColumns,
      spriteRows,
      pixelVisionOS.colorOffset,
      "spritepicker",
      "sprite",
      false,
      "SpritePicker"
    )

    -- spritePickerData.scrollScale = 4
    spritePickerData.onPress = OnSelectSprite

    -- Check the game editor if palettes are being used
    usePalettes = pixelVisionOS.paletteMode

    local totalColors = gameEditor:TotalColors(true)--pixelVisionOS.realSystemColorTotal + 1
    local totalPerPage = 16--pixelVisionOS.systemColorsPerPage
    local maxPages = 8
    local colorOffset = pixelVisionOS.colorOffset

    -- Configure tool for palette mode
    if(usePalettes == true) then

      -- Change the total colors when in palette mode
      totalColors = 128
      colorOffset = colorOffset + 128

    end


    -- TODO if using palettes, need to replace this with palette color value

    local pickerRect = {x = 184, y = 24, w = 64, h = 16}

    -- TODO setting the total to 0
    paletteColorPickerData = pixelVisionOS:CreateColorPicker(
      pickerRect,
      {x = 8, y = 8},
      totalColors,
      totalPerPage,
      maxPages,
      colorOffset,
      "itempicker",
      "Select a color."
    )

    if(usePalettes == true) then
      -- Force the palette picker to only display the total colors per sprite
      paletteColorPickerData.visiblePerPage = pixelVisionOS.paletteColorsPerPage

      paletteButton = editorUI:CreateButton(pickerRect, nil, "Apply color palette")

      paletteButton.onAction = ApplyTilePalette

    end

    -- Wire up the picker to change the color offset of the sprite picker
    paletteColorPickerData.onPageAction = function(value)

      if(usePalettes == true) then

        -- Calculate the new color offset
        local newColorOffset = pixelVisionOS.colorOffset + pixelVisionOS.totalPaletteColors + ((value - 1) * 16)

        -- Update the sprite picker color offset
        -- spritePickerData.colorOffset = newColorOffset
        pixelVisionOS:ChangeItemPickerColorOffset(spritePickerData, newColorOffset)

        tilePickerData.paintColorOffset = ((value - 1) * 16) + 128

        ApplyTilePalette()
      end

    end

    flagPicker = editorUI:CreatePicker(
      pickerRect,
      8,
      8,
      16,
      "flagpicker",
      "Pick a flag"
    )

    flagPicker.onAction = function(value)
      print("flagPicker Action")
      pixelVisionOS:ChangeTilemapPaintFlag(tilePickerData, value)

    end

    local pathSplit = string.split(rootDirectory, "/")

    -- TODO need to load the correct file here

    -- Update title with file path
    toolTitle = pathSplit[#pathSplit] .. "/" .. "tilemap.png"

    mapSize = gameEditor:TilemapSize()

    targetSize = NewPoint(math.ceil(mapSize.x / 4) * 4, math.ceil(mapSize.y / 4) * 4)




    if(mapSize.x ~= targetSize.x or mapSize.y ~= targetSize.y) then

      displayResizeWarning = true

    else
      OnInitCompleated()
    end

  else

    DrawRect(8, 24, 128, 48, 0, DrawMode.TilemapCache)
    DrawRect(152, 76, 3, 9, BackgroundColor(), DrawMode.TilemapCache)

    DrawRect(8, 112, 224, 96, 0, DrawMode.TilemapCache)

    DrawRect(176, 24, 64, 64, 0, DrawMode.TilemapCache)

    DrawRect(240, 92, 3, 9, BackgroundColor(), DrawMode.TilemapCache)

    pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

    pixelVisionOS:ShowMessageModal(toolName .. " Error", "The tool could not load without a reference to a file to edit.", 160, false,
      function()
        QuitCurrentTool()
      end
    )

  end



end

function ApplyTilePalette()
  if(tilePickerData.mode == 1 and tilePickerData.currentSelection > - 1) then

    -- TODO need to redraw the tile with the new color offset

    local pos = CalculatePosition(tilePickerData.currentSelection, tilePickerData.mapSize.x)
    --
    -- local tileData = gameEditor:Tile(pos.x, pos.y)
    --
    -- -- TODO need to manually loop through the tiles and apply the color offset
    --
    -- pixelVisionOS:ChangeTile(tilePickerData, pos.x, pos.y, tileData.spriteID, tilePickerData.paintColorOffset - 16)

    local total = spriteSize * spriteSize
    local tileHistory = {}

    for i = 1, total do

      local offset = CalculatePosition(i - 1, spriteSize)

      local nextCol = pos.x + offset.x
      local nextRow = pos.y + offset.y

      -- local nextSpriteID = spriteID == -1 and spriteID or CalculateIndex(spritePos.x + offset.x, spritePos.y + offset.y, spriteCols)

      local currentTile = gameEditor:Tile(nextCol, nextRow)

      local savedTile = {
        spriteID = currentTile.spriteID,
        col = nextCol,
        row = nextRow,
        colorOffset = currentTile.colorOffset,
        flag = currentTile.flag
      }

      -- TODO need to save changes to history?
      -- print("Tile History", currentTile.spriteID, nextSpriteID)
      table.insert(tileHistory, savedTile)

      -- local tile = gameEditor:Tile(nextCol, nextRow, nextSpriteID, colorOffset, flag)

      pixelVisionOS:OnChangeTile(data, nextCol, nextRow, currentTile.spriteID, tilePickerData.paintColorOffset, currentTile.flag)

    end

    UpdateHistory(tileHistory)


  end
end

function OnInitCompleated()

  -- Setup map viewport

  local mapWidth = mapSize.x * 8
  local mapHeight = mapSize.y * 8

  -- TODO need to modify the viewport to make sure the map fits inside of it correctly

  -- viewport.w = math.min(mapWidth, viewport.w)
  -- viewport.h = math.min(mapHeight, viewport.h)

  -- TODO need to account for tilemaps that are smaller than the default viewport

  tilePickerData = pixelVisionOS:CreateTilemapPicker(
    {x = viewport.x, y = viewport.y, w = viewport.w, h = viewport.h},
    {x = 8, y = 8},
    mapSize.x,
    mapSize.y,
    pixelVisionOS.colorOffset,
    "spritepicker",
    "tile",
    true,
    "tilemap"
  )

  tilePickerData.onRelease = OnTileSelection
  tilePickerData.onDropTarget = OnTilePickerDrop
  -- Need to convert sprites per page to editor's sprites per page value
  -- local spritePages = math.floor(gameEditor:TotalSprites() / 192)

  if(gameEditor:Name() == ReadSaveData("editing", "undefined")) then
    lastSystemColorSelection = tonumber(ReadSaveData("systemColorSelection", "0"))
    -- lastTab = tonumber(ReadSaveData("tab", "1"))
    -- lastSelection = tonumber(ReadSaveData("selected", "0"))
  end

  pixelVisionOS:SelectColorPage(paletteColorPickerData, 1)

  pixelVisionOS:SelectSpritePickerIndex(spritePickerData, 0)

  editorUI:SelectToggleButton(toolBtnData, 1)

  SelectLayer(1)

  ChangeSpriteID(0)

  ResetDataValidation()

end

function OnTileSelection(value)

  -- When in palette mode, change the palette page
  if(pixelVisionOS.paletteMode == true) then

    local pos = CalculatePosition(value, tilePickerData.tiles.w)

    local tileData = gameEditor:Tile(pos.x, pos.y)

    local colorPage = (tileData.colorOffset - 128) / 16

    -- print("Color Page", value, colorPage, tileData.colorOffset)

  end


end


function OnTilePickerDrop(src, dest)

  if(dest.inDragArea == false) then
    return
  end

  -- If the src and the dest are the same, we want to swap colors
  if(src.name == dest.name) then

    local srcPos = src.pressSelection

    -- Get the source color ID
    local srcTile = gameEditor:Tile(srcPos.x, srcPos.y)

    local srcIndex = srcTile.index
    local srcSpriteID = srcTile.spriteID

    local destPos = pixelVisionOS:CalculateItemPickerPosition(src)

    -- Get the destination color ID
    local destTile = gameEditor:Tile(destPos.x, destPos.y)

    local destIndex = destTile.index
    local destSpriteID = destTile.spriteID

    -- ReplaceTile(destIndex, srcSpriteID)
    --
    -- ReplaceTile(srcIndex, destSpriteID)

    pixelVisionOS:SwapTiles(tilePickerData, srcTile, destTile)

  end
end

function ToggleBackgroundColor(value)

  showBGColor = value

  tilePickerData.showBGColor = value

  pixelVisionOS:InvalidateItemPickerDisplay(tilePickerData)

  -- DrawRect(viewport.x, viewport.y, viewport.w, viewport.h, pixelVisionOS.emptyColorID, DrawMode.TilemapCache)

end

function ConfigureSpritePickerSelector(size)

  if(size < 1) then
    return
  end

  _G["spritepickerover"] = {spriteIDs = _G["spriteselection"..tostring(size) .."x"].spriteIDs, width = _G["spriteselection"..tostring(size) .."x"].width, colorOffset = 28}

  _G["spritepickerselectedup"] = {spriteIDs = _G["spriteselection"..tostring(size) .."x"].spriteIDs, width = _G["spriteselection"..tostring(size) .."x"].width, colorOffset = (_G["spritepickerover"].colorOffset + 2)}

  -- pixelVisionOS:ChangeSpritePickerSize(spritePickerData, size)
  pixelVisionOS:ChangeItemPickerScale(spritePickerData, size)

  if(tilePickerData ~= nil) then
    pixelVisionOS:ChangeItemPickerScale(tilePickerData, size)
  end

end



function ChangeMode(value)

  -- If value is true select layer 2, if not select layer 1
  SelectLayer(value == true and 2 or 1)

  -- Set the flag mode to the value
  flagModeActive = value

  -- If value is true we are in the flag mode
  if(value == true) then
    lastBGState = tilePickerData.showBGColor

    tilePickerData.showBGColor = false

    -- TODO need to disable bg menu option
    pixelVisionOS:EnableMenuItem(BGColorShortcut, false)

    pixelVisionOS:EnableMenuItem(BGColorShortcut, false)

    -- TODO need to make sure old bg color is removed
    -- DrawRect(viewport.x, viewport.y, viewport.w, viewport.h, - 1, DrawMode.TilemapCache)

    pixelVisionOS:InvalidateItemPickerDisplay(tilePickerData)

    -- editorUI:Enable(bgBtnData, false)

    -- print("Flag Mode")

    DrawFlagPage()


  else
    -- Swicth back to tile modes

    -- Restore background color state
    tilePickerData.showBGColor = lastBGState

    -- Enable bg menu option

    -- editorUI:Ena ble(bgBtnData, true)
    pixelVisionOS:EnableMenuItem(BGColorShortcut, true)


    pixelVisionOS:RebuildPickerPages(paletteColorPickerData)
    pixelVisionOS:SelectColorPage(paletteColorPickerData, 1)

  end

  flagBtnData.selected = value
  editorUI:Invalidate(flagBtnData)

  -- Clear history between layers
  ClearHistory()

end

function DrawFlagPage()

  local startX = 176 + 8
  local startY = 24

  local columns = 8

  local total = 16

  for i = 1, total do

    local pos = CalculatePosition(i - 1, columns)

    local spriteData = _G["flag".. i .. "small"]
    -- print("Flag Sprite", spriteData ~= nil)
    if(spriteData ~= nil) then

      DrawSprites(
        spriteData.spriteIDs,
        (pos.x * 8) + startX,
        (pos.y * 8) + startY,
        spriteData.width,
        false,
        false,
        DrawMode.TilemapCache
      )

    end

  end

  local pageSprites = {
    _G["pagebuttonempty"],
    _G["pagebuttonempty"],
    _G["pagebuttonempty"],
    _G["pagebuttonempty"],
    _G["pagebuttonempty"],
    _G["pagebuttonempty"],
    _G["pagebuttonempty"],
    _G["pagebutton1selectedup"],
  }

  startX = 184
  startY = 40

  for i = 1, #pageSprites do
    local spriteData = pageSprites[i]
    DrawSprites(spriteData.spriteIDs, startX + ((i - 1) * 8), startY, spriteData.width, false, false, DrawMode.TilemapCache)
  end


end


function SelectLayer(value)

  layerMode = value - 1

  -- Clear the color and sprite pickers
  pixelVisionOS:ClearItemPickerSelection(spritePickerData)
  pixelVisionOS:ClearColorPickerSelection(colorPickerData)

  -- Check to see if we are in tilemap mode
  if(layerMode == 0) then

    -- Disable selecting the color picker
    pixelVisionOS:EnableColorPicker(paletteColorPickerData, false, true)
    pixelVisionOS:EnableItemPicker(spritePickerData, true, true)

    pixelVisionOS:ClearItemPickerSelection(spritePickerData)

    pixelVisionOS:ChangeItemPickerColorOffset(tilePickerData, pixelVisionOS.colorOffset)

    if(spritePickerData.currentSelection == -1) then
      ChangeSpriteID(tilePickerData.paintTileIndex)
    end

    -- Test to see if we are in flag mode
  elseif(layerMode == 1) then

    -- Disable selecting the color picker
    pixelVisionOS:EnableColorPicker(paletteColorPickerData, true, true)
    pixelVisionOS:EnableItemPicker(spritePickerData, false, true)
    pixelVisionOS:ChangeItemPickerColorOffset(tilePickerData, 0)

    if(paletteColorPickerData.currentSelection == -1) then

      print("Select flag 0")
      editorUI:SelectPicker(flagPicker, 0)
      -- ChangeSpriteID(tilePickerData.paintFlagIndex)
    end

  end

  -- Clear background
  -- DrawRect(viewport.x, viewport.y, viewport.w, viewport.h, pixelVisionOS.emptyColorID, DrawMode.TilemapCache)

  pixelVisionOS:EnableMenuItem(QuitShortcut, false)

  gameEditor:RenderMapLayer(layerMode)

  pixelVisionOS:PreRenderMapLayer(tilePickerData, layerMode)

end

function OnSelectTool(value)

  toolMode = value

  -- Clear the last draw id when switching modes
  lastDrawTileID = -1

  lastSpriteSize = spriteSize

  local lastID = spritePickerData.currentSelection

  if(toolMode == 1) then

    -- Clear the sprite picker and tilemap picker
    pixelVisionOS:ClearItemPickerSelection(tilePickerData)

  elseif(toolMode == 2 or toolMode == 3) then

    -- Clear any tilemap picker selection
    pixelVisionOS:ClearItemPickerSelection(tilePickerData)

  end

  pixelVisionOS:ChangeTilemapPickerMode(tilePickerData, toolMode)


end

function OnNextSpriteSize(reverse)

  -- Loop backwards through the button sizes
  if(Key(Keys.LeftShift) or reverse == true) then
    spriteSize = spriteSize - 1

    -- Skip 24 x 24 selections
    if(spriteSize == 3) then
      spriteSize = 2
    end

    if(spriteSize < 1) then
      spriteSize = maxSpriteSize
    end

    -- Loop forward through the button sizes
  else
    spriteSize = spriteSize + 1

    -- Skip 24 x 24 selections
    if(spriteSize == 3) then
      spriteSize = 4
    end

    if(spriteSize > maxSpriteSize) then
      spriteSize = 1
    end
  end

  -- Find the next sprite for the button
  local spriteName = "sprite"..tostring(spriteSize).."x"

  -- Change sprite button graphic
  sizeBtnData.cachedSpriteData = {
    up = _G[spriteName .. "up"],
    down = _G[spriteName .. "down"] ~= nil and _G[spriteName .. "down"] or _G[spriteName .. "selectedup"],
    over = _G[spriteName .. "over"],
    selectedup = _G[spriteName .. "selectedup"],
    selectedover = _G[spriteName .. "selectedover"],
    selecteddown = _G[spriteName .. "selecteddown"] ~= nil and _G[spriteName .. "selecteddown"] or _G[spriteName .. "selectedover"],
    disabled = _G[spriteName .. "disabled"],
    empty = _G[spriteName .. "empty"] -- used to clear the sprites
  }

  ConfigureSpritePickerSelector(spriteSize)

  ChangeSpriteID(spritePickerData.currentSelection)

  -- Reset the flag preview
  pixelVisionOS:ChangeTilemapPaintFlag(tilePickerData, tilePickerData.paintFlagIndex)

  editorUI:Invalidate(sizeBtnData)

end

function ChangeSpriteID(value)

  -- Need to convert the text into a number
  value = tonumber(value)

  pixelVisionOS:SelectSpritePickerIndex(spritePickerData, value, false)

  if(tilePickerData ~= nil) then
    pixelVisionOS:ChangeTilemapPaintSpriteID(tilePickerData, spritePickerData.currentSelection)
  end

end

function OnSave()

  -- TODO need to save all of the colors back to the game

  -- This will save the system data, the colors and color-map
  gameEditor:Save(rootDirectory, {SaveFlags.System, SaveFlags.Colors, SaveFlags.Tilemap})-- SaveFlags.ColorMap, SaveFlags.FlagColors})

  -- Display a message that everything was saved
  pixelVisionOS:DisplayMessage("Your changes have been saved.", 5)

  -- Clear the validation
  ResetDataValidation()

end

function OnSelectSprite(value)

  -- TODO need to convert the value to the Real ID

  -- value = pixelVisionOS:CalculateItemPickerPosition(spritePickerData, value)

  pixelVisionOS:ChangeTilemapPaintSpriteID(tilePickerData, spritePickerData.pressSelection.index)

  -- if(currentTileSelection ~= nil and toolMode == 1) then
  --   -- print("Select Sprite", value, dump(currentTileSelection), currentTileSelection.index, CalculatePosition(currentTileSelection.index, mapSize.x))
  --
  --   if(Key(Keys.LeftShift)) then
  --
  --     -- TODO need to get a sample of the tile size and
  --     print("Replace all tiles")
  --
  --     -- local totalTiles = gameEditor:
  --     local total = mapSize.x * mapSize.y
  --
  --     for i = 1, total do
  --
  --       ReplaceTile(i - 1, value, currentTileSelection.spriteID)
  --
  --     end
  --
  --   else
  --
  --     ReplaceTile(currentTileSelection.index, value, currentTileSelection.spriteID)
  --
  --   end
  --
  -- end

end

function ReplaceTile(index, value, oldValue)

  local pos = CalculatePosition(index, mapSize.x)

  local tile = gameEditor:Tile(pos.x, pos.y)

  oldValue = oldValue or tile.spriteID

  if(tile.spriteID == oldValue) then

    pixelVisionOS:ChangeTile(tilePickerData, pos.x, pos.y, value, spritePickerData.colorOffset - 256)

  end

end


local lastDrawTileID = -1

function Update(timeDelta)

  -- This needs to be the first call to make sure all of the editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  editorUI:UpdateButton(paletteButton)

  -- Only update the tool's UI when the modal isn't active
  if(pixelVisionOS:IsModalActive() == false) then

    if(success == true) then

      if(Key(Keys.LeftControl) == false and Key(Keys.RightControl) == false) then
        for i = 1, #toolKeys do
          if(Key(toolKeys[i], InputState.Released)) then
            editorUI:SelectToggleButton(toolBtnData, i)
            break
          end
        end
      end

      pixelVisionOS:UpdateSpritePicker(spritePickerData)

      editorUI:UpdateButton(sizeBtnData)
      editorUI:UpdateButton(flagBtnData)
      editorUI:UpdateToggleGroup(toolBtnData)

      if(layerMode == 0) then

        pixelVisionOS:UpdateColorPicker(paletteColorPickerData)
      elseif(layerMode == 1) then
        editorUI:UpdatePicker(flagPicker)
      end

      if(IsExporting()) then
        pixelVisionOS:DisplayMessage("Saving " .. tostring(ReadExportPercent()).. "% complete.", 2)
      end

      -- gameEditor:ScrollPosition(scrollPos.x, scrollPos.y)

      if(displayResizeWarning == true) then

        showResize = true
      else

        -- TODO need to find the right picker to change the selction on


        local targetPicker = spritePickerData.picker.enabled == true and spritePickerData or flagPicker

        -- Change the scale
        if(Key(Keys.Minus, InputState.Released) and spriteSize > 1) then
          OnNextSpriteSize(true)
        elseif(Key(Keys.Plus, InputState.Released) and spriteSize < 4) then
          OnNextSpriteSize()
        end

        -- Create a new piont to see if we need to change the sprite position
        local newPos = NewPoint(0, 0)

        -- Get the sacle from the sprite picker
        local scale = spritePickerData.picker.enabled == true and spritePickerData.scale or 1

        local currentSelection = spritePickerData.picker.enabled == true and spritePickerData.currentSelection or flagPicker.selected

        -- Offset the new position by the direction button
        if(Button(Buttons.Up, InputState.Released)) then
          newPos.y = -1 * scale
        elseif(Button(Buttons.Right, InputState.Released)) then
          newPos.x = 1 * scale
        elseif(Button(Buttons.Down, InputState.Released)) then
          newPos.y = 1 * scale
        elseif(Button(Buttons.Left, InputState.Released)) then
          newPos.x = -1 * scale
        end

        -- Test to see if the new position has changed
        if(newPos.x ~= 0 or newPos.y ~= 0) then

          local curPos = CalculatePosition(currentSelection, targetPicker.columns)

          newPos.x = Clamp(curPos.x + newPos.x, 0, targetPicker.columns - 1)
          newPos.y = Clamp(curPos.y + newPos.y, 0, targetPicker.rows - 1)

          local newIndex = CalculateIndex(newPos.x, newPos.y, targetPicker.columns)

          if(spritePickerData.picker.enabled == true) then
            ChangeSpriteID(newIndex)
          else
            editorUI:SelectPicker(flagPicker, newIndex)
            -- print("Select flag", newIndex)
          end

        end

        pixelVisionOS:UpdateTilemapPicker(tilePickerData)

        if(tilePickerData.mapInvalid and invalid == false) then
          InvalidateData()
        end

        if(tilePickerData.renderingMap == true) then
          pixelVisionOS:NextRenderStep(tilePickerData)

          pixelVisionOS:DisplayMessage("Rendering Layer " .. tostring(pixelVisionOS:ReadRenderPercent(tilePickerData)).. "% complete.", 2)

          if(pixelVisionOS:ReadRenderPercent(tilePickerData) > 90) then
            pixelVisionOS:EnableMenuItem(QuitShortcut, true)

          end
          -- pixelVisionOS:InvalidateMap(tilePickerData)
        end

      end


    end
  end

end



function Draw()

  RedrawDisplay()

  -- pixelVisionOS:DrawTilemapPicker(tilePickerData, viewport, layerMode, showBGColor)



  -- The ui should be the last thing to update after your own custom draw calls
  pixelVisionOS:Draw()

  if(showResize == true) then

    showResize = false
    --
    pixelVisionOS:ShowMessageModal(toolName .. " Warning", "The tilemap will be resized from ".. mapSize.x .."x" .. mapSize.y .." to ".. targetSize.x .. "x" .. targetSize.y .. " in order for it to work in this editor. When you save the new map size will be applied to the game's data file.", 160, true,
      function(value)
        if(pixelVisionOS.messageModal.selectionValue == true) then

          mapSize = targetSize

          gameEditor:TilemapSize(targetSize.x, targetSize.y)
          OnInitCompleated()

          InvalidateData()

          displayResizeWarning = false
          showResize = false
        else

          QuitCurrentTool()
        end
      end
    )
  end

end

function OnQuit()

  if(tilePickerData.renderingMap == true) then
    return
  end

  if(invalid == true) then

    pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have unsaved changes. Do you want to save your work before you quit?", 160, true,
      function()
        if(pixelVisionOS.messageModal.selectionValue == true) then
          -- Save changes
          OnSave()

        end

        -- Quit the tool
        QuitCurrentTool()

      end
    )

  else
    -- Quit the tool
    QuitCurrentTool()
  end

end

function Shutdown()

  editorUI:Enable(tilePickerData, false)

  editorUI:Shutdown()

  -- WriteSaveData("editing", gameEditor:Name())
  -- WriteSaveData("tab", tostring(colorTabBtnData.currentSelection))
  -- WriteSaveData("selected", CalculateRealIndex(systemColorPickerData.picker.selected))

end

function UpdateHistory(tiles)

  if(#tiles == 0) then
    return
  end

  local historyAction = {
    -- sound = settingsString,
    Action = function()

      local total = #tiles

      for i = 1, total do

        local tile = tiles[i]

        pixelVisionOS:OnChangeTile(tilePickerData, tile.col, tile.row, tile.spriteID, tile.colorOffset, tile.flag)

      end

    end
  }

  pixelVisionOS:AddUndoHistory(historyAction)

  -- We only want to update the buttons in some situations
  -- if(updateButtons ~= false) then
  UpdateHistoryButtons()
  -- end

end

function OnUndo()

  local action = pixelVisionOS:Undo()

  if(action ~= nil and action.Action ~= nil) then
    action.Action()
  end

  UpdateHistoryButtons()
end

function OnRedo()

  local action = pixelVisionOS:Redo()

  if(action ~= nil and action.Action ~= nil) then
    action.Action()
  end

  UpdateHistoryButtons()
end

function UpdateHistoryButtons()

  pixelVisionOS:EnableMenuItem(UndoShortcut, pixelVisionOS:IsUndoable())
  pixelVisionOS:EnableMenuItem(RedoShortcut, pixelVisionOS:IsRedoable())

end

function ClearHistory()

  -- Reset history
  pixelVisionOS:ResetUndoHistory()
  UpdateHistoryButtons()

end

function OnPNGExport()


  local tmpFilePath = UniqueFilePath(NewWorkspacePath(rootDirectory .. "tilemap-export.png"))

  newFileModal:SetText("Export Tilemap As PNG ", string.split(tmpFilePath.EntityName, ".")[1], "Name file", true)

  pixelVisionOS:OpenModal(newFileModal,
    function()

      if(newFileModal.selectionValue == false) then
        return
      end

      local filePath = tmpFilePath.ParentPath.AppendFile( newFileModal.inputField.text .. ".png")

      SaveImage(filePath, pixelVisionOS:GenerateImage(tilePickerData))

    end
  )

  --

end
