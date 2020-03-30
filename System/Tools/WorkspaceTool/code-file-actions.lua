function WorkspaceTool:Test()
    print("Tool addon works")
end



-- Helper utility to delete files by moving them to the trash
function DeleteFile(path)

    -- Create the base trash path for the file
    local newPath = trashPath

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

function OnDeleteFile(path)

    if(path == nil) then

        if(currentSelectedFile == nil) then
            return
        end

        path = currentSelectedFile.path
    end

    filesToCopy = {}

    fileActionSrc = currentDirectory

    -- TODO need to find the base path
    local srcPath = NewWorkspacePath(path)
    if(srcPath.IsDirectory) then

        -- Add all of the files that need to be copied to the list
        filesToCopy = GetEntitiesRecursive(srcPath)

    end

    -- Make sure the selected directory is included
    table.insert(filesToCopy, 1, srcPath)


    local destPath = trashPath

    local action = "throw out"

    -- print("Delete Action", action, srcPath, destPath)

    -- Perform the file action

    selection = nil

    -- Always make sure anything going into the trash has a unique file name
    StartFileOperation(destPath, action)

end

function StartFileOperation(destPath, action)
    fileActionActiveTotal = #filesToCopy
    fileActionDest = destPath
    -- Clear the path filter (used to change base path if there is a duplicate)
    fileActionPathFilter = nil



    fileAction = action
    fileActionActiveTime = 0
    fileActionDelay = .02
    fileActionCounter = 0
    fileActionBasePath = destPath
    fileCleanup = {}

    if(action == "delete") then
        invalidateTrashIcon = true
        fileActionActive = true
        return
    end

    -- Modify the destPath with the first item for testing
    destPath = destPath.AppendPath(filesToCopy[1].Path:sub( #fileActionSrc.Path + 1))
    fileActionBasePath = destPath

    if(action == "throw out") then
        fileActionPathFilter = UniqueFilePath(destPath)
        invalidateTrashIcon = true
    end

    if(filesToCopy[1].IsChildOf(destPath)) then

        pixelVisionOS:ShowMessageModal(
            "Workspace Path Conflict",
            "Can't perform a file action on a path that is the child of the destination path.",
            128 + 16, false, function() CancelFileActions() end
        )
        return

    elseif(PathExists(destPath) and fileActionPathFilter == nil) then

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

                        fileActionPathFilter = UniqueFilePath(destPath)

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
            "Do you want to ".. action .. " " .. fileActionActiveTotal .. " files?",
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

function OnFileActionNextStep()

    if(#filesToCopy == 0) then
        return
    end

    -- Increment the counter
    fileActionCounter = fileActionCounter + 1

    -- Test to see if the counter is equil to the total
    if(fileActionCounter > fileActionActiveTotal) then

        fileActionDelay = 4
        return
    end

    local srcPath = filesToCopy[fileActionCounter]

    -- -- Look to see if the modal exists
    if(progressModal == nil) then
        --
        --   -- Create the model
        progressModal = ProgressModal:Init("File Action ", editorUI)

        -- Open the modal
        pixelVisionOS:OpenModal(progressModal)

    end

    local message = fileAction .. " "..string.lpad(tostring(fileActionCounter), string.len(tostring(fileActionActiveTotal)), "0") .. " of " .. fileActionActiveTotal .. ".\n\n\nDo not restart or shut down Pixel Vision 8."

    local percent = (fileActionCounter / fileActionActiveTotal)

    progressModal:UpdateMessage(message, percent)

    local destPath = fileAction == "delete" and fileActionDest or NewWorkspacePath(fileActionDest.Path .. srcPath.Path:sub( #fileActionSrc.Path + 1))

    if(fileActionPathFilter ~= nil) then

        destPath = NewWorkspacePath(fileActionPathFilter.Path .. destPath.Path:sub( #fileActionBasePath.Path + 1))

    end

    -- Find the path to the directory being copied
    local dirPath = destPath.IsFile and destPath.ParentPath or destPath

    -- Make sure the directory exists
    if(PathExists(dirPath) == false) then

        CreateDirectory(dirPath)
    end

    if(srcPath.IsFile) then

        TriggerSingleFileAction(srcPath, destPath, fileAction)
    elseif(fileAction ~= "copy") then

        table.insert(fileCleanup, srcPath)
    end

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

function TriggerSingleFileAction(srcPath, destPath, action)

    -- Copy the file to the new location, if a file with the same name exists it will be overwritten
    if(action == "copy") then

        -- Only copy files over since we create the directory in the previous step
        if(destPath.isFile) then
            -- print("CopyTo", srcPath, destPath)
            CopyTo(srcPath, destPath)
        end

    elseif(action == "move" or action == "throw out") then

        -- Need to keep track of directories that listed since we want to clean them up when they are empty at the end
        if(srcPath.IsDirectory) then
            -- print("Save file path", srcPath)
            table.insert(fileCleanup, srcPath)
        else
            MoveTo(srcPath, destPath)
            -- print("MoveTo", srcPath, destPath)
        end

    elseif(action == "delete") then
        if(srcPath.IsDirectory) then
            -- print("Save file path", srcPath)
            table.insert(fileCleanup, srcPath)
        else
            Delete(srcPath)
            -- print("MoveTo", srcPath, destPath)
        end
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

function WorkspaceTool:CancelFileActions()

    if(self.fileActionActive == true) then
        WorkspaceTool:OnFileActionComplete()

        -- editorUI.mouseCursor:SetCursor(1, false)
    end

end

function SafeDelete(srcPath)

    Delete(srcPath)--, trashPath)

end

function OnCopy()

    if(windowIconButtons ~= nil) then

        -- Remove previous files to be copied
        filesToCopy = {}
        fileActionSrc = currentDirectory

        -- TODO this needs to eventually support multiple selections

        local file = CurrentlySelectedFile()

        if(CanCopy(file)) then

            local tmpPath = NewWorkspacePath(file.path)

            -- Test if the path is a directory
            if(tmpPath.IsDirectory) then

                -- Add all of the files that need to be copied to the list
                filesToCopy = GetEntitiesRecursive(tmpPath)

            end

            -- Make sure the selected directory is included
            table.insert(filesToCopy, 1, NewWorkspacePath(file.path))

            -- print("Copy File", file.name, file.path, #filesToCopy, dump(filesToCopy))

            -- Enable the paste shortcut
            pixelVisionOS:EnableMenuItemByName(PasteShortcut, true)

            -- TODO eventually need to change the message to handle multiple files
            pixelVisionOS:DisplayMessage(#filesToCopy .. " file" .. (#filesToCopy == 1 and " has" or "s have") .." been copied.", 2)

        else

            -- Display a message that the file can not be copied
            pixelVisionOS:ShowMessageModal(toolName .. "Error", "'".. file.name .. "' can not be copied.", 160, false)

            -- Make sure we can't activate paste
            pixelVisionOS:EnableMenuItemByName(PasteShortcut, false)

        end

    end

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
    StartFileOperation(destPath, "copy")

    pixelVisionOS:DisplayMessage("Entit" .. (#filesToCopy > 1 and "ies have" or "y has") .. " has been pasted.", 2)

end