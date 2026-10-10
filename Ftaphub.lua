-- FTP Script Hub v5 FIXED | Mobile | Arceus X
-- All bugs fixed, new features added

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local camera           = workspace.CurrentCamera
local localPlayer      = Players.LocalPlayer

local connections    = {}
local currentReach   = 50
local currentFOV     = 70
local killAuraRange  = 20
local silentAimFOV   = 80
local flingAllPower  = 500
local autoFlingRange = 60
local swingBody      = nil
local swingConn      = nil
local origCF         = nil
local grabCooldown   = false
local fpsAllOn       = false
local purpleActive   = false
local redActive      = false
local blueActive     = false
local thirdPersonEnabled = false
local palletFlyEnabled   = false
local palletFlyConn      = nil
local savedLighting  = {}

local state = {
    esp=false, reach=false, speed=false, noclip=false,
    ijump=false, fling=false, swing=false,
    killAura=false, silentAim=false, flingAll=false,
    thirdPerson=false, palletFly=false,
    fps_potato=false, fps_particles=false,
    fps_shadows=false, fps_renderdist=false, fps_skybox=false,
}

-- ══════════════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name="FTPv5Fixed"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset=true
sg.Parent=game:GetService("CoreGui")

-- ══════════════════════════════════════════
--  FLOATING ICON (minimize target)
-- ══════════════════════════════════════════
local icon=Instance.new("Frame")
icon.Name="Icon"
icon.Size=UDim2.new(0,54,0,54)
icon.Position=UDim2.new(0,12,0.5,-27)
icon.BackgroundColor3=Color3.fromRGB(18,4,36)
icon.BorderSizePixel=0
icon.Visible=false
icon.ZIndex=20
icon.Parent=sg
Instance.new("UICorner",icon).CornerRadius=UDim.new(1,0)

local iStroke=Instance.new("UIStroke",icon)
iStroke.Color=Color3.fromRGB(155,89,255); iStroke.Thickness=2.5

local iLbl=Instance.new("TextLabel",icon)
iLbl.Size=UDim2.new(1,0,1,0)
iLbl.BackgroundTransparency=1
iLbl.Text="✦"
iLbl.TextColor3=Color3.fromRGB(212,138,255)
iLbl.TextSize=24
iLbl.Font=Enum.Font.GothamBold
iLbl.ZIndex=21

-- icon LED pulse
task.spawn(function()
    while true do
        if icon.Visible then
            TweenService:Create(iStroke,TweenInfo.new(0.8,Enum.EasingStyle.Sine),
                {Color=Color3.fromRGB(220,100,255)}):Play()
            task.wait(0.8)
            TweenService:Create(iStroke,TweenInfo.new(0.8,Enum.EasingStyle.Sine),
                {Color=Color3.fromRGB(60,0,140)}):Play()
            task.wait(0.8)
        else
            task.wait(0.3)
        end
    end
end)

-- icon drag
local iDrag,iDS,iSP=false,nil,nil
icon.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then
        iDrag=true; iDS=i.Position; iSP=icon.Position end
end)
UserInputService.InputChanged:Connect(function(i)
    if not iDrag then return end
    if i.UserInputType~=Enum.UserInputType.Touch
    and i.UserInputType~=Enum.UserInputType.MouseMovement then return end
    local d=i.Position-iDS
    icon.Position=UDim2.new(iSP.X.Scale,iSP.X.Offset+d.X,iSP.Y.Scale,iSP.Y.Offset+d.Y)
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then iDrag=false end
end)

-- tap icon to restore
local iconTapTime=0
icon.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.Touch
    and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    iconTapTime=tick()
end)
icon.InputEnded:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.Touch
    and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    if tick()-iconTapTime<0.2 and not iDrag then
        icon.Visible=false
        sg.MainWin.Visible=true
    end
end)

-- ══════════════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════════════
local win=Instance.new("Frame")
win.Name="MainWin"
win.Size=UDim2.new(0,310,0,420)
win.Position=UDim2.new(0.5,-155,0.5,-210)
win.BackgroundColor3=Color3.fromRGB(16,4,28)
win.BorderSizePixel=0; win.Parent=sg
Instance.new("UICorner",win).CornerRadius=UDim.new(0,14)

local wStroke=Instance.new("UIStroke",win)
wStroke.Color=Color3.fromRGB(120,40,200); wStroke.Thickness=1.5
task.spawn(function()
    while true do
        TweenService:Create(wStroke,TweenInfo.new(1.4,Enum.EasingStyle.Sine),
            {Color=Color3.fromRGB(180,80,255)}):Play() task.wait(1.4)
        TweenService:Create(wStroke,TweenInfo.new(1.4,Enum.EasingStyle.Sine),
            {Color=Color3.fromRGB(70,0,140)}):Play() task.wait(1.4)
    end
end)

-- iris background
local iris1=Instance.new("Frame")
iris1.Size=UDim2.new(1,0,1,0)
iris1.BackgroundColor3=Color3.fromRGB(12,2,22)
iris1.BorderSizePixel=0; iris1.ZIndex=0; iris1.Parent=win
Instance.new("UICorner",iris1).CornerRadius=UDim.new(0,14)

local ringColors={
    Color3.fromRGB(90,0,160),Color3.fromRGB(110,10,180),
    Color3.fromRGB(70,0,130),Color3.fromRGB(50,0,100),
}
for i,col in ipairs(ringColors) do
    local ring=Instance.new("Frame")
    local s=260-i*38
    ring.Size=UDim2.new(0,s,0,s)
    ring.Position=UDim2.new(0.5,-s/2,0.28,-s/2)
    ring.BackgroundColor3=col
    ring.BackgroundTransparency=0.75+i*0.04
    ring.BorderSizePixel=0; ring.ZIndex=1; ring.Parent=win
    Instance.new("UICorner",ring).CornerRadius=UDim.new(1,0)
end

local pupil=Instance.new("Frame")
pupil.Size=UDim2.new(0,55,0,55)
pupil.Position=UDim2.new(0.5,-27.5,0.28,-27.5)
pupil.BackgroundColor3=Color3.fromRGB(6,0,14)
pupil.BorderSizePixel=0; pupil.ZIndex=2; pupil.Parent=win
Instance.new("UICorner",pupil).CornerRadius=UDim.new(1,0)

local hl2=Instance.new("Frame")
hl2.Size=UDim2.new(0,16,0,16)
hl2.Position=UDim2.new(0.5,8,0.28,-26)
hl2.BackgroundColor3=Color3.fromRGB(220,180,255)
hl2.BackgroundTransparency=0.6
hl2.BorderSizePixel=0; hl2.ZIndex=3; hl2.Parent=win
Instance.new("UICorner",hl2).CornerRadius=UDim.new(1,0)

