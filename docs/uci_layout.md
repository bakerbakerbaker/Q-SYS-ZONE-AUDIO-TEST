# UCI Build Guide: "ZonePanel" (multi-zone audio)

A touchscreen panel for a 4-zone venue (bar, dining, patio, lounge) with scene presets
and a PIN-protected settings page. Build it in Designer's UCI editor, 1280x800.

## Pages

| Page | Purpose |
|------|---------|
| `Home` | Scenes, master mute, and zone summary |
| `Zones` | Per-zone faders and mutes |
| `PIN` | Keypad for settings access |
| `Settings` | Protected page (put EQ, source routing or house settings here) |

Use **Page Change** buttons for plain navigation (Home <-> Zones, Home -> PIN, Settings -> Home).
The script is only needed for the PIN check and the idle timeout.

## Page: Home

| Element | Type | Bind to |
|---------|------|---------|
| "Lunch" | Button | `ZoneAudio` > `Scene 1` (Trigger) |
| "Dinner" | Button | `ZoneAudio` > `Scene 2` |
| "Closing" | Button | `ZoneAudio` > `Scene 3` |
| Scene LEDs (or button Legend lit state) | Indicator | `SceneActive 1..3` |
| "Mute All" | Toggle Button | `AllMute` |
| Status | Text Box (read-only) | `Status` |
| "Zones" | Page Change button | page `Zones` |
| "Settings" | Page Change button | page `PIN` |

## Page: Zones

Four identical columns (x = 80, 380, 680, 980; width 220):

| Element | Type | Bind to |
|---------|------|---------|
| Zone name | Text label | static (Bar, Dining, Patio, Lounge) |
| Level fader (vertical, 100x450) | Fader | `ZoneLevel 1..4` |
| Level readout | Text Box | same control, show value |
| Mute | Toggle Button | `ZoneMute 1..4` |
| "Home" | Page Change button | page `Home` |

Tip: copy/paste column 1, then rebind the pin index for each zone.

## Page: PIN

| Element | Type | Bind to |
|---------|------|---------|
| PIN display | Text Box, **Text Mode: Password** (shows dots) | `UciNav` > `PinEntry` |
| Digits 0-9 | 10 Buttons | each appends its digit to `PinEntry` (Button Type: Text Append; text = digit) |
| Clear | Trigger Button | `PinClear` |
| Enter | Trigger Button | `PinSubmit` |
| Feedback | Text Box (read-only) | `PinStatus` |
| Cancel | Page Change button | page `Home` |

If your Designer version has no Text Append button type, use a
UCI **Keypad** element instead and bind it to `PinEntry`.

## Page: Settings

Put whatever installer-only controls you need here. Required:

| Element | Type | Bind to |
|---------|------|---------|
| Done | Trigger Button **and** Page Change to `Home` | `SettingsDone` |

## Wire-up

1. Add Script `ZoneAudio` and paste `src/zone_audio.lua`. Add the control pins listed in the header
   (use **Count** for arrayed pins).
2. Add four Gain blocks with Code Names `ZoneGain1` to `ZoneGain4`.
3. Add Script `UciNav` and paste `src/uci_nav.lua`. Add its control pins.
4. Name the UCI `ZonePanel`, matching `CFG.UciName`.
5. Change `CFG.Pin` from `4321` before any real deployment.
6. Emulate (F5), open the UCI viewer, and try: scene recall, per-zone mute (scene LEDs go dark),
   Mute All, and a wrong-PIN lockout.
