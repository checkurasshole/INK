local M = {}

local RS          = game:GetService("ReplicatedStorage")
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local UIS         = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local ProMgs    = RS:WaitForChild("ProMgs",    9e9):WaitForChild("RemoteEvent", 9e9)
local MsgRemote = RS:WaitForChild("Msg",       9e9):WaitForChild("RemoteEvent", 9e9)
local ServerMsg = RS:WaitForChild("ServerMsg", 9e9):WaitForChild("Setting",     9e9)

local bag     = LocalPlayer:WaitForChild("Bag", 9e9)
local EnumMgr = require(RS:WaitForChild("Tool", 9e9):WaitForChild("EnumMgr", 9e9))

local MoneyObj = bag:WaitForChild(EnumMgr.ItemID.Coin, 9e9)
local WinsObj  = bag:WaitForChild(EnumMgr.ItemID.Wins, 9e9)

local function getMoneyNum()
    local raw = tostring(MoneyObj.Value):match("^[%d%.]+") or "0"
    return tonumber(raw) or 0
end

local function getWinsNum()
    local raw = tostring(WinsObj.Value):match("^[%d%.]+") or "0"
    return tonumber(raw) or 0
end

local captured = {
    isAutoOn       = nil,
    JumpResults1   = nil,
    TeleportMe     = nil,
    LandingResults = nil,
    JumpResults2   = nil,
}
local listening   = false
local allCaptured = false

local originalNamecall        = nil
local hookInstalled           = false
local customJumpVal           = nil
local customCFrameOverride    = nil
local settingKeybind          = false
local teleportKeybind         = Enum.KeyCode.F
local currentWorldName        = nil
local lastWorldName           = nil
local claimingWins            = false
local farmStalled             = false
local winsStalled             = false

local FARM_STALL_THRESHOLD = 3
local WINS_STALL_THRESHOLD = 3
local farmNoIncreaseCount  = 0
local winsNoIncreaseCount  = 0

local sharedStallActive = false
local sharedStallUntil  = 0

local LADDER_FOLDER_NAME = '\230\162\175\229\173\144\230\150\135\228\187\182\229\164\185'

M.Library               = nil
M.autoListenOnWorldChange = true
M.autoFireWait          = 5
M.claimWinsDelay        = 40
M.walkSpeed             = 16
M.speedLoopEnabled      = false
M.autoBuyEggsEnabled    = false
M.autoClaimWinsEnabled  = false
M.autoAwardEnabled      = false
M.autoSpinEnabled       = false
M.autoSpinDelay         = 86400
M.TOUCH_COUNT           = 1
M.TOUCH_DELAY           = 0.3

M.foundEggs          = {}
M.nearestEggId       = nil
M.nearestDistance    = math.huge
M.cachedTouchPart    = nil
M.cachedWorldName    = nil

M.getMoneyNum = getMoneyNum
M.getWinsNum  = getWinsNum

function M.getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function M.getCurrentWorld()
    local hrp = M.getHRP()
    if not hrp then return nil end
    local mainWorld = Workspace:FindFirstChild("MainWorld")
    if not mainWorld then return nil end
    local bestMap, closestDistance = nil, math.huge
    for _, map in pairs(mainWorld:GetChildren()) do
        if map:IsA("Model") then
            local cf, size = map:GetBoundingBox()
            local rel = cf:PointToObjectSpace(hrp.Position)
            if math.abs(rel.X) <= size.X/2
            and math.abs(rel.Y) <= size.Y/2
            and math.abs(rel.Z) <= size.Z/2 then
                local dist = (cf.Position - hrp.Position).Magnitude
                if dist < closestDistance then
                    closestDistance = dist
                    bestMap = map
                end
            end
        end
    end
    return bestMap
end

function M.getCurrentWorldName()
    return currentWorldName
end

function M.getLastWorldName()
    return lastWorldName
end

function M.isListening()
    return listening
end

function M.isAllCaptured()
    return allCaptured
end

function M.isClaimingWins()
    return claimingWins
end

function M.isSharedStallActive()
    return sharedStallActive
end

function M.getSharedStallUntil()
    return sharedStallUntil
end

function M.getSettingKeybind()
    return settingKeybind
