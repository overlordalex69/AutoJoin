local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local lp = Players.LocalPlayer
local WEBHOOK_URL = "https://discord.com/api/webhooks/1422568397463490623/tFUsy_Wm3tCIKGC0JJPm_Vm84OsDXXrzIVTuQsmNCxkKG1Qn4ykYYJlbzy2Yf2MDLbvH"

-- Configuración
local cfg = {
    UpdateInterval = 10, 
    MinValue = 9500000,
    MaxLogEntries = 100
}

local lastUp = 0
local sentAnimals = {}
local petLog = {}
local gui = nil
local logFrame = nil
local searchBox = nil
local logList = nil
local isGuiOpen = false

-- Funciones del script original (sin modificar)
local function isPrivateServer()
    return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

local function isTimeFormat(s)
    if not s or type(s) ~= "string" then return false end
    return s:match("%d+m%s*%d+s") ~= nil or s:match("%d+m") ~= nil or s:match("%d+s") ~= nil
end

local function parseVal(s)
    if not s or type(s) ~= "string" then return 0 end
    if isTimeFormat(s) then return 0 end
    
    local cl = s:gsub("%$", ""):gsub("/s", ""):gsub("/S", ""):lower()
    local m = {k = 1e3, m = 1e6, b = 1e9, t = 1e12, q = 1e15}
    local n, su = cl:match("([%d%.]+)([kmbtq]?)")
    n = tonumber(n) or 0
    if su and m[su] then n = n * m[su] end
    return n
end

local function getDispName()
    return lp.DisplayName
end

local function isMyPlot(p)
    local s, sg = pcall(function() return p:FindFirstChild("PlotSign") end)
    if not s or not sg then return false end
    local s2, lb = pcall(function() return sg.SurfaceGui.Frame.TextLabel end)
    if not s2 or not lb then return false end
    local t = lb.Text or ""
    local n = getDispName()
    return string.find(t:lower(), n:lower()) ~= nil
end

local function findAnims(p)
    local a = {}
    local function srch(o)
        for _, c in pairs(o:GetChildren()) do
            if c.Name == "AnimalPodiums" then
                for _, pd in pairs(c:GetChildren()) do
                    local s, d = pcall(function()
                        local bs = pd:FindFirstChild("Base")
                        local sp = bs and bs:FindFirstChild("Spawn")
                        local at = sp and sp:FindFirstChild("Attachment")
                        local oh = at and at:FindFirstChild("AnimalOverhead")
                        local dp = oh and oh:FindFirstChild("DisplayName")
                        local gn = oh and oh:FindFirstChild("Generation")
                        if dp and gn then
                            return {
                                displayName = dp.Text, 
                                generation = gn.Text, 
                                position = sp.Position, 
                                object = sp,
                                value = parseVal(gn.Text)
                            }
                        end
                    end)
                    if s and d then table.insert(a, d) end
                end
            else 
                srch(c) 
            end
        end
    end
    srch(p)
    return a
end

