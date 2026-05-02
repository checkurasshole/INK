-- INK: hi-executor.lua
-- Simple executor-friendly test script.

local function notify(title, text, duration)
    local ok, err = pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title or "INK"),
            Text = tostring(text or "hi"),
            Duration = tonumber(duration) or 5,
        })
    end)

    if not ok then
        -- Fallback to console only if notifications are blocked
        warn("[INK] Notification failed: ", err)
    end
end

print("hi")
notify("INK", "hi", 5)
