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
-- Christina-Antoinette Neofotistou - @CastPixel
-- Christer Kaitila - @McFunkypants
-- Pedro Medeiros - @saint11
-- Shawn Rakowski - @shwany
--

PixelVisionOS = {}
PixelVisionOS.__index = PixelVisionOS

LoadScript("pixel-vision-ui-v2")

-- Pixel Vision OS Components
LoadScript("pixel-vision-os-title-bar-v2")
LoadScript("pixel-vision-os-message-bar-v2")
LoadScript("pixel-vision-os-modal-v2")
LoadScript("pixel-vision-os-message-modal-v2")
LoadScript("pixel-vision-os-color-utils-v2")
LoadScript("pixel-vision-os-undo-v2")
-- LoadScript("pixel-vision-os-menu-v2")

function PixelVisionOS:Init()
  -- Create a new object for the instance and register it
  local _pixelVisionOS = {}
  setmetatable(_pixelVisionOS, PixelVisionOS)

  _pixelVisionOS.editorUI = EditorUI:Init()

  -- Create new title bar instance
  _pixelVisionOS.titleBar = _pixelVisionOS:CreateTitleBar(0, 0)

  -- Create message bar instance
  _pixelVisionOS.messageBar = _pixelVisionOS:CreateMessageBar(7, 230, 60)

  _pixelVisionOS.version = "v2.4"

  return _pixelVisionOS

end

function PixelVisionOS:Update(timeDelta)

  -- Update the editorUI
  self.editorUI:Update(timeDelta)

  -- Update the title bar
  self:UpdateTitleBar(self.titleBar, timeDelta)

  -- Update message bar
  self:UpdateMessageBar(self.messageBar)

  -- if(self:IsModalActive() == true) then
  self:UpdateModal(timeDelta)
  -- end

end

function PixelVisionOS:Draw()

  if(self.editorUI.inFocusUI ~= nil and self.editorUI.inFocusUI.toolTip ~= nil) then

    self:DisplayToolTip(self.editorUI.inFocusUI.toolTip)

  else
    self:ClearToolTip()
    -- clear tool tip message

  end

  -- We manually call draw on the message bar since it can be updated at any point outside of its own update call
  self:DrawMessageBar(self.messageBar)


  -- Draw the editor UI
  self.editorUI:Draw()

  -- Draw modals on top
  self:DrawModal()

end

-- This is a helper for changing the text on the title bar
function PixelVisionOS:ChangeTitle(text, titleIconName)

  DrawRect(30, 0, 140, 8, 0, DrawMode.TilemapCache)

  local maxChars = 35
  if(#text > maxChars) then
    text = text:sub(0, maxChars - 3) .. "..."
  else
    text = string.rpad(text, maxChars, "")
  end

  self.titleBar.titleIcon = _G[titleIconName] and _G[titleIconName].spriteIDs[1] or nil
  self.titleBar.title = text
  self.editorUI:Invalidate(self.titleBar)
end

function PixelVisionOS:ShowAboutModal(toolTitle, optionalText, width)

  width = width or 160

  optionalText = optionalText or ""

  local message = "Copyright (c) 2018, Jesse Freeman. All rights reserved. Licensed under the Microsoft Public License (MS-PL) License.\n\n"

  self:ShowMessageModal("About " .. toolTitle .. " " .. self.version, message .. optionalText, width, false)

end

function PixelVisionOS:ShowMessageModal(title, message, width, showCancel, onCloseCallback)

  -- Look to see if the modal exists
  if(self.messageModal == nil) then

    -- Create the model
    self.messageModal = MessageModal:Init(title, message, width, showCancel )

    -- Pass a reference of the editorUI to the modal
    self.messageModal.editorUI = self.editorUI

  else

    -- If the modal exists, configure it with the new values
    self.messageModal:Configure(title, message, width, showCancel)
  end

  -- Open the modal
  self:OpenModal(self.messageModal, onCloseCallback)

end

-- function PixelVisionOS:ValidateGameInDir(path, requiredFiles)
--
--   if (OldPathExists(path) == false) then
--     return false
--   end
--
--   requiredFiles = requiredFiles or {}
--
--   -- Make sure a data file is part of the list
--   table.insert(requiredFiles, "data.json")
--
--   local flag = 0
--
--   local total = #requiredFiles
--
--   for i = 1, total do
--     if(OldPathExists(path .. requiredFiles[i]) == true) then
--       flag = flag + 1
--     end
--   end
--
--   return flag == total
--
-- end

function PixelVisionOS:FindEditors()

  local editors = {}--new Dictionary<string, string>();



  local paths = 
  {
    NewWorkspacePath("/PixelVisionOS/System/Tools/")

  }

  -- Add disk paths
  local disks = DiskPaths();

  for k, v in pairs(disks) do
    local diskPath = NewWorkspacePath(v).AppendDirectory("System").AppendDirectory("Tools")

    table.insert(paths, diskPath)

  end

  local total = #paths--.Count;

  for i = 1, total do

    local path = paths[i];

    -- try
    -- {
    if (PathExists(path)) then
      -- {
      -- print("Look for editors in", path.Path)
      --    /  / Console.WriteLine("Look for editors in " + path);
      --
      local folders = GetEntities(path);
      --
      for i = 1, #folders do
        -- body...
        local folder = folders[i]
        --   foreach (var folder in folders)
        if (folder.IsDirectory) then

          if (self:ValidateGameInDir(folder)) then
            --   {
            --      /  / Console.WriteLine("Reading from game folder " + folder);
            --
            --
            local jsonData = ReadJson(folder.AppendFile("info.json"))

            -- print("Reading game from", jsonData["editType"])

            --      /  / var metaData = workspace.ReadGameMetaData(folder.AppendFile("info.json"));
            --
            --     var data = workspace.ReadTextFromFile(folder.AppendFile("info.json")); /  / ReadTextFromFile(filePath);
            --
            --      /  / parse the json data into a dictionary the engine can use
            --     var jsonData = Json.Deserialize(data) as Dictionary < string, object > ;
            --
            if (jsonData["editType"] ~= nil) then
              --     {
              local split = string.split(jsonData["editType"], ",")
              --
              local totalTypes = #split
              for j = 1, totalTypes do
                -- body...


                local key = split[j];
                --
                -- if (!editors.ContainsKey(key))
                editors[key] = folder.Path
                --       else
                --         editors[key] = folder.Path;
                --
                -- print("Editor Found ", key, " ", folder.Path);
              end
            end
          end
        end
      end
    end
    -- catch
    -- {
    --    /  / runner.DisplayWarning("Couldn't find editor path " + path);
    -- }
    -- }

  end
  -- return editors;

  return editors

end

function PixelVisionOS:ValidateGameInDir(workspacePath, requiredFiles)

  if (PathExists(workspacePath) == false) then
    return false
  end

  requiredFiles = requiredFiles or {"data.json", "info.json"}

  -- if(table.indexOf(requiredFiles, "data.json") == -1) then
  --   -- Make sure a data file is part of the list
  --   table.insert(requiredFiles, "data.json")
  -- end

  local flag = 0

  local total = #requiredFiles

  for i = 1, total do
    if(PathExists(workspacePath.AppendFile(requiredFiles[i])) == true) then
      flag = flag + 1
    end
  end

  return flag == total

end
