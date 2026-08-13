-- ================================
-- منع ظهور الأخطاء (يُحط في أول الملف)
-- ================================

local oldWarn = warn
local oldError = error
warn = function() end
error = function() end

pcall(function()
    -- كل الكود بتاعك هنا
    print("Script loaded successfully!")
end)

task.spawn(function()
    task.wait(5)
    warn = oldWarn
    error = oldError
end)

-- ============================================
-- تعريف الخدمات (في بداية الكود)
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- ============================================
-- تعريف التابات
-- ============================================
local Tabs = {
    ESP = Window:Tab({ Title = "ESP", Icon = "eye", Locked = false }),
}
-- ================================
-- تبويب ESP
-- ================================
local ESPTab = Tabs.ESP

-- ================================
-- Player ESP & Highlight
-- ================================
local PlayerESPSection = ESPTab:Section({
    Title = "Player ESP & Highlight",
    Side = "Left",
    Collapsed = true,
})

-- ================================
-- المتغيرات العامة
-- ================================
local PlayerESPEnabled = false
local PlayerESPInstances = {}
local PlayerESPConnection = nil
local HighlightsEnabled = false
local HighlightsConnection = nil
local PlayerHighlights = {}

-- الألوان الافتراضية
local normalColor = Color3.fromRGB(255, 255, 255)    -- أبيض
local downedColor = Color3.fromRGB(255, 0, 0)        -- أحمر

-- ESP Config
local ESPConfig = {
    TextStroke = false,
    SpecialPlayer = "",
    SpecialPlayerColor = Color3.fromRGB(255, 215, 0),
    ShowUsername = false,
    TextSize = 9,
    GuiSize = 100,
    ZoomEffect = false,  -- false = حجم ثابت, true = يكبر مع المسافة
}

-- =====================================================================
-- 🔥 نظام تمييز الـ Owner ومستخدمي السكريبت
-- =====================================================================
local Remote = Instance.new("RemoteEvent")
Remote.Name = "NeoHyper_UserTracker"
Remote.Parent = ReplicatedStorage

local ScriptUsers = {}
local OwnerName = "2_panda223" -- 🔴 غير ده لاسمك

-- تسجيل اللاعب عند تشغيل السكريبت
task.spawn(function()
    task.wait(2)
    Remote:FireServer("Register", LP.Name)
end)

-- استقبال اللي شغالين السكريبت
Remote.OnClientEvent:Connect(function(playerName)
    if playerName ~= LP.Name then
        ScriptUsers[playerName] = true
    end
end)
-- =====================================================================

-- ================================
-- دوال مشتركة
-- ================================

local function GetTargetPart(character)
    if not character then return nil end
    return character:FindFirstChild("Head")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChildWhichIsA("BasePart")
end

local function IsPlayerDowned(player)
    if not player or not player.Character then return false end
    local char = player.Character
    if char:GetAttribute("Downed") == true then return true end
    local hum = char:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then return true end
    return false
end

local function GetPlayerHealth(player)
    if not player or not player.Character then return 0 end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health or 0
end

local function GetDistance(root1, root2)
    if not root1 or not root2 then return 0 end
    return math.floor((root1.Position - root2.Position).Magnitude)
end

local function GetPlayerDisplayName(player)
    if ESPConfig.ShowUsername then
        return player.Name
    else
        return player.DisplayName
    end
end

-- ================================
-- دالة حساب الحجم حسب المسافة
-- ================================
local function CalculateSize(distance)
    if not ESPConfig.ZoomEffect then
        return ESPConfig.GuiSize
    end
    
    local baseSize = ESPConfig.GuiSize
    if distance > 0 then
        local extra = math.min(distance / 4, 220)
        return math.min(baseSize + extra, 400)
    end
    return baseSize
end

-- ================================
-- 1. ESP اللاعبين (مع تمييز Owner & Users)
-- ================================

