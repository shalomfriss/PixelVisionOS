-- Global sortcut enums
NewFolderShortcut, EditShortcut, RenameShortcut, CopyShortcut, PasteShortcut, DeleteShortcut, EmptyTrashShortcut, EjectDiskShortcut, NewGameShortcut, RunShortcut, BuildShortcut = "New Folder", "Edit", "Rename", "Copy", "Paste", "Delete", "Empty Trash", "Eject Disk", nil, nil, nil 

-- Global focus enums
WindowFocus, DesktopIconFocus, WindowIconFocus, MultipleFiles, NoFocus = 1, 2, 3, 4, 5

function WorkspaceTool:CreateDropDownMenu()

    local tmpProjectPath = ReadBiosData("ProjectTemplate")
    self.fileTemplatePath = tmpProjectPath == nil and NewWorkspacePath(self.rootPath .. self.gameName .. "/ProjectTemplate/") or NewWorkspacePath(tmpProjectPath)

    -- Create some enums for the focus typess
    
    -- TODO need to see if the log file actually exists
    local logExits = PathExists(NewWorkspacePath("/Tmp/Log.txt"))--true

    local aboutText = "The ".. self.toolName.. " offers you access to the underlying file system. "

        if(TmpPath() ~= nil) then
            aboutText = aboutText .. "\n\nTemporary files are stores on your computer at: \n\n" .. TmpPath()
        end

        if(DocumentPath() ~= nil) then

            aboutText = aboutText .. "\n\nYou can access the 'Workspace' drive on your computer at: \n\n" .. DocumentPath()

        end

    local menuOptions = 
    {
        -- About ID 1
        {name = "About", action = function() pixelVisionOS:ShowAboutModal(self.toolName, aboutText, 220) end, toolTip = "Learn about PV8."},
        -- Settings ID 2
        {name = "Settings", action = function() self:OnLaunchSettings() end, toolTip = "Configure Pixel Vision OS's Settings."},
        -- Settings ID 3
        {name = "View Log", enabled = logExits, action = function() self:OnLaunchLog() end, toolTip = "Open up the log file."},
        
        {divider = true},

        -- New Folder ID 5
        {name = "New Folder", action = function() self:OnNewFolder() end, key = Keys.N, enabled = false, toolTip = "Create a new file."},

        {divider = true},

        -- Edit ID 7
        -- {name = "Edit", key = Keys.E, action = OnEdit, enabled = false, toolTip = "Edit the selected file."},
        -- Edit ID 8
        {name = "Rename", action = function() self:OnTriggerRename() end, enabled = false, toolTip = "Rename the currently selected file."},
        -- Copy ID 9
        {name = "Copy", key = Keys.C, action = function() self:OnCopy() end, enabled = false, toolTip = "Copy the selected file."},
        -- Paste ID 10
        {name = "Paste", key = Keys.V, action = function() self:OnPaste() end, enabled = false, toolTip = "Paste the selected file."},
        -- Delete ID 11
        {name = "Delete", key = Keys.D, action = function() self:OnDeleteFile() end, enabled = false, toolTip = "Delete the current file."},
        {divider = true},

        -- Empty Trash ID 16
        {name = "Empty Trash", action = function() self:OnEmptyTrash() end, enabled = false, toolTip = "Delete everything in the trash."},
        -- Eject ID 17
        {name = "Eject Disk", action = function() self:OnEjectDisk() end, enabled = false, toolTip = "Eject the currently selected disk."},
        -- Shutdown ID 18
        {name = "Shutdown", action = function() self:OnShutdown() end, toolTip = "Shutdown PV8."} -- Quit the current game
    }

    local addAt = 6

    if(PathExists(self.fileTemplatePath) == true) then

        table.insert(menuOptions, addAt, {name = "New Project", key = Keys.P, action = function() self:OnNewGame() end, enabled = false, toolTip = "Create a new file."})

        NewGameShortcut = "New Project"

        addAt = addAt + 1

    end

    self.newFileOptions = {}

    -- TODO this should be done better

    -- if(runnerName == DrawVersion or runnerName == TuneVersion) then

        table.insert(menuOptions, addAt, {name = "New Data", action = function() self:OnNewFile("data", "json", "data", false) end, enabled = false, toolTip = "Run the current game."})
        table.insert(self.newFileOptions, {name = "New Data", file = "data.json"})
        addAt = addAt + 1

    -- end

    -- Add text options to the menu
    -- if(runnerName ~= PlayVersion and runnerName ~= DrawVersion and runnerName ~= TuneVersion) then

        table.insert(menuOptions, addAt, {name = "New Code", action = function() self:OnNewFile("code", "lua") end, enabled = false, toolTip = "Run the current game."})
        table.insert(self.newFileOptions, {name = "New Code"})
        addAt = addAt + 1

        table.insert(menuOptions, addAt, {name = "New JSON", action = function() self:OnNewFile("untitled", "json") end, enabled = false, toolTip = "Run the current game."})
        table.insert(self.newFileOptions, {name = "New JSON"})
        addAt = addAt + 1

    -- end

    -- Add draw options

    if(PathExists(self.fileTemplatePath.AppendFile("colors.png"))) then
        table.insert(menuOptions, addAt, {name = "New Colors", action = function() self:OnNewFile("colors", "png", "colors", false) end, enabled = false, toolTip = "Run the current game.", file = "colors.png"})
        table.insert(self.newFileOptions, {name = "New Colors", file = "colors.png"})
        addAt = addAt + 1
    end

    if(PathExists(self.fileTemplatePath.AppendFile("sprites.png"))) then

        table.insert(menuOptions, addAt, {name = "New Sprites", action = function() self:OnNewFile("sprites", "png", "sprites", false) end, enabled = false, toolTip = "Run the current game.", file = "sprites.png"})
        table.insert(self.newFileOptions, {name = "New Sprites", file = "sprites.png"})
        addAt = addAt + 1
    end

    if(PathExists(self.fileTemplatePath.AppendFile("large.font.png"))) then

        table.insert(menuOptions, addAt, {name = "New Font", action = function() self:OnNewFile("untitled", "font.png", "font") end, enabled = false, toolTip = "Run the current game."})
        table.insert(self.newFileOptions, {name = "New Font"})
        addAt = addAt + 1

    end

    if(PathExists(self.fileTemplatePath.AppendFile("tilemap.json"))) then

        table.insert(menuOptions, addAt, {name = "New Tilemap", action = function() self:OnNewFile("tilemap", "json", "tilemap", false) end, enabled = false, toolTip = "Run the current game.", file = "tilemap.json"})
        table.insert(self.newFileOptions, {name = "New Tilemap", file = "tilemap.json"})
        addAt = addAt + 1

    end

    -- Add music options

    if(PathExists(self.fileTemplatePath.AppendFile("sounds.json"))) then

        table.insert(menuOptions, addAt, {name = "New Sounds", action = function() self:OnNewFile("sounds", "json", "sounds", false) end, enabled = false, toolTip = "Run the current game.", file = "sounds.json"})
        table.insert(self.newFileOptions, {name = "New Sounds", file = "sounds.json"})
        addAt = addAt + 1
    end

    if(PathExists(self.fileTemplatePath.AppendFile("music.json"))) then

        table.insert(menuOptions, addAt, {name = "New Music", action = function() self:OnNewFile("music", "json", "music", false) end, enabled = false, toolTip = "Run the current game.", file = "music.json"})
        table.insert(self.newFileOptions, {name = "New Music", file = "music.json"})
        addAt = addAt + 1

    end

    -- if(runnerName ~= DrawVersion and runnerName ~= TuneVersion) then

        -- TODO need to add to the offset
        addAt = addAt + 6
        -- Empty Trash ID 13
        table.insert(menuOptions, addAt, {name = "Run", key = Keys.R, action = function() self:OnRun() end, enabled = false, toolTip = "Run the current game."})
        addAt = addAt + 1

        table.insert(menuOptions, addAt, {name = "Build", action = function() self:OnExportGame() end, enabled = false, toolTip = "Create a PV8 file from the current game."})
        addAt = addAt + 1

        table.insert(menuOptions, addAt, {divider = true})
        addAt = addAt + 1

        RunShortcut = "Run"
        BuildShortcut = "Build"

    -- end

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

