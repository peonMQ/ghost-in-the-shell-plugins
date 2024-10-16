local mq = require('mq')
local logger = require('knightlinc/Write')
local broadcast = require('broadcast/broadcast')
local broadCastInterfaceFactory = require('broadcast/broadcastinterface')
local assist = require('core/assist')
local binder = require('application/binder')
local bci = broadCastInterfaceFactory('ACTOR')

local maxInventorySlots = 22 + mq.TLO.Me.NumBagSlots()
local maxBankSlots = mq.TLO.Inventory.Bank.BagSlots()

---@param searchTerms string
---@return fun(item): boolean
local function matchesSearchTerms(searchTerms)
  return function(item)
    if not item() then
      return false
    end

    local text = item.Name():lower()
    for searchTerm in string.gmatch(searchTerms:lower(), "%S+") do
      if not text:find(searchTerm) then
        return false
      end
    end

    return true
  end
end

---@param itemId number
---@return fun(item): boolean
local function matchesId(itemId)
  return function(item)
    if not item() then
      return false
    end

    return item.ID() == itemId
  end
end

---@param container item
---@param matchFunction fun(item): boolean
---@return boolean
local function findItemInContainer(container, matchFunction)
  logger.Debug("findItemInContainer <%s> <%s>", container.Name(), container.Container())
  for i = 1, container.Container() do
    local item = container.Item(i)
    if matchFunction(item) then
      return true
    end
  end

  return false
end

---@param matchFunction fun(item): boolean
---@return boolean
local function findItemInInventory(matchFunction)
  logger.Debug("Seaching inventory")
  local inventory = mq.TLO.Me.Inventory
  for i = 1, maxInventorySlots do
    local item = inventory(i) --[[@as item]]
    if matchFunction(item) then
      return true
    end

    if item.Container() and item.Container() > 0 then
      if (findItemInContainer(item, matchFunction)) then
        return true
      end
    end
  end

  return false
end

---@param matchFunction fun(item): boolean
---@return boolean
local function findItemInBank(matchFunction)
  logger.Debug("Seaching bank")
  local bank = mq.TLO.Me.Bank
  for i = 1, maxBankSlots do
    local item = bank(i) --[[@as item]]
    if matchFunction(item) then
      return true
    end

    if item.Container() and item.Container() > 0 then
      if (findItemInContainer(item, matchFunction)) then
        return true
      end
    end
  end

  return false
end

local function executeById(itemId)
  logger.Info('FMI for [ItemId] ==> %s.', itemId)

  local matchFunction = matchesId(itemId)
  if not findItemInInventory(matchFunction) and not findItemInBank(matchFunction) then
    broadcast.ErrorAll("Missing item %s", broadcast.ColorWrap(itemId, 'Red'))
  end

  logger.Info("End [FMI]")
end

local function executeByName(name)
  logger.Info('FMI for [Name] ==> %s.', name)

  local matchFunction = matchesSearchTerms(name)
  if not findItemInInventory(matchFunction) and not findItemInBank(matchFunction) then
    broadcast.ErrorAll("Missing item %s", broadcast.ColorWrap(name, 'Red'))
  end

  logger.Info("End [FMI]")
end

local function create(commandQueue)
  logger.Info("Creating bind for '/fmi'.")
  local function createCommand(query)
    if assist.IsOrchestrator() then
      bci.ExecuteAllCommand("/fmi " .. query)
    end

    local itemId = tonumber(query)
    if itemId then
      commandQueue.Enqueue(function() executeById(tonumber(itemId)) end)
    else
      commandQueue.Enqueue(function() executeByName(query) end)
    end
  end

  binder.Bind("/fmi", createCommand, "Tells all bots to report missing item for given id or name.", 'id|name')
end

return create
