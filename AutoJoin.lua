--// Auto JobID Joiner - Simplified Version
--// No UI - Auto execution only

--// Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

--// Check if GameID and JobID are provided
if not getgenv().GameID then
    warn("[Auto JobId Joiner] No GameID provided. Script terminated.")
    return
end

if not getgenv().JobID then
    warn("[Auto JobId Joiner] No JobID provided. Script terminated.")
    return
end

--// Validate JobID format
if type(getgenv().JobID) ~= "string" or getgenv().JobID == "" then
    warn("[Auto JobId Joiner] Invalid JobID format. Script terminated.")
    return
end

--// Check if current game matches target GameID
if game.PlaceId ~= getgenv().GameID then
    warn("[Auto JobId Joiner] You are not in the target GameID. Current: " .. tostring(game.PlaceId) .. ", Target: " .. tostring(getgenv().GameID))
    return
end

--// Function to check if server exists and is joinable
local function checkServerAvailability(gameId, jobId)
    local success, result = pcall(function()
        -- This is a basic check - in practice, Roblox doesn't provide a direct API to check server availability
        -- We'll attempt the teleport and let it fail naturally if the server doesn't exist
        return true
    end)
    return success
end

--// Auto join function
local function autoJoinJob()
    print("[Auto JobId Joiner] Attempting to join JobId: " .. getgenv().JobID)
    
    -- Check server availability (basic implementation)
    if not checkServerAvailability(getgenv().GameID, getgenv().JobID) then
        warn("[Auto JobId Joiner] Server availability check failed. Script terminated.")
        return
    end
    
    -- Attempt teleport
    local success, error = pcall(function()
        TeleportService:TeleportToPlaceInstance(getgenv().GameID, getgenv().JobID, LP)
    end)
    
    if success then
        print("[Auto JobId Joiner] Teleport initiated successfully.")
    else
        warn("[Auto JobId Joiner] Teleport failed: " .. tostring(error))
        warn("[Auto JobId Joiner] Server may not be available. Script terminated.")
    end
end

--// Execute auto join
autoJoinJob()

--// Clean up environment variables (optional)
getgenv().GameID = nil
getgenv().JobID = nil