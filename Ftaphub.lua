-- ══════════════════════════════════════════
--  GOJO TECHNIQUES + THIRD PERSON
--  Add this block to FTP Hub v5 Final
--  Then add the COMBAT tab section at the bottom
-- ══════════════════════════════════════════

-- ══════════════════════════════════════════
--  THIRD PERSON VIEW
-- ══════════════════════════════════════════
local thirdPersonEnabled = false
local defaultCameraMode  = localPlayer.CameraMode
local tpConn            = nil

local function enableThirdPerson()
    localPlayer.CameraMode = Enum.CameraMode.Classic
    localPlayer.CameraMinZoomDistance = 8
    localPlayer.CameraMaxZoomDistance = 25
    -- smooth zoom out
    local cam = game:GetService("RunService")
    tpConn = cam.RenderStepped:Connect(function()
        if not thirdPersonEnabled then return end
        local currentZoom = (camera.CFrame.Position -
            (localPlayer.Character and
            localPlayer.Character:FindFirstChild("HumanoidRootPart") and
            localPlayer.Character.HumanoidRootPart.Position or
            camera.CFrame.Position)).Magnitude
        if currentZoom < 10 then
            camera.CameraType = Enum.CameraType.Custom
        end
    end)
    -- force zoom out
    game:GetService("Players").LocalPlayer.CameraMinZoomDistance = 10
    game:GetService("Players").LocalPlayer.CameraMaxZoomDistance = 30
end

local function disableThirdPerson()
    if tpConn then tpConn:Disconnect(); tpConn = nil end
    localPlayer.CameraMode           = Enum.CameraMode.LockFirstPerson
    task.wait(0.05)
    localPlayer.CameraMode           = defaultCameraMode
    localPlayer.CameraMinZoomDistance = 0.5
    localPlayer.CameraMaxZoomDistance = 400
end

-- ══════════════════════════════════════════
--  GOJO — CURSED TECHNIQUE HELPERS
-- ══════════════════════════════════════════

-- creates a glowing sphere visible to all players via workspace
local function spawnSphere(position, color, size, name)
    local part = Instance.new("Part")
    part.Name          = name
    part.Shape         = Enum.PartType.Ball
    part.Size          = Vector3.new(size, size, size)
    part.Position      = position
    part.Anchored      = true
    part.CanCollide    = false
    part.CastShadow    = false
    part.Material      = Enum.Material.Neon
    part.Color         = color
    part.Parent        = workspace

    -- outer glow shell
    local glow = Instance.new("Part")
    glow.Name       = name.."Glow"
    glow.Shape      = Enum.PartType.Ball
    glow.Size       = Vector3.new(size*1.6, size*1.6, size*1.6)
    glow.Position   = position
    glow.Anchored   = true
    glow.CanCollide = false
    glow.CastShadow = false
    glow.Material   = Enum.Material.Neon
    glow.Color      = color
    glow.Transparency = 0.7
    glow.Parent     = workspace

    return part, glow
end

-- selection box highlight around a part (visible to all)
local function addHighlight(part, fillColor, outlineColor)
    local hl = Instance.new("SelectionBox")
    hl.Adornee       = part
    hl.Color3        = outlineColor
    hl.LineThickness  = 0.04
    hl.SurfaceColor3 = fillColor
    hl.SurfaceTransparency = 0.6
    hl.Parent = workspace
    return hl
end

-- pulse a part's size up then back (visual effect)
local function pulseSize(part, glow, baseSize, duration)
    task.spawn(function()
        local t = 0
        while t < duration and part.Parent do
            t = t + task.wait()
            local pulse = 1 + math.sin(t * math.pi * 6) * 0.12
            part.Size = Vector3.new(baseSize*pulse, baseSize*pulse, baseSize*pulse)
            glow.Size = Vector3.new(baseSize*1.6*pulse, baseSize*1.6*pulse, baseSize*1.6*pulse)
            part.Position = glow.Position -- keep centered
        end
    end)
end

