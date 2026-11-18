--!nocheck
-- Always.winning | Full Pack
-- Combat + Spoofer + Unlocker + Skybox + Hitsounds + Crosshair
-- All OFF at boot · custom UI · black/white

if getgenv().AlwaysWinning and getgenv().AlwaysWinning.Unload then
    pcall(getgenv().AlwaysWinning.Unload)
end
if game.GameId and game.GameId ~= 6035872082 then
    -- still run; Rivals preferred but not hard-blocked
end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local F = {
    -- combat
    silent=false, silent_fov=400, silent_hc=100, silent_show_fov=false,
    hitbox="Head", priority="Closest", shield=false, katana=false,
    aimbot=false, aim_fov=400, aim_smooth=8,
    rage=false, rage_ms=150, rage_need_silent=true, rage_auto=true,
    trigger=false, trig_fov=40, trig_ms=50,
    melee=false, melee_reach=12, melee_face=true,
    dagger=false, melee_bypass=false,
    -- visuals
    esp_box=false, esp_name=false, esp_dist=false, esp_tracer=false, esp_chams=false, esp_health=false,
    crosshair=true,
    -- move
    orbit=false, orb_spd=90, orb_rad=8, orb_h=0,
    fakepos=false, fake_depth=5.8,
    body=false, body_mode="Stick", body_h=3,
    speed=false, speed_m=1.5, fly=false, fly_spd=50, noclip=false,
    -- void
    void=false, void_pat="random", void_ms=50, void_burst=3, void_range=1500,
    void_ax=true, void_ay=true, void_az=true,
    -- world
    fullbright=false, nofog=false, skybox=false, skybox_name="None",
    -- hitsound
    hitsound=false, hitsound_name="Bell", hitsound_vol=50,
    -- spoofer
    spoof_device=false, device="Desktop",
    spoof_display=false, display_name="",
    spoof_username=false, username_value="",
    spoof_avatar=false, avatar_userid=0,
    spoof_elo=false, elo_value=2000,
    spoof_streak=false, streak_value=0,
    spoof_level=false, level_value=50,
    spoof_keys=false, keys_value=999,
    spoof_tokens=false, tokens_value=999,
    spoof_glory=false, glory_value=9999,
    -- unlocker
    unlock_all_skins=false,
    -- misc
    antiafk=false, staff=false,
}

local St = {
    dead=false, target=nil, lastMelee=0, lastRage=0, lastTrig=0,
    menu=true, vcf=nil, parts=nil, ang=0, vacc=0, vph=0,
    esp={}, chams={}, draw={}, priority={},
    modules={}, fake_cosmetic={}, fake_weapon={},
    sky_obj=nil,
}

