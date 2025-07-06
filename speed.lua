-- Speed Module for INK Game Script
return function(services)
    local MainTab = services.MainTab
    local LocalPlayer = services.LocalPlayer
    local RunService = services.RunService
    local Rayfield = services.Rayfield
    
    -- Movement Section
    local MovementSection = MainTab:CreateSection('Movement')
    
    -- Walk Speed with loop
    local walkSpeedLoop = nil
    
    MainTab:CreateSlider({
        Name = 'Walk Speed',
        Range = { 0, 200 },
        Increment = 1,
        CurrentValue = 16,
        Flag = 'WalkSpeedSlider',
        Callback = function(Value)
            if
                LocalPlayer.Character
                and LocalPlayer.Character:FindFirstChild('Humanoid')
            then
                LocalPlayer.Character.Humanoid.WalkSpeed = Value
            end

            -- Stop existing loop
            if walkSpeedLoop then
                walkSpeedLoop:Disconnect()
            end

            -- Start new loop to continuously apply walkspeed
            walkSpeedLoop = RunService.Heartbeat:Connect(function()
                if
                    LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild('Humanoid')
                then
                    LocalPlayer.Character.Humanoid.WalkSpeed = Value
                end
            end)
        end,
    })
    
    -- Jump Power
    MainTab:CreateSlider({
        Name = 'Jump Power',
        Range = { 0, 200 },
        Increment = 1,
        CurrentValue = 50,
        Flag = 'JumpPowerSlider',
        Callback = function(Value)
            if
                LocalPlayer.Character
                and LocalPlayer.Character:FindFirstChild('Humanoid')
            then
                LocalPlayer.Character.Humanoid.JumpPower = Value
            end
        end,
    })
    
    -- Return module functions for character respawn handling
    return {
        onCharacterAdded = function(character)
            character:WaitForChild('Humanoid')
            
            -- Restart walkspeed loop if it was active
            if Rayfield.Flags.WalkSpeedSlider then
                local walkSpeedValue = Rayfield.Flags.WalkSpeedSlider.CurrentValue
                character.Humanoid.WalkSpeed = walkSpeedValue

                -- Restart the loop
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
                character.Humanoid.JumpPower =
                    Rayfield.Flags.JumpPowerSlider.CurrentValue
            end
        end
    }
end
