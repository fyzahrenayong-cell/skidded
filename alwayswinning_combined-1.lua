--!nocheck
-- Always.winning Combined
-- Silent + Melee  = Sleepy path
-- Void / Orbit / Bypasses / Magic Bullet = MeowLua path
-- UI = Always.winning custom 480px + logo toggle

if getgenv().AlwaysWinning and getgenv().AlwaysWinning.Unload then
    pcall(getgenv().AlwaysWinning.Unload)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local flags = {
    -- Sleepy silent / melee
    silent_aim_enabled = false,
    hit_chance = 100,
    fov_radius = 400,
    show_fov = false,
    target_hitbox = "Head",
    target_priority = "Closest",
    riot_shield_check = false,
    avoid_katana = false,
    knife_rage = false,
    melee_safe_reach = 12,
    melee_auto_face_back = true,
    -- MeowLua void
    void_spam_enabled = false,
    void_pattern = "random",
    void_interval = 0.016,
    void_burst = 5,
    void_range = 2500,
    void_axis_x = true,
    void_axis_y = true,
    void_axis_z = true,
    -- MeowLua orbit
    orbit_enabled = false,
    orbit_radius = 8,
    orbit_speed = 90,
    orbit_height = 0,
    -- Bypasses
    dagger_bypass_enabled = false,
    melee_bypass_enabled = false,
    melee_bypass_y_range = 10,
    -- Magic bullet
    magic_bullet_enabled = false,
    magic_bullet_hitchance = 100,
    magic_bullet_closest = true,
    -- Aimbot
    aimbot_enabled = false,
    aimbot_smoothing = 8,
    aimbot_fov = 400,
    aimbot_show_fov = false,
    aimbot_use_shared_target = true,
    -- Ragebot
    ragebot_enabled = false,
    ragebot_interval = 0.15,
    ragebot_require_silent = true,
    ragebot_auto_shoot = true,
    -- Fake pos (Sleepy-style)
    fake_pos_enabled = false,
    fake_pos_depth = 5.8,
}

local state = {
    destroyed = false,
    target = nil,
    lastMelee = 0,
    lastRage = 0,
    orbAngle = 0,
    menuOpen = true,
    virtualCF = nil,
    originalParts = nil,
    voidAcc = 0,
    voidPhase = 0,
}

