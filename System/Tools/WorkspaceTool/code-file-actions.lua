-- Helper utility to delete files by moving them to the trash
function WorkspaceTool:DeleteFile(path)

    -- Create the base trash path for the file
    local newPath = self.trashPath

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

function WorkspaceTool:OnDeleteFile(selections)

    -- Get the current selections
    local selections = self:CurrentlySelectedFiles()

    -- Exit out of this if there are no selected files
    if(selections == nil) then
        return
    end

    -- TODO how should this be handled if there are multiple selections
    self.fileActionSrc = self.currentPath

    self.filesToCopy = {}

    -- Loop through all of the selections
    for i = 1, #selections do
        
        local srcPath = self.files[selections[i]].path

        if(srcPath.IsDirectory) then

            -- Add all of the files that need to be copied to the list
            local childEntities = GetEntitiesRecursive(srcPath)

            -- Loop through each of the children and add them to the list
            for j = 1, #childEntities do
                table.insert(self.filesToCopy, childEntities[i])
            end

        end

        -- Make sure the selected directory is included
        table.insert(self.filesToCopy, srcPath)

    end

    -- Always make sure anything going into the trash has a unique file name
    self:StartFileOperation(self.trashPath, "throw out")



    -- if(path == nil) then

    --     if(currentSelectedFile == nil) then
    --         return
    --     end

    --     path = currentSelectedFile.path
    -- end

    -- filesToCopy = {}

    -- fileActionSrc = self.currentPath

    -- -- TODO need to find the base path
    -- local srcPath = NewWorkspacePath(path)
    -- if(srcPath.IsDirectory) then

    --     -- Add all of the files that need to be copied to the list
    --     filesToCopy = GetEntitiesRecursive(srcPath)

    -- end

    -- -- Make sure the selected directory is included
    -- table.insert(filesToCopy, 1, srcPath)


    -- local destPath = trashPath

    -- local action = "throw out"

    -- -- print("Delete Action", action, srcPath, destPath)

    -- -- Perform the file action

    -- selection = nil

    -- -- Always make sure anything going into the trash has a unique file name
    -- StartFileOperation(destPath, action)

end