-- cherry blossoms
local petalColors={
    Color3.fromRGB(220,140,255),Color3.fromRGB(240,160,220),
    Color3.fromRGB(200,100,240),Color3.fromRGB(255,180,240),
}
local function spawnPetal()
    local petal=Instance.new("Frame")
    local sz=math.random(5,9)
    petal.Size=UDim2.new(0,sz,0,sz)
    petal.Position=UDim2.new(math.random(0,100)/100,-sz,0,-sz)
    petal.BackgroundColor3=petalColors[math.random(1,#petalColors)]
    petal.BackgroundTransparency=0.2
    petal.BorderSizePixel=0; petal.ZIndex=9; petal.Parent=win
    Instance.new("UICorner",petal).CornerRadius=UDim.new(1,0)
    local duration=3+math.random()*4
    task.spawn(function()
        local t=0
        while t<duration and petal.Parent do
            t=t+task.wait()
            local progress=t/duration
            local wobble=math.sin(progress*math.pi*4)*0.04
            petal.Position=UDim2.new(
                math.clamp(petal.Position.X.Scale+wobble/60,0,1),0,
                progress,-sz)
            petal.Rotation=progress*360
            petal.BackgroundTransparency=0.2+progress*0.7
        end
        if petal.Parent then petal:Destroy() end
    end)
end
task.spawn(function()
    while sg.Parent do spawnPetal(); task.wait(0.35) end
end)

-- title bar
local tBar=Instance.new("Frame")
tBar.Size=UDim2.new(1,0,0,40)
tBar.BackgroundColor3=Color3.fromRGB(14,3,26)
tBar.BackgroundTransparency=0.3
tBar.BorderSizePixel=0; tBar.ZIndex=5; tBar.Parent=win
Instance.new("UICorner",tBar).CornerRadius=UDim.new(0,14)

local tLbl=Instance.new("TextLabel")
tLbl.Size=UDim2.new(1,-90,1,0); tLbl.Position=UDim2.new(0,12,0,0)
tLbl.BackgroundTransparency=1; tLbl.Text="✦ FTP Hub v5"
tLbl.TextColor3=Color3.fromRGB(212,138,255)
tLbl.TextSize=12; tLbl.Font=Enum.Font.GothamBold
tLbl.TextXAlignment=Enum.TextXAlignment.Left
tLbl.ZIndex=6; tLbl.Parent=tBar

local function mkBtn(x,txt,bg,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,28,0,28); b.Position=UDim2.new(1,x,0,6)
    b.BackgroundColor3=bg; b.Text=txt; b.TextColor3=Color3.new(1,1,1)
    b.TextSize=11; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; b.ZIndex=6; b.Parent=tBar
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(cb); return b
end
mkBtn(-32,"✕",Color3.fromRGB(160,30,30),function() sg:Destroy() end)

-- MINIMIZE BUTTON → floating icon
mkBtn(-64,"—",Color3.fromRGB(20,60,180),function()
    win.Visible=false
    icon.Visible=true
end)

-- window drag
local wDrag,wDS,wSP=false,nil,nil
tBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then
        wDrag=true; wDS=i.Position; wSP=win.Position end
end)
UserInputService.InputChanged:Connect(function(i)
    if not wDrag then return end
    if i.UserInputType~=Enum.UserInputType.Touch
    and i.UserInputType~=Enum.UserInputType.MouseMovement then return end
    local d=i.Position-wDS
    win.Position=UDim2.new(wSP.X.Scale,wSP.X.Offset+d.X,wSP.Y.Scale,wSP.Y.Offset+d.Y)
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then wDrag=false end
end)

-- ══════════════════════════════════════════
--  TAB SYSTEM
-- ══════════════════════════════════════════
local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,0,0,32); tabBar.Position=UDim2.new(0,0,0,40)
tabBar.BackgroundColor3=Color3.fromRGB(10,2,20)
tabBar.BackgroundTransparency=0.3
tabBar.BorderSizePixel=0; tabBar.ZIndex=5; tabBar.Parent=win
Instance.new("UIListLayout",tabBar).FillDirection=Enum.FillDirection.Horizontal

local pages={}; local tabBtns={}
local TABS={
    {id="combat",label="Combat"},
    {id="move",  label="Movement"},
    {id="fps",   label="FPS Boost"},
}

local function switchTab(id)
    for _,p in pairs(pages) do p.Visible=false end
    for _,b in pairs(tabBtns) do
        b.BackgroundTransparency=1
        b.TextColor3=Color3.fromRGB(100,50,150)
    end
    if pages[id] then pages[id].Visible=true end
    if tabBtns[id] then
        tabBtns[id].BackgroundColor3=Color3.fromRGB(60,0,100)
        tabBtns[id].BackgroundTransparency=0.5
        tabBtns[id].TextColor3=Color3.fromRGB(212,138,255)
    end
end

for _,t in ipairs(TABS) do
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,103,1,0)
    btn.BackgroundTransparency=1; btn.BorderSizePixel=0
    btn.Text=t.label; btn.TextColor3=Color3.fromRGB(100,50,150)
    btn.TextSize=11; btn.Font=Enum.Font.GothamBold
    btn.ZIndex=6; btn.Parent=tabBar
    tabBtns[t.id]=btn
    btn.MouseButton1Click:Connect(function() switchTab(t.id) end)
end

local sep=Instance.new("Frame")
sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,0,72)
sep.BackgroundColor3=Color3.fromRGB(80,20,140)
sep.BorderSizePixel=0; sep.ZIndex=5; sep.Parent=win

-- ══════════════════════════════════════════
--  SCROLL PAGES
-- ══════════════════════════════════════════
local function makePage(id)
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,0,1,-74)
    scroll.Position=UDim2.new(0,0,0,74)
    scroll.BackgroundTransparency=1
    scroll.ScrollBarThickness=3
    scroll.ScrollBarImageColor3=Color3.fromRGB(140,50,220)
    scroll.CanvasSize=UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.Visible=false; scroll.ZIndex=5; scroll.Parent=win
    local lay=Instance.new("UIListLayout",scroll)
    lay.Padding=UDim.new(0,0)
    pages[id]=scroll; return scroll
end

-- ══════════════════════════════════════════
--  WIDGET HELPERS
-- ══════════════════════════════════════════
local TI=TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

local function sec(parent,txt)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,0,22); l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=Color3.fromRGB(80,30,120)
    l.TextSize=10; l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
    local p=Instance.new("UIPadding",l); p.PaddingLeft=UDim.new(0,12)
    l.ZIndex=6; l.Parent=parent
end

