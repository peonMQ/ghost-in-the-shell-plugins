local mq = require('mq')
local logger = require('knightlinc/Write')

local allowedInviters = {
}

local function execute()
  logger.Info("Accepting group invite")
  mq.cmd('/notify GroupWindow GW_FollowButton leftmouseup')
  mq.delay('1s');
  if not mq.TLO.Group() then
    logger.Error("Unable to accept group invite")
  end
end

local function create(commandQueue)
  logger.Info("Creating event for 'joingroup'.")
  local function createCommand(text, sender)
    logger.Warn("Got group invite from %s", sender)
    local inviter = mq.TLO.Spawn("pc =" .. sender)
    if not inviter() or (inviter.Guild() ~= mq.TLO.Me.Guild() and not allowedInviters[sender]) then
      logger.Error("Ignoring group invite from unknown player %s", sender)
      return
    end

    commandQueue.Enqueue(function() execute() end)
  end

  mq.event('joingroup', '#1# invites you to join a group.#*#', createCommand)
end

return create
