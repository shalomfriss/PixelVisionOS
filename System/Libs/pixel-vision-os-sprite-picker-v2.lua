--
-- Copyright (c) 2017, Jesse Freeman. All rights reserved.
--
-- Licensed under the Microsoft Public License (MS-PL) License.
-- See LICENSE file in the project root for full license information.
--
-- Contributors
-- --------------------------------------------------------
-- This is the official list of Pixel Vision 8 contributors:
--
-- Jesse Freeman - @JesseFreeman
-- Christina-Antoinette Neofotistou - @CastPixel
-- Christer Kaitila - @McFunkypants
-- Pedro Medeiros - @saint11
-- Shawn Rakowski - @shwany
--

function PixelVisionOS:CreateSpritePicker(rect, tileSize, total, totalPerPage, maxPages, colorOffset, spriteName, toolTip, ignoreEmptyPages, enableDragging, dragBetweenPages)

  -- Create the generic UI data for the component
  local data = self.editorUI:CreateData(rect)

  -- Modify the name to a ColorPicker
  data.name = "SpritePicker" .. data.name

  -- data.tileSize = tileSize
  -- Pre-calculate this from the rect size and tile size
  data.totalPerPage = totalPerPage

  data.colorOffset = colorOffset

  data.maxPages = maxPages
  data.ignoreEmptyPages = ignoreEmptyPages or true
  data.lastStartX = 0
  data.lastStartY = 0
  data.currentSelection = -1

  data.vertical = rect.h < 128 and true or false -- TODO need to auto detect this value

  data.dragBetweenPages = dragBetweenPages or false
  data.pageOverTime = 0
  data.pageOverDelay = .5
  data.pageOverLast = -1

  data.spritesPerPage = 256
  data.totalSprites = data.spritesPerPage * data.totalPerPage

  data.selectedSpriteDrawArgs = {
    nil,
    0,
    0,
    8,
    8,
    false,
    false,
    DrawMode.SpriteAbove,
    self.colorOffset
  }

  data.overSpriteDrawArgs = {
    nil,
    0,
    0,
    8,
    8,
    false,
    false,
    DrawMode.Sprite,
    self.colorOffset
  }

  data.pagePosition = NewPoint(
    rect.x + rect.w,
    rect.y + rect.h
  )

  if(data.vertical == true) then

    data.slider = editorUI:CreateSlider(
      { x = rect.x + rect.w + 1, y = rect.y, w = 10, h = rect.h},
      "vsliderhandle",
      "Scroll horizontally.",
      false
    )

    data.slider.onAction = function(value)

      self:OnSpritePickerVerticalScroll(data, value)

    end

    data.pagePosition.x = data.pagePosition.x + 16
  else

    data.slider = editorUI:CreateSlider(
      { x = rect.x, y = rect.y + rect.h + 1, w = rect.w, h = 10},
      "hsliderhandle",
      "Scroll text horizontally.",
      true
    )

    data.slider.onAction = function(value)

      self:OnSpritePickerHorizontalScroll(data, value)

    end

    data.pagePosition.y = data.pagePosition.y + 16

  end

  data.picker = self.editorUI:CreatePicker(rect, tileSize.x, tileSize.y, total, spriteName, toolTip)

  data.picker.onPress = function(value)

    data.currentSelection = self:CalculateRealSpriteIndex(data, value)

    self:UpdateSelectedSpritePixelData(data)

    if(data.onSpritePress ~= nil) then
      data.onSpritePress(value)
    end

    -- TODO need to see if the mouse is over the slider before activating a drag

    -- If there is a
    if(data.onStartDrag ~= nil) then

      -- Get the slider rect
      local rect = data.slider.rect

      -- Check to see if the mouse is not inside of the slider rect
      if(self.editorUI.collisionManager:MouseInRect(rect) == false) then
        data.onStartDrag(data)
      end

    end

  end

  data.picker.onAction = function(value)

    if(data.onSpriteAction ~= nil) then
      data.onSpriteAction(value)
    end

    if(data.onEndDrag ~= nil) then
      data.onEndDrag(data)
    end

  end

  -- Create Pagination
  data.pages = editorUI:CreateToggleGroup()

  data.pages.onAction = function(value)

    local oldDragValue = data.dragging
    self:OnSpritePageClick(data, value)

    if(data.onPageAction ~= nil) then
      data.onPageAction(value)
    end


    -- Disable dragging
    data.dragging = oldDragValue


  end

  -- TODO need to figured out if we want to hide pages when they are empty?
  self:RebuildPickerPages(data, math.floor(total / data.spritesPerPage))

  -- Set up drag and drop support

  if(enableDragging == true) then
    self.editorUI.collisionManager:EnableDragging(data, .5, "SpritePicker")
  end

  return data

