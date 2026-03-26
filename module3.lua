local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local folder = workspace:WaitForChild("Humanoids")

local OrgDestroyHeight = workspace.FallenPartsDestroyHeight
local antivoidloop = nil
local antivoidWasEnabled = false
local swimming = false
local oldgrav = workspace.Gravity
local swimbeat = nil
local gravReset = nil
local noclipConnection = nil
local isSwimmingToDestination = false
local swimDestination = Vector3.new(0, 0, 0)
local swimSpeed = 100
local processedPrompts = {}
local amberCollectionEnabled = false
local currentAmberTarget = nil
local isCollecting = false
local amberCollectionCoroutine = nil

local bossTeleportEnabled = false
local currentBossTarget = nil
local bossBehindDistance = 5
local bossTeleportConnection = nil

local antivoidEnabled = false
local voidDetectionLoop = nil
local floatingEnabled = false
local floatPart = nil
local floatName = "AmberFarmFloat_" .. math.random(1000, 9999)
local amberPausedForVoid = false
local staffwatchjoin = nil
local staffwatchEnabled = false
local antiAfkEnabled = false
local antiAfkConnections = {}
local lastCollectionTime = tick()
local collectionTimeout = 30
local noclipEnabled = false

local knockbackFlyEnabled = false
local knockbackFlyConnection = nil
local knockbackMoveVec = Vector3.zero
local knockbackSpeed = 8
local knockbackReturnPosition = Vector3.new(129.97, 470.59, 235.64)
local knockbackReturningToBase = false
local knockbackInputConnections = {}

local AUTO_SPAWN_ENABLED = false
local SPAWN_ARGS = { [1] = "Gallimimus" }
local selectedDino = "Gallimimus"

local SPAWN_ARGS = { [1] = "Gallimimus" }
local selectedDino = "Gallimimus"

local allDinosaurs = {
    "Acrocanthosaurus",
    "Albertosaurus",
    "Allosaurus",
    "Ankylosaurus",
    "Apatosaurus",
    "Baryonyx",
    "Brachiosaurus",
    "Carnotaurus",
    "Carcharodontosaurus",
    "Ceratosaurus",
    "Compsognathus",
    "Deinonychus",
    "Dilophosaurus",
    "Diplodocus",
    "Dreadnoughtus",
    "Gallimimus",
    "Giganotosaurus",
    "Invictus rex",
    "Mamenchisaurus",
    "Pachycephalosaurus",
    "Parasaurolophus",
    "Spinosaurus",
    "Stegosaurus",
    "Suchomimus",
    "Therizinosaurus",
    "Triceratops",
    "Tyrannosaurus",
    "Velociraptor",
    "Yutyrannus"
}

local lastVisibleGuis = {}
local SPAWN_COOLDOWN = 5
local lastSpawnTime = 0
local isSpawning = false

local espEnabled = false
local highlightEnabled = false
local teleporting = false
local npcTeleportEnabled = false
local currentTarget = nil
local currentNPCTarget = nil
local playerIndex = 1
local targetMovingPlayers = true
local targetStillPlayers = true
local behindDistance = 5
local npcBehindDistance = 5
local walkspeedEnabled = false
local customWalkspeed = 16
local HumanModCons = {}
local activeESPElements = {}
local activeHighlights = {}
local npcTeleportConnection = nil
local Connections = {}

local amberAttemptStartTime = 0
local amberAttemptTimeout = 15
local lastPlayerPosition = Vector3.new(0, 0, 0)
local stuckCheckCounter = 0
local stuckThreshold = 30
local v2SwitchedToV1 = false

local autoAttackEnabled = false
local autoHeavyEnabled = false
local autoAttackConnection = nil
local autoHeavyConnection = nil

-- Amber ESP variables
local amberESPEnabled = false
local activeAmberESP = {}
local amberESPConnections = {}
local amberESPPollCoroutine = nil

local function executeAutoAttack()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    pcall(function()
        local requestSkill = ReplicatedStorage["@rbxts/wcs:source/networking@GlobalEvents"].requestSkill
        requestSkill:FireServer({
            blobs = {
                0.5600000023841858,
                workspace:GetServerTimeNow(),
                false
            },
            buffer = buffer.fromstring("\8\0\0\0M1Attack\1\3\0\0\0\1\1\1")
        })
    end)
end

local function executeAutoHeavy()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    pcall(function()
        local onHeavyRequest = ReplicatedStorage["shared/network/init@GlobalEvents"].onHeavyRequest
        onHeavyRequest:FireServer()
    end)
end

local function executeInstantDespawn()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    pcall(function()
        local despawn = ReplicatedStorage["shared/network/init@GlobalEvents"].despawn
        despawn:FireServer()
    end)
end

local function toggleAutoAttack(value)
    autoAttackEnabled = value
    if value then
        if autoAttackConnection then
            autoAttackConnection:Disconnect()
        end
        autoAttackConnection = RunService.Heartbeat:Connect(function()
            if autoAttackEnabled then
                executeAutoAttack()
            end
        end)
        Connections.autoAttack = autoAttackConnection
    else
        if autoAttackConnection then
            autoAttackConnection:Disconnect()
            autoAttackConnection = nil
            Connections.autoAttack = nil
        end
    end
end

local function toggleAutoHeavy(value)
    autoHeavyEnabled = value
    if value then
        if autoHeavyConnection then
            autoHeavyConnection:Disconnect()
        end
        autoHeavyConnection = RunService.Heartbeat:Connect(function()
            if autoHeavyEnabled then
                executeAutoHeavy()
            end
        end)
        Connections.autoHeavy = autoHeavyConnection
    else
        if autoHeavyConnection then
            autoHeavyConnection:Disconnect()
            autoHeavyConnection = nil
            Connections.autoHeavy = nil
        end
    end
end

local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

local function enableAntiVoid()
    if antivoidloop then
        antivoidloop:Disconnect()
        antivoidloop = nil
    end
    antivoidloop = RunService.Stepped:Connect(function()
        local root = getRoot(localPlayer.Character)
        if root and root.Position.Y <= OrgDestroyHeight + 25 then
            root.Velocity = root.Velocity + Vector3.new(0, 250, 0)
        end
    end)
    Connections.antivoid = antivoidloop
    antivoidEnabled = true
end

local function disableAntiVoid()
    if antivoidloop then
        antivoidloop:Disconnect()
        antivoidloop = nil
        Connections.antivoid = nil
    end
    antivoidEnabled = false
end

local function fakeOut()
    local root = getRoot(localPlayer.Character)
    if not root then return end
    local oldpos = root.CFrame
    if antivoidloop then
        disableAntiVoid()
        antivoidWasEnabled = true
    end
    workspace.FallenPartsDestroyHeight = math.huge
    root.CFrame = CFrame.new(Vector3.new(0, OrgDestroyHeight - 25, 0))
    task.wait(1)
    root.CFrame = oldpos
    workspace.FallenPartsDestroyHeight = OrgDestroyHeight
    if antivoidWasEnabled then
        enableAntiVoid()
        antivoidWasEnabled = false
    end