end

function M.setSettingKeybind(val)
    settingKeybind = val
end

function M.getTeleportKeybind()
    return teleportKeybind
end

function M.setTeleportKeybind(key)
    teleportKeybind = key
end

function M.getCustomCFrameOverride()
    return customCFrameOverride
end

function M.setCustomCFrameOverride(cf)
    customCFrameOverride = cf
end

function M.getCaptured()
    return captured
end

function M.getCustomJumpVal()
    return customJumpVal
end

function M.setCustomJumpVal(val)
    customJumpVal = val
end

local function checkAllCaptured()
    return captured.isAutoOn
       and captured.JumpResults1
       and captured.TeleportMe
       and captured.LandingResults
       and captured.JumpResults2
end

local function isValid(obj)
    return obj and obj.Parent ~= nil
end

local function isGrounded()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local state = hum:GetState()
    return state == Enum.HumanoidStateType.Running
        or state == Enum.HumanoidStateType.Landed
        or state == Enum.HumanoidStateType.RunningNoPhysics
        or hum.FloorMaterial ~= Enum.Material.Air
end

local function waitUntilGrounded(timeout)
    timeout = timeout or 30
    local deadline = tick() + timeout
    while tick() < deadline do
        if isGrounded() then return true end
        task.wait(0.1)
    end
    return false
end

local function waitUntilGroundedSustained(seconds, timeout)
    local groundedFor = 0
    local deadline    = tick() + (timeout or 30)
    while tick() < deadline do
        if claimingWins then
            groundedFor = 0
            task.wait(0.5)
        elseif isGrounded() then
            groundedFor = groundedFor + 0.05
            if groundedFor >= seconds then return true end
            task.wait(0.05)
        else
            groundedFor = 0
            task.wait(0.05)
        end
    end
    return false
end

function M.fullReset()
    captured      = { isAutoOn=nil, JumpResults1=nil, TeleportMe=nil, LandingResults=nil, JumpResults2=nil }
    allCaptured   = false
    listening     = false
    customJumpVal = nil
    customCFrameOverride = nil
    farmNoIncreaseCount  = 0
    winsNoIncreaseCount  = 0
    sharedStallActive    = false
    sharedStallUntil     = 0
    farmStalled          = false
    winsStalled          = false
    if M.Library and M.Library.Toggles and M.Library.Toggles.AutoFarmToggle then
        M.Library.Toggles.AutoFarmToggle:SetValue(false)
    end
end

function M.triggerSharedStall(sourceLabel)
    if sharedStallActive then return end
    local pause = math.random(20, 30)
    sharedStallActive = true
    sharedStallUntil  = tick() + pause
    farmStalled       = true
    winsStalled       = true
    if M.Library then
        M.Library:Notify({
            Title       = "Stalled",
            Description = "No progress detected. Pausing both Cash & Wins for " .. pause .. "s...",
            Duration    = 5,
        })
    end
    if sourceLabel then
        sourceLabel:SetText("Status: Stalled — waiting " .. pause .. "s")
    end
    task.spawn(function()
        task.wait(pause)
        sharedStallActive = false
        sharedStallUntil  = 0
        farmStalled       = false
        winsStalled       = false
        farmNoIncreaseCount = 0
        winsNoIncreaseCount = 0
    end)
end

function M.waitOutSharedStall(statusLabel, labelText)
    while sharedStallActive do
        local remaining = math.max(0, math.ceil(sharedStallUntil - tick()))
        if statusLabel then
            statusLabel:SetText((labelText or "Status") .. ": Stalled — " .. remaining .. "s left")
        end
        task.wait(1)
    end
end

