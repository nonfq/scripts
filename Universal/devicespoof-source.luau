--[[
device spoooof
made by: @nonfq
]]--

local SG = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local GS = game:GetService("GuiService")

local PROFILES = {
    { name = "PC",      TouchEnabled = false, GamepadEnabled = false, KeyboardEnabled = true,  MouseEnabled = true,  TenFoot = false },
    { name = "Mobile",  TouchEnabled = true,  GamepadEnabled = false, KeyboardEnabled = false, MouseEnabled = false, TenFoot = false },
    { name = "Console", TouchEnabled = false, GamepadEnabled = true,  KeyboardEnabled = false, MouseEnabled = false, TenFoot = true  },
}

if not getgenv().__ds_idx then getgenv().__ds_idx = 0 end
getgenv().__ds_idx = (getgenv().__ds_idx % #PROFILES) + 1

local profile = PROFILES[getgenv().__ds_idx]
local state   = getgenv().__ds_state or {}
getgenv().__ds_state = state
state.profile = profile

local UIS_KEYS = { TouchEnabled = true, GamepadEnabled = true, KeyboardEnabled = true, MouseEnabled = true }

if not state.hooked then
    local mu = getrawmetatable(UIS)
    local ou = mu.__index
    setreadonly(mu, false)
    mu.__index = newcclosure(function(self, k)
        if self == UIS and state.profile and UIS_KEYS[k] then
            return state.profile[k]
        end
        return ou(self, k)
    end)
    setreadonly(mu, true)

    local mg = getrawmetatable(GS)
    local og = mg.__index
    setreadonly(mg, false)
    mg.__index = newcclosure(function(self, k)
        if self == GS and state.profile and k == "IsTenFootInterface" then
            return newcclosure(function() return state.profile.TenFoot end)
        end
        return og(self, k)
    end)
    setreadonly(mg, true)

    state.hooked = true
end

SG:SetCore("SendNotification", {
    Title    = "Device Spoofer",
    Text     = "Active \u{2192} " .. profile.name,
    Duration = 3,
})

local API = {
    Active = function() return state.profile and state.profile.name or "None" end,
}

getgenv().DeviceSpoofer = API
getgenv_device          = API
return API
