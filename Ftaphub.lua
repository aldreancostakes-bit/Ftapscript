-- FTP Script Hub v5 PATCHED | Mobile | Arceus X
-- Anti-detect, working grab, smaller GUI

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local camera           = workspace.CurrentCamera
local localPlayer      = Players.LocalPlayer

local connections    = {}
local currentReach   = 50
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
local palletFlyConn  = nil
local palletBody     = nil
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
--  ANTI-DETECT — randomise ScreenGui name
-- ══════════════════════════════════════════
local function randStr(len)
    local chars="abcdefghijklmnopqrstuvwxyz"
    local s=""
    for _=1,len do
        local i=math.random(1,#chars)
        s=s..chars:sub(i,i)
    end
    return s
end

-- ══════════════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════════════
local sg=Instance.new("ScreenGui")
sg.Name=randStr(8)
sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset=true
sg.Parent=game:GetService("CoreGui")

-- ══════════════════════════════════════════
--  FLOATING ICON
-- ══════════════════════════════════════════
local icon=Instance.new("Frame")
icon.Name=randStr(6)
icon.Size=UDim2.new(0,46,0,46)
icon.Position=UDim2.new(0,10,0.5,-23)
icon.BackgroundColor3=Color3.fromRGB(18,4,36)
icon.BorderSizePixel=0
icon.Visible=false
icon.ZIndex=20
icon.Parent=sg
Instance.new("UICorner",icon).CornerRadius=UDim.new(1,0)

local iStroke=Instance.new("UIStroke",icon)
iStroke.Color=Color3.fromRGB(155,89,255)
iStroke.Thickness=2

local iLbl=Instance.new("TextLabel",icon)
iLbl.Size=UDim2.new(1,0,1,0)
iLbl.BackgroundTransparency=1
iLbl.Text="✦"
iLbl.TextColor3=Color3.fromRGB(212,138,255)
iLbl.TextSize=20
iLbl.Font=Enum.Font.GothamBold
iLbl.ZIndex=21

task.spawn(function()
    while true do
        if icon.Visible then
            TweenService:Create(iStroke,TweenInfo.new(0.9,Enum.EasingStyle.Sine),
                {Color=Color3.fromRGB(220,100,255)}):Play()
            task.wait(0.9)
            TweenService:Create(iStroke,TweenInfo.new(0.9,Enum.EasingStyle.Sine),
                {Color=Color3.fromRGB(60,0,140)}):Play()
            task.wait(0.9)
        else
            task.wait(0.3)
        end
    end
end)

local iDrag,iDS,iSP=false,nil,nil
local iTapTime=0
icon.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then
        iDrag=true; iDS=i.Position; iSP=icon.Position
        iTapTime=tick()
    end
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
    or i.UserInputType==Enum.UserInputType.MouseButton1 then
        if tick()-iTapTime<0.25 and not iDrag then
            icon.Visible=false
            sg:FindFirstChild("MainWin",true).Visible=true
        end
        iDrag=false
    end
end)

-- ══════════════════════════════════════════
--  MAIN WINDOW — smaller so it doesn't cover screen
-- ══════════════════════════════════════════
local win=Instance.new("Frame")
win.Name="MainWin"
win.Size=UDim2.new(0,260,0,340)   -- was 310x420, now 260x340
win.Position=UDim2.new(0,6,0.5,-170)  -- left side, not centered
win.BackgroundColor3=Color3.fromRGB(16,4,28)
win.BorderSizePixel=0
win.Parent=sg
Instance.new("UICorner",win).CornerRadius=UDim.new(0,12)

local wStroke=Instance.new("UIStroke",win)
wStroke.Color=Color3.fromRGB(120,40,200)
wStroke.Thickness=1.5
task.spawn(function()
    while true do
        TweenService:Create(wStroke,TweenInfo.new(1.4,Enum.EasingStyle.Sine),
            {Color=Color3.fromRGB(180,80,255)}):Play() task.wait(1.4)
        TweenService:Create(wStroke,TweenInfo.new(1.4,Enum.EasingStyle.Sine),
            {Color=Color3.fromRGB(70,0,140)}):Play() task.wait(1.4)
    end
end)

