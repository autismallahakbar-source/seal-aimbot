-- =============================================
-- SEAL AIMBOT (Better use this for knife duels)
-- Aimbot (E) + Spin + Triggerbot + ESP (G) + Fly + Noclip + Speed + Checks + Kill Sound + Seal's Photo + Stealth (=)
-- =============================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Seal Aimbot (Better use this for knife duels)",
    LoadingTitle = "Seal Aimbot",
    LoadingSubtitle = "by Seal",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SealScript",
        FileName = "Config"
    },
    KeySystem = false,
})

-- ===== ВКЛАДКИ =====
local MainTab = Window:CreateTab("Aimbot", nil)
local SpinTab = Window:CreateTab("Spin", nil)
local TriggerTab = Window:CreateTab("Triggerbot", nil)
local ESPTab = Window:CreateTab("ESP", nil)
local KillSoundTab = Window:CreateTab("Kill Sound", nil)
local ChecksTab = Window:CreateTab("Checks", nil)
local MovementTab = Window:CreateTab("Movement", nil)
local SealPhotoTab = Window:CreateTab("Seal's Photo", nil)

-- ===== СЕРВИСЫ =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local SoundService = game:GetService("SoundService")

-- ===== НАСТРОЙКИ =====
local Settings = {
    FOVRadius = 130,
    MaxDistance = 500,
    Smoothness = 0.5,
    AimbotEnabled = false,
    SpinEnabled = false,
    SpinSpeed = 10,
    TriggerbotEnabled = false,
    TriggerbotDelay = 0.05,
    ESPEnabled = true,
    ESPColor = Color3.fromRGB(255, 50, 50),
    ESPTransparency = 1,
    ESPThickness = 5,
    TeamCheck = false,
    WallCheck = false,
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    SpeedEnabled = false,
    SpeedValue = 100,
    StealthMode = false,
    KillSoundEnabled = false,
    KillSoundVolume = 1,
    KillSoundRange = 500,
}

-- ===== ЗВУК (ОДИН) =====
local KillSoundId = 18315629371

-- ===== KILL SOUND (С РАДИУСОМ) =====
local killSoundActive = false
local watchedPlayers = {}
local diedConnections = {}

local function playKillSound()
    if not KillSoundId or KillSoundId == 0 then return end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(KillSoundId)
    sound.Volume = Settings.KillSoundVolume
    sound.Parent = SoundService
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 5)
end

local function onPlayerDied(player)
    if not killSoundActive then return end

    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local char = player.Character
    if char then
        local enemyRoot = char:FindFirstChild("HumanoidRootPart")
        if enemyRoot then
            local dist = (myRoot.Position - enemyRoot.Position).Magnitude
            if dist > Settings.KillSoundRange then return end
        end
    end

    playKillSound()
end

local function watchPlayer(player)
    if watchedPlayers[player] then return end
    watchedPlayers[player] = true

    diedConnections[player] = {}

    local function onChar(char)
        local humanoid = char:WaitForChild("Humanoid", 5)
        if not humanoid then return end

        local conn = humanoid.Died:Connect(function()
            onPlayerDied(player)
        end)
        table.insert(diedConnections[player], conn)
    end

    local charConn = player.CharacterAdded:Connect(onChar)
    table.insert(diedConnections[player], charConn)

    if player.Character then
        onChar(player.Character)
    end
end

local function unwatchAll()
    for player, conns in pairs(diedConnections) do
        for _, conn in ipairs(conns) do
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
    end
    diedConnections = {}
    watchedPlayers = {}
end

local function startKillSound()
    if killSoundActive then return end
    killSoundActive = true

    unwatchAll()

    for _, player in ipairs(Players:GetPlayers()) do
        watchPlayer(player)
    end

    Players.PlayerAdded:Connect(function(player)
        watchPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        watchedPlayers[player] = nil
        diedConnections[player] = nil
    end)
end

local function stopKillSound()
    killSoundActive = false
    unwatchAll()
end

-- ===== WHITE LIST =====
local WhiteList = {}

local function isWhiteListed(player)
    return WhiteList[player.Name] == true
end

