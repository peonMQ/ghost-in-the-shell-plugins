local mq = require('mq')
local logger = require('knightlinc/Write')
local broadcast = require('broadcast/broadcast')
local broadCastInterfaceFactory = require('broadcast/broadcastinterface')
local assist = require('core/assist')
local binder = require('application/binder')
local bci = broadCastInterfaceFactory('REMOTE')

local function splitSet(input, sep)
    if sep == nil then
        sep = "|"
    end
    local t = {}
    for str in string.gmatch(input, "([^" .. sep .. "]+)") do
        t[str] = true
    end
    return t
end

-- local validSlotNames = "charm|leftear|head|face|rightear|neck|shoulder|arms|back|leftwrist|rightwrist|ranged|hands|mainhand|offhand|leftfinger|rightfinger|chest|legs|feet|waist|powersource|ammo"
local validSlotNames =
"leftear|head|face|rightear|neck|shoulder|arms|back|leftwrist|rightwrist|ranged|hands|mainhand|offhand|leftfinger|rightfinger|chest|legs|feet|waist"
local validSlotNamesList = splitSet(validSlotNames, '|')

local function execute()
    logger.Info('FMIS ==>')
    local missing_slots = nil
    for slotname, _ in pairs(validSlotNamesList) do
        if not mq.TLO.Me.Inventory(slotname)() then
            if not missing_slots then
                missing_slots = broadcast.ColorWrap(slotname, 'Orange')
            else
                missing_slots = missing_slots .. "|" .. broadcast.ColorWrap(slotname, 'Orange')
            end
        end
    end

    if missing_slots then
        broadcast.FailAll("Missing slots %s", missing_slots)
    end

    logger.Info("End [FMIS]")
end

local function create(commandQueue)
    logger.Info("Creating bind for '/fmis'.")
    local function createCommand()
        if assist.IsOrchestrator() then
            bci.ExecuteAllCommand("/fmis")
        end

        commandQueue.Enqueue(function() execute() end)
    end
    binder.Bind("/fmis", createCommand, "Tells all bots to report the slots that are empty.")
end

return create