end

local function executeSpawn()
    local currentTime = tick()
    if currentTime - lastSpawnTime < SPAWN_COOLDOWN then
        return false
    end
    if isSpawning then
        return false
    end
    isSpawning = true
    lastSpawnTime = currentTime
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("shared/network/init@GlobalEvents", 9e9):WaitForChild("spawn", 9e9):FireServer(unpack(SPAWN_ARGS))
    end)
    isSpawning = false
    return true
end

local function getFullPath(obj)
    local path = obj.Name
    local parent = obj.Parent
    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end
    return path
end

local function checkForNewAppGuis(currentGuis)
    local newAppGuis = {}
    for path, _ in pairs(currentGuis) do
        if not lastVisibleGuis[path] and string.find(string.lower(path), "playergui%.app") ~= nil then
            table.insert(newAppGuis, path)
        end
    end
    return newAppGuis
end

local function scanForVisibleGuis()
    if not AUTO_SPAWN_ENABLED then return end
    local currentGuis = {}
    local function scanGui(obj)
        if obj:IsA("GuiObject") and obj.Visible then
            local fullPath = getFullPath(obj)
            currentGuis[fullPath] = true
        end
        for _, sub in ipairs(obj:GetChildren()) do
            scanGui(sub)
        end
    end
    pcall(function()
        scanGui(localPlayer:WaitForChild("PlayerGui"))
    end)
    local newAppGuis = checkForNewAppGuis(currentGuis)
    if #newAppGuis > 0 then
        executeSpawn()
    end
    lastVisibleGuis = currentGuis
end

local function isAboveTerrain(position)
    local region = Region3.new(
        Vector3.new(position.X - 1, position.Y - 200, position.Z - 1),
        Vector3.new(position.X + 1, position.Y, position.Z + 1)
    )
    local terrainRegion = Workspace.Terrain:ReadVoxels(region, 4)
    local size = terrainRegion.Size
    for x = 1, size.X do
        for y = 1, size.Y do
            for z = 1, size.Z do
                if terrainRegion:get(x, y, z).Value > 0 then
                    return true
                end
            end
        end
    end
    return false
end

local function hasGroundBelow(position, maxDistance)
    maxDistance = maxDistance or 50
    if isAboveTerrain(position) then
        return true
    end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
    local raycastResult = Workspace:Raycast(position, Vector3.new(0, -maxDistance, 0), raycastParams)
    return raycastResult ~= nil
end

local function enableFloating()
    if floatingEnabled or not localPlayer.Character then return end
    local pchar = localPlayer.Character
    local root = getRoot(pchar)
    if not root then return end
    floatingEnabled = true
    floatPart = Instance.new('Part')
    floatPart.Name = floatName
    floatPart.Parent = pchar
    floatPart.Transparency = 1
    floatPart.Size = Vector3.new(2, 0.2, 1.5)
    floatPart.Anchored = true
    floatPart.CFrame = root.CFrame * CFrame.new(0, -3.1, 0)
    local floatConnection
    floatConnection = RunService.Heartbeat:Connect(function()
        if floatingEnabled and pchar:FindFirstChild(floatName) and getRoot(pchar) then
            floatPart.CFrame = getRoot(pchar).CFrame * CFrame.new(0, -3.1, 0)
        else
            if floatConnection then
                floatConnection:Disconnect()
            end
        end
    end)
end

local function disableFloating()
    if not floatingEnabled then return end
    floatingEnabled = false
    if floatPart then
        floatPart:Destroy()
        floatPart = nil
    end
    local pchar = localPlayer.Character
    if pchar and pchar:FindFirstChild(floatName) then
        pchar:FindFirstChild(floatName):Destroy()
    end
end

local function startVoidDetection()
    if voidDetectionLoop then
        voidDetectionLoop:Disconnect()
    end
    voidDetectionLoop = RunService.Heartbeat:Connect(function()
        local root = getRoot(localPlayer.Character)
        if not root then return end
        local position = root.Position
        local hasGround = hasGroundBelow(position, 100)
        if not hasGround then
            if amberCollectionEnabled and not amberPausedForVoid then
                amberPausedForVoid = true
            end
            if not floatingEnabled then
                enableFloating()
            end
        else
            if amberPausedForVoid then
                amberPausedForVoid = false
            end
            if floatingEnabled then
                disableFloating()
            end
        end
    end)
end

local function stopVoidDetection()
    if voidDetectionLoop then
        voidDetectionLoop:Disconnect()
        voidDetectionLoop = nil
    end
    disableFloating()
    amberPausedForVoid = false
end

local function getStaffRole(player)
    if game.CreatorType == Enum.CreatorType.Group then
        local groupId = game.CreatorId
        local success, role = pcall(function()
            return player:GetRoleInGroup(groupId)
        end)
        if success and role then
            local staffRoles = {"Owner", "Co-Owner", "Admin", "Administrator", "Moderator", "Mod", "Staff", "Developer", "Dev"}
            for _, staffRole in pairs(staffRoles) do
                if string.find(string.lower(role), string.lower(staffRole)) then
                    return {Staff = true, Role = role}
                end
            end
        end
    end
    return {Staff = false, Role = "Member"}
end

local function toggleStaffWatch(value)
    staffwatchEnabled = value
    if value then
        if staffwatchjoin then
            staffwatchjoin:Disconnect()
        end
        if game.CreatorType == Enum.CreatorType.Group then
            staffwatchjoin = Players.PlayerAdded:Connect(function(player)
                local result = getStaffRole(player)
            end)
            for _, player in pairs(Players:GetPlayers()) do
                local result = getStaffRole(player)
                if result.Staff then
                    print("@" .. player.Name .. " is a " .. result.Role)
                end
            end
        end
    else
        if staffwatchjoin then
            staffwatchjoin:Disconnect()
            staffwatchjoin = nil
        end
    end
end

