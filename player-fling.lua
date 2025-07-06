-- Player Fling Module for INK Game Script
return function(services)
    local MainTab = services.MainTab
    local LocalPlayer = services.LocalPlayer
    local RunService = services.RunService
    local Players = services.Players
    
    -- Player Fling Section
    local PlayerFlingSection = MainTab:CreateSection('Player Fling')
    
    -- Variables
    local excludedPlayers = {}
    local targetCount = 1
    local isFlinging = false
    local flingConnection = nil
    local currentTargetIndex = 1
    local flingedPlayers = {}
    
    -- Helper function to get root part
    local function getRoot(character)
        return character:FindFirstChild('HumanoidRootPart')
            or character:FindFirstChild('Torso')
            or character:FindFirstChild('UpperTorso')
    end
    
    -- Helper function to get all valid targets
    local function getValidTargets()
        local targets = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and 
               player.Character and 
               getRoot(player.Character) and
               not excludedPlayers[player.Name:lower()] then
                table.insert(targets, player)
            end
        end
        return targets
    end
    
    -- Helper function to teleport to player
    local function teleportToPlayer(targetPlayer)
        if not LocalPlayer.Character or not getRoot(LocalPlayer.Character) then
            return false
        end
        
        local targetRoot = getRoot(targetPlayer.Character)
        if not targetRoot then
            return false
        end
        
        -- Teleport slightly behind the target
        local offset = targetRoot.CFrame.LookVector * -3
        getRoot(LocalPlayer.Character).CFrame = targetRoot.CFrame + offset
        
        return true
    end
    
    -- Helper function to fling player
    local function flingPlayer(targetPlayer)
        if not LocalPlayer.Character or not getRoot(LocalPlayer.Character) then
            return false
        end
        
        local myRoot = getRoot(LocalPlayer.Character)
        local targetRoot = getRoot(targetPlayer.Character)
        
        if not myRoot or not targetRoot then
            return false
        end
        
        -- Apply fling force
        local bodyVelocity = Instance.new('BodyVelocity')
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(
            math.random(-100, 100),
            math.random(50, 150),
            math.random(-100, 100)
        )
        bodyVelocity.Parent = myRoot
        
        -- Remove after short duration
        task.spawn(function()
            task.wait(0.1)
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
        end)
        
        return true
    end
    
    -- Main fling function
    local function startAutoFling()
        if isFlinging then
            return
        end
        
        isFlinging = true
        flingedPlayers = {}
        currentTargetIndex = 1
        
        local targets = getValidTargets()
        
        if #targets == 0 then
            print("No valid targets found!")
            isFlinging = false
            return
        end
        
        -- Limit targets to specified count
        local actualTargetCount = math.min(targetCount, #targets)
        
        print("Starting auto fling on " .. actualTargetCount .. " players...")
        
        flingConnection = RunService.Heartbeat:Connect(function()
            if not isFlinging or currentTargetIndex > actualTargetCount then
                if flingConnection then
                    flingConnection:Disconnect()
                    flingConnection = nil
                end
                isFlinging = false
                print("Auto fling completed!")
                return
            end
            
            local currentTarget = targets[currentTargetIndex]
            
            if currentTarget and 
               currentTarget.Character and 
               getRoot(currentTarget.Character) and
               not flingedPlayers[currentTarget.Name] then
                
                -- Teleport to player
                if teleportToPlayer(currentTarget) then
                    task.wait(0.5) -- Wait for teleport to complete
                    
                    -- Fling the player
                    if flingPlayer(currentTarget) then
                        print("Flung player: " .. currentTarget.Name)
                        flingedPlayers[currentTarget.Name] = true
                        
                        task.wait(1) -- Wait before moving to next target
                        currentTargetIndex = currentTargetIndex + 1
                    else
                        currentTargetIndex = currentTargetIndex + 1
                    end
                else
                    currentTargetIndex = currentTargetIndex + 1
                end
            else
                currentTargetIndex = currentTargetIndex + 1
            end
        end)
    end
    
    -- Stop fling function
    local function stopAutoFling()
        isFlinging = false
        if flingConnection then
            flingConnection:Disconnect()
            flingConnection = nil
        end
        print("Auto fling stopped!")
    end
    
    -- UI Elements
    
    -- Target count input
    MainTab:CreateInput({
        Name = 'Target Count',
        PlaceholderText = 'Enter number of players to target',
        RemoveTextAfterFocusLost = false,
        Flag = 'TargetCountInput',
        Callback = function(Text)
            local count = tonumber(Text)
            if count and count > 0 then
                targetCount = math.floor(count)
                print("Target count set to: " .. targetCount)
            else
                print("Invalid target count! Please enter a valid number.")
            end
        end,
    })
    
    -- Exclude player input
    MainTab:CreateInput({
        Name = 'Exclude Player',
        PlaceholderText = 'Enter player name to exclude',
        RemoveTextAfterFocusLost = true,
        Flag = 'ExcludePlayerInput',
        Callback = function(Text)
            if Text and Text ~= "" then
                local playerName = Text:lower()
                if not excludedPlayers[playerName] then
                    excludedPlayers[playerName] = true
                    print("Added to exclude list: " .. Text)
                else
                    print("Player already in exclude list: " .. Text)
                end
            end
        end,
    })
    
    -- Remove from exclude list
    MainTab:CreateInput({
        Name = 'Remove from Exclude List',
        PlaceholderText = 'Enter player name to remove from exclude list',
        RemoveTextAfterFocusLost = true,
        Flag = 'RemoveExcludeInput',
        Callback = function(Text)
            if Text and Text ~= "" then
                local playerName = Text:lower()
                if excludedPlayers[playerName] then
                    excludedPlayers[playerName] = nil
                    print("Removed from exclude list: " .. Text)
                else
                    print("Player not in exclude list: " .. Text)
                end
            end
        end,
    })
    
    -- Start/Stop toggle
    MainTab:CreateToggle({
        Name = 'Auto Fling Players',
        CurrentValue = false,
        Flag = 'AutoFlingToggle',
        Callback = function(Value)
            if Value then
                startAutoFling()
            else
                stopAutoFling()
            end
        end,
    })
    
    -- Clear exclude list button
    MainTab:CreateButton({
        Name = 'Clear Exclude List',
        Callback = function()
            excludedPlayers = {}
            print("Exclude list cleared!")
        end,
    })
    
    -- Show current targets button
    MainTab:CreateButton({
        Name = 'Show Valid Targets',
        Callback = function()
            local targets = getValidTargets()
            if #targets > 0 then
                local targetNames = {}
                for _, player in pairs(targets) do
                    table.insert(targetNames, player.Name)
                end
                print("Valid targets (" .. #targets .. "): " .. table.concat(targetNames, ", "))
            else
                print("No valid targets found!")
            end
        end,
    })
    
    -- Show exclude list button
    MainTab:CreateButton({
        Name = 'Show Exclude List',
        Callback = function()
            local excludedNames = {}
            for name, _ in pairs(excludedPlayers) do
                table.insert(excludedNames, name)
            end
            
            if #excludedNames > 0 then
                print("Excluded players: " .. table.concat(excludedNames, ", "))
            else
                print("No players in exclude list!")
            end
        end,
    })
    
    -- Return module functions
    return {
        onCharacterAdded = function(character)
            -- Stop auto fling on character respawn
            if isFlinging then
                stopAutoFling()
            end
        end
    }
end
