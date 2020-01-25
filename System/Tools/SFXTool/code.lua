--[[
	Pixel Vision 8 - SFX Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

-- API Bridge
LoadScript("sb-sprites")
LoadScript("pixel-vision-os-v2")
LoadScript("pixel-vision-os-sound-progress-modal-v1")

local toolName = "Sound Editor"

local success = false
local playSound = false
local originalSounds = {}
local canExport = ProgressModal ~= nil

-- local soundHistory = {}

local knobData = {

  {name = "Volume", x = 40, y = 88, propID = 24, range = 1, toolTip = "Volume is set to "},

  -- Envelope
  {name = "AttackTime", x = 80, y = 88, propID = 2, range = 1, toolTip = "Attack Time is set to ", disabledOffset = 28},
  {name = "SustainTime", x = 104, y = 88, propID = 3, range = 1, toolTip = "Sustain Time is set to ", disabledOffset = 28},
  {name = "SustainPunch", x = 128, y = 88, propID = 4, range = 1, toolTip = "Sustain Punch is set to ", disabledOffset = 28},
  {name = "DecayTime", x = 152, y = 88, propID = 5, range = 1, toolTip = "Decay Time is set to ", disabledOffset = 28},

  -- Frequency
  {name = "StartFrequency", x = 192, y = 88, propID = 6, range = 1, toolTip = "Start Frequency is set to ", disabledOffset = 28},
  {name = "MinFrequency", x = 216, y = 88, propID = 7, range = 1, toolTip = "Minimum Frequency is set to ", disabledOffset = 28},

  -- Slide
  {name = "Slide", x = 16, y = 128, propID = 8, range = 2, toolTip = "Slide is set to "},
  {name = "DeltaSlide", x = 40, y = 128, propID = 9, range = 2, toolTip = "Delta Slide is set to "},

  -- Vibrato
  {name = "VibratoDepth", x = 72, y = 128, propID = 10, range = 1, toolTip = "Vibrato Depth is set to "},
  {name = "VibratoSpeed", x = 96, y = 128, propID = 11, range = 1, toolTip = "Vibrato Speed is set to "},

  -- Harmonics
  {name = "OverTones", x = 128, y = 128, propID = 12, range = 1, toolTip = "Over Tones is set to "},
  {name = "OverTonesFalloff", x = 152, y = 128, propID = 13, range = 1, toolTip = "Over Tones Falloff is set to "},

  -- Square Wave
  {name = "SquareDuty", x = 192, y = 128, propID = 14, range = 1, toolTip = "Square Duty is set to ", disabledOffset = 32},
  {name = "DutySweep", x = 216, y = 128, propID = 15, range = 2, toolTip = "Duty Sweep is set to ", disabledOffset = 32},

  -- Repeat
  {name = "RepeatSpeed", x = 72, y = 168, propID = 16, range = 1, toolTip = "Repeat Speed is set to "},

  -- Phaser
  {name = "PhaserOffset", x = 16, y = 168, propID = 17, range = 2, toolTip = "Phaser Offset is set to "},
  {name = "PhaserSweep", x = 40, y = 168, propID = 18, range = 2, toolTip = "Phaser Sweep is set to "},

  -- LP Filter
  {name = "LPFilterCutoff", x = 104, y = 168, propID = 19, range = 1, toolTip = "LP Filter Cutoff is set to "},
  {name = "LPFilterCutoffSweep", x = 128, y = 168, propID = 20, range = 2, toolTip = "LP Filter Cutoff Sweep is set to "},
  {name = "LPFilterResonance", x = 152, y = 168, propID = 21, range = 1, toolTip = "LP Filter Resonance is set to "},

  -- HP Filter
  {name = HPFilterCutoff, x = 192, y = 168, propID = 22, range = 1, toolTip = "HP Filter Cutoff is set to "},
  {name = HPFilterCutoffSweep, x = 216, y = 168, propID = 23, range = 2, toolTip = "HP Filter Cutoff Sweep is set to "},

}

local sfxButtonData = {
  {name = "pickup", spriteName = "sfxbutton1", x = 8, y = 40, toolTip = "Create a randomized 'pickup' or coin sound effect."},
  {name = "explosion", spriteName = "sfxbutton2", x = 24, y = 40, toolTip = "Create a randomized 'explosion' sound effect."},
  {name = "powerup", spriteName = "sfxbutton3", x = 40, y = 40, toolTip = "Create a randomized 'power-up' sound effect."},
  {name = "shoot", spriteName = "sfxbutton4", x = 56, y = 40, toolTip = "Create a randomized 'laser' or 'shoot' sound effect."},
  {name = "jump", spriteName = "sfxbutton5", x = 72, y = 40, toolTip = "Create a randomized 'jump' sound effect."},
  {name = "hurt", spriteName = "sfxbutton6", x = 88, y = 40, toolTip = "Create a randomized 'hit' or 'hurt' sound effect."},
  {name = "select", spriteName = "sfxbutton7", x = 104, y = 40, toolTip = "Create a randomized 'blip' or 'select' sound effect."},
  {name = "random", spriteName = "sfxbutton8", x = 120, y = 40, toolTip = "Create a completely random sound effect."},
  {name = "melody", spriteName = "instrumentbutton1", x = 8, y = 56, toolTip = "Create a 'melody' instrument sound effect."},
  {name = "harmony", spriteName = "instrumentbutton2", x = 24, y = 56, toolTip = "Create a 'harmony' instrument sound effect."},
  {name = "bass", spriteName = "instrumentbutton3", x = 40, y = 56, toolTip = "Create a 'bass' instrument sound effect."},
  {name = "pad", spriteName = "instrumentbutton4", x = 56, y = 56, toolTip = "Create a 'pad' instrument sound effect."},
  {name = "lead", spriteName = "instrumentbutton5", x = 72, y = 56, toolTip = "Create a 'lead' instrument sound effect."},
  {name = "drums", spriteName = "instrumentbutton6", x = 88, y = 56, toolTip = "Create a 'drums' instrument sound effect."},
  {name = "snare", spriteName = "instrumentbutton7", x = 104, y = 56, toolTip = "Create a 'snare' instrument sound effect."},
  {name = "kick", spriteName = "instrumentbutton8", x = 120, y = 56, toolTip = "Create a 'kick' instrument sound effect."}
}

local waveButtonData = {
  {name = "Template1", spriteName = "wavebutton0", x = 112 - 24, y = 200, waveID = 0, toolTip = "Wave type square."},
  {name = "Template2", spriteName = "wavebutton1", x = 120, y = 200, waveID = 1, toolTip = "Wave type saw."},
  {name = "Template3", spriteName = "wavebutton3", x = 152, y = 200, waveID = 3, toolTip = "Wave type noise."},
  {name = "Template4", spriteName = "wavebutton4", x = 184, y = 200, waveID = 4, toolTip = "Wave type triangle."},
  {name = "Template5", spriteName = "wavebutton5", x = 216, y = 200, waveID = 5, toolTip = "Load wav sample file."},
}


local validWaves = {
  "!\"", -- any
  "%&", -- square
  ":;", -- saw tooth
  -- "'(", -- sine (Not enabled by default)
  ")*", -- noise
  "<=", -- triangle
  "./" -- wave
}

local waveTypeIDs = {
  -1,
  0,
  1,
  -- 2,
  3,
  4,
  5
}

local SaveShortcut, UndoShortcut, RedoShortcut, CopyShortcut, PasteShortcut = 4, 9, 10, 11, 12

local currentID = 0

function InvalidateData()

  -- Only everything if it needs to be
  if(invalid == true)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle .."*", "toolbariconfile")

  pixelVisionOS:EnableMenuItem(SaveShortcut, true)

  invalid = true

end

function ResetDataValidation()

  -- Only everything if it needs to be
  if(invalid == false)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle, "toolbariconfile")
  invalid = false

  pixelVisionOS:EnableMenuItem(SaveShortcut, false)