local function enableAntiAfk()
    if antiAfkEnabled then return end
    antiAfkEnabled = true
    antiAfkConnections.virtualUser = game:GetService("UserInputService").InputBegan:Connect(function() end)
    antiAfkConnections.periodicInput = task.spawn(function()
        while antiAfkEnabled do
            task.wait(300)
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
    antiAfkConnections.characterMovement = task.spawn(function()
        while antiAfkEnabled do
            task.wait(600)
            local char = localPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                local originalPos = root.CFrame
                root.CFrame = originalPos + Vector3.new(0.1, 0, 0)
                task.wait(0.1)
                root.CFrame = originalPos
            end
        end
    end)
    antiAfkConnections.idleConnection = localPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function disableAntiAfk()
    antiAfkEnabled = false
    for name, connection in pairs(antiAfkConnections) do
        if connection then
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            else
                task.cancel(connection)
            end
        end
    end
    antiAfkConnections = {}
end

local function noclip()
    local character = localPlayer.Character
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

local function enableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    noclipConnection = RunService.Stepped:Connect(noclip)
    Connections.noclip = noclipConnection
    noclipEnabled = true
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
        Connections.noclip = nil
    end
    local character = localPlayer.Character
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
        end
    end
    noclipEnabled = false
end

local function startSwim()
    if not swimming and localPlayer and localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
        oldgrav = workspace.Gravity
        workspace.Gravity = 0
        local swimDied = function()
            workspace.Gravity = oldgrav
            swimming = false
            disableNoclip()
            Connections.swimDied = nil
        end
        local Humanoid = localPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        gravReset = Humanoid.Died:Connect(swimDied)
        Connections.swimDied = gravReset
        local enums = Enum.HumanoidStateType:GetEnumItems()
        table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
        for i, v in pairs(enums) do
            Humanoid:SetStateEnabled(v, false)
        end
        Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        swimbeat = RunService.Heartbeat:Connect(function()
            pcall(function()
                local hrp = localPlayer.Character.HumanoidRootPart
                local humanoid = localPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                if isSwimmingToDestination then
                    local currentPos = hrp.Position
                    local direction = (swimDestination - currentPos).Unit
                    local distance = (swimDestination - currentPos).Magnitude
                    if distance < 5 then
                        isSwimmingToDestination = false
                        hrp.Velocity = Vector3.new(0, 0, 0)
                    else
                        hrp.Velocity = direction * swimSpeed
                    end
                else
                    local moveVector = humanoid.MoveDirection
                    local camera = workspace.CurrentCamera
                    local cameraCFrame = camera.CFrame
                    local worldMoveVector = Vector3.new(0, 0, 0)
                    if moveVector.Magnitude > 0 then
                        local cameraRight = cameraCFrame.RightVector
                        local cameraForward = -cameraCFrame.LookVector
                        cameraRight = Vector3.new(cameraRight.X, 0, cameraRight.Z).Unit
                        cameraForward = Vector3.new(cameraForward.X, 0, cameraForward.Z).Unit
                        worldMoveVector = (cameraRight * moveVector.X + cameraForward * moveVector.Z)
                    end
                    local verticalMovement = 0
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        verticalMovement = 1
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        verticalMovement = -1
                    end
                    local finalMoveVector = Vector3.new(worldMoveVector.X, verticalMovement, worldMoveVector.Z)
                    if finalMoveVector.Magnitude > 0 then
                        hrp.Velocity = finalMoveVector.Unit * swimSpeed
                    else
                        hrp.Velocity = hrp.Velocity * 0.9
                    end
                end
            end)
        end)
        Connections.swimbeat = swimbeat
        enableNoclip()
        swimming = true
        return true
    end
    return false
end

local function stopSwim()
    if localPlayer and localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
        workspace.Gravity = oldgrav
        swimming = false
        isSwimmingToDestination = false
        if gravReset then
            gravReset:Disconnect()
            gravReset = nil
            Connections.swimDied = nil
        end
        if swimbeat then
            swimbeat:Disconnect()
            swimbeat = nil
            Connections.swimbeat = nil
        end
        disableNoclip()
        local Humanoid = localPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        local enums = Enum.HumanoidStateType:GetEnumItems()
        table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
        for i, v in pairs(enums) do
            Humanoid:SetStateEnabled(v, true)
        end
    end
end

local function swimToDestination(targetPosition)
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    local hrp = character.HumanoidRootPart
    local currentPos = hrp.Position
    local skyPosition = Vector3.new(currentPos.X, currentPos.Y + 100, currentPos.Z)
    hrp.CFrame = CFrame.new(skyPosition)
    isSwimmingToDestination = true
    swimDestination = targetPosition
    if not swimming then
        startSwim()
    end
end

local function moveTowardsTarget(targetPosition, stepSize, speed)
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local root = char.HumanoidRootPart
    if not targetPosition then return false end
    local currentPos = root.Position
    local targetPosAbove = Vector3.new(targetPosition.X, targetPosition.Y + 2, targetPosition.Z)
    local direction = (targetPosAbove - currentPos).Unit
    local distance = (targetPosAbove - currentPos).Magnitude
    if distance <= 8 then
        return true
    end
    local moveDistance = math.min(stepSize or 40, distance * 0.6)
    local newPos = currentPos + (direction * moveDistance)
    if newPos.Y > currentPos.Y then
        newPos = newPos + Vector3.new(0, 5, 0)
    end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(newPos, newPos + root.CFrame.LookVector)})
    tween.Completed:Connect(function()
        task.wait(0.05)
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end)
    tween:Play()
    tween.Completed:Wait()
    return false
end

local function getHumanoidRootPart(model)
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
end

local function isPlayerMoving(player)
    if not player or not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return false
    end
    return player.Character.Humanoid.MoveDirection.Magnitude > 0.1
end

local function isPlayerDead(player)
    return not player or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0
end

local function setWalkspeed(speed)
    if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
        local Char = localPlayer.Character
        local Human = Char:FindFirstChildWhichIsA("Humanoid")
        local function WalkSpeedChange()
            if Char and Human and walkspeedEnabled then
                Human.WalkSpeed = speed
            end
        end
        WalkSpeedChange()
        HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and nil) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
        Connections.wsLoop = HumanModCons.wsLoop
        HumanModCons.wsCA = (HumanModCons.wsCA and HumanModCons.wsCA:Disconnect() and nil) or localPlayer.CharacterAdded:Connect(function(nChar)
            Char, Human = nChar, nChar:WaitForChild("Humanoid")
            character = nChar
            hrp = nChar:WaitForChild("HumanoidRootPart")
            WalkSpeedChange()
            HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and nil) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
            Connections.wsLoop = HumanModCons.wsLoop
        end)
        Connections.wsCA = HumanModCons.wsCA
    end
end

local function toggleWalkspeed(value)
    walkspeedEnabled = value
    if value then
        setWalkspeed(customWalkspeed)
    else
        if HumanModCons.wsLoop then
            HumanModCons.wsLoop:Disconnect()
            HumanModCons.wsLoop = nil
            Connections.wsLoop = nil
        end
        if HumanModCons.wsCA then
            HumanModCons.wsCA:Disconnect()
            HumanModCons.wsCA = nil
            Connections.wsCA = nil
        end
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            localPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
end

local function updateWalkspeed(value)
    customWalkspeed = value
    if walkspeedEnabled then
        setWalkspeed(customWalkspeed)
    end
end

