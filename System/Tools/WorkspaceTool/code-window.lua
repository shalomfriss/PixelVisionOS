FileTypeMap = 
    {
        folder = "filefolder",
        updirectory = "fileparentfolder",
        lua = "filecode",
        json = "filejson",
        png = "filepng",
        run = "filerun", -- TODO need to change this to run
        txt = "filetext",
        installer = "fileinstaller", -- TODO need a custom icon
        info = "fileinfo",
        pv8 = "diskempty",
        pvr = "disksystem",
        wav = "filewav",

        -- TODO these are not core file types
        unknown = "fileunknown",
        colors = "filecolor",
        system = "filesettings",
        font = "filefont",
        music = "filemusic",
        sounds = "filesound",
        sprites = "filesprites",
        tilemap = "filetilemap",
        pvt = "filerun",
        new = "filenewfile",
        gif = "filegif",
        tiles = "filetiles"
    }
    
function WorkspaceTool:OpenWindow(path, scrollTo, selection)

    print("Open", path)

    -- Make sure the path exists before loading it up
    if(PathExists(path) == false) then
              
        -- Use the fault workspace path
        path = self.workspacePath

    end

    print("Loading Path", path)

    -- Configure window settings
    self.iconPadding = 16
    self.iconWidth = 48
    self.iconHeight = 40
    self.windowBGColor = 11
    self.lastStartID = 0
    self.totalPerWindow = 12
    self.totalPerColumn = 3
    self.totalPerPage = 12
    self.pathHistory = {}
    
    self.totalDisk = tonumber(ReadBiosData("MaxDisks", 2))

    -- TODO this should come from the bios file
    self.validFiles =
    {
    ".png",
    ".json",
    ".txt",
    ".lua",
    ".pv8",
    ".pvr",
    ".wav",
    ".gif"
    }

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

    -- save the current directory
    self.currentPath = path

    -- Draw the window chrome
    DrawSprites(windowchrome.spriteIDs, 8, 16, windowchrome.width, false, false, DrawMode.TilemapCache)

    if(self.vSliderData == nil) then

        -- Create the slider for the window
        self.vSliderData = editorUI:CreateSlider({x = 192, y = 26, w = 16, h = 195}, "vsliderhandle", "This is a vertical slider")
        self.vSliderData.onAction = function(value) 

            -- Set the scroll position
            self.lastStartID = Clamp(self.hiddenRows * value, 0, self.hiddenRows - 1) * self.totalPerColumn

            -- Refresh the window at the end of the frame
            self:RefreshWindow()

        end

    end

    -- Register the slider
    

    -- Create the close button
    -- if(self.closeButton == nil) then
    --     print("Create new window closeButton")
        
    --     self.closeButton = editorUI:CreateButton({x = 192, y = 16}, "closewindow", "Close the window.")
    --     self.closeButton.hitRect = {x = self.closeButton.rect.x + 2, y = self.closeButton.rect.y + 2, w = 10, h = 10}
    --     self.closeButton.onAction = function() self:CloseWindow() end

    -- end

    -- -- Register the close button
    -- self:RegisterUI(self.closeButton, "UpdateButton", editorUI)
    self.desktopIconCount = 2 + self.totalDisk
    
    -- Check to see if we have window buttons
    if(self.windowIconButtons == nil) then

        -- Create a icon button group for all of the files
        self.windowIconButtons = pixelVisionOS:CreateIconGroup(false)

        local startY  = 16
        for i = 1, self.totalDisk + 1 do
            
            pixelVisionOS:NewIconGroupButton(self.windowIconButtons, NewPoint(208, startY), "none", nil, toolTip)
            
            startY = startY + 40
        end

        -- -- Create the placeholder for the trash can
        pixelVisionOS:NewIconGroupButton(self.windowIconButtons, NewPoint(208, 198), "none", nil, toolTip, self.windowBGColor)

        -- Create default buttons
        for i = 1, self.totalPerWindow do

            -- Calculate the correct position
            local pos = CalculatePosition( i-1, self.totalPerColumn )
            pos.x = (pos.x * (self.iconWidth + self.iconPadding)) + 13
            pos.y = (pos.y * (self.iconHeight + self.iconPadding / 2)) + 32
            
            -- Create the new icon button
            pixelVisionOS:NewIconGroupButton(self.windowIconButtons, pos, "none", nil, toolTip, self.windowBGColor)
    
        end

        -- Add the onTrigger callback
        self.windowIconButtons.onTrigger = function(id) self:OnWindowIconClick(id) end

        -- Make sure we disable any selection on the desktop when clicking inside of the window icon group
        self.windowIconButtons.onAction = function(id) self:OnWindowIconSelect(id) end
    
    end

    -- Reset the last start id
    self.lastStartID = 0

    self:UpdateFileList()

    

    -- Update the slider
    editorUI:ChangeSlider(self.vSliderData, scrollTo)
    
    self:ChangeWindowTitle(self.currentPath.Path)

    -- make sure the correct desktop icon is open

    
    
    -- TODO this needs to look through the top buttons

    -- Try to find the icon button if we open a window and its not selected beforehand
    -- if(self.currentOpenIconButton == nil and iconID > 0) then

    --     self.currentOpenIconButton = self.desktopIconButtons.buttons[iconID]

    --     if(self.currentOpenIconButton.open == false) then
    --         print("Open desktop icon", self.currentOpenIconButton.name)

    --         pixelVisionOS:OpenIconButton(self.currentOpenIconButton)
    --     end

    -- end

    -- Registere the window with the tool so it updates
    self:RegisterUI({name = "Window"}, "UpdateWindow", self)


    self:UpdateContextMenu(WindowFocus)

    -- TODO restore any selections

    -- Redraw the window
    self:RefreshWindow()

