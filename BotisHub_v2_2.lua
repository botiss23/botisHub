--[[
    ══════════════════════════════════════════════════════════
     BOTIS HUB  •  Universal Roblox LocalScript  v2.2
     Hafif • Toggle'lı • PC + Mobil • Tamamen istemci taraflı
     Menü: RightShift  |  Mobil: "B" butonu
    ══════════════════════════════════════════════════════════
]]

-- NOT (v2.2): Lua/Luau bir fonksiyonda en fazla 200 aktif yerel değişkene izin verir; dosyanın üst düzeyi de tek
-- fonksiyondur. Bu yüzden özellik fonksiyonları FX, animasyon fonksiyonları AN tablosunda tutulur.
-- Yeni özellik eklerken `local function fxXxx` yerine `function FX.fxXxx` kullanın.

local env = (getgenv and getgenv()) or _G
if env.__BOTIS_CLEANUP then pcall(env.__BOTIS_CLEANUP) end

-- ═══ SERVİSLER ═══
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local Lighting        = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Stats           = game:GetService("Stats")
local TextChatService = game:GetService("TextChatService")

local LP = Players.LocalPlayer
local FX, AN = {}, {}   -- özellik (fx*) ve animasyon fonksiyonları burada (200 yerel değişken sınırı için)
local function getCam()  return workspace.CurrentCamera end
local function hum()     local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function root()    local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end

-- Mouse raycast (LP:GetMouse() deprecated — workspace:Raycast kullan)
local function mouseRaycast(ignoreList)
    local cam = getCam(); if not cam then return nil end
    local pos = UIS:GetMouseLocation()
    local ray = cam:ViewportPointToRay(pos.X, pos.Y, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList or {LP.Character or workspace}
    return workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
end

-- ═══ TEMA ═══
local Theme = {
    bg     = Color3.fromRGB(16,  16,  22),
    panel  = Color3.fromRGB(23,  23,  31),
    item   = Color3.fromRGB(30,  30,  41),
    hover  = Color3.fromRGB(40,  40,  54),
    off    = Color3.fromRGB(56,  56,  72),
    stroke = Color3.fromRGB(46,  46,  62),
    text   = Color3.fromRGB(236, 236, 246),
    sub    = Color3.fromRGB(145, 145, 168),
    accent = Color3.fromRGB(139, 92,  246),
}
local FONT, FONTB = Enum.Font.GothamMedium, Enum.Font.GothamBold

-- ═══ YARDIMCILAR ═══
local function new(cls, props, parent)
    local o = Instance.new(cls)
    if props then for k, v in pairs(props) do o[k] = v end end
    if parent then o.Parent = parent end
    return o
end
local function round(o, r)   return new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function mkStroke(o, c, t)
    return new("UIStroke", {Color = c, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end
local function tween(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local accStatic, accFns = {}, {}
local function acc(o, prop) accStatic[#accStatic+1] = {o, prop}; o[prop] = Theme.accent; return o end
local function setAccent(c)
    Theme.accent = c
    for _, a in ipairs(accStatic) do if a[1] and a[1].Parent then a[1][a[2]] = c end end
    for _, fn in ipairs(accFns) do pcall(fn) end
end

local conns = {}
local function track(c) conns[#conns+1] = c; return c end
local fc = {}
local function unbind(k) if fc[k] then fc[k]:Disconnect(); fc[k] = nil end end
local function bind(k, sig, fn) unbind(k); fc[k] = sig:Connect(fn) end

local S = {
    speed = 50, jump = 100, fly = 60, cf = 60, spin = 360, roll = 40,
    fov = 90, time = 14, animSpeed = 1, grav0 = workspace.Gravity, uiScale = 1,
}

local LBackup = {}
local function lset(p, v)
    if LBackup[p] == nil then LBackup[p] = Lighting[p] end
    Lighting[p] = v
end
local function lrestore(...)
    for _, p in ipairs({...}) do
        if LBackup[p] ~= nil then Lighting[p] = LBackup[p]; LBackup[p] = nil end
    end
end

-- ═══ GUI PARENT (gethui → CoreGui → PlayerGui) ═══
local function getGuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok = pcall(function()
        local t = Instance.new("Folder"); t.Parent = game:GetService("CoreGui"); t:Destroy()
    end)
    if ok then return game:GetService("CoreGui") end
    return LP:WaitForChild("PlayerGui")
end

-- ═══ GUI OLUŞTUR ═══
local gui = new("ScreenGui", {
    Name = "BH"..math.random(10000,99999), ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, IgnoreGuiInset = true,
})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = getGuiParent()
local espFolder = new("Folder", {Name = "ESP"..math.random(1000,9999)}, gui.Parent)

-- Bildirimler
local toasts = new("Frame", {
    AnchorPoint = Vector2.new(1,1), Position = UDim2.new(1,-14,1,-14),
    Size = UDim2.fromOffset(260,300), BackgroundTransparency = 1,
}, gui)
new("UIListLayout", {
    Padding = UDim.new(0,6), HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder,
}, toasts)

local function notify(text, dur)
    dur = dur or 2.2
    local f = new("Frame", {Size = UDim2.fromOffset(250,34), BackgroundColor3 = Theme.panel,
        BackgroundTransparency = 1, BorderSizePixel = 0}, toasts)
    round(f, 8)
    local st = mkStroke(f, Theme.accent, 1); st.Transparency = 1
    local l = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), Text = text,
        Font = FONT, TextSize = 12, TextColor3 = Theme.text, TextTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd}, f)
    tween(f,.2,{BackgroundTransparency=.05}); tween(st,.2,{Transparency=.35}); tween(l,.2,{TextTransparency=0})
    task.delay(dur, function()
        tween(f,.25,{BackgroundTransparency=1}); tween(st,.25,{Transparency=1}); tween(l,.25,{TextTransparency=1})
        task.wait(.3); f:Destroy()
    end)
end

local function run(fn, ...)
    if not fn then return end
    local ok, err = pcall(fn, ...)
    if not ok then notify("⚠ "..tostring(err), 4); warn("[BotisHub] "..tostring(err)) end
end

-- Pencere
local WIN_W, WIN_H = 580, 390
local vp = (getCam() and getCam().ViewportSize) or Vector2.new(1280,720)
local baseScale = math.clamp(math.min(vp.X/(WIN_W+40), vp.Y/(WIN_H+40)), 0.55, 1)
S.uiScale = baseScale

local holder = new("Frame", {Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(0,0), BackgroundTransparency = 1}, gui)
local win = new("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromOffset(0,0),
    Size = UDim2.fromOffset(WIN_W,WIN_H), BackgroundColor3 = Theme.bg, BorderSizePixel = 0}, holder)
local winScale = new("UIScale", {Scale = baseScale}, win)
round(win,12); mkStroke(win, Theme.stroke, 1)

local top = new("Frame", {Size = UDim2.new(1,0,0,42), BackgroundColor3 = Theme.panel, BorderSizePixel = 0}, win)
round(top,12)
new("Frame", {Size = UDim2.new(1,0,0,12), Position = UDim2.new(0,0,1,-12), BackgroundColor3 = Theme.panel, BorderSizePixel = 0}, top)
local dot = new("Frame", {Size = UDim2.fromOffset(10,10), Position = UDim2.fromOffset(14,16), BorderSizePixel = 0}, top)
round(dot,5); acc(dot,"BackgroundColor3")
new("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(32,0), Size=UDim2.fromOffset(80,42),
    Text="BOTIS", Font=Enum.Font.GothamBlack, TextSize=16, TextColor3=Theme.text, TextXAlignment=Enum.TextXAlignment.Left}, top)
new("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(108,2), Size=UDim2.fromOffset(120,42),
    Text="hub • v2.2", Font=FONT, TextSize=11, TextColor3=Theme.sub, TextXAlignment=Enum.TextXAlignment.Left}, top)

local searchBox = new("TextBox", {AnchorPoint=Vector2.new(1,.5), Position=UDim2.new(1,-44,.5,0),
    Size=UDim2.fromOffset(150,26), BackgroundColor3=Theme.bg, BorderSizePixel=0, Text="",
    PlaceholderText="🔍 Ara...", PlaceholderColor3=Theme.sub, TextColor3=Theme.text,
    Font=FONT, TextSize=12, ClearTextOnFocus=false}, top)
round(searchBox,8)

local closeBtn = new("TextButton", {AnchorPoint=Vector2.new(1,.5), Position=UDim2.new(1,-10,.5,0),
    Size=UDim2.fromOffset(26,26), BackgroundColor3=Theme.item, Text="–", Font=FONTB, TextSize=16,
    TextColor3=Theme.text, AutoButtonColor=false}, top)
round(closeBtn,8)

local side    = new("Frame", {Position=UDim2.fromOffset(8,50),   Size=UDim2.new(0,124,1,-58), BackgroundTransparency=1}, win)
new("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, side)
local content = new("Frame", {Position=UDim2.fromOffset(140,50), Size=UDim2.new(1,-148,1,-58), BackgroundTransparency=1}, win)

-- Sürükleme
local function draggable(handle, target)
    local st = {moved=false}
    local dragging, p0, t0
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging=true; st.moved=false; p0=i.Position; t0=target.Position
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d = i.Position - p0
            if d.Magnitude > 6 then st.moved = true end
            if st.moved then target.Position = UDim2.new(t0.X.Scale, t0.X.Offset+d.X, t0.Y.Scale, t0.Y.Offset+d.Y) end
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))
    return st
end
draggable(top, holder)

local function toggleMenu(v)
    if v == nil then v = not win.Visible end
    win.Visible = v
    if v then winScale.Scale = S.uiScale*.92; tween(winScale,.2,{Scale=S.uiScale}) end
end
closeBtn.Activated:Connect(function() toggleMenu(false) end)
track(UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == (S.menuKey or Enum.KeyCode.RightShift) then toggleMenu() end
end))

-- Mobil FAB
local fab = new("TextButton", {Size=UDim2.fromOffset(42,42), Position=UDim2.new(0,14,.5,-21),
    BackgroundColor3=Theme.panel, Text="B", Font=Enum.Font.GothamBlack, TextSize=18, AutoButtonColor=false}, gui)
round(fab,21); acc(fab,"TextColor3"); acc(mkStroke(fab,Theme.accent,1.5),"Color")
local fabDrag = draggable(fab, fab)
fab.Activated:Connect(function() if not fabDrag.moved then toggleMenu() end end)

-- ═══ UI KÜTÜPHANESİ ═══
local Pages, Current, searchText = {}, nil, ""
local Toggles = {}
local P = {}; P.__index = P

local function applyFilter()
    if not Current then return end
    for _, r in ipairs(Current.rows) do
        r.frame.Visible = (searchText=="") or (not r.sec and r.name:find(searchText,1,true) ~= nil)
    end
end
track(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchText = searchBox.Text:lower(); applyFilter()
end))

local function selectPage(pg)
    Current = pg
    for _, p in pairs(Pages) do
        local on = p == pg
        p.sf.Visible=on; p.ind.Visible=on
        p.btn.BackgroundTransparency = on and .88 or 1
        p.lbl.TextColor3 = on and Theme.text or Theme.sub
    end
    applyFilter()
end

local pageOrder = 0
local function newPage(name, icon)
    local sf = new("ScrollingFrame", {Name=name, Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=Theme.stroke,
        ScrollingDirection=Enum.ScrollingDirection.Y, AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.new(), Visible=false}, content)
    new("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, sf)
    new("UIPadding",    {PaddingRight=UDim.new(0,8), PaddingBottom=UDim.new(0,8)}, sf)
    pageOrder = pageOrder + 1
    local btn = new("TextButton", {LayoutOrder=pageOrder, Size=UDim2.new(1,0,0,34),
        BackgroundTransparency=1, Text="", AutoButtonColor=false}, side)
    round(btn,8); acc(btn,"BackgroundColor3")
    local ind = new("Frame", {Size=UDim2.fromOffset(3,16), Position=UDim2.new(0,4,.5,-8), BorderSizePixel=0, Visible=false}, btn)
    round(ind,2); acc(ind,"BackgroundColor3")
    local lbl = new("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(16,0), Size=UDim2.new(1,-16,1,0),
        Text=icon.."  "..name, Font=FONT, TextSize=13, TextColor3=Theme.sub, TextXAlignment=Enum.TextXAlignment.Left}, btn)
    local pg = setmetatable({sf=sf, rows={}, n=0, btn=btn, ind=ind, lbl=lbl}, P)
    btn.Activated:Connect(function() selectPage(pg) end)
    Pages[name] = pg
    return pg
end

