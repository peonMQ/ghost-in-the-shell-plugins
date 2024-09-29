local mq = require("mq")
local broadcast = require('broadcast/broadcast')
local broadCastInterfaceFactory = require('broadcast/broadcastinterface')
local assist = require('core/assist')

local bci = broadCastInterfaceFactory('ACTOR')

-- report language skills
local function execute()
    local currentStrenght = mq.TLO.Me.STR()
    local currentWeight = mq.TLO.Me.CurrentWeight()
    if currentWeight > currentStrenght then -- red
        broadcast.ErrorAll("Weight %s/%s", broadcast.ColorWrap(currentWeight, 'Red'), broadcast.ColorWrap(currentStrenght, 'Red'))
    elseif currentWeight + 20 > currentStrenght then -- yellow
        broadcast.WarnAll("Weight %s/%s", broadcast.ColorWrap(currentWeight, 'Orange'), broadcast.ColorWrap(currentStrenght, 'Yellow'))
    else -- green
        broadcast.SuccessAll("Weight %s/%s", broadcast.ColorWrap(currentWeight, 'Green'), broadcast.ColorWrap(currentStrenght, 'Green'))
    end
end

local function create(commandQueue)
    local function createCommand()
        if assist.IsOrchestrator() then
            bci.ExecuteAllCommand("/weight")
        end

        commandQueue.Enqueue(function() execute() end)
    end

    mq.bind("/weight", createCommand)
end

return create