local QBCore = exports['qb-core']:GetCoreObject()

local function IsOxInventory()
    return GetResourceState('ox_inventory') == 'started'
end

local function GetItemCount(Player, src, itemName)
    if IsOxInventory() then
        local item = exports.ox_inventory:GetItem(src, itemName, nil, true)
        if item and type(item) == "table" and item.count then
            return item.count
        end
        
        item = exports.ox_inventory:GetItem(src, itemName)
        if item and type(item) == "table" and item.count then
            return item.count
        end
        
        local playerItems = Player.PlayerData.items
        if playerItems then
            local totalCount = 0
            for _, playerItem in pairs(playerItems) do
                if playerItem and playerItem.name == itemName then
                    totalCount = totalCount + (playerItem.count or 0)
                end
            end
            return totalCount
        end
    else
        local item = Player.Functions.GetItemByName(itemName)
        if item and type(item) == "table" and item.amount then
            return item.amount
        end
        
        local playerItems = Player.PlayerData.items
        if playerItems then
            local totalCount = 0
            for _, playerItem in pairs(playerItems) do
                if playerItem and playerItem.name == itemName then
                    totalCount = totalCount + (playerItem.amount or 0)
                end
            end
            return totalCount
        end
    end
    
    return 0
end

local function RemoveItem(Player, src, itemName, amount)
    if IsOxInventory() then
        return exports.ox_inventory:RemoveItem(src, itemName, amount)
    else
        local removed = Player.Functions.RemoveItem(itemName, amount)
        if removed then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove', amount)
        end
        return removed
    end
end

local function AddItem(Player, src, itemName, amount)
    if IsOxInventory() then
        return exports.ox_inventory:AddItem(src, itemName, amount)
    else
        local added = Player.Functions.AddItem(itemName, amount)
        if added then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add', amount)
        end
        return added
    end
end

QBCore.Functions.CreateCallback('f4_crafting:getTables', function(source, cb)
    MySQL.query('SELECT * FROM f4_crafting', {}, function(result)
        cb(result or {})
    end)
end)

QBCore.Functions.CreateCallback('f4_crafting:getMeta', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return cb(0, 0)
    end
    
    local md = Player.PlayerData.metadata or {}
    local level = md.crafting_level or 0
    local xp = md.crafting_xp or 0
    
    cb(level, xp)
end)

QBCore.Functions.CreateCallback('f4_crafting:craftItem', function(source, cb, itemIndex, quantity)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        return cb(false, 'Player not found') 
    end
    
    local item = F4.CraftingItems[itemIndex + 1]
    if not item then 
        return cb(false, 'Item not found') 
    end
    
    local craftingLevel = 0
    if Player.PlayerData.metadata then
        craftingLevel = Player.PlayerData.metadata.crafting_level or 0
    end
    
    if item.level > craftingLevel then
        return cb(false, 'You need crafting level ' .. item.level .. ' to craft this item')
    end
    
    local missingItems = {}
    for _, req in ipairs(item.requirements) do
        if GetItemCount(Player, src, req.item) < req.amount * quantity then
            table.insert(missingItems, req.label)
        end
    end
    
    if #missingItems > 0 then
        return cb(false, 'Missing materials: ' .. table.concat(missingItems, ', '))
    end
    
    local removedItems = {}
    for _, req in ipairs(item.requirements) do
        local amount = req.amount * quantity
        if not RemoveItem(Player, src, req.item, amount) then
            for _, removed in ipairs(removedItems) do
                AddItem(Player, src, removed.item, removed.amount)
            end
            return cb(false, 'Failed to remove ' .. req.label)
        end
        table.insert(removedItems, {item = req.item, amount = amount})
    end
    
    if not AddItem(Player, src, item.item, quantity) then
        for _, removed in ipairs(removedItems) do
            AddItem(Player, src, removed.item, removed.amount)
        end
        return cb(false, 'Failed to add crafted item')
    end
    
    local currentXP = 0
    if Player.PlayerData.metadata and Player.PlayerData.metadata.crafting_xp then
        currentXP = Player.PlayerData.metadata.crafting_xp
    end
    
    local xpGain = (item.xpReward or 0) * quantity
    local newXP = currentXP + xpGain
    local newLevel = craftingLevel
    
    if newXP >= F4.XPPerLevel then
        newLevel = craftingLevel + 1
        newXP = newXP - F4.XPPerLevel
        
        Player.Functions.SetMetaData('crafting_level', newLevel)
        Player.Functions.SetMetaData('crafting_xp', newXP)
        
        TriggerClientEvent('QBCore:Notify', src, 'Crafting Level Up! Now level ' .. newLevel, 'success')
        TriggerClientEvent('f4_crafting:updateLevel', src, newLevel, newXP)
    else
        Player.Functions.SetMetaData('crafting_xp', newXP)
        TriggerClientEvent('f4_crafting:updateLevel', src, newLevel, newXP)
    end
    
    cb(true, 'Successfully crafted ' .. quantity .. 'x ' .. item.name .. ' (+' .. xpGain .. ' XP)')
end)

RegisterNetEvent('f4_crafting:saveTablePosition', function(x, y, z, heading)
    local src = source
    
    MySQL.insert('INSERT INTO f4_crafting (x, y, z, heading) VALUES (?, ?, ?, ?)', {
        x, y, z, heading
    }, function(insertId)
        if insertId then
            TriggerClientEvent('QBCore:Notify', src, 'Crafting table saved successfully', 'success')
            TriggerClientEvent('f4_crafting:refreshTables', -1)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to save crafting table', 'error')
        end
    end)
end)

QBCore.Commands.Add('addcraftingtable', 'Add a crafting table (Admin Only)', {}, true, function(source, args)
    TriggerClientEvent('f4_crafting:createTable', source)
end, 'admin')

if F4.Debug then
    print('^2[F4 Crafting]^7 Server loaded successfully')
end
