local files = {}
local totalFiles = 0
local nextFile = 0
local destPath = nil
local action = nil
local fileCleanup = {}

function CalculateSteps()

    -- Get the destination path
    destPath = NewWorkspacePath(_G["args"][1])
    table.remove(_G["args"], 1)

    -- Get the action
    action = _G["args"][1]
    table.remove(_G["args"], 1)
    
    -- Loop through the rest of the arguments to get the files
    for i = 1, #_G["args"] do

        -- Convert the string to a path
        local path = NewWorkspacePath(_G["args"][i])

        -- Make sure that the file exists
        if(PathExists(path)) then
            
            -- Add the file to the list
            table.insert(files, path)

            -- Add a new file action step
            AddStep("SingleFileAction")

        end
        
    end

    -- Get the total files
    totalFiles = #files

    -- Make sure there are files to work with
    if(totalFiles > 0) then

        -- Set the next file to the first index
        nextFile = 1

        -- After all of the above steps are complete we'll clean up everything
        AddStep("CleanUpFiles")

    end

end


function SingleFileAction()

    local srcPath = files[nextFile]

    print("TriggerSingleFileAction", srcPath, destPath, action)


    if(PathExists(srcPath) == false) then
        return
    end

    
    -- Find the path to the directory being copied
    local dirPath = destPath.IsFile and destPath.ParentPath or destPath

    -- Make sure the directory exists
    if(PathExists(dirPath) == false) then

        CreateDirectory(dirPath)

    end

    if(srcPath.IsFile) then

        -- Copy the file to the new location, if a file with the same name exists it will be overwritten
        if(action == "copy") then

            -- Only copy files over since we create the directory in the previous step
            if(destPath.isFile) then
                CopyTo(srcPath, destPath)
                -- print(action, srcPath, destPath)

            end

        elseif(action == "move" or action == "throw out") then

            print(action, srcPath, destPath)

            -- Need to keep track of directories that listed since we want to clean them up when they are empty at the end
            if(srcPath.IsDirectory) then
                table.insert(fileCleanup, srcPath)
            else
                MoveTo(srcPath, destPath)
            end

        elseif(action == "delete") then

            print(action, srcPath, destPath)
            
            if(srcPath.IsDirectory) then
                table.insert(fileCleanup, srcPath)
            else
                Delete(srcPath)
            end

        end

    elseif(self.fileAction ~= "copy") then

        table.insert(fileCleanup, srcPath)
    end
    -- Move to the next file ID
    nextFile = nextFile + 1

end

function CleanUpFiles()

    if(fileCleanup ~= nil) then

        -- TODO perform any cleanup after moving
        for i = 1, #fileCleanup do
            local path = fileCleanup[i]
            print("Cleanup", path)
            if(PathExists(path)) then
                Delete(path)
            end

        end

    end

end


-- function WorkspaceTool:StartFileOperation(destPath, action)
    
--     print("StartFileOperation")

--     self.fileActionActiveTotal = #self.filesToCopy
--     self.fileActionDest = destPath

--     -- Clear the path filter (used to change base path if there is a duplicate)
--     self.fileActionPathFilter = nil

--     self.fileAction = action
--     self.fileActionActiveTime = 0
--     self.fileActionDelay = .02
--     self.fileActionCounter = 0
--     self.fileActionBasePath = destPath
--     fileCleanup = {}

    

--     if(action == "delete") then
--         invalidateTrashIcon = true
--         self.fileActionActive = true
--         return
--     end

