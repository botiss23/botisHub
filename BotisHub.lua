--[[
    ══════════════════════════════════════════════════════════
     BOTIS HUB  •  Universal Roblox LocalScript
     Hafif • Toggle'lı • PC + Mobil • Tamamen istemci (client) taraflı
     Menü aç/kapa: RightShift  (mobilde soldaki yuvarlak "N" butonu)
    ══════════════════════════════════════════════════════════
]]

local env = (getgenv and getgenv()) or _G
if env.__BOTIS_CLEANUP then pcall(env.__BOTIS_CLEANUP) end

-- ═════════════════════════ SERVİSLER ═════════════════════════
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local Lighting        = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Stats           = game:GetService("Stats")

local LP = Players.LocalPlayer
local function getCam() return workspace.CurrentCamera end
local function hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end

-- ═════════════════════════ TEMA & YARDIMCILAR ═════════════════════════
local Theme = {
    bg     = Color3.fromRGB(16, 16, 22),
    panel  = Color3.fromRGB(23, 23, 31),
    item   = Color3.fromRGB(30, 30, 41),
    hover  = Color3.fromRGB(40, 40, 54),
    off    = Color3.fromRGB(56, 56, 72),
    stroke = Color3.fromRGB(46, 46, 62),
    text   = Color3.fromRGB(236, 236, 246),
    sub    = Color3.fromRGB(145, 145, 168),
    accent = Color3.fromRGB(139, 92, 246),
}
local FONT, FONTB = Enum.Font.GothamMedium, Enum.Font.GothamBold
local LEFT, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right

local function new(class, props, parent)
    local o = Instance.new(class)
    if props then for k, v in pairs(props) do o[k] = v end end
    if parent then o.Parent = parent end
    return o
end
local function round(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function stroke(o, c, t)
    return new("UIStroke", {Color = c, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end
local function tween(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

-- Vurgu rengi kayıt sistemi (tema rengi canlı değişsin diye)
local accStatic, accFns = {}, {}
local function acc(o, prop) accStatic[#accStatic + 1] = {o, prop}; o[prop] = Theme.accent; return o end
local function setAccent(c)
    Theme.accent = c
    for _, a in ipairs(accStatic) do if a[1].Parent then a[1][a[2]] = c end end
    for _, fn in ipairs(accFns) do pcall(fn) end
end

-- Bağlantı yönetimi
local conns = {}                       -- menü seviyesi bağlantılar
local function track(c) conns[#conns + 1] = c; return c end
local fc = {}                          -- özellik bağlantıları
local function unbind(k) if fc[k] then fc[k]:Disconnect(); fc[k] = nil end end
local function bind(k, sig, fn) unbind(k); fc[k] = sig:Connect(fn) end

-- Durum tablosu
local S = {
    speed = 50, jump = 100, fly = 60, cf = 60, spin = 360, roll = 40,
    fov = 90, time = 14, animSpeed = 1, grav0 = workspace.Gravity,
    uiScale = 1, target = nil,
}

-- Lighting yedekleme (kapatınca eski haline dönsün)
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

-- ═════════════════════════ GUI İSKELETİ ═════════════════════════
local function getGuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local t = Instance.new("Folder")
        local ok2 = pcall(function() t.Parent = cg end)
        t:Destroy()
        if ok2 then return cg end
    end
    return LP:WaitForChild("PlayerGui")
end

local gui = new("ScreenGui", {
    Name = "Bt" .. math.random(10000, 99999), ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, IgnoreGuiInset = true,
})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = getGuiParent()
local espFolder = new("Folder", {Name = "Ex" .. math.random(1000, 9999)}, gui.Parent)

-- Bildirimler
local toasts = new("Frame", {
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.fromOffset(260, 300), BackgroundTransparency = 1,
}, gui)
new("UIListLayout", {
    Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder,
}, toasts)

local function notify(text, dur)
    dur = dur or 2.2
    local f = new("Frame", {Size = UDim2.fromOffset(250, 34), BackgroundColor3 = Theme.panel,
        BackgroundTransparency = 1, BorderSizePixel = 0}, toasts)
    round(f, 8)
    local st = stroke(f, Theme.accent, 1); st.Transparency = 1
    local l = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = text,
        Font = FONT, TextSize = 12, TextColor3 = Theme.text, TextTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd}, f)
    tween(f, .2, {BackgroundTransparency = .05}); tween(st, .2, {Transparency = .35}); tween(l, .2, {TextTransparency = 0})
    task.delay(dur, function()
        tween(f, .25, {BackgroundTransparency = 1}); tween(st, .25, {Transparency = 1}); tween(l, .25, {TextTransparency = 1})
        task.wait(.3); f:Destroy()
    end)
end

local function run(fn, ...)
    if not fn then return end
    local ok, err = pcall(fn, ...)
    if not ok then notify("⚠ " .. tostring(err), 4); warn("[Botis] " .. tostring(err)) end
end

-- Pencere (holder: ölçeklenmeyen sürükleme kökü)
local WIN_W, WIN_H = 580, 390
local vp = (getCam() and getCam().ViewportSize) or Vector2.new(1280, 720)
local baseScale = math.clamp(math.min(vp.X / (WIN_W + 40), vp.Y / (WIN_H + 40)), 0.55, 1)
S.uiScale = baseScale

local holder = new("Frame", {Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1}, gui)
local win = new("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(WIN_W, WIN_H), BackgroundColor3 = Theme.bg, BorderSizePixel = 0}, holder)
local winScale = new("UIScale", {Scale = baseScale}, win)
round(win, 12); stroke(win, Theme.stroke, 1)

local top = new("Frame", {Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Theme.panel, BorderSizePixel = 0}, win)
round(top, 12)
new("Frame", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = Theme.panel, BorderSizePixel = 0}, top)
local dot = new("Frame", {Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(14, 16), BorderSizePixel = 0}, top)
round(dot, 5); acc(dot, "BackgroundColor3")
new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(32, 0), Size = UDim2.fromOffset(70, 42),
    Text = "BOTIS", Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = Theme.text, TextXAlignment = LEFT}, top)
new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(96, 2), Size = UDim2.fromOffset(120, 42),
    Text = "universal • v2.0", Font = FONT, TextSize = 11, TextColor3 = Theme.sub, TextXAlignment = LEFT}, top)

local searchBox = new("TextBox", {AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -44, .5, 0),
    Size = UDim2.fromOffset(150, 26), BackgroundColor3 = Theme.bg, BorderSizePixel = 0, Text = "",
    PlaceholderText = "🔍 Ara...", PlaceholderColor3 = Theme.sub, TextColor3 = Theme.text,
    Font = FONT, TextSize = 12, ClearTextOnFocus = false}, top)
round(searchBox, 8)
local closeBtn = new("TextButton", {AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0),
    Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Theme.item, Text = "–", Font = FONTB, TextSize = 16,
    TextColor3 = Theme.text, AutoButtonColor = false}, top)
round(closeBtn, 8)

local side = new("Frame", {Position = UDim2.fromOffset(8, 50), Size = UDim2.new(0, 124, 1, -58), BackgroundTransparency = 1}, win)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, side)
local content = new("Frame", {Position = UDim2.fromOffset(140, 50), Size = UDim2.new(1, -148, 1, -58), BackgroundTransparency = 1}, win)

local function draggable(handle, target)
    local st = {moved = false}
    local dragging, p0, t0
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; st.moved = false; p0 = i.Position; t0 = target.Position
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - p0
            if d.Magnitude > 6 then st.moved = true end
            if st.moved then
                target.Position = UDim2.new(t0.X.Scale, t0.X.Offset + d.X, t0.Y.Scale, t0.Y.Offset + d.Y)
            end
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
    return st
end
draggable(top, holder)

local function toggleMenu(v)
    if v == nil then v = not win.Visible end
    win.Visible = v
    if v then winScale.Scale = S.uiScale * .92; tween(winScale, .2, {Scale = S.uiScale}) end
end
closeBtn.Activated:Connect(function() toggleMenu(false) end)
track(UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == (S.menuKey or Enum.KeyCode.RightShift) then toggleMenu() end
end))

-- Mobil / hızlı erişim yüzen buton
local fab = new("TextButton", {Size = UDim2.fromOffset(42, 42), Position = UDim2.new(0, 14, .5, -21),
    BackgroundColor3 = Theme.panel, Text = "B", Font = Enum.Font.GothamBlack, TextSize = 18, AutoButtonColor = false}, gui)
round(fab, 21); acc(fab, "TextColor3"); acc(stroke(fab, Theme.accent, 1.5), "Color")
local fabDrag = draggable(fab, fab)
fab.Activated:Connect(function() if not fabDrag.moved then toggleMenu() end end)

-- ═════════════════════════ UI KÜTÜPHANESİ ═════════════════════════
local Pages, Current, searchText = {}, nil, ""
local Toggles = {}           -- yalnızca "özellik" toggle'ları (hepsini kapat / temizlik için)
local P = {}; P.__index = P

local function applyFilter()
    if not Current then return end
    for _, r in ipairs(Current.rows) do
        r.frame.Visible = (searchText == "") or (not r.sec and r.name:find(searchText, 1, true) ~= nil)
    end
end
track(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchText = searchBox.Text:lower(); applyFilter()
end))

local function selectPage(pg)
    Current = pg
    for _, p in pairs(Pages) do
        local on = p == pg
        p.sf.Visible = on; p.ind.Visible = on
        p.btn.BackgroundTransparency = on and .88 or 1
        p.lbl.TextColor3 = on and Theme.text or Theme.sub
    end
    applyFilter()
end

local pageOrder = 0
local function newPage(name, icon)
    local sf = new("ScrollingFrame", {Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.stroke,
        ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(), Visible = false}, content)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, sf)
    new("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}, sf)

    pageOrder = pageOrder + 1
    local btn = new("TextButton", {LayoutOrder = pageOrder, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false}, side)
    round(btn, 8); acc(btn, "BackgroundColor3")
    local ind = new("Frame", {Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, 4, .5, -8), BorderSizePixel = 0, Visible = false}, btn)
    round(ind, 2); acc(ind, "BackgroundColor3")
    local lbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -16, 1, 0),
        Text = icon .. "  " .. name, Font = FONT, TextSize = 13, TextColor3 = Theme.sub, TextXAlignment = LEFT}, btn)

    local pg = setmetatable({sf = sf, rows = {}, n = 0, btn = btn, ind = ind, lbl = lbl}, P)
    btn.Activated:Connect(function() selectPage(pg) end)
    Pages[name] = pg
    return pg
end

local function rowFrame(pg, h, name, sec)
    pg.n = pg.n + 1
    local f = new("Frame", {LayoutOrder = pg.n, Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = Theme.item, BorderSizePixel = 0}, pg.sf)
    round(f, 8)
    pg.rows[#pg.rows + 1] = {frame = f, name = (name or ""):lower(), sec = sec}
    return f
end
local function rowLabel(parent, text, wOff)
    return new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -(wOff or 70), 1, 0), Text = text, Font = FONT, TextSize = 13,
        TextColor3 = Theme.text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd}, parent)
end

function P:Section(text)
    self.n = self.n + 1
    local l = new("TextLabel", {LayoutOrder = self.n, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
        Text = "  " .. text, Font = FONTB, TextSize = 11, TextXAlignment = LEFT}, self.sf)
    acc(l, "TextColor3")
    self.rows[#self.rows + 1] = {frame = l, name = "", sec = true}
end

function P:Label(text)
    local f = rowFrame(self, 30, "")
    local l = rowLabel(f, text, 24); l.TextColor3 = Theme.sub; l.TextSize = 12
    return function(t) l.Text = t end
end

function P:Toggle(text, default, cb)
    local f = rowFrame(self, 36, text)
    rowLabel(f, text, 70)
    local sw = new("Frame", {AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0),
        Size = UDim2.fromOffset(38, 20), BackgroundColor3 = Theme.off, BorderSizePixel = 0}, f)
    round(sw, 10)
    local knob = new("Frame", {AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 3, .5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, sw)
    round(knob, 7)
    local btn = new("TextButton", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = ""}, f)
    local state = false
    local function paint()
        tween(sw, .15, {BackgroundColor3 = state and Theme.accent or Theme.off})
        tween(knob, .15, {Position = state and UDim2.new(1, -17, .5, 0) or UDim2.new(0, 3, .5, 0)})
    end
    local obj = {}
    function obj.Set(v, silent)
        state = v and true or false
        paint()
        if not silent then run(cb, state) end
    end
    function obj.Get() return state end
    btn.Activated:Connect(function() obj.Set(not state) end)
    accFns[#accFns + 1] = paint
    if default then obj.Set(true) end
    return obj
end

function P:Slider(text, min, max, default, cb, step)
    step = step or 1
    local f = rowFrame(self, 46, text)
    local l = rowLabel(f, text, 90); l.Position = UDim2.fromOffset(12, 4); l.Size = UDim2.new(1, -90, 0, 18)
    local val = new("TextLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 4),
        Size = UDim2.fromOffset(70, 18), Font = FONTB, TextSize = 12, TextColor3 = Theme.sub, TextXAlignment = RIGHT}, f)
    local bar = new("Frame", {Position = UDim2.new(0, 12, 1, -14), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = Theme.off, BorderSizePixel = 0}, f)
    round(bar, 3)
    local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BorderSizePixel = 0}, bar)
    round(fill, 3); acc(fill, "BackgroundColor3")
    local hit = new("TextButton", {BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 1, -20)}, f)

    local function set(v, silent)
        v = math.clamp(math.floor(v / step + .5) * step, min, max)
        v = tonumber(string.format("%.3f", v))
        fill.Size = UDim2.fromScale((v - min) / (max - min), 1)
        val.Text = tostring(v)
        if not silent then run(cb, v) end
    end
    local dragging = false
    local function fromX(x) set(min + (max - min) * math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)) end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; self.sf.ScrollingEnabled = false; fromX(i.Position.X)
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromX(i.Position.X) end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false; self.sf.ScrollingEnabled = true
        end
    end))
    set(default, true)
    return {Set = set}
end

function P:Button(text, cb)
    local f = rowFrame(self, 34, text)
    local b = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text, Font = FONT,
        TextSize = 13, TextColor3 = Theme.text, AutoButtonColor = false}, f)
    b.MouseEnter:Connect(function() tween(f, .12, {BackgroundColor3 = Theme.hover}) end)
    b.MouseLeave:Connect(function() tween(f, .12, {BackgroundColor3 = Theme.item}) end)
    b.Activated:Connect(function() run(cb) end)
