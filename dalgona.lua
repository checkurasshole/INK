-- Dalgona Module
return function(services)
    local MainTab = services.MainTab
    
    -- Create section
    local Section = MainTab:CreateSection('Dalgona')
    
    local dalgonaAutoEnabled = false

    MainTab:CreateToggle({
        Name = 'Auto Complete Dalgona',
        CurrentValue = false,
        Flag = 'DalgonaAuto',
        Callback = function(Value)
            dalgonaAutoEnabled = Value
            
            if dalgonaAutoEnabled then
                local DalgonaClientModule = game.ReplicatedStorage:FindFirstChild("Modules")
                if DalgonaClientModule then
                    DalgonaClientModule = DalgonaClientModule:FindFirstChild("Games")
                    if DalgonaClientModule then
                        DalgonaClientModule = DalgonaClientModule:FindFirstChild("DalgonaClient")
                        if DalgonaClientModule then
                            local function CompleteDalgona()
                                if not dalgonaAutoEnabled then return end
                                
                                for _, Value in ipairs(getreg()) do
                                    if typeof(Value) == "function" and islclosure(Value) then
                                        if getfenv(Value).script == DalgonaClientModule then
                                            if getinfo(Value).nups == 54 then
                                                setupvalue(Value, 15, 9e9)
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- Run the completion function
                            task.spawn(CompleteDalgona)
                        end
                    end
                end
            end
        end,
    })
    
    return {
        name = "Dalgona",
        version = "1.0.0"
    }
end
