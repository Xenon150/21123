-- ==========================================
-- НАСТРОЙКИ
local AutoStart = true 
local VisualiseZones = true 
-- ==========================================

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ==== WEBHOOK ====
local WebhookURL = "https://discord.com/api/webhooks/1487809809561555127/dgpdUBqGId8AXEVMn0EO1eUvyCxvjO1rEkIO5c2pdcF1vcmzkI0YQmP3Paa1owLHzsgt" -- https://discord.com/api/webhooks/1487682721944965256/tz1C65I8X7_cprV0e19VDgfHGwydM0mrsAN6n6j9Gm_cvUbs1_TMPrPsk0AOsbR0Bv8B
local requestFunc = syn and syn.request or http_request or request

local function sendWebhook(eggName, isSuccess)
    if not requestFunc or WebhookURL == "" then return end
    local colorCode = 16711680
    if isSuccess then colorCode = 65280 end
    local titleText = "Action Log"
    if isSuccess then titleText = "✅ Egg Collected!" end
    
    task.spawn(function()
        pcall(function()
            requestFunc({
                Url = WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    ["embeds"] = {{
                        ["title"] = titleText,
                        ["description"] = "Egg: " .. tostring(eggName),
                        ["color"] = colorCode,
                        ["timestamp"] = DateTime.now():ToIsoDate(),
                        ["footer"] = {["text"] = "User: " .. player.Name}
                    }}
                })
            })
        end)
    end)
end

-- ==== ZONES DATA ====
local blacklistZone1 = {
    Size = Vector3.new(150, 90, 150),
    CFrame = CFrame.new(-28.1648, 128.4687, -123.9840)
}

local islandZones = {
    [2] = { Parent = nil, Size = Vector3.new(60, 30, 60), CFrame = CFrame.new(220.6902, 100.0900, -625.0073),
        Path = { Vector3.new(177.956, 93.500, -567.293), Vector3.new(180.733, 89.550, -585.324), Vector3.new(189.303, 89.532, -598.254), Vector3.new(198.556, 89.970, -606.730) }
    },
    [3] = { Parent = nil, Size = Vector3.new(60, 25, 60), CFrame = CFrame.new(45.2101, 99.2500, -430.0402),
        Path = { Vector3.new(107.523, 92.000, -422.050), Vector3.new(93.153, 91.971, -427.461), Vector3.new(83.859, 91.979, -431.765), Vector3.new(75.233, 93.984, -442.595), Vector3.new(60.534, 100.965, -441.453) }
    },
    [4] = { Parent = nil, Size = Vector3.new(50, 20, 50), CFrame = CFrame.new(541.4514, 98.0000, -108.5778),
        Path = { Vector3.new(504.7574, 97.9906, -137.8735), Vector3.new(511.1336, 98.0000, -125.9527) }
    },
    [5] = { Parent = 2, Size = Vector3.new(40, 20, 40), CFrame = CFrame.new(160, 100, -680.759),
        Path = { Vector3.new(186.326, 101.00, -675.180), Vector3.new(165.688, 100.00, -676.847) }
    },
    [6] = { Parent = 5, Size = Vector3.new(50, 30, 50), CFrame = CFrame.new(119.151, 111.00, -666.513),
        Path = { Vector3.new(143.737, 97.969, -678.703), Vector3.new(131.039, 97.981, -678.368) }
    }
}

-- DEX Visualise
if VisualiseZones then
    local folder = workspace:FindFirstChild("FarmZones") or Instance.new("Folder", workspace)
    folder.Name = "FarmZones"
    local function createPart(n, s, cf, col)
        local p = folder:FindFirstChild(n) or Instance.new("Part", folder)
        p.Name = n
        p.Size = s
        p.CFrame = cf
        p.Anchored = true
        p.CanCollide = false
        p.Transparency = 0.8
        p.Color = col
        p.Material = Enum.Material.ForceField
    end
    createPart("Blacklist_1", blacklistZone1.Size, blacklistZone1.CFrame, Color3.new(1,0,0))
    for id, data in pairs(islandZones) do
        createPart("Zone_"..tostring(id), data.Size, data.CFrame, Color3.new(0,1,1))
    end