end

function PixelVisionOS:OnSpritePickerHorizontalScroll(data, value)

  -- Disable dragging
  data.dragging = false

  local rect = data.rect
  local spriteSize = {w = 8, h = 8}
  local width = math.floor(rect.w / spriteSize.w)

  local totalWidth = math.floor(128 / spriteSize.w)

  local scale = (data.picker.itemHeight / spriteSize.h)

  local startX = math.ceil(math.ceil((totalWidth - width) * value) / scale) * scale

  data.lastStartX = startX

  self:DrawSpritePage(data, data.pages.currentSelection, data.lastStartX)

end

function PixelVisionOS:OnSpritePickerVerticalScroll(data, value)

  -- Disable dragging
  data.dragging = false

  local rect = data.rect
  local spriteSize = {w = 8, h = 8}

  local height = math.floor(rect.h / spriteSize.h)

  local totalHeight = math.floor(128 / spriteSize.h)

  local scale = (data.picker.itemHeight / spriteSize.w)

  local startY = math.ceil(math.floor((totalHeight - height) * value) / scale) * scale

  if(data.lastStartY ~= startY) then

    data.lastStartY = startY

    self:DrawSpritePage(data, data.pages.currentSelection, 0, startY)

  end

end

function PixelVisionOS:RedrawSpritePickerPage(data)
  self:DrawSpritePage(data, data.pages.currentSelection, data.lastStartX)
end

function PixelVisionOS:OnSpritePageClick(data, pageID, select)

  select = select or 0

  -- Make sure that the value is a number
  pageID = tonumber(pageID)

  self:ClearSpritePickerSelection(data)

  self:DrawSpritePage(data, pageID)

  -- Reset last start X value
  data.lastStartX = 0

  self.editorUI:ChangeSlider(data.slider, 0, false)

  if(pageID == tmpPage and data.dragging == false) then

    data.dragging = false

  end

end

function PixelVisionOS:ResetSpritePicker(data)

  self:SelectSpritePickerSprite(data, 0)

  self:DrawSpritePage(data, 1)

  -- Reset last start X value
  data.lastStartX = 0

  self.editorUI:ChangeSlider(data.slider, 0)

end

function PixelVisionOS:ClearSpritePickerSelection(data)
  -- TODO not sure why this isn't working
  self.editorUI:ClearPickerSelection(data.picker)
end

