local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local TeleportService = game:GetService("TeleportService")

local function getLowestPopServer()
    local placeId = game.PlaceId
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if not success then return nil end
    local parsed = pcall(function() result = game:GetService("HttpService"):JSONDecode(result) end)
    if not parsed or type(result) ~= "table" or not result.data then return nil end

    local lowest = nil
    local lowestCount = math.huge
    for _, server in ipairs(result.data) do
        if server.id ~= game.JobId and server.playing and server.playing < lowestCount and server.playing >= 1 then
            lowestCount = server.playing
            lowest = server
        end
    end
    return lowest
end

local function hopToLowestServer()
    local server = getLowestPopServer()
    if server then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, localPlayer)
    end
end

local localPlayer = Players.LocalPlayer

local Config = {
    Enabled = false,
    Method = "2",
    TweenSpeed = 74,
    StuckThreshold = 0.5,
    StuckCheckTime = 0.5,
    AvoidPlayers = true,
    NormalWalkSpeed = 16,
    SearchTimeout = 25,
    AvoidPlayersIdle = false,
    IdleHideRadius = 41,
    FleeDistance = 200,
    AutoRespawn = true,
}

local AUTO_SPAWN_ENABLED = false
local SPAWN_ARGS = { [1] = "Gallimimus" }
local selectedDino = "Gallimimus"

local allDinosaurs = {
    "Acrocanthosaurus", "Albertosaurus", "Allosaurus", "Ankylosaurus",
    "Apatosaurus", "Baryonyx", "Brachiosaurus", "Carnotaurus",
    "Carcharodontosaurus", "Ceratosaurus", "Compsognathus", "Deinonychus",
    "Dilophosaurus", "Diplodocus", "Dreadnoughtus", "Gallimimus",
    "Giganotosaurus", "Invictus rex", "Mamenchisaurus", "Pachycephalosaurus",
    "Parasaurolophus", "Spinosaurus", "Stegosaurus", "Suchomimus",
    "Therizinosaurus", "Triceratops", "Tyrannosaurus", "Velociraptor", "Yutyrannus"
}

local FALL_Y_THRESHOLD = -15.29
local SPAWN_COOLDOWN = 5
local lastSpawnTime = 0
local isSpawning = false
local lastVisibleGuis = {}
local respawnConnection = nil

local farmingConnection = nil
local collisionConnection = nil
local noclipConnection = nil
local pauseUntil = 0
local isIdle = false
local isFleeing = false
local lastAmberSeenTime = 0
local currentSearchTarget = nil

local currentPathWaypoints = {}
local currentWpIndex = 1
local activePathTarget = nil
local isComputingPath = false
local activePath = nil
local pathFailed = false
local stuckCount = 0

local breadcrumbs = {}
local isBacktracking = false
local backtrackTargetIndex = 1

local blacklistCFrames = {
    CFrame.new(600.457031, 12.1469746, 462.948608, -0.503320456, 0, 0.864099801, 0, 1, 0, -0.864099801, 0, -0.503320456),
    CFrame.new(607.78064, 12.2486401, 482.832123, -0.503320456, 0, 0.864099801, 0, 1, 0, -0.864099801, 0, -0.503320456),
    CFrame.new(601.758728, 12.5266809, 422.436829, 0.966311634, -0, -0.257374942, 0, 1, -0, 0.257374942, 0, 0.966311634),
    CFrame.new(368.234131, 3.84528422, 18.5760651, -0.897348642, 0, 0.441323191, 0, 1, 0, -0.441323191, 0, -0.897348642),
    CFrame.new(366.980499, 4.02995682, 90.4777298, -0.0200414658, 0, 0.999799132, 0, 1, 0, -0.999799132, 0, -0.0200414658),
    CFrame.new(454.72403, 3.70452666, 56.3391113, -0.897348642, 0, 0.441323191, 0, 1, 0, -0.441323191, 0, -0.897348642),
    CFrame.new(388.77063, 7.46208096, 1298.16003, -0.817959785, 0, -0.575275481, 0, 1, 0, 0.575275481, 0, -0.817959785),
}

local POSITION_THRESHOLD = 3

local function isBlacklistedAmber(amber)
    local part = amber:IsA("BasePart") and amber or amber:FindFirstChildWhichIsA("BasePart")
    if not part then return false end
    local pos = part.Position
    for _, cf in ipairs(blacklistCFrames) do
        if (pos - cf.Position).Magnitude <= POSITION_THRESHOLD then
            return true
        end
    end
    return false