local conns={}
local function track(c) conns[#conns+1]=c; return c end
local function HRP(c) c=c or LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function alive(c)
    if not c then return false end
    local h=c:FindFirstChildOfClass("Humanoid")
    return h and h.Health>0 and not c:FindFirstChildOfClass("ForceField")
end
local function hitpart(c)
    local m=F.hitbox
    if m=="HumanoidRootPart" or m=="Torso" then return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
    elseif m=="Random" then
        local n={"Head","HumanoidRootPart","UpperTorso"}
        return c:FindFirstChild(n[math.random(1,#n)]) or HRP(c)
    end
    return c:FindFirstChild("Head") or HRP(c)
end
local function deflect(c)
    local k=c and c:FindFirstChild("Katana")
    return k and k:FindFirstChild("Deflecting") and k.Deflecting.Value
end
local function shield(root,from)
    if not root or not root.Parent then return false end
    local sh=root.Parent:FindFirstChild("Riot Shield") or root.Parent:FindFirstChild("Shield")
    if not sh then return false end
    return root.CFrame.LookVector:Dot((from-root.Position).Unit)< -0.2
end
local function closest()
    local me=HRP(); if not me then return nil end
    local b,bd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and alive(p.Character) then
            local r=HRP(p.Character)
            if r then local d=(me.Position-r.Position).Magnitude; if d<bd then bd,b=d,p end end
        end
    end
    return b
end

local function get_target(fov)
    local me=HRP()
    if not me or not alive(LP.Character) then St.target=nil; return nil end
    fov=fov or F.silent_fov
    local center=Cam.ViewportSize*0.5
    local best,bs=nil,math.huge
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl~=LP and alive(pl.Character) then
            local ch,root,part=pl.Character,HRP(pl.Character),hitpart(pl.Character)
            if root and part then
                local skip=false
                if F.shield and shield(root,me.Position) then skip=true end
                if F.katana and deflect(ch) then skip=true end
                if not skip then
                    local sp,on=Cam:WorldToViewportPoint(part.Position)
                    if on and sp.Z>0 then
                        local fd=(Vector2.new(sp.X,sp.Y)-center).Magnitude
                        if fd<=fov then
                            local score=fd
                            if F.priority=="Lowest Health" then score=ch.Humanoid.Health
                            elseif F.priority=="Distance" then score=(root.Position-me.Position).Magnitude end
                            if score<bs then bs=score; best={Player=pl,Character=ch,HitPart=part,Root=root} end
                        end
                    end
                end
            end
        end
    end
    St.target=best
    return best
end

pcall(function()
    if type(hookmetamethod)~="function" then return end
    local old
    old=hookmetamethod(game,"__namecall",function(self,...)
        local method=getnamecallmethod()
        local args={...}
        if F.silent and (not checkcaller or not checkcaller()) then
            if (method=="Raycast" or method=="FindPartOnRayWithIgnoreList" or method=="FindPartOnRay") and self==Workspace then
                local origin=args[1]
                if F.fakepos and St.vcf then origin=St.vcf.Position; args[1]=origin end
                local t=St.target
                if t and t.HitPart and math.random(1,100)<=F.silent_hc then
                    args[2]=(t.HitPart.Position-origin).Unit*1000
                    return old(self,table.unpack(args))
                end
            end
        end
        return old(self,...)
    end)
end)

pcall(function()
    if type(hookfunction)~="function" then return end
    local old
    local det=function(self,...)
        if F.dagger and (not checkcaller or not checkcaller()) then
            local n=tostring(self.Name):lower()
            if n:find("dagger") or n:find("knife") or n:find("blade") then return end
        end
        return old(self,...)
    end
    if newcclosure then det=newcclosure(det) end
    old=hookfunction(Instance.new("RemoteEvent").FireServer, det)
end)

-- modules for spoofer
pcall(function()
    local PS=LP:WaitForChild("PlayerScripts",8)
    local C=PS and PS:FindFirstChild("Controllers")
    local RM=ReplicatedStorage:FindFirstChild("Modules")
    if C then
        pcall(function() St.modules.PDC=require(C:WaitForChild("PlayerDataController",5)) end)
        pcall(function() St.modules.Controls=require(C:WaitForChild("ControlsController",5)) end)
    end
    if RM then
        pcall(function() St.modules.Cosmetic=require(RM:WaitForChild("CosmeticLibrary",5)) end)
        pcall(function() St.modules.Item=require(RM:WaitForChild("ItemLibrary",5)) end)
    end
end)

-- PlayerData Get hook
pcall(function()
    if not St.modules.PDC or not St.modules.PDC.Get then return end
    local orig=St.modules.PDC.Get
    St.modules.PDC.Get=function(self,key,...)
        local data=orig(self,key,...)
        if key=="WeaponKeys" and F.spoof_keys then return F.keys_value end
        if key=="UnlockTokens" and F.spoof_tokens then return F.tokens_value end
        if key=="Glory" and F.spoof_glory then return F.glory_value end
        if key=="CosmeticInventory" and F.unlock_all_skins then
            return St.fake_cosmetic
        end
        if key=="WeaponInventory" and F.unlock_all_skins then
            return St.fake_weapon
        end
        return data
    end
end)

local function canFight()
    return alive(LP.Character) and HRP()~=nil
end

local function runMelee()
    if not F.melee or not canFight() then return end
    local me=HRP(); local now=os.clock()
    if now-St.lastMelee<0.12 then return end
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl~=LP and alive(pl.Character) then
            local r=HRP(pl.Character)
            if r and (r.Position-me.Position).Magnitude<=F.melee_reach then
                St.lastMelee=now
                pcall(function()
                    if F.melee_face then me.CFrame=CFrame.new(me.Position,me.Position-r.CFrame.LookVector) end
                    local tool=LP.Character:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end)
                break
            end
        end
    end
end

local function runRage()
    if not F.rage or not canFight() then return end
    if F.rage_need_silent and not F.silent then return end
    local t=St.target
    if not t or not t.HitPart or not alive(t.Character) then return end
    local me=HRP(); if not me or not t.Root then return end
    local d=(me.Position-t.Root.Position).Magnitude
    if d<3 or d>2000 then return end
    local now=os.clock()
    if now-St.lastRage<math.max(F.rage_ms/1000,0.1) then return end
    St.lastRage=now
    if not F.rage_auto then return end
    pcall(function()
        local tool=LP.Character:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end)
end

local function runTrig()
    if not F.trigger or not canFight() then return end
    local t=get_target(F.trig_fov)
    if not t then return end
    local now=os.clock()
    if now-St.lastTrig<F.trig_ms/1000 then return end
    St.lastTrig=now
    pcall(function()
        local tool=LP.Character:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end)
end

local function runAim(dt)
    if not F.aimbot or not St.target or not St.target.HitPart then return end
    local goal=CFrame.new(Cam.CFrame.Position,St.target.HitPart.Position)
    local a=math.clamp((dt or 0.016)*(60/math.max(F.aim_smooth,1)),0.02,1)
    Cam.CFrame=Cam.CFrame:Lerp(goal,a)
end

local function setFake(on)
    F.fakepos=on
    local r=HRP()
    if on then
        if r then St.vcf=r.CFrame end
        if LP.Character then
            St.parts={}
            for _,p in ipairs(LP.Character:GetDescendants()) do
                if p:IsA("BasePart") or p:IsA("Decal") then
                    table.insert(St.parts,{p=p,t=p.Transparency}); p.Transparency=1
                end
            end
        end
    else
        if St.parts then for _,d in ipairs(St.parts) do if d.p and d.p.Parent then d.p.Transparency=d.t end end; St.parts=nil end
        if r and St.vcf then r.CFrame=St.vcf; r.AssemblyLinearVelocity=Vector3.zero end
        St.vcf=nil
    end
end

local function voidDelta()
    local R=F.void_range
    local ax,ay,az=F.void_ax and 1 or 0,F.void_ay and 1 or 0,F.void_az and 1 or 0
    St.vph=St.vph+0.35; local t=St.vph
    if F.void_pat=="spiral" then return Vector3.new(ax*math.cos(t)*R,ay*math.sin(t*0.6)*R*0.4,az*math.sin(t)*R)
    elseif F.void_pat=="wave" then local w=tick()*8; return Vector3.new(ax*math.sin(w)*R,ay*math.sin(w*1.7)*R*0.5,az*math.cos(w)*R)
    elseif F.void_pat=="helix" then return Vector3.new(ax*math.cos(t*2)*R,ay*math.sin(t)*R*0.15,az*math.sin(t*2)*R)
    elseif F.void_pat=="chaos" then return Vector3.new(ax*(math.random()-0.5)*2*R,ay*(math.random()-0.5)*R,az*(math.random()-0.5)*2*R)
    end
    return Vector3.new(ax*(math.random()-0.5)*2*R,ay*(math.random()-0.5)*R,az*(math.random()-0.5)*2*R)
end

-- SKYBOX
local SkyboxPresets = {
    ["None"] = {SkyboxBk="rbxassetid://14147881792",SkyboxDn="rbxassetid://14147882149",SkyboxFt="rbxassetid://14147882761",SkyboxLf="rbxassetid://14147883091",SkyboxRt="rbxassetid://14147882405",SkyboxUp="rbxassetid://14147881297"},
    Aurora = {SkyboxBk="rbxassetid://116533337330584",SkyboxDn="rbxassetid://80054106187171",SkyboxFt="rbxassetid://94459139270943",SkyboxLf="rbxassetid://116368999680791",SkyboxRt="rbxassetid://125758104196312",SkyboxUp="rbxassetid://107060226443967"},
    Battlerock = {SkyboxBk="rbxassetid://131136284306917",SkyboxDn="rbxassetid://89505977207531",SkyboxFt="rbxassetid://140099243548102",SkyboxLf="rbxassetid://121676169821100",SkyboxRt="rbxassetid://97183886241447",SkyboxUp="rbxassetid://107128620201556"},
    ["Beach Bowl"] = {SkyboxBk="rbxassetid://81804134601271",SkyboxDn="rbxassetid://92395364196932",SkyboxFt="rbxassetid://81804134601271",SkyboxLf="rbxassetid://81804134601271",SkyboxRt="rbxassetid://81804134601271",SkyboxUp="rbxassetid://119089964803065"},
    ["Buoy Base"] = {SkyboxBk="rbxassetid://135017685421888",SkyboxDn="rbxassetid://76610044495625",SkyboxFt="rbxassetid://89675413438577",SkyboxLf="rbxassetid://138307087837279",SkyboxRt="rbxassetid://136723547010707",SkyboxUp="rbxassetid://83404878914838"},
    Clockwork = {SkyboxBk="rbxassetid://86284761193226",SkyboxDn="rbxassetid://111425663631622",SkyboxFt="rbxassetid://115606366886873",SkyboxLf="rbxassetid://127287488325060",SkyboxRt="rbxassetid://126844150113423",SkyboxUp="rbxassetid://74510789204352"},
    ["Dark Matter"] = {SkyboxBk="rbxassetid://97629693450922",SkyboxDn="rbxassetid://97898396690232",SkyboxFt="rbxassetid://134755033418084",SkyboxLf="rbxassetid://118219143707956",SkyboxRt="rbxassetid://114940065588775",SkyboxUp="rbxassetid://95430908943263"},
    ["Flash Black"] = {SkyboxBk="rbxassetid://78426835654353",SkyboxDn="rbxassetid://6213218651",SkyboxFt="rbxassetid://71970982976722",SkyboxLf="rbxassetid://78426835654353",SkyboxRt="rbxassetid://78426835654353",SkyboxUp="rbxassetid://138004866371717"},
    Ghostly = {SkyboxBk="rbxassetid://111506743048183",SkyboxDn="rbxassetid://86198196348228",SkyboxFt="rbxassetid://86265514167302",SkyboxLf="rbxassetid://100257959405445",SkyboxRt="rbxassetid://71935101953120",SkyboxUp="rbxassetid://132011089223498"},
    ["Good Egg"] = {SkyboxBk="rbxassetid://94681381933012",SkyboxDn="rbxassetid://75843838469806",SkyboxFt="rbxassetid://97891957473259",SkyboxLf="rbxassetid://102971518965494",SkyboxRt="rbxassetid://94588890960775",SkyboxUp="rbxassetid://127368871569815"},
    ["Melty Molten"] = {SkyboxBk="rbxassetid://131463907527649",SkyboxDn="rbxassetid://116154164311420",SkyboxFt="rbxassetid://113077689016278",SkyboxLf="rbxassetid://79984367513909",SkyboxRt="rbxassetid://82395195737484",SkyboxUp="rbxassetid://117530106700350"},
    Shiverburn = {SkyboxBk="rbxassetid://113636030839991",SkyboxDn="rbxassetid://118027268179499",SkyboxFt="rbxassetid://76405010847029",SkyboxLf="rbxassetid://112044353352688",SkyboxRt="rbxassetid://121078604572355",SkyboxUp="rbxassetid://132486295432727"},
    ["Spin Dig"] = {SkyboxBk="rbxassetid://124211111366754",SkyboxDn="rbxassetid://120491795220431",SkyboxFt="rbxassetid://130119279111055",SkyboxLf="rbxassetid://70742671331562",SkyboxRt="rbxassetid://76516826791940",SkyboxUp="rbxassetid://100229310567751"},
    ["Sweet Mystery"] = {SkyboxBk="rbxassetid://107264897520277",SkyboxDn="rbxassetid://135637946277638",SkyboxFt="rbxassetid://135705252786048",SkyboxLf="rbxassetid://119667604517747",SkyboxRt="rbxassetid://75904303027092",SkyboxUp="rbxassetid://97011146822716"},
    ["Terrace Dome"] = {SkyboxBk="rbxassetid://98684100016510",SkyboxDn="rbxassetid://108354040356521",SkyboxFt="rbxassetid://95723629635852",SkyboxLf="rbxassetid://106269064939837",SkyboxRt="rbxassetid://136234415079744",SkyboxUp="rbxassetid://75385962780878"},
}

local function ApplySkybox()
    if not F.skybox then return end
    local sky=St.sky_obj
    if not sky or not sky.Parent then
        local original=Lighting:FindFirstChildOfClass("Sky")
        if original then
            St.sky_obj=original:Clone()
            St.sky_obj.Parent=original.Parent
            original:Destroy()
        else
            St.sky_obj=Instance.new("Sky")
            St.sky_obj.Parent=Lighting
        end
        sky=St.sky_obj
    end
    local tex=SkyboxPresets[F.skybox_name] or SkyboxPresets["None"]
    if not tex then return end
    for k,v in pairs(tex) do
        pcall(function() sky[k]=v end)
    end
end

-- HITSOUNDS
local HIT_MAP={
    Bell="rbxassetid://146680539", Bubble="rbxassetid://146665237",
    Click="rbxassetid://146633140", Pop="rbxassetid://146681941",
    Skeet="rbxassetid://130791733", Neverlose="rbxassetid://146633485",
    Fatality="rbxassetid://146665147", Bonk="rbxassetid://146661497",
    Minecraft="rbxassetid://146649495", Bruh="rbxassetid://146657737",
}
pcall(function()
    task.spawn(function()
        task.wait(2)
        local path=LP.PlayerScripts:FindFirstChild("Modules")
        if not path then return end
        path=path:FindFirstChild("ClientReplicatedClasses")
        if not path then return end
        path=path:FindFirstChild("ClientFighter")
        if not path then return end
        path=path:FindFirstChild("ClientItem")
        if not path then return end
        local vm=path:FindFirstChild("ClientViewModel")
        if not vm then return end
        local ClientViewModel=require(vm)
        local orig=ClientViewModel.PlayHitmarkerSound
        ClientViewModel.PlayHitmarkerSound=function(self,is_crit,distance)
            if F.hitsound then
                local id=HIT_MAP[F.hitsound_name]
                if id then
                    local s=Instance.new("Sound")
                    s.SoundId=id
                    s.Volume=(F.hitsound_vol or 50)/100
                    s.Parent=SoundService
                    s:Play()
                    s.Ended:Connect(function() s:Destroy() end)
                    return
                end
            end
            return orig(self,is_crit,distance)
        end
    end)
end)

-- ESP
local function clearEsp()
    for _,d in pairs(St.esp) do pcall(function() d:Remove() end) end; St.esp={}
    for _,h in pairs(St.chams) do pcall(function() h:Destroy() end) end; St.chams={}
end
local function updateEsp()
    if not (F.esp_box or F.esp_name or F.esp_dist or F.esp_tracer or F.esp_chams or F.esp_health) then clearEsp(); return end
    if not Drawing then return end
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl~=LP and pl.Character and alive(pl.Character) then
            local root=HRP(pl.Character); local head=pl.Character:FindFirstChild("Head")
            if root then
                local sp,on=Cam:WorldToViewportPoint(root.Position)
                local hp=head and select(1,Cam:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0)))
                local key=tostring(pl.UserId)
                if F.esp_box and on then
                    local box=St.esp[key.."_b"]
                    if not box then box=Drawing.new("Square"); box.Thickness=1; box.Filled=false; box.Color=Color3.new(1,1,1); St.esp[key.."_b"]=box end
                    local h=math.abs((hp and hp.Y or sp.Y)-sp.Y)*2+18; local w=h*0.65
                    box.Size=Vector2.new(w,h); box.Position=Vector2.new(sp.X-w/2,sp.Y-h/2); box.Visible=true
                elseif St.esp[key.."_b"] then St.esp[key.."_b"].Visible=false end
                if F.esp_name and on then
                    local n=St.esp[key.."_n"]; if not n then n=Drawing.new("Text"); n.Size=13; n.Center=true; n.Outline=true; n.Color=Color3.new(1,1,1); St.esp[key.."_n"]=n end
                    n.Text=pl.DisplayName or pl.Name; n.Position=Vector2.new(sp.X,(hp and hp.Y or sp.Y)-16); n.Visible=true
                elseif St.esp[key.."_n"] then St.esp[key.."_n"].Visible=false end
                if F.esp_dist and on then
                    local n=St.esp[key.."_d"]; if not n then n=Drawing.new("Text"); n.Size=11; n.Center=true; n.Outline=true; n.Color=Color3.fromRGB(200,200,200); St.esp[key.."_d"]=n end
                    local me=HRP(); n.Text=(me and math.floor((me.Position-root.Position).Magnitude) or 0).."m"; n.Position=Vector2.new(sp.X,sp.Y+10); n.Visible=true
                elseif St.esp[key.."_d"] then St.esp[key.."_d"].Visible=false end
                if F.esp_health and on then
                    local n=St.esp[key.."_h"]; if not n then n=Drawing.new("Text"); n.Size=11; n.Center=true; n.Outline=true; n.Color=Color3.fromRGB(180,255,180); St.esp[key.."_h"]=n end
                    local hum=pl.Character:FindFirstChildOfClass("Humanoid"); n.Text=hum and (math.floor(hum.Health).." hp") or ""; n.Position=Vector2.new(sp.X,sp.Y+22); n.Visible=true
                elseif St.esp[key.."_h"] then St.esp[key.."_h"].Visible=false end
                if F.esp_tracer and on then
                    local n=St.esp[key.."_t"]; if not n then n=Drawing.new("Line"); n.Thickness=1; n.Color=Color3.new(1,1,1); St.esp[key.."_t"]=n end
                    local vs=Cam.ViewportSize; n.From=Vector2.new(vs.X/2,vs.Y); n.To=Vector2.new(sp.X,sp.Y); n.Visible=true
                elseif St.esp[key.."_t"] then St.esp[key.."_t"].Visible=false end
                if F.esp_chams then
                    if not St.chams[key] then
                        local h=Instance.new("Highlight"); h.FillTransparency=0.5; h.OutlineTransparency=0
                        h.FillColor=Color3.new(1,1,1); h.OutlineColor=Color3.new(0,0,0); h.Adornee=pl.Character; h.Parent=CoreGui; St.chams[key]=h
                    else St.chams[key].Adornee=pl.Character end
                elseif St.chams[key] then St.chams[key]:Destroy(); St.chams[key]=nil end
            end
        end
    end
end

-- unlock helper: fill fake inventory from CosmeticLibrary if available
local function doUnlockAll()
    F.unlock_all_skins=true
    pcall(function()
        if St.modules.Cosmetic and St.modules.Cosmetic.GetAll then
            local all=St.modules.Cosmetic:GetAll()
            if type(all)=="table" then
                for k,v in pairs(all) do St.fake_cosmetic[k]=v end
            end
        end
        -- broad fill: mark common keys as owned tables
        if St.modules.PDC and St.modules.PDC.Get then
            local inv=St.modules.PDC:Get("CosmeticInventory")
            if type(inv)=="table" then
                for k,v in pairs(inv) do St.fake_cosmetic[k]=v end
            end
        end
    end)
    warn("[AW] unlocker armed (client inventory spoof)")
end

-- loops
track(RunService.Heartbeat:Connect(function(dt)
    if St.dead then return end
    if F.silent or F.aimbot or F.rage or F.trigger then get_target() else St.target=nil end
    if F.aimbot then runAim(dt) end
    if F.melee then runMelee() end
    if F.rage then runRage() end
    if F.trigger then runTrig() end
    local r=HRP(); if not r then return end
    if F.orbit then
        local cl=closest()
        if cl and cl.Character then
            local tr=HRP(cl.Character)
            if tr then
                St.ang=St.ang+math.rad(F.orb_spd)*dt
                local off=Vector3.new(math.cos(St.ang)*F.orb_rad,F.orb_h,math.sin(St.ang)*F.orb_rad)
                r.CFrame=CFrame.new(r.Position:Lerp(tr.Position+off,0.4),Vector3.new(tr.Position.X,r.Position.Y,tr.Position.Z))
                r.AssemblyLinearVelocity=Vector3.zero
            end
        end
    end
    if F.body then
        local cl=closest()
        if cl and cl.Character then
            local tr=HRP(cl.Character)
            if tr then
                local y=F.body_h
                if F.body_mode=="Bounce" then y=math.abs(math.sin(tick()*8))*math.abs(y) end
                r.CFrame=CFrame.new(tr.Position+Vector3.new(0,y,0)); r.AssemblyLinearVelocity=Vector3.zero
            end
        end
    end
    if F.fakepos then
        if not St.vcf then St.vcf=r.CFrame end
        local look=Cam.CFrame.LookVector
        local rot=CFrame.Angles(0,math.atan2(-look.X,-look.Z),0)
        local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude>0 then
            St.vcf=CFrame.new(St.vcf.Position+hum.MoveDirection*(hum.WalkSpeed*dt))*rot
        else St.vcf=CFrame.new(St.vcf.Position)*rot end
        for _,p in ipairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        r.AssemblyLinearVelocity=Vector3.zero
        r.CFrame=CFrame.new(St.vcf.Position-Vector3.new(0,F.fake_depth,0))*rot
    end
    if F.void then
        St.vacc=St.vacc+dt
        if St.vacc>=math.max(F.void_ms/1000,0.02) then
            St.vacc=0
            for _=1,F.void_burst do r.CFrame=CFrame.new(r.Position+voidDelta()) end
        end
    end
    if F.noclip or F.melee_bypass then
        for _,p in ipairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end
    if F.speed then
        local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=16*F.speed_m end
    end
    if F.fly then
        local dir=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        r.AssemblyLinearVelocity=dir.Magnitude>0 and dir.Unit*F.fly_spd or Vector3.zero
    end
    -- display name local
    if F.spoof_display and F.display_name~="" then
        pcall(function()
            if LP.Character then
                local hum=LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.DisplayName=F.display_name end
            end
        end)
    end
end))

track(RunService.RenderStepped:Connect(function()
    if St.dead then return end
    updateEsp()
    if F.fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e6 end
    if F.nofog then Lighting.FogEnd=1e6 end
    if F.skybox then ApplySkybox() end
end))

track(LP.Idled:Connect(function()
    if F.antiafk then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end
end))

-- CROSSHAIR (Always.winning)
local function buildCrosshair()
    local parent=(gethui and gethui()) or CoreGui
    if parent:FindFirstChild("AlwaysWinningCrosshair") then parent.AlwaysWinningCrosshair:Destroy() end
    local sg=Instance.new("ScreenGui"); sg.Name="AlwaysWinningCrosshair"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true; sg.DisplayOrder=9998; sg.Parent=parent
    local box=Instance.new("Frame"); box.Name="Centro"; box.Size=UDim2.fromOffset(0,0); box.BackgroundTransparency=1; box.Parent=sg
    local CFG={Length=22,Thick=1,Gap=12,RotSpd=90,PulseSpd=3.5,SizeRng=8,GlowMult=4}
    local dirs={Vector2.new(0,-1),Vector2.new(0,1),Vector2.new(-1,0),Vector2.new(1,0)}
    local comps={}
    for i,dir in ipairs(dirs) do
        local line=Instance.new("Frame"); line.BorderSizePixel=0; line.AnchorPoint=Vector2.new(0.5,0.5); line.ZIndex=11; line.Parent=box
        local out=Instance.new("Frame"); out.BorderSizePixel=0; out.BackgroundColor3=Color3.new(0,0,0); out.BackgroundTransparency=0.5; out.AnchorPoint=Vector2.new(0.5,0.5); out.ZIndex=10; out.Parent=box
        comps[i]={Line=line,Outline=out,Dir=dir,IsH=dir.X~=0}
    end
    local wm=Instance.new("TextLabel"); wm.BackgroundTransparency=1; wm.Font=Enum.Font.GothamBold; wm.TextSize=14; wm.Size=UDim2.fromOffset(140,18)
    wm.AnchorPoint=Vector2.new(0.5,0); wm.Text="Always.winning"; wm.ZIndex=12; wm.Parent=sg
    local st=Instance.new("UIStroke",wm); st.Thickness=1; st.Color=Color3.new(0,0,0); st.Transparency=0.4
    local t,sp,sr=0,Vector2.zero,0
    track(RunService.PreRender:Connect(function(dt)
        if not F.crosshair then
            box.Visible=false; wm.Visible=false; return
        end
        box.Visible=true; wm.Visible=true
        t=t+dt
        local mp=UIS:GetMouseLocation()
        sp=sp:Lerp(mp,1-math.exp(-25*dt))
        box.Position=UDim2.fromOffset(sp.X,sp.Y)
        local pulse=math.sin(t*CFG.PulseSpd)
        local len=CFG.Length+pulse*CFG.SizeRng
        sr=(sr+CFG.RotSpd*(0.4+(pulse+1)*0.3)*dt)%360
        box.Rotation=sr
        local col=Color3.new(1,1,1):Lerp(Color3.new(0,0,0),(math.sin(t*2)+1)*0.5)
        for _,c in ipairs(comps) do
            local off=CFG.Gap+len*0.5
            local px,py=c.Dir.X*off,c.Dir.Y*off
            local w=c.IsH and len or CFG.Thick
            local h=c.IsH and CFG.Thick or len
            c.Line.Size=UDim2.fromOffset(w,h); c.Line.Position=UDim2.fromOffset(px,py); c.Line.BackgroundColor3=col
            c.Outline.Size=UDim2.fromOffset(w+(c.IsH and 0 or 2),h+(c.IsH and 2 or 0)); c.Outline.Position=UDim2.fromOffset(px,py)
        end
        wm.Text="Always.winning"; wm.TextColor3=col
        wm.Position=UDim2.fromOffset(sp.X,sp.Y+CFG.Gap+CFG.Length+CFG.SizeRng)
    end))
    St.crosshairGui=sg
end
buildCrosshair()

-- ================= UI =================
local function guiParent()
    local ok,h=pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    return CoreGui
end
local host=Instance.new("ScreenGui"); host.Name="AlwaysWinningUI"; host.ResetOnSpawn=false
host.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; host.DisplayOrder=9999; host.IgnoreGuiInset=true
pcall(function() host.Parent=guiParent() end)
if not host.Parent then host.Parent=LP:WaitForChild("PlayerGui") end
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 4); c.Parent=p end

local toggleBtn=Instance.new("TextButton")
toggleBtn.Size=UDim2.fromOffset(44,44); toggleBtn.Position=UDim2.new(0,12,0.5,-22)
toggleBtn.BackgroundColor3=Color3.fromRGB(12,12,12); toggleBtn.BorderSizePixel=0; toggleBtn.Text="AW"
toggleBtn.Font=Enum.Font.GothamBold; toggleBtn.TextSize=14; toggleBtn.TextColor3=Color3.new(1,1,1)
toggleBtn.AutoButtonColor=false; toggleBtn.Parent=host; corner(toggleBtn,8)
Instance.new("UIStroke",toggleBtn).Color=Color3.new(1,1,1)

local WW,WH=480,280
local win=Instance.new("Frame"); win.Size=UDim2.fromOffset(WW,WH); win.Position=UDim2.new(0.5,-WW/2,0.5,-WH/2)
win.BackgroundColor3=Color3.fromRGB(10,10,10); win.BorderSizePixel=0; win.Parent=host; corner(win,10)
local ws=Instance.new("UIStroke",win); ws.Color=Color3.new(1,1,1); ws.Thickness=1; ws.Transparency=0.3
local header=Instance.new("Frame"); header.Size=UDim2.new(1,0,0,36); header.BackgroundColor3=Color3.fromRGB(16,16,16); header.BorderSizePixel=0; header.Parent=win; corner(header,10)
local hc=Instance.new("Frame"); hc.Size=UDim2.new(1,0,0,10); hc.Position=UDim2.new(0,0,1,-10); hc.BackgroundColor3=Color3.fromRGB(16,16,16); hc.BorderSizePixel=0; hc.Parent=header
local title=Instance.new("TextLabel"); title.BackgroundTransparency=1; title.Position=UDim2.fromOffset(12,2); title.Size=UDim2.new(1,-20,0,16)
title.Font=Enum.Font.GothamBold; title.TextSize=13; title.TextXAlignment=Enum.TextXAlignment.Left; title.TextColor3=Color3.new(1,1,1); title.Text="Always.winning"; title.Parent=header
local sub=Instance.new("TextLabel"); sub.BackgroundTransparency=1; sub.Position=UDim2.fromOffset(12,17); sub.Size=UDim2.new(1,-20,0,14)
sub.Font=Enum.Font.Gotham; sub.TextSize=10; sub.TextXAlignment=Enum.TextXAlignment.Left; sub.TextColor3=Color3.fromRGB(150,150,150); sub.Text="PaidV2  ·  full pack"; sub.Parent=header

do local dragging,ds,sp
    header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; ds=i.Position; sp=win.Position end end)
    header.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    track(UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-ds; win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end))
