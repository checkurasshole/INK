-- Gun Mods Module
-- This module should be uploaded to GitHub as 'gun-mods.lua'

return function(services)
    local MainTab = services.MainTab
    local Players = services.Players
    local LocalPlayer = services.LocalPlayer
    local RunService = services.RunService
    local ReplicatedStorage = services.ReplicatedStorage
    local Rayfield = services.Rayfield
    
    -- NPC Teleport Variables
    local npcTeleportEnabled = false
    local teleportDistance = 5
    local teleportConnection
    
    -- Gun Mods Function
    local function applyGunMods()
        local weaponFolders = {
            ReplicatedStorage:FindFirstChild('Weapons'),
            ReplicatedStorage:FindFirstChild('Guns'),
            ReplicatedStorage:FindFirstChild('Items'),
            ReplicatedStorage:FindFirstChild('Tools'),
        }
        
        for _, folder in ipairs(weaponFolders) do
            if folder then
                for _, weapon in ipairs(folder:GetChildren()) do
                    if weapon:IsA('Folder') or weapon:IsA('Model') then
                        -- Apply all mods
                        if weapon:FindFirstChild('MaxBullets') then
                            weapon.MaxBullets.Value = math.huge
                        end
                        if weapon:FindFirstChild('Ammo') then
                            weapon.Ammo.Value = math.huge
                        end
                        if weapon:FindFirstChild('ClipSize') then
                            weapon.ClipSize.Value = math.huge
                        end
                        if weapon:FindFirstChild('Spread') then
                            weapon.Spread.Value = 0
                        end
                        if weapon:FindFirstChild('FireRateCD') then
                            weapon.FireRateCD.Value = 0
                        end
                        if weapon:FindFirstChild('FireRate') then
                            weapon.FireRate.Value = 0
                        end
                        if weapon:FindFirstChild('BulletsPerFire') then
                            weapon.BulletsPerFire.Value = 10
                        end
                        if weapon:FindFirstChild('ShotsPerFire') then
                            weapon.ShotsPerFire.Value = 10
                        end
                        if weapon:FindFirstChild('Damage') then
                            weapon.Damage.Value = math.huge
                        end
                        if weapon:FindFirstChild('MaxDamage') then
                            weapon.MaxDamage.Value = math.huge
                        end
                        if weapon:FindFirstChild('MinDamage') then
                            weapon.MinDamage.Value = math.huge
                        end
                    end
                end
            end
        end
    end
    
    -- NPC Teleport Function
    local function teleportNPCs()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
            return
        end
        
        local playerPosition = LocalPlayer.Character.HumanoidRootPart.Position
        local playerLookDirection = LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
        
        for _, npc in ipairs(workspace:GetChildren()) do
            if npc:FindFirstChild('Humanoid') and npc:FindFirstChild('HumanoidRootPart') and npc ~= LocalPlayer.Character then
                -- Check if it's an NPC (not a player)
                local isPlayer = false
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Character == npc then
                        isPlayer = true
                        break
                    end
                end
                
                if not isPlayer then
                    -- Teleport NPC in front of player
                    local teleportPosition = playerPosition + (playerLookDirection * teleportDistance)
                    teleportPosition = Vector3.new(teleportPosition.X, teleportPosition.Y, teleportPosition.Z)
                    
                    npc.HumanoidRootPart.CFrame = CFrame.new(teleportPosition)
                    npc.HumanoidRootPart.Anchored = true
                end
            end
        end
    end

     -- Create section
    local Section = MainTab:CreateSection('Gun Mods')
    
    -- Create Gun Mods Button
    MainTab:CreateButton({
        Name = 'Gun Mods',
        Callback = function()
            applyGunMods()
            Rayfield:Notify({
                Title = 'Gun Mods Applied',
                Content = 'All gun modifications applied! (Infinite ammo, no spread, rapid fire, multi-shot, max damage)',
                Duration = 2,
            })
        end,
    })
    
    -- Create NPC Teleport Toggle
    MainTab:CreateToggle({
        Name = 'Teleport NPCs',
        CurrentValue = false,
        Flag = 'NPCTeleport',
        Callback = function(value)
            npcTeleportEnabled = value
            
            if npcTeleportEnabled then
                teleportConnection = RunService.Heartbeat:Connect(function()
                    teleportNPCs()
                end)
            else
                if teleportConnection then
                    teleportConnection:Disconnect()
                    teleportConnection = nil
                end
                
                -- Unanchor all NPCs
                for _, npc in ipairs(workspace:GetChildren()) do
                    if npc:FindFirstChild('Humanoid') and npc:FindFirstChild('HumanoidRootPart') then
                        local isPlayer = false
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player.Character == npc then
                                isPlayer = true
                                break
                            end
                        end
                        
                        if not isPlayer then
                            npc.HumanoidRootPart.Anchored = false
                        end
                    end
                end
            end
        end,
    })
    
    -- Create Distance Slider
    MainTab:CreateSlider({
        Name = 'NPC Distance',
        Range = {1, 20},
        Increment = 1,
        Suffix = 'studs',
        CurrentValue = 5,
        Flag = 'NPCDistance',
        Callback = function(value)
            teleportDistance = value
        end,
    })
    
    print('Gun Mods module loaded successfully!')
    
    -- Return module functions for the main script
    return {
        applyGunMods = applyGunMods,
        teleportNPCs = teleportNPCs,
        onCharacterAdded = function(character)
            -- Handle character respawn if needed
        end
    }
end
