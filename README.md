# Killstreak Bonus XP Script

This is a lightweight Eluna script for [AzerothCore](https://www.azerothcore.org/) that rewards players with bonus experience when chaining multiple **PvE** kills in quick succession. The system incentivizes aggressive mob pulling and farming efficiency, without being exploitable through gray mobs, critters, or PvP.

---

## 🔥 Features

- 🧠 Smart Killstreak Tracking: Tracks consecutive PvE kills with a 5-second expiration timer.
- ⚔️ PvP Honor killstreaks now work! Get extra honor for going nuts in a battleground!
- 📈 XP Scaling: Bonus XP increases based on kill count using a curved formula.
- 🏆 Bonus Modifiers by Mob Rank:
  - Elite mobs: +25% XP
  - Rare elites: +50% XP
  - World bosses: +100% XP
- 🛡️ Anti-Exploit Logic:
  - ❌ No XP for PvP kills
  - ❌ Streaks Cap out at 50 kills to prevent potentially gaining hundreds of thousands of exp from a single streak.
  - ❌ No XP for critters or mobs that give no experience
  - ❌ No bonus if you die or log out before streak ends
  - 🧹 Automatically cleans up all player data and timers
- ⚙️ Fully Configurable:
  - Adjust XP curve scaling
  - Modify bonus values by mob rank
  - Change timeout window

---

## 🛠 Configuration

All config values are at the top of the script for easy tuning:

- local STREAK_TIMEOUT = 5        -- Seconds before streak expires
- local BASE_SCALE = 0.1          -- Base XP bonus multiplier
- local SCALE_MULTIPLIER = 0.03   -- Growth speed of XP bonus
- local SCALE_EXPONENT = 0.7      -- Curve sharpness (lower = faster early growth)
- local MAX_SCALE = 1.0           -- Max total multiplier (1.0 = 100% bonus)

Mob rank XP multipliers:
   - 1.0x  Normal mob
   - 1.25x Elite mob
   - 1.5x Rare Elite mob
   - 2.0x World Boss

---

## 💻Installation:
Requires Eluna Engine!
1. Place the script in your Lua scripts directory.
2. Restart your world server.
3. Profit!

---
## ‼️Disclaimer:
- This should be compatible with any other script as well as it works with playerbots!
- There is a slight concern for performance in massive servers (3000+ players)
- You may not sell this script. Any edits must freely be distributed back into the modding scene if you publish them.
- I kindly ask you give credit if you do edit the script.


## 🗒️Credits:
- Created by Doodihealz / Corey
