# AzerothCore Killstreak Bonus XP Script (Eluna)

This is a lightweight Eluna script for [AzerothCore](https://www.azerothcore.org/) that rewards players with bonus experience when chaining multiple PvE kills in quick succession. The system incentivizes aggressive mob pulling and farming efficiency, without being exploitable through gray mobs or PvP.

---

## 🔥 Features

- 🧠 **Smart Killstreak Tracking**: Tracks consecutive PvE kills with a 5-second expiration timer.
- 📈 **XP Scaling**: Bonus XP scales with streak length and mob difficulty.
- 🏆 **Bonus Modifiers**:
  - Elite mobs: +25% XP
  - Rare elites: +50% XP
  - World bosses: +100% XP
- 🛡️ **Anti-Exploit**:
  - No XP gain from gray mobs
  - No reward on death or logout
  - Timer auto-clears and cleans itself
- ⚙️ **Fully Configurable**: Adjust timers, XP scaling curve, and rank multipliers easily.

---

## 🛠 Configuration

Edit these values at the top of the script to adjust how XP is calculated:

```lua
local STREAK_TIMEOUT = 5        -- seconds before streak expires
local BASE_SCALE = 0.1          -- base bonus XP multiplier
local SCALE_MULTIPLIER = 0.03   -- how fast the XP bonus grows
local SCALE_EXPONENT = 0.7      -- curve sharpness
local MAX_SCALE = 1.0           -- max bonus multiplier (100%)
