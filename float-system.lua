-- float-system.lua
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local FloatSystem = {}
FloatSystem.enabled = true
FloatSystem.bodyVelocity = nil
FloatSystem.floatConnection = nil
FloatSystem.jumpBoostConnection = nil

-- Function to disable float
function FloatSystem:Disable()
    self.enabled = false
    
    if self.bodyVelocity then
        self.bodyVelocity:Destroy()
        self.bodyVelocity = nil
    end
    if self.floatConnection then
        self.floatConnection:Disconnect()
        self.floatConnection = nil
    end
    if self.jumpBoostConnection then
        self.jumpBoostConnection:Disconnect()
        self.jumpBoostConnection = nil
    end
end

-- Start float system
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
    local hrp = LocalPlayer.Character.HumanoidRootPart

    -- Create BodyVelocity
    FloatSystem.bodyVelocity = Instance.new('BodyVelocity')
    FloatSystem.bodyVelocity.Name = 'AntiFallFloat'
    FloatSystem.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    FloatSystem.bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
    FloatSystem.bodyVelocity.Parent = hrp

    -- Monitor falling
    FloatSystem.floatConnection = RunService.Heartbeat:Connect(function()
        if not hrp or not hrp.Parent or not FloatSystem.enabled then
            return
        end

        local yVelocity = hrp.Velocity.Y
        if yVelocity < -50 then
            FloatSystem.bodyVelocity.Velocity = Vector3.new(0, 50, 0)
            FloatSystem.bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
        elseif yVelocity > -5 then
            FloatSystem.bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
        end
    end)

    -- Add jump boost functionality
    FloatSystem.jumpBoostConnection = UserInputService.JumpRequest:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') 
           and LocalPlayer.Character:FindFirstChild('Humanoid') and FloatSystem.enabled then
            
            local humanoid = LocalPlayer.Character.Humanoid
            local rootPart = LocalPlayer.Character.HumanoidRootPart
            
            -- Check if character is on ground or close to ground
            local raycast = workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0))
            if raycast or humanoid.FloorMaterial ~= Enum.Material.Air then
                -- Apply jump boost
                FloatSystem.bodyVelocity.Velocity = Vector3.new(0, 150, 0)
                FloatSystem.bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
                
                -- Reset after a short delay
                task.spawn(function()
                    task.wait(0.1)
                    if FloatSystem.bodyVelocity and FloatSystem.bodyVelocity.Parent then
                        FloatSystem.bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
                    end
                end)
            end
        end
    end)

    print('Float enabled with jump boost')
end

-- Store in global for access
_G.FloatSystem = FloatSystem