end

local tabBar=Instance.new("ScrollingFrame"); tabBar.Size=UDim2.new(1,-8,0,22); tabBar.Position=UDim2.fromOffset(4,38)
tabBar.BackgroundTransparency=1; tabBar.BorderSizePixel=0; tabBar.ScrollBarThickness=0; tabBar.ScrollingDirection=Enum.ScrollingDirection.X
tabBar.CanvasSize=UDim2.fromOffset(900,0); tabBar.Parent=win
local tabLay=Instance.new("UIListLayout",tabBar); tabLay.FillDirection=Enum.FillDirection.Horizontal; tabLay.Padding=UDim.new(0,3)
local pages=Instance.new("Frame"); pages.Size=UDim2.new(1,-8,1,-64); pages.Position=UDim2.fromOffset(4,62); pages.BackgroundTransparency=1; pages.ClipsDescendants=true; pages.Parent=win
local pageFrames,firstBtn={},nil

local function makeTab(name)
    local btn=Instance.new("TextButton"); btn.Size=UDim2.fromOffset(62,20); btn.BackgroundColor3=Color3.fromRGB(22,22,22); btn.BorderSizePixel=0
    btn.Text=name; btn.Font=Enum.Font.GothamMedium; btn.TextSize=10; btn.TextColor3=Color3.fromRGB(170,170,170); btn.AutoButtonColor=false; btn.Parent=tabBar; corner(btn,4)
    local page=Instance.new("ScrollingFrame"); page.Size=UDim2.fromScale(1,1); page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=3; page.ScrollBarImageColor3=Color3.new(1,1,1); page.ScrollingEnabled=true; page.ElasticBehavior=Enum.ElasticBehavior.Always
    page.CanvasSize=UDim2.fromOffset(0,0); page.Visible=false; page.Parent=pages
    local lay=Instance.new("UIListLayout",page); lay.Padding=UDim.new(0,3); lay.SortOrder=Enum.SortOrder.LayoutOrder
    pageFrames[name]=page
    btn.MouseButton1Click:Connect(function()
        for n,p in pairs(pageFrames) do p.Visible=(n==name) end
        for _,b in ipairs(tabBar:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3=Color3.fromRGB(22,22,22); b.TextColor3=Color3.fromRGB(170,170,170) end end
        btn.BackgroundColor3=Color3.new(1,1,1); btn.TextColor3=Color3.new(0,0,0)
    end)
    if not firstBtn then firstBtn=btn end
    return page
end
local function refresh(page) local lay=page:FindFirstChildOfClass("UIListLayout"); if lay then page.CanvasSize=UDim2.fromOffset(0,lay.AbsoluteContentSize.Y+8) end end
local function section(page,text)
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,0,12); l.BackgroundTransparency=1; l.Font=Enum.Font.GothamBold; l.TextSize=9
    l.TextColor3=Color3.new(1,1,1); l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=text; l.Parent=page
