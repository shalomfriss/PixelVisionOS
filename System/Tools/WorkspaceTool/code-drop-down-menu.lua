function WorkspaceTool:CreateDropDownMenu()

    -- Create some enums for the focus types
    self.WindowFocus, self.DesktopIconFocus, self.WindowIconFocus, self.MultipleFiles, self.NoFocus = 1, 2, 3, 4, 5

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

        -- -- New Folder ID 5
        -- {name = "New Folder", action = OnNewFolder, key = Keys.N, enabled = false, toolTip = "Create a new file."},

        -- {divider = true},

        -- -- Edit ID 7
        -- -- {name = "Edit", key = Keys.E, action = OnEdit, enabled = false, toolTip = "Edit the selected file."},
        -- -- Edit ID 8
        -- {name = "Rename", action = OnTriggerRename, enabled = false, toolTip = "Rename the currently selected file."},
        -- -- Copy ID 9
        -- {name = "Copy", key = Keys.C, action = OnCopy, enabled = false, toolTip = "Copy the selected file."},
        -- -- Paste ID 10
        -- {name = "Paste", key = Keys.V, action = OnPaste, enabled = false, toolTip = "Paste the selected file."},
        -- -- Delete ID 11
        -- {name = "Delete", key = Keys.D, action = OnDeleteFile, enabled = false, toolTip = "Delete the current file."},
        -- {divider = true},

        -- -- Empty Trash ID 16
        -- {name = "Empty Trash", action = OnEmptyTrash, enabled = false, toolTip = "Delete everything in the trash."},
        -- -- Eject ID 17
        -- {name = "Eject Disk", action = OnEjectDisk, enabled = false, toolTip = "Eject the currently selected disk."},
        -- -- Shutdown ID 18
        {name = "Shutdown", action = function() self:OnShutdown() end, toolTip = "Shutdown PV8."} -- Quit the current game
    }

    -- local addAt = 6

    -- if(PathExists(fileTemplatePath) == true) then

    --     table.insert(menuOptions, addAt, {name = "New Project", key = Keys.P, action = OnNewGame, enabled = false, toolTip = "Create a new file."})

    --     NewGameShortcut = "New Project"

    --     addAt = addAt + 1

    -- end

    -- newFileOptions = {}

    -- -- TODO this should be done better

    -- if(runnerName == DrawVersion or runnerName == TuneVersion) then

    --     table.insert(menuOptions, addAt, {name = "New Data", action = function() OnNewFile("data", "json", "data", false) end, enabled = false, toolTip = "Run the current game."})
    --     table.insert(newFileOptions, {name = "New Data", file = "data.json"})
    --     addAt = addAt + 1

    --     -- table.insert(menuOptions, addAt, {name = "New Info", action = function() OnNewFile("info", "json", "info", false) end, enabled = false, toolTip = "Run the current game."})
    --     -- table.insert(newFileOptions, {name = "New Info", file = "info.json"})
    --     -- addAt = addAt + 1
    -- end

    -- -- Add text options to the menu
    -- if(runnerName ~= PlayVersion and runnerName ~= DrawVersion and runnerName ~= TuneVersion) then

    --     table.insert(menuOptions, addAt, {name = "New Code", action = function() OnNewFile("code", "lua") end, enabled = false, toolTip = "Run the current game."})
    --     table.insert(newFileOptions, {name = "New Code"})
    --     addAt = addAt + 1

    --     table.insert(menuOptions, addAt, {name = "New JSON", action = function() OnNewFile("untitled", "json") end, enabled = false, toolTip = "Run the current game."})
    --     table.insert(newFileOptions, {name = "New JSON"})
    --     addAt = addAt + 1

    -- end

    -- -- Add draw options

    -- if(PathExists(fileTemplatePath.AppendFile("colors.png"))) then
    --     table.insert(menuOptions, addAt, {name = "New Colors", action = function() OnNewFile("colors", "png", "colors", false) end, enabled = false, toolTip = "Run the current game.", file = "colors.png"})
    --     table.insert(newFileOptions, {name = "New Colors", file = "colors.png"})
    --     addAt = addAt + 1
    -- end

    -- if(PathExists(fileTemplatePath.AppendFile("sprites.png"))) then

    --     table.insert(menuOptions, addAt, {name = "New Sprites", action = function() OnNewFile("sprites", "png", "sprites", false) end, enabled = false, toolTip = "Run the current game.", file = "sprites.png"})
    --     table.insert(newFileOptions, {name = "New Sprites", file = "sprites.png"})
    --     addAt = addAt + 1
    -- end

    -- if(PathExists(fileTemplatePath.AppendFile("large.font.png"))) then

    --     table.insert(menuOptions, addAt, {name = "New Font", action = function() OnNewFile("untitled", "font.png", "font") end, enabled = false, toolTip = "Run the current game."})
    --     table.insert(newFileOptions, {name = "New Font"})
    --     addAt = addAt + 1

    -- end

    -- if(PathExists(fileTemplatePath.AppendFile("tilemap.json"))) then

    --     table.insert(menuOptions, addAt, {name = "New Tilemap", action = function() OnNewFile("tilemap", "json", "tilemap", false) end, enabled = false, toolTip = "Run the current game.", file = "tilemap.json"})
    --     table.insert(newFileOptions, {name = "New Tilemap", file = "tilemap.json"})
    --     addAt = addAt + 1

    -- end

    -- -- Add music options

    -- if(PathExists(fileTemplatePath.AppendFile("sounds.json"))) then

    --     table.insert(menuOptions, addAt, {name = "New Sounds", action = function() OnNewFile("sounds", "json", "sounds", false) end, enabled = false, toolTip = "Run the current game.", file = "sounds.json"})
    --     table.insert(newFileOptions, {name = "New Sounds", file = "sounds.json"})
    --     addAt = addAt + 1
    -- end

    -- if(PathExists(fileTemplatePath.AppendFile("music.json"))) then

    --     table.insert(menuOptions, addAt, {name = "New Music", action = function() OnNewFile("music", "json", "music", false) end, enabled = false, toolTip = "Run the current game.", file = "music.json"})
    --     table.insert(newFileOptions, {name = "New Music", file = "music.json"})
    --     addAt = addAt + 1

    -- end

    -- if(runnerName ~= DrawVersion and runnerName ~= TuneVersion) then

    --     -- TODO need to add to the offset
    --     addAt = addAt + 6
    --     -- Empty Trash ID 13
    --     table.insert(menuOptions, addAt, {name = "Run", key = Keys.R, action = OnRun, enabled = false, toolTip = "Run the current game."})
    --     addAt = addAt + 1

    --     table.insert(menuOptions, addAt, {name = "Build", action = OnExportGame, enabled = false, toolTip = "Create a PV8 file from the current game."})
    --     addAt = addAt + 1

    --     table.insert(menuOptions, addAt, {divider = true})
    --     addAt = addAt + 1

    --     RunShortcut, BuildShortcut = "Run", "Build"

    -- end

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

