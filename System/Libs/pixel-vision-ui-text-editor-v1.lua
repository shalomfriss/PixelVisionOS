LoadScript("code-highlighter")
LoadScript("lume")

-- local colorShift = 28

function EditorUI:CreateTextEditor(rect, text, toolTip, font, colorOffset)

  local colorShift = colorOffset or 28

  local text = text or ""

  local data = self:CreateData(rect, nil, toolTip)

  data.highlighterTheme = {
    text = colorShift,
    selection = colorShift + 4,
    keyword = colorShift + 2,
    number = colorShift + 6,
    comment = colorShift + 8,
    string = colorShift + 10,
    api = colorShift + 12,
    callback = colorShift + 14,
    escape = colorShift + 16,
    disabled = 2
  }

  if(highlighter ~= nil) then
    highlighter:setSyntax("lua")
    highlighter:setTheme(data.highlighterTheme)
  end

  data.editable = true

  data.viewPort = NewRect(data.rect.x, data.rect.y, data.rect.w, data.rect.h)
  -- local ce = {}
  -- setmetatable(ce, TextEditor)
  data.cursorPos = {x = 0, y = 0, color = 0}
  -- local screenW = Display().x
  -- local screenH = Display().y
  data.inputDelay = .15
  data.flavorBack = 0
  data.tiles.heme = {
    bg = 0, --Background Color
    cursor = 4 --Cursor Color
  }
  data.cx, data.cy = 1, 1 --Cursor Position
  data.fw = self.spriteSize.x
  data.fh = self.spriteSize.y --The font character size

  data.vx, data.vy = 1, 1 --View postions

  data.mflag = false --Mouse flag

  data.btimer = 0 --The cursor blink timer
  data.btime = 0.5 --The cursor blink time
  data.bflag = true --The cursor is blinking atm ?

  data.stimer = 0 -- The scroll timer when the mouse is dragging up
  data.stime = 0.1 -- The speed of up scrolling when the mouse is dragging up
  data.sflag = {x = 0, y = 0} -- Vector for scroll. 0 for no scroll, 1 for scroll down, -1 for scroll up.

  data.undoStack = {} -- Keep a stack of undo info, each one is {data, state}
  data.redoStack = {} -- Keep a stack of redo info, each one is {data, state}

  -- data.rect.w, data.rect.h = screenSize()

  -- data.charGrid = {0, 8, data.rect.w, data.rect.h, data.tiles.w, data.tiles.h}

  data.colorize = false --Color lua syntax
  data.autoDeselect = true

  data.buffer = {}
  -- data.touches = {}
  -- data.touchesNum = 0
  -- data.touchscrollx = 0
  -- data.touchscrolly = 0
  -- data.touchskipinput = false
  data.font = font or "input"
  data.invalidateLine = true
  data.invalidateBuffer = true
  data.invalidText = true
  data.lastKeyCounter = 0
  data.tabChar = "  "
  data.lastKey = ""

  -- Set up the draw arguments

  data.drawMode = DrawMode.TilemapCache
  data.colorOffset = 0
  data.spacing = 0

  data.bgMaskDrawArguments = {
    data.rect.x,
    data.rect.y,
    data.rect.w,
    data.rect.h,
    data.tiles.heme.bg,
    DrawMode.TilemapCache
  }

  data.lineMaskDrawArguments = {
    data.rect.x,
    data.rect.y,
    data.rect.w,
    data.rect.h,
    data.tiles.heme.bg,
    DrawMode.TilemapCache
  }

  -- data.drawArguments = {
  --   "",
  --   0,
  --   0,
  --   data.drawMode,
  --   data.font,
  --   data.colorOffset,
  --   data.spacing,
  --   data.viewPort
  -- }

  data.cursorDrawArguments = {
    data.blinkChar,
    0,
    0,
    DrawMode.Sprite,
    data.font,
    data.highlighterTheme.selection,
    data.spacing
  }

  -- Create input callbacks. These can be overridden to add special functionality to each input field
  data.captureInput = function()
    return InputString()
  end

  data.keymap = {
    ["return"] = function(targetData)
      -- if targetData.readonly then _systemMessage("The file is readonly !", 1, 9, 4) return end
      if targetData.sxs then self:TextEditorDeleteSelection(targetData) end
      self:TextEditorInsertNewLine(targetData)
    end,

    ["left"] = function(targetData)
      self:TextEditorDeselect(targetData)
      local flag = false
      targetData.cx = targetData.cx - 1
      if targetData.cx < 1 then
        if targetData.cy > 1 then
          targetData.cy = targetData.cy - 1
          targetData.cx = targetData.buffer[targetData.cy]:len() + 1
          flag = true
        end
      end
      self:TextEditorResetCursorBlink(targetData)
      self:TextEditorCheckPosition(targetData)-- or flag then self:TextEditorDrawBuffer(targetData) else self:TextEditorDrawLine(targetData) end
      self:TextEditorDrawLineNum(targetData)
    end,

    ["right"] = function(targetData)
      self:TextEditorDeselect(targetData)
      local flag = false
      targetData.cx = targetData.cx + 1
      if targetData.cx > targetData.buffer[targetData.cy]:len() + 1 then
        if targetData.buffer[targetData.cy + 1] then
          targetData.cy = targetData.cy + 1
          targetData.cx = 1
          flag = true
        end
      end
      self:TextEditorResetCursorBlink(targetData)
      self:TextEditorCheckPosition(targetData)-- or flag then self:TextEditorDrawBuffer(targetData) else self:TextEditorDrawLine(targetData) end
      self:TextEditorDrawLineNum(targetData)
    end,
    ["shift-up"] = function(targetData)
      --in case we want to reduce shift selection
      if targetData.cy == 1 then
        --we stay in buffer
        return
      end
      if targetData.sxs then
        --there is an existing selection to update
        targetData.cy = targetData.cy - 1
        self:TextEditorCheckPosition(targetData)
        targetData.sye = targetData.cy
        targetData.sxe = math.min(targetData.cx, #targetData.buffer[targetData.cy])
      else
        targetData.sxs = targetData.cx
        targetData.sys = targetData.cy
        targetData.cy = targetData.cy - 1
        self:TextEditorCheckPosition(targetData)
        targetData.sye = targetData.cy
        targetData.sxe = math.min(targetData.cx, #targetData.buffer[targetData.cy])
      end
      self:TextEditorInvalidateBuffer(targetData)
      self:TextEditorDrawLineNum(targetData)
    end,

    ["shift-ctrl-f"] = function(targetData)
      self:TextEditorSearchPreviousFunction(targetData)
    end,

    ["ctrl-f"] = function(targetData)
      self:TextEditorSearchNextFunction(targetData)
    end,

    ["shift-down"] = function(targetData)
      --last line check, we do not go further than buffer
      if #targetData.buffer == targetData.cy then
        return
      end

      if targetData.sxs then
        targetData.cy = targetData.cy + 1
        self:TextEditorCheckPosition(targetData)
        targetData.sye = targetData.cy
        targetData.sxe = math.min(targetData.cx, #targetData.buffer[targetData.cy])
      else
        targetData.sxs = targetData.cx
        targetData.sys = targetData.cy
        targetData.cy = targetData.cy + 1
        self:TextEditorCheckPosition(targetData)
        targetData.sye = targetData.cy
        targetData.sxe = math.min(targetData.cx, #targetData.buffer[targetData.cy])
      end
      self:TextEditorInvalidateBuffer(targetData)
      self:TextEditorDrawLineNum(targetData)
    end,
    ["shift-right"] = function(targetData)

      --last line check, we do not go further than buffer
      if #targetData.buffer == targetData.cy and targetData.cx == #targetData.buffer[targetData.cy] then
        return
      end
      local originalcx, originalcy = targetData.cx, targetData.cy
      targetData.cx = targetData.cx + 1

      if targetData.cx > targetData.buffer[targetData.cy]:len() + 1 then
        if targetData.buffer[targetData.cy + 1] then
          targetData.cy = targetData.cy + 1
          targetData.cx = 1
        end
      end
      self:TextEditorCheckPosition(targetData)

      if targetData.sxs then
        targetData.sye = targetData.cy
        targetData.sxe = math.min(targetData.cx, #targetData.buffer[targetData.cy])
      else
        targetData.sxs = originalcx
        targetData.sys = originalcy
        targetData.sye = targetData.cy
        targetData.sxe = math.min(targetData.cx, #targetData.buffer[targetData.cy])
      end

      self:TextEditorInvalidateBuffer(targetData)
      self:TextEditorDrawLineNum(targetData)
    end,

    ["shift-left"] = function(targetData)
      --last line check, we do not go further than buffer
      if 0 == targetData.cy and targetData.cx <= 1 then
        return
      end
      local originalcx, originalcy = targetData.cx, targetData.cy
      targetData.cx = targetData.cx - 1

      if targetData.cx < 1 then
        if targetData.cy > 1 then
          targetData.cy = targetData.cy - 1
          targetData.cx = targetData.buffer[targetData.cy]:len() + 1
        end
      end
      self:TextEditorCheckPosition(targetData)

      if targetData.sxs then
        targetData.sye = targetData.cy
        targetData.sxe = math.min(targetData.cx, #targetData.buffer[targetData.cy])
      else
        targetData.sxs = originalcx
        targetData.sys = originalcy
        targetData.sye = targetData.cy
        targetData.sxe = math.min(targetData.cx, #targetData.buffer[targetData.cy])
      end

      self:TextEditorInvalidateBuffer(targetData)
      self:TextEditorDrawLineNum(targetData)
    end,

    ["up"] = function(targetData)
      self:TextEditorDeselect(targetData)
      targetData.cy = targetData.cy - 1
      self:TextEditorResetCursorBlink(targetData)
      self:TextEditorCheckPosition(targetData)
      self:TextEditorDrawLineNum(targetData)
    end,

    ["down"] = function(targetData)
      self:TextEditorDeselect(targetData)
      targetData.cy = targetData.cy + 1
      self:TextEditorResetCursorBlink(targetData)
      self:TextEditorCheckPosition(targetData)
      self:TextEditorDrawLineNum(targetData)
    end,

    ["backspace"] = function(targetData)
      if targetData.readonly then _systemMessage("The file is readonly !", 1, 9, 4) return end
      if targetData.sxs then self:TextEditorDeleteSelection(targetData) return end
      if targetData.cx == 1 and targetData.cy == 1 then return end
      local lineChange
      targetData.cx, targetData.cy, lineChange = self:TextEditorDeleteCharAt(targetData, targetData.cx - 1, targetData.cy)
      self:TextEditorResetCursorBlink(targetData)
      self:TextEditorCheckPosition(targetData)-- or lineChange then self:TextEditorDrawBuffer(targetData) else self:TextEditorDrawLine(targetData) end
      self:TextEditorDrawLineNum(targetData)
    end,

    ["delete"] = function(targetData)
      if targetData.readonly then _systemMessage("The file is readonly !", 1, 9, 4) return end
      if targetData.sxs then self:TextEditorDeleteSelection(targetData) return end
      local lineChange
      targetData.cx, targetData.cy, lineChange = self:TextEditorDeleteCharAt(targetData, targetData.cx, targetData.cy)
      self:TextEditorResetCursorBlink(targetData)
      self:TextEditorCheckPosition(targetData)-- or lineChange then self:TextEditorDrawBuffer(targetData) else self:TextEditorDrawLine(targetData) end
      self:TextEditorDrawLineNum(targetData)
    end,

    ["home"] = function(targetData) self:TextEditorGotoLineStart(targetData) end,

    ["end"] = function(targetData) self:TextEditorGotoLineEnd(targetData) end,

    ["pageup"] = function(targetData)
      targetData.vy = targetData.vy - targetData.tiles.h
      targetData.cy = targetData.cy - targetData.tiles.h

      if targetData.vy < 1 then targetData.vy = 1 end
      if targetData.cy < 1 then targetData.cy = 1 end

      self:TextEditorResetCursorBlink(targetData)
      self:TextEditorInvalidateBuffer(targetData)
      -- self:TextEditorDrawBuffer(targetData)
      self:TextEditorDrawLineNum(targetData)
    end,

    ["pagedown"] = function(targetData)

      --print("Page down", targetData.vy, targetData.vy, targetData.tiles.h)
      targetData.vy = targetData.vy + targetData.tiles.h
      targetData.cy = targetData.cy + targetData.tiles.h

      local bottom = #targetData.buffer - targetData.tiles.h + 1

      if targetData.vy > bottom then targetData.vy = bottom end
      if targetData.cy > bottom then targetData.cy = bottom end

      self:TextEditorResetCursorBlink(targetData)
      self:TextEditorInvalidateBuffer(targetData)
      -- self:TextEditorDrawBuffer(targetData)
      self:TextEditorDrawLineNum(targetData)
    end,

    ["tab"] = function(targetData)
      self:TextEditorTextInput(targetData, targetData.tabChar)
    end,
    -- ["ctrl-i"] = function(targetData)
    --   if targetData.incsearch == nil or targetData.incsearch == false then
    --     targetData.incsearch = true
    --     self:TextEditorDrawIncSearchState(targetData)
    --   else
    --     targetData.incsearch = false
    --     targetData.searchtxt = ""
    --     self:TextEditorDrawLineNum(targetData)
    --   end
    -- end,
    ["ctrl-k"] = function(targetData)
      if targetData.incsearch == true then
        self:TextEditorSearchTextAndNavigate(targetData, targetData.cy)
      end
    end,
    ["ctrl-x"] = function(targetData)
      if targetData.readonly then _systemMessage("The file is readonly !", 1, 9, 4) return end
      self:TextEditorCutText(targetData)
    end,

    ["ctrl-c"] = function(targetData) self:TextEditorCopyText(targetData) end,

    ["ctrl-v"] = function(targetData)
      if targetData.readonly then _systemMessage("The file is readonly !", 1, 9, 4) return end
      self:TextEditorPasteText(targetData)
    end,

    ["ctrl-a"] = function(targetData) self:TextEditorSelectAll(targetData) end,

    ["ctrl-z"] = function(targetData)
      if targetData.readonly then _systemMessage("The file is readonly !", 1, 9, 4) return end
      self:TextEditorUndo(targetData)
    end,

    ["shift-ctrl-z"] = function(targetData)
      if targetData.readonly then _systemMessage("The file is readonly !", 1, 9, 4) return end
      self:TextEditorRedo(targetData)
    end,

    ["ctrl-y"] = function(targetData)
      if targetData.readonly then _systemMessage("The file is readonly !", 1, 9, 4) return end
      self:TextEditorRedo(targetData)
    end
  }

  -- self:TextEditorImport(data, text)

  return data

end


function EditorUI:TextEditorMoveCursor(data, x, y, color)

  -- print("pre cursor", x, y)
  if(x ~= nil) then
    data.cursorPos.x = x
  end

  if(y ~= nil) then
    -- Offset this by 1 since the buffer is not 0 based
    data.cursorPos.y = y - 1
  end

  if(color ~= nil) then
    data.cursorPos.color = color
  end

  -- print("cursor", dump(data.cursorPos))
  return data.cursorPos

end

function EditorUI:TextEditorCursorColor(data, value)
  data.cursorPos.color = value
end

function EditorUI:TextEditorDrawCharactersAtCursor(data, text, x, y)

  x = x or (data.cursorPos.x * 8)
  y = y or (data.cursorPos.y * 8)

  -- Move the cursor to the end of the text block for the next draw call
  data.cursorPos.x = data.cursorPos.x + #text

  -- TODO need to create a new object here

  local drawArguments = {
    text,
    data.rect.x + x,
    data.rect.y + y,
    DrawMode.TilemapCache,
    data.font,
    data.enabled == true and data.cursorPos.color or data.highlighterTheme.disabled,
    data.spacing,
    data.viewPort
  }
  -- data.drawArguments[1] = text
  -- data.drawArguments[2] = data.rect.x + x
  -- data.drawArguments[3] = data.rect.y + y
  -- data.drawArguments[6] = data.cursorPos.color

  self:NewDraw("DrawText", drawArguments)

  -- DrawText(text, data.rect.x + x, data.rect.y + y, DrawMode.TilemapCache, data.font, data.cursorPos.color)



  -- TODO This doesn't work with colored text

  -- x = x or (data.cursorPos.x * 8)
  -- y = y or (data.cursorPos.y * 8)
  --
  -- local rightBounds = data.rect.x-- Clamp(data.rect.x + x, 0, data.rect.x + data.rect.w - 8)
  -- local start = ((x / 8) * - 1) + 1
  -- --
  -- text = text:sub(start, Clamp(#text + start, 0, data.tiles.w) + start - 1)--math.min(#text, data.tiles.w))
  --
  -- data.cursorPos.x = x + #text
  -- -- print("Draw chars", start, start + #text, math.min(start + #text - 1, data.tiles.w))
  --
  -- DrawText(text, rightBounds, data.rect.y + y, DrawMode.TilemapCache, data.font, data.cursorPos.color)

end


--A usefull print function with color support !
function EditorUI:TextEditorDrawColoredTextAtCursor(data, tbl)
  -- pushColor()
  if type(tbl) == "string" then
    self:TextEditorCursorColor(data, data.highlighterTheme.text)
    self:TextEditorDrawCharactersAtCursor(data, tbl)--, false, true)
  else
    for i = 1, #tbl, 2 do
      local col = tbl[i]
      local txt = tbl[i + 1]
      self:TextEditorCursorColor(data, col)
      self:TextEditorDrawCharactersAtCursor(data, txt)--, false, true)--Disable auto newline
    end
  end
  -- popColor()
end

--Check the position of the cursor so the view includes it
function EditorUI:TextEditorCheckPosition(data)
  local flag = false --Flag if the whole buffer requires redrawing

  -- Clamp the y position between 1 and the length of the buffer
  data.cy = Clamp(data.cy, 1, #data.buffer)

  if data.cy > data.tiles.h + data.vy - 1 then --Passed the screen to the bottom
    data.vy = data.cy - (data.tiles.h - 1); flag = true
  elseif data.cy < data.vy then --Passed the screen to the top
    if data.cy < 1 then data.cy = 1 end
    data.vy = data.cy; flag = true
  end

  --X position checking--
  if data.buffer[data.cy]:len() < data.cx - 1 then data.cx = data.buffer[data.cy]:len() + 1 end --Passed the end of the line !

  data.cx = Clamp(data.cx, 1, data.maxLineWidth)

  if data.cx > data.tiles.w + (data.vx - 1) then --Passed the screen to the right
    data.vx = data.cx - (data.tiles.w - 1); flag = true
  elseif data.cx < data.vx then --Passed the screen to the left
    if data.cx < 1 then data.cx = 1 end
    data.vx = data.cx; flag = true
  end

  -- print(data.name, "Invalidate Flag", flag)

  if(flag) then
    self:TextEditorInvalidateBuffer(data)
    -- else
    --   self:TextEditorInvalidateLine(data)
  end

  return flag
end

-- function EditorUI:TextEditorClampPosition(data, x, y)
--   --Y position checking--
--   if y > #data.buffer then y = #data.buffer end --Passed the end of the file
--
--   if y < data.vy then --Passed the screen to the top
--     if y < 1 then y = 1 end
--   end
--
--   --X position checking--
--   if data.buffer[y]:len() < x - 1 then x = data.buffer[y]:len() + 1 end --Passed the end of the line !
--
--   if x < data.vx then --Passed the screen to the left
--     if x < 1 then x = 1 end
--   end
--
--   return x, y
-- end

-- Make the cursor visible and reset the blink timer
function EditorUI:TextEditorResetCursorBlink(data)
  data.btimer = 0
  data.bflag = true
end

--Draw the cursor blink
function EditorUI:TextEditorDrawBlink(data)

  if data.sxs then return end

  if data.cy - data.vy < 0 or data.cy - data.vy > data.tiles.h - 1 then return end
  if data.bflag then

    local bx = (data.cx - data.vx) * (data.fw)
    local by = (data.cy - data.vy) * (data.fh)

    local charIndex = data.cx--(data.cx - data.vx) + 1 -- bx / 8 + 1
    -- print("cursor", bx, by, "vs", cx, cy)

    local char = data.buffer[data.cy]:sub(charIndex, charIndex)

    if(char == "") then
      char = " "
    end

    data.cursorDrawArguments[1] = char
    data.cursorDrawArguments[2] = data.rect.x + bx
    data.cursorDrawArguments[3] = data.rect.y + by

    self:NewDraw("DrawText", data.cursorDrawArguments)

    -- DrawText(char, data.rect.x + bx, data.rect.y + by, DrawMode.Sprite, data.font, data.highlighterTheme.selection)

  end

end

--Draw the code on the screen
function EditorUI:TextEditorDrawBuffer(data)

  if data.invalidateBuffer == false then return end

  --print(data.name, "Draw Buffer")


  self:TextEditorResetBufferValidation(data)

  local vbuffer = lume.slice(data.buffer, data.vy, data.vy + data.tiles.h - 1) --Visible buffer
  local cbuffer = (data.colorize and highlighter ~= nil) and highlighter:highlightLines(vbuffer, data.vy) or vbuffer

  self:NewDraw("DrawRect", data.bgMaskDrawArguments)
  -- Clear the viewport by drawing a rect with the background color
  -- DrawRect(data.rect.x, data.rect.y, data.rect.w, data.rect.h, data.tiles.heme.bg, DrawMode.TilemapCache)

  -- TODO highlight is not working correctly on the first line

  for k, l in ipairs(cbuffer) do

    -- Draw the line first for the background
    self:TextEditorMoveCursor(data, - (data.vx - 2) - 1, k, - 1)
    self:TextEditorDrawColoredTextAtCursor(data, l)

    local sxs, sys, sxe, sye = self:TextEditorGetOrderedSelect(data)

    if sxs and data.vy + k - 1 >= sys and data.vy + k - 1 <= sye then --Selection
      self:TextEditorMoveCursor(data, - (data.vx - 2) - 1, k, data.highlighterTheme.selection)
      local linelen, skip = vbuffer[k]:len(), 0

      if data.vy + k - 1 == sys then --Selection start
        skip = sxs - 1
        self:TextEditorMoveCursor(data, skip - (data.vx - 2) - 1)
        linelen = linelen - skip
      end

      if data.vy + k - 1 == sye then --Selection end
        linelen = sxe - skip
      end

      if data.vy + k - 1 < sye then --Not the end of the selection
        linelen = linelen + 1
      end

      -- Highlight start
      local hs = data.vx + data.cursorPos.x

      --print("hs", hs)
      local he = hs + linelen - 1

      local char = data.buffer[data.vy + k - 1]:sub(hs, he)

      if(char == "") then
        char = " "
      end

      self:TextEditorDrawCharactersAtCursor(data, char)--, false, true)
      -- else


    end
  end
end

function EditorUI:TextEditorDrawLine(data)

  -- If the line hasn't been invalidated don't render it
  if data.invalidateLine == false then return end

  self:TextEditorResetLineValidation(data)

  -- If there is a selection we want to draw the buffer instead of the line
  if(data.sxs) then

    self:TextEditorInvalidateBuffer(data)

    return

  end

  -- TODO need a way to check the size has changed since the last time incase we need to decrease the value

  -- get the line's new width to see if it's larger than the max counter
  data.maxLineWidth = math.max(#data.buffer[data.cy], data.maxLineWidth)
  --print(data.name, "Draw line")

  -- Reset validation

  if data.cy - data.vy < 0 or data.cy - data.vy > data.tiles.h - 1 then return end
  local cline, colateral
  if (data.colorize and highlighter ~= nil) then
    cline, colateral = highlighter:highlightLine(data.buffer[data.cy], data.cy)
  end
  if not cline then cline = data.buffer[data.cy] end

  local y = (data.cy - data.vy + 1) * (data.fh)

  data.lineMaskDrawArguments[2] = data.rect.y + y - 8
  data.lineMaskDrawArguments[4] = data.fh

  self:NewDraw("DrawRect", data.lineMaskDrawArguments)

  -- DrawRect(data.rect.x, data.rect.y + y - 8, data.rect.w, data.fh, data.tiles.heme.bg, DrawMode.TilemapCache)

  self:TextEditorMoveCursor(data, - (data.vx - 2) - 1, y / 8, data.tiles.heme.bg)
  if not colateral then
    self:TextEditorDrawColoredTextAtCursor(data, cline)
  else
    self:TextEditorInvalidateBuffer(data)
  end

end

function EditorUI:TextEditorInvalidateLine(data)
  data.invalidateLine = true
end

function EditorUI:TextEditorResetLineValidation(data)
  data.invalidateLine = false
end

function EditorUI:TextEditorInvalidateBuffer(data)
  data.invalidateBuffer = true
end

function EditorUI:TextEditorResetBufferValidation(data)
  data.invalidateBuffer = false
end

function EditorUI:TextEditorInvalidateText(data)
  data.invalidText = true
end

function EditorUI:TextEditorResetTextValidation(data)
  data.invalidText = false
end



--Clear the selection just incase
function EditorUI:TextEditorDeselect(data)

  if data.sxs then
    --print(data.name, "Deselect")
    data.sxs, data.sys, data.sxe, data.sye = nil, nil, nil, nil
    self:TextEditorInvalidateBuffer(data)
  end
end

function EditorUI:TextEditorGetOrderedSelect(data)
  if data.sxs then
    if data.sye < data.sys then
      return data.sxe, data.sye, data.sxs, data.sys
    elseif data.sye == data.sys and data.sxe < data.sxs then
      return data.sxe, data.sys, data.sxs, data.sye
    else
      return data.sxs, data.sys, data.sxe, data.sye
    end
  else
    return false
  end
end

function EditorUI:TextEditorDrawLineNum(data)

  local linestr = "LINE "..tostring(data.cy).."/"..tostring(#data.buffer).."  CHAR "..tostring(data.cx - 1).."/"..tostring(data.buffer[data.cy]:len())

  -- TODO this should update an object an external renderer can use to display this text

  -- EditorUI:TextEditorCursorColor(data, data.flavorBack) EditorUI:TextEditorDrawTextAtCursor(data, linestr, 1, data.rect.h - data.fh)
end

-- function EditorUI:TextEditorDrawIncSearchState(data)
--   -- eapi:drawBottomBar()
--   local linestr = "ISRCH: "
--   if data.searchtxt then
--     linestr = linestr..data.searchtxt
--   end
--   self:TextEditorCursorColor(data, data.flavorBack) self:TextEditorDrawTextAtCursor(data, linestr, 1, data.rect.h - data.fh)
-- end


function EditorUI:TextEditorSearchNextFunction(data)
  for i, t in ipairs(data.buffer)
  do
    if i > data.cy then
      if string.find(t, "function ") then
        data.cy = i
        self:TextEditorCheckPosition(data)
        -- Force the buffer to redraw
        self:TextEditorInvalidateBuffer(data)

        -- EditorUI:TextEditorDrawBuffer(data)
        break
      end
    end
  end
end

function EditorUI:TextEditorSearchPreviousFunction(data)
  highermatch = -1
  for i, t in ipairs(data.buffer)
  do
    if i < data.cy then
      if string.find(t, "function ") then
        highermatch = i
      end
    end
  end

  if highermatch > - 1 then
    data.cy = highermatch
    data.vy = highermatch
    self:TextEditorCheckPosition(data)
    -- Force the buffer to redraw
    self:TextEditorInvalidateBuffer(data)
    -- EditorUI:TextEditorDrawBuffer(data)
  end

end



function EditorUI:TextEditorSearchTextAndNavigate(data, from_line)
  for i, t in ipairs(data.buffer)
  do
    if from_line ~= nil and i > from_line then
      if string.find(t, data.searchtxt) then
        data.cy = i
        data.vy = i
        self:TextEditorCheckPosition(data)
        self:TextEditorInvalidateBuffer(data)

        -- EditorUI:TextEditorDrawBuffer(data)
        break
      end
    end
  end

end

function EditorUI:TextEditorTextInput(data, t)
  if data.readonly then _systemMessage("The file is readonly !", 1, 9, 4) return end
  if data.incsearch then
    if data.searchtxt == nil then data.searchtxt = "" end
    data.searchtxt = data.searchtxt..t
    -- note on -1 : that way if search is on line , still works
    -- and also ok for ctrl k
    self:TextEditorSearchTextAndNavigate(data, data.cy - 1)
    self:TextEditorDrawIncSearchState(data)
  else
    self:TextEditorBeginUndoable(data)
    local delsel
    if data.sxs then self:TextEditorDeleteSelection(data); delsel = true end
    data.buffer[data.cy] = data.buffer[data.cy]:sub(0, data.cx - 1)..t..data.buffer[data.cy]:sub(data.cx, - 1)
    data.cx = data.cx + t:len()

    self:TextEditorResetCursorBlink(data)
    if self:TextEditorCheckPosition(data) or delsel then self:TextEditorDrawBuffer(data) else self:TextEditorDrawLine(data) end
    self:TextEditorDrawLineNum(data)

    self:TextEditorInvalidateLine(data)

    self:TextEditorEndUndoable(data)

    self:TextEditorInvalidateText(data)
  end
end

function EditorUI:TextEditorGotoLineStart(data)
  self:TextEditorDeselect(data)
  data.cx = 1
  self:TextEditorResetCursorBlink(data)
  if self:TextEditorCheckPosition(data) then self:TextEditorDrawBuffer(data) else self:TextEditorDrawLine(data) end
  -- EditorUI:TextEditorDrawLineNum(data)
end

function EditorUI:TextEditorGotoLineEnd(data)
  self:TextEditorDeselect(data)
  data.cx = data.buffer[data.cy]:len() + 1
  self:TextEditorResetCursorBlink(data)
  if self:TextEditorCheckPosition(data) then self:TextEditorDrawBuffer(data) else self:TextEditorDrawLine(data) end
  -- EditorUI:TextEditorDrawLineNum(data)
end

function EditorUI:TextEditorInsertNewLine(data)
  self:TextEditorBeginUndoable(data)
  local newLine = data.buffer[data.cy]:sub(data.cx, - 1)
  data.buffer[data.cy] = data.buffer[data.cy]:sub(0, data.cx - 1)
  local snum = string.find(data.buffer[data.cy].."a", "%S") --Number of spaces
  snum = snum and snum - 1 or 0
  newLine = string.rep(" ", snum)..newLine
  data.cx, data.cy = snum + 1, data.cy + 1
  if data.cy > #data.buffer then
    table.insert(data.buffer, newLine)
  else
    data.buffer = lume.concat(lume.slice(data.buffer, 0, data.cy - 1), {newLine}, lume.slice(data.buffer, data.cy, - 1)) --Insert between 2 different lines
  end

  self:TextEditorInvalidateBuffer(data)

  self:TextEditorResetCursorBlink(data)
  self:TextEditorCheckPosition(data)
  -- self:TextEditorDrawBuffer(data)
  -- self:TextEditorDrawLineNum(data)
  self:TextEditorEndUndoable(data)
  self:TextEditorInvalidateText(data)
end

-- Delete the char from the given coordinates.
-- If out of bounds, it'll merge the line with the previous or next as it suits
-- Returns the coordinates of the deleted character, adjusted if lines were changed
-- and a boolean "true" if other lines changed and redrawing the Buffer is needed
function EditorUI:TextEditorDeleteCharAt(data, x, y)
  self:TextEditorBeginUndoable(data)

  local lineChange = false
  -- adjust "y" if out of bounds, just as failsafe
  if y < 1 then y = 1 elseif y > #data.buffer then y = #data.buffer end
  -- newline before the start of line == newline at end of previous line
  if y > 1 and x < 1 then
    y = y - 1
    x = data.buffer[y]:len() + 1
  end
  -- join with next line (delete newline) when deleting past the boundaries of the line
  if x > data.buffer[y]:len() and y < #data.buffer then
    data.buffer[y] = data.buffer[y]..data.buffer[y + 1]
    data.buffer = lume.concat(lume.slice(data.buffer, 0, y), lume.slice(data.buffer, y + 2, - 1))
    lineChange = true
  else
    data.buffer[y] = data.buffer[y]:sub(0, x - 1) .. data.buffer[y]:sub(x + 1, - 1)
  end

  if lineChange then self:TextEditorInvalidateBuffer(data) else self:TextEditorInvalidateLine(data) end

  self:TextEditorEndUndoable(data)
  self:TextEditorInvalidateText(data)
  return x, y, lineChange
end

--Will delete the current selection
function EditorUI:TextEditorDeleteSelection(data)

  if not data.sxs then return end --If not selection just return back.
  local sxs, sys, sxe, sye = self:TextEditorGetOrderedSelect(data)

  self:TextEditorBeginUndoable(data)
  local lnum, slength = sys, sye + 1
  while lnum < slength do
    if lnum == sys and lnum == sye then --Single line selection
      data.buffer[lnum] = data.buffer[lnum]:sub(1, sxs - 1) .. data.buffer[lnum]:sub(sxe + 1, - 1)
      lnum = lnum + 1
    elseif lnum == sys then
      data.buffer[lnum] = data.buffer[lnum]:sub(1, sxs - 1)
      lnum = lnum + 1
    elseif lnum == slength - 1 then
      data.buffer[lnum - 1] = data.buffer[lnum - 1] .. data.buffer[lnum]:sub(sxe + 1, - 1)
      data.buffer = lume.concat(lume.slice(data.buffer, 1, lnum - 1), lume.slice(data.buffer, lnum + 1, - 1))
      slength = slength - 1
    else --Middle line
      data.buffer = lume.concat(lume.slice(data.buffer, 1, lnum - 1), lume.slice(data.buffer, lnum + 1, - 1))
      slength = slength - 1
    end
  end
  data.cx, data.cy = sxs, sys
  self:TextEditorCheckPosition(data)
  self:TextEditorDeselect(data)
  self:TextEditorInvalidateBuffer(data)
  self:TextEditorEndUndoable(data)
  self:TextEditorInvalidateText(data)
end

--Copy selection text (Only if selecting)
function EditorUI:TextEditorCopyText(data)
  local sxs, sys, sxe, sye = self:TextEditorGetOrderedSelect(data)
  if sxs then --If there are any selection
    local clipbuffer = {}
    for lnum = sys, sye do
      local line = data.buffer[lnum]

      if lnum == sys and lnum == sye then --Single line selection
        line = line:sub(sxs, sxe)
      elseif lnum == sys then
        line = line:sub(sxs, - 1)
      elseif lnum == sye then
        line = line:sub(1, sxe)
      end

      table.insert(clipbuffer, line)
    end

    local clipdata = table.concat(clipbuffer, "\n")
    self:TextEditorClipboard(clipdata)
  end
end

--Cut selection text
function EditorUI:TextEditorCutText(data)
  if data.sxs then
    self:TextEditorCopyText(data)
    self:TextEditorDeleteSelection(data)
  end
end

-- Paste the text from the clipboard
function EditorUI:TextEditorPasteText(data)
  self:TextEditorBeginUndoable(data)
  if data.sxs then self:TextEditorDeleteSelection(data) end
  local text = self:TextEditorClipboard()
  text = text:gsub("\t", " ") -- tabs mess up the layout, replace them with spaces
  local firstLine = true
  for line in string.gmatch(text.."\n", "([^\r\n]*)\r?\n") do
    if not firstLine then
      self:TextEditorInsertNewLine(data) data.cx = 1
    else
      firstLine = false
    end
    self:TextEditorTextInput(data, line)
  end
  if self:TextEditorCheckPosition(data) then self:TextEditorDrawBuffer(data) else self:TextEditorDrawLine(data) end

  self:TextEditorDrawLineNum(data)
  self:TextEditorEndUndoable(data)
  self:TextEditorInvalidateText(data)
end

--Select all text
function EditorUI:TextEditorSelectAll(data)
  data.sxs, data.sys = 1, 1
  data.sye = #data.buffer
  data.sxe = data.buffer[data.sye]:len()
  self:TextEditorInvalidateBuffer(data)
end

-- Call :TextEditorBeginUndoable(data) right before doing any modification to the
-- text in the editor. It will capture the current state of the editor's
-- contents (data) and the state of the cursor, selection, etc. (state)
-- so it can be restored later.
-- NOTE: Make sure to balance each call to :TextEditorBeginUndoable(data) with a call
-- to :TextEditorEndUndoable(data). They can nest fine, just don't forget one.
function EditorUI:TextEditorBeginUndoable(data)
  if data.currentUndo then
    -- we have already stashed the data & state, just track how deep we are
    data.currentUndo.count = data.currentUndo.count + 1
  else
    -- make a new in-progress undo
    data.currentUndo = {
      count = 1, -- here is where we track nested begin/endUndoable calls
      data = self:TextEditorExport(data),
      state = self:TextEditorGetState(data)
    }
  end
end

-- Call :TextEditorEndUndoable(data) after each modification to the text in the editor.
function EditorUI:TextEditorEndUndoable(data)
  -- We might be inside several nested calls to begin/endUndoable
  data.currentUndo.count = data.currentUndo.count - 1
  -- If this was the last of the nesting
  if data.currentUndo.count == 0 then
    -- then push the undo onto the undo stack.
    table.insert(data.undoStack, {
      data.currentUndo.data,
      data.currentUndo.state
    })
    -- clear the redo stack
    data.redoStack = {}
    data.currentUndo = nil
  end
end

-- Perform an undo. This will pop one entry off the undo
-- stack and restore the editor's contents & cursor state.
function EditorUI:TextEditorUndo(data)
  if #data.undoStack == 0 then
    -- beep?
    return
  end
  -- pull one entry from the undo stack
  local text, state = unpack(table.remove(data.undoStack))

  -- push a new entry onto the redo stack
  table.insert(data.redoStack, {
    self:TextEditorExport(data),
    self:TextEditorGetState(data)
  })

  -- restore the editor contents
  self:TextEditorImport(data, text)
  -- restore the cursor state
  self:TextEditorSetState(data, state)
end

-- Perform a redo. This will pop one entry off the redo
-- stack and restore the editor's contents & cursor state.
function EditorUI:TextEditorRedo(data)
  if #data.redoStack == 0 then
    -- beep?
    return
  end
  -- pull one entry from the redo stack
  local text, state = unpack(table.remove(data.redoStack))
  -- push a new entry onto the undo stack
  table.insert(data.undoStack, {
    self:TextEditorExport(data),
    self:TextEditorGetState(data)
  })
  -- restore the editor contents
  self:TextEditorImport(data, text)
  -- restore the cursor state
  self:TextEditorSetState(data, state)
end

-- Get the state of the cursor, selection, etc.
-- This is used for the undo/redo feature.
function EditorUI:TextEditorGetState(data)
  return {
    cx = data.cx,
    cy = data.cy,
    sxs = data.sxs,
    sys = data.sys,
    sxe = data.sxe,
    sye = data.sye,
  }
end

-- Set the state of the cursor, selection, etc.
-- This is used for the undo/redo feature.
function EditorUI:TextEditorSetState(data, state)
  data.cx = state.cx
  data.cy = state.cy
  data.sxs = state.sxs
  data.sys = state.sys
  data.sxe = state.sxe
  data.sye = state.sye

  -- TODO need to invalidate line and buffer

  self:TextEditorCheckPosition(data)
  self:TextEditorDrawBuffer(data)
  self:TextEditorDrawLineNum(data)
end

-- Last used key, this should be set to the last keymap used from the data.keymap table

function EditorUI:TextEditorMousepressed(data, cx, cy)--, istouch)
  -- if istouch then return end

  -- print("Press", self.collisionManager.mousePos.c, self.collisionManager.mousePos.r)


  -- local cx, cy = self:TextEditorWhereInGrid(x, y, data.charGrid)
  if (not data.mflag and data.inFocus) then

    cx = data.vx + (cx)
    cy = data.vy + (cy)


    --print(data.name, "Mouse Down", dt, data.mflag)

    data.mflag = true

    data.cx = cx
    data.cy = cy
    --print("cursor", cx, cy, data.cx, data.cy, data.vx, data.vy)
    if data.sxs then data.sxs, data.sys, data.sxe, data.sye = false, false, false, false end --End selection

    EditorUI:TextEditorCheckPosition(data)

  end
end

function EditorUI:TextEditorMouseMoved(data, cx, cy)--, dx, dy, it)

  if not data.mflag then return end

  if(cx < 0 or cy < 0) then
    data.sflag.x = 0
    data.sflag.y = 0
    return
  end

  -- Adjust for the view scroll
  local cx2 = data.vx + (cx)
  local cy2 = data.vy + (cy)

  if(data.cx ~= cx2 or data.cy ~= cy2) then

    --print(data.name, "Mouse move", cx, cy)

    data.bflag = false --Disable blinking
    if not data.sxs then --Start the selection
      --print(data.name, "Start selection", cx, data.cx, cy, data.cy)
      data.sxs, data.sys = cx2, cy2
      data.sxe, data.sye = data.cx, data.cy
      -- Note: the ordered selection is given by EditorUI:TextEditorGetOrderedSelect(data)
      -- This is used to avoid extra overhead.
    else

      data.sxe, data.sye = cx2, cy2

      if cx > data.tiles.w - 2 then
        data.sflag.x = 1
      elseif cx < 1 then
        data.sflag.x = -1
      else
        data.sflag.x = 0
      end

      -- TODO need to fix scroll calculation here
      if cy > data.tiles.h - 2 then
        data.sflag.y = 1
      elseif cy < 1 then
        data.sflag.y = -1
      else
        data.sflag.y = 0
      end

      self:TextEditorInvalidateBuffer(data)

    end

    -- Save the cursor position
    data.cx = cx2
    data.cy = cy2


  end
  -- EditorUI:TextEditorDrawBuffer(data)
  -- elseif data.sxs then --Top bar
  --   data.bflag = false --Disable blinking
  -- end

  -- TODO need to fix scroll calulation here
  -- if cy > data.tiles.h - 1 then
  --   data.sflag.y = 1
  -- elseif cy < 1 then
  --   data.sflag.y = -1
  -- else
  --   data.sflag.y = 0
  -- end

end
-- end

function EditorUI:TextEditorMouseReleased(data)--, b, it)

  --print(data.name, "Mouse Released")

  data.mflag = false
  data.sflag.x = 0
  data.sflag.y = 0

  if(data.sxs == data.sxe and data.sys == data.sye) then
    self:TextEditorDeselect(data)
  end

  self:TextEditorInvalidateBuffer(data)
  -- TODO need to figure out if there is only one character selected and disable the selection

end

function EditorUI:TextEditorWheelMoved(x, y)
  data.vy = math.floor(data.vy - y)
  if data.vy > #data.buffer then data.vy = #data.buffer end
  if data.vy < 1 then data.vy = 1 end
  data.vx = math.floor(data.vx + x)
  if data.vx < 1 then data.vx = 1 end
  self:TextEditorDrawBuffer(data)
end

function EditorUI:TextEditorUpdate(data, dt)



  local overrideFocus = (data.inFocus == true and self.collisionManager.mouseDown)

  -- TODO this should be only happen when in focus
  local cx = self.collisionManager.mousePos.c - data.tiles.c
  local cy = self.collisionManager.mousePos.r - data.tiles.r

  -- print("Inside Text", data.name)
  -- Ready to test finer collision if needed
  if(self.collisionManager:MouseInRect(data.rect) == true or overrideFocus) then

    if(data.enabled == true and data.editable == true) then

      if(data.inFocus == false) then
        -- Set focus
        self:SetFocus(data, 3)
      end


      -- -- Track the mouse in the component if it is in focus
      -- local mousePos = MousePosition()
      -- mousePos.x = mousePos.x - data.rect.x
      -- mousePos.y = mousePos.y - data.rect.y
      --
      -- print(data.name, "Mouse pos", cx, self.collisionManager.mousePos.c, mousePos.y)

      self:TextEditorMouseMoved(data, cx, cy)

      -- if(MouseButton(0)) then
      --   self:TextEditorMousepressed(data, cx, cy, 0)
      -- elseif(MouseButton(0, InputState.Released)) then
      --   self:TextEditorMouseReleased(data)
      -- end



      if(self.collisionManager.mouseReleased == true and data.editing == false) then

        self:EditTextEditor(data, true)

      end

    else

      -- If the mouse is not in the rect, clear the focus
      if(data.inFocus == true) then
        self:ClearFocus(data)
      end

    end

  else
    -- If the mouse isn't over the component clear the focus
    self:ClearFocus(data)

  end


  if(data.inFocus == true)then

    if(self.collisionManager.mouseDown == true) then
      self:TextEditorMousepressed(data, cx, cy, 0)
      -- end
    elseif(self.collisionManager.mouseReleased == true) then
      self:TextEditorMouseReleased(data)
    end

  elseif(data.editing == true and self.collisionManager.mouseDown == true) then
    --print(data.name, "Stop editing")
    self:EditTextEditor(data, false)
  end

  if(data.editing == true) then
    --
    -- If the field has focus, capture the keyboard input
    if(self.editingField ~= nil and data.name == self.editingField.name and data.editing == true) then

      -- Clear key name flag
      local keyName = ""

      if(Key(Keys.LeftShift) or Key(Keys.RightShift)) then
        keyName = keyName .. "shift-"
      end

      if(Key(Keys.LeftControl) or Key(Keys.RightControl)) then
        keyName = keyName .. "ctrl-"
      end

      if(Key(Keys.Backspace)) then
        keyName = keyName .. "backspace"
      elseif(Key(Keys.Delete)) then
        keyName = keyName .. "delete"
      elseif(Key(Keys.Enter)) then
        keyName = keyName .. "return"
      elseif(Key(Keys.Home, InputState.Released)) then
        keyName = keyName .. "home"
      elseif(Key(Keys.End, InputState.Released)) then
        keyName = keyName .. "end"
      elseif(Key(Keys.PageUp, InputState.Released)) then
        keyName = keyName .. "pageup"
      elseif(Key(Keys.PageDown, InputState.Released)) then
        keyName = keyName .. "pagedown"
      elseif(Key(Keys.Tab, InputState.Released)) then
        keyName = keyName .. "tab"
      elseif(Key(Keys.Up)) then
        keyName = keyName .. "up"
      elseif(Key(Keys.Down)) then
        keyName = keyName .. "down"
      elseif(Key(Keys.Right)) then
        keyName = keyName .. "right"
      elseif(Key(Keys.Left)) then
        keyName = keyName .. "left"
      else
        --These keys should have an immediate trigger when released
        if(Key(Keys.I, InputState.Released)) then
          keyName = keyName .. "i"
        elseif(Key(Keys.K, InputState.Released)) then
          keyName = keyName .. "k"
        elseif(Key(Keys.X, InputState.Released)) then
          keyName = keyName .. "x"
        elseif(Key(Keys.C, InputState.Released)) then
          keyName = keyName .. "c"
        elseif(Key(Keys.V, InputState.Released)) then
          keyName = keyName .. "v"
        elseif(Key(Keys.A, InputState.Released)) then
          keyName = keyName .. "a"
        elseif(Key(Keys.Z, InputState.Released)) then
          keyName = keyName .. "z"
        elseif(Key(Keys.Y, InputState.Released)) then
          keyName = keyName .. "y"
        elseif(Key(Keys.F, InputState.Released)) then
          keyName = keyName .. "f"
        end
        data.lastKeyCounter = data.inputDelay + 1
      end

      -- Clear the current key if it was the same as the last frame's key
      if(data.lastKey ~= "" and data.lastKey == keyName) then

        data.lastKeyCounter = data.lastKeyCounter + dt

        if(data.lastKeyCounter < data.inputDelay) then
          -- Clear key flag
          keyName = ""

        else

          data.lastKey = ""
        end

      end

      -- Look to see if there is a key map
      if(data.keymap[keyName] ~= nil) then

        -- Trigger the key action mapping
        data.keymap[keyName](data)

        -- Save the last key action
        data.lastKey = keyName
        -- Reset the counter
        data.lastKeyCounter = 0
      end

      -- end

      -- We only want to insert text if there the ctrl key is not being pressed
      if(Key(Keys.LeftControl) == false and Key(Keys.RightControl) == false) then
        local lastInput = data.captureInput(data)

        if(lastInput ~= "") then
          self:TextEditorTextInput(data, lastInput)
        end
      end

      --Blink timer
      if not data.sxs then --If not selecting
        data.btimer = data.btimer + dt
        if data.btimer >= data.btime then
          data.btimer = 0--data.btimer % data.btime
          data.bflag = not data.bflag


          -- -- EditorUI:TextEditorDrawBlink(data)
          -- EditorUI:TextEditorDrawLine(data) --Redraw the current line
        end

        if(data.bflag == true) then
          self:TextEditorDrawBlink(data)
        end
        -- print("Blink", data.bflag)
      elseif data.sflag.x ~= 0 or data.sflag.y ~= 0 then -- if selecting with the mouse and scrolling up/down
        data.stimer = data.stimer + dt
        if data.stimer > data.stime then
          data.stimer = data.stimer % data.stime

          data.vx = Clamp(data.vx + data.sflag.x, 1, data.maxLineWidth - data.tiles.w)

          data.vy = Clamp(data.vy + data.sflag.y, 1, #data.buffer - data.tiles.h)
          -- if data.vy <= 0 then
          --   data.vy = 1
          -- elseif data.vy > #data.buffer then
          --   data.vy = #data.buffer
          -- end

          -- EditorUI:TextEditorDrawBuffer(data)
        end
      end
    end
  end

  -- Only redraw the line if the buffer isn't about to redraw
  if(data.invalidateBuffer == false) then
    self:TextEditorDrawLine(data)
  end

  -- TODO this is sort of hacky, see if there is a better way to do this?
  -- Clear the flag just in case mouse is up but flag is true
  if(data.mflag == true and self.collisionManager.mouseDown == false) then
    data.mflag = false
    data.sflag.x = 0
    data.sflag.y = 0
  end

  -- Redraw the display
  self:TextEditorDrawBuffer(data)
end

function EditorUI:TextEditorMagicLines(s)
  if s:sub(-1) ~= "\n" then s = s.."\n" end
  return s:gmatch("([^\n]*)\n?") -- "([^\n]*)\n?"
end

function EditorUI:TextEditorImport(data, text)

  data.maxLineWidth = 0

  -- Create a new buffer
  data.buffer = {}

  -- Loop through each line of the text
  for line in self:TextEditorMagicLines(tostring(text)) do

    -- Replace tabs
    line = line:gsub("\t", data.tabChar)

    data.maxLineWidth = math.max(#line, data.maxLineWidth)

    -- Flag to add the new line
    local addLine = true

    -- Check to see if the maximum lines is set
    if(data.maxLines ~= nil) then

      -- Set the add line flag based on the current lines in the buffer
      addLine = #data.buffer < data.maxLines
    end

    -- Add the line
    if(addLine) then
      table.insert(data.buffer, line)
    end
  end

  if not data.buffer[1] then data.buffer[1] = "" end
  self:TextEditorCheckPosition(data)

  self:TextEditorResetTextValidation(data)
  self:TextEditorInvalidateBuffer(data)
  -- EditorUI:TextEditorDrawBuffer(data)
end

function EditorUI:TextEditorExport(data)
  return table.concat(data.buffer, "\n")
end

-- function EditorUI:TextEditorIsInRect(x, y, rect)
--   if (x >= rect[1] and y >= rect[2] and x <= rect[1] + rect[3] - 1 and y <= rect[2] + rect[4] - 1) then
--     return true
--   end
--   return false
-- end
--
-- function EditorUI:TextEditorWhereInGrid(x, y, grid) --Grid X, Grid Y, Grid Width, Grid Height, NumOfCells in width, NumOfCells in height
--   local gx, gy, gw, gh, cw, ch = unpack(grid)
--
--   if self:TextEditorIsInRect(x, y, {gx, gy, gw, gh}) then
--     local clw, clh = math.floor(gw / cw), math.floor(gh / ch)
--     local x, y = x - gx, y - gy
--     local hx = math.floor(x / clw) + 1 hx = hx <= cw and hx or hx - 1
--     local hy = math.floor(y / clh) + 1 hy = hy <= ch and hy or hy - 1
--     return hx, hy
--   end
--   return false, false
-- end

function EditorUI:TextEditorClipboard(value)

  -- TODO this should be tied to the OS scope
  if(value ~= nil) then

    self.codeEditorClipboardValue = value
  end

  return self.codeEditorClipboardValue

end

function EditorUI:EditTextEditor(data, value, callAction)

  if(data.enabled == false or value == data.editing)then
    return
  end

  if(data.onEdit ~= nil) then
    data.onEdit(data, value)
  end

  -- Need to make sure we are not currently editing another field
  if(value == true) then

    -- Look to see if a field is being edited
    if(self.editingField ~= nil) then

      -- Exit field's edit mode
      self:EditTextEditor(self.editingField, false)
      return

    end

    -- Set new field to edit mode
    self.editingField = data

  else
    self.editingField = nil
  end

  -- change the edit mode to the new value
  data.editing = value

  -- Make sure the field deselects when exiting edit mode
  if(data.editing == false) then
    if(data.autoDeselect == true) then
      self:TextEditorDeselect(data)
    end
    data.mflag = false
    -- TODO need to call action here, should this be a lose focus event?

    if(data.onAction ~= nil and callAction ~= false) then
      data.onAction(self:TextEditorExport(data))
    end

  end

  -- Force the text field to redraw itself
  self:TextEditorInvalidateBuffer(data)

end

function EditorUI:ResizeTexdtEditor(data, width, height, x, y)

  -- TODO need to fix this


  if(data.rect.x == x and data.rect.y == y and data.rect.w == width and data.rect.h == height) then
    return
  end

  -- print(data.name, "Resize", x, y, width, height)

  -- Update the rect value
  data.rect.x = x
  data.rect.y = y
  data.rect.w = width
  data.rect.h = height
  --
  -- -- Create new tile dimensions
  -- data.tiles = {
  data.tiles.c = math.floor(data.rect.x / self.spriteSize.x)
  data.tiles.r = math.floor(data.rect.y / self.spriteSize.y)
  data.tiles.w = math.ceil(data.rect.w / self.spriteSize.x)
  data.tiles.h = math.ceil(data.rect.h / self.spriteSize.y)
  -- }

  data.viewPort = NewRect(data.rect.x, data.rect.y, data.rect.w, data.rect.h)

  data.bgMaskDrawArguments[1] = data.rect.x
  data.bgMaskDrawArguments[2] = data.rect.y
  data.bgMaskDrawArguments[3] = data.rect.w
  data.bgMaskDrawArguments[4] = data.rect.h

  data.lineMaskDrawArguments[1] = data.rect.x
  data.lineMaskDrawArguments[2] = data.rect.y
  data.lineMaskDrawArguments[3] = data.rect.w
  data.lineMaskDrawArguments[4] = data.rect.h

  -- Update the input field's character width and height
  -- data.width = data.tiles.w
  -- data.height = data.tiles.h

  -- Adjust scroll right
  -- data.scrollRight = data.scrollLeft + data.width - 1

  self:TextEditorInvalidateBuffer(data)

end
