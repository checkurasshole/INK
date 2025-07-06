-- Emotes Module
return function(services)
    local MainTab = services.MainTab
    local LocalPlayer = services.LocalPlayer
    local ReplicatedStorage = services.ReplicatedStorage
    
    -- Create section
    local Section = MainTab:CreateSection('Emotes')
    
    -- Current playing animation track
    local currentEmoteTrack = nil
    
    -- Function to get available emotes
    local function getEmotesList()
        local emoteOptions = {"None"}
        
        -- Try to get emotes from ReplicatedStorage
        local success, emoteFolder = pcall(function()
            return ReplicatedStorage:WaitForChild("Animations", 5):WaitForChild("Emotes", 5)
        end)
        
        if success and emoteFolder then
            for _, emote in ipairs(emoteFolder:GetChildren()) do
                if emote:IsA("Animation") then
                    table.insert(emoteOptions, emote.Name)
                end
            end
        end
        
        return emoteOptions
    end

    -- Create emotes dropdown
    local EmotesDropdown = MainTab:CreateDropdown({
        Name = "Play Emote",
        Options = getEmotesList(),
        CurrentOption = {"None"},
        MultipleOptions = false,
        Flag = "EmotesDropdown",
        Callback = function(Options)
            local selectedEmote = Options[1]
            
            -- Stop current emote if playing
            if currentEmoteTrack then
                currentEmoteTrack:Stop()
                currentEmoteTrack = nil
            end
            
            -- If "None" is selected, just stop emotes
            if selectedEmote == "None" then
                return
            end
            
            -- Play selected emote
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                
                -- Try to find the emote
                local success, emoteFolder = pcall(function()
                    return ReplicatedStorage:WaitForChild("Animations", 5):WaitForChild("Emotes", 5)
                end)
                
                if success and emoteFolder then
                    local emoteAnimation = emoteFolder:FindFirstChild(selectedEmote)
                    if emoteAnimation and emoteAnimation:IsA("Animation") then
                        -- Stop all current animation tracks
                        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                            if track.Animation and track.Animation.Parent == emoteFolder then
                                track:Stop()
                            end
                        end
                        
                        -- Load and play the new emote
                        local animationTrack = humanoid:LoadAnimation(emoteAnimation)
                        animationTrack:Play()
                        currentEmoteTrack = animationTrack
                        
                        print("Playing emote: " .. selectedEmote)
                    else
                        print("Emote not found: " .. selectedEmote)
                    end
                else
                    print("Could not find emotes folder")
                end
            else
                print("Character or Humanoid not found")
            end
        end,
    })

    -- Button to refresh emotes list
    MainTab:CreateButton({
        Name = 'Refresh Emotes',
        Callback = function()
            local newEmotesList = getEmotesList()
            EmotesDropdown:Refresh(newEmotesList)
            print("Emotes list refreshed")
        end,
    })

    -- Button to stop all emotes
    MainTab:CreateButton({
        Name = 'Stop All Emotes',
        Callback = function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                
                -- Stop all playing animation tracks
                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                    track:Stop()
                end
                
                currentEmoteTrack = nil
                print("All emotes stopped")
            end
        end,
    })
    
    return {
        name = "Emotes",
        version = "1.0.0",
        onCharacterAdded = function(character)
            -- Reset current emote track on respawn
            currentEmoteTrack = nil
        end
    }
end
