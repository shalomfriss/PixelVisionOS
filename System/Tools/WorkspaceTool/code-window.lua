function WorkspaceTool:OpenWindow(path, scrollTo, selection)

    -- Configure window settings
    self.iconPadding = 16
    self.iconWidth = 48
    self.iconHeight = 40
    self.windowBGColor = 11
    self.lastStartID = -1
    self.totalPerWindow = 12
    self.totalPerColumn = 3
    self.totalPerPage = 12
    self.pathHistory = {}

    -- Look for the last scroll position of this path
    if(scrollTo == nil and self.pathHistory[path] ~= nil) then

        -- if there is a path history object, change the scrollTO and selection  value
        scrollTo = self.pathHistory[path].scrollPos
        selection = self.pathHistory[path].selection

    end

    -- Set a default scrollTo value if none is provided
    scrollTo = scrollTo or 0
    selection = selection or 0

    -- Clear the window refresh time
    self.refreshTime = 0

    -- Clear the previous file list
    self.files = {}

    -- save the current directory
    self.currentPath = path

    -- Draw the window chrome
    DrawSprites(windowchrome.spriteIDs, 8, 16, windowchrome.width, false, false, DrawMode.TilemapCache)

    if(self.vSliderData == nil) then
        
        -- Create the slider for the window
        self.vSliderData = editorUI:CreateSlider({x = 192, y = 26, w = 16, h = 195}, "vsliderhandle", "This is a vertical slider")
        self.vSliderData.onAction = function(value) 
            self:DrawWindow(Clamp(self.hiddenRows * value, 0, self.hiddenRows - 1) * self.totalPerColumn)
        end

        -- Register the slider
        self:RegisterUI(self.vSliderData, "UpdateSlider", editorUI)
    end

    -- Create the close button
    if(self.closeButton == nil) then
        
        self.closeButton = editorUI:CreateButton({x = 192, y = 16}, "closewindow", "Close the window.")
        self.closeButton.hitRect = {x = self.closeButton.rect.x + 2, y = self.closeButton.rect.y + 2, w = 10, h = 10}
        self.closeButton.onAction = function() self:CloseWindow() end

        -- Register the close button
        self:RegisterUI(self.closeButton, "UpdateButton", editorUI)

    end

    -- Get the list of files from the Lua Service
    self.files = self:GetDirectoryContents(self.currentPath)

    -- Need to clear the previous button drop targets
    if(self.windowIconButtons ~= nil) then
        for i = 1, #self.windowIconButtons.buttons do
            editorUI.collisionManager:RemoveDragTarget(self.windowIconButtons.buttons[i])
            -- editorUI:ToggleGroupRemoveButton(windowIconButtons, i)
        end
        -- editorUI:ClearIconGroup(windowIconButtons)

        editorUI:ClearFocus()
    else
        -- Create a icon button group for all of the files
        self.windowIconButtons = pixelVisionOS:CreateIconGroup(false)

        self:RegisterUI(self.windowIconButtons, "UpdateIconGroup", pixelVisionOS)

        self.windowIconButtons.onTrigger = function(id) self:OnWindowIconClick(id) end

        -- Make sure we disable any selection on the desktop when clicking inside of the window icon group
        self.windowIconButtons.onAction = function(id) self:OnWindowIconSelect(id) end
    end

    -- DrawRect()

    -- Reset the last start id
    self.lastStartID = -1

    if(runnerName ~= DrawVersion and runnerName ~= TuneVersion) then

        -- Check to see if this is a game directory
        if(pixelVisionOS:ValidateGameInDir(self.currentPath, {"code.lua"}) and TrashOpen() == false) then

            table.insert(
                self.files,
                1,
                {
                    name = "Run",
                    type = "run",
                    ext = "run",
                    path = self.currentPath,
                    isDirectory = false,
                    selected = false
                }

            )
        end

    end

    local parentDirectory = self.currentPath.ParentPath

    -- Check to see if this is a root directory
    if(parentDirectory.Path ~= "/Disks/" and parentDirectory.Path ~= "/Tmp/" and parentDirectory.Path ~= "/") then

        table.insert(
            self.files,
            1,
            {
                name = "..",
                type = "updirectory",
                path = parentDirectory,
                isDirectory = true,
                selected = false
            }

        )
    end

    -- Save a count of the files after we add the special files to the list
    self.fileCount = #self.files

    -- Update visible and hidden row count
    self.totalRows = math.ceil(self.fileCount / self.totalPerColumn) + 1
    self.hiddenRows = self.totalRows - math.ceil(self.totalPerPage / self.totalPerColumn)

    -- -- Enable the scroll bar if needed
    editorUI:Enable(self.vSliderData, self.fileCount > self.totalPerWindow)

    -- Update the slider
    editorUI:ChangeSlider(self.vSliderData, scrollTo)
    
    -- Redraw the window
    self:RefreshWindow()

    -- Clear any selected file
    -- self.currentSelectedFile = nil

    -- -- Select file
    -- if(selection > 0) then
    --     editorUI:SelectIconButton(windowIconButtons, selection, true)
    -- else
    --     UpdateContextMenu(WindowFocus)
    -- end

    self:ChangeWindowTitle(self.currentPath.Path)

    -- make sure the correct desktop icon is open

    local pathSplit = string.split(self.currentPath.Path, "/")

    local desktopIconName = pathSplit[1]

    local iconID = -1

    for i = 1, #self.desktopIcons do
        if(self.desktopIcons[i].name == desktopIconName) then
            iconID = i
            break
        end
    end
    
    -- Try to find the icon button if we open a window and its not selected beforehand
    if(self.currentOpenIconButton == nil and iconID > 0) then

        self.currentOpenIconButton = self.desktopIconButtons.buttons[iconID]

        if(self.currentOpenIconButton.open == false) then
            print("Open desktop icon", self.currentOpenIconButton.name)

            pixelVisionOS:OpenIconButton(self.currentOpenIconButton)
        end

    end

    -- Registere the window with the tool so it updates
    self:RegisterUI({name = "Window"}, "UpdateWindow", self)

