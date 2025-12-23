local mq = require('mq')
local logger = require('knightlinc/Write')

local allowedInviters = {
  Eredhrin = true,
  Mizzfit = true,
  Manwe = true,
  Drayek = true,
  Drayk = true,
}

local function execute()
  logger.Info("Accepting raid invite")
  mq.cmd("/notify ConfirmationDialogBox Yes_Button leftmouseup")
  mq.cmd("/squelch /raidaccept")
end

local function create(commandQueue)
  logger.Info("Creating event for 'joinraid'.")
  local function createCommand(text, sender)
    logger.Debug("Got raid invite from %s", sender)
    if not allowedInviters[sender] then
      logger.Error("Ignoring raid invite from unknown player %s", sender)
      return
    end

    commandQueue.Enqueue(function() execute() end)
  end

  mq.event('joinraid', '#1# invites you to join a raid.#*#', createCommand)
end

return create
