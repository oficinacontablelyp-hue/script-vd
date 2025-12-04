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
Tab:CreateSection("Generators")

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

-- Sección Disable Visual Effects
local disableEffectsEnabled = false
local effectsStore = {}

local function saveEffectsState()
    effectsStore = {}
    for _, eff in ipairs(Lighting:GetChildren()) do
        if eff:IsA("BloomEffect") or eff:IsA("DepthOfFieldEffect") or eff:IsA("SunRaysEffect") or eff:IsA("ColorCorrectionEffect") then
            effectsStore[eff] = {Enabled = eff.Enabled}
        end
    end
    for _, eff in ipairs(Workspace:GetChildren()) do
        if eff:IsA("BloomEffect") or eff:IsA("DepthOfFieldEffect") or eff:IsA("SunRaysEffect") or eff:IsA("ColorCorrectionEffect") then
            effectsStore[eff] = {Enabled = eff.Enabled}
        end
    end
end

local function applyDisableEffects()
    for eff, state in pairs(effectsStore) do
        if eff and eff.Parent then
            pcall(function() eff.Enabled = false end)
        end
    end
end

local function restoreEffectsState()
    for eff, state in pairs(effectsStore) do
        if eff and eff.Parent and state.Enabled ~= nil then
            pcall(function() eff.Enabled = state.Enabled end)
        end
    end
end

local function setDisableEffects(state)
    if state then
        if not disableEffectsEnabled then
            disableEffectsEnabled = true
            saveEffectsState()
            applyDisableEffects()
            Rayfield:Notify({Title = "Disable Visual Effects", Content = "Enabled - Effects disabled for better performance", Duration = 4})
        end
    else
        if disableEffectsEnabled then
            disableEffectsEnabled = false
            restoreEffectsState()
            Rayfield:Notify({Title = "Disable Visual Effects", Content = "Disabled - Effects restored", Duration = 4})
        end
    end
end

Tab:CreateToggle({
    Name = "Disable Visual Effects",
    CurrentValue = false,
    Flag = "DisableEffects",
    Callback = function(s) setDisableEffects(s) end
})

-- Sección Simplify Materials
local simplifyMaterialsEnabled = false
local materialsStore = {}

local function saveMaterialsState()
    materialsStore = {}
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            materialsStore[part] = {Material = part.Material}
        end
    end
end

local function applySimplifyMaterials()
    for part, state in pairs(materialsStore) do
        if part and part.Parent then
            pcall(function() part.Material = Enum.Material.Plastic end)
        end
    end
end

local function restoreMaterialsState()
    for part, state in pairs(materialsStore) do
        if part and part.Parent and state.Material ~= nil then
            pcall(function() part.Material = state.Material end)
        end
    end
end

local function setSimplifyMaterials(state)
    if state then
        if not simplifyMaterialsEnabled then
            simplifyMaterialsEnabled = true
            saveMaterialsState()
            applySimplifyMaterials()
            Rayfield:Notify({Title = "Simplify Materials", Content = "Enabled - Materials simplified for better performance", Duration = 4})
        end
    else
        if simplifyMaterialsEnabled then
            simplifyMaterialsEnabled = false
            restoreMaterialsState()
            Rayfield:Notify({Title = "Simplify Materials", Content = "Disabled - Materials restored", Duration = 4})
        end
    end
end

Tab:CreateToggle({
    Name = "Simplify Materials",
    CurrentValue = false,
    Flag = "SimplifyMaterials",
    Callback = function(s) setSimplifyMaterials(s) end
})

-- Sección Low Lighting Quality
local lowLightingEnabled = false
local lightingStore = {}

local function saveLightingState()
    lightingStore = {
        ShadowSoftness = Lighting:FindFirstChild("ShadowSoftness") and Lighting.ShadowSoftness or nil,
        Technology = Lighting.Technology,
        GlobalShadows = Lighting.GlobalShadows
    }
end

local function applyLowLighting()
    pcall(function()
        Lighting.ShadowSoftness = 0
        Lighting.Technology = Enum.Technology.Compatibility
        Lighting.GlobalShadows = false
    end)
end

local function restoreLightingState()
    for k, v in pairs(lightingStore) do
        pcall(function() if v ~= nil then Lighting[k] = v end end)
    end
end

