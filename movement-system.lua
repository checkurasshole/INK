-- movement-system.lua
return function(MainTab)
    local Players = game:GetService('Players')
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService('RunService')
    local UserInputService = game:GetService('UserInputService')
    
    -- Initialize global handlers if not exist
    if not _G.CharacterRespawnHandlers then
        _G.CharacterRespawnHandlers = {}
    end
    
    -- Movement variables
    local noclipEnabled = false
    local noclipConnection
    local infiniteJumpEnabled = false
    local infiniteJumpConnection
    local walkflinging = false
    local walkflingConnection = nil
    local walkSpeedLoop = nil
    
    -- Helper function to get root part
    local function getRoot(character)
        return character:FindFirstChild('HumanoidRootPart')
            or character:FindFirstChild('Torso')
            or character:FindFirstChild('UpperTorso')
    end
    
    -- Noclip Toggle
    MainTab:CreateToggle({
        Name = 'Noclip',
        CurrentValue = false,
        Flag = 'NoclipToggle',
        Callback = function(Value)
            noclipEnabled = Value
    
            if noclipEnabled then
                noclipConnection = RunService.Stepped:Connect(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
                        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                            if part:IsA('BasePart') then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            else
                if noclipConnection then
                    noclipConnection:Disconnect()
                end
                if LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                        if part:IsA('BasePart') then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end,
    })
    
    -- Infinite Jump Toggle
    MainTab:CreateToggle({
        Name = 'Infinite Jump',
        CurrentValue = false,
        Flag = 'InfiniteJumpToggle',
        Callback = function(Value)
            infiniteJumpEnabled = Value
    
            if infiniteJumpEnabled then
                infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid') then
                        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            else
                if infiniteJumpConnection then
                    infiniteJumpConnection:Disconnect()
                end
            end
        end,
    })
    
    -- Walk Fling Toggle
    MainTab:CreateToggle({
        Name = 'Walk Fling',
        CurrentValue = false,
        Flag = 'WalkFlingToggle',
        Callback = function(Value)
            if Value then
                walkflinging = false
                local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
                if humanoid then
                    humanoid.Died:Connect(function()
                        walkflinging = false
                    end)
                end
    
                walkflinging = true
                walkflingConnection = RunService.Heartbeat:Connect(function()
                    if not walkflinging then return end
    
                    local character = LocalPlayer.Character
                    local root = getRoot(character)
    
                    if not (character and character.Parent and root and root.Parent) then
                        return
                    end
    
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA('BasePart') and part ~= root then
                            part.CanCollide = true
                        end
                    end
    
                    local vel = root.Velocity
                    local movel = 0.1
                    local newVel = vel * 10000 + Vector3.new(0, math.max(vel.Y * 1000, -30000), 0)
                    root.Velocity = newVel
    
                    RunService.RenderStepped:Wait()
    
                    if character and character.Parent and root and root.Parent then
                        root.Velocity = Vector3.new(vel.X, math.max(vel.Y + movel, -50), vel.Z)
                        movel = movel * -1
                    end
                end)
            else
                walkflinging = false
                if walkflingConnection then
                    walkflingConnection:Disconnect()
                    walkflingConnection = nil
                end
            end
        end,
    })
    
    -- Walk Speed Slider
    MainTab:CreateSlider({
        Name = 'Walk Speed',
        Range = { 0, 200 },
        Increment = 1,
        CurrentValue = 16,
        Flag = 'WalkSpeedSlider',
        Callback = function(Value)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid') then
                LocalPlayer.Character.Humanoid.WalkSpeed = Value
            end
    
            if walkSpeedLoop then
                walkSpeedLoop:Disconnect()
            end
    
            walkSpeedLoop = RunService.Heartbeat:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid') then
                    LocalPlayer.Character.Humanoid.WalkSpeed = Value
                end
            end)
        end,
    })
    
    -- Jump Power Slider
    MainTab:CreateSlider({
        Name = 'Jump Power',
        Range = { 0, 200 },
        Increment = 1,
        CurrentValue = 50,
        Flag = 'JumpPowerSlider',
        Callback = function(Value)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid') then
                LocalPlayer.Character.Humanoid.JumpPower = Value
            end
        end,
    })
    
    -- Character respawn handler
    local function onCharacterRespawn(character)
        character:WaitForChild('Humanoid')
        
        -- Reapply walkspeed
        if Rayfield.Flags.WalkSpeedSlider then
            local walkSpeedValue = Rayfield.Flags.WalkSpeedSlider.CurrentValue
            character.Humanoid.WalkSpeed = walkSpeedValue
            
            if walkSpeedLoop then
                walkSpeedLoop:Disconnect()
            end
            walkSpeedLoop = RunService.Heartbeat:Connect(function()
                if character and character:FindFirstChild('Humanoid') then
                    character.Humanoid.WalkSpeed = walkSpeedValue
                end
            end)
        end
        
        -- Reapply jump power
        if Rayfield.Flags.JumpPowerSlider then
            character.Humanoid.JumpPower = Rayfield.Flags.JumpPowerSlider.CurrentValue
        end
    end
    
    -- Register respawn handler
    _G.CharacterRespawnHandlers.Movement = onCharacterRespawn
end