end
local function toggle(page,label,get,set)
    local on=get()
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,22); row.BackgroundColor3=Color3.fromRGB(16,16,16); row.BorderSizePixel=0; row.Parent=page; corner(row,4)
    local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.new(1,-42,1,0); t.Position=UDim2.fromOffset(6,0)
    t.Font=Enum.Font.Gotham; t.TextSize=10; t.TextColor3=Color3.fromRGB(220,220,220); t.TextXAlignment=Enum.TextXAlignment.Left; t.Text=label; t.Parent=row
    local btn=Instance.new("TextButton"); btn.Size=UDim2.fromOffset(30,13); btn.Position=UDim2.new(1,-36,0.5,-6.5)
    btn.BackgroundColor3=on and Color3.new(1,1,1) or Color3.fromRGB(40,40,40); btn.Text=""; btn.BorderSizePixel=0; btn.AutoButtonColor=false; btn.Parent=row; corner(btn,6)
    local kn=Instance.new("Frame"); kn.Size=UDim2.fromOffset(9,9); kn.Position=on and UDim2.new(1,-11,0.5,-4.5) or UDim2.new(0,2,0.5,-4.5)
    kn.BackgroundColor3=on and Color3.new(0,0,0) or Color3.fromRGB(180,180,180); kn.BorderSizePixel=0; kn.Parent=btn; corner(kn,4)
    btn.MouseButton1Click:Connect(function()
        local v=not get(); set(v)
        btn.BackgroundColor3=v and Color3.new(1,1,1) or Color3.fromRGB(40,40,40)
        kn.Position=v and UDim2.new(1,-11,0.5,-4.5) or UDim2.new(0,2,0.5,-4.5)
        kn.BackgroundColor3=v and Color3.new(0,0,0) or Color3.fromRGB(180,180,180)
    end)
