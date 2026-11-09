--[[
  Q-SYS Sample Project: UCI PIN Lock + Page Navigation
  ----------------------------------------------------
  Script component controls:
    PinEntry      Text    (Controller)   -- bound to a text box on the PIN page
    PinSubmit     Button  (Trigger)
    PinClear      Button  (Trigger)
    PinStatus     Text    (Indicator)
    SettingsDone  Button  (Trigger)      -- bound to "Done" on the Settings page
                                           (also set that button to change page to Home)

  Flow: Home -> [Settings button, page-change to "PIN"] -> correct PIN ->
        script sends the UCI to "Settings" -> auto-return to "Home" after a timeout.
]]

local CFG = {
  UciName = "ZonePanel",
  SettingsPage = "Settings",
  HomePage = "Home",
  Pin = "4321",             -- change per site; do not ship the default
  IdleSeconds = 60,         -- auto-leave Settings after this long
  MaxAttempts = 3,
  LockoutSeconds = 30,
}

local attempts = 0
local locked = false

local idleTimer = Timer.New()
local lockTimer = Timer.New()

local function setStatus(msg)
  Controls.PinStatus.String = msg
end

local function goHome()
  idleTimer:Stop()
  Uci.SetPage(CFG.UciName, CFG.HomePage)
end

idleTimer.EventHandler = function()
  print("[UciNav] Settings idle timeout")
  goHome()
end

lockTimer.EventHandler = function()
  lockTimer:Stop()
  locked = false
  attempts = 0
  setStatus("Enter PIN")
end

Controls.PinSubmit.EventHandler = function()
  if locked then return end

  if Controls.PinEntry.String == CFG.Pin then
    attempts = 0
    Controls.PinEntry.String = ""
    setStatus("Enter PIN")
    Uci.SetPage(CFG.UciName, CFG.SettingsPage)
    idleTimer:Start(CFG.IdleSeconds)
  else
    attempts = attempts + 1
    Controls.PinEntry.String = ""
    if attempts >= CFG.MaxAttempts then
      locked = true
      setStatus("Locked for " .. CFG.LockoutSeconds .. "s")
      lockTimer:Start(CFG.LockoutSeconds)
    else
      setStatus("Wrong PIN (" .. (CFG.MaxAttempts - attempts) .. " tries left)")
    end
  end
end

Controls.PinClear.EventHandler = function()
  Controls.PinEntry.String = ""
end

-- "Done" button on the Settings page cancels the idle timer so it can't
-- yank the user to Home later if they are somewhere else by then.
Controls.SettingsDone.EventHandler = function()
  idleTimer:Stop()
end

setStatus("Enter PIN")
