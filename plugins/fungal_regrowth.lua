local mq = require('mq')
local logger = require('knightlinc/Write')
local plugin = require('utils/plugins')
local buffitem = require('core/casting/buffs/buffitem')
local binder = require('application/binder')

---@param buffSpell BuffSpell|BuffItem
---@param targetId  integer
local function castBuff(buffSpell, targetId)
  local spawn = mq.TLO.Spawn(targetId)
  if spawn() then
    if buffSpell:CanCastOnSpawn(spawn --[[@as spawn]]) then
      if buffSpell.MQSpell.TargetType() ~= "Self" then
        spawn.DoTarget()
      end

      logger.Info("Casting [%s] on <%s>", buffSpell.Name, spawn.Name())
      buffSpell:Cast()
      return true
    end
  end

  return false
end

local function execute(classes)
  if plugin.IsLoaded("mq2netbots") == false then
    logger.Debug("mq2netbots is not loaded")
    return
  end

  if mq.TLO.NetBots.Counts() < 2 then
    logger.Debug("Not enough Nebots clients, current: %d", mq.TLO.NetBots.Counts())
    return
  end

  local itemName = "Fungi Covered Great Staff"
  if not mq.TLO.FindItem("=" .. itemName)() then
    logger.Error("Not enough Nebots clients, current: %d", mq.TLO.NetBots.Counts())
    return
  end

  local buff = buffitem:new(itemName, classes or "wiz")
  if buff:CanCast() then
    for i = 1, mq.TLO.NetBots.Counts() do
      local name = mq.TLO.NetBots.Client(i)()
      local netbot = mq.TLO.NetBots(name) --[[@as netbot]]
      if netbot.InZone() == true and netbot.Class() ~= "NULL" and buff:CanCastOnClass(netbot.Class.ShortName()) then
        if buff:WillStack(netbot) then
          castBuff(buff, netbot.ID())
        end
      end
    end
  else
    logger.Error("Cannot use '%s', unable to cast '%s'", buff.ItemName, buff.Name)
  end
end

local function create(commandQueue)
  logger.Info("Creating bind for '/fungal'.")
  local function createCommand(classes)
    commandQueue.Enqueue(function() execute(classes) end)
  end

  binder.Bind("/fungal", createCommand,
    "Tells all bot to use click item with Funcal Regrowth on given 'classes' comma separated.", 'classes')
end

return create
