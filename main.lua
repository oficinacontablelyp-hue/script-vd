-- Cargar Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Servicios de Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- Funciones auxiliares
local function alive(i)
    if not i then return false end
    local ok = pcall(function() return i.Parent end)
    return ok and i.Parent ~= nil
end

local function validPart(p) return p and alive(p) and p:IsA("BasePart") end
local function clamp(n, lo, hi) if n < lo then return lo elseif n > hi then return hi else return n end end
local function dist(a, b) return (a - b).Magnitude end

local function firstBasePart(inst)
    if not alive(inst) then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") and alive(inst.PrimaryPart) then return inst.PrimaryPart end
        local p = inst:FindFirstChildWhichIsA("BasePart", true)
        if validPart(p) then return p end
    end
    if inst:IsA("Tool") then
        local h = inst:FindFirstChild("Handle") or inst:FindFirstChildWhichIsA("BasePart")
        if validPart(h) then return h end
    end
    return nil
end

local function makeBillboard(text, color3)
    local g = Instance.new("BillboardGui")
    g.Name = "VD_Tag"
    g.AlwaysOnTop = true
    g.Size = UDim2.new(0, 200, 0, 36)
    g.StudsOffset = Vector3.new(0, 3, 0)
    local l = Instance.new("TextLabel")
    l.Name = "Label"
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Font = Enum.Font.GothamBold
    l.Text = text
    l.TextSize = 14
    l.TextColor3 = color3 or Color3.new(1, 1, 1)
    l.TextStrokeTransparency = 0
    l.TextStrokeColor3 = Color3.new(0, 0, 0)
    l.Parent = g
    return g
end

local function clearChild(o, n)
    if o and alive(o) then
        local c = o:FindFirstChild(n)
        if c then pcall(function() c:Destroy() end) end
    end
end

local function ensureHighlight(model, fill)
    if not (model and model:IsA("Model") and alive(model)) then return end
    local hl = model:FindFirstChild("VD_HL")
    if not hl then
        local ok, obj = pcall(function()
            local h = Instance.new("Highlight")
            h.Name = "VD_HL"
            h.Adornee = model
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = model
            return h
        end)
        if ok then hl = obj else return end
    end
    hl.FillColor = fill
    hl.OutlineColor = fill
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return hl
end

local function clearHighlight(model)
    if model and model:FindFirstChild("VD_HL") then
        pcall(function() model.VD_HL:Destroy() end)
    end
end

-- Crear la ventana principal
local Window = Rayfield:CreateWindow({
    Name = "LoreOnTop",
    LoadingTitle = "Violence District",
    LoadingSubtitle = "by Lore",
    ConfigurationSaving = {Enabled = true, FolderName = "ESP_Suite", FileName = "esp_config"},
    KeySystem = false
})

-- Crear pestaña ESP
local Tab = Window:CreateTab("Visual")
Tab:CreateSection("ESP")

-- Función para obtener el rol del jugador
local function getRole(p)
    local tn = p.Team and p.Team.Name and p.Team.Name:lower() or ""
    if tn:find("killer") then return "Killer" end
    if tn:find("survivor") then return "Survivor" end
    return "Survivor"
end

-- Variables para ESP de players
local survivorColor = Color3.fromRGB(0, 255, 0)  -- Verde
local killerColor = Color3.fromRGB(255, 0, 0)    -- Rojo
local playerESPEnabled = false
local nametagsEnabled = false
local showDistance = true  -- Siempre mostrar distancia
local maxDistance = 500
local playerConns = {}
local espLoopConn = nil

-- Función para aplicar ESP a un player
local function applyOnePlayerESP(p)
    if p == LP then return end
    local c = p.Character
    if not (c and alive(c)) then return end
    local role = getRole(p)
    local col = (role == "Killer") and killerColor or survivorColor
    local head = c:FindFirstChild("Head")
    local hrp = c:FindFirstChild("HumanoidRootPart")
    
    if playerESPEnabled then
        ensureHighlight(c, col)
        if nametagsEnabled and validPart(head) then
            local tag = head:FindFirstChild("VD_Tag") or makeBillboard("", col)
            tag.Name = "VD_Tag"
            tag.Parent = head
            local l = tag:FindFirstChild("Label")
            if l then
                local text = p.Name
                if showDistance and hrp and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor(dist(hrp.Position, LP.Character.HumanoidRootPart.Position))
                    text = text .. " - " .. dist .. "m"
                end
                l.Text = text
                l.TextColor3 = col
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

-- Loops para ESP de players
local function startESPLoop()
    if espLoopConn then return end
    espLoopConn = RunService.Heartbeat:Connect(function()
        if not playerESPEnabled and not nametagsEnabled then return end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then applyOnePlayerESP(pl) end
        end
    end)
end

local function stopESPLoop()
    if espLoopConn then espLoopConn:Disconnect() espLoopConn = nil end
end

