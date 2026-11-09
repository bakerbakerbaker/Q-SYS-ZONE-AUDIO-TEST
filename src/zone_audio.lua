--[[
  Q-SYS Sample Project: Multi-Zone Audio + Scenes
  -----------------------------------------------
  Script component controls:
    ZoneLevel    Knob    (Float, -60..0 dB)       Count = 4
    ZoneMute     Button  (Toggle)                  Count = 4
    Scene        Button  (Trigger)                 Count = 3
    SceneActive  LED     (Indicator, Boolean)      Count = 3
    AllMute      Button  (Toggle)
    Status       Text    (Indicator)

  Named components needed in the design (Code Name):
    "ZoneGain1" .. "ZoneGain4"   Gain blocks with controls "gain" and "mute"
]]

-- ---------- Configuration ----------
local NUM_ZONES = 4
local ZONE_NAMES = { "Bar", "Dining", "Patio", "Lounge" }

local MAX_LEVEL = -6   -- safety ceiling per zone, dB

local SCENES = {
  { name = "Lunch",   levels = { -30, -28, -35, -40 }, mutes = { false, false, false, true  } },
  { name = "Dinner",  levels = { -24, -26, -30, -28 }, mutes = { false, false, false, false } },
  { name = "Closing", levels = { -40, -45, -60, -45 }, mutes = { false, false, true,  false } },
}

-- ---------- Helpers ----------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function setStatus(msg)
  Controls.Status.String = msg
  print("[ZoneAudio] " .. msg)
end

-- Look up gain blocks once, tolerating missing ones
local gains = {}
for i = 1, NUM_ZONES do
  local ok, comp = pcall(Component.New, "ZoneGain" .. i)
  if ok and comp then
    gains[i] = comp
  else
    print("[ZoneAudio] Missing component ZoneGain" .. i)
  end
end

-- Set when a scene is being recalled, so handlers don't clear the scene LEDs
local recalling = false

local function clearSceneLeds()
  for s = 1, #SCENES do
    Controls.SceneActive[s].Boolean = false
  end
end

-- ---------- Zone control ----------
local function applyLevel(i)
  local lvl = clamp(Controls.ZoneLevel[i].Value, -60, MAX_LEVEL)
  if lvl ~= Controls.ZoneLevel[i].Value then
    Controls.ZoneLevel[i].Value = lvl
  end
  if gains[i] then gains[i]["gain"].Value = lvl end
end

local function applyMute(i)
  if gains[i] then gains[i]["mute"].Boolean = Controls.ZoneMute[i].Boolean end
end

for i = 1, NUM_ZONES do
  Controls.ZoneLevel[i].EventHandler = function()
    applyLevel(i)
    if not recalling then clearSceneLeds() end
  end

  Controls.ZoneMute[i].EventHandler = function()
    applyMute(i)
    setStatus(ZONE_NAMES[i] .. (Controls.ZoneMute[i].Boolean and " muted" or " unmuted"))
    if not recalling then clearSceneLeds() end
  end
end

-- ---------- Scenes ----------
local function recallScene(s)
  local scene = SCENES[s]
  recalling = true
  for i = 1, NUM_ZONES do
    Controls.ZoneLevel[i].Value = scene.levels[i]
    Controls.ZoneMute[i].Boolean = scene.mutes[i]
    applyLevel(i)
    applyMute(i)
  end
  recalling = false

  clearSceneLeds()
  Controls.SceneActive[s].Boolean = true
  setStatus("Scene: " .. scene.name)
end

for s = 1, #SCENES do
  Controls.Scene[s].EventHandler = function() recallScene(s) end
end

-- ---------- Master mute ----------
-- Remembers each zone's mute state so un-muting restores the prior state.
local savedMutes = {}

Controls.AllMute.EventHandler = function(ctl)
  if ctl.Boolean then
    for i = 1, NUM_ZONES do
      savedMutes[i] = Controls.ZoneMute[i].Boolean
      Controls.ZoneMute[i].Boolean = true
      applyMute(i)
    end
    setStatus("ALL MUTED")
  else
    for i = 1, NUM_ZONES do
      Controls.ZoneMute[i].Boolean = savedMutes[i] or false
      applyMute(i)
    end
    setStatus("Mute released")
  end
end

-- ---------- Startup ----------
Controls.AllMute.Boolean = false
recallScene(2) -- default to the "Dinner" scene
setStatus("Ready")
