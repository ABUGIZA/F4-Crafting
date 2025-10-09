# F4 Crafting
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
##
 Updates / Changelog
-
 
**
Blueprint System Added
**
: A new blueprint system has been implemented. Make sure to add the blueprint item to 
`
ox_inventory\data\items
`
:
```
lua
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

### Giving a Player a Blueprint (via ox_inventory)
To give a player a blueprint item, use the following export command in your server script:

```lua
exports.ox_inventory:AddItem(src, 'blueprint', 1, { type = 'tools' })
```
- `src` is the player's source ID.
- `'blueprint'` is the item name.
- `1` is the quantity.
- `{ type = 'tools' }` is optional metadata.

-
 
**
Dynamic Crafting Time System
**
: Crafting time now scales based on the number of items being crafted.
**
View Update Demo
**
: https://streamable.com/031rwo