end

function Init()

  BackgroundColor(22)

  -- Disable the back key in this tool
  EnableBackKey(false)

  -- Create an instance of the Pixel Vision OS
  pixelVisionOS = PixelVisionOS:Init()

  -- Reset the undo history so it's ready for the tool
  pixelVisionOS:ResetUndoHistory()

  -- Get a reference to the Editor UI
  editorUI = pixelVisionOS.editorUI


  rootDirectory = ReadMetadata("directory", nil)

  if(rootDirectory ~= nil) then

    -- Load only the game data we really need
    success = gameEditor.Load(rootDirectory, {SaveFlags.System, SaveFlags.Sounds})

  end

  if(success == true) then

    local pathSplit = string.split(rootDirectory, "/")

    -- Update title with file path
    toolTitle = pathSplit[#pathSplit] .. "/sounds.json"

    -- Get the game name we are editing
    -- pixelVisionOS:ChangeTitle(toolTitle)

    local menuOptions =
    {
      -- About ID 1
      {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName) end, toolTip = "Learn about PV8."},
      {divider = true},
      {name = "New", action = OnNewSound, key = Keys.N, toolTip = "Revert the sound to empty."}, -- Reset all the values
      {name = "Save", action = OnSave, key = Keys.S, toolTip = "Save changes made to the sounds file."}, -- Reset all the values
      {name = "Export SFX", action = function() OnExport(currentID, true) end, key = Keys.E, enabled = canExport, toolTip = "Create a wav for the current SFX file."}, -- Reset all the values
      {name = "Export All", action = OnExportAll, enabled = canExport, toolTip = "Export all sound effects to wavs."}, -- Reset all the values

      {name = "Revert", action = nil, key = Keys.R, enabled = false, toolTip = "Revert the sounds.json file to its previous state."}, -- Reset all the values
      {divider = true},
      {name = "Undo", action = OnUndo, enabled = false, key = Keys.Z, toolTip = "Undo the last action."}, -- Reset all the values
      {name = "Redo", action = OnRedo, enabled = false, key = Keys.Y, toolTip = "Redo the last undo."}, -- Reset all the values
      {name = "Copy", action = OnCopySound, key = Keys.C, toolTip = "Copy the currently selected sound."}, -- Reset all the values
      {name = "Paste", action = OnPasteSound, key = Keys.V, enabled = false, toolTip = "Paste the last copied sound."}, -- Reset all the values
      {name = "Mutate", action = OnMutate, key = Keys.M, toolTip = "Mutate the sound to produce random variations."}, -- Reset all the values
      {divider = true},
      {name = "Quit", key = Keys.Q, action = OnQuit, toolTip = "Quit the current game."}, -- Quit the current game
    }

    if(PathExists(NewWorkspacePath(rootDirectory).AppendFile("code.lua"))) then
      table.insert(menuOptions, #menuOptions, {name = "Run Game", action = OnRunGame, key = Keys.R, toolTip = "Run the code for this game."})
    end

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

    -- Get the total number of songs
    totalSounds = gameEditor:TotalSounds()
    totalChannels = gameEditor:TotalChannels()

    -- TODO need to replace this with the new number stepper component

    local textColorOffset = 52

    soundIDStepper = editorUI:CreateNumberStepper({x = 32, y = 16}, 16, 0, 0, totalSounds - 1, "top", "Sound ID value.", textColorOffset)

    soundIDStepper.onInputAction = OnChangeSoundID

    songNameFieldData = editorUI:CreateInputField({x = 88, y = 24, w = 80}, "Untitled", "Change the label of the selected sound.", "name", nil, textColorOffset)
    songNameFieldData.onAction = OnChangeName

    channelIDStepper = editorUI:CreateNumberStepper({x = 176, y = 16}, 8, - 1, 0, tostring(gameEditor:TotalChannels()) - 1, "top", "The channel sound effects will be previewed on.", textColorOffset)

    channelIDStepper.onInputAction = OnChangeChannelID

    waveInputField = editorUI:CreateInputField({x = 224, y = 24, w = 16}, validWaves[1], "Wave type.", nil, nil, textColorOffset)

    waveInputField.editable = false

    -- Create buttons

    totalKnobs = #knobData

    for i = 1, totalKnobs do

      local data = knobData[i]

      data.knobUI = editorUI:CreateKnob({x = data.x, y = data.y, w = 24, h = 24}, "knob", "Change the volume.")
      data.knobUI.type = data.name

      if(data.disabledOffset ~= nil) then
        data.knobUI.colorOffsetDisabled = data.disabledOffset
      end

      data.knobUI.onAction = function(value)

        local type = data.name
        local propID = data.propID

        -- Calculate new value based on range
        local newValue = (data.range * value) - (data.range - 1)

        UpdateLoadedSFX(propID, newValue)

        UpdateKnobTooltip(data, value)
      end

    end

    totalSFXButtons = #sfxButtonData

    for i = 1, totalSFXButtons do

      local data = sfxButtonData[i]

      -- TODO need to build sprite tables for each state
      data.buttonUI = editorUI:CreateButton({x = data.x, y = data.y}, data.spriteName, data.toolTip)
      data.buttonUI.onAction = function()
        -- print("Click")
        OnSFXAction(data.name)
      end

    end


    waveGroupData = editorUI:CreateToggleGroup(true)
    waveGroupData.onAction = function(value)
      -- print("Select Wave Button", value)
      OnChangeWave(value)
      --TODO refresh wave buttons
      -- TODO save wave data
    end

    totalWaveButtons = #waveButtonData

    for i = 1, totalWaveButtons do

      local data = waveButtonData[i]

      -- TODO need to build sprite tables for each state
      editorUI:ToggleGroupButton(waveGroupData, {x = data.x, y = data.y}, data.spriteName, data.toolTip)

    end


    playButton = editorUI:CreateButton({x = 8, y = 16}, "playbutton", "Play the current sound.")
    playButton.onAction = OnPlaySound


    -- {name = "Play", spriteName = "playbutton", x = 8, y = 16, toolTip = "Play the current sound.", action = function() OnPlaySound() end}
    --
    -- totalControlButtonData = #controlButtonData
    --
    -- for i = 1, totalControlButtonData do
    --
    --   local data = controlButtonData[i]
    --
    --   -- TODO need to build sprite tables for each state
    --   data.buttonUI = editorUI:CreateButton({x = data.x, y = data.y}, data.spriteName, data.toolTip)
    --   data.buttonUI.onAction = data.action
    --
    --   -- TODO need to add support for hit rect since each button is a different size
    --
    -- end

    -- Adjust hit area for the mutate button
    -- controlButtonData[3].hitRect = {x = 5, y = 4, w = 16, h = 16}

    -- Look to see if there is a saved ID

    if(SessionID() == ReadSaveData("sessionID", "") and rootDirectory == ReadSaveData("rootDirectory", "")) then
      currentID = tonumber(ReadSaveData("currentID", "0"))
    end

    editorUI:ChangeNumberStepperValue(channelIDStepper, 0)

    LoadSound(currentID, true, false)

    ResetDataValidation()

    pixelVisionOS:DisplayMessage(toolName..": Create and manage your game's sound effects.", 5)

  else

    -- Patch background when loading fails

    -- Left panel
    DrawRect(104, 24, 88, 8, 0, DrawMode.TilemapCache)

    DrawRect(214, 18, 25, 19, BackgroundColor(), DrawMode.TilemapCache)



    pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

    pixelVisionOS:ShowMessageModal(toolName .. " Error", "The tool could not load without a reference to a file to edit.", 160, false,
      function()
        QuitCurrentTool()
      end
    )

  end

end

local currentChannelType = -1

function OnChangeChannelID(value)

  currentChannelType = gameEditor:ChannelType(tonumber(value))

  -- print("New channel", value, currentChannelType)

  -- local value = tonumber(channelIDInputData.inputField.text)
  --
  -- local type = gameEditor:ChannelType(value)

  -- local wavID = table.indexOf(waveTypeIDs, value)
  local validWaveID = table.indexOf(waveTypeIDs, currentChannelType)

  editorUI:ChangeInputField(waveInputField, validWaves[validWaveID])


  UpdatePlayButton()

  -- UpdateSoundTemplates()



  -- Enable wave buttons based on the channel
  -- for i = 1, totalWaveButtons do
  --   editorUI:Enable(waveGroupData.buttons[i], currentChannelType < 0)
  -- end

end

function UpdatePlayButton()

  local enablePlay = true
  local isWav = gameEditor:IsWav(currentID)

  if(isWav) then --currentChannelType > - 1 or currentChannelType < 5) then
    enablePlay = (currentChannelType < 0 or currentChannelType > 4)
  elseif(currentChannelType == 5) then
    enablePlay = false
  end

  -- Enable play button
  editorUI:Enable(playButton, enablePlay)

