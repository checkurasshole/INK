local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Remote = ReplicatedStorage.packages.Net["RE/SpearFishing/Minigame"]

-- // GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "COMBO_WICK - Fish Dupe"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 400, 0, 250)
Frame.Position = UDim2.new(0.5, -200, 0.7, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BackgroundTransparency = 0.08
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

-- Header bar
local Header = Instance.new("Frame", Frame)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "COMBO_WICK - Fish Dupe"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSansSemibold
Title.TextSize = 20

-- Minimize Button
local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 30, 0, 28)
MinBtn.Position = UDim2.new(1, -60, 0, 1)
MinBtn.Text = "▼"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
Instance.new("UICorner", MinBtn)

-- Close Button
local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 30, 0, 28)
CloseBtn.Position = UDim2.new(1, -30, 0, 1)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
Instance.new("UICorner", CloseBtn)

-- Content Container
local Content = Instance.new("Frame", Frame)
Content.Size = UDim2.new(1, 0, 1, -30)
Content.Position = UDim2.new(0, 0, 0, 30)
Content.BackgroundTransparency = 1

-- Description
local Description = Instance.new("TextLabel", Content)
Description.Size = UDim2.new(1, -10, 0, 50)
Description.Position = UDim2.new(0, 5, 0, 5)
Description.Text = "Set your Min, Max wait & Cooldown (seconds). Lower = faster, higher = slower."
Description.TextColor3 = Color3.fromRGB(230, 230, 230)
Description.TextWrapped = true
Description.BackgroundTransparency = 1
Description.Font = Enum.Font.SourceSans
Description.TextSize = 16

-- Start & Stop Buttons
local StartBtn = Instance.new("TextButton", Content)
StartBtn.Size = UDim2.new(0.45, 0, 0.2, 0)
StartBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
StartBtn.Text = "Start"
StartBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
StartBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", StartBtn)

local StopBtn = Instance.new("TextButton", Content)
StopBtn.Size = UDim2.new(0.45, 0, 0.2, 0)
StopBtn.Position = UDim2.new(0.5, 0, 0.25, 0)
StopBtn.Text = "Stop"
StopBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
StopBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", StopBtn)

-- Timer Label
local TimerLabel = Instance.new("TextLabel", Content)
TimerLabel.Size = UDim2.new(1, 0, 0, 30)
TimerLabel.Position = UDim2.new(0, 0, 0.5, 0)
TimerLabel.Text = "Cooldown: N/A"
TimerLabel.TextColor3 = Color3.new(1, 1, 1)
TimerLabel.BackgroundTransparency = 1
TimerLabel.TextSize = 18
TimerLabel.Font = Enum.Font.SourceSansSemibold

-- Custom Wait Inputs
local MinLabel = Instance.new("TextLabel", Content)
MinLabel.Size = UDim2.new(0.2, 0, 0, 25)
MinLabel.Position = UDim2.new(0.05, 0, 0.65, 0)
MinLabel.Text = "Min Wait:"
MinLabel.TextColor3 = Color3.new(1, 1, 1)
MinLabel.BackgroundTransparency = 1
MinLabel.TextSize = 16

local MinBox = Instance.new("TextBox", Content)
MinBox.Size = UDim2.new(0.15, 0, 0, 25)
MinBox.Position = UDim2.new(0.25, 0, 0.65, 0)
MinBox.Text = "1"
MinBox.TextColor3 = Color3.new(1, 1, 1)
MinBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Instance.new("UICorner", MinBox)

local MaxLabel = Instance.new("TextLabel", Content)
MaxLabel.Size = UDim2.new(0.2, 0, 0, 25)
MaxLabel.Position = UDim2.new(0.05, 0, 0.78, 0)
MaxLabel.Text = "Max Wait:"
MaxLabel.TextColor3 = Color3.new(1, 1, 1)
MaxLabel.BackgroundTransparency = 1
MaxLabel.TextSize = 16

