--[[
  Spray | v1.1
  Load-safe UI + skybox picker + modules
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ===== LIB =====
--[[ Lib 1.7 load-safe ]]
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local Lib = { Version = "1.7.0", Flags = {}, Locked = false, _wins = {} }

local Theme = {
    Bg = Color3.fromRGB(12,12,12),
    Panel = Color3.fromRGB(18,18,18),
    Inner = Color3.fromRGB(26,26,26),
    Stroke = Color3.fromRGB(230,230,230),
    Stroke2 = Color3.fromRGB(90,90,90),
    Text = Color3.fromRGB(235,235,235),
    Dim = Color3.fromRGB(150,150,150),
    Accent = Color3.fromRGB(255,255,255),
    On = Color3.fromRGB(255,255,255),
    Off = Color3.fromRGB(40,40,40),
}

local function parent(g)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(g) end end)
    local ok = pcall(function() g.Parent = (gethui and gethui()) or CoreGui end)
    if not ok then pcall(function() g.Parent = LP:WaitForChild("PlayerGui") end) end
end

local function mkStroke(i, c, t)
    local s = Instance.new("UIStroke")
    s.Color = c or Theme.Stroke
    s.Thickness = t or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.LineJoinMode = Enum.LineJoinMode.Miter
    s.Parent = i
    return s
end

local function font(o)
    pcall(function() o.Font = Enum.Font.Code end)
end

function Lib:SetAccent(c)
    Theme.Accent = c
    Theme.On = c
    Theme.Stroke = c
end

function Lib:ApplyPreset(n)
    if n == "Purple" then Lib:SetAccent(Color3.fromRGB(180,100,255))
    elseif n == "Blue" then Lib:SetAccent(Color3.fromRGB(90,150,255))
    elseif n == "Red" then Lib:SetAccent(Color3.fromRGB(255,80,80))
    elseif n == "Green" then Lib:SetAccent(Color3.fromRGB(90,220,120))
    else Lib:SetAccent(Color3.fromRGB(255,255,255)) end
end

function Lib:Get(f) return Lib.Flags[f] end
function Lib:Set(f,v) Lib.Flags[f] = v end

function Lib:Window(opts)
    opts = opts or {}
    local title = opts.Title or "Lib"
    local W = math.clamp(opts.Width or 560, 300, 1200)
    local H = math.clamp(opts.Height or 420, 220, 900)
    local key = opts.ToggleKey or Enum.KeyCode.RightShift
    if opts.Preset then Lib:ApplyPreset(opts.Preset) else Lib:ApplyPreset("White") end
    if opts.Accent then Lib:SetAccent(opts.Accent) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "Lib17"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 250
    parent(gui)

    -- left chips
    local function chip(txt, y)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(96, 22)
        b.Position = UDim2.fromOffset(12, 72 + y)
        b.BackgroundColor3 = Theme.Bg
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Text = txt
        b.TextSize = 12
        b.TextColor3 = Theme.Text
        font(b)
        b.Parent = gui
        mkStroke(b, Theme.Stroke, 1)
        return b
    end
    local tBtn = chip("Toggle UI", 0)
    local lBtn = chip("Lock UI", 24)

    -- title rect right
    local tr = Instance.new("Frame")
    tr.AnchorPoint = Vector2.new(1, 0)
    tr.Position = UDim2.new(1, -16, 0, 72)
    tr.Size = UDim2.fromOffset(140, 28)
    tr.BackgroundColor3 = Theme.Bg
    tr.BorderSizePixel = 0
    tr.Parent = gui
    mkStroke(tr, Theme.Stroke, 1)
    local trt = Instance.new("TextLabel")
    trt.BackgroundTransparency = 1
    trt.Size = UDim2.fromScale(1,1)
    trt.Position = UDim2.fromOffset(10,0)
    trt.Text = title
    trt.TextSize = 13
    trt.TextColor3 = Theme.Text
    trt.TextXAlignment = Enum.TextXAlignment.Left
    font(trt)
    trt.Parent = tr

    -- window
    local win = Instance.new("Frame")
    win.Size = UDim2.fromOffset(W, H)
    win.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    win.BackgroundColor3 = Theme.Bg
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    mkStroke(win, Theme.Stroke, 1)

    local head = Instance.new("Frame")
    head.Size = UDim2.new(1,0,0,30)
    head.BackgroundColor3 = Theme.Panel
    head.BorderSizePixel = 0
    head.Parent = win
    local hline = Instance.new("Frame")
    hline.Size = UDim2.new(1,0,0,1)
    hline.Position = UDim2.new(0,0,1,-1)
    hline.BackgroundColor3 = Theme.Stroke
    hline.BorderSizePixel = 0
    hline.Parent = head
    local ht = Instance.new("TextLabel")
    ht.BackgroundTransparency = 1
    ht.Position = UDim2.fromOffset(12,0)
    ht.Size = UDim2.new(1,-20,1,0)
    ht.Text = title
    ht.TextSize = 14
    ht.TextColor3 = Theme.Text
    ht.TextXAlignment = Enum.TextXAlignment.Left
    font(ht)
    ht.Parent = head

    -- drag
    do
        local drag, o, op
        head.InputBegan:Connect(function(inp)
            if Lib.Locked then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                drag = true; o = inp.Position; op = win.Position
                inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then drag = false end end)
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if not drag or Lib.Locked then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = inp.Position - o
            win.Position = UDim2.new(op.X.Scale, op.X.Offset + d.X, op.Y.Scale, op.Y.Offset + d.Y)
        end)
    end

    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1,-2,0,26)
    tabs.Position = UDim2.fromOffset(1,30)
    tabs.BackgroundColor3 = Theme.Panel
    tabs.BorderSizePixel = 0
    tabs.Parent = win
    local tl = Instance.new("UIListLayout")
    tl.FillDirection = Enum.FillDirection.Horizontal
    tl.Parent = tabs

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1,-10,1,-64)
    body.Position = UDim2.fromOffset(5,60)
    body.BackgroundColor3 = Theme.Panel
    body.BorderSizePixel = 0
    body.Parent = win
    mkStroke(body, Theme.Stroke2, 1)

    local API = { Gui = gui, Frame = win, Tabs = {} }

    function API:Toggle()
        if Lib.Locked and win.Visible then return end
        win.Visible = not win.Visible
    end
    function API:SetTitle(t) ht.Text = t; trt.Text = t end

    tBtn.MouseButton1Click:Connect(function() API:Toggle() end)
    lBtn.MouseButton1Click:Connect(function()
        Lib.Locked = not Lib.Locked
        lBtn.Text = Lib.Locked and "Unlock UI" or "Lock UI"
    end)
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == key then API:Toggle() end
    end)

    function API:Tab(name)
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.fromOffset(math.max(70, #name*8+18), 26)
        tb.BackgroundColor3 = Theme.Inner
        tb.BorderSizePixel = 0
        tb.AutoButtonColor = false
        tb.Text = name
        tb.TextSize = 13
        tb.TextColor3 = Theme.Dim
        font(tb)
        tb.Parent = tabs

        local page = Instance.new("Frame")
        page.Size = UDim2.fromScale(1,1)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = body

        local function col(side)
            local sf = Instance.new("ScrollingFrame")
            sf.BackgroundTransparency = 1
            sf.BorderSizePixel = 0
            sf.ScrollBarThickness = 2
            sf.ScrollBarImageColor3 = Theme.Accent
            sf.CanvasSize = UDim2.new(0,0,0,0)
            sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
            sf.Size = UDim2.new(0.5,-6,1,-8)
            sf.Position = side == "R" and UDim2.new(0.5,2,0,4) or UDim2.fromOffset(4,4)
            sf.Parent = page
            local l = Instance.new("UIListLayout")
            l.Padding = UDim.new(0,6)
            l.Parent = sf
            return sf
        end
        local L, R = col("L"), col("R")
        local T = { Name = name, Page = page, Button = tb }

        local function sel()
            for _,x in pairs(API.Tabs) do
                x.Page.Visible = false
                x.Button.BackgroundColor3 = Theme.Inner
                x.Button.TextColor3 = Theme.Dim
            end
            page.Visible = true
            tb.BackgroundColor3 = Theme.Panel
            tb.TextColor3 = Theme.Text
        end
        tb.MouseButton1Click:Connect(sel)

        function T:Group(gname, side)
            local parent = side == "Right" and R or L
            local box = Instance.new("Frame")
            box.Size = UDim2.new(1,-4,0,28)
            box.AutomaticSize = Enum.AutomaticSize.Y
            box.BackgroundColor3 = Theme.Inner
            box.BorderSizePixel = 0
            box.Parent = parent
            mkStroke(box, Theme.Stroke2, 1)

            local gh = Instance.new("TextLabel")
            gh.BackgroundTransparency = 1
            gh.Size = UDim2.new(1,-10,0,18)
            gh.Position = UDim2.fromOffset(8,4)
            gh.Text = gname
            gh.TextSize = 12
            gh.TextColor3 = Theme.Text
            gh.TextXAlignment = Enum.TextXAlignment.Left
            font(gh)
            gh.Parent = box

            local content = Instance.new("Frame")
            content.Size = UDim2.new(1,-10,0,0)
            content.Position = UDim2.fromOffset(5,22)
            content.AutomaticSize = Enum.AutomaticSize.Y
            content.BackgroundTransparency = 1
            content.Parent = box
            local cl = Instance.new("UIListLayout")
            cl.Padding = UDim.new(0,3)
            cl.Parent = content

            local subs, cur = {}, nil
            local G = {}

            function G:SubTabs(names)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,18)
                row.BackgroundTransparency = 1
                row.Parent = content
                local rl = Instance.new("UIListLayout")
                rl.FillDirection = Enum.FillDirection.Horizontal
                rl.Padding = UDim.new(0,3)
                rl.Parent = row
                for i,n in ipairs(names) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.fromOffset(math.max(50,#n*7+12),16)
                    b.BackgroundColor3 = Theme.Bg
                    b.BorderSizePixel = 0
                    b.AutoButtonColor = false
                    b.Text = n
                    b.TextSize = 11
                    b.TextColor3 = Theme.Dim
                    font(b)
                    b.Parent = row
                    mkStroke(b, Theme.Stroke2, 1)
                    local sp = Instance.new("Frame")
                    sp.Size = UDim2.new(1,0,0,0)
                    sp.AutomaticSize = Enum.AutomaticSize.Y
                    sp.BackgroundTransparency = 1
                    sp.Visible = false
                    sp.Parent = content
                    local spl = Instance.new("UIListLayout")
                    spl.Padding = UDim.new(0,2)
                    spl.Parent = sp
                    subs[n] = {f=sp,b=b}
                    b.MouseButton1Click:Connect(function()
                        for _,d in pairs(subs) do d.f.Visible=false; d.b.BackgroundColor3=Theme.Bg; d.b.TextColor3=Theme.Dim end
                        sp.Visible=true; b.BackgroundColor3=Theme.Panel; b.TextColor3=Theme.Text; cur=n
                    end)
                    if i==1 then sp.Visible=true; b.BackgroundColor3=Theme.Panel; b.TextColor3=Theme.Text; cur=n end
                end
                return G
            end

            local function host()
                if cur and subs[cur] then return subs[cur].f end
                return content
            end

            function G:Toggle(label, flag, def, cb, col)
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = def == true end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,18)
                row.BackgroundTransparency = 1
                row.Parent = host()
                local bx = Instance.new("TextButton")
                bx.Size = UDim2.fromOffset(12,12)
                bx.Position = UDim2.fromOffset(2,3)
                bx.BackgroundColor3 = Lib.Flags[flag] and Theme.On or Theme.Off
                bx.BorderSizePixel = 0
                bx.Text = ""
                bx.AutoButtonColor = false
                bx.Parent = row
                mkStroke(bx, Theme.Stroke, 1)
                local lb = Instance.new("TextLabel")
                lb.BackgroundTransparency = 1
                lb.Position = UDim2.fromOffset(18,0)
                lb.Size = UDim2.new(1, col and -40 or -22, 1, 0)
                lb.Text = label
                lb.TextSize = 13
                lb.TextColor3 = Theme.Text
                lb.TextXAlignment = Enum.TextXAlignment.Left
                font(lb)
                lb.Parent = row
                if col then
                    local sw = Instance.new("Frame")
                    sw.Size = UDim2.fromOffset(12,11)
                    sw.Position = UDim2.new(1,-16,0,3)
                    sw.BackgroundColor3 = col
                    sw.BorderSizePixel = 0
                    sw.Parent = row
                    mkStroke(sw, Theme.Stroke, 1)
                end
                bx.MouseButton1Click:Connect(function()
                    Lib.Flags[flag] = not Lib.Flags[flag]
                    bx.BackgroundColor3 = Lib.Flags[flag] and Theme.On or Theme.Off
                    if cb then pcall(cb, Lib.Flags[flag]) end
                end)
            end

            function G:Slider(label, flag, minv, maxv, def, cb)
                minv = minv or 0; maxv = maxv or 100
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = def or minv end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,30)
                row.BackgroundTransparency = 1
                row.Parent = host()
                local lb = Instance.new("TextLabel")
                lb.BackgroundTransparency = 1
                lb.Size = UDim2.new(1,-50,0,13)
                lb.Position = UDim2.fromOffset(2,0)
                lb.Text = label
                lb.TextSize = 12
                lb.TextColor3 = Theme.Text
                lb.TextXAlignment = Enum.TextXAlignment.Left
                font(lb)
                lb.Parent = row
                local vl = Instance.new("TextLabel")
                vl.BackgroundTransparency = 1
                vl.Size = UDim2.fromOffset(48,13)
                vl.Position = UDim2.new(1,-50,0,0)
                vl.TextSize = 12
                vl.TextColor3 = Theme.Dim
                vl.TextXAlignment = Enum.TextXAlignment.Right
                font(vl)
                vl.Parent = row
                local track = Instance.new("Frame")
                track.Size = UDim2.new(1,-4,0,5)
                track.Position = UDim2.fromOffset(2,17)
                track.BackgroundColor3 = Theme.Off
                track.BorderSizePixel = 0
                track.Parent = row
                mkStroke(track, Theme.Stroke2, 1)
                local fill = Instance.new("Frame")
                fill.BackgroundColor3 = Theme.Accent
                fill.BorderSizePixel = 0
                fill.Parent = track
                local function apply(v)
                    v = math.clamp(v, minv, maxv)
                    if maxv-minv >= 5 then v = math.floor(v+0.5) else v = math.floor(v*100+0.5)/100 end
                    Lib.Flags[flag] = v
                    fill.Size = UDim2.new((v-minv)/math.max(maxv-minv,1e-9),0,1,0)
                    vl.Text = tostring(v)
                    if cb then pcall(cb, v) end
                end
                apply(Lib.Flags[flag])
                local hold = false
                track.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then hold = true end
                end)
                UIS.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then hold = false end
                end)
                UIS.InputChanged:Connect(function(inp)
                    if not hold then return end
                    if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                    local pct = math.clamp((inp.Position.X - track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
                    apply(minv + pct*(maxv-minv))
                end)
            end

            function G:ColorPicker(label, flag, def, cb)
                def = def or Color3.new(1,1,1)
                if typeof(Lib.Flags[flag]) ~= "Color3" then Lib.Flags[flag] = def end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,18)
                row.BackgroundTransparency = 1
                row.Parent = host()
                local lb = Instance.new("TextLabel")
                lb.BackgroundTransparency = 1
                lb.Size = UDim2.new(1,-40,1,0)
                lb.Position = UDim2.fromOffset(2,0)
                lb.Text = label
                lb.TextSize = 13
                lb.TextColor3 = Theme.Text
                lb.TextXAlignment = Enum.TextXAlignment.Left
                font(lb)
                lb.Parent = row
                local sw = Instance.new("TextButton")
                sw.Size = UDim2.fromOffset(28,12)
                sw.Position = UDim2.new(1,-32,0,3)
                sw.BackgroundColor3 = Lib.Flags[flag]
                sw.BorderSizePixel = 0
                sw.Text = ""
                sw.AutoButtonColor = false
                sw.Parent = row
                mkStroke(sw, Theme.Stroke, 1)
                local open, panel = false, nil
                local function setc(c)
                    Lib.Flags[flag] = c
                    sw.BackgroundColor3 = c
                    if cb then pcall(cb, c) end
                end
                sw.MouseButton1Click:Connect(function()
                    if open and panel then panel:Destroy(); panel=nil; open=false; return end
                    open = true
                    panel = Instance.new("Frame")
                    panel.Size = UDim2.fromOffset(150,78)
                    panel.Position = UDim2.new(1,-150,0,18)
                    panel.BackgroundColor3 = Theme.Bg
                    panel.BorderSizePixel = 0
                    panel.ZIndex = 50
                    panel.Parent = row
                    mkStroke(panel, Theme.Stroke, 1)
                    local function ch(nm, y)
                        local l = Instance.new("TextLabel")
                        l.BackgroundTransparency = 1
                        l.Size = UDim2.fromOffset(14,14)
                        l.Position = UDim2.fromOffset(6,y)
                        l.Text = nm
                        l.TextSize = 11
                        l.TextColor3 = Theme.Dim
                        l.ZIndex = 51
                        font(l)
                        l.Parent = panel
                        local tr = Instance.new("Frame")
                        tr.Size = UDim2.fromOffset(100,5)
                        tr.Position = UDim2.fromOffset(24,y+4)
                        tr.BackgroundColor3 = Theme.Off
                        tr.BorderSizePixel = 0
                        tr.ZIndex = 51
                        tr.Parent = panel
                        local fl = Instance.new("Frame")
                        fl.BackgroundColor3 = Theme.Accent
                        fl.BorderSizePixel = 0
                        fl.ZIndex = 52
                        fl.Parent = tr
                        local c0 = Lib.Flags[flag]
                        local pv = nm=="R" and c0.R or (nm=="G" and c0.G or c0.B)
                        fl.Size = UDim2.new(pv,0,1,0)
                        local hold=false
                        local function ap(pct)
                            pct = math.clamp(pct,0,1)
                            fl.Size = UDim2.new(pct,0,1,0)
                            local c = Lib.Flags[flag]
                            local r,g,b = c.R,c.G,c.B
                            if nm=="R" then r=pct elseif nm=="G" then g=pct else b=pct end
                            setc(Color3.new(r,g,b))
                        end
                        tr.InputBegan:Connect(function(inp)
                            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                                hold=true; ap((inp.Position.X-tr.AbsolutePosition.X)/math.max(tr.AbsoluteSize.X,1))
                            end
                        end)
                        UIS.InputEnded:Connect(function(inp)
                            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then hold=false end
                        end)
                        UIS.InputChanged:Connect(function(inp)
                            if not hold or not panel then return end
                            if inp.UserInputType~=Enum.UserInputType.MouseMovement and inp.UserInputType~=Enum.UserInputType.Touch then return end
                            ap((inp.Position.X-tr.AbsolutePosition.X)/math.max(tr.AbsoluteSize.X,1))
                        end)
                    end
                    ch("R",8); ch("G",28); ch("B",48)
                    local okb = Instance.new("TextButton")
                    okb.Size = UDim2.fromOffset(40,14)
                    okb.Position = UDim2.fromOffset(104,60)
                    okb.BackgroundColor3 = Theme.Inner
                    okb.BorderSizePixel = 0
                    okb.Text = "OK"
                    okb.TextSize = 10
                    okb.TextColor3 = Theme.Text
                    okb.ZIndex = 53
                    font(okb)
                    okb.Parent = panel
                    mkStroke(okb, Theme.Stroke, 1)
                    okb.MouseButton1Click:Connect(function()
                        if panel then panel:Destroy(); panel=nil; open=false end
                    end)
                end)
            end

            function G:Dropdown(label, flag, opts, def, cb)
                opts = opts or {"None"}
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = def or opts[1] end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,18)
                row.BackgroundTransparency = 1
                row.ZIndex = 5
                row.Parent = host()
                local lb = Instance.new("TextLabel")
                lb.BackgroundTransparency = 1
                lb.Size = UDim2.new(0.38,0,1,0)
                lb.Position = UDim2.fromOffset(2,0)
                lb.Text = label
                lb.TextSize = 12
                lb.TextColor3 = Theme.Text
                lb.TextXAlignment = Enum.TextXAlignment.Left
                font(lb)
                lb.Parent = row
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.58,0,0,15)
                btn.Position = UDim2.new(0.4,0,0,1)
                btn.BackgroundColor3 = Theme.Bg
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Text = " "..tostring(Lib.Flags[flag])
                btn.TextSize = 11
                btn.TextColor3 = Theme.Text
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 6
                font(btn)
                btn.Parent = row
                mkStroke(btn, Theme.Stroke, 1)
                local open, lf = false, nil
                btn.MouseButton1Click:Connect(function()
                    if open and lf then lf:Destroy(); lf=nil; open=false; return end
                    open = true
                    lf = Instance.new("Frame")
                    lf.Size = UDim2.new(0.58,0,0,math.min(#opts*16,96))
                    lf.Position = UDim2.new(0.4,0,0,16)
                    lf.BackgroundColor3 = Theme.Bg
                    lf.BorderSizePixel = 0
                    lf.ZIndex = 40
                    lf.Parent = row
                    mkStroke(lf, Theme.Stroke, 1)
                    local ll = Instance.new("UIListLayout")
                    ll.Parent = lf
                    for _,opt in ipairs(opts) do
                        local ob = Instance.new("TextButton")
                        ob.Size = UDim2.new(1,0,0,16)
                        ob.BackgroundColor3 = Theme.Inner
                        ob.BorderSizePixel = 0
                        ob.AutoButtonColor = false
                        ob.Text = " "..tostring(opt)
                        ob.TextSize = 11
                        ob.TextColor3 = Theme.Text
                        ob.TextXAlignment = Enum.TextXAlignment.Left
                        ob.ZIndex = 41
                        font(ob)
                        ob.Parent = lf
                        ob.MouseButton1Click:Connect(function()
                            Lib.Flags[flag] = opt
                            btn.Text = " "..tostring(opt)
                            if cb then pcall(cb, opt) end
                            lf:Destroy(); lf=nil; open=false
                        end)
                    end
                end)
            end

            function G:Button(label, cb)
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1,-4,0,20)
                b.BackgroundColor3 = Theme.Bg
                b.BorderSizePixel = 0
                b.AutoButtonColor = false
                b.Text = label
                b.TextSize = 13
                b.TextColor3 = Theme.Text
                font(b)
                b.Parent = host()
                mkStroke(b, Theme.Stroke, 1)
                b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
            end

            function G:ButtonAccent(label, cb)
                G:Button(label, cb)
            end

            function G:Label(text)
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1,0,0,14)
                l.BackgroundTransparency = 1
                l.Text = text
                l.TextSize = 11
                l.TextColor3 = Theme.Dim
                l.TextXAlignment = Enum.TextXAlignment.Left
                font(l)
                l.Parent = host()
            end

            function G:Textbox(label, flag, def, cb)
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = def or "" end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,18)
                row.BackgroundTransparency = 1
                row.Parent = host()
                local lb = Instance.new("TextLabel")
                lb.BackgroundTransparency = 1
                lb.Size = UDim2.new(0.38,0,1,0)
                lb.Position = UDim2.fromOffset(2,0)
                lb.Text = label
                lb.TextSize = 12
                lb.TextColor3 = Theme.Text
                lb.TextXAlignment = Enum.TextXAlignment.Left
                font(lb)
                lb.Parent = row
                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.58,0,0,15)
                box.Position = UDim2.new(0.4,0,0,1)
                box.BackgroundColor3 = Theme.Bg
                box.BorderSizePixel = 0
                box.TextSize = 11
                box.TextColor3 = Theme.Text
                box.ClearTextOnFocus = false
                box.Text = tostring(Lib.Flags[flag])
                font(box)
                box.Parent = row
                mkStroke(box, Theme.Stroke, 1)
                box.FocusLost:Connect(function()
                    Lib.Flags[flag] = box.Text
                    if cb then pcall(cb, box.Text) end
                end)
            end

            function G:Keybind(label, flag, def, cb)
                def = def or Enum.KeyCode.Unknown
                if Lib.Flags[flag] == nil then Lib.Flags[flag] = def end
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,18)
                row.BackgroundTransparency = 1
                row.Parent = host()
                local lb = Instance.new("TextLabel")
                lb.BackgroundTransparency = 1
                lb.Size = UDim2.new(0.5,0,1,0)
                lb.Position = UDim2.fromOffset(2,0)
                lb.Text = label
                lb.TextSize = 12
                lb.TextColor3 = Theme.Text
                lb.TextXAlignment = Enum.TextXAlignment.Left
                font(lb)
                lb.Parent = row
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.45,0,0,15)
                btn.Position = UDim2.new(0.52,0,0,1)
                btn.BackgroundColor3 = Theme.Bg
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.TextSize = 11
                btn.TextColor3 = Theme.Text
                font(btn)
                local function kn()
                    local k = Lib.Flags[flag]
                    return typeof(k)=="EnumItem" and k.Name or tostring(k)
                end
                btn.Text = kn()
                btn.Parent = row
                mkStroke(btn, Theme.Stroke, 1)
                local listen = false
                btn.MouseButton1Click:Connect(function() listen=true; btn.Text="..." end)
                UIS.InputBegan:Connect(function(inp)
                    if not listen then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        Lib.Flags[flag] = inp.KeyCode
                        btn.Text = inp.KeyCode.Name
                        listen = false
                        if cb then pcall(cb, inp.KeyCode) end
                    end
                end)
            end

            return G
        end

        API.Tabs[name] = T
        if not API._on then API._on = T; sel() end
        return T
    end

    function API:Unload()
        pcall(function() gui:Destroy() end)
    end

    table.insert(Lib._wins, API)
    return API
