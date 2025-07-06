-- glass-bridge-esp.lua
local GlassBridgeESP = {}
GlassBridgeESP.enabled = true
GlassBridgeESP.connection = nil

-- Function to highlight safe glass panels
local function SetupGlassPart(GlassPart)
    if not GlassBridgeESP.enabled then return end
    
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

-- Function to disable ESP
function GlassBridgeESP:Disable()
    self.enabled = false
    
    -- Reset all glass panels to normal appearance
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
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
        GlassBridgeESP.connection = GlassHolder.DescendantAdded:Connect(function(Descendant)
            if Descendant.Name == "glasspart" and Descendant:IsA("BasePart") then
                task.defer(SetupGlassPart, Descendant)
            end
        end)
    end
end

-- Store in global for access
_G.GlassBridgeESP = GlassBridgeESP
