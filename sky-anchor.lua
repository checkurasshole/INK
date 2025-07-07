-- Sky Anchor Teleport Module
return function(services)
    local MainTab = services.MainTab
    local LocalPlayer = services.LocalPlayer
    
    -- Create section
    local Section = MainTab:CreateSection('Sky Anchor Teleport')
    
    local skyTeleportEnabled = false
    local originalPosition = nil
    local anchorPart = nil

    MainTab:CreateToggle({
        Name = 'Safe Position Teleport',
        CurrentValue = false,
        Flag = 'SkyAnchorToggle',
        Callback = function(Value)
            skyTeleportEnabled = Value

            if skyTeleportEnabled then
                -- Save original position
                if
                    LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                then
                    originalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame

                    -- Create anchor part
                    anchorPart = Instance.new('Part')
                    anchorPart.Name = 'SkyAnchor'
                    anchorPart.Size = Vector3.new(4, 1, 4)
                    anchorPart.Material = Enum.Material.ForceField
                    anchorPart.BrickColor = BrickColor.new('Bright blue')
                    anchorPart.Anchored = true
                    anchorPart.CanCollide = true
                    anchorPart.Transparency = 0.5
                    anchorPart.CFrame = CFrame.new(
                        originalPosition.Position.X,
                        originalPosition.Position.Y + 1000,
                        originalPosition.Position.Z
                    )
                    anchorPart.Parent = workspace

                    -- Teleport to sky anchor
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
                        originalPosition.Position.X,
                        originalPosition.Position.Y + 1002,
                        originalPosition.Position.Z
                    )

                    print('Sky anchor created and teleported')
                end
            else
                -- Clean up anchor part
                if anchorPart then
                    anchorPart:Destroy()
                    anchorPart = nil
                end

                -- Teleport back to original position
                if
                    originalPosition
                    and LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = originalPosition
                    print('Teleported back to original position')
                end
            end
        end,
    })
    
    return {
        name = "Sky Anchor Teleport",
        version = "1.0.0",
        cleanup = function()
            if anchorPart then
                anchorPart:Destroy()
            end
        end
    }
end
