--[[
================================================================================
  SprayUI v1.2  —  fracture-style UI library for Roblox scripts
  Sharp edges · logo · resize · themes · configs · flags · subtabs

  local UI = loadstring(...)()  -- or getgenv().SprayUI
  local Win = UI:Window({ Title = "Script", Width = 540, Height = 400 })
================================================================================
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local SprayUI = {
    Version = "1.2.0",
    Flags = {},
    _connections = {},
    _themeListeners = {},
    _windows = {},
    Folder = "SprayUI",
    ConfigFolder = "SprayUI/Configs",
}

-- ===================== THEME =====================
local Theme = {
    Background   = Color3.fromRGB(16, 16, 16),
    Panel        = Color3.fromRGB(20, 20, 20),
    PanelInner   = Color3.fromRGB(26, 26, 26),
    Stroke       = Color3.fromRGB(38, 38, 38),
    StrokeLight  = Color3.fromRGB(52, 52, 52),
    Text         = Color3.fromRGB(205, 205, 205),
    TextDim      = Color3.fromRGB(130, 130, 130),
    Accent       = Color3.fromRGB(160, 90, 255),
    AccentDim    = Color3.fromRGB(100, 55, 165),
    ToggleOn     = Color3.fromRGB(160, 90, 255),
    ToggleOff    = Color3.fromRGB(42, 42, 42),
    SliderBg     = Color3.fromRGB(32, 32, 32),
    TabIdle      = Color3.fromRGB(24, 24, 24),
    TabActive    = Color3.fromRGB(34, 34, 34),
    Font         = Enum.Font.Code,
    FontSize     = 13,
    TitleSize    = 13,
}

local ThemeDefaults = {}
for k, v in pairs(Theme) do ThemeDefaults[k] = v end

local Presets = {
    Purple = {
        Accent = Color3.fromRGB(160, 90, 255),
        AccentDim = Color3.fromRGB(100, 55, 165),
        ToggleOn = Color3.fromRGB(160, 90, 255),
    },
    Blue = {
        Accent = Color3.fromRGB(70, 140, 255),
        AccentDim = Color3.fromRGB(40, 90, 180),
        ToggleOn = Color3.fromRGB(70, 140, 255),
    },
    Red = {
        Accent = Color3.fromRGB(230, 70, 70),
        AccentDim = Color3.fromRGB(150, 40, 40),
        ToggleOn = Color3.fromRGB(230, 70, 70),
    },
    Green = {
        Accent = Color3.fromRGB(90, 200, 110),
        AccentDim = Color3.fromRGB(50, 130, 70),
        ToggleOn = Color3.fromRGB(90, 200, 110),
    },
    Orange = {
        Accent = Color3.fromRGB(255, 160, 50),
        AccentDim = Color3.fromRGB(180, 100, 30),
        ToggleOn = Color3.fromRGB(255, 160, 50),
    },
    White = {
        Accent = Color3.fromRGB(220, 220, 220),
        AccentDim = Color3.fromRGB(140, 140, 140),
        ToggleOn = Color3.fromRGB(220, 220, 220),
    },
    Pink = {
        Accent = Color3.fromRGB(255, 100, 180),
        AccentDim = Color3.fromRGB(170, 50, 120),
        ToggleOn = Color3.fromRGB(255, 100, 180),
    },
}

local function parent_gui(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
    local ok = pcall(function()
        gui.Parent = (gethui and gethui()) or CoreGui
    end)
    if not ok then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
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
    table.insert(SprayUI._connections, c)
    return c
end

local function ensure_folders()
    pcall(function()
        if not isfolder then return end
        if not isfolder(SprayUI.Folder) then makefolder(SprayUI.Folder) end
        if not isfolder(SprayUI.ConfigFolder) then makefolder(SprayUI.ConfigFolder) end
    end)
end

-- theme bind: objects recolored on Theme update
local function theme_bind(inst, prop, key)
    table.insert(SprayUI._themeListeners, { inst = inst, prop = prop, key = key })
end

local function apply_theme_to_listeners()
    for _, e in ipairs(SprayUI._themeListeners) do
        if e.inst and e.inst.Parent then
            pcall(function()
                e.inst[e.prop] = Theme[e.key]
            end)
        end
    end
end

function SprayUI:GetTheme()
    local t = {}
    for k, v in pairs(Theme) do
        if typeof(v) == "Color3" then
            t[k] = { v.R, v.G, v.B }
        elseif typeof(v) ~= "EnumItem" then
            t[k] = v
        end
    end
    return t
end

function SprayUI:SetThemeKey(key, value)
    if Theme[key] ~= nil and typeof(value) == typeof(Theme[key]) then
        Theme[key] = value
        if key == "Accent" then
            Theme.ToggleOn = value
            Theme.AccentDim = Color3.new(
                math.max(value.R - 0.2, 0),
                math.max(value.G - 0.2, 0),
                math.max(value.B - 0.2, 0)
            )
        end
        apply_theme_to_listeners()
    end
end

function SprayUI:SetAccent(c)
    SprayUI:SetThemeKey("Accent", c)
end

function SprayUI:ApplyPreset(name)
    local p = Presets[name]
    if not p then return false end
    for k, v in pairs(p) do
        Theme[k] = v
    end
    apply_theme_to_listeners()
    return true
end

function SprayUI:ListPresets()
    local n = {}
    for k in pairs(Presets) do table.insert(n, k) end
    table.sort(n)
    return n
end

function SprayUI:ResetTheme()
    for k, v in pairs(ThemeDefaults) do Theme[k] = v end
    apply_theme_to_listeners()
end

-- ===================== FLAGS / CONFIG =====================
function SprayUI:Get(flag)
    return SprayUI.Flags[flag]
end

function SprayUI:Set(flag, value)
    SprayUI.Flags[flag] = value
end

function SprayUI:GetConfig()
    local cfg = { Flags = {}, Theme = SprayUI:GetTheme(), Version = SprayUI.Version }
    for k, v in pairs(SprayUI.Flags) do
        if typeof(v) == "Color3" then
            cfg.Flags[k] = { __color = true, v.R, v.G, v.B }
        elseif typeof(v) == "EnumItem" then
            cfg.Flags[k] = { __enum = true, tostring(v) }
        else
            cfg.Flags[k] = v
        end
    end
    return HttpService:JSONEncode(cfg)
end

function SprayUI:LoadConfig(json)
    local ok, cfg = pcall(HttpService.JSONDecode, HttpService, json)
    if not ok or type(cfg) ~= "table" then return false end
    if cfg.Theme then
        for k, v in pairs(cfg.Theme) do
            if type(v) == "table" and #v == 3 and Theme[k] and typeof(Theme[k]) == "Color3" then
                Theme[k] = Color3.new(v[1], v[2], v[3])
            end
        end
        apply_theme_to_listeners()
    end
    if cfg.Flags then
        for k, v in pairs(cfg.Flags) do
            if type(v) == "table" and v.__color then
                SprayUI.Flags[k] = Color3.new(v[1], v[2], v[3])
            else
                SprayUI.Flags[k] = v
            end
        end
    end
    -- notify windows to refresh control visuals
    for _, win in ipairs(SprayUI._windows) do
        if win._refreshFlags then win:_refreshFlags() end
    end
    return true
end

function SprayUI:SaveConfig(name)
    ensure_folders()
    name = tostring(name or "default"):gsub("[^%w%-%_]", "")
    if name == "" then name = "default" end
    local path = SprayUI.ConfigFolder .. "/" .. name .. ".json"
    local ok = pcall(function()
        writefile(path, SprayUI:GetConfig())
    end)
    return ok, path
end

function SprayUI:LoadConfigFile(name)
    ensure_folders()
    name = tostring(name or "default"):gsub("[^%w%-%_]", "")
    local path = SprayUI.ConfigFolder .. "/" .. name .. ".json"
    local ok, data = pcall(function()
        return readfile(path)
    end)
    if not ok or not data then return false end
    return SprayUI:LoadConfig(data)
end

function SprayUI:ListConfigs()
    ensure_folders()
    local list = {}
    pcall(function()
        if not listfiles then return end
        for _, f in ipairs(listfiles(SprayUI.ConfigFolder)) do
            local n = f:gsub("\\", "/"):match("([^/]+)%.json$")
            if n then table.insert(list, n) end
        end
    end)
    table.sort(list)
    return list
end

function SprayUI:DeleteConfig(name)
    name = tostring(name or ""):gsub("[^%w%-%_]", "")
    if name == "" then return false end
    local path = SprayUI.ConfigFolder .. "/" .. name .. ".json"
    local ok = pcall(function()
        if isfile and isfile(path) then delfile(path) end
    end)
    return ok
end

-- ===================== WINDOW =====================
function SprayUI:Window(opts)
    opts = opts or {}
    local title = opts.Title or "Spray"
    local watermarkText = opts.Watermark or title
    local logoImage = opts.Logo
    local width = math.clamp(opts.Width or 520, 320, 1200)
    local height = math.clamp(opts.Height or 380, 240, 900)
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    if opts.Accent then SprayUI:SetAccent(opts.Accent) end
    if opts.Preset then SprayUI:ApplyPreset(opts.Preset) end
    ensure_folders()

    local gui = Instance.new("ScreenGui")
    gui.Name = "SprayUI_" .. tostring(math.random(1000, 9999))
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    parent_gui(gui)

    -- watermark
    local wm = Instance.new("Frame")
    wm.BackgroundColor3 = Theme.Background
    wm.BorderSizePixel = 0
    wm.Position = UDim2.fromOffset(10, 10)
    wm.Size = UDim2.fromOffset(180, 22)
    wm.Parent = gui
    local wmStroke = stroke(wm, Theme.Stroke, 1)
    theme_bind(wm, "BackgroundColor3", "Background")
    theme_bind(wmStroke, "Color", "Stroke")

    local wmLogo = Instance.new("ImageLabel")
    wmLogo.BackgroundTransparency = 1
    wmLogo.Size = UDim2.fromOffset(14, 14)
    wmLogo.Position = UDim2.fromOffset(4, 4)
    wmLogo.ScaleType = Enum.ScaleType.Fit
    wmLogo.Visible = logoImage ~= nil and logoImage ~= ""
    if logoImage then wmLogo.Image = logoImage end
    wmLogo.Parent = wm

    local wmText = Instance.new("TextLabel")
    wmText.BackgroundTransparency = 1
    wmText.Position = UDim2.fromOffset(logoImage and 22 or 8, 0)
    wmText.Size = UDim2.new(1, logoImage and -26 or -12, 1, 0)
    wmText.Font = Theme.Font
    wmText.TextSize = 12
    wmText.TextColor3 = Theme.Text
    wmText.TextXAlignment = Enum.TextXAlignment.Left
    wmText.Text = watermarkText
    wmText.Parent = wm
    theme_bind(wmText, "TextColor3", "Text")

    local function refreshWatermark()
        local bounds = TextService:GetTextSize(wmText.Text, 12, Theme.Font, Vector2.new(4000, 22))
        local extra = (wmLogo.Visible and 22 or 8) + 10
        wm.Size = UDim2.fromOffset(math.max(100, bounds.X + extra), 22)
    end
    refreshWatermark()

    -- window
    local win = Instance.new("Frame")
    win.Size = UDim2.fromOffset(width, height)
    win.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    win.BackgroundColor3 = Theme.Background
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    local winStroke = stroke(win, Theme.StrokeLight, 1)
    theme_bind(win, "BackgroundColor3", "Background")
    theme_bind(winStroke, "Color", "StrokeLight")

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 26)
    titleBar.BackgroundColor3 = Theme.Panel
    titleBar.BorderSizePixel = 0
    titleBar.Parent = win
    theme_bind(titleBar, "BackgroundColor3", "Panel")

    local titleLogo = Instance.new("ImageLabel")
    titleLogo.BackgroundTransparency = 1
    titleLogo.Size = UDim2.fromOffset(16, 16)
    titleLogo.Position = UDim2.fromOffset(6, 5)
    titleLogo.ScaleType = Enum.ScaleType.Fit
    titleLogo.Visible = logoImage ~= nil and logoImage ~= ""
    if logoImage then titleLogo.Image = logoImage end
    titleLogo.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(logoImage and 26 or 8, 0)
    titleLabel.Size = UDim2.new(1, -90, 1, 0)
    titleLabel.Font = Theme.Font
    titleLabel.TextSize = Theme.TitleSize
    titleLabel.TextColor3 = Theme.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = title
    titleLabel.Parent = titleBar
    theme_bind(titleLabel, "TextColor3", "Text")

    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.AnchorPoint = Vector2.new(1, 0)
    sizeLabel.Position = UDim2.new(1, -8, 0, 0)
    sizeLabel.Size = UDim2.fromOffset(70, 26)
    sizeLabel.Font = Theme.Font
    sizeLabel.TextSize = 11
    sizeLabel.TextColor3 = Theme.TextDim
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Right
    sizeLabel.Text = string.format("%dx%d", width, height)
    sizeLabel.Parent = titleBar
    theme_bind(sizeLabel, "TextColor3", "TextDim")

    -- drag
    do
        local dragging, origin, originPos
        connect(titleBar.InputBegan, function(input)
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
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = input.Position - origin
            win.Position = UDim2.new(originPos.X.Scale, originPos.X.Offset + d.X, originPos.Y.Scale, originPos.Y.Offset + d.Y)
        end)
    end

    -- resize
    local resize = Instance.new("TextButton")
    resize.Size = UDim2.fromOffset(14, 14)
    resize.Position = UDim2.new(1, -14, 1, -14)
    resize.BackgroundColor3 = Theme.PanelInner
    resize.BorderSizePixel = 0
    resize.Text = ""
    resize.AutoButtonColor = false
    resize.ZIndex = 20
    resize.Parent = win
    stroke(resize, Theme.StrokeLight, 1)
    theme_bind(resize, "BackgroundColor3", "PanelInner")

    do
        local resizing, start, startSize
        connect(resize.InputBegan, function(input)
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
            if not resizing then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = input.Position - start
            local nw = math.clamp(startSize.X + d.X, 320, 1200)
            local nh = math.clamp(startSize.Y + d.Y, 240, 900)
            win.Size = UDim2.fromOffset(nw, nh)
            sizeLabel.Text = string.format("%dx%d", math.floor(nw), math.floor(nh))
        end)
    end

    local tabStrip = Instance.new("Frame")
    tabStrip.Size = UDim2.new(1, -2, 0, 22)
    tabStrip.Position = UDim2.fromOffset(1, 26)
    tabStrip.BackgroundColor3 = Theme.Panel
    tabStrip.BorderSizePixel = 0
    tabStrip.Parent = win
    theme_bind(tabStrip, "BackgroundColor3", "Panel")
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabStrip

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -8, 1, -54)
    content.Position = UDim2.fromOffset(4, 50)
    content.BackgroundColor3 = Theme.Panel
    content.BorderSizePixel = 0
    content.Parent = win
    stroke(content, Theme.Stroke, 1)
    theme_bind(content, "BackgroundColor3", "Panel")

    local flagRefreshers = {}

    local WindowAPI = {
        Gui = gui,
        Frame = win,
        Tabs = {},
        _active = nil,
        _refreshFlags = function()
            for _, fn in ipairs(flagRefreshers) do pcall(fn) end
        end,
    }

    function WindowAPI:SetVisible(v) win.Visible = v end
    function WindowAPI:Toggle() win.Visible = not win.Visible end

    function WindowAPI:SetWatermark(text)
        wmText.Text = text
        refreshWatermark()
    end

    function WindowAPI:SetLogo(image)
        logoImage = image
        local show = image ~= nil and image ~= ""
        wmLogo.Visible = show
        titleLogo.Visible = show
        if show then
            wmLogo.Image = image
            titleLogo.Image = image
            wmText.Position = UDim2.fromOffset(22, 0)
            titleLabel.Position = UDim2.fromOffset(26, 0)
        else
            wmText.Position = UDim2.fromOffset(8, 0)
            titleLabel.Position = UDim2.fromOffset(8, 0)
        end
        refreshWatermark()
    end

    function WindowAPI:SetSize(w, h)
        w = math.clamp(w or win.AbsoluteSize.X, 320, 1200)
        h = math.clamp(h or win.AbsoluteSize.Y, 240, 900)
        win.Size = UDim2.fromOffset(w, h)
        sizeLabel.Text = string.format("%dx%d", w, h)
    end

    function WindowAPI:GetSize()
        return win.AbsoluteSize.X, win.AbsoluteSize.Y
    end

    connect(UserInputService.InputBegan, function(input, gp)
        if gp then return end
        if input.KeyCode == toggleKey then WindowAPI:Toggle() end
    end)

    function WindowAPI:Tab(name)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.fromOffset(math.max(64, #name * 8 + 16), 22)
        tabBtn.BackgroundColor3 = Theme.TabIdle
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.Font = Theme.Font
        tabBtn.TextSize = Theme.FontSize
        tabBtn.TextColor3 = Theme.TextDim
        tabBtn.Text = name
        tabBtn.Parent = tabStrip
        theme_bind(tabBtn, "BackgroundColor3", "TabIdle")

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
            sf.CanvasSize = UDim2.new(0, 0, 0, 0)
            sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
            sf.Size = UDim2.new(0.5, -6, 1, -8)
            sf.Position = side == "Right" and UDim2.new(0.5, 2, 0, 4) or UDim2.fromOffset(4, 4)
            sf.Parent = page
            theme_bind(sf, "ScrollBarImageColor3", "Accent")
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
            WindowAPI._active = TabAPI
        end
        connect(tabBtn.MouseButton1Click, select)

        function TabAPI:Group(groupName, side)
            local parent = (side == "Right") and rightCol or leftCol
            local box = Instance.new("Frame")
            box.Size = UDim2.new(1, -4, 0, 28)
            box.AutomaticSize = Enum.AutomaticSize.Y
            box.BackgroundColor3 = Theme.PanelInner
            box.BorderSizePixel = 0
            box.Parent = parent
            stroke(box, Theme.Stroke, 1)
            theme_bind(box, "BackgroundColor3", "PanelInner")

            local header = Instance.new("TextLabel")
            header.BackgroundTransparency = 1
            header.Size = UDim2.new(1, -10, 0, 18)
            header.Position = UDim2.fromOffset(6, 2)
            header.Font = Theme.Font
            header.TextSize = 11
            header.TextColor3 = Theme.TextDim
            header.TextXAlignment = Enum.TextXAlignment.Left
            header.Text = groupName
            header.Parent = box
            theme_bind(header, "TextColor3", "TextDim")

            local body = Instance.new("Frame")
            body.Size = UDim2.new(1, -8, 0, 0)
            body.Position = UDim2.fromOffset(4, 20)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.BackgroundTransparency = 1
            body.Parent = box
            Instance.new("UIListLayout", body).Padding = UDim.new(0, 2)
            pad(body, 2, 0, 2, 6)

            local subPages, currentSub = {}, nil
            local GroupAPI = {}

            function GroupAPI:SubTabs(names)
                local subRow = Instance.new("Frame")
                subRow.Size = UDim2.new(1, 0, 0, 18)
                subRow.BackgroundTransparency = 1
                subRow.Parent = body
                local lay = Instance.new("UIListLayout")
                lay.FillDirection = Enum.FillDirection.Horizontal
                lay.Padding = UDim.new(0, 2)
                lay.Parent = subRow
                for i, n in ipairs(names) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.fromOffset(math.max(48, #n * 7 + 12), 16)
                    b.BackgroundColor3 = Theme.TabIdle
                    b.BorderSizePixel = 0
                    b.AutoButtonColor = false
                    b.Font = Theme.Font
                    b.TextSize = 11
                    b.TextColor3 = Theme.TextDim
                    b.Text = n
                    b.Parent = subRow
                    local sp = Instance.new("Frame")
                    sp.Size = UDim2.new(1, 0, 0, 0)
                    sp.AutomaticSize = Enum.AutomaticSize.Y
                    sp.BackgroundTransparency = 1
                    sp.Visible = false
                    sp.Parent = body
                    Instance.new("UIListLayout", sp).Padding = UDim.new(0, 2)
                    subPages[n] = { frame = sp, btn = b }
                    connect(b.MouseButton1Click, function()
                        for _, data in pairs(subPages) do
                            data.frame.Visible = false
                            data.btn.BackgroundColor3 = Theme.TabIdle
                            data.btn.TextColor3 = Theme.TextDim
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
                default = default == true
                if SprayUI.Flags[flag] == nil then SprayUI.Flags[flag] = default end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 18)
                row.BackgroundTransparency = 1
                row.Parent = host()

                local boxBtn = Instance.new("TextButton")
                boxBtn.Size = UDim2.fromOffset(11, 11)
                boxBtn.Position = UDim2.fromOffset(2, 3)
                boxBtn.BackgroundColor3 = SprayUI.Flags[flag] and Theme.ToggleOn or Theme.ToggleOff
                boxBtn.BorderSizePixel = 0
                boxBtn.Text = ""
                boxBtn.AutoButtonColor = false
                boxBtn.Parent = row
                stroke(boxBtn, Theme.StrokeLight, 1)

                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Position = UDim2.fromOffset(17, 0)
                lab.Size = UDim2.new(1, color3 and -40 or -22, 1, 0)
                lab.Font = Theme.Font
                lab.TextSize = Theme.FontSize
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row
                theme_bind(lab, "TextColor3", "Text")

                if color3 then
                    local sw = Instance.new("Frame")
                    sw.Size = UDim2.fromOffset(12, 11)
                    sw.Position = UDim2.new(1, -16, 0, 3)
                    sw.BackgroundColor3 = color3
                    sw.BorderSizePixel = 0
                    sw.Parent = row
                    stroke(sw, Theme.StrokeLight, 1)
                    SprayUI.Flags[flag .. "_Color"] = color3
                end

                local function paint()
                    boxBtn.BackgroundColor3 = SprayUI.Flags[flag] and Theme.ToggleOn or Theme.ToggleOff
                end
                table.insert(flagRefreshers, paint)
                connect(boxBtn.MouseButton1Click, function()
                    SprayUI.Flags[flag] = not SprayUI.Flags[flag]
                    paint()
                    if callback then callback(SprayUI.Flags[flag]) end
                end)
                return {
                    Set = function(_, v)
                        SprayUI.Flags[flag] = not not v
                        paint()
                        if callback then callback(SprayUI.Flags[flag]) end
                    end,
                    Get = function() return SprayUI.Flags[flag] end,
                }
            end

            function GroupAPI:Slider(label, flag, minv, maxv, default, callback)
                minv, maxv = minv or 0, maxv or 100
                default = default or minv
                if SprayUI.Flags[flag] == nil then SprayUI.Flags[flag] = default end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundTransparency = 1
                row.Parent = host()

                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(1, -52, 0, 13)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.Font = Theme.Font
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row
                theme_bind(lab, "TextColor3", "Text")

                local val = Instance.new("TextLabel")
                val.BackgroundTransparency = 1
                val.Size = UDim2.fromOffset(50, 13)
                val.Position = UDim2.new(1, -52, 0, 0)
                val.Font = Theme.Font
                val.TextSize = 12
                val.TextColor3 = Theme.TextDim
                val.TextXAlignment = Enum.TextXAlignment.Right
                val.Parent = row
                theme_bind(val, "TextColor3", "TextDim")

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, -4, 0, 5)
                track.Position = UDim2.fromOffset(2, 17)
                track.BackgroundColor3 = Theme.SliderBg
                track.BorderSizePixel = 0
                track.Parent = row
                theme_bind(track, "BackgroundColor3", "SliderBg")

                local fill = Instance.new("Frame")
                fill.BackgroundColor3 = Theme.Accent
                fill.BorderSizePixel = 0
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.Parent = track
                theme_bind(fill, "BackgroundColor3", "Accent")

                local function apply(v)
                    v = math.clamp(v, minv, maxv)
                    if (maxv - minv) >= 5 then v = math.floor(v + 0.5)
                    else v = math.floor(v * 100 + 0.5) / 100 end
                    SprayUI.Flags[flag] = v
                    fill.Size = UDim2.new((v - minv) / math.max(maxv - minv, 1e-9), 0, 1, 0)
                    val.Text = tostring(v)
                    if callback then callback(v) end
                end
                apply(SprayUI.Flags[flag] or default)
                table.insert(flagRefreshers, function() apply(SprayUI.Flags[flag] or default) end)

                local hold = false
                connect(track.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hold = true
                    end
                end)
                connect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hold = false
                    end
                end)
                connect(UserInputService.InputChanged, function(input)
                    if not hold then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                    apply(minv + pct * (maxv - minv))
                end)
                return { Set = function(_, v) apply(v) end, Get = function() return SprayUI.Flags[flag] end }
            end

            function GroupAPI:Dropdown(label, flag, options, default, callback)
                options = options or { "None" }
                default = default or options[1]
                if SprayUI.Flags[flag] == nil then SprayUI.Flags[flag] = default end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 18)
                row.BackgroundTransparency = 1
                row.ZIndex = 5
                row.Parent = host()

                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(0.38, 0, 1, 0)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.Font = Theme.Font
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.58, 0, 0, 15)
                btn.Position = UDim2.new(0.4, 0, 0, 1)
                btn.BackgroundColor3 = Theme.Panel
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Font = Theme.Font
                btn.TextSize = 11
                btn.TextColor3 = Theme.Text
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Text = " " .. tostring(SprayUI.Flags[flag]) .. "  v"
                btn.ZIndex = 6
                btn.Parent = row
                stroke(btn, Theme.Stroke, 1)
                theme_bind(btn, "BackgroundColor3", "Panel")

                local open, listFrame = false, nil
                connect(btn.MouseButton1Click, function()
                    if open and listFrame then listFrame:Destroy(); listFrame = nil; open = false; return end
                    open = true
                    listFrame = Instance.new("Frame")
                    listFrame.Size = UDim2.new(0.58, 0, 0, math.min(#options * 15, 90))
                    listFrame.Position = UDim2.new(0.4, 0, 0, 16)
                    listFrame.BackgroundColor3 = Theme.Background
                    listFrame.BorderSizePixel = 0
                    listFrame.ZIndex = 40
                    listFrame.Parent = row
                    stroke(listFrame, Theme.StrokeLight, 1)
                    Instance.new("UIListLayout", listFrame)
                    for _, opt in ipairs(options) do
                        local ob = Instance.new("TextButton")
                        ob.Size = UDim2.new(1, 0, 0, 15)
                        ob.BackgroundColor3 = Theme.PanelInner
                        ob.BorderSizePixel = 0
                        ob.AutoButtonColor = false
                        ob.Font = Theme.Font
                        ob.TextSize = 11
                        ob.TextColor3 = Theme.Text
                        ob.TextXAlignment = Enum.TextXAlignment.Left
                        ob.Text = " " .. opt
                        ob.ZIndex = 41
                        ob.Parent = listFrame
                        connect(ob.MouseButton1Click, function()
                            SprayUI.Flags[flag] = opt
                            btn.Text = " " .. opt .. "  v"
                            if callback then callback(opt) end
                            listFrame:Destroy(); listFrame = nil; open = false
                        end)
                    end
                end)
                table.insert(flagRefreshers, function()
                    btn.Text = " " .. tostring(SprayUI.Flags[flag] or default) .. "  v"
                end)
                return { Get = function() return SprayUI.Flags[flag] end }
            end

            function GroupAPI:Button(label, callback)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -4, 0, 18)
                btn.BackgroundColor3 = Theme.Panel
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Font = Theme.Font
                btn.TextSize = Theme.FontSize
                btn.TextColor3 = Theme.Text
                btn.Text = label
                btn.Parent = host()
                stroke(btn, Theme.Stroke, 1)
                theme_bind(btn, "BackgroundColor3", "Panel")
                connect(btn.MouseButton1Click, function() if callback then callback() end end)
                return btn
            end

            function GroupAPI:ButtonAccent(label, callback)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -4, 0, 18)
                btn.BackgroundColor3 = Theme.AccentDim
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Font = Theme.Font
                btn.TextSize = Theme.FontSize
                btn.TextColor3 = Theme.Text
                btn.Text = label
                btn.Parent = host()
                local st = stroke(btn, Theme.Accent, 1)
                theme_bind(btn, "BackgroundColor3", "AccentDim")
                theme_bind(st, "Color", "Accent")
                connect(btn.MouseButton1Click, function() if callback then callback() end end)
                return btn
            end

            function GroupAPI:Label(text)
                local lab = Instance.new("TextLabel")
                lab.Size = UDim2.new(1, 0, 0, 14)
                lab.BackgroundTransparency = 1
                lab.Font = Theme.Font
                lab.TextSize = 11
                lab.TextColor3 = Theme.TextDim
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = text
                lab.Parent = host()
                theme_bind(lab, "TextColor3", "TextDim")
                return lab
            end

            function GroupAPI:Textbox(label, flag, default, callback)
                default = default or ""
                if SprayUI.Flags[flag] == nil then SprayUI.Flags[flag] = default end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 18)
                row.BackgroundTransparency = 1
                row.Parent = host()
                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(0.38, 0, 1, 0)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.Font = Theme.Font
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                lab.Text = label
                lab.Parent = row
                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.58, 0, 0, 15)
                box.Position = UDim2.new(0.4, 0, 0, 1)
                box.BackgroundColor3 = Theme.Panel
                box.BorderSizePixel = 0
                box.Font = Theme.Font
                box.TextSize = 11
                box.TextColor3 = Theme.Text
                box.ClearTextOnFocus = false
                box.Text = tostring(SprayUI.Flags[flag])
                box.Parent = row
                stroke(box, Theme.Stroke, 1)
                connect(box.FocusLost, function()
                    SprayUI.Flags[flag] = box.Text
                    if callback then callback(box.Text) end
                end)
                return box
            end

            return GroupAPI
        end

        WindowAPI.Tabs[name] = TabAPI
        if not WindowAPI._active then select() end
        return TabAPI
    end

    -- built-in Settings helpers for theme + config (optional tab builder)
    function WindowAPI:AddSettingsTab()
        local tab = WindowAPI:Tab("Settings")
        local theme = tab:Group("Theme", "Left")
        theme:Label("Presets")
        for _, name in ipairs(SprayUI:ListPresets()) do
            theme:Button(name, function()
                SprayUI:ApplyPreset(name)
            end)
        end
        theme:Button("Reset theme", function() SprayUI:ResetTheme() end)

        local cfg = tab:Group("Configuration", "Right")
        cfg:Textbox("Config name", "SprayUI_ConfigName", "default")
        cfg:Button("Save config", function()
            local n = SprayUI.Flags["SprayUI_ConfigName"] or "default"
            local ok = SprayUI:SaveConfig(n)
            WindowAPI:SetWatermark(ok and (title .. "  |  saved " .. n) or (title .. "  |  save failed"))
            task.delay(2, function() WindowAPI:SetWatermark(watermarkText) end)
        end)
        cfg:Button("Load config", function()
            local n = SprayUI.Flags["SprayUI_ConfigName"] or "default"
            local ok = SprayUI:LoadConfigFile(n)
            WindowAPI:SetWatermark(ok and (title .. "  |  loaded " .. n) or (title .. "  |  load failed"))
            task.delay(2, function() WindowAPI:SetWatermark(watermarkText) end)
        end)
        cfg:Button("Delete config", function()
            local n = SprayUI.Flags["SprayUI_ConfigName"] or "default"
            SprayUI:DeleteConfig(n)
        end)
        cfg:ButtonAccent("Unload UI", function() WindowAPI:Unload() end)
        cfg:Label("Folder: " .. SprayUI.ConfigFolder)
        return tab
    end

    function WindowAPI:Unload()
        for i, w in ipairs(SprayUI._windows) do
            if w == WindowAPI then table.remove(SprayUI._windows, i) break end
        end
        for _, c in ipairs(SprayUI._connections) do pcall(function() c:Disconnect() end) end
        -- don't clear all connections if multiple windows — simple: destroy this gui
        pcall(function() gui:Destroy() end)
    end

    table.insert(SprayUI._windows, WindowAPI)
    return WindowAPI
