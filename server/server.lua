local QBCore = exports['qb-core']:GetCoreObject()

local function IsOxInventory()
    return GetResourceState('ox_inventory') == 'started'
end

local function DecodeQueue(queueJson)
    if not queueJson or queueJson == '' then
        return {}
    end

    local ok, decoded = pcall(json.decode, queueJson)
    if not ok or type(decoded) ~= 'table' then
        return {}
    end

    local normalized = {}
    if #decoded > 0 then
        for _, entry in ipairs(decoded) do
            if type(entry) == 'table' then
                normalized[#normalized + 1] = entry
            end
        end
    else
        for _, entry in pairs(decoded) do
            if type(entry) == 'table' then
                normalized[#normalized + 1] = entry
            end
        end
    end

    return normalized
end

local function EncodeQueue(queue)
    return json.encode(queue or {})
end

local function GetCraftingTableById(tableId)
    return MySQL.single.await('SELECT id, x, y, z, heading, craft_queue FROM f4_crafting WHERE id = ? LIMIT 1', { tableId })
end

local function SaveCraftingTableQueue(tableId, queue)
    local affected = MySQL.update.await(
        'UPDATE f4_crafting SET craft_queue = ?, queue_updated_at = NOW() WHERE id = ? LIMIT 1',
        { EncodeQueue(queue), tableId }
    )

    return affected and affected > 0
end

local function IsPlayerNearCraftingTable(src, tableData, maxDistance)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return false
    end

    local playerCoords = GetEntityCoords(ped)
    local tableCoords = vector3(tonumber(tableData.x) or 0.0, tonumber(tableData.y) or 0.0, tonumber(tableData.z) or 0.0)
    local allowedDistance = maxDistance or (F4.CraftingRadius + 1.0)

    return #(playerCoords - tableCoords) <= allowedDistance
end

local function GenerateQueueId(src)
    return ('%d:%d:%d'):format(os.time(), src, math.random(100000, 999999))
end

local function BuildPlayerQueue(queue, citizenid)
    local now = os.time()
    local result = {}

    for _, entry in ipairs(queue) do
        if entry.citizenid == citizenid then
            local readyAt = tonumber(entry.readyAt) or now
            local timeLeft = math.max(0, readyAt - now)
            result[#result + 1] = {
                id = tostring(entry.id or ''),
                item = tostring(entry.item or ''),
                label = tostring(entry.label or entry.item or 'Unknown Item'),
                quantity = math.max(1, math.floor(tonumber(entry.quantity) or 1)),
                xpGain = math.max(0, math.floor(tonumber(entry.xpGain) or 0)),
                readyAt = readyAt,
                timeLeft = timeLeft,
                ready = timeLeft <= 0
            }
        end
    end

    table.sort(result, function(a, b)
        return (a.readyAt or 0) < (b.readyAt or 0)
    end)

    return result
end

local function GetItemCount(Player, src, itemName)
    if IsOxInventory() then
        local item = exports.ox_inventory:GetItem(src, itemName, nil, true)
        if item and type(item) == 'table' and item.count then
            return item.count
        end

        item = exports.ox_inventory:GetItem(src, itemName)
        if item and type(item) == 'table' and item.count then
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
        if item and type(item) == 'table' and item.amount then
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

local function CheckItemWithMetadata(Player, src, itemName, requiredMetadata, amount)
    if not requiredMetadata then
        return GetItemCount(Player, src, itemName) >= amount
    end

    local playerItems = Player.PlayerData.items
    if not playerItems then
        return false
    end

    local matchCount = 0
    for _, playerItem in pairs(playerItems) do
        if playerItem and playerItem.name == itemName then
            local metadata = playerItem.info or playerItem.metadata or {}
            local metadataMatch = true

            for key, value in pairs(requiredMetadata) do
                if metadata[key] ~= value then
                    metadataMatch = false
                    break
                end
            end

            if metadataMatch then
                matchCount = matchCount + (playerItem.count or playerItem.amount or 1)
            end
        end
    end

    return matchCount >= amount
end

local function RemoveItemWithMetadata(Player, src, itemName, requiredMetadata, amount)
    if not requiredMetadata then
        return RemoveItem(Player, src, itemName, amount)
    end

    local playerItems = Player.PlayerData.items
    if not playerItems then
        return false
    end

    local toRemove = amount
    local removedSlots = {}

    for slot, playerItem in pairs(playerItems) do
        if toRemove <= 0 then
            break
        end

        if playerItem and playerItem.name == itemName then
            local metadata = playerItem.info or playerItem.metadata or {}
            local metadataMatch = true

            for key, value in pairs(requiredMetadata) do
                if metadata[key] ~= value then
                    metadataMatch = false
                    break
                end
            end

            if metadataMatch then
                local itemAmount = playerItem.count or playerItem.amount or 1
                local removeAmount = math.min(itemAmount, toRemove)
                removedSlots[#removedSlots + 1] = { slot = slot, amount = removeAmount }
                toRemove = toRemove - removeAmount
            end
        end
    end

    if toRemove > 0 then
        return false
    end

    for _, removeData in ipairs(removedSlots) do
        if IsOxInventory() then
            exports.ox_inventory:RemoveItem(src, itemName, removeData.amount, nil, removeData.slot)
        else
            Player.Functions.RemoveItem(itemName, removeData.amount, removeData.slot)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove', removeData.amount)
        end
    end

    return true
end

local function ApplyCraftingXP(Player, src, xpGain)
    if xpGain <= 0 then
        return
    end

    local md = Player.PlayerData.metadata or {}
    local currentLevel = md.crafting_level or 0
    local currentXP = md.crafting_xp or 0

    local newLevel = currentLevel
    local newXP = currentXP + xpGain

    while newXP >= F4.XPPerLevel do
        newLevel = newLevel + 1
        newXP = newXP - F4.XPPerLevel
    end

    if newLevel ~= currentLevel then
        Player.Functions.SetMetaData('crafting_level', newLevel)
        TriggerClientEvent('QBCore:Notify', src, 'Crafting Level Up! Now level ' .. newLevel, 'success')
    end

    Player.Functions.SetMetaData('crafting_xp', newXP)
    TriggerClientEvent('f4_crafting:updateLevel', src, newLevel, newXP)
end

QBCore.Functions.CreateCallback('f4_crafting:getTables', function(source, cb)
    local result = MySQL.query.await('SELECT id, x, y, z, heading FROM f4_crafting')
    cb(result or {})
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

QBCore.Functions.CreateCallback('f4_crafting:getQueue', function(source, cb, tableId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        return cb({})
    end

    local tableNum = tonumber(tableId)
    if not tableNum then
        return cb({})
    end

    local craftingTable = GetCraftingTableById(tableNum)
    if not craftingTable then
        return cb({})
    end

    local queue = DecodeQueue(craftingTable.craft_queue)
    local playerQueue = BuildPlayerQueue(queue, Player.PlayerData.citizenid)
    cb(playerQueue)
end)

QBCore.Functions.CreateCallback('f4_crafting:craftItem', function(source, cb, itemIndex, quantity, tableId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return cb(false, 'Player not found')
    end

    local tableNum = tonumber(tableId)
    if not tableNum then
        return cb(false, 'Invalid crafting table')
    end

    local craftingTable = GetCraftingTableById(tableNum)
    if not craftingTable then
        return cb(false, 'Crafting table not found')
    end

    if not IsPlayerNearCraftingTable(src, craftingTable, F4.CraftingRadius + 1.5) then
        return cb(false, 'You must be near the selected crafting table')
    end

    local itemIdx = tonumber(itemIndex)
    local amount = math.floor(tonumber(quantity) or 0)
    if not itemIdx or amount <= 0 then
        return cb(false, 'Invalid crafting request')
    end

    local item = F4.CraftingItems[itemIdx + 1]
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
        local neededAmount = req.amount * amount
        if req.metadata then
            if not CheckItemWithMetadata(Player, src, req.item, req.metadata, neededAmount) then
                local hasBlueprint = GetItemCount(Player, src, req.item) > 0
                if hasBlueprint and req.item == 'blueprint' and req.metadata.type then
                    local displayType = req.metadata.type:gsub('_', ' '):gsub('^%l', string.upper)
                    missingItems[#missingItems + 1] = 'You need ' .. displayType .. ' Blueprint'
                else
                    missingItems[#missingItems + 1] = req.label
                end
            end
        else
            if GetItemCount(Player, src, req.item) < neededAmount then
                missingItems[#missingItems + 1] = req.label
            end
        end
    end

    if #missingItems > 0 then
        return cb(false, 'Missing materials: ' .. table.concat(missingItems, ', '))
    end

    local removedItems = {}
    for _, req in ipairs(item.requirements) do
        local neededAmount = req.amount * amount
        local removed = false

        if req.metadata then
            removed = RemoveItemWithMetadata(Player, src, req.item, req.metadata, neededAmount)
        else
            removed = RemoveItem(Player, src, req.item, neededAmount)
        end

        if not removed then
            for _, removedItem in ipairs(removedItems) do
                AddItem(Player, src, removedItem.item, removedItem.amount)
            end
            return cb(false, 'Failed to remove ' .. req.label)
        end

        removedItems[#removedItems + 1] = { item = req.item, amount = neededAmount }
    end

    local craftTime = item.time or 0
    local totalCraftTime = craftTime * amount
    local xpGain = (item.xpReward or 0) * amount

    local queue = DecodeQueue(craftingTable.craft_queue)
    queue[#queue + 1] = {
        id = GenerateQueueId(src),
        citizenid = Player.PlayerData.citizenid,
        tableId = tableNum,
        item = item.item,
        label = item.name,
        quantity = amount,
        xpGain = xpGain,
        readyAt = os.time() + totalCraftTime,
        createdAt = os.time()
    }

    if not SaveCraftingTableQueue(tableNum, queue) then
        for _, removedItem in ipairs(removedItems) do
            AddItem(Player, src, removedItem.item, removedItem.amount)
        end
        return cb(false, 'Failed to queue crafted item')
    end

    if totalCraftTime > 0 then
        TriggerClientEvent('f4_crafting:startCountdown', src, totalCraftTime)
    end

    cb(true, 'Craft started: ' .. amount .. 'x ' .. item.name .. '. Claim it from this table when ready.')
end)

QBCore.Functions.CreateCallback('f4_crafting:claimQueuedItem', function(source, cb, tableId, queueId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return cb(false, 'Player not found')
    end

    local tableNum = tonumber(tableId)
    if not tableNum then
        return cb(false, 'Invalid crafting table')
    end

    local targetQueueId = tostring(queueId or '')
    if targetQueueId == '' then
        return cb(false, 'Invalid queue item')
    end

    local craftingTable = GetCraftingTableById(tableNum)
    if not craftingTable then
        return cb(false, 'Crafting table not found')
    end

    if not IsPlayerNearCraftingTable(src, craftingTable, F4.CraftingRadius + 1.5) then
        return cb(false, 'You must claim from the same crafting table')
    end

    local queue = DecodeQueue(craftingTable.craft_queue)
    local citizenid = Player.PlayerData.citizenid

    local foundIndex = nil
    local foundEntry = nil
    for i, entry in ipairs(queue) do
        if tostring(entry.id or '') == targetQueueId and entry.citizenid == citizenid then
            foundIndex = i
            foundEntry = entry
            break
        end
    end

    if not foundIndex or not foundEntry then
        return cb(false, 'Crafted item not found for this table')
    end

    local now = os.time()
    local readyAt = tonumber(foundEntry.readyAt) or 0
    if readyAt > now then
        return cb(false, 'Item not ready yet (' .. (readyAt - now) .. 's remaining)')
    end

    table.remove(queue, foundIndex)
    if not SaveCraftingTableQueue(tableNum, queue) then
        return cb(false, 'Failed to claim item, try again')
    end

    local itemName = tostring(foundEntry.item or '')
    local itemLabel = tostring(foundEntry.label or itemName)
    local amount = math.max(1, math.floor(tonumber(foundEntry.quantity) or 1))

    if itemName == '' or not AddItem(Player, src, itemName, amount) then
        local restoreTable = GetCraftingTableById(tableNum)
        local restoreQueue = DecodeQueue(restoreTable and restoreTable.craft_queue or nil)
        restoreQueue[#restoreQueue + 1] = foundEntry
        SaveCraftingTableQueue(tableNum, restoreQueue)
        return cb(false, 'Cannot carry this crafted item right now')
    end

    local xpGain = math.max(0, math.floor(tonumber(foundEntry.xpGain) or 0))
    if xpGain > 0 then
        ApplyCraftingXP(Player, src, xpGain)
    end

    cb(true, 'Collected ' .. amount .. 'x ' .. itemLabel .. (xpGain > 0 and (' (+' .. xpGain .. ' XP)') or ''))
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

local function IsTableAdmin(src)
    if src == 0 then
        return true
    end

    return QBCore.Functions.HasPermission(src, 'admin')
        or QBCore.Functions.HasPermission(src, 'god')
        or IsPlayerAceAllowed(src, 'command')
end

local function DeleteCraftingTable(src, tableId)
    local tableNum = tonumber(tableId)
    if not tableNum then
        if src ~= 0 then
            TriggerClientEvent('QBCore:Notify', src, 'Invalid crafting table id', 'error')
        end
        return
    end

    local existsBefore = MySQL.single.await('SELECT id, x, y, z FROM f4_crafting WHERE id = ? LIMIT 1', { tableNum })
    if not existsBefore then
        if src ~= 0 then
            TriggerClientEvent('QBCore:Notify', src, ('Crafting table #%d not found'):format(tableNum), 'error')
        end
        return
    end

    local ok, dbErr = pcall(function()
        MySQL.query.await('DELETE FROM f4_crafting WHERE id = ? LIMIT 1', { tableNum })
    end)

    if not ok then
        if src ~= 0 then
            TriggerClientEvent('QBCore:Notify', src, 'Failed to remove crafting table (DB error)', 'error')
        end
        if F4.Debug then
            print(('[F4 Crafting] DeleteCraftingTable DB error: %s'):format(tostring(dbErr)))
        end
        return
    end

    local existsAfter = MySQL.single.await('SELECT id FROM f4_crafting WHERE id = ? LIMIT 1', { tableNum })
    if existsAfter then
        if src ~= 0 then
            TriggerClientEvent('QBCore:Notify', src, 'Failed to remove crafting table', 'error')
        end
        return
    end

    if src ~= 0 then
        TriggerClientEvent('QBCore:Notify', src, ('Crafting table #%d removed'):format(tableNum), 'success')
    end

    TriggerClientEvent('f4_crafting:removeTableClient', -1, tableNum, existsBefore.x, existsBefore.y, existsBefore.z)
    TriggerClientEvent('f4_crafting:refreshTables', -1)
end

RegisterNetEvent('f4_crafting:deleteTable', function(tableId)
    local src = source

    if not IsTableAdmin(src) then
        TriggerClientEvent('QBCore:Notify', src, 'You are not allowed to remove crafting tables', 'error')
        return
    end

    DeleteCraftingTable(src, tableId)
end)

QBCore.Commands.Add('addcraftingtable', 'Add a crafting table (Admin Only)', {}, true, function(source, args)
    TriggerClientEvent('f4_crafting:createTable', source)
end, 'admin')

QBCore.Commands.Add('removecraftingtable', 'Remove nearest crafting table or remove by id (Admin Only)', {
    { name = 'id', help = 'Optional crafting table id' }
}, false, function(source, args)
    if not IsTableAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('QBCore:Notify', source, 'You are not allowed to remove crafting tables', 'error')
        end
        return
    end

    local argId = args and args[1]
    if argId and argId ~= '' then
        DeleteCraftingTable(source, argId)
        return
    end

    if source == 0 then
        print('[F4 Crafting] Console usage: removecraftingtable <id>')
        return
    end

    TriggerClientEvent('f4_crafting:removeNearestTable', source)
end, 'admin')

if F4.Debug then
    print('^2[F4 Crafting]^7 Server loaded successfully')
end
