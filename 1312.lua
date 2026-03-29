-- ==========================================
-- УЛЬТРА-ОПТИМИЗИРОВАННЫЙ EGG FARM
-- (GUI, ТОЧКИ ЗОН, АНТИ-КАМЕНЬ, Г-ВЗБИРАНИЕ, LEGIT SPEED)
-- ==========================================
local AutoStart = false 
local ForcedScanInterval = 10 
-- ==========================================

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ==== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ====
local isFarming = AutoStart
local activeEggs = {}
local blacklist = {} -- Только для хард-зоны
local tempSkips = {} -- Временный скип забаганных яиц

-- ==== GUI ====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileFarmGui"
screenGui.ResetOnSpawn = false
local successGui, _ = pcall(function() screenGui.Parent = CoreGui end)
if not successGui then screenGui.Parent = player:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 160, 0, 100)
mainFrame.Position = UDim2.new(0.5, -80, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true 
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(0, 255, 150)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "EGG MASTER PRO"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local actionBtn = Instance.new("TextButton", mainFrame)
actionBtn.Size = UDim2.new(0, 130, 0, 45)
actionBtn.Position = UDim2.new(0.5, -65, 0.45, 0)
actionBtn.Font = Enum.Font.GothamBold
actionBtn.TextSize = 16
Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 10)

local minBtn = Instance.new("TextButton", mainFrame)
minBtn.Size = UDim2.new(0, 25, 0, 25)
minBtn.Position = UDim2.new(1, -30, 0, 5)
minBtn.BackgroundTransparency = 1
minBtn.Text = "-"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.TextSize = 20

local function updateVisuals()
    if isFarming then
        actionBtn.Text = "STOP FARM"
        actionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        stroke.Color = Color3.fromRGB(255, 50, 50)
    else
        actionBtn.Text = "START FARM"
        actionBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        stroke.Color = Color3.fromRGB(0, 255, 150)
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
    if actionBtn.Visible then
        mainFrame:TweenSize(UDim2.new(0, 160, 0, 35), "Out", "Quad", 0.3, true)
        actionBtn.Visible = false
        minBtn.Text = "+"
    else
        mainFrame:TweenSize(UDim2.new(0, 160, 0, 100), "Out", "Quad", 0.3, true)
        actionBtn.Visible = true
        minBtn.Text = "-"
    end
end)

-- ==== ВЕБХУК ====
local WebhookURL = "https://discord.com/api/webhooks/1487809809561555127/dgpdUBqGId8AXEVMn0EO1eUvyCxvjO1rEkIO5c2pdcF1vcmzkI0YQmP3Paa1owLHzsgt"
local requestFunc = syn and syn.request or http_request or request

local function sendWebhook(eggName, isSuccess)
    if not requestFunc or WebhookURL == "" then return end
    task.spawn(function()
        pcall(function()
            requestFunc({
                Url = WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    ["embeds"] = {{
                        ["title"] = isSuccess and "✅ Egg Collected!" or "❌ Action Failed",
                        ["description"] = "Egg: " .. tostring(eggName),
                        ["color"] = isSuccess and 65280 or 16711680,
                        ["timestamp"] = DateTime.now():ToIsoDate(),
                        ["footer"] = {["text"] = "User: " .. player.Name}
                    }}
                })
            })
        end)
    end)
end

