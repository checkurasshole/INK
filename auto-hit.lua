-- auto-hit.lua
local RunService = game:GetService('RunService')

local AutoHit = {}
AutoHit.enabled = true
AutoHit.connection = nil

-- Function to disable auto hit
function AutoHit:Disable()
    self.enabled = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

-- Start auto hit
AutoHit.connection = RunService.Heartbeat:Connect(function()
    if not AutoHit.enabled then return end
    
    pcall(function()
        local args = {
            [1] = 'UsingMoveCustom',
            [2] = workspace:WaitForChild('Live', 9e9):WaitForChild('uhonestlydontxare', 9e9):WaitForChild('Bottle', 9e9),
            [4] = {
                ['Clicked'] = true,
            },
        }

        game:GetService('ReplicatedStorage'):WaitForChild('Remotes', 9e9):WaitForChild('UsedTool', 9e9):FireServer(unpack(args))
    end)
end)

-- Store in global for access
_G.AutoHit = AutoHit