-- iris bg
local irisBase=Instance.new("Frame")
irisBase.Size=UDim2.new(1,0,1,0)
irisBase.BackgroundColor3=Color3.fromRGB(12,2,22)
irisBase.BorderSizePixel=0; irisBase.ZIndex=0; irisBase.Parent=win
Instance.new("UICorner",irisBase).CornerRadius=UDim.new(0,12)

for i,col in ipairs({
    Color3.fromRGB(90,0,160),Color3.fromRGB(110,10,180),
    Color3.fromRGB(70,0,130),Color3.fromRGB(50,0,100),
}) do
    local ring=Instance.new("Frame")
    local s=200-i*30
    ring.Size=UDim2.new(0,s,0,s)
    ring.Position=UDim2.new(0.5,-s/2,0.25,-s/2)
    ring.BackgroundColor3=col
    ring.BackgroundTransparency=0.75+i*0.04
    ring.BorderSizePixel=0; ring.ZIndex=1; ring.Parent=win
    Instance.new("UICorner",ring).CornerRadius=UDim.new(1,0)
end

-- pupil
local pupil=Instance.new("Frame")
pupil.Size=UDim2.new(0,44,0,44)
pupil.Position=UDim2.new(0.5,-22,0.25,-22)
pupil.BackgroundColor3=Color3.fromRGB(6,0,14)
pupil.BorderSizePixel=0; pupil.ZIndex=2; pupil.Parent=win
Instance.new("UICorner",pupil).CornerRadius=UDim.new(1,0)

-- petals
local petalColors={
    Color3.fromRGB(220,140,255),Color3.fromRGB(240,160,220),
    Color3.fromRGB(200,100,240),Color3.fromRGB(255,180,240),
}
local function spawnPetal()
    local petal=Instance.new("Frame")
    local sz=math.random(4,7)
    petal.Size=UDim2.new(0,sz,0,sz)
    petal.Position=UDim2.new(math.random(0,100)/100,-sz,0,-sz)
    petal.BackgroundColor3=petalColors[math.random(1,#petalColors)]
    petal.BackgroundTransparency=0.2
    petal.BorderSizePixel=0; petal.ZIndex=9; petal.Parent=win
    Instance.new("UICorner",petal).CornerRadius=UDim.new(1,0)
    local dur=3+math.random()*3
    task.spawn(function()
        local t=0
        while t<dur and petal.Parent do
            t=t+task.wait()
            local p=t/dur
            petal.Position=UDim2.new(
                math.clamp(petal.Position.X.Scale+math.sin(p*12)*0.003,0,1),0,p,-sz)
            petal.Rotation=p*360
            petal.BackgroundTransparency=0.2+p*0.75
        end
        if petal.Parent then petal:Destroy() end
    end)
end
task.spawn(function()
    while sg.Parent do spawnPetal(); task.wait(0.5) end
end)

-- title bar
local tBar=Instance.new("Frame")
tBar.Size=UDim2.new(1,0,0,36)
tBar.BackgroundColor3=Color3.fromRGB(14,3,26)
tBar.BackgroundTransparency=0.2
tBar.BorderSizePixel=0; tBar.ZIndex=5; tBar.Parent=win
Instance.new("UICorner",tBar).CornerRadius=UDim.new(0,12)

local tLbl=Instance.new("TextLabel")
tLbl.Size=UDim2.new(1,-80,1,0); tLbl.Position=UDim2.new(0,10,0,0)
tLbl.BackgroundTransparency=1; tLbl.Text="✦ FTP Hub"
tLbl.TextColor3=Color3.fromRGB(212,138,255)
tLbl.TextSize=11; tLbl.Font=Enum.Font.GothamBold
tLbl.TextXAlignment=Enum.TextXAlignment.Left
tLbl.ZIndex=6; tLbl.Parent=tBar

local function mkBtn(x,txt,bg,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,26); b.Position=UDim2.new(1,x,0,5)
    b.BackgroundColor3=bg; b.Text=txt; b.TextColor3=Color3.new(1,1,1)
    b.TextSize=10; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; b.ZIndex=6; b.Parent=tBar
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(cb); return b
end
mkBtn(-30,"✕",Color3.fromRGB(160,30,30),function() sg:Destroy() end)
mkBtn(-58,"—",Color3.fromRGB(20,60,180),function()
    win.Visible=false; icon.Visible=true
end)

-- drag
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
--  TABS
-- ══════════════════════════════════════════
local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,0,0,28); tabBar.Position=UDim2.new(0,0,0,36)
tabBar.BackgroundColor3=Color3.fromRGB(10,2,20)
tabBar.BackgroundTransparency=0.2
tabBar.BorderSizePixel=0; tabBar.ZIndex=5; tabBar.Parent=win
Instance.new("UIListLayout",tabBar).FillDirection=Enum.FillDirection.Horizontal

local pages={}; local tabBtns={}
local TABS={
    {id="combat",label="Combat"},
    {id="move",  label="Move"},
    {id="fps",   label="FPS"},
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
    btn.Size=UDim2.new(0,87,1,0)
    btn.BackgroundTransparency=1; btn.BorderSizePixel=0
    btn.Text=t.label; btn.TextColor3=Color3.fromRGB(100,50,150)
    btn.TextSize=10; btn.Font=Enum.Font.GothamBold
    btn.ZIndex=6; btn.Parent=tabBar
    tabBtns[t.id]=btn
    btn.MouseButton1Click:Connect(function() switchTab(t.id) end)
end

local sep=Instance.new("Frame")
sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,0,64)
sep.BackgroundColor3=Color3.fromRGB(80,20,140)
sep.BorderSizePixel=0; sep.ZIndex=5; sep.Parent=win

-- ══════════════════════════════════════════
--  PAGES
-- ══════════════════════════════════════════
local function makePage(id)
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,0,1,-66)
    scroll.Position=UDim2.new(0,0,0,66)
    scroll.BackgroundTransparency=1
    scroll.ScrollBarThickness=2
    scroll.ScrollBarImageColor3=Color3.fromRGB(140,50,220)
    scroll.CanvasSize=UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.Visible=false; scroll.ZIndex=5; scroll.Parent=win
    local lay=Instance.new("UIListLayout",scroll)
    lay.Padding=UDim.new(0,0)
    pages[id]=scroll; return scroll
