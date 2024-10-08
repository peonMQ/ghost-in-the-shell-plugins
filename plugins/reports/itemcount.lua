local mq = require('mq')
local logger = require('knightlinc/Write')
local broadcast = require('broadcast/broadcast')
local binder = require('application/binder')

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
---@return number
local function findItemInContainer(container, matchFunction)
    logger.Debug("findItemInContainer <%s> <%s>", container.Name(), container.Container())
    local count = 0
    for i=1,container.Container() do
      local item = container.Item(i)
      if matchFunction(item) then
        count = count + item.Stack()
      end
    end

    return count
  end

---@param matchFunction fun(item): boolean
---@return number
  local function findItemInInventory(matchFunction)
    logger.Debug("Seaching inventory")
    local count = 0
    local inventory = mq.TLO.Me.Inventory
    for i=1, maxInventorySlots do
      local item = inventory(i) --[[@as item]]
      if matchFunction(item) then
        count = count + item.Stack()
      end

      if item.Container() and item.Container() > 0 then
        count = count + findItemInContainer(item, matchFunction)
      end
    end

    return count
  end

---@param matchFunction fun(item): boolean
---@return number
  local function findItemInBank(matchFunction)
    logger.Debug("Seaching bank for")
    local count = 0
    local bank = mq.TLO.Me.Bank
    for i=1, maxBankSlots do
      local item = bank(i) --[[@as item]]
      if matchFunction(item) then
        count = count + item.Stack()
      end

      if item.Container() and item.Container() > 0 then
        count = count + findItemInContainer(item, matchFunction)
      end
    end

    return count
  end

  ---@param itemId number
local function executeById(itemId)
  logger.Info('FIC for [ItemId] ==> %s.', itemId)


  local matchFunction = matchesId(itemId)
  local itemCount = findItemInInventory(matchFunction) + findItemInBank(matchFunction)
  broadcast.SuccessAll("Count for itemId %s : %s", broadcast.ColorWrap(itemId, 'Green'), broadcast.ColorWrap(itemCount, 'Maroon'))

  logger.Info("End [FIC]")
end

---@param name string
local function executeByName(name)
logger.Info('FIC for [Name] ==> %s.', name)

local matchFunction = matchesSearchTerms(name)
local itemCount = findItemInInventory(matchFunction) + findItemInBank(matchFunction)
broadcast.SuccessAll("Count for name %s : %s", broadcast.ColorWrap(name, 'Green'), broadcast.ColorWrap(itemCount, 'Maroon'))

logger.Info("End [FIC]")
end

local function create(commandQueue)
  logger.Info("Creating bind for '/fic'.")
  local function createCommand(query)
    local itemId = tonumber(query)
    if itemId then
      commandQueue.Enqueue(function() executeById(itemId) end)
    else
      commandQueue.Enqueue(function() executeByName(query) end)
    end
  end

   binder.Bind("/fic", createCommand, "Tells all bots to report their itemcount for given id or name.", 'id|name')
end

return create