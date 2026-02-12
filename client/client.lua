local QBCore = exports['qb-core']:GetCoreObject()

local isUIOpen = false
local playerData = {}
local craftingTables = {}
local spawnedBenches = {}
local spawnedInteractionIds = {}
local currentTableId = nil

local function ClearSpawnedInteractions()
    if GetResourceState('interact') ~= 'started' then
        spawnedInteractionIds = {}
        return
    end

    for interactionId in pairs(spawnedInteractionIds) do
        pcall(function()
            exports.interact:RemoveInteraction(interactionId)
        end)
    end

    spawnedInteractionIds = {}
end

local function DeleteBenchObject(obj)
    if not obj or not DoesEntityExist(obj) then
        return false
    end

    if NetworkGetEntityIsNetworked(obj) then
        local timeout = GetGameTimer() + 1000
        while not NetworkHasControlOfEntity(obj) and GetGameTimer() < timeout do
            NetworkRequestControlOfEntity(obj)
            Wait(0)
        end
    end

    SetEntityAsMissionEntity(obj, true, true)
    DeleteObject(obj)

    if DoesEntityExist(obj) then
        DeleteEntity(obj)
    end

    if DoesEntityExist(obj) then
        SetEntityCoordsNoOffset(obj, 0.0, 0.0, -200.0, false, false, false)
    end

    return not DoesEntityExist(obj)
end

local function RemoveNearbyBenchByCoords(x, y, z)
    local nx, ny, nz = tonumber(x), tonumber(y), tonumber(z)
    if not nx or not ny or not nz then
        return
    end

    local modelHash = type(F4.BenchModel) == 'number' and F4.BenchModel or joaat(F4.BenchModel)
    for _ = 1, 6 do
        local nearbyObject = GetClosestObjectOfType(nx, ny, nz, 2.0, modelHash, false, false, false)
        if not nearbyObject or nearbyObject == 0 or not DoesEntityExist(nearbyObject) then
            break
        end

        local removed = DeleteBenchObject(nearbyObject)
        if not removed then
            break
        end
    end
end

local function FindTableCoordsById(tableId)
    local targetId = tonumber(tableId)
    if not targetId then
        return nil
    end

    for _, tableData in ipairs(craftingTables) do
        if tonumber(tableData.id) == targetId then
            return tableData.x, tableData.y, tableData.z
        end
    end

    return nil
end

local function RemoveTableLocally(tableId, x, y, z)
    local tableNum = tonumber(tableId)
    if not tableNum then
        return
    end

    local obj = spawnedBenches[tableNum]
    if obj then
        DeleteBenchObject(obj)
        spawnedBenches[tableNum] = nil
    end

    local interactionId = 'crafting_table_' .. tableNum
    if spawnedInteractionIds[interactionId] then
        if GetResourceState('interact') == 'started' then
            pcall(function()
                exports.interact:RemoveInteraction(interactionId)
            end)
        end
        spawnedInteractionIds[interactionId] = nil
    end

    if currentTableId and currentTableId == tableNum then
        CloseCraftingUI()
        QBCore.Functions.Notify('This crafting table was removed', 'error')
    end

    if not x or not y or not z then
        x, y, z = FindTableCoordsById(tableNum)
    end

    RemoveNearbyBenchByCoords(x, y, z)
end

local function GetPlayerInventory()
    local inventory = {}
    local playerData = QBCore.Functions.GetPlayerData()
    
    if not playerData or not playerData.items then
        return inventory
    end
    
    local items = playerData.items
    
    if items then
        for slot, item in pairs(items) do
            if item and type(item) == "table" and item.name then
                if not inventory[item.name] then
                    inventory[item.name] = 0
                end
                
                local amount = item.count or item.amount or item.quantity or 1
                
                if type(amount) == "number" and amount > 0 then
                    inventory[item.name] = inventory[item.name] + amount
                end
            end
        end
    end
    
    return inventory
end

local function SpawnBench(coords, heading)
    local model = F4.BenchModel
    lib.requestModel(model)
    
    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    
    if heading then
        SetEntityHeading(obj, heading)
    end
    
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    
    return obj
end

local function SpawnAllBenches()
    ClearSpawnedInteractions()

    for tableId, obj in pairs(spawnedBenches) do
        DeleteBenchObject(obj)
        spawnedBenches[tableId] = nil
    end
    
    for _, tableData in ipairs(craftingTables) do
        local coords = vector3(tableData.x, tableData.y, tableData.z)
        local heading = tableData.heading or 0.0
        
        local obj = SpawnBench(coords, heading)
        if obj then
            local tableId = tonumber(tableData.id)
            if tableId then
                spawnedBenches[tableId] = obj
            end
            
            local interactionId = 'crafting_table_' .. tableData.id
            F4.interaction(interactionId, coords, tableData.id)
            spawnedInteractionIds[interactionId] = true
        end
    end