end

function UpdateLoadedSFX(propID, value)

  soundData[propID] = tostring(value)

  if(playButton.enabled) then
    playSound = true
  end
  -- OnPlaySound()

end

function OnChangeWave(value)

  currentWaveType = value

  -- if(value == 5) then
  --   EnableKnobs(false)
  -- else
  UpdateLoadedSFX(1, waveButtonData[value].waveID)

  EnableKnobs(value)

  --   EnableKnobs(true)
  -- end

  -- EnableWavePanel(value == 1)

  -- TODO need to

end

function EnableKnobs(waveID)

  -- for i = 2, totalKnobs do
  --   if(knobData[i] ~= nil) then
  --     editorUI:Enable(knobData[i].knobUI, value)
  --   end
  -- end


  -- print("Current Wav", currentWaveType)

  local enableSquarePanel = waveID == 1

  local isWav = gameEditor:IsWav(currentID)

  for i = 2, totalKnobs do

    local tmpKnob = knobData[i]

    editorUI:Enable(tmpKnob.knobUI, isWav == false)

    if(tmpKnob.name == "SquareDuty" or tmpKnob.name == "DutySweep") then
      editorUI:Enable(tmpKnob.knobUI, enableSquarePanel)
    end

  end

  -- Update any panels

  local spriteData = enableSquarePanel == true and squarewavepanelenabled or squarewavepaneldisabled

  if(spriteData ~= nil) then
    DrawSprites(spriteData.spriteIDs, 23, 14, spriteData.width, false, false, DrawMode.Tile)
  end


