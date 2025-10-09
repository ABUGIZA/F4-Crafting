# F4 Crafting
##
 Installation
1.
 Execute 
`
f4_Crafting.sql
`
 in your database
2.
 Add to 
`
server.cfg
`
:
```
txt
ensure F4-Crafting
```
##
 Configuration
Inventory System — edit 
`
shared/shared.lua
`
:
```
lua
F4.img = "ox_inventory"  -- "ox_inventory" or "qb-inventory"
```
Add crafting items — example:
```
lua
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
```
lua
F4.XPPerLevel = 600
F4.XPPerHexagon = 100
```
 Player Metadata Setup
Add the following lines to your 
`
qbx_core/server/player.lua
`
 file (around where other metadata fields are initialized):
```
lua
playerData.metadata.crafting_level = playerData.metadata.crafting_level or 0
playerData.metadata.crafting_xp = playerData.metadata.crafting_xp or 0
```
This ensures every player starts with crafting progression data (level and XP) initialized properly.
##
 Database
Execute the following SQL to create the crafting benches table:
```
sql
CREATE TABLE IF NOT EXISTS `f4_crafting` (
    `id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique identifier for each crafting bench',
    `x` FLOAT NOT NULL COMMENT 'X coordinate of the crafting bench',
    `y` FLOAT NOT NULL COMMENT 'Y coordinate of the crafting bench',
    `z` FLOAT NOT NULL COMMENT 'Z coordinate of the crafting bench',
    `heading` FLOAT NOT NULL COMMENT 'Heading of the crafting bench',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```
##
 Commands
-
 
`
/addcraftingtable
`
 — Add crafting bench (admin)
##
 Demo / Video
Watch the demo video: https://youtu.be/aEZfh85U2n4
Discord : https://discord.gg/CXYX39zkma
##
 License
MIT License — include the full MIT license text in the LICENSE file.

## Updates / Changelog

- **Blueprint System Added**: A new blueprint system has been implemented. Make sure to add the blueprint item to `ox_inventory\data\items`:
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

- **Dynamic Crafting Time System**: Crafting time now scales based on the number of items being crafted.

**View Update Demo**: https://streamable.com/031rwo