-- shockwave ring visible to everyone
local function spawnShockwave(position, color)
    for i = 1, 3 do
        task.delay(i * 0.12, function()
            local ring = Instance.new("Part")
            ring.Shape      = Enum.PartType.Ball
            ring.Size       = Vector3.new(2,2,2)
            ring.Position   = position
            ring.Anchored   = true
            ring.CanCollide = false
            ring.CastShadow = false
            ring.Material   = Enum.Material.Neon
            ring.Color      = color
            ring.Transparency = 0.3
            ring.Parent     = workspace

            -- expand outward
            local start = tick()
            local conn
            conn = RunService.Heartbeat:Connect(function()
                local elapsed = tick() - start
                if elapsed > 1.2 or not ring.Parent then
                    conn:Disconnect(); ring:Destroy(); return
                end
                local scale = 1 + elapsed * 28
                local trans = elapsed / 1.2
                ring.Size = Vector3.new(scale, scale, scale)
                ring.Transparency = 0.3 + trans * 0.7
            end)
        end)
    end
end

-- damage players caught inside a radius (hollow purple hit)
local function blastDamage(position, radius)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == localPlayer then continue end
        local ch  = p.Character
        local rt  = ch and ch:FindFirstChild("HumanoidRootPart")
        local hm  = ch and ch:FindFirstChildOfClass("Humanoid")
        if not rt or not hm then continue end
        if (rt.Position - position).Magnitude <= radius then
            hm.Health = 0
            rt.AssemblyLinearVelocity = (rt.Position - position).Unit * 600
                + Vector3.new(0, 200, 0)
        end
    end
end

-- ══════════════════════════════════════════
--  RED  (divergence — repelling)
-- ══════════════════════════════════════════
local redActive  = false
local redPart    = nil
local redGlow    = nil

local function castRed()
    if redActive then return end
    redActive = true

    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then redActive = false; return end

    -- spawn red sphere 6 studs in front
    local spawnPos = myRoot.Position + myRoot.CFrame.LookVector * 6 + Vector3.new(0,2,0)
    redPart, redGlow = spawnSphere(spawnPos, Color3.fromRGB(255, 40, 40), 3.5, "GojoRed")
    local hl = addHighlight(redPart, Color3.fromRGB(255,80,80), Color3.fromRGB(255,0,0))
    pulseSize(redPart, redGlow, 3.5, 2)

    -- repel nearby players
    local repelConn
    repelConn = RunService.Heartbeat:Connect(function()
        if not redPart or not redPart.Parent then
            repelConn:Disconnect(); return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == localPlayer then continue end
            local rt = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if not rt then continue end
            local dist = (rt.Position - spawnPos).Magnitude
            if dist < 18 then
                local pushDir = (rt.Position - spawnPos).Unit
                rt.AssemblyLinearVelocity = pushDir * (18-dist) * 12 + Vector3.new(0,8,0)
            end
        end
    end)

    task.delay(2, function()
        repelConn:Disconnect()
        if hl and hl.Parent then hl:Destroy() end
        -- red fades out
        if redPart and redPart.Parent then
            TweenService:Create(redPart, TweenInfo.new(0.4),
                {Transparency=1, Size=Vector3.new(0.1,0.1,0.1)}):Play()
            TweenService:Create(redGlow, TweenInfo.new(0.4),
                {Transparency=1, Size=Vector3.new(0.1,0.1,0.1)}):Play()
            task.delay(0.4, function()
                if redPart  and redPart.Parent  then redPart:Destroy()  end
                if redGlow  and redGlow.Parent  then redGlow:Destroy()  end
                redPart=nil; redGlow=nil
            end)
        end
        redActive=false
    end)
end

-- ══════════════════════════════════════════
--  BLUE  (convergence — attracting)
-- ══════════════════════════════════════════
local blueActive = false
local bluePart   = nil
local blueGlow   = nil

