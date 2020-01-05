ProgressModal = {}
ProgressModal.__index = ProgressModal

function ProgressModal:Init(title, editorUI)

    local _progressModal = {} -- our new object
    setmetatable(_progressModal, ProgressModal) -- make Account handle lookup

    _progressModal.editorUI = editorUI
    _progressModal:Configure(title)

    return _progressModal

end

function ProgressModal:Configure(title)

    -- Reset the modal so it redraws correctly when opened
    self.firstRun = nil

    local width = 128
    local height = 88

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

function ProgressModal:Open()

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

        local buttonSize = {x = 32, y = 16}

        -- TODO center ok button when no cancel button is shown
        local bX = ((self.rect.w - buttonSize.x) * .5)

        -- -- snap the x value to the grid
        bX = math.floor((bX + self.rect.x) / 8) * 8

        -- Fix the button to the bottom of the window
        local bY = math.floor(((self.rect.y + self.rect.h) - buttonSize.y - 8) / 8) * 8

        self.cancelBtnData = self.editorUI:CreateTextButton({x = bX, y = bY}, "Cancel", "", PaletteOffset(1))

        self.cancelBtnData.onAction = function()

            -- Set value to true when cancel is pressed
            self.selectionValue = false

            CancelFileActions()

            -- Close the panel
            if(self.onParentClose ~= nil) then
                self.onParentClose()
            end
        end

    end

    self.canvas:DrawPixels(self.rect.x, self.rect.y, DrawMode.TilemapCache)

    self.editorUI.mouseCursor:SetCursor(5, true)

end

function ProgressModal:UpdateMessage(currentItem, total, action)

    local message = action .. " "..string.lpad(tostring(currentItem), string.len(tostring(total)), "0") .. " of " .. fileActionActiveTotal .. ".\n\n\nDo not restart or shut down Pixel Vision 8."

    local percent = (currentItem / total)

    -- Need to calculate the height ahead of time
    -- Draw message text
    local wrap = WordWrap(message, (self.rect.w / 4) - 4)
    self.lines = SplitLines(wrap)

    -- Draw message text
    local total = #self.lines
    local startX = 8
    local startY = 16

    -- Clear the canvas where we are going to redraw the text
    self.canvas:Clear(11, startX, startY, self.canvas.width - 16, (total - 1) * 8)

    -- We want to render the text from the bottom of the screen so we offset it and loop backwards.
    for i = 1, total do
        self.canvas:DrawText(self.lines[i]:upper(), startX, (startY + ((i - 1) * 8)), "medium", 0, - 4)
    end

    local width = self.canvas.width - 16

    startY = startY + 4
    -- Background
    self.canvas:Clear(0, startX, startY + 8, width, 8)

    if(percent > 1 ) then
        percent = 1
    end

    width = width * percent

    -- Progress
    self.canvas:Clear(6, startX + 1, startY + 9, width - 2, 6)

    -- TODO need to hack this to work (removed to avoid throwing an error)
    -- self.canvas:DrawSprites(self.cancelBtnData.cachedSpriteData["up"].spriteIDs, 32 + 16, 32 + 32, self.cancelBtnData.tiles.w)

    self.canvas:DrawPixels(self.rect.x, self.rect.y, DrawMode.TilemapCache)

    -- print("focus", self.cancelBtnData.inFocus)

    if(self.cancelBtnData.inFocus) then
        self.editorUI.mouseCursor:SetCursor(2, false)
    elseif(self.cursorID ~= 5) then
        self.editorUI.mouseCursor:SetCursor(5, true)
    end

end

function ProgressModal:Update(timeDelta)

    self.editorUI:UpdateButton(self.cancelBtnData)

end

function ProgressModal:Close()
    self.editorUI.mouseCursor:SetCursor(1, false)
end
