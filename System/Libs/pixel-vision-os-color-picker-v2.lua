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

-- Creating a composite component (Picker, ToggleGroup, Buttons)
function PixelVisionOS:CreateColorPicker(rect, tileSize, total, totalPerPage, maxPages, colorOffset, spriteName, toolTip, modifyPages, enableDragging, dragBetweenPages)


  -- Create the generic UI data for the component
  local data = self.editorUI:CreateData(rect)

  -- Modify the name to a ColorPicker
  data.name = "ColorPicker" .. data.name
  data.totalPerPage = totalPerPage
  data.visiblePerPage = totalPerPage
  data.colorOffset = colorOffset
  data.tileSize = tileSize
  data.maxPages = maxPages
  data.pageToolTipTemplate = "Select color page "
  data.dragBetweenPages = dragBetweenPages or false
  data.pageOverTime = 0
  data.pageOverDelay = .5
  data.pageOverLast = -1
  data.toolTip = toolTip

  -- Total items in the picker
  data.total = total

  -- Create a picker with 0 items in it
  data.picker = self.editorUI:CreatePicker(rect, tileSize.x, tileSize.y, 0, spriteName, toolTip)

  data.picker.onPress = function(value)

    data.currentPress = self:CalculateRealColorIndex(data, value)
    data.currentSelection = self:CalculateRealColorIndex(data, value)

    if(data.onColorPress ~= nil) then
      data.onColorPress(value)
    end

    if(data.onStartDrag ~= nil) then
      data.onStartDrag(data)
    end
  end

  data.picker.onAction = function(value)

    if(data.currentPress == nil) then
      return
    end
    -- Clear current press
    data.currentPress = nil

    -- Trigger action
    if(data.onColorAction ~= nil) then
      data.onColorAction(value)
    end

    if(data.onEndDrag ~= nil) then
      data.onEndDrag(data)
    end

  end

  -- Create Pagination
  data.pages = editorUI:CreateToggleGroup()
  data.pages.onAction = function(value)

    self:OnColorPageClick(data, value)

    if(data.onPageAction ~= nil) then
      data.onPageAction(value)
    end

  end

  data.pagePosition = NewPoint(
    rect.x + rect.w,
    rect.y + rect.h
  )

  if(modifyPages == true) then
    self:CreateModifyPageButtons(data)
  end

  self:RebuildPickerPages(data)

  if(enableDragging == true) then
    self.editorUI.collisionManager:EnableDragging(data, .5, "ColorPicker")
  end

  -- Disable buttons by default
  self:UpdateModifyPageButtonState(data)

  return data

end

function PixelVisionOS:CreateModifyPageButtons(data)

  -- Shift page buttons over by two
  data.pagePosition.x = data.pagePosition.x - 16

  data.addPageButton = self.editorUI:CreateButton(
    {x = 120, y = 216},
    "pagebuttonadd",
    "Add a new page."
  )

  data.addPageButton.onAction = function()

    data.totalPages = data.totalPages + 1

    if(data.onAddPage ~= nil) then
      data.onAddPage(data)
    end

    self:RebuildPickerPages(data)

    self:UpdateModifyPageButtonState(data)

    editorUI:SelectToggleButton(data.pages, data.totalPages)

  end

  data.removePageButton = self.editorUI:CreateButton(
    {x = 128, y = 216},
    "pagebuttonminus",
    "Remove the last page."
  )

  data.removePageButton.onAction = function()
    -- print("Remove page")

    data.totalPages = data.totalPages - 1

    data.total = data.total - data.totalPerPage

    if(data.onRemovePage ~= nil) then
      data.onRemovePage(data)
    end

    self:RebuildPickerPages(data)

    self:UpdateModifyPageButtonState(data)

    editorUI:SelectToggleButton(data.pages, data.totalPages)

  end


end

