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
![Main UI - Item selection and crafting](https://res.cloudinary.com/dmcz9xz4d/image/upload/v1759866796/85de3c78-c396-44df-b502-c3d85d3549dd.png)
*Main crafting UI — item selection, crafting preview and material requirements.*

![Alternate UI view](https://res.cloudinary.com/dmcz9xz4d/image/upload/v1759866812/aa81b673-ee92-4ebf-a633-fa4ea019a625.png)
*Alternate view highlighting materials and controls.*

![In-game Workbench / Crafting Table](https://res.cloudinary.com/dmcz9xz4d/image/upload/v1759866826/5a414acf-02bf-4da0-bf24-f9ee755b3cd7.png)
*Example in-game crafting table / workbench.*

## Requirements
- Qbox Framework
- ox_lib
- oxmysql
- interact
- object_gizmo — https://github.com/DemiAutomatic/object_gizmo

## Installation
1. Execute `f4_Crafting.sql` in your database
2. Add to `server.cfg`:
```txt
ensure F4-Crafting
```

## Configuration

Inventory System — edit `shared/shared.lua`:
```lua
F4.img = "ox_inventory"  -- "ox_inventory" or "qb-inventory"
```

Add crafting items — example:
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

XP settings (example):
```lua
F4.XPPerLevel = 600
F4.XPPerHexagon = 100
```

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

## License
MIT License — include the full MIT license text in the LICENSE file.

## Notes
- Make sure your server's oxmysql is configured and accessible.
- If you use qb-inventory, verify inventory function names and adapt any inventory-specific calls in client/server code.