end


function WorkspaceTool:UpdateContextMenu(inFocus)

    -- Set a flag to enable any item that is dependant on the trash being closed
    local enable = not self:TrashOpen()

    if(inFocus == WindowFocus) then

        local canRun = pixelVisionOS:ValidateGameInDir(self.currentPath, {"code.lua"}) and enable

        if(self.runnerName == DrawVersion or self.runnerName == TuneVersion) then
            canRun = false
        end

        -- New File options
        -- if(runnerName ~= PlayVersion) then
            pixelVisionOS:EnableMenuItemByName(NewGameShortcut, not canRun and enable)
        -- end

        pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, enable)
        -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, not TrashOpen())
        
        self:ToggleOptions(enable)

        -- File options
        pixelVisionOS:EnableMenuItemByName(EditShortcut, false)

        if(RunShortcut ~= nil) then
            pixelVisionOS:EnableMenuItemByName(RunShortcut, canRun)
        end

        pixelVisionOS:EnableMenuItemByName(RenameShortcut, false)
        pixelVisionOS:EnableMenuItemByName(CopyShortcut, false)
        pixelVisionOS:EnableMenuItemByName(DeleteShortcut, false)

        if(BuildShortcut ~= nil) then
            pixelVisionOS:EnableMenuItemByName(BuildShortcut, canRun and string.starts(self.currentPath.Path, "/Disks/") == false)
        end

        pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, self:CanEject())

        -- Special cases

        -- Only active paste if there is something to paste
        pixelVisionOS:EnableMenuItemByName(PasteShortcut, self.filesToCopy ~= nil and #self.filesToCopy > 0)

        -- Clear the desktop selction
        self:ClearDesktopSelection()
        
    elseif(inFocus == WindowIconFocus) then

        local selections = self:CurrentlySelectedFiles()

        -- Check to see if the selction is empty
        if(selections == nil) then

            -- Change the focus to the window
            self:UpdateContextMenu(WindowFocus)

        -- Check  to see if there are multiple files
        elseif(#selections > 1) then

            -- Chnage the context menu to multiple files
            self:UpdateContextMenu(MultipleFiles)

        end

        -- Get the first file which is the current selection
        local currentSelection = self.files[selections[1]]

        -- Look to see if the selection is a special file (parent dir or run)
        local specialFile = currentSelection.name == ".." or currentSelection.name == "Run"

        -- Check to see if currentPath is a game
        local canRun = pixelVisionOS:ValidateGameInDir(self.currentPath, {"code.lua"}) and selections

        -- if(runnerName == DrawVersion or runnerName == TuneVersion) then
        --     canRun = false
        -- end

        -- Check to see if the build option is available
        if(BuildShortcut ~= nil) then
            pixelVisionOS:EnableMenuItemByName(BuildShortcut, canRun and string.starts(self.currentPath.Path, "/Disks/") == false)
        end

        -- Check to see if the new project file is available
        -- if(runnerName ~= PlayVersion) then
            pixelVisionOS:EnableMenuItemByName(NewGameShortcut, not canRun and enable)
        -- end

        -- Enable the new folder option if this file is not in the trash
        pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, enable)

        self:ToggleOptions(enable)


        pixelVisionOS:EnableMenuItemByName(EditShortcut, enable and not specialFile)

        -- TODO Can't rename up directory?
        pixelVisionOS:EnableMenuItemByName(RenameShortcut, enable and not specialFile)

        if(RunShortcut ~= nil) then
            pixelVisionOS:EnableMenuItemByName(RunShortcut, canRun)
        end

        pixelVisionOS:EnableMenuItemByName(CopyShortcut, enable and not specialFile)

        -- TODO need to makes sure the file can be deleted
        pixelVisionOS:EnableMenuItemByName(DeleteShortcut, enable and not specialFile)

        -- Disk options
        pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, false)

        -- Clear the desktop selction
        self:ClearDesktopSelection()
        
    elseif(inFocus == DesktopIconFocus) then

        -- New File options
        -- if(runnerName ~= PlayVersion) then
            pixelVisionOS:EnableMenuItemByName(NewGameShortcut, false)
        -- end

        pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, false)
        -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, false)
        -- for i = 1, #self.newFileOptions do
        --     pixelVisionOS:EnableMenuItemByName(self.newFileOptions[i].name, false)
        -- end

        self:ToggleOptions(false)

        -- File options
        -- pixelVisionOS:EnableMenuItemByName(EditShortcut, false)
        pixelVisionOS:EnableMenuItemByName(EditShortcut, false)

        if(RunShortcut ~= nil) then
            pixelVisionOS:EnableMenuItemByName(RunShortcut, false)
        end

        pixelVisionOS:EnableMenuItemByName(RenameShortcut, false)
        pixelVisionOS:EnableMenuItemByName(CopyShortcut, false)
        pixelVisionOS:EnableMenuItemByName(PasteShortcut, false)
        pixelVisionOS:EnableMenuItemByName(DeleteShortcut, false)
        if(BuildShortcut ~= nil) then
            pixelVisionOS:EnableMenuItemByName(BuildShortcut, false)
        end
        -- Disk options
        pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, self:CanEject())

    
    else

        -- New File options
        if(runnerName ~= PlayVersion) then
            pixelVisionOS:EnableMenuItemByName(NewGameShortcut, false)
        end

        pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, false)
        -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, false)

        -- for i = 1, #self.newFileOptions do
        --     pixelVisionOS:EnableMenuItemByName(self.newFileOptions[i].name, false)
        -- end

        self:ToggleOptions(false)

        -- File options
        -- pixelVisionOS:EnableMenuItemByName(EditShortcut, false)
        pixelVisionOS:EnableMenuItemByName(EditShortcut, false)

        if(RunShortcut ~= nil) then
            pixelVisionOS:EnableMenuItemByName(RunShortcut, false)
        end

        pixelVisionOS:EnableMenuItemByName(RenameShortcut, false)
        pixelVisionOS:EnableMenuItemByName(CopyShortcut, false)
        pixelVisionOS:EnableMenuItemByName(PasteShortcut, false)
        pixelVisionOS:EnableMenuItemByName(DeleteShortcut, false)

        if(BuildShortcut ~= nil) then
            pixelVisionOS:EnableMenuItemByName(BuildShortcut, false)
        end
        -- Disk options
        pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, false)

    end

