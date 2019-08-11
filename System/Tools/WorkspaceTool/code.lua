--[[
	Pixel Vision 8 - New Template Script
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	This project was designed to display some basic instructions when you create
	a new tool.	Simply delete the following code and implement your own Init(),
	Update() and Draw() logic.

	Learn more about making Pixel Vision 8 games at https://www.gitbook.com/@pixelvision8
]]--

-- Load in the editor framework script to access tool components
LoadScript("sb-sprites")
LoadScript("pixel-vision-os-v2")
LoadScript("code-icon-button")
LoadScript("code-new-file-modal")
LoadScript("code-workspace-utils")


local toolName = "Workspace Explorer"

local pixelVisionOS = nil
local editorUI = nil

local lastStartID = nil

local PlayVersion, DrawVersion, TuneVersion, MakeVersion = "Pixel Vision 8 Play", "Pixel Vision 8 Draw", "Pixel Vision 8 Tune", "Pixel Vision 8 Make"
local runnerName = SystemName()

local totalPerWindow = 12
local currentDirectory = "none"
local shuttingDown = false
local files = nil
local windowIconButtons = nil
local trashPath = "/Tmp/Trash/"
local workspacePath = "/Workspace/"
local refreshTime = 0
local refreshDelay = 5
local fileCount = 0

local fileTypeMap = 
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

local extToTypeMap = 
{
  colors = "png",
  system = "json",
  font = "font.png",
  music = "json",
  sounds = "json",
  sprites = "png",
  tilemap = "json",
  installer = "txt",
  info = "json",
  wav = "wav"
}

local rootPath = ReadMetaData("RootPath", "/")
local gameName = ReadMetaData("GameName", "FilePickerTool")

local windowScrollHistory = {}

local newFileModal = nil

local fileTemplatePath = NewWorkspacePath(rootPath .. gameName .. "/FileTemplates/")

-- This this is an empty game, we will the following text. We combined two sets of fonts into
-- the default.font.png. Use uppercase for larger characters and lowercase for a smaller one.
local title = "EMPTY TOOL"
local messageTxt = "This is an empty tool template. Press Ctrl + 1 to open the editor or modify the files found in your workspace game folder."

-- Container for horizontal slider data

local desktopIcons = nil
local vSliderData = nil

local currentSelectedFile = nil

-- Flags for managing focus
local WindowFocus, DesktopIconFocus, WindowIconFocus, NoFocus = 1, 2, 3, 4

local desktopIcons = {}

NewFolderShortcut, EditShortcut, RenameShortcut, CopyShortcut, PasteShortcut, DeleteShortcut, RunShortcut, BuildShortcut, EmptyTrashShortcut, EjectDiskShortcut = "New Folder", "Edit", "Rename", "Copy", "Paste", "Delete", "Run", "Build", "Empty Trash", "Eject Disk"

-- Get all of the available editors
local editorMapping = {}

-- The Init() method is part of the game's lifecycle and called a game starts. We are going to
-- use this method to configure background color, ScreenBufferChip and draw a text box.
function Init()

  runningFromDisk = string.starts(rootPath, "/Disks/")

  DrawWallpaper()

  -- Disable the back key in this tool
  EnableBackKey(false)
  EnableAutoRun(false)


  -- Create an instance of the Pixel Vision OS
  pixelVisionOS = PixelVisionOS:Init()

  -- Get a reference to the Editor UI
  editorUI = pixelVisionOS.editorUI

  newFileModal = NewFileModal:Init(editorUI)
  newFileModal.editorUI = editorUI

  -- Find all the editors
  editorMapping = pixelVisionOS:FindEditors()


  local aboutText = "The ".. toolName.. " offers you access to the underlying file system. "

  if(TmpPath() ~= nil) then
    aboutText = aboutText .. "\n\nTemporary files are stores on your computer at: \n\n" .. TmpPath()
  end

  if(DocumentPath() ~= nil) then

    aboutText = aboutText .. "\n\nYou can access the 'Workspace' drive on your computer at: \n\n" .. DocumentPath()

  end

  -- TODO need to see if the log file actually exists
  local logExits = true

  local menuOptions = 
  {
    -- About ID 1
    {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName, aboutText, 220) end, toolTip = "Learn about PV8."},
    -- Settings ID 2
    {name = "Settings", action = OnLaunchSettings, toolTip = "Learn about PV8."},
    -- Settings ID 3
    {name = "View Log", enabled = logExits, action = OnLaunchLog, toolTip = "Open up the log file."},
    {divider = true},

    -- New Folder ID 5
    {name = "New Folder", action = OnNewFolder, enabled = false, toolTip = "Create a new file."},

    {divider = true},

    -- Edit ID 7
    {name = "Edit", key = Keys.E, action = OnEdit, enabled = false, toolTip = "Edit the selected file."},
    -- Edit ID 8
    {name = "Rename", action = OnTriggerRename, enabled = false, toolTip = "Rename the currently selected file."},
    -- Copy ID 9
    {name = "Copy", key = Keys.C, action = OnCopy, enabled = false, toolTip = "Copy the selected file."},
    -- Paste ID 10
    {name = "Paste", key = Keys.V, action = OnPaste, enabled = false, toolTip = "Paste the selected file."},
    -- Delete ID 11
    {name = "Delete", key = Keys.D, action = OnDeleteFile, enabled = false, toolTip = "Delete the current file."},
    {divider = true},
    -- Empty Trash ID 13
    {name = "Run", key = Keys.R, action = OnRun, enabled = false, toolTip = "Run the current game."},
    -- Empty Trash ID 14
    {name = "Build", action = OnExportGame, enabled = false, toolTip = "Create a PV8 file from the current game."},
    {divider = true},
    -- Empty Trash ID 16
    {name = "Empty Trash", action = OnEmptyTrash, enabled = false, toolTip = "Delete everything in the trash."},
    -- Eject ID 17
    {name = "Eject Disk", action = OnEjectDisk, enabled = false, toolTip = "Eject the currently selected disk."},
    -- Shutdown ID 18
    {name = "Shutdown", action = OnShutdown, toolTip = "Shutdown PV8."} -- Quit the current game
  }

  -- local menuOffset = -2
  local addAt = 6

  if(runnerName ~= PlayVersion) then

    table.insert(menuOptions, addAt, {name = "New Project", action = OnNewGame, enabled = false, toolTip = "Create a new file."})
    -- menuOffset = menuOffset + 1
    -- NewCodeShortcut = addAt

    NewGameShortcut = "New Project"

    -- table.insert(newFileOptions, addAt)
    addAt = addAt + 1

  end

  newFileOptions = {}

  -- Add text options to the menu
  if(runnerName ~= PlayVersion and runnerName ~= DrawVersion and runnerName ~= TuneVersion) then

    table.insert(menuOptions, addAt, {name = "New Code", action = function() OnNewFile("code", "lua") end, enabled = false, toolTip = "Run the current game."})
    -- menuOffset = menuOffset + 1
    -- NewCodeShortcut = addAt
    table.insert(newFileOptions, {name = "New Code"})
    addAt = addAt + 1

    table.insert(menuOptions, addAt, {name = "New JSON", action = function() OnNewFile("untitled", "json") end, enabled = false, toolTip = "Run the current game."})
    -- menuOffset = menuOffset + 1
    -- NewJSONShortcut = addAt
    table.insert(newFileOptions, {name = "New JSON"})
    addAt = addAt + 1

  end

  -- Add draw options
  if(runnerName ~= PlayVersion and runnerName ~= TuneVersion) then

    table.insert(menuOptions, addAt, {name = "New Colors", action = function() OnNewFile("colors", "png", "colors", false) end, enabled = false, toolTip = "Run the current game.", file = "colors.png"})
    -- menuOffset = menuOffset + 1
    -- NewColorsShortcut = addAt
    table.insert(newFileOptions, {name = "New Colors", file = "colors.png"})
    addAt = addAt + 1

    table.insert(menuOptions, addAt, {name = "New Sprites", action = function() OnNewFile("sprites", "png", "sprites", false) end, enabled = false, toolTip = "Run the current game.", file = "sprites.png"})
    -- menuOffset = menuOffset + 1
    -- NewSpritesShortcut = addAt
    table.insert(newFileOptions, {name = "New Sprites", file = "sprites.png"})
    addAt = addAt + 1

    table.insert(menuOptions, addAt, {name = "New Font", action = function() OnNewFile("untitled", "font.png", "font") end, enabled = false, toolTip = "Run the current game."})
    -- menuOffset = menuOffset + 1
    -- NewFontShortcut = addAt
    table.insert(newFileOptions, {name = "New Font"})
    addAt = addAt + 1

    table.insert(menuOptions, addAt, {name = "New Tilemap", action = function() OnNewFile("tilemap", "json", "tilemap", false) end, enabled = false, toolTip = "Run the current game.", file = "tilemap.json"})
    -- menuOffset = menuOffset + 1
    -- NewTilemapShortcut = addAt
    table.insert(newFileOptions, {name = "New Tilemap", file = "tilemap.json"})
    addAt = addAt + 1

  end

  -- Add music options
  if(runnerName ~= PlayVersion and runnerName ~= DrawVersion) then

    table.insert(menuOptions, addAt, {name = "New Sounds", action = function() OnNewFile("sounds", "json", "sounds", false) end, enabled = false, toolTip = "Run the current game.", file = "sounds.json"})
    -- menuOffset = menuOffset + 1
    -- NewSoundsShortcut = addAt
    table.insert(newFileOptions, {name = "New Sounds", file = "sounds.json"})
    addAt = addAt + 1

    table.insert(menuOptions, addAt, {name = "New Music", action = function() OnNewFile("music", "json", "music", false) end, enabled = false, toolTip = "Run the current game.", file = "music.json"})
    -- menuOffset = menuOffset + 1
    -- NewMusicShortcut = addAt
    table.insert(newFileOptions, {name = "New Music", file = "music.json"})
    addAt = addAt + 1

  end

  pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

  -- Change the title
  pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

  RebuildDesktopIcons()

  local newPath = ReadSaveData("lastPath", "none")

  -- print("lastPath meta data", newPath, ReadMetaData("lastPath", "none") )
  --
  -- -- Override from metadata
  -- local overWritePath = ReadMetaData("lastPath", newPath)
  --
  -- if(overWritePath ~= "none") then
  --
  --   -- Clear the last path from history
  --   WriteMetaData("lastPath", "none")
  --
  --   print("Clear last path meta data", ReadMetaData("lastPath"))
  --
  --   newPath = overWritePath
  -- end

  if(SessionID() == ReadSaveData("sessionID", "") and newPath ~= "none" and PathExists(NewWorkspacePath(newPath))) then

    OpenWindow(newPath, tonumber(ReadSaveData("scrollPos", "0")), tonumber(ReadSaveData("selection", "0")))

  end