function PixelVisionOS:UpdateModifyPageButtonState(data)

  if(data.addPageButton ~= nil) then
    editorUI:Enable(data.addPageButton, data.totalPages < data.maxPages)
  end

  if(data.removePageButton ~= nil) then
    editorUI:Enable(data.removePageButton, data.totalPages > 0)
  end

end

function PixelVisionOS:OnColorPageClick(data, pageID, select)

  select = select or 0

  -- Make sure that the value is a number
  pageID = tonumber(pageID)

  local maxTotal = pageID * data.totalPerPage

  local newTotal = math.min(data.totalPerPage, data.visiblePerPage)

  if(maxTotal > data.total) then
    newTotal = newTotal - (maxTotal - data.total)
  end

  data.picker.total = newTotal

  self:DrawColorPage(data, pageID)

  self:ClearColorPickerSelection(data)

  if(data.currentSelection ~= nil) then

    local tmpPage = math.ceil(data.currentSelection / data.totalPerPage)

    if(pageID == tmpPage and data.dragging == false) then

      self.editorUI:SelectPicker(data.picker, data.currentSelection % data.totalPerPage)
      -- Force dragging to be false
      data.dragging = false

    end

  end

end


function PixelVisionOS:UpdateColorPicker(data)

  editorUI:UpdateToggleGroup(data.pages)
  editorUI:UpdatePicker(data.picker)

  if(data.addPageButton ~= nil) then
    editorUI:UpdateButton(data.addPageButton)
  end

  if(data.removePageButton ~= nil) then
    editorUI:UpdateButton(data.removePageButton)
  end

  -- Update color palette to reflect color selector
  if(data.currentPress ~= nil) then

    local colorID = data.currentPress + data.colorOffset

    if(Color(colorID) ~= self.maskColor) then
      ReplaceColor(50, colorID)
      ReplaceColor(51, colorID)
    else
      ReplaceColor(50, 11)
      ReplaceColor(51, 15)
    end

  end

  if(data.picker.overIndex > - 1) then

    colorID = pixelVisionOS:CalculateRealColorIndex(data, data.picker.overIndex) + data.colorOffset

    data.picker.toolTip = data.toolTip .. string.lpad(tostring((colorID - 256)), 3, "0")

    if(Color(colorID) ~= self.maskColor) then
      ReplaceColor(46, colorID)
      ReplaceColor(47, colorID)
    else
      ReplaceColor(46, 11)
      ReplaceColor(47, 15)
    end


  end

  if(data.dragging == true and self.editorUI.collisionManager.dragTime > data.dragDelay) then

    data.picker.overDrawArgs[2] = self.editorUI.collisionManager.mousePos.x - 10
    data.picker.overDrawArgs[3] = self.editorUI.collisionManager.mousePos.y - 10
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
            self:SelectColorPage(data, i)

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

function PixelVisionOS:DrawColorPage(data, page)

  -- Default to the currently selected page
  page = page or data.pages.currentSelection

  local startID = data.colorOffset - 1
  local total = data.picker.total
  local pageOffset = page
  local rect = data.rect
  local tileSize = data.tileSize
  local totalPixels = tileSize.x * tileSize.y
  local width = math.floor(rect.w / tileSize.x)
  local height = math.floor(rect.h / tileSize.y)
  local totalItems = width * height
  local pixelData = {}
  local x = 0
  local y = 0

  for i = 1, totalItems do

    -- Lua loops start at 1 but we need to start at 0
    index = i - 1

    x = (index % width) * tileSize.x + rect.x
    y = math.floor(index / width) * tileSize.y + rect.y

    local pageOffset = ((pageOffset - 1) * data.totalPerPage)
    local colorID = i + pageOffset

    if(i <= total and i <= data.visiblePerPage) then

      -- Shift the color ID over to the correct position
      colorID = colorID + startID

      -- We use a special
      if(Color(colorID) == self.maskColor) then
        -- print("Draw Mask Color", self.maskColor)
        DrawSprites(emptymaskcolor.spriteIDs, x, y, emptymaskcolor.width, false, false, DrawMode.TilemapCache)
      else

        for j = 1, totalPixels do
          pixelData[j] = colorID
        end
        DrawPixels(pixelData, x, y, tileSize.x, tileSize.y, false, false, DrawMode.TilemapCache, 0)
      end

    else
      DrawSprites(emptycolor.spriteIDs, x, y, emptycolor.width, false, false, DrawMode.TilemapCache)
    end

  end