end

-- ==== LOGIC FUNCTIONS ====
local function checkZone(pos)
    local lp1 = blacklistZone1.CFrame:PointToObjectSpace(pos)
    if math.abs(lp1.X) <= (blacklistZone1.Size.X / 2) and math.abs(lp1.Y) <= (blacklistZone1.Size.Y / 2) and math.abs(lp1.Z) <= (blacklistZone1.Size.Z / 2) then
        return "BLACKLIST"
    end
    for id, data in pairs(islandZones) do
        local lp = data.CFrame:PointToObjectSpace(pos)
        local hX = data.Size.X / 2
        local hY = data.Size.Y / 2
        local hZ = data.Size.Z / 2
        if math.abs(lp.X) <= hX and math.abs(lp.Y) <= hY and math.abs(lp.Z) <= hZ then
            return id
        end
    end
    return nil
end

local targetPriorities = {
    ["andromeda_egg"] = 100, ["angelic_egg"] = 100, ["blooming_egg"] = 100, ["dreamer_egg"] = 100, ["egg_v2"] = 100, ["forest_egg"] = 100, ["hatch_egg"] = 100, ["royal_egg"] = 100, ["the_egg_of_the_sky"] = 100, ["placeholder_egg"] = 100, ["random_potion_egg_2"] = 52, ["random_potion_egg_1"] = 51, ["point_egg_6"] = 16, ["point_egg_5"] = 15, ["point_egg_4"] = 14, ["point_egg_3"] = 13, ["point_egg_2"] = 12, ["point_egg_1"] = 11
}

local isFarming = AutoStart
local activeEggs = {}
local blacklist = {}
local skippedEggs = {}

player.CharacterAdded:Connect(function(nc)
    character = nc
    humanoid = nc:WaitForChild("Humanoid")
    rootPart = nc:WaitForChild("HumanoidRootPart")
end)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
rayParams.IgnoreWater = true

local function checkAndAddEgg(obj)
    if targetPriorities[obj.Name] then
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

for _, o in ipairs(workspace:GetDescendants()) do checkAndAddEgg(o) end
workspace.DescendantAdded:Connect(checkAndAddEgg)
workspace.DescendantRemoving:Connect(function(o)
    activeEggs[o] = nil
    blacklist[o] = nil
    skippedEggs[o] = nil
end)

local function getBestEgg()
    local bestO = nil
    local bestP = nil
    local bestPr = -1
    local minDist = math.huge
    local now = tick()
    for o, p in pairs(activeEggs) do
        local skipTime = skippedEggs[o] or 0
        if not blacklist[o] and (now - skipTime > 15) then
            if p and p.Parent and p.Transparency < 1 then
                local pr = targetPriorities[o.Name] or 0
                local d = (rootPart.Position - p.Position).Magnitude
                if pr > bestPr or (pr == bestPr and d < minDist) then
                    bestO = o
                    bestP = p
                    bestPr = pr
                    minDist = d
                end
            end
        end
    end
    return bestO, bestP
end

-- FLY
local function setupFly()
    local att = rootPart:FindFirstChild("FlyAtt") or Instance.new("Attachment", rootPart)
    att.Name = "FlyAtt"
    local ap = rootPart:FindFirstChild("FlyPos") or Instance.new("AlignPosition", rootPart)
    ap.Name = "FlyPos"
    ap.Mode = Enum.PositionAlignmentMode.OneAttachment
    ap.Attachment0 = att
    ap.MaxForce = 9999999
    ap.Responsiveness = 80
    ap.Enabled = false
    local ao = rootPart:FindFirstChild("FlyOri") or Instance.new("AlignOrientation", rootPart)
    ao.Name = "FlyOri"
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.Attachment0 = att
    ao.MaxTorque = 9999999
    ao.Responsiveness = 80
    ao.Enabled = false
    return ap, ao
