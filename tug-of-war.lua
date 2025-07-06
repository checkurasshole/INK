-- Tug of War Module
return function(services)
    local MainTab = services.MainTab
    local RunService = services.RunService
    
    -- Create section
    local Section = MainTab:CreateSection('Tug of War')
    
    local autoPullEnabled = false
    local autoPullConnection

    MainTab:CreateToggle({
        Name = 'Auto Pull',
        CurrentValue = false,
        Flag = 'AutoPullToggle',
        Callback = function(Value)
            autoPullEnabled = Value

            if autoPullEnabled then
                autoPullConnection = RunService.Heartbeat:Connect(function()
                    local args = {
                        [1] = {
                            ['QTEGood'] = true,
                        },
                    }

                    pcall(function()
                        game
                            :GetService('ReplicatedStorage')
                            :WaitForChild('Remotes', 9e9)
                            :WaitForChild('TemporaryReachedBindable', 9e9)
                            :FireServer(unpack(args))
                    end)
                end)
            else
                if autoPullConnection then
                    autoPullConnection:Disconnect()
                end
            end
        end,
    })
    
    return {
        name = "Tug of War",
        version = "1.0.0",
        cleanup = function()
            if autoPullConnection then
                autoPullConnection:Disconnect()
            end
        end
    }
end
