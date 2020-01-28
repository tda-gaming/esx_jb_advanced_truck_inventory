ESX = nil
local VehicleList = { }

TriggerEvent('esx:getSharedObject', function(obj)
  ESX = obj
end)

AddEventHandler('onMySQLReady', function ()
	MySQL.Async.execute('DELETE FROM `truck_inventory` WHERE `count` = 0', {})
end)

AddEventHandler('esx:playerLoaded', function(_source, xPlayer)
    TriggerClientEvent('esx_truck_inventory:receiveItems', _source, ESX.Items)
end)

RegisterServerEvent('esx_truck_inventory:requestItems')
AddEventHandler('esx_truck_inventory:requestItems', function()
    local _source = source
    MySQL.Async.fetchAll('SELECT name, weight FROM items', {}, function(result)
        if result[1] then
            local items = {}
            for i=1, #result do
                items[result[i].name] = result[i].weight or 500
            end
            TriggerClientEvent('esx_truck_inventory:receiveItems', _source, items)
        end
    end)
end)

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

local function getInventory(source, plate)
    local inventory_ = {}
    MySQL.Async.fetchAll(
		'SELECT name, item, count, itemt FROM `truck_inventory` WHERE `plate` = @plate',
		{
			['@plate'] = plate
		},
		function(inventory)
			TriggerClientEvent('esx_truck_inventory:getInventoryLoaded', source, inventory)
		end)
end

RegisterServerEvent('esx_truck_inventory:getInventory')
AddEventHandler('esx_truck_inventory:getInventory', function(plate)
      local _source = source
      getInventory(_source, plate)
end)

RegisterServerEvent('esx_truck_inventory:removeInventoryItem')
AddEventHandler('esx_truck_inventory:removeInventoryItem', function(plate, item, itemType, count)
  	local _source = source
    local xPlayer  = ESX.GetPlayerFromId(_source)
    local weapon = nil

    if xPlayer == nil then
        return
    end

  	if VehicleList[plate] ~= _source then
		return
    end

    if itemType == 'item_weapon' then
        if xPlayer.hasWeapon(item) then
            TriggerClientEvent('esx:showNotification', _source, "Je hebt dit wapen als bij je!")
            getInventory(_source, plate)
            return
        end
    end

    if itemType == 'item_component' then
        local split = mysplit(item, '.')
        if not xPlayer.hasWeapon(split[2]) or xPlayer.hasWeaponComponent(split[2], split[1]) then
            getInventory(_source, plate)
            return
        end
    end

	if plate ~= " " or plate ~= nil or plate ~= "" then
        MySQL.Async.fetchAll('SELECT `count`, `data` FROM truck_inventory WHERE `plate` = @plate AND `item`= @item AND `itemt`= @itemt',
        {
            ['@plate'] = plate,
            ['@item'] = item,
            ['@itemt'] = itemType
        }, function(result)
            if result[1] == nil then
                xPlayer.showNotification("Er ging iets mis probeer het opnieuw :|")
                return
            end
            local countincar = result[1].count
            if countincar >= count then
                if xPlayer ~= nil then
                    local removed = false
                    local data = nil

                    if itemType == 'item_standard' then
                        if xPlayer.canCarryItem(item, count) then
                            xPlayer.addInventoryItem(item, count)
                            removed = true
                        else
                            xPlayer.showNotification('~r~ Je kunt niet meer dragen')
                        end
                    end

                    if itemType == 'item_account' then
                        xPlayer.addAccountMoney(item, count, 'esx_truck_inventory:removeInventoryItem')
                        removed = true
                    end

                    if itemType == 'item_weapon' then
                        data = json.decode(result[1].data) or {}
                        local weaponData = table.remove(data, 1) or {}
                        if weaponData.components == nil then
                            weaponData.components = {}
                        end
                        xPlayer.addWeapon(item, weaponData.ammo, weaponData.serial, weaponData.id)
                        local _, weapon = xPlayer.getWeapon(item)
                        for k,v in pairs(weaponData.components) do
                            xPlayer.addWeaponComponent(weapon.name, v)
                        end
                        --weapon.components = weaponData.components
                        count = 1
                        removed = true
                    end

                    if itemType == 'item_component' then
                        local component = mysplit(item, '.')
                        xPlayer.addWeaponComponent(component[2], component[1])
                        removed = true
                    end

                    if removed then
                        if countincar > count then
                            MySQL.Async.execute('UPDATE `truck_inventory` SET `count`= `count` - @qty, `data` = @data WHERE `plate` = @plate AND `item`= @item AND `itemt`= @itemt',
                            {
                            ['@plate'] = plate,
                            ['@qty'] = count,
                            ['@item'] = item,
                            ['@itemt'] = itemType,
                            ['@data'] = json.encode(data)
                            }, function()
                                getInventory(_source, plate)
                            end)
                        else
                            MySQL.Async.execute('DELETE FROM `truck_inventory` WHERE plate = @plate AND item = @item AND itemt = @itemt', {
                                ['@plate'] = plate,
                                ['@item'] = item,
                                ['@itemt'] = itemType
                            }, function()
                                getInventory(_source, plate)
                            end)
                        end
                    end
                end
            else
                getInventory(_source, plate)
            end

        end)
	end
end)