end
local function slider(page,label,min,max,get,set)
    local cur=get()
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=Color3.fromRGB(16,16,16); row.BorderSizePixel=0; row.Parent=page; corner(row,4)
    local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.new(1,-44,0,11); t.Position=UDim2.fromOffset(6,2)
    t.Font=Enum.Font.Gotham; t.TextSize=10; t.TextColor3=Color3.fromRGB(220,220,220); t.TextXAlignment=Enum.TextXAlignment.Left; t.Text=label; t.Parent=row
    local val=Instance.new("TextLabel"); val.BackgroundTransparency=1; val.Size=UDim2.fromOffset(40,11); val.Position=UDim2.new(1,-42,0,2)
    val.Font=Enum.Font.GothamMedium; val.TextSize=9; val.TextColor3=Color3.new(1,1,1); val.Text=tostring(cur); val.Parent=row
    local bar=Instance.new("Frame"); bar.Size=UDim2.new(1,-12,0,4); bar.Position=UDim2.fromOffset(6,20); bar.BackgroundColor3=Color3.fromRGB(40,40,40); bar.BorderSizePixel=0; bar.Parent=row; corner(bar,2)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new(math.clamp((cur-min)/(max-min),0,1),0,1,0); fill.BackgroundColor3=Color3.new(1,1,1); fill.BorderSizePixel=0; fill.Parent=bar; corner(fill,2)
    local function apply(x)
        local rel=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        local v=math.floor(min+(max-min)*rel+0.5); set(v); fill.Size=UDim2.new(rel,0,1,0); val.Text=tostring(v)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            apply(input.Position.X)
            local move,up
            move=UIS.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then apply(i.Position.X) end end)
            up=UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then move:Disconnect(); up:Disconnect() end end)
        end
    end)