end

local wallPaperThemes = {
  {0, 5},
  {5, 5}
}


function DrawWallpaper()

  -- Set up logo values
  local logoSpriteData = _G["logo"]

  -- themeID = 1
  --
  -- -- Set logo
  -- if(not runningFromDisk) then
  --   --   logoSpriteData = _G["logomake"]
  --   -- colorOffset = 0
  --   -- backgroundColor = 5
  --   -- elseif(runnerName == DrawVersion) then
  --   --   logoSpriteData = _G["logodraw"]
  --   themeID = 2
  --   -- elseif(runnerName == TuneVersion) then
  --   --   logoSpriteData = _G["logotune"]
  --   --   -- colorOffset = 0
  --   --   backgroundColor = 8
  -- end

  local theme = wallPaperThemes[runningFromDisk == true and 2 or 1]

  -- Update background
  BackgroundColor(theme[2])

  -- Draw logo
  if(logoSpriteData ~= nil) then
    UpdateTiles(13, 13, logoSpriteData.width, logoSpriteData.spriteIDs, theme[1])
  end

end



function OnNewFile(fileName, ext, type, editable)

  if(type == nil) then
    type = ext
  end

  -- if(PathExists(fileTemplatePath)) then

  -- if(fileTemplatePath.AppendFile(fileName .. "." .. ext)) then
  -- print("Found file templates", fileName, ext)

  newFileModal:SetText("New ".. type, fileName, "Name " .. type .. " file", editable == nil and true or false)

  pixelVisionOS:OpenModal(newFileModal,
    function()

      if(newFileModal.selectionValue == false) then
        return
      end

      local filePath = UniqueFilePath(NewWorkspacePath(currentDirectory .. newFileModal.inputField.text .. "." .. ext))

      local tmpPath = fileTemplatePath.AppendFile(filePath.EntityName)

      -- Check for lua files first since we always want to make them empty
      if(ext == "lua") then
        SaveText(filePath, "-- Empty code file")

        -- Check for any files in the template folder we can copy over
      elseif(PathExists(tmpPath)) then

        CopyTo(tmpPath, filePath)
        -- print("Copy from template", tmpPath.Path)

        -- Create an empty text file
      elseif( ext == "txt") then
        SaveText(filePath, "")

        -- Create an empty json file
      elseif(ext == "json") then
        SaveText(filePath, "{}")
      else
        -- TODO need to display an error message that the file couldn't be created
        return
      end

      -- NewFile(filePath)
      RefreshWindow()

    end
  )
  -- end

  -- else
  --   print("No template path", fileTemplatePath.Path)
  -- end

  --
  -- if(newFileModal == nil) then
  --
  -- end




end