end

function WorkspaceTool:UpdateWindow()

    -- print("Update Window")

    if(self.invalid == true) then

        self:DrawWindow(self.lastStartID)
        
        editorUI:ResetValidation(self)

    end

end

function WorkspaceTool:CurrentlySelectedFile()

    -- Create containers for selected files and temp file
    local selectedFiles = {}
    local tmpFile = nil

    -- Loop through all of the files
    for i = 1, self.fileCount do
        
        -- Get the current file
        tmpFile = self.files[i]
        
        -- check to see if the file is selected
        if(tmpFile.selected) then
            
            -- Insert the selected file into the array
            table.insert(selectedFiles, i)
        end
    end

    -- Return all of the selected files or nil if there are no selections
    return #selectedFiles > 0 and selectedFiles or nil
    
end

function WorkspaceTool:RefreshWindow()
    editorUI:Invalidate(self)
    -- self.windowInvalidated = true
end

-- This is a helper for changing the text on the title bar
function WorkspaceTool:ChangeWindowTitle(pathTitle)

    -- Clean up the path
    if(pathTitle:sub(1, 7) == "/Disks/") then
        pathTitle = pathTitle:sub(7, #pathTitle)
    elseif(pathTitle:sub(1, 5) == "/Tmp/") then
        pathTitle = pathTitle:sub(5, #pathTitle)
    end

    DrawRect(24, 16, 168, 8, 0, DrawMode.TilemapCache)

    local maxChars = 43
    if(#pathTitle > maxChars) then
        pathTitle = pathTitle:sub(0, maxChars - 3) .. "..."
    else
        pathTitle = string.rpad(pathTitle, maxChars, "")
    end

    DrawText(pathTitle:upper(), 19, 17, DrawMode.TilemapCache, "medium", 15, - 4)

    -- Look for desktop icon
    -- TODO make sure the correct desktop item is highlighted

    
end

function WorkspaceTool:CloseWindow()

    -- Clear the previous scroll history
    self.pathHistory = {}

    self:RemoveUI(self.closeButton.name)
    self.closeButton = nil

    self:RemoveUI(self.vSliderData.name)
    self.vSliderData = nil

    self:RemoveUI(self.windowIconButtons.name)
    self.windowIconButtons = nil

    self.currentSelectedFile = nil

    self.currentPath = nil

    DrawRect(8, 16, windowchrome.width * 8, math.floor(#windowchrome.spriteIDs / windowchrome.width) * 8, BackgroundColor(), DrawMode.TilemapCache)

    self:DrawWallpaper()

    pixelVisionOS:ClearIconGroupSelections(self.desktopIconButtons)

    if(self.currentOpenIconButton ~= nil) then
        pixelVisionOS:CloseIconButton(self.currentOpenIconButton)
    end

    editorUI:ClearFocus()

    -- Update the drop down menu
    self:UpdateContextMenu(NoFocus)

    -- Remvoe the window UI elements
    self:RemoveUI("Window")

    

end

function WorkspaceTool:OnWindowIconSelect(id)

    -- print("OnWindowIconSelect", id)

    -- #3
    if(self.playingWav) then
        StopWav()
        self.playingWav = false
    end

    local realFileID = id + (self.lastStartID)
    local selectedFile = self.files[realFileID]

    local selectionFlag = true
    
    -- TODO test for shift or ctrl

    -- TODO need to clear all selected files

    local selections = self:CurrentlySelectedFile()
  
    if(Key(Keys.LeftShift, InputState.Down) or Key( Keys.RightShift, InputState.Down )) then

        -- Find the first selection and select all files all the way down to the current selection

        if(selections ~= nil) then

            -- Create the range between the first selected file and the one that was just selected
            local range = {realFileID, selections[1]}

            -- Sort the range from lowest to highest
            table.sort(range, function(a,b) return a < b end)

            -- Loop through all of the files and fix the selected states
            for i = 1, self.fileCount do
                
                print("File", i, "selected",  tostring(i >= range[1] and i <= range[2]))
                
                -- Change the value based on if it is within the range
                self.files[i].selected = i >= range[1] and i <= range[2]

            end

        end

        -- Update the selection
        selections = self:CurrentlySelectedFile()

    elseif(Key(Keys.LeftControl, InputState.Down) or Key( Keys.RightControl, InputState.Down )) then

        -- change the selection flag to the opposet of the current file's selection value
        selectionFlag = not selectedFile.selected

        print("crt select", selectionFlag)
    else

        -- Deselect all the files
        if(selections ~= nil) then

            for i = 1, #selections do
                self.files[selections[i]].selected = false
            end

        end

    end

    -- Set the selection of the file that was just selected
    selectedFile.selected = selectionFlag

    print("select", realFileID, selectedFile.selected)

    local lastValue = false

    -- Loop through all of the window buttons
    for i = 1, #self.windowIconButtons.buttons do

        -- Get a reference to the window button
        local tmpButton = self.windowIconButtons.buttons[i]

        -- Manually fix the selection of the buttons being displayed

        lastValue = tmpButton.selected

        tmpButton.selected = self.files[tmpButton.fileID].selected

        if(lastValue ~= tmpButton.selected) then
            editorUI:Invalidate(tmpButton)
        end

    end
    -- #4
    self:UpdateContextMenu(self.WindowIconFocus)

end

function WorkspaceTool:OnWindowIconClick(id)

    print("OnWindowIconClick", id)

    -- Make sure desktop icons are not selected
    pixelVisionOS:ClearIconGroupSelections(self.desktopIconButtons)

    -- -- local index = id + (lastStartID)-- TODO need to add the scrolling offset

    local tmpItem = self.files[id + self.lastStartID]--CurrentlySelectedFile()-- files[index]

    local type = tmpItem.type
    local path = tmpItem.path


    -- TODO need a list of things we can't delete

    -- Enable delete option

    -- -- print("Window Icon Click", tmpItem.name)
    local type = tmpItem.type

    -- If the type is a folder, open it
    if(type == "folder" or type == "updirectory") then

        
        -- self.pathHistory[self.currentPath.Path].scrollPos = self.vSliderData.value
        -- self.pathHistory[self.currentPath.Path].selection
        self:OpenWindow(tmpItem.path)

        -- Check to see if the file is in the trash
    elseif(self:TrashOpen()) then

        -- Show warning message about trying to edit files in the trash
        pixelVisionOS:ShowMessageModal(self.toolName .. " Error", "You are not able to edit files inside of the trash.", 160, false
        )

        -- Check to see if the file is an executable
    elseif(type == "run") then


        LoadGame(path)



    elseif(type == "pv8") then

        -- TODO need to see if there is space to mount another disk
        -- TODO need to know if this disk is being mounted as read only
        -- TODO don't run
        pixelVisionOS:ShowMessageModal("Run Disk", "Do you want to mount this disk?", 160, true,
            function()

                -- Only perform the copy if the user selects OK from the modal
                if(pixelVisionOS.messageModal.selectionValue) then

                    MountDisk(NewWorkspacePath(path))

                    -- TODO need to load the game in read only mode
                    -- LoadGame(path)

                end

            end
        )

    elseif(type == "wav") then

        PlayWav(NewWorkspacePath(path))

        self.playingWav = true

        -- Check to see if there is an editor for the type or if the type is unknown
    elseif(self.editorMapping[type] == nil or type == "unknown") then

        pixelVisionOS:ShowMessageModal(self.toolName .. " Error", "There is no tool installed to edit this file.", 160, false
        )

        -- Now we are ready to try to edit a file
    else

        if(type == "installer") then

            if(PathExists(NewWorkspacePath("/Workspace/")) == false) then

                pixelVisionOS:ShowMessageModal("Installer Error", "You need to create a 'Workspace' drive before you can run an install script.", 160, false)

                return

                -- TODO this could be optimized by using the path segments?
            elseif(string.starts(self.currentPath.Path, "/Disks/") == false) then

                -- TODO need to see if there is space to mount another disk
                -- TODO need to know if this disk is being mounted as read only
                -- TODO don't run
                pixelVisionOS:ShowMessageModal("Installer Error", "Installers can only be run from a disk.", 160, false)

                return

            end
        end

        -- When trying to load a tilemap.png file, check if there is a json file first
        if(type == "tiles" and PathExists(self.currentPath.AppendFile("tilemap.json"))) then
            -- Change the type to PNG so the image editor is used instead of the tilemap editor
            type = "png"
        end

        -- Find the correct editor from the list
        local editorPath = self.editorMapping[type]

        -- Set up the meta data for the editor
        local metaData = {
            directory = self.currentPath.Path,
            file = tmpItem.path,
            filePath = tmpItem.path, -- TODO this should be the root path
            fileName = tmpItem.fullName,
            -- introMessage = "Editing '" .. tmpItem.fullName .."'."
        }

        -- Check to see if the path to the editor exists
        if(PathExists(NewWorkspacePath(editorPath))) then

            -- Load the tool
            LoadGame(editorPath, metaData)

        end

        -- TODO find an editor for the file's extension
    end


end

function WorkspaceTool:OnOverDropTarget(src, dest)

    if(src.iconPath ~= dest.iconPath) then

        editorUI:HighlightIconButton(dest, true)

    end

end

function WorkspaceTool:DrawWindow(startID)

    -- TODO this should probably be a clamp?

    -- Make sure that the start ID isn't less than 0
    if(startID < 0) then
        startID = 0
    end
    
    -- Test to see if there has been a change in the startID
    if(self.lastStartID == startID) then
        return
    end

    -- Save the startID offset
    self.lastStartID = startID

    -- Clear any current selection
    pixelVisionOS:ClearIconGroup(self.windowIconButtons)

    -- TODO this is static so move it into the tool's constructor
    local startX = 13
    local startY = 32
    local tmpRow = 0
    

    local requiredFiles = {"data.json"}

    -- TODO this may be redundant
    if(self.runnerName ~= DrawVersion and self.runnerName ~= TuneVersion) then
        table.insert(requiredFiles, "info.json")
    end

    -- TODO make sure the trash path check is valid
    local isGameDir = pixelVisionOS:ValidateGameInDir(self.currentPath, requiredFiles) and self:TrashOpen() == false

    -- local tmpPath = NewWorkspacePath(item.path)
    local pathParts = self.currentPath.GetDirectorySegments()
    local systemRoot = ((pathParts[1] == "Workspace" and #pathParts == 1) or (pathParts[1] == "Disks" and #pathParts == 2))

    -- print("parts", #pathParts, dump(pathParts), systemRoot)

    for i = 1, self.totalPerPage do

        -- Calculate the real index
        local fileID = i + startID


        local index = i - 1

        -- Update column value
        local column = index % self.totalPerColumn

        local newX = index % self.totalPerColumn * (self.iconWidth + self.iconPadding) + startX
        local newY = tmpRow * (self.iconHeight + self.iconPadding / 2) + startY

        -- Update the row for the next loop
        if (column == (self.totalPerColumn - 1)) then
            tmpRow = tmpRow + 1
        end

        if(fileID <= self.fileCount) then

            local item = self.files[fileID]

            -- Find the right type for the file
            self:UpdateFileType(item, isGameDir)

            local spriteName = self:GetIconSpriteName(item)

            if(spriteName == self.fileTypeMap["folder"] and systemRoot == true) then

                -- TODO need another check for libs and tools

                if(item.name == "System" or item.name == "Libs" or item.name == "Tools") then

                    -- TODO should we check to make sure the folder isn't empty?

                    local correctParent = self.currentPath.EntityName == "System"

                    if(item.name == "System") then
                        spriteName = "fileosfolder"
                    elseif(correctParent and correctParent) then
                        spriteName = "fileosfolder"
                    end
                end
            end

            local toolTip = "Double click to "

            if(item.name == "Run") then
                toolTip = toolTip .. "run this game."
            elseif(item.name == "..") then

                toolTip = toolTip .. "go to the parent folder."

            elseif(item.isDirectory == true) then

                toolTip = toolTip .. "open the " .. item.name .. " folder."
            else
                toolTip = toolTip .. "edit " .. item.fullName .. "."

            end

            local button = pixelVisionOS:NewIconGroupButton(self.windowIconButtons, {x = newX, y = newY}, spriteName, item.name, toolTip, self.windowBGColor)

            button.fileID = fileID
            button.iconName = item.name
            button.iconType = item.type
            button.iconPath = item.path
            
            -- TODO this is keeping the updir and run from selecting
            button.selected = item.selected

            -- Disable the drag on files that don't exist in the directory
            if(item.type == "updirectory" or item.type == "folder") then

                -- updirectory and folder share the same code but we don't want to drag updirectory
                if(item.type == "updirectory") then
                    button.dragDelay = -1
                end

                -- button.onPress = function()
                --   -- print("Starting Drag")
                -- end

                button.onOverDropTarget = function(src, dest) self:OnOverDropTarget(src, dest) end

                -- -- Add on drop target code to each folder type
                button.onDropTarget = function(src, dest) self:FileDropAction(src, dest) end


            elseif(item.type == "run" or item.type == "unknown" or item.type == "installer") then

                editorUI.collisionManager:DisableDragging(button)
                button.onDropTarget = nil

            end

        else

            editorUI:NewDraw("DrawRect", {newX, newY, 48, 40, self.windowBGColor, DrawMode.TilemapCache})

        end



    end


end

function WorkspaceTool:OnOverDropTarget(src, dest)

    if(src.iconPath ~= dest.iconPath) then

        pixelVisionOS:HighlightIconButton(dest, true)

    end

end

function WorkspaceTool:FileDropAction(src, dest)

    -- if src and dest paths are the same, exit
    if(src == dest) then
        return
    end

    filesToCopy = {}

    fileActionSrc = currentDirectory

    -- TODO need to find the base path
    local srcPath = NewWorkspacePath(src.iconPath)
    if(srcPath.IsDirectory) then

        -- Add all of the files that need to be copied to the list
        filesToCopy = GetEntitiesRecursive(srcPath)

    end

    -- Make sure the selected directory is included
    table.insert(filesToCopy, 1, srcPath)


    local destPath = NewWorkspacePath(dest.iconPath)

    local action = "move"

    local srcSeg = srcPath.GetDirectorySegments()
    local destSeg = destPath.GetDirectorySegments()

    if(srcSeg[1] == "Tmp" and srcSeg[2] == "Trash") then
        -- print("Trash")
        action = "move"
    elseif(srcSeg[1] == "Disks" and destSeg[1] == "Disks") then
        if(srcSeg[2] ~= destSeg[2]) then
            action = "copy"
        end
    elseif(srcSeg[1] ~= destSeg[1]) then
        action = "copy"
    end

    -- print(action, dump(srcSeg), dump(destSeg))

    -- print("Drop Action", action, srcPath, destPath, srcSeg[1], srcSeg[2])

    -- Perform the file action
    StartFileOperation(destPath, action)

end

function WorkspaceTool:UpdateFileType(item, isGameFile)

    local key = item.type--item.isDirectory and item.type or item.ext

    key = item.type

    -- TODO support legacy files
    if(key == "png" and isGameFile == true) then
        -- -- print("Is PNG")
        if(item.name == "sprites" and self.editorMapping["sprites"] ~= nil) then
            key = "sprites"
        elseif(item.name == "tilemap" and self.editorMapping["tilemap"] ~= nil) then
            key = "tiles"
        elseif(item.name == "colors" and self.editorMapping["colors"] ~= nil) then
            key = "colors"
        end
    elseif(key == "font.png") then

        if(isGameFile == false or self.editorMapping["font"] == nil) then
            key = "png"
        else
            key = "font"
        end

    elseif(key == "json" and isGameFile == true) then

        if(item.name == "sounds" and self.editorMapping["sounds"] ~= nil)then
            key = "sounds"
        elseif(item.name == "tilemap" and self.editorMapping["tilemap"] ~= nil) then
            key = "tilemap"
        elseif(item.name == "music" and self.editorMapping["music"] ~= nil) then
            key = "music"
        elseif(item.name == "data" and self.editorMapping["system"] ~= nil) then
            key = "system"
        elseif(item.name == "info") then
            key = "info"
        end

    end

    if(key == "wav") then
        item.ext = "wav"
    end

    -- Fix type for pv8 and runner templates
    if(item.type == "pv8" or item.type == "pvr") then
        key = item.type
    end

    -- Last chance to fix any special edge cases like the installer and info which share text file extensions
    if(key == "txt" and item.name:lower() == "installer") then
        key = "installer"
    end

    item.type = key

end

function WorkspaceTool:GetIconSpriteName(item)

    local iconName = self.fileTypeMap[item.type]
    -- -- print("name", name, iconName)
    return iconName == nil and "fileunknown" or self.fileTypeMap[item.type]

end

function WorkspaceTool:OnValueChange(value)

    

    -- local offset = 


end