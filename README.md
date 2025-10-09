# F4 Crafting
Professional crafting system for FiveM / Qbox with UI and level progression.

## Description
F4 Crafting is a modular crafting system for FiveM servers using the QBCore framework. It provides a polished UI, level progression, XP rewards, and configurable crafting recipes. Designed to work with ox_inventory or qb-inventory and integrate with ox_lib, oxmysql, interact, and object_gizmo.

## Features
- Interactive crafting UI with stations
- Item level progression and XP rewards
- Configurable crafting recipes and material requirements
- Support for ox_inventory and qb-inventory
- Integration with ox_lib, oxmysql, interact and object_gizmo

## Screenshots
![Main UI - Item selection and crafting](https://camo.githubusercontent.com/9b84abf4cf3bc2eba5eb2c9cef08cd59f2ef9c92c163ec12a4d0505fcc6641a2/68747470733a2f2f7265732e636c6f7564696e6172792e636f6d2f646d637a39787a34642f696d6167652f75706c6f61642f76313735393836363739362f38356465336337382d633339362d343464662d623530322d6333643835643335343964642e706e67)
Main crafting UI — item selection, crafting preview and material requirements.

![Alternate UI view](https://camo.githubusercontent.com/9e9d878351798671de6023279811e20de08fb56a65c005f1405164101c934dc4/68747470733a2f2f7265732e636c6f7564696e6172792e636f6d2f646d637a39787a34642f696d6167652f75706c6f61642f76313735393836363831322f61613831623637332d656539322d346562662d613633332d6661346561303139613632352e706e67)
Alternate view highlighting materials and controls.

![In-game Workbench / Crafting Table](https://camo.githubusercontent.com/6f44936f4db09e7413b4b08ed4c6c9a8fd29116f322ca5b1b599ee1ddd63dafc/68747470733a2f2f7265732e636c6f7564696e6172792e636f6d2f646d637a39787a34642f696d6167652f75706c6f61642f76313735393836363832362f35613431346163662d303262662d346461302d626632342d6639656537353562336364372e706e67)
Example in-game crafting table / workbench.

## Requirements
- Qbox Framework
- ox_lib
- oxmysql
- interact
- object_gizmo — https://github.com/DemiAutomatic/object_gizmo

## Installation
1. Execute f4_Crafting.sql in your database
2. Add to server.cfg:
```
ensure F4-Crafting
```

## Configuration
### Inventory System — edit shared/shared.lua:
```lua
F4.img = "ox_inventory"  -- "ox_inventory" or "qb-inventory"
```

### Add crafting items — example:
```lua
F4.CraftingItems = {
    {
        name = 'Item Name',
        item = 'item_spawn_name',
        level = 0,
        description = 'Item description',
        xpReward = 10,
        requirements = {
            { item = 'steel', amount = 2, label = 'Steel' }
        }
    }
}
```

### XP settings (example):
```lua
F4.XPPerLevel = 600
F4.XPPerHexagon = 100
```

### Player Metadata Setup
Add the following lines to your qbx_core/server/player.lua file (around where other metadata fields are initialized):
```lua
playerData.metadata.crafting_level = playerData.metadata.crafting_level or 0
playerData.metadata.crafting_xp = playerData.metadata.crafting_xp or 0
```
This ensures every player starts with crafting progression data (level and XP) initialized properly.

## Database
Execute the following SQL to create the crafting benches table:
```sql
CREATE TABLE IF NOT EXISTS `f4_crafting` (
    `id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique identifier for each crafting bench',
    `x` FLOAT NOT NULL COMMENT 'X coordinate of the crafting bench',
    `y` FLOAT NOT NULL COMMENT 'Y coordinate of the crafting bench',
    `z` FLOAT NOT NULL COMMENT 'Z coordinate of the crafting bench',
    `heading` FLOAT NOT NULL COMMENT 'Heading of the crafting bench',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Commands
- `/addcraftingtable` — Add crafting bench (admin)

## Demo / Video
Watch the demo video: https://youtu.be/aEZfh85U2n4

Discord : https://discord.gg/CXYX39zkma

## License
MIT License — include the full MIT license text in the LICENSE file.

## Updates

### Latest Updates (October 2025)

1. **Blueprint System Added**
   - Introduced a professional blueprint system for crafting
   - Add the following item to your `ox_inventory\data\items.lua`:
   ```lua
   ['blueprint'] = {
       label = 'Blueprint',
       weight = 50,
       stack = false,
       close = true,
       consume = 0,
       description = 'A professional crafting blueprint with detailed specifications and requirements',
       client = {
           image = 'blueprint.png'
       }
   },
   ```

2. **Dynamic Crafting Time System**
   - Crafting time now scales based on the number of items being crafted
   - More items = longer crafting time for realistic progression

3. **Blueprint Distribution**
   - Use the following command to give players blueprints:
   ```lua
   exports.ox_inventory:AddItem(src, 'blueprint', 1, { type = 'tools' })
   ```

4. **Live Demo**
   - View the latest update demonstration: https://streamable.com/031rwo
