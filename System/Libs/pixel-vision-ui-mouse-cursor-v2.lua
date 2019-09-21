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

MouseCursor = {}
MouseCursor.__index = MouseCursor

-- TODO this should be set up like all of the other UI components and not its own object
function MouseCursor:Init()

  -- Create a new object for the instance and register it
  local _mouseCursor = {}
  setmetatable(_mouseCursor, MouseCursor)

  -- This defines which set of data to use when drawing the cursor
  _mouseCursor.cursorID = -1

  _mouseCursor.animationTime = 0
  _mouseCursor.animationDelay = .2
  _mouseCursor.animationFrame = 0

  _mouseCursor.lock = false

  -- Reference data for each of the different mouse cursors
  _mouseCursor.cursors = {
    -- Pointer
    {
      spriteData = cursorpointer,
      offset = {
        x = 0,
        y = -1
      }
    },
    -- Hand (for interaction)
    {
      spriteData = cursorhand,
      offset = {
        x = -6,
        y = -1
      }
    },
    -- Input
    {
      spriteData = cursortext,
      offset = {
        x = -4,
        y = -10
      }
    },

    -- Help (for showing tool tips)
    {
      spriteData = cursorhelp,
      offset = {
        x = -2,
        y = -3
      }
    },
    -- Wait
    {
      spriteData = cursorwait1,
      offset = {
        x = -2,
        y = -3
      },
      animated = true,
      frames = 10,
      spriteName = "cursorwait"
    },
    -- Pencil
    {
      spriteData = cursorpen,
      offset = {
        x = 0,
        y = -15
      }
    },
    -- Eraser
    {
      spriteData = cursoreraser,
      offset = {
        x = 0,
        y = -15
      }
    },
    -- Cross
    {
      spriteData = cursorcross,
      offset = {
        x = -8,
        y = -8
      }
    },
  }

  _mouseCursor.pos = {x = -1, y = -1}

  _mouseCursor:SetCursor(1)
  -- Return the new instance of the editor ui
  return _mouseCursor

end

function MouseCursor:Update(timeDelta, collisionState)

  -- Get the collision state's mouse cursor values
  --self.cursorID = collisionState.cursorID

  -- save the current mouse position
  self.pos.x = collisionState.mousePos.x
  self.pos.y = collisionState.mousePos.y

  if(self.cursorData ~= nil and self.cursorData.animated == true) then

    self.animationTime = self.animationTime + timeDelta

    if(self.animationTime > self.animationDelay) then

      self.animationTime = 0
      self.animationFrame = Repeat(self.animationFrame, self.cursorData.frames - 1) + 1

      self.cursorData.spriteData = _G[self.cursorData.spriteName .. tostring(self.animationFrame)]

    end

  end

  if(cursorID == 5) then


  end

end

function MouseCursor:Draw()

  -- Need to make sure the mouse is not off screen before drawing it
  if(self.pos.x < 0 or self.pos.y < 0) then
    return
  end

  -- Make sure the data isn't undefined
  if(self.cursorData ~= nil) then

    local spriteData = self.cursorData.spriteData

    if(self.cursorID == 2 and MouseButton(0)) then
      spriteData = cursorhanddown
    end

    if(spriteData ~= nil) then

      -- Draw the new cursor taking into account the cursors offset
      DrawSprites(spriteData.spriteIDs, self.pos.x + self.cursorData.offset.x, self.pos.y + self.cursorData.offset.y, spriteData.width, false, false, DrawMode.SpriteAbove, 0, true, false)

    end

  end

end

function MouseCursor:SetCursor(id, lock)

  -- Check for unlock flag
  if(lock == false) then
    self.lock = false
  end

  if(self.cursorID ~= id and self.lock ~= true) then

    self.lock = lock

    self.cursorID = id

    self.animationTime = 0
    self.animationFrame = 1

    -- get the current sprite data for the current cursor
    self.cursorData = self.cursors[self.cursorID]

  end

end
