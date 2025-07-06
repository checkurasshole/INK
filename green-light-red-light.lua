-- Green Light Red Light Module
return function(services)
    local MainTab = services.MainTab
    local Players = services.Players
    local LocalPlayer = services.LocalPlayer
    
    -- Create section
    local Section = MainTab:CreateSection('Green Light Red Light')
    
    -- Teleport to Position Button
    MainTab:CreateButton({
        Name = 'Teleport to Position',
        Callback = function()
            local Players = game:GetService('Players')
            local LocalPlayer = Players.LocalPlayer

            -- The target CFrame (position + rotation)
            local targetCFrame = CFrame.new(
                -44.893211,
                1049.128174,
                113.800880, -- Position (X, Y, Z)
                0.148912,
                0,
                -0.988850, -- Rotation row 1
                -0,
                1,
                0, -- Rotation row 2
                0.988850,
                0,
                0.148912 -- Rotation row 3
            )

            -- Wait for character and teleport
            if
                not LocalPlayer.Character
                or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            then
                LocalPlayer.CharacterAdded:Wait()
                repeat
                    task.wait()
                until LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            end

            LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
            print('Teleported to position')
        end,
    })

    -- Help Others Button
    MainTab:CreateButton({
        Name = 'Help Others for Red Light Green Light',
        Callback = function()
            loadstring(
                game:HttpGet(
                    'https://raw.githubusercontent.com/caomod2077/Script/refs/heads/main/Ink%20game%20help%20players'
                )
            )()
            print('Help others script executed')
        end,
    })

    -- Teleport to End of Glass Button
    MainTab:CreateButton({
        Name = 'Teleport to End of Glass',
        Callback = function()
            local Players = game:GetService('Players')
            local LocalPlayer = Players.LocalPlayer

            -- Glass bridge end position
            local glassEndCFrame = CFrame.new(
                -205.163925,
                520.731262,
                -1535.641968,
                -0.999866,
                0.000000,
                0.016376,
                0.000000,
                1.000000,
                -0.000000,
                0.016376,
                0.000000,
                0.999866
            )

            -- Wait for character and teleport
            if
                not LocalPlayer.Character
                or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            then
                LocalPlayer.CharacterAdded:Wait()
                repeat
                    task.wait()
                until LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            end

            LocalPlayer.Character.HumanoidRootPart.CFrame = glassEndCFrame
            print('Teleported to end of glass bridge')
        end,
    })
    
    return {
        name = "Green Light Red Light",
        version = "1.0.0"
    }
end
