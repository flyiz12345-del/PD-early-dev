--[[
    SKEET-STYLE ANTI-AIM UI v3.0
    Mobile Friendly | Skeet.cc Aesthetic
    Private server use only
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    enabled   = false,
    mode      = "psycho",
    speed     = 5,
    intensity = 1,
}

-- ============================================================
-- ANTI-AIM ENGINE
-- ============================================================
local t = 0
local modes = {
    spin = function(dt)
        t = t + dt
        return CFrame.Angles(0, math.rad(t * CONFIG.speed * 500), 0)
    end,
    jitter = function(dt)
        t = t + dt
        return CFrame.Angles(
            math.rad(math.sin(t * CONFIG.speed * 50) * 45 * CONFIG.intensity),
            math.rad(math.cos(t * CONFIG.speed * 50) * 180 * CONFIG.intensity), 0)
    end,
    random = function()
        return CFrame.Angles(
            math.rad((math.random()-.5)*90*CONFIG.intensity),
            math.rad((math.random()-.5)*360*CONFIG.intensity),
            math.rad((math.random()-.5)*45*CONFIG.intensity))
    end,
    orbital = function(dt)
        t = t + dt
        return CFrame.Angles(
            math.rad(math.sin(t*CONFIG.speed*3)*30*CONFIG.intensity),
            math.rad(t*CONFIG.speed*500),
            math.rad(math.cos(t*CONFIG.speed*3)*30*CONFIG.intensity))
    end,
    glitch = function(dt)
        t = t + dt
        local f = math.floor(t*20)%4
        return CFrame.Angles(
            math.rad(({0,45,-45,0})[f+1]*CONFIG.intensity),
            math.rad(f*90 + (math.random()-.5)*45*CONFIG.intensity), 0)
    end,
    psycho = function(dt)
        t = t + dt
        local s = t*CONFIG.speed*10
        return CFrame.Angles(
            math.rad(math.sin(s)*45*CONFIG.intensity + (math.random()-.5)*90*CONFIG.intensity),
            math.rad(s*100 + math.cos(t*50)*180),
            math.rad(math.cos(s)*45*CONFIG.intensity))
    end,
    earthquake = function(dt)
        t = t + dt
        return CFrame.Angles(
            math.rad(math.sin(t*CONFIG.speed*30)*20*CONFIG.intensity*math.random()),
            math.rad(t*CONFIG.speed*100%360),
            math.rad(math.cos(t*CONFIG.speed*30)*20*CONFIG.intensity*math.random()))
    end,
    matrix = function(dt)
        t = t + dt
        local w = math.sin(t*2)*15*CONFIG.intensity
        return CFrame.Angles(math.rad(w), math.rad(t*CONFIG.speed*15), math.rad(-w))
    end,
}

RunService.RenderStepped:Connect(function(dt)
    if not CONFIG.enabled then return end
    local fn = modes[CONFIG.mode]
    if fn then
        hrp.CFrame = CFrame.new(hrp.Position) * fn(dt)
    end
end)

-- ============================================================
-- GUI  (Skeet.cc aesthetic, mobile-friendly)
-- ============================================================
local C = {
    BG        = Color3.fromRGB(14,  14, 18),
    PANEL     = Color3.fromRGB(20,  20, 25),
    HEADER    = Color3.fromRGB(17,  17, 22),
    ACCENT    = Color3.fromRGB(210,  40, 40),    -- skeet red
    ACCENT2   = Color3.fromRGB(235,  60, 60),
    SEP       = Color3.fromRGB(35,  35, 42),
    TEXT      = Color3.fromRGB(220, 220, 220),
    SUBTEXT   = Color3.fromRGB(120, 120, 135),
    ACTIVE_BG = Color3.fromRGB(30,  30, 38),
    ON        = Color3.fromRGB(210,  40, 40),
    OFF       = Color3.fromRGB(55,  55, 65),
    FONT      = Enum.Font.GothamBold,
    FONT_REG  = Enum.Font.Gotham,
}

local function corner(r, p) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p end
local function stroke(t,clr,p) local s=Instance.new("UIStroke") s.Thickness=t s.Color=clr s.Parent=p end
local function tween(obj,props,dur,es)
    TweenService:Create(obj,TweenInfo.new(dur or .15,es or Enum.EasingStyle.Quad),props):Play()
end

local gui = Instance.new("ScreenGui")
gui.Name            = "SkeetUI"
gui.ResetOnSpawn    = false
gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset  = true
gui.Parent          = player.PlayerGui

-- ── Watermark ─────────────────────────────────────────────
local wm = Instance.new("TextLabel")
wm.Size              = UDim2.new(0,180,0,22)
wm.Position          = UDim2.new(1,-190,0,8)
wm.BackgroundColor3  = C.BG
wm.BorderSizePixel   = 0
wm.Text              = "skeet.cc  |  anti-aim"
wm.TextColor3        = C.ACCENT
wm.TextSize          = 12
wm.Font              = C.FONT
wm.TextXAlignment    = Enum.TextXAlignment.Center
wm.Parent            = gui
corner(4, wm)
stroke(1, C.SEP, wm)

-- ── Floating toggle button (mobile tap) ───────────────────
local fab = Instance.new("TextButton")
fab.Size             = UDim2.new(0,52,0,52)
fab.Position         = UDim2.new(0,14,0.5,-26)
fab.BackgroundColor3 = C.ACCENT
fab.BorderSizePixel  = 0
fab.Text             = "☰"
fab.TextColor3       = Color3.new(1,1,1)
fab.TextSize         = 22
fab.Font             = C.FONT
fab.ZIndex           = 20
fab.Parent           = gui
corner(12, fab)
stroke(1.5, C.ACCENT2, fab)

-- ── Main window ───────────────────────────────────────────
local win = Instance.new("Frame")
win.Name             = "Window"
win.Size             = UDim2.new(0,310,0,520)
win.Position         = UDim2.new(0,76,0.5,-260)
win.BackgroundColor3 = C.BG
win.BorderSizePixel  = 0
win.Visible          = false
win.ZIndex           = 10
win.Parent           = gui
corner(8, win)
stroke(1, C.SEP, win)

-- accent bar at top
local accentBar = Instance.new("Frame")
accentBar.Size            = UDim2.new(1,0,0,3)
accentBar.BackgroundColor3= C.ACCENT
accentBar.BorderSizePixel = 0
accentBar.ZIndex          = 11
accentBar.Parent          = win
corner(8, accentBar)  -- only top corners matter visually

-- ── Header ───────────────────────────────────────────────
local header = Instance.new("Frame")
header.Size             = UDim2.new(1,0,0,46)
header.Position         = UDim2.new(0,0,0,3)
header.BackgroundColor3 = C.HEADER
header.BorderSizePixel  = 0
header.ZIndex           = 11
header.Parent           = win

local titleLbl = Instance.new("TextLabel")
titleLbl.Size            = UDim2.new(1,-60,1,0)
titleLbl.Position        = UDim2.new(0,14,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text            = "ANTI-AIM"
titleLbl.TextColor3      = C.TEXT
titleLbl.TextSize        = 15
titleLbl.Font            = C.FONT
titleLbl.TextXAlignment  = Enum.TextXAlignment.Left
titleLbl.ZIndex          = 12
titleLbl.Parent          = header

local subtitleLbl = Instance.new("TextLabel")
subtitleLbl.Size            = UDim2.new(1,-60,0,16)
subtitleLbl.Position        = UDim2.new(0,14,1,-20)
subtitleLbl.BackgroundTransparency = 1
subtitleLbl.Text            = "ragebot › anti-aim"
subtitleLbl.TextColor3      = C.SUBTEXT
subtitleLbl.TextSize        = 11
subtitleLbl.Font            = C.FONT_REG
subtitleLbl.TextXAlignment  = Enum.TextXAlignment.Left
subtitleLbl.ZIndex          = 12
subtitleLbl.Parent          = header

-- close btn
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0,30,0,30)
closeBtn.Position         = UDim2.new(1,-38,0.5,-15)
closeBtn.BackgroundColor3 = C.ACTIVE_BG
closeBtn.BorderSizePixel  = 0
closeBtn.Text             = "✕"
closeBtn.TextColor3       = C.SUBTEXT
closeBtn.TextSize         = 14
closeBtn.Font             = C.FONT
closeBtn.ZIndex           = 13
closeBtn.Parent           = header
corner(6, closeBtn)

-- separator under header
local sep0 = Instance.new("Frame")
sep0.Size             = UDim2.new(1,0,0,1)
sep0.Position         = UDim2.new(0,0,0,49)
sep0.BackgroundColor3 = C.SEP
sep0.BorderSizePixel  = 0
sep0.ZIndex           = 11
sep0.Parent           = win

-- ── Scroll container ─────────────────────────────────────
local scroll = Instance.new("ScrollingFrame")
scroll.Size                  = UDim2.new(1,0,1,-53)
scroll.Position              = UDim2.new(0,0,0,53)
scroll.BackgroundTransparency= 1
scroll.BorderSizePixel       = 0
scroll.ScrollBarThickness    = 3
scroll.ScrollBarImageColor3  = C.ACCENT
scroll.CanvasSize            = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
scroll.ZIndex                = 11
scroll.Parent                = win

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder  = Enum.SortOrder.LayoutOrder
listLayout.Padding    = UDim.new(0,0)
listLayout.Parent     = scroll

local padding = Instance.new("UIPadding")
padding.PaddingBottom = UDim.new(0,12)
padding.Parent        = scroll

-- ── Helper: section header ────────────────────────────────
local function sectionHeader(text, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1,0,0,30)
    f.BackgroundTransparency = 1
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order
    f.ZIndex           = 12
    f.Parent           = scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1,-20,1,0)
    lbl.Position          = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = text:upper()
    lbl.TextColor3        = C.ACCENT
    lbl.TextSize          = 10
    lbl.Font              = C.FONT
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.LetterSpacingUnits = Enum.FontSizeConstraint.RelativeSize
    lbl.ZIndex            = 13
    lbl.Parent            = f

    local line = Instance.new("Frame")
    line.Size             = UDim2.new(1,-28,0,1)
    line.Position         = UDim2.new(0,14,1,-1)
    line.BackgroundColor3 = C.SEP
    line.BorderSizePixel  = 0
    line.ZIndex           = 12
    line.Parent           = f
    return f
