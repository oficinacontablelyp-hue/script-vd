-- Cargar Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Servicios de Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- Crear la ventana principal
local Window = Rayfield:CreateWindow({
    Name = "Rayfield Example Window",
    Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
    LoadingTitle = "Rayfield Interface Suite",
    LoadingSubtitle = "by Sirius",
    ShowText = "Rayfield", -- for mobile users to unhide rayfield, change if you'd like
    Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

    ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil, -- Create a custom folder for your hub/game
        FileName = "Big Hub"
    },

    Discord = {
        Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
        Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
        RememberJoins = true -- Set this to false to make them join the discord every time they load it up
    },

    KeySystem = false, -- Set this to true to use our key system
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
        FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
        SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
        GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
        Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
    }
})

-- Crear pestaña Visual
local TabVisual = Window:CreateTab("Visual")
TabVisual:CreateSection("ESP")

-- Variables globales para ESP de players
local playerESPEnhanced = false
local nametagsEnhanced = false
local showDistance = false
local maxDistance = 500

-- Variables globales para ESP de generators
local generatorESPEnhanced = false
local generatorMaxRange = 300
local worldReg = {Generator = {}}
local mapAdd, mapRem = {}, {}

-- Colores y variables auxiliares (ajusta según el juego, ej. Dead by Daylight)
local survivorColor = Color3.fromRGB(0, 255, 0)  -- Verde para survivors
local killerTypeName = "Unknown"  -- Nombre del tipo de killer, actualízalo dinámicamente si es necesario

-- Función para obtener el color del killer actual (ejemplo simple)
local function currentKillerColor()
    return Color3.fromRGB(255, 0, 0)  -- Rojo para killer
end

-- Funciones auxiliares
local function alive(obj)
    return obj and obj.Parent and not obj:IsDescendantOf(nil) and obj:IsA("Instance")
end

local function getRole(p)
    -- Ejemplo: Asume que el rol se basa en el equipo o atributo; ajusta según el juego
    if p.Team and p.Team.Name == "Killer" then
        return "Killer"
    else
        return "Survivor"
    end
end

local function dist(a, b)
    return (a - b).Magnitude
end

local function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

local function validPart(part)
    return part and part:IsA("BasePart") and alive(part)
end