end

function P:Input(text, placeholder, cb)
    local f = rowFrame(self, 36, text)
    rowLabel(f, text, 170)
    local tb = new("TextBox", {AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 0), Size = UDim2.fromOffset(150, 24),
        BackgroundColor3 = Theme.bg, BorderSizePixel = 0, Text = "", PlaceholderText = placeholder, PlaceholderColor3 = Theme.sub,
        TextColor3 = Theme.text, Font = FONT, TextSize = 12, ClearTextOnFocus = false}, f)
    round(tb, 6)
    tb.FocusLost:Connect(function(enter) if enter then run(cb, tb.Text) end end)
end

function P:Colors(text, list, cb)
    local f = rowFrame(self, 40, text)
    rowLabel(f, text, #list * 28 + 30)
    local h = new("Frame", {AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0),
        Size = UDim2.fromOffset(#list * 28, 24), BackgroundTransparency = 1}, f)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Center}, h)
    for _, c in ipairs(list) do
        local b = new("TextButton", {Size = UDim2.fromOffset(22, 22), BackgroundColor3 = c, Text = "", AutoButtonColor = false}, h)
        round(b, 11)
        b.Activated:Connect(function() run(cb, c) end)
    end
end

function P:PlayerList(onSelect)
    local f = rowFrame(self, 130, "oyuncu listesi")
    local sf = new("ScrollingFrame", {Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, f)
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.Name}, sf)
    local items = {}
    local function paint()
        for p, b in pairs(items) do
            b.BackgroundColor3 = (S.target == p) and Theme.accent or Theme.bg
        end
    end
    local function refresh()
        for _, b in pairs(items) do b:Destroy() end
        items = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local b = new("TextButton", {Name = p.Name:lower(), Size = UDim2.new(1, -4, 0, 26), BorderSizePixel = 0,
                    Text = "  " .. p.DisplayName .. "  (@" .. p.Name .. ")", Font = FONT, TextSize = 12, TextColor3 = Theme.text,
                    TextXAlignment = LEFT, AutoButtonColor = false}, sf)
                round(b, 6)
                b.Activated:Connect(function() onSelect(p); paint() end)
                items[p] = b
            end
        end
        paint()
    end
    accFns[#accFns + 1] = paint
    track(Players.PlayerAdded:Connect(function() task.defer(refresh) end))
    track(Players.PlayerRemoving:Connect(function(p)
        if S.target == p then S.target = nil; onSelect(nil) end
        task.defer(refresh)
    end))
    refresh()
end

-- ═════════════════════════ BOTIS: ARANABİLİR LİSTE SEÇİCİ ═════════════════════════
function P:Picker(text, options, cb, lines)
    local f = rowFrame(self, 54 + (lines or 5) * 28, text)
    local l = rowLabel(f, text, 20); l.Position = UDim2.fromOffset(12, 4); l.Size = UDim2.new(1, -24, 0, 18)
    local sb = new("TextBox", {Position = UDim2.fromOffset(8, 24), Size = UDim2.new(1, -16, 0, 22), BackgroundColor3 = Theme.bg,
        BorderSizePixel = 0, Text = "", PlaceholderText = "🔍 filtrele...", PlaceholderColor3 = Theme.sub,
        TextColor3 = Theme.text, Font = FONT, TextSize = 12, ClearTextOnFocus = false}, f)
    round(sb, 6)
    local sf = new("ScrollingFrame", {Position = UDim2.fromOffset(8, 50), Size = UDim2.new(1, -16, 1, -56), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, f)
    new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, sf)

    local list, limit, pool, names = options or {}, 60, {}, {}
    local function mk(i)
        local b = new("TextButton", {LayoutOrder = i, Size = UDim2.new(1, -6, 0, 26), BackgroundColor3 = Theme.bg, BorderSizePixel = 0,
            Font = FONT, TextSize = 12, TextColor3 = Theme.text, TextXAlignment = LEFT, AutoButtonColor = false,
            TextTruncate = Enum.TextTruncate.AtEnd}, sf)
        round(b, 6)
        b.MouseEnter:Connect(function() tween(b, .1, {BackgroundColor3 = Theme.hover}) end)
        b.MouseLeave:Connect(function() tween(b, .1, {BackgroundColor3 = Theme.bg}) end)
        b.Activated:Connect(function() if names[i] then run(cb, names[i]) end end)
        return b
    end
    local render
    local more = new("TextButton", {Size = UDim2.new(1, -6, 0, 24), BackgroundTransparency = 1, Font = FONTB, TextSize = 11,
        TextColor3 = Theme.sub, Visible = false, AutoButtonColor = false}, sf)
    more.Activated:Connect(function() limit = limit + 60; render() end)

    function render()
        local q = sb.Text:lower()
        local n = 0
        for _, name in ipairs(list) do
            if q == "" or name:lower():find(q, 1, true) then
                n = n + 1
                if n <= limit then
                    local b = pool[n]
                    if not b then b = mk(n); pool[n] = b end
                    names[n] = name; b.Text = "  " .. name; b.Visible = true
                end
            end
        end
        for i = math.min(n, limit) + 1, #pool do pool[i].Visible = false; names[i] = nil end
        more.Visible = n > limit
        more.LayoutOrder = limit + 1
        if n > limit then more.Text = "▼ daha fazla (" .. (n - limit) .. ")" end
    end
    track(sb:GetPropertyChangedSignal("Text"):Connect(function() limit = 60; sf.CanvasPosition = Vector2.zero; render() end))
    render()
    return {SetOptions = function(l) list = l or {}; limit = 60; render() end}
end

-- ═════════════════════════ ÖZELLİKLER ═════════════════════════
local Active = {}   -- açık özellikler (respawn sonrası yeniden uygulanır)

-- ── Hareket ──
local function fxSpeed(on)
    unbind("speed")
    local h = hum()
    if on then
        if h and not S._ws then S._ws = h.WalkSpeed end
        bind("speed", RunService.Heartbeat, function() local h = hum(); if h then h.WalkSpeed = S.speed end end)
    else
        if h and S._ws then h.WalkSpeed = S._ws end
        S._ws = nil
    end
end

local function fxJump(on)
    unbind("jump")
    local h = hum()
    if on then
        if h and not S._jp then S._jp = {h.UseJumpPower, h.JumpPower} end
        bind("jump", RunService.Heartbeat, function()
            local h = hum(); if h then h.UseJumpPower = true; h.JumpPower = S.jump end
        end)
    else
        if h and S._jp then h.UseJumpPower = S._jp[1]; h.JumpPower = S._jp[2] end
        S._jp = nil
    end
end

local function fxInfJump(on)
    unbind("inf")
    if on then bind("inf", UIS.JumpRequest, function()
        local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end) end
end

local flyBV, flyBG
local function fxFly(on)
    unbind("fly")
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local h, r = hum(), root()
    if not on then if h then h.PlatformStand = false end return end
    if not (h and r) then return end
    flyBV = new("BodyVelocity", {MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.zero}, r)
    flyBG = new("BodyGyro", {MaxTorque = Vector3.new(9e9, 9e9, 9e9), P = 9e4, CFrame = r.CFrame}, r)
    bind("fly", RunService.RenderStepped, function()
        local r, h, cam = root(), hum(), getCam()
        if not (r and h and cam and flyBV and flyBV.Parent) then return end
        h.PlatformStand = true
        -- hareket yönü: PC'de WASD, mobilde joystick (kameraya göre)
        local lo = cam.CFrame:VectorToObjectSpace(h.MoveDirection)
        local flat = Vector3.new(lo.X, 0, lo.Z)
        if flat.Magnitude > 0 then flat = flat.Unit * math.min(h.MoveDirection.Magnitude, 1) end
        local dir = cam.CFrame.RightVector * flat.X + cam.CFrame.LookVector * (-flat.Z)
        if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end
        flyBV.Velocity = dir * S.fly
        flyBG.CFrame = CFrame.new(r.Position, r.Position + cam.CFrame.LookVector)
    end)
end

local function fxNoclip(on)
    unbind("noclip")
    if on then bind("noclip", RunService.Stepped, function()
        local c = LP.Character
        if c then for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end end
    end) end
end

local function fxCFSpeed(on)
    unbind("cf")
    if on then bind("cf", RunService.Heartbeat, function(dt)
        local h, r = hum(), root()
        if h and r and h.MoveDirection.Magnitude > 0 then r.CFrame = r.CFrame + h.MoveDirection * S.cf * dt end
    end) end
end

local function fxBhop(on)
    unbind("bhop")
    if on then bind("bhop", RunService.Heartbeat, function()
        local h = hum()
        if h and h.MoveDirection.Magnitude > 0 and h.FloorMaterial ~= Enum.Material.Air then h.Jump = true end
    end) end
end

local function fxClickTP(on)
    unbind("ctp")
    if on then bind("ctp", UIS.InputBegan, function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            local r = root()
            if r then r.CFrame = CFrame.new(LP:GetMouse().Hit.Position + Vector3.new(0, 3, 0)) end
        end
    end) end
end

local function fxVoid(on)
    unbind("void")
    if on then
        local safe
        bind("void", RunService.Heartbeat, function()
            local r, h = root(), hum()
            if not (r and h) then return end
            if h.FloorMaterial ~= Enum.Material.Air then safe = r.CFrame end
            if safe and r.Position.Y < workspace.FallenPartsDestroyHeight + 60 then
                r.AssemblyLinearVelocity = Vector3.zero
                r.CFrame = safe + Vector3.new(0, 4, 0)
            end
        end)
    end
end

local function fxAfk(on)
    unbind("afk")
    if on then
        local VU = game:GetService("VirtualUser")
        bind("afk", LP.Idled, function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
    end
end

-- ── Görsel: ESP ──
local ESP = {objs = {}, t = 0, opt = {chams = true, names = true, dist = true, health = true, tracers = false, team = false}}
local hasDrawing = pcall(function() Drawing.new("Line"):Remove() end)

local function espClear(plr)
    local o = ESP.objs[plr]; if not o then return end
    ESP.objs[plr] = nil
    if o.cc then o.cc:Disconnect() end
    if o.hl then o.hl:Destroy() end
    if o.bb then o.bb:Destroy() end
    if o.ln then pcall(function() o.ln:Remove() end) end
end

local function espBuild(plr, c)
    local o = ESP.objs[plr]; if not o then return end
    if o.hl then o.hl:Destroy(); o.hl = nil end
    if o.bb then o.bb:Destroy(); o.bb = nil end
    local head = c:WaitForChild("Head", 5)
    if not head or ESP.objs[plr] ~= o or plr.Character ~= c then return end
    -- Not: Roblox aynı anda en fazla ~31 Highlight çizer.
    o.hl = new("Highlight", {Adornee = c, FillTransparency = .65, OutlineTransparency = 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, c)
    o.bb = new("BillboardGui", {Adornee = head, AlwaysOnTop = true, Size = UDim2.fromOffset(220, 40),
        StudsOffset = Vector3.new(0, 2.6, 0)}, espFolder)
    o.tl = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = FONTB, TextSize = 13,
        TextStrokeTransparency = .4, TextColor3 = Color3.new(1, 1, 1), Text = ""}, o.bb)
end

local function espStep(dt)
    ESP.t = ESP.t + dt
    local doText = ESP.t > .12
    if doText then ESP.t = 0 end
    local cam, mr = getCam(), root()
    for plr, o in pairs(ESP.objs) do
        local c = plr.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local col = (ESP.opt.team and plr.Team) and plr.TeamColor.Color or Color3.fromRGB(255, 75, 95)
        if o.hl then o.hl.Enabled = ESP.opt.chams; o.hl.FillColor = col; o.hl.OutlineColor = col end
        if o.bb and doText then
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local t = {}
            if ESP.opt.names then t[#t + 1] = plr.DisplayName end
            if ESP.opt.dist and mr and r then t[#t + 1] = "[" .. math.floor((mr.Position - r.Position).Magnitude) .. "m]" end
            if ESP.opt.health and h then t[#t + 1] = math.floor(h.Health) .. "HP" end
            o.tl.Text = table.concat(t, " "); o.tl.TextColor3 = col
            o.bb.Enabled = #t > 0
        end
        if hasDrawing then
            if ESP.opt.tracers and r and cam then
                if not o.ln then o.ln = Drawing.new("Line"); o.ln.Thickness = 1.5 end
                local p, vis = cam:WorldToViewportPoint(r.Position)
                o.ln.Visible = vis; o.ln.Color = col
                o.ln.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                o.ln.To = Vector2.new(p.X, p.Y)
            elseif o.ln then o.ln.Visible = false end
        end
    end
end

local function fxESP(on)
    unbind("espStep"); unbind("espAdd"); unbind("espRem")
    for plr in pairs(ESP.objs) do espClear(plr) end
    if not on then return end
    local function add(plr)
        if plr == LP or ESP.objs[plr] then return end
        local o = {}; ESP.objs[plr] = o
        o.cc = plr.CharacterAdded:Connect(function(c) task.spawn(espBuild, plr, c) end)
        if plr.Character then task.spawn(espBuild, plr, plr.Character) end
    end
    for _, p in ipairs(Players:GetPlayers()) do add(p) end
    bind("espAdd", Players.PlayerAdded, add)
    bind("espRem", Players.PlayerRemoving, espClear)
    bind("espStep", RunService.RenderStepped, espStep)
end

-- ── Görsel: dünya / kamera ──
local function fxFullbright(on)
    unbind("fb")
    if on then bind("fb", RunService.Heartbeat, function()
        lset("Brightness", 2); lset("GlobalShadows", false)
        lset("Ambient", Color3.fromRGB(190, 190, 190)); lset("OutdoorAmbient", Color3.fromRGB(190, 190, 190))
    end)
    else lrestore("Brightness", "GlobalShadows", "Ambient", "OutdoorAmbient") end
end

local function fxNoFog(on)
    unbind("fog")
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if on then
        if atm and S._atm == nil then S._atm = atm.Density end
        bind("fog", RunService.Heartbeat, function()
            lset("FogEnd", 9e8); lset("FogStart", 9e8)
            local a = Lighting:FindFirstChildOfClass("Atmosphere"); if a then a.Density = 0 end
        end)
    else
        lrestore("FogEnd", "FogStart")
        if atm and S._atm then atm.Density = S._atm end
        S._atm = nil
    end
end

local function fxTime(on)
    unbind("time")
    if on then bind("time", RunService.Heartbeat, function() lset("ClockTime", S.time) end)
    else lrestore("ClockTime") end
end

local xr = setmetatable({}, {__mode = "k"})
local function inChar(p)
    local m = p.Parent
    for _ = 1, 2 do
        if m and m:IsA("Model") and Players:GetPlayerFromCharacter(m) then return true end
        m = m and m.Parent
    end
    return false
end
local function fxXray(on)
    unbind("xr")
    S._xrTok = (S._xrTok or 0) + 1
    local tok = S._xrTok
    if on then
        local function apply(p)
            if p:IsA("BasePart") and not inChar(p) then xr[p] = true; p.LocalTransparencyModifier = .6 end
        end
        task.spawn(function()
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if S._xrTok ~= tok then return end
                apply(d); n = n + 1
                if n % 1500 == 0 then task.wait() end
            end
        end)
        bind("xr", workspace.DescendantAdded, apply)
    else
        for p in pairs(xr) do if p.Parent then p.LocalTransparencyModifier = 0 end end
        table.clear(xr)
    end
end

local function refreshFov()
    unbind("fov")
    local cam = getCam()
    if S.fovOn or S.zoomOn then
        S._defFov = S._defFov or (cam and cam.FieldOfView) or 70
        bind("fov", RunService.RenderStepped, function()
            local cam = getCam(); if not cam then return end
            local target = (S.zoomOn and S.zooming) and 20 or (S.fovOn and S.fov or S._defFov)
            cam.FieldOfView = cam.FieldOfView + (target - cam.FieldOfView) * .25
        end)
    else
        if cam and S._defFov then cam.FieldOfView = S._defFov end
        S._defFov = nil
    end
end
local function fxFov(on) S.fovOn = on; refreshFov() end
local function fxZoom(on)
    S.zoomOn = on; S.zooming = false
    unbind("zi"); unbind("zo")
    if on then
        bind("zi", UIS.InputBegan, function(i, g) if not g and i.KeyCode == Enum.KeyCode.C then S.zooming = true end end)
        bind("zo", UIS.InputEnded, function(i) if i.KeyCode == Enum.KeyCode.C then S.zooming = false end end)
    end
    refreshFov()
end

local function fxUnlockZoom(on)
    if on then
        S._zmax = S._zmax or LP.CameraMaxZoomDistance
        S._zmin = S._zmin or LP.CameraMinZoomDistance
        LP.CameraMaxZoomDistance = 1e5; LP.CameraMinZoomDistance = 0
    else
        if S._zmax then LP.CameraMaxZoomDistance = S._zmax end
        if S._zmin then LP.CameraMinZoomDistance = S._zmin end
        S._zmax, S._zmin = nil, nil
    end
end
local function fxCamNoclip(on)
    LP.DevCameraOcclusionMode = on and Enum.DevCameraOcclusionMode.Invisicam or Enum.DevCameraOcclusionMode.Zoom
end

-- Nişangah
local cross = new("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(20, 20),
    BackgroundTransparency = 1, Visible = false}, gui)
for _, s in ipairs({{UDim2.fromOffset(20, 2), UDim2.fromOffset(0, 9)}, {UDim2.fromOffset(2, 20), UDim2.fromOffset(9, 0)}}) do
    local b = new("Frame", {Size = s[1], Position = s[2], BorderSizePixel = 0}, cross); acc(b, "BackgroundColor3")
end
local function fxCross(on) cross.Visible = on end

-- FPS / Ping HUD
local hud = new("TextLabel", {AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 8), Size = UDim2.fromOffset(170, 24),
    BackgroundColor3 = Theme.bg, BackgroundTransparency = .15, Font = FONTB, TextSize = 12, TextColor3 = Theme.text, Text = "", Visible = false}, gui)
round(hud, 8); stroke(hud, Theme.stroke, 1)
local function fxHud(on)
    unbind("hud"); hud.Visible = on
    if on then
        local a, n = 0, 0
        bind("hud", RunService.RenderStepped, function(dt)
            a = a + dt; n = n + 1
            if a >= .5 then
                local ping = 0
                pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                hud.Text = ("FPS %d  •  Ping %d ms"):format(math.floor(n / a + .5), ping)
                a, n = 0, 0
            end
        end)
    end
end

local function fpsBoost()
    notify("FPS Booster uygulanıyor...")
    task.spawn(function()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        Lighting.GlobalShadows = false
        local function opt(d)
            if d:IsA("BasePart") and not d:IsA("Terrain") then d.Material = Enum.Material.SmoothPlastic; d.Reflectance = 0; d.CastShadow = false
            elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then d.Enabled = false end
        end
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            pcall(opt, d); n = n + 1
            if n % 1500 == 0 then task.wait() end
        end
        for _, d in ipairs(Lighting:GetDescendants()) do if d:IsA("PostEffect") then d.Enabled = false end end
        notify("FPS Booster tamam ✔")
    end)
end

-- ── Eğlence ──
local function fxSpin(on)
    unbind("spin")
    if on then bind("spin", RunService.Heartbeat, function(dt)
        local r = root(); if r then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(S.spin) * dt, 0) end
    end) end
end

local function fxRagdoll(on)
    unbind("rag")
    local h = hum()
    if on then bind("rag", RunService.Stepped, function()
        local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Physics) end
    end)
    elseif h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

local function fxMoon(on)
    unbind("moon")
    local h = hum()
    if on then bind("moon", RunService.Heartbeat, function()
        local h, r = hum(), root()
        if h and r then
            h.AutoRotate = false
            local md = h.MoveDirection
            if md.Magnitude > .1 then r.CFrame = CFrame.new(r.Position, r.Position - md) end
        end
    end)
    elseif h then h.AutoRotate = true end
end

local function fxRoll(on)
    pcall(function() RunService:UnbindFromRenderStep("BotisRoll") end)
    if on then
        local ang = 0
        RunService:BindToRenderStep("BotisRoll", Enum.RenderPriority.Camera.Value + 1, function(dt)
            ang = (ang + dt * S.roll) % 360
            local cam = getCam(); if cam then cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.rad(ang)) end
        end)
    end
end

local function fxAir(on)
    unbind("air")
    if S._plat then S._plat:Destroy(); S._plat = nil end
    if not on then return end
    local r, h = root(), hum()
    if not (r and h) then return end
    local feet = r.Position.Y - (h.RigType == Enum.HumanoidRigType.R6 and 3 or (h.HipHeight + r.Size.Y / 2))
    local y = feet - .5
    local p = new("Part", {Size = Vector3.new(10, 1, 10), Anchored = true, Transparency = .85, Material = Enum.Material.Neon}, workspace)
    acc(p, "Color")
    S._plat = p
    bind("air", RunService.Heartbeat, function(dt)
        local r = root(); if not r then return end
        if UIS:IsKeyDown(Enum.KeyCode.E) then y = y + 25 * dt elseif UIS:IsKeyDown(Enum.KeyCode.Q) then y = y - 25 * dt end
        p.CFrame = CFrame.new(r.Position.X, y, r.Position.Z)
    end)
end

local function fxTrail(on)
    if S._trail then for _, o in ipairs(S._trail) do o:Destroy() end S._trail = nil end
    local r = root()
    if on and r then
        local a0 = new("Attachment", {Position = Vector3.new(0, 1, 0)}, r)
        local a1 = new("Attachment", {Position = Vector3.new(0, -1, 0)}, r)
        local kp = {}
        for i = 0, 5 do kp[#kp + 1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV(i / 6, .8, 1)) end
        local tr = new("Trail", {Attachment0 = a0, Attachment1 = a1, Lifetime = .7, LightEmission = 1,
            Transparency = NumberSequence.new(0, 1), Color = ColorSequence.new(kp)}, r)
        S._trail = {a0, a1, tr}
    end
end

local function fxAura(on)
    if S._aura then S._aura:Destroy(); S._aura = nil end
    local r = root()
    if on and r then
        S._aura = new("ParticleEmitter", {Rate = 35, Lifetime = NumberRange.new(.8, 1.4), Speed = NumberRange.new(2, 5),
            SpreadAngle = Vector2.new(180, 180), LightEmission = 1, RotSpeed = NumberRange.new(-90, 90),
            Size = NumberSequence.new({NumberSequenceKeypoint.new(0, .7), NumberSequenceKeypoint.new(1, 0)}),
            Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .2), NumberSequenceKeypoint.new(1, 1)}),
            Color = ColorSequence.new(Theme.accent)}, r)
    end
