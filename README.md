# Enhanced Killstreak & Honor System
This is a comprehensive Eluna script for [AzerothCore](https://www.azerothcore.org/) that rewards players with bonus experience for **PvE killstreaks** and bonus honor for **PvP killstreaks**. The system features tier-based progression, authentic WoW PvP ranks, and balanced scaling to encourage aggressive gameplay without being exploitable.

---

##  Features

###  PvE Killstreak System
- **Smart Tracking**: Consecutive PvE kills with 5-second expiration timer
- **Tier Progression**: Every 5 kills unlocks a new tier with escalating names and colors
- **Tier Bonuses**: Each tier adds 1.5% to base 21% XP bonus (up to 28.5% at tier 10)
- **Kill Multiplier**: Scales from 1x to 15x based on streak length
- **Epic Naming**: From "On Fire!" to "Unfrigginbelievable!" with immersive color progression

###  PvP Honor System  
- **Authentic WoW Ranks**: Faction-specific rank progression every 5 kills
- **Alliance Ranks**: Private → Corporal → Sergeant → Master Sergeant → Sergeant Major → Knight → Knight-Lieutenant → Knight-Captain → Knight-Champion → Lieutenant Commander
- **Horde Ranks**: Scout → Grunt → Sergeant → Senior Sergeant → First Sergeant → Stone Guard → Blood Guard → Legionnaire → Centurion → Champion
- **Honor Tier Bonuses**: Each rank tier adds 2% to base 21% honor bonus
- **Visual Progression**: Color escalation from bright green to deep red

###  Anti-Exploit Protection
-  No XP/Honor from gray mobs or critters
-  Streaks cap at 50 kills to prevent excessive rewards
-  No cross-contamination between PvE and PvP systems
-  Automatic cleanup on death/logout
-  Level scaling prevents low-level exploitation
-  Comprehensive state management and memory cleanup

---

## Tier Progression

### PvE Killstreak Tiers
| Kills | Name | Color | Tier Bonus |
|-------|------|-------|------------|
| 5-9   | On Fire! | Bright Green | +22.5% XP |
| 10-14 | Rampage! | Yellow | +24% XP |
| 15-19 | Dominating! | Orange | +25.5% XP |
| 20-24 | Unstoppable! | Red-Orange | +27% XP |
| 25-29 | Merciless! | Red | +28.5% XP |
| 30-34 | Killtacular! | Dark Red | +30% XP |
| 35-39 | Apocalyptic! | Blood Red | +31.5% XP |
| 40-44 | Godlike! | Crimson | +33% XP |
| 45-49 | Legendary! | Deep Red | +34.5% XP |
| 50+   | Unfrigginbelievable! | Deep Red | +36% XP |

### PvP Honor Ranks
| Kills | Alliance Rank | Horde Rank | Tier Bonus |
|-------|---------------|------------|------------|
| 5-9   | Private | Scout | +23% Honor |
| 10-14 | Corporal | Grunt | +25% Honor |
| 15-19 | Sergeant | Sergeant | +27% Honor |
| 20-24 | Master Sergeant | Senior Sergeant | +29% Honor |
| 25-29 | Sergeant Major | First Sergeant | +31% Honor |
| 30-34 | Knight | Stone Guard | +33% Honor |
| 35-39 | Knight-Lieutenant | Blood Guard | +35% Honor |
| 40-44 | Knight-Captain | Legionnaire | +37% Honor |
| 45-49 | Knight-Champion | Centurion | +39% Honor |
| 50+   | Lieutenant Commander | Champion | +41% Honor |

---

## ⚙️ Configuration

### Core Settings
```lua
local STREAK_TIMEOUT        = 5     -- Seconds before PvE streak expires
local BONUS_PERCENT         = 0.21  -- Base XP bonus (21%)
local TIER_BONUS_PERCENT    = 0.015 -- XP bonus per tier (1.5%)
local MAX_LEVEL             = 80    -- Max level for XP bonuses
local MAX_KILLSTREAK        = 50    -- Cap for both systems
local MAX_KILL_MULTIPLIER   = 15    -- Max kill multiplier for XP

local HONOR_STREAK_TIMEOUT  = 5     -- Seconds before PvP streak expires  
local HONOR_BONUS_PERCENT   = 0.21  -- Base honor bonus (21%)
local HONOR_TIER_BONUS      = 0.02  -- Honor bonus per rank tier (2%)
local MAX_HONOR_STREAK      = 50    -- PvP killstreak cap
```

### Color Progression
```lua
-- Escalating color system from green to deep red
BRIGHT_GREEN → YELLOW_GREEN → YELLOW → ORANGE → RED_ORANGE → 
RED → DARK_RED → BLOOD_RED → CRIMSON → DEEP_RED
```

---

##  Bonus Calculations

### PvE Experience Bonus
```
Final XP = Base XP × (Base% + Tier%) × Kill Multiplier × Level Scaling
```
- **Base Bonus**: 21%
- **Tier Bonus**: +1.5% per tier (every 5 kills)
- **Kill Multiplier**: Min(kills, 15)
- **Level Scaling**: 1 + (level / 200)

### PvP Honor Bonus  
```
Final Honor = Base Honor × (Base% + Tier% + Level%)
```
- **Base Bonus**: 21%
- **Tier Bonus**: +2% per rank tier (every 5 kills)
- **Level Scaling**: +level/1000

---

##  Installation

### Requirements
- [Eluna Engine](https://github.com/ElunaLuaEngine/Eluna) installed
- Made on Azerothcore. May not work out of the box with other server engines.

### Setup
1. Place script in your `lua_scripts` directory
2. Restart world server or .reload eluna
3. Enjoy!

---

## Balance Philosophy

The system is designed to reward skilled play without breaking game balance:

- **Moderate Scaling**: Bonuses are meaningful but not game-breaking
- **Effort-Based**: Higher streaks require sustained performance
- **Risk vs Reward**: Streaks reset on death, encouraging careful play
- **Level Appropriate**: Scaling prevents low-level exploitation
- **PvP Focus**: Honor bonuses encourage battleground participation

---

##  Performance Notes

- **Optimized Design**: Event-driven architecture minimizes overhead
- **Smart Cleanup**: Automatic state management prevents memory leaks
- **Efficient Polling**: 2-second intervals for timeout checking
- **Scalable**: Handles typical server populations without issues

---

##  Disclaimer

-  Compatible with playerbots and other luascripts
-  This script may not be sold. Modifications may not be sold either.
-  Edits must be freely distributed if published
-  Please provide credit to me if you mod and redistribute this.

---

## Credits
Doodihealz / Corey  