function OnTriggerRename(callback)

  -- TODO need to get the currently selected file
  -- print("Rename file")

  -- if(renameModal == nil) then
  --   renameModal = RenameModal:Init(editorUI)
  --   renameModal.editorUI = editorUI
  -- end

  -- TODO need to get the filename for the currently selected file
  -- local text = "Untitled"

  -- pixelVisionOS:OpenModal(renameModal, OnRenameFile)

  local file = CurrentlySelectedFile()

  newFileModal:SetText("Rename File", file.name, "Name " .. file.type, true)

  pixelVisionOS:OpenModal(newFileModal,
    function()

      if(newFileModal.selectionValue == false) then
        return
      end

      OnRenameFile(newFileModal.inputField.text)

    end
  )


  -- renameModal:SetText(CurrentlySelectedFile().name)

end

function OnRenameFile(text)

  -- Need to read the last text input from the modal and rename the file
  -- local text = renameModal:GetText()

  local file = CurrentlySelectedFile()

  -- Make sure the new name is not the same as the old name
  if(text ~= file.name) then

    -- Check to see if the file is an extension
    if(file.isDirectory == true) then

      -- Add a trailing slash to the extension
      text = text .. "/"

    else

      -- Remap the extension by looking for it in the extToTypeMap
      local tmpExt = extToTypeMap[file.type]

      -- If the type doesn't exist, use the default ext
      if(tmpExt == nil) then
        tmpExt = file.ext
      end

      -- Add the new ext to the file
      text = text .. tmpExt

    end

    -- print("Rename", )

    MoveTo(NewWorkspacePath(file.path), NewWorkspacePath(file.parentPath .. text))
    -- Rename the file by moving it and giving it a new name
    -- if(MoveFile(file.path, file.parentPath .. text)) then
    RefreshWindow()
    -- end

  end

end

function RefreshWindow()

  if(currentDirectory ~= "none") then
    OpenWindow(currentDirectory, scrollTo, selection)

  end


end

function OnCloseModal()

  -- Clear the background?

  -- Redraw the desktop?

  -- Redraw the window on top of the screen
  -- OpenWindow(currentDirectory)


end

function OnEmptyTrash()

  pixelVisionOS:ShowMessageModal("Empty Trash", "Are you sure you want to empty the trash? This can not be undone.", 160, true,
    function()
      if(pixelVisionOS.messageModal.selectionValue == true) then

        -- Get all the files in the trash
        local files = GetEntities(NewWorkspacePath(trashPath))

        -- Loop through all the files in the root of the trash and delete them
        for i = 1, #files do
          Delete(files[i])
        end

        -- Need to rebuild the desktop to change the trash icon
        RebuildDesktopIcons()

        -- If we are in the trash, redraw the window at the root of the trash
        if(TrashOpen()) then
          OpenWindow(trashPath)
        end

      end

    end
  )

end

function OnRun()

  -- Only try to run if the directory is a game
  if(currentDirectory == nil or currentDirectory == "none" or pixelVisionOS:ValidateGameInDir(NewWorkspacePath(currentDirectory)) == false) then
    return
  end

  LoadGame(currentDirectory)

end
--
-- function CurrentlySelectedFile()
--
--   local path = nil
--
--   if(windowIconButtons ~= nil) then
--
--
--
--   end
--
--   return path
--
-- end

local filesToCopy = nil

function OnCopy()

  if(windowIconButtons ~= nil) then

    -- Remove previous files to be copied
    filesToCopy = {}

    -- TODO this needs to eventually support multiple selections

    local file = CurrentlySelectedFile()

    if(CanCopy(file)) then

      -- Copy the file to the list
      table.insert(filesToCopy, file)

      -- Enable the paste shortcut
      pixelVisionOS:EnableMenuItemByName(PasteShortcut, true)

    else

      -- Display a message that the file can not be copied
      pixelVisionOS:ShowMessageModal(toolName .. "Error", "'".. file.name .. "' can not be copied.", 160, false)

      -- Make sure we can't activate paste
      pixelVisionOS:EnableMenuItemByName(PasteShortcut, false)

    end

  end

end

function GetPathToFile(parent, file)

  local tmpPath = parent .. file.fullName

  if(file.isDirectory) then
    tmpPath = tmpPath .. "/"
  end

  return NewWorkspacePath(tmpPath)

end

function OnPaste(dest)

  -- Get the destination directory
  dest = dest or currentDirectory

  local destPath = NewWorkspacePath(dest)

  -- If there are no files to copy, exit out of this function
  if(filesToCopy == nil) then
    return
  end

  -- Perform the file action validation
  OnSingleFileAction(NewWorkspacePath(filesToCopy[1].path), destPath, "copy")

  -- Clear the files to copy variable
  filesToCopy = nil

end

function OnSingleFileAction(srcPath, destPath, action)

  -- print("OnSingleFileAction", srcPath, destPath, action)

  local tmpDest = (srcPath.IsDirectory == true) and destPath.AppendDirectory(srcPath.EntityName) or destPath.AppendFile(srcPath.EntityName)

  --- Need to make sure we can do the action

  if(srcPath.Path == tmpDest.path) then
    pixelVisionOS:ShowMessageModal(
      "Workspace Path Conflict",
      "You can not perform this action. The source and destination paths are the same.",
      128 + 16
    )
    return

    -- Make sure file doesn't exist and the src path doesn't match the dest path
  elseif(tmpDest.IsChildOf(srcPath)) then

    pixelVisionOS:ShowMessageModal(
      "Workspace Path Conflict",
      "Can't perform a file action on a path that is the child of the destination path.",
      128 + 16
    )

    return

  elseif(PathExists(tmpDest)) then

    pixelVisionOS:ShowMessageModal(
      "Workspace Path Conflict",
      "Looks like there is an existing file with the same name in '".. destPath.Path .. "'. Do you want to overwrite that file?",
      128 + 16,
      true,
      function()

        -- Only perform the copy if the user selects OK from the modal
        if(pixelVisionOS.messageModal.selectionValue) then

          Delete(tmpDest)

          -- Trigger the file copy
          TriggerSingleFileAction(srcPath, tmpDest, action)

        end

      end
    )

    return

  end

  TriggerSingleFileAction(srcPath, tmpDest, action)

end

function TriggerSingleFileAction(srcPath, destPath, action)

  -- Copy the file to the new location, if a file with the same name exists it will be overwritten
  if(action == "copy") then
    CopyTo(srcPath, destPath)
  elseif(action == "move") then
    MoveTo(srcPath, destPath)
  else
    -- nothing happened so exit before we refresh the window
    return
  end

  -- Refresh the window
  RefreshWindow()

end

function CanCopy(file)

  return (file.name ~= "Run" and file.type ~= "updirectory")

end

function OnEjectDisk(diskName)

  if(diskName == nil) then
    local id = desktopIconButtons.currentSelection
    diskName = desktopIcons[id].name
  end

  diskPath = "/" .. diskName .. "/"

  pixelVisionOS:ShowMessageModal("Eject Disk", "Do you want to eject the '".. diskName.."'disk?", 160, true,
    function()

      -- Only perform the copy if the user selects OK from the modal
      if(pixelVisionOS.messageModal.selectionValue) then

        if(currentDirectory ~= "none") then

          if(NewWorkspacePath(currentDirectory).GetDirectorySegments()[2] == diskName) then
            CloseWindow()
          end

        end

        EjectDisk(diskPath)

        ResetGame()
        -- RebuildDesktopIcons()
      end

    end
  )