end

function WorkspaceTool:ToggleOptions(enabled)

    -- Loop through all the file creation options
    for i = 1, #self.newFileOptions do

        -- Get the new file option data
        local option = self.newFileOptions[i]

        -- Check to see if the option should be enabled
        if(enable == true and option.file ~= nil) then

            -- Change the enable flag based on if the file exists
            enable = not PathExists(self.currentPath.AppendFile(option.file))

        end

        -- Enable the file in the menu
        pixelVisionOS:EnableMenuItemByName(option.name, enable)

    end

end


function WorkspaceTool:OnMenuQuit()

    QuitCurrentTool()

end

function WorkspaceTool:OnLaunchSettings()

    local editorPath = ReadBiosData("SettingsEditor")

    if(editorPath == nil) then
        editorPath = self.rootPath .."SettingsTool/"
    end

    LoadGame(editorPath)

end

function WorkspaceTool:OnLaunchLog()

    -- Get a list of all the editors
    local editorMapping = pixelVisionOS:FindEditors()

    -- Find the json editor
    textEditorPath = editorMapping["txt"]

    local metaData = {
        directory = "/Tmp/",
        file = "/Tmp/Log.txt"
    }

    LoadGame(textEditorPath, metaData)

end

function WorkspaceTool:OnShutdown()

    self:CancelFileActions()

    local runnerName = SystemName()

    local this = self

    pixelVisionOS:ShowMessageModal("Shutdown " .. runnerName, "Are you sure you want to shutdown "..runnerName.."?", 160, true,
        function()
            if(pixelVisionOS.messageModal.selectionValue == true) then

                ShutdownSystem()

                -- Save changes
                this.shuttingDown = true

            end

        end
    )

end