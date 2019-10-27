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

function PixelVisionOS:CreateTitleBar(x, y, title, product)

  local data = {} -- our new object

  data.pos = {
    x = x or 0,
    y = y or 0
  }

  data.invalid = true
  data.textColorOffset = 15
  data.font = "medium"
  data.lastTimeStamp = ""
  data.timeDelay = .3
  data.time = .3
  data.invalid = true
  data.showTimeDivider = true
  data.productName = product or SystemName()
  data.title = title or "Untitled"
  data.debugTime = ReadBiosData("DebugTime") == "True"

  data.productDrawArgs = {
    data.productName,
    20,
    1,
    DrawMode.TilemapCache,
    data.font,
    data.textColorOffset,
    - 4
  }

  data.timeDrawArgs = {
    "",
    0,
    1,
    DrawMode.TilemapCache,
    data.font,
    data.textColorOffset,
    - 4
  }

  data.muteDrawArgs = {
    titlebarvolumeon.spriteIDs,
    172,
    0,
    titlebarvolumeon.width,
    false,
    false,
    DrawMode.TilemapCache,
  }

  data.titleIconDrawArgs = {
    0,
    23,
    2,
    false,
    false,
    DrawMode.TilemapCache,
  }

  data.titleDrawArgs = {
    data.title,
    23 + 8,
    1,
    DrawMode.TilemapCache,
    "medium",
    data.textColorOffset,
    - 4
  }

  -- Create the time mask sprite data
  local timeMask = {}

  for i = 1, 8 * 4 do
    timeMask[i] = 0
  end

  data.timeMaskDrawArgs = {
    timeMask,
    208,
    0,
    4,
    8,
    false,
    false,
    DrawMode.Sprite,
    0
  }

  self.editorUI:Invalidate(data)

  -- Draw background
  local spriteData = _G["titlebarbackground"]

  if(spriteData ~= nil) then
    self.editorUI:NewDraw("DrawSprites", {spriteData.spriteIDs, 0, 0, spriteData.width, DrawMode.TilemapCache})
  end

  -- Fix scope for lamda functions below
  local this = self

  -- Create mute button
  data.iconButton = self.editorUI:CreateButton({x = 8, y = 0}, "pv8toolbaricon", "Options and shortcuts for this tool.")

  data.iconButton.hitRect = {x = 8, y = 0, w = 13, h = 11}
  data.iconButton.onPress = function()
    -- print("Show menu")
    this.titleBar.menu.showMenu = true
  end
  data.iconButton.onAction = function(value)
    this.titleBar.menu.showMenu = false
    data.iconButton.toolTip = this.titleBar.menu.defaultToolTip
  end

  -- Disable the button but default until the tool creates an option menu
  self.editorUI:Enable(data.iconButton, false)

  -- Create mute button
  data.muteBtnData = self.editorUI:CreateButton({x = data.muteDrawArgs[2], y = data.muteDrawArgs[3]}, "", "Toggle systme wide mute.")
  data.muteBtnData.hitRect = {x = data.muteDrawArgs[2], y = data.muteDrawArgs[3], w = 8, h = 11}

  data.muteBtnData.onAction = function()
    local value = Mute(not Mute())

    WriteBiosData("Mute", value == true and "True" or "False")

    this.lastMuteValue = nil
  end

  data.muteBtnData.selected = Mute()

  return data

end

