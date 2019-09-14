function EditorUI:CreateTextButtonSprites(spriteName, text, buttonSize, buttonOffset)

  -- Set the base offset for the button's color palette
  local colorOffset = 0

  -- Define the states we need to generate sprites for
  local states = {"disabled", "up", "over"}

  -- Loop through each of the states
  for i = 1, #states do

    -- Create a global sprite
    _G[spriteName .. state[i]] = self:BuildTextButtonSprite(text, buttonSize, buttonOffset)

  end

end

function EditorUI:BuildTextButtonSprite(text, buttonSize, buttonOffset, colorOffset)



end
