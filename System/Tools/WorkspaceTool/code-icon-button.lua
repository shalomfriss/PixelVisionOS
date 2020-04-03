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
-- Christer Kaitila - @McFunkypants
-- Pedro Medeiros - @saint11
-- Shawn Rakowski - @shwany
--

function PixelVisionOS:CreateIconButton(point, spriteName, label, toolTip, bgColor)

    -- TODO Create custom button states?

    label = label or ""

    -- TODO this need to be changed to a real rect when refactoring the components
    local tmpRect = {x = point.X, y = point.y, w = 48, h = 40}
    
    -- Use the same data as the button (but don't pass in a sprite)
    local data = self.editorUI:CreateButton(tmpRect, nil, toolTip)

    data.name = "Icon" .. data.name

    -- Add the selected property to make this a toggle button
    data.selected = false
    data.open = false
    data.redrawBackground = true
    -- Enable the button's doubleClick property
    data.doubleClick = true
    data.open = false

    data.tilePixelArgs = {nil, data.rect.x, data.rect.y, 48, 48, DrawMode.TilemapCache, 0}

    data.onClick = function(tmpData)
        
        if(self.editorUI.currentButtonDown == tmpData.name) then
            -- Toggle the button's action
            --#5 | #1
            self:ToggleIconButton(tmpData)

        end

    end

    data.onRedraw = function(tmpData)
        self:RedrawIconButton(tmpData)
    end

    data.bgDrawArgs = {data.rect.x, data.rect.y, data.rect.w - 1, data.rect.h, BackgroundColor(), DrawMode.TilemapCache}

    self:CreateIconButtonStates(data, spriteName, label, bgColor)

    -- Modify the hit rect around the icon
    data.hitRect = {x = data.rect.x + 12, y = data.rect.y, w = 24, h = 24}

    -- TODO we need multiple hitRects for this to support clicking on the label as well

    return data

end

function PixelVisionOS:CreateIconButtonStates(data, spriteName, text, bgColor)

    -- Make sure the spriteName and text have changed before rebuilding the states
    if(data.spriteName == spriteName and text == data.toolTip) then
        return
    end

    data.spriteName = spriteName

    -- Clear the cached pixel data
    data.cachedPixelData = {}

    if(spriteName == "none") then

        -- Make sure the background has been updated
        data.bgDrawArgs[5] = bgColor or BackgroundColor()

        self.editorUI:NewDraw("DrawRect", data.bgDrawArgs)

    else

        local states = {"up", "over", "openup", "selectedup", "disabled", "dragging"}

        for i = 1, #states do

            local state = states[i]
            local canvas = NewCanvas(data.rect.w, data.rect.h)

            -- Change the sprite state to accommodate for the fact that there is no dragging sprite
            local spriteState = state == "dragging" and "up" or state

            if(state == "over") then
                -- print("OVER")
                state = "over"
                spriteState = "selectedup"
            end

            -- Clear the canvas to the default background color
            canvas:Clear(-1)

            -- Get the background color
            local bgColor = state ~= "dragging" and data.bgDrawArgs[5] or - 1

            -- Set the stroke and pattern to clear any previous icon this draws over
            canvas:SetStroke({bgColor}, 1, 1)
            canvas:SetPattern({bgColor}, 1, 1)

            local offset = 12

            -- Clear icon background
            canvas:DrawSquare(offset, 0, 24 + offset, 24, true)

            -- Create states
            if(spriteName == nil) then
                spriteName = "fileunknown"
            end

            local spriteData = _G[spriteName .. spriteState]
            
            if(spriteData ~= nil) then
                
                local tmpX = math.floor((data.rect.w - spriteData.width * 8) * .5)

                canvas:DrawSprites(spriteData.spriteIDs, tmpX, 0, spriteData.width)

                local lines = {""}
                local counter = 0
                local maxWidth = 11
                local maxChars = maxWidth * 2

                if(#text > maxChars) then
                    text = text:sub(0, maxChars - 3) .. "..."
                end

                for i = 1, #text do

                    lines[#lines] = lines[#lines] .. text:sub(i, i):upper()

                    if(i % maxWidth == 0 and i ~= #text)then
                        table.insert(lines, "")
                    end

                end

                -- Clear the area for the text
                canvas:DrawSquare(0, 24, data.rect.w - 2, 24 + 14, true)

                for i = 1, #lines do

                    -- Get the current line
                    local line = lines[i]

                    -- Calculate the centered text
                    local x = (data.rect.w - (#line * 4)) * .5

                    -- Calculate the y position
                    local y = ((i - 1) * 6) + 24

                    local textColor = state == "up" and 0 or 15

                    if(state == "dragging") then
                        textColor = 15
                    end

                    if(state == "disabled") then
                        textColor = 12
                    end

                    if(textColor == 15) then

                        -- Set the background color to black since the text is white
                        canvas:SetStroke({0}, 1, 1)
                        canvas:SetPattern({0}, 1, 1)

                        canvas:DrawSquare(x - 1, y + 1, (x ) + (#line * 4) - 1, (y) + 7, true)

                    end

                    -- Draw the text
                    canvas:DrawText(line, x, y, "medium", textColor, - 4)

                end

                data.cachedPixelData[states[i]] = canvas

            end
        end

        editorUI:Invalidate(data)

    end

end

function PixelVisionOS:UpdateIconButton(data, hitRect)

    -- Make sure we have data to work with and the component isn't disabled, if not return out of the update method
    if(data == nil) then
        return
    end

    -- If the button has data but it's not enabled exit out of the update
    if(data.enabled == false) then

        -- If the button is disabled but still in focus we need to remove focus
        if(data.inFocus == true) then
            self.editorUI:ClearFocus(data)
        end

        -- See if the button needs to be redrawn.
        -- self:RedrawButton(data)
        data.onRedraw(data)
        -- Shouldn't update the button if its disabled
        return

    end



    -- If the hit rect hasn't been overridden, then use the buttons own hit rect
    if(hitRect == nil) then
        hitRect = data.hitRect or data.rect
    end

    local overrideFocus = (data.inFocus == true and self.editorUI.collisionManager.mouseDown)

    local collision = self.editorUI.collisionManager:MouseInRect(hitRect)

    -- Make sure we don't detect a collision if the mouse is down but not over this button
    if(self.editorUI.collisionManager.mouseDown and data.inFocus == false) then

        if(data.highlight == true and collision == false) then
            self:HighlightIconButton(data, false)
        end

        -- See if the button needs to be redrawn.
        data.onRedraw(data)
        return
    end

    -- Ready to test finer collision if needed
    if(collision or overrideFocus) then


        if(data.doubleClick == true) then

            -- If the button wasn't in focus before, reset the timer since it's about to get focus
            if(data.inFocus == false) then
                data.doubleClickTime = 0
                data.doubleClickActive = false
            end

            data.doubleClickTime = data.doubleClickTime + self.editorUI.timeDelta
            
            if(data.doubleClickActive and data.doubleClickTime > data.doubleClickDelay) then
                data.doubleClickActive = false
            end
        end

        -- If we are in the collision area, set the focus
        self.editorUI:SetFocus(data)

        self.editorUI:Invalidate(data)

        -- Check to see if the button is pressed and has an onAction callback
        if(self.editorUI.collisionManager.mouseReleased == true) then

            -- Click the button
            data.onClick(data)
            data.firstPress = true
        elseif(self.editorUI.collisionManager.mouseDown) then

            if(data.firstPress ~= false) then

                -- Call the onPress method for the button
                data.onFirstPress(data)

                -- Change the flag so we don't trigger first press again
                data.firstPress = false
            end
        end

    else

        if(data.highlight) then
            self:HighlightIconButton(data, false)
            data.highlight = false
        end

        if(data.inFocus == true) then
            data.firstPress = true
            -- If we are not in the button's rect, clear the focus
            self.editorUI:ClearFocus(data)

            self.editorUI:Invalidate(data)

        end

    end

    -- Make sure we don't need to redraw the button.
    -- self:RedrawButton(data)
    data.onRedraw(data)

end

function PixelVisionOS:RedrawIconButton(data)

    if(data == nil) then
        return
    end

    -- If the button changes state we need to redraw it to the tilemap
    if(data.invalid == true) then

        -- The default state is up
        local state = "up"

        -- If the button is selected, we will use the selected up state
        if(data.selected == true) then
            state = "selected" .. state
        end

        if(data.highlight) then
            state = "over"
        end
       
        -- Test to see if the button is disabled. If there is a disabled sprite data, we'll change the state to disabled. By default, always use the up state.
        if(data.enabled == false and data.cachedPixelData["disabled"] ~= nil and data.selected ~= true) then --_G[spriteName .. "disabled"] ~= nil) then
            state = "disabled"
        end

        if(data.open == true) then
            state = "openup"
        end

        -- Test to see if the sprite data exist before updating the tiles
        if(data.cachedPixelData ~= nil and data.cachedPixelData[state] ~= nil and data.tilePixelArgs ~= nil) then

            -- Update the tile draw arguments
            data.tilePixelArgs[1] = data.cachedPixelData[state]

            -- self:NewDraw("DrawPixels", data.cachedPixelData)

            data.cachedPixelData[state]:DrawPixels(data.rect.x, data.rect.y)
            -- canvas:DrawPixels(50, 50)

        end

        self.editorUI:ResetValidation(data)

    end

end

function PixelVisionOS:ToggleIconButton(data, value, callAction)

    
    -- Check to see if the icon was double clicked
    -- #6 | #2
    local doubleClick = data.doubleClickActive and data.doubleClickTime < data.doubleClickDelay

    -- Reset the double click flags
    data.doubleClickTime = 0
    data.doubleClickActive = true

    if(doubleClick == true and data.onTrigger ~= nil and callAction ~= false) then
        data.onTrigger()
        return
    end

    -- Call the button data's onAction method and pass the current selected state
    if(data.selected == false)then

        if(value == nil) then
            value = not data.selected
        end

        -- invert the selected value
        data.selected = true

        -- Invalidate the button so it redraws
        self.editorUI:Invalidate(data)

    end

    if(data.onAction ~= nil and callAction ~= false) then
        -- #7 | #3
        data.onAction(data.selected, doubleClick)
    end

end

function PixelVisionOS:OpenIconButton(data, value)
    
    if(data.open ~= value) then
        self.editorUI:Invalidate(data)
    end
    
    data.open = value
    
end

-- function PixelVisionOS:CloseIconButton(data)
--     data.open = false
--     self.editorUI:Invalidate(data)
-- end

function PixelVisionOS:CreateIconGroup(singleSelection)

    singleSelection = singleSelection == nil and true or singleSelection

    local data = self.editorUI:CreateData()

    data.name = "IconButtonGroup" .. data.name

    data.buttons = {}
    data.currentSelection = 0
    data.onAction = nil
    data.invalid = false
    data.hovered = 0
    data.singleSelection = singleSelection
    data.dragOverTime = 0
    data.dragOverDelay = .3
    data.drawIconArgs = {nil, 0, 0, 48, 40, false, false, DrawMode.UI}

    return data

end

-- Helper method that created a toggle button and adds it to the group
function PixelVisionOS:NewIconGroupButton(data, point, spriteName, label, toolTip, bgColor)

    -- Create a new toggle group button
    local buttonData = self:CreateIconButton(point, spriteName, label, toolTip, bgColor)

    -- Add the new button to the toggle group
    self:IconGroupAddButton(data, buttonData)

    -- Return the button data
    return buttonData

end

function PixelVisionOS:IconGroupAddButton(data, buttonData, id)

    -- TODO need to replace with table insert
    -- Need to figure out where to put the button, if no id exists, find the last position in the buttons table
    id = id or #data.buttons + 1

    -- save the button data
    table.insert(data.buttons, id, buttonData)

    self.editorUI.collisionManager:EnableDragging(buttonData, .5, data.name)

    buttonData.id = id

    -- Attach a new onAction to the button so it works within the group
    buttonData.onAction = function()


        -- if(doubleClick == true) then
        --   self:TriggerIconButton(data, id)
        -- else
        -- TODO need to enable double click here
        -- self:SelectIconButton(data, id)
        -- end

        -- TODO restore icon if dragging is complete
        -- if(buttonData.dragging == true) then
        -- print("Redraw", buttonData.name, "enabled")

        -- Clear

        -- #8 | #4
        buttonData.dragging = false

        -- end

        -- End the drag
        if(data.onEndDrag ~= nil) then
            data.onEndDrag(data)
        end

    end

    buttonData.onTrigger = function()

        self:TriggerIconButton(data, id)
    end


    buttonData.onPress = function(value)

        -- TODO there should be a delay
        if(buttonData.onStartDrag ~= nil) then

            -- if(buttonData.selected == false) then
                self:SelectIconButton(data, id)
            -- end

            data.draggingSrc = buttonData.iconPath
            data.draggingPixelData = buttonData.cachedPixelData["dragging"]
            data.dragTarget = {path = buttonData.iconPath, pxielData = buttonData.cachedPixelData["dragging"]}

            buttonData.onStartDrag(buttonData)
            
        end

    end

    -- Invalidate the button so it redraws
    self.editorUI:Invalidate(buttonData)

end

function PixelVisionOS:TriggerIconButton(data, id)

    if(data.onTrigger ~= nil) then
        data.onTrigger(id)
    end

end


function PixelVisionOS:IconGroupRemoveButton(data, id)

    self:ToggleGroupRemoveButton(data, id)

end

function PixelVisionOS:UpdateIconGroup(data)

    -- Exit the update if there is no is no data
    if(data == nil) then
        return
    end

    -- Set data for the total number of buttons for the loop
    local total = #data.buttons
    local btn = nil

    -- Loop through each of the buttons and update them
    for i = 1, total do

        btn = data.buttons[i]

        -- TODO not sure why this would ever be nil
        if(btn ~= nil) then
            if(btn.dragging == true) then

                -- Look for drop targets
                for i = 1, #self.editorUI.collisionManager.dragTargets do

                    local dest = self.editorUI.collisionManager.dragTargets[i]

                    -- Look for a collision with the dest
                    if(self.editorUI.collisionManager:MouseInRect(dest.hitRect ~= nil and dest.hitRect or dest.rect)) then

                        -- TODO there should be a timer before this is actually triggered
                        if(dest.onOverDropTarget ~= nil) then

                            if(data.dragOverIconButton == nil or data.dragOverIconButton.name ~= dest.name) then


                                data.dragOverIconButton = dest
                                data.dragOverTime = 0
                            end

                            if(data.dragOverTime > - 1) then
                                data.dragOverTime = data.dragOverTime + editorUI.timeDelta
                            end

                            if(data.dragOverTime ~= -1 and data.dragOverTime >= .2) then
                                dest.onOverDropTarget(btn, dest)
                            end

                            break

                        end

                    end
                    
                end

                if(self.editorUI.collisionManager.mousePos.x > - 1 and self.editorUI.collisionManager.mousePos.y > - 1) then

                    local mouseOffset = {x = 24, y = 12}

                    local clipSize = {x = 0, y = 0, w = 48, h = 40}

                    -- TODO need to save this so it's not being called every time
                    -- Calculate mask
                    local displaySize = Display()

                    displaySize.x = displaySize.x - 1
                    -- TODO think this is a bug in the display size, it shouldn't need to subtract 9, just 1 like the width
                    displaySize.y = displaySize.y - 9
                    -- displaySize.width = displaySize.width - 1
                    -- displaySize.y = displaySize.y - 9

                    if((self.editorUI.collisionManager.mousePos.x + (clipSize.w / 2)) > displaySize.x) then
                        clipSize.w = clipSize.w - ((self.editorUI.collisionManager.mousePos.x + (clipSize.w / 2)) - displaySize.x)
                    elseif((self.editorUI.collisionManager.mousePos.x - (clipSize.w / 2)) < 0) then

                        local tmp = clipSize.w - ((self.editorUI.collisionManager.mousePos.x + (clipSize.w / 2))) + 1

                        clipSize.x = tmp
                        clipSize.w = clipSize.w - tmp

                        mouseOffset.x = mouseOffset.x - clipSize.x

                    end

                    if((self.editorUI.collisionManager.mousePos.y + (clipSize.h / 2)) > displaySize.y) then
                        clipSize.h = clipSize.h - ((self.editorUI.collisionManager.mousePos.y + (clipSize.h / 2)) - displaySize.y)
                    elseif((self.editorUI.collisionManager.mousePos.y - (clipSize.h / 2)) < 4) then
                        -- clipSize.h = 0

                        local tmp = clipSize.h - ((self.editorUI.collisionManager.mousePos.y + (clipSize.h / 2))) + 3

                        clipSize.y = tmp
                        clipSize.h = clipSize.h - tmp

                        mouseOffset.y = mouseOffset.y - clipSize.y

                    end

                    data.drawIconArgs[1] = btn.cachedPixelData["dragging"]:SamplePixels(clipSize.x, clipSize.y, clipSize.w, clipSize.h)
                    data.drawIconArgs[2] = self.editorUI.collisionManager.mousePos.x - mouseOffset.x
                    data.drawIconArgs[3] = self.editorUI.collisionManager.mousePos.y - mouseOffset.y
                    data.drawIconArgs[4] = clipSize.w
                    data.drawIconArgs[5] = clipSize.h

                    -- DrawPixels(btn.cachedPixelData["up"], 0,0)
                    self.editorUI:NewDraw("DrawPixels", data.drawIconArgs)
                end

            end

        end
       
        self:UpdateIconButton(btn)

    end

end

function PixelVisionOS:SelectIconButton(data, id, trigger)
    -- TODO need to make sure we handle multiple selections vs one at a time
    -- Get the new button to select
    local buttonData = data.buttons[id]
    --print("Select", id, #data.buttons)

    -- #1

    -- Make sure there is button data and the button is not disabled
    if(buttonData == nil or buttonData.enabled == false)then
        return
    end

    -- if the button is already selected, just ignore the request
    if(id == buttonData.selected) then
        return
    end
    
    if(data.singleSelection == true) then
        -- Make sure that the button is selected before we disable it
        buttonData.selected = true
        -- self:Enable(buttonData, false)

    end

    -- Now it's time to restore the last button.
    if(data.currentSelection > 0) then

        -- Get the old button data
        buttonData = data.buttons[data.currentSelection]

        -- Make sure there is button data first, incase there wasn't a previous selection
        if(buttonData ~= nil) then

            if(data.singleSelection == true) then
                -- Reset the button's selection value to the group's disable selection value
                buttonData.selected = false

                -- Enable the button since it is no longer selected
                self.editorUI:Enable(buttonData, true)

            end

        end

    end

    -- Set the current selection ID
    data.currentSelection = id

    -- Trigger the action for the selection
    if(data.onAction ~= nil and trigger ~= false) then

        -- #2
        data.onAction(id, buttonData.selected)
    end

end

function PixelVisionOS:IconGroupCurrentSelection(data)

    return self.editorUI:ToggleGroupCurrentSelection(data)

end

-- TODO is anything using this?
function PixelVisionOS:ToggleIconGroupSelections(data)

    self.editorUI:ToggleGroupSelections(data)

end

function PixelVisionOS:ClearIconGroupSelections(data)
    self.editorUI:ClearGroupSelections(data)
end

function PixelVisionOS:ClearIconGroup(data)

    self.editorUI:ClearToggleGroup(data)

end

function PixelVisionOS:HighlightIconButton(data, value)

    if(data.highlight ~= value) then
        data.highlight = value
        self.editorUI:Invalidate(data)
    end
    
end