function M.installHook(JumpInput)
    if hookInstalled then return end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    originalNamecall = mt.__namecall
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}
        if listening then
            if method == "FireServer" and self == ProMgs then
                local key = args[1]; local id = args[2]; local val = args[3]
                if key == "JumpResults" and val and val > 0 and not captured.JumpResults1 then
                    captured.JumpResults1 = {id=id, value=val}
                elseif key == "JumpResults" and val and not captured.JumpResults2 and captured.LandingResults then
                    captured.JumpResults2 = {id=id, correction=val}
                elseif key == "LandingResults" and not captured.LandingResults then
                    captured.LandingResults = {id=id}
                end
            end
            if method == "FireServer" and self == MsgRemote then
                local key = args[1]; local cf = args[2]
                if key == "TeleportMe" and not captured.TeleportMe then
                    captured.TeleportMe = {cframe=cf}
                end
            end
            if method == "InvokeServer" and self == ServerMsg then
                local key = args[1]; local val = args[2]
                if key == "isAutoOn" and not captured.isAutoOn then
                    captured.isAutoOn = {value=val}
                end
            end
            if checkAllCaptured() then
                listening   = false
                allCaptured = true
                if JumpInput then
                    JumpInput:SetValue(tostring(math.clamp(math.floor(captured.JumpResults1.value), 0, 9999)))
                end
                customJumpVal = captured.JumpResults1.value
                if M.Library then
                    M.Library:Notify({Title="Ready!", Description="Captured! You can now farm wins.", Duration=4})
                end
            end
        end
        return originalNamecall(self, ...)
    end
    setreadonly(mt, true)
    hookInstalled = true
end

function M.startListening()
    if listening then return end
    captured    = { isAutoOn=nil, JumpResults1=nil, TeleportMe=nil, LandingResults=nil, JumpResults2=nil }
    allCaptured = false
    listening   = true
    if M.Library then
        M.Library:Notify({Title="Listening", Description="Now climb and jump once normally.", Duration=4})
    end
end

local function getCFrameToUse()
    if customCFrameOverride then return customCFrameOverride end
    return captured.TeleportMe and captured.TeleportMe.cframe
end

function M.fireSequence(jumpVal)
    if not allCaptured then
        if M.Library then
            M.Library:Notify({Title="Not Ready", Description="You need to capture first!", Duration=3})
        end
        return
    end

    local currentWorld = M.getCurrentWorld()
    if not currentWorld then
        if M.Library then
            M.Library:Notify({Title="Error", Description="Could not detect current tower.", Duration=3})
        end
        return
    end

    local cf = getCFrameToUse()
    if cf then
        local cfPos = cf.Position
        local worldCF, worldSize = currentWorld:GetBoundingBox()
        local rel = worldCF:PointToObjectSpace(cfPos)
        if math.abs(rel.X) > worldSize.X/2
        or math.abs(rel.Y) > worldSize.Y/2
        or math.abs(rel.Z) > worldSize.Z/2 then
            if M.Library then
                M.Library:Notify({Title="Wrong Tower", Description="Captured spot is from a different tower! Re-capture.", Duration=5})
            end
            M.fullReset()
            return
        end
    end

    local val = jumpVal or captured.JumpResults1.value
    ServerMsg:InvokeServer("isAutoOn", captured.isAutoOn.value)
    task.wait(0.1)
    ProMgs:FireServer("JumpResults", captured.JumpResults1.id, val)
    task.wait(0.1)
    MsgRemote:FireServer("TeleportMe", cf)
    task.wait(0.1)
    ProMgs:FireServer("LandingResults", captured.LandingResults.id)
    task.wait(0.1)
    ProMgs:FireServer("JumpResults", captured.JumpResults2.id, captured.JumpResults2.correction)
    task.wait(0.2)
end

local function getAllTrusses(world)
    local trusses = {}
    if not world then return trusses end
    local ladderFolder = world:FindFirstChild(LADDER_FOLDER_NAME)
    if not ladderFolder then return trusses end
    for _, child in ipairs(ladderFolder:GetChildren()) do
        if child.Name:match("^Ladder_%d+") then
            for _, part in ipairs(child:GetChildren()) do
                if part.Name == "Truss" and part:IsA("BasePart") then
                    table.insert(trusses, part)
                end
            end
        end
    end
    return trusses
end

local function getAllLadderParts(world)
    local parts = {}
    if not world then return parts end
    local ladderFolder = world:FindFirstChild(LADDER_FOLDER_NAME)
    if not ladderFolder then return parts end
    for _, child in ipairs(ladderFolder:GetChildren()) do
        if child.Name:match("^Ladder_%d+") then
            for _, part in ipairs(child:GetDescendants()) do
                if part:IsA("BasePart") then table.insert(parts, part) end
            end
        end
    end
    return parts
