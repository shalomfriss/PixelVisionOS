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

local pixelVisionOS = nil
local editorUI = nil

local toolName = "PV8 Tool Template"

-- This this is an empty game, we will the following text. We combined two sets of fonts into
-- the default.font.png. Use uppercase for larger characters and lowercase for a smaller one.
local title = "EMPTY PV8 TOOL"
local messageTxt = "This is an empty tool template. Press Ctrl + 1 to open the editor or modify the files found in your workspace game folder."

-- Container for horizontal slider data
local hSliderData = nil
local vSliderData = nil
local backBtnData = nil
local nextBtnData = nil
local muteBtnData = nil
local paginationBtnData = nil
local volumeInputData = nil
local nameInputData = nil
local pickerInputData = nil

-- The Init() method is part of the game's lifecycle and called a game starts. We are going to
-- use this method to configure background color, ScreenBufferChip and draw a text box.
function Init()

  BackgroundColor(5)

  -- Create an instance of the Pixel Vision OS
  pixelVisionOS = PixelVisionOS:Init()

  -- Get a reference to the Editor UI
  editorUI = pixelVisionOS.editorUI

  local menuOptions = 
  {
    {name = "About", key = Keys.A, action = nil, toolTip = "Learn about PV8."}, -- Should show a modal
    {name = "Reset", action = nil, divider = true, toolTip = "Reset the default value."}, -- Reset all the values
    {name = "Quit", key = Keys.Q, action = OnMenuQuit, toolTip = "Quit the current game."} -- Quit the current game
  }

  -- pixelVisionOS:CreateMenu(menuOptions, "See menu options for this tool.")

  -- Change the title
  pixelVisionOS:ChangeTitle(toolName)
  --
  -- -- TODO this text should use the EditorUI Text component
  --
  titleData = editorUI:CreateText({x = 8, y = 32}, title, "large", 15)

  -- Change the title
  pixelVisionOS:ChangeTitle(toolName)
  --
  -- -- TODO this text should use the EditorUI Text component
  --
  titleData = editorUI:CreateText({x = 8, y = 32}, title, "large", 15)

  -- Let's draw the title into the tilemap
  -- DrawText(title, 1, 4, DrawMode.Tile, "large", 15)

  -- We are going to render the message in a box as tiles.
  messageData = editorUI:CreateText({x = 8, y = 48, w = 240}, messageTxt, "large", 15)

  -- Configure hSlider
  hSliderData = editorUI:CreateSlider({x = 8, y = 107, w = 112, h = 16}, "hsliderhandle", "This is a horizontal slider.", true)
  hSliderData.onAction = OnValueChange

  vSliderData = editorUI:CreateSlider({x = 235, y = 104, w = 16, h = 72}, "vsliderhandle", "This is a vertical slider")
  vSliderData.onAction = OnValueChange

  knobData = editorUI:CreateKnob({x = 208, y = 104, w = 24, h = 24}, "knob", "This is a knob")
  knobData.onAction = OnValueChange

  -- Buttons
  backBtnData = editorUI:CreateButton({x = 200, y = 184}, "stepperback", "This is the picker back button.")
  backBtnData.onAction = OnPickerBack

  nextBtnData = editorUI:CreateButton({x = 224, y = 184}, "steppernext", "This is the picker next button.")
  nextBtnData.onAction = OnPickerNext

  -- Toggle Button
  muteBtnData = editorUI:CreateToggleButton({x = 168, y = 104}, "mute", "This is a toggle button.")
  muteBtnData.hitRect = {x = 168 + 2, y = 104 + 4, w = 28, h = 15}
  muteBtnData.onAction = OnMute

  -- Create a toggle group for the pagination buttons
  paginationBtnData = editorUI:CreateToggleGroup()
  paginationBtnData.onAction = OnPage

  --
  -- Create pagination buttons
  for i = 1, 4 do
    local offsetX = ((i - 1) * 8) + 40
    local rect = {x = offsetX, y = 168, w = 8, h = 16}
    editorUI:ToggleGroupButton(paginationBtnData, rect, "pagebutton" .. tostring(i), "This is page button " .. tostring(i))
  end

  editorUI:SelectToggleButton(paginationBtnData, 1, false)

  -- Input fields
  volumeInputData = editorUI:CreateInputField({x = 136, y = 112, w = 24}, "0", "The volume is set to %02s. Click to edit it.", "number")
  volumeInputData.min = 0
  volumeInputData.max = 100
  volumeInputData.onAction = OnVolumeFieldUpdate

  nameInputData = editorUI:CreateInputField({x = 16, y = 192, w = 11 * 8}, "Untitled", "Enter in a file name to this string input field.", "file")

  pickerInputData = editorUI:CreateInputField({x = 216, y = 192, w = 8}, "0", "You are on page %s of 9. Enter new page number.", "number")
  pickerInputData.min = 1
  pickerInputData.max = 9
  pickerInputData.onAction = UpdatePickerButtons

  editorUI:ChangeInputField(pickerInputData, 1)

  -- TODO this is broken, need to add back in the height to make it multi-line and turn on wrapping
  inputAreaData = editorUI:CreateInputArea({x = 16, y = 136, w = 208, h = 32}, "Lorem ipsum dolor sit amet\n, consectetur adipiscing elit. \nVivamus ultricies nunc ex, \nid commodo mauris iaculis nec.", "Text editor help")

  -- inputAreaData.wrap = true
  inputAreaData.editable = true
  -- inputAreaData.colorOffset = 32


  -- Check boxes
  checkboxGroupData = editorUI:CreateToggleGroup(false)
  checkboxGroupData.onAction = OnCheckbox

  editorUI:ToggleGroupButton(checkboxGroupData, {x = 120, y = 184, w = 8, h = 8}, "checkbox", "This is checkbox 1.")
  editorUI:ToggleGroupButton(checkboxGroupData, {x = 120, y = 192, w = 8, h = 8}, "checkbox", "This is checkbox 2.")

  radioButtonGroupData = editorUI:CreateToggleGroup(true)
  radioButtonGroupData.onAction = OnRadioButton

  editorUI:ToggleGroupButton(radioButtonGroupData, {x = 160, y = 184, w = 8, h = 8}, "radiobutton", "This is radio button 1.")
  editorUI:ToggleGroupButton(radioButtonGroupData, {x = 160, y = 192, w = 8, h = 8}, "radiobutton", "This is radio button 2.")