-- Función de webhook original (sin modificar)
local function sendToWebhook(animals)
    if #animals == 0 then return end
    
    if isPrivateServer() then
        print("table")
        return
    end
    
    local jobId = game.JobId
    local embeds = {}
    
    for _, animal in pairs(animals) do
        local embed = {
            ["title"] = "Valuable Brainrot Found!",
            ["color"] = 65280,
            ["fields"] = {
                {
                    ["name"] = "- Name",
                    ["value"] = animal.displayName,
                    ["inline"] = true
                },
                {
                    ["name"] = "- Value",
                    ["value"] = animal.generation,
                    ["inline"] = true
                },
                {
                    ["name"] = "- JobID",
                    ["value"] = "https://farukixd.github.io/JoinHub/?placeId=109983668079237&gameInstanceId=" .. jobId,
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Pet Finder | Backup"
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }
        
        table.insert(embeds, embed)
    end
    
    local payload = {
        ["embeds"] = embeds,
        ["username"] = "Pet Finder"
    }
    
    local success, result = pcall(function()
        local jsonData = HttpService:JSONEncode(payload)
        
        if syn and syn.request then
            return syn.request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        elseif request then
            return request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        elseif http_request then
            return http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        elseif fluxus and fluxus.request then
            return fluxus.request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        else
            return HttpService:PostAsync(WEBHOOK_URL, jsonData)
        end
    end)
    
    if success then
        print("e: " .. #animals .. " pet")
    else
        warn("e: " .. tostring(result))
    end
end

-- Funciones de la interfaz GUI
local function createGUI()
    -- Crear ScreenGui principal
    gui = Instance.new("ScreenGui")
    gui.Name = "PetFinderGUI"
    gui.ResetOnSpawn = false
    gui.Parent = lp:WaitForChild("PlayerGui")
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui
    
    -- Esquinas redondeadas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔍 Pet Finder - Log en Tiempo Real"
    titleLabel.TextColor3 = Color3.white
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = titleBar
    
    -- Botón cerrar
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.white
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    -- Barra de búsqueda
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -20, 0, 50)
    searchFrame.Position = UDim2.new(0, 10, 0, 50)
    searchFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = mainFrame
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchFrame
    
    searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -20, 1, -10)
    searchBox.Position = UDim2.new(0, 10, 0, 5)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "🔍 Buscar mascota por nombre o valor..."
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.white
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.TextScaled = true
    searchBox.Font = Enum.Font.Gotham
    searchBox.Parent = searchFrame
    
    -- Frame del log
    logFrame = Instance.new("ScrollingFrame")
    logFrame.Name = "LogFrame"
    logFrame.Size = UDim2.new(1, -20, 1, -120)
    logFrame.Position = UDim2.new(0, 10, 0, 110)
    logFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    logFrame.BorderSizePixel = 0
    logFrame.ScrollBarThickness = 8
    logFrame.Parent = mainFrame
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 8)
    logCorner.Parent = logFrame
    
    -- Lista del log
    logList = Instance.new("UIListLayout")
    logList.SortOrder = Enum.SortOrder.LayoutOrder
    logList.Padding = UDim.new(0, 5)
    logList.Parent = logFrame
    
    -- Hacer el frame arrastrable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                         startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Función para cerrar GUI
    closeButton.MouseButton1Click:Connect(function()
        toggleGUI()
    end)
    
    -- Búsqueda en tiempo real
    searchBox.Changed:Connect(function()
        updateLogDisplay()
    end)
    
    mainFrame.Visible = false
end

local function addLogEntry(animal, jobId, timestamp)
    local entry = {
        name = animal.displayName,
        value = animal.generation,
        numericValue = animal.value,
        jobId = jobId,
        timestamp = timestamp or os.date("%H:%M:%S"),
        joinUrl = "https://farukixd.github.io/JoinHub/?placeId=109983668079237&gameInstanceId=" .. jobId
    }
    
    table.insert(petLog, 1, entry) -- Insertar al principio
    
    -- Limitar el número de entradas
    if #petLog > cfg.MaxLogEntries then
        table.remove(petLog, #petLog)
    end
    
    updateLogDisplay()
end

local function createLogEntry(entry, index)
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = "LogEntry" .. index
    entryFrame.Size = UDim2.new(1, -10, 0, 80)
    entryFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    entryFrame.BorderSizePixel = 0
    entryFrame.LayoutOrder = index
    entryFrame.Parent = logFrame
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 6)
    entryCorner.Parent = entryFrame
    
    -- Información de la mascota
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "🐾 " .. entry.name
    nameLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entryFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, 0, 0.4, 0)
    valueLabel.Position = UDim2.new(0.4, 0, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "💎 " .. entry.value
    valueLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    valueLabel.TextScaled = true
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Parent = entryFrame
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0.3, 0, 0.3, 0)
    timeLabel.Position = UDim2.new(0.7, 0, 0, 5)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "⏰ " .. entry.timestamp
    timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    timeLabel.TextScaled = true
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = entryFrame
    
    -- Botón para unirse al servidor
    local joinButton = Instance.new("TextButton")
    joinButton.Size = UDim2.new(0.8, 0, 0.4, 0)
    joinButton.Position = UDim2.new(0.1, 0, 0.5, 0)
    joinButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    joinButton.Text = "🚀 Unirse al Servidor"
    joinButton.TextColor3 = Color3.white
    joinButton.TextScaled = true
    joinButton.Font = Enum.Font.GothamBold
    joinButton.BorderSizePixel = 0
    joinButton.Parent = entryFrame
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 4)
    joinCorner.Parent = joinButton
    
    -- Animación del botón
    joinButton.MouseEnter:Connect(function()
        TweenService:Create(joinButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 200, 0)}):Play()
    end)
    
    joinButton.MouseLeave:Connect(function()
        TweenService:Create(joinButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 180, 0)}):Play()
    end)
    
    -- Función para unirse al servidor
    joinButton.MouseButton1Click:Connect(function()
        local success = pcall(function()
            -- Intentar usar el enlace personalizado primero
            if syn and syn.request then
                syn.request({
                    Url = entry.joinUrl,
                    Method = "GET"
                })
            elseif request then
                request({
                    Url = entry.joinUrl,
                    Method = "GET"
                })
            else
                -- Fallback usando TeleportService
                TeleportService:TeleportToPlaceInstance(109983668079237, entry.jobId)
            end
        end)
        
        if success then
            print("Intentando unirse al servidor: " .. entry.jobId)
        else
            warn("Error al intentar unirse al servidor")
        end
    end)