local function firstBasePart(model)
    if not alive(model) then return nil end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function ensureHighlight(c, col)
    if not alive(c) then return nil end
    local hl = c:FindFirstChild("VD_Highlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "VD_Highlight"
        hl.Parent = c
    end
    hl.FillColor = col
    hl.FillTransparency = 0.5
    return hl
end

local function clearHighlight(c)
    if not alive(c) then return end
    local hl = c:FindFirstChild("VD_Highlight")
    if hl then hl:Destroy() end
end

local function makeBillboard(text, col)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = col
    lbl.TextScaled = true
    lbl.Font = Enum.Font.SourceSansBold
    lbl.Parent = bb
    return bb
end

local function clearChild(parent, name)
    if not alive(parent) then return end
    local child = parent:FindFirstChild(name)
    if child then child:Destroy() end
end

-- Función para aplicar ESP a players
local function applyEnhancedPlayerESP(p)
    if p == LP then return end
    local c = p.Character
    if not (c and alive(c)) then return end
    local role = getRole(p)
    local baseCol = (role == "Killer") and currentKillerColor() or survivorColor
    local head = c:FindFirstChild("Head")
    local hrp = c:FindFirstChild("HumanoidRootPart")
    
    if playerESPEnhanced then
        local hl = ensureHighlight(c, baseCol)
        if hl then
            hl.OutlineTransparency = 0
            hl.OutlineColor = baseCol
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            if hrp and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local dist = dist(hrp.Position, LP.Character.HumanoidRootPart.Position)
                if dist > maxDistance then
                    hl.FillTransparency = 1
                    hl.OutlineTransparency = 1
                else
                    local fade = clamp(dist / maxDistance, 0, 1)
                    hl.FillTransparency = 0.5 + (fade * 0.5)
                    hl.OutlineTransparency = fade * 0.5
                end
            end
        end
        
        if nametagsEnhanced and validPart(head) then
            local tag = head:FindFirstChild("VD_Tag") or makeBillboard("", baseCol)
            tag.Name = "VD_Tag"
            tag.Parent = head
            local l = tag:FindFirstChild("Label")
            if l then
                local text = (role == "Killer") and (p.Name .. " [" .. tostring(killerTypeName) .. "]") or p.Name
                if showDistance and hrp and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor(dist(hrp.Position, LP.Character.HumanoidRootPart.Position))
                    text = text .. " - " .. dist .. "m"
                end
                l.Text = text
                l.TextColor3 = baseCol
                l.TextStrokeTransparency = 0
                l.TextStrokeColor3 = Color3.new(0, 0, 0)
            end
        else
            local t = head and head:FindFirstChild("VD_Tag")
            if t then pcall(function() t:Destroy() end) end
        end
    else
        clearHighlight(c)
        local head = c:FindFirstChild("Head")
        local t = head and head:FindFirstChild("VD_Tag")
        if t then pcall(function() t:Destroy() end) end
    end
end

-- Función para genProgress
local function genProgress(m)
    local p = tonumber(m:GetAttribute("RepairProgress")) or 0
    if p <= 1.001 then p = p * 100 end
    return clamp(p, 0, 100)
end

-- Función para aplicar ESP a generators
local function applyEnhancedGeneratorESP(entry)
    local model = entry.model
    local part = entry.part
    if not generatorESPEnhanced or not alive(model) or not validPart(part) then return end
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp and dist(part.Position, hrp.Position) > generatorMaxRange then
        clearChild(part, "VD_Generator_Enhanced")
        clearChild(part, "VD_Text_Generator_Enhanced")
        return
    end
    local pct = genProgress(model)
    local hue = clamp(pct / 100, 0, 0.33)
    local dynamicCol = Color3.fromHSV(hue, 1, 1)
    local adornName = "VD_Generator_Enhanced"
    local a = part:FindFirstChild(adornName)
    if not a then
        a = Instance.new("BoxHandleAdornment")
        a.Name = adornName
        a.Adornee = part
        a.ZIndex = 10
        a.AlwaysOnTop = true
        a.Transparency = 0.3
        a.Size = part.Size + Vector3.new(0.5, 0.5, 0.5)
        a.Parent = part
    end
    a.Color3 = dynamicCol
    local textName = "VD_Text_Generator_Enhanced"
    local bb = part:FindFirstChild(textName)
    if not bb then
        bb = makeBillboard("", dynamicCol)
        bb.Name = textName
        bb.Parent = part
    end
    local lbl = bb:FindFirstChild("Label")
    if lbl then
        local txt = "Gen " .. math.floor(pct + 0.5) .. "%"
        lbl.Text = txt
        lbl.TextColor3 = dynamicCol
    end
    if hrp then
        local fadeDist = dist(part.Position, hrp.Position)
        local fade = clamp(fadeDist / generatorMaxRange, 0, 1)
        a.Transparency = 0.3 + (fade * 0.7)
        if lbl then lbl.TextTransparency = fade * 0.5 end
    end
end

-- Función para registrar generators
local function ensureWorldEntry(cat, model)
    if not alive(model) or worldReg[cat][model] then return end
    local rep = firstBasePart(model)
    if not validPart(rep) then return end
    worldReg[cat][model] = {model = model, part = rep}
end

local function registerFromDescendant(obj)
    if not alive(obj) then return end
    if obj:IsA("Model") and obj.Name == "Generator" then
        ensureWorldEntry("Generator", obj)
    end
end

local function refreshRoots()
    for _, cn in pairs(mapAdd) do if cn then cn:Disconnect() end end
    for _, cn in pairs(mapRem) do if cn then cn:Disconnect() end end
    mapAdd, mapRem = {}, {}
    local r1 = Workspace:FindFirstChild("Map")
    local r2 = Workspace:FindFirstChild("Map1")
    if r1 then
        mapAdd[r1] = r1.DescendantAdded:Connect(registerFromDescendant)
        for _, d in ipairs(r1:GetDescendants()) do registerFromDescendant(d) end
    end
    if r2 then
        mapAdd[r2] = r2.DescendantAdded:Connect(registerFromDescendant)
        for _, d in ipairs(r2:GetDescendants()) do registerFromDescendant(d) end
    end
end

-- Loops para ESP
local espEnhancedLoopConn = nil
local function startEnhancedESPLoop()
    if espEnhancedLoopConn then return end
    espEnhancedLoopConn = RunService.Heartbeat:Connect(function()
        if not playerESPEnhanced and not nametagsEnhanced then return end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then applyEnhancedPlayerESP(pl) end
        end
    end)
end
local function stopEnhancedESPLoop()
    if espEnhancedLoopConn then espEnhancedLoopConn:Disconnect() espEnhancedLoopConn = nil end
end

local generatorEnhancedLoopConn = nil
local function startGeneratorEnhancedLoop()
    if generatorEnhancedLoopConn then return end
    generatorEnhancedLoopConn = RunService.Heartbeat:Connect(function()
        if not generatorESPEnhanced then return end
        for _, entry in pairs(worldReg.Generator) do
            applyEnhancedGeneratorESP(entry)
        end
    end)
end
local function stopGeneratorEnhancedLoop()
    if generatorEnhancedLoopConn then generatorEnhancedLoopConn:Disconnect() generatorEnhancedLoopConn = nil end
    for _, entry in pairs(worldReg.Generator) do
        if entry.part then
            clearChild(entry.part, "VD_Generator_Enhanced")
            clearChild(entry.part, "VD_Text_Generator_Enhanced")
        end
    end
end

-- Función para watch players
local playerConns = {}
local function watchPlayer(p)
    if playerConns[p] then for _, cn in ipairs(playerConns[p]) do cn:Disconnect() end end
    playerConns[p] = {}
    table.insert(playerConns[p], p.CharacterAdded:Connect(function()
        task.delay(0.15, function() applyEnhancedPlayerESP(p) end)
    end))
    table.insert(playerConns[p], p:GetPropertyChangedSignal("Team"):Connect(function() applyEnhancedPlayerESP(p) end))
    if p.Character then applyEnhancedPlayerESP(p) end
end
local function unwatchPlayer(p)
    if p.Character then
        clearHighlight(p.Character)
        local head = p.Character:FindFirstChild("Head")
        if head and head:FindFirstChild("VD_Tag") then pcall(function() head.VD_Tag:Destroy() end) end
    end
    if playerConns[p] then for _, cn in ipairs(playerConns[p]) do cn:Disconnect() end end
    playerConns[p] = nil
end

-- Crear toggles en la UI
TabVisual:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESPEnhanced",
    Callback = function(s)
        playerESPEnhanced = s
        if playerESPEnhanced or nametagsEnhanced then startEnhancedESPLoop() else stopEnhancedESPLoop() end
    end
})

TabVisual:CreateToggle({
    Name = "Mostrar nombres",
    CurrentValue = false,
    Flag = "NametagsEnhanced",
    Callback = function(s)
        nametagsEnhanced = s
        if playerESPEnhanced or nametagsEnhanced then startEnhancedESPLoop() else stopEnhancedESPLoop() end
    end
})

TabVisual:CreateToggle({
    Name = "Mostrar distancia",
    CurrentValue = false,
    Flag = "ShowDistance",
    Callback = function(s)
        showDistance = s
    end
})

TabVisual:CreateToggle({
    Name = "Generator ESP",
    CurrentValue = false,
    Flag = "GeneratorESPEnhanced",
    Callback = function(s)
        generatorESPEnhanced = s
        if s then startGeneratorEnhancedLoop() else stopGeneratorEnhancedLoop() end
    end
})

-- Inicializar conexiones y registros
refreshRoots()

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then watchPlayer(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LP then watchPlayer(p) end end)
Players.PlayerRemoving:Connect(function(p) unwatchPlayer(p) end)
