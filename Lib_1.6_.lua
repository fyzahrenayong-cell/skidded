--[[
  Lib 1.6
  Fracture-style UI library — hardened load
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Lib = {
    Version = "1.6.0",
    Flags = {},
    _connections = {},
    _windows = {},
    Folder = "Lib16",
    ConfigFolder = "Lib16/Configs",
    Locked = false,
}

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

local Presets = {
    White  = { Accent = Color3.fromRGB(255,255,255), ToggleOn = Color3.fromRGB(255,255,255), Stroke = Color3.fromRGB(230,230,230) },
    Purple = { Accent = Color3.fromRGB(180,100,255), ToggleOn = Color3.fromRGB(180,100,255), Stroke = Color3.fromRGB(180,100,255) },
    Blue   = { Accent = Color3.fromRGB(90,150,255), ToggleOn = Color3.fromRGB(90,150,255), Stroke = Color3.fromRGB(90,150,255) },
    Red    = { Accent = Color3.fromRGB(255,80,80), ToggleOn = Color3.fromRGB(255,80,80), Stroke = Color3.fromRGB(255,80,80) },
    Green  = { Accent = Color3.fromRGB(90,220,120), ToggleOn = Color3.fromRGB(90,220,120), Stroke = Color3.fromRGB(90,220,120) },
}

local function parent_gui(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
    local ok = pcall(function()
        gui.Parent = (gethui and gethui()) or CoreGui
    end)
    if not ok then
        pcall(function()
            gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end)
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
    table.insert(Lib._connections, c)
    return c
end

local function set_font(obj)
    -- avoid FontFace/getcustomasset crash on weak executors
    pcall(function()
        obj.Font = Enum.Font.Code
    end)
end

local function ensure_folders()
    pcall(function()
        if not isfolder then return end
        if not isfolder(Lib.Folder) then makefolder(Lib.Folder) end
        if not isfolder(Lib.ConfigFolder) then makefolder(Lib.ConfigFolder) end
    end)
end

function Lib:SetAccent(c)
    Theme.Accent = c
    Theme.ToggleOn = c
    Theme.Stroke = c
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

function Lib:SetTheme(tbl)
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do
        if Theme[k] ~= nil and typeof(v) == typeof(Theme[k]) then
            Theme[k] = v
        end
    end
end

function Lib:Get(f) return Lib.Flags[f] end
function Lib:Set(f, v) Lib.Flags[f] = v end

function Lib:GetConfig()
    local cfg = { Flags = {}, Version = Lib.Version }
    for k, v in pairs(Lib.Flags) do
        if typeof(v) == "Color3" then
            cfg.Flags[k] = { __c = true, v.R, v.G, v.B }
        elseif typeof(v) ~= "Instance" and typeof(v) ~= "function" and typeof(v) ~= "EnumItem" then
            cfg.Flags[k] = v
        elseif typeof(v) == "EnumItem" then
            cfg.Flags[k] = { __e = true, tostring(v) }
        end
    end
    local ok, s = pcall(function() return HttpService:JSONEncode(cfg) end)
    return ok and s or "{}"
end

function Lib:LoadConfig(json)
    local ok, cfg = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(cfg) ~= "table" or not cfg.Flags then return false end
    for k, v in pairs(cfg.Flags) do
        if type(v) == "table" and v.__c then
            Lib.Flags[k] = Color3.new(v[1], v[2], v[3])
        else
            Lib.Flags[k] = v
        end
    end
    for _, win in ipairs(Lib._windows) do
        if win._refreshFlags then pcall(win._refreshFlags) end
    end
    return true
end

function Lib:SaveConfig(name)
    ensure_folders()
    name = tostring(name or "default"):gsub("[^%w%-%_]", "")
    if name == "" then name = "default" end
    local ok = pcall(function()
        writefile(Lib.ConfigFolder .. "/" .. name .. ".json", Lib:GetConfig())
    end)
    return ok
end

function Lib:LoadConfigFile(name)
    ensure_folders()
    name = tostring(name or "default"):gsub("[^%w%-%_]", "")
    local ok, data = pcall(function()
        return readfile(Lib.ConfigFolder .. "/" .. name .. ".json")
    end)
    if not ok or not data then return false end
    return Lib:LoadConfig(data)
end

function Lib:ListConfigs()
    ensure_folders()
    local list = {}
    pcall(function()
        if not listfiles then return end
        for _, f in ipairs(listfiles(Lib.ConfigFolder)) do
            local n = tostring(f):gsub("\\", "/"):match("([^/]+)%.json$")
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

function Lib:Window(opts)
    opts = opts or {}
    local title = opts.Title or "Lib"
    local width = math.clamp(tonumber(opts.Width) or 560, 300, 1400)
    local height = math.clamp(tonumber(opts.Height) or 430, 220, 1000)
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    local logoImage = opts.Logo

    if opts.Preset then Lib:ApplyPreset(opts.Preset) else Lib:ApplyPreset("White") end
    if opts.Accent then Lib:SetAccent(opts.Accent) end
    if opts.Theme then Lib:SetTheme(opts.Theme) end
    ensure_folders()

    local gui = Instance.new("ScreenGui")
    gui.Name = "Lib16"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 200
    parent_gui(gui)

    -- left controls
    local leftStack = Instance.new("Frame")
    leftStack.BackgroundTransparency = 1
    leftStack.Size = UDim2.fromOffset(100, 52)
    leftStack.Position = UDim2.fromOffset(opts.ControlsX or 12, opts.ControlsY or 72)
    leftStack.Visible = opts.ShowQuickControls ~= false
    leftStack.Parent = gui

    local function chip(text, y)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(96, 22)
        b.Position = UDim2.fromOffset(0, y)
        b.BackgroundColor3 = Theme.Background
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Text = text
        b.TextSize = 12
        b.TextColor3 = Theme.Text
        set_font(b)
        b.Parent = leftStack
        stroke(b, Theme.Stroke, 1)
        return b
    end
    local toggleBtn = chip("Toggle UI", 0)
    local lockBtn = chip("Lock UI", 24)

    -- title rect right
    local titleRect = Instance.new("Frame")
    titleRect.BackgroundColor3 = Theme.Background
    titleRect.BorderSizePixel = 0
    titleRect.AnchorPoint = Vector2.new(1, 0)
    titleRect.Position = UDim2.new(1, -16, 0, 72)
    titleRect.Size = UDim2.fromOffset(150, 28)
    titleRect.Visible = opts.ShowTitleRect ~= false
    titleRect.Parent = gui
    stroke(titleRect, Theme.Stroke, 1)

    local titleRectText = Instance.new("TextLabel")
    titleRectText.BackgroundTransparency = 1
    titleRectText.Size = UDim2.fromScale(1, 1)
    titleRectText.Position = UDim2.fromOffset(10, 0)
    titleRectText.Text = title
    titleRectText.TextSize = 13
    titleRectText.TextColor3 = Theme.Text
    titleRectText.TextXAlignment = Enum.TextXAlignment.Left
    set_font(titleRectText)
    titleRectText.Parent = titleRect

    if logoImage and logoImage ~= "" then
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Size = UDim2.fromOffset(16, 16)
        img.Position = UDim2.fromOffset(6, 6)
        img.Image = logoImage
        img.Parent = titleRect
        titleRectText.Position = UDim2.fromOffset(26, 0)
    end

    -- main window
    local win = Instance.new("Frame")
    win.Size = UDim2.fromOffset(width, height)
    win.Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
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
    headerTitle.Text = title
    headerTitle.TextSize = 14
    headerTitle.TextColor3 = Theme.Text
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    set_font(headerTitle)
    headerTitle.Parent = header

    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.AnchorPoint = Vector2.new(1, 0)
    sizeLabel.Position = UDim2.new(1, -12, 0, 0)
    sizeLabel.Size = UDim2.fromOffset(80, 30)
    sizeLabel.Text = string.format("%d x %d", width, height)
    sizeLabel.TextSize = 11
    sizeLabel.TextColor3 = Theme.TextDim
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Right
    set_font(sizeLabel)
    sizeLabel.Parent = header

    -- drag
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

    -- resize
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

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -64)
    content.Position = UDim2.fromOffset(5, 60)
    content.BackgroundColor3 = Theme.Panel
    content.BorderSizePixel = 0
    content.Parent = win
    stroke(content, Theme.StrokeDim, 1)

    local flagRefreshers = {}
    local WindowAPI = {
        Gui = gui,
        Frame = win,
        Tabs = {},
        _refreshFlags = function()
            for _, fn in ipairs(flagRefreshers) do pcall(fn) end
        end,
    }

    function WindowAPI:SetVisible(v) win.Visible = v end
    function WindowAPI:Toggle()
        if Lib.Locked and win.Visible then return end
        win.Visible = not win.Visible
    end
    function WindowAPI:SetTitle(t)
        headerTitle.Text = t
        titleRectText.Text = t
    end
    function WindowAPI:SetSize(w, h)
        w = math.clamp(w or 560, 300, 1400)
        h = math.clamp(h or 430, 220, 1000)
        win.Size = UDim2.fromOffset(w, h)
        sizeLabel.Text = string.format("%d x %d", w, h)
    end
    function WindowAPI:SetLogo(image)
        -- simple: recreate text offset if needed
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
        tabBtn.Size = UDim2.fromOffset(math.max(72, #tostring(name) * 8 + 20), 26)
        tabBtn.BackgroundColor3 = Theme.TabIdle
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.Text = tostring(name)
        tabBtn.TextSize = 13
        tabBtn.TextColor3 = Theme.TextDim
        set_font(tabBtn)
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
            sf.CanvasSize = UDim2.new(0, 0, 0, 0)
            sf.Size = UDim2.new(0.5, -6, 1, -8)
            sf.Position = side == "Right" and UDim2.new(0.5, 2, 0, 4) or UDim2.fromOffset(4, 4)
            sf.Parent = page
            local lay = Instance.new("UIListLayout")
            lay.Padding = UDim.new(0, 6)
            lay.Parent = sf
            return sf
        end
        local leftCol = makeCol("Left")
        local rightCol = makeCol("Right")
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
            local parent = (side == "Right") and rightCol or leftCol
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
            gHeader.Text = tostring(groupName)
            gHeader.TextSize = 12
            gHeader.TextColor3 = Theme.Text
            gHeader.TextXAlignment = Enum.TextXAlignment.Left
            set_font(gHeader)
            gHeader.Parent = box

            local body = Instance.new("Frame")
            body.Size = UDim2.new(1, -10, 0, 0)
            body.Position = UDim2.fromOffset(5, 22)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.BackgroundTransparency = 1
            body.Parent = box
            local bodyLay = Instance.new("UIListLayout")
            bodyLay.Padding = UDim.new(0, 3)
            bodyLay.Parent = body
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
                    b.Size = UDim2.fromOffset(math.max(52, #tostring(n) * 7 + 14), 16)
                    b.BackgroundColor3 = Theme.TabIdle
                    b.BorderSizePixel = 0
                    b.AutoButtonColor = false
                    b.Text = tostring(n)
                    b.TextSize = 11
                    b.TextColor3 = Theme.TextDim
                    set_font(b)
                    b.Parent = subRow
                    stroke(b, Theme.StrokeDim, 1)

                    local sp = Instance.new("Frame")
                    sp.Size = UDim2.new(1, 0, 0, 0)
                    sp.AutomaticSize = Enum.AutomaticSize.Y
                    sp.BackgroundTransparency = 1
                    sp.Visible = false
                    sp.Parent = body
                    local spl = Instance.new("UIListLayout")
                    spl.Padding = UDim.new(0, 2)
                    spl.Parent = sp
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
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = (default == true) end
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
                lab.Text = tostring(label)
                lab.TextSize = 13
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                set_font(lab)
                lab.Parent = row

                if color3 then
                    local sw = Instance.new("Frame")
                    sw.Size = UDim2.fromOffset(12, 11)
                    sw.Position = UDim2.new(1, -16, 0, 3)
                    sw.BackgroundColor3 = color3
                    sw.BorderSizePixel = 0
                    sw.Parent = row
                    stroke(sw, Theme.Stroke, 1)
                end

                local function paint()
                    boxBtn.BackgroundColor3 = Lib.Flags[flag] and Theme.ToggleOn or Theme.ToggleOff
                end
                table.insert(flagRefreshers, paint)
                connect(boxBtn.MouseButton1Click, function()
                    Lib.Flags[flag] = not Lib.Flags[flag]
                    paint()
                    if callback then pcall(callback, Lib.Flags[flag]) end
                end)
                return {
                    Set = function(_, v) Lib.Flags[flag] = not not v; paint() end,
                    Get = function() return Lib.Flags[flag] end,
                }
            end

            function GroupAPI:Slider(label, flag, minv, maxv, default, callback)
                minv = minv or 0
                maxv = maxv or 100
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = default or minv end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundTransparency = 1
                row.Parent = host()

                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(1, -52, 0, 13)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.Text = tostring(label)
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                set_font(lab)
                lab.Parent = row

                local val = Instance.new("TextLabel")
                val.BackgroundTransparency = 1
                val.Size = UDim2.fromOffset(50, 13)
                val.Position = UDim2.new(1, -52, 0, 0)
                val.TextSize = 12
                val.TextColor3 = Theme.TextDim
                val.TextXAlignment = Enum.TextXAlignment.Right
                set_font(val)
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
                    if (maxv - minv) >= 5 then
                        v = math.floor(v + 0.5)
                    else
                        v = math.floor(v * 100 + 0.5) / 100
                    end
                    Lib.Flags[flag] = v
                    fill.Size = UDim2.new((v - minv) / math.max(maxv - minv, 1e-9), 0, 1, 0)
                    val.Text = tostring(v)
                    if callback then pcall(callback, v) end
                end
                apply(Lib.Flags[flag])
                table.insert(flagRefreshers, function() apply(Lib.Flags[flag]) end)

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
                return { Set = function(_, v) apply(v) end, Get = function() return Lib.Flags[flag] end }
            end

            function GroupAPI:ColorPicker(label, flag, default, callback)
                default = default or Color3.new(1, 1, 1)
                if Lib.Flags[flag] == nil or typeof(Lib.Flags[flag]) ~= "Color3" then
                    Lib.Flags[flag] = default
                end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 18)
                row.BackgroundTransparency = 1
                row.Parent = host()

                local lab = Instance.new("TextLabel")
                lab.BackgroundTransparency = 1
                lab.Size = UDim2.new(1, -40, 1, 0)
                lab.Position = UDim2.fromOffset(2, 0)
                lab.Text = tostring(label)
                lab.TextSize = 13
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                set_font(lab)
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
                    if panel then pcall(function() panel:Destroy() end) panel = nil end
                    open = false
                end
                local function setColor(c)
                    Lib.Flags[flag] = c
                    sw.BackgroundColor3 = c
                    if callback then pcall(callback, c) end
                end

                connect(sw.MouseButton1Click, function()
                    if open then close() return end
                    open = true
                    panel = Instance.new("Frame")
                    panel.Size = UDim2.fromOffset(150, 78)
                    panel.Position = UDim2.new(1, -150, 0, 18)
                    panel.BackgroundColor3 = Theme.Background
                    panel.BorderSizePixel = 0
                    panel.ZIndex = 50
                    panel.Parent = row
                    stroke(panel, Theme.Stroke, 1)

                    local function channel(name, y, getv)
                        local l = Instance.new("TextLabel")
                        l.BackgroundTransparency = 1
                        l.Size = UDim2.fromOffset(14, 14)
                        l.Position = UDim2.fromOffset(6, y)
                        l.Text = name
                        l.TextSize = 11
                        l.TextColor3 = Theme.TextDim
                        l.ZIndex = 51
                        set_font(l)
                        l.Parent = panel

                        local track = Instance.new("Frame")
                        track.Size = UDim2.fromOffset(100, 5)
                        track.Position = UDim2.fromOffset(24, y + 4)
                        track.BackgroundColor3 = Theme.SliderBg
                        track.BorderSizePixel = 0
                        track.ZIndex = 51
                        track.Parent = panel

                        local fill = Instance.new("Frame")
                        fill.BackgroundColor3 = Theme.Accent
                        fill.BorderSizePixel = 0
                        fill.Size = UDim2.new(getv(), 0, 1, 0)
                        fill.ZIndex = 52
                        fill.Parent = track

                        local hold = false
                        local function apply(pct)
                            pct = math.clamp(pct, 0, 1)
                            fill.Size = UDim2.new(pct, 0, 1, 0)
                            local c = Lib.Flags[flag]
                            local r, g, b = c.R, c.G, c.B
                            if name == "R" then r = pct elseif name == "G" then g = pct else b = pct end
                            setColor(Color3.new(r, g, b))
                        end
                        connect(track.InputBegan, function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                hold = true
                                apply((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1))
                            end
                        end)
                        connect(UserInputService.InputEnded, function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                hold = false
                            end
                        end)
                        connect(UserInputService.InputChanged, function(input)
                            if not hold or not panel then return end
                            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
                            apply((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1))
                        end)
                    end

                    local c0 = Lib.Flags[flag]
                    channel("R", 8, function() return c0.R end)
                    channel("G", 28, function() return c0.G end)
                    channel("B", 48, function() return c0.B end)

                    local done = Instance.new("TextButton")
                    done.Size = UDim2.fromOffset(40, 14)
                    done.Position = UDim2.fromOffset(104, 60)
                    done.BackgroundColor3 = Theme.PanelInner
                    done.BorderSizePixel = 0
                    done.Text = "OK"
                    done.TextSize = 10
                    done.TextColor3 = Theme.Text
                    done.ZIndex = 53
                    set_font(done)
                    done.Parent = panel
                    stroke(done, Theme.Stroke, 1)
                    connect(done.MouseButton1Click, close)
                end)

                table.insert(flagRefreshers, function()
                    if typeof(Lib.Flags[flag]) == "Color3" then sw.BackgroundColor3 = Lib.Flags[flag] end
                end)
                return { Set = function(_, c) if typeof(c) == "Color3" then setColor(c) end end, Get = function() return Lib.Flags[flag] end }
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
                lab.Text = tostring(label)
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                set_font(lab)
                lab.Parent = row

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.58, 0, 0, 15)
                btn.Position = UDim2.new(0.4, 0, 0, 1)
                btn.BackgroundColor3 = Theme.Background
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Text = " " .. tostring(Lib.Flags[flag])
                btn.TextSize = 11
                btn.TextColor3 = Theme.Text
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 6
                set_font(btn)
                btn.Parent = row
                stroke(btn, Theme.Stroke, 1)

                local open, listFrame = false, nil
                connect(btn.MouseButton1Click, function()
                    if open and listFrame then
                        listFrame:Destroy()
                        listFrame = nil
                        open = false
                        return
                    end
                    open = true
                    listFrame = Instance.new("Frame")
                    listFrame.Size = UDim2.new(0.58, 0, 0, math.min(#options * 16, 96))
                    listFrame.Position = UDim2.new(0.4, 0, 0, 16)
                    listFrame.BackgroundColor3 = Theme.Background
                    listFrame.BorderSizePixel = 0
                    listFrame.ZIndex = 40
                    listFrame.Parent = row
                    stroke(listFrame, Theme.Stroke, 1)
                    local ll = Instance.new("UIListLayout")
                    ll.Parent = listFrame
                    for _, opt in ipairs(options) do
                        local ob = Instance.new("TextButton")
                        ob.Size = UDim2.new(1, 0, 0, 16)
                        ob.BackgroundColor3 = Theme.PanelInner
                        ob.BorderSizePixel = 0
                        ob.AutoButtonColor = false
                        ob.Text = " " .. tostring(opt)
                        ob.TextSize = 11
                        ob.TextColor3 = Theme.Text
                        ob.TextXAlignment = Enum.TextXAlignment.Left
                        ob.ZIndex = 41
                        set_font(ob)
                        ob.Parent = listFrame
                        connect(ob.MouseButton1Click, function()
                            Lib.Flags[flag] = opt
                            btn.Text = " " .. tostring(opt)
                            if callback then pcall(callback, opt) end
                            listFrame:Destroy()
                            listFrame = nil
                            open = false
                        end)
                    end
                end)
                table.insert(flagRefreshers, function()
                    btn.Text = " " .. tostring(Lib.Flags[flag])
                end)
                return { Get = function() return Lib.Flags[flag] end }
            end

            function GroupAPI:Button(label, callback)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -4, 0, 20)
                btn.BackgroundColor3 = Theme.Background
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Text = tostring(label)
                btn.TextSize = 13
                btn.TextColor3 = Theme.Text
                set_font(btn)
                btn.Parent = host()
                stroke(btn, Theme.Stroke, 1)
                connect(btn.MouseButton1Click, function()
                    if callback then pcall(callback) end
                end)
                return btn
            end

            function GroupAPI:ButtonAccent(label, callback)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -4, 0, 20)
                btn.BackgroundColor3 = Theme.PanelInner
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Text = tostring(label)
                btn.TextSize = 13
                btn.TextColor3 = Theme.Text
                set_font(btn)
                btn.Parent = host()
                stroke(btn, Theme.Stroke, 1)
                connect(btn.MouseButton1Click, function()
                    if callback then pcall(callback) end
                end)
                return btn
            end

            function GroupAPI:Label(text)
                local lab = Instance.new("TextLabel")
                lab.Size = UDim2.new(1, 0, 0, 14)
                lab.BackgroundTransparency = 1
                lab.Text = tostring(text)
                lab.TextSize = 11
                lab.TextColor3 = Theme.TextDim
                lab.TextXAlignment = Enum.TextXAlignment.Left
                set_font(lab)
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
                lab.Text = tostring(label)
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                set_font(lab)
                lab.Parent = row
                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.58, 0, 0, 15)
                box.Position = UDim2.new(0.4, 0, 0, 1)
                box.BackgroundColor3 = Theme.Background
                box.BorderSizePixel = 0
                box.TextSize = 11
                box.TextColor3 = Theme.Text
                box.ClearTextOnFocus = false
                box.Text = tostring(Lib.Flags[flag])
                set_font(box)
                box.Parent = row
                stroke(box, Theme.Stroke, 1)
                connect(box.FocusLost, function()
                    Lib.Flags[flag] = box.Text
                    if callback then pcall(callback, box.Text) end
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
                lab.Text = tostring(label)
                lab.TextSize = 12
                lab.TextColor3 = Theme.Text
                lab.TextXAlignment = Enum.TextXAlignment.Left
                set_font(lab)
                lab.Parent = row
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.45, 0, 0, 15)
                btn.Position = UDim2.new(0.52, 0, 0, 1)
                btn.BackgroundColor3 = Theme.Background
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.TextSize = 11
                btn.TextColor3 = Theme.Text
                set_font(btn)
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
                connect(UserInputService.InputBegan, function(input)
                    if not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        Lib.Flags[flag] = input.KeyCode
                        btn.Text = input.KeyCode.Name
                        listening = false
                        if callback then pcall(callback, input.KeyCode) end
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
        theme:ColorPicker("Accent", "Lib_Accent", Theme.Accent, function(c)
            Lib:SetAccent(c)
        end)

        local cfg = tab:Group("Configuration", "Right")
        cfg:Textbox("Name", "Lib_CfgName", "default")
        local list = Lib:ListConfigs()
        if #list == 0 then list = { "(none)" } end
        cfg:Dropdown("Select", "Lib_CfgPick", list, list[1])
        cfg:Button("Save", function()
            Lib:SaveConfig(Lib.Flags["Lib_CfgName"] or "default")
        end)
        cfg:Button("Load", function()
            local n = Lib.Flags["Lib_CfgPick"]
            if n and n ~= "(none)" then Lib:LoadConfigFile(n) end
        end)
        cfg:Button("Delete", function()
            local n = Lib.Flags["Lib_CfgPick"]
            if n and n ~= "(none)" then Lib:DeleteConfig(n) end
        end)
        cfg:ButtonAccent("Unload", function() WindowAPI:Unload() end)
        return tab
    end

    function WindowAPI:Unload()
        for i, w in ipairs(Lib._windows) do
            if w == WindowAPI then
                table.remove(Lib._windows, i)
                break
            end
        end
        pcall(function() gui:Destroy() end)
    end

    table.insert(Lib._windows, WindowAPI)
    return WindowAPI
end

-- export
local env = rawget(_G, "getgenv") and getgenv() or _G
env.Lib = Lib
env.SprayUI = Lib
print("[Lib] 1.6.0 loaded")
return Lib


-- demo boot (safe)
task.defer(function()
    local env = rawget(_G, "getgenv") and getgenv() or _G
    local Lib = env.Lib
    if not Lib then
        warn("[Lib] not found after load")
        return
    end
    local ok, err = pcall(function()
        local Win = Lib:Window({
            Title = "Lib 1.6",
            Width = 560,
            Height = 430,
            Preset = "White",
        })
        local Main = Win:Tab("Main")
        Win:AddSettingsTab()
        local g = Main:Group("Demo", "Left")
        g:Toggle("Enabled", "DemoOn", false)
        g:Slider("Value", "DemoVal", 0, 100, 50)
        g:ColorPicker("Color", "DemoCol", Color3.fromRGB(255, 255, 255))
        g:Dropdown("Mode", "DemoMode", { "A", "B", "C" }, "A")
        g:Button("Test")
        print("[Lib] window ok")
    end)
    if not ok then
        warn("[Lib] window error: ", err)
    end
end)
