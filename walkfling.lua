-- Improved Auto Fling Module for INK Game Script
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
    local currentTargets = {}
    local flingForce = 50000
    local flingDuration = 2
    local pauseBetweenTargets = 1
    
    -- Helper function to get root part
    local function getRoot(character)
        return character:FindFirstChild('HumanoidRootPart')
            or character:FindFirstChild('Torso')
            or character:FindFirstChild('UpperTorso')
    end
    
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
        if not Character then
            return {}
        end
        
        local Root = getRoot(Character)
        if not Root then
            return {}
        end
        
        local list = {}

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local theirRoot = getRoot(plr.Character)
                if theirRoot and not excludedPlayers[plr.Name] then
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
    
    -- Advanced fling function with proper physics
    local function flingPlayer(targetPlayer)
        local Character = LocalPlayer.Character
        local Root = getRoot(Character)
        local targetRoot = getRoot(targetPlayer.Character)
        
        if not (Character and Root and targetPlayer.Character and targetRoot) then
            return false
        end
        
        print("Flinging: " .. targetPlayer.Name)
        
        -- Calculate direction to target
        local direction = (targetRoot.Position - Root.Position).Unit
        local distance = (targetRoot.Position - Root.Position).Magnitude
        
        -- Position slightly behind target for better impact
        local behindTarget = targetRoot.Position - (direction * 5)
        
        -- Store original properties
        local originalCFrame = Root.CFrame
        local originalVelocity = Root.Velocity
        
        -- Keep character parts solid
        for _, part in pairs(Character:GetChildren()) do
            if part:IsA('BasePart') and part ~= Root then
                part.CanCollide = true
            end
        end
        
        -- Phase 1: Quick position to behind target
        Root.CFrame = CFrame.new(behindTarget, targetRoot.Position)
        
        -- Phase 2: Apply massive velocity toward target
        local flingVelocity = direction * flingForce
        Root.Velocity = flingVelocity
        
        -- Phase 3: Maintain velocity for impact
        local startTime = tick()
        local flingLoop = RunService.Heartbeat:Connect(function()
            if not (Character and Character.Parent and Root and Root.Parent) then
                return
            end
            
            local elapsed = tick() - startTime
            
            if elapsed < 0.3 then
                -- Maintain high velocity for impact
                Root.Velocity = flingVelocity
            elseif elapsed < 0.6 then
                -- Reduce velocity gradually
                Root.Velocity = flingVelocity * (1 - (elapsed - 0.3) / 0.3)
            else
                -- Stop the fling loop
                flingLoop:Disconnect()
                if Root and Root.Parent then
                    Root.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end)
        
        return true
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
    
    -- Fling Force Input
    MainTab:CreateInput({
        Name = "Fling Force",
        PlaceholderText = "Enter fling force (default: 50000)",
        RemoveTextAfterFocusLost = false,
        Flag = "FlingForceInput",
        Callback = function(Text)
            local force = tonumber(Text)
            if force and force > 0 and force <= 1000000 then
                flingForce = force
                print("Fling force set to: " .. flingForce)
            else
                print("Invalid fling force. Please enter a number between 1 and 1000000.")
            end
        end,
    })
    
    -- Pause Between Targets Input
    MainTab:CreateInput({
        Name = "Pause Between Targets",
        PlaceholderText = "Enter pause in seconds (default: 1)",
        RemoveTextAfterFocusLost = false,
        Flag = "PauseInput",
        Callback = function(Text)
            local pause = tonumber(Text)
            if pause and pause >= 0 and pause <= 10 then
                pauseBetweenTargets = pause
                print("Pause between targets set to: " .. pauseBetweenTargets .. " seconds")
            else
                print("Invalid pause time. Please enter a number between 0 and 10.")
            end
        end,
    })
    
    -- Auto Fling Toggle
    MainTab:CreateToggle({
        Name = 'Auto Fling',
        CurrentValue = false,
        Flag = 'AutoFlingToggle',
        Callback = function(Value)
            if Value then
                -- Start auto fling
                local Character = LocalPlayer.Character
                if not Character then
                    print("Character not found!")
                    return
                end
                
                local Root = getRoot(Character)
                if not Root then
                    print("HumanoidRootPart not found!")
                    return
                end
                
                isFlingRunning = true
                print("Starting auto fling targeting " .. targetCount .. " players...")
                
                task.spawn(function()
                    local originalPosition = Root.CFrame
                    
                    while isFlingRunning do
                        -- Get nearest players
                        local nearest = getNearestPlayers(targetCount)
                        
                        if #nearest == 0 then
                            print("No valid targets found!")
                            task.wait(2)
                            continue
                        end
                        
                        print("Found " .. #nearest .. " targets")
                        
                        -- Fling each player
                        for i, plr in ipairs(nearest) do
                            if not isFlingRunning then
                                break
                            end
                            
                            local success = flingPlayer(plr)
                            if success then
                                print("Flung player " .. i .. "/" .. #nearest .. ": " .. plr.Name)
                            else
                                print("Failed to fling: " .. plr.Name)
                            end
                            
                            -- Wait between targets
                            if pauseBetweenTargets > 0 and i < #nearest then
                                task.wait(pauseBetweenTargets)
                            end
                        end
                        
                        -- Return to original position after each round
                        if Character and Character.Parent then
                            local currentRoot = getRoot(Character)
                            if currentRoot then
                                currentRoot.CFrame = originalPosition
                                currentRoot.Velocity = Vector3.new(0, 0, 0)
                            end
                        end
                        
                        print("Completed fling round, waiting before next...")
                        task.wait(3) -- Wait before next round
                    end
                    
                    print("Auto fling stopped")
                end)
            else
                -- Stop auto fling
                isFlingRunning = false
                if flingConnection then
                    flingConnection:Disconnect()
                    flingConnection = nil
                end
            end
        end,
    })
    
    -- Single Target Fling Button
    MainTab:CreateButton({
        Name = 'Fling Nearest Player',
        Callback = function()
            if isFlingRunning then
                print("Auto fling is running! Stop it first.")
                return
            end
            
            local nearest = getNearestPlayers(1)
            if #nearest > 0 then
                flingPlayer(nearest[1])
            else
                print("No valid targets found!")
            end
        end,
    })
    
    -- Emergency Stop Button
    MainTab:CreateButton({
        Name = 'Emergency Stop',
        Callback = function()
            isFlingRunning = false
            if flingConnection then
                flingConnection:Disconnect()
                flingConnection = nil
            end
            
            local Character = LocalPlayer.Character
            if Character then
                local Root = getRoot(Character)
                if Root then
                    Root.Velocity = Vector3.new(0, 0, 0)
                    -- Teleport to safe position
                    local currentPos = Root.Position
                    Root.CFrame = CFrame.new(currentPos.X, currentPos.Y + 50, currentPos.Z)
                end
            end
            print("Emergency stop activated")
        end,
    })
    
    -- Status display
    local StatusLabel = MainTab:CreateLabel("Status: Ready")
    
    -- Update status periodically
    task.spawn(function()
        while true do
            if isFlingRunning then
                StatusLabel:Set("Status: Auto Fling Active")
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
                isFlingRunning = false
                if flingConnection then
                    flingConnection:Disconnect()
                    flingConnection = nil
                end
                print("Auto fling stopped due to character respawn")
            end
        end
    }
end
