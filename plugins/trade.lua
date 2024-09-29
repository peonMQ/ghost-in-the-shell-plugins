local mq = require('mq')
local broadcast = require('broadcast/broadcast')
local mqUtils = require('utils/mqhelpers')
local logger = require('knightlinc/Write')
local assist = require('core/assist')

-- ---@param item ItemLinkInfo
-- ---@return boolean
-- local function alreadyHaveLoreItem(item)
--     local existingItem = mq.TLO.FindItem(item.itemID)
--     if existingItem() then
--         return existingItem.Lore()
--     end

--     existingItem = mq.TLO.FindItemBank(item.itemID)
--     if existingItem() then
--         return existingItem.Lore()
--     end

--     return false
--   end

-- ---@param item ItemLinkInfo
-- ---@return boolean
-- local function canAcceptItem(item)

--     for i = 3008, 3015, 1 do
--         local invSlotItem = mq.TLO.InvSlot(i).Item
--         if invSlotItem() then
--         end
--     end

--     if alreadyHaveLoreItem(item) then
--         logger.Debug("<%s> is [Lore] and I already have one.", item.itemName)
--         mq.cmd("/beep")
--         return false
--     end

--     local existingItem = mq.TLO.FindItem(item.itemID)
--     if existingItem() and mq.TLO.Me.FreeInventory(existingItem.Size())() < 1 then
--       if existingItem.Stackable() and existingItem.FreeStack() > 0 then
--         return true
--       end

--       logger.Debug("My inventory is full!", item.itemName)
--       mq.cmd("/beep")
--       return false
--     end

--     return mq.TLO.Me.FreeInventory() > 0
-- end


local function alreadyHaveLoreItem(item)
    if not item.Lore() then
      return false
    end
  
    local findQuery = "="..item.Name()
    return mq.TLO.FindItemCount(findQuery)() > 0 or mq.TLO.FindItemBankCount(findQuery)() > 0
end
  
---@param item item
---@return boolean
local function canAcceptItem(item)
    if alreadyHaveLoreItem(item) then
      logger.Debug("<%s> is [Lore] and I already have one.", item.Name())
      mq.cmd("/beep")
      return false
    end

    if  mq.TLO.Me.FreeInventory(item.Size())() < 1 then
      if item.Stackable() and item.FreeStack() > 0 then
        return true
      end

      logger.Debug("My inventory is full!", item.Name())
      mq.cmd("/beep")
      return false
    end

    return true
end

local function canAcceptItems()
    for i = 3008, 3015, 1 do
        local invSlotItem = mq.TLO.InvSlot(i).Item
        if invSlotItem() then
            if not canAcceptItem(invSlotItem) then
                return false
            end
        end
    end

    return true
end

local function getItemLink(msg)
    local links = mq.ExtractLinks(msg)
    local i, linkItem = next(links)
    if i and linkItem.type == mq.LinkTypes.Item then
        return mq.ParseItemLink(linkItem.link)
    end

    return nil
end

local function execute(trader, msg)
    local tradespawn = mq.TLO.Spawn("pc ="..trader)
    local item = getItemLink(msg)
    if mq.TLO.Window("tradewnd").Open() == true and not mq.TLO.Cursor() then
        if not tradespawn() or tradespawn.Guild() ~= mq.TLO.Me.Guild() then
            broadcast.WarnAll("Ignoring trades from unknown player %s", trader)
            mq.cmd("/squelch /notify tradewnd TRDW_Cancel_Button leftmouseup")
        elseif item and not canAcceptItems() then
            broadcast.WarnAll("Unable to accept trade from player %s for item %s", trader, item.itemName)
            mq.cmd("/squelch /notify tradewnd TRDW_Cancel_Button leftmouseup")
        else
            if assist.IsOrchestrator() then
                broadcast.SuccessAll("Accepting trade in 5s with %s", trader)
                mq.delay(5000, function() return not mq.TLO.Window("tradewnd") end)
            end

            mq.cmd("/squelch /notify tradewnd TRDW_Trade_Button leftmouseup")
        end
    end
end

local function create(commandQueue)
    logger.Info("Creating event for 'tradeaccept'.")
    local function createCommand(msg, sender)
        logger.Debug("Got trade from %s", sender)
        commandQueue.Enqueue(function() execute(sender, msg) end)
    end

    mq.event('tradeaccept', '#1# has offered you a #*#', createCommand, { keepLinks = true })
end

return create

--- TRDW_TradeSlot0-7 + 8-15