local function addToWhiteList(name)
    name = string.lower(name)
    WhiteList[name] = true
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name) == name then
            WhiteList[p.Name] = true
            break
        end
    end
end

-- ===== TEAM CHECK =====
local function isTeammate(player)
    if player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then return true end
    if LocalPlayer.TeamColor and player.TeamColor then
        if LocalPlayer.TeamColor ~= BrickColor.new("White")
           and LocalPlayer.TeamColor ~= BrickColor.new("Medium stone grey")
           and LocalPlayer.TeamColor == player.TeamColor then
            return true
        end
    end
    local attrNames = {"Team", "Side", "Ally", "TeamId", "team", "side"}
    for _, attr in ipairs(attrNames) do
        local myVal = LocalPlayer:GetAttribute(attr)
        local theirVal = player:GetAttribute(attr)
        if myVal ~= nil and theirVal ~= nil and myVal == theirVal then return true end
    end
    return false
end

-- ===== FOV CIRCLE =====
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = Settings.FOVRadius
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Filled = false
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- ===== ESP СИСТЕМА =====
local ESPBoxes = {}

local function createESP(player)
    if player == LocalPlayer then return end
    if ESPBoxes[player] then return end
    local box = Drawing.new("Square")
    box.Visible = true
    box.Color = Settings.ESPColor
    box.Thickness = Settings.ESPThickness
    box.Filled = false
    box.Transparency = Settings.ESPTransparency
    ESPBoxes[player] = box
end

local function updateESP()
    for player, box in pairs(ESPBoxes) do
        local char = player.Character
        if not char or not char.PrimaryPart then
            box.Visible = false
            continue
        end
        if isWhiteListed(player) then box.Visible = false continue end
        if Settings.TeamCheck and isTeammate(player) then box.Visible = false continue end

        local myChar = LocalPlayer.Character
        if myChar and myChar.PrimaryPart then
            local worldDist = (myChar.PrimaryPart.Position - char.PrimaryPart.Position).Magnitude
            if worldDist > Settings.MaxDistance then box.Visible = false continue end
        end

        local root = char.PrimaryPart
        local pos = root.Position
        local size = root.Size
        local head = char:FindFirstChild("Head")
        local topPos = head and head.Position or pos + Vector3.new(0, 2, 0)
        local bottomPos = pos - Vector3.new(0, size.Y / 2, 0)
        local topPoint, topOnScreen = Camera:WorldToViewportPoint(topPos + Vector3.new(0, 1, 0))
        local bottomPoint, bottomOnScreen = Camera:WorldToViewportPoint(bottomPos)

        if not topOnScreen or not bottomOnScreen then box.Visible = false continue end

        local height = topPoint.Y - bottomPoint.Y
        local width = height * 0.5
        box.Size = Vector2.new(width, height)
        box.Position = Vector2.new(topPoint.X - width/2, topPoint.Y - height)
        box.Visible = true
    end
end

local function cleanUpESP(player)
    if ESPBoxes[player] then ESPBoxes[player]:Remove() ESPBoxes[player] = nil end
end

local function refreshAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then createESP(player) end
    end
end

local function disableAllESP()
    for _, box in pairs(ESPBoxes) do box.Visible = false end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if Settings.ESPEnabled and not Settings.StealthMode then createESP(player) end
    end)
    if player.Character and Settings.ESPEnabled and not Settings.StealthMode then createESP(player) end
end)

Players.PlayerRemoving:Connect(cleanUpESP)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and Settings.ESPEnabled and not Settings.StealthMode then createESP(player) end
end

-- ===== AIMBOT =====
local function hasLineOfSight(targetPart)
    local char = LocalPlayer.Character
    if not char then return false end
    local myHead = char:FindFirstChild("Head")
    if not myHead then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char, targetPart.Parent}
    local direction = targetPart.Position - myHead.Position
    local result = Workspace:Raycast(myHead.Position, direction, rayParams)
    return result == nil
end