end

function OnShutdown()

  local systemName = SystemName()

  pixelVisionOS:ShowMessageModal("Shutdown " .. systemName, "Are you sure you want to shutdown "..systemName.."?", 160, true,
    function()
      if(pixelVisionOS.messageModal.selectionValue == true) then
        -- Save changes
        shuttingDown = true

        BackgroundColor(0)

        DrawRect(0, 0, 256, 480, 0, DrawMode.TilemapCache)

        local startX = math.floor((32 - #systemName) * .5)
        DrawText(systemName:upper(), startX, 10, DrawMode.Tile, "large", 15)
        DrawText("IS READY FOR SHUTDOWN.", 5, 11, DrawMode.Tile, "large", 15)

        ShutdownSystem()

      end


    end
  )

end

function RebuildDesktopIcons()

  -- TODO clear desktop with background color
  DrawRect(216, 16, 39, 216, BackgroundColor(), DrawMode.TilemapCache)

  -- Place holder for the old selction
  local oldOpen = -1

  -- See if there are any desktop buttons
  if(desktopIconButtons ~= nil) then

    -- Find the total buttons
    local total = #desktopIconButtons.buttons

    -- Loop through all of the desktop buttons
    for i = 1, total do

      -- See if any of the desktop buttons are open before redrawing them
      if(desktopIconButtons.buttons[i].open) then
        oldOpen = i
      end
    end

  end

  -- Build Desktop Icons
  desktopIcons = {}

  if(PathExists(NewWorkspacePath("/Workspace/"))) then
    table.insert(desktopIcons, {
      name = "Workspace",
      sprite = "filedrive",
      tooltip = "This is the 'Workspace' drive",
      path = "/Workspace/",
      type = "workspace",
      dragDelay = -1
    })
  end

  local disks = DiskPaths()

  for k, v in pairs(disks) do
    -- print(k, v)

    table.insert(desktopIcons, {
      name = k,
      sprite = "diskempty",
      tooltip = "Double click to open the '".. k .. "' disk.",
      tooltipDrag = "You are dragging the '".. k .. "' disk.",
      path = v,
      type = "disk"
    })

  end

  -- Draw desktop icons
  local startY = 16

  desktopIconButtons = editorUI:CreateIconGroup()
  desktopIconButtons.onTrigger = OnDesktopIconClick
  desktopIconButtons.onAction = OnDesktopIconSelected

  for i = 1, #desktopIcons do

    local item = desktopIcons[i]

    local button = editorUI:NewIconGroupButton(desktopIconButtons, {x = 216 - 8, y = startY}, item.sprite, item.name, item.tooltip, bgColor)

    button.iconName = item.name
    button.iconType = item.type
    button.iconPath = item.path

    if(item.dragDelay ~= nil) then
      button.dragDelay = item.dragDelay
    end

    button.toolTipDragging = item.tooltipDrag

    button.onDropTarget = function(src, dest)

      -- print("Drop", src, dest)

      -- if src and dest paths are the same, exit
      if(src == dest) then
        return
      end

      -- TODO need to find the base path
      local srcPath = NewWorkspacePath(src.iconPath)
      local destPath = NewWorkspacePath(dest.iconPath)

      local action = "copy"

      -- Test to see if we should move the entity
      if(srcPath.IsChildOf(destPath) or string.starts(srcPath.Path, trashPath)) then
        action = "move"
      end

      -- Perform the file action
      OnSingleFileAction(srcPath, destPath, action)

    end

    startY = startY + 32 + 8

  end

  -- See if the trash exists
  local trashWorkspacePath = NewWorkspacePath(trashPath)

  if(PathExists(trashWorkspacePath) == false) then
    CreateDirectory(trashWorkspacePath)
  end

  local trashFiles = GetDirectoryContents(trashPath)

  table.insert(desktopIcons, {
    name = "Trash",
    sprite = #trashFiles > 0 and "filetrashfull" or "filetrashempty",
    tooltip = "The trash folder",
    path = trashPath,
    type = "trash"
  })

  pixelVisionOS:EnableMenuItemByName(EmptyTrashShortcut, #trashFiles > 0)

  local item = desktopIcons[#desktopIcons]

  local trashButton = editorUI:NewIconGroupButton(desktopIconButtons, {x = 216 - 8, y = 200 - 2}, item.sprite, item.name, item.tooltip, bgColor)

  trashButton.iconName = item.name
  trashButton.iconType = item.type
  trashButton.iconPath = item.path

  -- Lock the trash from Dragging
  trashButton.dragDelay = -1

  trashButton.onDropTarget = function(src, dest)

    -- print("OnDropTarget", "Trash Icon", src.name, dest.name)
    if(src.iconType == "disk") then

      OnEjectDisk(src.iconName)

    else
      OnDeleteFile(src.iconPath)
      -- print("Move To", src.iconPath, dest.iconPath)
    end

  end

  -- Restore old open value
  if(oldOpen > - 1) then
    editorUI:OpenIconButton(desktopIconButtons.buttons[oldOpen])
  end

end


function OnDesktopIconSelected(value)

  -- TODO need to check if the disk can be ejected?

  if(playingWav) then
    StopWav()
    playingWav = false
  end

  UpdateContextMenu(DesktopIconFocus)

  -- Clear any window selections
  editorUI:ClearIconGroupSelections(windowIconButtons)

  currentSelectedFile = nil

end

local currentOpenIconButton = nil

function OnDesktopIconClick(value, doubleClick)



  -- Close the currently open button
  if(currentOpenIconButton ~= nil) then
    editorUI:CloseIconButton(currentOpenIconButton)
  end

  currentOpenIconButton = desktopIconButtons.buttons[value]
  editorUI:OpenIconButton(currentOpenIconButton)

  OpenWindow(desktopIcons[value].path)


end


function OnNewGame()

  if(PathExists(fileTemplatePath) == false) then
    pixelVisionOS:ShowMessageModal(toolName .. " Error", "There is no default template.", 160, false)
    return
  end

  newFileModal:SetText("New Project", "NewProject", "Folder Name", true)

  pixelVisionOS:OpenModal(newFileModal,
    function()

      if(newFileModal.selectionValue == false) then
        return
      end

      -- Create a new workspace path
      local newPath = NewWorkspacePath(currentDirectory .. newFileModal.inputField.text .. "/")

      -- Copy the contents of the template path to the new unique path
      CopyTo(fileTemplatePath, UniqueFilePath(newPath))

      RefreshWindow()

    end
  )

end

function OnNewFolder(name)

  if(currentDirectory == "none") then
    return
  end

  if(name == nil) then
    name = "Untitled"
  end

  -- Create a new unique workspace path for the folder
  local newPath = UniqueFilePath(NewWorkspacePath(currentDirectory .. name .. "/"))

  -- Set the new file modal to show the folder name
  newFileModal:SetText("New Folder", newPath.EntityName, "Folder Name", true)

  -- Open the new file modal before creating the folder
  pixelVisionOS:OpenModal(newFileModal,
    function()

      if(newFileModal.selectionValue == false) then
        return
      end

      -- Create a new workspace path
      local filePath = NewWorkspacePath(currentDirectory .. newFileModal.inputField.text .. "/")

      -- Make sure the path doesn't exist before trying to make a new directory
      if(PathExists(filePath) == false) then

        -- Create a new directory
        CreateDirectory(filePath)

        -- Refresh the window to show the new folder
        RefreshWindow()

      end

    end
  )

end

function OnDeleteFile(path)

  if(path == nil) then

    if(currentSelectedFile == nil) then
      return
    end

    path = currentSelectedFile.path
  end

  -- Ask the user if they want to delete the file first
  pixelVisionOS:ShowMessageModal("Delete File", "Are you sure you want to move this file to the trash?", 160, true,
    function()

      -- If the user selects ok, we attempt to delete the file
      if(pixelVisionOS.messageModal.selectionValue) then

        -- Look to see if the current file exists and if it's not in the trash
        if(currentDirectory:sub(1, #trashPath) ~= trashPath) then

          -- Delete the file
          DeleteFile(NewWorkspacePath(path))

          -- TODO should only do this if the trash is empty
          -- Rebuild the desktop if we need to change the trash icon
          RebuildDesktopIcons()

          -- Clear the selection
          selection = nil

          -- Refresh the currently open window
          RefreshWindow()

        else

          -- Let the user know the file can not be deleted
          pixelVisionOS:ShowMessageModal(toolName .. " Error", "'".. path .. "' could not be deleted.", 160, false)

        end
      end
    end
  )

end

-- Helper utility to delete files by moving them to the trash
function DeleteFile(path)

  -- Create the base trash path for the file
  local newPath = NewWorkspacePath(trashPath)

  -- See if this is a directory or a file and add the entity name
  if(path.IsDirectory) then
    newPath = newPath.AppendDirectory(path.EntityName)
  else
    newPath = newPath.AppendFile(path.EntityName)
  end

  -- Make sure the path is unique
  newPath = UniqueFilePath(newPath)

  -- Move to the new trash path
  MoveTo(path, newPath)

end

function OpenWindow(path, scrollTo, selection)

  if(scrollTo == nil and windowScrollHistory[path] ~= nil) then
    scrollTo = windowScrollHistory[path]
  end

  refreshTime = 0

  -- Clear the previous file list
  files = {}

  -- save the current directory
  currentDirectory = path

  -- Set a default scrollTo value if none is provided
  scrollTo = scrollTo or 0
  selection = selection or 0

  -- print("OpenWindow", path, scrollTo, selection)


  -- Draw the window chrome
  DrawSprites(windowchrome.spriteIDs, 8, 16, windowchrome.width, false, false, DrawMode.TilemapCache)

  -- Create the slider for the window
  vSliderData = editorUI:CreateSlider({x = 192, y = 26, w = 16, h = 195}, "vsliderhandle", "This is a vertical slider")
  vSliderData.value = scrollTo
  vSliderData.onAction = OnValueChange

  -- Create the close button
  closeButton = editorUI:CreateButton({x = 192, y = 16}, "closewindow", "Close the window.")
  closeButton.hitRect = {x = closeButton.rect.x + 2, y = closeButton.rect.y + 2, w = 10, h = 10}
  closeButton.onAction = CloseWindow

  -- Need to clear the previous button drop targets
  if(windowIconButtons ~= nil) then
    for i = 1, #windowIconButtons.buttons do
      editorUI.collisionManager:RemoveDragTarget(windowIconButtons.buttons[i])
    end
  end

  -- Create a icon button group for all of the files
  windowIconButtons = editorUI:CreateIconGroup()
  windowIconButtons.onTrigger = OnWindowIconClick

  -- Make sure we disable any selection on the desktop when clicking inside of the window icon group
  windowIconButtons.onAction = OnWindowIconSelect

  -- Reset the last start id
  lastStartID = -1

  -- Parse files

  -- Get the list of files from the Lua Service
  files = GetDirectoryContents(path)

  -- Save a count of the files before we add the special files to the list
  fileCount = #files

  -- TODO need to see if the game can be run only if there is a code file

  if(runnerName ~= DrawVersion and runnerName ~= TuneVersion) then

    -- Check to see if this is a game directory
    if(pixelVisionOS:ValidateGameInDir(NewWorkspacePath(path), {"code.lua"}) and TrashOpen() == false) then

      table.insert(
        files,
        1,
        {
          name = "Run",
          type = "run",
          ext = "run",
          path = path,
          isDirectory = false,
          selected = false
        }

      )
    end

  end

  local parentDirectory = NewWorkspacePath(path).ParentPath.Path

  -- Check to see if this is a root directory
  if(parentDirectory ~= "/Disks/" and parentDirectory ~= "/Tmp/" and parentDirectory ~= "/") then

    -- local results = {}
    -- for match in string.gmatch(parentDirectory, "[^/]+") do
    --   table.insert(results, match)
    -- end

    table.insert(
      files,
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

  -- Enable the scroll bar if needed
  editorUI:Enable(vSliderData, #files > totalPerWindow)

  -- Redraw the window for the first time
  -- DrawWindow(files, 0, totalPerWindow)

  OnValueChange(scrollTo)

  currentSelectedFile = nil

  -- Select file
  if(selection > 0) then
    editorUI:SelectIconButton(windowIconButtons, selection, true)
  else
    UpdateContextMenu(WindowFocus)
  end

  ChangeWindowTitle(path, "toolbaricontool")

end



function UpdateContextMenu(inFocus)

  if(inFocus == WindowFocus) then

    local canRun = pixelVisionOS:ValidateGameInDir(NewWorkspacePath(currentDirectory)) and not TrashOpen()

    if(runnerName == DrawVersion or runnerName == TuneVersion) then
      canRun = false
    end

    -- New File options
    if(runnerName ~= PlayVersion) then
      pixelVisionOS:EnableMenuItemByName(NewGameShortcut, not canRun and not TrashOpen())
    end

    pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, not TrashOpen())
    -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, not TrashOpen())
    for i = 1, #newFileOptions do

      local option = newFileOptions[i]
      local enable = not TrashOpen()

      if(enable == true) then

        if(option.file ~= nil) then

          enable = not PathExists(NewWorkspacePath(currentDirectory .. option.file))

        end

      end

      pixelVisionOS:EnableMenuItemByName(option.name, enable)

    end

    -- File options
    pixelVisionOS:EnableMenuItemByName(EditShortcut, false)

    pixelVisionOS:EnableMenuItemByName(RunShortcut, canRun)
    pixelVisionOS:EnableMenuItemByName(RenameShortcut, false)
    -- pixelVisionOS:EnableMenuItemByName(RunShortcut, not TrashOpen())
    pixelVisionOS:EnableMenuItemByName(CopyShortcut, false)
    pixelVisionOS:EnableMenuItemByName(DeleteShortcut, false)
    pixelVisionOS:EnableMenuItemByName(BuildShortcut, canRun)


    -- Disk options
    -- local canEject = not TrashOpen() and currentDirectory:sub(1, #workspacePath) == workspacePath

    pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, CanEject())

    -- Special cases

    -- Only active paste if there is something to paste
    pixelVisionOS:EnableMenuItemByName(PasteShortcut, filesToCopy ~= nil and #filesToCopy > 0)

  elseif(inFocus == DesktopIconFocus) then

    -- New File options
    if(runnerName ~= PlayVersion) then
      pixelVisionOS:EnableMenuItemByName(NewGameShortcut, false)
    end

    pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, false)
    -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, false)
    for i = 1, #newFileOptions do
      pixelVisionOS:EnableMenuItemByName(newFileOptions[i].name, false)
    end

    -- File options
    -- pixelVisionOS:EnableMenuItemByName(EditShortcut, false)
    pixelVisionOS:EnableMenuItemByName(EditShortcut, false)

    pixelVisionOS:EnableMenuItemByName(RunShortcut, false)
    pixelVisionOS:EnableMenuItemByName(RenameShortcut, false)
    pixelVisionOS:EnableMenuItemByName(CopyShortcut, false)
    pixelVisionOS:EnableMenuItemByName(PasteShortcut, false)
    pixelVisionOS:EnableMenuItemByName(DeleteShortcut, false)
    pixelVisionOS:EnableMenuItemByName(BuildShortcut, false)
    -- Disk options



    pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, CanEject())


  elseif(inFocus == WindowIconFocus) then

    local currentSelection = CurrentlySelectedFile()

    local specialFile = currentSelection.name == ".." or currentSelection.name == "Run"

    -- Check to see if currentDirectory is a game
    local canRun = pixelVisionOS:ValidateGameInDir(NewWorkspacePath(currentDirectory)) and not TrashOpen()

    if(runnerName == DrawVersion or runnerName == TuneVersion) then
      canRun = false
    end

    pixelVisionOS:EnableMenuItemByName(BuildShortcut, canRun)


    -- New File options
    if(runnerName ~= PlayVersion) then
      pixelVisionOS:EnableMenuItemByName(NewGameShortcut, not canRun and not TrashOpen())
    end

    pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, not TrashOpen())
    -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, not TrashOpen())

    for i = 1, #newFileOptions do


      local option = newFileOptions[i]
      local enable = not TrashOpen()

      if(enable == true) then

        if(option.file ~= nil) then

          enable = not PathExists(NewWorkspacePath(currentDirectory .. option.file))

        end

      end

      pixelVisionOS:EnableMenuItemByName(option.name, enable)

    end

    -- File options
    -- pixelVisionOS:EnableMenuItemByName(EditShortcut, not TrashOpen() and not specialFile)

    pixelVisionOS:EnableMenuItemByName(EditShortcut, not TrashOpen() and not specialFile)




    -- TODO Can't rename up directory?
    pixelVisionOS:EnableMenuItemByName(RenameShortcut, not TrashOpen() and not specialFile)

    pixelVisionOS:EnableMenuItemByName(RunShortcut, canRun)

    -- pixelVisionOS:EnableMenuItemByName(RunShortcut, canRun)
    pixelVisionOS:EnableMenuItemByName(CopyShortcut, not TrashOpen() and not specialFile)

    -- TODO need to makes sure the file can be deleted
    pixelVisionOS:EnableMenuItemByName(DeleteShortcut, not TrashOpen() and not specialFile)

    -- Disk options
    pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, false)

  else

    -- New File options
    if(runnerName ~= PlayVersion) then
      pixelVisionOS:EnableMenuItemByName(NewGameShortcut, false)
    end

    pixelVisionOS:EnableMenuItemByName(NewFolderShortcut, false)
    -- pixelVisionOS:EnableMenuItemByName(NewFileShortcut, false)

    for i = 1, #newFileOptions do
      pixelVisionOS:EnableMenuItemByName(newFileOptions[i].name, false)
    end

    -- File options
    -- pixelVisionOS:EnableMenuItemByName(EditShortcut, false)
    pixelVisionOS:EnableMenuItemByName(EditShortcut, false)

    pixelVisionOS:EnableMenuItemByName(RunShortcut, false)
    pixelVisionOS:EnableMenuItemByName(RenameShortcut, false)
    pixelVisionOS:EnableMenuItemByName(CopyShortcut, false)
    pixelVisionOS:EnableMenuItemByName(PasteShortcut, false)
    pixelVisionOS:EnableMenuItemByName(DeleteShortcut, false)
    pixelVisionOS:EnableMenuItemByName(BuildShortcut, false)

    -- Disk options
    pixelVisionOS:EnableMenuItemByName(EjectDiskShortcut, false)

  end


end



function OnLaunchSettings()

  local editorPath = ReadBiosData("SettingsEditor")

  if(editorPath == nil) then
    editorPath = rootPath .."SettingsTool/"
  end

  local success = LoadGame(editorPath)

end

function OnLaunchLog()

  local editorPath = ReadBiosData("LogEditor")

  if(editorPath == nil) then
    editorPath = rootPath .."LogPreviewTool/"
  end

  local success = LoadGame(editorPath)

end

-- This is a helper for changing the text on the title bar
function ChangeWindowTitle(pathTitle, titleIconName)

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

  local pathSplit = string.split(pathTitle, "/")

  local desktopIconName = pathSplit[1]

  local iconID = -1

  for i = 1, #desktopIcons do
    if(desktopIcons[i].name == desktopIconName) then
      iconID = i
      break
    end
  end

  -- Try to find the icon button if we open a window and its not selected beforehand
  if(currentOpenIconButton == nil and iconID > 0) then
    currentOpenIconButton = desktopIconButtons.buttons[iconID]

    editorUI:OpenIconButton(currentOpenIconButton)
  end
end

function CloseWindow()

  -- Clear the previous scroll history
  windowScrollHistory = {}

  closeButton = nil

  vSliderData = nil

  windowIconButtons = nil

  currentSelectedFile = nil

  currentDirectory = "none"

  DrawRect(8, 16, windowchrome.width * 8, math.floor(#windowchrome.spriteIDs / windowchrome.width) * 8, BackgroundColor(), DrawMode.TilemapCache)

  DrawWallpaper()

  editorUI:ClearGroupSelections(desktopIconButtons)

  if(currentOpenIconButton ~= nil) then
    editorUI:CloseIconButton(currentOpenIconButton)
  end

  editorUI:ClearFocus()

  UpdateContextMenu(NoFocus)

end

function OnWindowIconSelect(id)


  if(playingWav) then
    StopWav()
    playingWav = false
  end

  if(currentSelectedFile ~= nil) then
    currentSelectedFile.selected = false
    currentSelectedFile.open = false

    -- TODO this is not optimized, force old selected button to reset
    for i = 1, #windowIconButtons.buttons do
      local btn = windowIconButtons.buttons[i]

      if(btn.iconPath == currentSelectedFile.path) then

        btn.selected = false
        editorUI:Invalidate(btn)
      end
    end

    editorUI:RedrawIconButton(currentOpenIconButton)

    -- TODO clearing this doesn't always redraw the button
    -- currentSelectedFile.invalid = true
  end

  local index = id + (lastStartID)-- TODO need to add the scrolling offset

  local tmpItem = files[index]

  -- Select file
  tmpItem.selected = true

  local type = tmpItem.type
  local path = tmpItem.path

  -- TODO need a way to clear any stuck icons that are selected

  -- Set new selected file
  currentSelectedFile = tmpItem

  -- Clear desktop selection
  editorUI:ClearIconGroupSelections(desktopIconButtons)

  UpdateContextMenu(WindowIconFocus)

end

function TrashOpen()

  return currentDirectory:sub(1, #trashPath) == trashPath

end

function CanEject()

  local value = false

  local id = desktopIconButtons.currentSelection

  if(id > 0) then

    local selection = desktopIcons[id]

    value = selection.name ~= "Workspace" and selection.name ~= "Trash"

  end

  return value

end

function CurrentlySelectedFile()

  -- TODO need to return an array to support multiple selections

  local file = nil
  for i = 1, #files do
    file = files[i]
    if(file.selected) then
      return file
    end
  end
  --
  -- local index = windowIconButtons.currentSelection + lastStartID
  --
  -- local tmpItem = files[index]
  --
  -- return tmpItem

end

function OnWindowIconClick(id)

  -- Make sure desktop icons are not selected
  editorUI:ClearGroupSelections(desktopIconButtons)

  -- local index = id + (lastStartID)-- TODO need to add the scrolling offset

  local tmpItem = files[id + lastStartID]--CurrentlySelectedFile()-- files[index]

  local type = tmpItem.type
  local path = tmpItem.path


  -- TODO need a list of things we can't delete

  -- Enable delete option

  -- print("Window Icon Click", tmpItem.name)
  local type = tmpItem.type

  -- If the type is a folder, open it
  if(type == "folder" or type == "updirectory") then

    windowScrollHistory[currentDirectory] = vSliderData.value

    OpenWindow(tmpItem.path)

    -- Check to see if the file is in the trash
  elseif(TrashOpen()) then

    -- Show warning message about trying to edit files in the trash
    pixelVisionOS:ShowMessageModal(toolName .. " Error", "You are not able to edit files inside of the trash.", 160, false
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

    playingWav = true

    -- Check to see if there is an editor for the type or if the type is unknown
  elseif(editorMapping[type] == nil or type == "unknown") then

    pixelVisionOS:ShowMessageModal(toolName .. " Error", "There is no tool installed to edit this file.", 160, false
    )

    -- Now we are ready to try to edit a file
  else

    if(type == "installer") then

      if(PathExists(NewWorkspacePath("/Workspace/")) == false) then

        pixelVisionOS:ShowMessageModal("Installer Error", "You need to create a 'Workspace' drive before you can run an install script.", 160, false)

        return

      elseif(string.starts(currentDirectory, "/Disks/") == false) then

        -- TODO need to see if there is space to mount another disk
        -- TODO need to know if this disk is being mounted as read only
        -- TODO don't run
        pixelVisionOS:ShowMessageModal("Installer Error", "Installers can only be run from a disk.", 160, false)

        return

      end
    end


    -- Find the correct editor from the list
    local editorPath = editorMapping[type]

    -- Set up the meta data for the editor
    local metaData = {
      directory = currentDirectory,
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

function OnMenuQuit()

  QuitCurrentTool()

end

function OnValueChange(value)

  local totalPerRow = 3
  local totalPerPage = 12

  local totalFiles = #files

  local totalRows = math.ceil(totalFiles / totalPerRow) + 1

  local hiddenRows = totalRows - math.ceil(totalPerPage / totalPerRow)

  local offset = Clamp(hiddenRows * value, 0, hiddenRows - 1)

  DrawWindow(files, offset * totalPerRow, totalPerPage)

end

function DrawWindow(files, startID, total)

  if(startID < 0) then
    startID = 0
  end
  -- print("DrawWindow", startID)

  if(lastStartID == startID) then
    return
  end

  -- TODO the icon buttons should have their own clear graphic
  -- DrawRect(10, 28, 180, 192, 11, DrawMode.TilemapCache)

  editorUI:ClearIconGroup(windowIconButtons)

  lastStartID = startID

  local startX = 13
  local startY = 32
  local row = 0
  local maxColumns = 3
  local padding = 16
  local width = 48
  local height = 40
  local bgColor = 11

  local isGameDir = pixelVisionOS:ValidateGameInDir(NewWorkspacePath(currentDirectory)) and currentDirectory ~= trashPath

  local dirSplit = string.split(currentDirectory, "/")

  local systemRoot = dirSplit[1] == "Workspace" or (dirSplit[1] == "Disks" and #dirSplit == 2)

  for i = 1, total do

    -- Calculate the real index
    local fileID = i + startID

    local index = i - 1

    -- Update column value
    local column = index % maxColumns

    local newX = index % maxColumns * (width + padding) + startX
    local newY = row * (height + padding / 2) + startY

    if(fileID <= #files) then

      local item = files[fileID]

      -- Find the right type for the file
      UpdateFileType(item, isGameDir)

      local spriteName = GetIconSpriteName(item)

      if(spriteName == fileTypeMap["folder"] and systemRoot == true) then

        -- TODO any system type folder should get this icon including tools or libs on disks

        if(item.name == "System" or item.name == "Libs" or item.name == "Tools") then
          spriteName = "fileosfolder"
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

      local button = editorUI:NewIconGroupButton(windowIconButtons, {x = newX, y = newY}, spriteName, item.name, toolTip, bgColor)

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

        -- Add on drop target code to each folder type
        button.onDropTarget = function(src, dest)

          -- print("Drop", src, dest)

          -- if src and dest paths are the same, exit
          if(src.iconPath == dest.iconPath) then
            return
          end

          local srcPath = NewWorkspacePath(src.iconPath)
          local destPath = NewWorkspacePath(dest.iconPath)

          -- Default action is copy
          local action = "copy"

          -- Test to see if we should move the entity
          if(srcPath.IsChildOf(destPath) or srcPath.ParentPath == destPath.ParentPath) then
            action = "move"
          end

          -- Perform the file action
          OnSingleFileAction(srcPath, destPath, action)

        end

      elseif(item.type == "run" or item.type == "unknown") then

        editorUI.collisionManager:DisableDragging(button)
        button.onDropTarget = nil

      end

      if (column == (maxColumns - 1)) then
        row = row + 1
      end

    else

      DrawRect(newX, newY, 48, 48 - 8, bgColor, DrawMode.TilemapCache)

    end

  end


end


function UpdateFileType(item, isGameFile)

  local key = item.type--item.isDirectory and item.type or item.ext

  -- print(item.name, item.type)

  -- Only convert file types when we are in a game directory
  -- if(isGameFile == true) then

  key = item.type

  -- if(item.isDirectory == false and item.name ~= "Run") then
  --
  --   -- TODO need to look this up based on if an editor is registered with the system
  --
  --   if(editorMapping[key] == nil) then
  --     key = fileTypeMap[item.ext] and item.ext or "unknown"
  --   end
  --
  -- end

  -- TODO support legacy files
  if(key == "png" and isGameFile == true) then
    -- print("Is PNG")
    if(item.name == "sprites" and editorMapping["sprites"] ~= nil) then
      key = "sprites"
    elseif(item.name == "tilemap" and editorMapping["tilemap"] ~= nil) then
      key = "tiles"
    elseif(item.name == "colors" and editorMapping["colors"] ~= nil) then
      key = "colors"
      -- elseif(item.name == "tilemap" and editorMapping["tilemap"] ~= nil) then
      --   key = "tilemap"
    end
  elseif(key == "font.png") then

    -- print("Is font")
    if(isGameFile == false or editorMapping["font"] == nil) then
      key = "png"
    else
      key = "font"
    end

  elseif(key == "json" and isGameFile == true) then

    if(item.name == "sounds" and editorMapping["sounds"] ~= nil)then
      key = "sounds"
    elseif(item.name == "tilemap" and editorMapping["tilemap"] ~= nil) then
      key = "tilemap"
    elseif(item.name == "music" and editorMapping["music"] ~= nil) then
      key = "music"
    elseif(item.name == "data" and editorMapping["system"] ~= nil) then
      key = "system"
    elseif(item.name == "info") then
      key = "info"
    end

  end

  if(key == "wav") then
    item.ext = "wav"
  end

  -- end



  -- Fix type for pv8 and runner templates
  if(item.type == "pv8" or item.type == "pvr") then
    key = item.type
  end

  -- Last chance to fix any special edge cases like the installer and info which share text file extensions
  if(key == "txt" and item.name:lower() == "installer") then
    key = "installer"
  end
  --
  -- if(key == "json" and item.name:lower() == "info") then
  --   key = "info"
  -- end

  item.type = key

end

function GetIconSpriteName(item)

  local iconName = fileTypeMap[item.type]
  -- print("name", name, iconName)
  return iconName == nil and "fileunknown" or fileTypeMap[item.type]

end

-- The Update() method is part of the game's life cycle. The engine calls Update() on every frame
-- before the Draw() method. It accepts one argument, timeDelta, which is the difference in
-- milliseconds since the last frame.
function Update(timeDelta)

  if(shuttingDown == true) then
    return
  end



  -- This needs to be the first call to make sure all of the OS and editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- Only update the tool's UI when the modal isn't active
  if(pixelVisionOS:IsModalActive() == false) then

    if(currentDirectory ~= "none") then

      -- Check for file system changes
      refreshTime = refreshTime + timeDelta

      if(refreshTime > refreshDelay) then

        tmpFiles = GetDirectoryContents(currentDirectory)

        if(#tmpFiles > fileCount) then
          RefreshWindow()
        end

        refreshTime = 0

      end

      -- Create a new piont to see if we need to change the sprite position
      local newPos = NewPoint(0, 0)

      local columns = 3
      local rows = 1

      -- Offset the new position by the direction button
      if(Button(Buttons.Up, InputState.Released)) then
        newPos.y = -1
      elseif(Button(Buttons.Right, InputState.Released)) then
        newPos.x = 1
      elseif(Button(Buttons.Down, InputState.Released)) then
        newPos.y = 1
      elseif(Button(Buttons.Left, InputState.Released)) then
        newPos.x = -1
      end

      -- Test to see if the new position has changed
      if(newPos.x ~= 0 or newPos.y ~= 0) then

        -- TODO need to wire this up correctly
        local currentSelectionID = 0

        local curPos = CalculatePosition(currentSelectionID, columns)

        newPos.x = Clamp(curPos.x + newPos.x, 0, columns - 1)
        newPos.y = Clamp(curPos.y + newPos.y, 0, rows - 1)

        local newIndex = CalculateIndex(newPos.x, newPos.y, columns)

        print(newIndex)

      end

    end

    editorUI:UpdateIconGroup(desktopIconButtons)
    editorUI:UpdateIconGroup(windowIconButtons)

    -- if(data.dragging == true and self.editorUI.collisionManager.dragTime > data.dragDelay) then

    editorUI:UpdateButton(closeButton)

    editorUI:UpdateSlider(vSliderData)
  end



end

-- The Draw() method is part of the game's life cycle. It is called after Update() and is where
-- all of our draw calls should go. We'll be using this to render sprites to the display.
function Draw()

  -- We can use the RedrawDisplay() method to clear the screen and redraw the tilemap in a
  -- single call.
  RedrawDisplay()

  if(shuttingDown == true) then
    return
  end

  -- The UI should be the last thing to draw after your own custom draw calls
  pixelVisionOS:Draw()

end

function Shutdown()

  -- print("File Tool Shutdown", SessionID(), currentDirectory)

  -- Save the current session ID
  WriteSaveData("sessionID", SessionID())

  -- Make sure we don't save paths in the tmp directory
  WriteSaveData("lastPath", currentDirectory)

  -- Save the current session ID
  WriteSaveData("scrollPos", (vSliderData ~= nil and vSliderData.value or 0))

  -- Save the current selection
  WriteSaveData("selection", (windowIconButtons ~= nil and editorUI:ToggleGroupSelections(windowIconButtons)[1] or 0))

  -- Tell the system to save all active disks
  -- SaveActiveDisks()

end

function OnExportGame()

  local buildTool = editorMapping["build"]

  -- Look to see if there is a build tool
  if(buildTool ~= nil) then

    -- Pass in the current directory
    local metaData = {
      directory = currentDirectory,
    }

    -- Load the build tool and pass the current directory
    LoadGame(buildTool, metaData)

  else

    local srcPath = NewWorkspacePath(currentDirectory)
    local destPath = srcPath.AppendDirectory("Builds")

    -- TODO need to read game name from info file

    local metaData = ReadJson(srcPath.AppendFile("info.json"))

    local gameName = metaData["name"] or srcPath.EntityName

    -- Manually create a game disk from the current folder's files
    local gameFiles = GetEntities(srcPath)

    local response = CreateDisk(gameName, gameFiles, destPath)

    pixelVisionOS:ShowMessageModal("Build " .. (response.success == true and "Complete" or "Failed"), response.message, 160, false,

      function()
        if(response.success == true) then
          OpenWindow(NewWorkspacePath(response.path).ParentPath.path)
        end
      end
    )
  end

end