local http = game:GetService("HttpService")
local ts = game:GetService("TeleportService")
local players = game:GetService("Players")
local lplr = players.LocalPlayer
local tcs = game:GetService("TextChatService")
local url = "https://joins-f0ac3-default-rtdb.firebaseio.com/"

local function req(method, path, data)
    local success, response = pcall(function()
        return http:RequestAsync({
            Url = url .. path .. ".json",
            Method = method,
            Headers = {["Content-Type"] = "application/json"},
            Body = data and http:JSONEncode(data) or nil
        })
    end)
    return success and response or nil
end

task.spawn(function()
    for i = 1, 6 do
        local channel = tcs.ChatInputBarConfiguration.TargetTextChannel
        if channel then
            channel:SendAsync("request ron.the.seller for coin/item/account deals")
        end
        task.wait(5)
    end

    local dataRaw = req("GET", "people")
    local people = (dataRaw and http:JSONDecode(dataRaw.Body)) or {}
    
    local myDataRaw = req("GET", "users/" .. lplr.UserId)
    local myData = (myDataRaw and http:JSONDecode(myDataRaw.Body)) or {}
    
    local unjoined = {}
    local all = {}
    
    for id, info in pairs(people) do
        table.insert(all, id)
        if not myData[id] then
            table.insert(unjoined, id)
        end
    end
    
    local targetId
    if #unjoined > 0 then
        targetId = unjoined[math.random(1, #unjoined)]
    elseif #all > 0 then
        targetId = all[math.random(1, #all)]
    end
    
    if targetId and people[targetId] then
        local count = (myData[targetId] or 0) + 1
        req("PATCH", "users/" .. lplr.UserId, {[targetId] = count})
        
        local target = people[targetId]
        if target.placeId and target.jobId then
            if queue_on_teleport then
                queue_on_teleport([[
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/gotham10/joins/main/joins.lua"))()
                ]])
            end
            ts:TeleportToPlaceInstance(target.placeId, target.jobId, lplr)
        elseif target.placeId then
            ts:Teleport(target.placeId, lplr)
        end
    end
end)