local function castBlue()
    if blueActive then return end
    blueActive = true

    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then blueActive = false; return end

    local spawnPos = myRoot.Position + myRoot.CFrame.LookVector * 6 + Vector3.new(0,2,0)
    bluePart, blueGlow = spawnSphere(spawnPos, Color3.fromRGB(40, 120, 255), 3.5, "GojoBlue")
    local hl = addHighlight(bluePart, Color3.fromRGB(80,160,255), Color3.fromRGB(0,100,255))
    pulseSize(bluePart, blueGlow, 3.5, 2)

    -- suck in nearby players
    local suckConn
    suckConn = RunService.Heartbeat:Connect(function()
        if not bluePart or not bluePart.Parent then
            suckConn:Disconnect(); return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == localPlayer then continue end
            local rt = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if not rt then continue end
            local dist = (rt.Position - spawnPos).Magnitude
            if dist < 20 then
                local pullDir = (spawnPos - rt.Position).Unit
                rt.AssemblyLinearVelocity = pullDir * (20-dist) * 10
            end
        end
    end)

    task.delay(2, function()
        suckConn:Disconnect()
        if hl and hl.Parent then hl:Destroy() end
        if bluePart and bluePart.Parent then
            TweenService:Create(bluePart, TweenInfo.new(0.4),
                {Transparency=1, Size=Vector3.new(0.1,0.1,0.1)}):Play()
            TweenService:Create(blueGlow, TweenInfo.new(0.4),
                {Transparency=1, Size=Vector3.new(0.1,0.1,0.1)}):Play()
            task.delay(0.4, function()
                if bluePart and bluePart.Parent then bluePart:Destroy() end
                if blueGlow and blueGlow.Parent then blueGlow:Destroy() end
                bluePart=nil; blueGlow=nil
            end)
        end
        blueActive=false
    end)
end

-- ══════════════════════════════════════════
--  HOLLOW PURPLE  (red + blue combined)
-- ══════════════════════════════════════════
local purpleActive = false

local function castHollowPurple(statusLbl)
    if purpleActive then return end
    purpleActive = true
    statusLbl.Text = "Charging Red..."
    statusLbl.TextColor3 = Color3.fromRGB(255,80,80)

    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then purpleActive=false; return end

    local centerPos = myRoot.Position + myRoot.CFrame.LookVector * 8 + Vector3.new(0,3,0)

    -- PHASE 1: Red spawns left
    local rPos = centerPos - myRoot.CFrame.RightVector * 5
    local rPart, rGlow = spawnSphere(rPos, Color3.fromRGB(255,40,40), 3, "HP_Red")
    pulseSize(rPart, rGlow, 3, 1.2)

    task.wait(0.8)
    statusLbl.Text = "Charging Blue..."
    statusLbl.TextColor3 = Color3.fromRGB(80,140,255)

    -- PHASE 2: Blue spawns right
    local bPos = centerPos + myRoot.CFrame.RightVector * 5
    local bPart, bGlow = spawnSphere(bPos, Color3.fromRGB(40,120,255), 3, "HP_Blue")
    pulseSize(bPart, bGlow, 3, 1.2)

    task.wait(0.9)
    statusLbl.Text = "Hollow Purple..."
    statusLbl.TextColor3 = Color3.fromRGB(200,80,255)

    -- PHASE 3: Red and Blue travel toward each other
    local travelConn
    local t = 0
    travelConn = RunService.Heartbeat:Connect(function(dt)
        t = t + dt
        local progress = math.min(t / 0.5, 1)
        -- lerp both toward center
        if rPart and rPart.Parent then
            rPart.Position = rPos:Lerp(centerPos, progress)
            rGlow.Position = rPart.Position
        end
        if bPart and bPart.Parent then
            bPart.Position = bPos:Lerp(centerPos, progress)
            bGlow.Position = bPart.Position
        end
        if progress >= 1 then travelConn:Disconnect() end
    end)

    task.wait(0.55)

    -- PHASE 4: Collision — destroy red/blue, spawn hollow purple
    if rPart and rPart.Parent then rPart:Destroy() end
    if rGlow and rGlow.Parent then rGlow:Destroy() end
    if bPart and bPart.Parent then bPart:Destroy() end
    if bGlow and bGlow.Parent then bGlow:Destroy() end

    -- HOLLOW PURPLE sphere (massive, magenta-violet)
    local hp, hpGlow = spawnSphere(centerPos, Color3.fromRGB(180, 50, 255), 5, "HollowPurple")
    addHighlight(hp, Color3.fromRGB(200,80,255), Color3.fromRGB(150,0,255))

    -- additional inner core
    local core = Instance.new("Part")
    core.Shape       = Enum.PartType.Ball
    core.Size        = Vector3.new(2.5,2.5,2.5)
    core.Position    = centerPos
    core.Anchored    = true; core.CanCollide=false; core.CastShadow=false
    core.Material    = Enum.Material.Neon
    core.Color       = Color3.fromRGB(240,180,255)
    core.Parent      = workspace

    -- shockwaves
    spawnShockwave(centerPos, Color3.fromRGB(180,50,255))

    -- damage everything in range
    blastDamage(centerPos, 35)

    -- hollow purple travels forward (beam movement)
    local beamT = 0
    local beamConn
    beamConn = RunService.Heartbeat:Connect(function(dt)
        beamT = beamT + dt
        if beamT > 2 or not hp.Parent then
            beamConn:Disconnect()
            return
        end
        local move = myRoot.CFrame.LookVector * dt * 55
        hp.Position    = hp.Position    + move
        hpGlow.Position = hpGlow.Position + move
        core.Position  = core.Position  + move
        -- continuous damage along path
        blastDamage(hp.Position, 10)
        -- grow slightly as it travels
        local s = 5 + beamT * 2
        hp.Size   = Vector3.new(s,s,s)
        hpGlow.Size = Vector3.new(s*1.5,s*1.5,s*1.5)
    end)

    -- fade out after 2 seconds
    task.delay(2, function()
        beamConn:Disconnect()
        if hp   and hp.Parent   then
            TweenService:Create(hp,   TweenInfo.new(0.5),{Transparency=1}):Play() end
        if hpGlow and hpGlow.Parent then
            TweenService:Create(hpGlow,TweenInfo.new(0.5),{Transparency=1}):Play() end
        if core and core.Parent then
            TweenService:Create(core, TweenInfo.new(0.5),{Transparency=1}):Play() end
        task.delay(0.5, function()
            if hp   and hp.Parent   then hp:Destroy()    end
            if hpGlow and hpGlow.Parent then hpGlow:Destroy() end
            if core and core.Parent then core:Destroy()  end
        end)
        statusLbl.Text = "Ready"
        statusLbl.TextColor3 = Color3.fromRGB(140,60,220)
        purpleActive = false
    end)