local function applyESP(model)
    if not model:IsA("Model") or not model:FindFirstChild("Humanoid") or not string.find(model.Name, "Goat") then return end
    if model:FindFirstChild("NPC_ESP") then return end
    local humanoid = model:FindFirstChild("Humanoid")
    local root = getHumanoidRootPart(model)
    if not root then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NPC_ESP"
    billboard.Adornee = root
    billboard.Size = UDim2.new(0, 80, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = model.Name
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard
    billboard.Parent = root
    activeESPElements[model] = billboard
    local connection
    connection = humanoid.Died:Connect(function()
        billboard:Destroy()
        activeESPElements[model] = nil
        if connection then
            Connections["ESP_" .. tostring(model)] = nil
            connection:Disconnect()
        end
    end)
    Connections["ESP_" .. tostring(model)] = connection
end

local function applyHighlight(model)
    if not model:IsA("Model") or not model:FindFirstChild("Humanoid") or not string.find(model.Name, "Goat") then return end
    if model:FindFirstChild("NPC_Highlight") then return end
    local humanoid = model:FindFirstChild("Humanoid")
    if not humanoid then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "NPC_Highlight"
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(100, 150, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model
    activeHighlights[model] = highlight
    local connection
    connection = humanoid.Died:Connect(function()
        highlight:Destroy()
        activeHighlights[model] = nil
        if connection then
            Connections["Highlight_" .. tostring(model)] = nil
            connection:Disconnect()
        end
    end)
    Connections["Highlight_" .. tostring(model)] = connection
end

local function toggleESP(value)
    espEnabled = value
    if value then
        for _, model in pairs(folder:GetChildren()) do
            applyESP(model)
        end
    else
        for model, billboard in pairs(activeESPElements) do
            if billboard and billboard.Parent then
                billboard:Destroy()
            end
            if Connections["ESP_" .. tostring(model)] then
                Connections["ESP_" .. tostring(model)]:Disconnect()
                Connections["ESP_" .. tostring(model)] = nil
            end
        end
        activeESPElements = {}
    end
end

local function toggleHighlight(value)
    highlightEnabled = value
    if value then
        for _, model in pairs(folder:GetChildren()) do
            applyHighlight(model)
        end
    else
        for model, highlight in pairs(activeHighlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
            if Connections["Highlight_" .. tostring(model)] then
                Connections["Highlight_" .. tostring(model)]:Disconnect()
                Connections["Highlight_" .. tostring(model)] = nil
            end
        end
        activeHighlights = {}
    end
end

local function getValidPlayers()
    local players = Players:GetPlayers()
    local validPlayers = {}
    for _, player in pairs(players) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
           player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local isMoving = isPlayerMoving(player)
            if (isMoving and targetMovingPlayers) or (not isMoving and targetStillPlayers) then
                table.insert(validPlayers, player)
            end
        end
    end
    return validPlayers
end

local function getNextTarget()
    local validPlayers = getValidPlayers()
    if #validPlayers == 0 then
        return nil
    end
    playerIndex = ((playerIndex - 1) % #validPlayers) + 1
    return validPlayers[playerIndex]
end

local function anchorToPlayer(targetPlayer)
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    local targetRoot = targetPlayer.Character.HumanoidRootPart
    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    local targetLookVector = targetRoot.CFrame.LookVector
    if targetHumanoid and targetHumanoid.MoveDirection.Magnitude > 0.1 then
        local moveDirection = targetHumanoid.MoveDirection
        targetLookVector = Vector3.new(moveDirection.X, 0, moveDirection.Z).Unit
    end
    local behindPosition = targetRoot.Position - (targetLookVector * behindDistance)
    behindPosition = Vector3.new(behindPosition.X, targetRoot.Position.Y, behindPosition.Z)
    local newCFrame = CFrame.lookAt(behindPosition, targetRoot.Position)
    localPlayer.Character.HumanoidRootPart.CFrame = newCFrame
    localPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    localPlayer.Character.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    localPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    localPlayer.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    return true
end

local function teleportLoop()
    if not teleporting then return end
    if not currentTarget or isPlayerDead(currentTarget) then
        currentTarget = getNextTarget()
        if currentTarget then
            anchorToPlayer(currentTarget)
        else
            task.wait(1)
            return
        end
    end
    if localPlayer.Character and currentTarget.Character then
        local myPosition = localPlayer.Character.HumanoidRootPart.Position
        local targetPosition = currentTarget.Character.HumanoidRootPart.Position
        local targetLookVector = currentTarget.Character.HumanoidRootPart.CFrame.LookVector
        local intendedPosition = targetPosition - (targetLookVector * behindDistance)
        local distanceFromIntended = (myPosition - intendedPosition).Magnitude
        if distanceFromIntended > 2 then
            anchorToPlayer(currentTarget)
        end
    end
end

local function getClosestNPC()
    local closest = nil
    local shortestDist = math.huge
    for _, npc in pairs(folder:GetChildren()) do
        if npc:IsA("Model") and npc.Name == "Goat" and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") and npc.Humanoid.Health > 0 then
            local dist = (npc.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closest = npc
            end
        end
    end
    return closest
end

local function anchorToNPC(targetNPC)
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    local targetRoot = targetNPC:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        return false
    end
    local dir = -(targetRoot.CFrame.LookVector) * npcBehindDistance
    hrp.CFrame = CFrame.new(targetRoot.Position + dir, targetRoot.Position)
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    return true
end

local function npcTeleportLoop()
    if not npcTeleportEnabled then return end
    if not currentNPCTarget or not currentNPCTarget:IsDescendantOf(workspace) or currentNPCTarget.Humanoid.Health <= 0 then
        currentNPCTarget = getClosestNPC()
        if not currentNPCTarget then
            return
        end
    end
    if hrp and currentNPCTarget.HumanoidRootPart then
        anchorToNPC(currentNPCTarget)
    end
end

local function toggleNPCTeleport(value)
    npcTeleportEnabled = value
    if value then
        currentNPCTarget = getClosestNPC()
        if currentNPCTarget then
            anchorToNPC(currentNPCTarget)
        end
        npcTeleportConnection = RunService.Heartbeat:Connect(function()
            npcTeleportLoop()
        end)
        Connections.npcTeleport = npcTeleportConnection
    else
        currentNPCTarget = nil
        if npcTeleportConnection then
            npcTeleportConnection:Disconnect()
            npcTeleportConnection = nil
            Connections.npcTeleport = nil
        end
    end
end

local function switchToNextNPC()
    local allNPCs = {}
    for _, npc in pairs(folder:GetChildren()) do
        if npc:IsA("Model") and npc.Name == "Goat" and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") and npc.Humanoid.Health > 0 then
            table.insert(allNPCs, npc)
        end
    end
    if #allNPCs == 0 then
        return nil
    elseif #allNPCs == 1 then
        return allNPCs[1]
    else
        for _, npc in pairs(allNPCs) do
            if npc ~= currentNPCTarget then
                return npc
            end
        end
        return allNPCs[1]
    end
end

local function deepSearchProximityPrompts(obj, path)
    local prompts = {}
    path = path or obj.Name
    if obj:IsA("ProximityPrompt") then
        table.insert(prompts, {prompt = obj, path = path, parent = obj.Parent})
        return prompts
    end
    for _, child in pairs(obj:GetChildren()) do
        local childPath = path .. "." .. child.Name
        local childPrompts = deepSearchProximityPrompts(child, childPath)
        for _, promptData in pairs(childPrompts) do
            table.insert(prompts, promptData)
        end
    end
    return prompts
end

local function getBestPosition(obj)
    local function findPartPosition(searchObj)
        if searchObj:IsA("BasePart") then
            return searchObj.Position
        elseif searchObj:IsA("Model") and searchObj.PrimaryPart then
            return searchObj.PrimaryPart.Position
        else
            for _, child in pairs(searchObj:GetChildren()) do
                if child:IsA("BasePart") then
                    return child.Position
                end
            end
        end
        return nil
    end
    local pos = findPartPosition(obj)
    if pos then return pos end
    local current = obj.Parent
    while current and current ~= Workspace do
        pos = findPartPosition(current)
        if pos then return pos end
        current = current.Parent
    end
    return nil
end

function getAllAmberPrompts()
    local itemSpawn = Workspace:FindFirstChild("ItemSpawn")
    if not itemSpawn then
        return {}
    end
    local amber = itemSpawn:FindFirstChild("Amber")
    if not amber then
        return {}
    end
    local allPrompts = {}
    for _, child in pairs(amber:GetChildren()) do
        if child.Name == "AmberSpawn" then
            local prompts = deepSearchProximityPrompts(child)
            for _, promptData in pairs(prompts) do
                local promptId = tostring(promptData.prompt)
                if not processedPrompts[promptId] and promptData.prompt.Parent and promptData.prompt.Enabled then
                    table.insert(allPrompts, promptData)
                end
            end
        end
    end
    return allPrompts
end

local function fireProximityPromptSwim(promptData)
    if not fireproximityprompt then
        return false
    end
    local prompt = promptData.prompt
    local promptId = tostring(prompt)
    if not prompt.Parent or not prompt.Enabled then
        processedPrompts[promptId] = true
        return false
    end
    local targetPosition = getBestPosition(prompt)
    if not targetPosition then
        processedPrompts[promptId] = true
        return false
    end
    if not swimming then
        startSwim()
        task.wait(0.2)
    end
    swimToDestination(targetPosition)
    local timeoutCounter = 0
    local maxTimeout = 50
    while isSwimmingToDestination and timeoutCounter < maxTimeout do
        task.wait(0.1)
        timeoutCounter = timeoutCounter + 1
        if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            hrp = localPlayer.Character.HumanoidRootPart
        end
    end
    if hrp and prompt.Parent and prompt.Enabled then
        local distance = (hrp.Position - targetPosition).Magnitude
        if distance < 20 then
            local success = false
            pcall(function()
                fireproximityprompt(prompt, 0, true)
                success = true
            end)
            task.wait(0.05)
            if prompt.Parent and prompt.Enabled and not success then
                pcall(function()
                    fireproximityprompt(prompt)
                    success = true
                end)
            end
            task.wait(0.05)
            if prompt.Parent and prompt.Enabled and not success then
                pcall(function()
                    fireproximityprompt(prompt, prompt.HoldDuration or 0)
                    success = true
                end)
            end
        end
    end
    processedPrompts[promptId] = true
    task.wait(0.1)
    return true
end

local function fireProximityPromptTween(promptData)
    if not fireproximityprompt then
        return false
    end
    local prompt = promptData.prompt
    local promptId = tostring(prompt)
    if not prompt.Parent or not prompt.Enabled then
        processedPrompts[promptId] = true
        return false
    end
    local targetPosition = getBestPosition(prompt)
    if not targetPosition then
        processedPrompts[promptId] = true
        return false
    end
    amberAttemptStartTime = tick()
    local maxAttempts = 6
    local attempts = 0
    while attempts < maxAttempts and amberCollectionEnabled do
        attempts = attempts + 1
        if not prompt.Parent or not prompt.Enabled then
            processedPrompts[promptId] = true
            return false
        end
        if tick() - amberAttemptStartTime > amberAttemptTimeout then
            processedPrompts[promptId] = true
            return false
        end
        for _, part in pairs(localPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        local isCloseEnough = moveTowardsTarget(targetPosition, 50, 5)
        task.wait(0.15)
        if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            hrp = localPlayer.Character.HumanoidRootPart
        end
        if hrp and prompt.Parent and prompt.Enabled then
            local targetPosAbove = Vector3.new(targetPosition.X, targetPosition.Y + 2, targetPosition.Z)
            local distance = (hrp.Position - targetPosAbove).Magnitude
            if distance < 30 then
                local success = false
                pcall(function()
                    fireproximityprompt(prompt, 0, true)
                    success = true
                end)
                task.wait(0.02)
                if prompt.Parent and prompt.Enabled and not success then
                    pcall(function()
                        fireproximityprompt(prompt)
                        success = true
                    end)
                end
                task.wait(0.02)
                if prompt.Parent and prompt.Enabled and not success then
                    pcall(function()
                        fireproximityprompt(prompt, prompt.HoldDuration or 0)
                        success = true
                    end)
                end
                if success then
                    lastCollectionTime = tick()
                end
                break
            end
        end
    end
    for _, part in pairs(localPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
        end
    end
    processedPrompts[promptId] = true
    task.wait(0.05)
    return true
end

local function amberCollectionLoopSwim()
    if not amberCollectionEnabled or isCollecting then 
        return 
    end
    isCollecting = true
    local availablePrompts = getAllAmberPrompts()
    if #availablePrompts > 0 then
        if hrp then
            table.sort(availablePrompts, function(a, b)
                local posA = getBestPosition(a.prompt)
                local posB = getBestPosition(b.prompt)
                if posA and posB then
                    local distA = (hrp.Position - posA).Magnitude
                    local distB = (hrp.Position - posB).Magnitude
                    return distA < distB
                end
                return false
            end)
        end
        currentAmberTarget = availablePrompts[1]
        fireProximityPromptSwim(currentAmberTarget)
    else
        processedPrompts = {}
        currentAmberTarget = nil
        stopSwim()
        task.wait(1)
    end
    isCollecting = false
end

local function amberCollectionLoopTween()
    if not amberCollectionEnabled then 
        return 
    end
    if amberPausedForVoid then
        return
    end
    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        hrp = localPlayer.Character.HumanoidRootPart
        local currentPos = hrp.Position
        local distanceMoved = (currentPos - lastPlayerPosition).Magnitude
        if distanceMoved < 0.5 then
            stuckCheckCounter = stuckCheckCounter + 1
        else
            stuckCheckCounter = 0
        end
        lastPlayerPosition = currentPos
        if stuckCheckCounter > stuckThreshold and not v2SwitchedToV1 then
            v2SwitchedToV1 = true
            return
        end
    end
    local availablePrompts = getAllAmberPrompts()
    if #availablePrompts > 0 then
        if hrp then
            table.sort(availablePrompts, function(a, b)
                local posA = getBestPosition(a.prompt)
                local posB = getBestPosition(b.prompt)
                if posA and posB then
                    local distA = (hrp.Position - posA).Magnitude
                    local distB = (hrp.Position - posB).Magnitude
                    return distA < distB
                end
                return false
            end)
        end
        currentAmberTarget = availablePrompts[1]
        fireProximityPromptTween(currentAmberTarget)
    else
        currentAmberTarget = nil
        processedPrompts = {}
    end
end

local function toggleAmberCollectionSwim(value)
    amberCollectionEnabled = value
    if value then
        processedPrompts = {}
        currentAmberTarget = nil
        amberCollectionCoroutine = task.spawn(function()
            while amberCollectionEnabled do
                pcall(function()
                    amberCollectionLoopSwim()
                end)
                task.wait(0.3)
            end
        end)
    else
        amberCollectionEnabled = false
        currentAmberTarget = nil
        isCollecting = false
        stopSwim()
        if amberCollectionCoroutine then
            task.cancel(amberCollectionCoroutine)
            amberCollectionCoroutine = nil
        end
    end
end

local function toggleAmberCollection(value)
    amberCollectionEnabled = value
    if value then
        lastCollectionTime = tick()
        enableAntiVoid()
        startVoidDetection()
        processedPrompts = {}
        currentAmberTarget = nil
        v2SwitchedToV1 = false
        stuckCheckCounter = 0
        lastPlayerPosition = Vector3.new(0, 0, 0)
        amberCollectionCoroutine = task.spawn(function()
            while amberCollectionEnabled do
                pcall(function()
                    if v2SwitchedToV1 then
                        amberCollectionLoopSwim()
                        if not swimming then
                            v2SwitchedToV1 = false
                            stuckCheckCounter = 0
                        end
                    else
                        amberCollectionLoopTween()
                    end
                end)
                task.wait(0.05)
            end
        end)
    else
        amberCollectionEnabled = false
        currentAmberTarget = nil
        amberPausedForVoid = false
        v2SwitchedToV1 = false
        stuckCheckCounter = 0
        stopVoidDetection()
        disableAntiVoid()
        if amberCollectionCoroutine then
            task.cancel(amberCollectionCoroutine)
            amberCollectionCoroutine = nil
        end
    end
end

local function stabilizeCharacter()
    local currentHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if currentHrp then
        currentHrp.RotVelocity = Vector3.zero
        currentHrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function applyKnockbackThrust()
    if not knockbackFlyEnabled then return end
    
    local currentHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not currentHrp then return end
    
    if knockbackMoveVec.Magnitude > 0 then
        local dir = workspace.CurrentCamera.CFrame:VectorToWorldSpace(knockbackMoveVec).Unit
        local thrust = dir * math.clamp(knockbackSpeed, 1, 20)
        thrust = Vector3.new(
            math.clamp(thrust.X, -10, 10),
            math.clamp(thrust.Y, -5, 5),
            math.clamp(thrust.Z, -10, 10)
        )
        pcall(function()
            local requestKnockback = game:GetService("ReplicatedStorage")["shared/network/init@GlobalEvents"].requestKnockback
            firesignal(requestKnockback.OnClientEvent, 15, 0.6, thrust)
        end)
    end
end

local function startKnockbackFly()
    knockbackFlyEnabled = true
    if knockbackFlyConnection then
        knockbackFlyConnection:Disconnect()
    end
    knockbackFlyConnection = RunService.Heartbeat:Connect(function()
        if knockbackFlyEnabled then
            stabilizeCharacter()
            applyKnockbackThrust()
        end
    end)
    Connections.knockbackFly = knockbackFlyConnection
end

local function stopKnockbackFly()
    knockbackFlyEnabled = false
    if knockbackFlyConnection then
        knockbackFlyConnection:Disconnect()
        knockbackFlyConnection = nil
        Connections.knockbackFly = nil
    end
end

local function moveToPositionKnockback(targetPosition)
    local currentHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not currentHrp then return false end
    
    local distance = (currentHrp.Position - targetPosition).Magnitude
    
    if distance < 10 then
        return true
    end
    
    local direction = (targetPosition - currentHrp.Position).Unit
    local thrust = direction * math.clamp(knockbackSpeed, 1, 20)
    thrust = Vector3.new(
        math.clamp(thrust.X, -10, 10),
        math.clamp(thrust.Y, -5, 5),
        math.clamp(thrust.Z, -10, 10)
    )
    
    pcall(function()
        local requestKnockback = game:GetService("ReplicatedStorage")["shared/network/init@GlobalEvents"].requestKnockback
        firesignal(requestKnockback.OnClientEvent, 15, 0.6, thrust)
    end)
    
    return false
end

local function moveToAmberKnockback(targetPosition)
    local currentHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not currentHrp then return false end
    
    local distance = (currentHrp.Position - targetPosition).Magnitude
    
    if distance < 20 then
        return true
    end
    
    local direction = (targetPosition - currentHrp.Position).Unit
    local thrust = direction * math.clamp(knockbackSpeed, 1, 20)
    thrust = Vector3.new(
        math.clamp(thrust.X, -10, 10),
        math.clamp(thrust.Y, -5, 5),
        math.clamp(thrust.Z, -10, 10)
    )
    
    pcall(function()
        local requestKnockback = game:GetService("ReplicatedStorage")["shared/network/init@GlobalEvents"].requestKnockback
        firesignal(requestKnockback.OnClientEvent, 15, 0.6, thrust)
    end)
    
    return false
end

local function amberCollectionLoopKnockback()
    if not amberCollectionEnabled then return end
    
    local currentHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not currentHrp then return end
    
    local availablePrompts = getAllAmberPrompts()
    
    if #availablePrompts > 0 then
        if not knockbackFlyEnabled then
            startKnockbackFly()
        end
        
        knockbackReturningToBase = false
        
        table.sort(availablePrompts, function(a, b)
            local posA = getBestPosition(a.prompt)
            local posB = getBestPosition(b.prompt)
            if posA and posB then
                local distA = (currentHrp.Position - posA).Magnitude
                local distB = (currentHrp.Position - posB).Magnitude
                return distA < distB
            end
            return false
        end)
        
        currentAmberTarget = availablePrompts[1]
        local targetPos = getBestPosition(currentAmberTarget.prompt)
        
        if targetPos then
            local isClose = moveToAmberKnockback(targetPos)
            
            if isClose then
                local prompt = currentAmberTarget.prompt
                local promptId = tostring(prompt)
                
                if prompt.Parent and prompt.Enabled then
                    pcall(function()
                        fireproximityprompt(prompt, 0, true)
                    end)
                    task.wait(0.02)
                    if prompt.Parent and prompt.Enabled then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                    end
                    processedPrompts[promptId] = true
                end
            end
        end
    else
        processedPrompts = {}
        currentAmberTarget = nil
        
        if not knockbackReturningToBase then
            knockbackReturningToBase = true
        end
        
        if knockbackReturningToBase then
            local reachedBase = moveToPositionKnockback(knockbackReturnPosition)
            
            if reachedBase then
                stopKnockbackFly()
                knockbackReturningToBase = false
            end
        end
    end
end

local function setupKnockbackInput()
    knockbackInputConnections.inputBegan = UserInputService.InputBegan:Connect(function(i, g)
        if g or not knockbackFlyEnabled then return end
        if i.KeyCode == Enum.KeyCode.W then knockbackMoveVec += Vector3.new(0, 0, -1) end
        if i.KeyCode == Enum.KeyCode.S then knockbackMoveVec += Vector3.new(0, 0, 1) end
        if i.KeyCode == Enum.KeyCode.A then knockbackMoveVec += Vector3.new(-1, 0, 0) end
        if i.KeyCode == Enum.KeyCode.D then knockbackMoveVec += Vector3.new(1, 0, 0) end
        if i.KeyCode == Enum.KeyCode.Space then knockbackMoveVec += Vector3.new(0, 1, 0) end
        if i.KeyCode == Enum.KeyCode.LeftControl then knockbackMoveVec += Vector3.new(0, -1, 0) end
    end)
    
    knockbackInputConnections.inputEnded = UserInputService.InputEnded:Connect(function(i)
        if not knockbackFlyEnabled then return end
        if i.KeyCode == Enum.KeyCode.W then knockbackMoveVec -= Vector3.new(0, 0, -1) end
        if i.KeyCode == Enum.KeyCode.S then knockbackMoveVec -= Vector3.new(0, 0, 1) end
        if i.KeyCode == Enum.KeyCode.A then knockbackMoveVec -= Vector3.new(-1, 0, 0) end
        if i.KeyCode == Enum.KeyCode.D then knockbackMoveVec -= Vector3.new(1, 0, 0) end
        if i.KeyCode == Enum.KeyCode.Space then knockbackMoveVec -= Vector3.new(0, 1, 0) end
        if i.KeyCode == Enum.KeyCode.LeftControl then knockbackMoveVec -= Vector3.new(0, -1, 0) end
    end)
    
    Connections.knockbackInputBegan = knockbackInputConnections.inputBegan
    Connections.knockbackInputEnded = knockbackInputConnections.inputEnded
end

local function toggleAmberCollectionKnockback(value)
    amberCollectionEnabled = value
    if value then
        processedPrompts = {}
        currentAmberTarget = nil
        knockbackReturningToBase = false
        enableNoclip()
        startKnockbackFly()
        setupKnockbackInput()
        
        amberCollectionCoroutine = task.spawn(function()
            while amberCollectionEnabled do
                pcall(function()
                    amberCollectionLoopKnockback()
                end)
                task.wait(0.05)
            end
        end)
    else
        amberCollectionEnabled = false
        currentAmberTarget = nil
        knockbackReturningToBase = false
        disableNoclip()
        stopKnockbackFly()
        
        for key, connection in pairs(knockbackInputConnections) do
            if connection then
                connection:Disconnect()
            end
        end
        knockbackInputConnections = {}
        
        if amberCollectionCoroutine then
            task.cancel(amberCollectionCoroutine)
            amberCollectionCoroutine = nil
        end
    end
end

local function getClosestBoss()
    local closest = nil
    local shortestDist = math.huge
    for _, npc in pairs(folder:GetChildren()) do
        if npc:IsA("Model") and npc.Name == "D-Rex Boss" and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") and npc.Humanoid.Health > 0 then
            local dist = (npc.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closest = npc
            end
        end
    end
    return closest
end

local function anchorToBoss(targetBoss)
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    local targetRoot = targetBoss:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        return false
    end
    local dir = -(targetRoot.CFrame.LookVector) * bossBehindDistance
    hrp.CFrame = CFrame.new(targetRoot.Position + dir, targetRoot.Position)
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    return true
end

local function bossTeleportLoop()
    if not bossTeleportEnabled then return end
    if not currentBossTarget or not currentBossTarget:IsDescendantOf(workspace) or currentBossTarget.Humanoid.Health <= 0 then
        currentBossTarget = getClosestBoss()
        if not currentBossTarget then
            return
        end
    end
    if hrp and currentBossTarget.HumanoidRootPart then
        anchorToBoss(currentBossTarget)
    end
end

local function toggleBossTeleport(value)
    bossTeleportEnabled = value
    if value then
        currentBossTarget = getClosestBoss()
        if currentBossTarget then
            anchorToBoss(currentBossTarget)
        end
        bossTeleportConnection = RunService.Heartbeat:Connect(function()
            bossTeleportLoop()
        end)
        Connections.bossTeleport = bossTeleportConnection
    else
        currentBossTarget = nil
        if bossTeleportConnection then
            bossTeleportConnection:Disconnect()
            bossTeleportConnection = nil
            Connections.bossTeleport = nil
        end
    end
end

local function switchToNextBoss()
    local allBosses = {}
    for _, npc in pairs(folder:GetChildren()) do
        if npc:IsA("Model") and npc.Name == "D-Rex Boss" and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") and npc.Humanoid.Health > 0 then
            table.insert(allBosses, npc)
        end
    end
    if #allBosses == 0 then
        return nil
    elseif #allBosses == 1 then
        return allBosses[1]
    else
        for _, npc in pairs(allBosses) do
            if npc ~= currentBossTarget then
                return npc
            end
        end
        return allBosses[1]
    end
end

-- Amber ESP functions
local function showAmberESP(amber)
    if activeAmberESP[amber] then return end

    local prompts = deepSearchProximityPrompts(amber)
    if #prompts == 0 then return end
    local promptData = prompts[1]
    if not promptData or not promptData.prompt or not promptData.prompt.Enabled then return end

    local part = amber:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = amber
    highlight.FillColor = Color3.fromRGB(255, 200, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = amber

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 120, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 6, 0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🟡 AMBER READY"
    label.TextColor3 = Color3.fromRGB(255, 210, 0)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard
    billboard.Parent = part

    activeAmberESP[amber] = {highlight, billboard}
end

local function hideAmberESP(amber)
    if activeAmberESP[amber] then
        for _, el in pairs(activeAmberESP[amber]) do
            if el and el.Parent then el:Destroy() end
        end
        activeAmberESP[amber] = nil
    end
end

local function trackAmber(amber)
    if amber.Name ~= "AmberSpawn" then return end
    if amberESPConnections[amber] then return end

    local prompts = deepSearchProximityPrompts(amber)
    if #prompts == 0 then return end
    local promptData = prompts[1]
    if not promptData or not promptData.prompt then return end
    local prompt = promptData.prompt

    if prompt.Enabled then
        showAmberESP(amber)
    end

    amberESPConnections[amber] = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not amberESPEnabled then return end
        if prompt.Enabled then
            showAmberESP(amber)
        else
            hideAmberESP(amber)
        end
    end)
end

local function untrackAmber(amber)
    hideAmberESP(amber)
    if amberESPConnections[amber] then
        amberESPConnections[amber]:Disconnect()
        amberESPConnections[amber] = nil
    end
end

local function setupAmberNode(amber)
    if amber.Name ~= "AmberSpawn" then return end

    if amberESPConnections[amber] then
        amberESPConnections[amber]:Disconnect()
        amberESPConnections[amber] = nil
    end

    local prompts = deepSearchProximityPrompts(amber)
    if #prompts == 0 then return end
    local prompt = prompts[1].prompt
    if not prompt or not prompt.Parent then return end

    if prompt.Enabled then
        showAmberESP(amber)
    else
        hideAmberESP(amber)
    end

    amberESPConnections[amber] = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not amberESPEnabled then return end
        if prompt.Enabled then
            showAmberESP(amber)
        else
            hideAmberESP(amber)
        end
    end)
end

local function toggleAmberESP(value)
    amberESPEnabled = value

    if Connections.amberESPHeartbeat then
        Connections.amberESPHeartbeat:Disconnect()
        Connections.amberESPHeartbeat = nil
    end
    if Connections.amberESPChildAdded then
        Connections.amberESPChildAdded:Disconnect()
        Connections.amberESPChildAdded = nil
    end
    if Connections.amberESPChildRemoved then
        Connections.amberESPChildRemoved:Disconnect()
        Connections.amberESPChildRemoved = nil
    end
    for amber in pairs(amberESPConnections) do
        untrackAmber(amber)
    end

    if not value then return end

    local iSpawn = Workspace:FindFirstChild("ItemSpawn")
    local aFolder = iSpawn and iSpawn:FindFirstChild("Amber")

    if aFolder then
        for _, amber in pairs(aFolder:GetChildren()) do
            setupAmberNode(amber)
        end

        Connections.amberESPChildAdded = aFolder.ChildAdded:Connect(function(amber)
            task.wait(0.3)
            if amberESPEnabled then
                setupAmberNode(amber)
            end
        end)

        Connections.amberESPChildRemoved = aFolder.ChildRemoving:Connect(function(amber)
            untrackAmber(amber)
        end)
    end

    local hbTick = 0
    Connections.amberESPHeartbeat = RunService.Heartbeat:Connect(function(dt)
        hbTick = hbTick + dt
        if hbTick < 1 then return end
        hbTick = 0

        local is = Workspace:FindFirstChild("ItemSpawn")
        local af = is and is:FindFirstChild("Amber")
        if not af then return end

        for _, amber in pairs(af:GetChildren()) do
            if amber.Name == "AmberSpawn" then
                if not amberESPConnections[amber] then
                    setupAmberNode(amber)
                else
                    local prompts = deepSearchProximityPrompts(amber)
                    if #prompts > 0 then
                        local prompt = prompts[1].prompt
                        if prompt and prompt.Parent then
                            if prompt.Enabled then
                                showAmberESP(amber)
                            else
                                hideAmberESP(amber)
                            end
                        end
                    end
                end
            end
        end

        for amber in pairs(activeAmberESP) do
            if not amber.Parent then
                hideAmberESP(amber)
            end
        end
    end)
end

local function cleanup()
    for key, connection in pairs(Connections) do
        if connection then
            connection:Disconnect()
            Connections[key] = nil
        end
    end
    stopSwim()
    toggleWalkspeed(false)
    toggleNPCTeleport(false)
    toggleAmberCollection(false)
    toggleAmberCollectionSwim(false)
    toggleESP(false)
    toggleHighlight(false)
    teleporting = false
    currentTarget = nil
    disableAntiVoid()
	toggleBossTeleport(false)
    stopVoidDetection()
    toggleStaffWatch(false)
    disableAntiAfk()
    disableNoclip()
    AUTO_SPAWN_ENABLED = false
	stopKnockbackFly()
    for key, connection in pairs(knockbackInputConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    knockbackInputConnections = {}
end

Connections.childAdded = folder.ChildAdded:Connect(function(model)
    task.wait(0.2)
    if espEnabled then
        applyESP(model)
    end
    if highlightEnabled then
        applyHighlight(model)
    end
end)

Connections.charAdded = localPlayer.CharacterAdded:Connect(function(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
    if walkspeedEnabled then
        task.wait(1)
        setWalkspeed(customWalkspeed)
    end
    if swimming then
        task.wait(1)
        startSwim()
    end
end)

Connections.charRemoving = localPlayer.CharacterRemoving:Connect(function()
    stopSwim()
end)

Connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
    if teleporting and currentTarget == player then
        currentTarget = getNextTarget()
        if currentTarget then
            anchorToPlayer(currentTarget)
        end
    end
end)

Connections.teleportLoop = RunService.Heartbeat:Connect(function()
    if teleporting and currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
        teleportLoop()
    end
end)

task.spawn(function()
    task.wait(2)
    scanForVisibleGuis()
    while true do
        task.wait(1)
        pcall(scanForVisibleGuis)
    end
end)

-- ============================================================
-- Public API
-- ============================================================
return {
    -- Core toggles
    toggleWalkspeed          = toggleWalkspeed,
    updateWalkspeed          = updateWalkspeed,
    toggleESP                = toggleESP,
    toggleHighlight          = toggleHighlight,
    toggleNPCTeleport        = toggleNPCTeleport,
    toggleBossTeleport       = toggleBossTeleport,
    toggleAutoAttack         = toggleAutoAttack,
    toggleAutoHeavy          = toggleAutoHeavy,
    toggleAmberESP           = toggleAmberESP,
    toggleAmberCollection    = toggleAmberCollection,
    toggleAmberCollectionSwim = toggleAmberCollectionSwim,
    toggleStaffWatch         = toggleStaffWatch,
    enableAntiVoid           = enableAntiVoid,
    disableAntiVoid          = disableAntiVoid,
    enableNoclip             = enableNoclip,
    disableNoclip            = disableNoclip,
    enableAntiAfk            = enableAntiAfk,
    disableAntiAfk           = disableAntiAfk,
    executeInstantDespawn    = executeInstantDespawn,
    executeSpawn             = executeSpawn,
    cleanup                  = cleanup,

    -- NPC helpers
    switchToNextNPC  = switchToNextNPC,
    anchorToNPC      = anchorToNPC,
    switchToNextBoss = switchToNextBoss,
    anchorToBoss     = anchorToBoss,

    -- Player teleport helpers
    getValidPlayers = getValidPlayers,
    getNextTarget   = getNextTarget,
    anchorToPlayer  = anchorToPlayer,

    -- Data
    allDinosaurs = allDinosaurs,

    -- State setters (used by UI callbacks to write internal locals)
    setTeleporting          = function(v) teleporting = v end,
    setCurrentTarget        = function(v) currentTarget = v end,
    setCurrentNPCTarget     = function(v) currentNPCTarget = v end,
    setCurrentBossTarget    = function(v) currentBossTarget = v end,
    setPlayerIndex          = function(v) playerIndex = v end,
    setNpcBehindDistance    = function(v) npcBehindDistance = v end,
    setBehindDistance       = function(v) behindDistance = v end,
    setBossBehindDistance   = function(v) bossBehindDistance = v end,
    setTargetMovingPlayers  = function(v) targetMovingPlayers = v end,
    setTargetStillPlayers   = function(v) targetStillPlayers = v end,
    setAutoSpawnEnabled     = function(v) AUTO_SPAWN_ENABLED = v end,
    setLastVisibleGuis      = function(v) lastVisibleGuis = v end,
    setSpawnArgs            = function(v) SPAWN_ARGS = v end,

    -- State getters
    getTeleporting         = function() return teleporting end,
    getCurrentTarget       = function() return currentTarget end,
    getCurrentNPCTarget    = function() return currentNPCTarget end,
    getCurrentBossTarget   = function() return currentBossTarget end,
    getTargetMovingPlayers = function() return targetMovingPlayers end,
    getTargetStillPlayers  = function() return targetStillPlayers end,
    getNpcTeleportEnabled  = function() return npcTeleportEnabled end,
    getBossTeleportEnabled = function() return bossTeleportEnabled end,
}