local function getClosestEnemyHead()
    local closest = nil
    local shortestDist = Settings.FOVRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        if isWhiteListed(player) then continue end
        if Settings.TeamCheck and isTeammate(player) then continue end

        local head = char:FindFirstChild("Head")
        if not head then continue end
        local worldDist = (myRoot.Position - head.Position).Magnitude
        if worldDist > Settings.MaxDistance then continue end
        if Settings.WallCheck then
            if not hasLineOfSight(head) then continue end
        end
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < shortestDist then
            shortestDist = dist
            closest = head
        end
    end
    return closest
end

-- ===== SPIN =====
local spinConn = nil

local function startSpin()
    if spinConn then return end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        if not Settings.SpinEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local motor = root:FindFirstChild("SpinMotor")
        if not motor then
            motor = Instance.new("BodyAngularVelocity")
            motor.Name = "SpinMotor"
            motor.Parent = root
            motor.MaxTorque = Vector3.new(0, math.huge, 0)
            motor.AngularVelocity = Vector3.new(0, Settings.SpinSpeed * math.pi * 2, 0)
            motor.P = 10000
        end
        motor.AngularVelocity = Vector3.new(0, Settings.SpinSpeed * math.pi * 2, 0)
    end)
end

local function stopSpin()
    if spinConn then spinConn:Disconnect() spinConn = nil end
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local motor = root:FindFirstChild("SpinMotor")
            if motor then motor:Destroy() end
        end
    end
end

-- ===== TRIGGERBOT =====
local lastTrigger = 0

local function getEnemyUnderCrosshair()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        if isWhiteListed(player) then continue end
        if Settings.TeamCheck and isTeammate(player) then continue end

        local head = char:FindFirstChild("Head")
        if not head then continue end
        local worldDist = (myRoot.Position - head.Position).Magnitude
        if worldDist > Settings.MaxDistance then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local screenPos = Vector2.new(pos.X, pos.Y)
        local dist = (screenPos - center).Magnitude
        if dist < 30 then
            if not hasLineOfSight(head) then continue end
            return head
        end
    end
    return nil
end

local function fireWeapon()
    local virtualUser = game:GetService("VirtualUser")
    virtualUser:CaptureController()
    virtualUser:ClickButton1(Vector2.new())
end

RunService.RenderStepped:Connect(function()
    if not Settings.TriggerbotEnabled then return end
    local now = tick()
    if now - lastTrigger < Settings.TriggerbotDelay then return end
    local target = getEnemyUnderCrosshair()
    if target then
        lastTrigger = now
        fireWeapon()
    end
end)

-- ===== FLY =====
local flyConn = nil
local flyBodyVelocity = nil

local function startFly()
    if flyConn then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Parent = hrp
    flyBodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)

    flyConn = RunService.Heartbeat:Connect(function()
        if not Settings.FlyEnabled then return end
        local char2 = LocalPlayer.Character
        if not char2 then return end
        local hrp2 = char2:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return end
        if not flyBodyVelocity or flyBodyVelocity.Parent ~= hrp2 then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.Parent = hrp2
            flyBodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
        end
        local cam = Workspace.CurrentCamera
        local camCF = cam.CFrame
        local camLook = camCF.LookVector.Unit
        hrp2.CFrame = CFrame.new(hrp2.Position, hrp2.Position + camLook)
        hrp2.RotVelocity = Vector3.new(0, 0, 0)
        hrp2.Velocity = Vector3.new(0, 0, 0)

        local move = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camLook end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camLook end
        local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if move.Magnitude > 0 then move = move.Unit * Settings.FlySpeed end
        flyBodyVelocity.Velocity = move
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

-- ===== NOCLIP =====
RunService.Stepped:Connect(function()
    if Settings.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- ===== KEYBINDS =====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        Settings.AimbotEnabled = not Settings.AimbotEnabled
        Rayfield:Notify({Title = "Aimbot", Content = Settings.AimbotEnabled and "Enabled" or "Disabled", Duration = 2})
    end
    if input.KeyCode == Enum.KeyCode.G then
        Settings.ESPEnabled = not Settings.ESPEnabled
        if Settings.ESPEnabled then refreshAllESP() else disableAllESP() end
        Rayfield:Notify({Title = "ESP", Content = Settings.ESPEnabled and "Enabled" or "Disabled", Duration = 2})
    end
    if input.KeyCode == Enum.KeyCode.Equals then
        Settings.StealthMode = not Settings.StealthMode
        if Settings.StealthMode then
            disableAllESP()
            FOVCircle.Visible = false
        else
            if Settings.ESPEnabled then refreshAllESP() end
        end
        Rayfield:Notify({Title = "Stealth Mode", Content = Settings.StealthMode and "ON" or "OFF", Duration = 2})
    end
end)

-- ===== ОСНОВНОЙ ЦИКЛ =====
RunService.RenderStepped:Connect(function()
    if Settings.ESPEnabled and not Settings.StealthMode then
        updateESP()
    else
        for _, box in pairs(ESPBoxes) do box.Visible = false end
    end

    if not Settings.AimbotEnabled then
        FOVCircle.Visible = false
        return
    end

    if not Settings.StealthMode then
        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        FOVCircle.Visible = false
    end

    local targetHead = getClosestEnemyHead()
    if targetHead then
        local lookAt = targetHead.Position
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, lookAt)
        Camera.CFrame = currentCF:Lerp(targetCF, Settings.Smoothness)
    end

    if Settings.SpeedEnabled then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid and humanoid.WalkSpeed ~= Settings.SpeedValue then
                humanoid.WalkSpeed = Settings.SpeedValue
            end
        end
    end
end)

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)

