local mq             = require('mq')
local logger         = require('knightlinc/Write')
local mqUtils        = require('utils/mqhelpers')
local binder         = require('application/binder')
local plugins        = require('utils/plugins')

local foodItemClicky = "Endless Turkeys"
local foodItem       = "Cooked Turkey"
local maxFoodCount   = 5

local function DoSummon(itemName)
  mq.cmdf('/nomodkey /itemnotify "%s" rightmouseup', itemName)
  mq.delay("3s", function() return mq.TLO.Cursor.ID() and mq.TLO.Cursor.ID() > 0 end)
  if mq.TLO.Cursor.ID() then
    mq.delay(500)
    mq.cmd('/autoinventory')
  end
  logger.Debug("Done sommon with cursor <%s>", mq.TLO.Cursor.ID())
end

local function execute()
  local isBardSwapping = plugins.IsLoaded("MQ2BardSwap") and mq.TLO.BardSwap.Swapping()
  if isBardSwapping then
    mq.cmd("/bardswap")
  end
  logger.Info('Start [SummonFood] ==> %s of %s.', maxFoodCount, foodItem)

  if mq.TLO.FindItemCount('=' .. foodItemClicky)() < 1 then
    logger.Fatal('Missing item/spell <%s>', foodItemClicky)
  end

  mqUtils.ClearCursor()
  while mq.TLO.FindItemCount('=' .. foodItem)() < maxFoodCount do
    local clicky = mq.TLO.FindItem('=' .. foodItemClicky)
    if clicky() and clicky.TimerReady() == 0 then
      logger.Info('Summoning: %s =>  %s/%s', foodItem, mq.TLO.FindItemCount('=' .. foodItem)() + 1, maxFoodCount)
      DoSummon(foodItemClicky)
      mq.delay(clicky.TimerReady() + 500)
    end

    mqUtils.ClearCursor()
  end

  mq.cmd('/beep .\\sounds\\mail1.wav')
  logger.Info("End [SummonFood]")
  if isBardSwapping then
    mq.cmd("/bardswap")
  end
end

local function create(commandQueue)
  logger.Info("Creating bind for '/food'.")
  local function createCommand()
    commandQueue.Enqueue(function() execute() end)
  end

  binder.Bind("/food", createCommand, "Tells all bot to use click item to summon food.")
end

return create
