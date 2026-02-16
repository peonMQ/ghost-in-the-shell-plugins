local mq = require("mq")
local logger = require('knightlinc/Write')
local broadCastInterfaceFactory = require("broadcast/broadcastinterface")
local luaUtils = require('utils/lua-table')
local assist = require('core/assist')
local binder = require('application/binder')
local settings = require('settings/settings')
local bci = broadCastInterfaceFactory('REMOTE')

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

---@param new_ma_order_str string
local function execute(new_ma_order_str)
  local ma_order = splitSet(new_ma_order_str, ',')
  local current_bots = bci.ConnectedClients()
  local new_ma_order = {}
  for _, maintank in ipairs(ma_order) do
    if luaUtils.ContainsValue(current_bots, maintank) then
      table.insert(new_ma_order, maintank)
    end
  end

  if not next(new_ma_order) then
    return
  end

  settings.assist.tanks = new_ma_order;
end

local function create(commandQueue)
  logger.Info("Creating bind for '/maorder'.")
  local function createCommand(new_ma_order)
    if not new_ma_order then
      return
    end

    if assist.IsOrchestrator() then
      bci.ExecuteAllCommand("/maorder " .. new_ma_order)
    end

    commandQueue.Enqueue(function() execute(new_ma_order) end)
  end

  binder.Bind("/maorder", createCommand, "Changes MA order with given comma separated list 'ma_order'.",
    'Fluffy,Humpty,Dumpty')
end

return create