end

function M.disableLadder(world)
    local parts = getAllLadderParts(world)
    local saved = {}
    for _, part in ipairs(parts) do
        saved[part] = {CanCollide=part.CanCollide, Transparency=part.Transparency}
        part.CanCollide   = false
        part.Transparency = 0.9
    end
    return saved
end

function M.restoreLadder(saved)
    for part, state in pairs(saved) do
        if isValid(part) then
            part.CanCollide   = state.CanCollide
            part.Transparency = state.Transparency
        end
    end
end

function M.waitForCharacterReady()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart", 10)
    local hum  = char:WaitForChild("Humanoid", 10)
    if not hrp or not hum then return false end
    local deadline = tick() + 8
    while tick() < deadline do
        if hum.Health > 0 and hrp.Parent ~= nil then break end
        task.wait(0.1)
    end
    task.wait(1.0)
    return true
end

function M.doLadderDrop()
    local world = M.getCurrentWorld()
    if not world then return false end
    local trusses = getAllTrusses(world)
    if #trusses == 0 then return false end
    local hrp = M.getHRP()
    if not hrp then return false end
    local randomTruss = trusses[math.random(1, #trusses)]
    hrp.Anchored = true
    hrp.CFrame   = CFrame.new(randomTruss.Position + Vector3.new(0, 50, 0))
    task.wait(0.3)
    hrp.Anchored = false
    waitUntilGrounded(30)
    task.wait(0.3)
    return true
end

function M.doLadderDropThenListen()
    if not M.waitForCharacterReady() then
        if M.Library then
            M.Library:Notify({Title="Error", Description="Character not ready, try again.", Duration=4})
        end
        return
    end
    M.startListening()
    task.wait(0.5)
    if not M.doLadderDrop() then
        if M.Library then
            M.Library:Notify({Title="No Ladder Found", Description="Couldn't find the ladder. Jump manually!", Duration=4})
        end
    end
end

function M.getPlayerPos()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart.Position
    end
    return Vector3.new(0,0,0)
end

local function getObjPos(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") and obj.PrimaryPart then
        return obj.PrimaryPart.Position
    elseif obj:IsA("Model") then
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position end
    end
    return Vector3.new(0,0,0)
end

function M.findAllEggs()
    M.foundEggs = {}
    local playerPos = M.getPlayerPos()
    local function searchObject(obj, depth)
        if depth > 15 then return end
        local eggId = obj:FindFirstChild("EggId")
        if eggId and eggId.Value then
            local pos = getObjPos(obj)
            if (playerPos - pos).Magnitude <= 1000 then
                table.insert(M.foundEggs, {id=eggId.Value, position=pos})
            end
        end
        for _, child in ipairs(obj:GetChildren()) do
            searchObject(child, depth+1)
        end
    end
    searchObject(Workspace, 0)
end

function M.updateNearestEgg()
    if #M.foundEggs == 0 then return end
    local playerPos = M.getPlayerPos()
    M.nearestEggId    = nil
    M.nearestDistance = math.huge
    for _, egg in ipairs(M.foundEggs) do
        local d = (playerPos - egg.position).Magnitude
        if d < M.nearestDistance then
            M.nearestDistance = d
            M.nearestEggId    = egg.id
        end
    end
end

function M.executeEgg()
    if not M.nearestEggId then return end
    pcall(function()
        RS:WaitForChild("Tool",9e9)
          :WaitForChild("DrawUp",9e9)
          :WaitForChild("Msg",9e9)
          :WaitForChild("DrawHero",9e9)
          :InvokeServer(M.nearestEggId, 3)
    end)
end

function M.autoBuyEggsLoop()
    M.findAllEggs()
    local tick0 = tick()
    while M.autoBuyEggsEnabled do
        M.updateNearestEgg()
        M.executeEgg()
        task.wait(0.5)
        if tick() - tick0 >= 10 then
            M.findAllEggs()
            tick0 = tick()
        end
    end
end

local function simulateTouch(touchPart, hrp)
    if not touchPart or not hrp then return end
    for _ = 1, 3 do
        firetouchinterest(hrp, touchPart, 0)
        task.wait(0.05)
        firetouchinterest(hrp, touchPart, 1)
        task.wait(0.05)
    end
end

function M.findTouchPart()
    M.cachedTouchPart = nil
    M.cachedWorldName = nil
    local world = M.getCurrentWorld()
    if not world then return nil end
    local topPlatform = world:FindFirstChild("Top Platform")
    if not topPlatform then return nil end
    M.cachedWorldName = world.Name
    local hrp = M.getHRP()
    if not hrp then return nil end
    local cf, _ = topPlatform:GetBoundingBox()
    hrp.Anchored = true
    hrp.CFrame   = CFrame.new(cf.Position + Vector3.new(0, 50, 0))
    task.wait(0.1)
    hrp.Anchored = false
    task.wait(0.6)
    task.wait(0.5)
    local winsTouch = topPlatform:FindFirstChild("WinsTouch", true)
    if winsTouch then M.cachedTouchPart = winsTouch end
    return M.cachedTouchPart
end

function M.claimWinsOnce(statusLabel)
    claimingWins = true
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    if not hrp then
        if statusLabel then statusLabel:SetText("Status: No character") end
        claimingWins = false
        return
    end
    local originalCFrame = hrp.CFrame
    if statusLabel then statusLabel:SetText("Status: Finding top...") end
    local touchPart = M.findTouchPart()
    if not touchPart then
        if M.Library then
            M.Library:Notify({Title="Claim Wins", Description="Could not find the top of the tower!", Duration=3})
        end
        if statusLabel then statusLabel:SetText("Status: Top not found") end
        hrp.Anchored = false
        hrp.CFrame   = originalCFrame
        claimingWins = false
        return
    end
    if statusLabel then statusLabel:SetText("Status: Claiming wins...") end
    hrp.Anchored = true
    hrp.CFrame   = CFrame.new(touchPart.Position + Vector3.new(0, 50, 0))
    task.wait(0.1)
    hrp.Anchored = false
    task.wait(0.6)
    for i = 1, M.TOUCH_COUNT do
        simulateTouch(touchPart, hrp)
        task.wait(0.05)
        pcall(function() MsgRemote:FireServer('\233\162\134\229\143\150\230\169\188\233\161\182wins') end)
        task.wait(0.05)
        pcall(function() MsgRemote:FireServer('\232\181\183\232\183\179', -1.0614961385726929) end)
        if i < M.TOUCH_COUNT then task.wait(M.TOUCH_DELAY) end
    end
    if M.Library then
        M.Library:Notify({Title="Wins Claimed!", Description="Done!", Duration=3})
    end
    if statusLabel then statusLabel:SetText("Status: Returning to ladder...") end
    task.wait(0.3)
    hrp.CFrame   = originalCFrame
    hrp.Anchored = false
    if statusLabel then statusLabel:SetText("Status: Waiting to land...") end
    local landed = waitUntilGrounded(30)
    if not landed then
        if M.Library then
            M.Library:Notify({Title="Warning", Description="Landing timeout, resuming anyway.", Duration=3})
        end
    end
    task.wait(0.3)
    if statusLabel then statusLabel:SetText("Status: Done!") end
    claimingWins = false
end

function M.autoClaimWinsLoop(statusLabel)
    winsNoIncreaseCount = 0
    while M.autoClaimWinsEnabled do
        M.waitOutSharedStall(statusLabel, "Status")

        local winsBefore = getWinsNum()
        M.claimWinsOnce(statusLabel)
        if not M.autoClaimWinsEnabled then break end

        if getWinsNum() <= winsBefore then
            winsNoIncreaseCount = winsNoIncreaseCount + 1
            if winsNoIncreaseCount >= WINS_STALL_THRESHOLD then
                M.triggerSharedStall(statusLabel)
                winsNoIncreaseCount = 0
                M.waitOutSharedStall(statusLabel, "Status")
            end
        else
            winsNoIncreaseCount = 0
        end

        if not M.autoClaimWinsEnabled then break end
        local world = M.getCurrentWorld()
        local savedLadderState = {}
        if statusLabel then statusLabel:SetText("Status: Dropping to ladder...") end
        local dropped = M.doLadderDrop()
        if dropped and world then savedLadderState = M.disableLadder(world) end
        local elapsed = 0
        while elapsed < M.claimWinsDelay and M.autoClaimWinsEnabled do
            if statusLabel then
                statusLabel:SetText(string.format("Status: Next claim in %ds", M.claimWinsDelay - elapsed))
            end
            task.wait(1)
            elapsed = elapsed + 1
        end
        if world then M.restoreLadder(savedLadderState) end
        task.wait(0.5)
    end
    if statusLabel then statusLabel:SetText("Status: Off") end
end

function M.speedLoop()
    while M.speedLoopEnabled do
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum  = char:WaitForChild("Humanoid")
        pcall(function() hum.WalkSpeed = M.walkSpeed end)
        task.wait()
    end
end

function M.claimAllOnlineAwards()
    for i = 1, 12 do
        pcall(function()
            MsgRemote:FireServer("GetOnlineAward", i)
        end)
        task.wait(0.3)
    end
    if M.Library then
        M.Library:Notify({Title="Free Gifts", Description="All gifts claimed!", Duration=3})
    end
end

function M.autoAwardLoop()
    while M.autoAwardEnabled do
        M.claimAllOnlineAwards()
        local elapsed = 0
        while elapsed < 60 and M.autoAwardEnabled do
            task.wait(1)
            elapsed = elapsed + 1
        end
    end
end

function M.doSpin()
    pcall(function()
        RS:WaitForChild("System", 9e9)
          :WaitForChild("SystemDailyLottery", 9e9)
          :WaitForChild("Spin", 9e9)
          :InvokeServer()
    end)
    if M.Library then
        M.Library:Notify({Title="Spin", Description="Spin fired!", Duration=3})
    end
end

function M.autoSpinLoop()
    while M.autoSpinEnabled do
        M.doSpin()
        local elapsed = 0
        while elapsed < M.autoSpinDelay and M.autoSpinEnabled do
            task.wait(1)
            elapsed = elapsed + 1
        end
    end
end

function M.enableAntiAFK()
    if getconnections then
        for _, connection in pairs(getconnections(LocalPlayer.Idled)) do
            if connection["Disable"] then
                connection["Disable"](connection)
            elseif connection["Disconnect"] then
                connection["Disconnect"](connection)
            end
        end
    else
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end

function M.startAutoFarmLoop(farmNoIncreaseCountRef)
    farmNoIncreaseCount = 0
    task.spawn(function()
        while M.Library.Toggles.AutoFarmToggle.Value and not M.Library.Unloaded do
            M.waitOutSharedStall(nil, "Status")

            if claimingWins then
                task.wait(0.5)
            elseif not allCaptured then
                task.wait(0.5)
            elseif M.autoClaimWinsEnabled then
                local grounded = waitUntilGroundedSustained(1.0, 30)
                if not M.Library.Toggles.AutoFarmToggle.Value then break end
                if claimingWins or not grounded then
                    task.wait(0.1)
                else
                    local moneyBefore = getMoneyNum()
                    M.fireSequence(customJumpVal)
                    if not allCaptured then
                        task.wait(1)
                    else
                        task.spawn(function()
                            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                            local Humanoid  = Character:WaitForChild("Humanoid")
                            local RootPart  = Character:WaitForChild("HumanoidRootPart")
                            local duration  = math.random(5, 6)
                            local elapsed   = 0
                            local offsets   = {Vector3.new(5,0,0), Vector3.new(-5,0,0), Vector3.new(0,0,5), Vector3.new(0,0,-5)}
                            while elapsed < duration do
                                if not M.Library.Toggles.AutoFarmToggle.Value or claimingWins then break end
                                Humanoid:MoveTo(RootPart.Position + offsets[math.random(1, #offsets)])
                                task.wait(1)
                                elapsed = elapsed + 1
                            end
                            Humanoid:MoveTo(RootPart.Position)
                            Humanoid:Move(Vector3.new(0,0,0))
                        end)
                        task.wait(M.autoFireWait)
                        if getMoneyNum() <= moneyBefore then
                            farmNoIncreaseCount = farmNoIncreaseCount + 1
                            if farmNoIncreaseCount >= FARM_STALL_THRESHOLD then
                                M.triggerSharedStall(nil)
                                farmNoIncreaseCount = 0
                                M.waitOutSharedStall(nil, "Status")
                            end
                        else
                            farmNoIncreaseCount = 0
                        end
                    end
                end
            else
                local moneyBefore = getMoneyNum()
                M.fireSequence(customJumpVal)
                if not allCaptured then
                    task.wait(1)
                else
                    task.spawn(function()
                        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        local Humanoid  = Character:WaitForChild("Humanoid")
                        local RootPart  = Character:WaitForChild("HumanoidRootPart")
                        local duration  = math.random(5, 6)
                        local elapsed   = 0
                        local offsets   = {Vector3.new(5,0,0), Vector3.new(-5,0,0), Vector3.new(0,0,5), Vector3.new(0,0,-5)}
                        while elapsed < duration do
                            if not M.Library.Toggles.AutoFarmToggle.Value or claimingWins then break end
                            Humanoid:MoveTo(RootPart.Position + offsets[math.random(1, #offsets)])
                            task.wait(1)
                            elapsed = elapsed + 1
                        end
                        Humanoid:MoveTo(RootPart.Position)
                        Humanoid:Move(Vector3.new(0,0,0))
                    end)
                    task.wait(M.autoFireWait)
                    if getMoneyNum() <= moneyBefore then
                        farmNoIncreaseCount = farmNoIncreaseCount + 1
                        if farmNoIncreaseCount >= FARM_STALL_THRESHOLD then
                            M.triggerSharedStall(nil)
                            farmNoIncreaseCount = 0
                            M.waitOutSharedStall(nil, "Status")
                        end
                    else
                        farmNoIncreaseCount = 0
                    end
                end
            end
        end
    end)
end

function M.init(Library, JumpInput)
    M.Library = Library
    M.enableAntiAFK()
    M.installHook(JumpInput)

    task.spawn(function()
        if not M.waitForCharacterReady() then return end
        M.startListening()
        task.wait(0.5)
        if not M.doLadderDrop() then
            Library:Notify({Title="No Ladder Found", Description="Couldn't find the ladder. Jump manually!", Duration=4})
        end
    end)

    task.spawn(function()
        while true do
            task.wait(2)
            local world = M.getCurrentWorld()
            currentWorldName = world and world.Name or nil
            if currentWorldName and currentWorldName ~= lastWorldName then
                lastWorldName = currentWorldName
                M.fullReset()
                Library:Notify({
                    Title       = "New Tower!",
                    Description = currentWorldName .. (M.autoListenOnWorldChange and " | Setting up..." or ""),
                    Duration    = 4,
                })
                if M.autoListenOnWorldChange then
                    task.wait(1)
                    task.spawn(M.doLadderDropThenListen)
                end
            end
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        M.fullReset()
        lastWorldName = nil
    end)

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if settingKeybind then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                teleportKeybind = input.KeyCode
                settingKeybind = false
                if M.onKeybindSet then M.onKeybindSet(input.KeyCode) end
                Library:Notify({Title="Key Set!", Description="Press " .. input.KeyCode.Name .. " to save your spot.", Duration=3})
            end
            return
        end
        if teleportKeybind and input.KeyCode == teleportKeybind then
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            customCFrameOverride = root.CFrame
            local p = root.Position
            if M.onSpotSaved then M.onSpotSaved(p) end
            Library:Notify({Title="Spot Saved!", Description=string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z), Duration=3})
        end
    end)
end

M.onKeybindSet = nil
M.onSpotSaved  = nil

local function checkFn(name)
    return type(_G[name]) == "function" or type(getfenv()[name]) == "function"
end

M.requiredFns = {
    "getrawmetatable",
    "setreadonly",
    "getnamecallmethod",
    "firetouchinterest",
}
M.optionalFns = {
    "hookfunction",
    "isexecutorclosure",
    "getgc",
    "getsenv",
    "readfile",
    "writefile",
    "syn",
}

M.allRequiredPresent = true
M.missingRequired = {}
for _, name in ipairs(M.requiredFns) do
    if not checkFn(name) then
        M.allRequiredPresent = false
        table.insert(M.missingRequired, name)
    end
end

M.checkFn = checkFn

return M