end

local ignoredAmbers = {}
pcall(function()
    local amberFolder = Workspace:FindFirstChild("ItemSpawn"):FindFirstChild("Amber")
    if amberFolder then
        for _, amber in pairs(amberFolder:GetChildren()) do
            if isBlacklistedAmber(amber) then
                ignoredAmbers[amber] = true
            end
        end
    end
end)

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function getHumanoid(char)
    return char:FindFirstChildWhichIsA("Humanoid")
end

local function getPosition(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then return obj:GetPivot().Position end
    if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    return nil
end

local function startNoclip()
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    noclipConnection = RunService.Stepped:Connect(function()
        if tick() < pauseUntil then return end
        local char = localPlayer.Character
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

local function executeInstantDespawn()
    pcall(function()
        ReplicatedStorage["shared/network/init@GlobalEvents"].despawn:FireServer()
    end)
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
    for path in pairs(currentGuis) do
        if not lastVisibleGuis[path] and string.find(string.lower(path), "playergui%.app") then
            table.insert(newAppGuis, path)
        end
    end
    return newAppGuis
end

local function executeSpawn()
    local currentTime = tick()
    if currentTime - lastSpawnTime < SPAWN_COOLDOWN then return false end
    if isSpawning then return false end
    isSpawning = true
    lastSpawnTime = currentTime
    pcall(function()
        ReplicatedStorage:WaitForChild("shared/network/init@GlobalEvents", 9e9)
            :WaitForChild("spawn", 9e9):FireServer(unpack(SPAWN_ARGS))
    end)
    isSpawning = false
    return true
end

local function scanForVisibleGuis()
    local currentGuis = {}
    local function scanGui(obj)
        if obj:IsA("GuiObject") and obj.Visible then
            currentGuis[getFullPath(obj)] = true
        end
        for _, sub in ipairs(obj:GetChildren()) do
            scanGui(sub)
        end
    end
    pcall(function() scanGui(localPlayer:WaitForChild("PlayerGui")) end)
    local spawned = false
    local newAppGuis = checkForNewAppGuis(currentGuis)
    if #newAppGuis > 0 then
        if AUTO_SPAWN_ENABLED then
            spawned = executeSpawn()
        elseif Config.AutoRespawn then
            local currentTime = tick()
            if not isSpawning and currentTime - lastSpawnTime >= SPAWN_COOLDOWN then
                isSpawning = true
                lastSpawnTime = currentTime
                pcall(function()
                    ReplicatedStorage:WaitForChild("shared/network/init@GlobalEvents", 9e9)
                        :WaitForChild("spawn", 9e9):FireServer(unpack(SPAWN_ARGS))
                end)
                isSpawning = false
                spawned = true
            end
        end
    end
    lastVisibleGuis = currentGuis
    return spawned
end

local function stopFarm()
    if farmingConnection then farmingConnection:Disconnect() farmingConnection = nil end
    if collisionConnection then collisionConnection:Disconnect() collisionConnection = nil end
    stopNoclip()
    local char = localPlayer.Character
    if char then
        local hum = getHumanoid(char)
        if hum then hum.WalkSpeed = Config.NormalWalkSpeed end
    end
    isFleeing = false
    currentSearchTarget = nil
    currentPathWaypoints = {}
    activePathTarget = nil
    breadcrumbs = {}
    isBacktracking = false
    stuckCount = 0
    isIdle = false
end

local function startFarm()
    if farmingConnection then return end

    local currentTargetPrompt = nil
    local lastCheckTime = tick()
    local lastCheckPos = Vector3.new(0, 0, 0)

    isFleeing = false
    currentSearchTarget = nil
    lastAmberSeenTime = tick()
    activePathTarget = nil
    breadcrumbs = {}
    isBacktracking = false
    pathFailed = false
    stuckCount = 0
    isIdle = false

    startNoclip()

    farmingConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not Config.Enabled then return end
        if tick() < pauseUntil then return end

        local char = localPlayer.Character
        if not char then return end
        local root = getRoot(char)
        local hum = getHumanoid(char)
        if not root or not hum or hum.Health <= 0 then return end

        if not isBacktracking then
            if #breadcrumbs == 0 or (root.Position - breadcrumbs[1]).Magnitude > 8 then
                table.insert(breadcrumbs, 1, root.Position)
                if #breadcrumbs > 100 then table.remove(breadcrumbs, 101) end
            end
        end

        if pathFailed and not isBacktracking then
            isBacktracking = true
            backtrackTargetIndex = 1
            pathFailed = false
        end

        if isBacktracking then
            if #breadcrumbs >= backtrackTargetIndex then
                local escapeTarget = breadcrumbs[backtrackTargetIndex]
                hum:MoveTo(escapeTarget)
                if Config.Method == "2" then
                    local eDir = escapeTarget - root.Position
                    local eFlat = Vector3.new(eDir.X, 0, eDir.Z)
                    local step = Config.TweenSpeed * deltaTime
                    if eFlat.Magnitude > 0 then
                        root.CFrame = root.CFrame + (eFlat.Magnitude < step and eFlat or eFlat.Unit * step)
                    end
                else
                    hum.WalkSpeed = Config.TweenSpeed
                end
                if (root.Position - escapeTarget).Magnitude < 6 then
                    backtrackTargetIndex = backtrackTargetIndex + 1
                    if backtrackTargetIndex > 15 or backtrackTargetIndex > #breadcrumbs then
                        isBacktracking = false
                        activePathTarget = nil
                        for _ = 1, backtrackTargetIndex do
                            if #breadcrumbs > 0 then table.remove(breadcrumbs, 1) end
                        end
                    end
                end
                if tick() - lastCheckTime > 0.6 then
                    if (root.Position - lastCheckPos).Magnitude < 1 then hum.Jump = true end
                    lastCheckPos = root.Position
                    lastCheckTime = tick()
                end
                return
            else
                isBacktracking = false
            end
        end

        local finalTargetPos = nil
        local forceMethod2 = false

        if Config.AvoidPlayersIdle then
            local closest, closestDist = nil, 99999
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= localPlayer and p.Character then
                    local r = getRoot(p.Character)
                    if r then
                        local d = (r.Position - root.Position).Magnitude
                        if d < closestDist then closestDist = d closest = r.Position end
                    end
                end
            end
            if closest and closestDist < Config.IdleHideRadius then
                local dirAway = Vector3.new((root.Position - closest).X, 0, (root.Position - closest).Z).Unit
                finalTargetPos = root.Position + (dirAway * Config.FleeDistance)
                if not isFleeing then
                    isFleeing = true
                    currentTargetPrompt = nil
                    currentSearchTarget = nil
                    activePathTarget = nil
                end
            elseif isFleeing then
                isFleeing = false
                lastAmberSeenTime = tick()
            end
        end

        if not isFleeing then
            if currentTargetPrompt and not currentTargetPrompt.Parent then
                currentTargetPrompt = nil
                activePathTarget = nil
                currentPathWaypoints = {}
            end

            if not currentTargetPrompt then
                local itemSpawn = Workspace:FindFirstChild("ItemSpawn")
                local amberFolder = itemSpawn and itemSpawn:FindFirstChild("Amber")
                local prompts = {}
                if amberFolder then
                    for _, amber in pairs(amberFolder:GetChildren()) do
                        if not ignoredAmbers[amber] and amber.Name == "AmberSpawn" then
                            local prompt = amber:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                local pos = getPosition(amber)
                                if pos then
                                    local params = RaycastParams.new()
                                    params.FilterType = Enum.RaycastFilterType.Exclude
                                    params.FilterDescendantsInstances = {localPlayer.Character, itemSpawn}
                                    local hit = Workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, 300, 0), params)
                                    local inside = hit and hit.Instance and (hit.Instance:IsA("Terrain") or hit.Instance.CanCollide)
                                    if not inside then
                                        table.insert(prompts, prompt)
                                    end
                                end
                            end
                        end
                    end
                end

                if #prompts > 0 then
                    currentSearchTarget = nil
                    lastAmberSeenTime = tick()
                    table.sort(prompts, function(a, b)
                        local pa = getPosition(a.Parent)
                        local pb = getPosition(b.Parent)
                        if pa and pb then
                            return (root.Position - pa).Magnitude < (root.Position - pb).Magnitude
                        end
                        return false
                    end)
                    currentTargetPrompt = prompts[1]
                    isIdle = false
                    if Config.AvoidPlayers then
                        if collisionConnection then collisionConnection:Disconnect() collisionConnection = nil end
                        collisionConnection = RunService.Stepped:Connect(function()
                            for _, p in pairs(Players:GetPlayers()) do
                                if p ~= localPlayer and p.Character then
                                    for _, part in pairs(p.Character:GetChildren()) do
                                        if part:IsA("BasePart") and part.CanCollide then
                                            part.CanCollide = false
                                        end
                                    end
                                end
                            end
                        end)
                    end
                else
                    if not isIdle then
                        isIdle = true
                        if collisionConnection then collisionConnection:Disconnect() collisionConnection = nil end
                        hum.WalkSpeed = Config.NormalWalkSpeed
                    end
                    if currentSearchTarget then
                        finalTargetPos = currentSearchTarget
                        forceMethod2 = true
                        if (root.Position - currentSearchTarget).Magnitude < 15 then
                            currentSearchTarget = nil
                            lastAmberSeenTime = tick()
                            finalTargetPos = nil
                        end
                    elseif (tick() - lastAmberSeenTime) > Config.SearchTimeout then
                        local rndX = math.random(-2000, 2000)
                        local rndZ = math.random(-2000, 2000)
                        local groundCheck = Workspace:Raycast(Vector3.new(rndX, 1000, rndZ), Vector3.new(0, -2000, 0))
                        currentSearchTarget = groundCheck and groundCheck.Position or Vector3.new(rndX, root.Position.Y, rndZ)
                    end
                end
            end

            if currentTargetPrompt and currentTargetPrompt.Parent then
                finalTargetPos = getPosition(currentTargetPrompt.Parent)
            end
        end

        if finalTargetPos then
            if not activePathTarget or (activePathTarget - finalTargetPos).Magnitude > 15 then
                if not isComputingPath then
                    isComputingPath = true
                    local capturedRoot = root.Position
                    task.spawn(function()
                        activePath = PathfindingService:CreatePath({
                            AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4
                        })
                        activePath.Blocked:Connect(function(bi)
                            if bi >= currentWpIndex then
                                activePathTarget = nil
                                currentPathWaypoints = {}
                            end
                        end)
                        local ok = pcall(function() activePath:ComputeAsync(capturedRoot, finalTargetPos) end)
                        if ok and activePath.Status == Enum.PathStatus.Success then
                            currentPathWaypoints = activePath:GetWaypoints()
                            currentWpIndex = 1
                        else
                            currentPathWaypoints = {{ Position = finalTargetPos, Action = Enum.PathWaypointAction.Walk }}
                            currentWpIndex = 1
                        end
                        activePathTarget = finalTargetPos
                        isComputingPath = false
                    end)
                end
            end

            local currentWaypoint = nil
            if #currentPathWaypoints > 0 and currentWpIndex <= #currentPathWaypoints then
                currentWaypoint = currentPathWaypoints[currentWpIndex]
                local wpFlat = Vector3.new(currentWaypoint.Position.X, root.Position.Y, currentWaypoint.Position.Z)
                if (root.Position - wpFlat).Magnitude < 4 then currentWpIndex = currentWpIndex + 1 end
            else
                if (root.Position - finalTargetPos).Magnitude > 15 then
                    if not isComputingPath then activePathTarget = nil currentPathWaypoints = {} end
                else
                    currentWaypoint = { Position = finalTargetPos, Action = Enum.PathWaypointAction.Walk }
                end
            end

            if currentWaypoint then
                local flatDist = (Vector3.new(finalTargetPos.X, 0, finalTargetPos.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
                local yDist = math.abs(finalTargetPos.Y - root.Position.Y)
                local reached = flatDist < 10 and yDist < 10

                if not reached then
                    local dir = currentWaypoint.Position - root.Position
                    hum:MoveTo(currentWaypoint.Position)
                    if currentWaypoint.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
                    if Config.Method == "2" or forceMethod2 then
                        local flatDir = Vector3.new(dir.X, 0, dir.Z)
                        local step = Config.TweenSpeed * deltaTime
                        if flatDir.Magnitude > 0 then
                            root.CFrame = root.CFrame + (flatDir.Magnitude < step and flatDir or flatDir.Unit * step)
                        end
                    else
                        hum.WalkSpeed = Config.TweenSpeed
                    end
                end

                if reached then
                    lastCheckPos = root.Position
                    lastCheckTime = tick()
                    if not isFleeing then
                        if currentTargetPrompt and currentTargetPrompt.Parent then
                            hum:MoveTo(root.Position)
                            if Config.Method == "1" then hum.WalkSpeed = Config.NormalWalkSpeed end

                            local function firePrompt(prompt)
                                if typeof(fireproximityprompt) == "function" then
                                    pcall(fireproximityprompt, prompt)
                                else
                                    pcall(function()
                                        prompt.HoldDuration = 0
                                        prompt:InputHoldBegin()
                                        task.wait(0.1)
                                        prompt:InputHoldEnd()
                                    end)
                                end
                            end

                            firePrompt(currentTargetPrompt)
                            currentTargetPrompt = nil
                            activePathTarget = nil
                            currentPathWaypoints = {}

                        elseif currentSearchTarget then
                            currentSearchTarget = nil
                            lastAmberSeenTime = tick()
                        end
                    end
                else
                    if tick() - lastCheckTime > Config.StuckCheckTime then
                        if (root.Position - lastCheckPos).Magnitude < Config.StuckThreshold then
                            stuckCount = stuckCount + 1
                            hum.Jump = true
                            if stuckCount >= 4 then
                                stuckCount = 0
                                pathFailed = true
                                activePathTarget = nil
                                currentPathWaypoints = {}
                            else
                                hum:Move(Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)), true)
                                activePathTarget = nil
                                currentPathWaypoints = {}
                                pauseUntil = tick() + 0.3
                            end
                        else
                            stuckCount = 0
                        end
                        lastCheckPos = root.Position
                        lastCheckTime = tick()
                    end
                end
            elseif isComputingPath then
                hum:MoveTo(root.Position)
                lastCheckTime = tick()
            end
        else
            if not isIdle and not isFleeing then
                hum.WalkSpeed = Config.NormalWalkSpeed
            end
        end
    end)
