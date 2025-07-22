_addon.command = 'SellNPC'
_addon.version = '2.1.202507.22'
_addon.author = 'Kaiconure,Ivaar'
_addon.name = 'SellNPC'

require('sets')
profiles = require('profiles')
res_items = require('resources').items

files = require('files')
json = require('jsonlua')

sales_que = {}

default_settings    = { auto = false, auto_list = {} }
settings            = nil
settings_file       = nil

function read_json_from_file(path, defaults)
    local file = files.new(path)
    if not file:exists() then
        return defaults, false
    end

    return json.parse(file:read()) or defaults
end

function write_json_to_file(path, obj)
    local file = files.new(path)
    file:write(json.stringify(obj))
end

function colorize(color, message, returnColor)
    color = color or 72
    returnColor = returnColor or color

    return string.char(0x1E, tonumber(color)) 
        .. (message or '')
        .. string.char(0x1E, returnColor)
end

function get_item_res(item)
    for k,v in pairs(res_items) do
        if (v.en:lower() == item or v.enl:lower() == item) and not v.flags['No NPC Sale'] then
            return v
        end
    end
    return nil
end

function is_valid_item(name)
    local name = windower.convert_auto_trans(name):lower()
    local item = get_item_res(name)

    return item
end


function check_item(name, silent)
    local name = windower.convert_auto_trans(name):lower()
    local item = get_item_res(name)
    if not item then
        windower.add_to_chat(207, '%s: "%s" not a valid item name.':format(_addon.name, name))
    else
        sales_que[item.id] = true
        if silent then return end
        windower.add_to_chat(207, '%s: "%s" added to sales queue.':format(_addon.name, item.en))
    end
end

function merge_into_sales_que(item_list)
    for _id, val in pairs(item_list) do
        local id = tonumber(_id)
        sales_que[id] = true
    end
end