-- ==== ЗОНЫ ====
local blacklistZone1 = { Size = Vector3.new(150, 90, 150), CFrame = CFrame.new(-28.1648, 128.4687, -123.9840) }
local islandZones = {
    [2] = { Parent = nil, Size = Vector3.new(60, 30, 60), CFrame = CFrame.new(220.6902, 100.0900, -625.0073), Path = { Vector3.new(177.956, 93.500, -567.293), Vector3.new(180.733, 89.550, -585.324), Vector3.new(189.303, 89.532, -598.254), Vector3.new(198.556, 89.970, -606.730) }},
    [3] = { Parent = nil, Size = Vector3.new(60, 25, 60), CFrame = CFrame.new(45.2101, 99.2500, -430.0402), Path = { Vector3.new(107.523, 92.000, -422.050), Vector3.new(93.153, 91.971, -427.461), Vector3.new(83.859, 91.979, -431.765), Vector3.new(75.233, 93.984, -442.595), Vector3.new(60.534, 100.965, -441.453) }},
    [4] = { Parent = nil, Size = Vector3.new(50, 20, 50), CFrame = CFrame.new(541.4514, 98.0000, -108.5778), Path = { Vector3.new(504.7574, 97.9906, -137.8735), Vector3.new(511.1336, 98.0000, -125.9527) }},
    [5] = { Parent = 2, Size = Vector3.new(40, 20, 40), CFrame = CFrame.new(160, 100, -680.759), Path = { Vector3.new(186.326, 101.00, -675.180), Vector3.new(165.688, 100.00, -676.847) }},
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

local targetPriorities = {
    ["andromeda_egg"] = 100, ["angelic_egg"] = 100, ["blooming_egg"] = 100, ["dreamer_egg"] = 100, ["egg_v2"] = 100, 
    ["forest_egg"] = 100, ["hatch_egg"] = 100, ["royal_egg"] = 100, ["the_egg_of_the_sky"] = 100, ["placeholder_egg"] = 100, 
    ["random_potion_egg_2"] = 52, ["random_potion_egg_1"] = 51, ["point_egg_6"] = 16, ["point_egg_5"] = 15, 
    ["point_egg_4"] = 14, ["point_egg_3"] = 13, ["point_egg_2"] = 12, ["point_egg_1"] = 11
}

local rayParams = RaycastParams.new()
rayParams.FilterType, rayParams.RespectCanCollide, rayParams.IgnoreWater = Enum.RaycastFilterType.Exclude, true, true

player.CharacterAdded:Connect(function(nc) 
    character, humanoid, rootPart = nc, nc:WaitForChild("Humanoid"), nc:WaitForChild("HumanoidRootPart") 
    rayParams.FilterDescendantsInstances = {character}
end)
rayParams.FilterDescendantsInstances = {character}

-- ==== ЛОГИКА ОПРЕДЕЛЕНИЯ ЯИЦ ====
local function checkAndAddEgg(obj)
    if targetPriorities[obj.Name] and not activeEggs[obj] then
        local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
        if p then
            if checkZone(p.Position) == "BLACKLIST" then 
                blacklist[obj] = true
            else 
                activeEggs[obj] = p 
            end
        end
    end
end

local function scanWorkspace()
    local descendants = workspace:GetDescendants()
    for i, o in ipairs(descendants) do 
        checkAndAddEgg(o)
        if i % 500 == 0 then task.wait() end 
    end
end

scanWorkspace()
workspace.DescendantAdded:Connect(checkAndAddEgg)
workspace.DescendantRemoving:Connect(function(o) activeEggs[o] = nil; blacklist[o] = nil; tempSkips[o] = nil end)

task.spawn(function()
    while true do
        task.wait(ForcedScanInterval)
        if isFarming then scanWorkspace() end
    end
end)

local function getBestEgg()
    local bestO, bestP, bestPr, minDist = nil, nil, -1, math.huge
    for o, p in pairs(activeEggs) do
        if not blacklist[o] and not tempSkips[o] then 
            if p and p.Parent and p.Transparency < 1 then
                local pr = targetPriorities[o.Name] or 0
                local d = (rootPart.Position - p.Position).Magnitude
                if pr > bestPr or (pr == bestPr and d < minDist) then
                    bestO, bestP, bestPr, minDist = o, p, pr, d
                end
            end
        end
    end
    return bestO, bestP
end

-- ==== FLY SYSTEM (L-SHAPE + ANTI-ROCK) ====
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
    ap.MaxVelocity = humanoid.WalkSpeed -- Скорость легит

    local hOff = (humanoid.RigType == Enum.HumanoidRigType.R15) and (humanoid.HipHeight + rootPart.Size.Y / 2) or 3
    local bY = targetPos.Y + hOff
    local reached, stuckT, lastP, startT = false, 0, rootPart.Position, tick()

    local hover = RunService.Heartbeat:Connect(function()
        if not isFarming or humanoid.Health <= 0 then return end
        
        local cPos = rootPart.Position
        local tX, tY, tZ = targetPos.X, bY, targetPos.Z
        local flatDist = (Vector3.new(cPos.X, 0, cPos.Z) - Vector3.new(tX, 0, tZ)).Magnitude
        
        -- ВЕКТОР НАПРАВЛЕНИЯ
        local mDir = (Vector3.new(tX, 0, tZ) - Vector3.new(cPos.X, 0, cPos.Z))
        if mDir.Magnitude > 0.1 then mDir = mDir.Unit else mDir = Vector3.zero end

        -- 1. АНТИ-КАМЕНЬ (Raycast прямо перед лицом)
        if mDir ~= Vector3.zero then
            local hitObstacle = workspace:Raycast(cPos, mDir * 4, rayParams) -- Луч на 4 стада вперед
            if hitObstacle then
                -- Перед носом препятствие! Подпрыгиваем СТРОГО ВВЕРХ
                ap.Position = Vector3.new(cPos.X, cPos.Y + 15, cPos.Z)
                return
            end
        end

        -- 2. Г-ОБРАЗНОЕ ВЗБИРАНИЕ НА ПЛАТФОРМЫ
        if targetPos.Y > cPos.Y + 2 then
            -- Если подошли к стене вплотную
            if flatDist < 6 then 
                -- Поднимаемся вертикально
                if cPos.Y < targetPos.Y + hOff + 0.5 then 
                    ap.Position = Vector3.new(cPos.X, targetPos.Y + hOff + 3, cPos.Z)
                    return
                end
            end
        end
        
        -- 3. ОБЫЧНЫЙ ПОЛЕТ
        ap.Position = Vector3.new(tX, tY, tZ)
    end)

    while not reached and isFarming and humanoid and humanoid.Health > 0 do
        if maxTime and (tick() - startT) >= maxTime then break end
        task.wait()
        
        ao.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z))
        
        local currentFlatDist = (Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
        
        if currentFlatDist < 2.5 and math.abs(rootPart.Position.Y - bY) < 4 then 
            reached = true 
            break 
        end
        
        if (rootPart.Position - lastP).Magnitude < 0.1 then 
            stuckT = stuckT + task.wait()
            if stuckT > 1.5 then break end
        else 
            stuckT = 0 
        end
        lastP = rootPart.Position
    end
    
    hover:Disconnect()
    ap.Enabled, ao.Enabled = false, false
    return reached
end

-- ВОССТАНОВЛЕННАЯ ЛОГИКА ЦЕПОЧЕК (ТОЧКИ ЗОН)
local function getChainTo(targetId)
    local chain = {}
    local curr = targetId
    while curr do 
        table.insert(chain, 1, curr) 
        curr = islandZones[curr].Parent 
    end
    return chain
end

local function smartPath(targetPos, checkPart, huntStart)
    local path = PathfindingService:CreatePath({AgentRadius = 3, AgentHeight = 5, AgentCanJump = true, Costs = {Water = math.huge}})
    local success, _ = pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end)
    if not success or path.Status ~= Enum.PathStatus.Success then return "NoPath" end
    local wps = path:GetWaypoints()
    for i = 2, #wps do
        if not isFarming or humanoid.Health <= 0 then return "Failed" end
        if huntStart and tick() - huntStart > 60 then return "Timeout" end
        if checkPart and (not checkPart.Parent or checkPart.Transparency == 1) then return "Failed" end
        if (rootPart.Position - targetPos).Magnitude < 8 then return "Reached" end
        if not flyTo(wps[i].Position, wps[i].Action == Enum.PathWaypointAction.Jump, 3) then 
             flyTo(rootPart.Position + (-rootPart.CFrame.LookVector * 5), false, 0.5)
             return "Stuck" 
        end
    end
    return "Reached"