end
local function dropdown(page,label,options,get,set)
    local cur=get(); local idx=table.find(options,cur) or 1
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,22); row.BackgroundColor3=Color3.fromRGB(16,16,16); row.BorderSizePixel=0; row.Parent=page; corner(row,4)
    local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.new(0.36,0,1,0); t.Position=UDim2.fromOffset(6,0)
    t.Font=Enum.Font.Gotham; t.TextSize=10; t.TextColor3=Color3.fromRGB(220,220,220); t.TextXAlignment=Enum.TextXAlignment.Left; t.Text=label; t.Parent=row
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0.6,-8,0,16); btn.Position=UDim2.new(0.38,0,0.5,-8)
    btn.BackgroundColor3=Color3.fromRGB(28,28,28); btn.BorderSizePixel=0; btn.Font=Enum.Font.Gotham; btn.TextSize=9; btn.TextColor3=Color3.new(1,1,1); btn.Text=tostring(cur); btn.AutoButtonColor=false; btn.Parent=row; corner(btn,3)
    btn.MouseButton1Click:Connect(function() idx=idx%#options+1; set(options[idx]); btn.Text=options[idx] end)
end
local function button(page,label,fn)
    local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,24); row.BackgroundColor3=Color3.fromRGB(28,28,28); row.BorderSizePixel=0
    row.Text=label; row.Font=Enum.Font.GothamBold; row.TextSize=11; row.TextColor3=Color3.new(1,1,1); row.Parent=page; corner(row,4)
    row.MouseButton1Click:Connect(fn)