end

-- ── Helper: toggle row ────────────────────────────────────
local function toggleRow(text, desc, initVal, order, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1,0,0,54)
    row.BackgroundTransparency = 1
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.ZIndex           = 12
    row.Parent           = scroll

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1,-28,1,-10)
    btn.Position         = UDim2.new(0,14,0,5)
    btn.BackgroundColor3 = C.ACTIVE_BG
    btn.BorderSizePixel  = 0
    btn.Text             = ""
    btn.ZIndex           = 13
    btn.Parent           = row
    corner(6, btn)
    stroke(1, C.SEP, btn)

    local nameL = Instance.new("TextLabel")
    nameL.Size              = UDim2.new(1,-60,0,20)
    nameL.Position          = UDim2.new(0,12,0,8)
    nameL.BackgroundTransparency = 1
    nameL.Text              = text
    nameL.TextColor3        = C.TEXT
    nameL.TextSize          = 13
    nameL.Font              = C.FONT
    nameL.TextXAlignment    = Enum.TextXAlignment.Left
    nameL.ZIndex            = 14
    nameL.Parent            = btn

    local descL = Instance.new("TextLabel")
    descL.Size              = UDim2.new(1,-60,0,14)
    descL.Position          = UDim2.new(0,12,0,27)
    descL.BackgroundTransparency = 1
    descL.Text              = desc
    descL.TextColor3        = C.SUBTEXT
    descL.TextSize          = 10
    descL.Font              = C.FONT_REG
    descL.TextXAlignment    = Enum.TextXAlignment.Left
    descL.ZIndex            = 14
    descL.Parent            = btn

    -- pill toggle
    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0,40,0,22)
    pill.Position         = UDim2.new(1,-52,0.5,-11)
    pill.BackgroundColor3 = initVal and C.ON or C.OFF
    pill.BorderSizePixel  = 0
    pill.ZIndex           = 14
    pill.Parent           = btn
    corner(11, pill)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0,16,0,16)
    knob.Position         = initVal and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 15
    knob.Parent           = pill
    corner(8, knob)

    local state = initVal
    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(pill, {BackgroundColor3 = state and C.ON or C.OFF})
        tween(knob, {Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)})
        callback(state)
    end)

    return row
