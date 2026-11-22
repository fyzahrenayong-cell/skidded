--[[
  Lib 1.5  (SprayUI family)
  Customizable fracture-style UI for script developers

  local Lib = loadstring(...)()
  local Win = Lib:Window({ Title = "Script", Preset = "White", Width = 560, Height = 430 })
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Lib = {
    Version = "1.5.0",
    Flags = {},
    _connections = {},
    _windows = {},
    Folder = "Lib15",
    ConfigFolder = "Lib15/Configs",
    Locked = false,
    Options = {
        Notify = false,
        ShowSize = true,
        ShowQuickControls = true,
        ShowTitleRect = true,
        ToggleKey = Enum.KeyCode.RightShift,
    },
}

local FONT_B64 = "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"

local function b64decode(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = data:gsub("[^" .. b .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2^(8 - i) or 0) end
        return string.char(c)
    end))
end

local function ensure_font()
    local ok, font = pcall(function()
        if isfolder and not isfolder(Lib.Folder) then makefolder(Lib.Folder) end
        if writefile and FONT_B64 ~= "" then
            local path = Lib.Folder .. "/Minecraft.ttf"
            if not (isfile and isfile(path)) then
                writefile(path, b64decode(FONT_B64))
            end
            if getcustomasset then
                return Font.new(getcustomasset(path))
            end
        end
        return nil
    end)
    if ok and font then return font end
    return Font.fromEnum(Enum.Font.Code)
end

local UIFont = ensure_font()

local Theme = {
    Background = Color3.fromRGB(10, 10, 10),
    Panel = Color3.fromRGB(16, 16, 16),
    PanelInner = Color3.fromRGB(22, 22, 22),
    Stroke = Color3.fromRGB(230, 230, 230),
    StrokeDim = Color3.fromRGB(90, 90, 90),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 150),
    Accent = Color3.fromRGB(255, 255, 255),
    AccentDim = Color3.fromRGB(170, 170, 170),
    ToggleOn = Color3.fromRGB(255, 255, 255),
    ToggleOff = Color3.fromRGB(36, 36, 36),
    SliderBg = Color3.fromRGB(36, 36, 36),
    TabIdle = Color3.fromRGB(18, 18, 18),
    TabActive = Color3.fromRGB(32, 32, 32),
    TitleBar = Color3.fromRGB(14, 14, 14),
}

local ThemeDefaults = {}
for k, v in pairs(Theme) do ThemeDefaults[k] = v end

local Presets = {
    White  = { Accent = Color3.fromRGB(255,255,255), AccentDim = Color3.fromRGB(170,170,170), ToggleOn = Color3.fromRGB(255,255,255), Stroke = Color3.fromRGB(230,230,230) },
    Purple = { Accent = Color3.fromRGB(180,100,255), AccentDim = Color3.fromRGB(110,60,170), ToggleOn = Color3.fromRGB(180,100,255), Stroke = Color3.fromRGB(180,100,255) },
    Blue   = { Accent = Color3.fromRGB(90,150,255), AccentDim = Color3.fromRGB(50,100,180), ToggleOn = Color3.fromRGB(90,150,255), Stroke = Color3.fromRGB(90,150,255) },
    Red    = { Accent = Color3.fromRGB(255,80,80), AccentDim = Color3.fromRGB(160,40,40), ToggleOn = Color3.fromRGB(255,80,80), Stroke = Color3.fromRGB(255,80,80) },
    Green  = { Accent = Color3.fromRGB(90,220,120), AccentDim = Color3.fromRGB(50,140,70), ToggleOn = Color3.fromRGB(90,220,120), Stroke = Color3.fromRGB(90,220,120) },
    Orange = { Accent = Color3.fromRGB(255,160,50), AccentDim = Color3.fromRGB(180,100,30), ToggleOn = Color3.fromRGB(255,160,50), Stroke = Color3.fromRGB(255,160,50) },
    Cyan   = { Accent = Color3.fromRGB(80,220,220), AccentDim = Color3.fromRGB(40,140,140), ToggleOn = Color3.fromRGB(80,220,220), Stroke = Color3.fromRGB(80,220,220) },
}