end


function WorkspaceTool:UpdateContextMenu(inFocus)

    -- if(inFocus == WindowFocus) then

    --     local canRun = pixelVisionOS:ValidateGameInDir(currentDirectory, {"code.lua"}) and not TrashOpen()

    --     if(runnerName == DrawVersion or runnerName == TuneVersion) then
    --         canRun = false
    --     end

    --     -- New File options
    --     if(runnerName ~= PlayVersion) then
    --         pixelVisionOS:EnableMenuItemByName(NewGameShortcut, not canRun and not TrashOpen())
    --     end

    --     pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, not TrashOpen())
    --     -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, not TrashOpen())
    --     for i = 1, #newFileOptions do

    --         local option = newFileOptions[i]
    --         local enable = not TrashOpen()

    --         if(enable == true) then

    --             if(option.file ~= nil) then

    --                 enable = not PathExists(currentDirectory.AppendFile(option.file))

    --             end

    --         end

    --         pixelVisionOS:EnableMenuItemByName(option.name, enable)

    --     end

    --     -- File options
    --     pixelVisionOS:EnableMenuItemByName(EditShortcut, false)

    --     if(RunShortcut ~= nil) then
    --         pixelVisionOS:EnableMenuItemByName(RunShortcut, canRun)
    --     end

    --     pixelVisionOS:EnableMenuItemByName(RenameShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(CopyShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(DeleteShortcut, false)

    --     if(BuildShortcut ~= nil) then
    --         pixelVisionOS:EnableMenuItemByName(BuildShortcut, canRun and string.starts(currentDirectory.Path, "/Disks/") == false)
    --     end

    --     pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, CanEject())

    --     -- Special cases

    --     -- Only active paste if there is something to paste
    --     pixelVisionOS:EnableMenuItemByName(PasteShortcut, filesToCopy ~= nil and #filesToCopy > 0)

    -- elseif(inFocus == DesktopIconFocus) then

    --     -- New File options
    --     if(runnerName ~= PlayVersion) then
    --         pixelVisionOS:EnableMenuItemByName(NewGameShortcut, false)
    --     end

    --     pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, false)
    --     -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, false)
    --     for i = 1, #newFileOptions do
    --         pixelVisionOS:EnableMenuItemByName(newFileOptions[i].name, false)
    --     end

    --     -- File options
    --     -- pixelVisionOS:EnableMenuItemByName(EditShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(EditShortcut, false)

    --     if(RunShortcut ~= nil) then
    --         pixelVisionOS:EnableMenuItemByName(RunShortcut, false)
    --     end

    --     pixelVisionOS:EnableMenuItemByName(RenameShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(CopyShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(PasteShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(DeleteShortcut, false)
    --     if(BuildShortcut ~= nil) then
    --         pixelVisionOS:EnableMenuItemByName(BuildShortcut, false)
    --     end
    --     -- Disk options
    --     pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, CanEject())


    -- elseif(inFocus == WindowIconFocus) then

    --     local currentSelection = CurrentlySelectedFile()

    --     local specialFile = currentSelection.name == ".." or currentSelection.name == "Run"

    --     -- Check to see if currentDirectory is a game
    --     local canRun = pixelVisionOS:ValidateGameInDir(currentDirectory, {"code.lua"}) and not TrashOpen()

    --     if(runnerName == DrawVersion or runnerName == TuneVersion) then
    --         canRun = false
    --     end
    --     if(BuildShortcut ~= nil) then
    --         pixelVisionOS:EnableMenuItemByName(BuildShortcut, canRun and string.starts(currentDirectory.Path, "/Disks/") == false)
    --     end

    --     -- New File options
    --     if(runnerName ~= PlayVersion) then
    --         pixelVisionOS:EnableMenuItemByName(NewGameShortcut, not canRun and not TrashOpen())
    --     end

    --     pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, not TrashOpen())

    --     for i = 1, #newFileOptions do


    --         local option = newFileOptions[i]
    --         local enable = not TrashOpen()

    --         if(enable == true) then

    --             if(option.file ~= nil) then

    --                 enable = not PathExists(currentDirectory.AppendFile(option.file))

    --             end

    --         end

    --         pixelVisionOS:EnableMenuItemByName(option.name, enable)

    --     end

    --     pixelVisionOS:EnableMenuItemByName(EditShortcut, not TrashOpen() and not specialFile)

    --     -- TODO Can't rename up directory?
    --     pixelVisionOS:EnableMenuItemByName(RenameShortcut, not TrashOpen() and not specialFile)

    --     if(RunShortcut ~= nil) then
    --         pixelVisionOS:EnableMenuItemByName(RunShortcut, canRun)
    --     end

    --     pixelVisionOS:EnableMenuItemByName(CopyShortcut, not TrashOpen() and not specialFile)

    --     -- TODO need to makes sure the file can be deleted
    --     pixelVisionOS:EnableMenuItemByName(DeleteShortcut, not TrashOpen() and not specialFile)

    --     -- Disk options
    --     pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, false)

    -- else

    --     -- New File options
    --     if(runnerName ~= PlayVersion) then
    --         pixelVisionOS:EnableMenuItemByName(NewGameShortcut, false)
    --     end

    --     pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, false)
    --     -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, false)

    --     for i = 1, #newFileOptions do
    --         pixelVisionOS:EnableMenuItemByName(newFileOptions[i].name, false)
    --     end

    --     -- File options
    --     -- pixelVisionOS:EnableMenuItemByName(EditShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(EditShortcut, false)

    --     if(RunShortcut ~= nil) then
    --         pixelVisionOS:EnableMenuItemByName(RunShortcut, false)
    --     end

    --     pixelVisionOS:EnableMenuItemByName(RenameShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(CopyShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(PasteShortcut, false)
    --     pixelVisionOS:EnableMenuItemByName(DeleteShortcut, false)

    --     if(BuildShortcut ~= nil) then
    --         pixelVisionOS:EnableMenuItemByName(BuildShortcut, false)
    --     end
    --     -- Disk options
    --     pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, false)

    -- end

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