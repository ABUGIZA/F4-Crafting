F4 = {}

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
        name = 'Lockpick',
        item = 'lockpick',
        level = 0,
        description = 'Basic lockpicking tool',
        xpReward = 10,
        time = 3,
        requirements = {
            { item = 'metalscrap', amount = 2, label = 'Metal Scrap' },
            { item = 'plastic', amount = 1, label = 'Plastic' }
        }
    },
    {
        name = 'Advanced Lockpick',
        item = 'advancedlockpick',
        level = 2,
        description = 'Professional lockpicking tool',
        xpReward = 25,
        time = 8,
        requirements = {
            { item = 'metalscrap', amount = 3, label = 'Metal Scrap' },
            { item = 'plastic', amount = 2, label = 'Plastic' },
            { item = 'rubber', amount = 1, label = 'Rubber' },
            { item = 'blueprint', amount = 1, label = 'Blueprint', metadata = { type = 'opmw' } }
        }
    },
    {
        name = 'Screwdriver Set',
        item = 'screwdriverset',
        level = 1,
        description = 'Complete screwdriver set for repairs',
        xpReward = 15,
        time = 5,
        requirements = {
            { item = 'steel', amount = 2, label = 'Steel' },
            { item = 'plastic', amount = 1, label = 'Plastic' },
            { item = 'rubber', amount = 1, label = 'Rubber' }
        }
    },
    {
        name = 'Electronic Kit',
        item = 'electronickit',
        level = 3,
        description = 'Advanced electronic repair kit',
        xpReward = 35,
        time = 12,
        requirements = {
            { item = 'copper', amount = 3, label = 'Copper' },
            { item = 'plastic', amount = 2, label = 'Plastic' },
            { item = 'glass', amount = 1, label = 'Glass' },
            { item = 'blueprint', amount = 1, label = 'Blueprint', metadata = { type = 'electronics' } }
        }
    },
    {
        name = 'Bandage',
        item = 'bandage',
        level = 0,
        description = 'Basic medical bandage',
        xpReward = 8,
        time = 2,
        requirements = {
            { item = 'plastic', amount = 1, label = 'Plastic' },
            { item = 'rubber', amount = 1, label = 'Rubber' }
        }
    },
    {
        name = 'First Aid',
        item = 'firstaid',
        level = 2,
        description = 'Complete first aid kit',
        xpReward = 30,
        time = 10,
        requirements = {
            { item = 'bandage', amount = 3, label = 'Bandage' },
            { item = 'plastic', amount = 2, label = 'Plastic' },
            { item = 'rubber', amount = 1, label = 'Rubber' }
        }
    },
    {
        name = 'Painkillers',
        item = 'painkillers',
        level = 1,
        description = 'Pain relief medication',
        xpReward = 12,
        time = 4,
        requirements = {
            { item = 'glass', amount = 1, label = 'Glass' },
            { item = 'plastic', amount = 1, label = 'Plastic' }
        }
    },
    {
        name = 'Diamond',
        item = 'diamond_ring',
        level = 4,
        description = 'Valuable diamond ring',
        xpReward = 50,
        time = 15,
        requirements = {
            { item = 'glass', amount = 2, label = 'Glass' },
            { item = 'metalscrap', amount = 1, label = 'Metal Scrap' },
            { item = 'blueprint', amount = 1, label = 'Blueprint', metadata = { type = 'jewelry' } }
        }
    },
    {
        name = 'Golden Watch',
        item = 'rolex',
        level = 3,
        description = 'Luxury golden watch',
        xpReward = 40,
        time = 12,
        requirements = {
            { item = 'metalscrap', amount = 2, label = 'Metal Scrap' },
            { item = 'glass', amount = 1, label = 'Glass' },
            { item = 'rubber', amount = 1, label = 'Rubber' }
        }
    },
    {
        name = 'Gold Bar',
        item = 'goldbar',
        level = 5,
        description = 'Pure gold bar',
        xpReward = 75,
        time = 20,
        requirements = {
            { item = 'metalscrap', amount = 5, label = 'Metal Scrap' },
            { item = 'copper', amount = 2, label = 'Copper' },
            { item = 'blueprint', amount = 1, label = 'Blueprint', metadata = { type = 'gold' } }
        }
    },
    {
        name = '2Brothers Firework',
        item = 'firework1',
        level = 2,
        description = 'Colorful firework display',
        xpReward = 20,
        time = 8,
        requirements = {
            { item = 'plastic', amount = 2, label = 'Plastic' },
            { item = 'metalscrap', amount = 1, label = 'Metal Scrap' },
            { item = 'rubber', amount = 1, label = 'Rubber' }
        }
    },
    {
        name = 'Poppelers Firework',
        item = 'firework2',
        level = 3,
        description = 'Advanced firework with multiple colors',
        xpReward = 30,
        time = 12,
        requirements = {
            { item = 'plastic', amount = 3, label = 'Plastic' },
            { item = 'metalscrap', amount = 2, label = 'Metal Scrap' },
            { item = 'glass', amount = 1, label = 'Glass' },
            { item = 'blueprint', amount = 1, label = 'Blueprint', metadata = { type = 'fireworks' } }
        }
    },
    {
        name = 'Repair Kit',
        item = 'repairkit',
        level = 2,
        description = 'Basic vehicle repair kit',
        xpReward = 25,
        time = 10,
        requirements = {
            { item = 'metalscrap', amount = 3, label = 'Metal Scrap' },
            { item = 'rubber', amount = 2, label = 'Rubber' },
            { item = 'plastic', amount = 2, label = 'Plastic' }
        }
    },
    {
        name = 'Advanced Repair Kit',
        item = 'advancedrepairkit',
        level = 4,
        description = 'Professional vehicle repair kit',
        xpReward = 60,
        time = 18,
        requirements = {
            { item = 'steel', amount = 2, label = 'Steel' },
            { item = 'metalscrap', amount = 4, label = 'Metal Scrap' },
            { item = 'rubber', amount = 3, label = 'Rubber' },
            { item = 'blueprint', amount = 1, label = 'Blueprint', metadata = { type = 'advanced_tools' } }
        }
    }
}

F4.XPPerLevel = 600
F4.XPPerHexagon = 100

F4.CraftingRadius = 2.5
F4.Debug = false

function F4.interaction(id, coords, tableId)
    exports.interact:AddInteraction({
        coords = vec3(coords.x, coords.y, coords.z + 1.0),
        distance = 8.0,
        interactDst = 1.0,
        id = id,
        name = id,
        options = {
            {
                label = 'Crafting',
                args = {
                    tableId = tableId
                },
                action = function(entity, coords, args)
                    local targetTableId = args and args.tableId or tableId
                    TriggerEvent('f4_crafting:openUI', targetTableId)
                end
            }
        }
    })
end

F4.BenchModel = 'xm3_prop_xm3_bench_04b'