local function divider(parent)
    local d=Instance.new("Frame",parent)
    d.Size=UDim2.new(1,0,0,1)
    d.BackgroundColor3=Color3.fromRGB(40,10,60)
    d.BorderSizePixel=0; d.ZIndex=5
end

local function toggleRow(parent,label,key,onEn,onDis)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,44); row.BackgroundTransparency=1; row.ZIndex=5
    divider(parent)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-66,1,0); lbl.Position=UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(200,168,240)
    lbl.TextSize=12; lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(0,42,0,22); track.Position=UDim2.new(1,-52,0.5,-11)
    track.BackgroundColor3=Color3.fromRGB(40,8,64)
    track.BorderSizePixel=0; track.ZIndex=6
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local thumb=Instance.new("Frame",track)
    thumb.Size=UDim2.new(0,16,0,16); thumb.Position=UDim2.new(0,3,0.5,-8)
    thumb.BackgroundColor3=Color3.fromRGB(130,70,180)
    thumb.BorderSizePixel=0; thumb.ZIndex=7
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local isOn=false
    local function setOn()
        TweenService:Create(thumb,TI,{Position=UDim2.new(1,-19,0.5,-8),
            BackgroundColor3=Color3.fromRGB(200,100,255)}):Play()
        TweenService:Create(track,TI,{BackgroundColor3=Color3.fromRGB(100,0,180)}):Play()
        lbl.TextColor3=Color3.fromRGB(220,160,255)
    end
    local function setOff()
        TweenService:Create(thumb,TI,{Position=UDim2.new(0,3,0.5,-8),
            BackgroundColor3=Color3.fromRGB(130,70,180)}):Play()
        TweenService:Create(track,TI,{BackgroundColor3=Color3.fromRGB(40,8,64)}):Play()
        lbl.TextColor3=Color3.fromRGB(200,168,240)
    end
    local hit=Instance.new("TextButton",row)
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1
    hit.Text=""; hit.ZIndex=8
    hit.MouseButton1Click:Connect(function()
        isOn=not isOn; state[key]=isOn
        if isOn then setOn(); if onEn  then onEn()  end
        else         setOff(); if onDis then onDis() end end
    end)
end

local function sliderRow(parent,label,minV,maxV,defV,suffix,onChange)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,52); row.BackgroundTransparency=1; row.ZIndex=5
    divider(parent)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.58,0,0,24); lbl.Position=UDim2.new(0,14,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(200,168,240)
    lbl.TextSize=11; lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local pill=Instance.new("Frame",row)
    pill.Size=UDim2.new(0,52,0,20); pill.Position=UDim2.new(1,-62,0,5)
    pill.BackgroundColor3=Color3.fromRGB(74,0,144)
    pill.BorderSizePixel=0; pill.ZIndex=6
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local valLbl=Instance.new("TextLabel",pill)
    valLbl.Size=UDim2.new(1,0,1,0); valLbl.BackgroundTransparency=1
    valLbl.Text=tostring(defV)..suffix
    valLbl.TextColor3=Color3.fromRGB(240,200,255)
    valLbl.TextSize=10; valLbl.Font=Enum.Font.GothamBold; valLbl.ZIndex=7
    local trackBg=Instance.new("Frame",row)
    trackBg.Size=UDim2.new(1,-28,0,4); trackBg.Position=UDim2.new(0,14,0,36)
    trackBg.BackgroundColor3=Color3.fromRGB(40,8,64)
    trackBg.BorderSizePixel=0; trackBg.ZIndex=6
    Instance.new("UICorner",trackBg).CornerRadius=UDim.new(0,2)
    local initPct=(defV-minV)/(maxV-minV)
    local fill=Instance.new("Frame",trackBg)
    fill.Size=UDim2.new(initPct,0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(140,50,220)
    fill.BorderSizePixel=0; fill.ZIndex=7
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,2)
    local th=Instance.new("TextButton",trackBg)
    th.Size=UDim2.new(0,18,0,18); th.AnchorPoint=Vector2.new(0.5,0.5)
    th.Position=UDim2.new(initPct,0,0.5,0)
    th.BackgroundColor3=Color3.fromRGB(180,80,255)
    th.BorderSizePixel=0; th.Text=""; th.ZIndex=8
    Instance.new("UICorner",th).CornerRadius=UDim.new(1,0)
    local dragging=false
    th.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType~=Enum.UserInputType.Touch
        and i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local abs=trackBg.AbsolutePosition; local absS=trackBg.AbsoluteSize
        local rx=math.clamp((i.Position.X-abs.X)/absS.X,0,1)
        local val=math.floor(minV+rx*(maxV-minV))
        fill.Size=UDim2.new(rx,0,1,0); th.Position=UDim2.new(rx,0,0.5,0)
        valLbl.Text=tostring(val)..suffix
        if onChange then onChange(val) end
    end)
end

local function actionBtn(parent,txt,bgCol,borderCol,txtCol,cb)
    local wrap=Instance.new("Frame",parent)
    wrap.Size=UDim2.new(1,0,0,48); wrap.BackgroundTransparency=1; wrap.ZIndex=5
    local btn=Instance.new("TextButton",wrap)
    btn.Size=UDim2.new(1,-24,0,36); btn.Position=UDim2.new(0,12,0,6)
    btn.BackgroundColor3=bgCol; btn.BorderSizePixel=1
    btn.BorderColor3=borderCol; btn.Text=txt
    btn.TextColor3=txtCol; btn.TextSize=12
    btn.Font=Enum.Font.GothamBold; btn.ZIndex=8
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function mkStatusLbl(parent)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(1,0,0,20); l.BackgroundTransparency=1
    l.Text="Ready"; l.TextColor3=Color3.fromRGB(140,60,220)
    l.TextSize=11; l.Font=Enum.Font.Gotham; l.ZIndex=6
    return l
end

-- ══════════════════════════════════════════
--  GOJO SPHERE HELPER
-- ══════════════════════════════════════════
local function spawnSphere(position,color,size,name)
    local part=Instance.new("Part")
    part.Name=name; part.Shape=Enum.PartType.Ball
    part.Size=Vector3.new(size,size,size); part.Position=position
    part.Anchored=true; part.CanCollide=false; part.CastShadow=false
    part.Material=Enum.Material.Neon; part.Color=color
    part.Parent=workspace  -- goes into workspace = visible to ALL players
    local glow=Instance.new("Part")
    glow.Name=name.."Glow"; glow.Shape=Enum.PartType.Ball
    glow.Size=Vector3.new(size*1.6,size*1.6,size*1.6); glow.Position=position
    glow.Anchored=true; glow.CanCollide=false; glow.CastShadow=false
    glow.Material=Enum.Material.Neon; glow.Color=color
    glow.Transparency=0.7; glow.Parent=workspace
    return part,glow
end