end

local env = (type(getgenv)=="function" and getgenv()) or _G
env.Lib = Lib
env.SprayUI = Lib
print("[Lib] 1.7.0 loaded")
return Lib

local Lib = (type(getgenv) == "function" and getgenv().Lib) or _G.Lib
if not Lib then
    warn("[Spray] Lib failed to embed")
    return
end
local F = Lib.Flags

-- ===== SKYBOX =====

local SKYBOXES = {
    Default = "DEFAULT",
    Afternoon = {
        SkyboxBk = "rbxassetid://6444884337",
        SkyboxDn = "rbxassetid://6444884780",
        SkyboxFt = "rbxassetid://6444884337",
        SkyboxLf = "rbxassetid://6444884337",
        SkyboxRt = "rbxassetid://6444884337",
        SkyboxUp = "rbxassetid://6412503612",
    },
    Night = {
        SkyboxBk = "rbxassetid://12064107",
        SkyboxDn = "rbxassetid://12064152",
        SkyboxFt = "rbxassetid://12064121",
        SkyboxLf = "rbxassetid://12064115",
        SkyboxRt = "rbxassetid://12064124",
        SkyboxUp = "rbxassetid://12064131",
    },
    Space = {
        SkyboxBk = "rbxassetid://159454299",
        SkyboxDn = "rbxassetid://159454296",
        SkyboxFt = "rbxassetid://159454293",
        SkyboxLf = "rbxassetid://159454286",
        SkyboxRt = "rbxassetid://159454300",
        SkyboxUp = "rbxassetid://159454288",
    },
    Pink = {
        SkyboxBk = "rbxassetid://271042516",
        SkyboxDn = "rbxassetid://271077391",
        SkyboxFt = "rbxassetid://271042556",
        SkyboxLf = "rbxassetid://271042310",
        SkyboxRt = "rbxassetid://271042467",
        SkyboxUp = "rbxassetid://271077887",
    },
    Cloudy = {
        SkyboxBk = "rbxassetid://591058823",
        SkyboxDn = "rbxassetid://591059876",
        SkyboxFt = "rbxassetid://591058104",
        SkyboxLf = "rbxassetid://591057861",
        SkyboxRt = "rbxassetid://591057625",
        SkyboxUp = "rbxassetid://591058671",
    },
    Sunset = {
        SkyboxBk = "rbxassetid://151165214",
        SkyboxDn = "rbxassetid://151165197",
        SkyboxFt = "rbxassetid://151165224",
        SkyboxLf = "rbxassetid://151165191",
        SkyboxRt = "rbxassetid://151165206",
        SkyboxUp = "rbxassetid://151165227",
    },
}