end

local function fxDisco(on)
    unbind("disco")
    if on then bind("disco", RunService.Heartbeat, function()
        local c = Color3.fromHSV((tick() * .15) % 1, .8, 1)
        lset("Ambient", c); lset("OutdoorAmbient", c)
    end)
    else lrestore("Ambient", "OutdoorAmbient") end
end

local function fxClickDelete(on)
    unbind("cdel")
    if on then bind("cdel", UIS.InputBegan, function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftAlt) then
            local t = LP:GetMouse().Target
            if t and not inChar(t) and not t:IsA("Terrain") then t:Destroy() end   -- sadece senin ekranında
        end
    end) end
end

-- ── Oyuncu ──
local function fxAntiFling(on)
    unbind("af")
    if on then bind("af", RunService.Stepped, function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                for _, d in ipairs(p.Character:GetChildren()) do
                    if d:IsA("BasePart") then d.CanCollide = false end
                end
            end
        end
    end) end
end

local function spectate(on)
    local cam = getCam(); if not cam then return end
    if on and S.target and S.target.Character then
        local h = S.target.Character:FindFirstChildOfClass("Humanoid")
        if h then cam.CameraSubject = h; return end
    end
    cam.CameraSubject = hum()
end

local function tpTo(plr)
    local r = root()
    local tr = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if r and tr then r.CFrame = tr.CFrame * CFrame.new(0, 0, 3) else notify("Hedef bulunamadı") end
end

local function rejoin()
    if #Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, LP)
    else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end
end