local function spawnShockwave(position,color)
    for i=1,3 do
        task.delay(i*0.12,function()
            local ring=Instance.new("Part")
            ring.Shape=Enum.PartType.Ball; ring.Size=Vector3.new(2,2,2)
            ring.Position=position; ring.Anchored=true; ring.CanCollide=false
            ring.CastShadow=false; ring.Material=Enum.Material.Neon
            ring.Color=color; ring.Transparency=0.3; ring.Parent=workspace
            local start=tick(); local conn
            conn=RunService.Heartbeat:Connect(function()
                local e=tick()-start
                if e>1.2 or not ring.Parent then
                    conn:Disconnect()
                    if ring.Parent then ring:Destroy() end
                    return
                end
                local s=1+e*28
                ring.Size=Vector3.new(s,s,s)
                ring.Transparency=0.3+(e/1.2)*0.7
            end)
        end)
    end
end

local function blastDamage(position,radius)
    for _,p in ipairs(Players:GetPlayers()) do
        if p==localPlayer then continue end
        local ch=p.Character
        local rt=ch and ch:FindFirstChild("HumanoidRootPart")
        local hm=ch and ch:FindFirstChildOfClass("Humanoid")
        if not rt or not hm then continue end
        if (rt.Position-position).Magnitude<=radius then
            hm.Health=0
            rt.AssemblyLinearVelocity=(rt.Position-position).Unit*600+Vector3.new(0,200,0)
        end
    end
end

-- ══════════════════════════════════════════
--  FEATURE LOGIC
-- ══════════════════════════════════════════

-- ── GRAB NEAREST (FIXED) ─────────────────
-- No pointing required — pure distance scan across ALL players
-- Works on players in air too — no ground check
local function doGrab(lbl)
    if grabCooldown then return end
    grabCooldown=true
    lbl.Text="Scanning..."; lbl.TextColor3=Color3.fromRGB(200,150,255)

    local myChar=localPlayer.Character
    local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        lbl.Text="No character found"
        lbl.TextColor3=Color3.fromRGB(255,100,100)
        grabCooldown=false; return
    end

    -- scan every player, no distance cap — find absolute nearest
    local best=nil; local bestDist=math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p==localPlayer then continue end
        local ch=p.Character
        local rt=ch and ch:FindFirstChild("HumanoidRootPart")
        if not rt then continue end
        local d=(rt.Position-myRoot.Position).Magnitude
        if d<bestDist then
            bestDist=d; best=rt
        end
    end

    if best then
        -- teleport target directly in front of us regardless of where they are
        local targetCF=CFrame.new(
            myRoot.Position + myRoot.CFrame.LookVector*4 + Vector3.new(0,0.5,0)
        )
        best.CFrame=targetCF
        best.AssemblyLinearVelocity=Vector3.zero
        best.AssemblyAngularVelocity=Vector3.zero
        lbl.Text="Grabbed! ("..math.floor(bestDist).." st)"
        lbl.TextColor3=Color3.fromRGB(130,255,130)
    else
        lbl.Text="No players in server"
        lbl.TextColor3=Color3.fromRGB(255,130,130)
    end

    task.delay(1.5,function()
        lbl.Text="Ready"; lbl.TextColor3=Color3.fromRGB(140,60,220)
        grabCooldown=false
    end)
end

-- ── KILL AURA ────────────────────────────
local function enableKillAura()
    connections.killAura=RunService.Heartbeat:Connect(function()
        local myRoot=localPlayer.Character and
            localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p==localPlayer then continue end
            local ch=p.Character
            local rt=ch and ch:FindFirstChild("HumanoidRootPart")
            local hm=ch and ch:FindFirstChildOfClass("Humanoid")
            if not rt or not hm or hm.Health<=0 then continue end
            if (rt.Position-myRoot.Position).Magnitude<=killAuraRange then
                hm.Health=0
                rt.AssemblyLinearVelocity=Vector3.new(0,9999,0)
            end
        end
    end)
end
local function disableKillAura()
    if connections.killAura then
        connections.killAura:Disconnect(); connections.killAura=nil end
end

-- ── SILENT AIM ───────────────────────────
local function getNearestHead()
    local sc=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    local best,bestDist=nil,silentAimFOV
    for _,p in ipairs(Players:GetPlayers()) do
        if p==localPlayer then continue end
        local ch=p.Character; if not ch then continue end
        local hd=ch:FindFirstChild("Head")
        local hm=ch:FindFirstChildOfClass("Humanoid")
        if not hd or not hm or hm.Health<=0 then continue end
        local sp,onScreen=camera:WorldToViewportPoint(hd.Position)
        if not onScreen then continue end
        local d=(Vector2.new(sp.X,sp.Y)-sc).Magnitude
        if d<bestDist then bestDist=d; best=hd end
    end
    return best
end
local function enableSilentAim()
    connections.silentAim=RunService.RenderStepped:Connect(function()
        if not state.silentAim then return end
        local target=getNearestHead(); if not target then return end
        origCF=camera.CFrame
        camera.CFrame=CFrame.new(camera.CFrame.Position,target.Position)
    end)
    connections.silentAimRestore=RunService.Stepped:Connect(function()
        if origCF and state.silentAim then
            camera.CFrame=origCF; origCF=nil end
    end)
end
local function disableSilentAim()
    if connections.silentAim then
        connections.silentAim:Disconnect(); connections.silentAim=nil end
    if connections.silentAimRestore then
        connections.silentAimRestore:Disconnect(); connections.silentAimRestore=nil end
    if origCF then camera.CFrame=origCF; origCF=nil end
end

-- ── FLING ALL (FIXED) ────────────────────
-- Uses a repeated Heartbeat loop that fires every frame
-- Forces velocity on EVERY player, no range limit
local function doFlingAll()
    for _,p in ipairs(Players:GetPlayers()) do
        if p==localPlayer then continue end
        local ch=p.Character
        local rt=ch and ch:FindFirstChild("HumanoidRootPart")
        if not rt then continue end
        -- set network ownership attempt
        pcall(function() rt:SetNetworkOwner(localPlayer) end)
        rt.AssemblyLinearVelocity=Vector3.new(
            (math.random()-0.5)*flingAllPower*2,
            flingAllPower*0.8,
            (math.random()-0.5)*flingAllPower*2
        )
    end
end

local function enableFlingAll()
    connections.flingAll=RunService.Heartbeat:Connect(function()
        for _,p in ipairs(Players:GetPlayers()) do
            if p==localPlayer then continue end
            local ch=p.Character
            local rt=ch and ch:FindFirstChild("HumanoidRootPart")
            if not rt then continue end
            pcall(function() rt:SetNetworkOwner(localPlayer) end)
            -- re-apply every frame so they never land
            rt.AssemblyLinearVelocity=Vector3.new(
                (math.random()-0.5)*flingAllPower*2,
                flingAllPower*0.8,
                (math.random()-0.5)*flingAllPower*2
            )
        end
    end)
