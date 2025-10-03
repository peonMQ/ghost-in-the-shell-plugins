local mq = require("mq")
local logger = require('knightlinc/Write')
local broadCastInterfaceFactory = require("broadcast/broadcastinterface")
local luaUtils = require('utils/lua-table')
local assist = require('core/assist')
local binder = require('application/binder')
local settings = require('settings/settings')
local bci = broadCastInterfaceFactory('ACTOR')

---@param input string
---@param sep string
---@return string[]
local function splitSet(input, sep)
  if sep == nil then
    sep = "|"
  end

  local t = {}
  for str in string.gmatch(input, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end

  return t
end

---@param new_mt_order_str string
local function execute(new_mt_order_str)
  local mt_order = splitSet(new_mt_order_str, ',')
  local current_bots = bci.ConnectedClients()
  local new_mt_order = {}
  for _, maintank in ipairs(mt_order) do
    if luaUtils.ContainsValue(current_bots, maintank:lower()) then
      table.insert(new_mt_order, maintank)
    end
  end

  if not next(new_mt_order) then
    return
  end

  settings.assist.tanks = new_mt_order;
end

local function create(commandQueue)
  logger.Info("Creating bind for '/mtorder'.")
  local function createCommand(new_mt_order)
    if not new_mt_order then
      return
    end

    if assist.IsOrchestrator() then
      bci.ExecuteAllCommand("/mtorder " .. new_mt_order)
    end

    commandQueue.Enqueue(function() execute(new_mt_order) end)
  end

  binder.Bind("/mtorder", createCommand, "Changes MT order with given comma separated list 'mt_order'.",
    'Fluffy,Humpty,Dumpty')
end

return create
