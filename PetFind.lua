--// Pet Finder Interface - Complete Version
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local lp = Players.LocalPlayer

-- Configuración
local cfg = {
    UpdateInterval = 10, 
    MinValue = 9500000,
    WebhookURL = "https://discord.com/api/webhooks/1422568397463490623/tFUsy_Wm3tCIKGC0JJPm_Vm84OsDXXrzIVTuQsmNCxkKG1Qn4ykYYJlbzy2Yf2MDLbvH"
}

local lastUp = 0
local sentAnimals = {}
local foundPets = {}
local isScanning = false

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Pet Finder Pro",
    LoadingTitle = "Pet Finder Pro",
    LoadingSubtitle = "by overlordalex69",
    ConfigurationSaving = { Enabled = true, FolderName = "PetFinderPro" },
    Discord = { Enabled = false },
    KeySystem = false
})

-- Tabs
local MainTab = Window:CreateTab("Scanner", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local PetsTab = Window:CreateTab("Found Pets", 4483362458)

-- Variables para UI
local petsList = {}
local currentMinValue = cfg.MinValue
local currentInterval = cfg.UpdateInterval

-- Utility Functions
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
        return string.format("%.2fQ", value / 1e15)
    elseif value >= 1e12 then
        return string.format("%.2fT", value / 1e12)
    elseif value >= 1e9 then
        return string.format("%.2fB", value / 1e9)
    elseif value >= 1e6 then
        return string.format("%.2fM", value / 1e6)
    elseif value >= 1e3 then
        return string.format("%.2fK", value / 1e3)
    else
        return tostring(value)
    end
end

local function notify(title, content, duration)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration or 4,
        Image = 4483362458,
    })
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
                                value = parseVal(gn.Text),
                                jobId = game.JobId,
                                timestamp = os.time()
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

local function joinServer(jobId)
    if not jobId or jobId == "" then
        notify("Error", "Invalid JobID")
        return
    end
    
    notify("Joining Server", "Attempting to join server...", 5)
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(109983668079237, jobId, lp)
    end)
    
    if not success then
        notify("Join Failed", "Could not join server: " .. tostring(err))
    end
end

local function updatePetsList()
    -- Clear existing buttons
    for i = #petsList, 1, -1 do
        if petsList[i] and petsList[i].Destroy then
            petsList[i]:Destroy()
        end
        table.remove(petsList, i)
    end
    
    -- Add new buttons for found pets
    for i, pet in ipairs(foundPets) do
        if i <= 10 then -- Limit to 10 most recent
            local button = PetsTab:CreateButton({
                Name = pet.displayName .. " - " .. formatValue(pet.value) .. " (" .. pet.jobId:sub(1, 8) .. "...)",
                Callback = function()
                    joinServer(pet.jobId)
                end,
            })
            table.insert(petsList, button)
        end
    end
end

local function findValuableAnimals()
    local valuableAnimals = {}
    local plts = Workspace:FindFirstChild("Plots")
    if not plts then 
        return valuableAnimals 
    end
    
    for _, p in pairs(plts:GetChildren()) do
        if not isMyPlot(p) then
            local anims = findAnims(p)
            for _, a in pairs(anims) do
                if a.value >= currentMinValue then
                    local animalKey = a.displayName .. "_" .. tostring(a.value) .. "_" .. game.JobId
                    if not sentAnimals[animalKey] then
                        table.insert(valuableAnimals, a)
                        table.insert(foundPets, 1, a) -- Add to beginning of list
                        sentAnimals[animalKey] = true
                        
                        -- Limit foundPets to 50 entries
                        if #foundPets > 50 then
                            table.remove(foundPets, #foundPets)
                        end
                        
                        notify("Pet Found!", a.displayName .. " - " .. formatValue(a.value), 6)
                    end
                end
            end
        end
    end
    
    if #valuableAnimals > 0 then
        updatePetsList()
    end
    
    return valuableAnimals
end

local function upd()
    if not isScanning then return end
    
    local n = tick()
    if n - lastUp < currentInterval then return end
    lastUp = n
    
    local valuableAnimals = findValuableAnimals()
end

-- Main Tab UI
local scanButton = MainTab:CreateButton({
    Name = "Start Scanning",
    Callback = function()
        isScanning = not isScanning
        if isScanning then
            notify("Scanner Started", "Now scanning for pets...", 3)
            scanButton.Name = "Stop Scanning"
        else
            notify("Scanner Stopped", "Pet scanning stopped.", 3)
            scanButton.Name = "Start Scanning"
        end
    end,
})

MainTab:CreateButton({
    Name = "Clear Found Pets",
    Callback = function()
        foundPets = {}
        sentAnimals = {}
        updatePetsList()
        notify("Cleared", "Pet list cleared.", 2)
    end,
})

MainTab:CreateButton({
    Name = "Scan Now",
    Callback = function()
        local pets = findValuableAnimals()
        notify("Manual Scan", "Found " .. #pets .. " valuable pets", 3)
    end,
})

MainTab:CreateLabel("Current Server: " .. (isPrivateServer() and "Private" or "Public"))
MainTab:CreateLabel("JobID: " .. game.JobId:sub(1, 12) .. "...")

-- Settings Tab UI
SettingsTab:CreateSlider({
    Name = "Minimum Pet Value",
    Range = {1000000, 100000000},
    Increment = 500000,
    Suffix = " Value",
    CurrentValue = currentMinValue,
    Flag = "MinValueSlider",
    Callback = function(value)
        currentMinValue = value
        cfg.MinValue = value
        notify("Settings", "Min value set to " .. formatValue(value), 2)
    end,
})

SettingsTab:CreateSlider({
    Name = "Scan Interval (seconds)",
    Range = {5, 60},
    Increment = 5,
    Suffix = "s",
    CurrentValue = currentInterval,
    Flag = "IntervalSlider",
    Callback = function(value)
        currentInterval = value
        cfg.UpdateInterval = value
        notify("Settings", "Scan interval set to " .. value .. "s", 2)
    end,
})

SettingsTab:CreateButton({
    Name = "Reset Settings",
    Callback = function()
        currentMinValue = 9500000
        currentInterval = 10
        notify("Settings", "Settings reset to default", 2)
    end,
})

-- Pets Tab UI
PetsTab:CreateLabel("Found Pets (Click to Join):")
PetsTab:CreateLabel("Showing most recent valuable pets")

-- Start the main loop
local function main()
    if isPrivateServer() then
        notify("Private Server", "You are in a private server", 4)
    else
        notify("Public Server", "Ready to scan for pets!", 4)
    end
    
    RunService.Heartbeat:Connect(upd)
end

main()