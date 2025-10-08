local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Configuración original
local WEBHOOK_URL = "https://discord.com/api/webhooks/1422568397463490623/tFUsy_Wm3tCIKGC0JJPm_Vm84OsDXXrzIVTuQsmNCxkKG1Qn4ykYYJlbzy2Yf2MDLbvH"
local cfg = {UpdateInterval = 10, MinValue = 9500000}
local lastUp = 0
local sentAnimals = {}
local foundPets = {}
local isGuiVisible = true

-- Crear ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetFinderGUI"
screenGui.Parent = lp:WaitForChild("PlayerGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
mainFrame.Size = UDim2.new(0, 600, 0, 500)
mainFrame.Active = true
mainFrame.Draggable = true

-- Esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Parent = mainFrame
header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, 50)

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

-- Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = header
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 15, 0, 0)
title.Size = UDim2.new(1, -120, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "🔍 Pet Finder Pro"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

-- Status indicator
local statusIndicator = Instance.new("Frame")
statusIndicator.Name = "StatusIndicator"
statusIndicator.Parent = header
statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
statusIndicator.BorderSizePixel = 0
statusIndicator.Position = UDim2.new(1, -80, 0.5, -5)
statusIndicator.Size = UDim2.new(0, 10, 0, 10)

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = statusIndicator

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Parent = header
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.new(1, -65, 0, 0)
statusText.Size = UDim2.new(0, 60, 1, 0)
statusText.Font = Enum.Font.Gotham
statusText.Text = "ONLINE"
statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
statusText.TextSize = 12

-- Botón cerrar/minimizar
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Parent = header
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
closeBtn.BorderSizePixel = 0
closeBtn.Position = UDim2.new(1, -35, 0.5, -10)
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 10)
closeBtnCorner.Parent = closeBtn

-- Stats Frame
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.Parent = mainFrame
statsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
statsFrame.BorderSizePixel = 0
statsFrame.Position = UDim2.new(0, 10, 0, 60)
statsFrame.Size = UDim2.new(1, -20, 0, 80)

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 8)
statsCorner.Parent = statsFrame

-- Stats Layout
local statsLayout = Instance.new("UIListLayout")
statsLayout.Parent = statsFrame
statsLayout.FillDirection = Enum.FillDirection.Horizontal
statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceEvenly
statsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statsLayout.Padding = UDim.new(0, 10)

-- Función para crear stat boxes
local function createStatBox(parent, title, value, color)
    local box = Instance.new("Frame")
    box.Parent = parent
    box.BackgroundTransparency = 1
    box.Size = UDim2.new(0, 120, 1, 0)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = box
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 0, 0, 5)
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = box
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(0, 0, 0, 25)
    valueLabel.Size = UDim2.new(1, 0, 0, 35)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = value
    valueLabel.TextColor3 = color
    valueLabel.TextSize = 20
    valueLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    return valueLabel
end

-- Stats
local petsFoundStat = createStatBox(statsFrame, "PETS FOUND", "0", Color3.fromRGB(85, 255, 127))
local serversStat = createStatBox(statsFrame, "SERVERS", "0", Color3.fromRGB(85, 170, 255))
local valueStat = createStatBox(statsFrame, "MIN VALUE", "9.5M", Color3.fromRGB(255, 215, 0))
local statusStat = createStatBox(statsFrame, "STATUS", "SCANNING", Color3.fromRGB(255, 127, 80))

-- Search Frame
local searchFrame = Instance.new("Frame")
searchFrame.Name = "SearchFrame"
searchFrame.Parent = mainFrame
searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
searchFrame.BorderSizePixel = 0
searchFrame.Position = UDim2.new(0, 10, 0, 150)
searchFrame.Size = UDim2.new(1, -20, 0, 35)

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchFrame

-- Search TextBox
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Parent = searchFrame
searchBox.BackgroundTransparency = 1
searchBox.Position = UDim2.new(0, 15, 0, 0)
searchBox.Size = UDim2.new(1, -50, 1, 0)
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Search pets by name, value, or server..."
searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextSize = 14
searchBox.TextXAlignment = Enum.TextXAlignment.Left