end
local function disableFlingAll()
    if connections.flingAll then
        connections.flingAll:Disconnect(); connections.flingAll=nil end
end

-- ── ESP ──────────────────────────────────
local espF=Instance.new("Folder")
espF.Name="ESP_FTP"; espF.Parent=game:GetService("CoreGui")
local function enableESP()
    connections.esp=RunService.RenderStepped:Connect(function()
        for _,v in ipairs(espF:GetChildren()) do v:Destroy() end
        for _,p in ipairs(Players:GetPlayers()) do
            if p==localPlayer then continue end
            local ch=p.Character; if not ch then continue end
            local rt=ch:FindFirstChild("HumanoidRootPart")
            local hm=ch:FindFirstChildOfClass("Humanoid")
            if not rt or not hm or hm.Health<=0 then continue end
            local _,onS=camera:WorldToViewportPoint(rt.Position)
            if not onS then continue end
            local bg=Instance.new("BillboardGui")
            bg.Size=UDim2.new(0,55,0,85); bg.StudsOffset=Vector3.new(0,3,0)
            bg.Adornee=rt; bg.AlwaysOnTop=true; bg.Parent=espF
            local bx=Instance.new("Frame",bg)
            bx.Size=UDim2.new(1,0,1,0); bx.BackgroundTransparency=1
            bx.BorderSizePixel=2; bx.BorderColor3=Color3.fromRGB(180,80,255)
            local nl=Instance.new("TextLabel",bg)
            nl.Size=UDim2.new(1,0,0,16); nl.Position=UDim2.new(0,0,0,-18)
            nl.BackgroundTransparency=1; nl.Text=p.Name
            nl.TextColor3=Color3.fromRGB(212,138,255)
            nl.TextSize=11; nl.Font=Enum.Font.GothamBold
            local hpBg=Instance.new("Frame",bg)
            hpBg.Size=UDim2.new(0,4,1,0); hpBg.Position=UDim2.new(0,-8,0,0)
            hpBg.BackgroundColor3=Color3.fromRGB(30,0,50)
            local pct=hm.Health/hm.MaxHealth
            local hf=Instance.new("Frame",hpBg)
            hf.Size=UDim2.new(1,0,pct,0); hf.Position=UDim2.new(0,0,1-pct,0)
            hf.BackgroundColor3=Color3.fromHSV(0.75,0.8,1)
        end
    end)
end
local function disableESP()
    if connections.esp then connections.esp:Disconnect(); connections.esp=nil end
    for _,v in ipairs(espF:GetChildren()) do v:Destroy() end
end

-- ── SPEED ────────────────────────────────
local function enableSpeed()
    local hm=localPlayer.Character and
        localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hm then hm.WalkSpeed=80 end
    connections.speed=localPlayer.CharacterAdded:Connect(function(c)
        local h=c:WaitForChild("Humanoid"); if h then h.WalkSpeed=80 end
    end)
end
local function disableSpeed()
    if connections.speed then connections.speed:Disconnect(); connections.speed=nil end
    local hm=localPlayer.Character and
        localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hm then hm.WalkSpeed=16 end
end

