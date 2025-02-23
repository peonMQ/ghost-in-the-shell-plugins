local mq = require("mq")
local logger = require('knightlinc/Write')
local broadCastInterfaceFactory = require("broadcast/broadcastinterface")
local plugins = require('utils/plugins')
local assist = require('core/assist')
local binder = require('application/binder')
local strings = require('core/strings')
local bci = broadCastInterfaceFactory('ACTOR')

---@param enable boolean
local function execute(enable)
  if enable and not mq.TLO.BardSwap.MeleeSwap() then
    mq.cmd('/bardswap melee')
  elseif not enable and mq.TLO.BardSwap.MeleeSwap() then
    mq.cmd('/bardswap melee')
  end
end

local function create(commandQueue)
  logger.Info("Creating bind for '/bardswap_melee'.")
  local function createCommand(enable)
    if assist.IsOrchestrator() then
      bci.ExecuteAllCommand("/bardswap_melee " .. enable)
    end

    if mq.TLO.Me.Class.ShortName() == "BRD" and plugins.IsLoaded("mq2bardswap") then
      commandQueue.Enqueue(function() execute(strings.ConvertToBoolean(enable)) end)
    end
  end

  binder.Bind("/bardswap_melee", createCommand, "Tells all bards to toggle bardswap melee swapping given 'bool'.",
    'on|off')
end

return create
