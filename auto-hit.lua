-- Auto Hit Module
return function(services)
    local MainTab = services.MainTab
    local RunService = services.RunService
    
    -- Create section
    local Section = MainTab:CreateSection('Auto Hit')
    
    local autoHitEnabled = false
    local autoHitConnection

    MainTab:CreateToggle({
        Name = 'Auto Hit',
        CurrentValue = false,
        Flag = 'AutoHitToggle',
        Callback = function(Value)
            autoHitEnabled = Value

            if autoHitEnabled then
                autoHitConnection = RunService.Heartbeat:Connect(function()
                    pcall(function()
                        local args = {
                            [1] = 'UsingMoveCustom',
                            [2] = workspace
                                :WaitForChild('Live', 9e9)
                                :WaitForChild('uhonestlydontxare', 9e9)
                                :WaitForChild('Bottle', 9e9),
                            [4] = {
                                ['Clicked'] = true,
                            },
                        }

                        game
                            :GetService('ReplicatedStorage')
                            :WaitForChild('Remotes', 9e9)
                            :WaitForChild('UsedTool', 9e9)
                            :FireServer(unpack(args))
                    end)
                end)
            else
                if autoHitConnection then
                    autoHitConnection:Disconnect()
                end
            end
        end,
    })
    
    return {
        name = "Auto Hit",
        version = "1.0.0",
        cleanup = function()
            if autoHitConnection then
                autoHitConnection:Disconnect()
            end
        end
    }
end