end

function PixelVisionOS:ClearColorPickerSelection(data)

  if(data == nil) then
    return
  end

  self.editorUI:ClearPickerSelection(data.picker)

  data.currentSelection = -1

end

function PixelVisionOS:ChangeColorPickerTotal(data, value)

  data.total = value

  local currentPage = data.pages.currentSelection

  self:RebuildPickerPages(data)

  self:SelectColorPage(data, currentPage)

end

function PixelVisionOS:RebuildPickerPages(data, totalPages)

  -- If the total colors are 0, make the total pages 0 too
  if(data.total == 0) then

    data.totalPages = 0

  else

    -- If there are colors, calculate the correct number of pages
    data.totalPages = totalPages ~= nil and totalPages or math.ceil(data.total / data.totalPerPage)

    if(data.totalPages > data.maxPages) then
      data.totalPages = data.maxPages
    end

  end

  local totalPages = data.totalPages
  local position = data.pagePosition
  local maxPages = data.maxPages or 10
  local toolTipTemplate = data.pageToolTipTemplate or "Select page "

  if(data == nil or data.pages == nil) then
    return
  end

  -- Clear all the existing buttons
  editorUI:ClearToggleGroup(data.pages)

  -- Need to shift the offset to the left
  local tmpPosX = position.x - (maxPages * 8)

  -- Create new pagination buttons
  for i = 1, maxPages do

    local pageID = totalPages - (maxPages - (i - 1)) + 1

    local offsetX = ((i - 1) * 8) + tmpPosX
    local rect = {x = offsetX, y = position.y, w = 8, h = 16}

    if(pageID < 1) then
      DrawSprites(pagebuttonempty.spriteIDs, rect.x, rect.y, pagebuttonempty.width, false, false, DrawMode.TilemapCache)
    else
      editorUI:ToggleGroupButton(data.pages, rect, "pagebutton" .. tostring(pageID), toolTipTemplate .. tostring(pageID))
    end
  end

end

function PixelVisionOS:SelectColorPickerColor(data, value)

  -- Force dragging to be false
  data.dragging = false

  -- Calculate the correct page
  local page = math.floor(value / (data.totalPerPage)) + 1

  -- Select the right page
  self:SelectColorPage(data, page)

  -- Select the color on the page
  self.editorUI:SelectPicker(data.picker, value % data.totalPerPage)

end

function PixelVisionOS:CalculateColorPickerPosition(data)

  local pos = self.editorUI:CalculatePickerPosition(data.picker)
  pos.index = self:CalculateRealColorIndex(data, pos.index)
  return pos

end

function PixelVisionOS:SelectColorPage(data, value)
  self.editorUI:SelectToggleButton(data.pages, value)
end

function PixelVisionOS:CalculateRealColorIndex(data, value)

  value = value or data.picker.selected

  return value + ((data.pages.currentSelection - 1) * data.totalPerPage)

end

function PixelVisionOS:AddNewColorToPicker(data)

  self:ChangeColorPickerTotal(data, data.total + 1)

end

function PixelVisionOS:RemoveColorFromPicker(data)

  self:ChangeColorPickerTotal(data, data.total - 1)

end

function PixelVisionOS:EnableColorPicker(data, pickerEnabled, pagesEnabled)

  self.editorUI:Enable(data.picker, pickerEnabled)
  self.editorUI:Enable(data.pages, pagesEnabled)

end