end

-- ══════════════════════════════════════════
--  WIDGETS
-- ══════════════════════════════════════════
local TI=TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

local function sec(parent,txt)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,0,18); l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=Color3.fromRGB(80,30,120)
    l.TextSize=9; l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
    local p=Instance.new("UIPadding",l); p.PaddingLeft=UDim.new(0,10)
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
    row.Size=UDim2.new(1,0,0,38); row.BackgroundTransparency=1; row.ZIndex=5
    divider(parent)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-58,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(200,168,240)
    lbl.TextSize=11; lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(0,38,0,20); track.Position=UDim2.new(1,-46,0.5,-10)
    track.BackgroundColor3=Color3.fromRGB(40,8,64)
    track.BorderSizePixel=0; track.ZIndex=6
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local thumb=Instance.new("Frame",track)
    thumb.Size=UDim2.new(0,14,0,14); thumb.Position=UDim2.new(0,3,0.5,-7)
    thumb.BackgroundColor3=Color3.fromRGB(130,70,180)
    thumb.BorderSizePixel=0; thumb.ZIndex=7
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local isOn=false
    local function setOn()
        TweenService:Create(thumb,TI,{Position=UDim2.new(1,-17,0.5,-7),
            BackgroundColor3=Color3.fromRGB(200,100,255)}):Play()
        TweenService:Create(track,TI,{BackgroundColor3=Color3.fromRGB(100,0,180)}):Play()
        lbl.TextColor3=Color3.fromRGB(220,160,255)
    end
    local function setOff()
        TweenService:Create(thumb,TI,{Position=UDim2.new(0,3,0.5,-7),
            BackgroundColor3=Color3.fromRGB(130,70,180)}):Play()
        TweenService:Create(track,TI,{BackgroundColor3=Color3.fromRGB(40,8,64)}):Play()
        lbl.TextColor3=Color3.fromRGB(200,168,240)
    end
    local hit=Instance.new("TextButton",row)
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1
    hit.Text=""; hit.ZIndex=8
    hit.MouseButton1Click:Connect(function()
        isOn=not isOn; state[key]=isOn
        if isOn then setOn(); if onEn then onEn() end
        else setOff(); if onDis then onDis() end end
    end)
end

