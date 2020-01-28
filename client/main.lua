ESX                             = nil
local GUI                       = {}
local PlayerData                = {}
local LastVehicle = 0
local LastOpen = false
GUI.Time                      = 0
local ModelLimit = {}
local CloseToVehicle = false
local GlobalPlate = nil
local Skip = nil
local Items = {}

function getInventoryWeight(inventory)
    local weight = 0
    local itemWeight = 0

    if inventory ~= nil then
        for i=1, #inventory, 1 do
            if inventory[i] ~= nil then
                itemWeight = Config.DefaultWeight
                if Items[inventory[i].item] then
                    itemWeight = Items[inventory[i].item]
                end
                weight = weight + (itemWeight * inventory[i].count)
            end
        end
    end
    return weight
end

function getItemWeight(item)
    local itemWeight = 0

    if item ~= nil then
        itemWeight = Config.DefaultWeight
        if Items[item] ~= nil then
            itemWeight = Items[item]
        end
    end
    return itemWeight
end

local function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end


Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    TriggerServerEvent('esx_truck_inventory:requestItems')
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    TriggerServerEvent('esx_truck_inventory:requestItems')

    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('esx_truck_inventory:receiveItems')
AddEventHandler('esx_truck_inventory:receiveItems', function(items)
    Items = items
end)

function VehicleInFront()
    local pos = GetEntityCoords(PlayerPedId())
    local closecar, distance = ESX.Game.GetClosestVehicle(pos)
    if distance > 4.0 then
        return 0
    else
        return closecar
    end
end

function VehicleMaxSpeed(vehicle,weight,maxweight)
    local percent = (weight/maxweight)*100
    local model = GetEntityModel(vehicle)
    if percent > 80  then
        SetEntityMaxSpeed(vehicle, GetVehicleModelMaxSpeed(model)/1.4)
    elseif percent > 50 then
        SetEntityMaxSpeed(vehicle, GetVehicleModelMaxSpeed(model)/1.2)
    else
        SetEntityMaxSpeed(vehicle, GetVehicleModelMaxSpeed(model))
    end
end

function OpenMenuVehicle()
    local playerPed = PlayerPedId()
    local coords    = GetEntityCoords(playerPed)
    local vehicle   = VehicleInFront()
    
    if not DoesEntityExist(vehicle) then
        ESX.ShowNotification('Geen ~r~voertuig~w~ dichtbij')
        return
    end
    
    GlobalPlate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
    
    if GlobalPlate ~= nil and GlobalPlate ~= "" and GlobalPlate ~= " " then
        ESX.TriggerServerCallback('esx_truck:checkvehicle',function(valid)
            if (not valid) then
                local vehFront = VehicleInFront()
                if vehFront ~= nil and vehFront > 0 and GetPedInVehicleSeat(vehFront, -1) ~= PlayerPedId() then
                    LastVehicle = vehFront
                    local model = GetEntityModel(vehFront)
                    local locked = GetVehicleDoorLockStatus(vehFront)
                    local class = GetVehicleClass(vehFront)
                    if ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'inventory') then
                        SetVehicleDoorShut(vehFront, 5, false)
                    else
                        if locked == 1 or class == 15 or class == 16 or class == 14 then
                            SetVehicleDoorOpen(vehFront, 5, false, false)
                            if GlobalPlate ~= nil and GlobalPlate ~= "" and GlobalPlate ~= " " then
                                CloseToVehicle = true
                                TriggerServerEvent('esx_truck_inventory:AddVehicleList', GlobalPlate)
                                TriggerServerEvent("esx_truck_inventory:getInventory", GlobalPlate)
                            end
                        else
                            ESX.ShowNotification('Deze kofferbak zit op ~r~slot!')
                        end
                    end
                else
                    ESX.ShowNotification('Geen ~r~voertuig~w~ dichtbij')
                end
                LastOpen = true
                GUI.Time  = GetGameTimer()
            else
                TriggerEvent('esx:showNotification', "~r~Iemand anders ~w~kijkt al in deze kofferbak.")
            end
        end, GlobalPlate)
    end
end

