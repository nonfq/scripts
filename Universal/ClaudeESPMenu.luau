--[[
good esp
made by: @nonfq
]]--

local genv = (getgenv and getgenv()) or _G

if genv.__ESPMenu then
    pcall(genv.__ESPMenu)
    genv.__ESPMenu = nil
end

local cref = cloneref or function(x) return x end
local Players = cref(game:GetService("Players"))
local RunService = cref(game:GetService("RunService"))
local UIS = cref(game:GetService("UserInputService"))
local CoreGui = cref(game:GetService("CoreGui"))
local Workspace = cref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer
local hasDrawing = type(Drawing) == "table" and type(Drawing.new) == "function"

if not hasDrawing then
    warn("[ESP] Drawing library not found. Only Chams will work.")
end

local Settings = {
    Enabled = false,
    Boxes = true,
    Names = true,
    Health = true,
    Distance = true,
    Tracers = false,
    Skeleton = true,
    TracerOrigin = "Bottom",
    Chams = false,
    TeamCheck = false,
    TeamColors = true,
}

local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end

local gui = Instance.new("ScreenGui")
gui.Name = "ClaudeESPMenu"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
local okParent = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
if not okParent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local objects = {}
local DEFAULT_COLOR = Color3.fromRGB(255, 70, 70)

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function createObjects(plr)
    if objects[plr] then return end
    local o = {}
    if hasDrawing then
        o.Box = newDrawing("Square", {Thickness = 1, Filled = false, Visible = false, Color = DEFAULT_COLOR})
        o.BoxOutline = newDrawing("Square", {Thickness = 3, Filled = false, Visible = false, Color = Color3.new(0, 0, 0)})
        o.Name = newDrawing("Text", {Size = 13, Center = true, Outline = true, Visible = false, Color = Color3.new(1, 1, 1)})
        o.Dist = newDrawing("Text", {Size = 12, Center = true, Outline = true, Visible = false, Color = Color3.fromRGB(200, 200, 200)})
        o.HealthBG = newDrawing("Line", {Thickness = 4, Visible = false, Color = Color3.new(0, 0, 0)})
        o.HealthBar = newDrawing("Line", {Thickness = 2, Visible = false, Color = Color3.fromRGB(0, 255, 0)})
        o.Tracer = newDrawing("Line", {Thickness = 1, Visible = false, Color = DEFAULT_COLOR})
        o.Bones = {}
        for i = 1, 14 do
            o.Bones[i] = newDrawing("Line", {Thickness = 1, Visible = false, Color = DEFAULT_COLOR})
        end
    end
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = gui
    o.Highlight = hl
    objects[plr] = o
end

local function hide(o)
    for key, obj in pairs(o) do
        if key == "Highlight" then
            obj.Enabled = false
            obj.Adornee = nil
        elseif key == "Bones" then
            for _, line in ipairs(obj) do line.Visible = false end
        else
            obj.Visible = false
        end
    end
end

local function removeObjects(plr)
    local o = objects[plr]
    if not o then return end
    for key, obj in pairs(o) do
        if key == "Highlight" then
            obj:Destroy()
        elseif key == "Bones" then
            for _, line in ipairs(obj) do pcall(function() line:Remove() end) end
        else
            pcall(function() obj:Remove() end)
        end
    end
    objects[plr] = nil
end

local function getColor(plr)
    if Settings.TeamColors and plr.Team and plr.TeamColor then
        return plr.TeamColor.Color
    end
    return DEFAULT_COLOR
end

local R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function drawSkeleton(o, char, camera, color)
    local bones = o.Bones
    if not bones then return end
    if not Settings.Skeleton then
        for _, line in ipairs(bones) do line.Visible = false end
        return
    end
    local rig = char:FindFirstChild("UpperTorso") and R15 or R6
    for i, line in ipairs(bones) do
        local pair = rig[i]
        local a = pair and char:FindFirstChild(pair[1])
        local b = pair and char:FindFirstChild(pair[2])
        if a and b then
            local pa, va = camera:WorldToViewportPoint(a.Position)
            local pb, vb = camera:WorldToViewportPoint(b.Position)
            if va and vb then
                line.From = Vector2.new(pa.X, pa.Y)
                line.To = Vector2.new(pb.X, pb.Y)
                line.Color = color
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

