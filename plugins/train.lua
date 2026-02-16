local mq = require("mq")
local logger = require('knightlinc/Write')
local broadCastInterfaceFactory = require("broadcast/broadcastinterface")
local mqUtils = require('utils/mqhelpers')
local binder = require('application/binder')
local bci = broadCastInterfaceFactory('REMOTE')

local pickpockets = "Pick Pockets"
local function doPickPockets()
  local me = mq.TLO.Me
  local target = mq.TLO.Target
  if me.Heading.Degrees() - target.Heading.Degrees() < 45 then
    -- doRogueStrike()
    if me.AbilityReady(pickpockets)() then
      if mq.TLO.Me.Combat() then
        mq.cmd("/attack off")
      end
      mq.cmdf("/doability %s", pickpockets)
      logger.Debug("Triggering ability <%s>", pickpockets)
    end
  end
end

local hide = "Hide"
local function trainPickPockets()
  local me = mq.TLO.Me
  local target = mq.TLO.Target
  local inCombat = me.Combat()
  -- doRogueStrike()
  if me.AbilityReady(pickpockets)() and me.AbilityReady(hide)() and target() and target.Type() == "NPC" then
    if inCombat then
      mq.cmd("/attack off")
    end
    logger.Debug("Triggering ability <%s>", hide)
    mq.cmdf("/doability %s", hide)
    doPickPockets()
    if inCombat then
      mq.cmd("/attack on")
    end
  end
end

local function train_ability(ability)
  if mq.TLO.Me.Skill(ability)() == false then
    logger.Info('You do not have the skill <%s>', ability)
    return true
  end

  if mq.TLO.Me.Ability(ability)() == false then
    logger.Info('Ability is not mapped to action button <%s>', ability)
    return true
  end

  if mq.TLO.Me.Skill(ability)() == mq.TLO.Skill(ability).SkillCap() then
    logger.Info("Skill training completed for <%s>", ability)
    return true
  end

  if mq.TLO.Me.Sneaking() then
    mq.cmd('/doability Sneak')
    mq.delay(2)
  end

  if ability == "pickpockets" then
    trainPickPockets()
  elseif mq.TLO.Me.AbilityReady(ability)() then
    logger.Info("Training <%s>", ability)
    mq.cmdf('/doability "%s"', ability)
    mq.delay(2)
    mqUtils.ClearCursor()
  end

  if mq.TLO.Me.Feigning() then
    mq.cmd('/stand')
    mq.delay(2)
  end

  return false
end

local completed_skills = {}

local function is_training_completed(skills)
  for k, ability in ipairs(skills) do
    if not completed_skills[ability] then
      return false
    end
  end

  return true
end

---@class TrainCommand
---@field Skills string[]

---@param command TrainCommand
local function createPostCommand(command)
  return coroutine.create(function()
    while not is_training_completed(command.Skills) do
      for k, ability in ipairs(command.Skills) do
        completed_skills[ability] = train_ability(ability)
        if completed_skills[ability] then
          table.remove(command.Skills, k)
        end
      end

      coroutine.yield()
    end
    logger.Info("Completed training...")
  end)
end

---@param command TrainCommand
local function execute(command)
  logger.Info("Training abilities [%s]", table.concat(command.Skills, ","))
  return createPostCommand(command)
end

local function create(commandQueue)
  logger.Info("Creating bind for '/train'.")
  local function createCommand(skills)
    commandQueue.Enqueue(function() execute({ Skills = skills or {} }) end)
  end

  binder.Bind("/train", createCommand, "Tells all bots to train the given 'skill'.", 'skill')
end

return create