local skyBackup = nil
local function backupSky()
    if skyBackup then return end
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        skyBackup = {
            SkyboxBk = sky.SkyboxBk, SkyboxDn = sky.SkyboxDn, SkyboxFt = sky.SkyboxFt,
            SkyboxLf = sky.SkyboxLf, SkyboxRt = sky.SkyboxRt, SkyboxUp = sky.SkyboxUp,
        }
    else
        skyBackup = "NONE"
    end
end

local function applySkybox(name)
    backupSky()
    if name == "Default" or not SKYBOXES[name] or SKYBOXES[name] == "DEFAULT" then
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if skyBackup == "NONE" then
            if sky then sky:Destroy() end
            return
        end
        if type(skyBackup) == "table" then
            if not sky then
                sky = Instance.new("Sky")
                sky.Parent = Lighting
            end
            for k, v in pairs(skyBackup) do
                pcall(function() sky[k] = v end)
            end
        end
        return
    end
    local data = SKYBOXES[name]
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Name = "SpraySky"
        sky.Parent = Lighting
    end
    for k, v in pairs(data) do
        pcall(function() sky[k] = v end)
    end
end


-- ===== UI =====
local okUI, errUI = pcall(function()
local Win = Lib:Window({
    Title = "Spray | v1",
    Width = 600,
    Height = 460,
    Preset = "White",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Win:Tab("Main")
do
    local combat = Main:Group("Combat", "Left")
    combat:SubTabs({ "Silent", "Aimbot", "Trigger" })
    combat:Toggle("Enabled", "SilentEnabled", false)
    combat:Toggle("Visible only", "SilentVisible", false)
    combat:Toggle("Team check", "SilentTeam", true)
    combat:Slider("Hit chance", "SilentHC", 1, 100, 100)
    combat:Slider("FOV radius", "SilentRadius", 20, 500, 120)
    combat:Dropdown("Target part", "SilentPart", { "Head", "HumanoidRootPart", "UpperTorso", "Closest" }, "Head")

    local rage = Main:Group("Rage", "Right")
    rage:Toggle("Ragebot enabled", "RageEnabled", false)
    rage:Toggle("Void spam", "VoidSpam", false)
    rage:Toggle("Void tap", "VoidTap", false)
    rage:Slider("Hide (s)", "VoidHide", 0.05, 2, 0.25)
    rage:Slider("Attack (s)", "VoidAtk", 0.01, 1, 0.1)
    rage:Button("Panic off", function()
        F.SilentEnabled = false
        F.RageEnabled = false
        F.VoidSpam = false
        F.VoidTap = false
    end)
end

local ESP = Win:Tab("ESP")
do
    local e = ESP:Group("Enemy", "Left")
    e:SubTabs({ "Enemy", "Team", "Local" })
    e:Toggle("Enabled", "EspEnabled", false)
    e:Toggle("Box", "EspBox", false, nil, Color3.fromRGB(255,255,255))
    e:Toggle("Name", "EspName", false)
    e:Toggle("Distance", "EspDist", false)
    e:Toggle("Health bar", "EspHP", false)
    e:Toggle("Skeleton", "EspSkel", false)
    e:Toggle("Highlight", "EspHL", false)
    e:ColorPicker("Box color", "EspBoxColor", Color3.fromRGB(255,255,255))

    local o = ESP:Group("Override", "Right")
    o:Toggle("Override appearance", "EspOverride", false)
    o:ColorPicker("Override color", "EspOvColor", Color3.fromRGB(255,255,255))
end

local Visuals = Win:Tab("Visuals")
do
    local v = Visuals:Group("Effects", "Left")
    v:Toggle("Chams", "Chams", false)
    v:ColorPicker("Chams color", "ChamsColor", Color3.fromRGB(100,140,255))
    v:Toggle("Crosshair", "Crosshair", false)
    v:Toggle("Remove vignette", "NoVignette", false)

    local c = Visuals:Group("Camera", "Right")
    c:Toggle("FOV changer", "FovOn", false)
    c:Slider("FOV", "FovVal", 50, 120, 80)
    c:Toggle("Fullbright", "Fullbright", false)
    c:Toggle("No hands", "NoHands", false)
    c:Toggle("Stretched screen", "StretchOn", false)
    c:Dropdown("Stretch mode", "StretchMode", { "1080x1080", "4:3", "16:10" }, "1080x1080")
    c:Slider("Stretch FOV boost", "StretchFov", 0, 40, 15)
    c:Label("1080x1080 = square letterbox")
end

local World = Win:Tab("World")
do
    local w = World:Group("Lighting", "Left")
    w:Toggle("Color correction", "CCOn", false)
    w:Slider("Saturation", "CCSat", -1, 1, 0)
    w:Slider("Contrast", "CCCon", -1, 1, 0)
    w:Slider("Brightness", "CCBright", -1, 1, 0)
    w:Toggle("Bloom", "BloomOn", false)
    w:Slider("Bloom intensity", "BloomInt", 0, 2, 0.6)
    w:ColorPicker("Ambient", "AmbientCol", Color3.fromRGB(128,128,128))
    w:ColorPicker("Fog color", "FogCol", Color3.fromRGB(191,191,191))
    w:Slider("Fog end", "FogEnd", 100, 10000, 1000)

    local s = World:Group("Skybox", "Right")
    s:Toggle("Skybox enabled", "SkyOn", false)
    s:Dropdown("Skybox", "SkyName", { "Default", "Afternoon", "Night", "Space", "Pink", "Cloudy", "Sunset" }, "Afternoon")
    s:Button("Apply skybox", function()
        F.SkyOn = true
        applySkybox(F.SkyName or "Afternoon")
    end)
    s:Button("Reset skybox", function()
        F.SkyOn = false
        applySkybox("Default")
    end)
end

local Char = Win:Tab("Character")
do
    local m = Char:Group("Movement", "Left")
    m:Toggle("Speed", "SpeedOn", false)
    m:Slider("Speed", "SpeedVal", 16, 120, 24)
    m:Toggle("Fly", "FlyOn", false)
    m:Slider("Fly speed", "FlySpeed", 20, 200, 50)
    m:Toggle("Noclip", "Noclip", false)
    m:Toggle("Infinite jump", "InfJump", false)

    local a = Char:Group("Anti Aim", "Right")
    a:Toggle("Enabled", "AAEnabled", false)
    a:Dropdown("Yaw", "AAYaw", { "None", "Spin", "Jitter", "Static" }, "None")
    a:Slider("Spin speed", "AASpin", 1, 50, 10)
end

local Misc = Win:Tab("Misc")
do
    local g = Misc:Group("General", "Left")
    g:Toggle("Hit notify", "HitNotify", true)
    g:Toggle("Chat spam", "ChatSpam", false)
    g:Textbox("Spam text", "SpamText", "Spray")
    g:Dropdown("Queue", "QueueMode", { "1v1", "2v2", "Casual" }, "1v1")

    local u = Misc:Group("Modules", "Right")
    u:Toggle("Skin unlock (local)", "SkinUnlock", false)
    u:Toggle("Angel Aura", "AngelAura", false)
    u:Toggle("AC Bypass", "ACBypass", false)
    u:Label("Enable AC in lobby")
end

local Settings = Win:Tab("Settings")
do
    local th = Settings:Group("Theme", "Left")
    th:Button("White", function() Lib:ApplyPreset("White") end)
    th:Button("Purple", function() Lib:ApplyPreset("Purple") end)
    th:Button("Blue", function() Lib:ApplyPreset("Blue") end)
    th:Button("Red", function() Lib:ApplyPreset("Red") end)
    th:Button("Green", function() Lib:ApplyPreset("Green") end)
    th:ColorPicker("Accent", "AccentCol", Color3.fromRGB(255,255,255), function(c) Lib:SetAccent(c) end)

    local c = Settings:Group("System", "Right")
    c:Label("Spray | v1")
    c:Button("Unload", function()
        pcall(function()
            if getgenv().RV and getgenv().RV.stop then getgenv().RV.stop() end
        end)
        applySkybox("Default")
        Win:Unload()
    end)
end

_G.__SprayWin = Win
end)

if not okUI then
    warn("[Spray] UI error:", errUI)
    return
end


local function getChar()
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then
        return c
    end
end

local function applyNoHands(on)
    local c = getChar()
    if not c then return end
    local names = { "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm" }
    for _, n in ipairs(names) do
        local p = c:FindFirstChild(n)
        if p and p:IsA("BasePart") then
            p.LocalTransparencyModifier = on and 1 or 0
        end
    end
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        for _, v in ipairs(cam:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = v.Name:lower()
                if n:find("hand") or n:find("arm") then
                    v.LocalTransparencyModifier = on and 1 or 0
                end
            end
        end
    end)
end

local acLoaded, skinLoaded, auraLoaded = false, false, false
local lastSky, lastSkyOn = nil, nil
local lastNoHands = nil
local lastStretch, lastStretchMode = nil, nil

local function loadAC()
    if acLoaded then return end
    acLoaded = true
    local src = [=[-- LocalScript3 | ReplicatedFirst
-- Axiom: Rivals AC Bypass v3.0 | Adapted | <10KB

local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp              = Players.LocalPlayer

-- // Crash fallback
local function crash()
    local t={}
    while true do t[#t+1]=string.rep("x",1e6) end
end

-- // Setmetatable hook — kills MiscellaneousController weak table
local _stbl
_stbl = hookfunction(getrenv().setmetatable, newcclosure(function(tbl, mt)
    if mt and typeof(mt)=="table" and rawget(mt,"__mode")=="kv" then
        local tr = debug.traceback()
        if tr:find("MiscellaneousController") then
            return _stbl({1,2,3},{})
        end
    end
    return _stbl(tbl,mt)
end))

-- // Config
local LEARN_PACKETS = 1
local REAP_TARGET   = "LocalScript3"
local REAP_EVERY    = 0.5
local RETRY_AFTER   = 5
local KEY           = "jdsbau"

-- // Cipher
local function cipher(s)
    local o=table.create(#s)
    for i=1,#s do
        o[i]=string.char(bit32.bxor(string.byte(s,i),string.byte(KEY,(i-1)%6+1)))
    end
    return table.concat(o)
end

local function isText(s)
    if #s==0 then return false end
    for i=1,#s do local b=string.byte(s,i) if b<32 or b>126 then return false end end
    return true
end

local function deepCopy(v,seen)
    if type(v)~="table" then return v end
    seen=seen or {}
    if seen[v] then return seen[v] end
    local t={} seen[v]=t
    for k,x in pairs(v) do t[deepCopy(k,seen)]=deepCopy(x,seen) end
    return t
end

local function count(t)
    local n=0
    if type(t)=="table" then for _ in pairs(t) do n=n+1 end end
    return n
end

local FMT="%s_UrA_Paster_nn"
do
    local ok,r=pcall(string.format,"%*_UrA_Paster_nn","X")
    if ok and r=="X_UrA_Paster_nn" then FMT="%*_UrA_Paster_nn" end
end

local function identityPlain() return string.format(FMT,lp.Name) end
local function identityField() return cipher(identityPlain()) end
local function clockField()    return cipher(tostring(workspace:GetServerTimeNow())) end

local KNOWNNONCE={}

local function classify(v)
    local t=type(v)
    if t=="number" then return "number",v end
    if t=="table"  then return "table",v end
    if t=="string" then
        if KNOWNNONCE[v] then return "nonce",v end
        local d=cipher(v)
        if d==identityPlain() then return "identity",d end
        if isText(d) and tonumber(d) then return "clock",tonumber(d) end
        return "nonce",v
    end
    return t,v
end

local function dissect(a1)
    local r={kinds={},maxKey=0,nonce=nil,nonceSlot=nil,descValue=nil}
    if type(a1)~="table" then return r end
    for k,v in pairs(a1) do
        local kind,val=classify(v)
        r.kinds[k]=kind
        if type(k)=="number" and k>r.maxKey then r.maxKey=k end
        if kind=="nonce" and r.nonce==nil then r.nonce,r.nonceSlot=val,k end
        if kind=="table" then r.descValue=v end
    end
    return r
end

local function validate(d,realIndex)
    local bad,N={},d.maxKey
    if N<2 then return{"N="..tostring(N).." < 2"} end
    if d.kinds[N]~="table" then
        bad[#bad+1]=string.format("[%d] descriptor missing, got %s",N,tostring(d.kinds[N]))
    end
    for k=1,N-1 do
        local want
        if k==realIndex then want="nonce"
        elseif k==1 then want="identity"
        elseif k==2 then want="clock"
        else want="number" end
        if d.kinds[k]~=want then
            bad[#bad+1]=string.format("[%d] want %s got %s",k,want,tostring(d.kinds[k]))
        end
    end
    return bad
end

local TPL=nil
local OUTER={n=5,arg2IsDesc1=false}

local function learn(d)
    if type(d.descValue)~="table" then return end
    TPL={desc=deepCopy(d.descValue),descN=count(d.descValue)}
end

local function build(nonce,realIndex)
    local N=math.random(1,8)+1
    local p={}
    p[1]=identityField()
    p[2]=clockField()
    for k=3,N-1 do p[k]=math.random(5,100000) end
    if type(realIndex)=="number" and realIndex>=1 and realIndex<N then
        p[realIndex]=nonce
    end
    p[N]=(TPL and deepCopy(TPL.desc)) or {{},{1,2,3,4,5},{},{},{},{}}
    return p,N
end

-- // Kill previous instance
do
    local prev=(getgenv and getgenv() or _G).RV
    if type(prev)=="table" and type(prev.stop)=="function" then pcall(prev.stop) end
end

-- // Flexible remote resolve — tries Rivals paths
local ev
local function resolveRemote()
    -- Try known Rivals paths
    local paths = {
        function() return ReplicatedStorage:WaitForChild("Remotes",3):WaitForChild("RemoteEvent",3) end,
        function() return ReplicatedStorage:WaitForChild("RemoteEvent",3) end,
        function()
            for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") then return v end
            end
        end,
    }
    for _,fn in ipairs(paths) do
        local ok,result=pcall(fn)
        if ok and result then return result end
    end
    return nil
end

ev = resolveRemote()
if not ev then
    warn("[RV] remote not found — AC bypass inactive")
    return
end

-- // Hook crash on AC client fire
ev.OnClientEvent:Connect(function(a1)
    -- if AC fires unexpected kick signal — crash first
    if type(a1)=="string" and (a1:lower():find("kick") or a1:lower():find("ban")) then
        coroutine.wrap(crash)()
    end
end)

local RV={}
RV.phase="LEARN"
RV.running=true

local STAT={learned=0,sent=0,fail=0,suppressed=0,retries=0,
            inbound=0,gamePackets=0,lawBad=0,killed=0,sweeps=0}

local mine=false
local last=nil
local pendingOurs=nil
local lastInboundAt=0

local function fire(p,N)
    local desc1=p[N] and p[N][1]
    if type(desc1)~="table" then desc1={} end
    local outer={p,OUTER.arg2IsDesc1 and desc1 or {}}
    mine=true
    local ok,err=pcall(function() ev:FireServer(table.unpack(outer,1,OUTER.n)) end)
    mine=false
    if ok then STAT.sent=STAT.sent+1
    else STAT.fail=STAT.fail+1 end
    return ok
end

ev.OnClientEvent:Connect(function(a1,a2)
    local nonce
    if typeof(a1)=="buffer" then nonce=buffer.tostring(a1)
    elseif type(a1)=="string" then nonce=a1 end
    if not nonce then return end
    KNOWNNONCE[nonce]=true
    STAT.inbound=STAT.inbound+1
    lastInboundAt=os.clock()
    local realIndex=(type(a2)=="number") and a2 or 1
    last={nonce=nonce,realIndex=realIndex}
    local p,N=build(nonce,realIndex)
    pendingOurs={packet=p,realIndex=realIndex}
    if RV.phase=="LIVE" then fire(p,N) end
end)

local function observe(args)
    local d=dissect(args[1])
    STAT.gamePackets=STAT.gamePackets+1
    OUTER.n=args.n
    local desc=args[1] and args[1][d.maxKey]
    OUTER.arg2IsDesc1=(type(desc)=="table" and desc[1]~=nil and args[2]==desc[1])
    learn(d)
    local realIndex=pendingOurs and pendingOurs.realIndex or nil
    local gbad=validate(d,realIndex)
    local obad=pendingOurs and validate(dissect(pendingOurs.packet),realIndex) or {}
    if RV.phase=="LEARN" then
        if #gbad>0 or #obad>0 then
            STAT.learned=0
        else
            STAT.learned=STAT.learned+1
            if STAT.learned>=LEARN_PACKETS then
                RV.phase="LIVE"
                print("[LIVE] takeover active boss man")
            end
        end
    end
    pendingOurs=nil
end

local function wrap(f)
    if type(newcclosure)=="function" then
        local ok,c=pcall(newcclosure,f)
        if ok then return c end
    end
    return f
end

local function tap(self,...)
    if self~=ev or mine then return false end
    local args=table.pack(...)
    local suppress=(RV.phase=="LIVE")
    if suppress then STAT.suppressed=STAT.suppressed+1 end
    task.defer(function() pcall(observe,args) end)
    return suppress
end

local mode,oldFire,oldNamecall="none",nil,nil
local hookedTarget=nil

local function namecallBody(self,...)
    if self==ev then
        local m=(getnamecallmethod and getnamecallmethod()) or ""
        if m=="FireServer" and tap(self,...) then return end
    end
    return oldNamecall(self,...)
end

-- // Hook
if type(hookmetamethod)=="function" then
    local ok=pcall(function()
        oldNamecall=hookmetamethod(game,"__namecall",wrap(namecallBody))
    end)
    if ok and oldNamecall then mode="hookmetamethod" end
end

if mode=="none" then
    local ok=pcall(function()
        hookedTarget=ev.FireServer
        oldFire=hookfunction(ev.FireServer,wrap(function(self,...)
            if tap(self,...) then return end
            return oldFire(self,...)
        end))
    end)
    if ok and oldFire then mode="hookfunction:FireServer" end
end

-- // Reaper — kills LocalScript3 threads
local me=coroutine.running()
local function threadOwner(t)
    for lvl=1,32 do
        local ok,s=pcall(debug.info,t,lvl,"s")
        if not ok or s==nil then break end
        if type(s)=="string" and s~="" and string.find(s,REAP_TARGET,1,true) then return s end
    end
    if type(getscriptfromthread)=="function" then
        local ok,sc=pcall(getscriptfromthread,t)
        if ok and typeof(sc)=="Instance" then
            local n=sc:GetFullName()
            if string.find(n,REAP_TARGET,1,true) then return n end
        end
    end
    return nil
end

local function reapSweep()
    if type(getthreads)~="function" then return end
    local ok,list=pcall(getthreads)
    if not ok or type(list)~="table" then return end
    STAT.sweeps=STAT.sweeps+1
    local cur=coroutine.running()
    for _,t in ipairs(list) do
        if type(t)=="thread" and t~=me and t~=cur and coroutine.status(t)~="dead" then
            if threadOwner(t) then
                local killed=pcall(coroutine.close,t)
                if not killed and type(task.cancel)=="function" then
                    killed=pcall(task.cancel,t)
                end
                if killed then STAT.killed=STAT.killed+1 end
            end
        end
    end
end

task.spawn(function()
    while RV.running do
        if RV.phase=="LIVE" then reapSweep() end
        task.wait(REAP_EVERY)
    end
end)

task.spawn(function()
    while RV.running do
        task.wait(1)
        if RV.phase=="LIVE" and last and lastInboundAt>0
           and os.clock()-lastInboundAt>RETRY_AFTER then
            STAT.retries=STAT.retries+1
            local p,N=build(last.nonce,last.realIndex)
            fire(p,N)
            lastInboundAt=os.clock()
        end
    end
end)

RV.stats=STAT
RV.stop=function()
    RV.running=false
    RV.phase="LEARN"
    print("stopped.")
end

print("[RV] rivals ac bypass loaded | mode="..mode)
getgenv().RV=RV
return RV]=]
    local ok, err = pcall(function()
        local fn = loadstring(src)
        if fn then fn() end
    end)
    if ok then
        print("[Spray] AC bypass loaded")
    else
        warn("[Spray] AC:", err)
        acLoaded = false
    end
end

local function loadSkin()
    if skinLoaded then return end
    skinLoaded = true
    local ok, err = pcall(function()
        local CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 8))
        if not CosmeticLibrary then return end
        local orig = CosmeticLibrary.OwnsCosmetic
        CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
            if type(name) == "string" and name:find("MISSING_") then
                return orig(self, inventory, name, weapon)
            end
            local cosmetic = CosmeticLibrary.Cosmetics and CosmeticLibrary.Cosmetics[name]
            if cosmetic then
                local t = cosmetic.Type
                if t == "Skin" or t == "Charm" or t == "Dance" or t == "Emote" or t == "Wrap" or t == "Wrapping" then
                    return true
                end
            end
            return orig(self, inventory, name, weapon)
        end
        for _, fnName in ipairs({ "OwnsCosmeticNormally", "OwnsCosmeticUniversally", "OwnsCosmeticForWeapon" }) do
            if CosmeticLibrary[fnName] then
                CosmeticLibrary[fnName] = function() return true end
            end
        end
        print("[Spray] skin unlock on")
    end)
    if not ok then warn("[Spray] skin:", err) end
end

local function loadAura()
    if auraLoaded then return end
    auraLoaded = true
    local src = [=[local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AuraEngine = {}

local state = {
    loaded = false,
    tree = nil,         
    instances = {},      
    baseValues = {},     
    roots = {},      
    rig = nil,       
    currentName = nil,
    connections = {},
}

local BONE_MAP = {
    Head = { "Head" },
    UpperTorso = { "UpperTorso", "Torso" },
    LowerTorso = { "LowerTorso" },
    RightUpperArm = { "RightUpperArm", "Right Arm" },
    RightLowerArm = { "RightLowerArm", "Right Arm" },
    RightHand = { "RightHand", "Right Arm" },
    LeftUpperArm = { "LeftUpperArm", "Left Arm" },
    LeftLowerArm = { "LeftLowerArm", "Left Arm" },
    LeftHand = { "LeftHand", "Left Arm" },
    RightUpperLeg = { "RightUpperLeg", "Right Leg" },
    RightLowerLeg = { "RightLowerLeg", "Right Leg" },
    LeftUpperLeg = { "LeftUpperLeg", "Left Leg" },
    LeftLowerLeg = { "LeftLowerLeg", "Left Leg" },
    HumanoidRootPart = { "HumanoidRootPart" },
    Torso = { "Torso", "UpperTorso" },
}

local function newInstance(className)
    local ok, inst = pcall(function() return Instance.new(className) end)
    if not ok or not inst then return nil end
    return inst
end

local function resolveEnum(value, enumType)
    if type(value) ~= "string" then return value end
    local short = value:match("^Enum%.[^.]+%.(.+)$")
    if not short then return value end
    local enum = enumType
    if not enum then
        enum = Enum
        for part in value:gmatch("Enum%.([^.]+)") do
            enum = enum[part]
            if not enum then break end
        end
    end
    if type(enum) == "table" then
        local v = enum[short]
        if v ~= nil then return v end
    end
    return value
end

local function applyProp(inst, key, value)
    local enumType
    if key == "Material" then
        enumType = Enum.Material
    elseif key == "Shape" and inst:IsA("BasePart") then
        enumType = Enum.PartType
    elseif key == "Shape" and inst:IsA("ParticleEmitter") then
        enumType = Enum.ParticleEmitterShape
    elseif key == "ShapeInOut" then
        enumType = Enum.ParticleEmitterShapeInOut
    elseif key == "ShapeStyle" then
        enumType = Enum.ParticleEmitterShapeStyle
    elseif key == "EmissionDirection" then
        enumType = Enum.NormalId
    elseif key == "Orientation" then
        enumType = Enum.ParticleOrientation
    elseif key == "FlipbookLayout" then
        enumType = Enum.ParticleFlipbookLayout
    elseif key == "FlipbookMode" then
        enumType = Enum.ParticleFlipbookMode
    elseif key == "TextureMode" then
        enumType = Enum.TextureMode
    end

    local resolved = resolveEnum(value, enumType)
    local ok = pcall(function() inst[key] = resolved end)
    return ok
end

local function resolveBone(node)
    local candidates = BONE_MAP[node.name]
    if not candidates then return nil end
    for _, name in ipairs(candidates) do
        local found = state.rig:FindFirstChild(name)
        if found and found:IsA("BasePart") then return found end
    end
    return nil
end

local function weldToBone(part, bone)
    if not (part and bone) then return false end

    if not part.Parent then
        part.Parent = bone
    end

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part
    weld.Part1 = bone
    weld.Parent = part

    return true
end

function AuraEngine.Load(tree, character)
    AuraEngine.Unload()

    if type(tree) ~= "table" then
        warn("[aura] invalid tree")
        return false
    end

    state.tree = tree
    state.rig = character or (Players.LocalPlayer and Players.LocalPlayer.Character)
    if not state.rig then
        warn("[aura] no character available")
        return false
    end

    local nodes = tree.nodes or {}

    local byId = {}
    for _, node in ipairs(nodes) do
        byId[node.id] = node
    end

    for _, node in ipairs(nodes) do
        local inst = newInstance(node.class)
        if not inst then
            warn("[aura] could not create " .. node.class .. " id=" .. tostring(node.id))
            continue
        end

        local props = node.props or {}
        local base = {}
        for key, value in pairs(props) do
            if key ~= "CFrame" then
                applyProp(inst, key, value)
                if type(value) == "number" then
                    base[key] = value
                elseif type(value) == "table" and value.Min and value.Max then
                    base[key] = { Min = value.Min, Max = value.Max }
                end
            end
        end

        state.instances[node.id] = inst
        state.baseValues[inst] = base
    end

    for _, node in ipairs(nodes) do
        local inst = state.instances[node.id]
        if not inst then continue end

        if node.parent == 0 then

            local bone = resolveBone(node)
            if bone then
                inst.Name = "AuraRoot_" .. node.name

                inst.CanCollide = false
                inst.CanTouch = false
                inst.CanQuery = false
                inst.Massless = true
                inst.CastShadow = false
                inst.Transparency = 1

                inst.CFrame = bone.CFrame
                inst.Parent = bone
                weldToBone(inst, bone)

                state.roots[node.id] = inst
            end
        else
            local parentNode = byId[node.parent]
            local parentInst = state.instances[node.parent]

            if inst:IsA("Attachment") and parentNode and parentNode.class == "Attachment" then
            
                local topNode = parentNode
                while topNode do
                    local up = byId[topNode.parent]
                    if not up or up.class ~= "Attachment" then break end
                    topNode = up
                end

              
                local partNode = topNode and byId[topNode.parent]
                if partNode and partNode.class ~= "Attachment" then
                    parentInst = state.instances[partNode.id]
                    state.lifted = (state.lifted or 0) + 1
                end
            end

            if parentInst then
                inst.Parent = parentInst
            end
        end
    end


    for _, link in ipairs(tree.links or {}) do
        local beam = state.instances[link[1]]
        local a0 = state.instances[link[2]]
        local a1 = state.instances[link[3]]
        if beam and a0 and a1 then
            local ok = pcall(function()
                beam.Attachment0 = a0
                beam.Attachment1 = a1
            end)
            if not ok then warn("[aura] link failed: " .. tostring(link[1])) end
        end
    end

    for _, node in ipairs(nodes) do
        local inst = state.instances[node.id]
        if inst and inst:IsA("Attachment") then
            local props = node.props or {}
            if props.CFrame then
                pcall(function() inst.CFrame = props.CFrame end)
            end
        end
    end

    state.loaded = true
    state.currentName = tree.name

    local live = 0
    for _, inst in pairs(state.instances) do
        if inst and inst.Parent then live = live + 1 end
    end
    local rootCount = 0
    for _ in pairs(state.roots) do rootCount = rootCount + 1 end

    print(("[aura] loaded: %s | nodes=%d | live=%d | roots=%d | lifted=%d"):format(
        tostring(tree.name), #nodes, live, rootCount, state.lifted or 0))

    if rootCount == 0 then
        warn("[aura] no root could be attached to a bone (check the character rig)")
    end

    return true
end

function AuraEngine.Unload()
    for _, inst in pairs(state.instances) do
        if inst and inst.Parent then pcall(function() inst:Destroy() end) end
    end
    for _, anchor in pairs(state.roots) do
        if anchor and anchor.Parent then pcall(function() anchor:Destroy() end) end
    end
    for _, c in pairs(state.connections) do
        pcall(function() c:Disconnect() end)
    end

    state.instances = {}
    state.baseValues = {}
    state.roots = {}
    state.connections = {}
    state.tree = nil
    state.loaded = false
    state.currentName = nil
end

function AuraEngine.IsLoaded() return state.loaded end
function AuraEngine.Current() return state.currentName end

function AuraEngine.GetInstances()
    local out = {}
    for _, inst in pairs(state.instances) do
        if inst and inst.Parent then out[#out + 1] = inst end
    end
    return out
end

function AuraEngine.GetBase(inst, prop)
    if not inst then return nil end
    local entry = state.baseValues[inst]
    if entry and entry[prop] ~= nil then return entry[prop] end
    local current = inst[prop]
    if type(current) == "table" and current.Min and current.Max then
        return { Min = current.Min, Max = current.Max }
    end
    if type(current) == "number" then return current end
    return nil
end

function AuraEngine.ScaleProp(inst, prop, factor)
    if not inst then return end
    local base = state.baseValues[inst]
    local original = base and base[prop]
    if original == nil then return end
    pcall(function() inst[prop] = original * factor end)
end

function AuraEngine.AutoLoad(tree)
    local function onChar(char)
        if not char then return end
        char:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.3)
        AuraEngine.Load(tree, char)
    end

    local player = Players.LocalPlayer
    if not player then return end
    if player.Character then onChar(player.Character) end

    local conn = player.CharacterAdded:Connect(onChar)
    state.connections[#state.connections + 1] = conn
end

local TREE = {
name = "angel",
nodes = {
{ id = 1, parent = 0, class = "Part", name = "Head", props = {
Size = Vector3.new(2, 1, 1),
Color = Color3.fromRGB(127, 127, 127),
Material = Enum.Material.Plastic,
Transparency = 1,
Reflectance = 0,
CastShadow = true,
Shape = Enum.PartType.Block,
Anchored = false,
CanCollide = true,
CanQuery = true,
CanTouch = true,
Massless = false,
CFrame = CFrame.new(158.375, -210.449, 49.5779, -1, 0, 0, 0, 1, 0, 0, 0, -1),
} },
{ id = 2, parent = 1, class = "Attachment", name = "Halo", props = {
CFrame = CFrame.new(-0.25, 0.933013, 0.25882, 0.965932, -0.249973, 0.0670034, 0.258797, 0.933026, -0.249973, -2.93739e-05, 0.258797, 0.965932),
Visible = false,
} },
{ id = 3, parent = 2, class = "ParticleEmitter", name = "Ring2", props = {
Acceleration = Vector3.new(0, 0, 0),
Brightness = 2,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
Drag = 0,
EmissionDirection = Enum.NormalId.Top,
Enabled = true,
FlipbookFramerate = NumberRange.new(1, 1),
FlipbookLayout = Enum.ParticleFlipbookLayout.None,
FlipbookMode = Enum.ParticleFlipbookMode.Loop,
FlipbookStartRandom = false,
Lifetime = NumberRange.new(1, 1),
LightEmission = 1,
LightInfluence = 0,
LockedToPart = true,
Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
Rate = 7,
RotSpeed = NumberRange.new(-400, 400),
Rotation = NumberRange.new(0, 360),
Shape = Enum.ParticleEmitterShape.Box,
ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
ShapePartial = 1,
ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2, 0), NumberSequenceKeypoint.new(1, 3, 0) }),
SpreadAngle = Vector2.new(5, 5),
Speed = NumberRange.new(0.001, 0.001),
Squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }),
Texture = "rbxassetid://8819682608",
TimeScale = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.2, 0, 0), NumberSequenceKeypoint.new(0.8, 0, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
VelocityInheritance = 0,
VelocitySpread = 5,
WindAffectsDrag = false,
ZOffset = 0,
} },
{ id = 4, parent = 2, class = "ParticleEmitter", name = "Ring1", props = {
Acceleration = Vector3.new(0, 0, 0),
Brightness = 2,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
Drag = 0,
EmissionDirection = Enum.NormalId.Top,
Enabled = true,
FlipbookFramerate = NumberRange.new(1, 1),
FlipbookLayout = Enum.ParticleFlipbookLayout.None,
FlipbookMode = Enum.ParticleFlipbookMode.Loop,
FlipbookStartRandom = false,
Lifetime = NumberRange.new(1, 1),
LightEmission = 1,
LightInfluence = 0,
LockedToPart = true,
Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
Rate = 7,
RotSpeed = NumberRange.new(-400, 400),
Rotation = NumberRange.new(0, 360),
Shape = Enum.ParticleEmitterShape.Box,
ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
ShapePartial = 1,
ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5, 0), NumberSequenceKeypoint.new(1, 3, 0) }),
SpreadAngle = Vector2.new(5, 5),
Speed = NumberRange.new(0.001, 0.001),
Squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }),
Texture = "rbxassetid://8819682608",
TimeScale = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.2, 0, 0), NumberSequenceKeypoint.new(0.8, 0, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
VelocityInheritance = 0,
VelocitySpread = 5,
WindAffectsDrag = false,
ZOffset = 0,
} },
{ id = 5, parent = 0, class = "Part", name = "RightUpperArm", props = {
Size = Vector3.new(1, 2, 1),
Color = Color3.fromRGB(127, 127, 127),
Material = Enum.Material.Plastic,
Transparency = 1,
Reflectance = 0,
CastShadow = true,
Shape = Enum.PartType.Block,
Anchored = false,
CanCollide = false,
CanQuery = true,
CanTouch = true,
Massless = false,
CFrame = CFrame.new(156.875, -211.949, 49.5779, -1, 0, 0, 0, 1, 0, 0, 0, -1),
} },
{ id = 6, parent = 5, class = "Attachment", name = "Beam1", props = {
CFrame = CFrame.new(0.5, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, 0),
Visible = false,
} },
{ id = 7, parent = 6, class = "Beam", name = "Beam", props = {
Brightness = 10,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
CurveSize0 = 0,
CurveSize1 = 0,
Enabled = true,
FaceCamera = false,
LightEmission = 1,
LightInfluence = 0,
Segments = 10,
Texture = "http://www.roblox.com/asset/?id=5059527230",
TextureLength = 0.1,
TextureMode = Enum.TextureMode.Stretch,
TextureSpeed = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.9, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
Width0 = 2,
Width1 = 2,
ZOffset = 0.1,
} },
{ id = 8, parent = 6, class = "Attachment", name = "Attachment", props = {
CFrame = CFrame.new(0, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 9, parent = 5, class = "Attachment", name = "Beam3", props = {
CFrame = CFrame.new(0, -1, -0.5, 0, -1, 0, 0, 0, 1, -1, 0, 0),
Visible = false,
} },
{ id = 10, parent = 9, class = "Beam", name = "Beam", props = {
Brightness = 10,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
CurveSize0 = 0,
CurveSize1 = 0,
Enabled = true,
FaceCamera = false,
LightEmission = 1,
LightInfluence = 0,
Segments = 10,
Texture = "http://www.roblox.com/asset/?id=5059527230",
TextureLength = 0.1,
TextureMode = Enum.TextureMode.Stretch,
TextureSpeed = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.9, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
Width0 = 2,
Width1 = 2,
ZOffset = 0.1,
} },
{ id = 11, parent = 9, class = "Attachment", name = "Attachment", props = {
CFrame = CFrame.new(0, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 12, parent = 5, class = "Attachment", name = "Beam2", props = {
CFrame = CFrame.new(-0.5, -1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
Visible = false,
} },
{ id = 13, parent = 12, class = "Beam", name = "Beam", props = {
Brightness = 10,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
CurveSize0 = 0,
CurveSize1 = 0,
Enabled = true,
FaceCamera = false,
LightEmission = 1,
LightInfluence = 0,
Segments = 10,
Texture = "http://www.roblox.com/asset/?id=5059527230",
TextureLength = 0.1,
TextureMode = Enum.TextureMode.Stretch,
TextureSpeed = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.9, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
Width0 = 2,
Width1 = 2,
ZOffset = 0.1,
} },
{ id = 14, parent = 12, class = "Attachment", name = "Attachment", props = {
CFrame = CFrame.new(0, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 15, parent = 5, class = "Attachment", name = "Beam4", props = {
CFrame = CFrame.new(0, -1, 0.5, 0, 1, 0, 0, 0, 1, 1, 0, 0),
Visible = false,
} },
{ id = 16, parent = 15, class = "Attachment", name = "Attachment", props = {
CFrame = CFrame.new(0, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 17, parent = 15, class = "Beam", name = "Beam", props = {
Brightness = 10,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
CurveSize0 = 0,
CurveSize1 = 0,
Enabled = true,
FaceCamera = false,
LightEmission = 1,
LightInfluence = 0,
Segments = 10,
Texture = "http://www.roblox.com/asset/?id=5059527230",
TextureLength = 0.1,
TextureMode = Enum.TextureMode.Stretch,
TextureSpeed = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.9, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
Width0 = 2,
Width1 = 2,
ZOffset = 0.1,
} },
{ id = 18, parent = 0, class = "Part", name = "UpperTorso", props = {
Size = Vector3.new(2, 2, 1),
Color = Color3.fromRGB(127, 127, 127),
Material = Enum.Material.Plastic,
Transparency = 1,
Reflectance = 0,
CastShadow = true,
Shape = Enum.PartType.Block,
Anchored = false,
CanCollide = true,
CanQuery = true,
CanTouch = true,
Massless = false,
CFrame = CFrame.new(158.375, -211.949, 49.5779, -1, 0, 0, 0, 1, 0, 0, 0, -1),
} },
{ id = 19, parent = 18, class = "Attachment", name = "Center", props = {
CFrame = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 20, parent = 19, class = "ParticleEmitter", name = "Ambient", props = {
Acceleration = Vector3.new(0, 0, 0),
Brightness = 2,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
Drag = 0,
EmissionDirection = Enum.NormalId.Top,
Enabled = true,
FlipbookFramerate = NumberRange.new(1, 1),
FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
FlipbookStartRandom = false,
Lifetime = NumberRange.new(2, 2),
LightEmission = 1,
LightInfluence = 0,
LockedToPart = true,
Orientation = Enum.ParticleOrientation.FacingCamera,
Rate = 5,
RotSpeed = NumberRange.new(0, 0),
Rotation = NumberRange.new(0, 360),
Shape = Enum.ParticleEmitterShape.Box,
ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
ShapePartial = 1,
ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3, 0), NumberSequenceKeypoint.new(1, 4, 0) }),
SpreadAngle = Vector2.new(180, 180),
Speed = NumberRange.new(0.5, 0.5),
Squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }),
Texture = "rbxassetid://11402221943",
TimeScale = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.3, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
VelocityInheritance = 0,
VelocitySpread = 180,
WindAffectsDrag = false,
ZOffset = 0,
} },
{ id = 21, parent = 18, class = "Attachment", name = "LeftWing", props = {
CFrame = CFrame.new(-2, 0.5, 1, 0.96593, 0, 0.258805, 0, 1, -0, -0.258805, 0, 0.96593),
Visible = false,
} },
{ id = 22, parent = 21, class = "ParticleEmitter", name = "Wing", props = {
Acceleration = Vector3.new(0, 0, 0),
Brightness = 1,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
Drag = 0,
EmissionDirection = Enum.NormalId.Back,
Enabled = true,
FlipbookFramerate = NumberRange.new(1, 1),
FlipbookLayout = Enum.ParticleFlipbookLayout.None,
FlipbookMode = Enum.ParticleFlipbookMode.Loop,
FlipbookStartRandom = false,
Lifetime = NumberRange.new(1, 1),
LightEmission = 1,
LightInfluence = 0,
LockedToPart = true,
Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
Rate = 4,
RotSpeed = NumberRange.new(0, 0),
Rotation = NumberRange.new(-15, -15),
Shape = Enum.ParticleEmitterShape.Box,
ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
ShapePartial = 1,
ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.75, 0), NumberSequenceKeypoint.new(1, 3.5, 0) }),
SpreadAngle = Vector2.new(0, 0),
Speed = NumberRange.new(0.05, 0.05),
Squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }),
Texture = "http://www.roblox.com/asset/?id=13267054240",
TimeScale = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.944444, 0), NumberSequenceKeypoint.new(0.2, 0, 0), NumberSequenceKeypoint.new(0.8, 0, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
VelocityInheritance = 0,
VelocitySpread = 0,
WindAffectsDrag = false,
ZOffset = 0,
} },
{ id = 23, parent = 18, class = "Attachment", name = "RightWing", props = {
CFrame = CFrame.new(2, 0.5, 1, 0.96593, 0, -0.258805, 0, 1, 0, 0.258805, 0, 0.96593),
Visible = false,
} },
{ id = 24, parent = 23, class = "ParticleEmitter", name = "Wing", props = {
Acceleration = Vector3.new(0, 0, 0),
Brightness = 1,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
Drag = 0,
EmissionDirection = Enum.NormalId.Front,
Enabled = true,
FlipbookFramerate = NumberRange.new(1, 1),
FlipbookLayout = Enum.ParticleFlipbookLayout.None,
FlipbookMode = Enum.ParticleFlipbookMode.Loop,
FlipbookStartRandom = false,
Lifetime = NumberRange.new(1, 1),
LightEmission = 1,
LightInfluence = 0,
LockedToPart = true,
Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
Rate = 4,
RotSpeed = NumberRange.new(0, 0),
Rotation = NumberRange.new(-15, -15),
Shape = Enum.ParticleEmitterShape.Box,
ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
ShapePartial = 1,
ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.75, 0), NumberSequenceKeypoint.new(1, 3.5, 0) }),
SpreadAngle = Vector2.new(0, 0),
Speed = NumberRange.new(0.05, 0.05),
Squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }),
Texture = "http://www.roblox.com/asset/?id=13267054240",
TimeScale = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.944444, 0), NumberSequenceKeypoint.new(0.2, 0, 0), NumberSequenceKeypoint.new(0.8, 0, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
VelocityInheritance = 0,
VelocitySpread = 0,
WindAffectsDrag = false,
ZOffset = 0,
} },
{ id = 25, parent = 0, class = "Part", name = "LeftUpperArm", props = {
Size = Vector3.new(1, 2, 1),
Color = Color3.fromRGB(127, 127, 127),
Material = Enum.Material.Plastic,
Transparency = 1,
Reflectance = 0,
CastShadow = true,
Shape = Enum.PartType.Block,
Anchored = false,
CanCollide = false,
CanQuery = true,
CanTouch = true,
Massless = false,
CFrame = CFrame.new(159.875, -211.949, 49.5779, -1, 0, 0, 0, 1, 0, 0, 0, -1),
} },
{ id = 26, parent = 25, class = "Attachment", name = "Beam3", props = {
CFrame = CFrame.new(0, -1, -0.5, 0, -1, 0, 0, 0, 1, -1, 0, 0),
Visible = false,
} },
{ id = 27, parent = 26, class = "Attachment", name = "Attachment", props = {
CFrame = CFrame.new(0, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 28, parent = 26, class = "Beam", name = "Beam", props = {
Brightness = 10,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
CurveSize0 = 0,
CurveSize1 = 0,
Enabled = true,
FaceCamera = false,
LightEmission = 1,
LightInfluence = 0,
Segments = 10,
Texture = "http://www.roblox.com/asset/?id=5059527230",
TextureLength = 0.1,
TextureMode = Enum.TextureMode.Stretch,
TextureSpeed = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.9, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
Width0 = 2,
Width1 = 2,
ZOffset = 0.1,
} },
{ id = 29, parent = 25, class = "Attachment", name = "Beam4", props = {
CFrame = CFrame.new(0, -1, 0.5, 0, 1, 0, 0, 0, 1, 1, 0, 0),
Visible = false,
} },
{ id = 30, parent = 29, class = "Beam", name = "Beam", props = {
Brightness = 10,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
CurveSize0 = 0,
CurveSize1 = 0,
Enabled = true,
FaceCamera = false,
LightEmission = 1,
LightInfluence = 0,
Segments = 10,
Texture = "http://www.roblox.com/asset/?id=5059527230",
TextureLength = 0.1,
TextureMode = Enum.TextureMode.Stretch,
TextureSpeed = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.9, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
Width0 = 2,
Width1 = 2,
ZOffset = 0.1,
} },
{ id = 31, parent = 29, class = "Attachment", name = "Attachment", props = {
CFrame = CFrame.new(0, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 32, parent = 25, class = "Attachment", name = "Beam2", props = {
CFrame = CFrame.new(-0.5, -1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
Visible = false,
} },
{ id = 33, parent = 32, class = "Attachment", name = "Attachment", props = {
CFrame = CFrame.new(0, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 34, parent = 32, class = "Beam", name = "Beam", props = {
Brightness = 10,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
CurveSize0 = 0,
CurveSize1 = 0,
Enabled = true,
FaceCamera = false,
LightEmission = 1,
LightInfluence = 0,
Segments = 10,
Texture = "http://www.roblox.com/asset/?id=5059527230",
TextureLength = 0.1,
TextureMode = Enum.TextureMode.Stretch,
TextureSpeed = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.9, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
Width0 = 2,
Width1 = 2,
ZOffset = 0.1,
} },
{ id = 35, parent = 25, class = "Attachment", name = "Beam1", props = {
CFrame = CFrame.new(0.5, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, 0),
Visible = false,
} },
{ id = 36, parent = 35, class = "Beam", name = "Beam", props = {
Brightness = 10,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
CurveSize0 = 0,
CurveSize1 = 0,
Enabled = true,
FaceCamera = false,
LightEmission = 1,
LightInfluence = 0,
Segments = 10,
Texture = "http://www.roblox.com/asset/?id=5059527230",
TextureLength = 0.1,
TextureMode = Enum.TextureMode.Stretch,
TextureSpeed = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.9, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
Width0 = 2,
Width1 = 2,
ZOffset = 0.1,
} },
{ id = 37, parent = 35, class = "Attachment", name = "Attachment", props = {
CFrame = CFrame.new(0, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 38, parent = 0, class = "Part", name = "RightUpperLeg", props = {
Size = Vector3.new(1, 2, 1),
Color = Color3.fromRGB(127, 127, 127),
Material = Enum.Material.Plastic,
Transparency = 1,
Reflectance = 0,
CastShadow = true,
Shape = Enum.PartType.Block,
Anchored = false,
CanCollide = false,
CanQuery = true,
CanTouch = true,
Massless = false,
CFrame = CFrame.new(157.875, -213.949, 49.5779, -1, 0, 0, 0, 1, 0, 0, 0, -1),
} },
{ id = 39, parent = 0, class = "Part", name = "HumanoidRootPart", props = {
Size = Vector3.new(2, 2, 1),
Color = Color3.fromRGB(163, 162, 165),
Material = Enum.Material.Plastic,
Transparency = 1,
Reflectance = 0,
CastShadow = true,
Shape = Enum.PartType.Block,
Anchored = false,
CanCollide = false,
CanQuery = true,
CanTouch = true,
Massless = false,
CFrame = CFrame.new(158.375, -211.949, 49.5779, -1, 0, 0, 0, 1, 0, 0, 0, -1),
} },
{ id = 40, parent = 39, class = "Attachment", name = "Floor", props = {
CFrame = CFrame.new(0, -2.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
Visible = false,
} },
{ id = 41, parent = 40, class = "ParticleEmitter", name = "Ambient1", props = {
Acceleration = Vector3.new(0, 0, 0),
Brightness = 2,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
Drag = 0,
EmissionDirection = Enum.NormalId.Top,
Enabled = true,
FlipbookFramerate = NumberRange.new(1, 1),
FlipbookLayout = Enum.ParticleFlipbookLayout.None,
FlipbookMode = Enum.ParticleFlipbookMode.Loop,
FlipbookStartRandom = false,
Lifetime = NumberRange.new(2, 2),
LightEmission = 1,
LightInfluence = 0,
LockedToPart = true,
Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
Rate = 20,
RotSpeed = NumberRange.new(-40, 40),
Rotation = NumberRange.new(0, 360),
Shape = Enum.ParticleEmitterShape.Box,
ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
ShapePartial = 1,
ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.3, 2, 0), NumberSequenceKeypoint.new(0.6, 5, 0), NumberSequenceKeypoint.new(0.8, 8, 0), NumberSequenceKeypoint.new(1, 12, 0) }),
SpreadAngle = Vector2.new(0.001, 0.001),
Speed = NumberRange.new(0.001, 0.001),
Squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0.2) }),
Texture = "rbxassetid://7216855136",
TimeScale = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.2, 0.3, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
VelocityInheritance = 0,
VelocitySpread = 0.001,
WindAffectsDrag = false,
ZOffset = 0,
} },
{ id = 42, parent = 40, class = "ParticleEmitter", name = "Ambient2", props = {
Acceleration = Vector3.new(0, 0, 0),
Brightness = 2,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
Drag = 0,
EmissionDirection = Enum.NormalId.Top,
Enabled = true,
FlipbookFramerate = NumberRange.new(1, 1),
FlipbookLayout = Enum.ParticleFlipbookLayout.None,
FlipbookMode = Enum.ParticleFlipbookMode.Loop,
FlipbookStartRandom = false,
Lifetime = NumberRange.new(2, 2),
LightEmission = 1,
LightInfluence = 0,
LockedToPart = true,
Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
Rate = 20,
RotSpeed = NumberRange.new(-600, 600),
Rotation = NumberRange.new(0, 360),
Shape = Enum.ParticleEmitterShape.Box,
ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
ShapePartial = 1,
ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.3, 1, 0), NumberSequenceKeypoint.new(0.6, 2.5, 0), NumberSequenceKeypoint.new(0.8, 4, 0), NumberSequenceKeypoint.new(1, 6, 0) }),
SpreadAngle = Vector2.new(0.001, 0.001),
Speed = NumberRange.new(0.001, 0.001),
Squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0.2) }),
Texture = "https://assetgame.roblox.com/asset/?id=12713358087&assetName=crescent",
TimeScale = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
VelocityInheritance = 0,
VelocitySpread = 0.001,
WindAffectsDrag = false,
ZOffset = 0,
} },
{ id = 43, parent = 40, class = "ParticleEmitter", name = "Stars", props = {
Acceleration = Vector3.new(0, 0, 0),
Brightness = 2,
Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(133, 220, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 220, 255)) }),
Drag = 0,
EmissionDirection = Enum.NormalId.Top,
Enabled = true,
FlipbookFramerate = NumberRange.new(1, 1),
FlipbookLayout = Enum.ParticleFlipbookLayout.None,
FlipbookMode = Enum.ParticleFlipbookMode.Loop,
FlipbookStartRandom = false,
Lifetime = NumberRange.new(2, 2),
LightEmission = 1,
LightInfluence = 0,
LockedToPart = true,
Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
Rate = 20,
RotSpeed = NumberRange.new(-30, 30),
Rotation = NumberRange.new(0, 360),
Shape = Enum.ParticleEmitterShape.Box,
ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
ShapePartial = 1,
ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.3, 1, 0), NumberSequenceKeypoint.new(0.6, 2.5, 0), NumberSequenceKeypoint.new(0.8, 4, 0), NumberSequenceKeypoint.new(1, 6, 0) }),
SpreadAngle = Vector2.new(0.001, 0.001),
Speed = NumberRange.new(0.001, 0.001),
Squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 2, 0) }),
Texture = "rbxassetid://7216849325",
TimeScale = 1,
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.6, 0.2, 0), NumberSequenceKeypoint.new(1, 1, 0) }),
VelocityInheritance = 0,
VelocitySpread = 0.001,
WindAffectsDrag = false,
ZOffset = 0,
} },
{ id = 44, parent = 0, class = "Part", name = "LeftUpperLeg", props = {
Size = Vector3.new(1, 2, 1),
Color = Color3.fromRGB(127, 127, 127),
Material = Enum.Material.Plastic,
Transparency = 1,
Reflectance = 0,
CastShadow = true,
Shape = Enum.PartType.Block,
Anchored = false,
CanCollide = false,
CanQuery = true,
CanTouch = true,
Massless = false,
CFrame = CFrame.new(158.875, -213.949, 49.5779, -1, 0, 0, 0, 1, 0, 0, 0, -1),
} },
},
links = {
{ 7, 6, 8 },
{ 10, 9, 11 },
{ 13, 12, 14 },
{ 17, 15, 16 },
{ 28, 26, 27 },
{ 30, 29, 31 },
{ 34, 32, 33 },
{ 36, 35, 37 },
},
}



