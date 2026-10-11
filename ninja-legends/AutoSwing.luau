local Event = game:GetService("Players").LocalPlayer:WaitForChild("ninjaEvent")
local delay = 0.1

while task.wait(delay) do
    pcall(function()
        Event:FireServer("swingKatana")
    end)
end