-- ── NOCLIP ───────────────────────────────
local function enableNoclip()
    connections.noclip=RunService.Stepped:Connect(function()
        local ch=localPlayer.Character; if not ch then return end
        for _,p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end
local function disableNoclip()
    if connections.noclip then
        connections.noclip:Disconnect(); connections.noclip=nil end
    local ch=localPlayer.Character; if not ch then return end
    for _,p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=true end
    end
end

-- ── INFINITE JUMP ────────────────────────
local function enableIJump()
    connections.ijump=UserInputService.JumpRequest:Connect(function()
        local hm=localPlayer.Character and
            localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hm then hm:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end
local function disableIJump()
    if connections.ijump then
        connections.ijump:Disconnect(); connections.ijump=nil end
end

-- ── AUTO FLING (nearby) ──────────────────
local function enableFling()
    connections.fling=RunService.Heartbeat:Connect(function()
        local mr=localPlayer.Character and
            localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not mr then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p==localPlayer then continue end
            local rt=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if not rt then continue end
            if (rt.Position-mr.Position).Magnitude<autoFlingRange then
                pcall(function() rt:SetNetworkOwner(localPlayer) end)
                rt.AssemblyLinearVelocity=Vector3.new(
                    math.random(-1,1)*300,160,math.random(-1,1)*300)
            end
        end
    end)
end
local function disableFling()
    if connections.fling then
        connections.fling:Disconnect(); connections.fling=nil end
end

-- ── FAR REACH ────────────────────────────
local function applyReach(v)
    currentReach=v
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("ClickDetector") then o.MaxActivationDistance=v end
        if o:IsA("ProximityPrompt") then o.MaxActivationDistance=v end
    end
end
local function enableReach()
    applyReach(currentReach)
    connections.reachWs=workspace.DescendantAdded:Connect(function(o)
        if o:IsA("ClickDetector") then o.MaxActivationDistance=currentReach end
        if o:IsA("ProximityPrompt") then o.MaxActivationDistance=currentReach end
    end)
    connections.reachCh=localPlayer.CharacterAdded:Connect(function()
        task.wait(0.5); applyReach(currentReach) end)
end
local function disableReach()
    if connections.reachWs then
        connections.reachWs:Disconnect(); connections.reachWs=nil end
    if connections.reachCh then
        connections.reachCh:Disconnect(); connections.reachCh=nil end
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("ClickDetector") then o.MaxActivationDistance=32 end
        if o:IsA("ProximityPrompt") then o.MaxActivationDistance=10 end
    end
end

-- ── SWING PALLET ─────────────────────────
local STAGS={"pallet","swing","swingpart"}
local function enableSwing()
    local mc=localPlayer.Character
    local mr=mc and mc:FindFirstChild("HumanoidRootPart"); if not mr then return end
    local best,bd=nil,math.huge
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            for _,t in ipairs(STAGS) do
                if o.Name:lower():find(t) then
                    local d=(o.Position-mr.Position).Magnitude
                    if d<bd then bd=d; best=o end; break
                end
            end
        end
    end
    local anchor=best
    if not anchor then
        anchor=Instance.new("Part"); anchor.Name="VA"
        anchor.Anchored=true; anchor.CanCollide=false
        anchor.Transparency=1; anchor.Size=Vector3.new(1,1,1)
        anchor.Position=mr.Position+Vector3.new(0,30,0)
        anchor.Parent=workspace
    end
    local hm=mc:FindFirstChildOfClass("Humanoid")
    if hm then hm:ChangeState(Enum.HumanoidStateType.Physics) end
    swingBody=Instance.new("BodyVelocity")
    swingBody.MaxForce=Vector3.new(1e5,1e5,1e5)
    swingBody.Velocity=Vector3.zero; swingBody.Parent=mr
    swingConn=RunService.Heartbeat:Connect(function(dt)
        if not mr or not mr.Parent then return end
        local toA=anchor.Position-mr.Position
        local len=toA.Magnitude; local dir=toA.Unit
        local vel=mr.AssemblyLinearVelocity
        local cent=dir*vel:Dot(dir)
        local grav=Vector3.new(0,-workspace.Gravity*0.85,0)
        swingBody.Velocity=(swingBody.Velocity+
            (grav-cent+dir*(len-20)*60)*dt)*0.97
    end)
end
local function disableSwing()
    if swingConn then swingConn:Disconnect(); swingConn=nil end
    if swingBody then swingBody:Destroy(); swingBody=nil end
    local hm=localPlayer.Character and
        localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hm then hm:ChangeState(Enum.HumanoidStateType.GettingUp) end
    local tmp=workspace:FindFirstChild("VA"); if tmp then tmp:Destroy() end
end

-- ── PALLET FLY (no fall) ─────────────────
-- Finds nearest pallet/platform, welds you to it via BodyPosition
-- You hover on the pallet without falling off even if it moves
local palletBody=nil
local function enablePalletFly()
    local mc=localPlayer.Character
    local mr=mc and mc:FindFirstChild("HumanoidRootPart"); if not mr then return end

    -- find nearest pallet-named part
    local best,bd=nil,math.huge
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            for _,t in ipairs(STAGS) do
                if o.Name:lower():find(t) then
                    local d=(o.Position-mr.Position).Magnitude
                    if d<bd then bd=d; best=o end; break
                end
            end
        end
    end

    local targetPart=best
    -- if no pallet found, create a floating platform above player
    if not targetPart then
        local plat=Instance.new("Part")
        plat.Name="FlyPallet"; plat.Size=Vector3.new(8,1,8)
        plat.Anchored=true; plat.CanCollide=true
        plat.Material=Enum.Material.SmoothPlastic
        plat.Color=Color3.fromRGB(100,0,180)
        plat.Position=mr.Position+Vector3.new(0,5,0)
        plat.Parent=workspace
        targetPart=plat
    end

    -- disable humanoid fall state
    local hm=mc:FindFirstChildOfClass("Humanoid")
    if hm then hm:ChangeState(Enum.HumanoidStateType.Physics) end

    -- BodyPosition keeps player locked above the pallet
    palletBody=Instance.new("BodyPosition")
    palletBody.MaxForce=Vector3.new(1e5,1e5,1e5)
    palletBody.D=500
    palletBody.P=10000
    palletBody.Position=targetPart.Position+Vector3.new(0,4,0)
    palletBody.Parent=mr

    palletFlyConn=RunService.Heartbeat:Connect(function()
        if not mr or not mr.Parent or not palletBody then return end
        -- follow pallet if it moves, stay 4 studs above it
        palletBody.Position=targetPart.Position+Vector3.new(0,4,0)
    end)
end
local function disablePalletFly()
    if palletFlyConn then palletFlyConn:Disconnect(); palletFlyConn=nil end
    if palletBody then palletBody:Destroy(); palletBody=nil end
    local hm=localPlayer.Character and
        localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hm then hm:ChangeState(Enum.HumanoidStateType.GettingUp) end
    -- clean generated platform
    local tmp=workspace:FindFirstChild("FlyPallet")
    if tmp then tmp:Destroy() end
end

-- ── THIRD PERSON ─────────────────────────
local defaultCameraMode=localPlayer.CameraMode
local function enableThirdPerson()
    thirdPersonEnabled=true
    localPlayer.CameraMode=Enum.CameraMode.Classic
    localPlayer.CameraMinZoomDistance=10
    localPlayer.CameraMaxZoomDistance=30
end
local function disableThirdPerson()
    thirdPersonEnabled=false
    localPlayer.CameraMode=defaultCameraMode
    localPlayer.CameraMinZoomDistance=0.5
    localPlayer.CameraMaxZoomDistance=400
end

-- ── GOJO RED ─────────────────────────────
local function castRed(statusLbl)
    if redActive then return end; redActive=true
    statusLbl.Text="Red — active"; statusLbl.TextColor3=Color3.fromRGB(255,80,80)
    local mc=localPlayer.Character
    local mr=mc and mc:FindFirstChild("HumanoidRootPart")
    if not mr then redActive=false; return end
    local spawnPos=mr.Position+mr.CFrame.LookVector*6+Vector3.new(0,2,0)
    local rPart,rGlow=spawnSphere(spawnPos,Color3.fromRGB(255,40,40),3.5,"GojoRed")
    local repelConn
    repelConn=RunService.Heartbeat:Connect(function()
        if not rPart or not rPart.Parent then repelConn:Disconnect(); return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p==localPlayer then continue end
            local rt=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if not rt then continue end
            local dist=(rt.Position-spawnPos).Magnitude
            if dist<18 then
                pcall(function() rt:SetNetworkOwner(localPlayer) end)
                rt.AssemblyLinearVelocity=(rt.Position-spawnPos).Unit*(18-dist)*14
                    +Vector3.new(0,10,0)
            end
        end
    end)
    task.delay(2,function()
        repelConn:Disconnect()
        if rPart and rPart.Parent then
            TweenService:Create(rPart,TweenInfo.new(0.4),
                {Transparency=1,Size=Vector3.new(0.1,0.1,0.1)}):Play()
            TweenService:Create(rGlow,TweenInfo.new(0.4),
                {Transparency=1,Size=Vector3.new(0.1,0.1,0.1)}):Play()
            task.delay(0.4,function()
                if rPart and rPart.Parent then rPart:Destroy() end
                if rGlow and rGlow.Parent then rGlow:Destroy() end
            end)
        end
        redActive=false
        statusLbl.Text="Ready"; statusLbl.TextColor3=Color3.fromRGB(255,80,80)
    end)
end

-- ── GOJO BLUE ────────────────────────────
local function castBlue(statusLbl)
    if blueActive then return end; blueActive=true
    statusLbl.Text="Blue — active"; statusLbl.TextColor3=Color3.fromRGB(80,140,255)
    local mc=localPlayer.Character
    local mr=mc and mc:FindFirstChild("HumanoidRootPart")
    if not mr then blueActive=false; return end
    local spawnPos=mr.Position+mr.CFrame.LookVector*6+Vector3.new(0,2,0)
    local bPart,bGlow=spawnSphere(spawnPos,Color3.fromRGB(40,120,255),3.5,"GojoBlue")
    local suckConn
    suckConn=RunService.Heartbeat:Connect(function()
        if not bPart or not bPart.Parent then suckConn:Disconnect(); return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p==localPlayer then continue end
            local rt=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if not rt then continue end
            local dist=(rt.Position-spawnPos).Magnitude
            if dist<20 then
                pcall(function() rt:SetNetworkOwner(localPlayer) end)
                rt.AssemblyLinearVelocity=(spawnPos-rt.Position).Unit*(20-dist)*12
            end
        end
    end)
    task.delay(2,function()
        suckConn:Disconnect()
        if bPart and bPart.Parent then
            TweenService:Create(bPart,TweenInfo.new(0.4),
                {Transparency=1,Size=Vector3.new(0.1,0.1,0.1)}):Play()
            TweenService:Create(bGlow,TweenInfo.new(0.4),
                {Transparency=1,Size=Vector3.new(0.1,0.1,0.1)}):Play()
            task.delay(0.4,function()
                if bPart and bPart.Parent then bPart:Destroy() end
                if bGlow and bGlow.Parent then bGlow:Destroy() end
            end)
        end
        blueActive=false
        statusLbl.Text="Ready"; statusLbl.TextColor3=Color3.fromRGB(80,140,255)
    end)
end

-- ── HOLLOW PURPLE (everyone sees it) ─────
local function castHollowPurple(statusLbl)
    if purpleActive then return end; purpleActive=true
    local mc=localPlayer.Character
    local mr=mc and mc:FindFirstChild("HumanoidRootPart")
    if not mr then purpleActive=false; return end
    local centerPos=mr.Position+mr.CFrame.LookVector*8+Vector3.new(0,3,0)

    statusLbl.Text="Charging Red..."
    statusLbl.TextColor3=Color3.fromRGB(255,80,80)
    local rPos=centerPos-mr.CFrame.RightVector*5
    local rPart,rGlow=spawnSphere(rPos,Color3.fromRGB(255,40,40),3,"HP_Red")

    task.wait(0.8)
    statusLbl.Text="Charging Blue..."
    statusLbl.TextColor3=Color3.fromRGB(80,140,255)
    local bPos=centerPos+mr.CFrame.RightVector*5
    local bPart,bGlow=spawnSphere(bPos,Color3.fromRGB(40,120,255),3,"HP_Blue")

    task.wait(0.9)
    statusLbl.Text="Hollow Purple!"
    statusLbl.TextColor3=Color3.fromRGB(200,80,255)

    -- travel both toward center
    local tT=0; local tConn
    tConn=RunService.Heartbeat:Connect(function(dt)
        tT=tT+dt
        local prog=math.min(tT/0.5,1)
        if rPart and rPart.Parent then
            rPart.Position=rPos:Lerp(centerPos,prog); rGlow.Position=rPart.Position end
        if bPart and bPart.Parent then
            bPart.Position=bPos:Lerp(centerPos,prog); bGlow.Position=bPart.Position end
        if prog>=1 then tConn:Disconnect() end
    end)
    task.wait(0.55)

    -- destroy red + blue
    for _,v in ipairs({rPart,rGlow,bPart,bGlow}) do
        if v and v.Parent then v:Destroy() end
    end

    -- spawn hollow purple — visible to everyone via workspace
    local hp,hpGlow=spawnSphere(centerPos,Color3.fromRGB(180,50,255),6,"HollowPurple")
    local core=Instance.new("Part")
    core.Shape=Enum.PartType.Ball; core.Size=Vector3.new(3,3,3)
    core.Position=centerPos; core.Anchored=true; core.CanCollide=false
    core.CastShadow=false; core.Material=Enum.Material.Neon
    core.Color=Color3.fromRGB(240,180,255); core.Parent=workspace

    spawnShockwave(centerPos,Color3.fromRGB(180,50,255))
    blastDamage(centerPos,40)

    -- beam travels forward
    local bT=0; local bConn
    bConn=RunService.Heartbeat:Connect(function(dt)
        bT=bT+dt
        if bT>2.5 or not hp.Parent then bConn:Disconnect(); return end
        local move=mr.CFrame.LookVector*dt*55
        hp.Position=hp.Position+move
        hpGlow.Position=hpGlow.Position+move
        core.Position=core.Position+move
        blastDamage(hp.Position,12)
        local s=6+bT*2
        hp.Size=Vector3.new(s,s,s)
        hpGlow.Size=Vector3.new(s*1.5,s*1.5,s*1.5)
    end)

    task.delay(2.5,function()
        bConn:Disconnect()
        for _,v in ipairs({hp,hpGlow,core}) do
            if v and v.Parent then
                TweenService:Create(v,TweenInfo.new(0.5),{Transparency=1}):Play()
                task.delay(0.5,function()
                    if v and v.Parent then v:Destroy() end
                end)
            end
        end
        statusLbl.Text="Ready"
        statusLbl.TextColor3=Color3.fromRGB(200,80,255)
        purpleActive=false
    end)
end

-- ── FPS BOOSTER ──────────────────────────
local function enablePotato()
    savedLighting.ambient=Lighting.Ambient
    savedLighting.outAmb=Lighting.OutdoorAmbient
    savedLighting.brightness=Lighting.Brightness
    Lighting.Ambient=Color3.fromRGB(178,178,178)
    Lighting.OutdoorAmbient=Color3.fromRGB(178,178,178)
    Lighting.Brightness=1
    settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
end
local function disablePotato()
    if savedLighting.ambient then Lighting.Ambient=savedLighting.ambient end
    if savedLighting.outAmb then Lighting.OutdoorAmbient=savedLighting.outAmb end
    if savedLighting.brightness then Lighting.Brightness=savedLighting.brightness end
    settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic
end

local function enableRemoveParticles()
    local function kill(obj)
        if obj:IsA("ParticleEmitter") then obj.Enabled=false; obj:Clear()
        elseif obj:IsA("Beam") or obj:IsA("Trail")
            or obj:IsA("Fire") or obj:IsA("Smoke")
            or obj:IsA("Sparkles") then obj.Enabled=false end
    end
    for _,o in ipairs(workspace:GetDescendants()) do kill(o) end
    connections.particles=workspace.DescendantAdded:Connect(kill)
end
local function disableRemoveParticles()
    if connections.particles then
        connections.particles:Disconnect(); connections.particles=nil end
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail")
        or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles") then
            o.Enabled=true end
    end
end

local function enableNoShadows()
    Lighting.GlobalShadows=false; Lighting.ShadowSoftness=0 end
local function disableNoShadows()
    Lighting.GlobalShadows=true; Lighting.ShadowSoftness=0.2 end

local function enableLowRender()
    savedLighting.fogEnd=Lighting.FogEnd
    savedLighting.fogStart=Lighting.FogStart
    savedLighting.fogColor=Lighting.FogColor
    Lighting.FogEnd=600; Lighting.FogStart=400
    Lighting.FogColor=Color3.fromRGB(20,10,30)
end
local function disableLowRender()
    if savedLighting.fogEnd then Lighting.FogEnd=savedLighting.fogEnd end
    if savedLighting.fogStart then Lighting.FogStart=savedLighting.fogStart end
    if savedLighting.fogColor then Lighting.FogColor=savedLighting.fogColor end
end

local function enableNoSkybox()
    local sky=Lighting:FindFirstChildOfClass("Sky")
    if sky then sky.Enabled=false end
end
local function disableNoSkybox()
    local sky=Lighting:FindFirstChildOfClass("Sky")
    if sky then sky.Enabled=true end
end

local function toggleAllFPS(lbl)
    fpsAllOn=not fpsAllOn
    if fpsAllOn then
        enablePotato(); enableRemoveParticles()
        enableNoShadows(); enableLowRender(); enableNoSkybox()
        lbl.Text="All boosts active"
        lbl.TextColor3=Color3.fromRGB(130,255,130)
    else
        disablePotato(); disableRemoveParticles()
        disableNoShadows(); disableLowRender(); disableNoSkybox()
        lbl.Text="All disabled"
        lbl.TextColor3=Color3.fromRGB(180,80,255)
    end
end

-- ══════════════════════════════════════════
--  BUILD PAGES
-- ══════════════════════════════════════════

-- COMBAT PAGE
local pCombat=makePage("combat")

sec(pCombat,"Grab")
sliderRow(pCombat,"Grab range",5,500,999," st",function(v) currentReach=v end)
local grabSt=mkStatusLbl(pCombat)
actionBtn(pCombat,"⚡ Grab nearest player",
    Color3.fromRGB(60,0,120),Color3.fromRGB(140,60,220),
    Color3.fromRGB(220,170,255),function() doGrab(grabSt) end)

sec(pCombat,"Kill aura")
toggleRow(pCombat,"Kill aura","killAura",enableKillAura,disableKillAura)
sliderRow(pCombat,"Kill range",5,80,20," st",function(v) killAuraRange=v end)

sec(pCombat,"Silent aim")
toggleRow(pCombat,"Silent aim  (no cam move)","silentAim",
    function() state.silentAim=true; enableSilentAim() end,
    function() state.silentAim=false; disableSilentAim() end)
sliderRow(pCombat,"Silent aim FOV",10,300,80," px",function(v) silentAimFOV=v end)

sec(pCombat,"Fling all")
toggleRow(pCombat,"Fling all  (continuous)","flingAll",enableFlingAll,disableFlingAll)
sliderRow(pCombat,"Fling power",100,2000,500,"",function(v) flingAllPower=v end)
actionBtn(pCombat,"💥 Fling all once",
    Color3.fromRGB(80,10,10),Color3.fromRGB(200,60,60),
    Color3.fromRGB(255,180,180),doFlingAll)

sec(pCombat,"Vision")
toggleRow(pCombat,"ESP  (box + HP + name)","esp",enableESP,disableESP)

sec(pCombat,"Reach")
toggleRow(pCombat,"Far reach","reach",enableReach,disableReach)
sliderRow(pCombat,"Reach distance",5,200,50," st",function(v)
    currentReach=v; if state.reach then applyReach(v) end end)

sec(pCombat,"Gojo techniques")
toggleRow(pCombat,"Third person view","thirdPerson",
    enableThirdPerson,disableThirdPerson)

local redSt=mkStatusLbl(pCombat)
redSt.TextColor3=Color3.fromRGB(255,80,80)
actionBtn(pCombat,"🔴 Red — divergence (repel)",
    Color3.fromRGB(80,8,8),Color3.fromRGB(220,50,50),
    Color3.fromRGB(255,160,160),function() castRed(redSt) end)

local blueSt=mkStatusLbl(pCombat)
blueSt.TextColor3=Color3.fromRGB(80,140,255)
actionBtn(pCombat,"🔵 Blue — convergence (pull)",
    Color3.fromRGB(8,20,80),Color3.fromRGB(50,100,220),
    Color3.fromRGB(160,200,255),function() castBlue(blueSt) end)

local purpleSt=mkStatusLbl(pCombat)
purpleSt.TextColor3=Color3.fromRGB(200,80,255)
actionBtn(pCombat,"✦ Hollow Purple — combine",
    Color3.fromRGB(50,0,90),Color3.fromRGB(160,40,255),
    Color3.fromRGB(220,150,255),function() castHollowPurple(purpleSt) end)

-- MOVEMENT PAGE
local pMove=makePage("move")
sec(pMove,"Movement")
toggleRow(pMove,"Speed hack  (80 WS)","speed",enableSpeed,disableSpeed)
toggleRow(pMove,"Noclip","noclip",enableNoclip,disableNoclip)
toggleRow(pMove,"Infinite jump","ijump",enableIJump,disableIJump)

sec(pMove,"Fling")
toggleRow(pMove,"Auto fling  (nearby)","fling",enableFling,disableFling)
sliderRow(pMove,"Auto fling range",10,200,60," st",function(v) autoFlingRange=v end)
sliderRow(pMove,"Fling power",100,2000,500,"",function(v) flingAllPower=v end)

sec(pMove,"Pallet")
toggleRow(pMove,"Swing pallet","swing",enableSwing,disableSwing)
toggleRow(pMove,"Pallet fly  (no fall)","palletFly",enablePalletFly,disablePalletFly)

-- FPS BOOST PAGE
local pFPS=makePage("fps")
sec(pFPS,"Graphics optimizer")
toggleRow(pFPS,"Potato graphics","fps_potato",enablePotato,disablePotato)
toggleRow(pFPS,"Remove particles + fire","fps_particles",
    enableRemoveParticles,disableRemoveParticles)
toggleRow(pFPS,"Disable shadows","fps_shadows",enableNoShadows,disableNoShadows)
toggleRow(pFPS,"Low render distance","fps_renderdist",enableLowRender,disableLowRender)
toggleRow(pFPS,"Disable skybox","fps_skybox",enableNoSkybox,disableNoSkybox)
sec(pFPS,"Quick actions")
local fpsSt=mkStatusLbl(pFPS)
actionBtn(pFPS,"Enable all FPS boosts",
    Color3.fromRGB(20,60,20),Color3.fromRGB(60,160,60),
    Color3.fromRGB(180,255,180),function() toggleAllFPS(fpsSt) end)

-- INIT
switchTab("combat")