local count = 0
-- Key controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, 182) --[[ 182 L ]] and IsInputDisabled(2) and (GetGameTimer() - GUI.Time) > 1000 then -- 182 L
            if LastVehicle == 0 then
                OpenMenuVehicle()
                count = count +1
            else
                ESX.ShowNotification("Er ging iets mis, probeer het opnieuw.")
                ESX.UI.Menu.CloseAll()
                local _plate = GlobalPlate
                TriggerServerEvent("esx_truck_inventory:RemoveVehicleList", _plate, "149 LastVehicle Not 0")
                SetVehicleDoorShut(LastVehicle, 5, false)
                LastVehicle = 0
                GlobalPlate = nil
            end
        elseif LastVehicle ~= 0 and LastVehicle ~= nil and #(GetEntityCoords(LastVehicle) - GetEntityCoords(PlayerPedId())) > 10.0 then
            ESX.UI.Menu.CloseAll()
            if GlobalPlate ~= nil or not DoesEntityExist(LastVehicle) then
                local _plate = GlobalPlate
                TriggerServerEvent("esx_truck_inventory:RemoveVehicleList", _plate, "170 Distance Check")
                SetVehicleDoorShut(LastVehicle, 5, false)
                LastVehicle = 0
                GlobalPlate = nil
            end
            LastVehicle = 0
            GlobalPlate = nil
        end
    end
end)

-- CloseToVehicle
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local pos = GetEntityCoords(PlayerPedId())
        if CloseToVehicle then
            local vehicle, distance = ESX.Game.GetClosestVehicle(pos)
            if DoesEntityExist(vehicle) and distance < 7.0 then
                CloseToVehicle = true
            else
                ESX.UI.Menu.CloseAll()
                CloseToVehicle = false
                LastVehicle = 0
                GlobalPlate = nil
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

RegisterNetEvent('esx_truck_inventory:closeInventory')
AddEventHandler('esx_truck_inventory:closeInventory', function()
    if GlobalPlate ~= nil then
        local _plate = GlobalPlate
        SetVehicleDoorShut(LastVehicle, 5, false)
        TriggerServerEvent('esx_truck_inventory:RemoveVehicleList', _plate, "467 Close Menu 1")
        GlobalPlate = nil
        LastVehicle = 0
    end
end)