end

function OnSFXAction(name)

  -- print("OnSFX", name)

  if(name == "pickup") then
    OnSoundTemplatePress(1)
  elseif(name == "explosion") then
    OnSoundTemplatePress(3)
  elseif(name == "powerup") then
    OnSoundTemplatePress(4)
  elseif(name == "shoot") then
    OnSoundTemplatePress(2)
  elseif(name == "jump") then
    OnSoundTemplatePress(6)
  elseif(name == "hurt") then
    OnSoundTemplatePress(5)
  elseif(name == "select") then
    OnSoundTemplatePress(7)
  elseif(name == "random") then
    OnSoundTemplatePress(8)
  elseif(name == "melody") then
    OnInstrumentTemplatePress(1)
  elseif(name == "harmony") then
    OnInstrumentTemplatePress(2)
  elseif(name == "bass") then
    OnInstrumentTemplatePress(3)
  elseif(name == "drums") then
    OnInstrumentTemplatePress(4)
  elseif(name == "lead") then
    OnInstrumentTemplatePress(5)
  elseif(name == "pad") then
    OnInstrumentTemplatePress(6)
  elseif(name == "snare") then
    OnInstrumentTemplatePress(7)
  elseif(name == "kick") then
    OnInstrumentTemplatePress(8)
  end