RegisterServerEvent('esx_truck_inventory:addInventoryItem')
AddEventHandler('esx_truck_inventory:addInventoryItem', function(type, model, plate, item, qtty, name, itemType, key)
  	local _source = source
  	local xPlayer  = ESX.GetPlayerFromId(_source)
	if VehicleList[plate] ~= _source then
		print(tostring(xPlayer.name) .. " tried to add items to trunk opened by somebody else (" .. tostring(VehicleList[plate]) .. ' : ' .. tostring(_source) .. ')')
		return
    end

    if plate ~= " " or plate ~= nil or plate ~= "" then
        local removed = false
        if itemType ~= 'item_weapon' then
            if itemType == 'item_standard' then
                local playerItemCount = xPlayer.getInventoryItem(item).count
                if playerItemCount >= qtty then
                   xPlayer.removeInventoryItem(item, qtty)
                   removed = true
                else
                  TriggerClientEvent('esx:showNotification', _source, 'Ongeldige hoeveelheid')
                  getInventory(_source, plate)
                  return
                end
            end

            if itemType == 'item_account' then
                local account = xPlayer.getAccount(item)
                if account == nil or account.money < qtty then
                    TriggerClientEvent('esx:showNotification', _source, 'Ongeldige hoeveelheid')
                    getInventory(_source, plate)
                    return
                end
                xPlayer.removeAccountMoney(item, qtty, 'esx_truck_inventory:addInventoryItem')
                removed = true
            end

            if removed then
                local result = MySQL.Sync.fetchScalar('SELECT count FROM truck_inventory WHERE item = @item AND plate = @plate AND itemt = @itemt LIMIT 1',
                {
                    ['@plate'] = plate,
                    ['@item'] = item,
                    ['@itemt'] = itemType
                })
                if result == nil then
                    MySQL.Async.execute('INSERT INTO truck_inventory (item,count,plate,name,itemt) VALUES (@item,@qty,@plate,@name,@itemt)',
                    {
                        ['@plate'] = plate,
                        ['@qty'] = qtty,
                        ['@item'] = item,
                        ['@name'] = name,
                        ['@itemt'] = itemType,
                    }, function()
                        getInventory(_source, plate)
                    end)
                else
                    MySQL.Async.execute('UPDATE truck_inventory SET `count` = `count` + @qty WHERE plate = @plate AND item = @item AND itemt = @itemt LIMIT 1',
                    {
                        ['@qty'] = qtty,
                        ['@plate'] = plate,
                        ['@item'] = item,
                        ['@itemt'] = itemType,
                    }, function()
                        getInventory(_source, plate)
                    end)
                end
            end
        else
            local _, playerWeapon = xPlayer.getWeapon(item)
            if playerWeapon ~= nil then
                qtty = math.min(playerWeapon.ammo, qtty)
                -- for i=1, #playerWeapon.components do
                --     if playerWeapon.components[i] ~= 'clip_default' then
                --         local componentName = playerWeapon.components[i] .. '.' .. item
                --         MySQL.Async.fetchScalar('SELECT count FROM truck_inventory WHERE item = @component AND plate = @plate AND itemt = "item_component" LIMIT 1',
                --         {
                --             ['@plate'] = plate,
                --             ['@component'] = componentName
                --         }, function(result)
                --             if result == nil then
                --                 MySQL.Async.execute('INSERT INTO truck_inventory (item,count,plate,name,itemt) VALUES (@item,@qty,@plate,@name,"item_component")',
                --                 {
                --                     ['@plate'] = plate,
                --                     ['@qty'] = 1,
                --                     ['@item'] = componentName,
                --                     ['@name'] = playerWeapon.components[i]
                --                 })
                --             else
                --                 MySQL.Async.execute('UPDATE truck_inventory SET `count` = `count` + 1 WHERE plate = @plate AND item = @item AND itemt = "item_component" LIMIT 1',
                --                 {
                --                     ['@qty'] = qtty,
                --                     ['@plate'] = plate,
                --                     ['@item'] = componentName
                --                 })
                --             end
                --         end)
                --     end
                -- end


                MySQL.Async.fetchAll('SELECT count, data FROM truck_inventory WHERE item = @item AND plate = @plate AND itemt = @itemt LIMIT 1',
                {
                    ['@plate'] = plate,
                    ['@item'] = item,
                    ['@itemt'] = itemType
                }, function(result)
                    if result[1] == nil then
                        local storeWeapons = {}
                        table.insert(storeWeapons, {
                            name = item,
                            components = playerWeapon.components,
                            ammo = qtty,
                            id = playerWeapon.id,
                            serial = playerWeapon.serial
                        })
                        MySQL.Async.execute('INSERT INTO truck_inventory (item,count,plate,name,itemt,data) VALUES (@item,1,@plate,@name,@itemt,@data)',
                        {
                            ['@plate'] = plate,
                            ['@item'] = item,
                            ['@name'] = name,
                            ['@itemt'] = itemType,
                            ['@data'] = json.encode(storeWeapons)
                        }, function()
                            xPlayer.removeWeapon(item, qtty)
                            getInventory(_source, plate)
                        end)
                    elseif result[1].data ~= nil then
                        local storeWeapons = json.decode(result[1].data)
                        table.insert(storeWeapons, {
                            name = item,
                            components = playerWeapon.components,
                            ammo = qtty,
                            id = playerWeapon.id,
                            serial = playerWeapon.serial
                        })
                        MySQL.Async.execute('UPDATE truck_inventory SET `count` = `count` + 1, `data` = @data WHERE plate = @plate AND item = @item AND itemt = @itemt LIMIT 1',
                        {
                            ['@plate'] = plate,
                            ['@item'] = item,
                            ['@itemt'] = itemType,
                            ['@data'] = json.encode(storeWeapons)
                        }, function()
                            xPlayer.removeWeapon(item, qtty)
                            getInventory(_source, plate)
                        end)
                    end
                end)
            else
                getInventory(_source, plate)
                TriggerClientEvent('esx:showNotification', _source, 'Ongeldige hoeveelheid')
                return
            end
        end
    else
        getInventory(_source, plate)
	end
end)

ESX.RegisterServerCallback('esx_truck:checkvehicle',function(source, cb, plate)
	local isFound = false
	local _source = source
	if plate ~= " " or plate ~= nil or plate ~= "" then
		if VehicleList[plate] == _source then
			isFound = true
		end
	end
	cb(isFound)
end)


RegisterServerEvent('esx_truck_inventory:AddVehicleList')
AddEventHandler('esx_truck_inventory:AddVehicleList', function(plate)
	local _source = source
    if plate ~= " " or plate ~= nil or plate ~= "" then
        for k,v in pairs(VehicleList) do
            if v == _source then
                VehicleList[k] = nil
            end
        end
		VehicleList[plate] = _source
	end
end)

RegisterServerEvent('esx_truck_inventory:RemoveVehicleList')
AddEventHandler('esx_truck_inventory:RemoveVehicleList', function(plate, reason)
	local _source = source
	if plate == nil then
		return
	end
	if VehicleList[plate] == _source then
		VehicleList[plate] = nil
	end
end)


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