function PixelVisionOS:UpdateSpritePicker(data)

  editorUI:UpdatePicker(data.picker)
  editorUI:UpdateToggleGroup(data.pages)

  editorUI:UpdateSlider(data.slider)

  -- We need to redraw the over selection box on top with the sprite below to clean up the overlap
  if(data.picker.overIndex > - 1) then

    data.picker.drawOver = false

    local overID = self:CalculateRealSpriteIndex(data, data.picker.overIndex)
    local scale = data.picker.itemWidth / 8

    local overPixelData = gameEditor:ReadSpriteData(overID, scale, scale)

    data.overSpriteDrawArgs[1] = overPixelData
    data.overSpriteDrawArgs[2] = data.picker.overDrawArgs[2] + data.picker.borderOffset
    data.overSpriteDrawArgs[3] = data.picker.overDrawArgs[3] + data.picker.borderOffset
    data.overSpriteDrawArgs[9] = data.colorOffset

    self.editorUI:NewDraw("DrawPixels", data.overSpriteDrawArgs)

    self.editorUI:NewDraw("DrawSprites", data.picker.overDrawArgs)

    data.picker.toolTip = "Select sprite ID " .. string.lpad(tostring(overID), #tostring(256 * data.totalPages), "0")

  end



  -- TODO need logic for displaying sprite over and selected tiles


  if(data.dragging == true and self.editorUI.collisionManager.dragTime > data.dragDelay and self.editorUI.collisionManager.mousePos.x > - 1 and self.editorUI.collisionManager.mousePos.y > - 1) then

    data.picker.overDrawArgs[2] = self.editorUI.collisionManager.mousePos.x - 4
    data.picker.overDrawArgs[3] = self.editorUI.collisionManager.mousePos.y - 4


    if(data.selectedSpritePixelData ~= nil) then

      data.selectedSpriteDrawArgs[1] = data.selectedSpritePixelData
      data.selectedSpriteDrawArgs[2] = data.picker.overDrawArgs[2] + 1
      data.selectedSpriteDrawArgs[3] = data.picker.overDrawArgs[3] + 1



      self.editorUI:NewDraw("DrawPixels", data.selectedSpriteDrawArgs)

    end

    self.editorUI:NewDraw("DrawSprites", data.picker.overDrawArgs)

    if(data.dragBetweenPages == true) then

      local pageButtons = data.pages.buttons

      for i = 1, #pageButtons do
        local tmpButton = pageButtons[i]

        local hitRect = tmpButton.rect

        if(self.editorUI.collisionManager:MouseInRect(hitRect) == true and tmpButton.enabled == true) then

          -- Test if over a new page
          if(data.pageOverLast ~= i) then

            data.pageOverLast = i
            data.pageOverTime = 0

          end

          data.pageOverTime = data.pageOverTime + self.editorUI.timeDelta

          if(data.pageOverTime > data.pageOverDelay)then
            data.pageOverTime = 0
            self:SelectSpritePickerPage(data, i)

            data.pageOverLast = i
            data.pageOverTime = 0
          end

        end

      end
    else
      -- Reset page over flag
      data.pageOverLast = -1
      data.pageOverTime = 0
    end
  end

end

function PixelVisionOS:SelectSpritePickerPage(data, value)
  editorUI:SelectToggleButton(data.pages, value)
end

function PixelVisionOS:DrawSpritePage(data, page, startX, startY)

  DrawRect(data.rect.x, data.rect.y, data.rect.w, data.rect.h, pixelVisionOS.emptyColorID, DrawMode.TilemapCache)

  local width = data.picker.rect.w
  local height = data.picker.rect.h

  local columns = width / 8
  local rows = height / 8

  startX = startX or 0
  startY = startY or 0

  local pageOffset = ((page - 1) * 16)

  local spriteID = CalculateIndex(startX, startY + pageOffset, 16)

  local pixelData = gameEditor:ReadSpriteData(spriteID, columns, rows)

  DrawPixels(pixelData, data.rect.x, data.rect.y, width, height, false, false, DrawMode.TilemapCache, data.colorOffset)


  -- Update selection

  -- Clear selection when drawing the page
  self:ClearSpritePickerSelection(data)


  local selPos = CalculatePosition(data.currentSelection, 128 / 8)

  local tmpRect = NewRect(startX, startY + pageOffset, columns, rows)

  local insideRect = tmpRect:Contains(selPos.x, selPos.y)

  if(insideRect) then

    local scale = data.picker.itemWidth / 8

    -- Offset position
    selPos.x = (selPos.x - tmpRect.x) / scale
    selPos.y = (selPos.y - tmpRect.y) / scale

    local newIndex = CalculateIndex(selPos.x, selPos.y, columns / scale)

    -- TODO no idea why I need to divide the index by the scale but it apears to work?
    self.editorUI:SelectPicker(data.picker, newIndex, false)

  end

end

function PixelVisionOS:EnableSpritePicker(data, pickerEnabled, pagesEnabled)

  self.editorUI:Enable(data.picker, pickerEnabled)

  self.editorUI:Enable(data.pages, pagesEnabled)

end

function PixelVisionOS:BuildSpritePickerPages(data, total)

  local pageCount = 0

  if(ignoreEmptyPages == false) then

    pageCount = math.floor(total / data.totalPerPage)

  else

    -- local colorCounter = 0
    local emptyColorCounter = 0

    for i = 1, total do

      local hexColor = Color(data.colorOffset + i)

      if(hexColor == self.maskColor) then -- TODO need mask color
        emptyColorCounter = emptyColorCounter + 1
      end

      local tmpTotal = data.totalPerPage - 1

      if(i % tmpTotal == 0) then

        if(emptyColorCounter ~= tmpTotal) then
          pageCount = pageCount + 1
        end

        emptyColorCounter = 0
        -- colorCounter = 0
      end

    end

  end

  self:RebuildPickerPages(data, pageCount)

end

function PixelVisionOS:CalculateRealSpriteIndex(data, value)

  -- TODO need to take scroll position into account

  value = value or data.picker.selected

  local scale = data.picker.itemWidth / 8

  local visibleWidth = math.floor(data.rect.w / data.picker.itemWidth)

  local totalWidth = math.floor(128 / data.picker.itemWidth)

  local pos = CalculatePosition(value, visibleWidth)

  pos.x = (pos.x * scale) + data.lastStartX
  pos.y = (pos.y * scale) * scale + data.lastStartY

  value = CalculateIndex(pos.x, pos.y, totalWidth)

  return value + ((data.pages.currentSelection - 1) * data.spritesPerPage)

end

function PixelVisionOS:CalculateSpritePickerPosition(data)

  local pos = self.editorUI:CalculatePickerPosition(data.picker)
  pos.index = self:CalculateRealSpriteIndex(data, pos.index)
  return pos

end

function PixelVisionOS:SelectSpritePickerSprite(data, value)


  -- Only update the sprite picker if a new selection is made
  if(data.currentSelection == value) then
    return
  end

  -- Clear the current selection
  self:ClearSpritePickerSelection(data)

  local itemSize = data.picker.itemWidth

  local total = (128 / itemSize) * (128 / itemSize)
  -- local realTotal = 128
  -- Calculate the correct page and index
  local page = math.floor(value / 256) + 1
  local index = value % total

  -- Save the new selection
  data.currentSelection = value

  self:UpdateSelectedSpritePixelData(data)

  -- Go to the correct page
  self:SelectSpritePickerPage(data, page)

  -- Calculate the scroll position

  -- TODO this is hardcoded
  local columns = 128 / itemSize
  -- local rows = 128 / 8

  -- TODO this is only working for vertical scrolling
  -- local visibleWidth = math.floor(data.rect.w / 8)
  local pos = CalculatePosition(index, columns)

  local percent = 0

  if(data.vertical == true) then
    percent = (pos.y / (columns - 1))
  else
    percent = (pos.x / (columns ))
  end

  -- Check to see if we are at the same scroll position
  if(data.slider.value == percent) then
    -- print("Force redraw")
    -- Force a page redraw (TODO maybe we can just update the selection)
    self:DrawSpritePage(data, data.pages.currentSelection, 0, data.vertical == true and data.lastStartY or data.lastStartX)

  else
    editorUI:ChangeSlider(data.slider, percent)
  end
  --

  -- Force dragging to be false
  data.dragging = false

end

function PixelVisionOS:UpdateSelectedSpritePixelData(data)

  data.selectedSpritePixelData = gameEditor:ReadSpriteData(data.currentSelection, data.picker.itemWidth / 8, data.picker.itemWidth / 8)


  -- gameEditor:Sprite(data.currentSelection)

  local total = #data.selectedSpritePixelData

  for i = 1, total do
    if(data.selectedSpritePixelData[i] == -1) then
      data.selectedSpritePixelData[i] = self.emptyColorID
    end
  end

end

function PixelVisionOS:ChangeSpritePickerSize(data, size)

  if(data == nil) then
    return
  end

  local spriteSize = size * 8

  editorUI:ResizePickerSize(data.picker, spriteSize, spriteSize)

  data.picker.overDrawArgs[1] = _G["spritepickerover"].spriteIDs
  data.picker.overDrawArgs[4] = _G["spritepickerover"].width

  data.picker.selectedDrawArgs[1] = _G["spritepickerselectedup"].spriteIDs
  data.picker.selectedDrawArgs[4] = _G["spritepickerselectedup"].width

  data.selectedSpriteDrawArgs[4] = spriteSize
  data.selectedSpriteDrawArgs[5] = spriteSize

  data.overSpriteDrawArgs[4] = spriteSize
  data.overSpriteDrawArgs[5] = spriteSize

end