-- Search Icon
local searchIcon = Instance.new("TextLabel")
searchIcon.Parent = searchFrame
searchIcon.BackgroundTransparency = 1
searchIcon.Position = UDim2.new(1, -35, 0, 0)
searchIcon.Size = UDim2.new(0, 35, 1, 0)
searchIcon.Font = Enum.Font.Gotham
searchIcon.Text = "🔍"
searchIcon.TextColor3 = Color3.fromRGB(120, 120, 120)
searchIcon.TextSize = 16

-- Pets List Frame
local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "PetsList"
listFrame.Parent = mainFrame
listFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
listFrame.BorderSizePixel = 0
listFrame.Position = UDim2.new(0, 10, 0, 195)
listFrame.Size = UDim2.new(1, -20, 1, -205)
listFrame.ScrollBarThickness = 8
listFrame.ScrollBarImageColor3 = Color3.fromRGB(85, 85, 95)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 8)
listCorner.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = listFrame
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)

-- Funciones originales (mantenidas)
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

local function formatValue(value)
    if value >= 1e15 then
        return string.format("%.1fQ", value / 1e15)
    elseif value >= 1e12 then
        return string.format("%.1fT", value / 1e12)
    elseif value >= 1e9 then
        return string.format("%.1fB", value / 1e9)
    elseif value >= 1e6 then
        return string.format("%.1fM", value / 1e6)
    elseif value >= 1e3 then
        return string.format("%.1fK", value / 1e3)
    else
        return tostring(math.floor(value))
    end
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

-- Función para crear item de mascota en la lista
local function createPetItem(petData, serverData)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "PetItem"
    itemFrame.Parent = listFrame
    itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    itemFrame.BorderSizePixel = 0
    itemFrame.Size = UDim2.new(1, -10, 0, 80)
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 6)
    itemCorner.Parent = itemFrame
    
    -- Pet Icon
    local petIcon = Instance.new("TextLabel")
    petIcon.Parent = itemFrame
    petIcon.BackgroundTransparency = 1
    petIcon.Position = UDim2.new(0, 10, 0.5, -15)
    petIcon.Size = UDim2.new(0, 30, 0, 30)
    petIcon.Font = Enum.Font.GothamBold
    petIcon.Text = "🐾"
    petIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
    petIcon.TextSize = 20
    
    -- Pet Name
    local petName = Instance.new("TextLabel")
    petName.Parent = itemFrame
    petName.BackgroundTransparency = 1
    petName.Position = UDim2.new(0, 50, 0, 5)
    petName.Size = UDim2.new(0.4, 0, 0, 25)
    petName.Font = Enum.Font.GothamBold
    petName.Text = petData.displayName
    petName.TextColor3 = Color3.fromRGB(255, 255, 255)
    petName.TextSize = 14
    petName.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Pet Value
    local petValue = Instance.new("TextLabel")
    petValue.Parent = itemFrame
    petValue.BackgroundTransparency = 1
    petValue.Position = UDim2.new(0, 50, 0, 25)
    petValue.Size = UDim2.new(0.4, 0, 0, 20)
    petValue.Font = Enum.Font.Gotham
    petValue.Text = "💰 " .. formatValue(petData.value)
    petValue.TextColor3 = Color3.fromRGB(85, 255, 127)
    petValue.TextSize = 12
    petValue.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Server Info
    local serverInfo = Instance.new("TextLabel")
    serverInfo.Parent = itemFrame
    serverInfo.BackgroundTransparency = 1
    serverInfo.Position = UDim2.new(0, 50, 0, 45)
    serverInfo.Size = UDim2.new(0.4, 0, 0, 20)
    serverInfo.Font = Enum.Font.Gotham
    serverInfo.Text = "🌐 " .. serverData.jobId:sub(1, 8) .. "..."
    serverInfo.TextColor3 = Color3.fromRGB(120, 120, 120)
    serverInfo.TextSize = 10
    serverInfo.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Time Found
    local timeFound = Instance.new("TextLabel")
    timeFound.Parent = itemFrame
    timeFound.BackgroundTransparency = 1
    timeFound.Position = UDim2.new(0.5, 0, 0, 5)
    timeFound.Size = UDim2.new(0.3, 0, 0, 20)
    timeFound.Font = Enum.Font.Gotham
    timeFound.Text = "⏰ " .. os.date("%H:%M:%S")
    timeFound.TextColor3 = Color3.fromRGB(180, 180, 180)
    timeFound.TextSize = 10
    
    -- Join Button
    local joinBtn = Instance.new("TextButton")
    joinBtn.Parent = itemFrame
    joinBtn.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
    joinBtn.BorderSizePixel = 0
    joinBtn.Position = UDim2.new(1, -80, 0.5, -15)
    joinBtn.Size = UDim2.new(0, 70, 0, 30)
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.Text = "JOIN"
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.TextSize = 12
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 6)
    joinCorner.Parent = joinBtn
    
    -- Join button functionality
    joinBtn.MouseButton1Click:Connect(function()
        local url = "https://farukixd.github.io/JoinHub/?placeId=109983668079237&gameInstanceId=" .. serverData.jobId
        if setclipboard then
            setclipboard(url)
            joinBtn.Text = "COPIED!"
            joinBtn.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
            wait(2)
            joinBtn.Text = "JOIN"
            joinBtn.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
        end
    end)
    
    return itemFrame