function WorkspaceTool:StartFileOperation(destPath, action)
    
    self.fileActionActiveTotal = #filesToCopy
    self.fileActionDest = destPath

    -- Clear the path filter (used to change base path if there is a duplicate)
    self.fileActionPathFilter = nil

    self.fileAction = action
    self.fileActionActiveTime = 0
    self.fileActionDelay = .02
    self.fileActionCounter = 0
    self.fileActionBasePath = destPath
    self.fileCleanup = {}

    -- Registere the file action update function with the tool so it updates
    self:RegisterUI({name = "FileAction"}, "OnFileActionNextStep", self)

    if(action == "delete") then
        invalidateTrashIcon = true
        self.fileActionActive = true
        return
    end

    -- Modify the destPath with the first item for testing
    destPath = destPath.AppendPath(filesToCopy[1].Path:sub( #fileActionSrc.Path + 1))
    self.fileActionBasePath = destPath

    if(action == "throw out") then
        self.fileActionPathFilter = UniqueFilePath(destPath)
        invalidateTrashIcon = true
    end

    if(filesToCopy[1].IsChildOf(destPath)) then

        pixelVisionOS:ShowMessageModal(
            "Workspace Path Conflict",
            "Can't perform a file action on a path that is the child of the destination path.",
            128 + 16, false, function() CancelFileActions() end
        )
        return

    elseif(PathExists(destPath) and self.fileActionPathFilter == nil) then

        local duplicate = destPath.Path == filesToCopy[1].Path

        -- Ask if the file first item should be duplicated
        pixelVisionOS:ShowMessageModal(
            "Workspace Path Conflict",
            "Looks like there is an existing file with the same name in '".. destPath.Path .. "'. Do you want to " .. (duplicate and "duplicate" or "replace") .. " '"..destPath.EntityName.."'?",
            200,
            true,
            function()

                -- Only perform the copy if the user selects OK from the modal
                if(pixelVisionOS.messageModal.selectionValue) then

                    if(duplicate == true) then

                        self.fileActionPathFilter = UniqueFilePath(destPath)

                    else
                        -- print("Delete", destPath)
                        SafeDelete(destPath)
                    end
                    -- Start the file action process
                    fileActionActive = true

                else
                    CancelFileActions()
                    RefreshWindow()
                end

            end
        )

    else

        pixelVisionOS:ShowMessageModal(
            "Workspace ".. action .." Action",
            "Do you want to ".. action .. " " .. self.fileActionActiveTotal .. " files?",
            160,
            true,
            function()

                -- -- Only perform the copy if the user selects OK from the modal
                if(pixelVisionOS.messageModal.selectionValue) then

                    -- Start the file action process
                    fileActionActive = true

                else
                    CancelFileActions()
                    RefreshWindow()
                end

            end
        )

    end

end

function WorkspaceTool:FileActionUpdate()

    if(self.fileActionActive == true) then

        self.fileActionActiveTime = self.fileActionActiveTime + editorUI.timeDelta

        if(self.fileActionActiveTime > self.fileActionDelay) then
            self.fileActionActiveTime = 0

            self:OnFileActionNextStep()

            if(self.fileActionCounter >= self.fileActionActiveTotal) then

                OnFileActionComplete()

            end

        end


    end

end

function WorkspaceTool:OnFileActionNextStep()

    if(#filesToCopy == 0) then
        return
    end

    -- -- Increment the counter
    -- self.fileActionCounter = self.fileActionCounter + 1

    -- -- Test to see if the counter is equil to the total
    -- if(self.fileActionCounter > self.fileActionActiveTotal) then

    --     self.fileActionDelay = 4
    --     return
    -- end

    -- local srcPath = filesToCopy[self.fileActionCounter]

    -- -- -- Look to see if the modal exists
    -- if(progressModal == nil) then
    --     --
    --     --   -- Create the model
    --     progressModal = ProgressModal:Init("File Action ", editorUI)

    --     -- Open the modal
    --     pixelVisionOS:OpenModal(progressModal)

    -- end

    -- local message = self.fileAction .. " "..string.lpad(tostring(self.fileActionCounter), string.len(tostring(self.fileActionActiveTotal)), "0") .. " of " .. self.fileActionActiveTotal .. ".\n\n\nDo not restart or shut down Pixel Vision 8."

    -- local percent = (self.fileActionCounter / self.fileActionActiveTotal)

    -- progressModal:UpdateMessage(message, percent)

    -- local destPath = self.fileAction == "delete" and self.fileActionDest or NewWorkspacePath(self.fileActionDest.Path .. srcPath.Path:sub( #fileActionSrc.Path + 1))

    -- if(self.fileActionPathFilter ~= nil) then

    --     destPath = NewWorkspacePath(self.fileActionPathFilter.Path .. destPath.Path:sub( #self.fileActionBasePath.Path + 1))

    -- end

    -- -- Find the path to the directory being copied
    -- local dirPath = destPath.IsFile and destPath.ParentPath or destPath

    -- -- Make sure the directory exists
    -- if(PathExists(dirPath) == false) then

    --     CreateDirectory(dirPath)
    -- end

    -- if(srcPath.IsFile) then

    --     TriggerSingleFileAction(srcPath, destPath, self.fileAction)
    -- elseif(self.fileAction ~= "copy") then

    --     table.insert(self.fileCleanup, srcPath)
    -- end

end

function WorkspaceTool:OnFileActionComplete()

    if(self.fileCleanup == nil) then
        return
    end

    -- TODO perform any cleanup after moving
    for i = 1, #self.fileCleanup do
        local path = self.fileCleanup[i]
        if(PathExists(path)) then
            Delete(path)
        end
    end

    -- Turn off the file action loop
    self.fileActionActive = false

    -- Remove the file action update from the UI loop
    self:RemoveUI("FileAction")

    -- Close the modal
    pixelVisionOS:CloseModal()

    -- Destroy the progress modal
    self.progressModal = nil

    -- Clear files to copy list
    self.filesToCopy = nil

    self:RefreshWindow()

    if(self.invalidateTrashIcon == true) then
        self:RebuildDesktopIcons()
        self.invalidateTrashIcon = false
    end

end

function WorkspaceTool:TriggerSingleFileAction(srcPath, destPath, action)

    -- Copy the file to the new location, if a file with the same name exists it will be overwritten
    if(action == "copy") then

        -- Only copy files over since we create the directory in the previous step
        if(destPath.isFile) then
            print("CopyTo", srcPath, destPath)
            -- CopyTo(srcPath, destPath)
        end

    elseif(action == "move" or action == "throw out") then

        -- Need to keep track of directories that listed since we want to clean them up when they are empty at the end
        if(srcPath.IsDirectory) then
            -- print("Save file path", srcPath)
            table.insert(self.fileCleanup, srcPath)
        else
            -- MoveTo(srcPath, destPath)
            print("MoveTo", srcPath, destPath)
        end

    elseif(action == "delete") then
        if(srcPath.IsDirectory) then
            -- print("Save file path", srcPath)
            table.insert(self.fileCleanup, srcPath)
        else
            -- Delete(srcPath)
            print("MoveTo", srcPath, destPath)
        end
    else
        -- nothing happened so exit before we refresh the window
        return
    end

    -- Refresh the window
    self:RefreshWindow()

end

function WorkspaceTool:CanCopy(file)

    return (file.name ~= "Run" and file.type ~= "updirectory")

end

function WorkspaceTool:CancelFileActions()

    if(self.fileActionActive == true) then
        self:OnFileActionComplete()

        -- editorUI.mouseCursor:SetCursor(1, false)
    end

end

function WorkspaceTool:SafeDelete(srcPath)

    self:Delete(srcPath)--, trashPath)

end

function WorkspaceTool:OnCopy()

    -- if(windowIconButtons ~= nil) then

    --     -- Remove previous files to be copied
    --     filesToCopy = {}
    --     fileActionSrc = self.currentPath

    --     -- TODO this needs to eventually support multiple selections

    --     local file = CurrentlySelectedFile()

    --     if(CanCopy(file)) then

    --         local tmpPath = NewWorkspacePath(file.path)

    --         -- Test if the path is a directory
    --         if(tmpPath.IsDirectory) then

    --             -- Add all of the files that need to be copied to the list
    --             filesToCopy = GetEntitiesRecursive(tmpPath)

    --         end

    --         -- Make sure the selected directory is included
    --         table.insert(filesToCopy, 1, NewWorkspacePath(file.path))

    --         -- print("Copy File", file.name, file.path, #filesToCopy, dump(filesToCopy))

    --         -- Enable the paste shortcut
    --         pixelVisionOS:EnableMenuItemByName(PasteShortcut, true)

    --         -- TODO eventually need to change the message to handle multiple files
    --         pixelVisionOS:DisplayMessage(#filesToCopy .. " file" .. (#filesToCopy == 1 and " has" or "s have") .." been copied.", 2)

    --     else

    --         -- Display a message that the file can not be copied
    --         pixelVisionOS:ShowMessageModal(toolName .. "Error", "'".. file.name .. "' can not be copied.", 160, false)

    --         -- Make sure we can't activate paste
    --         pixelVisionOS:EnableMenuItemByName(PasteShortcut, false)

    --     end

    -- end

end

function WorkspaceTool:OnPaste(dest)

    -- -- Get the destination directory
    -- dest = dest or self.currentPath

    -- local destPath = NewWorkspacePath(dest)

    -- -- If there are no files to copy, exit out of this function
    -- if(filesToCopy == nil) then
    --     return
    -- end

    -- -- Perform the file action validation
    -- StartFileOperation(destPath, "copy")

    -- pixelVisionOS:DisplayMessage("Entit" .. (#filesToCopy > 1 and "ies have" or "y has") .. " has been pasted.", 2)

end

function WorkspaceTool:OnNewFolder(name)

    if(self.currentPath == nil) then
        return
    end

    if(name == nil) then
        name = "Untitled"
    end

    -- Create a new unique workspace path for the folder
    local newPath = UniqueFilePath(self.currentPath.AppendDirectory(name))

    local newFileModal = self:GetNewFileModal()

    -- Set the new file modal to show the folder name
    newFileModal:SetText("New Folder", newPath.EntityName, "Folder Name", true)

    -- Open the new file modal before creating the folder
    pixelVisionOS:OpenModal(newFileModal,
        function()

            if(newFileModal.selectionValue == false) then
                return
            end

            -- Create a new workspace path
            local filePath = self.currentPath.AppendDirectory(newFileModal.inputField.text)

            -- Make sure the path doesn't exist before trying to make a new directory
            if(PathExists(filePath) == false) then

                -- This is a bit of a hack to get around an issue creating folders on disks.

                -- Test to see if we are creating a folder on a disk
                if(string.starts(filePath.Path, "/Disks/")) then

                    -- Create a new path in the tmp directory
                    local tmpPath = UniqueFilePath(NewWorkspacePath("/Tmp/"..newFileModal.inputField.text .. "/"))

                    -- Create a new folder in the tmp directory
                    CreateDirectory(tmpPath)

                    -- Move the folder from tmp to the new location
                    MoveTo(tmpPath, filePath)

                else
                    -- Create a new directory
                    CreateDirectory(filePath)

                end

                -- Refresh the window to show the new folder
                self:RefreshWindow(true)

                self:SelectFile(filePath)

            end

        end
    )

end

function WorkspaceTool:GetNewFileModal()

    if(self.newFileModal == nil) then

        self.newFileModal = NewFileModal:Init(editorUI)
        self.newFileModal.editorUI = editorUI

    end

    return self.newFileModal

end

function WorkspaceTool:OnNewGame()

    -- if(PathExists(fileTemplatePath) == false) then
    --     pixelVisionOS:ShowMessageModal(toolName .. " Error", "There is no default template.", 160, false)
    --     return
    -- end

    -- newFileModal:SetText("New Project", "NewProject", "Folder Name", true)

    -- pixelVisionOS:OpenModal(newFileModal,
    --     function()

    --         if(newFileModal.selectionValue == false) then
    --             return
    --         end

    --         -- Create a new workspace path
    --         local newPath = currentDirectory.AppendDirectory(newFileModal.inputField.text)

    --         -- Copy the contents of the template path to the new unique path
    --         CopyTo(fileTemplatePath, UniqueFilePath(newPath))

    --         RefreshWindow()

    --     end
    -- )

end

function WorkspaceTool:OnNewFile(fileName, ext, type, editable)

    -- if(type == nil) then
    --     type = ext
    -- end

    -- newFileModal:SetText("New ".. type, fileName, "Name " .. type .. " file", editable == nil and true or false)

    -- pixelVisionOS:OpenModal(newFileModal,
    --     function()

    --         if(newFileModal.selectionValue == false) then
    --             return
    --         end

    --         local filePath = UniqueFilePath(currentDirectory.AppendFile(newFileModal.inputField.text .. "." .. ext))

    --         local tmpPath = fileTemplatePath.AppendFile(filePath.EntityName)

    --         -- Check for lua files first since we always want to make them empty
    --         if(ext == "lua") then
    --             SaveText(filePath, "-- Empty code file")

    --             -- Check for any files in the template folder we can copy over
    --         elseif(PathExists(tmpPath)) then

    --             CopyTo(tmpPath, filePath)
    --             -- -- print("Copy from template", tmpPath.Path)

    --             -- Create an empty text file
    --         elseif( ext == "txt") then
    --             SaveText(filePath, "")

    --             -- Create an empty json file
    --         elseif(ext == "json") then
    --             SaveText(filePath, "{}")
    --         elseif(type == "font") then

    --             tmpPath = fileTemplatePath.AppendFile("large.font.png")
    --             CopyTo(tmpPath, filePath)

    --         else
    --             -- print("File not supported")
    --             -- TODO need to display an error message that the file couldn't be created
    --             return
    --         end

    --         -- NewFile(filePath)
    --         RefreshWindow()

    --     end
    -- )

end

function WorkspaceTool:OnRun()

    -- Only try to run if the directory is a game
    if(self.currentPath == nil or pixelVisionOS:ValidateGameInDir(self.currentPath) == false) then
        return
    end

    -- TODO this should also accept a workspace path?
    LoadGame(self.currentPath.Path)

end

function WorkspaceTool:OnEmptyTrash()

    -- pixelVisionOS:ShowMessageModal("Empty Trash", "Are you sure you want to empty the trash? This can not be undone.", 160, true,
    --     function()
    --         if(pixelVisionOS.messageModal.selectionValue == true) then

    --             -- Get all the files in the trash
    --             filesToCopy = GetEntitiesRecursive(trashPath)

    --             StartFileOperation(trashPath, "delete")

    --         end

    --     end
    -- )

end

function WorkspaceTool:TrashOpen()

    return self.currentPath.Path == self.trashPath.Path

end

function WorkspaceTool:CanEject()

    local value = false

    local id = self.desktopIconButtons.currentSelection

    if(id > 0) then

        local selection = self.desktopIcons[id]

        value = selection.name ~= "Workspace" and selection.name ~= "Trash"

    end

    return value

end