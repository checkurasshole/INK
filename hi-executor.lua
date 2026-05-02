-- INK: simple executor script
-- Paste into your executor, or load it with loadstring(game:HttpGet(...))()

-- Basic print (shows in executor console)
print("hi")

-- Also show an in-game notification (works in most Roblox executors)
pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "INK",
		Text = "hi",
		Duration = 3
	})
end)