local function rowFrame(pg, h, name, sec)
    pg.n = pg.n + 1
    local f = new("Frame", {LayoutOrder=pg.n, Size=UDim2.new(1,0,0,h), BackgroundColor3=Theme.item, BorderSizePixel=0}, pg.sf)
    round(f,8); pg.rows[#pg.rows+1] = {frame=f, name=(name or ""):lower(), sec=sec}
    return f
end
local function rowLabel(parent, text, wOff)
    return new("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(12,0),
        Size=UDim2.new(1,-(wOff or 70),1,0), Text=text, Font=FONT, TextSize=13,
        TextColor3=Theme.text, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, parent)
end

function P:Section(text)
    self.n = self.n + 1
    local l = new("TextLabel", {LayoutOrder=self.n, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
        Text="  "..text, Font=FONTB, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, self.sf)
    acc(l,"TextColor3"); self.rows[#self.rows+1] = {frame=l, name="", sec=true}
end

function P:Label(text)
    local f = rowFrame(self, 30, "")
    local l = rowLabel(f, text, 24); l.TextColor3=Theme.sub; l.TextSize=12
    return function(t) l.Text=t end
end

function P:Toggle(text, default, cb)
    local f = rowFrame(self, 36, text)
    rowLabel(f, text, 70)
    local sw = new("Frame", {AnchorPoint=Vector2.new(1,.5), Position=UDim2.new(1,-12,.5,0),
        Size=UDim2.fromOffset(38,20), BackgroundColor3=Theme.off, BorderSizePixel=0}, f)
    round(sw,10)
    local knob = new("Frame", {AnchorPoint=Vector2.new(0,.5), Position=UDim2.new(0,3,.5,0),
        Size=UDim2.fromOffset(14,14), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}, sw)
    round(knob,7)
    local btn = new("TextButton", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Text=""}, f)
    local state = false
    local function paint()
        tween(sw,.15,{BackgroundColor3 = state and Theme.accent or Theme.off})
        tween(knob,.15,{Position = state and UDim2.new(1,-17,.5,0) or UDim2.new(0,3,.5,0)})
    end
    local obj = {}
    function obj.Set(v, silent)
        state = v and true or false; paint()
        if not silent then run(cb, state) end
    end
    function obj.Get() return state end
    btn.Activated:Connect(function() obj.Set(not state) end)
    accFns[#accFns+1] = paint
    if default then obj.Set(true) end
    return obj
end

function P:Slider(text, min, max, default, cb, step)
    step = step or 1
    local f = rowFrame(self, 46, text)
    local l = rowLabel(f, text, 90); l.Position=UDim2.fromOffset(12,4); l.Size=UDim2.new(1,-90,0,18)
    local val = new("TextLabel", {BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-12,0,4),
        Size=UDim2.fromOffset(70,18), Font=FONTB, TextSize=12, TextColor3=Theme.sub, TextXAlignment=Enum.TextXAlignment.Right}, f)
    local bar = new("Frame", {Position=UDim2.new(0,12,1,-14), Size=UDim2.new(1,-24,0,6), BackgroundColor3=Theme.off, BorderSizePixel=0}, f)
    round(bar,3)
    local fill = new("Frame", {Size=UDim2.fromScale(0,1), BorderSizePixel=0}, bar)
    round(fill,3); acc(fill,"BackgroundColor3")
    local hit = new("TextButton", {BackgroundTransparency=1, Text="", Position=UDim2.fromOffset(0,20), Size=UDim2.new(1,0,1,-20)}, f)
    local function set(v, silent)
        v = math.clamp(math.floor(v/step+.5)*step, min, max)
        v = tonumber(string.format("%.3f", v))
        fill.Size = UDim2.fromScale((v-min)/(max-min), 1)
        val.Text = tostring(v)
        if not silent then run(cb,v) end
    end
    local dragging = false
    local function fromX(x) set(min+(max-min)*math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)) end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; self.sf.ScrollingEnabled=false; fromX(i.Position.X)
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            fromX(i.Position.X)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then
            dragging=false; self.sf.ScrollingEnabled=true
        end
    end))
    set(default, true)
    return {Set=set}
end

function P:Button(text, cb)
    local f = rowFrame(self, 34, text)
    local b = new("TextButton", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=text,
        Font=FONT, TextSize=13, TextColor3=Theme.text, AutoButtonColor=false}, f)
    b.MouseEnter:Connect(function() tween(f,.12,{BackgroundColor3=Theme.hover}) end)
    b.MouseLeave:Connect(function() tween(f,.12,{BackgroundColor3=Theme.item}) end)
    b.Activated:Connect(function() run(cb) end)
end

function P:Input(text, placeholder, cb)
    local f = rowFrame(self, 36, text)
    rowLabel(f, text, 170)
    local tb = new("TextBox", {AnchorPoint=Vector2.new(1,.5), Position=UDim2.new(1,-8,.5,0),
        Size=UDim2.fromOffset(150,24), BackgroundColor3=Theme.bg, BorderSizePixel=0, Text="",
        PlaceholderText=placeholder, PlaceholderColor3=Theme.sub, TextColor3=Theme.text,
        Font=FONT, TextSize=12, ClearTextOnFocus=false}, f)
    round(tb,6)
    tb.FocusLost:Connect(function(enter) if enter then run(cb,tb.Text) end end)
end

