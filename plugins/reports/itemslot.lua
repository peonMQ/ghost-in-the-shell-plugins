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
local function splitIndexed(input, sep)
  if sep == nil then
    sep = "|"
  end
  local t = {}
  for str in string.gmatch(input, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

local minValidSlotId = 0
local maxValidSlotId = 22
local validSlotNames =
"charm|leftear|head|face|rightear|neck|shoulder|arms|back|leftwrist|rightwrist|ranged|hands|mainhand|offhand|leftfinger|rightfinger|chest|legs|feet|waist|powersource|ammo"
local validSlotNamesList = splitSet(validSlotNames, '|')
local indexedSlotNames = splitIndexed(validSlotNames, '|')

local function executeById(id)
  logger.Info('FIS for [Id] ==> %s.', id)
  if id < minValidSlotId or id > maxValidSlotId then
    broadcast.FailAll("Invalid slot id", broadcast.ColorWrap(id, 'Red'))
    logger.Info("Invalid slotid used %s, valid ids are between %s and %s", id, minValidSlotId, maxValidSlotId)
  else
    broadcast.SuccessAll("Slot[%s] : %s", broadcast.ColorWrap(indexedSlotNames[id + 1], 'Orange'),
      broadcast.ColorWrap(mq.TLO.Me.Inventory(id)() or '', 'Green'))
  end
  logger.Info("End [FIS]")
end

---@param name string
local function executeByName(name)
  logger.Info('FIS for [Name] ==> %s.', name)
  if validSlotNamesList[name] then
    broadcast.SuccessAll("Slot[%s] : %s", broadcast.ColorWrap(name, 'Orange'),
      broadcast.ColorWrap(mq.TLO.Me.Inventory(name)() or '', 'Green'))
  else
    broadcast.FailAll("Invalid slot name %s", broadcast.ColorWrap(name, 'Red'))
    logger.Info("Invalid slotname used %s, valid slotnames are %s", name, validSlotNames)
  end
  logger.Info("End [FIS]")
end

local function create(commandQueue)
  logger.Info("Creating bind for '/fis'.")
  local function createCommand(query)
    if assist.IsOrchestrator() then
      bci.ExecuteAllCommand("/fis " .. query)
    end

    local id = tonumber(query)
    if id then
      commandQueue.Enqueue(function() executeById(id) end)
    else
      commandQueue.Enqueue(function() executeByName(query) end)
    end
  end

  binder.Bind("/fis", createCommand, "Tells all bots to report the item they currently have for given id or name.",
    'slotid|slotname')
end

return create
