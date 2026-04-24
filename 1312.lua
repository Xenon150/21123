-- ==========================================
-- НАСТРОЙКИ АККАУНТОВ И ССЫЛОК НА ПРИВАТКИ
-- ==========================================
local ACCOUNTS = {
    ["Yippe8980"]            = "https://www.roblox.com/share?code=b391e85809fbb3439ed533cd8dc5448b&type=Server",
    ["ggdgdhthgtgdhhb"]      = "https://www.roblox.com/share?code=78cfa0c21970ca4fb5140d0cd9acdb6f&type=Server",
    ["k0uhuqst2xbnwbbm"]     = "https://www.roblox.com/share?code=29ab404648869b459c53f77b6cffc2a5&type=Server",
    ["c9zdadakrhm6dyqogoee"] = "https://www.roblox.com/share?code=aea8d1dbced7f847b231413eac1ac42c&type=Server",
    ["5o9h2m7hu18jh9k8zog"]  = "https://www.roblox.com/share?code=dd14b7c7487be049a9e5b417c0e6a4db&type=Server",
    ["7a5fir39k0eu5x"]       = "https://www.roblox.com/share?code=77ea1780b1e8234fbf412f7aacf9e44a&type=Server",
    ["xh18pd8tl0tv88vcg7p"]  = "https://www.roblox.com/share?code=68216ea36fc03440a2de4d0b8ee37fd1&type=Server",
    ["svtedusn3a8rbe6v"]     = "https://www.roblox.com/share?code=0a3e006e92e81f41bae4614f3ac7be32&type=Server",
    ["6zcm2ejca9l32lwkl"]    = "https://www.roblox.com/share?code=1c7a9def5eb7a2449e23634c81ea09dc&type=Server",
    ["cyhgv26p0ldamwhs2"]    = "https://www.roblox.com/share?code=dfc6433236824148a6d51e4b33135671&type=Server",
    ["1p4ai22qkhfl3ykj8wdy"] = "https://www.roblox.com/share?code=0525f1dbb6fa1947a8492f5ff74bf3ac&type=Server",
    ["sb6r3uir7d2rd56"]      = "https://www.roblox.com/share?code=2a8128e1f1e20541915cf51bbe0bcb5b&type=Server",
}

-- ==========================================
-- СЕРВИСЫ
-- ==========================================
local HttpService         = game:GetService("HttpService")
local TextChatService     = game:GetService("TextChatService")
local Players             = game:GetService("Players")
local PathfindingService  = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService    = game:GetService("UserInputService")
local RunService          = game:GetService("RunService")
local CoreGui             = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- ОПРЕДЕЛЯЕМ АККАУНТ И ССЫЛКУ
local playerName = player.Name:lower()
local accountLink = nil
for nick, link in pairs(ACCOUNTS) do
    if playerName == nick:lower() then
        accountLink = link
        break
    end
end
if accountLink then
    print("[Tracker]: Аккаунт определён → " .. player.Name)
else
    print("[Tracker]: Аккаунт не найден в списке → " .. player.Name)
end

-- ==========================================
-- УНИВЕРСАЛЬНАЯ ФУНКЦИЯ HTTP-ЗАПРОСОВ
-- ==========================================
local function getRequestFunc()
    if syn and syn.request then return syn.request end
    if http_request then return http_request end
    if request then return request end
    if httpRequest then return httpRequest end
    if fluxus and fluxus.request then return fluxus.request end
    return nil
end

-- ==========================================
-- ВЕБХУКИ
-- ==========================================
local CHAT_WEBHOOK_URL  = "https://discord.com/api/webhooks/1489315967455596714/dW3ann_p2G8xWEGj_ivisYWCY0kk9p_TM8Z7KL94xDcjrega3QyGQbzX04sNyYoqXRfl"
local FARM_WEBHOOK_URL  = "https://discord.com/api/webhooks/1488832159904043108/RBf3b0n4UI4FAlaGoSDdASBz6ll61xZ_jZZXEY-cm88s8YwlfMVWqBewezEPWPHnO6pm"
local BIOME_WEBHOOK_URL = "https://discord.com/api/webhooks/1487364754824630344/ksjs-O211EhlZoWUdT_cbipFKUf_UVJjAGZS__Gvg1LwkxyrZNBDqUveIHfyAr6UpAAj"

-- ==========================================
-- МОНИТОРИНГ БИОМОВ
-- ==========================================
local PING_BIOMES = {"CYBERSPACE", "DREAMSPACE"}
local trackedBiomeObjects = {}
local lastBiomeSent = ""

local function sendBiomeToDiscord(title, description, ping)
    local msg = title .. description
    if lastBiomeSent == msg then return end
    lastBiomeSent = msg
    local fullDescription = description
    if accountLink and accountLink ~= "" then
        fullDescription = description .. "\n\n🔗 **[Войти в сервер](" .. accountLink .. ")**"
    end
    task.spawn(function()
        local reqFunc = getRequestFunc()
        if not reqFunc or BIOME_WEBHOOK_URL == "" then return end
        pcall(function()
            reqFunc({
                Url     = BIOME_WEBHOOK_URL,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = HttpService:JSONEncode({
                    ["content"] = ping and "@everyone" or nil,
                    ["embeds"]  = {{
                        ["title"]       = title,
                        ["description"] = fullDescription,
                        ["color"]       = ping and 16711680 or 16753488,
                        ["timestamp"]   = DateTime.now():ToIsoDate(),
                        ["footer"]      = {["text"] = "👤 " .. player.Name}
                    }}
                })
            })
        end)
    end)
end

local function isBiomLabel(v)
    local ok, result = pcall(function()
        return v:IsA("TextLabel")
            and v.Parent ~= nil
            and v.Parent:IsA("TextLabel")
            and v.Text:match("^%[ .+ %]$") ~= nil
    end)
    return ok and result
end

local function shouldPingBiome(text)
    for _, biom in pairs(PING_BIOMES) do
        if text:lower():find(biom:lower(), 1, true) then return true end
    end
    if text:match("%d") then return true end
    return false
end

local function handleBiom(text, title)
    print("[Tracker]: " .. title .. " → " .. text)
    if shouldPingBiome(text) then
        sendBiomeToDiscord(title, "**Биом:** `" .. text .. "`", true)
        return
    end
    task.spawn(function()
        for i = 1, 3 do
            task.wait(1)
            if text:match("%d") then
                sendBiomeToDiscord(title, "**Биом:** `" .. text .. "`", true)
                return
            end
        end
        sendBiomeToDiscord(title, "**Биом:** `" .. text .. "`", false)
    end)
