function WorkspaceTool:DrawWallpaper()

    local DrawVersion, TuneVersion = "Pixel Vision 8 Draw", "Pixel Vision 8 Tune"

    -- Set up logo values
    local logoSpriteData = _G["logo"]
    local colorOffset = 0
    local backgroundColor = tonumber(ReadBiosData("DefaultBackgroundColor", "5"))

    -- Make sure that the message bar has the correct background color to clear with
    pixelVisionOS.messageBar.clearDrawArgs[5] = backgroundColor

    if(self.runnerName == DrawVersion) then
        logoSpriteData = _G["logodraw"]
        colorOffset = 5
    elseif(self.runnerName == TuneVersion) then
        logoSpriteData = _G["logotune"]
    end

    -- Update background
    BackgroundColor(backgroundColor)

    -- Draw logo
    if(logoSpriteData ~= nil) then
        DrawSprites(logoSpriteData.spriteIDs, 13, 13, logoSpriteData.width, false, false, DrawMode.Tile, colorOffset)
    end

end

function WorkspaceTool:RebuildDesktopIcons()

    -- TODO need to make sure this is correct and used
    self.desktopHitRect = NewRect(0, 12, 256, 229)

    -- Clear the side where the desktop icons are
    DrawRect(216, 16, 39, 216, BackgroundColor(), DrawMode.TilemapCache)

    -- Place holder for the old selction
    local oldOpen = -1

    -- See if there are any desktop buttons
    if(self.desktopIconButtons ~= nil) then

        -- Find the total buttons
        local total = #self.desktopIconButtons.buttons

        -- Loop through all of the desktop buttons
        for i = 1, total do

            -- See if any of the desktop buttons are open before redrawing them
            if(self.desktopIconButtons.buttons[i].open) then
                oldOpen = i
            end
        end

    end

    -- Build Desktop Icons
    self.desktopIcons = {}

    if(PathExists(self.workspacePath)) then

        table.insert(self.desktopIcons, {
            name = "Workspace",
            sprite = PathExists(self.workspacePath.AppendDirectory("System")) and "filedriveos" or "filedrive",
            tooltip = "This is the 'Workspace' drive",
            path = self.workspacePath,
            type = "workspace",
            dragDelay = -1
        })
    end

    local disks = DiskPaths()

    for i = 1, #disks do

        local name = disks[i].EntityName
        local path = disks[i]

        table.insert(self.desktopIcons, {
            name = name,
            sprite = "diskempty",
            tooltip = "Double click to open the '".. name .. "' disk.",
            tooltipDrag = "You are dragging the '".. name .. "' disk.",
            path = path,
            type = "disk"
        })
    end

    -- Draw desktop icons
    local startY = 16

    self.desktopIconButtons = pixelVisionOS:CreateIconGroup()
    self.desktopIconButtons.name = "desktopIconGroup"

    self:RegisterUI(self.desktopIconButtons, "UpdateIconGroup")
    

    -- Register the component to be updated
    

    self.desktopIconButtons.onTrigger = function(value, doubleClick)

        -- Close the currently open button
        if(self.currentOpenIconButton ~= nil) then
            pixelVisionOS:CloseIconButton(self.currentOpenIconButton)
        end

        self.currentOpenIconButton = self.desktopIconButtons.buttons[value]
        pixelVisionOS:OpenIconButton(self.currentOpenIconButton)

        self:OpenWindow(self.desktopIcons[value].path)

    end
    
    self.desktopIconButtons.onAction = function(value)

        -- TODO need to check if the disk can be ejected?
    
        if(self.playingWav == true) then
            StopWav()
            self.playingWav = false
        end
    
        self:UpdateContextMenu(DesktopIconFocus)
    
        -- TODO this should clear the selection in a generic way
        -- Clear any window selections
        -- pixelVisionOS:ClearIconGroupSelections(self.windowIconButtons)
    
        -- Clear all file selections in the window
        self:ClearSelections()

        -- Redraw the window if needed to remove any current selections
        self:RefreshWindow()
        
    end

    -- for i = 1, #self.desktopIcons do

    --     local item = self.desktopIcons[i]

    --     local button = pixelVisionOS:NewIconGroupButton(self.desktopIconButtons, NewPoint(208, startY), item.sprite, item.name, item.tooltip, bgColor)

    --     button.iconName = item.name
    --     button.iconType = item.type
    --     button.iconPath = item.path

    --     if(item.dragDelay ~= nil) then
    --         button.dragDelay = item.dragDelay
    --     end

    --     button.toolTipDragging = item.tooltipDrag

    --     -- button.onOverDropTarget = OnOverDropTarget

    --     -- button.onDropTarget = FileDropAction

    --     startY = startY + 32 + 8

    -- end

    -- See if the trash exists
    -- if(PathExists(self.trashPath) == false) then
    --     CreateDirectory(self.trashPath)
    -- end

    -- local trashFiles = self:GetDirectoryContents(self.trashPath)

    -- table.insert(self.desktopIcons, {
    --     name = "Trash",
    --     sprite = #trashFiles > 0 and "filetrashfull" or "filetrashempty",
    --     tooltip = "The trash folder",
    --     path = self.trashPath,
    --     type = "throw out"
    -- })

    -- -- pixelVisionOS:EnableMenuItemByName(EmptyTrashShortcut, #trashFiles > 0)

    -- local item = self.desktopIcons[#self.desktopIcons]

    -- local trashButton = pixelVisionOS:NewIconGroupButton(self.desktopIconButtons, NewPoint(208, 198), item.sprite, item.name, item.tooltip, bgColor)

    -- trashButton.iconName = item.name
    -- trashButton.iconType = item.type
    -- trashButton.iconPath = item.path

    -- -- Lock the trash from Dragging
    -- trashButton.dragDelay = -1

    -- trashButton.onOverDropTarget = OnOverDropTarget

    -- trashButton.onDropTarget = function(src, dest)

    --     -- -- print("OnDropTarget", "Trash Icon", src.name, dest.name)
    --     if(src.iconType == "disk") then

    --         OnEjectDisk(src.iconName)

    --     else
    --         OnDeleteFile(src.iconPath)
    --         -- -- print("Move To", src.iconPath, dest.iconPath)
    --     end

    -- end

    -- -- Restore old open value
    -- if(oldOpen > - 1) then
    --     pixelVisionOS:OpenIconButton(self.desktopIconButtons.buttons[oldOpen])
    -- end


end

function WorkspaceTool:ClearDesktopSelection()

    pixelVisionOS:ClearIconGroupSelections(self.desktopIconButtons)

end