end

local function GetNearestCraftingTable(maxDistance)
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then
        return nil
    end

    local playerCoords = GetEntityCoords(playerPed)
    local closestTable = nil
    local closestDistance = maxDistance or (F4.CraftingRadius + 1.0)

    for _, tableData in ipairs(craftingTables) do
        local tableCoords = vector3(tableData.x, tableData.y, tableData.z)
        local distance = #(playerCoords - tableCoords)
        if distance <= closestDistance then
            closestDistance = distance
            closestTable = tableData
        end
    end

    return closestTable
end

local function RefreshQueueUI()
    if not isUIOpen or not currentTableId then
        return
    end

    QBCore.Functions.TriggerCallback('f4_crafting:getQueue', function(queueItems)
        SendNUIMessage({
            action = 'updateQueue',
            queue = queueItems or {}
        })
    end, currentTableId)
end

local function LoadAndSpawnTables()
    QBCore.Functions.TriggerCallback('f4_crafting:getTables', function(tables)
        craftingTables = tables
        if #tables > 0 then
            SpawnAllBenches()
        end
    end)
end

function OpenCraftingUI(tableId)
    if isUIOpen then return end

    local targetTableId = tonumber(tableId)
    if not targetTableId then
        local nearestTable = GetNearestCraftingTable(F4.CraftingRadius + 1.0)
        if not nearestTable then
            QBCore.Functions.Notify('No crafting table nearby', 'error')
            return
        end
        targetTableId = nearestTable.id
    end

    currentTableId = targetTableId
    isUIOpen = true
    SetNuiFocus(true, true)

    local inventory = GetPlayerInventory()

    local craftingLevel = 0
    local craftingXP = 0

    QBCore.Functions.TriggerCallback('f4_crafting:getMeta', function(level, xp)
        craftingLevel = level or 0
        craftingXP = xp or 0

        QBCore.Functions.TriggerCallback('f4_crafting:getQueue', function(queueItems)
            local itemsWithImages = {}
            for i, item in ipairs(F4.CraftingItems) do
                itemsWithImages[i] = {
                    name = item.name,
                    item = item.item,
                    image = F4.getItemImage(item.item),
                    level = item.level,
                    description = item.description,
                    xpReward = item.xpReward,
                    time = item.time or 0,
                    requirements = item.requirements
                }
            end

            SendNUIMessage({
                action = 'open',
                items = itemsWithImages,
                inventory = inventory,
                playerLevel = craftingLevel,
                playerXP = craftingXP,
                xpRequired = F4.XPPerLevel,
                xpPerHex = F4.XPPerHexagon,
                queue = queueItems or {},
                tableId = currentTableId
            })
        end, currentTableId)
    end)
end

function CloseCraftingUI()
    if not isUIOpen then 
        return 
    end
    
    isUIOpen = false
    currentTableId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(data, cb)
    CloseCraftingUI()
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    if isUIOpen then
        isUIOpen = false
        currentTableId = nil
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = 'close' })
    end
    
    cb('ok')
end)

RegisterNUICallback('craft', function(data, cb)
    local itemIndex = data.itemIndex
    local quantity = data.quantity

    if not itemIndex or not quantity or not currentTableId then
        cb({ success = false, message = 'Invalid data' })
        return
    end

    QBCore.Functions.TriggerCallback('f4_crafting:craftItem', function(success, message)
        if success then
            Wait(100)

            local inventory = GetPlayerInventory()
            SendNUIMessage({
                action = 'updateInventory',
                inventory = inventory
            })

            RefreshQueueUI()

            SendNUIMessage({
                action = 'showNotification',
                type = 'success',
                message = message
            })
        else
            SendNUIMessage({
                action = 'showNotification',
                type = 'error',
                message = message
            })
        end

        cb({ success = success, message = message })
    end, itemIndex, quantity, currentTableId)
end)

RegisterNUICallback('claimQueuedItem', function(data, cb)
    local queueId = data and data.queueId

    if not queueId or not currentTableId then
        cb({ success = false, message = 'Invalid request' })
        return
    end

    QBCore.Functions.TriggerCallback('f4_crafting:claimQueuedItem', function(success, message)
        if success then
            Wait(100)

            local inventory = GetPlayerInventory()
            SendNUIMessage({
                action = 'updateInventory',
                inventory = inventory
            })

            RefreshQueueUI()
        end

        SendNUIMessage({
            action = 'showNotification',
            type = success and 'success' or 'error',
            message = message
        })

        cb({ success = success, message = message })
    end, currentTableId, queueId)
end)