local function setLowLighting(state)
    if state then
        if not lowLightingEnabled then
            lowLightingEnabled = true
            saveLightingState()
            applyLowLighting()
            Rayfield:Notify({Title = "Low Lighting Quality", Content = "Enabled - Lighting optimized for performance", Duration = 4})
        end
    else
        if lowLightingEnabled then
            lowLightingEnabled = false
            restoreLightingState()
            Rayfield:Notify({Title = "Low Lighting Quality", Content = "Disabled - Lighting restored", Duration = 4})
        end
    end
end

Tab:CreateToggle({
    Name = "Low Lighting Quality",
    CurrentValue = false,
    Flag = "LowLighting",
    Callback = function(s) setLowLighting(state) end
})

-- Sección No Shadows
local nsActive = false
local nsStore = {lighting = {}, parts = setmetatable({}, {__mode = "k"}), conns = {}}
local nsQueue, nsQueued, nsProcessed = {}, setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "k"})
local nsSignal = Instance.new("BindableEvent")
local nsBatchSize, nsTickDelay = 400, 0.02

local function nsSaveLighting()
    nsStore.lighting = {GlobalShadows = Lighting.GlobalShadows, Technology = Lighting.Technology}
end

local function nsApplyLighting()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.Technology = Enum.Technology.Compatibility
    end)
end

local function nsRestoreLighting()
    for k, v in pairs(nsStore.lighting or {}) do pcall(function() if v ~= nil then Lighting[k] = v end end) end
end

local function nsIsCandidate(o) return o and o:IsA("BasePart") end

local function nsSavePart(p) if nsStore.parts[p] == nil then nsStore.parts[p] = {CastShadow = p.CastShadow} end end

local function nsHandlePart(p) if nsProcessed[p] then return end nsProcessed[p] = true nsSavePart(p) pcall(function() p.CastShadow = false end) end

local function nsEnqueue(o) if nsActive and nsIsCandidate(o) and not nsQueued[o] then nsQueued[o] = true table.insert(nsQueue, o) nsSignal:Fire() end end

local function nsProcessQueue()
    while nsActive do
        if #nsQueue == 0 then nsSignal.Event:Wait() end
        local c = 0
        while nsActive and #nsQueue > 0 and c < nsBatchSize do
            local o = table.remove(nsQueue, 1)
            if o and o.Parent then nsHandlePart(o) end
            c = c + 1
        end
        task.wait(nsTickDelay)
    end
end

local function nsSoftRescan()
    for _, root in ipairs({Workspace, Workspace:FindFirstChild("Map"), Workspace:FindFirstChild("Terrain")}) do
        if root then for _, d in ipairs(root:GetDescendants()) do if nsIsCandidate(d) then nsEnqueue(d) end end end
    end
end

local function nsBindWatchers()
    local a = Workspace.DescendantAdded:Connect(function(d) if nsIsCandidate(d) then nsEnqueue(d) end end)
    local b = Workspace.ChildAdded:Connect(function(ch) if ch.Name == "Map" or ch.Name == "Map1" then task.delay(0.2, nsSoftRescan) end end)
    local c = RunService.Heartbeat:Connect(function()
        local t = os.clock()
        if t - nsLastSoft >= nsSoftRescanInterval then nsLastSoft = t nsSoftRescan() end
    end)
    table.insert(nsStore.conns, a)
    table.insert(nsStore.conns, b)
    table.insert(nsStore.conns, c)
end

local nsThread = nil
local nsSoftRescanInterval, nsLastSoft = 6, 0

local function nsEnable()
    if nsActive then return end
    nsActive = true
    nsQueue, nsQueued, nsProcessed = {}, setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "k"})
    nsSaveLighting()
    nsApplyLighting()
    nsSoftRescan()
    nsBindWatchers()
    if not nsThread then nsThread = task.spawn(nsProcessQueue) end
end

local function nsDisable()
    if not nsActive then return end
    nsActive = false
    for p, st in pairs(nsStore.parts) do if p and p.Parent and st and st.CastShadow ~= nil then pcall(function() p.CastShadow = st.CastShadow end) end end
    nsStore.parts = setmetatable({}, {__mode = "k"})
    for _, c in ipairs(nsStore.conns) do pcall(function() c:Disconnect() end) end
    nsStore.conns = {}
    nsRestoreLighting()
    nsQueue, nsQueued, nsProcessed = {}, setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "k"})
    nsSignal:Fire()
    nsThread = nil