local function parent_gui(gui)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    local ok = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
    if not ok then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local function stroke(inst, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or Theme.Stroke
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.LineJoinMode = Enum.LineJoinMode.Miter
    s.Parent = inst
    return s
end

local function pad(inst, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = inst
    return p
end

local function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(Lib._connections, c)
    return c
end

local function ensure_folders()
    pcall(function()
        if not isfolder then return end
        if not isfolder(Lib.Folder) then makefolder(Lib.Folder) end
        if not isfolder(Lib.ConfigFolder) then makefolder(Lib.ConfigFolder) end
    end)
end

local function color_to_table(c)
    return { c.R, c.G, c.B }
end

local function table_to_color(t)
    if type(t) == "table" and t[1] then
        return Color3.new(t[1], t[2], t[3])
    end
    return Color3.new(1, 1, 1)
end

-- ===== PUBLIC THEME API =====
function Lib:GetTheme()
    local t = {}
    for k, v in pairs(Theme) do
        if typeof(v) == "Color3" then t[k] = color_to_table(v) else t[k] = v end
    end
    return t
end

function Lib:SetTheme(tbl)
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do
        if Theme[k] ~= nil then
            if typeof(Theme[k]) == "Color3" then
                if typeof(v) == "Color3" then Theme[k] = v
                elseif type(v) == "table" then Theme[k] = table_to_color(v) end
            else
                Theme[k] = v
            end
        end
    end
    if tbl.Accent and typeof(Theme.Accent) == "Color3" then
        Theme.ToggleOn = Theme.Accent
    end
end

function Lib:SetThemeKey(key, value)
    if Theme[key] == nil then return end
    if typeof(Theme[key]) == "Color3" and typeof(value) == "Color3" then
        Theme[key] = value
        if key == "Accent" then Theme.ToggleOn = value end
    elseif typeof(Theme[key]) == typeof(value) then
        Theme[key] = value
    end
end

function Lib:SetAccent(c)
    Theme.Accent = c
    Theme.ToggleOn = c
    Theme.Stroke = c
    Theme.AccentDim = Color3.new(math.max(c.R - 0.25, 0), math.max(c.G - 0.25, 0), math.max(c.B - 0.25, 0))
end

function Lib:ApplyPreset(name)
    local p = Presets[name]
    if not p then return false end
    for k, v in pairs(p) do Theme[k] = v end
    return true
end

function Lib:ListPresets()
    local t = {}
    for k in pairs(Presets) do table.insert(t, k) end
    table.sort(t)
    return t
end

function Lib:ResetTheme()
    for k, v in pairs(ThemeDefaults) do Theme[k] = v end
end

function Lib:SetOption(key, value)
    if Lib.Options[key] ~= nil then Lib.Options[key] = value end
end

function Lib:Get(f) return Lib.Flags[f] end
function Lib:Set(f, v) Lib.Flags[f] = v end

-- ===== CONFIG =====
function Lib:GetConfig()
    local cfg = { Flags = {}, Theme = Lib:GetTheme(), Version = Lib.Version }
    for k, v in pairs(Lib.Flags) do
        if typeof(v) == "Color3" then
            cfg.Flags[k] = { __color = true, v.R, v.G, v.B }
        elseif typeof(v) ~= "Instance" and typeof(v) ~= "function" then
            cfg.Flags[k] = v
        end
    end
    return HttpService:JSONEncode(cfg)
end

function Lib:LoadConfig(json)
    local ok, cfg = pcall(HttpService.JSONDecode, HttpService, json)
    if not ok or type(cfg) ~= "table" then return false end
    if cfg.Theme then Lib:SetTheme(cfg.Theme) end
    if cfg.Flags then
        for k, v in pairs(cfg.Flags) do
            if type(v) == "table" and v.__color then
                Lib.Flags[k] = Color3.new(v[1], v[2], v[3])
            else
                Lib.Flags[k] = v
            end
        end
    end
    for _, win in ipairs(Lib._windows) do
        if win._refreshFlags then win:_refreshFlags() end
    end
    return true
end

function Lib:SaveConfig(name)
    ensure_folders()
    name = tostring(name or "default"):gsub("[^%w%-%_]", "")
    if name == "" then name = "default" end
    return pcall(function()
        writefile(Lib.ConfigFolder .. "/" .. name .. ".json", Lib:GetConfig())
    end)
end

function Lib:LoadConfigFile(name)
    ensure_folders()
    name = tostring(name or "default"):gsub("[^%w%-%_]", "")
    local ok, data = pcall(function() return readfile(Lib.ConfigFolder .. "/" .. name .. ".json") end)
    if not ok or not data then return false end
    return Lib:LoadConfig(data)
end

function Lib:ListConfigs()
    ensure_folders()
    local list = {}
    pcall(function()
        if not listfiles then return end
        for _, f in ipairs(listfiles(Lib.ConfigFolder)) do
            local n = f:gsub("\\", "/"):match("([^/]+)%.json$")
            if n then table.insert(list, n) end
        end
    end)
    table.sort(list)
    return list
end

function Lib:DeleteConfig(name)
    name = tostring(name or ""):gsub("[^%w%-%_]", "")
    pcall(function()
        local path = Lib.ConfigFolder .. "/" .. name .. ".json"
        if isfile and isfile(path) then delfile(path) end
    end)
end

-- ===== WINDOW =====
function Lib:Window(opts)
    opts = opts or {}
    local title = opts.Title or "Lib"
    local width = math.clamp(opts.Width or 560, 300, 1400)
    local height = math.clamp(opts.Height or 430, 220, 1000)
    local toggleKey = opts.ToggleKey or Lib.Options.ToggleKey
    local logoImage = opts.Logo
    if opts.Preset then Lib:ApplyPreset(opts.Preset) elseif not opts.Accent then Lib:ApplyPreset("White") end
    if opts.Accent then Lib:SetAccent(opts.Accent) end
    if opts.Theme then Lib:SetTheme(opts.Theme) end
    for k, v in pairs(opts) do
        if Lib.Options[k] ~= nil then Lib.Options[k] = v end
    end
    ensure_folders()

    local gui = Instance.new("ScreenGui")
    gui.Name = "Lib15_" .. tostring(math.random(1000, 9999))
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 150
    parent_gui(gui)

    -- quick controls left
    local leftStack = Instance.new("Frame")
    leftStack.BackgroundTransparency = 1
    leftStack.Size = UDim2.fromOffset(100, 52)
    leftStack.Position = UDim2.fromOffset(opts.ControlsX or 12, opts.ControlsY or 72)
    leftStack.Visible = Lib.Options.ShowQuickControls ~= false
    leftStack.Parent = gui

    local function chip(text, order)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(96, 22)
        b.Position = UDim2.fromOffset(0, (order - 1) * 24)
        b.BackgroundColor3 = Theme.Background
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.FontFace = UIFont
        b.TextSize = 12
        b.TextColor3 = Theme.Text
        b.Text = text
        b.Parent = leftStack
        stroke(b, Theme.Stroke, 1)
        return b
    end
    local toggleBtn = chip("Toggle UI", 1)
    local lockBtn = chip("Lock UI", 2)

    -- title rect right
    local titleRect = Instance.new("Frame")
    titleRect.BackgroundColor3 = Theme.Background
    titleRect.BorderSizePixel = 0
    titleRect.AnchorPoint = Vector2.new(1, 0)
    titleRect.Position = UDim2.new(1, -(opts.TitleRectX or 16), 0, opts.TitleRectY or 72)
    titleRect.Size = UDim2.fromOffset(opts.TitleRectWidth or 150, 28)
    titleRect.Visible = Lib.Options.ShowTitleRect ~= false
    titleRect.Parent = gui
    stroke(titleRect, Theme.Stroke, 1)

    local titleRectLogo = Instance.new("ImageLabel")
    titleRectLogo.BackgroundTransparency = 1
    titleRectLogo.Size = UDim2.fromOffset(16, 16)
    titleRectLogo.Position = UDim2.fromOffset(6, 6)
    titleRectLogo.ScaleType = Enum.ScaleType.Fit
    titleRectLogo.Visible = logoImage ~= nil and logoImage ~= ""
    if logoImage then titleRectLogo.Image = logoImage end
    titleRectLogo.Parent = titleRect

    local titleRectText = Instance.new("TextLabel")
    titleRectText.BackgroundTransparency = 1
    titleRectText.Position = UDim2.fromOffset(logoImage and 26 or 10, 0)
    titleRectText.Size = UDim2.new(1, -12, 1, 0)
    titleRectText.FontFace = UIFont
    titleRectText.TextSize = 13
    titleRectText.TextColor3 = Theme.Text
    titleRectText.TextXAlignment = Enum.TextXAlignment.Left
    titleRectText.Text = title
    titleRectText.Parent = titleRect

    -- window
    local win = Instance.new("Frame")
    win.Size = UDim2.fromOffset(width, height)
    win.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    win.BackgroundColor3 = Theme.Background
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    stroke(win, Theme.Stroke, 1)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Theme.TitleBar
    header.BorderSizePixel = 0
    header.Parent = win

    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 1, -1)
    headerLine.BackgroundColor3 = Theme.Stroke
    headerLine.BorderSizePixel = 0
    headerLine.Parent = header

    local headerTitle = Instance.new("TextLabel")
    headerTitle.BackgroundTransparency = 1
    headerTitle.Position = UDim2.fromOffset(12, 0)
    headerTitle.Size = UDim2.new(1, -90, 1, 0)
    headerTitle.FontFace = UIFont
    headerTitle.TextSize = 14
    headerTitle.TextColor3 = Theme.Text
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Text = title
    headerTitle.Parent = header

    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.AnchorPoint = Vector2.new(1, 0)
    sizeLabel.Position = UDim2.new(1, -12, 0, 0)
    sizeLabel.Size = UDim2.fromOffset(80, 30)
    sizeLabel.FontFace = UIFont
    sizeLabel.TextSize = 11
    sizeLabel.TextColor3 = Theme.TextDim
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Right
    sizeLabel.Text = string.format("%d x %d", width, height)
    sizeLabel.Visible = Lib.Options.ShowSize ~= false
    sizeLabel.Parent = header

    do
        local dragging, origin, originPos
        connect(header.InputBegan, function(input)
            if Lib.Locked then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                origin = input.Position
                originPos = win.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if not dragging or Lib.Locked then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = input.Position - origin
            win.Position = UDim2.new(originPos.X.Scale, originPos.X.Offset + d.X, originPos.Y.Scale, originPos.Y.Offset + d.Y)
        end)
    end

    local resize = Instance.new("TextButton")
    resize.Size = UDim2.fromOffset(12, 12)
    resize.Position = UDim2.new(1, -12, 1, -12)
    resize.BackgroundColor3 = Theme.PanelInner
    resize.BorderSizePixel = 0
    resize.Text = ""
    resize.AutoButtonColor = false
    resize.ZIndex = 20
    resize.Parent = win
    stroke(resize, Theme.StrokeDim, 1)
    do
        local resizing, start, startSize
        connect(resize.InputBegan, function(input)
            if Lib.Locked then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                start = input.Position
                startSize = win.AbsoluteSize
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then resizing = false end
                end)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if not resizing or Lib.Locked then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = input.Position - start
            local nw = math.clamp(startSize.X + d.X, 300, 1400)
            local nh = math.clamp(startSize.Y + d.Y, 220, 1000)
            win.Size = UDim2.fromOffset(nw, nh)
            sizeLabel.Text = string.format("%d x %d", math.floor(nw), math.floor(nh))
        end)
    end

    local tabStrip = Instance.new("Frame")
    tabStrip.Size = UDim2.new(1, -2, 0, 26)
    tabStrip.Position = UDim2.fromOffset(1, 30)
    tabStrip.BackgroundColor3 = Theme.Panel
    tabStrip.BorderSizePixel = 0
    tabStrip.Parent = win
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Parent = tabStrip

    local tabLine = Instance.new("Frame")
    tabLine.Size = UDim2.new(1, 0, 0, 1)
    tabLine.Position = UDim2.new(0, 0, 1, -1)
    tabLine.BackgroundColor3 = Theme.StrokeDim
    tabLine.BorderSizePixel = 0
    tabLine.Parent = tabStrip

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -64)
    content.Position = UDim2.fromOffset(5, 60)
    content.BackgroundColor3 = Theme.Panel
    content.BorderSizePixel = 0
    content.Parent = win
    stroke(content, Theme.StrokeDim, 1)

    local flagRefreshers = {}
    local WindowAPI = {
        Gui = gui, Frame = win, Tabs = {},
        _refreshFlags = function() for _, fn in ipairs(flagRefreshers) do pcall(fn) end end,
    }

    function WindowAPI:SetVisible(v) win.Visible = v end
    function WindowAPI:Toggle()
        if Lib.Locked and win.Visible then return end
        win.Visible = not win.Visible
    end
    function WindowAPI:SetTitle(t)
        title = t
        headerTitle.Text = t
        titleRectText.Text = t
    end
    function WindowAPI:SetLogo(image)
        logoImage = image
        local show = image and image ~= ""
        titleRectLogo.Visible = show
        if show then titleRectLogo.Image = image end
        titleRectText.Position = UDim2.fromOffset(show and 26 or 10, 0)
    end
    function WindowAPI:SetSize(w, h)
        w = math.clamp(w or 560, 300, 1400)
        h = math.clamp(h or 430, 220, 1000)
        win.Size = UDim2.fromOffset(w, h)
        sizeLabel.Text = string.format("%d x %d", w, h)
    end
    function WindowAPI:SetControlsPosition(x, y)
        leftStack.Position = UDim2.fromOffset(x, y)
    end
    function WindowAPI:SetTitleRectPosition(offsetRight, y)
        titleRect.Position = UDim2.new(1, -offsetRight, 0, y)
    end

    connect(toggleBtn.MouseButton1Click, function() WindowAPI:Toggle() end)
    connect(lockBtn.MouseButton1Click, function()
        Lib.Locked = not Lib.Locked
        lockBtn.Text = Lib.Locked and "Unlock UI" or "Lock UI"
    end)
    connect(UserInputService.InputBegan, function(input, gp)
        if gp then return end
        if input.KeyCode == toggleKey then WindowAPI:Toggle() end
    end)

    function WindowAPI:Tab(name)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.fromOffset(math.max(72, #name * 8 + 20), 26)
        tabBtn.BackgroundColor3 = Theme.TabIdle
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.FontFace = UIFont
        tabBtn.TextSize = 13
        tabBtn.TextColor3 = Theme.TextDim
        tabBtn.Text = name
        tabBtn.Parent = tabStrip

        local page = Instance.new("Frame")
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = content

        local function makeCol(side)
            local sf = Instance.new("ScrollingFrame")
            sf.BackgroundTransparency = 1
            sf.BorderSizePixel = 0
            sf.ScrollBarThickness = 2
            sf.ScrollBarImageColor3 = Theme.Accent
            sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
            sf.CanvasSize = UDim2.new()
            sf.Size = UDim2.new(0.5, -6, 1, -8)
            sf.Position = side == "Right" and UDim2.new(0.5, 2, 0, 4) or UDim2.fromOffset(4, 4)
            sf.Parent = page
            Instance.new("UIListLayout", sf).Padding = UDim.new(0, 6)
            return sf
        end
        local leftCol, rightCol = makeCol("Left"), makeCol("Right")
        local TabAPI = { Name = name, Page = page, Button = tabBtn }

        local function select()
            for _, t in pairs(WindowAPI.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = Theme.TabIdle
                t.Button.TextColor3 = Theme.TextDim
            end
            page.Visible = true
            tabBtn.BackgroundColor3 = Theme.TabActive
            tabBtn.TextColor3 = Theme.Text
        end
        connect(tabBtn.MouseButton1Click, select)

        function TabAPI:Group(groupName, side)
            local parent = side == "Right" and rightCol or leftCol
            local box = Instance.new("Frame")
            box.Size = UDim2.new(1, -4, 0, 28)
            box.AutomaticSize = Enum.AutomaticSize.Y
            box.BackgroundColor3 = Theme.PanelInner
            box.BorderSizePixel = 0
            box.Parent = parent
            stroke(box, Theme.StrokeDim, 1)

            local gHeader = Instance.new("TextLabel")
            gHeader.BackgroundTransparency = 1
            gHeader.Size = UDim2.new(1, -10, 0, 18)
            gHeader.Position = UDim2.fromOffset(8, 4)
            gHeader.FontFace = UIFont
            gHeader.TextSize = 12
            gHeader.TextColor3 = Theme.Text
            gHeader.TextXAlignment = Enum.TextXAlignment.Left
            gHeader.Text = groupName
            gHeader.Parent = box

            local body = Instance.new("Frame")
            body.Size = UDim2.new(1, -10, 0, 0)
            body.Position = UDim2.fromOffset(5, 22)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.BackgroundTransparency = 1
            body.Parent = box
            Instance.new("UIListLayout", body).Padding = UDim.new(0, 3)
            pad(body, 2, 0, 2, 8)

            local subPages, currentSub = {}, nil
            local GroupAPI = {}

            function GroupAPI:SubTabs(names)
                local subRow = Instance.new("Frame")
                subRow.Size = UDim2.new(1, 0, 0, 18)
                subRow.BackgroundTransparency = 1
                subRow.Parent = body
                local lay = Instance.new("UIListLayout")
                lay.FillDirection = Enum.FillDirection.Horizontal
                lay.Padding = UDim.new(0, 3)
                lay.Parent = subRow
                for i, n in ipairs(names) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.fromOffset(math.max(52, #n * 7 + 14), 16)
                    b.BackgroundColor3 = Theme.TabIdle
                    b.BorderSizePixel = 0
                    b.AutoButtonColor = false
                    b.FontFace = UIFont
                    b.TextSize = 11
                    b.TextColor3 = Theme.TextDim
                    b.Text = n
                    b.Parent = subRow
                    stroke(b, Theme.StrokeDim, 1)
                    local sp = Instance.new("Frame")
                    sp.Size = UDim2.new(1, 0, 0, 0)
                    sp.AutomaticSize = Enum.AutomaticSize.Y
                    sp.BackgroundTransparency = 1
                    sp.Visible = false
                    sp.Parent = body
                    Instance.new("UIListLayout", sp).Padding = UDim.new(0, 2)
                    subPages[n] = { frame = sp, btn = b }
                    connect(b.MouseButton1Click, function()
                        for _, d in pairs(subPages) do
                            d.frame.Visible = false
                            d.btn.BackgroundColor3 = Theme.TabIdle
                            d.btn.TextColor3 = Theme.TextDim
                        end
                        sp.Visible = true
                        b.BackgroundColor3 = Theme.TabActive
                        b.TextColor3 = Theme.Text
                        currentSub = n
                    end)
                    if i == 1 then
                        sp.Visible = true
                        b.BackgroundColor3 = Theme.TabActive
                        b.TextColor3 = Theme.Text
                        currentSub = n
                    end
                end
                return GroupAPI
            end

            local function host()
                if currentSub and subPages[currentSub] then return subPages[currentSub].frame end
                return body
            end

            function GroupAPI:Toggle(label, flag, default, callback, color3)
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = default == true end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 18)
                row.BackgroundTransparency = 1
                row.Parent = host()

                local boxBtn = Instance.new("TextButton")
                boxBtn.Size = UDim2.fromOffset(12, 12)
                boxBtn.Position = UDim2.fromOffset(2, 3)
                boxBtn.BackgroundColor3 = Lib.Flags[flag] and Theme.ToggleOn or Theme.ToggleOff
                boxBtn.BorderSizePixel = 0
                boxBtn.Text = ""
                boxBtn.AutoButtonColor = false
                boxBtn.Parent = row
                stroke(boxBtn, Theme.Stroke, 1)

                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Position = UDim2.fromOffset(18, 0)
                lab.Size = UDim2.new(1, color3 and -40 or -22, 1, 0)
                lab.FontFace = UIFont
                lab.TextSize = 13
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row

                if color3 then
                    local sw = Instance.new("Frame")
                    sw.Size = UDim2.fromOffset(12, 11)
                    sw.Position = UDim2.new(1, -16, 0, 3)
                    sw.BackgroundColor3 = color3
                    sw.BorderSizePixel = 0
                    sw.Parent = row
                    stroke(sw, Theme.Stroke, 1)
                    Lib.Flags[flag .. "_Color"] = color3
                end

                local function paint()
                    boxBtn.BackgroundColor3 = Lib.Flags[flag] and Theme.ToggleOn or Theme.ToggleOff
                end
                table.insert(flagRefreshers, paint)
                connect(boxBtn.MouseButton1Click, function()
                    Lib.Flags[flag] = not Lib.Flags[flag]
                    paint()
                    if callback then callback(Lib.Flags[flag]) end
                end)
                return {
                    Set = function(_, v) Lib.Flags[flag] = not not v; paint(); if callback then callback(Lib.Flags[flag]) end end,
                    Get = function() return Lib.Flags[flag] end,
                }
            end

            function GroupAPI:Slider(label, flag, minv, maxv, default, callback)
                minv, maxv = minv or 0, maxv or 100
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = default or minv end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundTransparency = 1
                row.Parent = host()

                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(1, -52, 0, 13)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.FontFace = UIFont
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row

                local val = Instance.new("TextLabel")
                val.BackgroundTransparency = 1
                val.Size = UDim2.fromOffset(50, 13)
                val.Position = UDim2.new(1, -52, 0, 0)
                val.FontFace = UIFont
                val.TextSize = 12
                val.TextColor3 = Theme.TextDim
                val.TextXAlignment = Enum.TextXAlignment.Right
                val.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, -4, 0, 5)
                track.Position = UDim2.fromOffset(2, 17)
                track.BackgroundColor3 = Theme.SliderBg
                track.BorderSizePixel = 0
                track.Parent = row
                stroke(track, Theme.StrokeDim, 1)

                local fill = Instance.new("Frame")
                fill.BackgroundColor3 = Theme.Accent
                fill.BorderSizePixel = 0
                fill.Parent = track

                local function apply(v)
                    v = math.clamp(v, minv, maxv)
                    if (maxv - minv) >= 5 then v = math.floor(v + 0.5) else v = math.floor(v * 100 + 0.5) / 100 end
                    Lib.Flags[flag] = v
                    fill.Size = UDim2.new((v - minv) / math.max(maxv - minv, 1e-9), 0, 1, 0)
                    val.Text = tostring(v)
                    if callback then callback(v) end
                end
                apply(Lib.Flags[flag])
                table.insert(flagRefreshers, function() apply(Lib.Flags[flag]) end)

                local hold = false
                connect(track.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hold = true end
                end)
                connect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hold = false end
                end)
                connect(UserInputService.InputChanged, function(input)
                    if not hold then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                    apply(minv + pct * (maxv - minv))
                end)
                return { Set = function(_, v) apply(v) end, Get = function() return Lib.Flags[flag] end }
            end

            function GroupAPI:ColorPicker(label, flag, default, callback)
                default = default or Color3.new(1, 1, 1)
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = default end
                if typeof(Lib.Flags[flag]) ~= "Color3" then Lib.Flags[flag] = default end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 18)
                row.BackgroundTransparency = 1
                row.Parent = host()

                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(1, -40, 1, 0)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.FontFace = UIFont
                lab.TextSize = 13
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row

                local sw = Instance.new("TextButton")
                sw.Size = UDim2.fromOffset(28, 12)
                sw.Position = UDim2.new(1, -32, 0, 3)
                sw.BackgroundColor3 = Lib.Flags[flag]
                sw.BorderSizePixel = 0
                sw.Text = ""
                sw.AutoButtonColor = false
                sw.Parent = row
                stroke(sw, Theme.Stroke, 1)

                local open = false
                local panel
                local function close()
                    if panel then panel:Destroy(); panel = nil end
                    open = false
                end

                local function setColor(c)
                    Lib.Flags[flag] = c
                    sw.BackgroundColor3 = c
                    if callback then callback(c) end
                end

                connect(sw.MouseButton1Click, function()
                    if open then close(); return end
                    open = true
                    panel = Instance.new("Frame")
                    panel.Size = UDim2.fromOffset(150, 78)
                    panel.Position = UDim2.new(1, -150, 0, 18)
                    panel.BackgroundColor3 = Theme.Background
                    panel.BorderSizePixel = 0
                    panel.ZIndex = 50
                    panel.Parent = row
                    stroke(panel, Theme.Stroke, 1)

                    local function channel(name, y, getter, setter)
                        local l = Instance.new("TextLabel")
                        l.BackgroundTransparency = 1
                        l.Size = UDim2.fromOffset(14, 14)
                        l.Position = UDim2.fromOffset(6, y)
                        l.FontFace = UIFont
                        l.TextSize = 11
                        l.TextColor3 = Theme.TextDim
                        l.Text = name
                        l.ZIndex = 51
                        l.Parent = panel

                        local track = Instance.new("Frame")
                        track.Size = UDim2.fromOffset(100, 5)
                        track.Position = UDim2.fromOffset(24, y + 4)
                        track.BackgroundColor3 = Theme.SliderBg
                        track.BorderSizePixel = 0
                        track.ZIndex = 51
                        track.Parent = panel
                        stroke(track, Theme.StrokeDim, 1)

                        local fill = Instance.new("Frame")
                        fill.BackgroundColor3 = Theme.Accent
                        fill.BorderSizePixel = 0
                        fill.Size = UDim2.new(getter(), 0, 1, 0)
                        fill.ZIndex = 52
                        fill.Parent = track

                        local hold = false
                        local function apply(pct)
                            pct = math.clamp(pct, 0, 1)
                            fill.Size = UDim2.new(pct, 0, 1, 0)
                            setter(pct)
                            local c = Lib.Flags[flag]
                            setColor(Color3.new(
                                name == "R" and pct or c.R,
                                name == "G" and pct or c.G,
                                name == "B" and pct or c.B
                            ))
                        end
                        connect(track.InputBegan, function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                hold = true
                                local pct = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
                                apply(pct)
                            end
                        end)
                        connect(UserInputService.InputEnded, function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hold = false end
                        end)
                        connect(UserInputService.InputChanged, function(input)
                            if not hold or not panel then return end
                            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
                            local pct = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
                            apply(pct)
                        end)
                    end

                    local c0 = Lib.Flags[flag]
                    channel("R", 8, function() return c0.R end, function() end)
                    channel("G", 28, function() return c0.G end, function() end)
                    channel("B", 48, function() return c0.B end, function() end)

                    local done = Instance.new("TextButton")
                    done.Size = UDim2.fromOffset(40, 14)
                    done.Position = UDim2.fromOffset(104, 60)
                    done.BackgroundColor3 = Theme.PanelInner
                    done.BorderSizePixel = 0
                    done.FontFace = UIFont
                    done.TextSize = 10
                    done.TextColor3 = Theme.Text
                    done.Text = "OK"
                    done.ZIndex = 53
                    done.Parent = panel
                    stroke(done, Theme.Stroke, 1)
                    connect(done.MouseButton1Click, close)
                end)

                table.insert(flagRefreshers, function()
                    if typeof(Lib.Flags[flag]) == "Color3" then sw.BackgroundColor3 = Lib.Flags[flag] end
                end)

                return {
                    Set = function(_, c) if typeof(c) == "Color3" then setColor(c) end end,
                    Get = function() return Lib.Flags[flag] end,
                }
            end

            function GroupAPI:Dropdown(label, flag, options, default, callback)
                options = options or { "None" }
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = default or options[1] end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 18)
                row.BackgroundTransparency = 1
                row.ZIndex = 5
                row.Parent = host()

                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(0.38, 0, 1, 0)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.FontFace = UIFont
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.58, 0, 0, 15)
                btn.Position = UDim2.new(0.4, 0, 0, 1)
                btn.BackgroundColor3 = Theme.Background
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.FontFace = UIFont
                btn.TextSize = 11
                btn.TextColor3 = Theme.Text
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Text = " " .. tostring(Lib.Flags[flag])
                btn.ZIndex = 6
                btn.Parent = row
                stroke(btn, Theme.Stroke, 1)

                local open, listFrame = false, nil
                connect(btn.MouseButton1Click, function()
                    if open and listFrame then listFrame:Destroy(); listFrame = nil; open = false; return end
                    open = true
                    listFrame = Instance.new("Frame")
                    listFrame.Size = UDim2.new(0.58, 0, 0, math.min(#options * 16, 96))
                    listFrame.Position = UDim2.new(0.4, 0, 0, 16)
                    listFrame.BackgroundColor3 = Theme.Background
                    listFrame.BorderSizePixel = 0
                    listFrame.ZIndex = 40
                    listFrame.Parent = row
                    stroke(listFrame, Theme.Stroke, 1)
                    Instance.new("UIListLayout", listFrame)
                    for _, opt in ipairs(options) do
                        local ob = Instance.new("TextButton")
                        ob.Size = UDim2.new(1, 0, 0, 16)
                        ob.BackgroundColor3 = Theme.PanelInner
                        ob.BorderSizePixel = 0
                        ob.AutoButtonColor = false
                        ob.FontFace = UIFont
                        ob.TextSize = 11
                        ob.TextColor3 = Theme.Text
                        ob.TextXAlignment = Enum.TextXAlignment.Left
                        ob.Text = " " .. opt
                        ob.ZIndex = 41
                        ob.Parent = listFrame
                        connect(ob.MouseButton1Click, function()
                            Lib.Flags[flag] = opt
                            btn.Text = " " .. opt
                            if callback then callback(opt) end
                            listFrame:Destroy(); listFrame = nil; open = false
                        end)
                    end
                end)
                table.insert(flagRefreshers, function() btn.Text = " " .. tostring(Lib.Flags[flag]) end)
                return { Get = function() return Lib.Flags[flag] end }
            end

            function GroupAPI:Button(label, callback)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -4, 0, 20)
                btn.BackgroundColor3 = Theme.Background
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.FontFace = UIFont
                btn.TextSize = 13
                btn.TextColor3 = Theme.Text
                btn.Text = label
                btn.Parent = host()
                stroke(btn, Theme.Stroke, 1)
                connect(btn.MouseButton1Click, function() if callback then callback() end end)
                return btn
            end

            function GroupAPI:ButtonAccent(label, callback)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -4, 0, 20)
                btn.BackgroundColor3 = Theme.PanelInner
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.FontFace = UIFont
                btn.TextSize = 13
                btn.TextColor3 = Theme.Text
                btn.Text = label
                btn.Parent = host()
                stroke(btn, Theme.Stroke, 1)
                connect(btn.MouseButton1Click, function() if callback then callback() end end)
                return btn
            end

            function GroupAPI:Label(text)
                local lab = Instance.new("TextLabel")
                lab.Size = UDim2.new(1, 0, 0, 14)
                lab.BackgroundTransparency = 1
                lab.FontFace = UIFont
                lab.TextSize = 11
                lab.TextColor3 = Theme.TextDim
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = text
                lab.Parent = host()
                return lab
            end

            function GroupAPI:Textbox(label, flag, default, callback)
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = default or "" end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 18)
                row.BackgroundTransparency = 1
                row.Parent = host()
                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(0.38, 0, 1, 0)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.FontFace = UIFont
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row
                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.58, 0, 0, 15)
                box.Position = UDim2.new(0.4, 0, 0, 1)
                box.BackgroundColor3 = Theme.Background
                box.BorderSizePixel = 0
                box.FontFace = UIFont
                box.TextSize = 11
                box.TextColor3 = Theme.Text
                box.ClearTextOnFocus = false
                box.Text = tostring(Lib.Flags[flag])
                box.Parent = row
                stroke(box, Theme.Stroke, 1)
                connect(box.FocusLost, function()
                    Lib.Flags[flag] = box.Text
                    if callback then callback(box.Text) end
                end)
                return box
            end

            function GroupAPI:Keybind(label, flag, default, callback)
                default = default or Enum.KeyCode.Unknown
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = default end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 18)
                row.BackgroundTransparency = 1
                row.Parent = host()
                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(0.5, 0, 1, 0)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.FontFace = UIFont
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.45, 0, 0, 15)
                btn.Position = UDim2.new(0.52, 0, 0, 1)
                btn.BackgroundColor3 = Theme.Background
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.FontFace = UIFont
                btn.TextSize = 11
                btn.TextColor3 = Theme.Text
                local function keyName()
                    local k = Lib.Flags[flag]
                    if typeof(k) == "EnumItem" then return k.Name end
                    return tostring(k)
                end
                btn.Text = keyName()
                btn.Parent = row
                stroke(btn, Theme.Stroke, 1)
                local listening = false
                connect(btn.MouseButton1Click, function()
                    listening = true
                    btn.Text = "..."
                end)
                connect(UserInputService.InputBegan, function(input, gp)
                    if not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        Lib.Flags[flag] = input.KeyCode
                        btn.Text = input.KeyCode.Name
                        listening = false
                        if callback then callback(input.KeyCode) end
                    end
                end)
                return { Get = function() return Lib.Flags[flag] end }
            end

            return GroupAPI
        end

        WindowAPI.Tabs[name] = TabAPI
        if not WindowAPI._active then
            WindowAPI._active = TabAPI
            select()
        end
        return TabAPI
    end

    function WindowAPI:AddSettingsTab()
        local tab = WindowAPI:Tab("Settings")
        local theme = tab:Group("Theme", "Left")
        theme:Label("Presets")
        for _, name in ipairs(Lib:ListPresets()) do
            theme:Button(name, function() Lib:ApplyPreset(name) end)
        end
        theme:ColorPicker("Accent", "Lib_AccentColor", Theme.Accent, function(c)
            Lib:SetAccent(c)
        end)

        local cfg = tab:Group("Configuration", "Right")
        cfg:Textbox("New name", "Lib_ConfigName", "default")
        local list = Lib:ListConfigs()
        if #list == 0 then list = { "(none)" } end
        cfg:Dropdown("Select", "Lib_ConfigPick", list, list[1])
        cfg:Button("Save", function() Lib:SaveConfig(Lib.Flags["Lib_ConfigName"] or "default") end)
        cfg:Button("Load selected", function()
            local n = Lib.Flags["Lib_ConfigPick"]
            if n and n ~= "(none)" then Lib:LoadConfigFile(n) end
        end)
        cfg:Button("Delete selected", function()
            local n = Lib.Flags["Lib_ConfigPick"]
            if n and n ~= "(none)" then Lib:DeleteConfig(n) end
        end)
        cfg:ButtonAccent("Unload", function() WindowAPI:Unload() end)
        return tab
    end

    function WindowAPI:Unload()
        for i, w in ipairs(Lib._windows) do
            if w == WindowAPI then table.remove(Lib._windows, i) break end
        end
        pcall(function() gui:Destroy() end)
    end

    table.insert(Lib._windows, WindowAPI)
    return WindowAPI