end
local function textbox(page,placeholder,get,set)
    local row=Instance.new("TextBox"); row.Size=UDim2.new(1,0,0,22); row.BackgroundColor3=Color3.fromRGB(16,16,16); row.BorderSizePixel=0
    row.PlaceholderText=placeholder; row.Text=tostring(get() or ""); row.Font=Enum.Font.Gotham; row.TextSize=10
    row.TextColor3=Color3.new(1,1,1); row.PlaceholderColor3=Color3.fromRGB(100,100,100); row.ClearTextOnFocus=false; row.Parent=page; corner(row,4)
    row.FocusLost:Connect(function() set(row.Text) end)
end

local combat=makeTab("Combat")
local visuals=makeTab("Visuals")
local move=makeTab("Move")
local voidp=makeTab("Void")
local world=makeTab("World")
local spoof=makeTab("Spoof")
local unlock=makeTab("Unlock")
local misc=makeTab("Misc")
local sett=makeTab("Settings")

section(combat,"Silent")
toggle(combat,"Silent Aim",function() return F.silent end,function(v) F.silent=v end)
toggle(combat,"Show FOV",function() return F.silent_show_fov end,function(v) F.silent_show_fov=v end)
slider(combat,"FOV",20,800,function() return F.silent_fov end,function(v) F.silent_fov=v end)
slider(combat,"Hit Chance",1,100,function() return F.silent_hc end,function(v) F.silent_hc=v end)
dropdown(combat,"Hitbox",{"Head","HumanoidRootPart","Torso","Random"},function() return F.hitbox end,function(v) F.hitbox=v end)
section(combat,"Ragebot")
toggle(combat,"Ragebot",function() return F.rage end,function(v) F.rage=v end)
toggle(combat,"Need Silent",function() return F.rage_need_silent end,function(v) F.rage_need_silent=v end)
slider(combat,"Interval ms",80,400,function() return F.rage_ms end,function(v) F.rage_ms=v end)
section(combat,"Trigger / Melee")
toggle(combat,"Triggerbot",function() return F.trigger end,function(v) F.trigger=v end)
toggle(combat,"Melee Aura",function() return F.melee end,function(v) F.melee=v end)
slider(combat,"Reach",4,30,function() return F.melee_reach end,function(v) F.melee_reach=v end)
toggle(combat,"Dagger Bypass",function() return F.dagger end,function(v) F.dagger=v end)

