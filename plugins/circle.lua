local mq = require("mq")
local logger = require('knightlinc/Write')
local broadCastInterfaceFactory = require("broadcast/broadcastinterface")
local bci = broadCastInterfaceFactory('ACTOR')

-- form bots in a circle around orchestrator
---@param dist integer|nil Distance from the center
local function make_peers_circle_me(dist)
    local peers = bci.ConnectedClients()
	local n = #peers
    if dist == nil then
        dist = 20
    end

    bci.ExecuteZoneCommand("/followoff")

    for i, peer in ipairs(peers) do
        if peer ~= mq.TLO.Me.Name():lower() then
            local angle = (360 / n) * i
            if mq.TLO.SpawnCount("pc ="..peer)() > 0 then
                local y = mq.TLO.Me.Y() + (dist * math.sin(angle))
                local x = mq.TLO.Me.X() + (dist * math.cos(angle))
                bci.ExecuteCommand(string.format("/moveto loc %d %d", y, x), {peer})
            end
        else
        end
    end
end

---@class CircleMeCommand
---@field Distance integer

---@param command CircleMeCommand
local function execute(command)
    make_peers_circle_me(command.Distance)
end

local function create(commandQueue)
    logger.Info("Creating bind for '/circleme'.")
    local function createCommand(distance)
        commandQueue.Enqueue(function() execute({Distance = tonumber(distance) or 20}) end)
    end

    mq.bind("/circleme", createCommand)
end

return create
