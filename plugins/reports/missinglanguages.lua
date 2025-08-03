local mq = require("mq")
local broadCast = require('broadcast/broadcast')
local broadCastInterfaceFactory = require('broadcast/broadcastinterface')
local assist = require('core/assist')
local binder = require('application/binder')

local bci = broadCastInterfaceFactory('ACTOR')

local maxLanguageID = 25
if mq.TLO.MacroQuest.Server() == "FVP" then
  maxLanguageID = 24   -- 25 "Vah Shir" was added with Luclin
end
-- report language skills
local function execute()
  local s = ""
  for i = 1, maxLanguageID do
    if mq.TLO.Me.LanguageSkill(i)() >= 100 then
      --log.Debug("Language %s CAPPED (id %d)", mq.TLO.Me.Language(i)(), i)
    elseif mq.TLO.Me.LanguageSkill(i)() == 0 then
      bci:ColorWrap(s, 'Red')
      s = s .. bci:ColorWrap(string.format("  %d:%s (0)\n", i, mq.TLO.Me.Language(i)()), 'Red')
    else
      s = s ..
      bci:ColorWrap(string.format("  %d:%s (%d)\n", i, mq.TLO.Me.Language(i)(), mq.TLO.Me.LanguageSkill(i)()), "Yellow")
    end
  end

  if s ~= "" then
    broadCast.InfoAll("Missing language report\n" .. s)
  else
    broadCast.SuccessAll("OK: All languages capped")
  end
end

local function create(commandQueue)
  local function createCommand()
    if assist.IsOrchestrator() then
      bci.ExecuteAllCommand("/fml")
    end

    commandQueue.Enqueue(function() execute() end)
  end

  binder.Bind("/fml", createCommand, "Tells all bots to report their missing languages.")
end

return create