end

function WorkspaceTool:UpdateFileList()

    -- Get the list of files from the Lua Service
    self.files = self:GetDirectoryContents(self.currentPath)

    -- Save a count of the files after we add the special files to the list
    self.fileCount = #self.files

    -- Update visible and hidden row count
    self.totalRows = math.ceil((self.fileCount- self.desktopIconCount) / self.totalPerColumn) + 1
    self.hiddenRows = self.totalRows - math.ceil(self.totalPerPage / self.totalPerColumn)

    -- Enable the scroll bar if needed
    editorUI:Enable(self.vSliderData, self.fileCount > self.totalPerWindow)

end

function WorkspaceTool:UpdateWindow()

    editorUI:UpdateSlider(self.vSliderData)

    pixelVisionOS:UpdateIconGroup(self.windowIconButtons)

    -- Call draw window after each update
    self:DrawWindow()
    
end

function WorkspaceTool:CurrentlySelectedFiles()

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

function WorkspaceTool:RefreshWindow(updateFileList)

    -- Check to see if we need to refresh the file list
    if(updateFileList == true) then

        -- Update the file list
        self:UpdateFileList()

    end

    -- Invalidate the component so it redraws at the end of the frame
    editorUI:Invalidate(self)

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

end

-- function WorkspaceTool:CloseWindow()

--     -- Clear the previous scroll history
--     self.pathHistory = {}

--     -- self:RemoveUI(self.closeButton.name)
--     -- self.closeButton = nil

--     self:RemoveUI(self.vSliderData.name)
--     -- self.vSliderData = nil

--     self:RemoveUI(self.windowIconButtons.name)
--     self.windowIconButtons = nil

--     self.currentSelectedFile = nil

--     self.currentPath = nil