end

-- ══════════════════════════════════════════
--  ADD TO COMBAT PAGE — paste after the
--  existing sec(pCombat,"Reach") block
-- ══════════════════════════════════════════

sec(pCombat, "Gojo techniques")

-- third person toggle
toggleRow(pCombat,"Third person view","thirdPerson",
    function() thirdPersonEnabled=true;  enableThirdPerson()  end,
    function() thirdPersonEnabled=false; disableThirdPerson() end)

-- Red
local redSt = Instance.new("TextLabel", pCombat)
redSt.Size=UDim2.new(1,0,0,18); redSt.BackgroundTransparency=1
redSt.Text="Ready"; redSt.TextColor3=Color3.fromRGB(255,80,80)
redSt.TextSize=10; redSt.Font=Enum.Font.Gotham; redSt.ZIndex=6

actionBtn(pCombat,"Red  — cast divergence",
    Color3.fromRGB(80,8,8), Color3.fromRGB(220,50,50),
    Color3.fromRGB(255,160,160),
    function()
        redSt.Text="Casting..."
        castRed()
        task.delay(2.1, function()
            redSt.Text="Ready"
        end)
    end)

-- Blue
local blueSt = Instance.new("TextLabel", pCombat)
blueSt.Size=UDim2.new(1,0,0,18); blueSt.BackgroundTransparency=1
blueSt.Text="Ready"; blueSt.TextColor3=Color3.fromRGB(80,140,255)
blueSt.TextSize=10; blueSt.Font=Enum.Font.Gotham; blueSt.ZIndex=6

actionBtn(pCombat,"Blue  — cast convergence",
    Color3.fromRGB(8,20,80), Color3.fromRGB(50,100,220),
    Color3.fromRGB(160,200,255),
    function()
        blueSt.Text="Casting..."
        castBlue()
        task.delay(2.1, function()
            blueSt.Text="Ready"
        end)
    end)

-- Hollow Purple
local purpleSt = Instance.new("TextLabel", pCombat)
purpleSt.Size=UDim2.new(1,0,0,18); purpleSt.BackgroundTransparency=1
purpleSt.Text="Ready"; purpleSt.TextColor3=Color3.fromRGB(200,80,255)
purpleSt.TextSize=10; purpleSt.Font=Enum.Font.Gotham; purpleSt.ZIndex=6

actionBtn(pCombat,"Hollow Purple  — combine",
    Color3.fromRGB(50,0,90), Color3.fromRGB(160,40,255),
    Color3.fromRGB(220,150,255),
    function() castHollowPurple(purpleSt) end)