end

getgenv().SprayUI = SprayUI
return SprayUI


-- ===== example =====

--[[ SprayUI v1.2 example hub ]]
local SprayUI = getgenv().SprayUI
if not SprayUI then error("SprayUI not loaded") end

local Win = SprayUI:Window({
    Title = "Spray",
    Watermark = "Spray  |  v1.2",
    Logo = "", -- set getcustomasset("logo.png") or rbxassetid
    Width = 560,
    Height = 420,
    ToggleKey = Enum.KeyCode.RightShift,
    Preset = "Purple",
})

local Main = Win:Tab("Main")
local Visuals = Win:Tab("Visuals")
local Misc = Win:Tab("Misc")
Win:AddSettingsTab() -- theme + config built-in

do
    local g = Main:Group("Combat", "Left")
    g:SubTabs({ "Silent", "Aimbot", "Trigger" })
    g:Toggle("Enabled", "SilentEnabled", false, nil, Color3.fromRGB(255, 200, 0))
    g:Toggle("Visualize FOV", "SilentVis", false)
    g:Slider("Radius", "SilentRadius", 20, 400, 100)
    g:Slider("Hit Chance", "SilentHC", 1, 100, 100)
    g:Dropdown("Part", "SilentPart", { "Head", "HumanoidRootPart", "UpperTorso" }, "Head")

    local r = Main:Group("Rage", "Right")
    r:Toggle("Enabled", "RageEnabled", false)
    r:Toggle("Void Spam", "VoidSpam", false)
    r:Slider("Hide", "VoidHide", 0.05, 2, 0.25)
    r:Slider("Attack", "VoidAtk", 0.01, 1, 0.1)
    r:ButtonAccent("Panic Off", function()
        SprayUI.Flags.SilentEnabled = false
        SprayUI.Flags.RageEnabled = false
        Win:_refreshFlags()
    end)