section(visuals,"ESP")
toggle(visuals,"Box",function() return F.esp_box end,function(v) F.esp_box=v end)
toggle(visuals,"Name",function() return F.esp_name end,function(v) F.esp_name=v end)
toggle(visuals,"Distance",function() return F.esp_dist end,function(v) F.esp_dist=v end)
toggle(visuals,"Health",function() return F.esp_health end,function(v) F.esp_health=v end)
toggle(visuals,"Tracer",function() return F.esp_tracer end,function(v) F.esp_tracer=v end)
toggle(visuals,"Chams",function() return F.esp_chams end,function(v) F.esp_chams=v end)
section(visuals,"Crosshair")
toggle(visuals,"Crosshair",function() return F.crosshair end,function(v) F.crosshair=v end)

section(move,"Movement")
toggle(move,"Orbit",function() return F.orbit end,function(v) F.orbit=v end)
slider(move,"Orbit Speed",10,720,function() return F.orb_spd end,function(v) F.orb_spd=v end)
toggle(move,"Fake Position",function() return F.fakepos end,function(v) setFake(v) end)
toggle(move,"Body Split",function() return F.body end,function(v) F.body=v end)
toggle(move,"Speed",function() return F.speed end,function(v) F.speed=v end)
toggle(move,"Fly",function() return F.fly end,function(v) F.fly=v end)
toggle(move,"Noclip",function() return F.noclip end,function(v) F.noclip=v end)

section(voidp,"Void")
toggle(voidp,"Void Spam",function() return F.void end,function(v) F.void=v end)
dropdown(voidp,"Pattern",{"random","spiral","wave","helix","chaos"},function() return F.void_pat end,function(v) F.void_pat=v end)
slider(voidp,"Range",100,5000,function() return F.void_range end,function(v) F.void_range=v end)

section(world,"World")
toggle(world,"Fullbright",function() return F.fullbright end,function(v) F.fullbright=v end)
toggle(world,"No Fog",function() return F.nofog end,function(v) F.nofog=v end)
toggle(world,"Skybox",function() return F.skybox end,function(v) F.skybox=v; if v then ApplySkybox() end end)
local skyNames={}
for n in pairs(SkyboxPresets) do skyNames[#skyNames+1]=n end
table.sort(skyNames)
if #skyNames==0 then skyNames={"None"} end
dropdown(world,"Sky Preset",skyNames,function() return F.skybox_name end,function(v) F.skybox_name=v; ApplySkybox() end)
section(world,"Hitsound")
toggle(world,"Hitsound",function() return F.hitsound end,function(v) F.hitsound=v end)
dropdown(world,"Sound",{"Bell","Bubble","Click","Pop","Skeet","Neverlose","Fatality","Bonk","Minecraft","Bruh"},function() return F.hitsound_name end,function(v) F.hitsound_name=v end)
slider(world,"Volume",1,100,function() return F.hitsound_vol end,function(v) F.hitsound_vol=v end)

section(spoof,"Identity (client)")
toggle(spoof,"Spoof DisplayName",function() return F.spoof_display end,function(v) F.spoof_display=v end)
textbox(spoof,"Display name...",function() return F.display_name end,function(v) F.display_name=v end)
toggle(spoof,"Spoof Device flag",function() return F.spoof_device end,function(v) F.spoof_device=v end)
dropdown(spoof,"Device",{"Desktop","Mobile","Console","VR"},function() return F.device end,function(v) F.device=v end)
section(spoof,"Stats (client Get hook)")
toggle(spoof,"Spoof ELO",function() return F.spoof_elo end,function(v) F.spoof_elo=v end)
slider(spoof,"ELO",0,5000,function() return F.elo_value end,function(v) F.elo_value=v end)
toggle(spoof,"Spoof Keys",function() return F.spoof_keys end,function(v) F.spoof_keys=v end)
slider(spoof,"Keys",0,9999,function() return F.keys_value end,function(v) F.keys_value=v end)
toggle(spoof,"Spoof Tokens",function() return F.spoof_tokens end,function(v) F.spoof_tokens=v end)
slider(spoof,"Tokens",0,9999,function() return F.tokens_value end,function(v) F.tokens_value=v end)
toggle(spoof,"Spoof Glory",function() return F.spoof_glory end,function(v) F.spoof_glory=v end)
slider(spoof,"Glory",0,99999,function() return F.glory_value end,function(v) F.glory_value=v end)

section(unlock,"Skin / Cosmetic (client)")
toggle(unlock,"Unlock Inventory Spoof",function() return F.unlock_all_skins end,function(v) F.unlock_all_skins=v end)
button(unlock,"Arm Unlock All Cosmetics",function() doUnlockAll() end)

section(misc,"Utility")
toggle(misc,"Anti AFK",function() return F.antiafk end,function(v) F.antiafk=v end)
toggle(misc,"Staff Name Detect",function() return F.staff end,function(v) F.staff=v end)

section(sett,"System")
button(sett,"Unload",function() if getgenv().AlwaysWinning then getgenv().AlwaysWinning.Unload() end end)

firstBtn.BackgroundColor3=Color3.new(1,1,1); firstBtn.TextColor3=Color3.new(0,0,0); combat.Visible=true
for _,pg in pairs(pageFrames) do
    local lay=pg:FindFirstChildOfClass("UIListLayout")
    if lay then lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() refresh(pg) end); task.defer(refresh,pg) end
end

local function setMenu(open) St.menu=open; win.Visible=open end
toggleBtn.MouseButton1Click:Connect(function() setMenu(not St.menu) end)
track(UIS.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.RightShift then setMenu(not St.menu) end
end))

getgenv().AlwaysWinning={
    Unload=function()
        St.dead=true
        for k,v in pairs(F) do if type(v)=="boolean" then F[k]=false end end
        setFake(false); clearEsp()
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        pcall(function() if St.crosshairGui then St.crosshairGui:Destroy() end end)
        pcall(function() host:Destroy() end)
        getgenv().AlwaysWinning=nil
        print("[Always.winning] unloaded")
    end,
    flags=F,
}
print("[Always.winning] full pack online — combat/spoof/unlock/sky/hit/crosshair")
