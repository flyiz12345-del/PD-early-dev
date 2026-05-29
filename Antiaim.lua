--[[
    SKEET-STYLE ANTI-AIM UI v4.0
    
    Engines included:
       Anti-Aim (8 modes)
       Waist Pitch  (340 deg skyward tilt)
       Look-Back    (180 deg yaw flip)
       Anti-Separation Matrix (glued joints)
    Mobile friendly | Skeet.cc aesthetic
shout out to claude for organizing 
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")

-- ============================================================
-- CHARACTER REFS  (rebuild on respawn)
-- ============================================================
local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

-- per-engine caches
local originalC1s          = {}   -- waist pitch
local rootJointBaselineC1  = nil  -- look-back & anti-sep
local savedPositions       = { RootJoint=nil, Waist=nil, Head=nil }

local function cleanAndCache(char)
    character              = char
    hrp                    = char:WaitForChild("HumanoidRootPart")
    humanoid               = char:WaitForChild("Humanoid")
    rootJointBaselineC1    = nil
    table.clear(originalC1s)
    for k in pairs(savedPositions) do savedPositions[k] = nil end
end

player.CharacterAdded:Connect(cleanAndCache)
cleanAndCache(player.Character)

-- ============================================================
-- MASTER CONFIG
-- ============================================================
local CONFIG = {
    -- Anti-Aim
    antiAim    = false,
    aaMode     = "psycho",
    aaSpeed    = 5,
    aaIntensity= 1,

    -- Waist Pitch
    waistPitch = false,
    waistAngle = 340,   -- 340 deg = -20 deg backward arch

    -- Look-Back
    lookBack   = false,

    -- Anti-Separation
    antiSep    = false,
    sepWaist   = 45,
    sepHead    = 0,
}

-- ============================================================
-- SHARED JOINT FINDER (cached, refreshes on respawn)
-- ============================================================
local cachedJoints = { root=nil, waist=nil, head=nil }

local function findJoints()
    cachedJoints.root  = nil
    cachedJoints.waist = nil
    cachedJoints.head  = nil
    for _, child in ipairs(character:GetDescendants()) do
        if child:IsA("Motor6D") then
            local p0, p1 = child.Part0, child.Part1
            if p0 and p1 then
                if child.Name == "RootJoint" or p0.Name == "HumanoidRootPart" then
                    cachedJoints.root = child
                elseif child.Name == "Waist" or p1.Name == "UpperTorso" then
                    cachedJoints.waist = child
                elseif child.Name == "Neck" or p1.Name == "Head" then
                    cachedJoints.head = child
                end
            end
        end
    end
end

-- baseline C1 values (captured once, reset on respawn)
local baseC1 = { root=nil, waist=nil, head=nil }

local function captureBaselines()
    findJoints()
    if cachedJoints.root  and not baseC1.root  then baseC1.root  = cachedJoints.root.C1  end
    if cachedJoints.waist and not baseC1.waist then baseC1.waist = cachedJoints.waist.C1 end
    if cachedJoints.head  and not baseC1.head  then baseC1.head  = cachedJoints.head.C1  end
end

-- hook respawn to re-find joints
local _origClean = cleanAndCache
cleanAndCache = function(char)
    _origClean(char)
    baseC1.root  = nil
    baseC1.waist = nil
    baseC1.head  = nil
    cachedJoints.root  = nil
    cachedJoints.waist = nil
    cachedJoints.head  = nil
    task.defer(captureBaselines)
end
player.CharacterAdded:Connect(cleanAndCache)
task.defer(captureBaselines)

-- ============================================================
-- ENGINE 1 - ANTI-AIM
-- All modes go through RootJoint.C1 - NEVER touches hrp.CFrame
-- so physics/velocity are 100% preserved (no flying, no lag)
-- ============================================================
local aaTime = 0

-- returns the yaw+pitch+roll rotation CFrame to bake into RootJoint.C1
local aaModes = {
    spin = function(dt)
        aaTime = aaTime + dt
        -- accumulate raw radians so full 360 is never clamped
        local yaw = aaTime * CONFIG.aaSpeed * 8
        return 0, yaw, 0
    end,
    jitter = function(dt)
        aaTime = aaTime + dt
        local t = aaTime * CONFIG.aaSpeed
        return  math.sin(t*50) * math.rad(45)  * CONFIG.aaIntensity,
                math.cos(t*50) * math.rad(180) * CONFIG.aaIntensity,
                0
    end,
    random = function()
        return  (math.random()-.5) * math.rad(90)  * CONFIG.aaIntensity,
                (math.random()-.5) * math.rad(360) * CONFIG.aaIntensity,
                (math.random()-.5) * math.rad(45)  * CONFIG.aaIntensity
    end,
    orbital = function(dt)
        aaTime = aaTime + dt
        local t = aaTime * CONFIG.aaSpeed
        return  math.sin(t*3) * math.rad(30) * CONFIG.aaIntensity,
                t * 8,
                math.cos(t*3) * math.rad(30) * CONFIG.aaIntensity
    end,
    glitch = function(dt)
        aaTime = aaTime + dt
        local f = math.floor(aaTime * CONFIG.aaSpeed * 8) % 4
        local pitches = {0, math.rad(45), math.rad(-45), 0}
        return  pitches[f+1] * CONFIG.aaIntensity,
                f * math.rad(90) + (math.random()-.5) * math.rad(45) * CONFIG.aaIntensity,
                0
    end,
    psycho = function(dt)
        aaTime = aaTime + dt
        local s = aaTime * CONFIG.aaSpeed * 10
        return  math.sin(s) * math.rad(45) * CONFIG.aaIntensity
                    + (math.random()-.5) * math.rad(90) * CONFIG.aaIntensity,
                s * 10 + math.cos(aaTime*50) * math.rad(180),
                math.cos(s) * math.rad(45) * CONFIG.aaIntensity
    end,
    earthquake = function(dt)
        aaTime = aaTime + dt
        local t = aaTime * CONFIG.aaSpeed
        return  math.sin(t*30) * math.rad(20) * CONFIG.aaIntensity * math.random(),
                t * 6,
                math.cos(t*30) * math.rad(20) * CONFIG.aaIntensity * math.random()
    end,
    matrix = function(dt)
        aaTime = aaTime + dt
        local w = math.sin(aaTime*2) * math.rad(15) * CONFIG.aaIntensity
        return w, aaTime * CONFIG.aaSpeed * 0.5, -w
    end,
}

RunService:BindToRenderStep("SkeetAntiAim", Enum.RenderPriority.Last.Value - 2, function(dt)
    if not CONFIG.antiAim then return end
    captureBaselines()
    local rj = cachedJoints.root
    if not rj or not baseC1.root then return end

    local fn = aaModes[CONFIG.aaMode]
    if not fn then return end

    local rx, ry, rz = fn(dt)
    -- inject into RootJoint - physics body (HRP) is never touched
    rj.C1 = CFrame.Angles(rx, ry, rz) * baseC1.root
end)

-- ============================================================
-- ENGINE 2 - WAIST PITCH  (340 deg skyward tilt)
-- Uses Waist joint C1 only - no hrp.CFrame, no velocity loss
-- ============================================================
RunService:BindToRenderStep("SkeetWaistPitch", Enum.RenderPriority.Last.Value - 1, function()
    captureBaselines()
    local wj = cachedJoints.waist
    if not wj or not baseC1.waist then return end

    if not CONFIG.waistPitch then
        -- restore baseline
        wj.C1 = baseC1.waist
        return
    end
    wj.C1 = baseC1.waist * CFrame.Angles(math.rad(CONFIG.waistAngle), 0, 0)
end)

-- ============================================================
-- ENGINE 3 - LOOK-BACK  (180 deg yaw flip)
-- ============================================================
RunService:BindToRenderStep("SkeetLookBack", Enum.RenderPriority.Last.Value, function()
    if not CONFIG.lookBack then return end
    captureBaselines()
    local rj = cachedJoints.root
    if not rj or not baseC1.root then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local _, camYaw, _ = camera.CFrame:ToEulerAnglesYXZ()
    local _, hrpYaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
    -- 180 deg flip: character faces away from camera direction
    rj.C1 = CFrame.Angles(0, (camYaw - hrpYaw) + math.pi, 0) * baseC1.root
end)

-- ============================================================
-- ENGINE 4 - ANTI-SEPARATION MATRIX (glued joints)
-- Uses shared joint cache - no hrp.CFrame, no flying
-- ============================================================
RunService:BindToRenderStep("SkeetAntiSep", Enum.RenderPriority.Last.Value + 1, function()
    if not CONFIG.antiSep then return end
    captureBaselines()

    local rj = cachedJoints.root
    local wj = cachedJoints.waist
    local hj = cachedJoints.head
    local camera = workspace.CurrentCamera
    if not camera then return end

    local _, camYaw, _ = camera.CFrame:ToEulerAnglesYXZ()
    local _, hrpYaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
    local relYaw = camYaw - hrpYaw

    if rj and baseC1.root then
        rj.C1 = CFrame.Angles(0, relYaw, 0) * baseC1.root
    end
    if wj and baseC1.waist then
        wj.C1 = CFrame.new(baseC1.waist.Position)
            * CFrame.Angles(math.rad(CONFIG.sepWaist), 0, 0)
    end
    if hj and baseC1.head then
        hj.C1 = CFrame.new(baseC1.head.Position)
            * CFrame.Angles(math.rad(CONFIG.sepHead), 0, 0)
    end
end)

-- ============================================================
-- GUI - Skeet.cc aesthetic, mobile-friendly
-- ============================================================
local C = {
    BG       = Color3.fromRGB(14, 14, 18),
    PANEL    = Color3.fromRGB(20, 20, 25),
    HEADER   = Color3.fromRGB(17, 17, 22),
    ACCENT   = Color3.fromRGB(210, 40, 40),
    ACCENT2  = Color3.fromRGB(235, 60, 60),
    SEP      = Color3.fromRGB(35, 35, 42),
    TEXT     = Color3.fromRGB(220, 220, 220),
    SUB      = Color3.fromRGB(120, 120, 135),
    ROW      = Color3.fromRGB(22, 22, 28),
    ON       = Color3.fromRGB(210, 40, 40),
    OFF      = Color3.fromRGB(55, 55, 65),
    FONT     = Enum.Font.GothamBold,
    FONTR    = Enum.Font.Gotham,
}

local function corner(r,p) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p end
local function stroke(t,cl,p) local s=Instance.new("UIStroke") s.Thickness=t s.Color=cl s.Parent=p end
local function tw(obj,props,dur)
    TweenService:Create(obj,TweenInfo.new(dur or .15,Enum.EasingStyle.Quad),props):Play()
end

local gui = Instance.new("ScreenGui")
gui.Name="SkeetUI" gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset=true
gui.Parent=player.PlayerGui

-- watermark
local wm=Instance.new("TextLabel")
wm.Size=UDim2.new(0,185,0,22) wm.Position=UDim2.new(1,-193,0,8)
wm.BackgroundColor3=C.BG wm.BorderSizePixel=0
wm.Text=" volatile.tech | anti-aim v4" wm.TextColor3=C.ACCENT
wm.TextSize=11 wm.Font=C.FONT wm.TextXAlignment=Enum.TextXAlignment.Center
wm.Parent=gui corner(4,wm) stroke(1,C.SEP,wm)

-- FAB
local fab=Instance.new("TextButton")
fab.Size=UDim2.new(0,52,0,52) fab.Position=UDim2.new(0,14,0.5,-26)
fab.BackgroundColor3=C.ACCENT fab.BorderSizePixel=0
fab.Text="Menu" fab.TextColor3=Color3.new(1,1,1) fab.TextSize=22
fab.Font=C.FONT fab.ZIndex=20 fab.Parent=gui
corner(12,fab) stroke(1.5,C.ACCENT2,fab)

-- main window
local win=Instance.new("Frame")
win.Name="Win" win.Size=UDim2.new(0,315,0,0)
win.Position=UDim2.new(0,76,0.5,-300)
win.BackgroundColor3=C.BG win.BorderSizePixel=0
win.Visible=false win.ZIndex=10 win.AutomaticSize=Enum.AutomaticSize.Y
win.Parent=gui corner(8,win) stroke(1,C.SEP,win)

local abar=Instance.new("Frame")
abar.Size=UDim2.new(1,0,0,3) abar.BackgroundColor3=C.ACCENT
abar.BorderSizePixel=0 abar.ZIndex=11 abar.Parent=win corner(8,abar)

-- header
local hdr=Instance.new("Frame")
hdr.Size=UDim2.new(1,0,0,46) hdr.Position=UDim2.new(0,0,0,3)
hdr.BackgroundColor3=C.HEADER hdr.BorderSizePixel=0 hdr.ZIndex=11 hdr.Parent=win

local function lbl(txt,sz,col,parent,x,y,w,h,font,xa)
    local l=Instance.new("TextLabel")
    l.Text=txt l.TextSize=sz l.TextColor3=col
    l.Size=UDim2.new(w or 1,0,0,h or 20)
    l.Position=UDim2.new(0,x or 0,0,y or 0)
    l.BackgroundTransparency=1 l.BorderSizePixel=0
    l.Font=font or C.FONTR
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.ZIndex=13 l.Parent=parent return l
end

lbl("ANTI-AIM",15,C.TEXT,hdr,14,8,0.7,20,C.FONT)
lbl("ragebot  anti-aim",11,C.SUB,hdr,14,28,0.7,14)

local closeBt=Instance.new("TextButton")
closeBt.Size=UDim2.new(0,30,0,30) closeBt.Position=UDim2.new(1,-38,0.5,-15)
closeBt.BackgroundColor3=C.ROW closeBt.BorderSizePixel=0
closeBt.Text="X" closeBt.TextColor3=C.SUB closeBt.TextSize=14
closeBt.Font=C.FONT closeBt.ZIndex=13 closeBt.Parent=hdr corner(6,closeBt)

local sep0=Instance.new("Frame")
sep0.Size=UDim2.new(1,0,0,1) sep0.Position=UDim2.new(0,0,0,49)
sep0.BackgroundColor3=C.SEP sep0.BorderSizePixel=0 sep0.ZIndex=11 sep0.Parent=win

-- scroll
local scroll=Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,0,0,480)
scroll.Position=UDim2.new(0,0,0,53)
scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0
scroll.ScrollBarThickness=3 scroll.ScrollBarImageColor3=C.ACCENT
scroll.CanvasSize=UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.ZIndex=11 scroll.Parent=win

local ll=Instance.new("UIListLayout")
ll.SortOrder=Enum.SortOrder.LayoutOrder ll.Padding=UDim.new(0,0)
ll.Parent=scroll
local lpad=Instance.new("UIPadding")
lpad.PaddingBottom=UDim.new(0,14) lpad.Parent=scroll

--  helpers 
local lo=0
local function nextLO() lo=lo+1 return lo end

local function secHead(txt)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,28) f.BackgroundTransparency=1
    f.BorderSizePixel=0 f.LayoutOrder=nextLO() f.ZIndex=12 f.Parent=scroll
    local t=Instance.new("TextLabel")
    t.Size=UDim2.new(1,-20,1,0) t.Position=UDim2.new(0,14,0,0)
    t.BackgroundTransparency=1 t.Text=txt:upper()
    t.TextColor3=C.ACCENT t.TextSize=9 t.Font=C.FONT
    t.TextXAlignment=Enum.TextXAlignment.Left t.ZIndex=13 t.Parent=f
    local ln=Instance.new("Frame")
    ln.Size=UDim2.new(1,-28,0,1) ln.Position=UDim2.new(0,14,1,-1)
    ln.BackgroundColor3=C.SEP ln.BorderSizePixel=0 ln.ZIndex=12 ln.Parent=f