RegisterNetEvent('f4_crafting:createTable', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local spawnCoords = coords + forward * 2.0

    local obj = SpawnBench(spawnCoords, GetEntityHeading(playerPed))
    if not obj then
        QBCore.Functions.Notify('Failed to spawn crafting bench', 'error')
        return
    end

    local data = exports.object_gizmo:useGizmo(obj)

    if data and data.position and data.rotation then
        SetEntityCoords(obj, data.position.x, data.position.y, data.position.z, false, false, false, false)
        SetEntityHeading(obj, data.rotation.z)
        FreezeEntityPosition(obj, true)

        TriggerServerEvent('f4_crafting:saveTablePosition', 
            data.position.x, 
            data.position.y, 
            data.position.z, 
            data.rotation.z
        )

        DeleteBenchObject(obj)
        
        QBCore.Functions.Notify('Crafting table saved successfully', 'success')
    else
        DeleteBenchObject(obj)
        QBCore.Functions.Notify('Table creation cancelled', 'error')
    end
end)

RegisterNetEvent('f4_crafting:removeNearestTable', function()
    local nearestTable = GetNearestCraftingTable((F4.CraftingRadius or 2.5) + 2.0)

    if not nearestTable then
        QBCore.Functions.Notify('No crafting table nearby to remove', 'error')
        return
    end

    TriggerServerEvent('f4_crafting:deleteTable', nearestTable.id)
end)

RegisterNetEvent('f4_crafting:removeTableClient', function(tableId, x, y, z)
    RemoveTableLocally(tableId, x, y, z)
end)

RegisterNetEvent('f4_crafting:openUI', function(tableId)
    OpenCraftingUI(tableId)
end)

RegisterNetEvent('f4_crafting:refreshTables', function()
    QBCore.Functions.TriggerCallback('f4_crafting:getTables', function(tables)
        local oldTables = craftingTables
        craftingTables = tables

        local existing = {}
        for _, tableData in ipairs(craftingTables) do
            existing[tonumber(tableData.id)] = true
        end

        for _, oldTable in ipairs(oldTables or {}) do
            local oldId = tonumber(oldTable.id)
            if oldId and not existing[oldId] then
                RemoveTableLocally(oldId, oldTable.x, oldTable.y, oldTable.z)
            end
        end

        SpawnAllBenches()

        if isUIOpen and currentTableId then
            local exists = false
            for _, tableData in ipairs(craftingTables) do
                if tableData.id == currentTableId then
                    exists = true
                    break
                end
            end

            if not exists then
                CloseCraftingUI()
                QBCore.Functions.Notify('This crafting table is no longer available', 'error')
            end
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if isUIOpen then
        CloseCraftingUI()
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    playerData = val
    
    if isUIOpen then
        Wait(200)
        
        local inventory = GetPlayerInventory()
        SendNUIMessage({
            action = 'updateInventory',
            inventory = inventory
        })
        
        local craftingLevel = 0
        local craftingXP = 0
        
        if val.metadata then
            craftingLevel = val.metadata.crafting_level or 0
            craftingXP = val.metadata.crafting_xp or 0
        end
        
        SendNUIMessage({
            action = 'updateLevel',
            level = craftingLevel,
            xp = craftingXP,
            xpRequired = F4.XPPerLevel,
            xpPerHex = F4.XPPerHexagon
        })
    end
end)

RegisterNetEvent('ox_inventory:updateInventory', function()
    if isUIOpen then
        Wait(100)
        local inventory = GetPlayerInventory()
        SendNUIMessage({
            action = 'updateInventory',
            inventory = inventory
        })
    end
end)

RegisterNetEvent('f4_crafting:updateLevel', function(level, xp)
    if isUIOpen then
        SendNUIMessage({
            action = 'updateLevel',
            level = level,
            xp = xp,
            xpRequired = F4.XPPerLevel,
            xpPerHex = F4.XPPerHexagon
        })
    end
end)

RegisterNetEvent('f4_crafting:startCountdown', function(totalTime)
    if isUIOpen then
        SendNUIMessage({
            action = 'startCountdown',
            time = totalTime
        })
    end
end)

CreateThread(function()
    while true do
        if isUIOpen and currentTableId then
            Wait(5000)
            RefreshQueueUI()
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    Wait(1000)
    LoadAndSpawnTables()
end)

exports('OpenCraftingUI', OpenCraftingUI)
exports('CloseCraftingUI', CloseCraftingUI)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    ClearSpawnedInteractions()
end)