local function serverHop()
    notify("Sunucu aranıyor...")
    task.spawn(function()
        local ok, res = pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if not ok or not res or not res.data then notify("Sunucu listesi alınamadı (executor HttpGet desteklemiyor olabilir)", 4); return end
        local list = {}
        for _, s in ipairs(res.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then list[#list + 1] = s.id end
        end
        if #list == 0 then notify("Uygun sunucu yok"); return end
        TeleportService:TeleportToPlaceInstance(game.PlaceId, list[math.random(#list)], LP)
    end)
end

-- Özellik toggle'ı: respawn sonrası otomatik yeniden uygular
local function feat(page, text, fn, default, noReapply)
    local t = page:Toggle(text, default, function(on)
        Active[text] = (on and not noReapply) and fn or nil
        fn(on)
    end)
    Toggles[#Toggles + 1] = t
    return t
end

track(LP.CharacterAdded:Connect(function(c)
    c:WaitForChild("HumanoidRootPart", 10); c:WaitForChild("Humanoid", 10); task.wait(.3)
    for _, fn in pairs(Active) do task.spawn(function() run(fn, true) end) end
end))

-- ═════════════════════════ BOTIS: AYAR DOSYASI ═════════════════════════
local TextChatService = game:GetService("TextChatService")
local CFG_DIR, CFG_FILE = "BotisHub", "BotisHub/settings.json"
local Cfg = {favorites = {}, lastEmote = "", pack = "", custom = {}, theme = "Gece", accent = {139, 92, 246},
    alpha = 0, menuKey = "RightShift", emotePrefix = "/em", animPrefix = "/a"}
local canFile = (writefile and readfile and isfile) and true or false
local function saveCfg()
    if not canFile then return end
    pcall(function()
        if makefolder and isfolder and not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
        writefile(CFG_FILE, HttpService:JSONEncode(Cfg))
    end)
end
local saveStamp = 0
local function saveSoon()
    saveStamp = tick()
    local s = saveStamp
    task.delay(2, function() if s == saveStamp then saveCfg() end end)
end
pcall(function()
    if canFile and isfile(CFG_FILE) then
        for k, v in pairs(HttpService:JSONDecode(readfile(CFG_FILE))) do Cfg[k] = v end
    end
end)
if type(Cfg.accent) ~= "table" or #Cfg.accent < 3 then Cfg.accent = {139, 92, 246} end
if type(Cfg.favorites) ~= "table" then Cfg.favorites = {} end
if type(Cfg.custom) ~= "table" then Cfg.custom = {} end

-- ═════════════════════════ BOTIS: TEMA MOTORU ═════════════════════════
local THEME_KEYS = {"bg", "panel", "item", "hover", "off", "stroke", "text", "sub"}
local THEME_ORDER = {"Gece", "Gece Yarısı", "AMOLED", "Orman", "Gül", "Açık"}
local THEMES = {
    ["Gece"]        = {bg = {16, 16, 22}, panel = {23, 23, 31}, item = {30, 30, 41}, hover = {40, 40, 54}, off = {56, 56, 72}, stroke = {46, 46, 62}, text = {236, 236, 246}, sub = {145, 145, 168}},
    ["Gece Yarısı"] = {bg = {10, 14, 28}, panel = {15, 21, 40}, item = {22, 30, 54}, hover = {32, 43, 74}, off = {50, 62, 98}, stroke = {38, 50, 86}, text = {232, 238, 255}, sub = {140, 152, 190}},
    ["AMOLED"]      = {bg = {0, 0, 0}, panel = {10, 10, 10}, item = {18, 18, 18}, hover = {30, 30, 30}, off = {52, 52, 52}, stroke = {34, 34, 34}, text = {245, 245, 245}, sub = {140, 140, 140}},
    ["Orman"]       = {bg = {14, 22, 18}, panel = {20, 31, 25}, item = {27, 42, 34}, hover = {37, 57, 46}, off = {52, 76, 62}, stroke = {40, 62, 50}, text = {232, 245, 236}, sub = {140, 170, 150}},
    ["Gül"]         = {bg = {24, 14, 20}, panel = {34, 20, 28}, item = {46, 28, 38}, hover = {62, 38, 52}, off = {86, 54, 72}, stroke = {66, 40, 56}, text = {250, 235, 242}, sub = {185, 145, 165}},
    ["Açık"]        = {bg = {244, 244, 248}, panel = {232, 232, 240}, item = {222, 222, 232}, hover = {208, 208, 222}, off = {186, 186, 204}, stroke = {200, 200, 214}, text = {28, 28, 40}, sub = {100, 100, 124}},
}
local function ckey(c) return math.floor(c.R * 255 + .5) .. "," .. math.floor(c.G * 255 + .5) .. "," .. math.floor(c.B * 255 + .5) end

local function applyTheme(name)
    local t = THEMES[name]; if not t then return end
    local map, fresh = {}, {}
    for _, k in ipairs(THEME_KEYS) do
        fresh[k] = Color3.fromRGB(t[k][1], t[k][2], t[k][3])
        map[ckey(Theme[k])] = fresh[k]
    end
    local function remap(o, prop)
        local n = map[ckey(o[prop])]
        if n then o[prop] = n end
    end
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("GuiObject") then
            remap(d, "BackgroundColor3")
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then remap(d, "TextColor3") end
            if d:IsA("TextBox") then remap(d, "PlaceholderColor3") end
            if d:IsA("ScrollingFrame") then remap(d, "ScrollBarImageColor3") end
        elseif d:IsA("UIStroke") then
            remap(d, "Color")
        end
    end
    for k, v in pairs(fresh) do Theme[k] = v end
    Cfg.theme = name; saveSoon()
end

local function accentSet(c)
    setAccent(c)
    Cfg.accent = {math.floor(c.R * 255 + .5), math.floor(c.G * 255 + .5), math.floor(c.B * 255 + .5)}
    saveSoon()
end

local function winAlpha(v)
    win.BackgroundTransparency = v; top.BackgroundTransparency = v
    for _, c in ipairs(top:GetChildren()) do
        if c:IsA("Frame") and c.Size.Y.Offset == 12 then c.BackgroundTransparency = v end
    end
    Cfg.alpha = v; saveSoon()
end

-- ═════════════════════════ BOTIS: EMOTE VERİLERİ (R15) ═════════════════════════
local EMOTES = {
    ["Fashion"] = 3333331310, ["Baby Dance"] = 4265725525, ["Cha-Cha"] = 6862001787, ["Monkey"] = 3333499508,
    ["Shuffle"] = 4349242221, ["Shuffle 2"] = 17748314784, ["Top Rock"] = 3361276673, ["Around Town"] = 3303391864,
    ["Fancy Feet"] = 3333432454, ["Hype Dance"] = 3695333486, ["Bodybuilder"] = 3333387824, ["Idol"] = 4101966434,
    ["Curtsy"] = 4555816777, ["Happy"] = 4841405708, ["Quiet Waves"] = 7465981288, ["Sleep"] = 4686925579,
    ["Floss Dance"] = 5917459365, ["Shy"] = 3337978742, ["Godlike"] = 3337994105, ["Hero Landing"] = 5104344710,
    ["High Wave"] = 5915690960, ["Cower"] = 4940563117, ["Bored"] = 5230599789, ["Show Dem Wrists -KSI"] = 7198989668,
    ["Celebrate"] = 3338097973, ["Dash"] = 582855105, ["Beckon"] = 5230598276, ["Haha"] = 3337966527,
    ["Lasso Turn - Tai Verdes"] = 7942896991, ["Line Dance"] = 4049037604, ["Shrug"] = 3334392772, ["Point2"] = 3344585679,
    ["Stadium"] = 3338055167, ["Confused"] = 4940561610, ["Side to Side"] = 3333136415,
    ["Old Town Road Dance - Lil Nas X"] = 5937560570, ["Hello"] = 3344650532, ["Dolphin Dance"] = 5918726674,
    ["Samba"] = 6869766175, ["Break Dance"] = 5915648917, ["Hips Poppin' - Zara Larsson"] = 6797888062,
    ["Wake Up Call - KSI"] = 7199000883, ["Greatest"] = 3338042785, ["On The Outside - Twenty One"] = 7422779536,
    ["Boxing Punch - KSI"] = 7202863182, ["Sad"] = 4841407203, ["Flowing Breeze"] = 7465946930, ["Twirl"] = 3334968680,
    ["Jumping Wave"] = 4940564896, ["HOLIDAY Dance - Lil Nas X (LNX)"] = 5937558680, ["Take Me Under - Zara Larsson"] = 6797890377,
    ["Dizzy"] = 3361426436, ["Dancing' Shoes - Twenty One"] = 7404878500, ["Fashionable"] = 3333331310, ["Fast Hands"] = 4265701731,
    ["Tree"] = 4049551434, ["Agree"] = 4841397952, ["Power Blast"] = 4841403964, ["Swoosh"] = 3361481910,
    ["Jumping Cheer"] = 5895324424, ["Disagree"] = 4841401869, ["Rodeo Dance - Lil Nas X (LNX)"] = 5918728267,
    ["It Ain't My Fault - Zara Larsson"] = 6797891807, ["Rock On"] = 5915714366, ["Block Partier"] = 6862022283,
    ["Dorky Dance"] = 4212455378, ["Zombie"] = 4210116953, ["Zombie 2"] = 10714089137, ["AOK - Tai Verdes"] = 7942885103,
    ["T"] = 3338010159, ["Cobra Arms - Tai Verdes"] = 7942890105, ["Panini Dance - Lil Nas X (LNX)"] = 5915713518,
    ["Fishing"] = 3334832150, ["Robot"] = 3338025566, ["Saturday Dance - Twenty One"] = 7422807549, ["Keeping Time"] = 4555808220,
    ["Air Dance"] = 4555782893, ["Rock Guitar - Royal Blood"] = 6532134724, ["Borock's Rage"] = 3236842542,
    ["Ud'zal's Summoning"] = 3303161675, ["Y"] = 4349285876, ["Swan Dance"] = 7465997989, ["Louder"] = 3338083565,
    ["Up and Down - Twenty One"] = 7422797678, ["Swish"] = 3361481910, ["Drummer Moves - Twenty One"] = 7422527690,
    ["Sneaky"] = 3334424322, ["Heisman Pose"] = 3695263073, ["Jacks"] = 3338066331, ["Cha-Cha 2"] = 3695322025,
    ["BURBERRY LOLA ATTITUDE - NIMBUS"] = 10147821284, ["BURBERRY LOLA ATTITUDE - GEM"] = 10147815602,
    ["BURBERRY LOLA ATTITUDE - HYDRO"] = 10147823318, ["BURBERRY LOLA ATTITUDE - BLOOM"] = 10147817997,
    ["Superhero Reveal"] = 3695373233, ["Air Guitar"] = 3695300085, ["Air Guitar 2"] = 15505454268,
    ["Dismissive Wave"] = 3333272779, ["Country Line Dance - Lil Nas X"] = 5915712534, ["Salute"] = 3333474484,
    ["Applaud"] = 5915693819, ["Get Out"] = 3333272779, ["Hwaiting (화이팅)"] = 9527885267, ["Annyeong (안녕)"] = 9527883498,
    ["Bunny Hop"] = 4641985101, ["Sandwich Dance"] = 4406555273, ["Hyperfast 5G Dance Move"] = 9408617181,
    ["Victory - 24kGoldn"] = 9178377686, ["Tantrum"] = 5104341999, ["Rock Star - Royal Blood"] = 10714400171,
    ["Drum Solo - Royal Blood"] = 6532839007, ["Drum Master - Royal Blood"] = 6531483720, ["High Hands"] = 9710985298,
    ["Tilt"] = 3334538554, ["Gashina - SUNMI"] = 9527886709, ["Chicken Dance"] = 4841399916,
    ["You can't sit with us - Sunmi"] = 9983520970, ["Frosty Flair - Tommy Hilfiger"] = 10214311282,
    ["Floor Rock Freeze - Tommy Hilfiger"] = 10214314957, ["Boom Boom Clap - George Ezra"] = 10370346995,
    ["Cartwheel - George Ezra"] = 10370351535, ["Chill Vibes - George Ezra"] = 10370353969, ["Sidekicks - George Ezra"] = 10370362157,
    ["The Conductor - George Ezra"] = 10370359115, ["Super Charge"] = 10478338114, ["Swag Walk"] = 10478341260,
    ["Mean Mug - Tommy Hilfiger"] = 10214317325, ["V Pose - Tommy Hilfiger"] = 10214319518, ["Uprise - Tommy Hilfiger"] = 10275008655,
    ["2 Baddies Dance Move - NCT 127"] = 12259828678, ["Kick It Dance Move - NCT 127"] = 12259826609,
    ["Sticker Dance Move - NCT 127"] = 12259825026, ["Elton John - Rock Out"] = 11753474067, ["Elton John - Heart Skip"] = 11309255148,
    ["Elton John - Still Standing"] = 11444443576, ["Elton John - Elevate"] = 11394033602, ["Elton John - Cat Man"] = 11444441914,
    ["Elton John - Piano Jump"] = 11453082181, ["Alo Yoga Pose - Triangle"] = 12507084541, ["Alo Yoga Pose - Warrior II"] = 12507083048,
    ["Alo Yoga Pose - Lotus Position"] = 12507085924, ["TWICE-Moonlight-Sunrise"] = 12714233242,
    ["TWICE-Set-Me-Free-Dance-1"] = 12714228341, ["TWICE-Set-Me-Free-Dance-2"] = 12714231087, ["Ay-Yo-Dance-Move-NCT-127"] = 12804157977,
    ["TWICE-The-Feels"] = 12874447851, ["Rise-Above-The-Chainsmokers"] = 12992262118, ["TWICE-What-Is-Love"] = 13327655243,
    ["Man-City-Bicycle-Kick"] = 13421057998, ["TWICE-Fancy"] = 13520524517, ["TWICE Pop by Nayeon"] = 13768941455,
    ["Tommy - Archer"] = 13823324057, ["Man City Backflip"] = 13694100677, ["Man-City-Scorpion-Kick"] = 13694096724,
    ["Arm Twist"] = 10713968716, ["YUNGBLUD – HIGH KICK"] = 14022936101, ["TWICE Like Ooh-Ahh"] = 14123781004,
    ["Baby Queen - Air Guitar & Knee Slide"] = 14352335202, ["Baby Queen - Dramatic Bow"] = 14352337694,
    ["Baby Queen - Face Frame"] = 14352340648, ["Baby Queen - Bouncy Twirl"] = 14352343065, ["Baby Queen - Strut"] = 14352362059,
    ["BLACKPINK Pink Venom - Get em Get em Get em"] = 14548619594, ["BLACKPINK Pink Venom - I Bring the Pain Like…"] = 14548620495,
    ["BLACKPINK Pink Venom - Straight to Ya Dome"] = 14548621256, ["TWICE LIKEY"] = 14899979575, ["TWICE Feel Special"] = 14899980745,
    ["BLACKPINK Shut Down - Part 1"] = 14901306096, ["BLACKPINK Shut Down - Part 2"] = 14901308987, ["Bone Chillin' Bop"] = 15122972413,
    ["Paris Hilton - Sliving For The Groove"] = 15392759696, ["Paris Hilton - Iconic IT-Grrrl"] = 15392756794,
    ["Paris Hilton - Checking My Angles"] = 15392752812, ["BLACKPINK JISOO Flower"] = 15439354020, ["BLACKPINK JENNIE You and Me"] = 15439356296,
    ["Rock n Roll"] = 15505458452, ["Victory Dance"] = 15505456446, ["Flex Walk"] = 15505459811, ["Olivia Rodrigo Head Bop"] = 15517864808,
    ["Olivia Rodrigo good 4 u"] = 15517862739, ["Olivia Rodrigo Fall Back to Float"] = 15549124879,
    ["Nicki Minaj That's That Super Bass"] = 15571446961, ["Nicki Minaj Boom Boom Boom"] = 15571448688, ["Nicki Minaj Anaconda"] = 15571450952,
    ["Nicki Minaj Starships"] = 15571453761, ["Yungblud Happier Jump"] = 15609995579, ["Festive Dance"] = 15679621440,
    ["BLACKPINK LISA Money"] = 15679623052, ["BLACKPINK ROSÉ On The Ground"] = 15679624464, ["Imagine Dragons - “Bones” Dance"] = 15689279687,
    ["GloRilla - \"Tomorrow\" Dance"] = 15689278184, ["d4vd - Backflip"] = 15693621070, ["ericdoa - dance"] = 15698402762,
    ["Cuco - Levitate"] = 15698404340, ["Mean Girls Dance Break"] = 15963314052, ["Paris Hilton Sanasa"] = 16126469463,
    ["BLACKPINK Ice Cream"] = 16181797368, ["BLACKPINK Kill This Love"] = 16181798319, ["TWICE I GOT YOU part 1"] = 16215030041,
    ["TWICE I GOT YOU part 2"] = 16256203246, ["Dave's Spin Move - Glass Animals"] = 16272432203, ["Sol de Janeiro - Samba"] = 16270690701,
    ["Beauty Touchdown"] = 16302968986, ["Skadoosh Emote - Kung Fu Panda 4"] = 16371217304, ["Jawny - Stomp"] = 16392075853,
    ["Mae Stephens - Piano Hands"] = 16553163212, ["BLACKPINK Boombayah Emote"] = 16553164850, ["BLACKPINK DDU-DU DDU-DU"] = 16553170471,
    ["HIPMOTION - Amaarae"] = 16572740012, ["Mae Stephens – Arm Wave"] = 16584481352, ["Wanna play?"] = 16646423316,
    ["BLACKPINK-How-You-Like-That"] = 16874470507, ["BLACKPINK - Lovesick Girls"] = 16874472321, ["Mini Kong"] = 17000021306,
    ["HUGO Let's Drive!"] = 17360699557, ["Wisp - air guitar"] = 17370775305, ["Vans Ollie"] = 18305395285,
    ["Sturdy Dance - Ice Spice"] = 17746180844, ["Rolling Stones Guitar Strum"] = 18148804340, ["Rock Out - Bebe Rexha"] = 18225053113,
    ["SpongeBob Imaginaaation 🌈"] = 18443237526, ["SpongeBob Dance"] = 18443245017, ["Shrek Roar"] = 18524313628,
    ["Team USA Breaking Emote"] = 18526288497, ["NBA WNBA Fadeaway"] = 18526362841, ["Vroom Vroom"] = 18526397037,
    ["TMNT Dance"] = 18665811005, ["Olympic Dismount"] = 18665825805, ["BLACKPINK As If It's Your Last"] = 18855536648,
    ["BLACKPINK Don't know what to do"] = 18855531354, ["TWICE ABCD by Nayeon"] = 18933706381, ["Charli xcx - Apple Dance"] = 18946844622,
    ["The Zabb"] = 129470135909814, ["Fashion Klossette - Runway my way"] = 80995190624232, ["ALTÉGO - Couldn’t Care Less"] = 107875941017127,
    ["Fashion Roadkill"] = 136831243854748, ["Skibidi Toilet - Titan Speakerman Laser Spin"] = 134283166482394,
    ["Chappell Roan HOT TO GO!"] = 85267023718407, ["Secret Handshake Dance"] = 71243990877913, ["KATSEYE - Touch"] = 135876612109535,
    ["Fashion Spin"] = 131669256082047, ["TWICE Strategy"] = 97311229290836, ["NBA Monster Dunk"] = 132748833449150,
    ["DearALICE - Ariana"] = 134318425949290, ["The Weeknd Starboy Strut"] = 71105746210464, ["The Weeknd Opening Night"] = 133110725387025,
    ["Robot M3GAN"] = 125803725853577, ["M3GAN's Dance"] = 99649534578309, ["Rasputin – Boney M."] = 114872820353992,
    ["Thanos Happy Jump - Squid Game"] = 97611664803614, ["Young-hee Head Spin - Squid Game"] = 112011282168475,
    ["TWICE Takedown"] = 140182843839424, ["Stray Kids Walkin On Water"] = 125064469983655, ["TWICE TAKEDOWN DANCE 2"] = 127104635954695,
}
local EMOTE_LIST = {}
for n in pairs(EMOTES) do EMOTE_LIST[#EMOTE_LIST + 1] = n end
table.sort(EMOTE_LIST, function(a, b) return a:lower() < b:lower() end)

-- ═════════════════════════ BOTIS: EMOTE VERİLERİ (R6) ═════════════════════════
local R6E, R6_LIST = {}, {}
local function r6(name, id, speed, time) R6E[name] = {id, speed, time}; R6_LIST[#R6_LIST + 1] = name end
r6("Balloon Float", 148840371); r6("Idle", 180435571); r6("Arm Turbine", 259438880, 1.5); r6("Floating Head", 121572214)
r6("Insane Rotation", 121572214, 99); r6("Scream", 180611870, 1.5); r6("Party Time", 33796059); r6("Chop", 33169596)
r6("Weird Sway", 248336677); r6("Goal!", 28488254); r6("Rotation", 136801964); r6("Spin", 188632011)
r6("Weird Float", 248336459); r6("Pinch Nose", 30235165); r6("Cry", 180612465, 1.5); r6("Penguin Slide", 282574440, 0)
r6("Zombie Arms", 183294396); r6("Flying", 46196309); r6("Stab", 66703241); r6("Dance", 35654637); r6("Random", 48977286)
r6("Hmmm", 33855276); r6("Sword", 35978879); r6("Arms Out", 27432691); r6("Kick", 45737360); r6("Insane Legs", 87986341, 99)
r6("Head Detach", 35154961, 0, 3); r6("Moon Walk", 30196114, 0, 3); r6("Crouch", 182724289); r6("Beat Box", 45504977, 0, 3)
r6("Big Guns", 161268368, 0, 3); r6("Bigger Guns", 225975820, 0, 3); r6("Charleston", 429703734); r6("Moon Dance", 27789359)
r6("Roar", 163209885); r6("Weird Pose", 248336163); r6("Spin Dance 2", 186934910); r6("Bow Down", 204292303)
r6("Sword Slam", 204295235); r6("Glitch Levitate", 313762630); r6("Full Swing", 218504594); r6("Full Punch", 204062532)
r6("Faint", 181526230); r6("Floor Faint", 181525546); r6("Jumping Jacks", 429681631); r6("Spin Dance", 429730430)
r6("Arm Detach", 33169583); r6("Mega Insane", 184574340); r6("Dino Walk", 204328711); r6("Tilt Head", 283545583)
r6("Dab", 183412246); r6("Float Sit", 179224234); r6("Clone Illusion", 215384594, 1e7, .5); r6("Hero Jump", 184574340)
table.sort(R6_LIST, function(a, b) return a:lower() < b:lower() end)

-- ═════════════════════════ BOTIS: ANİMASYON PAKETLERİ ═════════════════════════
local PACKS, PACK_LIST = {}, {}
local function pk(name, a, b, c, d, e, f, g, h, i, j)
    PACKS[name] = {Idle = a, Idle2 = b, Idle3 = c, Walk = d, Run = e, Jump = f, Climb = g, Fall = h, Swim = i, SwimIdle = j, Weight = 9, Weight2 = 1}
    PACK_LIST[#PACK_LIST + 1] = name
end
pk("Stylish", 616136790, 616138447, 886888594, 616146177, 616140816, 616139451, 616133594, 616134815, 616143378, 616144772)
pk("Zombie", 616158929, 616160636, 885545458, 616168032, 616163682, 616161997, 616156119, 616157476, 616165109, 616166655)
pk("Robot", 616088211, 616089559, 885531463, 616095330, 616091570, 616090535, 616086039, 616087089, 616092998, 616094091)
pk("Toy", 782841498, 782845736, 980952228, 782843345, 782842708, 782847020, 782843869, 782846423, 782844582, 782845186)
pk("Cartoony", 742637544, 742638445, 885477856, 742640026, 742638842, 742637942, 742636889, 742637151, 742639220, 742639812)
pk("Superhero", 616111295, 616113536, 885535855, 616122287, 616117076, 616115533, 616104706, 616108001, 616119360, 616120861)
pk("Mage", 707742142, 707855907, 885508740, 707897309, 707861613, 707853694, 707826056, 707829716, 707876443, 707894699)
pk("Levitation", 616006778, 616008087, 886862142, 616013216, 616010382, 616008936, 616003713, 616005863, 616011509, 616012453)
pk("Vampire", 1083445855, 1083450166, 1088037547, 1083473930, 1083462077, 1083455352, 1083439238, 1083443587, 1083464683, 1083467779)
pk("Elder", 845397899, 845400520, 901160519, 845403856, 845386501, 845398858, 845392038, 845396048, 845401742, 845403127)
pk("Werewolf", 1083195517, 1083214717, 1099492820, 1083178339, 1083216690, 1083218792, 1083182000, 1083189019, 1083222527, 1083225406)
pk("Knight", 657595757, 657568135, 885499184, 657552124, 657564596, 658409194, 658360781, 657600338, 657560551, 657557095)
pk("Bold", 16738333868, 16738334710, 16738335517, 16738340646, 16738337225, 16738336650, 16738332169, 16738333171, 16738339158, 16738339817)
pk("Astronaut", 891621366, 891633237, 1047759695, 891667138, 891636393, 891627522, 891609353, 891617961, 891639666, 891663592)
pk("Bubbly", 910004836, 910009958, 1018536639, 910034870, 910025107, 910016857, 909997997, 910001910, 910028158, 910030921)
pk("Pirate", 750781874, 750782770, 885515365, 750785693, 750783738, 750782230, 750779899, 750780242, 750784579, 750785176)
pk("Rthro", 2510196951, 2510197257, 3711062489, 2510202577, 2510198475, 2510197830, 2510192778, 2510195892, 2510199791, 2510201162)
pk("Ninja", 656117400, 656118341, 886742569, 656121766, 656118852, 656117878, 656114359, 656115606, 656119721, 656121397)
pk("Oldschool", 5319828216, 5319831086, 5392107832, 5319847204, 5319844329, 5319841935, 5319816685, 5319839762, 5319850266, 5319852613)
pk("Realistic", 17172918855, 17173014241, 17173014241, 11600249883, 11600211410, 11600210487, 11600205519, 11600206437, 11600212676, 11600213505)
pk("No Boundaries", 18747067405, 18747063918, 18747063918, 18747074203, 18747070484, 18747069148, 18747060903, 18747062535, 18747073181, 18747071682)
pk("NFL Animation", 92080889861410, 74451233229259, 80884010501210, 110358958299415, 117333533048078, 119846112151352, 134630013742019, 129773241321032, 132697394189921, 79090109939093)
pk("Adidas Aura", 110211186840347, 114191137265065, 99129837931148, 83842218823011, 118320322718866, 109996626521204, 97824616490448, 95603166884636, 134530128383903, 94922130551805)
pk("Adidas Sports", 18537376492, 18537371272, 18537374150, 18537392113, 18537384940, 18537380791, 18537363391, 18537367238, 18537389531, 18537387180)
pk("Adidas Community", 122257458498464, 102357151005774, 89262795687364, 122150855457006, 82598234841035, 75290611992385, 88763136693023, 98600215928904, 133308483266208, 109346520324160)
pk("Wickled Popular", 118832222982049, 76049494037641, 138255200176080, 92072849924640, 72301599441680, 104325245285198, 131326830509784, 121152442762481, 99384245425157, 113199415118199)
pk("Catwalk Glam", 133806214992291, 94970088341563, 87105332133518, 109168724482748, 81024476153754, 116936326516985, 119377220967554, 92294537340807, 134591743181628, 98854111361360)
pk("Princess", 941003647, 941013098, 1159195712, 941028902, 941015281, 941008832, 940996062, 941000007, 941018893, 941025398)
pk("Confident", 1069977950, 1069987858, 1116160740, 1070017263, 1070001516, 1069984524, 1069946257, 1069973677, 1070009914, 1070012133)
pk("Popstar", 1212900985, 1150842221, 1239733474, 1212980338, 1212980348, 1212954642, 1213044953, 1212900995, 1212852603, 1070012133)
pk("Patrol", 1149612882, 1150842221, 1159573567, 1151231493, 1150967949, 1150944216, 1148811837, 1148863382, 1151204998, 1151221899)
pk("Sneaky", 1132473842, 1132477671, nil, 1132510133, 1132494274, 1132489853, 1132461372, 1132469004, 1132500520, 1132506407)
pk("Cowboy", 1014390418, 1014398616, 1159487651, 1014421541, 1014401683, 1014394726, 1014380606, 1014384571, 1014406523, 1014411816)
pk("Ghost", 616006778, 616008087, 616008087, 616013216, 616013216, 616008936, nil, 616005863, 616011509, 616012453)
pk("Ghost 2", 1151221899, 1151221899, nil, 1151221899, 1151221899, 1151221899, nil, 1151221899, 16738339158, 1151221899)
pk("Mr. Toilet", 4417977954, 4417978624, 4441285342, 2510202577, 4417979645, 2510197830, 2510192778, 2510195892, 2510199791, 2510201162)
pk("Udzal", 3303162274, 3303162549, 3710161342, 3303162967, 3236836670, 2510197830, 2510192778, 2510195892, 2510199791, 2510201162)
pk("Oinan Thickhoof", 657595757, 657568135, 885499184, 2510202577, 3236836670, 2510197830, 2510192778, 2510195892, 2510199791, 2510201162)
pk("Borock", 3293641938, 3293642554, 3710131919, 2510202577, 3236836670, 2510197830, 2510192778, 2510195892, 2510199791, 2510201162)
pk("Blocky Mech", 4417977954, 4417978624, 4441285342, 2510202577, 4417979645, 2510197830, 2510192778, 2510195892, 2510199791, 2510201162)
pk("Stylized Female", 4708191566, 4708192150, nil, 4708193840, 4708192705, 4708188025, 4708184253, 4708186162, 4708189360, 4708190607)
pk("R15", 4211217646, 4211218409, nil, 4211223236, 4211220381, 4211219390, 4211214992, 4211216152, 4211221314, 4374694239)
pk("Mocap", 913367814, 913373430, nil, 913402848, 913376220, 913370268, 913362637, 913365531, 913384386, 913389285)
pk("Wicked Dancing Through Life", 92849173543269, 132238900951109, 87867222929430, 73718308412641, 135515454877967, 78508480717326, 129447497744818, 78147885297412, 110657013921774, 129183123083281)
pk("Unboxed", 98281136301627, 138183121662404, 133117300343405, 90478085024465, 134824450619865, 121454505477205, 121145883950231, 94788218468396, 105962919001086, 129126268464847)
table.sort(PACK_LIST, function(a, b) return a:lower() < b:lower() end)

-- ═════════════════════════ BOTIS: ANIMATE SCRIPT YARDIMCILARI ═════════════════════════
local ANIM_URL = "http://www.roblox.com/asset/?id="
local BODY_MAP = {
    {"Idle", {"idle", "Animation1"}}, {"Idle2", {"idle", "Animation2"}}, {"Idle3", {"pose"}}, {"Walk", {"walk"}},
    {"Run", {"run"}}, {"Jump", {"jump"}}, {"Climb", {"climb"}}, {"Fall", {"fall"}}, {"Swim", {"swim"}}, {"SwimIdle", {"swimidle"}},
}
-- {görünen ad, Animate klasörü/slot, paket alanı (sadece gövde slotları)}
local SLOTS = {
    {"Idle", "idle1", "Idle"}, {"Idle 2", "idle2", "Idle2"}, {"Walk", "walk", "Walk"}, {"Run", "run", "Run"},
    {"Jump", "jump", "Jump"}, {"Climb", "climb", "Climb"}, {"Fall", "fall", "Fall"}, {"Swim Idle", "swimidle", "SwimIdle"},
    {"Swim", "swim", "Swim"}, {"Wave", "wave"}, {"Laugh", "laugh"}, {"Cheer", "cheer"}, {"Point", "point"},
    {"Sit", "sit"}, {"Dance", "dance"}, {"Dance 2", "dance2"}, {"Dance 3", "dance3"},
}
local SLOT_NAMES, SLOT_BY_NAME = {}, {}
for _, s in ipairs(SLOTS) do SLOT_NAMES[#SLOT_NAMES + 1] = s[1]; SLOT_BY_NAME[s[1]] = s end

local function getAnimate() local c = LP.Character; return c and c:FindFirstChild("Animate") end
local function isR15() local h = hum(); return h and h.RigType == Enum.HumanoidRigType.R15 end
local function animInst(a, p)
    local f = a and a:FindFirstChild(p[1]); if not f then return nil end
    if p[2] then return f:FindFirstChild(p[2]) end
    return f:FindFirstChildOfClass("Animation")
end
local function setId(inst, id)
    if not inst or not id or id == 0 then return end
    if type(id) == "string" then
        if id:find("://") then inst.AnimationId = id end
        return
    end
    inst.AnimationId = ANIM_URL .. tostring(id)
end

-- Orijinal animasyonlar (tekrar çalıştırmada bozulmasın diye env'de saklanır)
local Orig = env.__BOTIS_ORIG
local function captureOrig()
    if Orig then return end
    local t0, a = tick(), nil
    repeat a = getAnimate(); if not a then task.wait(.2) end until a or tick() - t0 > 6
    if not a then return end
    Orig = {slots = {}}
    for _, m in ipairs(BODY_MAP) do local i = animInst(a, m[2]); if i then Orig[m[1]] = i.AnimationId end end
    for _, s in ipairs(SLOTS) do
        if not s[3] then
            local f, ids = a:FindFirstChild(s[2]), {}
            if f then for _, v in ipairs(f:GetChildren()) do if v:IsA("Animation") then ids[#ids + 1] = v.AnimationId end end end
            Orig.slots[s[2]] = ids
        end
    end
    env.__BOTIS_ORIG = Orig
end

local function applyBody(p)
    local a = getAnimate(); if not a then return end
    for _, m in ipairs(BODY_MAP) do setId(animInst(a, m[2]), p[m[1]]) end
    local idle = a:FindFirstChild("idle")
    if idle then
        local w1 = idle:FindFirstChild("Animation1") and idle.Animation1:FindFirstChild("Weight")
        local w2 = idle:FindFirstChild("Animation2") and idle.Animation2:FindFirstChild("Weight")
        if w1 and p.Weight then w1.Value = tonumber(p.Weight) end
        if w2 and p.Weight2 then w2.Value = tonumber(p.Weight2) end
    end
end

local function setSlot(slot, id)
    local a = getAnimate(); if not a then return end
    if slot == "idle1" then
        setId(animInst(a, {"idle", "Animation1"}), id); setId(animInst(a, {"pose"}), id)
    elseif slot == "idle2" then
        setId(animInst(a, {"idle", "Animation2"}), id); setId(animInst(a, {"pose"}), id)
    else
        local f = a:FindFirstChild(slot)
        if f then for _, v in ipairs(f:GetChildren()) do if v:IsA("Animation") then setId(v, id) end end end
    end
end

-- ═════════════════════════ BOTIS: EMOTE / ANİMASYON ÇEKİRDEĞİ ═════════════════════════
local Anim = {loop = false, reverse = false, freeze = false, always = false, timeOn = false, timePct = 0,
    speed = 1, animSpeed = 1, last = Cfg.lastEmote or "", track = nil, pose = nil}
local setEmoteStatus, setPackStatus = function() end, function() end
local function updateStatus()
    setEmoteStatus(("Emote: %s  •  Hız: %s  •  Döngü: %s"):format(Anim.last ~= "" and Anim.last or "—", tostring(Anim.speed), tostring(Anim.loop)))
    setPackStatus(("Paket: %s  •  Hız: %s"):format(Cfg.pack ~= "" and Cfg.pack or "Varsayılan", tostring(Anim.animSpeed)))
end

local function stopAllTracks()
    local h = hum(); if not h then return end
    for _, t in ipairs(h:GetPlayingAnimationTracks()) do pcall(function() t:Stop() end) end
end
local function refreshAnims()
    local a, h = getAnimate(), hum()
    if not (a and h) then return end
    a.Disabled = true
    for _, t in ipairs(h:GetPlayingAnimationTracks()) do pcall(function() t:Stop() end) end
    a.Disabled = false
    local ws = h.WalkSpeed; h.WalkSpeed = 0; task.wait(); h.WalkSpeed = ws
    if Anim.animSpeed ~= 1 then
        for _, t in ipairs(h:GetPlayingAnimationTracks()) do pcall(function() t:AdjustSpeed(Anim.animSpeed) end) end
    end
end
local function stopEmote()
    if Anim.track then pcall(function() Anim.track:Stop() end); Anim.track = nil end
    unbind("emoteMove")
end

local function playAnimation(id, o)
    o = o or {}
    local h = hum(); if not h then return end
    local animator = h:FindFirstChildOfClass("Animator") or new("Animator", nil, h)
    if Anim.track then pcall(function() Anim.track:Stop() end) end
    local a = new("Animation", {AnimationId = "rbxassetid://" .. tostring(id)})
    local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
    if not ok or not tr then notify("Animasyon yüklenemedi"); return end
    tr.Priority = Enum.AnimationPriority.Action4
    Anim.track = tr
    tr:Play(.1)
    task.spawn(function()
        local t0 = tick()
        while tr.Length == 0 and tick() - t0 < 3 do task.wait() end
        if Anim.track ~= tr then return end
        if Anim.loop then tr.Looped = true end
        local spd = o.speed
        if spd == nil then spd = Anim.freeze and 0 or (Anim.reverse and -math.abs(Anim.speed) or Anim.speed) end
        if Anim.reverse and o.speed == nil and tr.Length > 0 then tr.TimePosition = math.max(tr.Length - .05, 0) end
        if o.pct then tr.TimePosition = o.pct / 100 * tr.Length
        elseif Anim.timeOn then tr.TimePosition = Anim.timePct / 100 * tr.Length end
        if o.time then tr.TimePosition = o.time end
        tr:AdjustSpeed(spd)
    end)
    bind("emoteMove", h:GetPropertyChangedSignal("MoveDirection"), function()
        if h.MoveDirection.Magnitude > 0 and not (Anim.always or o.hold) then
            if Anim.track == tr then pcall(function() tr:Stop() end) end
            unbind("emoteMove")
        end
    end)
    updateStatus()
    return tr
end

local function playEmoteByName(n)
    local id = EMOTES[n]; if not id then return end
    local h = hum()
    if h and h.RigType == Enum.HumanoidRigType.R6 then notify("Bu emote R15 içindir — R6 listesini kullan"); return end
    Anim.last = n; Cfg.lastEmote = n; saveSoon()
    playAnimation(id)
end
local function playR6(n)
    local e = R6E[n]; if not e then return end
    local h = hum()
    if h and h.RigType ~= Enum.HumanoidRigType.R6 then notify("R6 emote'u için R6 karakter gerekir"); return end
    Anim.last = n
    playAnimation(e[1], {speed = e[2], time = e[3]})
end
local function playLast()
    if Anim.last == "" then notify("Önce bir emote oynat"); return end
    if R6E[Anim.last] and not EMOTES[Anim.last] then playR6(Anim.last) else playEmoteByName(Anim.last) end
end
local function findEmote(q)
    q = q:lower()
    for _, n in ipairs(EMOTE_LIST) do if n:lower() == q then return n end end
    for _, n in ipairs(EMOTE_LIST) do if n:lower():find(q, 1, true) then return n end end
end
local function findPack(q)
    q = q:lower()
    for _, n in ipairs(PACK_LIST) do if n:lower() == q then return n end end
    for _, n in ipairs(PACK_LIST) do if n:lower():find(q, 1, true) then return n end end
end
local function findPlayer(n)
    n = n:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower():sub(1, #n) == n or p.DisplayName:lower():sub(1, #n) == n) then return p end
    end
end

-- Paket / özel slot uygulama
local BODY_SLOT = {}
for _, s in ipairs(SLOTS) do if s[3] then BODY_SLOT[s[2]] = true end end

local function applyPack(n)
    local p = PACKS[n]; if not p then return end
    if not isR15() then notify("Animasyon paketleri R15 içindir"); return end
    Cfg.pack = n
    for slot in pairs(BODY_SLOT) do Cfg.custom[slot] = nil end
    stopAllTracks()
    applyBody(p)
    for slot, id in pairs(Cfg.custom) do setSlot(slot, id) end
    refreshAnims(); updateStatus(); saveSoon()
end
local function assignSlot(slotKey, id)
    Cfg.custom[slotKey] = id
    setSlot(slotKey, id)
    refreshAnims(); saveSoon()
end
local function reapplyAnims()
    if not isR15() or not getAnimate() then return end
    if PACKS[Cfg.pack] then applyBody(PACKS[Cfg.pack]) end
    local any = PACKS[Cfg.pack] ~= nil
    for slot, id in pairs(Cfg.custom) do setSlot(slot, id); any = true end
    if any then refreshAnims() end
    updateStatus()
end
local function resetAnims()
    stopAllTracks()
    Cfg.pack = ""; Cfg.custom = {}
    local a = getAnimate()
    if Orig and a then
        applyBody(Orig)
        for _, s in ipairs(SLOTS) do
            if not s[3] and Orig.slots[s[2]] then
                local f = a:FindFirstChild(s[2])
                if f then
                    local i = 0
                    for _, v in ipairs(f:GetChildren()) do
                        if v:IsA("Animation") then i = i + 1; if Orig.slots[s[2]][i] then v.AnimationId = Orig.slots[s[2]][i] end end
                    end
                end
            end
        end
    end
    refreshAnims(); updateStatus(); saveSoon()
end

local function animText()
    local a = getAnimate(); if not a then return nil end
    local lines = {"local Animate = game:GetService('Players').LocalPlayer.Character.Animate"}
    for _, m in ipairs(BODY_MAP) do
        local i = animInst(a, m[2])
        if i then
            local path = m[2][2] and ("Animate.%s.%s"):format(m[2][1], m[2][2]) or ("Animate.%s:FindFirstChildOfClass('Animation')"):format(m[2][1])
            lines[#lines + 1] = ("%s.AnimationId = '%s'"):format(path, i.AnimationId)
        end
    end
    return table.concat(lines, "\n")
end

-- Başka oyuncudan kopyalama
local function copyPackFrom(plr)
    local mine = getAnimate()
    local theirs = plr and plr.Character and plr.Character:FindFirstChild("Animate")
    if not (mine and theirs) then return false end
    local changed = false
    for _, m in ipairs(BODY_MAP) do
        local a, b = animInst(mine, m[2]), animInst(theirs, m[2])
        if a and b and a.AnimationId ~= b.AnimationId then a.AnimationId = b.AnimationId; changed = true end
    end
    return changed
end
local function mirrorTrack(v)
    local h = hum(); if not h then return end
    if v.Priority == Enum.AnimationPriority.Core or v.Priority.Value < 2 then return end
    local animator = h:FindFirstChildOfClass("Animator"); if not animator then return end
    local ok, tr = pcall(function() return animator:LoadAnimation(v.Animation) end)
    if not ok or not tr then return end
    tr.Priority = Enum.AnimationPriority.Action4
    tr:Play(.1, v.WeightCurrent, v.Speed)
    tr.TimePosition = v.TimePosition
    Anim.track = tr
end
local function mirrorEmotes(plr)
    local th = plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    local tan = th and th:FindFirstChildOfClass("Animator")
    if not tan then notify("Hedef bulunamadı"); return false end
    for _, v in ipairs(tan:GetPlayingAnimationTracks()) do mirrorTrack(v) end
    return true
end

-- ═════════════════════════ BOTIS: POZLAR ═════════════════════════
local POSES, POSE_NAMES = {}, {}
local function pose(name, emote, pct, hip, loop)
    POSES[name] = {emote = emote, pct = pct, hip = hip, loop = loop}; POSE_NAMES[#POSE_NAMES + 1] = name
end
pose("Otur", "Alo Yoga Pose - Lotus Position", 45)
pose("Otur 2", "Man-City-Bicycle-Kick", 72)
pose("Otur 3", "Quiet Waves", 12)
pose("Otur 4", "Skadoosh Emote - Kung Fu Panda 4", 77)
pose("Süzül", "Olivia Rodrigo Fall Back to Float", 72, 4)
pose("Süzül 2", "Skadoosh Emote - Kung Fu Panda 4", 43)
pose("Süzül 3", "Cuco - Levitate", 7, nil, true)
pose("Ters dur", "Hero Landing", 24.15)
pose("Ters dur 2", "Skadoosh Emote - Kung Fu Panda 4", 44)
pose("Uzan", "Man-City-Bicycle-Kick", 57)
pose("Gerin", "Quiet Waves", 52)

local function stopPose()
    unbind("pose")
    if Anim.pose then
        Anim.pose = nil
        stopEmote()
        local h = hum()
        if h and S._hip0 then h.HipHeight = S._hip0; S._hip0 = nil end
        refreshAnims()
    end
end
local function startPose(def)
    if not def or not EMOTES[def.emote] then return end
    if not isR15() then notify("Pozlar R15 içindir"); return end
    stopPose()
    Anim.pose = def
    local tr = playAnimation(EMOTES[def.emote], {pct = def.pct, speed = def.loop and 1 or 0, hold = true})
    local h = hum()
    if def.hip and h then S._hip0 = S._hip0 or h.HipHeight; h.HipHeight = def.hip end
    local lastReset = tick()
    bind("pose", RunService.Heartbeat, function()
        local h = hum(); if h and h.Sit then h.Sit = false end
        if def.loop and tr and Anim.track == tr and tr.Length > 0 and tick() - lastReset > 6 then
            lastReset = tick(); tr.TimePosition = def.pct / 100 * tr.Length
        end
    end)
end

-- ═════════════════════════ BOTIS: ÖZELLİK FONKSİYONLARI ═════════════════════════
local function fxRandomEmote(on)
    S._re = (S._re or 0) + 1
    local tok = S._re
    if not on then stopEmote(); return end
    task.spawn(function()
        while S._re == tok do
            local n = EMOTE_LIST[math.random(#EMOTE_LIST)]
            Anim.last = n
            local tr = playAnimation(EMOTES[n], {hold = true})
            local t0 = tick()
            while S._re == tok and (not tr or tr.Length == 0) and tick() - t0 < 3 do task.wait(.1) end
            local len = (tr and tr.Length > 0) and tr.Length or 5
            local w = 0
            while S._re == tok and w < len + .5 do task.wait(.2); w = w + .2 end
        end
    end)
end

local function fxRandomPack(on)
    S._rp = (S._rp or 0) + 1
    local tok = S._rp
    if not on then return end
    task.spawn(function()
        while S._rp == tok do
            applyPack(PACK_LIST[math.random(#PACK_LIST)])
            local w = 0
            while S._rp == tok and w < 6.35 do task.wait(.2); w = w + .2 end
        end
    end)
end

local function fxRandomIdle(on)
    S._ri = (S._ri or 0) + 1
    local tok = S._ri
    if not on then return end
    task.spawn(function()
        while S._ri == tok do
            local a = getAnimate()
            local p = PACKS[PACK_LIST[math.random(#PACK_LIST)]]
            if a and p then
                setId(animInst(a, {"idle", "Animation1"}), p.Idle); setId(animInst(a, {"idle", "Animation2"}), p.Idle2)
                setId(animInst(a, {"pose"}), p.Idle3)
            end
            local w = 0
            while S._ri == tok and w < 3 do task.wait(.2); w = w + .2 end
        end
    end)
end

local function fxAnimSpeed(on)
    unbind("animSpeed")
    if on then bind("animSpeed", RunService.Heartbeat, function()
        local h = hum(); if not h then return end
        for _, t in ipairs(h:GetPlayingAnimationTracks()) do
            if t ~= Anim.track then t:AdjustSpeed(Anim.animSpeed) end
        end
    end)
    else task.spawn(refreshAnims) end
end

local function fxFreezePack(on)
    unbind("freezePack")
    if on then bind("freezePack", RunService.Heartbeat, function()
        local h = hum(); if not h then return end
        for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:AdjustSpeed(0) end
    end)
    else
        local h = hum()
        if h then for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:AdjustSpeed(1) end end
        task.spawn(refreshAnims)
    end
end

local function fxSyncEmote(on)
    unbind("syncEmote")
    if not on then return end
    local p = S.syncTarget or S.target
    local th = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    local tan = th and th:FindFirstChildOfClass("Animator")
    if not tan then notify("Önce hedef seç (Sync hedefi veya Oyuncu sekmesi)"); return end
    mirrorEmotes(p)
    bind("syncEmote", tan.AnimationPlayed, mirrorTrack)
end

local function fxSyncPack(on)
    S._sp = (S._sp or 0) + 1
    local tok = S._sp
    if not on then return end
    task.spawn(function()
        while S._sp == tok do
            local p = S.syncTarget or S.target
            if p and copyPackFrom(p) then refreshAnims() end
            task.wait(2)
        end
    end)
end

-- Sohbet komutları
local chatHooked, chatLast, chatLastT = false, "", 0
local function handleChat(msg)
    if not (S.chatEmote or S.chatAnim) then return end
    if msg == chatLast and tick() - chatLastT < .5 then return end
    chatLast, chatLastT = msg, tick()
    local low, ep, ap = msg:lower(), Cfg.emotePrefix:lower(), Cfg.animPrefix:lower()
    if S.chatEmote and low:sub(1, #ep + 1) == ep .. " " then
        local q = msg:sub(#ep + 2)
        local n = findEmote(q)
        if n then playEmoteByName(n) else notify("Emote bulunamadı: " .. q) end
    elseif S.chatAnim and low:sub(1, #ap + 1) == ap .. " " then
        local q = msg:sub(#ap + 2)
        local n = findPack(q)
        if n then applyPack(n) else notify("Paket bulunamadı: " .. q) end
    end
end
local function ensureChat()
    if chatHooked then return end
    chatHooked = true
    bind("chatLegacy", LP.Chatted, handleChat)
    pcall(function()
        local chs = TextChatService:FindFirstChild("TextChannels")
        local ch = chs and chs:FindFirstChild("RBXGeneral")
        if ch then
            bind("chatNew", ch.MessageReceived, function(m)
                if m.TextSource and m.TextSource.UserId == LP.UserId then handleChat(m.Text) end
            end)
        end
        TextChatService.OnIncomingMessage = function(m)
            pcall(function()
                if m.TextSource and m.TextSource.UserId == LP.UserId then
                    local t = m.Text:lower()
                    if (S.chatEmote and t:sub(1, #Cfg.emotePrefix) == Cfg.emotePrefix:lower())
                        or (S.chatAnim and t:sub(1, #Cfg.animPrefix) == Cfg.animPrefix:lower()) then
                        m.Status = Enum.TextChatMessageStatus.InvalidTextChannelPermissions
                    end
                end
            end)
        end
    end)
end
local function fxChatEmote(on) S.chatEmote = on; if on then ensureChat() end end
local function fxChatAnim(on) S.chatAnim = on; if on then ensureChat() end end

-- Hareket ekstraları
local function fxPlatform(on)
    if S._bigPlat then S._bigPlat:Destroy(); S._bigPlat = nil end
    if not on then return end
    local r, h = root(), hum()
    if not (r and h) then return end
    local feet = r.Position.Y - (h.RigType == Enum.HumanoidRigType.R6 and 3 or (h.HipHeight + r.Size.Y / 2))
    S._bigPlat = new("Part", {Size = Vector3.new(300, 1, 300), Anchored = true, Transparency = 1, Name = tostring(math.random(100, 9999)),
        Position = Vector3.new(r.Position.X, feet - .5, r.Position.Z)}, workspace)
end

local function fxSwim(on)
    unbind("swim")
    local h = hum()
    if on and h then
        S._gravSwim = S._gravSwim or workspace.Gravity
        workspace.Gravity = 0
        for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            if st ~= Enum.HumanoidStateType.None and st ~= Enum.HumanoidStateType.Dead then
                pcall(function() h:SetStateEnabled(st, false) end)
            end
        end
        h:ChangeState(Enum.HumanoidStateType.Swimming)
        bind("swim", RunService.Heartbeat, function()
            local h, r = hum(), root()
            if h and r and h.MoveDirection == Vector3.zero and not UIS:IsKeyDown(Enum.KeyCode.Space) then
                r.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    else
        if S._gravSwim then workspace.Gravity = S._gravSwim; S._gravSwim = nil end
        if h then
            for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                if st ~= Enum.HumanoidStateType.None then pcall(function() h:SetStateEnabled(st, true) end) end
            end
        end
    end
end

local function watchDeath()
    local h = hum(); if not h then return end
    if S._deathConn then S._deathConn:Disconnect() end
    S._deathConn = h.Died:Connect(function() local r = root(); if r then S.deathCF = r.CFrame end end)
end
local function fxRefreshPos(on)
    S.refreshPos = on
    if on then watchDeath()
    elseif S._deathConn then S._deathConn:Disconnect(); S._deathConn = nil end
end

local function fxHear(on)
    local SS = game:GetService("SoundService")
    if S._hearPart then S._hearPart:Destroy(); S._hearPart = nil end
    if on then
        local r = root(); if not r then return end
        S._hearPart = new("Part", {Name = "SoundInf", Size = Vector3.new(1e10, 1e10, 1e10), Anchored = true, CanCollide = false,
            Transparency = 1, CFrame = r.CFrame}, workspace)
        SS:SetListener(Enum.ListenerType.ObjectPosition, S._hearPart)
    else
        SS:SetListener(Enum.ListenerType.Camera)
    end
end

local function fxSpy(on)
    local SS = game:GetService("SoundService")
    if on then
        local r = S.target and S.target.Character and S.target.Character:FindFirstChild("HumanoidRootPart")
        if not r then notify("Önce oyuncu seç"); return end
        SS:SetListener(Enum.ListenerType.ObjectPosition, r)
    else
        SS:SetListener(Enum.ListenerType.Camera)
    end
end

local function fxClickSelect(on)
    unbind("csel")
    if on then bind("csel", UIS.InputBegan, function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            local t = LP:GetMouse().Target
            local m = t and t:FindFirstAncestorOfClass("Model")
            local p = m and Players:GetPlayerFromCharacter(m)
            if p and p ~= LP then
                S.target = p
                if S.onSelect then S.onSelect(p) end
                notify("Seçildi: " .. p.Name)
            end
        end
    end) end
end

-- Respawn sonrası paketleri geri yükle + ölüm noktası
track(LP.CharacterAdded:Connect(function(c)
    c:WaitForChild("Humanoid", 10); c:WaitForChild("Animate", 10); task.wait(.5)
    Anim.track = nil; Anim.pose = nil; unbind("pose")
    if S.refreshPos then
        watchDeath()
        if S.deathCF then
            local r = c:WaitForChild("HumanoidRootPart", 5)
            if r then task.wait(.15); r.CFrame = S.deathCF end
        end
    end
    task.spawn(reapplyAnims)
end))

-- ═════════════════════════ SAYFALAR ═════════════════════════
local pMove = newPage("Hareket", "🏃")
local pVis  = newPage("Görsel", "👁")
local pEmote = newPage("Emote", "🎭")
local pPack = newPage("Animasyon", "🕺")
local pCustom = newPage("Özel Anim", "🧩")
local pFun  = newPage("Eğlence", "🤡")
local pPly  = newPage("Oyuncu", "👥")
local pSet  = newPage("Ayarlar", "⚙")

-- Hareket
pMove:Section("Temel")
feat(pMove, "Hız", fxSpeed)
pMove:Slider("Hız değeri", 16, 300, S.speed, function(v) S.speed = v end)
feat(pMove, "Zıplama gücü", fxJump)
pMove:Slider("Zıplama değeri", 50, 500, S.jump, function(v) S.jump = v end)
feat(pMove, "Sonsuz zıplama", fxInfJump)
feat(pMove, "Bunny hop (otomatik zıpla)", fxBhop)
pMove:Section("Uçuş & Işınlanma")
feat(pMove, "Uçuş (Space/E yukarı • Ctrl/Q aşağı)", fxFly)
pMove:Slider("Uçuş hızı", 10, 300, S.fly, function(v) S.fly = v end)
feat(pMove, "Noclip (duvarlardan geç)", fxNoclip)
feat(pMove, "CFrame hız", fxCFSpeed)
pMove:Slider("CFrame hız değeri", 10, 300, S.cf, function(v) S.cf = v end)
feat(pMove, "Tıkla-ışınlan (Ctrl + Tık)", fxClickTP)
feat(pMove, "Void koruması", fxVoid)
pMove:Section("Fizik")
pMove:Slider("Yerçekimi", 0, 400, math.floor(S.grav0), function(v) workspace.Gravity = v end)
pMove:Button("Yerçekimini sıfırla", function() workspace.Gravity = S.grav0; notify("Yerçekimi eski haline döndü") end)

-- Görsel
pVis:Section("ESP")
feat(pVis, "ESP (ana şalter)", fxESP, false, true)
pVis:Toggle("Highlight / Chams", true, function(v) ESP.opt.chams = v end)
pVis:Toggle("İsimler", true, function(v) ESP.opt.names = v end)
pVis:Toggle("Mesafe", true, function(v) ESP.opt.dist = v end)
pVis:Toggle("Can", true, function(v) ESP.opt.health = v end)
pVis:Toggle("Takım rengi", false, function(v) ESP.opt.team = v end)
if hasDrawing then pVis:Toggle("Tracer çizgileri", false, function(v) ESP.opt.tracers = v end)
else pVis:Label("Tracer: executor'un Drawing API'si yok") end
pVis:Section("Dünya")
feat(pVis, "Fullbright", fxFullbright)
feat(pVis, "Sis kaldır", fxNoFog)
feat(pVis, "Saat kilidi", fxTime)
pVis:Slider("Saat (0-24)", 0, 24, math.floor(Lighting.ClockTime), function(v) S.time = v end, .5)
feat(pVis, "X-Ray (duvarlar yarı saydam)", fxXray)
pVis:Section("Kamera & Ekran")
feat(pVis, "FOV uygula", fxFov)
pVis:Slider("FOV değeri", 30, 120, S.fov, function(v) S.fov = v end)
feat(pVis, "Zoom (C basılı tut)", fxZoom)
feat(pVis, "Kamera zoom kilidini aç", fxUnlockZoom)
feat(pVis, "Kamera duvarlardan geçsin", fxCamNoclip)
feat(pVis, "Nişangah", fxCross, false, true)
feat(pVis, "FPS / Ping göstergesi", fxHud, false, true)
pVis:Button("🚀 FPS Booster (geri alınamaz)", fpsBoost)

-- Eğlence
pFun:Section("Hareket oyunları")
feat(pFun, "Dön (spin)", fxSpin)
pFun:Slider("Dönüş hızı (°/sn)", 30, 1440, S.spin, function(v) S.spin = v end, 10)
feat(pFun, "Moonwalk (ters yürü)", fxMoon)
feat(pFun, "Ragdoll (yığıl)", fxRagdoll)
feat(pFun, "Hava yürüyüşü (E yüksel • Q alçal)", fxAir)
pFun:Button("Otur", function() local h = hum(); if h then h.Sit = true end end)
pFun:Button("Yukarı fırla", function() local r = root(); if r then r.AssemblyLinearVelocity = Vector3.new(0, 250, 0) end end)
pFun:Section("Efektler (sadece sen görürsün)")
feat(pFun, "Gökkuşağı iz (trail)", fxTrail)
feat(pFun, "Aura (parçacık)", fxAura)
feat(pFun, "Disko ışıkları", fxDisco)
feat(pFun, "Kamera dönüşü (barrel roll)", fxRoll)
pFun:Slider("Kamera dönüş hızı", 5, 200, S.roll, function(v) S.roll = v end, 5)
feat(pFun, "Tıkla-sil (Alt + Tık, yerel)", fxClickDelete)

-- Oyuncu
pPly:Section("Hedef seç")
local setSel = pPly:Label("Seçili: —")
pPly:PlayerList(function(p) S.target = p; setSel("Seçili: " .. (p and (p.DisplayName .. " (@" .. p.Name .. ")") or "—")) end)
pPly:Button("📍 Yanına ışınlan", function() if S.target then tpTo(S.target) else notify("Önce oyuncu seç") end end)
pPly:Button("🎥 İzle", function() if S.target then spectate(true) else notify("Önce oyuncu seç") end end)
pPly:Button("⏹ İzlemeyi bırak", function() spectate(false) end)
pPly:Button("📋 Kullanıcı ID kopyala", function()
    if S.target and setclipboard then setclipboard(tostring(S.target.UserId)); notify("Kopyalandı") else notify("Seçim yok / panoya erişim yok") end
end)
pPly:Button("🎲 Rastgele oyuncuya ışınlan", function()
    local l = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then l[#l + 1] = p end end
    if #l > 0 then tpTo(l[math.random(#l)]) else notify("Başka oyuncu yok") end
end)
pPly:Section("Koruma")
feat(pPly, "Anti-fling (oyuncu çarpışması kapalı)", fxAntiFling)

-- Ayarlar
pSet:Section("Görünüm")
pSet:Colors("Tema rengi", {
    Color3.fromRGB(139, 92, 246), Color3.fromRGB(59, 130, 246), Color3.fromRGB(16, 185, 129), Color3.fromRGB(244, 63, 94),
    Color3.fromRGB(245, 158, 11), Color3.fromRGB(236, 72, 153), Color3.fromRGB(34, 211, 238),
}, accentSet)
pSet:Slider("Menü boyutu (%)", 50, 130, math.floor(baseScale * 100), function(v) S.uiScale = v / 100; winScale.Scale = S.uiScale end, 5)
pSet:Section("Genel")
feat(pSet, "Anti-AFK", fxAfk, true)
pSet:Button("🔴 Tüm özellikleri kapat", function()
    for _, t in ipairs(Toggles) do t.Set(false) end
    notify("Hepsi kapatıldı")
end)
pSet:Button("♻ Karakteri sıfırla", function() local h = hum(); if h then h.Health = 0 end end)
pSet:Button("🔁 Yeniden katıl", rejoin)
pSet:Button("🌐 Sunucu değiştir", serverHop)

-- ═════════════════════════ BOTIS: EMOTE SAYFASI ═════════════════════════
setEmoteStatus = pEmote:Label("Emote: —")
pEmote:Section("R15 emote'lar (" .. #EMOTE_LIST .. ")")
pEmote:Picker("Emote listesi — tıkla ve oynat", EMOTE_LIST, playEmoteByName, 6)
local favPicker = pEmote:Picker("⭐ Favoriler", Cfg.favorites, playEmoteByName, 3)
pEmote:Button("▶ Son emote'u tekrar oynat", playLast)
pEmote:Button("⭐ Son emote'u favori ekle / çıkar", function()
    if Anim.last == "" then notify("Önce bir emote oynat"); return end
    local i = table.find(Cfg.favorites, Anim.last)
    if i then table.remove(Cfg.favorites, i); notify("Favoriden çıkarıldı")
    else table.insert(Cfg.favorites, Anim.last); notify("Favorilere eklendi ⭐") end
    favPicker.SetOptions(Cfg.favorites); saveSoon()
end)
pEmote:Button("⏹ Emote'u durdur", function() stopEmote(); stopPose(); refreshAnims() end)
pEmote:Section("R6 emote'lar")
pEmote:Picker("R6 emote listesi", R6_LIST, playR6, 4)

pEmote:Section("Emote ayarları")
pEmote:Toggle("Döngü (loop)", false, function(v)
    Anim.loop = v
    if Anim.track and v then Anim.track.Looped = true end
    updateStatus()
end)
pEmote:Toggle("Ters oynat", false, function(v)
    Anim.reverse = v
    if Anim.track and not Anim.freeze then Anim.track:AdjustSpeed(v and -math.abs(Anim.speed) or Anim.speed) end
end)
pEmote:Toggle("Dondur", false, function(v)
    Anim.freeze = v
    if Anim.track then Anim.track:AdjustSpeed(v and 0 or (Anim.reverse and -math.abs(Anim.speed) or Anim.speed)) end
end)
pEmote:Toggle("Hep oynat (hareket edince durmasın)", false, function(v) Anim.always = v end)
pEmote:Toggle("Zaman konumu uygula", false, function(v) Anim.timeOn = v end)
pEmote:Slider("Zaman konumu (%)", 0, 100, 0, function(v)
    Anim.timePct = v
    if Anim.timeOn and Anim.track and Anim.track.Length > 0 then Anim.track.TimePosition = v / 100 * Anim.track.Length end
end)
pEmote:Slider("Emote hızı", 0, 20, 1, function(v)
    Anim.speed = v
    if Anim.track and not Anim.freeze then Anim.track:AdjustSpeed(Anim.reverse and -math.abs(v) or v) end
    updateStatus()
end, .1)
feat(pEmote, "Rastgele emote (otomatik)", fxRandomEmote, false, true)
feat(pEmote, "Emote sohbet komutu (/em isim)", fxChatEmote, false, true)

pEmote:Section("Pozlar (dondurulmuş emote karesi)")
pEmote:Picker("Poz seç", POSE_NAMES, function(n) startPose(POSES[n]) end, 4)
pEmote:Button("⏹ Pozu bırak", stopPose)

pEmote:Section("Senkron")
pEmote:Input("Sync hedefi (isim)", "oyuncu adı + Enter", function(t)
    local p = findPlayer(t)
    if p then S.syncTarget = p; notify("Sync hedefi: " .. p.DisplayName) else notify("Oyuncu bulunamadı") end
end)
pEmote:Button("🔁 Hedefin emote'unu kopyala", function() mirrorEmotes(S.syncTarget or S.target) end)
feat(pEmote, "Sürekli emote sync", fxSyncEmote, false, true)

-- ═════════════════════════ BOTIS: ANİMASYON PAKETLERİ SAYFASI ═════════════════════════
setPackStatus = pPack:Label("Paket: —")
pPack:Section("Paket seç (" .. #PACK_LIST .. " adet, R15)")
pPack:Picker("Animasyon paketi — tıkla ve uygula", PACK_LIST, applyPack, 6)
pPack:Input("Paketi isimle uygula", "örn: zombie + Enter", function(t)
    local n = findPack(t)
    if n then applyPack(n) else notify("Paket bulunamadı") end
end)
feat(pPack, "Rastgele paket (6 sn'de bir)", fxRandomPack, false, true)
pPack:Button("♻ Animasyonları sıfırla", resetAnims)
pPack:Button("💾 Animasyonlarımı kaydet (dosya / pano)", function()
    local txt = animText()
    if not txt then notify("Animate bulunamadı"); return end
    if writefile then
        local fn = ("%s_Animations_%d.lua"):format(LP.Name, math.random(1e5, 9e5))
        writefile(fn, txt); notify("Kaydedildi: " .. fn, 3.5)
    elseif setclipboard then setclipboard(txt); notify("Panoya kopyalandı")
    else notify("Dosya/pano desteği yok") end
end)
pPack:Section("Paket ayarları")
pPack:Slider("Animasyon hızı", 0, 20, 1, function(v) Anim.animSpeed = v; updateStatus() end, .1)
feat(pPack, "Animasyon hızını sürekli uygula", fxAnimSpeed, false, true)
feat(pPack, "Animasyonu dondur", fxFreezePack, false, true)
feat(pPack, "Animasyon sohbet komutu (/a isim)", fxChatAnim, false, true)
pPack:Section("Başka oyuncudan kopyala")
pPack:Button("📋 Hedefin animasyon paketini kopyala", function()
    local p = S.syncTarget or S.target
    if not p then notify("Önce oyuncu seç"); return end
    if copyPackFrom(p) then refreshAnims(); notify("Kopyalandı: " .. p.DisplayName) else notify("Değişiklik yok / Animate bulunamadı") end
end)
feat(pPack, "Sürekli animasyon sync", fxSyncPack, false, true)

-- ═════════════════════════ BOTIS: ÖZEL ANİMASYON SAYFASI ═════════════════════════
local slotLabel = pCustom:Label("Seçili slot: Idle")
S.slot = SLOT_BY_NAME["Idle"]
pCustom:Section("1) Slot seç")
pCustom:Picker("Slot", SLOT_NAMES, function(n) S.slot = SLOT_BY_NAME[n]; slotLabel("Seçili slot: " .. n) end, 4)
pCustom:Section("2) Ata")
pCustom:Picker("Emote'u slota ata", EMOTE_LIST, function(n)
    if not S.slot then return end
    assignSlot(S.slot[2], EMOTES[n]); notify(S.slot[1] .. " ← " .. n)
end, 5)
pCustom:Picker("Paketten slota ata", PACK_LIST, function(n)
    if not S.slot then return end
    local field = S.slot[3]
    if not field then notify("Bu slot paketlerde yok — emote kullan"); return end
    local id = PACKS[n][field]
    if id then assignSlot(S.slot[2], id); notify(S.slot[1] .. " ← " .. n) else notify("Pakette bu animasyon yok") end
end, 4)
pCustom:Section("Rastgele")
pCustom:Button("🎲 Rastgele paket animasyonları", function()
    for _, s in ipairs(SLOTS) do
        if s[3] then
            local p = PACKS[PACK_LIST[math.random(#PACK_LIST)]]
            if p[s[3]] then Cfg.custom[s[2]] = p[s[3]]; setSlot(s[2], p[s[3]]) end
        end
    end
    refreshAnims(); saveSoon(); notify("Rastgele animasyonlar uygulandı")
end)
pCustom:Button("🎲 Rastgele emote animasyonları", function()
    for _, s in ipairs(SLOTS) do
        if s[3] then
            local id = EMOTES[EMOTE_LIST[math.random(#EMOTE_LIST)]]
            Cfg.custom[s[2]] = id; setSlot(s[2], id)
        end
    end
    refreshAnims(); saveSoon(); notify("Rastgele emote animasyonları uygulandı")
end)
feat(pCustom, "Rastgele idle (3 sn'de bir)", fxRandomIdle, false, true)
pCustom:Button("♻ Özel animasyonları sıfırla", resetAnims)

-- ═════════════════════════ BOTIS: HAREKET EKSTRALARI ═════════════════════════
pMove:Section("Ekstra")
pMove:Slider("Kalça yüksekliği (HipHeight)", 0, 60, math.floor((hum() and hum().HipHeight or 2) + .5), function(v)
    local h = hum(); if h then h.HipHeight = v end
end)
feat(pMove, "Platform (görünmez geniş zemin)", fxPlatform)
feat(pMove, "Yüzme (havada yüz)", fxSwim)
feat(pMove, "Ölünce aynı yerde doğ", fxRefreshPos, false, true)
pMove:Button("⬆ Zıpla", function() local h = hum(); if h then h.Jump = true end end)
pMove:Button("🪂 Skydive (+500 stud)", function() local r = root(); if r then r.CFrame = r.CFrame + Vector3.new(0, 500, 0) end end)
if setfpscap then
    pMove:Slider("FPS limiti", 10, 360, 60, function(v) setfpscap(v) end, 5)
end

-- ═════════════════════════ BOTIS: OYUNCU EKSTRALARI ═════════════════════════
S.onSelect = function(p) setSel("Seçili: " .. p.DisplayName .. " (@" .. p.Name .. ")") end
pPly:Section("Araçlar")
pPly:Button("🔎 Envanteri incele (Inspect)", function()
    if not S.target then notify("Önce oyuncu seç"); return end
    local GS = game:GetService("GuiService")
    pcall(function() GS:CloseInspectMenu() end)
    GS:InspectPlayerFromUserId(S.target.UserId)
end)
feat(pPly, "Dinle (hedefin ses konumu)", fxSpy, false, true)
feat(pPly, "Tıkla-seç (Ctrl + oyuncuya tık)", fxClickSelect, false, true)

-- ═════════════════════════ BOTIS: AYARLAR (TEMA & KİŞİSELLEŞTİRME) ═════════════════════════
pSet:Section("Tema")
pSet:Picker("Tema paleti", THEME_ORDER, function(n) applyTheme(n); notify("Tema: " .. n) end, 3)
local rgb = {Cfg.accent[1], Cfg.accent[2], Cfg.accent[3]}
local function rgbApply() accentSet(Color3.fromRGB(rgb[1], rgb[2], rgb[3])) end
pSet:Slider("Vurgu rengi • Kırmızı", 0, 255, rgb[1], function(v) rgb[1] = v; rgbApply() end)
pSet:Slider("Vurgu rengi • Yeşil", 0, 255, rgb[2], function(v) rgb[2] = v; rgbApply() end)
pSet:Slider("Vurgu rengi • Mavi", 0, 255, rgb[3], function(v) rgb[3] = v; rgbApply() end)
pSet:Input("Vurgu rengi HEX", "#8B5CF6 + Enter", function(t)
    local hex = t:gsub("#", ""):gsub("%s", "")
    local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
    if r and g and b then accentSet(Color3.fromRGB(r, g, b)) else notify("Geçersiz HEX (örn: #8B5CF6)") end
end)
pSet:Slider("Menü saydamlığı (%)", 0, 60, math.floor((Cfg.alpha or 0) * 100 + .5), function(v) winAlpha(v / 100) end, 5)
pSet:Toggle("Yüzen B butonu", true, function(v) fab.Visible = v end)
pSet:Input("Menü tuşu", "örn: Insert, RightShift", function(t)
    local ok, kc = pcall(function() return Enum.KeyCode[t:gsub("%s", "")] end)
    if ok and kc then S.menuKey = kc; Cfg.menuKey = kc.Name; saveSoon(); notify("Menü tuşu: " .. kc.Name) else notify("Geçersiz tuş adı") end
end)
pSet:Section("Sohbet komutları")
pSet:Input("Emote öneki", "varsayılan: /em", function(t)
    t = t:gsub("%s", ""); if t == "" then return end
    if t:sub(1, 1) ~= "/" then t = "/" .. t end
    Cfg.emotePrefix = t; saveSoon(); notify("Emote öneki: " .. t)
end)
pSet:Input("Animasyon öneki", "varsayılan: /a", function(t)
    t = t:gsub("%s", ""); if t == "" then return end
    if t:sub(1, 1) ~= "/" then t = "/" .. t end
    Cfg.animPrefix = t; saveSoon(); notify("Animasyon öneki: " .. t)
end)
pSet:Section("Dünya")
feat(pSet, "Her yerden duy (Hear Anywhere)", fxHear, false, true)
pSet:Section("Kayıt")
pSet:Button("💾 Ayarları şimdi kaydet", function()
    saveCfg()
    notify(canFile and "Ayarlar kaydedildi" or "Executor dosya yazmayı desteklemiyor", 3)
end)

local function destroy()
    for _, t in ipairs(Toggles) do pcall(t.Set, false) end
    pcall(function() workspace.Gravity = S.grav0 end)
    pcall(function() RunService:UnbindFromRenderStep("BotisRoll") end)
    pcall(spectate, false)
    pcall(function() if S._deathConn then S._deathConn:Disconnect() end end)
    pcall(function() game:GetService("SoundService"):SetListener(Enum.ListenerType.Camera) end)
    pcall(function() if S._bigPlat then S._bigPlat:Destroy() end end)
    pcall(saveCfg)
    if Anim and Anim.track then pcall(function() Anim.track:Stop() end) end
    for k in pairs(fc) do unbind(k) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
    pcall(function() espFolder:Destroy() end)
    env.__BOTIS_CLEANUP = nil
end
pSet:Button("🗑 Menüyü kapat ve temizle", destroy)
env.__BOTIS_CLEANUP = destroy

selectPage(pMove)
pcall(function() local k = Enum.KeyCode[Cfg.menuKey]; if k then S.menuKey = k end end)
pcall(function() if Cfg.theme ~= "Gece" then applyTheme(Cfg.theme) end end)
pcall(function() local a = Cfg.accent; setAccent(Color3.fromRGB(a[1], a[2], a[3])) end)
pcall(winAlpha, Cfg.alpha or 0)
task.spawn(function() captureOrig(); reapplyAnims(); updateStatus() end)
toggleMenu(true)
notify(("BOTIS HUB yüklendi • %d emote • %d animasyon paketi"):format(#EMOTE_LIST, #PACK_LIST), 4)