function PixelVisionOS:CreateTitleBarMenu(items, toolTip)

  -- Get a reference to the iconButton
  local iconButton = self.titleBar.iconButton

  self.editorUI:Enable(iconButton, true)
  iconButton.toolTip = toolTip

  -- TODO Button draws should always happen on the first frame? (This breaks in tilemap tool since it loads in wait mode)
  -- Force this to draw just incase the tool loads up in wait mode
  self.editorUI:UpdateButton(iconButton)

  local data = {
    options = items,
    menuSelection = -1,
    showMenu = false,
    defaultToolTip = toolTip,
    shortcuts = {}
  }

  -- Get the total number of options
  local totalOptions = #data.options

  local itemHeight = 9
  local dividerHeight = 4

  local tmpW = 92
  local tmpH = 0

  for i = 1, totalOptions do

    local tmpOption = data.options[i]

    tmpOption.height = tmpOption.divider == true and dividerHeight or itemHeight

    tmpOption.y = tmpH

    tmpH = tmpH + tmpOption.height

  end

  -- Create menu canvas
  local canvas = NewCanvas(tmpW, tmpH + 10)

  -- Set the canvas stroke to be 2 x 2 pixels wide
  canvas:SetStroke({0, 0, 0, 0}, 2, 2)

  -- Create a solid background pattern
  canvas:SetPattern({12}, 1, 1)

  -- Draw border
  canvas:DrawSquare(0, 0, canvas.width - 8, canvas.height - 8, true)
  canvas.wrap = false

  local tmpCanvas = NewCanvas(canvas.width - 10, itemHeight)
  tmpCanvas.wrap = false

  local pos = NewPoint(6, 9)

  for i = 1, totalOptions do

    local option = data.options[i]

    if(option.key ~= nil) then
      table.insert(data.shortcuts, option.key)
    end

    local tmpX, tmpY = 2, option.y + 2

    -- Create up pixel data
    tmpCanvas:Clear()

    -- Draw the up state
    self:DrawTitleBarMenuItem(tmpCanvas, option, 14)

    canvas:MergePixels(tmpX, tmpY, tmpCanvas.width, tmpCanvas.height, tmpCanvas:GetPixels(), false, false, 0, true)

    if(option.divider ~= true) then
      -- Create over pixel data
      tmpCanvas:Clear(14)

      option.rect = NewRect(
        tmpX + pos.x,
        tmpY + pos.y - 2,
        tmpCanvas.width,
        tmpCanvas.height
      )

      -- Draw the over state
      self:DrawTitleBarMenuItem(tmpCanvas, option)

      -- Save the over state
      option.overPixelData = 
      {
        tmpCanvas:GetPixels(),
        tmpX + pos.x,
        tmpY + pos.y,
        tmpCanvas.width,
        tmpCanvas.height,
        false,
        false,
        DrawMode.SpriteAbove
      }
    end

  end

  data.canvas = canvas

  data.menuDrawArgs = {
    canvas.GetPixels(),
    pos.x,
    pos.y,
    canvas.width,
    canvas.height,
    false,
    false,
    DrawMode.SpriteAbove,
    0
  }

  -- adjust the rect to match the correct layout position
  -- Save the menu values to the data object
  data.rect = NewRect(pos.x - 2, pos.y + 2, data.menuDrawArgs[4] - 4, data.menuDrawArgs[5] - 4)

  -- Save data back to the title bar data object
  self.titleBar.menu = data

  -- The menu is create so reset its validation
  self.editorUI:ResetValidation(data)

  return data

end

function PixelVisionOS:DrawTitleBarMenuItem(canvas, option, bgColor2)

  local bgColor = 12
  bgColor2 = option.enabled == false and 11 or bgColor2

  local divColor = 5
  local t1Color = option.enabled == false and 11 or 0
  local t2Color = t2Color or 12
  local divWidth = canvas.width

  if(option.divider == true) then
    canvas:SetStroke({divColor}, 1, 1)
    local y = 2
    canvas:DrawLine(0, y, canvas.width, y)
  else

    canvas:DrawText(option.name:upper(), 4, 0, "medium", t1Color, - 4)

    if(option.key ~= nil) then

      canvas:SetStroke({bgColor2}, 1, 1)
      if(bgColor2 ~= nil) then
        canvas:SetPattern({bgColor2}, 1, 1)
      end

      local tmpX = canvas.width - 4 - 13
      local tmpY = 1

      canvas:DrawSquare(tmpX, tmpY, tmpX + 13, tmpY + 5, true)

      canvas:DrawText(("^" .. tostring(option.key)):upper(), tmpX + 3, tmpY - 1, "small", t2Color, - 4)

    end

  end

end

function PixelVisionOS:UpdateTitleBar(data, timeDelta)

  -- Keep track of time passed since last frame
  data.time = data.time + timeDelta

  -- Enable and disable elements based on the status of any active modals
  if(self:IsModalActive() == true) then
    self.editorUI:Enable(data.muteBtnData, false)
  else
    self.editorUI:Enable(data.muteBtnData, true)
  end

  -- Only update these buttons if the mouse is not in wait mode
  if(self.editorUI.mouseCursor.cursorID ~= 5) then

    -- Update buttons
    self.editorUI:UpdateButton(data.iconButton)
    self.editorUI:UpdateButton(data.muteBtnData)

  end

  self:DrawTitleBar(data)

  local menuData = self.titleBar.menu

  if(menuData ~= nil) then

    -- Loop through all the options and see what needs to be done

    if(menuData.showMenu ~= false) then

      -- First, we want to test that the iconButton hasn't lost focus
      if(data.iconButton.inFocus == false) then

        menuData.showMenu = false
        -- Restore default tooltip

        data.iconButton.toolTip = menuData.defaultToolTip

        if(menuData.menuSelection > 0) then
          local option = menuData.options[menuData.menuSelection]

          if(option.action ! = nil) then
            option.action()
          end
        end

      end

    end

    local mousePos = MousePosition()

    -- If we are showing the menu, reset the selction and tooltip
    if(menuData.showMenu == true) then

      -- Reset mouse selection while we loop through all the options
      menuData.menuSelection = -1

      -- Clear the icon button's tooltip
      data.iconButton.toolTip = ""

    end

    for i = 1, #menuData.options do

      local option = menuData.options[i]

      -- First, check to see if there is a shortcut key
      if(option.key ~= nil and option.enabled ~= false and self:IsModalActive() == false) then

        -- Either the left or right control key needs to be down
        local triggerShortcut = Key(Keys.LeftControl) or Key(Keys.RightControl)

        -- If you can trigger the shortcut, check to see if a key was released
        if(triggerShortcut and Key(option.key, InputState.Released)) then

          -- Call the option's action function
          if(option.action ~= nil) then
            option.action()

            -- Exit the for loop
            break

          end

        end

      end
      if(option.enabled ~= false) then
        -- Test for collision
        if(menuData.showMenu == true and option.rect ~= nil and option.rect.Contains(mousePos.x, mousePos.y)) then

          -- Update menu selection
          menuData.menuSelection = i

          -- Update the icon button's tool tip
          data.iconButton.toolTip = option.toolTip

          if(option.subMenuOptions ~= nil) then

            menuData.showSubMenu = i
            print("has sub menu", option.subMenuOptions ~= nil, option.rect.x)

          end


          break
        end
      end

    end

  end

  if(data.time > data.timeDelay) then

    local newTimeStamp = data.debugTime == true and "08:00AM" or string.upper(os.date("%I:%M%p"))

    if(newTimeStamp ~= data.lastTimeStamp) then

      -- Clears the time tiles first
      UpdateTiles(25, 0, 4, { 0, 0, 0, 0})

      DrawText(newTimeStamp, 200, 1, DrawMode.TilemapCache, "medium", data.textColorOffset, - 4)

      data.lastTimeStamp = newTimeStamp

    end

    if(data.showTimeDivider == true) then
      data.showTimeDivider = false
    else
      data.showTimeDivider = true
    end
    data.time = 0
  end

