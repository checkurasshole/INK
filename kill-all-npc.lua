-- kill-all-npc.lua
return function(params)
    local Players = params.Players
    local LocalPlayer = params.LocalPlayer
    local Workspace = game:GetService("Workspace")
    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorage = params.ReplicatedStorage
    local Rayfield = params.Rayfield
    local MainTab = params.MainTab

    -- Variables
    local Camera = Workspace.CurrentCamera
    local npcESPEnabled = false
    local npcHitboxEnabled = false
    local npcTeleportEnabled = false
    local teleportDistance = 10

    -- NPC Functions
    local function isNPC(character)
        if character and character:IsA("Model") then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid and not Players:GetPlayerFromCharacter(character) and humanoid.Health > 0 then
                return true
            end
        end
        return false
    end

    local function addNPCESP(character)
        if character:FindFirstChild("ESPBox") then return end
        local esp = Instance.new("BillboardGui")
        esp.Name = "ESPBox"
        esp.AlwaysOnTop = true
        esp.Size = UDim2.new(4, 0, 2, 0)
        esp.StudsOffset = Vector3.new(0, 2, 0)
        local text = Instance.new("TextLabel", esp)
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = "NPC"
        text.TextColor3 = Color3.fromRGB(255, 0, 0)
        text.TextStrokeTransparency = 0
        text.Font = Enum.Font.GothamBold
        text.TextSize = 16
        esp.Parent = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    end

    local function expandNPCHitbox(character)
        if CollectionService:HasTag(character, "ModifiedNPC") then return end
        local head = character:FindFirstChild("Head")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if head then
            head.Size = Vector3.new(9, 9, 9)
            head.Transparency = 0.5
            head.Material = Enum.Material.ForceField
        end
        if rootPart then
            rootPart.Size = Vector3.new(8, 8, 8)
            rootPart.Transparency = 0.5
            rootPart.Material = Enum.Material.ForceField
        end
        CollectionService:AddTag(character, "ModifiedNPC")
    end

    local function scanForNPCs()
        for _, v in pairs(Workspace:GetChildren()) do
            if isNPC(v) then
                if npcESPEnabled then
                    addNPCESP(v)
                end
                if npcHitboxEnabled then
                    expandNPCHitbox(v)
                end
            end
        end
    end

    -- Monitor new NPCs
    Workspace.ChildAdded:Connect(function(child)
        task.wait(0.1)
        if isNPC(child) then
            if npcESPEnabled then
                addNPCESP(child)
            end
            if npcHitboxEnabled then
                expandNPCHitbox(child)
            end
        end
    end)

    -- Initial NPC scan
    scanForNPCs()

    -- Function to teleport NPCs to one position in front of player
    local function teleportNPCsToSinglePoint()
        local character = LocalPlayer.Character
        local fixedPosition
        if character and character:FindFirstChild("HumanoidRootPart") then
            local cameraDirection = Camera.CFrame.LookVector
            local cameraPosition = Camera.CFrame.Position
            fixedPosition = cameraPosition + cameraDirection * teleportDistance
        else
            fixedPosition = Vector3.new(0, 5, 0)
        end
        for _, npc in pairs(Workspace:GetDescendants()) do
            if isNPC(npc) then
                local humanoid = npc:FindFirstChild("Humanoid")
                local targetRootPart = npc:FindFirstChild("HumanoidRootPart")
                if humanoid and targetRootPart then
                    for _, v in pairs(npc:GetChildren()) do
                        if v:IsA("BodyGyro") or v:IsA("BodyPosition") then
                            v:Destroy()
                        end
                    end
                    targetRootPart.CFrame = CFrame.new(fixedPosition)
                    targetRootPart.Anchored = true
                    humanoid.PlatformStand = true
                    humanoid:ChangeState(Enum.HumanoidStateType.None)
                end
            end
        end
    end

    -- Gun Mods for MP5
    local MP5 = ReplicatedStorage:FindFirstChild("Weapons") and ReplicatedStorage.Weapons:FindFirstChild("Guns") and ReplicatedStorage.Weapons.Guns:FindFirstChild("MP5")
    if MP5 then
        if MP5:FindFirstChild("MaxBullets") then
            MP5.MaxBullets.Value = math.huge
        end
        if MP5:FindFirstChild("Spread") then
            MP5.Spread.Value = 0
        end
        if MP5:FindFirstChild("BulletsPerFire") then
            MP5.BulletsPerFire.Value = 5
        end
        if MP5:FindFirstChild("FireRateCD") then
            MP5.FireRateCD.Value = 0
        end
    end

    -- Create UI Elements
    MainTab:CreateToggle({
        Name = "Kill All NPC",
        CurrentValue = false,
        Callback = function(value)
            npcTeleportEnabled = value
            if value then
                while npcTeleportEnabled do
                    teleportNPCsToSinglePoint()
                    wait(0.5)
                end
            end
        end,
    })

    MainTab:CreateSlider({
        Name = "Teleport Distance",
        Range = {0, 50},
        Increment = 1,
        Suffix = "Studs",
        CurrentValue = 10,
        Callback = function(value)
            teleportDistance = value
        end
    })

    MainTab:CreateToggle({
        Name = "NPC ESP",
        CurrentValue = false,
        Flag = "npcESPToggle",
        Callback = function(value)
            npcESPEnabled = value
            if value then
                scanForNPCs()
            else
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v.Name == "ESPBox" then
                        v:Destroy()
                    end
                end
            end
        end
    })

    MainTab:CreateToggle({
        Name = "NPC Hitbox Expander",
        CurrentValue = false,
        Flag = "npcHitboxToggle",
        Callback = function(value)
            npcHitboxEnabled = value
            if value then
                scanForNPCs()
            else
                for _, v in pairs(Workspace:GetChildren()) do
                    if isNPC(v) and CollectionService:HasTag(v, "ModifiedNPC") then
                        local head = v:FindFirstChild("Head")
                        local rootPart = v:FindFirstChild("HumanoidRootPart")
                        if head then
                            head.Size = Vector3.new(1, 1, 1)
                            head.Transparency = 0
                            head.Material = Enum.Material.Plastic
                        end
                        if rootPart then
                            rootPart.Size = Vector3.new(2, 2, 1)
                            rootPart.Transparency = 0
                            rootPart.Material = Enum.Material.Plastic
                        end
                        CollectionService:RemoveTag(v, "ModifiedNPC")
                    end
                end
            end
        end
    })

    -- Return module object with onCharacterAdded for respawn handling
    return {
        onCharacterAdded = function(character)
            if npcESPEnabled then
                scanForNPCs()
            end
            if npcHitboxEnabled then
                scanForNPCs()
            end
        end
    }
end