local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then
    warn("[angel] LocalPlayer unavailable; run this from a client context")
    return
end

local function applyToCharacter(character)
    if not character then return end
    character:WaitForChild("HumanoidRootPart", 10)
    task.wait(0.25)
    local ok, result = pcall(function()
        return AuraEngine.Load(TREE, character)
    end)
    if not ok then
        warn("[angel] load error: " .. tostring(result))
    elseif result then
        print("[angel] Angel Aura loaded")
    else
        warn("[angel] AuraEngine.Load returned false; check rig/root diagnostics above")
    end
end

if player.Character then
    applyToCharacter(player.Character)
else
    applyToCharacter(player.CharacterAdded:Wait())
end

player.CharacterAdded:Connect(function(character)
    applyToCharacter(character)
end)
]=]
    local ok, err = pcall(function()
        local fn = loadstring(src)
        if fn then fn() end
    end)
    if ok then
        print("[Spray] Angel Aura on")
    else
        warn("[Spray] aura:", err)
        auraLoaded = false
    end
end


-- ===== STRETCHED SCREEN (1080x1080 / aspect letterbox) =====
local stretchGui = nil
local stretchBars = {}
local function destroyStretch()
    if stretchGui then
        pcall(function() stretchGui:Destroy() end)
        stretchGui = nil
        stretchBars = {}
    end