local function CreatePlayerESP(player)
    if player == LP then return end
    local character = player.Character
    if not character then return end
    
    local targetPart = GetTargetPart(character)
    if not targetPart then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function()
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            humanoid.NameDisplayDistance = 0
        end)
    end
    
    if PlayerESPInstances[player] then
        pcall(function() PlayerESPInstances[player]:Destroy() end)
    end
    
    -- 🟡 تحديد حالة اللاعب
    local isOwner = (player.Name == OwnerName)
    local isScriptUser = ScriptUsers[player.Name]
    
    local backgroundColor = Color3.fromRGB(10, 0, 0)
    local strokeColor = Color3.fromRGB(80, 0, 0)
    local nameColor = normalColor
    local icon = ""

    if isOwner then
        backgroundColor = Color3.fromRGB(40, 30, 0)
        strokeColor = Color3.fromRGB(255, 215, 0)
        nameColor = Color3.fromRGB(255, 215, 0)
    elseif isScriptUser then
        icon = "👑 "
    end

    -- BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerESP_Hyper"
    billboard.Adornee = targetPart
    billboard.Size = UDim2.new(0, ESPConfig.GuiSize, 0, ESPConfig.GuiSize * 0.36)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1500
    billboard.Parent = targetPart
    
    -- خلفية
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = backgroundColor
    background.BackgroundTransparency = 0.35
    background.BorderSizePixel = 0
    background.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.15, 0)
    corner.Parent = background
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = strokeColor
    stroke.Thickness = isOwner and 2.5 or 1.5
    stroke.Parent = background
    
    -- اسم اللاعب
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -8, 0.45, 0)
    nameLabel.Position = UDim2.new(0, 4, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = icon .. GetPlayerDisplayName(player)
    nameLabel.TextColor3 = nameColor
    nameLabel.TextSize = ESPConfig.TextSize
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = billboard
    
    -- شريط الصحة
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(0.7, 0, 0.12, 0)
    healthBar.Position = UDim2.new(0.05, 0, 0.48, 4)
    healthBar.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = billboard
    
    local healthCorner = Instance.new("UICorner")
    healthCorner.CornerRadius = UDim.new(0.5, 0)
    healthCorner.Parent = healthBar
    
    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBar
    
    local healthCornerFill = Instance.new("UICorner")
    healthCornerFill.CornerRadius = UDim.new(0.5, 0)
    healthCornerFill.Parent = healthFill
    
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(0.25, 0, 0.12, 0)
    healthText.Position = UDim2.new(0.73, 5, 0.48, 4)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100"
    healthText.TextColor3 = Color3.fromRGB(255, 200, 200)
    healthText.TextSize = math.max(10, ESPConfig.TextSize - 3)
    healthText.Font = Enum.Font.GothamBold
    healthText.TextXAlignment = Enum.TextXAlignment.Left
    healthText.Parent = billboard
    
    -- الحالة
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
    statusLabel.Position = UDim2.new(0, 4, 0.6, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "ALIVE"
    statusLabel.TextColor3 = Color3.fromRGB(68, 255, 68)
    statusLabel.TextSize = math.max(8, ESPConfig.TextSize - 4)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = billboard
    
    -- المسافة
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(0.4, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0.55, 0, 0.6, 5)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = Color3.fromRGB(136, 136, 136)
    distanceLabel.TextSize = math.max(8, ESPConfig.TextSize - 4)
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Right
    distanceLabel.Parent = billboard

    PlayerESPInstances[player] = billboard
    return billboard
end

-- ================================
-- دالة تحديث حجم كل الـ ESP
-- ================================
local function UpdateAllESPSize()
    if not PlayerESPEnabled then return end
    
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    for player, gui in pairs(PlayerESPInstances) do
        if gui and gui.Parent then
            local targetPart = gui.Adornee
            local distance = 0
            
            if myRoot and targetPart then
                distance = GetDistance(myRoot, targetPart)
            end
            
            local size = CalculateSize(distance)
            gui.Size = UDim2.new(0, size, 0, size * 0.36)
            
            local textSize = ESPConfig.TextSize
            if ESPConfig.ZoomEffect then
                local sizeRatio = size / ESPConfig.GuiSize
                textSize = math.min(ESPConfig.TextSize * sizeRatio, 28)
            end
            
            local nameLabel = gui:FindFirstChild("NameLabel")
            if nameLabel then
                nameLabel.TextSize = textSize
            end
            
            local healthText = gui:FindFirstChild("HealthText")
            if healthText then
                healthText.TextSize = math.max(10, textSize - 3)
            end
            
            local statusLabel = gui:FindFirstChild("StatusLabel")
            if statusLabel then
                statusLabel.TextSize = math.max(8, textSize - 4)
            end
            
            local distanceLabel = gui:FindFirstChild("DistanceLabel")
            if distanceLabel then
                distanceLabel.TextSize = math.max(8, textSize - 4)
            end
        end
    end
end

local function ClearPlayerESP()
    for player, gui in pairs(PlayerESPInstances) do
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    PlayerESPInstances = {}
end

local function UpdateAllPlayerESP()
    if not PlayerESPEnabled then return end
    
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local specialName = ESPConfig.SpecialPlayer:lower()
    
    UpdateAllESPSize()
    
    for player, gui in pairs(PlayerESPInstances) do
        if not player or not player.Parent or not player.Character then
            if gui then gui:Destroy() end
            PlayerESPInstances[player] = nil
        else
            local character = player.Character
            local targetPart = GetTargetPart(character)
            local nameLabel = gui:FindFirstChild("NameLabel")
            local healthFill = gui:FindFirstChild("HealthBar") and gui.HealthBar:FindFirstChild("HealthFill")
            local healthText = gui:FindFirstChild("HealthText")
            local statusLabel = gui:FindFirstChild("StatusLabel")
            local distanceLabel = gui:FindFirstChild("DistanceLabel")
            
            if targetPart and gui.Adornee ~= targetPart then
                gui.Adornee = targetPart
                gui.Parent = targetPart
            end
            
            if targetPart and nameLabel then
                local isDowned = IsPlayerDowned(player)
                local health = GetPlayerHealth(player)
                
                local color = normalColor
                if isDowned then
                    color = downedColor
                end
                
                local playerNameLower = player.Name:lower()
                local playerDisplayLower = player.DisplayName:lower()
                if specialName ~= "" and (playerNameLower:find(specialName) or playerDisplayLower:find(specialName)) then
                    color = ESPConfig.SpecialPlayerColor
                end
                
                local statusText = isDowned and "DOWNED" or "ALIVE"
                
                local distance = ""
                if myRoot then
                    local dist = GetDistance(myRoot, targetPart)
                    distance = string.format(" [%dm]", dist)
                end
                
                local displayName = GetPlayerDisplayName(player)
                local newText = displayName .. distance
                if nameLabel.Text ~= newText then
                    nameLabel.Text = newText
                end
                if nameLabel.TextColor3 ~= color then
                    nameLabel.TextColor3 = color
                end
                
                if healthFill and healthText then
                    local maxHealth = 100
                    local percent = math.clamp(health / maxHealth, 0, 1)
                    healthFill.Size = UDim2.new(percent, 0, 1, 0)
                    
                    if percent > 0.6 then
                        healthFill.BackgroundColor3 = Color3.fromRGB(68, 255, 68)
                    elseif percent > 0.3 then
                        healthFill.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
                    else
                        healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                    end
                    
                    healthText.Text = math.floor(health) .. "%"
                end
                
                if statusLabel then
                    local statusColor = isDowned and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(68, 255, 68)
                    statusLabel.Text = statusText
                    statusLabel.TextColor3 = statusColor
                end
                
                if distanceLabel and myRoot and targetPart then
                    local dist = GetDistance(myRoot, targetPart)
                    distanceLabel.Text = dist .. "m"
                    
                    if dist < 20 then
                        distanceLabel.TextColor3 = Color3.fromRGB(255, 68, 68)
                    elseif dist < 50 then
                        distanceLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
                    else
                        distanceLabel.TextColor3 = Color3.fromRGB(136, 136, 136)
                    end
                end
            end
        end
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and not PlayerESPInstances[player] then
            CreatePlayerESP(player)
        end
    end
end

-- ================================
-- 2. Highlight (مع تمييز Owner & Users)
-- ================================

local function UpdatePlayerHighlight(player)
    if not player or player == LP then return end
    if not HighlightsEnabled then return end
    
    local character = player.Character
    if not character then return end
    
    local isDowned = IsPlayerDowned(player)
    local color = isDowned and downedColor or normalColor
    
    local specialName = ESPConfig.SpecialPlayer:lower()
    local playerNameLower = player.Name:lower()
    local playerDisplayLower = player.DisplayName:lower()
    if specialName ~= "" and (playerNameLower:find(specialName) or playerDisplayLower:find(specialName)) then
        color = ESPConfig.SpecialPlayerColor
    end
    
    -- 🔥 تمييز Owner ومستخدمي السكريبت في الـ Highlight
    if player.Name == OwnerName then
        color = Color3.fromRGB(255, 215, 0) -- ذهبي للأونر
    elseif ScriptUsers[player.Name] then
        color = Color3.fromRGB(0, 255, 255) -- سماوي للمستخدمين
    end
    
    if PlayerHighlights[player] then
        local highlight = PlayerHighlights[player]
        if highlight and highlight.Parent then
            highlight.FillColor = color
            highlight.OutlineColor = color
            return
        else
            PlayerHighlights[player] = nil
        end
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "HyperHighlight_" .. player.Name
    highlight.Parent = character
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.OutlineColor = color
    
    PlayerHighlights[player] = highlight
end

local function ClearAllHighlights()
    for player, highlight in pairs(PlayerHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    PlayerHighlights = {}
end

local function UpdateAllHighlights()
    if not HighlightsEnabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            UpdatePlayerHighlight(player)
        end
    end
end

-- ================================
-- عناصر التحكم في الواجهة
-- ================================

-- Toggle ESP
PlayerESPSection:Toggle({
    Title = "ESP Players",
    Flag = "PlayerESP",
    Desc = "Display player names with distance and status",
    Value = false,
    Callback = function(state)
        PlayerESPEnabled = state
        if state then
            ClearPlayerESP()
            UpdateAllPlayerESP()
            if PlayerESPConnection then PlayerESPConnection:Disconnect() end
            PlayerESPConnection = RunService.Heartbeat:Connect(UpdateAllPlayerESP)
            WindUI:Notify({ Title = "ESP", Content = "Players ESP Enabled", Duration = 2 })
        else
            if PlayerESPConnection then
                PlayerESPConnection:Disconnect()
                PlayerESPConnection = nil
            end
            ClearPlayerESP()
            WindUI:Notify({ Title = "ESP", Content = "Players ESP Disabled", Duration = 2 })
        end
    end,
})

-- لون ESP العادي
PlayerESPSection:Dropdown({
    Title = "Normal Color",
    Flag = "NormalColorDropdown",
    Values = { "White", "Blood Red", "Ocean Deep", "Red", "Green", "Blue", "Yellow", "Cyan", "Purple" },
    Default = "White",
    Callback = function(value)
        local colors = {
            White = Color3.fromRGB(255, 255, 255),
            ["Blood Red"] = Color3.fromRGB(255, 68, 68),
            ["Ocean Deep"] = Color3.fromRGB(0, 68, 170),
            Red = Color3.fromRGB(255, 0, 0),
            Green = Color3.fromRGB(0, 255, 0),
            Blue = Color3.fromRGB(0, 0, 255),
            Yellow = Color3.fromRGB(255, 255, 0),
            Cyan = Color3.fromRGB(0, 255, 255),
            Purple = Color3.fromRGB(255, 0, 255),
        }
        normalColor = colors[value] or Color3.fromRGB(255, 255, 255)
        if PlayerESPEnabled then UpdateAllPlayerESP() end
        if HighlightsEnabled then UpdateAllHighlights() end
    end,
})

-- لون ESP للميتين
PlayerESPSection:Dropdown({
    Title = "Downed Color",
    Flag = "DownedColorDropdown",
    Values = { "Red", "Blood Red", "Dark Red", "Orange", "Yellow" },
    Default = "Red",
    Callback = function(value)
        local colors = {
            Red = Color3.fromRGB(255, 0, 0),
            ["Blood Red"] = Color3.fromRGB(255, 68, 68),
            ["Dark Red"] = Color3.fromRGB(200, 0, 0),
            Orange = Color3.fromRGB(255, 100, 0),
            Yellow = Color3.fromRGB(255, 200, 0),
        }
        downedColor = colors[value] or Color3.fromRGB(255, 0, 0)
        if PlayerESPEnabled then UpdateAllPlayerESP() end
        if HighlightsEnabled then UpdateAllHighlights() end
    end,
})



-- ================================
-- خيارات العرض
-- ================================

PlayerESPSection:Space()
PlayerESPSection:Divider({ Title = "Display Options" })

-- خيار عرض الاسم / اليوزرنيم
PlayerESPSection:Toggle({
    Title = "Show Username",
    Flag = "ShowUsername",
    Desc = "Show Username instead of Display Name",
    Value = false,
    Callback = function(state)
        ESPConfig.ShowUsername = state
        if PlayerESPEnabled then
            UpdateAllPlayerESP()
        end
    end,
})

-- خيار سمك الخط
PlayerESPSection:Dropdown({
    Title = "Text Stroke Style",
    Flag = "TextStrokeStyle",
    Values = { "Thin", "Thick" },
    Default = "Thin",
    Callback = function(value)
        ESPConfig.TextStroke = (value == "Thick")
        if PlayerESPEnabled then
            for player, gui in pairs(PlayerESPInstances) do
                local label = gui and gui:FindFirstChild("NameLabel")
                if label then
                    if ESPConfig.TextStroke then
                        label.TextStrokeTransparency = 0.2
                    else
                        label.TextStrokeTransparency = 0.5
                    end
                end
            end
        end
    end,
})

-- ================================
-- Special Player
-- ================================

PlayerESPSection:Space()
PlayerESPSection:Divider({ Title = "Special Player" })

PlayerESPSection:Input({
    Title = "Special Player Name",
    Flag = "SpecialPlayerName",
    Placeholder = "Enter player name...",
    Value = "",
    Callback = function(value)
        ESPConfig.SpecialPlayer = value
        if PlayerESPEnabled then
            UpdateAllPlayerESP()
            UpdateAllHighlights()
        end
    end,
})

PlayerESPSection:Dropdown({
    Title = "Special Player Color",
    Flag = "SpecialPlayerColor",
    Values = { "Gold", "White", "Blood Red", "Ocean Deep", "Red", "Green", "Blue", "Yellow", "Cyan", "Purple" },
    Default = "Gold",
    Callback = function(value)
        local colors = {
            Gold = Color3.fromRGB(255, 215, 0),
            White = Color3.fromRGB(255, 255, 255),
            ["Blood Red"] = Color3.fromRGB(255, 68, 68),
            ["Ocean Deep"] = Color3.fromRGB(0, 68, 170),
            Red = Color3.fromRGB(255, 0, 0),
            Green = Color3.fromRGB(0, 255, 0),
            Blue = Color3.fromRGB(0, 0, 255),
            Yellow = Color3.fromRGB(255, 255, 0),
            Cyan = Color3.fromRGB(0, 255, 255),
            Purple = Color3.fromRGB(255, 0, 255),
        }
        ESPConfig.SpecialPlayerColor = colors[value] or Color3.fromRGB(255, 215, 0)
        if PlayerESPEnabled then
            UpdateAllPlayerESP()
            UpdateAllHighlights()
        end
    end,
})

-- ================================
-- خيارات الحجم والشكل
-- ================================

PlayerESPSection:Space()
PlayerESPSection:Divider({ Title = "Size Options" })

-- Toggle Zoom Effect
PlayerESPSection:Toggle({
    Title = "Zoom Effect",
    Flag = "ZoomEffect",
    Desc = "ESP grows bigger when player is far away",
    Value = false,
    Callback = function(state)
        ESPConfig.ZoomEffect = state
        if PlayerESPEnabled then
            UpdateAllESPSize()
        end
    end,
})

-- حجم الـ GUI
PlayerESPSection:Slider({
    Title = "GUI Size",
    Flag = "ESP_GuiSize",
    Desc = "Size of the ESP box (100-300)",
    Value = { Min = 50, Max = 300, Default = 100 },
    Step = 5,
    Callback = function(value)
        ESPConfig.GuiSize = value
        UpdateAllESPSize()
    end,
})

-- حجم النص
PlayerESPSection:Slider({
    Title = "Text Size",
    Flag = "ESP_TextSize",
    Desc = "Size of the text (10-24)",
    Value = { Min = 5, Max = 24, Default = 10 },
    Step = 1,
    Callback = function(value)
        ESPConfig.TextSize = value
        UpdateAllESPSize()
    end,
})
-- ================================
-- Refresh & Reset
-- ================================

PlayerESPSection:Space()
PlayerESPSection:Divider({ Title = "Controls" })

PlayerESPSection:Button({
    Title = "Refresh ESP",
    Desc = "Manually refresh all player ESP",
    Callback = function()
        if PlayerESPEnabled then
            ClearPlayerESP()
            UpdateAllPlayerESP()
            WindUI:Notify({ Title = "ESP", Content = "Refreshed", Duration = 1 })
        else
            WindUI:Notify({ Title = "ESP", Content = "Enable ESP first", Duration = 1 })
        end
    end,
})

PlayerESPSection:Button({
    Title = "Reset Settings",
    Desc = "Reset all ESP settings to default",
    Callback = function()
        normalColor = Color3.fromRGB(255, 255, 255)
        downedColor = Color3.fromRGB(255, 0, 0)
        ESPConfig.TextStroke = false
        ESPConfig.SpecialPlayer = ""
        ESPConfig.SpecialPlayerColor = Color3.fromRGB(255, 215, 0)
        ESPConfig.ShowUsername = false
        ESPConfig.TextSize = 14
        ESPConfig.GuiSize = 180
        ESPConfig.ZoomEffect = false
        if PlayerESPEnabled then
            ClearPlayerESP()
            UpdateAllPlayerESP()
        end
        if HighlightsEnabled then
            ClearAllHighlights()
            UpdateAllHighlights()
        end
        WindUI:Notify({ Title = "ESP", Content = "Settings Reset", Duration = 2 })
    end,
})

-- Toggle Highlight
PlayerESPSection:Toggle({
    Title = "Player Highlight",
    Flag = "PlayerHighlight",
    Desc = "Highlight players with colors",
    Value = false,
    Callback = function(state)
        HighlightsEnabled = state
        if state then
            ClearAllHighlights()
            UpdateAllHighlights()
            if HighlightsConnection then HighlightsConnection:Disconnect() end
            HighlightsConnection = RunService.Heartbeat:Connect(UpdateAllHighlights)
            WindUI:Notify({ Title = "Highlight", Content = "Enabled", Duration = 2 })
        else
            if HighlightsConnection then
                HighlightsConnection:Disconnect()
                HighlightsConnection = nil
            end
            ClearAllHighlights()
            WindUI:Notify({ Title = "Highlight", Content = "Disabled", Duration = 2 })
        end
    end,
})

-- ================================
-- Services & Events
-- ================================

if LP.Character then
    task.wait(1)
    if PlayerESPEnabled then UpdateAllPlayerESP() end
    if HighlightsEnabled then UpdateAllHighlights() end
end

LP.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(function()
        if PlayerESPEnabled then
            ClearPlayerESP()
            UpdateAllPlayerESP()
        end
        if HighlightsEnabled then
            ClearAllHighlights()
            UpdateAllHighlights()
        end
    end)
end)

print("[ESP] Player ESP loaded successfully!")




-- ================================
-- Nextbot ESP & Highlight (Fixed Version)
-- ================================
local NextbotSection = Tabs.ESP:Section({
    Title = "Nextbot ESP & Highlight",
    Side = "Left",
    Collapsed = true,
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- المتغيرات العامة
local nextbotESPEnabled = false
local nextbotHighlightEnabled = false
local nextbotBillboards = {}
local nextbotHighlights = {}
local nextbotConnection = nil

-- الألوان الافتراضية (بنفسجي ناري ساطع وببنفسجي غامق)
local nextbotESPColor = Color3.fromHex("#cc44ff")
local nextbotHighlightColor = Color3.fromHex("#8800cc")

-- جلب أسماء النمادج الخاصة بالـ NPCs من المسار الصحيح المحدث
local nextBotNames = {}
local npcsFolder = ReplicatedStorage:FindFirstChild("NPCs") or game:GetService("ReplicatedStorage").Info.Templates.NPC
if npcsFolder then
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        table.insert(nextBotNames, npc.Name)
    end
end

-- دالة التحقق من الـ Nextbot بذكاء
local function IsNextbotModel(model)
    if not model or not model.Name then return false end
    
    for _, name in ipairs(nextBotNames) do
        if model.Name == name then return true end
    end
    
    local nameLower = model.Name:lower()
    return nameLower:find("nextbot") or 
           nameLower:find("scp") or 
           nameLower:find("monster") or
           nameLower:find("creep") or
           nameLower:find("enemy") or
           nameLower:find("zombie") or
           nameLower:find("ghost") or
           nameLower:find("demon")
end

-- دالة جلب الجزء الأساسي للهدف
local function GetNextbotTargetPart(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Head")
        or model:FindFirstChild("Torso")
        or model:FindFirstChildWhichIsA("BasePart")
end

-- 1. إنشاء ESP للـ Nextbots
local function CreateNextbotESP(model)
    if not model then return end
    
    local targetPart = GetNextbotTargetPart(model)
    if not targetPart then return end
    
    if nextbotBillboards[model] then
        pcall(function() nextbotBillboards[model]:Destroy() end)
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NextbotESP_Hyper"
    billboard.Adornee = targetPart
    billboard.Size = UDim2.new(0, 140, 0, 45)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1500
    billboard.Parent = targetPart
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "⚠️ " .. model.Name
    label.TextColor3 = nextbotESPColor
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = billboard
    
    nextbotBillboards[model] = billboard
    return billboard
end

local function ClearNextbotESP()
    for model, gui in pairs(nextbotBillboards) do
        pcall(function() if gui then gui:Destroy() end end)
    end
    nextbotBillboards = {}
end

-- تحديث الـ ESP وعمل فحص للمجلدات المحدثة
local function UpdateAllNextbotESP()
    if not nextbotESPEnabled then return end
    
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local candidates = {}
    
    -- البحث في الأماكن المحتملة لتواجد الـ Nextbots / الوحوش في الخريطة والتحديث الجديد
    local searchFolders = {
        workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players"),
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("Active"),
        workspace -- البحث العام في الworkspace كخطة أمان احتياطية
    }
    
    for _, folder in ipairs(searchFolders) do
        if folder then
            for _, model in pairs(folder:GetChildren()) do
                if model:IsA("Model") and model ~= LP.Character and IsNextbotModel(model) then
                    candidates[model] = true
                end
            end
        end
    end
    
    for model in pairs(candidates) do
        local targetPart = GetNextbotTargetPart(model)
        if targetPart then
            if not nextbotBillboards[model] then
                CreateNextbotESP(model)
            end
            
            local gui = nextbotBillboards[model]
            if gui then
                local label = gui:FindFirstChildOfClass("TextLabel")
                if label then
                    if gui.Adornee ~= targetPart then
                        gui.Adornee = targetPart
                        gui.Parent = targetPart
                    end
                    
                    local distance = ""
                    if myRoot then
                        local dist = math.floor((targetPart.Position - myRoot.Position).Magnitude)
                        distance = string.format(" [%dm]", dist)
                    end
                    
                    local newText = "⚠️ " .. model.Name .. distance
                    if label.Text ~= newText then label.Text = newText end
                    if label.TextColor3 ~= nextbotESPColor then label.TextColor3 = nextbotESPColor end
                end
            end
        end
    end
    
    for model, gui in pairs(nextbotBillboards) do
        if not candidates[model] or not model.Parent then
            pcall(function() if gui then gui:Destroy() end end)
            nextbotBillboards[model] = nil
        end
    end
end

-- 2. الـ Highlight الخاص بالـ Nextbots
local function UpdateNextbotHighlight(model)
    if not nextbotHighlightEnabled then return end
    if not model or not model.Parent then return end
    
    if nextbotHighlights[model] then
        local highlight = nextbotHighlights[model]
        if highlight and highlight.Parent then
            highlight.FillColor = nextbotHighlightColor
            highlight.OutlineColor = nextbotHighlightColor
            return
        else
            nextbotHighlights[model] = nil
        end
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "NextbotHighlight_Hyper"
    highlight.Parent = model
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = nextbotHighlightColor
    highlight.OutlineColor = nextbotHighlightColor
    
    nextbotHighlights[model] = highlight
end

local function ClearAllNextbotHighlights()
    for model, highlight in pairs(nextbotHighlights) do
        pcall(function() if highlight then highlight:Destroy() end end)
    end
    nextbotHighlights = {}
end

local function UpdateAllNextbotHighlights()
    if not nextbotHighlightEnabled then return end
    
    local currentBots = {}
    local searchFolders = {
        workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players"),
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("Active"),
        workspace
    }
    
    for _, folder in ipairs(searchFolders) do
        if folder then
            for _, model in pairs(folder:GetChildren()) do
                if model:IsA("Model") and model ~= LP.Character and IsNextbotModel(model) then
                    currentBots[model] = true
                    UpdateNextbotHighlight(model)
                end
            end
        end
    end
    
    for model in pairs(nextbotHighlights) do
        if not currentBots[model] or not model.Parent then
            pcall(function() if nextbotHighlights[model] then nextbotHighlights[model]:Destroy() end end)
            nextbotHighlights[model] = nil
        end
    end
end

-- الحلقة الرئيسية للتشغيل
local function StartNextbotLoop()
    if nextbotConnection then return end
    nextbotConnection = RunService.Heartbeat:Connect(function()
        if nextbotESPEnabled then UpdateAllNextbotESP() end
        if nextbotHighlightEnabled then UpdateAllNextbotHighlights() end
    end)
end

local function StopNextbotLoop()
    if nextbotConnection then
        nextbotConnection:Disconnect()
        nextbotConnection = nil
    end
    ClearNextbotESP()
    ClearAllNextbotHighlights()
end

-- أزرار الواجهة (WindUI Elements)
NextbotSection:Toggle({
    Title = "Nextbot ESP",
    Flag = "NextbotESP",
    Desc = "Display Nextbot names with distance (Purple Theme)",
    Value = false,
    Callback = function(state)
        nextbotESPEnabled = state
        if nextbotESPEnabled or nextbotHighlightEnabled then StartNextbotLoop() else StopNextbotLoop() end
    end,
})

NextbotSection:Toggle({
    Title = "Nextbot Highlight",
    Flag = "NextbotHighlight",
    Desc = "Highlight Nextbots with Purple color",
    Value = false,
    Callback = function(state)
        nextbotHighlightEnabled = state
        if nextbotESPEnabled or nextbotHighlightEnabled then StartNextbotLoop() else StopNextbotLoop() end
    end,
})

NextbotSection:Dropdown({
    Title = "Nextbot ESP Color",
    Flag = "NextbotESPColorDropdown",
    Values = { "Purple Neon", "Purple", "Red", "Green", "Blue", "Yellow", "Cyan", "White" },
    Default = "Purple Neon",
    Callback = function(value)
        local colors = {
            ["Purple Neon"] = Color3.fromHex("#cc44ff"),
            ["Purple"] = Color3.fromRGB(128, 0, 255),
            Red = Color3.fromRGB(255, 0, 0),
            Green = Color3.fromRGB(0, 255, 0),
            Blue = Color3.fromRGB(0, 0, 255),
            Yellow = Color3.fromRGB(255, 255, 0),
            Cyan = Color3.fromRGB(0, 255, 255),
            White = Color3.fromRGB(255, 255, 255),
        }
        nextbotESPColor = colors[value] or Color3.fromHex("#cc44ff")
    end,
})

NextbotSection:Dropdown({
    Title = "Nextbot Highlight Color",
    Flag = "NextbotHighlightColorDropdown",
    Values = { "Purple Dark", "Purple", "Red", "Green", "Blue", "Yellow", "Cyan", "White" },
    Default = "Purple Dark",
    Callback = function(value)
        local colors = {
            ["Purple Dark"] = Color3.fromHex("#8800cc"),
            ["Purple"] = Color3.fromRGB(128, 0, 255),
            Red = Color3.fromRGB(255, 0, 0),
            Green = Color3.fromRGB(0, 255, 0),
            Blue = Color3.fromRGB(0, 0, 255),
            Yellow = Color3.fromRGB(255, 255, 0),
            Cyan = Color3.fromRGB(0, 255, 255),
            White = Color3.fromRGB(255, 255, 255),
        }
        nextbotHighlightColor = colors[value] or Color3.fromHex("#8800cc")
    end,
})

print("[ESP] Nextbot features loaded cleanly!")

-- ================================
-- Performance & Visuals (في تبويب ESP)
-- ================================

local PerfVisualSection = ESPTab:Section({
    Title = "Performance & Visuals",
    Side = "Left",
    Collapsed = true,
})

-- ================================
-- متغيرات الحالة
-- ================================
local noFogEnabled = false
local originalFogEnd = nil
local fullBrightEnabled = false
local originalBrightness = nil
local originalAmbient = nil

-- ================================
-- 1. Anti Lag Buttons
-- ================================

-- Anti Lag 1 (أساسي)
PerfVisualSection:Button({
    Title = "Anti Lag 1 - Basic Clean",
    Desc = "Removes heavy shadows and effects",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        Lighting.Brightness = 1
        
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj:Destroy()
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
            end
        end
        
        WindUI:Notify({ Title = "Anti Lag", Content = "Performance improved (Level 1)", Duration = 2 })
    end,
})

-- Anti Lag 2 (متوسط)
PerfVisualSection:Button({
    Title = "Anti Lag 2 - Medium Clean",
    Desc = "It removes visual effects and particles.",
    Callback = function()
        for _, v in next, game:GetDescendants() do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
            end
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
                v.Enabled = false
            end
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
                v.Enabled = false
            end
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Texture = ""
            end
            if v:IsA("Sky") then
                v.Parent = nil
            end
        end
        
        WindUI:Notify({ Title = "Anti Lag", Content = "Performance improved (Level 2)", Duration = 2 })
    end,
})

-- Anti Lag 3 (إزالة التكستشرز)
PerfVisualSection:Button({
    Title = "Anti Lag 3 - Remove Textures",
    Desc = "Removes all textures from the game",
    Callback = function()
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
                if part:IsA("Part") then
                    part.Material = Enum.Material.SmoothPlastic
                end
                for _, texture in ipairs(part:GetChildren()) do
                    if texture:IsA("Texture") or texture:IsA("Decal") then
                        texture.Texture = "rbxassetid://0"
                    end
                end
            end
        end
        
        WindUI:Notify({ Title = "Anti Lag", Content = "Textures removed", Duration = 2 })
    end,
})

-- ================================
-- 2. No Fog (إزالة الضباب)
-- ================================
PerfVisualSection:Toggle({
    Title = "No Fog",
    Desc = "Removes fog from the game",
    Icon = "cloud",
    Value = false,
    Type = "Toggle",
    Callback = function(state)
        local Lighting = game:GetService("Lighting")
        if state then
            originalFogEnd = Lighting.FogEnd
            Lighting.FogEnd = 1000000
            WindUI:Notify({ Title = "No Fog", Content = "Fog removed", Duration = 2 })
        else
            Lighting.FogEnd = originalFogEnd or 100000
            WindUI:Notify({ Title = "No Fog", Content = "Fog restored", Duration = 2 })
        end
        noFogEnabled = state
    end,
})

-- ================================
-- 3. Full Bright (إضاءة كاملة)
-- ================================
PerfVisualSection:Toggle({
    Title = "Full Bright",
    Desc = "The entire game lights up",
    Icon = "sun",
    Value = false,
    Type = "Toggle",
    Callback = function(state)
        local Lighting = game:GetService("Lighting")
        if state then
            originalBrightness = Lighting.Brightness
            originalAmbient = Lighting.Ambient
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            WindUI:Notify({ Title = "Full Bright", Content = "Full bright enabled", Duration = 2 })
        else
            Lighting.Brightness = originalBrightness or 0.5
            Lighting.Ambient = originalAmbient or Color3.fromRGB(127, 127, 127)
            Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
            WindUI:Notify({ Title = "Full Bright", Content = "Full bright disabled", Duration = 2 })
        end
        fullBrightEnabled = state
    end,
})

-- ================================
-- 4. Reset All Settings
-- ================================
PerfVisualSection:Button({
    Title = "Reset All Performance Settings",
    Desc = "All performance settings are restored to normal.",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        
        Lighting.GlobalShadows = true
        Lighting.Brightness = 0.5
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        Lighting.FogEnd = 100000
        
        if noFogEnabled then
            noFogEnabled = false
        end
        
        if fullBrightEnabled then
            fullBrightEnabled = false
        end
        
        WindUI:Notify({ Title = "Reset", Content = "All settings reset to default", Duration = 3 })
    end,
})
-- ================================
-- Barriers Section (في تبويب ESP)
-- ================================

local BarriersSection = ESPTab:Section({
    Title = "Barriers",
    Side = "Left",
    Collapsed = true,
})

-- متغيرات الحواجز
local barriersRemoved = false
local barriersVisible = false

-- وظيفة البحث عن المسار الجديد بالحواجز (مع خطط بديلة للاحتياط)
local function GetInvisParts()
    local map = workspace:FindFirstChild("Map")
    if map then
        local invisParts = map:FindFirstChild("InvisParts")
        if invisParts then
            local cutParts = invisParts:FindFirstChild("CutParts")
            if cutParts then
                local outsideBarrier = cutParts:FindFirstChild("outsidebarrier")
                if outsideBarrier then
                    return outsideBarrier
                end
            end
            return invisParts
        end
    end
    
    -- خطة بديلة للقديم لو مش موجود
    local gameFolder = workspace:FindFirstChild("Game")
    if gameFolder then
        local mapFolder = gameFolder:FindFirstChild("Map")
        if mapFolder then
            return mapFolder:FindFirstChild("InvisParts")
        end
    end
    
    return nil
end

-- وظيفة Remove Barriers (تعطيل التصادم)
local function ToggleBarriers(state)
    local targetFolder = GetInvisParts()
    if not targetFolder then
        WindUI:Notify({ Title = "Barriers", Content = "Barrier path not found", Duration = 2 })
        return false
    end
    
    local changed = 0
    for _, obj in ipairs(targetFolder:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = not state
            obj.CanQuery = not state
            changed = changed + 1
        end
    end
    
    WindUI:Notify({ Title = "Barriers", Content = string.format("Collision updated for %d parts", changed), Duration = 2 })
    return true
end

-- وظيفة Barriers Visible (إظهار الحواجز الشفافة)
local function ToggleBarriersVisible(state)
    local targetFolder = GetInvisParts()
    if not targetFolder then
        WindUI:Notify({ Title = "Barriers", Content = "Barrier path not found", Duration = 2 })
        return false
    end
    
    local changed = 0
    local transparency = state and 0 or 1
    
    for _, obj in ipairs(targetFolder:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Decal") then
            obj.Transparency = transparency
            changed = changed + 1
        end
    end
    
    WindUI:Notify({ Title = "Barriers", Content = string.format("Visibility updated for %d objects", changed), Duration = 2 })
    return true
end

-- زر Remove Barriers
BarriersSection:Toggle({
    Title = "Remove Barriers",
    Desc = "Disable barriers (pass through them)",
    Icon = "shield-off",
    Value = false,
    Type = "Toggle",
    Callback = function(state)
        barriersRemoved = state
        ToggleBarriers(state)
    end,
})

-- زر Barriers Visible
BarriersSection:Toggle({
    Title = "Barriers Visible",
    Desc = "Show transparent barriers (make them visible)",
    Icon = "eye",
    Value = false,
    Type = "Toggle",
    Callback = function(state)
        barriersVisible = state
        ToggleBarriersVisible(state)
        
        -- مراقبة إضافة أجزاء جديدة
        if state then
            local targetFolder = GetInvisParts()
            if targetFolder then
                targetFolder.DescendantAdded:Connect(function(obj)
                    if barriersVisible then
                        task.wait(0.05)
                        if obj:IsA("BasePart") or obj:IsA("Decal") then
                            obj.Transparency = 0
                        end
                    end
                end)
            end
        end
    end,
})