-- Función para watch players
local function watchPlayer(p)
    if playerConns[p] then for _, cn in ipairs(playerConns[p]) do cn:Disconnect() end end
    playerConns[p] = {}
    table.insert(playerConns[p], p.CharacterAdded:Connect(function()
        task.delay(0.15, function() applyOnePlayerESP(p) end)
    end))
    table.insert(playerConns[p], p:GetPropertyChangedSignal("Team"):Connect(function() applyOnePlayerESP(p) end))
    if p.Character then applyOnePlayerESP(p) end
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

-- Toggles para ESP de players
Tab:CreateToggle({
    Name = "Players ESP",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(s)
        playerESPEnabled = s
        if playerESPEnabled or nametagsEnabled then startESPLoop() else stopESPLoop() end
    end
})

Tab:CreateToggle({
    Name = "Names/Distance",
    CurrentValue = false,
    Flag = "Nametags",
    Callback = function(s)
        nametagsEnabled = s
        if playerESPEnabled or nametagsEnabled then startESPLoop() else stopESPLoop() end
    end
})

Tab:CreateColorPicker({
    Name = "Survivor Color",
    Color = survivorColor,
    Flag = "SurvivorCol",
    Callback = function(c) survivorColor = c end
})

Tab:CreateColorPicker({
    Name = "Killer Color",
    Color = killerColor,
    Flag = "KillerCol",
    Callback = function(c) killerColor = c end
})

-- Inicializar ESP de players
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then watchPlayer(p) end end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(unwatchPlayer)

-- Sección para Generators
TabESP:CreateSection("Generators")

-- Variables para ESP de generators
local generatorESPEnabled = false
local generatorColor = Color3.fromRGB(0, 170, 255)  -- Azul
local generatorTextPrefix = "Gen"  -- Prefijo personalizable para el texto
local worldReg = {Generator = {}}
local mapAdd, mapRem = {}, {}

-- Función para progreso de generator
local function genProgress(m)
    local p = tonumber(m:GetAttribute("RepairProgress")) or 0
    if p <= 1.001 then p = p * 100 end
    return clamp(p, 0, 100)
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

-- Función para aplicar ESP a generators (usando Highlight para glow)
local function applyEnhancedGeneratorESP(entry)
    local model = entry.model
    local part = entry.part
    if not generatorESPEnabled or not alive(model) or not validPart(part) then return end
    local pct = genProgress(model)
    local dynamicCol = (pct >= 100) and Color3.fromRGB(0, 255, 0) or generatorColor  -- Azul si no completado, verde si completado
    -- Usar Highlight para glow en el modelo
    local hl = ensureHighlight(model, dynamicCol)
    if hl then
        hl.FillTransparency = 0.7  -- Más transparente para glow
        hl.OutlineTransparency = 0.2
    end
    -- Etiqueta de texto
    local textName = "VD_Text_Generator_Enhanced"
    local bb = part:FindFirstChild(textName)
    if not bb then
        bb = makeBillboard("", dynamicCol)
        bb.Name = textName
        bb.Parent = part
    end
    local lbl = bb:FindFirstChild("Label")
    if lbl then
        local txt = "Gen" .. math.floor(pct + 0.5) .. "%"
        lbl.Text = txt
        lbl.TextColor3 = dynamicCol
    end
end

local generatorEnhancedLoopConn = nil
local function startGeneratorEnhancedLoop()
    if generatorEnhancedLoopConn then return end
    generatorEnhancedLoopConn = RunService.Heartbeat:Connect(function()
        if not generatorESPEnabled then return end
        for _, entry in pairs(worldReg.Generator) do
            applyEnhancedGeneratorESP(entry)
        end
    end)
end

local function stopGeneratorEnhancedLoop()
    if generatorEnhancedLoopConn then generatorEnhancedLoopConn:Disconnect() generatorEnhancedLoopConn = nil end
    for _, entry in pairs(worldReg.Generator) do
        if entry.model then
            clearHighlight(entry.model)
            clearChild(entry.part, "VD_Text_Generator_Enhanced")
        end
    end
end

-- Toggle para Generator ESP
Tab:CreateToggle({
    Name = "Generator ESP",
    CurrentValue = false,
    Flag = "GeneratorESP",
    Callback = function(s)
        generatorESPEnabled = s
        if s then startGeneratorEnhancedLoop() else stopGeneratorEnhancedLoop() end
    end
})

Tab:CreateColorPicker({
    Name = "Generator Color (Base)",
    Color = generatorColor,
    Flag = "GenCol",
    Callback = function(c) generatorColor = c end
})

-- Inicializar generators
refreshRoots()

local Tab = Window:CreateTab("Survivors")
Tab:CreateSection("Generators")

local Tab = Window:CreateTab("Killers")
Tab:CreateSection("Survivors")

local Tab = Window:CreateTab("Graphics")
Tab:CreateSection("Optimization")

-- Cargar configuración y notificar
Rayfield:LoadConfiguration()
Rayfield:Notify({Title = "ESP Suite", Content = "Loaded", Duration = 6})