end

local function ensureStretchGui()
    if stretchGui and stretchGui.Parent then return stretchGui end
    destroyStretch()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    stretchGui = Instance.new("ScreenGui")
    stretchGui.Name = "SprayStretch"
    stretchGui.IgnoreGuiInset = true
    stretchGui.DisplayOrder = 99999
    stretchGui.ResetOnSpawn = false
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(stretchGui) end
    end)
    local ok = pcall(function()
        stretchGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not ok then stretchGui.Parent = pg end
    return stretchGui
end

local function aspectForMode(mode)
    if mode == "1080x1080" then return 1 end
    if mode == "4:3" then return 4/3 end
    if mode == "16:10" then return 16/10 end
    return 1
end

local function layoutStretch()
    if not F.StretchOn then
        destroyStretch()
        return
    end
    local gui = ensureStretchGui()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vs = cam.ViewportSize
    local targetAspect = aspectForMode(F.StretchMode or "1080x1080")
    local screenAspect = vs.X / math.max(vs.Y, 1)

    for _, b in ipairs(stretchBars) do
        pcall(function() b:Destroy() end)
    end
    stretchBars = {}

    local function bar(props)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = Color3.new(0, 0, 0)
        f.BorderSizePixel = 0
        f.ZIndex = 100
        for k, v in pairs(props) do f[k] = v end
        f.Parent = gui
        table.insert(stretchBars, f)
        return f
    end

    if screenAspect > targetAspect then
        -- too wide: bars left/right
        local contentW = vs.Y * targetAspect
        local side = math.max(0, (vs.X - contentW) / 2)
        bar({ Size = UDim2.fromOffset(side, vs.Y), Position = UDim2.fromOffset(0, 0) })
        bar({ Size = UDim2.fromOffset(side, vs.Y), Position = UDim2.fromOffset(vs.X - side, 0) })
    else
        -- too tall: bars top/bottom
        local contentH = vs.X / targetAspect
        local side = math.max(0, (vs.Y - contentH) / 2)
        bar({ Size = UDim2.fromOffset(vs.X, side), Position = UDim2.fromOffset(0, 0) })
        bar({ Size = UDim2.fromOffset(vs.X, side), Position = UDim2.fromOffset(0, vs.Y - side) })
    end
end

local stretchConn
local function bindStretch()
    if stretchConn then stretchConn:Disconnect() stretchConn = nil end
    if not F.StretchOn then
        destroyStretch()
        return
    end
    layoutStretch()
    stretchConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutStretch)
