local mq = require("mq")
local broadcast = require('broadcast/broadcast')
local broadCastInterfaceFactory = require('broadcast/broadcastinterface')
local assist = require('core/assist')
local binder = require('application/binder')

local bci = broadCastInterfaceFactory('ACTOR')

-- report language skills
local function execute()
  local me = mq.TLO.Me
  local current_pp = me.Platinum()
  if me.Gold() > 0 then
    current_pp = current_pp + (me.Gold() / 10)
  end

  if me.Silver() > 0 then
    current_pp = current_pp + (me.Silver() / 100)
  end

  if me.Copper() > 0 then
    current_pp = current_pp + (me.Copper() / 1000)
  end

  broadcast.SuccessAll("%s pp", broadcast.ColorWrap(current_pp, 'Green'))
end

local function create(commandQueue)
  local function createCommand()
    if assist.IsOrchestrator() then
      bci.ExecuteAllCommand("/money")
    end

    commandQueue.Enqueue(function() execute() end)
  end

  binder.Bind("/money", createCommand, "Tells all bots to report their current platinum status.")
end

return create