end

function Update(timeDelta)

  -- Convert timeDelta to a float
  timeDelta = timeDelta / 1000
  
  -- This needs to be the first call to make sure all of the editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- Only update the tool's UI when the modal isn't active
  if(pixelVisionOS:IsModalActive() == false) then
    -- If the tool didn't load, don't display any of the UI
    if(success == false) then
      return
    end

    if(Key(Keys.Space, InputState.Released)) then
      OnPlaySound()
    end

    -- editorUI:UpdateButton(backBtnData)
    -- editorUI:UpdateButton(nextBtnData)

    -- editorUI:Enable(controlButtonData[2].buttonUI, gameEditor:IsChannelPlaying())

    editorUI:UpdateStepper(soundIDStepper)
    editorUI:UpdateStepper(channelIDStepper)

    editorUI:UpdateInputField(waveInputField)
    editorUI:UpdateInputField(songNameFieldData)

    for i = 1, totalKnobs do

      local data = knobData[i].knobUI

      -- TODO go through and make sure the value is correct, then update
      editorUI:UpdateKnob(data)

    end

    for i = 1, totalSFXButtons do

      local data = sfxButtonData[i].buttonUI

      editorUI:UpdateButton(data)

    end

    editorUI:UpdateToggleGroup(waveGroupData)

    -- for i = 1, totalControlButtonData do
    --
    --   local data = playButton

    editorUI:UpdateButton(playButton)

    -- end

    -- TODO this is not working
    -- local playing = gameEditor:IsChannelPlaying(0)
    -- if(playing) then
    --   -- print("Channel Playing", playing)
    -- end

    -- Only play sounds when the mouse is not down
    if(editorUI.collisionManager.mouseDown == false and playSound == true) then
      playSound = false
      ApplySoundChanges()
    end

  end

  if(installing == true) then


    installingTime = installingTime + timeDelta

    if(installingTime > installingDelay) then
      installingTime = 0


      OnInstallNextStep()

      if(installingCounter >= installingTotal) then

        OnInstallComplete()

      end

    end


  end

