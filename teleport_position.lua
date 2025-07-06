-- teleport-position.lua
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

-- The target CFrame (position + rotation)
local targetCFrame = CFrame.new(
    -44.893211,
    1049.128174,
    113.800880, -- Position (X, Y, Z)
    0.148912,
    0,
    -0.988850, -- Rotation row 1
    -0,
    1,
    0, -- Rotation row 2
    0.988850,
    0,
    0.148912 -- Rotation row 3
)

-- Wait for character and teleport
if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
    LocalPlayer.CharacterAdded:Wait()
    repeat
        task.wait()
    until LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
end

LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
print('Teleported to position')