function P:Colors(text, list, cb)
    local f = rowFrame(self, 40, text)
    rowLabel(f, text, #list*28+30)
    local h = new("Frame", {AnchorPoint=Vector2.new(1,.5), Position=UDim2.new(1,-10,.5,0),
        Size=UDim2.fromOffset(#list*28,24), BackgroundTransparency=1}, f)
    new("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6),
        VerticalAlignment=Enum.VerticalAlignment.Center}, h)
    for _, c in ipairs(list) do
        local b = new("TextButton", {Size=UDim2.fromOffset(22,22), BackgroundColor3=c, Text="", AutoButtonColor=false}, h)
        round(b,11); b.Activated:Connect(function() run(cb,c) end)
    end
end

function P:PlayerList(onSelect)
    local f = rowFrame(self, 130, "oyuncu listesi")
    local sf = new("ScrollingFrame", {Position=UDim2.fromOffset(6,6), Size=UDim2.new(1,-12,1,-12), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=3, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, f)
    new("UIListLayout", {Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.Name}, sf)
    local items = {}
    local function paint()
        for p, b in pairs(items) do b.BackgroundColor3 = (S.target==p) and Theme.accent or Theme.bg end
    end
    local function refresh()
        for _, b in pairs(items) do b:Destroy() end; items={}
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=LP then
                local b = new("TextButton", {Name=p.Name:lower(), Size=UDim2.new(1,-4,0,26),
                    BackgroundColor3=Theme.bg, BorderSizePixel=0,
                    Text="  "..p.DisplayName.."  (@"..p.Name..")", Font=FONT, TextSize=12,
                    TextColor3=Theme.text, TextXAlignment=Enum.TextXAlignment.Left, AutoButtonColor=false}, sf)
                round(b,6); b.Activated:Connect(function() onSelect(p); paint() end); items[p]=b
            end
        end
        paint()
    end
    accFns[#accFns+1] = paint
    track(Players.PlayerAdded:Connect(function() task.defer(refresh) end))
    track(Players.PlayerRemoving:Connect(function(p)
        if S.target==p then S.target=nil; onSelect(nil) end; task.defer(refresh)
    end))
    refresh()
end

function P:Picker(text, options, cb, lines)
    lines = lines or 5
    local f = rowFrame(self, 54+lines*28, text)
    local l = rowLabel(f,text,20); l.Position=UDim2.fromOffset(12,4); l.Size=UDim2.new(1,-24,0,18)
    local sb = new("TextBox", {Position=UDim2.fromOffset(8,24), Size=UDim2.new(1,-16,0,22), BackgroundColor3=Theme.bg,
        BorderSizePixel=0, Text="", PlaceholderText="🔍 filtrele...", PlaceholderColor3=Theme.sub,
        TextColor3=Theme.text, Font=FONT, TextSize=12, ClearTextOnFocus=false}, f)
    round(sb,6)
    local sf = new("ScrollingFrame", {Position=UDim2.fromOffset(8,50), Size=UDim2.new(1,-16,1,-56), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=3, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, f)
    new("UIListLayout", {Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder}, sf)
    local list, limit, pool, names = options or {}, 60, {}, {}
    local function mk(i)
        local b = new("TextButton", {LayoutOrder=i, Size=UDim2.new(1,-6,0,26), BackgroundColor3=Theme.bg,
            BorderSizePixel=0, Font=FONT, TextSize=12, TextColor3=Theme.text,
            TextXAlignment=Enum.TextXAlignment.Left, AutoButtonColor=false, TextTruncate=Enum.TextTruncate.AtEnd}, sf)
        round(b,6)
        b.MouseEnter:Connect(function() tween(b,.1,{BackgroundColor3=Theme.hover}) end)
        b.MouseLeave:Connect(function() tween(b,.1,{BackgroundColor3=Theme.bg}) end)
        b.Activated:Connect(function() if names[i] then run(cb,names[i]) end end)
        return b
    end
    local render
    local more = new("TextButton", {Size=UDim2.new(1,-6,0,24), BackgroundTransparency=1, Font=FONTB, TextSize=11,
        TextColor3=Theme.sub, Visible=false, AutoButtonColor=false}, sf)
    more.Activated:Connect(function() limit=limit+60; render() end)
    function render()
        local q = sb.Text:lower(); local n=0
        for _, name in ipairs(list) do
            if q=="" or name:lower():find(q,1,true) then
                n=n+1
                if n<=limit then
                    local b=pool[n]; if not b then b=mk(n); pool[n]=b end
                    names[n]=name; b.Text="  "..name; b.Visible=true
                end
            end
        end
        for i=math.min(n,limit)+1, #pool do pool[i].Visible=false; names[i]=nil end
        more.Visible = n>limit; more.LayoutOrder=limit+1
        if n>limit then more.Text="▼ daha fazla ("..(n-limit)..")" end
    end
    track(sb:GetPropertyChangedSignal("Text"):Connect(function() limit=60; sf.CanvasPosition=Vector2.zero; render() end))
    render()
    return {SetOptions=function(l2) list=l2 or {}; limit=60; render() end}
end

-- ═══ ÖZELLİKLER ═══
local Active = {}
local function feat(page, text, fn, default, noReapply)
    local t = page:Toggle(text, default, function(on)
        Active[text] = (on and not noReapply) and fn or nil
        fn(on)
    end)
    Toggles[#Toggles+1] = t; return t
end
track(LP.CharacterAdded:Connect(function(c)
    c:WaitForChild("HumanoidRootPart",10); c:WaitForChild("Humanoid",10); task.wait(.3)
    for _, fn in pairs(Active) do task.spawn(function() run(fn,true) end) end
end))

-- ── Hareket ──
function FX.fxSpeed(on)
    unbind("speed")
    if on then
        local h=hum(); if h and not S._ws then S._ws=h.WalkSpeed end
        bind("speed", RunService.Heartbeat, function() local h2=hum(); if h2 then h2.WalkSpeed=S.speed end end)
    else local h=hum(); if h and S._ws then h.WalkSpeed=S._ws end; S._ws=nil end
end

function FX.fxJump(on)
    unbind("jump")
    if on then
        local h=hum(); if h and not S._jp then S._jp={h.UseJumpPower,h.JumpPower} end
        bind("jump", RunService.Heartbeat, function()
            local h2=hum(); if h2 then h2.UseJumpPower=true; h2.JumpPower=S.jump end
        end)
    else local h=hum(); if h and S._jp then h.UseJumpPower=S._jp[1]; h.JumpPower=S._jp[2] end; S._jp=nil end
end

function FX.fxInfJump(on)
    unbind("inf")
    if on then bind("inf", UIS.JumpRequest, function()
        local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end) end
end

-- Uçuş: LinearVelocity (Roblox 2022+) + BodyVelocity fallback
function FX.fxFly(on)
    unbind("fly")
    for _, k in ipairs({"_flyAtt","_flyLV","_flyAO"}) do
        if S[k] then pcall(function() S[k]:Destroy() end); S[k]=nil end
    end
    S._flyNew = false
    local h, r = hum(), root()
    if not on then if h then h.PlatformStand=false end; return end
    if not (h and r) then return end
    -- LinearVelocity (modern)
    pcall(function()
        S._flyAtt = Instance.new("Attachment"); S._flyAtt.Parent = r
        local lv = Instance.new("LinearVelocity")
        lv.Attachment0 = S._flyAtt; lv.MaxForce = 2e5
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.VectorVelocity = Vector3.zero; lv.Parent = r
        S._flyLV = lv; S._flyNew = true
    end)
    if not S._flyNew then
        -- BodyVelocity fallback (eski)
        pcall(function()
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e9,1e9,1e9); bv.Velocity=Vector3.zero; bv.Parent=r
            S._flyLV = bv
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque=Vector3.new(1e9,1e9,1e9); bg.P=9e4; bg.CFrame=r.CFrame; bg.Parent=r
            S._flyAO = bg
        end)
    end
    bind("fly", RunService.RenderStepped, function()
        local r2,h2,cam = root(),hum(),getCam()
        if not (r2 and h2 and cam) then return end
        h2.PlatformStand = true
        local md = h2.MoveDirection
        local dir = Vector3.zero
        if md.Magnitude > 0.05 then
            local d = cam.CFrame.RightVector*md.X + cam.CFrame.LookVector*(-md.Z)
            dir = Vector3.new(d.X,0,d.Z)
            if dir.Magnitude > 0 then dir = dir.Unit end
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E)           then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q)     then dir=dir-Vector3.new(0,1,0) end
        local vel = dir.Magnitude>0 and dir.Unit*S.fly or Vector3.zero
        local lk  = cam.CFrame.LookVector
        local lkFlat = Vector3.new(lk.X,0,lk.Z)
        if S._flyNew and S._flyLV and S._flyLV.Parent then
            S._flyLV.VectorVelocity = vel
            if lkFlat.Magnitude > 0.01 then
                r2.CFrame = CFrame.new(r2.Position) * CFrame.lookAt(Vector3.zero, lkFlat)
            end
        elseif S._flyLV and S._flyLV.Parent then
            S._flyLV.Velocity = vel
            if S._flyAO and S._flyAO.Parent then
                S._flyAO.CFrame = CFrame.new(r2.Position, r2.Position+(lkFlat.Magnitude>0.01 and lkFlat or Vector3.new(0,0,-1)))
            end
        else
            r2.AssemblyLinearVelocity = vel
            if lkFlat.Magnitude > 0.01 then r2.CFrame = CFrame.new(r2.Position, r2.Position+lkFlat) end
        end
    end)
end

function FX.fxNoclip(on)
    unbind("noclip")
    if on then bind("noclip", RunService.Stepped, function()
        local c=LP.Character
        if c then for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end end
    end) end
end

function FX.fxCFSpeed(on)
    unbind("cf")
    if on then bind("cf", RunService.Heartbeat, function(dt)
        local h2,r2=hum(),root()
        if h2 and r2 and h2.MoveDirection.Magnitude>0 then r2.CFrame=r2.CFrame+h2.MoveDirection*S.cf*dt end
    end) end
end

function FX.fxBhop(on)
    unbind("bhop")
    if on then bind("bhop", RunService.Heartbeat, function()
        local h2=hum()
        if h2 and h2.MoveDirection.Magnitude>0 and h2.FloorMaterial~=Enum.Material.Air then h2.Jump=true end
    end) end
end

function FX.fxClickTP(on)
    unbind("ctp")
    if on then bind("ctp", UIS.InputBegan, function(i, g)
        if g then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            local r2 = root(); if not r2 then return end
            local res = mouseRaycast({LP.Character})
            if res then r2.CFrame = CFrame.new(res.Position+Vector3.new(0,3,0)) end
        end
    end) end
end

function FX.fxVoid(on)
    unbind("void")
    if on then
        local safe
        bind("void", RunService.Heartbeat, function()
            local r2,h2=root(),hum()
            if not (r2 and h2) then return end
            if h2.FloorMaterial~=Enum.Material.Air then safe=r2.CFrame end
            if safe and r2.Position.Y < workspace.FallenPartsDestroyHeight+60 then
                r2.AssemblyLinearVelocity = Vector3.zero
                r2.CFrame = safe + Vector3.new(0,4,0)
            end
        end)
    end
end

function FX.fxAfk(on)
    unbind("afk")
    if on then
        local VU = game:GetService("VirtualUser")
        bind("afk", LP.Idled, function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
    end
end

-- ── Görsel: ESP ──
local ESP = {objs={}, t=0, opt={chams=true, names=true, dist=true, health=true, tracers=false, team=false}}
local hasDrawing = pcall(function() Drawing.new("Line"):Remove() end)

function FX.espClear(plr)
    local o = ESP.objs[plr]; if not o then return end
    ESP.objs[plr] = nil
    if o.cc then o.cc:Disconnect() end
    if o.hl and o.hl.Parent then o.hl:Destroy() end
    if o.bb and o.bb.Parent then o.bb:Destroy() end
    if o.ln then pcall(function() o.ln:Remove() end) end
end

function FX.espBuild(plr, c)
    local o = ESP.objs[plr]; if not o then return end
    if o.hl and o.hl.Parent then o.hl:Destroy(); o.hl=nil end
    if o.bb and o.bb.Parent then o.bb:Destroy(); o.bb=nil end
    local head = c:WaitForChild("Head",5)
    if not head or ESP.objs[plr]~=o or plr.Character~=c then return end
    o.hl = new("Highlight", {Adornee=c, FillTransparency=.65, OutlineTransparency=0,
        DepthMode=Enum.HighlightDepthMode.AlwaysOnTop}, c)
    o.bb = new("BillboardGui", {Adornee=head, AlwaysOnTop=true, Size=UDim2.fromOffset(220,40),
        StudsOffset=Vector3.new(0,2.6,0)}, espFolder)
    o.tl = new("TextLabel", {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Font=FONTB, TextSize=13,
        TextStrokeTransparency=.4, TextColor3=Color3.new(1,1,1), Text=""}, o.bb)
end

function FX.espStep(dt)
    ESP.t = ESP.t + dt
    local doText = ESP.t > .12
    if doText then ESP.t = 0 end
    local cam, mr = getCam(), root()
    for plr, o in pairs(ESP.objs) do
        local c  = plr.Character
        local r2 = c and c:FindFirstChild("HumanoidRootPart")
        local col = (ESP.opt.team and plr.Team) and plr.TeamColor.Color or Color3.fromRGB(255,75,95)
        if o.hl and o.hl.Parent then o.hl.Enabled=ESP.opt.chams; o.hl.FillColor=col; o.hl.OutlineColor=col end
        if o.bb and o.tl and doText then
            local h2 = c and c:FindFirstChildOfClass("Humanoid")
            local t={}
            if ESP.opt.names then t[#t+1]=plr.DisplayName end
            if ESP.opt.dist and mr and r2 then t[#t+1]="["..math.floor((mr.Position-r2.Position).Magnitude).."m]" end
            if ESP.opt.health and h2 then t[#t+1]=math.floor(h2.Health).."HP" end
            o.tl.Text=table.concat(t," "); o.tl.TextColor3=col
            if o.bb.Parent then o.bb.Enabled=#t>0 end
        end
        if hasDrawing then
            if ESP.opt.tracers and r2 and cam then
                if not o.ln then o.ln=Drawing.new("Line"); o.ln.Thickness=1.5 end
                local p, vis = cam:WorldToViewportPoint(r2.Position)
                o.ln.Visible=vis; o.ln.Color=col
                o.ln.From=Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                o.ln.To=Vector2.new(p.X,p.Y)
            elseif o.ln then o.ln.Visible=false end
        end
    end
end

function FX.fxESP(on)
    unbind("espStep"); unbind("espAdd"); unbind("espRem")
    for plr in pairs(ESP.objs) do FX.espClear(plr) end
    if not on then return end
    local function add(plr)
        if plr==LP or ESP.objs[plr] then return end
        local o={}; ESP.objs[plr]=o
        o.cc = plr.CharacterAdded:Connect(function(c) task.spawn(FX.espBuild,plr,c) end)
        if plr.Character then task.spawn(FX.espBuild,plr,plr.Character) end
    end
    for _, p in ipairs(Players:GetPlayers()) do add(p) end
    bind("espAdd", Players.PlayerAdded, add)
    bind("espRem", Players.PlayerRemoving, FX.espClear)
    bind("espStep", RunService.RenderStepped, FX.espStep)
end

-- ── Görsel: Dünya/Kamera ──
function FX.fxFullbright(on)
    unbind("fb")
    if on then bind("fb", RunService.Heartbeat, function()
        lset("Brightness",2); lset("GlobalShadows",false)
        lset("Ambient",Color3.fromRGB(190,190,190)); lset("OutdoorAmbient",Color3.fromRGB(190,190,190))
    end) else lrestore("Brightness","GlobalShadows","Ambient","OutdoorAmbient") end
end

function FX.fxNoFog(on)
    unbind("fog")
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if on then
        if atm and S._atm==nil then S._atm=atm.Density end
        bind("fog", RunService.Heartbeat, function()
            lset("FogEnd",9e8); lset("FogStart",9e8)
            local a=Lighting:FindFirstChildOfClass("Atmosphere"); if a then a.Density=0 end
        end)
    else
        lrestore("FogEnd","FogStart")
        if atm and S._atm then atm.Density=S._atm end; S._atm=nil
    end
end

function FX.fxTime(on)
    unbind("time")
    if on then bind("time", RunService.Heartbeat, function() lset("ClockTime",S.time) end)
    else lrestore("ClockTime") end
end

local xr = setmetatable({}, {__mode="k"})
function FX.inChar(p)
    local m = p.Parent
    for _ = 1, 2 do
        if m and m:IsA("Model") and Players:GetPlayerFromCharacter(m) then return true end
        m = m and m.Parent
    end
    return false
end
function FX.fxXray(on)
    unbind("xr"); S._xrTok=(S._xrTok or 0)+1; local tok=S._xrTok
    if on then
        local function apply(p)
            if p:IsA("BasePart") and not p:IsA("Terrain") and not FX.inChar(p) then
                xr[p]=true; p.LocalTransparencyModifier=.6
            end
        end
        task.spawn(function()
            local n=0
            for _, d in ipairs(workspace:GetDescendants()) do
                if S._xrTok~=tok then return end
                pcall(apply,d); n=n+1
                if n%1500==0 then task.wait() end
            end
        end)
        bind("xr", workspace.DescendantAdded, function(d) pcall(apply,d) end)
    else
        for p in pairs(xr) do if p and p.Parent then pcall(function() p.LocalTransparencyModifier=0 end) end end
        table.clear(xr)
    end
end

function FX.refreshFov()
    unbind("fov"); local cam=getCam()
    if S.fovOn or S.zoomOn then
        S._defFov = S._defFov or (cam and cam.FieldOfView) or 70
        bind("fov", RunService.RenderStepped, function()
            local c=getCam(); if not c then return end
            local target=(S.zoomOn and S.zooming) and 20 or (S.fovOn and S.fov or S._defFov)
            c.FieldOfView = c.FieldOfView+(target-c.FieldOfView)*.25
        end)
    else
        if cam and S._defFov then cam.FieldOfView=S._defFov end; S._defFov=nil
    end
end
function FX.fxFov(on)       S.fovOn=on; FX.refreshFov() end
function FX.fxZoom(on)
    S.zoomOn=on; S.zooming=false; unbind("zi"); unbind("zo")
    if on then
        bind("zi",UIS.InputBegan, function(i,g) if not g and i.KeyCode==Enum.KeyCode.C then S.zooming=true end end)
        bind("zo",UIS.InputEnded, function(i)   if i.KeyCode==Enum.KeyCode.C then S.zooming=false end end)
    end
    FX.refreshFov()
end
function FX.fxUnlockZoom(on)
    if on then
        S._zmax=S._zmax or LP.CameraMaxZoomDistance
        S._zmin=S._zmin or LP.CameraMinZoomDistance
        LP.CameraMaxZoomDistance=1e5; LP.CameraMinZoomDistance=0
    else
        if S._zmax then LP.CameraMaxZoomDistance=S._zmax end
        if S._zmin then LP.CameraMinZoomDistance=S._zmin end
        S._zmax,S._zmin=nil,nil
    end
end
function FX.fxCamNoclip(on)
    LP.DevCameraOcclusionMode = on and Enum.DevCameraOcclusionMode.Invisicam or Enum.DevCameraOcclusionMode.Zoom
end

-- Nişangah
local cross = new("Frame", {AnchorPoint=Vector2.new(.5,.5), Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(20,20), BackgroundTransparency=1, Visible=false}, gui)
for _, s in ipairs({{UDim2.fromOffset(20,2),UDim2.fromOffset(0,9)},{UDim2.fromOffset(2,20),UDim2.fromOffset(9,0)}}) do
    local b=new("Frame",{Size=s[1],Position=s[2],BorderSizePixel=0},cross); acc(b,"BackgroundColor3")
end
function FX.fxCross(on) cross.Visible=on end

-- FPS/Ping HUD
local hud = new("TextLabel", {AnchorPoint=Vector2.new(.5,0), Position=UDim2.new(.5,0,0,8),
    Size=UDim2.fromOffset(170,24), BackgroundColor3=Theme.bg, BackgroundTransparency=.15,
    Font=FONTB, TextSize=12, TextColor3=Theme.text, Text="", Visible=false}, gui)
round(hud,8); mkStroke(hud,Theme.stroke,1)
function FX.fxHud(on)
    unbind("hud"); hud.Visible=on
    if on then
        local a,n=0,0
        bind("hud", RunService.RenderStepped, function(dt)
            a=a+dt; n=n+1
            if a>=.5 then
                local ping=0
                pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                hud.Text=("FPS %d  •  Ping %d ms"):format(math.floor(n/a+.5),ping)
                a,n=0,0
            end
        end)
    end
end

function FX.fpsBoost()
    notify("FPS Booster uygulanıyor...")
    task.spawn(function()
        pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
        Lighting.GlobalShadows=false
        local function opt(d)
            if d:IsA("BasePart") and not d:IsA("Terrain") then
                d.Material=Enum.Material.SmoothPlastic; d.Reflectance=0; d.CastShadow=false
            elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                d.Enabled=false
            end
        end
        local n=0
        for _, d in ipairs(workspace:GetDescendants()) do
            pcall(opt,d); n=n+1; if n%1500==0 then task.wait() end
        end
        for _, d in ipairs(Lighting:GetDescendants()) do if d:IsA("PostEffect") then d.Enabled=false end end
        notify("FPS Booster tamam ✔")
    end)
end

-- ── Eğlence ──
function FX.fxSpin(on)
    unbind("spin")
    if on then bind("spin", RunService.Heartbeat, function(dt)
        local r2=root(); if r2 then r2.CFrame=r2.CFrame*CFrame.Angles(0,math.rad(S.spin)*dt,0) end
    end) end
end

function FX.fxRagdoll(on)
    unbind("rag"); local h=hum()
    if on then bind("rag", RunService.Stepped, function()
        local h2=hum(); if h2 then h2:ChangeState(Enum.HumanoidStateType.Physics) end
    end)
    elseif h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

function FX.fxMoon(on)
    unbind("moon"); local h=hum()
    if on then bind("moon", RunService.Heartbeat, function()
        local h2,r2=hum(),root()
        if h2 and r2 then
            h2.AutoRotate=false
            local md=h2.MoveDirection
            if md.Magnitude>.1 then r2.CFrame=CFrame.new(r2.Position,r2.Position-md) end
        end
    end)
    elseif h then h.AutoRotate=true end
end

function FX.fxRoll(on)
    pcall(function() RunService:UnbindFromRenderStep("BotisRoll") end)
    if on then
        local ang=0
        RunService:BindToRenderStep("BotisRoll", Enum.RenderPriority.Camera.Value+1, function(dt)
            ang=(ang+dt*S.roll)%360
            local cam=getCam(); if cam then cam.CFrame=cam.CFrame*CFrame.Angles(0,0,math.rad(ang)) end
        end)
    end
end

function FX.fxAir(on)
    unbind("air")
    if S._plat then S._plat:Destroy(); S._plat=nil end
    if not on then return end
    local r2,h2=root(),hum()
    if not (r2 and h2) then return end
    local hipH = h2.RigType==Enum.HumanoidRigType.R6 and 3 or (h2.HipHeight+r2.Size.Y/2)
    local y = r2.Position.Y - hipH - .5
    local p = new("Part", {Size=Vector3.new(10,1,10), Anchored=true, CanCollide=true,
        Transparency=.85, Material=Enum.Material.Neon}, workspace)
    acc(p,"Color"); S._plat=p
    bind("air", RunService.Heartbeat, function(dt)
        local r3=root(); if not r3 then return end
        if UIS:IsKeyDown(Enum.KeyCode.E) then y=y+25*dt elseif UIS:IsKeyDown(Enum.KeyCode.Q) then y=y-25*dt end
        p.CFrame=CFrame.new(r3.Position.X,y,r3.Position.Z)
    end)
end

function FX.fxTrail(on)
    if S._trail then for _, o in ipairs(S._trail) do pcall(function() o:Destroy() end) end; S._trail=nil end
    local r2=root()
    if on and r2 then
        local a0=new("Attachment",{Position=Vector3.new(0,1,0)},r2)
        local a1=new("Attachment",{Position=Vector3.new(0,-1,0)},r2)
        local kp={}
        for i=0,5 do kp[#kp+1]=ColorSequenceKeypoint.new(i/5,Color3.fromHSV(i/6,.8,1)) end
        S._trail={a0,a1,new("Trail",{Attachment0=a0,Attachment1=a1,Lifetime=.7,LightEmission=1,
            Transparency=NumberSequence.new(0,1),Color=ColorSequence.new(kp)},r2)}
    end
end

function FX.fxAura(on)
    if S._aura then S._aura:Destroy(); S._aura=nil end
    local r2=root()
    if on and r2 then
        S._aura=new("ParticleEmitter",{Rate=35,Lifetime=NumberRange.new(.8,1.4),Speed=NumberRange.new(2,5),
            SpreadAngle=Vector2.new(180,180),LightEmission=1,RotSpeed=NumberRange.new(-90,90),
            Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.7),NumberSequenceKeypoint.new(1,0)}),
            Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,1)}),
            Color=ColorSequence.new(Theme.accent)},r2)
    end
end

function FX.fxDisco(on)
    unbind("disco")
    if on then bind("disco", RunService.Heartbeat, function()
        local c=Color3.fromHSV((tick()*.15)%1,.8,1)
        lset("Ambient",c); lset("OutdoorAmbient",c)
    end) else lrestore("Ambient","OutdoorAmbient") end
end

function FX.fxClickDelete(on)
    unbind("cdel")
    if on then bind("cdel", UIS.InputBegan, function(i,g)
        if g then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftAlt) then
            local res=mouseRaycast({LP.Character})
            if res and res.Instance and not res.Instance:IsA("Terrain") and not FX.inChar(res.Instance) then
                res.Instance:Destroy()
            end
        end
    end) end
end

-- ── Oyuncu ──
function FX.fxAntiFling(on)
    unbind("af")
    if on then bind("af", RunService.Stepped, function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                for _, d in ipairs(p.Character:GetChildren()) do
                    if d:IsA("BasePart") then d.CanCollide=false end
                end
            end
        end
    end) end
end

function FX.spectate(on)
    local cam=getCam(); if not cam then return end
    if on and S.target and S.target.Character then
        local h2=S.target.Character:FindFirstChildOfClass("Humanoid")
        if h2 then cam.CameraSubject=h2; return end
    end
    local h2=hum(); if h2 then cam.CameraSubject=h2 end
end

function FX.tpTo(plr)
    local r2=root()
    local tr=plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if r2 and tr then r2.CFrame=tr.CFrame*CFrame.new(0,0,3) else notify("Hedef bulunamadı") end
end

function FX.rejoin()
    if #Players:GetPlayers()<=1 then TeleportService:Teleport(game.PlaceId,LP)
    else TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end
end

function FX.serverHop()
    notify("Sunucu aranıyor...")
    task.spawn(function()
        local ok,res=pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)))
        end)
        if not ok or not res or not res.data then notify("Sunucu listesi alınamadı",4); return end
        local list={}
        for _, s in ipairs(res.data) do
            if s.id~=game.JobId and s.playing<s.maxPlayers then list[#list+1]=s.id end
        end
        if #list==0 then notify("Uygun sunucu yok"); return end
        TeleportService:TeleportToPlaceInstance(game.PlaceId,list[math.random(#list)],LP)
    end)
end

function FX.fxClickSelect(on)
    unbind("csel")
    if on then bind("csel", UIS.InputBegan, function(i,g)
        if g then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            local res=mouseRaycast({})
            if not res then return end
            local m=res.Instance and res.Instance:FindFirstAncestorOfClass("Model")
            local p=m and Players:GetPlayerFromCharacter(m)
            if p and p~=LP then S.target=p; if S.onSelect then S.onSelect(p) end; notify("Seçildi: "..p.Name) end
        end
    end) end
end

-- ══════════════════════════════════════════════════
--  AYAR DOSYASI
-- ══════════════════════════════════════════════════
local CFG_DIR, CFG_FILE = "BotisHub", "BotisHub/settings.json"
local Cfg = {
    favorites={}, lastEmote="", pack="", custom={}, theme="Gece",
    accent={139,92,246}, alpha=0, menuKey="RightShift",
    emotePrefix="/em", animPrefix="/a"
}
local canFile = (writefile and readfile and isfile) and true or false
local function saveCfg()
    if not canFile then return end
    pcall(function()
        if makefolder and isfolder and not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
        writefile(CFG_FILE, HttpService:JSONEncode(Cfg))
    end)
end
local saveStamp=0
local function saveSoon()
    saveStamp=tick(); local s=saveStamp
    task.delay(2, function() if s==saveStamp then saveCfg() end end)
end
pcall(function()
    if canFile and isfile(CFG_FILE) then
        for k,v in pairs(HttpService:JSONDecode(readfile(CFG_FILE))) do Cfg[k]=v end
    end
end)
if type(Cfg.accent)~="table"   or #Cfg.accent<3    then Cfg.accent={139,92,246} end
if type(Cfg.favorites)~="table"                     then Cfg.favorites={} end
if type(Cfg.custom)~="table"                        then Cfg.custom={} end

-- ══════════════════════════════════════════════════
--  TEMA MOTORU
-- ══════════════════════════════════════════════════
local THEME_KEYS  = {"bg","panel","item","hover","off","stroke","text","sub"}
local THEME_ORDER = {"Gece","Gece Yarısı","AMOLED","Orman","Gül","Açık"}
local THEMES = {
    ["Gece"]        = {bg={16,16,22}, panel={23,23,31}, item={30,30,41}, hover={40,40,54}, off={56,56,72},  stroke={46,46,62},   text={236,236,246}, sub={145,145,168}},
    ["Gece Yarısı"] = {bg={10,14,28}, panel={15,21,40}, item={22,30,54}, hover={32,43,74}, off={50,62,98},  stroke={38,50,86},   text={232,238,255}, sub={140,152,190}},
    ["AMOLED"]      = {bg={0,0,0},    panel={10,10,10}, item={18,18,18}, hover={30,30,30}, off={52,52,52},  stroke={34,34,34},   text={245,245,245}, sub={140,140,140}},
    ["Orman"]       = {bg={14,22,18}, panel={20,31,25}, item={27,42,34}, hover={37,57,46}, off={52,76,62},  stroke={40,62,50},   text={232,245,236}, sub={140,170,150}},
    ["Gül"]         = {bg={24,14,20}, panel={34,20,28}, item={46,28,38}, hover={62,38,52}, off={86,54,72},  stroke={66,40,56},   text={250,235,242}, sub={185,145,165}},
    ["Açık"]        = {bg={244,244,248},panel={232,232,240},item={222,222,232},hover={208,208,222},off={186,186,204},stroke={200,200,214},text={28,28,40},sub={100,100,124}},
}
local function ckey(c) return math.floor(c.R*255+.5)..","..math.floor(c.G*255+.5)..","..math.floor(c.B*255+.5) end

local function applyTheme(name)
    local t=THEMES[name]; if not t then return end
    local map,fresh={},{}
    for _, k in ipairs(THEME_KEYS) do
        fresh[k]=Color3.fromRGB(t[k][1],t[k][2],t[k][3]); map[ckey(Theme[k])]=fresh[k]
    end
    local function remap(o,prop) local n=map[ckey(o[prop])]; if n then o[prop]=n end end
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("GuiObject") then
            remap(d,"BackgroundColor3")
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then remap(d,"TextColor3") end
            if d:IsA("TextBox")       then remap(d,"PlaceholderColor3") end
            if d:IsA("ScrollingFrame") then remap(d,"ScrollBarImageColor3") end
        elseif d:IsA("UIStroke") then remap(d,"Color") end
    end
    for k,v in pairs(fresh) do Theme[k]=v end
    Cfg.theme=name; saveSoon()
end

local function accentSet(c)
    setAccent(c)
    Cfg.accent={math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)}
    saveSoon()
end

local function winAlpha(v)
    win.BackgroundTransparency=v; top.BackgroundTransparency=v
    for _, c in ipairs(top:GetChildren()) do
        if c:IsA("Frame") and c.Size.Y.Offset==12 then c.BackgroundTransparency=v end
    end
    Cfg.alpha=v; saveSoon()
end

-- ══════════════════════════════════════════════════
--  EMOTE VERİLERİ (R15)
-- ══════════════════════════════════════════════════
local EMOTES = {
    ["Fashion"]=3333331310,["Baby Dance"]=4265725525,["Cha-Cha"]=6862001787,["Monkey"]=3333499508,
    ["Shuffle"]=4349242221,["Shuffle 2"]=17748314784,["Top Rock"]=3361276673,["Around Town"]=3303391864,
    ["Fancy Feet"]=3333432454,["Hype Dance"]=3695333486,["Bodybuilder"]=3333387824,["Idol"]=4101966434,
    ["Curtsy"]=4555816777,["Happy"]=4841405708,["Quiet Waves"]=7465981288,["Sleep"]=4686925579,
    ["Floss Dance"]=5917459365,["Shy"]=3337978742,["Godlike"]=3337994105,["Hero Landing"]=5104344710,
    ["High Wave"]=5915690960,["Cower"]=4940563117,["Bored"]=5230599789,["Celebrate"]=3338097973,
    ["Dash"]=582855105,["Beckon"]=5230598276,["Haha"]=3337966527,["Line Dance"]=4049037604,
    ["Shrug"]=3334392772,["Point2"]=3344585679,["Stadium"]=3338055167,["Confused"]=4940561610,
    ["Side to Side"]=3333136415,["Hello"]=3344650532,["Dolphin Dance"]=5918726674,["Samba"]=6869766175,
    ["Break Dance"]=5915648917,["Greatest"]=3338042785,["Sad"]=4841407203,["Flowing Breeze"]=7465946930,
    ["Twirl"]=3334968680,["Jumping Wave"]=4940564896,["Dizzy"]=3361426436,["Fast Hands"]=4265701731,
    ["Tree"]=4049551434,["Agree"]=4841397952,["Power Blast"]=4841403964,["Swoosh"]=3361481910,
    ["Jumping Cheer"]=5895324424,["Disagree"]=4841401869,["Rock On"]=5915714366,["Block Partier"]=6862022283,
    ["Dorky Dance"]=4212455378,["Zombie"]=4210116953,["Zombie 2"]=10714089137,["T"]=3338010159,
    ["Fishing"]=3334832150,["Robot"]=3338025566,["Keeping Time"]=4555808220,["Air Dance"]=4555782893,
    ["Louder"]=3338083565,["Sneaky"]=3334424322,["Heisman Pose"]=3695263073,["Jacks"]=3338066331,
    ["Cha-Cha 2"]=3695322025,["Superhero Reveal"]=3695373233,["Air Guitar"]=3695300085,
    ["Air Guitar 2"]=15505454268,["Dismissive Wave"]=3333272779,["Salute"]=3333474484,
    ["Applaud"]=5915693819,["Bunny Hop"]=4641985101,["Sandwich Dance"]=4406555273,
    ["Tantrum"]=5104341999,["High Hands"]=9710985298,["Tilt"]=3334538554,["Chicken Dance"]=4841399916,
    ["Arm Twist"]=10713968716,["Super Charge"]=10478338114,["Swag Walk"]=10478341260,
    ["Hwaiting (화이팅)"]=9527885267,["Annyeong (안녕)"]=9527883498,["Gashina - SUNMI"]=9527886709,
    ["TWICE-Moonlight-Sunrise"]=12714233242,["TWICE-Set-Me-Free-Dance-1"]=12714228341,
    ["TWICE-Set-Me-Free-Dance-2"]=12714231087,["TWICE-The-Feels"]=12874447851,["TWICE-What-Is-Love"]=13327655243,
    ["TWICE-Fancy"]=13520524517,["TWICE Pop by Nayeon"]=13768941455,["TWICE Like Ooh-Ahh"]=14123781004,
    ["TWICE I GOT YOU part 1"]=16215030041,["TWICE I GOT YOU part 2"]=16256203246,
    ["TWICE LIKEY"]=14899979575,["TWICE Feel Special"]=14899980745,["TWICE Strategy"]=97311229290836,
    ["TWICE ABCD by Nayeon"]=18933706381,["TWICE Takedown"]=140182843839424,
    ["TWICE TAKEDOWN DANCE 2"]=127104635954695,["Stray Kids Walkin On Water"]=125064469983655,
    ["BLACKPINK Pink Venom - Get em"]=14548619594,["BLACKPINK Pink Venom - Pain"]=14548620495,
    ["BLACKPINK Pink Venom - Dome"]=14548621256,["BLACKPINK Shut Down - Part 1"]=14901306096,
    ["BLACKPINK Shut Down - Part 2"]=14901308987,["BLACKPINK JISOO Flower"]=15439354020,
    ["BLACKPINK JENNIE You and Me"]=15439356296,["BLACKPINK LISA Money"]=15679623052,
    ["BLACKPINK ROSÉ On The Ground"]=15679624464,["BLACKPINK Ice Cream"]=16181797368,
    ["BLACKPINK Kill This Love"]=16181798319,["BLACKPINK Boombayah"]=16553164850,
    ["BLACKPINK DDU-DU DDU-DU"]=16553170471,["BLACKPINK How You Like That"]=16874470507,
    ["BLACKPINK Lovesick Girls"]=16874472321,["BLACKPINK As If It's Your Last"]=18855536648,
    ["BLACKPINK Don't Know What To Do"]=18855531354,
    ["Imagine Dragons Bones"]=15689279687,["GloRilla Tomorrow"]=15689278184,["d4vd Backflip"]=15693621070,
    ["ericdoa dance"]=15698402762,["Cuco Levitate"]=15698404340,["Jawny Stomp"]=16392075853,
    ["Mae Stephens Piano Hands"]=16553163212,["Mae Stephens Arm Wave"]=16584481352,
    ["HIPMOTION Amaarae"]=16572740012,["Charli xcx Apple Dance"]=18946844622,
    ["The Zabb"]=129470135909814,["Chappell Roan HOT TO GO!"]=85267023718407,
    ["Secret Handshake Dance"]=71243990877913,["SpongeBob Imaginaaation"]=18443237526,
    ["SpongeBob Dance"]=18443245017,["Shrek Roar"]=18524313628,["TMNT Dance"]=18665811005,
    ["Mean Girls Dance Break"]=15963314052,["Bone Chillin Bop"]=15122972413,
    ["Nicki Minaj Anaconda"]=15571450952,["Nicki Minaj Starships"]=15571453761,
    ["Nicki Minaj Super Bass"]=15571446961,["Nicki Minaj Boom Boom"]=15571448688,
    ["Olivia Rodrigo Head Bop"]=15517864808,["Olivia Rodrigo good 4 u"]=15517862739,
    ["Olivia Rodrigo Fall Back"]=15549124879,["Elton John Rock Out"]=11753474067,
    ["Elton John Still Standing"]=11444443576,["Elton John Cat Man"]=11444441914,
    ["Elton John Piano Jump"]=11453082181,["Rolling Stones Guitar Strum"]=18148804340,
    ["Alo Yoga Triangle"]=12507084541,["Alo Yoga Warrior II"]=12507083048,
    ["Alo Yoga Lotus Position"]=12507085924,["Sol de Janeiro Samba"]=16270690701,
    ["Skadoosh Emote"]=16371217304,["Skibidi Titan Speakerman"]=134283166482394,
    ["Robot M3GAN"]=125803725853577,["M3GAN Dance"]=99649534578309,
    ["Rasputin Boney M"]=114872820353992,["Vans Ollie"]=18305395285,
    ["Festive Dance"]=15679621440,["Rock n Roll"]=15505458452,["Victory Dance"]=15505456446,
    ["Flex Walk"]=15505459811,["Team USA Breaking"]=18526288497,["Olympic Dismount"]=18665825805,
    ["Vroom Vroom"]=18526397037,["Beauty Touchdown"]=16302968986,
    ["Wanna play?"]=16646423316,["Mini Kong"]=17000021306,["Wisp air guitar"]=17370775305,
    ["Sturdy Dance Ice Spice"]=17746180844,["Rock Out Bebe Rexha"]=18225053113,
    ["Man City Bicycle Kick"]=13421057998,["Man City Backflip"]=13694100677,
    ["Man City Scorpion Kick"]=13694096724,["NBA WNBA Fadeaway"]=18526362841,
    ["NBA Monster Dunk"]=132748833449150,["Yungblud HIGH KICK"]=14022936101,
    ["Yungblud Happier Jump"]=15609995579,["KATSEYE Touch"]=135876612109535,
    ["The Weeknd Starboy Strut"]=71105746210464,["The Weeknd Opening Night"]=133110725387025,
    ["DearALICE Ariana"]=134318425949290,["Fashion Spin"]=131669256082047,
    ["Fashion Klossette"]=80995190624232,["Fashion Roadkill"]=136831243854748,
}
local EMOTE_LIST = {}
for n in pairs(EMOTES) do EMOTE_LIST[#EMOTE_LIST+1]=n end
table.sort(EMOTE_LIST, function(a,b) return a:lower()<b:lower() end)

-- ══════════════════════════════════════════════════
--  EMOTE VERİLERİ (R6)
-- ══════════════════════════════════════════════════
local R6E, R6_LIST = {}, {}
function AN.r6(name, id, speed, time) R6E[name]={id,speed,time}; R6_LIST[#R6_LIST+1]=name end
AN.r6("Balloon Float",148840371); AN.r6("Idle",180435571); AN.r6("Arm Turbine",259438880,1.5)
AN.r6("Floating Head",121572214); AN.r6("Insane Rotation",121572214,99); AN.r6("Scream",180611870,1.5)
AN.r6("Party Time",33796059); AN.r6("Chop",33169596); AN.r6("Weird Sway",248336677); AN.r6("Goal!",28488254)
AN.r6("Rotation",136801964); AN.r6("Spin",188632011); AN.r6("Weird Float",248336459); AN.r6("Pinch Nose",30235165)
AN.r6("Cry",180612465,1.5); AN.r6("Penguin Slide",282574440,0); AN.r6("Zombie Arms",183294396)
AN.r6("Flying",46196309); AN.r6("Stab",66703241); AN.r6("Dance",35654637); AN.r6("Random",48977286)
AN.r6("Hmmm",33855276); AN.r6("Sword",35978879); AN.r6("Arms Out",27432691); AN.r6("Kick",45737360)
AN.r6("Insane Legs",87986341,99); AN.r6("Head Detach",35154961,0,3); AN.r6("Moon Walk",30196114,0,3)
AN.r6("Crouch",182724289); AN.r6("Beat Box",45504977,0,3); AN.r6("Big Guns",161268368,0,3)
AN.r6("Bigger Guns",225975820,0,3); AN.r6("Charleston",429703734); AN.r6("Moon Dance",27789359)
AN.r6("Roar",163209885); AN.r6("Weird Pose",248336163); AN.r6("Spin Dance 2",186934910)
AN.r6("Bow Down",204292303); AN.r6("Sword Slam",204295235); AN.r6("Glitch Levitate",313762630)
AN.r6("Full Swing",218504594); AN.r6("Full Punch",204062532); AN.r6("Faint",181526230)
AN.r6("Floor Faint",181525546); AN.r6("Jumping Jacks",429681631); AN.r6("Spin Dance",429730430)
AN.r6("Arm Detach",33169583); AN.r6("Dino Walk",204328711); AN.r6("Tilt Head",283545583)
AN.r6("Dab",183412246); AN.r6("Float Sit",179224234); AN.r6("Clone Illusion",215384594,1e7,.5)
table.sort(R6_LIST, function(a,b) return a:lower()<b:lower() end)

-- ══════════════════════════════════════════════════
--  ANİMASYON PAKETLERİ
-- ══════════════════════════════════════════════════
local PACKS, PACK_LIST = {}, {}
function AN.pk(name,a,b,c,d,e,f,g,h,i,j)
    PACKS[name]={Idle=a,Idle2=b,Idle3=c,Walk=d,Run=e,Jump=f,Climb=g,Fall=h,Swim=i,SwimIdle=j,Weight=9,Weight2=1}
    PACK_LIST[#PACK_LIST+1]=name
end
AN.pk("Stylish",616136790,616138447,886888594,616146177,616140816,616139451,616133594,616134815,616143378,616144772)
AN.pk("Zombie",616158929,616160636,885545458,616168032,616163682,616161997,616156119,616157476,616165109,616166655)
AN.pk("Robot",616088211,616089559,885531463,616095330,616091570,616090535,616086039,616087089,616092998,616094091)
AN.pk("Toy",782841498,782845736,980952228,782843345,782842708,782847020,782843869,782846423,782844582,782845186)
AN.pk("Cartoony",742637544,742638445,885477856,742640026,742638842,742637942,742636889,742637151,742639220,742639812)
AN.pk("Superhero",616111295,616113536,885535855,616122287,616117076,616115533,616104706,616108001,616119360,616120861)
AN.pk("Mage",707742142,707855907,885508740,707897309,707861613,707853694,707826056,707829716,707876443,707894699)
AN.pk("Levitation",616006778,616008087,886862142,616013216,616010382,616008936,616003713,616005863,616011509,616012453)
AN.pk("Vampire",1083445855,1083450166,1088037547,1083473930,1083462077,1083455352,1083439238,1083443587,1083464683,1083467779)
AN.pk("Elder",845397899,845400520,901160519,845403856,845386501,845398858,845392038,845396048,845401742,845403127)
AN.pk("Werewolf",1083195517,1083214717,1099492820,1083178339,1083216690,1083218792,1083182000,1083189019,1083222527,1083225406)
AN.pk("Knight",657595757,657568135,885499184,657552124,657564596,658409194,658360781,657600338,657560551,657557095)
AN.pk("Bold",16738333868,16738334710,16738335517,16738340646,16738337225,16738336650,16738332169,16738333171,16738339158,16738339817)
AN.pk("Astronaut",891621366,891633237,1047759695,891667138,891636393,891627522,891609353,891617961,891639666,891663592)
AN.pk("Bubbly",910004836,910009958,1018536639,910034870,910025107,910016857,909997997,910001910,910028158,910030921)
AN.pk("Pirate",750781874,750782770,885515365,750785693,750783738,750782230,750779899,750780242,750784579,750785176)
AN.pk("Rthro",2510196951,2510197257,3711062489,2510202577,2510198475,2510197830,2510192778,2510195892,2510199791,2510201162)
AN.pk("Ninja",656117400,656118341,886742569,656121766,656118852,656117878,656114359,656115606,656119721,656121397)
AN.pk("Oldschool",5319828216,5319831086,5392107832,5319847204,5319844329,5319841935,5319816685,5319839762,5319850266,5319852613)
AN.pk("Realistic",17172918855,17173014241,17173014241,11600249883,11600211410,11600210487,11600205519,11600206437,11600212676,11600213505)
AN.pk("No Boundaries",18747067405,18747063918,18747063918,18747074203,18747070484,18747069148,18747060903,18747062535,18747073181,18747071682)
AN.pk("Princess",941003647,941013098,1159195712,941028902,941015281,941008832,940996062,941000007,941018893,941025398)
AN.pk("Confident",1069977950,1069987858,1116160740,1070017263,1070001516,1069984524,1069946257,1069973677,1070009914,1070012133)
AN.pk("Popstar",1212900985,1150842221,1239733474,1212980338,1212980348,1212954642,1213044953,1212900995,1212852603,1070012133)
AN.pk("Cowboy",1014390418,1014398616,1159487651,1014421541,1014401683,1014394726,1014380606,1014384571,1014406523,1014411816)
AN.pk("Ghost",616006778,616008087,616008087,616013216,616013216,616008936,nil,616005863,616011509,616012453)
AN.pk("Mocap",913367814,913373430,nil,913402848,913376220,913370268,913362637,913365531,913384386,913389285)
AN.pk("Sneaky",1132473842,1132477671,nil,1132510133,1132494274,1132489853,1132461372,1132469004,1132500520,1132506407)
AN.pk("Patrol",1149612882,1150842221,1159573567,1151231493,1150967949,1150944216,1148811837,1148863382,1151204998,1151221899)
AN.pk("Blocky Mech",4417977954,4417978624,4441285342,2510202577,4417979645,2510197830,2510192778,2510195892,2510199791,2510201162)
AN.pk("Stylized Female",4708191566,4708192150,nil,4708193840,4708192705,4708188025,4708184253,4708186162,4708189360,4708190607)
AN.pk("R15",4211217646,4211218409,nil,4211223236,4211220381,4211219390,4211214992,4211216152,4211221314,4374694239)
AN.pk("NFL Animation",92080889861410,74451233229259,80884010501210,110358958299415,117333533048078,119846112151352,134630013742019,129773241321032,132697394189921,79090109939093)
AN.pk("Adidas Aura",110211186840347,114191137265065,99129837931148,83842218823011,118320322718866,109996626521204,97824616490448,95603166884636,134530128383903,94922130551805)
AN.pk("Adidas Sports",18537376492,18537371272,18537374150,18537392113,18537384940,18537380791,18537363391,18537367238,18537389531,18537387180)
AN.pk("Wicked Dancing Through Life",92849173543269,132238900951109,87867222929430,73718308412641,135515454877967,78508480717326,129447497744818,78147885297412,110657013921774,129183123083281)
AN.pk("Catwalk Glam",133806214992291,94970088341563,87105332133518,109168724482748,81024476153754,116936326516985,119377220967554,92294537340807,134591743181628,98854111361360)
table.sort(PACK_LIST, function(a,b) return a:lower()<b:lower() end)

-- ══════════════════════════════════════════════════
--  ANİMASYON YARDIMCILARI
-- ══════════════════════════════════════════════════
local ANIM_URL = "http://www.roblox.com/asset/?id="
local BODY_MAP = {
    {"Idle",{"idle","Animation1"}},{"Idle2",{"idle","Animation2"}},{"Idle3",{"pose"}},
    {"Walk",{"walk"}},{"Run",{"run"}},{"Jump",{"jump"}},{"Climb",{"climb"}},
    {"Fall",{"fall"}},{"Swim",{"swim"}},{"SwimIdle",{"swimidle"}},
}
local SLOTS = {
    {"Idle","idle1","Idle"},{"Idle 2","idle2","Idle2"},{"Walk","walk","Walk"},{"Run","run","Run"},
    {"Jump","jump","Jump"},{"Climb","climb","Climb"},{"Fall","fall","Fall"},
    {"Swim Idle","swimidle","SwimIdle"},{"Swim","swim","Swim"},
    {"Wave","wave"},{"Laugh","laugh"},{"Cheer","cheer"},{"Point","point"},
    {"Sit","sit"},{"Dance","dance"},{"Dance 2","dance2"},{"Dance 3","dance3"},
}
local SLOT_NAMES, SLOT_BY_NAME = {}, {}
for _, s in ipairs(SLOTS) do SLOT_NAMES[#SLOT_NAMES+1]=s[1]; SLOT_BY_NAME[s[1]]=s end

function AN.getAnimate()  local c=LP.Character; return c and c:FindFirstChild("Animate") end
function AN.isR15()       local h=hum(); return h and h.RigType==Enum.HumanoidRigType.R15 end
function AN.animInst(a,p)
    local f = a and a:FindFirstChild(p[1]); if not f then return nil end
    if p[2] then return f:FindFirstChild(p[2]) end
    return f:FindFirstChildOfClass("Animation")
end
function AN.setId(inst, id)
    if not inst or not id or id==0 then return end
    inst.AnimationId = ANIM_URL..tostring(id)
end

local Orig = env.__BOTIS_ORIG
function AN.captureOrig()
    if Orig then return end
    local t0, a = tick(), nil
    repeat a=AN.getAnimate(); if not a then task.wait(.2) end until a or tick()-t0>6
    if not a then return end
    Orig = {slots={}}
    for _, m in ipairs(BODY_MAP) do local i=AN.animInst(a,m[2]); if i then Orig[m[1]]=i.AnimationId end end
    for _, s in ipairs(SLOTS) do
        if not s[3] then
            local f,ids = a:FindFirstChild(s[2]),{}
            if f then for _, v in ipairs(f:GetChildren()) do if v:IsA("Animation") then ids[#ids+1]=v.AnimationId end end end
            Orig.slots[s[2]]=ids
        end
    end
    env.__BOTIS_ORIG = Orig
end

function AN.applyBody(p)
    local a=AN.getAnimate(); if not a then return end
    for _, m in ipairs(BODY_MAP) do AN.setId(AN.animInst(a,m[2]),p[m[1]]) end
    local idle = a:FindFirstChild("idle")
    if idle then
        local w1 = idle:FindFirstChild("Animation1") and idle.Animation1:FindFirstChild("Weight")
        local w2 = idle:FindFirstChild("Animation2") and idle.Animation2:FindFirstChild("Weight")
        if w1 and p.Weight  then w1.Value=tonumber(p.Weight) end
        if w2 and p.Weight2 then w2.Value=tonumber(p.Weight2) end
    end
end

function AN.setSlot(slot, id)
    local a=AN.getAnimate(); if not a then return end
    if slot=="idle1" then
        AN.setId(AN.animInst(a,{"idle","Animation1"}),id); AN.setId(AN.animInst(a,{"pose"}),id)
    elseif slot=="idle2" then
        AN.setId(AN.animInst(a,{"idle","Animation2"}),id); AN.setId(AN.animInst(a,{"pose"}),id)
    else
        local f=a:FindFirstChild(slot)
        if f then for _, v in ipairs(f:GetChildren()) do if v:IsA("Animation") then AN.setId(v,id) end end end
    end
end

-- ══════════════════════════════════════════════════
--  EMOTE / ANİMASYON ÇEKİRDEĞİ
-- ══════════════════════════════════════════════════
local Anim = {
    loop=false, reverse=false, freeze=false, always=false, timeOn=false, timePct=0,
    speed=1, animSpeed=1, last=Cfg.lastEmote or "", track=nil, pose=nil,
}
local setEmoteStatus, setPackStatus = function() end, function() end
function AN.updateStatus()
    setEmoteStatus(("Emote: %s  •  Hız: %s  •  Döngü: %s"):format(
        Anim.last~="" and Anim.last or "—", tostring(Anim.speed), tostring(Anim.loop)))
    setPackStatus(("Paket: %s  •  Hız: %s"):format(
        Cfg.pack~="" and Cfg.pack or "Varsayılan", tostring(Anim.animSpeed)))
end

function AN.stopAllTracks()
    local h=hum(); if not h then return end
    for _, t in ipairs(h:GetPlayingAnimationTracks()) do pcall(function() t:Stop() end) end
end
function AN.refreshAnims()
    local a,h=AN.getAnimate(),hum()
    if not (a and h) then return end
    a.Disabled=true
    for _, t in ipairs(h:GetPlayingAnimationTracks()) do pcall(function() t:Stop() end) end
    a.Disabled=false
    local ws=h.WalkSpeed; h.WalkSpeed=0; task.wait(); h.WalkSpeed=ws
    if Anim.animSpeed~=1 then
        for _, t in ipairs(h:GetPlayingAnimationTracks()) do pcall(function() t:AdjustSpeed(Anim.animSpeed) end) end
    end
end
function AN.stopEmote()
    if Anim.track then pcall(function() Anim.track:Stop() end); Anim.track=nil end
    unbind("emoteMove")
end

function AN.playAnimation(id, o)
    o = o or {}
    local h=hum(); if not h then return end
    local animator = h:FindFirstChildOfClass("Animator") or new("Animator",nil,h)
    if Anim.track then pcall(function() Anim.track:Stop() end) end
    local anim = new("Animation", {AnimationId="rbxassetid://"..tostring(id)})
    local ok, tr = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not tr then notify("Animasyon yüklenemedi"); return end
    tr.Priority = Enum.AnimationPriority.Action4
    Anim.track = tr; tr:Play(.1)
    task.spawn(function()
        local t0=tick()
        while tr.Length==0 and tick()-t0<3 do task.wait() end
        if Anim.track~=tr then return end
        if Anim.loop then tr.Looped=true end
        local spd = o.speed
        if spd==nil then spd=Anim.freeze and 0 or (Anim.reverse and -math.abs(Anim.speed) or Anim.speed) end
        if Anim.reverse and o.speed==nil and tr.Length>0 then tr.TimePosition=math.max(tr.Length-.05,0) end
        if o.pct  then tr.TimePosition=o.pct/100*tr.Length
        elseif Anim.timeOn then tr.TimePosition=Anim.timePct/100*tr.Length end
        if o.time then tr.TimePosition=o.time end
        tr:AdjustSpeed(spd)
    end)
    bind("emoteMove", h:GetPropertyChangedSignal("MoveDirection"), function()
        if h.MoveDirection.Magnitude>0 and not (Anim.always or o.hold) then
            if Anim.track==tr then pcall(function() tr:Stop() end) end
            unbind("emoteMove")
        end
    end)
    AN.updateStatus(); return tr
end

function AN.playEmoteByName(n)
    local id=EMOTES[n]; if not id then return end
    local h=hum()
    if h and h.RigType==Enum.HumanoidRigType.R6 then notify("Bu emote R15 içindir — R6 listesini kullan"); return end
    Anim.last=n; Cfg.lastEmote=n; saveSoon(); AN.playAnimation(id)
end
function AN.playR6(n)
    local e=R6E[n]; if not e then return end
    local h=hum()
    if h and h.RigType~=Enum.HumanoidRigType.R6 then notify("R6 emote için R6 karakter gerekir"); return end
    Anim.last=n; AN.playAnimation(e[1],{speed=e[2],time=e[3]})
end
function AN.playLast()
    if Anim.last=="" then notify("Önce bir emote oynat"); return end
    if R6E[Anim.last] and not EMOTES[Anim.last] then AN.playR6(Anim.last) else AN.playEmoteByName(Anim.last) end
end
function AN.findEmote(q)
    q=q:lower()
    for _, n in ipairs(EMOTE_LIST) do if n:lower()==q then return n end end
    for _, n in ipairs(EMOTE_LIST) do if n:lower():find(q,1,true) then return n end end
end
function AN.findPack(q)
    q=q:lower()
    for _, n in ipairs(PACK_LIST) do if n:lower()==q then return n end end
    for _, n in ipairs(PACK_LIST) do if n:lower():find(q,1,true) then return n end end
end
function AN.findPlayer(n)
    n=n:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LP and (p.Name:lower():sub(1,#n)==n or p.DisplayName:lower():sub(1,#n)==n) then return p end
    end
end

local BODY_SLOT={}
for _, s in ipairs(SLOTS) do if s[3] then BODY_SLOT[s[2]]=true end end

function AN.applyPack(n)
    local p=PACKS[n]; if not p then return end
    if not AN.isR15() then notify("Animasyon paketleri R15 içindir"); return end
    Cfg.pack=n
    for slot in pairs(BODY_SLOT) do Cfg.custom[slot]=nil end
    AN.stopAllTracks(); AN.applyBody(p)
    for slot, id in pairs(Cfg.custom) do AN.setSlot(slot,id) end
    AN.refreshAnims(); AN.updateStatus(); saveSoon()
end
function AN.assignSlot(slotKey, id)
    Cfg.custom[slotKey]=id; AN.setSlot(slotKey,id); AN.refreshAnims(); saveSoon()
end
function AN.reapplyAnims()
    if not AN.isR15() or not AN.getAnimate() then return end
    if PACKS[Cfg.pack] then AN.applyBody(PACKS[Cfg.pack]) end
    local any = PACKS[Cfg.pack]~=nil
    for slot, id in pairs(Cfg.custom) do AN.setSlot(slot,id); any=true end
    if any then AN.refreshAnims() end
    AN.updateStatus()
end
function AN.resetAnims()
    AN.stopAllTracks(); Cfg.pack=""; Cfg.custom={}
    local a=AN.getAnimate()
    if Orig and a then
        AN.applyBody(Orig)
        for _, s in ipairs(SLOTS) do
            if not s[3] and Orig.slots[s[2]] then
                local f=a:FindFirstChild(s[2])
                if f then
                    local i=0
                    for _, v in ipairs(f:GetChildren()) do
                        if v:IsA("Animation") then i=i+1; if Orig.slots[s[2]][i] then v.AnimationId=Orig.slots[s[2]][i] end end
                    end
                end
            end
        end
    end
    AN.refreshAnims(); AN.updateStatus(); saveSoon()
end

function AN.animText()
    local a=AN.getAnimate(); if not a then return nil end
    local lines={"local Animate = game:GetService('Players').LocalPlayer.Character.Animate"}
    for _, m in ipairs(BODY_MAP) do
        local i=AN.animInst(a,m[2])
        if i then
            local path=m[2][2] and ("Animate.%s.%s"):format(m[2][1],m[2][2]) or ("Animate.%s:FindFirstChildOfClass('Animation')"):format(m[2][1])
            lines[#lines+1]=("%s.AnimationId = '%s'"):format(path,i.AnimationId)
        end
    end
    return table.concat(lines,"\n")
end

function AN.copyPackFrom(plr)
    local mine=AN.getAnimate()
    local theirs=plr and plr.Character and plr.Character:FindFirstChild("Animate")
    if not (mine and theirs) then return false end
    local changed=false
    for _, m in ipairs(BODY_MAP) do
        local a2,b2=AN.animInst(mine,m[2]),AN.animInst(theirs,m[2])
        if a2 and b2 and a2.AnimationId~=b2.AnimationId then a2.AnimationId=b2.AnimationId; changed=true end
    end
    return changed
end
function AN.mirrorTrack(v)
    local h=hum(); if not h then return end
    if v.Priority==Enum.AnimationPriority.Core or v.Priority.Value<2 then return end
    local animator=h:FindFirstChildOfClass("Animator"); if not animator then return end
    local ok,tr=pcall(function() return animator:LoadAnimation(v.Animation) end)
    if not ok or not tr then return end
    tr.Priority=Enum.AnimationPriority.Action4; tr:Play(.1,v.WeightCurrent,v.Speed)
    tr.TimePosition=v.TimePosition; Anim.track=tr
end
function AN.mirrorEmotes(plr)
    local th=plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    local tan=th and th:FindFirstChildOfClass("Animator")
    if not tan then notify("Hedef bulunamadı"); return false end
    for _, v in ipairs(tan:GetPlayingAnimationTracks()) do AN.mirrorTrack(v) end
    return true
end

-- ── Pozlar ──
local POSES, POSE_NAMES = {}, {}
function AN.pose(name, emote, pct, hip, loop)
    POSES[name]={emote=emote,pct=pct,hip=hip,loop=loop}; POSE_NAMES[#POSE_NAMES+1]=name
end
AN.pose("Otur",         "Alo Yoga Lotus Position",  45)
AN.pose("Otur 2",       "Man City Bicycle Kick",     72)
AN.pose("Otur 3",       "Quiet Waves",               12)
AN.pose("Süzül",        "Olivia Rodrigo Fall Back",  72, 4)
AN.pose("Süzül 2",      "Skadoosh Emote",            43)
AN.pose("Süzül 3",      "Cuco Levitate",              7, nil, true)
AN.pose("Ters dur",     "Hero Landing",              24.15)
AN.pose("Uzan",         "Man City Bicycle Kick",     57)
AN.pose("Gerin",        "Quiet Waves",               52)

function AN.stopPose()
    unbind("pose")
    if Anim.pose then
        Anim.pose=nil; AN.stopEmote()
        local h=hum()
        if h and S._hip0 then h.HipHeight=S._hip0; S._hip0=nil end
        AN.refreshAnims()
    end
end
function AN.startPose(def)
    if not def or not EMOTES[def.emote] then return end
    if not AN.isR15() then notify("Pozlar R15 içindir"); return end
    AN.stopPose(); Anim.pose=def
    local tr=AN.playAnimation(EMOTES[def.emote],{pct=def.pct,speed=def.loop and 1 or 0,hold=true})
    local h=hum()
    if def.hip and h then S._hip0=S._hip0 or h.HipHeight; h.HipHeight=def.hip end
    local lastReset=tick()
    bind("pose", RunService.Heartbeat, function()
        local h2=hum(); if h2 and h2.Sit then h2.Sit=false end
        if def.loop and tr and Anim.track==tr and tr.Length>0 and tick()-lastReset>6 then
            lastReset=tick(); tr.TimePosition=def.pct/100*tr.Length
        end
    end)
end

-- ── Özellik fonksiyonları ──
function FX.fxRandomEmote(on)
    S._re=(S._re or 0)+1; local tok=S._re
    if not on then AN.stopEmote(); return end
    task.spawn(function()
        while S._re==tok do
            local n=EMOTE_LIST[math.random(#EMOTE_LIST)]
            Anim.last=n
            local tr=AN.playAnimation(EMOTES[n],{hold=true})
            local t0=tick()
            while S._re==tok and (not tr or tr.Length==0) and tick()-t0<3 do task.wait(.1) end
            local len=(tr and tr.Length>0) and tr.Length or 5
            local w=0
            while S._re==tok and w<len+.5 do task.wait(.2); w=w+.2 end
        end
    end)
end

function FX.fxRandomPack(on)
    S._rp=(S._rp or 0)+1; local tok=S._rp
    if not on then return end
    task.spawn(function()
        while S._rp==tok do
            AN.applyPack(PACK_LIST[math.random(#PACK_LIST)])
            local w=0; while S._rp==tok and w<6.35 do task.wait(.2); w=w+.2 end
        end
    end)
end

function FX.fxRandomIdle(on)
    S._ri=(S._ri or 0)+1; local tok=S._ri
    if not on then return end
    task.spawn(function()
        while S._ri==tok do
            local a=AN.getAnimate(); local p=PACKS[PACK_LIST[math.random(#PACK_LIST)]]
            if a and p then
                AN.setId(AN.animInst(a,{"idle","Animation1"}),p.Idle)
                AN.setId(AN.animInst(a,{"idle","Animation2"}),p.Idle2)
                AN.setId(AN.animInst(a,{"pose"}),p.Idle3)
            end
            local w=0; while S._ri==tok and w<3 do task.wait(.2); w=w+.2 end
        end
    end)
end

function FX.fxAnimSpeed(on)
    unbind("animSpeed")
    if on then bind("animSpeed", RunService.Heartbeat, function()
        local h=hum(); if not h then return end
        for _, t in ipairs(h:GetPlayingAnimationTracks()) do
            if t~=Anim.track then t:AdjustSpeed(Anim.animSpeed) end
        end
    end) else task.spawn(AN.refreshAnims) end
end

function FX.fxFreezePack(on)
    unbind("freezePack")
    if on then bind("freezePack", RunService.Heartbeat, function()
        local h=hum(); if not h then return end
        for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:AdjustSpeed(0) end
    end) else
        local h=hum()
        if h then for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:AdjustSpeed(1) end end
        task.spawn(AN.refreshAnims)
    end
end

function FX.fxSyncEmote(on)
    unbind("syncEmote"); if not on then return end
    local p=S.syncTarget or S.target
    local th=p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    local tan=th and th:FindFirstChildOfClass("Animator")
    if not tan then notify("Önce hedef seç"); return end
    AN.mirrorEmotes(p); bind("syncEmote", tan.AnimationPlayed, AN.mirrorTrack)
end

function FX.fxSyncPack(on)
    S._sp=(S._sp or 0)+1; local tok=S._sp
    if not on then return end
    task.spawn(function()
        while S._sp==tok do
            local p=S.syncTarget or S.target
            if p and AN.copyPackFrom(p) then AN.refreshAnims() end
            task.wait(2)
        end
    end)
end

-- Sohbet komutları
local chatHooked, chatLast, chatLastT = false, "", 0
function FX.handleChat(msg)
    if not (S.chatEmote or S.chatAnim) then return end
    if msg==chatLast and tick()-chatLastT<.5 then return end
    chatLast,chatLastT=msg,tick()
    local low,ep,ap = msg:lower(), Cfg.emotePrefix:lower(), Cfg.animPrefix:lower()
    if S.chatEmote and low:sub(1,#ep+1)==ep.." " then
        local q=msg:sub(#ep+2); local n=AN.findEmote(q)
        if n then AN.playEmoteByName(n) else notify("Emote bulunamadı: "..q) end
    elseif S.chatAnim and low:sub(1,#ap+1)==ap.." " then
        local q=msg:sub(#ap+2); local n=AN.findPack(q)
        if n then AN.applyPack(n) else notify("Paket bulunamadı: "..q) end
    end
end
function FX.ensureChat()
    if chatHooked then return end
    chatHooked=true
    bind("chatLegacy", LP.Chatted, FX.handleChat)
    pcall(function()
        local chs=TextChatService:FindFirstChild("TextChannels")
        local ch=chs and chs:FindFirstChild("RBXGeneral")
        if ch then bind("chatNew", ch.MessageReceived, function(m)
            if m.TextSource and m.TextSource.UserId==LP.UserId then FX.handleChat(m.Text) end
        end) end
        local oldOIM = TextChatService.OnIncomingMessage
        S._oldOIM = oldOIM or false
        TextChatService.OnIncomingMessage = function(m)
            pcall(function()
                if m.TextSource and m.TextSource.UserId==LP.UserId then
                    local t=m.Text:lower()
                    if (S.chatEmote and t:sub(1,#Cfg.emotePrefix)==Cfg.emotePrefix:lower())
                        or (S.chatAnim and t:sub(1,#Cfg.animPrefix)==Cfg.animPrefix:lower()) then
                        m.Status=Enum.TextChatMessageStatus.InvalidTextChannelPermissions
                    end
                end
            end)
            if oldOIM then local ok, res = pcall(oldOIM, m); if ok then return res end end
        end
    end)
end
function FX.fxChatEmote(on) S.chatEmote=on; if on then FX.ensureChat() end end
function FX.fxChatAnim(on)  S.chatAnim=on;  if on then FX.ensureChat() end end

-- Hareket ekstraları
function FX.fxPlatform(on)
    if S._bigPlat then S._bigPlat:Destroy(); S._bigPlat=nil end
    if not on then return end
    local r2,h2=root(),hum()
    if not (r2 and h2) then return end
    local hipH = h2.RigType==Enum.HumanoidRigType.R6 and 3 or (h2.HipHeight+r2.Size.Y/2)
    S._bigPlat = new("Part", {Size=Vector3.new(300,1,300), Anchored=true, Transparency=1,
        Name=tostring(math.random(100,9999)),
        Position=Vector3.new(r2.Position.X, r2.Position.Y-hipH-.5, r2.Position.Z)}, workspace)
end

function FX.fxSwim(on)
    unbind("swim"); local h=hum()
    if on and h then
        S._gravSwim = S._gravSwim or workspace.Gravity
        workspace.Gravity = 0
        for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            if st~=Enum.HumanoidStateType.None and st~=Enum.HumanoidStateType.Dead then
                pcall(function() h:SetStateEnabled(st,false) end)
            end
        end
        h:ChangeState(Enum.HumanoidStateType.Swimming)
        bind("swim", RunService.Heartbeat, function()
            local h2,r2=hum(),root()
            if h2 and r2 and h2.MoveDirection==Vector3.zero and not UIS:IsKeyDown(Enum.KeyCode.Space) then
                r2.AssemblyLinearVelocity=Vector3.zero
            end
        end)
    else
        if S._gravSwim then workspace.Gravity=S._gravSwim; S._gravSwim=nil end
        if h then
            for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                if st~=Enum.HumanoidStateType.None then pcall(function() h:SetStateEnabled(st,true) end) end
            end
        end
    end
end

function FX.watchDeath()
    local h=hum(); if not h then return end
    if S._deathConn then S._deathConn:Disconnect() end
    S._deathConn = h.Died:Connect(function() local r2=root(); if r2 then S.deathCF=r2.CFrame end end)
end
function FX.fxRefreshPos(on)
    S.refreshPos=on
    if on then FX.watchDeath() elseif S._deathConn then S._deathConn:Disconnect(); S._deathConn=nil end
end

function FX.fxHear(on)
    local SS=game:GetService("SoundService")
    if S._hearPart then S._hearPart:Destroy(); S._hearPart=nil end
    if on then
        local r2=root(); if not r2 then return end
        S._hearPart=new("Part",{Name="SoundInf",Size=Vector3.new(1e10,1e10,1e10),Anchored=true,
            CanCollide=false,Transparency=1,CFrame=r2.CFrame},workspace)
        SS:SetListener(Enum.ListenerType.ObjectPosition,S._hearPart)
    else SS:SetListener(Enum.ListenerType.Camera) end
end

function FX.fxSpy(on)
    local SS=game:GetService("SoundService")
    if on then
        local r2=S.target and S.target.Character and S.target.Character:FindFirstChild("HumanoidRootPart")
        if not r2 then notify("Önce oyuncu seç"); return end
        SS:SetListener(Enum.ListenerType.ObjectPosition,r2)
    else SS:SetListener(Enum.ListenerType.Camera) end
end

track(LP.CharacterAdded:Connect(function(c)
    c:WaitForChild("Humanoid",10); c:WaitForChild("Animate",10); task.wait(.5)
    Anim.track=nil; Anim.pose=nil; unbind("pose")
    if S.refreshPos then
        FX.watchDeath()
        if S.deathCF then
            local r2=c:WaitForChild("HumanoidRootPart",5)
            if r2 then task.wait(.15); r2.CFrame=S.deathCF end
        end
    end
    task.spawn(AN.reapplyAnims)
end))

-- ══════════════════════════════════════════════════
--  SAYFALAR
-- ══════════════════════════════════════════════════
local pMove   = newPage("Hareket",   "🏃")
local pVis    = newPage("Görsel",    "👁")
local pEmote  = newPage("Emote",     "🎭")
local pPack   = newPage("Animasyon", "🕺")
local pCustom = newPage("Özel Anim", "🧩")
local pFun    = newPage("Eğlence",   "🤡")
local pPly    = newPage("Oyuncu",    "👥")
local pSet    = newPage("Ayarlar",   "⚙")

-- Hareket
pMove:Section("Temel")
feat(pMove,"Hız",FX.fxSpeed)
pMove:Slider("Hız değeri",16,300,S.speed,function(v) S.speed=v end)
feat(pMove,"Zıplama gücü",FX.fxJump)
pMove:Slider("Zıplama değeri",50,500,S.jump,function(v) S.jump=v end)
feat(pMove,"Sonsuz zıplama",FX.fxInfJump)
feat(pMove,"Bunny hop (otomatik zıpla)",FX.fxBhop)
pMove:Section("Uçuş & Işınlanma")
feat(pMove,"Uçuş (Space/E yukarı • Ctrl/Q aşağı)",FX.fxFly)
pMove:Slider("Uçuş hızı",10,300,S.fly,function(v) S.fly=v end)
feat(pMove,"Noclip (duvarlardan geç)",FX.fxNoclip)
feat(pMove,"CFrame hız",FX.fxCFSpeed)
pMove:Slider("CFrame hız değeri",10,300,S.cf,function(v) S.cf=v end)
feat(pMove,"Tıkla-ışınlan (Ctrl + Tık)",FX.fxClickTP)
feat(pMove,"Void koruması",FX.fxVoid)
pMove:Section("Fizik")
pMove:Slider("Yerçekimi",0,400,math.floor(S.grav0),function(v) workspace.Gravity=v end)
pMove:Button("Yerçekimini sıfırla",function() workspace.Gravity=S.grav0; notify("Yerçekimi sıfırlandı") end)
pMove:Section("Ekstra")
pMove:Slider("Kalça yüksekliği",0,60,math.floor((hum() and hum().HipHeight or 2)+.5),function(v)
    local h=hum(); if h then h.HipHeight=v end
end)
feat(pMove,"Platform (görünmez geniş zemin)",FX.fxPlatform)
feat(pMove,"Yüzme (havada yüz)",FX.fxSwim)
feat(pMove,"Ölünce aynı yerde doğ",FX.fxRefreshPos,false,true)
pMove:Button("⬆ Zıpla",function() local h=hum(); if h then h.Jump=true end end)
pMove:Button("🪂 Skydive (+500 stud)",function() local r2=root(); if r2 then r2.CFrame=r2.CFrame+Vector3.new(0,500,0) end end)
if setfpscap then pMove:Slider("FPS limiti",10,360,60,function(v) setfpscap(v) end,5) end

-- Görsel
pVis:Section("ESP")
feat(pVis,"ESP (ana şalter)",FX.fxESP,false,true)
pVis:Toggle("Highlight / Chams",true,function(v) ESP.opt.chams=v end)
pVis:Toggle("İsimler",true,function(v) ESP.opt.names=v end)
pVis:Toggle("Mesafe",true,function(v) ESP.opt.dist=v end)
pVis:Toggle("Can",true,function(v) ESP.opt.health=v end)
pVis:Toggle("Takım rengi",false,function(v) ESP.opt.team=v end)
if hasDrawing then pVis:Toggle("Tracer çizgileri",false,function(v) ESP.opt.tracers=v end)
else pVis:Label("Tracer: executor Drawing API desteklemiyor") end
pVis:Section("Dünya")
feat(pVis,"Fullbright",FX.fxFullbright)
feat(pVis,"Sis kaldır",FX.fxNoFog)
feat(pVis,"Saat kilidi",FX.fxTime)
pVis:Slider("Saat (0-24)",0,24,math.floor(Lighting.ClockTime),function(v) S.time=v end,.5)
feat(pVis,"X-Ray (duvarlar yarı saydam)",FX.fxXray)
pVis:Section("Kamera & Ekran")
feat(pVis,"FOV uygula",FX.fxFov)
pVis:Slider("FOV değeri",30,120,S.fov,function(v) S.fov=v end)
feat(pVis,"Zoom (C basılı tut)",FX.fxZoom)
feat(pVis,"Kamera zoom kilidini aç",FX.fxUnlockZoom)
feat(pVis,"Kamera duvarlardan geçsin",FX.fxCamNoclip)
feat(pVis,"Nişangah",FX.fxCross,false,true)
feat(pVis,"FPS / Ping göstergesi",FX.fxHud,false,true)
pVis:Button("🚀 FPS Booster (geri alınamaz)",FX.fpsBoost)

-- Eğlence
pFun:Section("Hareket oyunları")
feat(pFun,"Dön (spin)",FX.fxSpin)
pFun:Slider("Dönüş hızı (°/sn)",30,1440,S.spin,function(v) S.spin=v end,10)
feat(pFun,"Moonwalk (ters yürü)",FX.fxMoon)
feat(pFun,"Ragdoll (yığıl)",FX.fxRagdoll)
feat(pFun,"Hava yürüyüşü (E yüksel • Q alçal)",FX.fxAir)
pFun:Button("Otur",function() local h=hum(); if h then h.Sit=true end end)
pFun:Button("Yukarı fırla",function() local r2=root(); if r2 then r2.AssemblyLinearVelocity=Vector3.new(0,250,0) end end)
pFun:Section("Efektler (sadece sen görürsün)")
feat(pFun,"Gökkuşağı iz (trail)",FX.fxTrail)
feat(pFun,"Aura (parçacık)",FX.fxAura)
feat(pFun,"Disko ışıkları",FX.fxDisco)
feat(pFun,"Kamera dönüşü (barrel roll)",FX.fxRoll)
pFun:Slider("Kamera dönüş hızı",5,200,S.roll,function(v) S.roll=v end,5)
feat(pFun,"Tıkla-sil (Alt + Tık, yerel)",FX.fxClickDelete)

-- Oyuncu
pPly:Section("Hedef seç")
local setSel = pPly:Label("Seçili: —")
pPly:PlayerList(function(p) S.target=p; setSel("Seçili: "..(p and (p.DisplayName.." (@"..p.Name..")") or "—")) end)
pPly:Button("📍 Yanına ışınlan",function() if S.target then FX.tpTo(S.target) else notify("Önce oyuncu seç") end end)
pPly:Button("🎥 İzle",function() if S.target then FX.spectate(true) else notify("Önce oyuncu seç") end end)
pPly:Button("⏹ İzlemeyi bırak",function() FX.spectate(false) end)
pPly:Button("📋 Kullanıcı ID kopyala",function()
    if S.target and setclipboard then setclipboard(tostring(S.target.UserId)); notify("Kopyalandı")
    else notify("Seçim yok / panoya erişim yok") end
end)
pPly:Button("🎲 Rastgele oyuncuya ışınlan",function()
    local l={}
    for _, p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then l[#l+1]=p end end
    if #l>0 then FX.tpTo(l[math.random(#l)]) else notify("Başka oyuncu yok") end
end)
pPly:Section("Araçlar")
pPly:Button("🔎 Envanteri incele (Inspect)",function()
    if not S.target then notify("Önce oyuncu seç"); return end
    local GS=game:GetService("GuiService")
    pcall(function() GS:CloseInspectMenu() end)
    GS:InspectPlayerFromUserId(S.target.UserId)
end)
feat(pPly,"Dinle (hedefin ses konumu)",FX.fxSpy,false,true)
feat(pPly,"Tıkla-seç (Ctrl + oyuncuya tık)",FX.fxClickSelect,false,true)
pPly:Section("Koruma")
feat(pPly,"Anti-fling (oyuncu çarpışması kapalı)",FX.fxAntiFling)
S.onSelect=function(p) setSel("Seçili: "..p.DisplayName.." (@"..p.Name..")") end

-- Emote sayfası
setEmoteStatus = pEmote:Label("Emote: —")
pEmote:Section("R15 emote'lar ("..#EMOTE_LIST..")")
pEmote:Picker("Emote listesi — tıkla ve oynat",EMOTE_LIST,AN.playEmoteByName,6)
local favPicker = pEmote:Picker("⭐ Favoriler",Cfg.favorites,AN.playEmoteByName,3)
pEmote:Button("▶ Son emote'u tekrar oynat",AN.playLast)
pEmote:Button("⭐ Son emote'u favori ekle / çıkar",function()
    if Anim.last=="" then notify("Önce bir emote oynat"); return end
    local i=table.find(Cfg.favorites,Anim.last)
    if i then table.remove(Cfg.favorites,i); notify("Favoriden çıkarıldı")
    else table.insert(Cfg.favorites,Anim.last); notify("Favorilere eklendi ⭐") end
    favPicker.SetOptions(Cfg.favorites); saveSoon()
end)
pEmote:Button("⏹ Emote'u durdur",function() AN.stopEmote(); AN.stopPose(); AN.refreshAnims() end)
pEmote:Section("R6 emote'lar")
pEmote:Picker("R6 emote listesi",R6_LIST,AN.playR6,4)
pEmote:Section("Emote ayarları")
pEmote:Toggle("Döngü (loop)",false,function(v)
    Anim.loop=v; if Anim.track and v then Anim.track.Looped=true end; AN.updateStatus()
end)
pEmote:Toggle("Ters oynat",false,function(v)
    Anim.reverse=v
    if Anim.track and not Anim.freeze then Anim.track:AdjustSpeed(v and -math.abs(Anim.speed) or Anim.speed) end
end)
pEmote:Toggle("Dondur",false,function(v)
    Anim.freeze=v
    if Anim.track then Anim.track:AdjustSpeed(v and 0 or (Anim.reverse and -math.abs(Anim.speed) or Anim.speed)) end
end)
pEmote:Toggle("Hep oynat (hareket edince durmasın)",false,function(v) Anim.always=v end)
pEmote:Toggle("Zaman konumu uygula",false,function(v) Anim.timeOn=v end)
pEmote:Slider("Zaman konumu (%)",0,100,0,function(v)
    Anim.timePct=v
    if Anim.timeOn and Anim.track and Anim.track.Length>0 then Anim.track.TimePosition=v/100*Anim.track.Length end
end)
pEmote:Slider("Emote hızı",0,20,1,function(v)
    Anim.speed=v
    if Anim.track and not Anim.freeze then Anim.track:AdjustSpeed(Anim.reverse and -math.abs(v) or v) end
    AN.updateStatus()
end,.1)
feat(pEmote,"Rastgele emote (otomatik)",FX.fxRandomEmote,false,true)
feat(pEmote,"Emote sohbet komutu (/em isim)",FX.fxChatEmote,false,true)
pEmote:Section("Pozlar")
pEmote:Picker("Poz seç",POSE_NAMES,function(n) AN.startPose(POSES[n]) end,4)
pEmote:Button("⏹ Pozu bırak",AN.stopPose)
pEmote:Section("Senkron")
pEmote:Input("Sync hedefi (isim)","oyuncu adı + Enter",function(t)
    local p=AN.findPlayer(t)
    if p then S.syncTarget=p; notify("Sync hedefi: "..p.DisplayName) else notify("Oyuncu bulunamadı") end
end)
pEmote:Button("🔁 Hedefin emote'unu kopyala",function() AN.mirrorEmotes(S.syncTarget or S.target) end)
feat(pEmote,"Sürekli emote sync",FX.fxSyncEmote,false,true)

-- Animasyon paketi sayfası
setPackStatus = pPack:Label("Paket: —")
pPack:Section("Paket seç ("..#PACK_LIST.." adet, R15)")
pPack:Picker("Animasyon paketi — tıkla ve uygula",PACK_LIST,AN.applyPack,6)
pPack:Input("Paketi isimle uygula","örn: zombie + Enter",function(t)
    local n=AN.findPack(t); if n then AN.applyPack(n) else notify("Paket bulunamadı") end
end)
feat(pPack,"Rastgele paket (6 sn'de bir)",FX.fxRandomPack,false,true)
pPack:Button("♻ Animasyonları sıfırla",AN.resetAnims)
pPack:Button("💾 Animasyonlarımı kaydet",function()
    local txt=AN.animText()
    if not txt then notify("Animate bulunamadı"); return end
    if writefile then
        local fn=("%s_Anims_%d.lua"):format(LP.Name,math.random(1e5,9e5))
        writefile(fn,txt); notify("Kaydedildi: "..fn,3.5)
    elseif setclipboard then setclipboard(txt); notify("Panoya kopyalandı")
    else notify("Dosya/pano desteği yok") end
end)
pPack:Section("Paket ayarları")
pPack:Slider("Animasyon hızı",0,20,1,function(v) Anim.animSpeed=v; AN.updateStatus() end,.1)
feat(pPack,"Animasyon hızını sürekli uygula",FX.fxAnimSpeed,false,true)
feat(pPack,"Animasyonu dondur",FX.fxFreezePack,false,true)
feat(pPack,"Animasyon sohbet komutu (/a isim)",FX.fxChatAnim,false,true)
pPack:Section("Başka oyuncudan kopyala")
pPack:Button("📋 Hedefin animasyonunu kopyala",function()
    local p=S.syncTarget or S.target
    if not p then notify("Önce oyuncu seç"); return end
    if AN.copyPackFrom(p) then AN.refreshAnims(); notify("Kopyalandı: "..p.DisplayName)
    else notify("Değişiklik yok / Animate bulunamadı") end
end)
feat(pPack,"Sürekli animasyon sync",FX.fxSyncPack,false,true)

-- Özel animasyon sayfası
local slotLabel = pCustom:Label("Seçili slot: Idle")
S.slot = SLOT_BY_NAME["Idle"]
pCustom:Section("1) Slot seç")
pCustom:Picker("Slot",SLOT_NAMES,function(n) S.slot=SLOT_BY_NAME[n]; slotLabel("Seçili slot: "..n) end,4)
pCustom:Section("2) Ata")
pCustom:Picker("Emote'u slota ata",EMOTE_LIST,function(n)
    if not S.slot then return end
    AN.assignSlot(S.slot[2],EMOTES[n]); notify(S.slot[1].." ← "..n)
end,5)
pCustom:Picker("Paketten slota ata",PACK_LIST,function(n)
    if not S.slot then return end
    local field=S.slot[3]
    if not field then notify("Bu slot paketlerde yok — emote kullan"); return end
    local id=PACKS[n][field]
    if id then AN.assignSlot(S.slot[2],id); notify(S.slot[1].." ← "..n) else notify("Pakette bu animasyon yok") end
end,4)
pCustom:Section("Rastgele")
pCustom:Button("🎲 Rastgele paket animasyonları",function()
    for _, s in ipairs(SLOTS) do
        if s[3] then
            local p=PACKS[PACK_LIST[math.random(#PACK_LIST)]]
            if p[s[3]] then Cfg.custom[s[2]]=p[s[3]]; AN.setSlot(s[2],p[s[3]]) end
        end
    end
    AN.refreshAnims(); saveSoon(); notify("Rastgele animasyonlar uygulandı")
end)
pCustom:Button("🎲 Rastgele emote animasyonları",function()
    for _, s in ipairs(SLOTS) do
        if s[3] then
            local id=EMOTES[EMOTE_LIST[math.random(#EMOTE_LIST)]]
            Cfg.custom[s[2]]=id; AN.setSlot(s[2],id)
        end
    end
    AN.refreshAnims(); saveSoon(); notify("Rastgele emote animasyonları uygulandı")
end)
feat(pCustom,"Rastgele idle (3 sn'de bir)",FX.fxRandomIdle,false,true)
pCustom:Button("♻ Özel animasyonları sıfırla",AN.resetAnims)

-- Ayarlar sayfası
pSet:Section("Görünüm")
pSet:Colors("Tema rengi",{
    Color3.fromRGB(139,92,246),Color3.fromRGB(59,130,246),Color3.fromRGB(16,185,129),
    Color3.fromRGB(244,63,94),Color3.fromRGB(245,158,11),Color3.fromRGB(236,72,153),Color3.fromRGB(34,211,238),
},accentSet)
pSet:Slider("Menü boyutu (%)",50,130,math.floor(baseScale*100),function(v) S.uiScale=v/100; winScale.Scale=S.uiScale end,5)
pSet:Section("Tema")
pSet:Picker("Tema paleti",THEME_ORDER,function(n) applyTheme(n); notify("Tema: "..n) end,3)
local rgb={Cfg.accent[1],Cfg.accent[2],Cfg.accent[3]}
local function rgbApply() accentSet(Color3.fromRGB(rgb[1],rgb[2],rgb[3])) end
pSet:Slider("Vurgu • Kırmızı",0,255,rgb[1],function(v) rgb[1]=v; rgbApply() end)
pSet:Slider("Vurgu • Yeşil",0,255,rgb[2],function(v) rgb[2]=v; rgbApply() end)
pSet:Slider("Vurgu • Mavi",0,255,rgb[3],function(v) rgb[3]=v; rgbApply() end)
pSet:Input("Vurgu rengi HEX","#8B5CF6 + Enter",function(t)
    local hex=t:gsub("#",""):gsub("%s","")
    local r,g,b=tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16)
    if r and g and b then accentSet(Color3.fromRGB(r,g,b)) else notify("Geçersiz HEX") end
end)
pSet:Slider("Menü saydamlığı (%)",0,60,math.floor((Cfg.alpha or 0)*100+.5),function(v) winAlpha(v/100) end,5)
pSet:Toggle("Yüzen B butonu",true,function(v) fab.Visible=v end)
pSet:Input("Menü tuşu","örn: Insert, RightShift",function(t)
    local ok,kc=pcall(function() return Enum.KeyCode[t:gsub("%s","")] end)
    if ok and kc then S.menuKey=kc; Cfg.menuKey=kc.Name; saveSoon(); notify("Menü tuşu: "..kc.Name)
    else notify("Geçersiz tuş adı") end
end)
pSet:Section("Sohbet komutları")
pSet:Input("Emote öneki","varsayılan: /em",function(t)
    t=t:gsub("%s",""); if t=="" then return end
    if t:sub(1,1)~="/" then t="/"..t end
    Cfg.emotePrefix=t; saveSoon(); notify("Emote öneki: "..t)
end)
pSet:Input("Animasyon öneki","varsayılan: /a",function(t)
    t=t:gsub("%s",""); if t=="" then return end
    if t:sub(1,1)~="/" then t="/"..t end
    Cfg.animPrefix=t; saveSoon(); notify("Animasyon öneki: "..t)
end)
pSet:Section("Genel")
feat(pSet,"Anti-AFK",FX.fxAfk,true)
feat(pSet,"Her yerden duy",FX.fxHear,false,true)
pSet:Button("🔴 Tüm özellikleri kapat",function()
    for _, t in ipairs(Toggles) do t.Set(false) end; notify("Hepsi kapatıldı")
end)
pSet:Button("♻ Karakteri sıfırla",function() local h=hum(); if h then h.Health=0 end end)
pSet:Button("🔁 Yeniden katıl",FX.rejoin)
pSet:Button("🌐 Sunucu değiştir",FX.serverHop)
pSet:Section("Kayıt")
pSet:Button("💾 Ayarları kaydet",function()
    saveCfg(); notify(canFile and "Ayarlar kaydedildi" or "Executor dosya yazmayı desteklemiyor",3)
end)

-- ══════════════════════════════════════════════════
--  KAPATMA / TEMIZLEME
-- ══════════════════════════════════════════════════
local function destroy()
    for _, t in ipairs(Toggles) do pcall(t.Set,false) end
    pcall(function() workspace.Gravity=S.grav0 end)
    pcall(function() RunService:UnbindFromRenderStep("BotisRoll") end)
    pcall(function() FX.spectate(false) end)
    pcall(function() if S._deathConn then S._deathConn:Disconnect() end end)
    pcall(function() if S._oldOIM ~= nil then TextChatService.OnIncomingMessage = S._oldOIM or nil end end)
    pcall(function() game:GetService("SoundService"):SetListener(Enum.ListenerType.Camera) end)
    pcall(function() if S._bigPlat  then S._bigPlat:Destroy() end end)
    pcall(function() if S._hearPart then S._hearPart:Destroy() end end)
    pcall(function() if S._plat     then S._plat:Destroy() end end)
    pcall(function() if Anim.track  then Anim.track:Stop() end end)
    for _, k in ipairs({"_flyAtt","_flyLV","_flyAO"}) do
        if S[k] then pcall(function() S[k]:Destroy() end) end
    end
    pcall(saveCfg)
    for k in pairs(fc)    do unbind(k) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
    pcall(function() espFolder:Destroy() end)
    env.__BOTIS_CLEANUP = nil
end
pSet:Button("🗑 Menüyü kapat ve temizle",destroy)
env.__BOTIS_CLEANUP = destroy

-- ══════════════════════════════════════════════════
--  BAŞLATMA
-- ══════════════════════════════════════════════════
selectPage(pMove)
pcall(function() local k=Enum.KeyCode[Cfg.menuKey]; if k then S.menuKey=k end end)
pcall(function() if Cfg.theme~="Gece" then applyTheme(Cfg.theme) end end)
pcall(function() local a=Cfg.accent; setAccent(Color3.fromRGB(a[1],a[2],a[3])) end)
pcall(winAlpha, Cfg.alpha or 0)
task.spawn(function() AN.captureOrig(); AN.reapplyAnims(); AN.updateStatus() end)
toggleMenu(true)
notify(("BOTIS HUB yüklendi  •  %d emote  •  %d paket"):format(#EMOTE_LIST,#PACK_LIST), 4)
