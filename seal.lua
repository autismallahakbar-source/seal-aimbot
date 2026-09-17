-- Seal's MM2 - Rayfield UI (AIMBOT + SIMPLE ESP)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Seal's MM2",
    LoadingTitle = "Seal's Hub",
    LoadingSubtitle = "by Seal",
    Theme = "DarkBlue",
    ToggleUIKeybind = "K",
    KeySystem = false,
    ConfigurationSaving = { Enabled = true, FileName = "SealMM2" }
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local Settings = {
    AimbotEnabled = false,
    AimPart = "Head",
    FOV = 100,
    Smoothness = 0.2,
    TeamCheck = true,
    WallCheck = false,
    ShowFOV = true,
    MaxDistance = 500,
    ESPEnabled = false,
    ESPColor = Color3.fromRGB(255, 0, 0),
    ESPMaxDistance = 500,
}

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(0, 255, 200)
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Transparency = 0.8
fovCircle.Visible = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = UIS:GetMouseLocation()
    fovCircle.Radius = Settings.FOV
    fovCircle.Visible = Settings.AimbotEnabled and Settings.ShowFOV
end)

-- ==========================================================
-- ФУНКЦИИ
-- ==========================================================
local function isAlive(player)
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return false end
    return humanoid.Health > 0
end

local function isEnemy(player)
    if not Settings.TeamCheck then return true end
    if not LP.Team or not player.Team then return true end
    return player.Team ~= LP.Team
end

local function isVisible(part)
    if not Settings.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LP.Character}
    local result = workspace:Raycast(origin, direction * distance, rayParams)
    if result then
        local hitChar = result.Instance:FindFirstAncestorWhichIsA("Model")
        if hitChar and hitChar:FindFirstChild("Humanoid") then return true end
        return false
    end
    return true
end

-- ==========================================================
-- AIMBOT
-- ==========================================================
local function getClosestPlayer()
    local closest = nil
    local shortestDist = Settings.FOV
    local mousePos = UIS:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and isAlive(player) and isEnemy(player) then
            local char = player.Character
            local aimPart = char:FindFirstChild(Settings.AimPart) or char:FindFirstChild("Head")
            if aimPart then
                local distance = (LP.Character.HumanoidRootPart.Position - aimPart.Position).Magnitude
                if distance > Settings.MaxDistance then continue end
                if Settings.WallCheck and not isVisible(aimPart) then continue end
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        closest = player
                        shortestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

local aimbotConn = nil

local function startAimbot()
    if aimbotConn then return end
    aimbotConn = RunService.RenderStepped:Connect(function()
        if not Settings.AimbotEnabled then return end
        local target = getClosestPlayer()
        if target and target.Character then
            local aimPart = target.Character:FindFirstChild(Settings.AimPart) or target.Character:FindFirstChild("Head")
            if aimPart then
                Camera.CFrame = Camera.CFrame:Lerp(
                    CFrame.new(Camera.CFrame.Position, aimPart.Position),
                    Settings.Smoothness
                )
            end
        end
    end)
end

local function stopAimbot()
    if aimbotConn then
        aimbotConn:Disconnect()
        aimbotConn = nil
    end
end

-- ==========================================================
-- SIMPLE ESP (КРАСНЫЙ КОНТУР)
-- ==========================================================
local espObjects = {}

local function removeESP()
    for _, obj in pairs(espObjects) do
        pcall(function() obj:Destroy() end)
    end
    espObjects = {}
end

spawn(function()
    while task.wait(1) do
        removeESP()
        if not Settings.ESPEnabled then continue end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character and isAlive(player) then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                
                if hrp and myHrp then
                    local dist = (myHrp.Position - hrp.Position).Magnitude
                    if dist < Settings.ESPMaxDistance then
                        local highlight = Instance.new("Highlight")
                        highlight.Parent = player.Character
                        highlight.FillColor = Settings.ESPColor
                        highlight.FillTransparency = 1
                        highlight.OutlineColor = Settings.ESPColor
                        highlight.OutlineTransparency = 0
                        highlight.Adornee = player.Character
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        table.insert(espObjects, highlight)
                    end
                end
            end
        end
    end
end)

-- ==========================================================
-- GUI TABS
-- ==========================================================
local AimTab = Window:CreateTab("🎯 Aimbot", nil)
AimTab:CreateSection("Main")

AimTab:CreateToggle({
    Name = "Aimbot (Always Active)",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(val)
        Settings.AimbotEnabled = val
        if val then startAimbot() else stopAimbot() end
    end
})

AimTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = "Head",
    Flag = "AimPart",
    Callback = function(option) Settings.AimPart = option end
})

AimTab:CreateSlider({
    Name = "FOV",
    Range = {10, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 100,
    Flag = "FOV",
    Callback = function(val) Settings.FOV = val end
})

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.2,
    Flag = "Smoothness",
    Callback = function(val) Settings.Smoothness = val end
})

AimTab:CreateSlider({
    Name = "Max Distance",
    Range = {50, 1000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 500,
    Flag = "MaxDistance",
    Callback = function(val) Settings.MaxDistance = val end
})

AimTab:CreateSection("Checks")

AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(val) Settings.TeamCheck = val end
})

AimTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "WallCheck",
    Callback = function(val) Settings.WallCheck = val end
})

AimTab:CreateSection("Visuals")

AimTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "ShowFOV",
    Callback = function(val) Settings.ShowFOV = val end
})

-- ESP TAB
local ESPTab = Window:CreateTab("👁️ ESP", nil)
ESPTab:CreateSection("Simple ESP")

ESPTab:CreateToggle({
    Name = "ESP (Red Outline)",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(val)
        Settings.ESPEnabled = val
        if not val then removeESP() end
    end
})

ESPTab:CreateSlider({
    Name = "ESP Max Distance",
    Range = {100, 2000},
    Increment = 100,
    Suffix = "studs",
    CurrentValue = 500,
    Flag = "ESPMaxDistance",
    Callback = function(val) Settings.ESPMaxDistance = val end
})

print("==========================================")
print("     🎯 Seal's MM2 (AIMBOT + ESP)")
print("         XENO EDITION")
print("==========================================")
print("✅ Скрипт загружен!")
print("K - показать/скрыть меню")