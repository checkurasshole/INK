-- Walk Fling Module for INK Game Script
return function(services)
    local MainTab = services.MainTab
    local LocalPlayer = services.LocalPlayer
    local RunService = services.RunService
    
    -- Walk Fling (Fixed to prevent falling through map)
    local walkflinging = false
    local walkflingConnection = nil

    -- Helper function to get root part
    local function getRoot(character)
        return character:FindFirstChild('HumanoidRootPart')
            or character:FindFirstChild('Torso')
            or character:FindFirstChild('UpperTorso')
    end

    MainTab:CreateToggle({
        Name = 'Walk Fling',
        CurrentValue = false,
        Flag = 'WalkFlingToggle',
        Callback = function(Value)
            if Value then
                -- Start walk fling
                walkflinging = false -- Stop any existing walk fling
                local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA(
                    'Humanoid'
                )
                if humanoid then
                    humanoid.Died:Connect(function()
                        walkflinging = false
                    end)
                end

                walkflinging = true
                walkflingConnection = RunService.Heartbeat:Connect(function()
                    if not walkflinging then
                        return
                    end

                    local character = LocalPlayer.Character
                    local root = getRoot(character)

                    if
                        not (
                            character
                            and character.Parent
                            and root
                            and root.Parent
                        )
                    then
                        return
                    end

                    -- Keep character parts solid to prevent falling through ground
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA('BasePart') and part ~= root then
                            part.CanCollide = true
                        end
                    end

                    -- Store original velocity
                    local vel = root.Velocity
                    local movel = 0.1

                    -- Apply fling force with Y velocity protection
                    local newVel = vel * 10000
                        + Vector3.new(0, math.max(vel.Y * 1000, -30000), 0)
                    root.Velocity = newVel

                    RunService.RenderStepped:Wait()

                    if character and character.Parent and root and root.Parent then
                        -- Reset to original velocity with small Y adjustment
                        root.Velocity = Vector3.new(vel.X, math.max(vel.Y + movel, -50), vel.Z)
                        movel = movel * -1
                    end
                end)
            else
                -- Stop walk fling
                walkflinging = false
                if walkflingConnection then
                    walkflingConnection:Disconnect()
                    walkflingConnection = nil
                end
            end
        end,
    })
    
    -- Return module functions
    return {
        onCharacterAdded = function(character)
            -- Reset walk fling on character respawn
            if walkflinging then
                walkflinging = false
                if walkflingConnection then
                    walkflingConnection:Disconnect()
                    walkflingConnection = nil
                end
            end
        end
    }
end