end

local function trackBiomeLabel(v)
    pcall(function()
        if trackedBiomeObjects[v] or not isBiomLabel(v) then return end
        trackedBiomeObjects[v] = true
        handleBiom(v.Text, "🌍 Текущий биом")
        v:GetPropertyChangedSignal("Text"):Connect(function()
            if not v.Parent then return end
            handleBiom(v.Text, "🔄 Смена биома!")
        end)
        v.AncestryChanged:Connect(function()
            if not v.Parent then trackedBiomeObjects[v] = nil end
        end)
    end)
end

local pGui = player:WaitForChild("PlayerGui")
task.spawn(function()
    task.wait(0.5)
    for _, v in pairs(pGui:GetDescendants()) do trackBiomeLabel(v) end
end)
pGui.DescendantAdded:Connect(function(v)
    if not v:IsA("TextLabel") then return end
    task.wait(0.1)
    trackBiomeLabel(v)
end)

-- ==========================================
-- МОНИТОРИНГ ЧАТА НА МЕРЧАНТОВ
-- ==========================================
local CHAT_CONFIG = {
    ["jester"] = {color = 10181046, name = "Jester", emoji = "🎪"},
    ["mari"]   = {color = 16777215, name = "Mari",   emoji = "🌙"},
    ["rin"]    = {color = 16776960, name = "Rin",    emoji = "☀️"}
}

local function cleanRichText(str)
    return str:gsub("<[^>]+>", "")
end

