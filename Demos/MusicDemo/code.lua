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
-- Christer Kaitila - @McFunkypants
-- Pedro Medeiros - @saint11
-- Shawn Rakowski - @shwany
--

local startMessage = "Press any button to play!"
local stopMessage = "Press any button to stop!"

function Init()

  -- display instruction text for playing thesound
  DrawText("Music Demo", 1, 1, DrawMode.Tile, "large", 15)
  DrawText(startMessage, 1, 4, DrawMode.Tile, "large", 15)

  --apiBridge:LoadSong(0)
end

function Update()
  -- get if the mouse is down
  local mouseDown = MouseButton(0, InputState.Released)

  -- Get the current song data table
  local songData = SongData()
  local playing = songData["playing"] == 1

  -- if mouse is down, play the first sound sfx
  if(mouseDown == true) then

    if(playing) then
      StopSong()
      DrawText(startMessage, 1, 4, DrawMode.Tile, "large", 15)
    else
      -- play the first sound id in the first channel
      PlayPatterns({0, 1, 2, 3, 4}, true)
      DrawText(stopMessage, 1, 4, DrawMode.Tile, "large", 15)
    end

  end

  -- See if the song is playing
  if(playing) then

    -- Pull out each of the values and format them

    DrawText("Loop " .. tostring(songData["loop"] == 1), 8, 256 - 32 - 16, DrawMode.Sprite, "large", 15)

    -- Draw the values to the screen
    DrawText("Pattern " .. (songData["pattern"] + 1) .. "/" .. songData["patterns"], 8, 256 - 32 - 8, DrawMode.Sprite, "large", 15)

    DrawText("Note " .. string.format("%02d", tostring(songData["note"])) .. "/" .. songData["notes"], 8, 256 - 32, DrawMode.Sprite, "large", 15)

  end

end

function Draw()
  Clear()
  DrawTilemap()
end
