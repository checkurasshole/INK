-- Auto Fling Module for INK Game Script
return function(services)
    local MainTab = services.MainTab
    local LocalPlayer = services.LocalPlayer
    local Players = services.Players
    local RunService = services.RunService
    
    -- Auto Fling Section
    local AutoFlingSection = MainTab:CreateSection('Auto Fling')
    
    -- Variables
    local excludedPlayers = {}
    local targetCount = 6
    local isFlingRunning = false
    local walkflinging = false
    local flingConnection = nil
    local humanoidDiedConnection = nil
    
    -- Get all players for dropdown
    local function getAllPlayers()
        local playerList = {"None"}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(playerList, player.Name)
            end
        end
        return playerList
    end
    
    -- Get nearest players excluding those in exclude list
    local function getNearestPlayers(count)
        local Character = LocalPlayer.Character
        if not Character or not Character:FindFirstChild("HumanoidRootPart") then
            return {}
        end
        
        local Root = Character.HumanoidRootPart
        local list = {}

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                -- Check if player is not in exclude list
                if not excludedPlayers[plr.Name] then
                    local theirRoot = plr.Character.HumanoidRootPart
                    local dist = (Root.Position - theirRoot.Position).Magnitude
                    table.insert(list, {plr = plr, dist = dist})
                end
            end
        end

        table.sort(list, function(a, b) return a.dist < b.dist end)

        local result = {}
        for i = 1, math.min(count, #list) do
            table.insert(result, list[i].plr)
        end

        return result
    end
    
    -- Enable noclip
    local function enableNoclip()
        local Character = LocalPlayer.Character
        if not Character then return end
        
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Disable noclip
    local function disableNoclip()
        local Character = LocalPlayer.Character
        if not Character then return end
        
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    -- Start walkfling
    local function startWalkfling()
        local Character = LocalPlayer.Character
        if not Character then return false end
        
        local humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoidDiedConnection = humanoid.Died:Connect(function()
                stopWalkfling()
            end)
        end
        
        enableNoclip()
        walkflinging = true
        
        flingConnection = RunService.Heartbeat:Connect(function()
            if not walkflinging then return end
            
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            
            if not (character and character.Parent and root and root.Parent) then
                return
            end
            
            local vel = root.Velocity
            local movel = 0.1
            
            -- Apply fling velocity
            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            
            RunService.RenderStepped:Wait()
            if character and character.Parent and root and root.Parent then
                root.Velocity = vel
            end
            
            RunService.Stepped:Wait()
            if character and character.Parent and root and root.Parent then
                root.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        end)
        
        return true
    end
    
    -- Stop walkfling
    local function stopWalkfling()
        walkflinging = false
        disableNoclip()
        
        if flingConnection then
            flingConnection:Disconnect()
            flingConnection = nil
        end
        
        if humanoidDiedConnection then
            humanoidDiedConnection:Disconnect()
            humanoidDiedConnection = nil
        end
    end
    
    -- Exclude List Dropdown
    local ExcludeDropdown = MainTab:CreateDropdown({
        Name = "Exclude Players",
        Options = getAllPlayers(),
        CurrentOption = {"None"},
        MultipleOptions = true,
        Flag = "ExcludePlayersDropdown",
        Callback = function(Options)
            excludedPlayers = {}
            for _, playerName in ipairs(Options) do
                if playerName ~= "None" then
                    excludedPlayers[playerName] = true
                end
            end
            
            local excludedNames = {}
            for name, _ in pairs(excludedPlayers) do
                table.insert(excludedNames, name)
            end
            
            if #excludedNames > 0 then
                print("Excluded players: " .. table.concat(excludedNames, ", "))
            else
                print("No players excluded")
            end
        end,
    })
    
    -- Refresh Players Button
    MainTab:CreateButton({
        Name = 'Refresh Player List',
        Callback = function()
            local newPlayerList = getAllPlayers()
            ExcludeDropdown:Refresh(newPlayerList)
            print("Player list refreshed")
        end,
    })
    
    -- Target Count Input
    MainTab:CreateInput({
        Name = "Target Count",
        PlaceholderText = "Enter number of players to target",
        RemoveTextAfterFocusLost = false,
        Flag = "TargetCountInput",
        Callback = function(Text)
            local count = tonumber(Text)
            if count and count > 0 and count <= 50 then
                targetCount = math.floor(count)
                print("Target count set to: " .. targetCount)
            else
                print("Invalid target count. Please enter a number between 1 and 50.")
            end
        end,
    })
    
    -- Auto Fling Button
    MainTab:CreateButton({
        Name = 'Start Auto Fling',
        Callback = function()
            if isFlingRunning then
                print("Auto fling is already running!")
                return
            end
            
            local Character = LocalPlayer.Character
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then
                print("Character or HumanoidRootPart not found!")
                return
            end
            
            isFlingRunning = true
            print("Starting silent auto fling targeting " .. targetCount .. " players...")
            
            -- Start walkfling
            if not startWalkfling() then
                print("Failed to start walkfling!")
                isFlingRunning = false
                return
            end
            
            task.spawn(function()
                local Root = Character.HumanoidRootPart
                local originalPosition = Root.CFrame
                
                -- Get nearest players
                local nearest = getNearestPlayers(targetCount)
                
                if #nearest == 0 then
                    print("No valid targets found!")
                    stopWalkfling()
                    isFlingRunning = false
                    return
                end
                
                print("Found " .. #nearest .. " targets")
                
                -- Teleport and fling each player
                for i, plr in ipairs(nearest) do
                    if not isFlingRunning then
                        break
                    end
                    
                    local targetRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        print("Silently targeting player " .. i .. "/" .. #nearest .. ": " .. plr.Name)
                        
                        -- Teleport directly into the target (noclip allows this)
                        Root.CFrame = targetRoot.CFrame
                        
                        -- Wait for fling effect (shorter time since walkfling is more efficient)
                        task.wait(1.0)
                    else
                        print("Skipping " .. plr.Name .. " - no valid character")
                    end
                end
                
                -- Stop walkfling and return to original position
                stopWalkfling()
                
                if Character and Character:FindFirstChild("HumanoidRootPart") then
                    task.wait(0.3) -- Wait for physics to settle
                    Character.HumanoidRootPart.CFrame = originalPosition
                    print("Returned to original position")
                end
                
                isFlingRunning = false
                print("Silent auto fling completed!")
            end)
        end,
    })
    
    -- Stop Auto Fling Button
    MainTab:CreateButton({
        Name = 'Stop Auto Fling',
        Callback = function()
            if isFlingRunning then
                isFlingRunning = false
                stopWalkfling()
                print("Auto fling stopped")
            else
                print("Auto fling is not running")
            end
        end,
    })
    
    -- Emergency Teleport Back Button
    MainTab:CreateButton({
        Name = 'Emergency Teleport Back',
        Callback = function()
            local Character = LocalPlayer.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                -- Stop walkfling first
                stopWalkfling()
                isFlingRunning = false
                
                -- Teleport to a safe position (high up)
                local currentPos = Character.HumanoidRootPart.Position
                Character.HumanoidRootPart.CFrame = CFrame.new(currentPos.X, currentPos.Y + 50, currentPos.Z)
                print("Emergency teleported to safe position")
            end
        end,
    })
    
    -- Status display
    local StatusLabel = MainTab:CreateLabel("Status: Ready")
    
    -- Update status periodically
    task.spawn(function()
        while true do
            if isFlingRunning then
                StatusLabel:Set("Status: Silent Fling Running...")
            else
                StatusLabel:Set("Status: Ready")
            end
            task.wait(1)
        end
    end)
    
    -- Return module functions
    return {
        onCharacterAdded = function(character)
            -- Stop auto fling if character respawns
            if isFlingRunning then
                stopWalkfling()
                isFlingRunning = false
                print("Auto fling stopped due to character respawn")
            end
        end
    }
end
