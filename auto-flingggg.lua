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
    local flingConnection = nil
    local bodyAngularVelocity = nil
    
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
    
    -- Setup fling physics
    local function setupFlingPhysics()
        local Character = LocalPlayer.Character
        if not Character or not Character:FindFirstChild("HumanoidRootPart") then
            return false
        end
        
        local Root = Character.HumanoidRootPart
        
        -- Apply custom physical properties to all parts
        for _, child in pairs(Character:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                child.CanCollide = false
                child.Massless = true
                child.Velocity = Vector3.new(0, 0, 0)
            end
        end
        
        -- Create BodyAngularVelocity for spinning
        bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.Name = "FlingVelocity"
        bodyAngularVelocity.Parent = Root
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, 99999, 0)
        bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
        bodyAngularVelocity.P = math.huge
        
        return true
    end
    
    -- Clean up fling physics
    local function cleanupFlingPhysics()
        local Character = LocalPlayer.Character
        if Character then
            local Root = Character:FindFirstChild("HumanoidRootPart")
            if Root then
                -- Remove BodyAngularVelocity
                for _, child in pairs(Root:GetChildren()) do
                    if child:IsA("BodyAngularVelocity") then
                        child:Destroy()
                    end
                end
            end
            
            -- Reset physical properties
            for _, child in pairs(Character:GetDescendants()) do
                if child:IsA("BasePart") then
                    child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                    child.CanCollide = true
                    child.Massless = false
                end
            end
        end
        
        bodyAngularVelocity = nil
        if flingConnection then
            flingConnection:Disconnect()
            flingConnection = nil
        end
    end
    
    -- Fling loop function
    local function startFlingLoop()
        if not bodyAngularVelocity then return end
        
        flingConnection = RunService.Heartbeat:Connect(function()
            if not isFlingRunning or not bodyAngularVelocity or not bodyAngularVelocity.Parent then
                return
            end
            
            -- Alternate between spinning and stopping for maximum fling effect
            if tick() % 0.3 < 0.2 then
                bodyAngularVelocity.AngularVelocity = Vector3.new(0, 99999, 0)
            else
                bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
            end
        end)
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
            print("Starting auto fling targeting " .. targetCount .. " players...")
            
            -- Setup fling physics first
            if not setupFlingPhysics() then
                print("Failed to setup fling physics!")
                isFlingRunning = false
                return
            end
            
            -- Start the fling loop
            startFlingLoop()
            
            task.spawn(function()
                local Root = Character.HumanoidRootPart
                local originalPosition = Root.CFrame
                
                -- Get nearest players
                local nearest = getNearestPlayers(targetCount)
                
                if #nearest == 0 then
                    print("No valid targets found!")
                    cleanupFlingPhysics()
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
                        print("Targeting player " .. i .. "/" .. #nearest .. ": " .. plr.Name)
                        
                        -- Teleport to target with slight offset to ensure collision
                        local offset = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
                        Root.CFrame = targetRoot.CFrame + offset
                        
                        -- Wait for fling effect
                        task.wait(1.5)
                    else
                        print("Skipping " .. plr.Name .. " - no valid character")
                    end
                end
                
                -- Clean up and return to original position
                cleanupFlingPhysics()
                
                if Character and Character:FindFirstChild("HumanoidRootPart") then
                    task.wait(0.5) -- Wait for physics to settle
                    Character.HumanoidRootPart.CFrame = originalPosition
                    print("Returned to original position")
                end
                
                isFlingRunning = false
                print("Auto fling completed!")
            end)
        end,
    })
    
    -- Stop Auto Fling Button
    MainTab:CreateButton({
        Name = 'Stop Auto Fling',
        Callback = function()
            if isFlingRunning then
                isFlingRunning = false
                cleanupFlingPhysics()
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
                -- Clean up fling physics first
                cleanupFlingPhysics()
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
                StatusLabel:Set("Status: Auto Fling Running...")
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
                cleanupFlingPhysics()
                isFlingRunning = false
                print("Auto fling stopped due to character respawn")
            end
        end
    }
end