function get_sorted_item_names(item_list, filter)
    local names = {}

    if type(filter) == 'string' and filter ~= '' then
        filter = string.format('^%s', filter):lower()
    else
        filter = nil
    end

    -- Create a list of item names
    for _id, _ in pairs(item_list or {}) do
        local id = tonumber(_id)
        if id then
            local item = res_items[id or -1]
            if item then
                local name = item.name
                if filter == nil or string.match(name:lower(), filter) then
                    if type(name) == 'string' then
                        names[#names + 1] = name
                    end
                end
            end
        end
    end

    -- Sort the item name list case-insensitively
    table.sort(names, function (a, b)
        return string.lower(a) < string.lower(b)
    end)

    return names
end

function sell_all_items()
    -- If we're using the auto list, merge those items into the sales queue now
    if settings and settings.auto == true and type(settings.auto_list) == 'table' then
        merge_into_sales_que(settings.auto_list)
    end

    local num = 0
    for index = 1, 80 do 
        local item = windower.ffxi.get_items(0,index)

        if item and sales_que[item.id] and item.status == 0 then
            windower.packets.inject_outgoing(0x084,string.char(0x084,0x06,0,0,item.count,0,0,0,item.id%256,math.floor(item.id/256)%256,index,0))
            windower.packets.inject_outgoing(0x085,string.char(0x085,0x04,0,0,1,0,0,0))
            num = num + item.count
        end
    end
    sales_que = {}
    if num > 0 then
        windower.add_to_chat(207, '%s: Selling %d items.':format(_addon.name, num))
    end
end

function initialize_shop(id, data)
    if id == 0x03C then
        sell_all_items()
    end
end

function sell_npc_auto_command(command, ...)
    if settings and settings_file then
        command = string.lower(tostring(command) or '')

        if not settings.auto_list then
            settings.auto_list = {}
        end
        
        local commands = {...}
        local save_changes = false
        if command == 'on' then
            settings.auto = true
            save_changes = true

            windower.add_to_chat(207, '%s: The auto-sell list is: %s':format(_addon.name, colorize(2, 'enabled')))
        elseif command == 'off' then
            settings.auto = false
            save_changes = true

            windower.add_to_chat(207, '%s: The auto-sell list is: %s':format(_addon.name, colorize(76, 'enabled')))
        elseif command == 'list' then
            --
            -- Writes out the auto sell list to the chat log
            --
            local num_total = 0
            local num_added = 0
            local filter = table.concat(commands, ' ')

            local names = get_sorted_item_names(settings.auto_list, filter)
            local count = #names

            local message = '%s: %s':format(_addon.name, colorize(89, 'Showing %s from the auto-sell list: \n  ':format(colorize(
                    2,
                    '%d matching item%s':format(count, count ~= 1 and 's' or ''),
                    89
                )), 
            89))

            for i, name in ipairs(names) do
                if num_added > 0 and (num_added % 5) == 0 then
                    windower.add_to_chat(207, message .. '\n')
                    message = '  '
                    num_added = 0
                end

                message = message .. '%s%s':format(
                    colorize(2, name, 89),
                    i < count and ', ' or ' '
                )
                num_added = num_added + 1
                num_total = num_total + 1
            end

            if num_added > 0 or num_total == 0 then
                windower.add_to_chat(207, message)
            end
        elseif command == 'add' then
            --
            -- Adds an item to the auto sell list
            --
            local name = table.concat(commands, ' ')
            local item = is_valid_item(name)
            if item then
                windower.add_to_chat(207, '%s: Adding "%s" to the auto-sell list.':format(_addon.name, item.name))
                settings.auto_list[item.id] = {id = item.id, name = item.name}

                save_changes = true
            else
                windower.add_to_chat(207, '%s: "%s" is not a valid item name.':format(_addon.name, name))
            end
        elseif command == 'remove' then
            --
            -- Removes an item from the auto sell list
            --
            local name = table.concat(commands, ' ')
            local item = is_valid_item(name)
            if item then
                windower.add_to_chat(207, '%s: Removing "%s" (%d) from the auto-sell list.':format(_addon.name, item.name, item.id))
                settings.auto_list[item.id] = nil
                
                save_changes = true
            else
                windower.add_to_chat(207, '%s: "%s" is not a valid item name.':format(_addon.name, name))
            end
        else
            windower.add_to_chat(207, '%s: The auto-sell list is: %s':format(
                _addon.name,
                settings.auto and colorize(2, 'enabled') or colorize(76, 'disabled')
            ))
        end

        if save_changes then
            write_json_to_file(settings_file, settings)
        end
    end
end

function sell_npc_login(name)
    if type(name) == 'string' then
        settings_file   = './data/%s.json':format(name)
        settings        = read_json_from_file(settings_file, default_settings)        
    end
end

function sell_npc_logout(name)
    settings        = nil
    settings_file   = nil
end

function sell_npc_load()
    -- On load, if the player is already logged in we will forward the event to the login handler
    local player = windower.ffxi.get_player()
    if player then
        sell_npc_login(player.name)
    end
end

function sell_npc_command(...)
    local commands = {...}
    if not commands[1] then
    elseif string.lower(commands[1]) == 'auto' then
        -- Clear the 'auto' entry and forward the remainder of the arguments to the auto handler
        table.remove(commands, 1)
        sell_npc_auto_command(table.unpack(commands))
    elseif profiles[commands[1]] then
        for name in pairs(profiles[commands[1]]) do
            check_item(name, true)
        end
        windower.add_to_chat(207, '%s: Loaded profile "%s"':format(_addon.name, commands[1]))
    else
        check_item(table.concat(commands,' '))
    end
end

windower.register_event('incoming chunk', initialize_shop)
windower.register_event('addon command', sell_npc_command)
windower.register_event('login', sell_npc_login)
windower.register_event('logout', sell_npc_logout)
windower.register_event('load', sell_npc_load)