end

function ApplySoundChanges(autoPlay, saveHistory)

  -- Save sound changes
  local settingsString = ""
  local total = #soundData

  --print("total", total)
  for i = 1, total do
    local value = soundData[i]
    if(value ~= "" or value ~= nil) then
      settingsString = settingsString .. soundData[i]
    end
    if(i < total) then
      settingsString = settingsString .. ","
    end
  end

  local id = CurrentSoundID()
  gameEditor:Sound(id, settingsString)
  InvalidateData()

  if(saveHistory ~= false) then
    UpdateHistory(settingsString)
  end

  if(autoPlay ~= false) then
    OnPlaySound()
  end

end

function UpdateHistory(settingsString)

  local historyAction = {
    sound = settingsString,
    Action = function()
      UpdateSound(settingsString, true, false)
    end
  }

  pixelVisionOS:AddUndoHistory(historyAction)

  UpdateHistoryButtons()

end

-- local historyPos = 1

function OnUndo()

  local action = pixelVisionOS:Undo()

  if(action ~= nil and action.Action ~= nil) then
    action.Action()
  end

  UpdateHistoryButtons()
end

function OnRedo()

  local action = pixelVisionOS:Redo()

  if(action ~= nil and action.Action ~= nil) then
    action.Action()
  end

  UpdateHistoryButtons()
end

