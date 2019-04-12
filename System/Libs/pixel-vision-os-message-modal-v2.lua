MessageModal = {}
MessageModal.__index = MessageModal

function MessageModal:Init(title, message, width, showCancel)

  local _messageModal = {} -- our new object
  setmetatable(_messageModal, MessageModal) -- make Account handle lookup


  _messageModal:Configure(title, message, width, showCancel)
  -- _messageModal.currentSelection = 1
  -- _messageModal.message = message



  return _messageModal

end

function MessageModal:Configure(title, message, width, showCancel)

  self.showCancel = showCancel or false

  -- Reset the modal so it redraws correctly when opened
  self.firstRun = nil

  width = width or 96

  -- Need to calculate the height ahead of time
  -- Draw message text
  local wrap = WordWrap(message, (width / 4) - 4)
  self.lines = SplitLines(wrap)

  height = #self.lines * 8 + 42

  -- Make sure width and height are on the grid
  width = math.floor(width / 8) * 8
  height = math.floor(height / 8) * 8

  self.canvas = NewCanvas(width, height)

  local displaySize = Display()

  self.title = title or "Message Modal"

  self.rect = {
    x = math.floor(((displaySize.x - width) * .5) / 8) * 8,
    y = math.floor(((displaySize.y - height) * .5) / 8) * 8,
    w = width,
    h = height
  }

  self.selectionValue = false

end

function MessageModal:Open()

  if(self.firstRun == nil) then

    -- Draw the black background
    self.canvas:SetStroke({5}, 1, 1)
    self.canvas:SetPattern({0}, 1, 1)
    self.canvas:DrawSquare(0, 0, self.canvas.width - 1, self.canvas.height - 1, true)

    -- Draw the brown background
    self.canvas:SetStroke({12}, 1, 1)
    self.canvas:SetPattern({11}, 1, 1)
    self.canvas:DrawSquare(3, 9, self.canvas.width - 4, self.canvas.height - 4, true)

    local tmpX = (self.canvas.width - (#self.title * 4)) * .5

    self.canvas:DrawText(self.title:upper(), tmpX, 1, "small", 15, - 4)

    -- draw highlight stroke
    self.canvas:SetStroke({15}, 1, 1)
    self.canvas:DrawLine(3, 9, self.canvas.width - 5, 9)
    self.canvas:DrawLine(3, 9, 3, self.canvas.height - 5)


    -- Draw message text
    -- local wrap = WordWrap(self.message, (self.rect.w / 4) - 4)
    -- local lines = SplitLines(wrap)
    local total = #self.lines
    local startX = 8--
    local startY = 16--self.rect.y + 8

    -- We want to render the text from the bottom of the screen so we offset it and loop backwards.
    for i = 1, total do
      self.canvas:DrawText(self.lines[i]:upper(), startX, (startY + ((i - 1) * 8)), "medium", 0, - 4)
    end


    self.buttons = {}

    -- TODO Create button states?

    local buttonSize = {x = 32, y = 16}

    -- TODO center ok button when no cancel button is shown
    local bX = self.showCancel == true and (self.rect.w - buttonSize.x - 8) or ((self.rect.w - buttonSize.x) * .5)

    -- snap the x value to the grid
    bX = math.floor((bX + self.rect.x) / 8) * 8

    -- Fix the button to the bottom of the window
    local bY = math.floor(((self.rect.y + self.rect.h) - buttonSize.y - 8) / 8) * 8

    local backBtnData = self.editorUI:CreateButton({x = bX, y = bY}, "modalokbutton", "")

    backBtnData.onAction = function()

      -- Set value to true when ok is pressed
      self.selectionValue = true

      if(self.onParentClose ~= nil) then
        self.onParentClose()
      end
    end

    table.insert(self.buttons, backBtnData)

    if(self.showCancel) then

      -- Offset the bX value and snap to the grid
      bX = math.floor((bX - buttonSize.x - 8) / 8) * 8

      local cancelBtnData = self.editorUI:CreateButton({x = bX, y = bY}, "modalcancelbutton", "")

      cancelBtnData.onAction = function()

        -- Set value to true when cancel is pressed
        self.selectionValue = false

        -- Close the panel
        if(self.onParentClose ~= nil) then
          self.onParentClose()
        end
      end

      table.insert(self.buttons, cancelBtnData)

    end



    self.firstRun = false;

  end

  for i = 1, #self.buttons do
    self.editorUI:Invalidate(self.buttons[i])
  end

  self.canvas:DrawPixels(self.rect.x, self.rect.y, DrawMode.TilemapCache)

end

function MessageModal:Close()
  -- print("Modal Close")
  -- if(self.onParentClose ~= nil) then
  --   self.onParentClose()
  -- end
end

function MessageModal:Update(timeDelta)

  for i = 1, #self.buttons do
    self.editorUI:UpdateButton(self.buttons[i])
  end

end

function MessageModal:Draw()

end