end

RunService.Heartbeat:Connect(function()
    if F.ACBypass and not acLoaded then
        loadAC()
    end
    if F.SkinUnlock and not skinLoaded then
        loadSkin()
    end
    if F.AngelAura and not auraLoaded then
        loadAura()
    end

    if F.NoHands ~= lastNoHands then
        lastNoHands = F.NoHands
        applyNoHands(F.NoHands == true)
    end

    if F.StretchOn ~= lastStretch or F.StretchMode ~= lastStretchMode then
        lastStretch = F.StretchOn
        lastStretchMode = F.StretchMode
        bindStretch()
    end

    -- skybox live apply
    if F.SkyOn then
        if F.SkyName ~= lastSky or lastSkyOn ~= true then
            lastSky = F.SkyName
            lastSkyOn = true
            applySkybox(F.SkyName or "Afternoon")
        end
    elseif lastSkyOn then
        lastSkyOn = false
        applySkybox("Default")
    end

    -- stretched screen
    if F.StretchOn then
        if not stretchGui or not stretchGui.Parent then
            bindStretch()
        end
        pcall(function()
            local cam = workspace.CurrentCamera
            if not cam then return end
            local base = (F.FovOn and (F.FovVal or 80)) or 70
            local boost = F.StretchFov or 15
            cam.FieldOfView = base + boost
        end)
    else
        if stretchGui then
            destroyStretch()
        end
        if F.FovOn then
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam then cam.FieldOfView = F.FovVal or 80 end
            end)
        end
    end
    if F.Fullbright then
        pcall(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 1e5
        end)
    end
    if F.SpeedOn then
        local c = getChar()
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = F.SpeedVal or 24 end
        end
    end
    if F.Noclip then
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
    if F.CCOn then
        pcall(function()
            local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
            if not cc then
                cc = Instance.new("ColorCorrectionEffect")
                cc.Parent = Lighting
            end
            cc.Enabled = true
            cc.Saturation = F.CCSat or 0
            cc.Contrast = F.CCCon or 0
            cc.Brightness = F.CCBright or 0
        end)
    end
end)

print("[Spray] v1.1 ready | RightShift")
