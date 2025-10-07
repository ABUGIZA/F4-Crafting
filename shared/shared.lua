F4 = {}

-- Supported inventory systems: ox_inventory, qb-inventory
F4.img = "ox_inventory"

function F4.getItemImage(item)
    if F4.img == "ox_inventory" then
        return 'nui://ox_inventory/web/images/' .. item .. '.png'
    elseif F4.img == "qb-inventory" then
        return 'nui://qb-inventory/html/images/' .. item .. '.png'
    else
        return 'nui://ox_inventory/web/images/' .. item .. '.png'
    end
end

F4.CraftingItems = {
    {
        name = '9mm AP Ammo',
        item = 'ammo-9',
        level = 0,
        description = 'Armor-piercing 9mm rounds',
        xpReward = 60,
        requirements = {
            { item = 'steel', amount = 3, label = 'Steel' },
            { item = 'rubber', amount = 3, label = 'Rubber' },
            { item = 'copper', amount = 1, label = 'Copper' },
            { item = 'iron', amount = 1, label = 'Iron' },
        }
    },
    {
        name = 'Hunting Ammo',
        item = 'ammo-rifle',
        level = 1,
        description = 'Precision hunting rounds',
        xpReward = 5,
        requirements = {
            { item = 'steel', amount = 2, label = 'Steel' },
            { item = 'gunpowder', amount = 2, label = 'Gunpowder' }
        }
    },
    {
        name = 'Hunting Ammo MK2',
        item = 'ammo-rifle2',
        level = 2,
        description = 'High-penetration rifle rounds',
        xpReward = 8,
        requirements = {
            { item = 'steel', amount = 3, label = 'Steel' },
            { item = 'gunpowder', amount = 4, label = 'Gunpowder' },
            { item = 'copper', amount = 2, label = 'Copper' }
        }
    },
    {
        name = 'Shotgun Shells',
        item = 'ammo-shotgun',
        level = 2,
        description = 'Close-range devastation',
        xpReward = 8,
        requirements = {
            { item = 'steel', amount = 2, label = 'Steel' },
            { item = 'gunpowder', amount = 5, label = 'Gunpowder' },
            { item = 'plastic', amount = 2, label = 'Plastic' }
        }
    },
    {
        name = 'Grenade Ammo',
        item = 'ammo-grenade',
        level = 3,
        description = 'Devastating armor-piercing rounds',
        xpReward = 12,
        requirements = {
            { item = 'steel', amount = 4, label = 'Steel' },
            { item = 'gunpowder', amount = 6, label = 'Gunpowder' },
            { item = 'copper', amount = 3, label = 'Copper' }
        }
    }
}

F4.XPPerLevel = 600
F4.XPPerHexagon = 100

F4.CraftingRadius = 2.5
F4.Debug = false

function F4.interaction(id, coords) 
    exports.interact:AddInteraction({
        coords = vec3(coords.x, coords.y, coords.z + 1.0),
        distance = 8.0,
        interactDst = 1.0,
        id = id,
        name = id,
        options = {
            {
                label = 'Crafting',
                action = function(entity, coords, args)
                    TriggerEvent('f4_crafting:openUI')
                end
            }
        }
    })
end

F4.BenchModel = 'xm3_prop_xm3_bench_04b'