end

function PixelVisionOS:EnableMenuItemByName( name, value)

  local options = self.titleBar.menu.options

  local total = #options

  for i = 1, total do

    local option = options[i]

    if(option.name == name) then

      if(option.enabled ~= value) then
        option.enabled = value
        self.editorUI:Invalidate(self.titleBar.menu)
      end

    end

  end

end

function PixelVisionOS:EnableMenuItem( id, value)

  local menuData = self.titleBar.menu

  if(menuData.options[id].enabled ~= value) then

    local option = self.titleBar.menu.options[id]

    menuData.options[id].enabled = value

    self.editorUI:Invalidate(menuData)

  end

end

function PixelVisionOS:DrawTitleBar(data)

  local menuData = self.titleBar.menu

  -- Redraw the menu bar
  if(menuData ~= nil and menuData.invalid == true) then

    menuData = self:CreateTitleBarMenu(menuData.options, menuData.defaultToolTip)

    self.editorUI:ResetValidation(menuData)

  end

  if(data.invalid == true) then
    local displayWidth = Display().x
    local offsetRight = 8
    local charWidth = 4
    local date = ReadBiosData("DebugTime") == "True" and string.upper(os.date("SAT         1985")) or string.upper(os.date("%a         1985"))

    offsetRight = ((#date * charWidth) + offsetRight)

    data.timeDrawArgs[1] = string.upper(date)
    data.timeDrawArgs[2] = displayWidth - offsetRight,

    self.editorUI:NewDraw("DrawText", data.timeDrawArgs)

    -- Draw title icon
    if(data.titleIcon ~= nil) then
      data.titleIconDrawArgs[1] = data.titleIcon
      self.editorUI:NewDraw("DrawSprite", data.titleIconDrawArgs)
    end

    -- Draw title text
    local nameWidth = #data.title * charWidth
    data.titleDrawArgs[1] = string.upper(data.title)
    self.editorUI:NewDraw("DrawText", data.titleDrawArgs)

    data.lastTimeStamp = ""

    -- Reset the titlebar validation
    self.editorUI:ResetValidation(data)
  end

  if(data.showTimeDivider == true) then

    self.editorUI:NewDraw("DrawPixels", data.timeMaskDrawArgs)

  end

  -- TODO need to make sure this is cached in the lua bridge somewhere?
  local newMuteValue = Mute()

  if(self.lastMuteValue ~= newMuteValue) then

    data.muteDrawArgs[1] = newMuteValue and titlebarvolumeoff.spriteIDs or titlebarvolumeon.spriteIDs

    self.editorUI:NewDraw("DrawSprites", data.muteDrawArgs)
    self.lastMuteValue = newMuteValue

  end

  local menuData = self.titleBar.menu

  if(menuData ~= nil and menuData.showMenu ~= false) then

    menuData.canvas:DrawPixels(menuData.menuDrawArgs[2], menuData.menuDrawArgs[3], DrawMode.UI)

    if(menuData.menuSelection > 0) then
      local pixelData = menuData.options[menuData.menuSelection].overPixelData

      if(pixelData ~= nil)then
        self.editorUI:NewDraw("DrawPixels", pixelData)
      end

    end

  end


end