local function sliderRow(parent,label,minV,maxV,defV,suffix,onChange)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,46); row.BackgroundTransparency=1; row.ZIndex=5
    divider(parent)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.6,0,0,20); lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(200,168,240)
    lbl.TextSize=10; lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local pill=Instance.new("Frame",row)
    pill.Size=UDim2.new(0,46,0,18); pill.Position=UDim2.new(1,-54,0,4)
    pill.BackgroundColor3=Color3.fromRGB(74,0,144)
    pill.BorderSizePixel=0; pill.ZIndex=6
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local valLbl=Instance.new("TextLabel",pill)
    valLbl.Size=UDim2.new(1,0,1,0); valLbl.BackgroundTransparency=1
    valLbl.Text=tostring(defV)..suffix
    valLbl.TextColor3=Color3.fromRGB(240,200,255)
    valLbl.TextSize=9; valLbl.Font=Enum.Font.GothamBold; valLbl.ZIndex=7
    local trackBg=Instance.new("Frame",row)
    trackBg.Size=UDim2.new(1,-20,0,4); trackBg.Position=UDim2.new(0,10,0,32)
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
    th.Size=UDim2.new(0,16,0,16); th.AnchorPoint=Vector2.new(0.5,0.5)
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
    wrap.Size=UDim2.new(1,0,0,42); wrap.BackgroundTransparency=1; wrap.ZIndex=5
    local btn=Instance.new("TextButton",wrap)
    btn.Size=UDim2.new(1,-20,0,32); btn.Position=UDim2.new(0,10,0,5)
    btn.BackgroundColor3=bgCol; btn.BorderSizePixel=1
    btn.BorderColor3=borderCol; btn.Text=txt
    btn.TextColor3=txtCol; btn.TextSize=11
    btn.Font=Enum.Font.GothamBold; btn.ZIndex=8
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function mkSt(parent,col)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(1,0,0,16); l.BackgroundTransparency=1
    l.Text="Ready"; l.TextColor3=col or Color3.fromRGB(140,60,220)
    l.TextSize=10; l.Font=Enum.Font.Gotham; l.ZIndex=6
    return l
end

-- ══════════════════════════════════════════
--  GOJO SPHERES
-- ══════════════════════════════════════════
local function spawnSphere(pos,col,sz,nm)
    local p=Instance.new("Part")
    p.Name=nm; p.Shape=Enum.PartType.Ball
    p.Size=Vector3.new(sz,sz,sz); p.Position=pos
    p.Anchored=true; p.CanCollide=false; p.CastShadow=false
    p.Material=Enum.Material.Neon; p.Color=col; p.Parent=workspace
    local g=Instance.new("Part")
    g.Name=nm.."G"; g.Shape=Enum.PartType.Ball
    g.Size=Vector3.new(sz*1.5,sz*1.5,sz*1.5); g.Position=pos
    g.Anchored=true; g.CanCollide=false; g.CastShadow=false
    g.Material=Enum.Material.Neon; g.Color=col
    g.Transparency=0.7; g.Parent=workspace
    return p,g
end

local function shockwave(pos,col)
    for i=1,3 do
        task.delay(i*0.1,function()
            local r=Instance.new("Part")
            r.Shape=Enum.PartType.Ball; r.Size=Vector3.new(2,2,2)
            r.Position=pos; r.Anchored=true; r.CanCollide=false
            r.Material=Enum.Material.Neon; r.Color=col
            r.Transparency=0.3; r.Parent=workspace
            local s=tick(); local c
            c=RunService.Heartbeat:Connect(function()
                local e=tick()-s
                if e>1.2 or not r.Parent then
                    c:Disconnect(); pcall(function() r:Destroy() end); return end
                r.Size=Vector3.new(1+e*28,1+e*28,1+e*28)
                r.Transparency=0.3+(e/1.2)*0.7
            end)
        end)
    end
end

local function blastDmg(pos,rad)
    for _,p in ipairs(Players:GetPlayers()) do
        if p==localPlayer then continue end
        local ch=p.Character
        local rt=ch and ch:FindFirstChild("HumanoidRootPart")
        local hm=ch and ch:FindFirstChildOfClass("Humanoid")
        if not rt or not hm then continue end
        if (rt.Position-pos).Magnitude<=rad then
            hm.Health=0
            pcall(function() rt:SetNetworkOwner(localPlayer) end)
            rt.AssemblyLinearVelocity=(rt.Position-pos).Unit*600+Vector3.new(0,200,0)
        end
    end
end

-- ═════════