local conns, drawings = {}, {}
local function track(c) conns[#conns+1] = c; return c end

local function getHrp(char)
    char = char or LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function hitboxPart(char)
    local mode = flags.target_hitbox
    if mode == "HumanoidRootPart" or mode == "Torso" then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    elseif mode == "Random" then
        local n = {"Head","HumanoidRootPart","UpperTorso"}
        return char:FindFirstChild(n[math.random(1,#n)]) or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function is_deflecting(char)
    local k = char and char:FindFirstChild("Katana")
    return k and k:FindFirstChild("Deflecting") and k.Deflecting.Value == true
end

local function shield_blocks(root, fromPos)
    if not root then return false end
    local sh = root.Parent and (root.Parent:FindFirstChild("Riot Shield") or root.Parent:FindFirstChild("Shield"))
    if not sh then return false end
    return root.CFrame.LookVector:Dot((fromPos - root.Position).Unit) < -0.2
end

local function getClosest()
    local my = getHrp()
    if not my then return nil end
    local best, bestD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local r, h = getHrp(p.Character), p.Character:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local d = (my.Position - r.Position).Magnitude
                if d < bestD then bestD, best = d, p end
            end
        end
    end
    return best
end

-- ========== SLEEPY: get_target + silent + melee ==========
local function get_target()
    local myRoot = getHrp()
    if not myRoot then state.target = nil; return nil end
    local center = Camera.ViewportSize * 0.5
    local best, bestScore = nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local char = pl.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = getHrp(char)
            local part = hitboxPart(char)
            if hum and hum.Health > 0 and root and part and not char:FindFirstChildOfClass("ForceField") then
                if not (flags.riot_shield_check and shield_blocks(root, myRoot.Position)) then
                    if not (flags.avoid_katana and is_deflecting(char)) then
                        local sp, on = Camera:WorldToViewportPoint(part.Position)
                        if on and sp.Z > 0 then
                            local fovDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if fovDist <= flags.fov_radius then
                                local score = fovDist
                                if flags.target_priority == "Lowest Health" then score = hum.Health
                                elseif flags.target_priority == "Distance" then score = (root.Position - myRoot.Position).Magnitude
                                end
                                if score < bestScore then
                                    bestScore = score
                                    best = { Player = pl, Character = char, HitPart = part, Root = root }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    state.target = best
    return best
end

pcall(function()
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return end
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if flags.silent_aim_enabled and (not checkcaller or not checkcaller()) then
            if (method == "Raycast" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay") and self == Workspace then
                local origin = args[1]
                if flags.fake_pos_enabled and state.virtualCF then
                    origin = state.virtualCF.Position
                    args[1] = origin
                end
                local t = state.target
                if t and t.HitPart and math.random(1,100) <= flags.hit_chance then
                    args[2] = (t.HitPart.Position - origin).Unit * 1000
                    return old(self, table.unpack(args))
                end
            end
        end
        return old(self, ...)
    end)
end)

local function runMeleeAura()
    if not flags.knife_rage then return end
    local my = LocalPlayer.Character
    local myRoot = getHrp(my)
    if not myRoot then return end
    local now = os.clock()
    if now - state.lastMelee < 0.12 then return end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local root = getHrp(pl.Character)
            local hum = pl.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 and (root.Position - myRoot.Position).Magnitude <= flags.melee_safe_reach then
                state.lastMelee = now
                pcall(function()
                    if flags.melee_auto_face_back then
                        myRoot.CFrame = CFrame.new(myRoot.Position, myRoot.Position - root.CFrame.LookVector)
                    end
                    local tool = my:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end)
                break
            end
        end
    end
end

-- ========== MEOWLUA: dagger bypass ==========
pcall(function()
    if type(hookfunction) ~= "function" then return end
    local oldFire
    local detour = function(self, ...)
        if flags.dagger_bypass_enabled and (not checkcaller or not checkcaller()) then
            local n = tostring(self.Name):lower()
            if n:find("dagger") or n:find("knife") or n:find("blade") or n:find("throw") then
                return
            end
        end
        return oldFire(self, ...)
    end
    if newcclosure then detour = newcclosure(detour) end
    oldFire = hookfunction(Instance.new("RemoteEvent").FireServer, detour)
end)

-- ========== MEOWLUA: magic bullet (ray redirect) ==========
local mb_hook
local function mb_acquire()
    local center = Camera.ViewportSize * 0.5
    local best, bestD = nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local hum = pl.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local part
                if flags.magic_bullet_closest then
                    local camPos = Camera.CFrame.Position
                    local bestP, bestPD = nil, math.huge
                    for _, bp in ipairs(pl.Character:GetChildren()) do
                        if bp:IsA("BasePart") then
                            local d = (bp.Position - camPos).Magnitude
                            if d < bestPD then bestPD, bestP = d, bp end
                        end
                    end
                    part = bestP
                else
                    part = pl.Character:FindFirstChild("Head") or getHrp(pl.Character)
                end
                if part then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bestD then bestD, best = d, part end
                    end
                end
            end
        end
    end
    return best
end

local function mb_set(on)
    flags.magic_bullet_enabled = on
    if on then
        if mb_hook or type(hookfunction) ~= "function" then return end
        local orig = Workspace.Raycast
        mb_hook = newcclosure and newcclosure(function(ws, origin, direction, params)
            if flags.magic_bullet_enabled and math.random(1,100) <= flags.magic_bullet_hitchance then
                local t = mb_acquire()
                if t then
                    local dir = (t.Position - origin)
                    return orig(ws, origin, dir.Unit * direction.Magnitude, params)
                end
            end
            return orig(ws, origin, direction, params)
        end) or function(ws, origin, direction, params)
            if flags.magic_bullet_enabled then
                local t = mb_acquire()
                if t then return orig(ws, origin, (t.Position - origin).Unit * direction.Magnitude, params) end
            end
            return orig(ws, origin, direction, params)
        end
        pcall(hookfunction, Workspace.Raycast, mb_hook)
    end
end

-- ========== MEOWLUA: void spam ==========
local function voidDelta()
    local R = flags.void_range or 2500
    local ax = flags.void_axis_x and 1 or 0
    local ay = flags.void_axis_y and 1 or 0
    local az = flags.void_axis_z and 1 or 0
    local p = flags.void_pattern
    state.voidPhase = state.voidPhase + 0.35
    local t = state.voidPhase
    if p == "spiral" then
        return Vector3.new(ax*math.cos(t)*R, ay*math.sin(t*0.6)*R*0.4, az*math.sin(t)*R)
    elseif p == "wave" then
        local w = tick() * 8
        return Vector3.new(ax*math.sin(w)*R, ay*math.sin(w*1.7)*R*0.5, az*math.cos(w)*R)
    elseif p == "helix" then
        return Vector3.new(ax*math.cos(t*2)*R, ay*math.sin(t)*R*0.15, az*math.sin(t*2)*R)
    elseif p == "chaos" then
        return Vector3.new(ax*(math.random()-0.5)*2*R, ay*(math.random()-0.5)*R, az*(math.random()-0.5)*2*R)
    else
        return Vector3.new(ax*(math.random()-0.5)*2*R, ay*(math.random()-0.5)*R, az*(math.random()-0.5)*2*R)
    end
end

-- ========== Fake pos ==========
local function setFake(on)
    flags.fake_pos_enabled = on
    local hrp = getHrp()
    if on then
        if hrp then state.virtualCF = hrp.CFrame end
        local char = LocalPlayer.Character
        if char then
            state.originalParts = {}
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") or p:IsA("Decal") then
                    table.insert(state.originalParts, {p=p, t=p.Transparency})
                    p.Transparency = 1
                end
            end
        end
    else
        if state.originalParts then
            for _, d in ipairs(state.originalParts) do
                if d.p and d.p.Parent then d.p.Transparency = d.t end
            end
            state.originalParts = nil
        end
        if hrp and state.virtualCF then
            hrp.CFrame = state.virtualCF
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
        state.virtualCF = nil
    end
end



-- ========== AIMBOT (camera lock) ==========
local function runAimbot(dt)
    if not flags.aimbot_enabled then return end
    local t = state.target
    if flags.aimbot_use_shared_target then
        if not t or not t.HitPart then return end
    else
        -- independent FOV pick
        local myRoot = getHrp()
        if not myRoot then return end
        local center = Camera.ViewportSize * 0.5
        local best, bestScore = nil, math.huge
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character then
                local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                local part = hitboxPart(pl.Character)
                if hum and hum.Health > 0 and part then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d <= (flags.aimbot_fov or 400) and d < bestScore then
                            bestScore = d
                            best = part
                        end
                    end
                end
            end
        end
        if not best then return end
        t = { HitPart = best }
    end
    local part = t.HitPart
    if not part then return end
    local goal = CFrame.new(Camera.CFrame.Position, part.Position)
    local smooth = math.max(flags.aimbot_smoothing or 8, 1)
    local alpha = math.clamp((dt or 0.016) * (60 / smooth), 0.02, 1)
    Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
end



-- ========== RAGEBOT (Rivals) ==========
-- Does NOT spray UseItem from spawn.
-- Gates: alive, LocalFighter, equipped item, valid target in FOV, no FF.
-- Fire path: Tool:Activate first; UseItem only when fighter item resolves.

local function rivalsCanFight()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    -- ignore literal spawn pad hover (very low move, still in lobby-ish)
    return true
end

local function rivalsGetItem()
    local item, fighter = nil, nil
    pcall(function()
        local ok, ctrl = pcall(require, LocalPlayer.PlayerScripts.Controllers.FighterController)
        if ok and ctrl and ctrl.LocalFighter then
            fighter = ctrl.LocalFighter
            item = fighter.EquippedItem
        end
    end)
    if not item then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        return tool, fighter
    end
    return item, fighter
end

local function rivalsFireAt(hitPart)
    if not hitPart or not hitPart.Parent then return end
    if not rivalsCanFight() then return end
    local item, fighter = rivalsGetItem()
    if not item then return end

    -- Prefer tool activate — silent namecall rewrites the ray on real shots.
    -- Avoid blind StartShooting spam (that spawns projectile models from lobby/spawn).
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        return
    end

    -- Only if we have a real fighter item object with Get
    pcall(function()
        if type(item.Get) ~= "function" then return end
        local rs = game:GetService("ReplicatedStorage")
        local util_ok, util = pcall(require, rs.Modules.Utility)
        local enums_ok, enums = pcall(require, rs.Modules.EnumLibrary)
        if not (util_ok and enums_ok) then return end
        local cam = Workspace.CurrentCamera.CFrame
        local shoot_pos = cam.Position
        local look = CFrame.lookAt(shoot_pos, hitPart.Position)
        local cameradata = {}
        cameradata[utf8.char(1)] = {
            [utf8.char(0)] = util:EncodeCFrame(CFrame.new(shoot_pos) * CFrame.Angles(look:ToOrientation())),
            [utf8.char(1)] = util:EncodeCFrame(CFrame.new(hitPart.Position) * CFrame.Angles(look:ToOrientation())),
            [utf8.char(2)] = hitPart,
            [utf8.char(3)] = util:EncodeCFrame(hitPart.CFrame:ToObjectSpace(CFrame.new(hitPart.Position))),
        }
        local use = rs.Remotes.Replication.Fighter.UseItem
        use:FireServer(item:Get("ObjectID"), enums:ToEnum("StartShooting"), cameradata, nil)
    end)
end

local function runRagebot()
    if not flags.ragebot_enabled then return end
    if flags.ragebot_require_silent and not flags.silent_aim_enabled then return end
    if not rivalsCanFight() then return end
    local target = state.target
    if not target or not target.HitPart or not target.HitPart.Parent then return end
    -- target must be alive / no FF
    if target.Character then
        local th = target.Character:FindFirstChildOfClass("Humanoid")
        if not th or th.Health <= 0 then return end
        if target.Character:FindFirstChildOfClass("ForceField") then return end
    end
    local myRoot = getHrp()
    if not myRoot or not target.Root then return end
    local dist = (myRoot.Position - target.Root.Position).Magnitude
    if dist < 3 or dist > 2000 then return end

    local now = os.clock()
    local interval = math.max(flags.ragebot_interval or 0.12, 0.08)
    if now - (state.lastRage or 0) < interval then return end
    state.lastRage = now
    if not flags.ragebot_auto_shoot then return end
    rivalsFireAt(target.HitPart)
end

-- ========== MAIN LOOP ==========
track(RunService.Heartbeat:Connect(function(dt)
    if state.destroyed then return end
    if flags.silent_aim_enabled or flags.magic_bullet_enabled or flags.aimbot_enabled or flags.ragebot_enabled then
        get_target()
    else
        state.target = nil
    end
    if flags.aimbot_enabled then
        runAimbot(dt)
    end
    if flags.knife_rage then
        runMeleeAura()
    end
    if flags.ragebot_enabled then
        if not flags.silent_aim_enabled and not flags.magic_bullet_enabled then
            get_target()
        end
        runRagebot()
    end

    local hrp = getHrp()
    if not hrp then return end

    -- orbit (MeowLua)
    if flags.orbit_enabled then
        local cl = getClosest()
        if cl and cl.Character then
            local tr = getHrp(cl.Character)
            if tr then
                state.orbAngle = state.orbAngle + math.rad(flags.orbit_speed) * dt
                local off = Vector3.new(math.cos(state.orbAngle)*flags.orbit_radius, flags.orbit_height, math.sin(state.orbAngle)*flags.orbit_radius)
                local dst = tr.Position + off
                hrp.CFrame = CFrame.new(hrp.Position:Lerp(dst, 0.4), Vector3.new(tr.Position.X, hrp.Position.Y, tr.Position.Z))
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end

    -- fake pos
    if flags.fake_pos_enabled then
        if not state.virtualCF then state.virtualCF = hrp.CFrame end
        local look = Camera.CFrame.LookVector
        local rot = CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then
            state.virtualCF = CFrame.new(state.virtualCF.Position + hum.MoveDirection * (hum.WalkSpeed * dt)) * rot
        else
            state.virtualCF = CFrame.new(state.virtualCF.Position) * rot
        end
        local under = state.virtualCF.Position - Vector3.new(0, flags.fake_pos_depth, 0)
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(under) * rot
    end

    -- void spam (MeowLua)
    if flags.void_spam_enabled then
        state.voidAcc = state.voidAcc + dt
        local iv = flags.void_interval
        if iv > 1 then iv = iv / 1000 end
        if state.voidAcc >= math.max(iv, 0.005) then
            state.voidAcc = 0
            for _ = 1, flags.void_burst do
                hrp.CFrame = CFrame.new(hrp.Position + voidDelta())
            end
        end
    end

    -- melee bypass / godmode style (Y-range suppress — simplified)
    if flags.melee_bypass_enabled then
        -- keep noclip when active
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end))

track(RunService.RenderStepped:Connect(function()
    if state.destroyed or not Drawing then return end
    if not drawings.fov then
        drawings.fov = Drawing.new("Circle")
        drawings.fov.Thickness = 1
        drawings.fov.NumSides = 48
        drawings.fov.Color = Color3.new(1,1,1)
        drawings.fov.Filled = false
    end
    local showSilent = flags.show_fov and flags.silent_aim_enabled
    local showAim = flags.aimbot_show_fov and flags.aimbot_enabled
    drawings.fov.Visible = showSilent or showAim
    if drawings.fov.Visible then
        drawings.fov.Position = Camera.ViewportSize * 0.5
        drawings.fov.Radius = showAim and (flags.aimbot_fov or 400) or flags.fov_radius
        drawings.fov.Color = showAim and Color3.fromRGB(200, 200, 200) or Color3.new(1,1,1)
    end
end))

-- ========== UI ==========
local LOGO_B64 = [=[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AqACiACoAoiggoAAAAAAAACoAAAAAAAKIAoICooAIcgoICocqCKAAAIKgCooIKAgAAAAKCCgIoAgAKAAAAAAAAIAonICoAAACoAqAAAAAAAAIASAAAAAAioCoAAAAACCgiooAAAAAiggACgAAAAAAAACAoAACAAAAAAigIADIEBUAAD0AA4AEUBFAQOFAD0AAAFRQAABFARQBFAAAAAAAAAAAAAAAAAFT1AFQBRFAAAAAAAAAABRAFEAUAAAARQAAAAAAAQFAAAAAAAAAABAURQAAVBAUEBQAAABFAVAFT1AAAFQAAAAAD1AAAD1AARQAAAAARQAAEAAAAAAAAAAQBUAAEBQQFEUEUARQAAAQUAAAAAAAAAAAAARQAOAAAEAAAAABAABQBQEUQAAAVAAAAAAABQEFAAAQUAAAAAAAAAAAAARQAAARQAAA5AAAAAVABRAAAFAAAABAUAAAFQAAAAAUEBRAFOEUARQAAAAAQFEAUQBUAFEAUAEFAAAQAFEUAAARQAAEUAAAEUAAAEABQEFAEAUQAABUAAAAAAAAABFQFQAAAAAAAQAAUAAAAAABFAAAAAAAAAADgAAAEBT0AAAEAAAAABBUA8gkBkIoCKgAAKgoIAAoAAAAAioAoigAAAAgoAAAIAoIACgIqAoigAACAKIAogAAAqAKAAACiKAIAqKAIoAAAAAAAAAAAAACAoICggKAACAp6oAoigAAqACiKAIAKgAAAAAAAAAqAKIAqACiAAICgAAAAAAAAgKIoAAAAAgCiAKAAgAAAAAAgKIAqKAAAAAAACAKIAoICgAAAAAAAIKAAAACAAAAAAAAIqAAAyAAQAAAUAEPQAAAVABUAAABQAAAQAAAAAUAAAAABABQARQBAAAAUAEAAAAUAAAFAEUAAAEABQAAAAAAAAAQAAAAAAAOVABAAAAABUABQAAAOQAAAAAAAAAABFAAAAABAAABUAAAFAAABAAFAAAAAAAEAAAAAAABAAPQAAABQAAAAAAAABAAUAAAAAAAAAABAABAFAAAAAABABUAFQAf//Z]=]
local function decodeB64(data)
    local b="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data=data:gsub("[^"..b.."=]","")
    local out={}
    for i=1,#data,4 do
        local a=(b:find(data:sub(i,i),1,true) or 1)-1
        local c=(b:find(data:sub(i+1,i+1),1,true) or 1)-1
        local d=b:find(data:sub(i+2,i+2),1,true)
        local e=b:find(data:sub(i+3,i+3),1,true)
        local v=a*262144+c*4096+((d or 1)-1)*64+((e or 1)-1)
        out[#out+1]=string.char(math.floor(v/65536)%256)
        if data:sub(i+2,i+2)~="=" then out[#out+1]=string.char(math.floor(v/256)%256) end
        if data:sub(i+3,i+3)~="=" then out[#out+1]=string.char(v%256) end
    end
    return table.concat(out)
end
local logoAsset
pcall(function()
    if writefile and (getcustomasset or getsynasset) then
        writefile("alwayswinning_logo.png", decodeB64(LOGO_B64))
        logoAsset = (getcustomasset or getsynasset)("alwayswinning_logo.png")
    end
end)

local function guiParent()
    local ok,h=pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    return CoreGui
end

local host = Instance.new("ScreenGui")
host.Name = "AlwaysWinningUI"
host.ResetOnSpawn = false
host.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
host.DisplayOrder = 9999
host.IgnoreGuiInset = true
pcall(function() host.Parent = guiParent() end)
if not host.Parent then host.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function corner(p,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=p
end

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.fromOffset(44,44)
toggleBtn.Position = UDim2.new(0,12,0.5,-22)
toggleBtn.BackgroundColor3 = Color3.fromRGB(12,12,12)
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = host
corner(toggleBtn, 8)
local ts = Instance.new("UIStroke", toggleBtn); ts.Color=Color3.new(1,1,1); ts.Thickness=1
if logoAsset then
    local img=Instance.new("ImageLabel"); img.BackgroundTransparency=1; img.Size=UDim2.fromScale(0.75,0.75); img.Position=UDim2.fromScale(0.125,0.125); img.ScaleType=Enum.ScaleType.Fit; img.Image=logoAsset; img.Parent=toggleBtn
else
    local fb=Instance.new("TextLabel"); fb.Size=UDim2.fromScale(1,1); fb.BackgroundTransparency=1; fb.Text="AW"; fb.TextColor3=Color3.new(1,1,1); fb.Font=Enum.Font.GothamBold; fb.TextSize=14; fb.Parent=toggleBtn
end

local WIN_W, WIN_H = 420, 280
local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(WIN_W, WIN_H)
win.Position = UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
win.BackgroundColor3 = Color3.fromRGB(10,10,10)
win.BorderSizePixel = 0
win.Parent = host
corner(win, 10)
local ws=Instance.new("UIStroke",win); ws.Color=Color3.new(1,1,1); ws.Thickness=1; ws.Transparency=0.3

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,48)
header.BackgroundColor3 = Color3.fromRGB(16,16,16)
header.BorderSizePixel = 0
header.Parent = win
corner(header, 10)
local hc=Instance.new("Frame"); hc.Size=UDim2.new(1,0,0,12); hc.Position=UDim2.new(0,0,1,-12); hc.BackgroundColor3=Color3.fromRGB(16,16,16); hc.BorderSizePixel=0; hc.Parent=header
if logoAsset then
    local hl=Instance.new("ImageLabel"); hl.Size=UDim2.fromOffset(28,28); hl.Position=UDim2.fromOffset(12,10); hl.BackgroundTransparency=1; hl.Image=logoAsset; hl.ScaleType=Enum.ScaleType.Fit; hl.Parent=header
end
local title=Instance.new("TextLabel"); title.BackgroundTransparency=1; title.Position=UDim2.fromOffset(48,6); title.Size=UDim2.new(1,-100,0,18); title.Font=Enum.Font.GothamBold; title.TextSize=15; title.TextXAlignment=Enum.TextXAlignment.Left; title.TextColor3=Color3.new(1,1,1); title.Text="Always.winning"; title.Parent=header
local sub=Instance.new("TextLabel"); sub.BackgroundTransparency=1; sub.Position=UDim2.fromOffset(48,26); sub.Size=UDim2.new(1,-100,0,14); sub.Font=Enum.Font.Gotham; sub.TextSize=11; sub.TextXAlignment=Enum.TextXAlignment.Left; sub.TextColor3=Color3.fromRGB(160,160,160); sub.Text="PaidV2  ·  Sleepy + MeowLua"; sub.Parent=header

do
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=win.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local d=input.Position-dragStart
            win.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end))
end

local tabBar=Instance.new("Frame"); tabBar.Size=UDim2.new(1,-16,0,28); tabBar.Position=UDim2.fromOffset(8,52); tabBar.BackgroundTransparency=1; tabBar.Parent=win
local tabLayout=Instance.new("UIListLayout",tabBar); tabLayout.FillDirection=Enum.FillDirection.Horizontal; tabLayout.Padding=UDim.new(0,6)
local pages=Instance.new("Frame"); pages.Size=UDim2.new(1,-16,1,-88); pages.Position=UDim2.fromOffset(8,84); pages.BackgroundTransparency=1; pages.ClipsDescendants=true; pages.Parent=win
local pageFrames, firstBtn = {}, nil

local function makeTab(name)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.fromOffset(68,28); btn.BackgroundColor3=Color3.fromRGB(20,20,20); btn.BorderSizePixel=0
    btn.Text=name; btn.Font=Enum.Font.GothamMedium; btn.TextSize=12; btn.TextColor3=Color3.fromRGB(180,180,180)
    btn.AutoButtonColor=false; btn.Parent=tabBar; corner(btn,6)
    local page=Instance.new("ScrollingFrame")
    page.Size=UDim2.fromScale(1,1); page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=4; page.ScrollBarImageColor3=Color3.new(1,1,1); page.CanvasSize=UDim2.fromOffset(0,0); page.ScrollingEnabled=true; page.ElasticBehavior=Enum.ElasticBehavior.Always
    page.Visible=false; page.Parent=pages
    local lay=Instance.new("UIListLayout",page); lay.Padding=UDim.new(0,6); lay.SortOrder=Enum.SortOrder.LayoutOrder
    pageFrames[name]=page
    btn.MouseButton1Click:Connect(function()
        for n,p in pairs(pageFrames) do p.Visible=(n==name) end
        for _,b in ipairs(tabBar:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3=Color3.fromRGB(20,20,20); b.TextColor3=Color3.fromRGB(180,180,180) end
        end
        btn.BackgroundColor3=Color3.new(1,1,1); btn.TextColor3=Color3.new(0,0,0)
    end)
    if not firstBtn then firstBtn=btn end
    return page
end

local function refresh(page)
    local lay=page:FindFirstChildOfClass("UIListLayout")
    if lay then page.CanvasSize=UDim2.fromOffset(0, lay.AbsoluteContentSize.Y+16) end
end
local function section(page, text)
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,0,16); l.BackgroundTransparency=1
    l.Font=Enum.Font.GothamBold; l.TextSize=11; l.TextColor3=Color3.new(1,1,1); l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=text; l.Parent=page
end
local function toggle(page, label, get, set)
    local on=get()
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,28); row.BackgroundColor3=Color3.fromRGB(16,16,16); row.BorderSizePixel=0; row.Parent=page; corner(row,6)
    local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.new(1,-50,1,0); t.Position=UDim2.fromOffset(10,0)
    t.Font=Enum.Font.Gotham; t.TextSize=12; t.TextColor3=Color3.fromRGB(220,220,220); t.TextXAlignment=Enum.TextXAlignment.Left; t.Text=label; t.Parent=row
    local btn=Instance.new("TextButton"); btn.Size=UDim2.fromOffset(36,18); btn.Position=UDim2.new(1,-42,0.5,-9)
    btn.BackgroundColor3=on and Color3.new(1,1,1) or Color3.fromRGB(40,40,40); btn.Text=""; btn.BorderSizePixel=0; btn.AutoButtonColor=false; btn.Parent=row; corner(btn,9)
    local kn=Instance.new("Frame"); kn.Size=UDim2.fromOffset(14,14); kn.Position=on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    kn.BackgroundColor3=on and Color3.new(0,0,0) or Color3.fromRGB(180,180,180); kn.BorderSizePixel=0; kn.Parent=btn; corner(kn,7)
    btn.MouseButton1Click:Connect(function()
        local v=not get(); set(v)
        btn.BackgroundColor3=v and Color3.new(1,1,1) or Color3.fromRGB(40,40,40)
        kn.Position=v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
        kn.BackgroundColor3=v and Color3.new(0,0,0) or Color3.fromRGB(180,180,180)
    end)
end
local function slider(page, label, min, max, get, set)
    local cur=get()
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,42); row.BackgroundColor3=Color3.fromRGB(16,16,16); row.BorderSizePixel=0; row.Parent=page; corner(row,6)
    local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.new(1,-56,0,16); t.Position=UDim2.fromOffset(10,4)
    t.Font=Enum.Font.Gotham; t.TextSize=12; t.TextColor3=Color3.fromRGB(220,220,220); t.TextXAlignment=Enum.TextXAlignment.Left; t.Text=label; t.Parent=row
    local val=Instance.new("TextLabel"); val.BackgroundTransparency=1; val.Size=UDim2.fromOffset(50,16); val.Position=UDim2.new(1,-54,0,4)
    val.Font=Enum.Font.GothamMedium; val.TextSize=11; val.TextColor3=Color3.new(1,1,1); val.Text=tostring(cur); val.Parent=row
    local bar=Instance.new("Frame"); bar.Size=UDim2.new(1,-20,0,6); bar.Position=UDim2.fromOffset(10,28); bar.BackgroundColor3=Color3.fromRGB(40,40,40); bar.BorderSizePixel=0; bar.Parent=row; corner(bar,3)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new(math.clamp((cur-min)/(max-min),0,1),0,1,0); fill.BackgroundColor3=Color3.new(1,1,1); fill.BorderSizePixel=0; fill.Parent=bar; corner(fill,3)
    local function apply(x)
        local rel=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        local v=math.floor(min+(max-min)*rel+0.5); set(v); fill.Size=UDim2.new(rel,0,1,0); val.Text=tostring(v)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            apply(input.Position.X)
            local move,up
            move=UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then apply(i.Position.X) end
            end)
            up=UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then move:Disconnect(); up:Disconnect() end
            end)
        end
    end)
end
local function dropdown(page, label, options, get, set)
    local cur=get(); local idx=table.find(options,cur) or 1
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,28); row.BackgroundColor3=Color3.fromRGB(16,16,16); row.BorderSizePixel=0; row.Parent=page; corner(row,6)
    local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.new(0.42,0,1,0); t.Position=UDim2.fromOffset(10,0)
    t.Font=Enum.Font.Gotham; t.TextSize=12; t.TextColor3=Color3.fromRGB(220,220,220); t.TextXAlignment=Enum.TextXAlignment.Left; t.Text=label; t.Parent=row
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0.52,-12,0,22); btn.Position=UDim2.new(0.48,0,0.5,-11)
    btn.BackgroundColor3=Color3.fromRGB(28,28,28); btn.BorderSizePixel=0; btn.Font=Enum.Font.Gotham; btn.TextSize=11; btn.TextColor3=Color3.new(1,1,1); btn.Text=tostring(cur); btn.AutoButtonColor=false; btn.Parent=row; corner(btn,4)
    btn.MouseButton1Click:Connect(function() idx=idx%#options+1; set(options[idx]); btn.Text=options[idx] end)
end

local rage=makeTab("Rage")
local move=makeTab("Move")
local voidp=makeTab("Void")
local def=makeTab("Def")
local sys=makeTab("Sys")

section(rage,"Aimbot (camera assist)")
toggle(rage,"Camera Aimbot", function() return flags.aimbot_enabled end, function(v) flags.aimbot_enabled=v end)
toggle(rage,"Show Aimbot FOV", function() return flags.aimbot_show_fov end, function(v) flags.aimbot_show_fov=v end)
slider(rage,"Aimbot FOV",20,800, function() return flags.aimbot_fov end, function(v) flags.aimbot_fov=v end)
slider(rage,"Smoothing",1,30, function() return flags.aimbot_smoothing end, function(v) flags.aimbot_smoothing=v end)
toggle(rage,"Use Silent Target", function() return flags.aimbot_use_shared_target end, function(v) flags.aimbot_use_shared_target=v end)
section(rage,"Silent (Sleepy)")
toggle(rage,"Silent Aim", function() return flags.silent_aim_enabled end, function(v) flags.silent_aim_enabled=v end)
toggle(rage,"Show FOV", function() return flags.show_fov end, function(v) flags.show_fov=v end)
slider(rage,"FOV",20,800, function() return flags.fov_radius end, function(v) flags.fov_radius=v end)
slider(rage,"Hit Chance %",1,100, function() return flags.hit_chance end, function(v) flags.hit_chance=v end)
dropdown(rage,"Hitbox",{"Head","HumanoidRootPart","Torso","Random"}, function() return flags.target_hitbox end, function(v) flags.target_hitbox=v end)
dropdown(rage,"Priority",{"Closest","Lowest Health","Distance"}, function() return flags.target_priority end, function(v) flags.target_priority=v end)
toggle(rage,"Riot Shield Check", function() return flags.riot_shield_check end, function(v) flags.riot_shield_check=v end)
toggle(rage,"Avoid Katana", function() return flags.avoid_katana end, function(v) flags.avoid_katana=v end)
section(rage,"Melee (Sleepy)")
toggle(rage,"Melee Aura", function() return flags.knife_rage end, function(v) flags.knife_rage=v end)
slider(rage,"Reach",4,30, function() return flags.melee_safe_reach end, function(v) flags.melee_safe_reach=v end)
toggle(rage,"Face Back", function() return flags.melee_auto_face_back end, function(v) flags.melee_auto_face_back=v end)
section(rage,"Ragebot (Rivals auto-fire)")
toggle(rage,"Ragebot", function() return flags.ragebot_enabled end, function(v) flags.ragebot_enabled=v end)
toggle(rage,"Require Silent", function() return flags.ragebot_require_silent end, function(v) flags.ragebot_require_silent=v end)
toggle(rage,"Auto Shoot", function() return flags.ragebot_auto_shoot end, function(v) flags.ragebot_auto_shoot=v end)
slider(rage,"Fire Interval ms",20,500, function() return math.floor((flags.ragebot_interval or 0.08)*1000) end, function(v) flags.ragebot_interval=v/1000 end)
section(rage,"Magic Bullet (MeowLua)")
toggle(rage,"Magic Bullet", function() return flags.magic_bullet_enabled end, function(v) mb_set(v) end)
slider(rage,"MB Hit Chance",1,100, function() return flags.magic_bullet_hitchance end, function(v) flags.magic_bullet_hitchance=v end)
toggle(rage,"MB Closest Part", function() return flags.magic_bullet_closest end, function(v) flags.magic_bullet_closest=v end)

section(move,"Orbit (MeowLua)")
toggle(move,"Orbit", function() return flags.orbit_enabled end, function(v) flags.orbit_enabled=v end)
slider(move,"Speed",10,720, function() return flags.orbit_speed end, function(v) flags.orbit_speed=v end)
slider(move,"Radius",1,100, function() return flags.orbit_radius end, function(v) flags.orbit_radius=v end)
slider(move,"Height",-50,50, function() return flags.orbit_height end, function(v) flags.orbit_height=v end)
section(move,"Fake Position (Sleepy)")
toggle(move,"Fake Position", function() return flags.fake_pos_enabled end, function(v) setFake(v) end)
slider(move,"Depth x10",10,200, function() return math.floor(flags.fake_pos_depth*10) end, function(v) flags.fake_pos_depth=v/10 end)

section(voidp,"Void Spam (MeowLua)")
toggle(voidp,"Void Spam", function() return flags.void_spam_enabled end, function(v) flags.void_spam_enabled=v end)
dropdown(voidp,"Pattern",{"random","spiral","wave","helix","chaos"}, function() return flags.void_pattern end, function(v) flags.void_pattern=v end)
slider(voidp,"Interval ms",5,200, function() return math.floor(flags.void_interval*1000) end, function(v) flags.void_interval=v/1000 end)
slider(voidp,"Burst",1,20, function() return flags.void_burst end, function(v) flags.void_burst=v end)
slider(voidp,"Range",100,20000, function() return flags.void_range end, function(v) flags.void_range=v end)
toggle(voidp,"Axis X", function() return flags.void_axis_x end, function(v) flags.void_axis_x=v end)
toggle(voidp,"Axis Y", function() return flags.void_axis_y end, function(v) flags.void_axis_y=v end)
toggle(voidp,"Axis Z", function() return flags.void_axis_z end, function(v) flags.void_axis_z=v end)

section(def,"Bypasses (MeowLua)")
toggle(def,"Dagger Bypass", function() return flags.dagger_bypass_enabled end, function(v) flags.dagger_bypass_enabled=v end)
toggle(def,"Melee Bypass / Godmode", function() return flags.melee_bypass_enabled end, function(v) flags.melee_bypass_enabled=v end)
slider(def,"MB Y Range",1,50, function() return flags.melee_bypass_y_range end, function(v) flags.melee_bypass_y_range=v end)

section(sys,"System")
do
    local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=Color3.fromRGB(30,30,30); row.BorderSizePixel=0
    row.Text="Unload"; row.Font=Enum.Font.GothamBold; row.TextSize=13; row.TextColor3=Color3.new(1,1,1); row.Parent=sys; corner(row,6)
    row.MouseButton1Click:Connect(function() if getgenv().AlwaysWinning then getgenv().AlwaysWinning.Unload() end end)
end

firstBtn.BackgroundColor3=Color3.new(1,1,1); firstBtn.TextColor3=Color3.new(0,0,0); rage.Visible=true
for _,pg in pairs(pageFrames) do
    local lay=pg:FindFirstChildOfClass("UIListLayout")
    if lay then lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() refresh(pg) end); task.defer(refresh,pg) end
end

local function setMenu(open) state.menuOpen=open; win.Visible=open end
toggleBtn.MouseButton1Click:Connect(function() setMenu(not state.menuOpen) end)
track(UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.RightShift then setMenu(not state.menuOpen) end
end))

getgenv().AlwaysWinning = {
    Unload = function()
        state.destroyed = true
        flags.silent_aim_enabled=false; flags.aimbot_enabled=false; flags.knife_rage=false; flags.ragebot_enabled=false; flags.orbit_enabled=false
        flags.void_spam_enabled=false; flags.magic_bullet_enabled=false
        setFake(false)
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        for _,d in pairs(drawings) do pcall(function() d:Remove() end) end
        pcall(function() host:Destroy() end)
        getgenv().AlwaysWinning = nil
        print("[Always.winning] unloaded")
    end,
    flags = flags,
}

print("[Always.winning] combined Sleepy+MeowLua online")
