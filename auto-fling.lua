-- Auto Fling Module for INK Game Script
return function(services)
    local MainTab = services.MainTab
    local LocalPlayer = services.LocalPlayer
    local RunService = services.RunService
    local Players = services.Players
    local Window = services.Window or services.Rayfield
    
    -- Create Auto Fling Tab
    local AutoFlingTab = Window:CreateTab('Auto Fling', 4483362458)
    
    -- Variables
    local autoFlingEnabled = false
    local excludedPlayers = {}
    local targetCount = 1
    local currentTargetIndex = 1
    local flingConnection = nil
    local teleportConnection = nil
    local originalPosition = nil
    local currentTarget = nil
    local flingDelay = 2 -- seconds between each fling
    local lastFlingTime = 0
    local playersProcessed = 0
    
    -- Auto Fling Section
    local AutoFlingSection = AutoFlingTab:CreateSection('Auto Fling Settings')
    
    -- Target Count Input
    AutoFlingTab:CreateInput({
        Name = 'Players to Target',
        PlaceholderText = 'Enter number (1-20)',
        RemoveTextAfterFocusLost = false,
        Flag = 'TargetCountInput',
        Callback = function(Text)
            local number = tonumber(Text)
            if number and number >= 1 and number <= 20 then
                targetCount = math.floor(number)
                print('Target count set to: ' .. targetCount)
            else
                print('Please enter a valid number between 1 and 20')
            end
        end,
    })
    
    -- Fling Delay Slider
    AutoFlingTab:CreateSlider({
        Name = 'Fling Delay (seconds)',
        Range = { 0.5, 10 },
        Increment = 0.1,
        CurrentValue = 2,
        Flag = 'FlingDelaySlider',
        Callback = function(Value)
            flingDelay = Value
            print('Fling delay set to: ' .. Value .. ' seconds')
        end,
    })
    
    -- Exclude List Section
    local ExcludeSection = AutoFlingTab:CreateSection('Exclude List')
    
    -- Add to Exclude List
    AutoFlingTab:CreateInput({
        Name = 'Add Player to Exclude List',
        PlaceholderText = 'Enter player name',
        RemoveTextAfterFocusLost = true,
        Flag = 'ExcludePlayerInput',
        Callback = function(Text)
            if Text and Text ~= '' then
                -- Find player with partial name match
                local targetPlayer = nil
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and string.find(string.lower(player.Name), string.lower(Text)) then
                        targetPlayer = player
                        break
                    end
                end
                
                if targetPlayer then
                    excludedPlayers[targetPlayer.UserId] = targetPlayer.Name
                    print('Added ' .. targetPlayer.Name .. ' to exclude list')
                    updateExcludeList()
                else
                    print('Player not found: ' .. Text)
                end
            end
        end,
    })
    
    -- Exclude List Display
    local ExcludeListLabel = AutoFlingTab:CreateLabel('Excluded Players: None')
    
    -- Function to update exclude list display
    function updateExcludeList()
        local excludedNames = {}
        for _, name in pairs(excludedPlayers) do
            table.insert(excludedNames, name)
        end
        
        if #excludedNames > 0 then
            ExcludeListLabel:Set('Excluded Players: ' .. table.concat(excludedNames, ', '))
        else
            ExcludeListLabel:Set('Excluded Players: None')
        end
    end
    
    -- Clear Exclude List
    AutoFlingTab:CreateButton({
        Name = 'Clear Exclude List',
        Callback = function()
            excludedPlayers = {}
            updateExcludeList()
            print('Exclude list cleared')
        end,
    })
    
    -- Auto Exclude Self
    AutoFlingTab:CreateButton({
        Name = 'Auto Exclude Self',
        Callback = function()
            excludedPlayers[LocalPlayer.UserId] = LocalPlayer.Name
            updateExcludeList()
            print('Added yourself to exclude list')
        end,
    })
    
    -- Control Section
    local ControlSection = AutoFlingTab:CreateSection('Auto Fling Control')
    
    -- Status Label
    local StatusLabel = AutoFlingTab:CreateLabel('Status: Ready')
    
    -- Progress Label
    local ProgressLabel = AutoFlingTab:CreateLabel('Progress: 0/0')
    
    -- Helper Functions
    local function updateStatus(status)
        StatusLabel:Set('Status: ' .. status)
        print('Auto Fling Status: ' .. status)
    end
    
    local function updateProgress()
        ProgressLabel:Set('Progress: ' .. playersProcessed .. '/' .. targetCount)
    end
    
    local function getValidTargets()
        local validTargets = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and 
               not excludedPlayers[player.UserId] and 
               player.Character and 
               player.Character:FindFirstChild('HumanoidRootPart') then
                table.insert(validTargets, player)
            end
        end
        return validTargets
    end
    
    local function teleportToPlayer(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild('HumanoidRootPart') then
            return false
        end
        
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
            return false
        end
        
        local targetPosition = targetPlayer.Character.HumanoidRootPart.CFrame
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetPosition * CFrame.new(0, 0, -3)
        
        return true
    end
    
    local function flingPlayer(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild('HumanoidRootPart') then
            return false
        end
        
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
            return false
        end
        
        local targetRoot = targetPlayer.Character.HumanoidRootPart
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        
        -- Apply fling force
        local bodyVelocity = Instance.new('BodyVelocity')
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(
            math.random(-100, 100),
            math.random(50, 150),
            math.random(-100, 100)
        )
        bodyVelocity.Parent = targetRoot
        
        -- Remove body velocity after short time
        game:GetService('Debris'):AddItem(bodyVelocity, 0.5)
        
        -- Also apply force to self for fling effect
        local myBodyVelocity = Instance.new('BodyVelocity')
        myBodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
        myBodyVelocity.Velocity = Vector3.new(
            math.random(-50, 50),
            0,
            math.random(-50, 50)
        )
        myBodyVelocity.Parent = myRoot
        
        game:GetService('Debris'):AddItem(myBodyVelocity, 0.3)
        
        return true
    end
    
    local function stopAutoFling()
        autoFlingEnabled = false
        if flingConnection then
            flingConnection:Disconnect()
            flingConnection = nil
        end
        if teleportConnection then
            teleportConnection:Disconnect()
            teleportConnection = nil
        end
        
        -- Return to original position
        if originalPosition and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
            LocalPlayer.Character.HumanoidRootPart.CFrame = originalPosition
        end
        
        currentTarget = nil
        updateStatus('Stopped')
    end
    
    -- Main Auto Fling Toggle
    AutoFlingTab:CreateToggle({
        Name = 'Start Auto Fling',
        CurrentValue = false,
        Flag = 'AutoFlingToggle',
        Callback = function(Value)
            if Value then
                -- Start auto fling
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
                    updateStatus('Error: No character found')
                    return
                end
                
                -- Save original position
                originalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
                
                -- Reset counters
                playersProcessed = 0
                currentTargetIndex = 1
                lastFlingTime = 0
                
                -- Get valid targets
                local validTargets = getValidTargets()
                if #validTargets == 0 then
                    updateStatus('Error: No valid targets found')
                    return
                end
                
                -- Limit target count to available players
                if targetCount > #validTargets then
                    targetCount = #validTargets
                    print('Target count limited to available players: ' .. targetCount)
                end
                
                autoFlingEnabled = true
                updateStatus('Starting...')
                updateProgress()
                
                -- Start the fling loop
                flingConnection = RunService.Heartbeat:Connect(function()
                    if not autoFlingEnabled then
                        return
                    end
                    
                    -- Check if we've processed enough players
                    if playersProcessed >= targetCount then
                        stopAutoFling()
                        updateStatus('Completed! Processed ' .. playersProcessed .. ' players')
                        return
                    end
                    
                    -- Check if enough time has passed for next fling
                    local currentTime = tick()
                    if currentTime - lastFlingTime < flingDelay then
                        return
                    end
                    
                    -- Get fresh list of valid targets
                    local validTargets = getValidTargets()
                    if #validTargets == 0 then
                        stopAutoFling()
                        updateStatus('No more valid targets')
                        return
                    end
                    
                    -- Get next target
                    local targetPlayer = validTargets[((currentTargetIndex - 1) % #validTargets) + 1]
                    if not targetPlayer then
                        currentTargetIndex = currentTargetIndex + 1
                        return
                    end
                    
                    -- Teleport to target
                    if teleportToPlayer(targetPlayer) then
                        updateStatus('Teleporting to ' .. targetPlayer.Name)
                        
                        -- Wait a bit then fling
                        task.wait(0.5)
                        
                        if flingPlayer(targetPlayer) then
                            updateStatus('Flinging ' .. targetPlayer.Name)
                            playersProcessed = playersProcessed + 1
                            updateProgress()
                            lastFlingTime = currentTime
                        end
                    end
                    
                    currentTargetIndex = currentTargetIndex + 1
                end)
                
            else
                -- Stop auto fling
                stopAutoFling()
            end
        end,
    })
    
    -- Manual Controls Section
    local ManualSection = AutoFlingTab:CreateSection('Manual Controls')
    
    -- Stop Button
    AutoFlingTab:CreateButton({
        Name = 'Emergency Stop',
        Callback = function()
            stopAutoFling()
        end,
    })
    
    -- Return to Original Position
    AutoFlingTab:CreateButton({
        Name = 'Return to Original Position',
        Callback = function()
            if originalPosition and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
                LocalPlayer.Character.HumanoidRootPart.CFrame = originalPosition
                updateStatus('Returned to original position')
            else
                updateStatus('No original position saved')
            end
        end,
    })
    
    -- Get Player Count
    AutoFlingTab:CreateButton({
        Name = 'Check Available Targets',
        Callback = function()
            local validTargets = getValidTargets()
            updateStatus('Available targets: ' .. #validTargets)
        end,
    })
    
    -- Initialize exclude list with self
    excludedPlayers[LocalPlayer.UserId] = LocalPlayer.Name
    updateExcludeList()
    
    -- Return module functions
    return {
        onCharacterAdded = function(character)
            -- Stop auto fling if character respawns
            if autoFlingEnabled then
                stopAutoFling()
                updateStatus('Stopped due to character respawn')
            end
        end
    }
end
