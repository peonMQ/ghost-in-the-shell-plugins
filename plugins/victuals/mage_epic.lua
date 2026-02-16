local mq                        = require('mq')
local logger                    = require('knightlinc/Write')
local broadcast                 = require('broadcast/broadcast')
local mqUtils                   = require('utils/mqhelpers')
local binder                    = require('application/binder')
local item                      = require('core/casting/item')
local spell                     = require('core/casting/spell')
local settings                  = require('settings/settings')
local assist                    = require('core/assist')

local broadCastInterfaceFactory = require('broadcast/broadcastinterface')

local bci                       = broadCastInterfaceFactory('REMOTE')
local mageEpicSpellName         = "Summon Orb"
local mageEpicItem              = "Orb of Mastery"

local function deleteItem(itemName)
  mqUtils.ClearCursor()
  local cursor = mq.TLO.Cursor
  while not cursor() do
    mq.cmdf('/itemnotify "%s" leftmouseup', itemName)
    mq.delay(100, function() return cursor() == itemName end)
  end

  while cursor() ~= nil do
    mq.cmdf("/destroy")
    mq.delay(100, function() return cursor() == nil end)
  end
  mqUtils.ClearCursor()
end

local function execute()
  logger.Info('Start [Mage Epic]')

  local bookSpell = mq.TLO.Me.Book(mq.TLO.Spell(mageEpicSpellName).RankName.Name())
  if not bookSpell() then
    broadcast.WarnAll("Missing \ay%s\ax", mageEpicSpellName)
    return
  end

  local clicky = mq.TLO.FindItem('=' .. mageEpicItem)
  if clicky() and clicky.Charges() == 0 then
    logger.Info("Has '%s' is out of charges, deleting current.", mageEpicItem)
    deleteItem(mageEpicItem)
  end

  if mq.TLO.FindItemCount('=' .. mageEpicItem)() == 0 then
    logger.Info("Missing '%s', casting '%s' to summon a new one.", mageEpicItem, mageEpicSpellName)
    local mageEpicSpell = spell:new(mageEpicSpellName, settings:GetDefaultGem(mageEpicSpellName), 0, 100)
    mageEpicSpell:MemSpell()
    while not mq.TLO.Me.SpellReady(mageEpicSpellName)() do
      mq.delay(500, function() return mq.TLO.Me.SpellReady(mageEpicSpellName)() end)
    end
    mageEpicSpell:Cast()
    mq.delay(1000, function() return mq.TLO.Cursor() ~= nil end)
    mqUtils.ClearCursor()
  end

  logger.Info("End [Mage Epic]")
end

local function create(commandQueue)
  logger.Info("Creating bind for '/mageepic'.")
  local function createCommand()
    if assist.IsOrchestrator() then
      bci.ExecuteAllCommand("/mageepic")
    end

    if mq.TLO.Me.Class.ShortName() == "MAG" then
      commandQueue.Enqueue(function() execute() end)
    end
  end

  binder.Bind("/mageepic", createCommand, "Tells all bot to refresh mage epic weapon if they have the spell/item.")
end

return create