end

local env = (getgenv and getgenv()) or _G
env.Lib = Lib
env.SprayUI = Lib -- alias
print("[Lib] " .. Lib.Version .. " loaded")
return Lib


-- optional demo when file is executed alone
task.spawn(function()
    local Lib = ((getgenv and getgenv()) or _G).Lib
    if not Lib then return end
    local ok, err = pcall(function()
        local Win = Lib:Window({
            Title = "Lib 1.5",
            Width = 580,
            Height = 440,
            Preset = "White",
            ShowQuickControls = true,
            ShowTitleRect = true,
        })
        local Main = Win:Tab("Main")
        Win:AddSettingsTab()

        local g = Main:Group("Demo", "Left")
        g:SubTabs({ "A", "B" })
        g:Toggle("Enabled", "DemoOn", false, nil, Color3.fromRGB(255, 255, 255))
        g:Slider("Value", "DemoVal", 0, 100, 50)
        g:ColorPicker("Color", "DemoColor", Color3.fromRGB(255, 255, 255))
        g:Dropdown("Mode", "DemoMode", { "One", "Two", "Three" }, "One")
        g:Keybind("Key", "DemoKey", Enum.KeyCode.Q)
        g:Button("Button")
        g:ButtonAccent("Accent Button")

        local r = Main:Group("Right", "Right")
        r:Label("Fully customizable lib")
        r:Textbox("Name", "DemoName", "player")
        print("[Lib] demo ready")
    end)
    if not ok then warn("[Lib]", err) end
end)