end

local function interactWithPrompt(obj)
    local pr = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
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
    end
end

local function huntTarget(obj, p)
    if not p or not p.Parent then return end
    local eggName, huntStart, tarZone, isEarlyExit = tostring(obj.Name), tick(), checkZone(p.Position), false
    local startZone = checkZone(rootPart.Position)
    
    -- БЕГ ПО ТВОИМ ТОЧКАМ (ИЗ ЗОНЫ В ЗОНУ)
    if typeof(tarZone) == "number" and startZone ~= tarZone then
        local chain = getChainTo(tarZone)
        for _, zoneId in ipairs(chain) do
            if not isEarlyExit and checkZone(rootPart.Position) ~= zoneId then
                local data = islandZones[zoneId]
                -- Подлетаем к началу пути если мы далеко
                if (rootPart.Position - data.Path[1]).Magnitude > 15 then
                    local res = smartPath(data.Path[1], p, huntStart)
                    if res == "Timeout" or res == "NoPath" then isEarlyExit = true end
                end
                -- Летим по точкам
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
            
            if tick() - huntStart > 60 then 
                tempSkips[obj] = true 
                break 
            end
            
            if (rootPart.Position - p.Position).Magnitude < 8 then
                humanoid.PlatformStand = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.wait(0.1)
                
                interactWithPrompt(obj)
                
                local wt = 0
                while p and p.Parent and p.Transparency < 1 and wt < 2 do task.wait(0.1) wt = wt + 0.1 end
                sendWebhook(eggName, true)
                
                tempSkips = {} -- Сбрасываем скипы
                break
            end
            
            -- Последний рывок до яйца (с анти-камнем)
            local status = smartPath(p.Position, p, huntStart)
            if status == "Timeout" or status == "NoPath" or status == "Failed" then 
                tempSkips[obj] = true 
                break 
            end
        end
    end
    
    -- ВОЗВРАТ НАЗАД ПО ТОЧКАМ
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
print("EGG MASTER PRO LOADED: GUI + WAYPOINTS + ANTI-ROCK FIX")