end

function OnMenuQuit()

  QuitCurrentTool()

end

function OnVolumeFieldUpdate(text)

  local value = tonumber(text / 100)

  editorUI:ChangeSlider(hSliderData, value, false)
  editorUI:ChangeSlider(vSliderData, value, false)
  editorUI:ChangeKnob(knobData, value, false)

end

function OnAction()
  pixelVisionOS:DisplayMessage("The 'Button' was pressed")
end

function OnTwoStepAction()

  pixelVisionOS:EnableActionButton(2, false)

  pixelVisionOS:DisplayMessage("The 'Two Step' button was disabled")

  pixelVisionOS:RemoveActionButton(3)

end

function OnDisabledAction()
  pixelVisionOS:DisplayMessage("Shouldn't be able to click on disabled buttons")
end

function OnValueChange(value)
  --print("New value", value)

  editorUI:ChangeInputField(volumeInputData, tostring(value * 100))

  if(hSliderData.value ~= value) then

    editorUI:ChangeSlider(hSliderData, value)

  end

  if(vSliderData.value ~= value) then

    editorUI:ChangeSlider(vSliderData, value)

  end

  if(knobData.value ~= value) then

    editorUI:ChangeKnob(knobData, value)

  end

end

function OnPickerBack()
  local value = tonumber(pickerInputData.text)
  OnPageChange(value - 1)

end

function OnPickerNext()
  local value = tonumber(pickerInputData.text)
  OnPageChange(value + 1)
end

function OnPageChange(value)

  if(value < pickerInputData.min) then
    value = pickerInputData.min

  elseif(value > pickerInputData.max) then
    value = pickerInputData.max
  end

  local stringValue = tostring(value)

  if(pickerInputData.text ~= stringValue) then
    editorUI:ChangeInputField(pickerInputData, stringValue)
  end

  -- UpdatePickerButtons(stringValue)

end

function OnCheckbox(value)

  local selections = editorUI:ToggleGroupSelections(checkboxGroupData)
  local total = #selections

  local message = "There are now " .. total .. " selected checkboxes"

  if(total > 0) then
    message = message .. ": " .. table.concat(selections, ",")

  end
  pixelVisionOS:DisplayMessage(message ..".")

end



function OnRadioButton(value)

  local message = "Radio Button " .. value .. " was selected."

  pixelVisionOS:DisplayMessage(message ..".")

end

function UpdatePickerButtons(text)

  if(text == "") then
    text = "0"
  end
  -- convert the text value to a number
  local value = tonumber(text)

  -- update buttons
  editorUI:Enable(backBtnData, value > pickerInputData.min)
  editorUI:Enable(nextBtnData, value < pickerInputData.max)

end

function OnMute(value)
  -- Enable or disable the volume input field and sliders based on the mute value
  editorUI:Enable(volumeInputData, not value)
  editorUI:Enable(hSliderData, not value)
  editorUI:Enable(vSliderData, not value)
  editorUI:Enable(knobData, not value)
end

function OnPage(value)
  pixelVisionOS:DisplayMessage("Page " .. value .. " selected")
end

-- The Update() method is part of the game's life cycle. The engine calls Update() on every frame
-- before the Draw() method. It accepts one argument, timeDelta, which is the difference in
-- milliseconds since the last frame.
function Update(timeDelta)

  -- This needs to be the first call to make sure all of the OS and editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- Update Text
  editorUI:UpdateText(titleData)
  editorUI:UpdateText(messageData)

  -- Update Slider
  editorUI:UpdateSlider(hSliderData)
  editorUI:UpdateSlider(vSliderData)
  editorUI:UpdateKnob(knobData)

  -- Update buttons
  editorUI:UpdateButton(backBtnData)
  editorUI:UpdateButton(nextBtnData)
  editorUI:UpdateButton(muteBtnData)

  -- Update toggle groups
  editorUI:UpdateToggleGroup(paginationBtnData)
  editorUI:UpdateToggleGroup(checkboxGroupData)
  editorUI:UpdateToggleGroup(radioButtonGroupData)

  -- Input fields
  editorUI:UpdateInputField(volumeInputData)
  editorUI:UpdateInputField(nameInputData)
  editorUI:UpdateInputField(pickerInputData)

  -- Input Area
  editorUI:UpdateInputArea(inputAreaData)

end

-- The Draw() method is part of the game's life cycle. It is called after Update() and is where
-- all of our draw calls should go. We'll be using this to render sprites to the display.
function Draw()

  -- We can use the RedrawDisplay() method to clear the screen and redraw the tilemap in a
  -- single call.
  RedrawDisplay()

  -- The UI should be the last thing to draw after your own custom draw calls
  pixelVisionOS:Draw()

end