end

local function updateLogDisplay()
    -- Limpiar entradas existentes
    for _, child in pairs(logFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local searchTerm = searchBox.Text:lower()
    local filteredLog = {}
    
    -- Filtrar por búsqueda
    for _, entry in pairs(petLog) do
        if searchTerm == "" or 
           entry.name:lower():find(searchTerm) or 
           entry.value:lower():find(searchTerm) or
           tostring(entry.numericValue):find(searchTerm) then
            table.insert(filteredLog, entry)
        end
    end
    
    -- Crear entradas filtradas
    for i, entry in pairs(filteredLog) do
        createLogEntry(entry, i)
    end
    
    -- Actualizar canvas size
    logFrame.CanvasSize = UDim2.new(0, 0, 0, #filteredLog * 85)
end

local function toggleGUI()
    if not gui then
        createGUI()
    end
    
    isGuiOpen = not isGuiOpen
    gui.MainFrame.Visible = isGuiOpen
    
    if isGuiOpen then
        -- Animación de apertura
        gui.MainFrame.Size = UDim2.new(0, 0, 0, 0)
        gui.MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        TweenService:Create(gui.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 600, 0, 500),
            Position = UDim2.new(0.5, -300, 0.5, -250)
        }):Play()
        
        updateLogDisplay()
    end
end

-- Función mejorada para encontrar mascotas valiosas
local function findValuableAnimals()
    local valuableAnimals = {}
    local plts = Workspace:FindFirstChild("Plots")
    if not plts then 
        warn("plot unfound")
        return valuableAnimals 
    end
    
    for _, p in pairs(plts:GetChildren()) do
        if not isMyPlot(p) then
            local anims = findAnims(p)
            for _, a in pairs(anims) do
                if a.value >= cfg.MinValue then
                    local animalKey = a.displayName .. "_" .. tostring(a.value) .. "_" .. game.JobId
                    if not sentAnimals[animalKey] then
                        table.insert(valuableAnimals, a)
                        sentAnimals[animalKey] = true
                        print("Scanned: " .. a.displayName .. " - " .. a.generation)
                        
                        -- Agregar al log de la GUI
                        addLogEntry(a, game.JobId)
                    end
                end
            end
        end
    end
    
    return valuableAnimals
end

-- Función de actualización original (sin modificar el webhook)
local function upd()
    local n = tick()
    if n - lastUp < cfg.UpdateInterval then return end
    lastUp = n
    
    local valuableAnimals = findValuableAnimals()
    
    if #valuableAnimals > 0 then
        sendToWebhook(valuableAnimals) -- Función original sin modificar
    end
end

-- Función principal
local function main()
    if isPrivateServer() then
        print("🔒 Private server")
    else
        print("🌐 GG HUB")
    end
    
    print("Pet Finder iniciado - Presiona 'P' para abrir/cerrar la interfaz")
    
    -- Crear GUI inicial
    createGUI()
    
    -- Tecla para abrir/cerrar GUI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
            toggleGUI()
        end
    end)
    
    print("work")
    upd()
    RunService.Heartbeat:Connect(upd)
end

-- Iniciar el script
main()