end

do
    local esp = Visuals:Group("ESP", "Left")
    esp:SubTabs({ "Enemy", "Team", "Local" })
    esp:Toggle("Enabled", "EspEnabled", false)
    esp:Toggle("Box", "EspBox", false, nil, Color3.fromRGB(255, 200, 80))
    esp:Toggle("Name", "EspName", false, nil, Color3.fromRGB(255, 255, 255))
    esp:Toggle("Distance", "EspDist", false)
    esp:Toggle("Health Bar", "EspHP", false)
    esp:Toggle("Chams", "EspChams", false, nil, Color3.fromRGB(100, 140, 255))
    esp:Dropdown("Anchor", "EspAnchor", { "Top", "Center", "Bottom" }, "Top")
    esp:Toggle("Tracers", "EspTracers", false)
    esp:Slider("Render Distance", "EspMax", 100, 2500, 1000)

    local cam = Visuals:Group("Camera", "Right")
    cam:Toggle("FOV Changer", "FovOn", false)
    cam:Slider("FOV", "FovVal", 50, 120, 80)
    cam:Button("Reset")
    cam:ButtonAccent("Apply")
end

do
    local m = Misc:Group("General", "Left")
    m:Toggle("Hit Notify", "HitNotify", true)
    m:Textbox("Notify format", "NotifyFmt", "Hit {NAME}")
    m:Dropdown("Queue", "QueueMode", { "1v1", "2v2", "Casual" }, "1v1")
end

print("[SprayUI]", SprayUI.Version, "example ready — RightShift")