RegisterNetEvent('esx_truck_inventory:getInventoryLoaded')
AddEventHandler('esx_truck_inventory:getInventoryLoaded', function(inventory)
    local weight = getInventoryWeight(inventory)
    local elements = {}
    local vehFrontBack = VehicleInFront()
    
    table.insert(elements, {
        label     = 'Deposeren',
        count     = 0,
        value     = 'deposit',
    })
    
    if inventory ~= nil and #inventory > 0 then
        for _,v in ipairs(inventory) do
            if v.itemt == 'item_standard' then
                table.insert(elements, {
                    label     = v.name .. ' x' .. v.count,
                    count     = v.count,
                    value     = v.item,
                    type	  = v.itemt
                })
            elseif v.itemt == 'item_weapon' then
                table.insert(elements, {
                    label     = v.name .. ' | x' .. v.count,
                    count     = v.count,
                    value     = v.item,
                    type	  = v.itemt
                })
            elseif v.itemt == 'item_account' then
                table.insert(elements, {
                    label     = v.name .. ' [ €' .. v.count..' ]',
                    count     = v.count,
                    value     = v.item,
                    type	  = v.itemt
                })
            elseif v.itemt == 'item_component' then
                local split = mysplit(v.item, '.')
                local label = ESX.GetWeaponLabel(split[2]) .. ' - ' .. split[1] .. ' | x' .. v.count
                table.insert(elements, {
                    label   = label,
                    count   = v.count,
                    value   = v.item,
                    type    = v.itemt
                })
            end
        end
    end
    
    ESX.UI.Menu.Open(
    'default',GetCurrentResourceName(), 'inventory_deposit',
    {
        title    = 'Kofferbak inhoud',
        align    = 'top-right',
        elements = elements,
    },
    function(data, menu) -- Submit
        if data.current.value == 'deposit' then
            local elem = {}
            -- xPlayer.getAccount('black_money').money
            -- table.insert(elements, {label = 'Argent sale: ' .. inventory.blackMoney, type = 'item_account', value = 'black_money'})
            
            PlayerData = ESX.GetPlayerData()
            for i=1, #PlayerData.accounts, 1 do
                if PlayerData.accounts[i].name == 'black_money' then
                    -- if PlayerData.accounts[i].money > 0 then
                    table.insert(elem, {
                        label     = PlayerData.accounts[i].label .. ' [ €'.. math.floor(PlayerData.accounts[i].money+0.5) ..' ]',
                        count     = PlayerData.accounts[i].money,
                        value     = PlayerData.accounts[i].name,
                        name      = PlayerData.accounts[i].label,
                        weight     = PlayerData.accounts[i].weight,
                        type		= 'item_account',
                    })
                    -- end
                end
            end
            
            for i=1, #PlayerData.inventory, 1 do
                if PlayerData.inventory[i].count > 0 then
                    table.insert(elem, {
                        label     = PlayerData.inventory[i].label .. ' x' .. PlayerData.inventory[i].count,
                        count     = PlayerData.inventory[i].count,
                        value     = PlayerData.inventory[i].name,
                        name      = PlayerData.inventory[i].label,
                        weight     = PlayerData.inventory[i].weight,
                        type		= 'item_standard',
                    })
                end
            end
            
            local playerPed  = PlayerPedId()
            local weaponList = ESX.GetWeaponList()
            
            for i=1, #weaponList, 1 do
                local weaponHash = GetHashKey(weaponList[i].name)
                
                if HasPedGotWeapon(playerPed,  weaponHash,  false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
                    local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
                    table.insert(elem, {label = weaponList[i].label .. ' [' .. ammo .. ']',name = weaponList[i].label, type = 'item_weapon', value = weaponList[i].name, count = ammo})
                end
            end
            
            
            ESX.UI.Menu.Open(
            'default', GetCurrentResourceName(), 'inventory_player',
            {
                title    = 'Inventaris inhoud',
                align    = 'top-right',
                elements = elem,
            },function(data3, menu3) -- Submit
                ESX.UI.Menu.Open(
                'dialog', GetCurrentResourceName(), 'inventory_item_count_give',
                {
                    title = 'Aantal'
                },
                function(data4, menu4) -- Submit
                    local quantity = tonumber(data4.value)
                    if not quantity then
                        if data3.current.type == 'item_weapon' then
                            quantity = 0
                        else
                            ESX.ShowNotification("Vul AUB een geldig getal in")
                            return
                        end
                    end
                    local Itemweight
                    if data3.current.type == 'item_weapon' then
                        Itemweight = 1000
                    else
                        Itemweight = tonumber(getItemWeight(data3.current.value)) * quantity
                    end
                    local totalWeight = tonumber(weight) + Itemweight
                    local vehFront = VehicleInFront()

                    local maxWeight = ModelLimit[GetEntityModel(vehFront)]
                    if maxWeight == nil then
                        maxWeight = Config.VehicleLimit[GetVehicleClass(vehFront)] or 0
                    end

                    local max = totalWeight > maxWeight

                    --fin test

                    if GetVehicleDoorLockStatus(vehFront) == 1 then
                        if ((quantity >= 0 and quantity <= tonumber(data3.current.count)) or data3.current.type == 'item_weapon') and vehFront > 0  then
                            maxWeight = (tonumber(maxWeight)/1000)
                            totalWeight =  totalWeight/1000
                            if not max then

                                TriggerServerEvent('esx_truck_inventory:addInventoryItem', GetVehicleClass(vehFront), GetDisplayNameFromVehicleModel(GetEntityModel(vehFront)), GlobalPlate, data3.current.value, quantity, data3.current.name, data3.current.type)
                                ESX.ShowNotification('Gewicht : ~g~'.. totalWeight .. ' Kg / '..maxWeight..' Kg')

                                Skip = true
                            else
                                ESX.ShowNotification('De limiet van ~r~ '..maxWeight..' Kg is bereikt')
                            end
                        else
                            ESX.ShowNotification('~r~ Ongeldige hoeveelheid')
                        end
                    else
                        ESX.ShowNotification('~r~ Kofferbak is op slot')
                    end
                    
                    ESX.UI.Menu.CloseAll()
                    
                end,
                function(data4, menu4) -- Cancel
                    SetVehicleDoorShut(vehFrontBack, 5, false)
                    ESX.UI.Menu.CloseAll()
                end,
                function(data4, menu4) -- Change
                    
                end,
                function(data4, menu4) -- Close
                    
                end, true)
            end,
            function(data, menu) -- Cancel
                menu.close()
            end,
            nil, -- Change
            nil, -- Close
            true)
        elseif data.current.type == 'cancel' then
            menu.close()
        else
            if data.current.type ~= 'item_weapon' then
                ESX.UI.Menu.Open(
                'dialog', GetCurrentResourceName(), 'inventory_item_count_give',
                {
                    title = 'Hoeveelheid'
                },
                function(data2, menu2)
                    
                    local quantity = tonumber(data2.value)
                    if not quantity then
                        if data.current.type == 'item_weapon' then
                            quantity = 0
                        else
                            ESX.ShowNotification("Vul AUB een geldig getal in")
                            return
                        end
                    end
                    PlayerData = ESX.GetPlayerData()
                    local vehFront = VehicleInFront()
                    local Itemweight = tonumber(getItemWeight(data.current.value)) * quantity
                    local totalWeight = weight - Itemweight
                    
                    local max = true
                    if data.current.type == 'item_standard' then
                        local currentWeight = 0
                        local maxWeight = PlayerData.maxWeight
                        local itemWeight = nil
                        for k,v in ipairs(PlayerData.inventory) do
                            if v.count > 0 then
                                currentWeight = currentWeight + (v.weight * v.count)
                            end
                            if v.name == data.current.value then
                                itemWeight = v.weight
                            end
                        end
                        
                        print(("[esx_truck_inventory] currentWeight: %s; maxWeight: %s; itemWeight: %s; count: %s;"):format(tostring(currentWeight), tostring(maxWeight), tostring(itemWeight), tostring(quantity)))
                        
                        local newWeight = currentWeight + (itemWeight * quantity)
                        
                        if newWeight <= maxWeight then
                            max = false
                        else
                            max = true
                        end
                    elseif data.current.type == 'item_weapon' or data.current.type == 'item_component' then
                        max = false
                    elseif data.current.type == 'item_account' then
                        max = false
                    else
                        max = true
                    end

                    if GetVehicleDoorLockStatus(vehFront) == 1 then
                        if ((quantity > 0 and quantity <= tonumber(data.current.count)) or data.current.type == 'item_weapon') and DoesEntityExist(vehFront) then
                            if not max then
                                TriggerServerEvent('esx_truck_inventory:removeInventoryItem', GlobalPlate, data.current.value, data.current.type, quantity)
                                local MaxVh = tonumber(ModelLimit[GetEntityModel(vehFront)])
                                if MaxVh == nil then -- We don't want to ignore 0, so hard check for nil
                                    MaxVh = (tonumber(Config.VehicleLimit[GetVehicleClass(vehFront)]) or 0)
                                end

                                MaxVh = MaxVh / 1000

                                local Kgweight =  totalWeight/1000
                                ESX.ShowNotification('Gewicht: ~g~'.. Kgweight .. ' Kg / '..MaxVh..' Kg')
                                Skip = true
                            else
                                ESX.ShowNotification('~r~ Je kunt niet meer dragen')
                            end
                        else
                            ESX.ShowNotification('~r~ Ongeldige hoeveelheid')
                        end
                    else
                        ESX.ShowNotification("~r~ Dit voertuig is op slot")
                    end

                    ESX.UI.Menu.CloseAll()
                end,
                function(data2, menu2) -- Cancel
                    SetVehicleDoorShut(vehFrontBack, 5, false)
                    ESX.UI.Menu.CloseAll()
                end,
                nil, -- Change
                nil, -- Close
                true)
            else
                if not HasPedGotWeapon(PlayerPedId(), GetHashKey(data.current.value), false) then
                    if not Config.PoliceWeapons[GetHashKey(data.current.value)] or PlayerData.job.name == 'police' then
                        local vehFront = VehicleInFront()
                        local totalWeight = weight - tonumber(getItemWeight(data.current.value))
                        TriggerServerEvent('esx_truck_inventory:removeInventoryItem', GlobalPlate, data.current.value, data.current.type, 1)
                        local MaxVh = tonumber(ModelLimit[GetEntityModel(vehFront)])
                        if MaxVh == nil then -- We don't want to ignore 0, so hard check for nil
                            MaxVh = (tonumber(Config.VehicleLimit[GetVehicleClass(vehFront)]) or 0)
                        end

                        MaxVh = MaxVh / 1000

                        local Kgweight =  totalWeight/1000
                        ESX.ShowNotification('Gewicht: ~g~'.. Kgweight .. ' Kg / '..MaxVh..' Kg')
                        Skip = true
                    else
                        ESX.ShowNotification('~r~ Deze wapens zitten in de kluis')
                    end
                else
                    ESX.ShowNotification('Je hebt dit wapen al bij je!')
                end
            end
        end
    end,
    function(data, menu) -- Cancel
        menu.close()
    end,
    function(data, menu) -- Change
        
    end,
    function(data, menu) -- Close
        if LastVehicle > 0 and not Skip then
            if GlobalPlate ~= nil then
                local _plate = GlobalPlate
                SetVehicleDoorShut(LastVehicle, 5, false)
                TriggerServerEvent('esx_truck_inventory:RemoveVehicleList', _plate, "467 Close Menu 1")
                GlobalPlate = nil
                LastVehicle = 0
            end
        elseif Skip then
            Skip = false
        end
    end, true)
end)

for k,v in pairs(Config.ModelLimit) do
    local key
    if type(k) == 'string' then
        key = GetHashKey(k)
    elseif type(k) == 'number' then
        key = k
    end
    
    if key ~= nil then
        ModelLimit[key] = v
    end
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
