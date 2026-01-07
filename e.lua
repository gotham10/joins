local http = game:GetService("HttpService")
local ts = game:GetService("TeleportService")
local players = game:GetService("Players")
local lplr = players.LocalPlayer
local tcs = game:GetService("TextChatService")
local url = "https://joins-f0ac3-default-rtdb.firebaseio.com/"

local function req(method, path, data)
    print("DEBUG: Requesting " .. method .. " to " .. path)
    local success, response = pcall(function()
        return http:RequestAsync({
            Url = url .. path .. ".json",
            Method = method,
            Headers = {["Content-Type"] = "application/json"},
            Body = data and http:JSONEncode(data) or nil
        })
    end)
    
    if not success then
        warn("DEBUG ERROR: Request failed: " .. tostring(response))
        return nil
    end
    
    print("DEBUG: Response Status: " .. tostring(response.StatusCode))
    return response
end

local function startLoop()
    print("DEBUG: Starting main loop. Waiting for game load...")
    repeat task.wait() until game:IsLoaded()
    print("DEBUG: Game loaded. Registering self in Firebase...")

    local selfReg = req("PATCH", "people/" .. lplr.UserId, {
        placeId = game.PlaceId,
        jobId = game.JobId,
        lastSeen = os.time()
    })
    
    if selfReg then
        print("DEBUG: Self-registration successful.")
    else
        warn("DEBUG: Self-registration failed.")
    end

    print("DEBUG: Starting 30 second chat cycle...")
    for i = 1, 6 do
        local channel = tcs.ChatInputBarConfiguration.TargetTextChannel
        if channel then
            print("DEBUG: Sending chat message " .. i .. " of 6")
            channel:SendAsync("request ron.the.seller for coin/item/account deals")
        else
            warn("DEBUG: Chat channel not found!")
        end
        task.wait(5)
    end
    print("DEBUG: Chat cycle complete. Fetching target data...")

    local dataRaw = req("GET", "people")
    local people = {}
    if dataRaw and dataRaw.Body then
        people = http:JSONDecode(dataRaw.Body) or {}
        print("DEBUG: Successfully retrieved " .. #all .. " entries from people folder.")
    end
    
    local myDataRaw = req("GET", "users/" .. lplr.UserId)
    local myData = {}
    if myDataRaw and myDataRaw.Body then
        myData = http:JSONDecode(myDataRaw.Body) or {}
        print("DEBUG: Successfully retrieved personal history.")
    end
    
    local unjoined = {}
    local all = {}
    
    for id, info in pairs(people) do
        if tostring(id) ~= tostring(lplr.UserId) then
            table.insert(all, id)
            if not myData[id] then
                table.insert(unjoined, id)
            end
        end
    end
    
    print("DEBUG: Targets found - Total: " .. #all .. " | New: " .. #unjoined)
    
    local targetId
    if #unjoined > 0 then
        targetId = unjoined[math.random(1, #unjoined)]
        print("DEBUG: Selected NEW target: " .. tostring(targetId))
    elseif #all > 0 then
        targetId = all[math.random(1, #all)]
        print("DEBUG: No new targets. Selected REPEAT target: " .. tostring(targetId))
    end
    
    if targetId and people[targetId] then
        local count = (myData[targetId] or 0) + 1
        print("DEBUG: Incrementing join count for " .. tostring(targetId) .. " to " .. count)
        req("PATCH", "users/" .. lplr.UserId, {[targetId] = count})
        
        local target = people[targetId]
        
        print("DEBUG: Preparing teleport to PlaceId: " .. tostring(target.placeId))
        if queue_on_teleport then
            print("DEBUG: Setting queue_on_teleport for persistency.")
            queue_on_teleport([[
                loadstring(game:HttpGet("https://raw.githubusercontent.com/gotham10/joins/main/e.lua"))()
            ]])
        end

        if target.placeId and target.jobId then
            print("DEBUG: Attempting TeleportToPlaceInstance...")
            ts:TeleportToPlaceInstance(target.placeId, target.jobId, lplr)
        elseif target.placeId then
            print("DEBUG: Attempting standard Teleport...")
            ts:Teleport(target.placeId, lplr)
        end
    else
        warn("DEBUG: No valid target found. Restarting loop in 10 seconds...")
        task.wait(10)
        startLoop()
    end
end

task.spawn(startLoop)