-- function OnRestoreSoundHistory(value)
--
--   if(historyPos < 1) then
--     historyPos = 1
--   elseif(historyPos > #soundHistory) then
--     historyPos = #soundHistory
--   end
--
--   UpdateHistoryButtons()
--
-- end

function UpdateHistoryButtons()

  -- TODO need to update the menu buttons

  pixelVisionOS:EnableMenuItem(UndoShortcut, pixelVisionOS:IsUndoable())
  pixelVisionOS:EnableMenuItem(RedoShortcut, pixelVisionOS:IsRedoable())
  -- editorUI:Enable(controlButtonData[4].buttonUI, pixelVisionOS:IsUndoable())
  -- editorUI:Enable(controlButtonData[5].buttonUI, pixelVisionOS:IsRedoable())

end

function Draw()

  -- Copy over the screen buffer
  RedrawDisplay()

  if(gameEditor:IsChannelPlaying()) then

    DrawSprites(powerbuttonon.spriteIDs, 16, 88, powerbuttonon.width)

    -- playButton.selected = gameEditor:IsChannelPlaying()
    -- editorUI:Invalidate(controlButtonData[1])

  end


  pixelVisionOS:Draw()

end

function OnSave()

  -- This will save the system data, the colors and color-map
  gameEditor:Save(rootDirectory, {SaveFlags.System, SaveFlags.Sounds})

  -- Display a message that everything was saved
  pixelVisionOS:DisplayMessage("You're changes have been saved.", 5)

  -- Clear the validation
  ResetDataValidation()

  -- Clear the sound cache
  originalSounds = {}

end

function OnPage(value)
  activePage = activePanel[value]
  activePage:Open()
end

function CurrentSoundID()
  return tonumber(soundIDStepper.inputField.text)
end

function OnSoundTemplatePress(value)

  gameEditor:GenerateSound(CurrentSoundID(), value)

  if(playButton.enabled) then
    gameEditor:PlaySound(CurrentSoundID())
  end

  local id = CurrentSoundID()

  -- Reload the sound data
  LoadSound(id)

  InvalidateData()
end

local playFlag = true
local playDelay = .2
local playTime = 0

function OnPlaySound()

  if(playButton.enabled == false) then
    return
  end
  -- print("Play Sound")
  gameEditor:StopSound()
  gameEditor:PlaySound(CurrentSoundID(), tonumber(channelIDStepper.inputField.text))
end

function OnInstrumentTemplatePress(value)

  local template = nil

  if(value == 1) then
    -- Melody
    template = "0,,.2,,.2,.1266,,,,,,,,,,,,,1,,,,,.5"
  elseif(value == 2) then
    -- Harmony
    template = "0,,.01,,.509,.1266,,,,,,,,.31,,,,,1,,,.1,,.5";
  elseif(value == 3) then
    -- Bass
    template = "4,,.01,,.509,.1266,,,,,,,,.31,,,,,1,,,.1,,1";
  elseif(value == 4) then
    -- Drums
    template = "3,,.01,,.209,.1668,,,,,,,,.31,,,,,.3,,,.1,,.5";
  elseif(value == 5) then
    -- Lead
    template = "4,.6,.01,,.609,.1347,,,,,.2,,,.31,,,,,1,,,.1,,.5";
  elseif(value == 6) then
    -- Pad
    template = "4,.5706,.4763,.0767,.8052,.1266,,,-.002,,.1035,.2062,,,-.0038,.8698,-.0032,,.6377,.1076,,.0221,.0164,.5";
  elseif(value == 7) then
    -- Snare
    template = "3,.032,.11,.6905,.4,.1668,.0412,-.2434,.0259,.1296,.4162,.069,.7284,.5,-.213,.0969,-.1699,.8019,.1452,-.0715,.3,.1509,.9632,.5";
  elseif(value == 8) then
    -- Kick
    template = "4,,.2981,.1079,.1122,.1826,.0583,-.2287,.1341,.3666,.0704,.1626,.2816,.0642,.3733,.2103,-.3137,-.3065,.8693,-.3045,.4969,.0218,-.015,.6";

  end

  if(template ~= nil) then
    UpdateSound(template)
  end

end

function UpdateSound(settings, autoPlay, addToHistory)
  local id = CurrentSoundID()

  gameEditor:Sound(id, settings)

  if(autoPlay ~= false) then
    gameEditor:PlaySound(CurrentSoundID(), tonumber(channelIDStepper.inputField.text))
  end

  -- Reload the sound data
  LoadSound(id, false, addToHistory)


  InvalidateData()

end

function OnChangeSoundID(text)

  -- convert the text value to a number
  local value = tonumber(text)

  -- update buttons
  -- editorUI:Enable(backBtnData, value > soundIDStepper.inputField.min)
  -- editorUI:Enable(nextBtnData, value < soundIDFieldData.inputField.max)

  -- Load the sound into the editor
  LoadSound(value, true, false)

end

function LoadSound(value, clearHistory, updateHistory)
  -- print("Load Sound Clear", clearHistory)
  currentID = value

  local data = gameEditor:Sound(value)

  if(originalSounds[value] == nil) then
    -- Make a copy of the sound
    originalSounds[value] = data
  end

  -- Load the current sounds string data so we can edit it
  soundData = {}

  local tmpValue = ""

  for i = 1, #data do
    local c = data:sub(i, i)

    if(c == ",") then

      table.insert(soundData, tmpValue)
      tmpValue = ""

    else
      tmpValue = tmpValue .. c

    end

  end

  -- Always add the last value since it doesn't end in a comma
  table.insert(soundData, tmpValue)

  Refresh()

  local label = gameEditor:SoundLabel(value)

  editorUI:ChangeInputField(songNameFieldData, label, false)
  editorUI:ChangeNumberStepperValue(soundIDStepper, currentID, false, true)

  if(clearHistory == true) then
    -- Reset the undo history so it's ready for the tool
    pixelVisionOS:ResetUndoHistory()
    UpdateHistoryButtons()
  end

  if(updateHistory ~= false) then
    UpdateHistory(data)
  end





  -- TODO need to refresh the editor panels
end

function Refresh()

  for i = 1, totalKnobs do
    local knob = knobData[i]

    local value = soundData[knob.propID] ~= "" and tonumber(soundData[knob.propID]) or 0

    local percent = ((knob.range - 1) + value) / knob.range

    UpdateKnobTooltip(knob, percent)


    editorUI:ChangeKnob(knob.knobUI, percent, false)

  end

  UpdateSoundTemplates()

  UpdateWaveButtons()

  UpdatePlayButton()

end

function UpdateSoundTemplates()

  -- Loop through template buttons
  totalSFXButtons = #sfxButtonData

  local enabled = true


  if(gameEditor:IsWav(currentID)) then
    enabled = false
  end

  for i = 1, totalSFXButtons do

    local data = sfxButtonData[i].buttonUI
    editorUI:Enable(sfxButtonData[i].buttonUI, enabled)

  end

end

function UpdateKnobTooltip(knobData, value)

  local percentString = string.lpad(tostring(value * 100), 3, "0") .. "%"

  knobData.knobUI.toolTip = knobData.toolTip .. percentString .. "."

end

function UpdateWaveButtons()

  editorUI:ClearGroupSelections(waveGroupData)

  local isWav = gameEditor:IsWav(currentID)
  local tmpID = isWav and 5 or 1
  local waveID = soundData[1]

  for i = 1, totalWaveButtons do

    tmpButton = waveGroupData.buttons[i]

    local enabled = not isWav

    if(i == 5) then
      enabled = isWav
    end

    -- Enable the button
    editorUI:Enable(tmpButton, enabled)

    if(tonumber(waveID) == waveButtonData[i].waveID) then
      tmpID = i
    end

  end

  if(isWav) then
    tmpID = 5
  end

  EnableKnobs(tmpID)

  editorUI:SelectToggleButton(waveGroupData, tmpID, false)

end

local enableSquarePanel = nil

function EnableWavePanel(value)

  -- if(enableSquarePanel == value) then
  --   return
  -- end

  enableSquarePanel = value

  local spriteData = value == true and squarewavepanelenabled or squarewavepaneldisabled

  if(spriteData ~= nil) then
    DrawSprites(spriteData.spriteIDs, 23, 14, spriteData.width, false, false, DrawMode.Tile)
  end

  for i = 1, totalKnobs do

    local tmpKnob = knobData[i]
    if(tmpKnob.name == "SquareDuty" or tmpKnob.name == "DutySweep") then
      editorUI:Enable(tmpKnob.knobUI, value)
    end

  end

end


function OnRevertSound()

  local id = CurrentSoundID()

  if(originalSounds[id] ~= nil) then

    UpdateSound(originalSounds[id])

  end

end

function OnChangeName(value)

  local id = CurrentSoundID()

  local label = gameEditor:SoundLabel(id, value)

  Refresh()

  InvalidateData()

end

function OnNewSound()
  gameEditor:NewSound(CurrentSoundID())

  -- Reload the sound
  LoadSound(CurrentSoundID())

  InvalidateData()
end

local soundClipboard = nil

function OnCopySound()
  local id = CurrentSoundID()

  soundClipboard = {name = songNameFieldData.text, data = gameEditor:Sound(id)}

  pixelVisionOS:DisplayMessage("Sound '".. id .. "' has been copied.", 5)

  pixelVisionOS:EnableMenuItem(PasteShortcut, true)
end

function OnPasteSound()
  local id = CurrentSoundID()
  gameEditor:SoundLabel(id, soundClipboard.name)
  gameEditor:Sound(id, soundClipboard.data)

  pixelVisionOS:DisplayMessage("New data has been pasted into sound '".. id .. "'.", 5)

  LoadSound(id)

  soundClipboard = nil

  InvalidateData()

  OnPlaySound()

  pixelVisionOS:EnableMenuItem(PasteShortcut, false)

end

function OnPlaySound()

  if(playButton.enabled == false) then
    return
  end

  id = CurrentSoundID()

  gameEditor:PlaySound(id, tonumber(channelIDStepper.inputField.text))
end

function OnStopSound()

  gameEditor:StopSound()

end

function OnMutate()
  id = CurrentSoundID()

  gameEditor:Mutate(id)
  gameEditor:PlaySound(id, tonumber(channelIDStepper.inputField.text))

  LoadSound(id)

  InvalidateData()
end

function Shutdown()

  -- Make sure all sounds are stopped before shuttong down
  OnStopSound()

  -- Save the current session ID
  WriteSaveData("sessionID", SessionID())

  WriteSaveData("rootDirectory", rootDirectory)

  -- Make sure we don't save paths in the tmp directory
  WriteSaveData("currentID", currentID)

end

function OnQuit()

  if(invalid == true) then

    pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have unsaved changes. Do you want to save your work before you quit?", 160, true,
      function()
        if(pixelVisionOS.messageModal.selectionValue == true) then
          -- Save changes
          OnSave()

        end

        -- Quit the tool
        QuitCurrentTool()

      end
    )

  else
    -- Quit the tool
    QuitCurrentTool()
  end

end

function OnRunGame()
  -- TODO should this ask to launch the game first?

  if(invalid == true) then

    pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have unsaved changes. You will lose those changes if you run the game now?", 160, true,
      function()
        if(pixelVisionOS.messageModal.selectionValue == true) then
          LoadGame(NewWorkspacePath(rootDirectory))
        end

      end
    )

  else

    LoadGame(NewWorkspacePath(rootDirectory))

  end

end