-- ==========================================================
-- SEAL'S PHOTO WINDOW
-- ==========================================================
local pictureGui = Instance.new("ScreenGui")
pictureGui.Name = "SealPictureGui"
pictureGui.Parent = PlayerGui
pictureGui.ResetOnSpawn = false
pictureGui.Enabled = false

local pictureFrame = Instance.new("Frame")
pictureFrame.Parent = pictureGui
pictureFrame.Size = UDim2.new(0, 400, 0, 400)
pictureFrame.Position = UDim2.new(0.5, -200, 0.5, -200)
pictureFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
pictureFrame.BorderSizePixel = 2
pictureFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
pictureFrame.Active = true
pictureFrame.Draggable = true

local pictureImage = Instance.new("ImageLabel")
pictureImage.Parent = pictureFrame
pictureImage.Size = UDim2.new(1, -20, 1, -60)
pictureImage.Position = UDim2.new(0, 10, 0, 10)
pictureImage.BackgroundTransparency = 1
pictureImage.Image = "rbxassetid://94513154691410"
pictureImage.ScaleType = Enum.ScaleType.Fit

local closeButton = Instance.new("TextButton")
closeButton.Parent = pictureFrame
closeButton.Size = UDim2.new(0, 100, 0, 30)
closeButton.Position = UDim2.new(0.5, -50, 1, -40)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Text = "Close"
closeButton.MouseButton1Click:Connect(function()
    pictureGui.Enabled = false
end)

-- ==========================================================
-- GUI — AIMBOT
-- ==========================================================
MainTab:CreateToggle({
    Name = "Aimbot [E]",
    CurrentValue = false,
    Flag = "aimbot_enabled",
    Callback = function(Value)
        Settings.AimbotEnabled = Value
        if not Value then FOVCircle.Visible = false end
    end
})

MainTab:CreateSlider({
    Name = "Aim Radius (studs)",
    Range = {10, 5000},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 500,
    Flag = "max_distance",
    Callback = function(Value) Settings.MaxDistance = Value end
})

MainTab:CreateSlider({
    Name = "FOV Radius (screen px)",
    Range = {50, 300},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 130,
    Flag = "fov_radius",
    Callback = function(Value)
        Settings.FOVRadius = Value
        FOVCircle.Radius = Value
    end
})

MainTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.3, 1.0},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "smoothness",
    Callback = function(Value) Settings.Smoothness = Value end
})

-- ==========================================================
-- GUI — SPIN
-- ==========================================================
SpinTab:CreateToggle({
    Name = "Spin",
    CurrentValue = false,
    Flag = "spin_enabled",
    Callback = function(Value)
        Settings.SpinEnabled = Value
        if Value then startSpin() else stopSpin() end
    end
})

SpinTab:CreateSlider({
    Name = "Spin Speed",
    Range = {1, 50},
    Increment = 1,
    Suffix = "",
    CurrentValue = 10,
    Flag = "spin_speed",
    Callback = function(Value) Settings.SpinSpeed = Value end
})