--     -- Modify the destPath with the first item for testing
--     destPath = destPath.AppendPath(self.filesToCopy[1].Path:sub( #self.fileActionSrc.Path + 1))
--     self.fileActionBasePath = destPath

--     if(action == "throw out") then
--         self.fileActionPathFilter = UniqueFilePath(destPath)
--         invalidateTrashIcon = true
--     end

--     if(self.filesToCopy[1].IsChildOf(destPath)) then

--         pixelVisionOS:ShowMessageModal(
--             "Workspace Path Conflict",
--             "Can't perform a file action on a path that is the child of the destination path.",
--             128 + 16, false, function() self:CancelFileActions() end
--         )
--         return

--     elseif(PathExists(destPath) and self.fileActionPathFilter == nil) then

--         local duplicate = destPath.Path == self.filesToCopy[1].Path

--         -- Ask if the file first item should be duplicated
--         pixelVisionOS:ShowMessageModal(
--             "Workspace Path Conflict",
--             "Looks like there is an existing file with the same name in '".. destPath.Path .. "'. Do you want to " .. (duplicate and "duplicate" or "replace") .. " '"..destPath.EntityName.."'?",
--             200,
--             true,
--             function()

--                 -- Only perform the copy if the user selects OK from the modal
--                 if(pixelVisionOS.messageModal.selectionValue) then

--                     if(duplicate == true) then

--                         self.fileActionPathFilter = UniqueFilePath(destPath)

--                     else
--                         -- print("Delete", destPath)
--                         SafeDelete(destPath)
--                     end
--                     -- Start the file action process
--                     fileActionActive = true

--                 else
--                     self:CancelFileActions()
--                     RefreshWindow()
--                 end

--             end
--         )

--     else

--         pixelVisionOS:ShowMessageModal(
--             "Workspace ".. action .." Action",
--             "Do you want to ".. action .. " " .. self.fileActionActiveTotal .. " files?",
--             160,
--             true,
--             function()

--                 -- -- Only perform the copy if the user selects OK from the modal
--                 if(pixelVisionOS.messageModal.selectionValue) then

--                     -- Start the file action process
--                     self.fileActionActive = true

--                     -- Registere the file action update function with the tool so it updates
--                     self:RegisterUI({name = "FileAction"}, "FileActionUpdate", self)

--                 else
--                     self:CancelFileActions()
--                     -- self:RefreshWindow(true)
--                 end

--             end
--         )

--     end

-- end

-- function WorkspaceTool:FileActionUpdate()

--     print("File Action Update", self.fileActionActive)
--     if(self.fileActionActive == true) then

--         self.fileActionActiveTime = self.fileActionActiveTime + editorUI.timeDelta

--         if(self.fileActionActiveTime > self.fileActionDelay) then
--             self.fileActionActiveTime = 0

--             self:OnFileActionNextStep()

--             if(self.fileActionCounter >= self.fileActionActiveTotal) then

--                 self:OnFileActionComplete()

--             end

--         end


--     end

-- end

-- function WorkspaceTool:OnFileActionNextStep()

--     if(#self.filesToCopy == 0) then
--         return
--     end

--     print("OnFileActionNextStep")

--     -- Increment the counter
--     self.fileActionCounter = self.fileActionCounter + 1

--     -- Test to see if the counter is equil to the total
--     if(self.fileActionCounter > self.fileActionActiveTotal) then

--         self.fileActionDelay = 4
--         return
--     end

--     local srcPath = self.filesToCopy[self.fileActionCounter]

--     -- -- Look to see if the modal exists
--     if(self.progressModal == nil) then
--         --
--         --   -- Create the model
--         self.progressModal = ProgressModal:Init("File Action ", editorUI, function() self:CancelFileActions() end)

--         -- Open the modal
--         pixelVisionOS:OpenModal(self.progressModal)

--     end
    
--     local message = self.fileAction .. " "..string.lpad(tostring(self.fileActionCounter), string.len(tostring(self.fileActionActiveTotal)), "0") .. " of " .. self.fileActionActiveTotal .. ".\n\n\nDo not restart or shut down Pixel Vision 8."

--     local percent = (self.fileActionCounter / self.fileActionActiveTotal)

--     self.progressModal:UpdateMessage(message, percent)

--     local destPath = self.fileAction == "delete" and self.fileActionDest or NewWorkspacePath(self.fileActionDest.Path .. srcPath.Path:sub( #self.fileActionSrc.Path + 1))

--     if(self.fileActionPathFilter ~= nil) then

--         destPath = NewWorkspacePath(self.fileActionPathFilter.Path .. destPath.Path:sub( #self.fileActionBasePath.Path + 1))

--     end

--     -- Find the path to the directory being copied
--     local dirPath = destPath.IsFile and destPath.ParentPath or destPath

--     -- Make sure the directory exists
--     if(PathExists(dirPath) == false) then

--         CreateDirectory(dirPath)
--     end

--     if(srcPath.IsFile) then

--         self:TriggerSingleFileAction(srcPath, destPath, self.fileAction)

--     elseif(self.fileAction ~= "copy") then

--         table.insert(fileCleanup, srcPath)
--     end

-- end

-- function WorkspaceTool:OnFileActionComplete()

--     print("OnFileActionComplete")

--     if(fileCleanup ~= nil) then

--         -- TODO perform any cleanup after moving
--         for i = 1, #fileCleanup do
--             local path = fileCleanup[i]

--             if(PathExists(path)) then
--                 Delete(path)
--             end

--         end

--     end

--     -- Turn off the file action loop
--     self.fileActionActive = false

--     -- Remove the file action update from the UI loop
--     self:RemoveUI("FileAction")

--     print("File action done")

--     -- Close the modal
--     pixelVisionOS:CloseModal()

--     -- Destroy the progress modal
--     self.progressModal = nil

--     -- Clear files to copy list
--     self.filesToCopy = nil

--     -- if(self.invalidateTrashIcon == true) then
--     --     self:RebuildDesktopIcons()
--     --     self.invalidateTrashIcon = false
--     -- end

--     -- Refresh the window
--     self:RefreshWindow(true)

-- end

-- function WorkspaceTool:TriggerSingleFileAction(srcPath, destPath, action)

--     print("TriggerSingleFileAction", action)

--     -- Copy the file to the new location, if a file with the same name exists it will be overwritten
--     if(action == "copy") then

--         -- Only copy files over since we create the directory in the previous step
--         if(destPath.isFile) then
--             -- print("CopyTo", srcPath, destPath)
--             CopyTo(srcPath, destPath)
--         end

--     elseif(action == "move" or action == "throw out") then

--         -- Need to keep track of directories that listed since we want to clean them up when they are empty at the end
--         if(srcPath.IsDirectory) then
--             -- print("Save file path", srcPath)
--             table.insert(fileCleanup, srcPath)
--         else
--             MoveTo(srcPath, destPath)
--             -- print("MoveTo", srcPath, destPath)
--         end

--     elseif(action == "delete") then
--         if(srcPath.IsDirectory) then
--             -- print("Save file path", srcPath)
--             table.insert(fileCleanup, srcPath)
--         else
--             Delete(srcPath)
--             -- print("MoveTo", srcPath, destPath)
--         end
--     else
--         -- nothing happened so exit before we refresh the window
--         return
--     end

-- end