end

local function pillToggle(parent, initVal, callback)
    local pill=Instance.new("Frame")
    pill.Size=UDim2.new(0,40,0,22) pill.Position=UDim2.new(1,-52,0.5,-11)
    pill.BackgroundColor3=initVal and C.ON or C.OFF
    pill.BorderSizePixel=0 pill.ZIndex=14 pill.Parent=parent corner(11,pill)
    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,16,0,16)
    knob.Position=initVal and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    knob.BackgroundColor3=Color3.new(1,1,1) knob.BorderSizePixel=0
    knob.ZIndex=15 knob.Parent=pill corner(8,knob)

    local state=initVal
    local hitbox=Instance.new("TextButton")
    hitbox.Size=UDim2.new(1,0,1,0) hitbox.BackgroundTransparency=1
    hitbox.Text="" hitbox.ZIndex=16 hitbox.Parent=pill
    hitbox.MouseButton1Click:Connect(function()
        state=not state
        tw(pill,{BackgroundColor3=state and C.ON or C.OFF})
        tw(knob,{Position=state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)})
        callback(state)
    end)
    return pill
end

local function toggleRow(txt,desc,initVal,callback)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,52) row.BackgroundTransparency=1
    row.BorderSizePixel=0 row.LayoutOrder=nextLO() row.ZIndex=12 row.Parent=scroll
    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(1,-28,1,-8) bg.Position=UDim2.new(0,14,0,4)
    bg.BackgroundColor3=C.ROW bg.BorderSizePixel=0 bg.ZIndex=13 bg.Parent=row
    corner(6,bg) stroke(1,C.SEP,bg)
    lbl(txt,13,C.TEXT,bg,12,7,0.75,18,C.FONT)
    lbl(desc,10,C.SUB,bg,12,25,0.75,14)
    pillToggle(bg,initVal,callback)
