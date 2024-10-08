local mq = require('mq')
local logger = require('knightlinc/Write')
local mqUtils = require('utils/mqhelpers')
local binder = require('application/binder')

local foodItemClicky  = "Endless Turkeys"
local foodItem  = "Cooked Turkey"
local maxFoodCount  = 5

local function DoSummon (itemName)
  mq.cmdf('/nomodkey /itemnotify "%s" rightmouseup', itemName)
  mq.delay("3s", function() return mq.TLO.Cursor.ID() and mq.TLO.Cursor.ID() > 0 end)
  if mq.TLO.Cursor.ID() then
    mq.delay(500)
    mq.cmd('/autoinventory')
  end
  logger.Debug("Done sommon with cursor <%s>", mq.TLO.Cursor.ID())
end

local function execute()
  logger.Info('Start [SummonFood] ==> %s of %s.', maxFoodCount, foodItem)

  if mq.TLO.FindItemCount('='..foodItemClicky)() < 1 then
    logger.Fatal('Missing item/spell <%s>', foodItemClicky)
  end

  mqUtils.ClearCursor()
  while mq.TLO.FindItemCount('='..foodItem)() < maxFoodCount do
    if mq.TLO.FindItem('='..foodItemClicky).TimerReady() == 0 then
      logger.Info('Summoning: %s =>  %s/%s', foodItem, mq.TLO.FindItemCount('='..foodItem)()+1, maxFoodCount)
      DoSummon(foodItemClicky)
      mq.delay(mq.TLO.FindItem('='..foodItemClicky).TimerReady() + 500)
    end

    mqUtils.ClearCursor()
  end

  mq.cmd('/beep .\\sounds\\mail1.wav')
  logger.Info("End [SummonFood]")
end

local function create(commandQueue)
  logger.Info("Creating bind for '/food'.")
  local function createCommand()
    commandQueue.Enqueue(function() execute() end)
  end

   mq.bind("/food", createCommand)
end

return create