local function update()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize

    for plr, o in pairs(objects) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        local valid = Settings.Enabled and hrp and head and hum and hum.Health > 0
        if valid and Settings.TeamCheck and plr.Team ~= nil and plr.Team == LocalPlayer.Team then
            valid = false
        end

        if not valid then
            hide(o)
        else
            local color = getColor(plr)

            if Settings.Chams then
                o.Highlight.Adornee = char
                o.Highlight.FillColor = color
                o.Highlight.OutlineColor = color
                o.Highlight.Enabled = true
            else
                o.Highlight.Enabled = false
            end

            if hasDrawing then
                local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local top = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
                    local bottom = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    local height = math.abs(bottom.Y - top.Y)
                    local width = height / 1.6
                    local x = rootPos.X - width / 2
                    local y = top.Y

                    o.Box.Visible = Settings.Boxes
                    o.BoxOutline.Visible = Settings.Boxes
                    if Settings.Boxes then
                        o.Box.Size = Vector2.new(width, height)
                        o.Box.Position = Vector2.new(x, y)
                        o.Box.Color = color
                        o.BoxOutline.Size = o.Box.Size
                        o.BoxOutline.Position = o.Box.Position
                    end

                    o.Name.Visible = Settings.Names
                    if Settings.Names then
                        o.Name.Text = plr.DisplayName
                        o.Name.Position = Vector2.new(rootPos.X, y - 16)
                    end

                    o.Dist.Visible = Settings.Distance
                    if Settings.Distance then
                        local dist = (camera.CFrame.Position - hrp.Position).Magnitude
                        o.Dist.Text = string.format("[%d studs]", dist)
                        o.Dist.Position = Vector2.new(rootPos.X, y + height + 2)
                    end

                    o.HealthBG.Visible = Settings.Health
                    o.HealthBar.Visible = Settings.Health
                    if Settings.Health then
                        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        local bx = x - 5
                        o.HealthBG.From = Vector2.new(bx, y + height + 1)
                        o.HealthBG.To = Vector2.new(bx, y - 1)
                        o.HealthBar.From = Vector2.new(bx, y + height)
                        o.HealthBar.To = Vector2.new(bx, y + height - height * pct)
                        o.HealthBar.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), pct)
                    end

                    o.Tracer.Visible = Settings.Tracers
                    if Settings.Tracers then
                        local originY = viewport.Y
                        if Settings.TracerOrigin == "Top" then
                            originY = 0
                        elseif Settings.TracerOrigin == "Center" then
                            originY = viewport.Y / 2
                        end
                        o.Tracer.From = Vector2.new(viewport.X / 2, originY)
                        o.Tracer.To = Vector2.new(rootPos.X, y + height)
                        o.Tracer.Color = color
                    end
                else
                    o.Box.Visible = false
                    o.BoxOutline.Visible = false
                    o.Name.Visible = false
                    o.Dist.Visible = false
                    o.HealthBG.Visible = false
                    o.HealthBar.Visible = false
                    o.Tracer.Visible = false
                end
                drawSkeleton(o, char, camera, color)
            end
        end
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then createObjects(plr) end
end
connect(Players.PlayerAdded, function(plr)
    if plr ~= LocalPlayer then createObjects(plr) end
end)
connect(Players.PlayerRemoving, removeObjects)
connect(RunService.RenderStepped, update)

local C = {
    bg = Color3.fromRGB(24, 24, 28),
    panel = Color3.fromRGB(32, 32, 38),
    item = Color3.fromRGB(42, 42, 50),
    on = Color3.fromRGB(70, 190, 110),
    off = Color3.fromRGB(80, 80, 90),
    text = Color3.fromRGB(230, 230, 235),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 390)
main.Position = UDim2.new(0, 20, 0.3, 0)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.Parent = gui
corner(main, 8)

local title = Instance.new("Frame")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = C.panel
title.BorderSizePixel = 0
title.Parent = main
corner(title, 8)

