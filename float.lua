-- Float Module
return function(services)
    local MainTab = services.MainTab
    local LocalPlayer = services.LocalPlayer
    local RunService = services.RunService
    local UserInputService = services.UserInputService
    
    -- Create section
    local Section = MainTab:CreateSection('Float')
    
    local floatEnabled = false
    local bodyVelocity = nil
    local floatConnection = nil
    local jumpBoostConnection = nil

    MainTab:CreateToggle({
        Name = 'Float',
        CurrentValue = false,
        Flag = 'FloatToggle',
        Callback = function(Value)
            floatEnabled = Value

            if floatEnabled then
                if
                    LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                then
                    local hrp = LocalPlayer.Character.HumanoidRootPart

                    -- Create BodyVelocity
                    bodyVelocity = Instance.new('BodyVelocity')
                    bodyVelocity.Name = 'AntiFallFloat'
                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
                    bodyVelocity.Parent = hrp

                    -- Monitor falling
                    floatConnection = RunService.Heartbeat:Connect(function()
                        if not hrp or not hrp.Parent or not floatEnabled then
                            return
                        end

                        local yVelocity = hrp.Velocity.Y
                        if yVelocity < -50 then
                            bodyVelocity.Velocity = Vector3.new(0, 50, 0)
                            bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
                        elseif yVelocity > -5 then
                            bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
                        end
                    end)

                    -- Add jump boost functionality
                    jumpBoostConnection = UserInputService.JumpRequest:Connect(function()
                        if
                            LocalPlayer.Character
                            and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                            and LocalPlayer.Character:FindFirstChild('Humanoid')
                            and floatEnabled
                        then
                            local humanoid = LocalPlayer.Character.Humanoid
                            local rootPart = LocalPlayer.Character.HumanoidRootPart
                            
                            -- Check if character is on ground or close to ground
                            local raycast = workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0))
                            if raycast or humanoid.FloorMaterial ~= Enum.Material.Air then
                                -- Apply jump boost
                                bodyVelocity.Velocity = Vector3.new(0, 150, 0) -- Increased jump height
                                bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
                                
                                -- Reset after a short delay
                                task.wait(0.1)
                                if bodyVelocity and bodyVelocity.Parent then
                                    bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
                                end
                            end
                        end
                    end)

                    print('Float enabled with jump boost')
                end
            else
                if bodyVelocity then
                    bodyVelocity:Destroy()
                    bodyVelocity = nil
                end
                if floatConnection then
                    floatConnection:Disconnect()
                    floatConnection = nil
                end
                if jumpBoostConnection then
                    jumpBoostConnection:Disconnect()
                    jumpBoostConnection = nil
                end
                print('Float disabled')
            end
        end,
    })
    
    return {
        name = "Float",
        version = "1.0.0",
        cleanup = function()
            if bodyVelocity then
                bodyVelocity:Destroy()
            end
            if floatConnection then
                floatConnection:Disconnect()
            end
            if jumpBoostConnection then
                jumpBoostConnection:Disconnect()
            end
        end
    }
end