-- ==========================================================
-- GUI — TRIGGERBOT
-- ==========================================================
TriggerTab:CreateToggle({
    Name = "Triggerbot",
    CurrentValue = false,
    Flag = "triggerbot_enabled",
    Callback = function(Value) Settings.TriggerbotEnabled = Value end
})

TriggerTab:CreateSlider({
    Name = "Trigger Delay (sec)",
    Range = {0.01, 0.5},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.05,
    Flag = "trigger_delay",
    Callback = function(Value) Settings.TriggerbotDelay = Value end
})

-- ==========================================================
-- GUI — ESP
-- ==========================================================
ESPTab:CreateToggle({
    Name = "ESP [G]",
    CurrentValue = true,
    Flag = "esp_enabled",
    Callback = function(Value)
        Settings.ESPEnabled = Value
        if Value and not Settings.StealthMode then refreshAllESP() else disableAllESP() end
    end
})

-- ==========================================================
-- GUI — KILL SOUND
-- ==========================================================
KillSoundTab:CreateToggle({
    Name = "Kill Sound",
    CurrentValue = false,
    Flag = "killsound_enabled",
    Callback = function(Value)
        Settings.KillSoundEnabled = Value
        if Value then startKillSound() else stopKillSound() end
    end
})

KillSoundTab:CreateSlider({
    Name = "Hear Range",
    Range = {10, 1000},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 500,
    Flag = "killsound_range",
    Callback = function(Value) Settings.KillSoundRange = Value end
})

KillSoundTab:CreateSlider({
    Name = "Volume",
    Range = {0, 5},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 1,
    Flag = "killsound_volume",
    Callback = function(Value) Settings.KillSoundVolume = Value end
})

-- ==========================================================
-- GUI — CHECKS
-- ==========================================================
ChecksTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "team_check",
    Callback = function(Value) Settings.TeamCheck = Value end
})

ChecksTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "wall_check",
    Callback = function(Value) Settings.WallCheck = Value end
})

ChecksTab:CreateInput({
    Name = "White List (add nickname)",
    PlaceholderText = "Enter nickname",
    RemoveTextAfterFocusLost = true,
    Flag = "whitelist_input",
    Callback = function(Text)
        if Text and Text ~= "" then
            addToWhiteList(Text)
            Rayfield:Notify({Title = "White List", Content = "Added: " .. Text, Duration = 2})
        end
    end
})

-- ==========================================================
-- GUI — MOVEMENT
-- ==========================================================
MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "fly_enabled",
    Callback = function(Value)
        Settings.FlyEnabled = Value
        if Value then startFly() else stopFly() end
    end
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 150},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Flag = "fly_speed",
    Callback = function(Value) Settings.FlySpeed = Value end
})

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "noclip_enabled",
    Callback = function(Value)
        Settings.NoclipEnabled = Value
        if not Value then
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
    end
})

MovementTab:CreateToggle({
    Name = "Speed",
    CurrentValue = false,
    Flag = "speed_enabled",
    Callback = function(Value)
        Settings.SpeedEnabled = Value
        if not Value then
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then humanoid.WalkSpeed = 16 end
            end
        end
    end
})

MovementTab:CreateSlider({
    Name = "Speed Value",
    Range = {16, 300},
    Increment = 5,
    Suffix = "",
    CurrentValue = 100,
    Flag = "speed_value",
    Callback = function(Value) Settings.SpeedValue = Value end
})

-- ==========================================================
-- GUI — SEAL'S PHOTO
-- ==========================================================
SealPhotoTab:CreateButton({
    Name = "Show Seal",
    Callback = function() pictureGui.Enabled = true end
})

SealPhotoTab:CreateLabel("⚠️ If you open this photo in Knife Duels, you will be banned for 1 day.")

Rayfield:Notify({
    Title = "Seal Aimbot Loaded",
    Content = "E = Aimbot | G = ESP | = = Stealth | Kill Sound ready",
    Duration = 4,
})

print("✅ Seal Aimbot загружен (Rayfield)")
