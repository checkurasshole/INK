-- Glass Bridge ESP Module
return function(services)
    local MainTab = services.MainTab
    
    -- Create section
    local Section = MainTab:CreateSection('Glass Bridge ESP')
    
    local glassBridgeESPEnabled = false
    local glassBridgeConnection = nil

    MainTab:CreateToggle({
        Name = 'Show Safe Glass Panels',
        CurrentValue = false,
        Flag = 'GlassBridgeESP',
        Callback = function(Value)
            glassBridgeESPEnabled = Value
            
            if glassBridgeESPEnabled then
                -- Function to highlight safe glass panels
                local function SetupGlassPart(GlassPart)
                    if not glassBridgeESPEnabled then return end
                    
                    -- Only highlight safe panels (green)
                    if not GlassPart:GetAttribute("exploitingisevil") then
                        GlassPart.Color = Color3.fromRGB(28, 235, 87) -- Green for safe
                        GlassPart.Transparency = 0
                        GlassPart.Material = Enum.Material.Neon
                    else
                        -- Reset dangerous panels to normal appearance
                        GlassPart.Color = Color3.fromRGB(106, 106, 106)
                        GlassPart.Transparency = 0.45
                        GlassPart.Material = Enum.Material.SmoothPlastic
                    end
                end
                
                -- Check if GlassBridge exists
                local GlassBridge = workspace:FindFirstChild("GlassBridge")
                if GlassBridge then
                    local GlassHolder = GlassBridge:FindFirstChild("GlassHolder")
                    if GlassHolder then
                        -- Apply ESP to existing glass panels
                        for _, PanelPair in ipairs(GlassHolder:GetChildren()) do
                            for _, Panel in ipairs(PanelPair:GetChildren()) do
                                local GlassPart = Panel:FindFirstChild("glasspart")
                                if GlassPart then
                                    SetupGlassPart(GlassPart)
                                end
                            end
                        end
                        
                        -- Monitor for new glass panels
                        glassBridgeConnection = GlassHolder.DescendantAdded:Connect(function(Descendant)
                            if Descendant.Name == "glasspart" and Descendant:IsA("BasePart") then
                                task.defer(SetupGlassPart, Descendant)
                            end
                        end)
                    end
                end
            else
                -- Reset all glass panels to normal appearance
                if glassBridgeConnection then
                    glassBridgeConnection:Disconnect()
                    glassBridgeConnection = nil
                end
                
                local GlassBridge = workspace:FindFirstChild("GlassBridge")
                if GlassBridge then
                    local GlassHolder = GlassBridge:FindFirstChild("GlassHolder")
                    if GlassHolder then
                        for _, PanelPair in ipairs(GlassHolder:GetChildren()) do
                            for _, Panel in ipairs(PanelPair:GetChildren()) do
                                local GlassPart = Panel:FindFirstChild("glasspart")
                                if GlassPart then
                                    GlassPart.Color = Color3.fromRGB(106, 106, 106)
                                    GlassPart.Transparency = 0.45
                                    GlassPart.Material = Enum.Material.SmoothPlastic
                                end
                            end
                        end
                    end
                end
            end
        end,
    })
    
    return {
        name = "Glass Bridge ESP",
        version = "1.0.0",
        cleanup = function()
            if glassBridgeConnection then
                glassBridgeConnection:Disconnect()
            end
        end
    }
end