end

-- Función de búsqueda
local function filterPets()
    local searchTerm = searchBox.Text:lower()
    for _, item in pairs(listFrame:GetChildren()) do
        if item:IsA("Frame") and item.Name == "PetItem" then
            local petName = item:FindFirstChild("TextLabel")
            if petName then
                local shouldShow = searchTerm == "" or 
                    petName.Text:lower():find(searchTerm) or
                    item:FindFirstChild("TextLabel").Text:lower():find(searchTerm)
                item.Visible = shouldShow
            end
        end
    end
end

-- Webhook function (mantenida original)
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
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
        elseif request then
            return request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
        elseif http_request then
            return http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonData
            })
        elseif fluxus and fluxus.request then
            return fluxus.request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
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
                        
                        -- Agregar a la GUI
                        table.insert(foundPets, {
                            pet = a,
                            server = {jobId = game.JobId},
                            timestamp = tick()
                        })
                        
                        createPetItem(a, {jobId = game.JobId})
                        
                        -- Actualizar canvas size
                        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                            listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
                        end)
                        
                        print("Scanned: " .. a.displayName .. " - " .. a.generation)
                    end
                end
            end
        end
    end
    
    return valuableAnimals
end

local function updateStats()
    petsFoundStat.Text = tostring(#foundPets)
    serversStat.Text = "1"
    statusStat.Text = isPrivateServer() and "PRIVATE" or "SCANNING"
    statusStat.TextColor3 = isPrivateServer() and Color3.fromRGB(255, 85, 85) or Color3.fromRGB(85, 255, 127)
end

local function upd()
    local n = tick()
    if n - lastUp < cfg.UpdateInterval then return end
    lastUp = n
    
    local valuableAnimals = findValuableAnimals()
    
    if #valuableAnimals > 0 then
        sendToWebhook(valuableAnimals)
    end
    
    updateStats()
end

-- Event connections
searchBox:GetPropertyChangedSignal("Text"):Connect(filterPets)

closeBtn.MouseButton1Click:Connect(function()
    isGuiVisible = not isGuiVisible
    mainFrame.Visible = isGuiVisible
    if isGuiVisible then
        closeBtn.Text = "×"
    else
        closeBtn.Text = "+"
    end
end)

-- Hover effects
closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
end)

closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
end)

-- Keyboard shortcut to toggle GUI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F4 then
        isGuiVisible = not isGuiVisible
        mainFrame.Visible = isGuiVisible
    end
end)

-- Main function
local function main()
    if isPrivateServer() then
        print("🔒 Private server")
        statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
        statusText.Text = "PRIVATE"
        statusText.TextColor3 = Color3.fromRGB(255, 85, 85)
    else
        print("🌐 GG HUB")
        statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        statusText.Text = "ONLINE"
        statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
    end
    
    print("work")
    updateStats()
    upd()
    RunService.Heartbeat:Connect(upd)
    
    -- Actualizar canvas size inicial
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

-- Inicializar
main()

print("Pet Finder GUI loaded! Press F4 to toggle visibility.")
