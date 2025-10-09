local QBCore = exports['qb-core']:GetCoreObject()

local isUIOpen = false
local playerData = {}
local craftingTables = {}
local spawnedBenches = {}

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
    for i, obj in pairs(spawnedBenches) do
        if DoesEntityExist(obj) then
            DeleteObject(obj)
        end
    end
    spawnedBenches = {}
    
    for i, tableData in ipairs(craftingTables) do
        local coords = vector3(tableData.x, tableData.y, tableData.z)
        local heading = tableData.heading or 0.0
        
        local obj = SpawnBench(coords, heading)
        if obj then
            spawnedBenches[i] = obj
            
            local interactionId = 'crafting_table_' .. tableData.id
            F4.interaction(interactionId, coords)
        end
    end
end

local function LoadAndSpawnTables()
    QBCore.Functions.TriggerCallback('f4_crafting:getTables', function(tables)
        craftingTables = tables
        if #tables > 0 then
            SpawnAllBenches()
        end
    end)
end

function OpenCraftingUI()
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    local inventory = GetPlayerInventory()
    
    local craftingLevel = 0
    local craftingXP = 0
    
    QBCore.Functions.TriggerCallback('f4_crafting:getMeta', function(level, xp)
        craftingLevel = level or 0
        craftingXP = xp or 0
        
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
            xpPerHex = F4.XPPerHexagon
        })
    end)
end

function CloseCraftingUI()
    if not isUIOpen then 
        return 
    end
    
    isUIOpen = false
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
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = 'close' })
    end
    
    cb('ok')
end)

RegisterNUICallback('craft', function(data, cb)
    local itemIndex = data.itemIndex
    local quantity = data.quantity
    
    if not itemIndex or not quantity then
        cb({ success = false, message = 'Invalid data' })
        return
    end
    
    local item = F4.CraftingItems[itemIndex + 1]
    local craftTime = (item and item.time) or 0
    local totalTime = craftTime * quantity
    
    QBCore.Functions.TriggerCallback('f4_crafting:craftItem', function(success, message)
        SendNUIMessage({
            action = 'stopCountdown'
        })
        
        if success then
            Wait(100)
            
            local inventory = GetPlayerInventory()
            SendNUIMessage({
                action = 'updateInventory',
                inventory = inventory
            })
            
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
    end, itemIndex, quantity)
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
        
        QBCore.Functions.Notify('Crafting table saved successfully', 'success')
    else
        DeleteObject(obj)
        QBCore.Functions.Notify('Table creation cancelled', 'error')
    end
end)

RegisterNetEvent('f4_crafting:openUI', function()
    OpenCraftingUI()
end)

RegisterNetEvent('f4_crafting:refreshTables', function()
    QBCore.Functions.TriggerCallback('f4_crafting:getTables', function(tables)
        craftingTables = tables
        SpawnAllBenches()
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
    Wait(1000)
    LoadAndSpawnTables()
end)

exports('OpenCraftingUI', OpenCraftingUI)
exports('CloseCraftingUI', CloseCraftingUI)
