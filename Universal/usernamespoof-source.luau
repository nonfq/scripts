local Players         = game:GetService("Players")
local StarterGui      = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local InsertService   = game:GetService("InsertService")
local LocalPlayer     = Players.LocalPlayer

if getgenv().SpooferConnections then
    for _, conn in ipairs(getgenv().SpooferConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv().SpooferConnections = {}
local connections = getgenv().SpooferConnections

local FAKE_NAME    = getgenv().spoof_name or "III"
local REAL_NAME    = LocalPlayer.Name
local REAL_DISPLAY = LocalPlayer.DisplayName
getgenv().spoof_name = FAKE_NAME


local function applySpoof(instance)
    if not (instance:IsA("TextLabel")
         or instance:IsA("TextButton")
         or instance:IsA("TextBox")) then return end

    local function refreshText()
        local raw = instance.Text
        local out = raw
            :gsub(REAL_NAME,    FAKE_NAME)
            :gsub(REAL_DISPLAY, FAKE_NAME)
        if out ~= raw then
            instance.Text = out
        end
    end

    refreshText()
    local c = instance:GetPropertyChangedSignal("Text"):Connect(refreshText)
    table.insert(connections, c)
end

local function scanContainer(root)
    for _, d in ipairs(root:GetDescendants()) do applySpoof(d) end
    local c = root.DescendantAdded:Connect(applySpoof)
    table.insert(connections, c)
end

scanContainer(LocalPlayer:WaitForChild("PlayerGui"))
pcall(function() scanContainer(game:GetService("CoreGui")) end)

local function changeName(newName)
    FAKE_NAME            = newName
    getgenv().spoof_name = newName

    local function rescan(root)
        pcall(function()
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("TextLabel")
                or d:IsA("TextButton")
                or d:IsA("TextBox") then
                    local raw = d.Text
                    local out = raw
                        :gsub(REAL_NAME,    newName)
                        :gsub(REAL_DISPLAY, newName)
                    for _, prev in ipairs(getgenv()._name_history or {}) do
                        out = out:gsub(prev, newName)
                    end
                    if d.Text ~= out then d.Text = out end
                end
            end
        end)
    end

    rescan(LocalPlayer.PlayerGui)
    pcall(function() rescan(game:GetService("CoreGui")) end)

    getgenv()._name_history = getgenv()._name_history or {}
    table.insert(getgenv()._name_history, newName)

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = "Name Spoofer",
            Text     = "Name → " .. newName,
            Duration = 2
        })
    end)
    print("[NameSpoofer] Changed to: " .. newName)
end

local function parseIds(str)
    local t = {}
    if not str or str == "" then return t end
    for id in tostring(str):gmatch("%d+") do
        table.insert(t, tonumber(id))
    end
    return t
end

local chatConn = LocalPlayer.Chatted:Connect(function(msg)
    local newName = msg:match("^!c%s+(.-)%s*$")
    if newName and #newName > 0 then
        changeName(newName)
        return
    end
    local avatarTarget = msg:match("^!a%s+(.-)%s*$")
    if avatarTarget and #avatarTarget > 0 then
        changeAvatar(avatarTarget)
        return
    end
end)
table.insert(connections, chatConn)

pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local existing = TextChatService.OnIncomingMessage
        TextChatService.OnIncomingMessage = function(msg)
            if msg.TextSource
            and msg.TextSource.UserId == LocalPlayer.UserId
            and (msg.Text:match("^!c%s+") or msg.Text:match("^!a%s+")) then
                local props = Instance.new("TextChatMessageProperties")
                props.Text = ""
                return props
            end
            if existing then return existing(msg) end
        end
    end
end)

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title    = "Name Spoofer",
        Text     = "!c <name>",
        Duration = 4
    })
end)

print(("[Spoofer] v2.3.2 | Active as: %s"):format(FAKE_NAME))
print("[Spoofer] Commands: !c <name>")
print("Discord: nonfq")
