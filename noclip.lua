-- Noclip Module for INK Game Script
return function(services)
    local MainTab = services.MainTab
    local LocalPlayer = services.LocalPlayer
    local RunService = services.RunService
    local UserInputService = services.UserInputService
    
    -- Noclip
    local noclipEnabled = false
    local noclipConnection
    
    MainTab:CreateToggle({
        Name = 'Noclip',
        CurrentValue = false,
        Flag = 'NoclipToggle',
        Callback = function(Value)
            noclipEnabled = Value

            if noclipEnabled then
                noclipConnection = RunService.Stepped:Connect(function()
                    if
                        LocalPlayer.Character
                        and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                    then
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
    
    -- Infinite Jump
    local infiniteJumpEnabled = false
    local infiniteJumpConnection

    MainTab:CreateToggle({
        Name = 'Infinite Jump',
        CurrentValue = false,
        Flag = 'InfiniteJumpToggle',
        Callback = function(Value)
            infiniteJumpEnabled = Value

            if infiniteJumpEnabled then
                infiniteJumpConnection = UserInputService.JumpRequest:Connect(
                    function()
                        if
                            LocalPlayer.Character
                            and LocalPlayer.Character:FindFirstChild('Humanoid')
                        then
                            LocalPlayer.Character.Humanoid:ChangeState(
                                Enum.HumanoidStateType.Jumping
                            )
                        end
                    end
                )
            else
                if infiniteJumpConnection then
                    infiniteJumpConnection:Disconnect()
                end
            end
        end,
    })
    
    -- Return module functions
    return {
        onCharacterAdded = function(character)
            -- No special handling needed for noclip on respawn
        end
    }
end