local function sendChatToDiscord(sender, message, info)
    task.spawn(function()
        local reqFunc = getRequestFunc()
        if not reqFunc or CHAT_WEBHOOK_URL == "" then return end
        local cleanedMessage = cleanRichText(message)
        local description = string.format(
            "**Отправитель:** %s\n**Сообщение:** %s\n**Триггер:** %s",
            sender, cleanedMessage, info.name
        )
        if accountLink and accountLink ~= "" then
            description = description .. "\n\n🔗 **[Войти в сервер](" .. accountLink .. ")**"
        end
        local body = {
            ["content"]    = "@everyone продавец (ази пупсик)!",
            ["username"]   = "nexus Monitor",
            ["avatar_url"] = "https://cdn-icons-png.flaticon.com/512/8646/8646083.png",
            ["embeds"]     = {{
                ["title"]       = info.emoji .. " Новое совпадение в чате",
                ["description"] = description,
                ["color"]       = info.color,
                ["footer"]      = {
                    ["text"] = "Игра: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
                             .. " • " .. os.date("%H:%M:%S") .. " | 👤 " .. player.Name
                },
                ["timestamp"] = DateTime.now():ToIsoDate()
            }}
        }
        local senderPlayer = Players:FindFirstChild(sender)
        if senderPlayer then
            body.embeds[1].thumbnail = {
                ["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="
                        .. senderPlayer.UserId .. "&width=150&height=150&format=png"
            }
        end
        pcall(function()
            reqFunc({
                Url     = CHAT_WEBHOOK_URL,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = HttpService:JSONEncode(body)
            })
        end)
    end)
end

TextChatService.MessageReceived:Connect(function(textChatMessage)
    local rawText    = textChatMessage.Text:lower()
    local senderName = "Unknown"
    if textChatMessage.TextSource then
        senderName = textChatMessage.TextSource.Name
    else
        local cleanMsg = cleanRichText(textChatMessage.Text)
        local match = cleanMsg:match("^%[(.-)%]") or cleanMsg:match("^(.-):")
        if match then senderName = match end
    end
    local isMerchant = (senderName:lower() == "merchant" or rawText:find("%[merchant%]"))
    local paddedText = " " .. rawText:gsub("[%p%c]", " ") .. " "
    for key, info in pairs(CHAT_CONFIG) do
        local isFound = false
        if isMerchant then
            if rawText:find(key) then isFound = true end
        else
            if paddedText:find(" " .. key .. " ", 1, true) then isFound = true end
        end
        if isFound then
            sendChatToDiscord(senderName, textChatMessage.Text, info)
            break
        end
    end
end)

-- ==========================================
-- EGG FARM
-- ==========================================
local AutoStart          = false
local ForcedScanInterval = 30
local isFarming          = AutoStart
local activeEggs         = {}
local tempSkips          = {}
local totalCollected     = 0
local pendingEggs        = {}

-- ==== DEBUG ZONES ====
local debugZonesData = {
    {Size = Vector3.new(10, 2.5, 10),  CFrame = CFrame.new(180.654694, 83.9499969, -592.783386, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(35, 2, 15),    CFrame = CFrame.new(191.5, 97, -671, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(16, 2, 25),    CFrame = CFrame.new(130.5, 94, -675, 0,0,1, 0,1,-0, -1,0,0)},
    {Size = Vector3.new(10, 2, 25),    CFrame = CFrame.new(94.5, 98, -647.5, 0,0,1, 0,1,-0, -1,0,0)},
    {Size = Vector3.new(11, 2, 20),    CFrame = CFrame.new(98.5, 88.0000153, -426.5, 0,0,1, 0,1,-0, -1,0,0)},
    {Size = Vector3.new(20, 2, 4),     CFrame = CFrame.new(83, 88.0000153, -429.5, 0,0,1, 0,1,-0, -1,0,0)},
    {Size = Vector3.new(8, 2, 16),     CFrame = CFrame.new(77, 90.0000153, -442, 0,0,1, 0,1,-0, -1,0,0)},
    {Size = Vector3.new(10, 0.5, 5),   CFrame = CFrame.new(173.322296, 86.5, -575.310608, 0.499959469,0,0.866048813, 0,1,0, -0.866048813,0,0.499959469)},
    {Size = Vector3.new(7, 0.5, 2),    CFrame = CFrame.new(189.179077, 87, -602.072876, 0.984812498,-0,-0.173621148, 0,1,-0, 0.173621148,0,0.984812498)},
    {Size = Vector3.new(6, 5, 18.999996185302734), CFrame = CFrame.new(171, 94, -681.5, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(38, 2, 25),    CFrame = CFrame.new(527, 94.0000153, -124, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(10, 6, 20),    CFrame = CFrame.new(541.158752, 117.000008, -268.721222, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(2, 17, 5),     CFrame = CFrame.new(566.847534, 190.999985, -165.76091, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(7, 17, 4),     CFrame = CFrame.new(569, 197.5, -170.5, 0,0,1, 0,1,-0, -1,0,0)},
    {Size = Vector3.new(7, 8, 5),      CFrame = CFrame.new(583.261841, 220.999985, -223.692963, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(7, 230, 25),   CFrame = CFrame.new(626.5, 113.5, -192.5, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(8, 236, 20),   CFrame = CFrame.new(624, 118.000015, -157.5, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(4, 8, 4),      CFrame = CFrame.new(575.013, 187.000015, -225, 1,0,0, 0,1,0, 0,0,1)},
    {Size = Vector3.new(50, 2, 28.999996185302734), CFrame = CFrame.new(55, 101, -605.5, 1,0,0, 0,1,0, 0,0,1)}
}

task.spawn(function()
    local folderName = "RedDebugZones"
    local folder = workspace:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = workspace
    else
        folder:ClearAllChildren()
    end
    for i, data in ipairs(debugZonesData) do
        local part = Instance.new("Part")
        part.Name         = "Zone_" .. tostring(i)
        part.Size         = data.Size
        part.CFrame       = data.CFrame
        part.Color        = Color3.fromRGB(255, 0, 0)
        part.Transparency = 0.8
        part.Material     = Enum.Material.SmoothPlastic
        part.Anchored     = true
        part.CanCollide   = true
        local pathMod       = Instance.new("PathfindingModifier")
        pathMod.Label       = "ClimbPlatform"
        pathMod.PassThrough = false
        pathMod.Parent      = part
        part.Parent         = folder
    end
end)

-- ==== ПОИСК ЛЕЙБЛА ОЧКОВ ====
local cachedPointsLabel = nil
local function findPointsLabel()
    local ok, result = pcall(function()
        for _, desc in ipairs(player.PlayerGui:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local c = desc.TextColor3
                if math.abs(c.R - 170/255) < 0.05
                and math.abs(c.G - 1)       < 0.05
                and math.abs(c.B - 127/255) < 0.05 then
                    local txt = desc.Text
                    if txt:find("%[") or txt:find("%]") or txt == "" then continue end
                    return desc
                end
            end
        end
        return nil
    end)
    return ok and result or nil
end

local function getPointsText()
    if cachedPointsLabel and cachedPointsLabel.Parent then
        local txt = cachedPointsLabel.Text
        if not txt:find("%[") and not txt:find("%]") and txt ~= "" then return txt end
    end
    cachedPointsLabel = findPointsLabel()
    if cachedPointsLabel then return cachedPointsLabel.Text end
    return nil
end

task.spawn(function()
    while true do
        if not cachedPointsLabel or not cachedPointsLabel.Parent then
            cachedPointsLabel = findPointsLabel()
        end
        task.wait(5)
    end
end)

-- ==== GUI ====
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "NexusEggFarm"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local okGui = pcall(function() screenGui.Parent = CoreGui end)
if not okGui then screenGui.Parent = player:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Size             = UDim2.new(0, 180, 0, 140)
mainFrame.Position         = UDim2.new(0.5, -90, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
mainFrame.BorderSizePixel  = 0
mainFrame.Active           = true
mainFrame.Draggable        = true
mainFrame.Parent           = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local border = Instance.new("UIStroke", mainFrame)
border.Thickness = 1.5
border.Color     = Color3.fromRGB(70, 70, 70)

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size             = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.BorderSizePixel  = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleFix = Instance.new("Frame", titleBar)
titleFix.Size             = UDim2.new(1, 0, 0, 12)
titleFix.Position         = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleFix.BorderSizePixel  = 0

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size                   = UDim2.new(1, -35, 1, 0)
titleLbl.Position               = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                   = "Nexus Egg Farm"
titleLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextSize               = 13
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size             = UDim2.new(0, 24, 0, 24)
minBtn.Position         = UDim2.new(1, -28, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minBtn.Text             = "−"
minBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
minBtn.TextSize         = 16
minBtn.Font             = Enum.Font.GothamBold
minBtn.BorderSizePixel  = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local content = Instance.new("Frame", mainFrame)
content.Name                   = "Content"
content.Size                   = UDim2.new(1, -16, 1, -40)
content.Position               = UDim2.new(0, 8, 0, 36)
content.BackgroundTransparency = 1

local statusLabel = Instance.new("TextLabel", content)
statusLabel.Size                   = UDim2.new(1, 0, 0, 16)
statusLabel.Position               = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text                   = "● Idle"
statusLabel.TextColor3             = Color3.fromRGB(140, 140, 140)
statusLabel.Font                   = Enum.Font.Gotham
statusLabel.TextSize               = 11
statusLabel.TextXAlignment         = Enum.TextXAlignment.Left

local countLabel = Instance.new("TextLabel", content)
countLabel.Size                   = UDim2.new(1, 0, 0, 16)
countLabel.Position               = UDim2.new(0, 0, 0, 18)
countLabel.BackgroundTransparency = 1
countLabel.Text                   = "Collected: 0"
countLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
countLabel.Font                   = Enum.Font.Gotham
countLabel.TextSize               = 11
countLabel.TextXAlignment         = Enum.TextXAlignment.Left

local lastLabel = Instance.new("TextLabel", content)
lastLabel.Size                   = UDim2.new(1, 0, 0, 16)
lastLabel.Position               = UDim2.new(0, 0, 0, 36)
lastLabel.BackgroundTransparency = 1
lastLabel.Text                   = "Last: —"
lastLabel.TextColor3             = Color3.fromRGB(130, 130, 130)
lastLabel.Font                   = Enum.Font.Gotham
lastLabel.TextSize               = 10
lastLabel.TextXAlignment         = Enum.TextXAlignment.Left
lastLabel.TextTruncate           = Enum.TextTruncate.AtEnd

local actionBtn = Instance.new("TextButton", content)
actionBtn.Size            = UDim2.new(1, 0, 0, 36)
actionBtn.Position        = UDim2.new(0, 0, 1, -38)
actionBtn.Font            = Enum.Font.GothamBold
actionBtn.TextSize        = 14
actionBtn.BorderSizePixel = 0
Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 8)

local function updateVisuals()
    if isFarming then
        actionBtn.Text             = "STOP"
        actionBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        actionBtn.TextColor3       = Color3.fromRGB(20, 20, 20)
        border.Color               = Color3.fromRGB(200, 200, 200)
        statusLabel.Text           = "● Farming"
        statusLabel.TextColor3     = Color3.fromRGB(220, 220, 220)
    else
        actionBtn.Text             = "START"
        actionBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        actionBtn.TextColor3       = Color3.fromRGB(220, 220, 220)
        border.Color               = Color3.fromRGB(70, 70, 70)
        statusLabel.Text           = "● Idle"
        statusLabel.TextColor3     = Color3.fromRGB(140, 140, 140)
    end
end

actionBtn.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    updateVisuals()
    if not isFarming then
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end)

minBtn.MouseButton1Click:Connect(function()
    if content.Visible then
        content.Visible = false
        mainFrame.Size  = UDim2.new(0, 180, 0, 32)
        minBtn.Text     = "+"
    else
        content.Visible = true
        mainFrame.Size  = UDim2.new(0, 180, 0, 140)
        minBtn.Text     = "−"
    end
end)

task.spawn(function()
    while screenGui.Parent do
        countLabel.Text = "Collected: " .. totalCollected
        task.wait(1)
    end
end)

-- ==== ПРИОРИТЕТЫ ЯИЦ ====
local targetPriorities = {
    ["andromeda_egg"]       = 100, ["angelic_egg"]         = 100,
    ["blooming_egg"]        = 100, ["dreamer_egg"]         = 100,
    ["egg_v2"]              = 100, ["forest_egg"]          = 100,
    ["hatch_egg"]           = 100, ["royal_egg"]           = 100,
    ["the_egg_of_the_sky"]  = 100, ["placeholder_egg"]     = 100,
    ["random_potion_egg_2"] = 52,  ["random_potion_egg_1"] = 51,
--    ["point_egg_"]         = 16,  ["point_egg_"]         = 15,
--    ["point_egg_"]         = 14,  ["point_egg_"]         = 13,
--    ["point_egg_"]         = 12,  ["point_egg_"]         = 11
}

local function sendFarmWebhook(eggName, isSuccess, pointsValue)
    task.spawn(function()
        local reqFunc = getRequestFunc()
        if not reqFunc or FARM_WEBHOOK_URL == "" then return end
        local ok, err = pcall(function()
            local priority      = targetPriorities[eggName] or 0
            local isPriority100 = (priority == 100)
            local prettyName    = eggName:gsub("_", " "):gsub("(%a)([%w]*)", function(a, b) return a:upper() .. b end)
            local rarityTag     = "Common"
            local embedColor    = 8421504
            if priority == 100 then rarityTag = "LEGENDARY"; embedColor = 16766720
            elseif priority >= 50 then rarityTag = "Epic"; embedColor = 10494192
            elseif priority >= 14 then rarityTag = "Rare"; embedColor = 3447003
            elseif priority >= 11 then rarityTag = "Common"; embedColor = 8421504
            end
            if not isSuccess then embedColor = 16711680 end
            local fields = {
                {["name"] = "Egg",             ["value"] = prettyName,                                       ["inline"] = true},
                {["name"] = "Rarity",          ["value"] = rarityTag,                                        ["inline"] = true},
                {["name"] = "Priority",        ["value"] = tostring(priority),                               ["inline"] = true},
                {["name"] = "Total Collected", ["value"] = tostring(totalCollected),                         ["inline"] = true},
                {["name"] = "Points",          ["value"] = pointsValue or "N/A",                             ["inline"] = true},
                {["name"] = "Player",          ["value"] = player.Name .. " (" .. player.DisplayName .. ")", ["inline"] = true}
            }
            local embedTitle
            if isPriority100 then embedTitle = "LEGENDARY EGG COLLECTED!"
            elseif isSuccess  then embedTitle = "Egg Collected"
            else                   embedTitle = "Collection Failed"
            end
            local body = {
                ["embeds"] = {{
                    ["title"]       = embedTitle,
                    ["description"] = isSuccess
                        and ("**" .. prettyName .. "** has been collected!")
                        or  ("Failed to collect **" .. prettyName .. "**"),
                    ["color"]     = embedColor,
                    ["fields"]    = fields,
                    ["footer"]    = {["text"] = "Nexus Egg Farm | " .. os.date("%H:%M:%S")},
                    ["timestamp"] = DateTime.now():ToIsoDate()
                }}
            }
            if isPriority100 then body["content"] = "@everyone LEGENDARY EGG!" end
            reqFunc({
                Url     = FARM_WEBHOOK_URL,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = HttpService:JSONEncode(body)
            })
        end)
        if not ok then warn("[Webhook Error]: " .. tostring(err)) end
    end)
end

-- ==== ISLAND ZONES ====
local islandZones = {
    [4] = {
        Parent = nil,
        Size   = Vector3.new(50, 20, 50),
        CFrame = CFrame.new(541.4514, 98.0000, -108.5778),
        Path   = {Vector3.new(504.7574, 97.9906, -137.8735), Vector3.new(511.1336, 98.0000, -125.9527)}
    },
    [5] = {
        Parent = nil,
        Size   = Vector3.new(40, 20, 40),
        CFrame = CFrame.new(160, 100, -680.759),
        Path   = {Vector3.new(186.326, 101.00, -675.180), Vector3.new(165.688, 100.00, -676.847)}
    },
    [6] = {
        Parent = 5,
        Size   = Vector3.new(50, 30, 50),
        CFrame = CFrame.new(119.151, 111.00, -666.513),
        Path   = {Vector3.new(143.737, 97.969, -678.703), Vector3.new(131.039, 97.981, -678.368)}
    }
}

local function checkZone(pos)
    for id, data in pairs(islandZones) do
        local lp = data.CFrame:PointToObjectSpace(pos)
        if math.abs(lp.X) <= data.Size.X / 2
        and math.abs(lp.Y) <= data.Size.Y / 2
        and math.abs(lp.Z) <= data.Size.Z / 2 then
            return id
        end
    end
    return nil
end

-- ==== RAYCAST PARAMS ====
local rayParams = RaycastParams.new()
rayParams.FilterType        = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
rayParams.IgnoreWater       = true
rayParams.FilterDescendantsInstances = {character}

player.CharacterAdded:Connect(function(nc)
    character = nc
    humanoid  = nc:WaitForChild("Humanoid")
    rootPart  = nc:WaitForChild("HumanoidRootPart")
    rayParams.FilterDescendantsInstances = {character}
end)

-- ==== DANGER ZONES ====
local function setupDangerZones()
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local function applyModifier(part)
        if part:IsA("BasePart") and not part:FindFirstChild("DangerMod") then
            local mod  = Instance.new("PathfindingModifier")
            mod.Name   = "DangerMod"
            mod.Label  = "DangerZone"
            mod.Parent = part
        end
    end
    local miscs = map:FindFirstChild("Miscs")
    if miscs then
        local wb = miscs:FindFirstChild("WaterBlocks")
        if wb then
            for _, block in ipairs(wb:GetChildren()) do
                if block.Name == "WaterBlock" then applyModifier(block) end
            end
        end
    end
    local lava = map:FindFirstChild("lava")
    if lava then
        for _, part in ipairs(lava:GetDescendants()) do applyModifier(part) end
    end
end
setupDangerZones()

-- ==========================================
-- СИСТЕМА ОБНАРУЖЕНИЯ ЯИЦ
-- Яйцо может быть как Model так и BasePart
-- ==========================================
local function findEggAncestor(obj)
    local current = obj
    while current and current ~= workspace do
        if targetPriorities[current.Name] then return current end
        current = current.Parent
    end
    return nil
end

local function tryRegisterEgg(eggModel)
    if not eggModel or not eggModel.Parent then return false end
    if not targetPriorities[eggModel.Name] then return false end
    if activeEggs[eggModel] then return true end

    -- Яйцо само является BasePart
    if eggModel:IsA("BasePart") then
        activeEggs[eggModel] = eggModel
        pendingEggs[eggModel] = nil
        return true
    end

    -- Яйцо является Model/Folder — ищем BasePart внутри
    local p = eggModel:FindFirstChildWhichIsA("BasePart", true)
    if p then
        activeEggs[eggModel] = p
        pendingEggs[eggModel] = nil
        return true
    end

    return false
end

local function scheduleEggWatch(eggModel)
    if not eggModel or not targetPriorities[eggModel.Name] then return end
    if activeEggs[eggModel] or pendingEggs[eggModel] then return end
    pendingEggs[eggModel] = true
    task.spawn(function()
        for _, delay in ipairs({0.1, 0.3, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0}) do
            task.wait(delay)
            if not eggModel or not eggModel.Parent then
                pendingEggs[eggModel] = nil
                return
            end
            if tryRegisterEgg(eggModel) then return end
        end

        if eggModel and eggModel.Parent and not activeEggs[eggModel] then
            local conn
            conn = eggModel.DescendantAdded:Connect(function(desc)
                if desc:IsA("BasePart") then
                    if tryRegisterEgg(eggModel) then
                        if conn and conn.Connected then conn:Disconnect() end
                    end
                end
            end)
            task.delay(60, function()
                if conn and conn.Connected then conn:Disconnect() end
                pendingEggs[eggModel] = nil
            end)
            task.wait(0.1)
            if tryRegisterEgg(eggModel) then
                if conn and conn.Connected then conn:Disconnect() end
            end
        else
            pendingEggs[eggModel] = nil
        end
    end)
end

local function checkAndAddEgg(obj)
    if not obj or not obj.Parent then return end

    -- Объект сам является яйцом (любого типа)
    if targetPriorities[obj.Name] then
        if not tryRegisterEgg(obj) then
            scheduleEggWatch(obj)
        end
        return
    end

    -- Объект является дочерним BasePart яйца-модели
    if obj:IsA("BasePart") then
        local anc = findEggAncestor(obj)
        if anc then tryRegisterEgg(anc) end
    end

    -- Объект является контейнером внутри яйца
    if obj:IsA("Model") or obj:IsA("Folder") then
        local anc = findEggAncestor(obj)
        if anc and anc ~= obj then
            tryRegisterEgg(anc)
        end
    end
end

local function scanWorkspace()
    setupDangerZones()
    local descendants = workspace:GetDescendants()
    for i, o in ipairs(descendants) do
        if targetPriorities[o.Name] then
            if not tryRegisterEgg(o) then scheduleEggWatch(o) end
        end
        if i % 200 == 0 then task.wait() end
    end
end
scanWorkspace()

workspace.DescendantAdded:Connect(function(obj)
    task.defer(function() checkAndAddEgg(obj) end)
end)

workspace.DescendantRemoving:Connect(function(o)
    activeEggs[o]  = nil
    tempSkips[o]   = nil
    pendingEggs[o] = nil
    local anc = findEggAncestor(o)
    if anc then
        local stillHasPart = anc:FindFirstChildWhichIsA("BasePart", true)
        if not stillHasPart and not anc:IsA("BasePart") then
            activeEggs[anc] = nil
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(ForcedScanInterval)
        if isFarming then scanWorkspace() end
    end
end)

-- ==== ВЫБОР ЛУЧШЕГО ЯЙЦА ====
local function getBestEgg()
    local bestO, bestP, bestPr, minDist = nil, nil, -1, math.huge
    local rPos = rootPart.Position

    for o, p in pairs(activeEggs) do
        if not tempSkips[o] then
            local validP = nil

            -- Случай 1: яйцо само является BasePart
            if o:IsA("BasePart") then
                if o.Parent and o.Transparency < 1 then
                    validP = o
                    activeEggs[o] = o
                else
                    activeEggs[o] = nil
                end
            -- Случай 2: яйцо является Model/Folder, p — его дочерний BasePart
            else
                if p and p.Parent and p.Transparency < 1 then
                    validP = p
                elseif o and o.Parent then
                    local newP = o:FindFirstChildWhichIsA("BasePart", true)
                    if newP and newP.Transparency < 1 then
                        activeEggs[o] = newP
                        validP = newP
                    else
                        activeEggs[o] = nil
                    end
                else
                    activeEggs[o] = nil
                end
            end

            if validP then
                local pr = targetPriorities[o.Name] or 0
                local d  = (rPos - validP.Position).Magnitude
                if pr > bestPr or (pr == bestPr and d < minDist) then
                    bestO, bestP, bestPr, minDist = o, validP, pr, d
                end
            end
        end
    end

    return bestO, bestP
end

-- ==========================================
-- FLY SYSTEM
-- ==========================================
local function setupFly()
    local att = rootPart:FindFirstChild("FlyAtt") or Instance.new("Attachment", rootPart)
    att.Name = "FlyAtt"
    local ap = rootPart:FindFirstChild("FlyPos") or Instance.new("AlignPosition", rootPart)
    ap.Name, ap.Mode, ap.Attachment0, ap.MaxForce, ap.Responsiveness =
        "FlyPos", Enum.PositionAlignmentMode.OneAttachment, att, 9999999, 80
    ap.Enabled = false
    local ao = rootPart:FindFirstChild("FlyOri") or Instance.new("AlignOrientation", rootPart)
    ao.Name, ao.Mode, ao.Attachment0, ao.MaxTorque, ao.Responsiveness =
        "FlyOri", Enum.OrientationAlignmentMode.OneAttachment, att, 9999999, 80
    ao.Enabled = false
    return ap, ao
end

local function flyTo(targetPos, isJump, maxTime)
    if not humanoid or humanoid.Health <= 0 then return false end
    local ap, ao = setupFly()
    humanoid.PlatformStand = true
    ap.Enabled, ao.Enabled = true, true
    ap.MaxVelocity = humanoid.WalkSpeed
    local hOff = (humanoid.RigType == Enum.HumanoidRigType.R15)
        and (humanoid.HipHeight + rootPart.Size.Y / 2) or 3
    local bY = targetPos.Y + hOff
    local reached, stuckT, lastP, startT = false, 0, rootPart.Position, tick()
    local stuckAttempts = 0
    local hover = RunService.Heartbeat:Connect(function()
        if not isFarming or humanoid.Health <= 0 then return end
        local cPos = rootPart.Position
        local tX, tZ = targetPos.X, targetPos.Z
        local dx, dz = tX - cPos.X, tZ - cPos.Z
        local flatDist   = math.sqrt(dx*dx + dz*dz)
        local heightDiff = bY - cPos.Y
        local mDir = Vector3.zero
        if flatDist > 0.3 then mDir = Vector3.new(dx, 0, dz).Unit end
        local hasObstacleAhead = false
        if mDir ~= Vector3.zero then
            local hitMid  = workspace:Raycast(cPos, mDir * 4, rayParams)
            local hitFeet = workspace:Raycast(cPos - Vector3.new(0, 2.5, 0), mDir * 4, rayParams)
            hasObstacleAhead = (hitMid ~= nil) or (hitFeet ~= nil)
        end
        if heightDiff > 2 then
            if hasObstacleAhead then ap.Position = Vector3.new(cPos.X, cPos.Y + 12, cPos.Z); return end
            ap.Position = Vector3.new(tX, bY + 1.5, tZ); return
        end
        if heightDiff < -2 then
            if flatDist < 4 then
                local blockBelow = workspace:Raycast(cPos, Vector3.new(0, -3, 0), rayParams)
                if blockBelow and (cPos.Y - blockBelow.Position.Y) < 2.5 then
                    local nudge = mDir * 5
                    if nudge.Magnitude < 0.1 then nudge = rootPart.CFrame.RightVector * 4 end
                    ap.Position = cPos + nudge + Vector3.new(0, -1, 0)
                else
                    ap.Position = Vector3.new(tX, bY, tZ)
                end
                return
            end
            if hasObstacleAhead then
                if heightDiff < -10 then
                    ap.Position = cPos + rootPart.CFrame.RightVector * 5 + Vector3.new(0, -2, 0)
                else
                    ap.Position = Vector3.new(cPos.X, cPos.Y + 6, cPos.Z)
                end
                return
            end
            ap.Position = Vector3.new(tX, bY, tZ); return
        end
        if hasObstacleAhead then ap.Position = Vector3.new(cPos.X, cPos.Y + 10, cPos.Z); return end
        ap.Position = Vector3.new(tX, bY, tZ)
    end)
    while not reached and isFarming and humanoid and humanoid.Health > 0 do
        if maxTime and (tick() - startT) >= maxTime then break end
        task.wait()
        ao.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z))
        local cPos = rootPart.Position
        local flatD = math.sqrt((cPos.X-targetPos.X)^2 + (cPos.Z-targetPos.Z)^2)
        if flatD < 3 and math.abs(cPos.Y - bY) < 5 then reached = true; break end
        local moved = (cPos - lastP).Magnitude
        if moved < 0.12 then
            stuckT = stuckT + task.wait()
            if stuckT > 1.5 then
                stuckAttempts += 1
                stuckT = 0
                if stuckAttempts >= 4 then break end
                local hDiff = bY - cPos.Y
                if hDiff < -3 then
                    local sd = rootPart.CFrame.RightVector * (stuckAttempts % 2 == 0 and 7 or -7)
                    ap.Position = cPos + sd + Vector3.new(0, -4, 0)
                elseif hDiff > 3 then
                    ap.Position = cPos - rootPart.CFrame.LookVector * 5 + Vector3.new(0, 10, 0)
                else
                    ap.Position = cPos - rootPart.CFrame.LookVector * 6 + Vector3.new(0, 3, 0)
                end
                task.wait(0.6)
            end
        else
            stuckT = 0
        end
        lastP = cPos
    end
    hover:Disconnect()
    ap.Enabled, ao.Enabled = false, false
    return reached
end

-- ==========================================
-- FLY DIRECT TO EGG
-- ==========================================
local function flyDirectToEgg(targetPos, checkPart, huntStart, maxTime)
    maxTime = maxTime or 45

    local FLY_SPEED = 40
    local STEP_TIME = 0.3

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent   = rootPart

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.P         = 15000
    bg.CFrame    = rootPart.CFrame
    bg.Parent    = rootPart

    humanoid.PlatformStand = true
    rootPart.Anchored      = false

    local CHECK_DIST   = 6
    local SIDE_DIST    = 5
    local RISE_AMOUNT  = 18
    local RISE_TIMEOUT = 2.5
    local SIDE_TIMEOUT = 2.0

    local state      = "direct"
    local stateStart = tick()
    local sideDir    = nil

    local stuckTimer = 0
    local lastPos    = rootPart.Position
    local reached    = false
    local startT     = tick()
    local moveTimer  = 0
    local isMoving   = true

    local function checkObs(origin, dir, dist)
        return workspace:Raycast(origin, dir * dist, rayParams) ~= nil
    end

    -- Получаем позицию цели (учитываем что checkPart может быть == obj если яйцо это Part)
    local function getTargetPos()
        if checkPart and checkPart.Parent then
            return checkPart.Position
        end
        return targetPos
    end

    local conn = RunService.Heartbeat:Connect(function(dt)
        if not isFarming or humanoid.Health <= 0 then return end
        if checkPart and (not checkPart.Parent or checkPart.Transparency >= 1) then return end

        local cPos = rootPart.Position
        local tPos = getTargetPos()

        local dx = tPos.X - cPos.X
        local dy = tPos.Y - cPos.Y
        local dz = tPos.Z - cPos.Z
        local fullDist = math.sqrt(dx*dx + dy*dy + dz*dz)
        local flatDist = math.sqrt(dx*dx + dz*dz)

        local toTarget3D = (fullDist > 0.1)
            and Vector3.new(dx, dy, dz).Unit
            or  Vector3.new(0, 0, 0)

        local toTargetFlat = (flatDist > 0.1)
            and Vector3.new(dx, 0, dz).Unit
            or  Vector3.new(0, 0, 0)

        local obsForward = false
        local obsUp      = false
        local obsRight   = false
        local obsLeft    = false

        if toTargetFlat.Magnitude > 0.1 then
            obsForward = checkObs(cPos + Vector3.new(0, -2.5, 0), toTargetFlat, CHECK_DIST)
                      or checkObs(cPos,                            toTargetFlat, CHECK_DIST)
                      or checkObs(cPos + Vector3.new(0,  2.5, 0), toTargetFlat, CHECK_DIST)
            obsUp      = checkObs(cPos, Vector3.new(0, 1, 0), RISE_AMOUNT + 2)
            local rightVec = Vector3.new(toTargetFlat.Z, 0, -toTargetFlat.X)
            obsRight = checkObs(cPos,  rightVec, SIDE_DIST)
            obsLeft  = checkObs(cPos, -rightVec, SIDE_DIST)
        end

        local elapsed = tick() - stateStart
        local flyDir  = Vector3.new(0, 0, 0)

        if state == "direct" then
            if obsForward then
                if not obsUp then
                    state = "rising"
                elseif not obsRight then
                    state   = "siding"
                    sideDir = Vector3.new(toTargetFlat.Z, 0, -toTargetFlat.X)
                elseif not obsLeft then
                    state   = "siding"
                    sideDir = Vector3.new(-toTargetFlat.Z, 0, toTargetFlat.X)
                else
                    state = "backing"
                end
                stateStart = tick()
            else
                flyDir = toTarget3D
            end

        elseif state == "rising" then
            local clearAhead = not checkObs(cPos + Vector3.new(0, -2.5, 0), toTargetFlat, CHECK_DIST)
                           and not checkObs(cPos,                            toTargetFlat, CHECK_DIST)
                           and not checkObs(cPos + Vector3.new(0,  2.5, 0), toTargetFlat, CHECK_DIST)
            if clearAhead or elapsed > RISE_TIMEOUT then
                state = "direct"
                stateStart = tick()
                flyDir = toTarget3D
            else
                flyDir = Vector3.new(0, 1, 0)
            end

        elseif state == "siding" then
            local clearAhead = not checkObs(cPos + Vector3.new(0, -2.5, 0), toTargetFlat, CHECK_DIST)
                           and not checkObs(cPos,                            toTargetFlat, CHECK_DIST)
            if clearAhead or elapsed > SIDE_TIMEOUT then
                state   = "direct"
                sideDir = nil
                stateStart = tick()
                flyDir = toTarget3D
            else
                local md = sideDir + toTargetFlat * 0.4
                md = Vector3.new(md.X, 0, md.Z)
                if md.Magnitude > 0 then md = md.Unit end
                flyDir = (md + Vector3.new(0, 0.2, 0)).Unit
            end

        elseif state == "backing" then
            if elapsed > 1.5 then
                state = "direct"
                stateStart = tick()
                flyDir = toTarget3D
            else
                flyDir = (-toTargetFlat + Vector3.new(0, 0.5, 0)).Unit
            end
        end

        moveTimer = moveTimer + dt
        if isMoving then
            rootPart.Anchored = false
            if flyDir.Magnitude > 0.01 then
                bv.Velocity = flyDir * FLY_SPEED
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end
            if toTargetFlat.Magnitude > 0.1 then
                bg.CFrame = CFrame.lookAt(cPos, cPos + toTargetFlat)
            end
            if moveTimer >= STEP_TIME then
                moveTimer = 0
                isMoving  = false
                bv.Velocity = Vector3.new(0, 0, 0)
            end
        else
            rootPart.Anchored = true
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            if moveTimer >= STEP_TIME then
                moveTimer = 0
                isMoving  = true
                rootPart.Anchored = false
            end
        end
    end)

    while isFarming and humanoid and humanoid.Health > 0 do
        if tick() - startT >= maxTime then break end
        if checkPart and (not checkPart.Parent or checkPart.Transparency >= 1) then break end

        task.wait()

        local cPos = rootPart.Position
        local tPos = getTargetPos()

        local moved = (cPos - lastPos).Magnitude
        if moved < 0.05 then
            stuckTimer = stuckTimer + 1
            if stuckTimer > 80 then
                stuckTimer = 0
                state      = "backing"
                stateStart = tick()
            end
        else
            stuckTimer = 0
        end
        lastPos = cPos

        local flatDist = math.sqrt((cPos.X-tPos.X)^2 + (cPos.Z-tPos.Z)^2)
        local vertDist = math.abs(cPos.Y - tPos.Y)
        if flatDist < 5 and vertDist < 8 then
            reached = true
            break
        end
    end

    conn:Disconnect()
    if bv and bv.Parent then bv:Destroy() end
    if bg and bg.Parent then bg:Destroy() end
    rootPart.Anchored      = false
    humanoid.PlatformStand = false
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

    return reached
end

-- ==========================================
-- PATHFINDING
-- ==========================================
local function getChainTo(targetId)
    local chain = {}
    local curr  = targetId
    while curr do
        table.insert(chain, 1, curr)
        curr = islandZones[curr].Parent
    end
    return chain
end

local function smartPath(targetPos, checkPart, huntStart)
    local path = PathfindingService:CreatePath({
        AgentRadius     = 3,
        AgentHeight     = 5,
        AgentCanJump    = true,
        WaypointSpacing = 3,
        Costs = {Water = math.huge, DangerZone = math.huge, ClimbPlatform = 0.1}
    })
    local success, _ = pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end)
    if not success or path.Status ~= Enum.PathStatus.Success then return "NoPath" end
    local wps = path:GetWaypoints()
    for i = 2, #wps do
        if not isFarming or humanoid.Health <= 0 then return "Failed" end
        if huntStart and tick() - huntStart > 60 then return "Timeout" end
        if checkPart and (not checkPart.Parent or checkPart.Transparency == 1) then return "Failed" end
        local cPos = rootPart.Position
        if (cPos - targetPos).Magnitude < 8 then return "Reached" end
        if not flyTo(wps[i].Position, wps[i].Action == Enum.PathWaypointAction.Jump, 4) then
            local cY = rootPart.Position.Y
            local tY = wps[i].Position.Y
            if cY > tY + 5 then
                flyTo(rootPart.Position + rootPart.CFrame.RightVector * 6 + Vector3.new(0, -3, 0), false, 1)
            elseif cY < tY - 5 then
                flyTo(rootPart.Position - rootPart.CFrame.LookVector * 5 + Vector3.new(0, 8, 0), false, 1)
            else
                flyTo(rootPart.Position - rootPart.CFrame.LookVector * 5, false, 0.5)
            end
            return "Stuck"
        end
    end
    return "Reached"
end

-- ==========================================
-- ВЗАИМОДЕЙСТВИЕ С ЯЙЦОМ
-- ==========================================
local function getEggPosition(obj, p)
    -- Если яйцо само является Part — используем его позицию напрямую
    if obj:IsA("BasePart") then
        return obj.Parent and obj.Position or nil
    end
    -- Иначе используем найденный BasePart
    if p and p.Parent then
        return p.Position
    end
    -- Последняя попытка
    local bp = obj:FindFirstChildWhichIsA("BasePart", true)
    return bp and bp.Position or nil
end

local function isEggGone(obj, p)
    -- Если яйцо само является Part
    if obj:IsA("BasePart") then
        return not obj.Parent or obj.Transparency >= 1
    end
    -- Если яйцо Model/Folder
    return not obj.Parent
        or not p
        or not p.Parent
        or p.Transparency >= 1
end

local function clickUntilGone(obj, p, maxWait)
    maxWait = maxWait or 10
    local startT = tick()
    local pr = nil
    if obj then pr = obj:FindFirstChildWhichIsA("ProximityPrompt", true) end
    if not pr and p and p ~= obj then pr = p:FindFirstChildWhichIsA("ProximityPrompt", true) end
    while true do
        if isEggGone(obj, p) then break end
        if tick() - startT > maxWait then break end
        if pr and pr.Parent then
            if fireproximityprompt then
                pcall(function() fireproximityprompt(pr, 1) end)
            else
                local key = pr.KeyboardKeyCode == Enum.KeyCode.Unknown
                    and Enum.KeyCode.E or pr.KeyboardKeyCode
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, key, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, key, false, game)
                end)
            end
        else
            if obj and obj.Parent then
                pr = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
            if not pr and p and p.Parent and p ~= obj then
                pr = p:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
        end
        task.wait(0.1)
    end
end

-- ==========================================
-- ГЛАВНЫЙ ОХОТНИК
-- ==========================================
local function huntTarget(obj, p)
    if isEggGone(obj, p) then return end

    local eggName     = tostring(obj.Name)
    local huntStart   = tick()
    local eggPos      = getEggPosition(obj, p)
    if not eggPos then return end

    local tarZone     = checkZone(eggPos)
    local isEarlyExit = false
    local startZone   = checkZone(rootPart.Position)

    if typeof(tarZone) == "number" and startZone ~= tarZone then
        local chain = getChainTo(tarZone)
        for _, zoneId in ipairs(chain) do
            if not isEarlyExit and checkZone(rootPart.Position) ~= zoneId then
                local data = islandZones[zoneId]
                local dPos = data.Path[1]
                if (rootPart.Position - dPos).Magnitude > 15 then
                    local res = smartPath(dPos, p, huntStart)
                    if res == "NoPath" then
                        print("[Farm]: NoPath к zone entry → FLY напрямую")
                        flyDirectToEgg(dPos, nil, huntStart, 30)
                    elseif res == "Timeout" then
                        isEarlyExit = true
                    end
                end
                if not isEarlyExit then
                    for i = 1, #data.Path do
                        if not isFarming or humanoid.Health <= 0 or (tick() - huntStart > 60) then
                            isEarlyExit = true; break
                        end
                        flyTo(data.Path[i], false, 6)
                    end
                end
            end
        end
    end

    if not isEarlyExit then
        while not isEggGone(obj, p) do
            if not isFarming or humanoid.Health <= 0 then break end
            if tick() - huntStart > 60 then tempSkips[obj] = true; break end

            -- Обновляем позицию яйца (она может меняться)
            eggPos = getEggPosition(obj, p)
            if not eggPos then break end

            local cPos = rootPart.Position
            local dist = (cPos - eggPos).Magnitude

            if dist < 8 then
                humanoid.PlatformStand = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.wait(0.1)
                clickUntilGone(obj, p, 10)

                -- Проверяем что яйцо исчезло (собрали)
                if isEggGone(obj, p) then
                    totalCollected = totalCollected + 1
                    local pointsNow  = getPointsText()
                    local prettyName = eggName:gsub("_", " "):gsub("(%a)([%w]*)", function(a, b) return a:upper() .. b end)
                    lastLabel.Text   = "Last: " .. prettyName
                    countLabel.Text  = "Collected: " .. totalCollected
                    sendFarmWebhook(eggName, true, pointsNow)
                    tempSkips = {}
                end
                break
            end

            local status = smartPath(eggPos, p, huntStart)

            if status == "NoPath" then
                print("[Farm]: NoPath → FLY напрямую к " .. eggName)
                local flyReached = flyDirectToEgg(eggPos, p, huntStart, 45)
                if not flyReached then
                    tempSkips[obj] = true
                    break
                end
            elseif status == "Timeout" or status == "Failed" then
                tempSkips[obj] = true; break
            end
        end
    end

    -- Возврат с острова
    local myZone = checkZone(rootPart.Position)
    while typeof(myZone) == "number" do
        local data = islandZones[myZone]
        for i = #data.Path, 1, -1 do
            if not isFarming or humanoid.Health <= 0 then break end
            flyTo(data.Path[i], false, 6)
        end
        myZone = data.Parent
    end

    activeEggs[obj] = nil
end

-- ==========================================
-- ГЛАВНЫЙ ЦИКЛ ФАРМА
-- ==========================================
task.spawn(function()
    while true do
        if isFarming and humanoid and humanoid.Health > 0 then
            local o, p = getBestEgg()
            if o and p then
                huntTarget(o, p)
            else
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
        task.wait(0.05)
    end
end)

-- ==========================================
-- ГОРЯЧАЯ КЛАВИША P
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        isFarming = not isFarming
        updateVisuals()
        if not isFarming then
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

updateVisuals()