end

local function flyTo(targetPos, isJump, maxTime, checkEgg)
    if not humanoid or humanoid.Health <= 0 then return false end
    local ap, ao = setupFly()
    humanoid.PlatformStand = true
    ap.Enabled = true
    ao.Enabled = true
    ap.MaxVelocity = humanoid.WalkSpeed * 1.1
    
    local hOff = 3
    if humanoid.RigType == Enum.HumanoidRigType.R15 then
        hOff = humanoid.HipHeight + (rootPart.Size.Y / 2)
    end
    local bY = targetPos.Y + hOff
    
    local reached = false
    local stuckT = 0
    local lastP = rootPart.Position
    local startT = tick()
    local lastS = tick()
    local lastG = tick()
    
    rayParams.FilterDescendantsInstances = {character}
    
    local hover = RunService.Heartbeat:Connect(function()
        if not isFarming or humanoid.Health <= 0 then return end
        if checkEgg and (not checkEgg.Parent) then return end

        local mDir = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z))
        if mDir.Magnitude > 0.1 then mDir = mDir.Unit else mDir = Vector3.zero end
        
        local hitF = workspace:Raycast(rootPart.Position + Vector3.new(0,5,0), Vector3.new(0,-30,0), rayParams)
        if hitF and hitF.Instance.CanCollide == false then hitF = nil end

        local hitL = workspace:Raycast(rootPart.Position + Vector3.new(0,-1.5,0), mDir*3, rayParams)
        local hitH = workspace:Raycast(rootPart.Position + Vector3.new(0,1.5,0), mDir*3, rayParams)
        local hitC = workspace:Raycast(rootPart.Position, Vector3.new(0,5,0), rayParams)
        
        local tY = bY
        if hitF then 
            local fY = hitF.Position.Y + hOff
            if fY < (rootPart.Position.Y + 2) then
                if math.abs(tY - fY) < 3.5 then tY = fY else tY = math.max(tY, fY) end
            end
        end
        if hitL and not hitH and not hitC then tY = math.max(tY, hitL.Position.Y + hOff + 1)
        elseif hitL and hitH and not hitC then tY = math.max(tY, rootPart.Position.Y + 4) end
        if hitC then tY = math.min(tY, hitC.Position.Y - 2) end

        local hDist = (Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
        if hDist > 5 then
            tY = math.min(tY, rootPart.Position.Y + 1.1)
        end
        ap.Position = Vector3.new(targetPos.X, tY, targetPos.Z)
    end)

    while not reached and isFarming and humanoid and humanoid.Health > 0 do
        if checkEgg and (not checkEgg.Parent) then break end
        if maxTime and (tick() - startT >= maxTime) then break end
        task.wait()
        
        if tick() - lastG >= 0.5 then
            if rootPart.Position.Y > (bY + 15) then
                rootPart.Velocity = Vector3.new(0, -50, 0)
                ap.Position = Vector3.new(targetPos.X, bY, targetPos.Z)
            end
            lastG = tick()
        end

        ao.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z))
        local curDist = (Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
        local hRad = math.max(1.5, humanoid.WalkSpeed / 12)
        if curDist < hRad then reached = true break end
        
        if tick() - lastS >= 0.2 then
            if (rootPart.Position - lastP).Magnitude < 0.5 then 
                stuckT = stuckT + 0.2
                if stuckT > 1.0 then break end
            else
                stuckT = 0
            end
            lastP = rootPart.Position
            lastS = tick()
        end
    end
    hover:Disconnect()
    ap.Enabled = false
    ao.Enabled = false
    return reached
end

local function smartPath(targetPos, checkPart, huntStart)
    local path = PathfindingService:CreatePath({AgentRadius = 3, AgentHeight = 5, AgentCanJump = true, Costs = {Water = math.huge}})
    local success, _ = pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end)
    if not success or path.Status ~= Enum.PathStatus.Success then return "NoPath" end
    local wps = path:GetWaypoints()
    for i = 2, #wps do
        if not isFarming or humanoid.Health <= 0 then return "Failed" end
        if not checkPart or not checkPart.Parent then return "EggGone" end
        if huntStart and (tick() - huntStart > 60) then return "Timeout" end
        if (rootPart.Position - targetPos).Magnitude < 8 then return "Reached" end
        local ok = flyTo(wps[i].Position, wps[i].Action == Enum.PathWaypointAction.Jump, 3, checkPart)
        if not ok then
            if not checkPart or not checkPart.Parent then return "EggGone" end
            flyTo(rootPart.Position + (-rootPart.CFrame.LookVector * 5), false, 0.5, nil)
        end
    end
    return "Reached"