end

-- ── Helper: slider row ────────────────────────────────────
local function sliderRow(text, min, max, init, order, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1,0,0,66)
    row.BackgroundTransparency = 1
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.ZIndex           = 12
    row.Parent           = scroll

    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(1,-28,1,-10)
    bg.Position         = UDim2.new(0,14,0,5)
    bg.BackgroundColor3 = C.ACTIVE_BG
    bg.BorderSizePixel  = 0
    bg.ZIndex           = 13
    bg.Parent           = row
    corner(6, bg)
    stroke(1, C.SEP, bg)

    local nameL = Instance.new("TextLabel")
    nameL.Size              = UDim2.new(0.6,0,0,20)
    nameL.Position          = UDim2.new(0,12,0,8)
    nameL.BackgroundTransparency = 1
    nameL.Text              = text
    nameL.TextColor3        = C.TEXT
    nameL.TextSize          = 13
    nameL.Font              = C.FONT
    nameL.TextXAlignment    = Enum.TextXAlignment.Left
    nameL.ZIndex            = 14
    nameL.Parent            = bg

    local valL = Instance.new("TextLabel")
    valL.Size              = UDim2.new(0.35,0,0,20)
    valL.Position          = UDim2.new(0.65,0,0,8)
    valL.BackgroundTransparency = 1
    valL.Text              = tostring(init)
    valL.TextColor3        = C.ACCENT
    valL.TextSize          = 13
    valL.Font              = C.FONT
    valL.TextXAlignment    = Enum.TextXAlignment.Right
    valL.ZIndex            = 14
    valL.Parent            = bg

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1,-24,0,5)
    track.Position         = UDim2.new(0,12,0,36)
    track.BackgroundColor3 = C.SEP
    track.BorderSizePixel  = 0
    track.ZIndex           = 14
    track.Parent           = bg
    corner(3, track)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((init-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = C.ACCENT
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 15
    fill.Parent           = track
    corner(3, fill)

    -- drag handle (bigger for mobile)
    local handle = Instance.new("TextButton")
    handle.Size             = UDim2.new(0,22,0,22)
    handle.AnchorPoint      = Vector2.new(0.5,0.5)
    handle.Position         = UDim2.new((init-min)/(max-min),0,0.5,0)
    handle.BackgroundColor3 = C.ACCENT
    handle.BorderSizePixel  = 0
    handle.Text             = ""
    handle.ZIndex           = 16
    handle.Parent           = track
    corner(11, handle)
    stroke(2, Color3.new(1,1,1), handle)

    local dragging = false
    handle.MouseButton1Down:Connect(function() dragging=true end)
    handle.TouchLongPress:Connect(function() dragging=true end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not dragging then return end
        local mouse = player:GetMouse()
        local rel = math.clamp(mouse.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
        local pct = rel / track.AbsoluteSize.X
        local val = math.floor((min + (max-min)*pct)*10)/10
        fill.Size = UDim2.new(pct,0,1,0)
        handle.Position = UDim2.new(pct,0,0.5,0)
        valL.Text = tostring(val)
        callback(val)
    end)

    return row
end

-- ── Helper: mode selector ─────────────────────────────────
local modeList   = {"spin","jitter","random","orbital","glitch","psycho","earthquake","matrix"}
local modeButtons= {}

local function modeSelector(order)
    local container = Instance.new("Frame")
    container.Size             = UDim2.new(1,0,0,10 + math.ceil(#modeList/2)*42)
    container.BackgroundTransparency = 1
    container.BorderSizePixel  = 0
    container.LayoutOrder      = order
    container.ZIndex           = 12
    container.Parent           = scroll

    for i, m in ipairs(modeList) do
        local col = (i-1)%2
        local row2= math.floor((i-1)/2)

        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0.44,0,0,34)
        btn.Position         = UDim2.new(0.04 + col*0.5, 0, 0, row2*42+4)
        btn.BackgroundColor3 = m==CONFIG.mode and C.ACCENT or C.ACTIVE_BG
        btn.BorderSizePixel  = 0
        btn.Text             = m:upper()
        btn.TextColor3       = m==CONFIG.mode and Color3.new(1,1,1) or C.SUBTEXT
        btn.TextSize         = 11
        btn.Font             = C.FONT
        btn.ZIndex           = 13
        btn.Parent           = container
        corner(6, btn)
        if m~=CONFIG.mode then stroke(1, C.SEP, btn) end

        modeButtons[m] = btn

        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(modeButtons) do
                tween(b, {BackgroundColor3=C.ACTIVE_BG, TextColor3=C.SUBTEXT})
            end
            tween(btn, {BackgroundColor3=C.ACCENT, TextColor3=Color3.new(1,1,1)})
            CONFIG.mode = m
            t = 0
        end)
    end
    return container
end

-- ── Build layout ──────────────────────────────────────────
sectionHeader("General", 1)
toggleRow("Anti-Aim", "Enable anti-aim engine", false, 2, function(v)
    CONFIG.enabled = v
    t = 0
end)

sectionHeader("Mode", 3)
modeSelector(4)

sectionHeader("Parameters", 5)
sliderRow("Speed",     0.1, 10, CONFIG.speed,     6, function(v) CONFIG.speed=v end)
sliderRow("Intensity", 0.1,  3, CONFIG.intensity, 7, function(v) CONFIG.intensity=v end)

-- ── FAB toggle ────────────────────────────────────────────
fab.MouseButton1Click:Connect(function()
    win.Visible = not win.Visible
    tween(fab, {BackgroundColor3 = win.Visible and C.ACTIVE_BG or C.ACCENT})
end)

closeBtn.MouseButton1Click:Connect(function()
    win.Visible = false
    tween(fab, {BackgroundColor3 = C.ACCENT})
end)

-- ── Drag window ───────────────────────────────────────────
do
    local drag, ds, sp = false, nil, nil
    header.InputBegan:Connect(function(i)
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

print("[skeet-ui] loaded — tap ☰ to open")