local titleText = Instance.new("TextLabel")
titleText.BackgroundTransparency = 1
titleText.Size = UDim2.new(1, -44, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.TextColor3 = C.text
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Text = "Claude ESP Menu"
titleText.Parent = title

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.TextColor3 = C.text
closeBtn.Parent = title
corner(closeBtn, 5)

do
    local dragging, dragStart, startPos
    connect(title.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, main.Position
        end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local holder = Instance.new("ScrollingFrame")
holder.Size = UDim2.new(1, -12, 1, -42)
holder.Position = UDim2.new(0, 6, 0, 38)
holder.BackgroundTransparency = 1
holder.BorderSizePixel = 0
holder.ScrollBarThickness = 3
holder.CanvasSize = UDim2.new()
holder.AutomaticCanvasSize = Enum.AutomaticSize.Y
holder.Parent = main
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = holder

layout.SortOrder = Enum.SortOrder.LayoutOrder
local order = 0

local function addToggle(labelText, key, dropdown)
    order += 1
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, -4, 0, 0)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder = order
    wrap.Parent = holder
    local wl = Instance.new("UIListLayout")
    wl.SortOrder = Enum.SortOrder.LayoutOrder
    wl.Padding = UDim.new(0, 3)
    wl.Parent = wrap

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = C.item
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.LayoutOrder = 1
    btn.Parent = wrap
    corner(btn, 5)

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -90, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText
    lbl.Parent = btn

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 38, 0, 18)
    pill.Position = UDim2.new(1, dropdown and -76 or -46, 0.5, -9)
    pill.BorderSizePixel = 0
    pill.Parent = btn
    corner(pill, 9)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    corner(knob, 7)

    local function render()
        local on = Settings[key]
        pill.BackgroundColor3 = on and C.on or C.off
        knob.Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    end
    render()

    connect(btn.MouseButton1Click, function()
        Settings[key] = not Settings[key]
        render()
    end)

    if dropdown then
        local dots = Instance.new("TextButton")
        dots.Size = UDim2.new(0, 28, 0, 22)
        dots.Position = UDim2.new(1, -34, 0.5, -11)
        dots.BackgroundColor3 = C.panel
        dots.Text = "..."
        dots.Font = Enum.Font.GothamBold
        dots.TextSize = 14
        dots.TextColor3 = C.text
        dots.ZIndex = 2
        dots.Parent = btn
        corner(dots, 5)

        local menu = Instance.new("Frame")
        menu.Size = UDim2.new(1, 0, 0, 0)
        menu.AutomaticSize = Enum.AutomaticSize.Y
        menu.BackgroundColor3 = C.panel
        menu.BorderSizePixel = 0
        menu.Visible = false
        menu.LayoutOrder = 2
        menu.Parent = wrap
        corner(menu, 5)
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 4)
        pad.PaddingLeft = UDim.new(0, 4)
        pad.PaddingRight = UDim.new(0, 4)
        pad.Parent = menu
        local ml = Instance.new("UIListLayout")
        ml.SortOrder = Enum.SortOrder.LayoutOrder
        ml.Padding = UDim.new(0, 3)
        ml.Parent = menu

        local optionButtons = {}
        local function renderOptions()
            for name, ob in pairs(optionButtons) do
                ob.BackgroundColor3 = (Settings.TracerOrigin == name) and C.on or C.item
            end
        end

        for idx, name in ipairs({"Top", "Center", "Bottom"}) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, 0, 0, 24)
            ob.LayoutOrder = idx
            ob.BackgroundColor3 = C.item
            ob.AutoButtonColor = true
            ob.Text = name
            ob.Font = Enum.Font.GothamMedium
            ob.TextSize = 12
            ob.TextColor3 = C.text
            ob.Parent = menu
            corner(ob, 4)
            optionButtons[name] = ob
            connect(ob.MouseButton1Click, function()
                Settings.TracerOrigin = name
                renderOptions()
                menu.Visible = false
            end)
        end
        renderOptions()

        connect(dots.MouseButton1Click, function()
            menu.Visible = not menu.Visible
        end)
    end
end

addToggle("ESP Enabled", "Enabled")
addToggle("Boxes", "Boxes")
addToggle("Names", "Names")
addToggle("Health Bars", "Health")
addToggle("Distance", "Distance")
addToggle("Tracers", "Tracers", true)
addToggle("Skeleton", "Skeleton")
addToggle("Chams", "Chams")
addToggle("Team Check", "TeamCheck")
addToggle("Team Colors", "TeamColors")

local function destroy()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
    for plr in pairs(objects) do removeObjects(plr) end
    gui:Destroy()
end

genv.__ESPMenu = destroy
closeBtn.MouseButton1Click:Connect(function()
    genv.__ESPMenu = nil
    destroy()
end)
