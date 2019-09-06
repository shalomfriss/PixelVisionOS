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

function EditorUI:CreateInputField(rect, text, toolTip, pattern, font, colorOffset)

  -- If no hight is provided, simply make the height one row high
  if(rect.h == nil) then
    rect.h = self.spriteSize.y
  end

  local data = self:CreateInputArea(rect, nil, toolTip, font, colorOffset)

  -- Create a unique name by removing the InputArea string from the data's name
  data.name = "InputField" .. data.name:sub(10, - 1)

  data.multiline = data.tiles.h > 1
  data.maxLines = data.tiles.h

  data.nextField = nil
  data.previousField = nil
  data.clearValue = ""
  data.clearOnEnter = false
  data.allowEmptyString = false
  data.forceCase = nil -- Accepts nil, upper and lower
  data.colorize = false

  data.pattern = pattern
  data.patterns = {
    hex = '%x',
    number = '%d',
    file = '[_%-%w]',
    keys = '%a',
    note = '[A-G#]'
  }

  -- Make sure the component has a default text value
  -- data.text = self:TextEditorExport(data)

  -- Remap return
  data.keymap["return"] = function(targetData)
    --print("Submit Field Value")

    -- TODO need to validate the value before saving

    -- Save value to text property
    data.text = self:TextEditorExport(targetData)

    -- Stop editing via the input field's custom method
    self:EditTextEditor(data, false)

    -- if targetData.sxs then self:TextEditorDeleteSelection(targetData) end
    -- self:TextEditorInsertNewLine(targetData)
  end

  -- Remap up to home
  data.keymap["up"] = data.keymap["home"]

  -- Remap down to end
  data.keymap["down"] = data.keymap["end"]

  data.captureInput = function(targetData)


    local inputString = InputString()
    local outputString = ""

    for char in inputString:gmatch"." do

      local pattern = targetData.patterns[targetData.pattern]

      if(pattern ~= nil) then
        char = string.match(char, pattern)
      end

      if(char ~= nil) then

        if(targetData.forceCase ~= nil) then
          char = string[targetData.forceCase](char)
        end

        -- Text to see if the input field is a single character and clear it
        if(targetData.tiles.w == 1) then
          targetData.buffer[1] = char
        end

        -- Test to see if we are at the end of the input field
        if(#targetData.buffer[1] + 1 < targetData.tiles.w or targetData.sxs) then
          outputString = outputString .. char
          -- end
        else
          --print(targetData.name, "Close input field")
          self:EditTextEditor(targetData, false)
          return ""
        end

      end

    end

    return outputString
  end

  data.onEdit = function(targetData, value)
    -- print("Input Field Edit", value)
    self:OnEditTextInputField(targetData, value)

  end
  -- override key callbacks for input fields

  -- data.onEdit = function(data, value)
  --   self:EditTextEditor(data, value)
  -- end
  --
  -- data.onTab = function(data)
  --
  --   -- TODO need to test to see if shift key is down to go back
  --
  --   -- Move over to the next input field
  --   if(data.nextField ~= nil) then
  --     self:EditTextEditor(data.previousField, true)
  --   end
  --
  -- end
  --
  -- data.onUpArrow = function(data)
  --   self:InputAreaMoveCursorTo(data, 0, 0 )
  -- end
  --
  -- data.onDownArrow = function(data)
  --   self:InputAreaMoveCursorTo(data, data.width, 0 )
  -- end
  --
  -- data.onReturn = function(data)
  --   self:EditTextEditor(data, false)
  -- end
  --
  -- data.onInsertChar = function(data, char)
  --   self:InputFieldInsertChar(data, char)
  -- end
  --
  -- We want to route the default text through ChangeInputField
  if(text ~= nil) then
    self:ChangeInputField(data, text)
  end

  return data

end

function EditorUI:OnEditTextInputField(data, value)

  data.previousValue = data.buffer[1]

  --print(data.name, "editing", value, "value", data.previousValue)

  -- Test to see if we are entering edit mode
  if(value == true) then

    -- Stop the blinker from drawing
    -- data.bflag = false
    --print("Select all")
    -- Select all the text
    self:TextEditorSelectAll(data)
  elseif(value == false and data.editing == true) then

    self:TextEditorGotoLineStart(data)
    -- If we were just editing, force the buffer back through the valdation
    self:ChangeInputField(data, data.buffer[1], false)
  end

  -- self:EditTextEditor(data, value, false)

end

function EditorUI:UpdateInputField(data)

  self:UpdateInputArea(data)

  -- -- Exit if there is no data to render the input field
  -- if(data == nil) then
  --   return
  -- end
  --
  -- -- If the input field is disabled we need to see if it should be redrawn and then exit
  -- if(data.enabled == false ) then
  --   self:DrawInputArea(data)
  --   return
  -- end
  --
  -- -- Do the first test to see if we are in the right area to detect a collision
  -- -- if(self.collisionManager.hovered == data.flagID) then
  --
  -- local overrideFocus = (data.inFocus == true and self.collisionManager.mouseDown)
  --
  -- -- print("Inside Text", data.name)
  -- -- Ready to test finer collision if needed
  -- if(self.collisionManager:MouseInRect(data.rect) == true or overrideFocus) then
  --
  --   -- Set focus
  --   if(self.inFocusUI == nil) then
  --
  --     self:SetFocus(data, data.editable == false and 1 or 3)
  --
  --
  --   end
  --
  --
  --   -- self.cursorID = 3
  --
  --   if(self.collisionManager.mouseReleased == true and data.editing == false) then
  --
  --     --print("Click to edit")
  --     self:InputAreaMoveCursorToMousePos(data)
  --
  --     -- Enter edit mode
  --     self:EditTextEditor(data, true)
  --
  --   end
  --
  -- else
  --
  --   -- If the mouse is not in the rect, clear the focus
  --   if(data.inFocus == true) then
  --     self:ClearFocus(data)
  --   end
  --
  -- end
  --
  -- -- else
  -- --   -- If the mouse isn't over the component clear the focus
  -- --   -- self:ClearFocus(data)
  -- --
  -- -- end
  --
  -- if(data.editing == true) then
  --
  --   if(self.collisionManager.mouseReleased == true ) then
  --
  --     if(data.inFocus == false)then
  --       self:EditTextEditor(data, false)
  --     else
  --       -- Update the mouse cursor
  --       self:InputAreaMoveCursorToMousePos(data)
  --     end
  --
  --   else
  --
  --     local lastInput = data.captureInput()
  --
  --     if(lastInput ~= "") then
  --
  --       self:InputAreaOnInput(data, lastInput)
  --
  --     end
  --
  --     self:InputAreaKeyCapture(data)
  --
  --     -- if we are in edit mode, we need to update the cursor blink time
  --     data.blinkTime = data.blinkTime + self.timeDelta
  --
  --     if(data.blinkTime > data.blinkDelay) then
  --       data.blinkTime = 0
  --       data.blink = not data.blink
  --
  --     end
  --
  --   end
  --
  -- end
  --
  -- self:DrawInputArea(data)

end

-- function EditorUI:InputFieldInsertChar(data, char)
--
--   local pattern = data.patterns[data.pattern]
--
--   if(pattern ~= nil) then
--     char = string.match(char, pattern)
--   end
--
--   if(data.forceCase ~= nil) then
--     char = string[data.forceCase](char)
--   end
--
--   if(char ~= nil) then
--     self:InputAreaInsertChar(data, char)
--     --lineWidth + 1
--
--     -- Test to see if we are at the end of the input field
--     if(#data.lines[1] >= data.width) then
--
--       self:EditTextEditor(data, false)
--
--     end
--
--   end
--
-- end

-- function EditorUI:EditTextEditor(data, value, callChild)
--
--   -- TODO need to scroll the input field back to the start position
--
--
--
--   --
--   --   -- TODO need to test to see if there is something already in focus
--   --
--   -- Don't enable editing if editable is set to false
--   if(data.editable == false) then
--     return
--   end
--
--   -- TODO need to see if the input field is empty and restore the previous value
--   if(value == false) then
--
--     if(data.buffer[1] == "" or data.buffer == nil) then
--       --print(data.name, "Restore previous text", data.buffer[1], data.text)
--
--       data.buffer[1] = data.text
--       self:TextEditorInvalidateBuffer(data)
--
--     end
--
--     self:TextEditorGotoLineStart(data)
--
--     -- Update text value
--     text = self:TextEditorExport(data)
--
--   end
--
--
--   if(callChild ~= false) then
--     self:EditTextEditor(data, value)
--   end


--
--   -- Need to make sure we are not currently editing another field
--   if(value == true) then
--
--     -- Look to see if a field is being edited
--     if(self.editingField ~= nil) then
--
--       -- Exit field's edit mode
--       self:EditTextEditor(self.editingField, false)
--
--     end
--
--     -- Set new field to edit mode
--     self.editingField = data
--
--   else
--     self.editingField = nil
--   end
--
--   -- change the edit mode to the new value
--   data.editing = value
--
--   -- Force the text field to redraw itself
--   self:Invalidate(data)
--
--   -- If editing mode is false, shut it down
--   if(data.editing == false) then
--
--     data.blink = false
--
--     local newText = data.lines[1]
--
--     if(newText == "" and data.allowEmptyString == false) then
--
--       newText = data.defaultValue
--
--     end
--
--     -- local newText = data.lines[1] == "" and data.defaultValue or data.lines[1]
--
--     self:ChangeInputField(data, newText)
--
--     -- TODO need to scroll to the beginning of the field when exiting
--   else
--
--     -- Update the blink time
--     data.blinkTime = 0
--     data.blink = true
--
--     -- Save a copy of the current line of text
--     data.defaultValue = data.lines[1]
--
--     if(data.clearOnEnter == true) then
--       data.defaultValue = data.clearValue
--     end
--
--     -- Clear the current text from the field
--     data.lines[1] = ""
--
--     -- Move the cursor to the first character
--     self:InputAreaMoveCursorTo(data, 0, 0)
--   end
--
-- end

function EditorUI:ChangeInputField(data, text, trigger)
  -- Input fields need to process the text before setting it

  -- print(data.name, "Change Input Field")
  -- Look for any custom validation
  if(data.onValidate ~= nil) then
    text = data.onValidate(text)
  end

  -- Make sure the field is within number range if a number
  if(data.pattern == "number") then

    -- Make sure that the text is always set to zero if it's not valid
    if(text == nil) then
      text = ""
    end

    if(data.allowEmptyString == false and text == "") then
      text = "0"
    end

    if(data.allowEmptyString == false) then
      -- Convert text to a number
      local value = tonumber(text)

      -- TODO need to add logic for handling negative numbers
      -- update the text var with the new value
      if(value < 0) then
        -- negative numbers are not valid so just replace with -
        text = string.lpad(tostring(""), data.tiles.w, "-")
      else

        -- make sure that the value is above the minimum allowed value
        if(data.min ~= nil) then
          if(value < data.min) then value = data.min end
        end

        -- make sure that the value us below the maximum allowed value
        if(data.max ~= nil) then
          if(value > data.max) then value = data.max end
        end

        text = string.lpad(tostring(value), data.tiles.w, "0")
      end

    end

  end
  --
  if(trigger ~= false)then
    trigger = data.text ~= text
  end
  --
  -- -- Make the text contents of the input field easy to access since there is only one line of it
  -- data.text = text

  -- Route the modified text to ChangeInputArea()
  self:ChangeInputArea(data, text, trigger)

  -- Make sure to limit the imput field

  -- Update the text value
  data.text = self:TextEditorExport(data)
end