--     DrawRect(8, 16, windowchrome.width * 8, math.floor(#windowchrome.spriteIDs / windowchrome.width) * 8, BackgroundColor(), DrawMode.TilemapCache)

--     self:DrawWallpaper()

--     pixelVisionOS:ClearIconGroupSelections(self.desktopIconButtons)

--     if(self.currentOpenIconButton ~= nil) then
--         pixelVisionOS:CloseIconButton(self.currentOpenIconButton)
--     end

--     editorUI:ClearFocus()

--     -- Update the drop down menu
--     self:UpdateContextMenu(NoFocus)

--     -- Remvoe the window UI elements
--     self:RemoveUI("Window")

    

-- end

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
    local clearSelections = false
    -- TODO test for shift or ctrl

    -- TODO need to clear all selected files

    local selections = self:CurrentlySelectedFiles()
  
    if(Key(Keys.LeftShift, InputState.Down) or Key( Keys.RightShift, InputState.Down )) then

        -- Find the first selection and select all files all the way down to the current selection

        if(selections ~= nil) then

            -- Create the range between the first selected file and the one that was just selected
            local range = {realFileID, selections[1]}

            -- TODO should we test for the total disks?

            if(selections[1] > self.desktopIconCount) then

                -- Sort the range from lowest to highest
                table.sort(range, function(a,b) return a < b end)

                -- Loop through all of the files and fix the selected states
                for i = 1, self.fileCount do
                    
                    -- Change the value based on if it is within the range
                    self.files[i].selected = i >= range[1] and i <= range[2]

                end

            else

                clearSelections = true

            end

        end

        -- Update the selection
        selections = self:CurrentlySelectedFiles()

    elseif(Key(Keys.LeftControl, InputState.Down) or Key( Keys.RightControl, InputState.Down )) then

        -- change the selection flag to the opposet of the current file's selection value
        selectionFlag = not selectedFile.selected

        print("crt select", selectionFlag)
    
    else

        clearSelections = true

    end
    
    -- Deselect all the files
    if(selections ~= nil and clearSelections == true) then

        for i = 1, #selections do
            self.files[selections[i]].selected = false
        end

    end

    -- Set the selection of the file that was just selected
    selectedFile.selected = selectionFlag

    local lastValue = false

    -- Loop through all of the window buttons
    for i = 1, #self.windowIconButtons.buttons do

        -- Get a reference to the window button
        local tmpButton = self.windowIconButtons.buttons[i]

        if(tmpButton.fileID ~= -1) then

            -- Manually fix the selection of the buttons being displayed
            lastValue = tmpButton.selected

            tmpButton.selected = self.files[tmpButton.fileID].selected

            if(lastValue ~= tmpButton.selected) then
                editorUI:Invalidate(tmpButton)
            end

        end

    end

    -- #4
    self:UpdateContextMenu(WindowIconFocus)

end

function WorkspaceTool:OnWindowIconClick(id)

    

    -- Make sure desktop icons are not selected
    pixelVisionOS:ClearIconGroupSelections(self.desktopIconButtons)

    -- -- local index = id + (lastStartID)-- TODO need to add the scrolling offset

    local tmpItem = self.files[id + self.lastStartID]--CurrentlySelectedFiles()-- files[index]

    local type = tmpItem.type
    local path = tmpItem.path

    print("OnWindowIconClick", id, type, path)


    -- TODO need a list of things we can't delete

    -- Enable delete option

    -- -- print("Window Icon Click", tmpItem.name)
    local type = tmpItem.type

    -- If the type is a folder, open it
    if(type == "folder" or type == "updirectory" or type == "disk" or type == "drive" or type == "trash") then

        
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

function WorkspaceTool:DrawWindow()

    -- Check to see if the window has been invalidated before drawing it
    if(self.invalid ~= true or self.files == nil or self.fileActionActive == true) then
        return
    end

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


    for i = 1, #self.windowIconButtons.buttons do

        -- Calculate the real index
        local fileID = i + self.lastStartID

        -- Get a reference to the button
        local button = self.windowIconButtons.buttons[i]

        local item = nil
        local spriteName = "none"

        -- Determin which index to use for the pathParts
        local pathOffset = pathParts[1] == "Workspace" and 1 or 2

        -- We'll use this name to figure out which desktopp icon to show as open
        local desktopName = pathParts[ pathOffset ]

        -- Make sure the index is less than the maximum icon count
        if(i <= self.desktopIconCount) then
            
            -- Pick the files from the top of the list (desktop icons)
            fileID = i

            -- Check to see if the icon should be set to open if the name matches the desktopName
            pixelVisionOS:OpenIconButton(button, self.files[i].name == desktopName)

        end

        if(fileID <= self.fileCount) then

            item = self.files[fileID]

            -- Find the right type for the file
            self:UpdateFileType(item, isGameDir)

            spriteName = item.sprite ~= nil and item.sprite or self:GetIconSpriteName(item)

            if(spriteName == FileTypeMap["folder"] and systemRoot == true) then

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
        else

        end

        pixelVisionOS:CreateIconButtonStates(button, spriteName, item ~= nil and item.name or "", item ~= nil and item.bgColor or self.windowBGColor)
        
        -- Set the button values
        button.fileID = item ~= nil and fileID or -1
        button.iconName = item ~= nil and item.name or ""
        button.iconType = item ~= nil and item.type or "none"
        button.iconPath = item ~= nil and item.path or ""
        button.selected = item ~= nil and item.selected or false

        -- Reset button value
        button.onOverDropTarget = nil
        button.onDropTarget = nil 
        button.dragDelay = item ~= nil and item.dragDelay or .5

        editorUI:Enable(button, item ~= nil)

        if(item ~= nil) then

            -- Disable the drag on files that don't exist in the directory
            if(item.type == "updirectory" or item.type == "folder" or item.type == "disk" or item.type == "drive" or item.type == "trash") then

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

        end

    end

    -- Reset the component's validation once drwaing is done
    editorUI:ResetValidation(self)

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

    local iconName = FileTypeMap[item.type]
    -- -- print("name", name, iconName)
    return iconName == nil and "fileunknown" or FileTypeMap[item.type]

end



function WorkspaceTool:GetDirectoryContents(workspacePath)

    -- Create empty entities table
    local entities = {}

    -- Create the workspace desktop icon
    table.insert(
            entities,
            {
                name = "Workspace",
                type = "drive",
                path = self.workspacePath,
                isDirectory = true,
                selected = false,
                dragDelay = -1,
                sprite = PathExists(self.workspacePath.AppendDirectory("System")) and "filedriveos" or "filedrive",
                bgColor = BackgroundColor()
            }
        )


    local disks = DiskPaths()

    -- TODO this should loop through the maxium number of disks
    for i = 1, self.totalDisk do

        local noDisk = i > #disks

        local name = noDisk and "none" or disks[i].EntityName
        local path = noDisk and "none" or disks[i]

        table.insert(entities, {
            name = name,
            isDirectory = true,
            sprite = noDisk and "empty" or "diskempty",
            tooltip = "Double click to open the '".. name .. "' disk.",
            tooltipDrag = "You are dragging the '".. name .. "' disk.",
            path = path,
            type = noDisk and "none" or "disk",
            bgColor = BackgroundColor()
        })
    end

    --  

    -- Check to see if there is a trash
    if(PathExists(self.trashPath) == false) then

        -- Create the trash directory
        CreateDirectory(self.trashPath)

    end

    -- TODO need to set the correct icon and background
    -- Creat the trash entity
    table.insert(entities, {
        name = "Trash",
        sprite = #GetEntities(self.trashPath) > 0 and "filetrashfull" or "filetrashempty",
        tooltip = "The trash folder",
        path = self.trashPath,
        type = "trash",
        isDirectory = true,
        bgColor = BackgroundColor(),
        dragDelay = -1,
    })


    -- Get the parent directory
    local parentDirectory = workspacePath.ParentPath

    -- Check to see if this is a root directory
    if(parentDirectory.Path ~= "/Disks/" and parentDirectory.Path ~= "/Tmp/" and parentDirectory.Path ~= "/") then

        -- Add an entity to go up one directory
        table.insert(
            entities,
            {
                name = "..",
                type = "updirectory",
                path = parentDirectory,
                isDirectory = true,
                selected = false,
                bgColor = self.windowBGColor
            }
        )

    end

    -- Check to see if this is a game directory
    if(pixelVisionOS:ValidateGameInDir(workspacePath, {"code.lua"}) and self:TrashOpen() == false) then

        -- Add an entity to run the game
        table.insert(
            entities,
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

    -- Get all of the entities in the directory
    local srcEntities = GetEntities(workspacePath)

    -- Make sure the src entity value is not empty
    if(srcEntities ~= nil) then

        -- Get the total and create a entity placeholder
        local total = #srcEntities
        local tmpEntity = nil

        -- Loop through each entity
        for i = 1, total do

            -- Get the current entity
            tmpEntity = srcEntities[i]

            -- Create the new file
            local tmpFile = {
                fullName = tmpEntity.EntityName,
                isDirectory = tmpEntity.IsDirectory,
                parentPath = tmpEntity.ParentPath,
                path = tmpEntity,
                selected = false,
                ext = "",
                type = "none"
            }

            -- Split the file name by .
            local nameSplit = string.split(tmpFile.fullName, ".")

            -- The file name is the first item in the array
            tmpFile.name = nameSplit[1]

            -- Check to see if this is a directory
            if(tmpFile.isDirectory) then

                tmpFile.type = "folder"

                -- Insert the table
                table.insert(entities, tmpFile)

            else

                -- Get the entity's exenstion
                tmpFile.ext = tmpEntity.GetExtension()

                -- make sure that the extension is valid
                if(table.indexOf(self.validFiles, tmpFile.ext) > - 1) then

                    -- Remove the first item from the name split since it's already used as the name
                    table.remove(nameSplit, 1)

                    -- Join the nameSplit table with . to create the type
                    tmpFile.type = table.concat(nameSplit, ".")

                    -- Add theh entity
                    table.insert(entities, tmpFile)
                end

            end

        end

    end

    return entities

end

function WorkspaceTool:SelectFile(workspacePath)

    -- set the default value to 0 (invald file ID)
    local fileID = 0

    -- Loop through all of the files
    for i = 1, self.fileCount do

        -- Test the file path with the workspace path
        if(self.files[i].path.Path == workspacePath.Path) then

            -- Save the file ID and exit the loop
            fileID = i
            break

        end

    end

    -- Make sure there is a file that can be selected
    if(fileID > 0) then

        self:ClearSelections()

        -- Select the current file
        self.files[fileID].selected = true

        -- Calculate position
        local tmpVPer = CalculatePosition(fileID, self.totalPerColumn).Y / self.totalRows

        -- Update slide position
        editorUI:ChangeSlider(self.vSliderData, tmpVPer)

        -- Tell the window to redraw
        self:RefreshWindow()

    end

end

function WorkspaceTool:ClearSelections()

    -- Get the current selections
    local selections = self:CurrentlySelectedFiles()

    -- Make sure there are selections
    if(selections ~= nil) then

        -- Loop through the selections and disable them
        for i = 1, #selections do
            self.files[selections[i]].selected = false
        end

    end

end