end

local function getChainTo(targetId)
    local chain = {}
    local curr = targetId
    while curr do
        table.insert(chain, 1, curr)
        curr = islandZones[curr].Parent
    end
    return chain
end

local function huntTarget(obj, p)
    if not p or not p.Parent then return end
    local eggName = tostring(obj.Name)
    local huntStart = tick()
    local tarZone = checkZone(p.Position)
    local isEarlyExit = false

    -- GO TO
    if typeof(tarZone) == "number" then
        local chain = getChainTo(tarZone)
        for _, zoneId in ipairs(chain) do
            if not isEarlyExit and checkZone(rootPart.Position) ~= zoneId then
                local data = islandZones[zoneId]
                if (rootPart.Position - data.Path[1]).Magnitude > 15 then
                    local res = smartPath(data.Path[1], p, huntStart)
                    if res == "EggGone" or res == "Timeout" then isEarlyExit = true end
                end
                if not isEarlyExit then
                    for i = 1, #data.Path do
                        if not isFarming or not p.Parent or (tick() - huntStart > 60) then 
                            isEarlyExit = true
                            break 
                        end
                        flyTo(data.Path[i], false, 4, p)
                    end
                end
            end
        end
    end

    -- LOOT
    if not isEarlyExit then
        while p and p.Parent and p.Transparency < 1 do
            if not isFarming or humanoid.Health <= 0 or (tick() - huntStart > 60) then
                if tick() - huntStart > 60 then skippedEggs[obj] = tick() end
                break
            end
            if (rootPart.Position - p.Position).Magnitude < 8 then
                humanoid.PlatformStand = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.wait(0.1)
                local pr = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if pr then
                    local key = pr.KeyboardKeyCode
                    if key == Enum.KeyCode.Unknown then key = Enum.KeyCode.E end
                    VirtualInputManager:SendKeyEvent(true, key, false, game)
                    task.wait(pr.HoldDuration + 0.2)
                    VirtualInputManager:SendKeyEvent(false, key, false, game)
                end
                local wt = 0
                while p and p.Parent and p.Transparency < 1 and wt < 2 do
                    task.wait(0.1)
                    wt = wt + 0.1
                end
                sendWebhook(eggName, true)
                break
            end
            local status = smartPath(p.Position, p, huntStart)
            if status == "EggGone" or status == "Timeout" then
                if status == "Timeout" then skippedEggs[obj] = tick() end
                break
            end
            if status ~= "Reached" then
                flyTo(rootPart.Position + (p.Position - rootPart.Position).Unit * 15, false, 0.8, p)
            end
        end
    end

    -- RETURN
    local myZone = checkZone(rootPart.Position)
    while typeof(myZone) == "number" do
        local data = islandZones[myZone]
        for i = #data.Path, 1, -1 do
            if not isFarming or humanoid.Health <= 0 then break end
            flyTo(data.Path[i], false, 4, nil)
        end
        myZone = data.Parent
    end
    activeEggs[obj] = nil
end

-- MAIN
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
        print("Farm: " .. (isFarming and "ON" or "OFF"))
        if not isFarming then
            local ap = rootPart:FindFirstChild("FlyPos")
            if ap then ap.Enabled = false end
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

print("EGG MASTER 3.0 FINAL LOADED. NO COMPOUND OPS. NO GHOSTS.")