end

local function sliderRow(txt,min,max,init,callback)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,62) row.BackgroundTransparency=1
    row.BorderSizePixel=0 row.LayoutOrder=nextLO() row.ZIndex=12 row.Parent=scroll
    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(1,-28,1,-8) bg.Position=UDim2.new(0,14,0,4)
    bg.BackgroundColor3=C.ROW bg.BorderSizePixel=0 bg.ZIndex=13 bg.Parent=row
    corner(6,bg) stroke(1,C.SEP,bg)
    lbl(txt,13,C.TEXT,bg,12,7,0.6,18,C.FONT)
    local valL=lbl(tostring(init),13,C.ACCENT,bg,0,7,0.88,18,C.FONT,Enum.TextXAlignment.Right)
    local track=Instance.new("Frame")
    track.Size=UDim2.new(1,-24,0,5) track.Position=UDim2.new(0,12,0,34)
    track.BackgroundColor3=C.SEP track.BorderSizePixel=0 track.ZIndex=14 track.Parent=bg
    corner(3,track)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((init-min)/(max-min),0,1,0)
    fill.BackgroundColor3=C.ACCENT fill.BorderSizePixel=0 fill.ZIndex=15 fill.Parent=track
    corner(3,fill)
    local handle=Instance.new("TextButton")
    handle.Size=UDim2.new(0,22,0,22) handle.AnchorPoint=Vector2.new(0.5,0.5)
    handle.Position=UDim2.new((init-min)/(max-min),0,0.5,0)
    handle.BackgroundColor3=C.ACCENT handle.BorderSizePixel=0
    handle.Text="" handle.ZIndex=16 handle.Parent=track
    corner(11,handle) stroke(2,Color3.new(1,1,1),handle)
    local drag=false
    handle.MouseButton1Down:Connect(function() drag=true end)
    handle.TouchLongPress:Connect(function() drag=true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    RunService.RenderStepped:Connect(function()
        if not drag then return end
        local mx=player:GetMouse().X
        local rel=math.clamp(mx-track.AbsolutePosition.X,0,track.AbsoluteSize.X)
        local pct=rel/track.AbsoluteSize.X
        local val=math.floor((min+(max-min)*pct)*10)/10
        fill.Size=UDim2.new(pct,0,1,0)
        handle.Position=UDim2.new(pct,0,0.5,0)
        valL.Text=tostring(val)
        callback(val)
    end)
end

local function modeGrid(modeList,getMode,setMode)
    local cols=2
    local rows=math.ceil(#modeList/cols)
    local container=Instance.new("Frame")
    container.Size=UDim2.new(1,0,0,rows*40+8)
    container.BackgroundTransparency=1 container.BorderSizePixel=0
    container.LayoutOrder=nextLO() container.ZIndex=12 container.Parent=scroll
    local btns={}
    for i,m in ipairs(modeList) do
        local col=(i-1)%cols
        local row=math.floor((i-1)/cols)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0.44,0,0,32) b.BorderSizePixel=0
        b.Position=UDim2.new(0.04+col*0.5,0,0,row*40+4)
        b.BackgroundColor3=m==getMode() and C.ACCENT or C.ROW
        b.TextColor3=m==getMode() and Color3.new(1,1,1) or C.SUB
        b.Text=m:upper() b.TextSize=10 b.Font=C.FONT
        b.ZIndex=13 b.Parent=container
        corner(6,b)
        if m~=getMode() then stroke(1,C.SEP,b) end
        btns[m]=b
        b.MouseButton1Click:Connect(function()
            for _,x in pairs(btns) do
                tw(x,{BackgroundColor3=C.ROW,TextColor3=C.SUB})
            end
            tw(b,{BackgroundColor3=C.ACCENT,TextColor3=Color3.new(1,1,1)})
            setMode(m) aaTime=0
        end)
    end
end

-- ============================================================
-- BUILD THE PANEL
-- ============================================================

-- -- ANTI-AIM
secHead("Anti-Aim")
toggleRow("Anti-Aim","8 anti-aim modes",CONFIG.antiAim,function(v) CONFIG.antiAim=v aaTime=0 end)
modeGrid(
    {"spin","jitter","random","orbital","glitch","psycho","earthquake","matrix"},
    function() return CONFIG.aaMode end,
    function(m) CONFIG.aaMode=m end)
sliderRow("Speed",0.1,10,CONFIG.aaSpeed,function(v) CONFIG.aaSpeed=v end)
sliderRow("Intensity",0.1,3,CONFIG.aaIntensity,function(v) CONFIG.aaIntensity=v end)

-- -- WAIST PITCH
secHead("Waist Pitch")
toggleRow("Waist Pitch","340 deg skyward tilt (-20 deg arch)",CONFIG.waistPitch,function(v)
    CONFIG.waistPitch=v
    if not v then
        for joint,origC1 in pairs(originalC1s) do
            if joint and joint.Parent then joint.C1=origC1 end
        end
    end
end)
sliderRow("Waist Angle",0,360,CONFIG.waistAngle,function(v) CONFIG.waistAngle=v end)
 
-- -- LOOK-BACK
secHead("Look-Back")
toggleRow("Look-Back","180 deg yaw flip on rootjoint",CONFIG.lookBack,function(v)
    CONFIG.lookBack=v
    if not v then rootJointBaselineC1=nil end
end)
-- -- ANTI-SEPARATION
secHead("Anti-Separation")
toggleRow("Anti-Sep Matrix","Glued joints, blocks separation",CONFIG.antiSep,function(v)
    CONFIG.antiSep=v
    if not v then
        rootJointBaselineC1=nil
        for k in pairs(savedPositions) do savedPositions[k]=nil end
    end
end)
sliderRow("Waist Angle",0,90,CONFIG.sepWaist,function(v) CONFIG.sepWaist=v end)
sliderRow("Head Angle",-45,45,CONFIG.sepHead,function(v) CONFIG.sepHead=v end)
 
-- ============================================================
-- FAB / CLOSE / DRAG
-- ============================================================
fab.MouseButton1Click:Connect(function()
    win.Visible=not win.Visible
    tw(fab,{BackgroundColor3=win.Visible and C.ROW or C.ACCENT})
end)
closeBt.MouseButton1Click:Connect(function()
    win.Visible=false tw(fab,{BackgroundColor3=C.ACCENT})
end)
 
do
  local drag,ds,sp=false,nil,nil
    hdr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true ds=i.Position sp=win.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end
 
print("[skeet-ui v4] Loaded - tap Menu to open panel")
print("  Engines: Anti-Aim | Waist-Pitch | Look-Back | Anti-Sep")
