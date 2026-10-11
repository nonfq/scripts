--[[
Custom Output
made by: @nonfq
]]--

local LogService = game:GetService("LogService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local outputGui = Instance.new("ScreenGui")
outputGui.Name = "CustomOutput"
outputGui.ResetOnSpawn = false
outputGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 200)
frame.Position = UDim2.new(0, 10, 1, -220)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = outputGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(44, 120, 224)
title.BorderSizePixel = 0
title.Text = "  output"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 1, 0)
closeBtn.Position = UDim2.new(1, -25, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Parent = title

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 45, 1, 0)
copyBtn.Position = UDim2.new(1, -70, 0, 0)
copyBtn.BackgroundTransparency = 1
copyBtn.Text = "copy"
copyBtn.TextColor3 = Color3.new(1, 1, 1)
copyBtn.Font = Enum.Font.Gotham
copyBtn.TextSize = 12
copyBtn.Parent = title

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 45, 1, 0)
clearBtn.Position = UDim2.new(1, -115, 0, 0)
clearBtn.BackgroundTransparency = 1
clearBtn.Text = "clear"
clearBtn.TextColor3 = Color3.new(1, 1, 1)
clearBtn.Font = Enum.Font.Gotham
clearBtn.TextSize = 12
clearBtn.Parent = title

local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local resizeHandle = Instance.new("TextLabel")
resizeHandle.Size = UDim2.new(0, 16, 0, 16)
resizeHandle.Position = UDim2.new(1, -16, 1, -16)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = "◢"
resizeHandle.TextColor3 = Color3.fromRGB(150, 150, 150)
resizeHandle.TextSize = 12
resizeHandle.Font = Enum.Font.Gotham
resizeHandle.ZIndex = 3
resizeHandle.Active = true
resizeHandle.Parent = frame

local resizing, resizeStart, startSize
resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        startSize = frame.AbsoluteSize
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStart
        local newWidth = math.max(250, startSize.X + delta.X)
        local newHeight = math.max(100, startSize.Y + delta.Y)
        frame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -8, 1, -33)
scrollFrame.Position = UDim2.new(0, 4, 0, 29)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(44, 120, 224)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = frame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = scrollFrame

local logCount = 0

local function log(msg, color)
    logCount += 1
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -6, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = "  " .. tostring(msg)
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.LayoutOrder = logCount
    label.Parent = scrollFrame

    task.defer(function()
        scrollFrame.CanvasPosition = Vector2.new(0, 999999)
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    outputGui:Destroy()
end)

copyBtn.MouseButton1Click:Connect(function()
    local logs = {}
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            table.insert(logs, child.Text)
        end
    end
    
    local fullLogText = table.concat(logs, "\n")
    
    if setclipboard then
        setclipboard(fullLogText)
    elseif toclipboard then
        toclipboard(fullLogText)
    end

    local originalText = copyBtn.Text
    copyBtn.Text = "copied!"
    task.delay(1.5, function()
        copyBtn.Text = originalText
    end)
end)

clearBtn.MouseButton1Click:Connect(function()
    for _, v in ipairs(scrollFrame:GetChildren()) do
        if v:IsA("TextLabel") then
            v:Destroy()
        end
    end
    logCount = 0
end)

LogService.MessageOut:Connect(function(message, messageType)
    local color = Color3.fromRGB(255, 255, 255)
    local prefix = ""

    if messageType == Enum.MessageType.MessageWarning then
        color = Color3.fromRGB(255, 200, 0)
        prefix = "⚠ "
    elseif messageType == Enum.MessageType.MessageError then
        color = Color3.fromRGB(255, 80, 80)
        prefix = "❌ "
    elseif messageType == Enum.MessageType.MessageInfo then
        color = Color3.fromRGB(100, 180, 255)
        prefix = "ℹ "
    end

    log(prefix .. message, color)
end)