end

Tab:CreateToggle({
  Name = "No Shadows",
  CurrentValue = false,
  Flag = "NoShadows",
  Callback = function(s) if s then nsEnable() else nsDisable()
    end
end
})

-- Sección No Fog
local nfActive = false
local nfStore = {conns = {}, tick = nil}
local nfQueue, nfQueued = {}, setmetatable({}, {__mode = "k"})

local function nfNameHasFog(inst)
    local n = inst and inst.Name or ""
    n = string.lower(n)
    return string.find(n, "fog", 1, true) ~= nil
end

local function nfHardNuke(o)
    pcall(function()
        for _, d in ipairs(o:GetDescendants()) do
            if d:IsA("ParticleEmitter") then pcall(function() d.Enabled = false d.Rate = 0 end) end
        end
        o:Destroy()
    end)
end

local function nfIsCandidate(inst)
    if not inst or not inst.Parent then return false end
    if nfNameHasFog(inst) then return true end
    if inst:IsA("Clouds") or inst:IsA("Atmosphere") then return true end
    if inst:IsA("ParticleEmitter") then return true end
    if inst:IsA("SunRaysEffect") or inst:IsA("BloomEffect") or inst:IsA("DepthOfFieldEffect") then return true end
    return false
end

local function nfHandle(inst)
    if not inst or not inst.Parent then return end
    if nfNameHasFog(inst) then
        nfHardNuke(inst)
        return
    end
    if inst:IsA("Clouds") or inst:IsA("Atmosphere") then
        nfHardNuke(inst)
        return
    end
    if inst:IsA("ParticleEmitter") then
        nfHardNuke(inst)
        return
    end
    if inst:IsA("SunRaysEffect") or inst:IsA("BloomEffect") or inst:IsA("DepthOfFieldEffect") then
        nfHardNuke(inst)
        return
    end
    for _, d in ipairs(inst:GetDescendants()) do
        if nfNameHasFog(d) or d:IsA("ParticleEmitter") then nfHardNuke(d) end
    end
end

local function nfEnqueueOne(inst)
    if not nfActive or not nfIsCandidate(inst) or nfQueued[inst] then return end
    nfQueued[inst] = true
    table.insert(nfQueue, inst)
end

local function nfBindWatchers()
    local c1 = Workspace.DescendantAdded:Connect(function(d) nfEnqueueOne(d) end)
    local c2 = Lighting.DescendantAdded:Connect(function(d) nfEnqueueOne(d) end)
    local c3 = ReplicatedStorage.DescendantAdded:Connect(function(d) nfEnqueueOne(d) end)
    table.insert(nfStore.conns, c1)
    table.insert(nfStore.conns, c2)
    table.insert(nfStore.conns, c3)
end

local function nfStartQueue()
    if nfStore.tick then nfStore.tick:Disconnect() nfStore.tick = nil end
    nfStore.tick = RunService.Heartbeat:Connect(function()
        if not nfActive then return end
        local t0 = os.clock()
        while #nfQueue > 0 and (os.clock() - t0) < 0.004 do
            local inst = table.remove(nfQueue, 1)
            if inst and inst.Parent then nfHandle(inst) end
        end
    end)
end

local function nfInitialSweep()
    for _, root in ipairs({Workspace, Lighting, ReplicatedStorage}) do
        for _, d in ipairs(root:GetDescendants()) do
            if nfIsCandidate(d) then nfHandle(d) end
        end
    end
end

local function nfEnable()
    if nfActive then return end
    nfActive = true
    nfInitialSweep()
    nfBindWatchers()
    nfStartQueue()
end

local function nfDisable()
    if not nfActive then return end
    nfActive = false
    if nfStore.tick then pcall(function() nfStore.tick:Disconnect() end) nfStore.tick = nil end
    for _, c in ipairs(nfStore.conns) do pcall(function() c:Disconnect() end) end
    nfStore.conns = {}
    nfQueue, nfQueued = {}, setmetatable({}, {__mode = "k"})
end

TabVisual:CreateToggle({
  Name = "No Fog",
  CurrentValue = false,
  Flag = "NoFog",
  Callback = function(s) if s then nfEnable() else nfDisable()
    end
end
})

-- Cargar configuración y notificar
Rayfield:LoadConfiguration()
Rayfield:Notify({Title = "LoreOnTop", Content = "Loaded", Duration = 6})