end

local startRespawnMonitor
startRespawnMonitor = function()
    if respawnConnection then respawnConnection:Disconnect() respawnConnection = nil end

    local function attachDeathListener(char)
        if not char then return end
        local hum = getHumanoid(char)
        if not hum then return end

        hum.Died:Connect(function()
            if not Config.AutoRespawn then return end
            local wasFarming = Config.Enabled
            stopFarm()
            executeInstantDespawn()

            task.spawn(function()
                task.wait(1.5)
                local attempts = 0
                while Config.AutoRespawn and attempts < 30 do
                    task.wait(0.8)
                    pcall(function() scanForVisibleGuis() end)

                    if attempts > 2 then
                        pcall(function() executeSpawn() end)
                    end

                    attempts = attempts + 1

                    local newChar = localPlayer.Character
                    if newChar then
                        local newRoot = newChar:FindFirstChild("HumanoidRootPart")
                        local newHum = getHumanoid(newChar)
                        if newRoot and newHum and newHum.Health > 0 and newRoot.Position.Y > FALL_Y_THRESHOLD then
                            task.wait(2.5)
                            if Config.AutoRespawn then
                                startRespawnMonitor()
                                if wasFarming and Config.Enabled then
                                    startFarm()
                                end
                            end
                            return
                        end
                    end
                end
                startRespawnMonitor()
            end)
        end)
    end

    respawnConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoRespawn then return end
        local char = localPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if root.Position.Y > FALL_Y_THRESHOLD then return end

        respawnConnection:Disconnect()
        respawnConnection = nil

        local wasFarming = Config.Enabled
        stopFarm()
        executeInstantDespawn()

        task.spawn(function()
            task.wait(2)
            local attempts = 0
            while Config.AutoRespawn and attempts < 20 do
                task.wait(1)
                pcall(function() scanForVisibleGuis() end)
                attempts = attempts + 1
                local newChar = localPlayer.Character
                if newChar then
                    local newRoot = newChar:FindFirstChild("HumanoidRootPart")
                    local newHum = getHumanoid(newChar)
                    if newRoot and newHum and newHum.Health > 0 and newRoot.Position.Y > FALL_Y_THRESHOLD then
                        task.wait(2)
                        startRespawnMonitor()
                        if wasFarming and Config.Enabled then startFarm() end
                        return
                    end
                end
            end
            startRespawnMonitor()
        end)
    end)

    attachDeathListener(localPlayer.Character)

    localPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(1)
        attachDeathListener(newChar)
    end)
end

-- Initialize background tasks
task.spawn(function()
    task.wait(2)
    while true do
        task.wait(0.8)
        pcall(scanForVisibleGuis)
    end
end)

startRespawnMonitor()

-- Return public API
return {
    Config = Config,
    startFarm = startFarm,
    stopFarm = stopFarm,
    executeSpawn = executeSpawn,
    hopToLowestServer = hopToLowestServer,
    startRespawnMonitor = startRespawnMonitor,
    setAutoSpawn = function(value)
        AUTO_SPAWN_ENABLED = value
        if value then lastVisibleGuis = {} end
    end,
}