local MaxBox = Instance.new("TextBox", Content)
MaxBox.Size = UDim2.new(0.15, 0, 0, 25)
MaxBox.Position = UDim2.new(0.25, 0, 0.78, 0)
MaxBox.Text = "2"
MaxBox.TextColor3 = Color3.new(1, 1, 1)
MaxBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Instance.new("UICorner", MaxBox)

local CooldownLabel = Instance.new("TextLabel", Content)
CooldownLabel.Size = UDim2.new(0.25, 0, 0, 25)
CooldownLabel.Position = UDim2.new(0.55, 0, 0.65, 0)
CooldownLabel.Text = "Cooldown:"
CooldownLabel.TextColor3 = Color3.new(1, 1, 1)
CooldownLabel.BackgroundTransparency = 1
CooldownLabel.TextSize = 16

local CooldownBox = Instance.new("TextBox", Content)
CooldownBox.Size = UDim2.new(0.15, 0, 0, 25)
CooldownBox.Position = UDim2.new(0.75, 0, 0.65, 0)
CooldownBox.Text = "5"
CooldownBox.TextColor3 = Color3.new(1, 1, 1)
CooldownBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Instance.new("UICorner", CooldownBox)

-- Coming Soon
local ComingSoon = Instance.new("TextLabel", Content)
ComingSoon.Size = UDim2.new(1, -10, 0, 25)
ComingSoon.Position = UDim2.new(0, 5, 0.9, 0)
ComingSoon.Text = "⚙️ More features coming soon. Stay tuned!"
ComingSoon.TextColor3 = Color3.fromRGB(180, 180, 180)
ComingSoon.BackgroundTransparency = 1
ComingSoon.TextSize = 15
ComingSoon.Font = Enum.Font.SourceSansItalic

-- Logic
local running = false
local minimized = false

local function startFarming()
	if running then return end
	running = true
	print("[COMBO_WICK] Started")

	task.spawn(function()
		while running do
			local minWait = tonumber(MinBox.Text) or 1
			local maxWait = tonumber(MaxBox.Text) or 2
			local cooldown = tonumber(CooldownBox.Text) or 5

			local char = LocalPlayer.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				char.HumanoidRootPart.CFrame = CFrame.new(-2585, 144, -1942)
			end

			for _, zone in next, CollectionService:GetTagged("SpearfishingZone") do
				local fishZone = zone:FindFirstChild("ZoneFish")
				if fishZone then
					for _, fish in next, fishZone:GetChildren() do
						task.spawn(function()
							local UID = fish:GetAttribute("UID")
							if UID then
								Remote:FireServer(UID)
								task.wait()
								Remote:FireServer(UID, true)
							end
						end)
						task.wait()
					end
				end
			end

			task.wait(math.random(minWait, maxWait))

			for i = cooldown, 1, -1 do
				if not running then break end
				TimerLabel.Text = "Cooldown: " .. i .. "s"
				task.wait(1)
			end
			TimerLabel.Text = "Cooldown: 0s"
		end
	end)
end

local function stopFarming()
	running = false
	TimerLabel.Text = "Cooldown: N/A"
	print("[COMBO_WICK] Stopped")
end

local function minimizeGUI()
	minimized = not minimized
	if minimized then
		Content.Visible = false
		Frame.Size = UDim2.new(0, 400, 0, 30)
		MinBtn.Text = "▲"
	else
		Content.Visible = true
		Frame.Size = UDim2.new(0, 400, 0, 250)
		MinBtn.Text = "▼"
	end
end

local function closeGUI()
	running = false
	ScreenGui:Destroy()
	print("[COMBO_WICK] Closed")
end

-- Button Connections
StartBtn.MouseButton1Click:Connect(startFarming)
StopBtn.MouseButton1Click:Connect(stopFarming)
MinBtn.MouseButton1Click:Connect(minimizeGUI)
CloseBtn.MouseButton1Click:Connect(closeGUI)

-- GUI Resize Logic
Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	local width = Frame.AbsoluteSize.X
	Description.Size = UDim2.new(0, width - 20, 0, 50)
end)
