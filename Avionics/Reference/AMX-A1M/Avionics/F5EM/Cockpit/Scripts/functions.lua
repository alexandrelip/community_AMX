

function startup_print(msg)
--    print_message_to_user(msg)
end

function debug_message_to_user(msg)
--    print_message_to_user(msg)
end

function round_to(value, roundto)
    value = value + roundto/2
    return value - value % roundto
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function limit_xy(x, y, limit_x, limit_y, limit_x_down, limit_y_down) 
    limit_x_down = limit_x_down or -limit_x
    limit_y_down = limit_y_down or -limit_y

    local limited_x = false
    local limited_y = false

    if (x > limit_x) and (y <= limit_y / limit_x * x) and (y >= limit_y_down / limit_x * x) then 
        y = y * limit_x / x
        x = limit_x
        limited_x = true
    end
    
    if (x < limit_x_down)  and (y <= limit_y / limit_x_down * x) and (y >= limit_y_down / limit_x_down * x) then 
        y = y * limit_x_down / x
        x = limit_x_down 
        limited_x = true
    end

    if (y > limit_y) and (x < limit_x / limit_y * y) and (x > limit_x_down / limit_y * y) then 
        x = x * limit_y / y
        y = limit_y 
        limited_y = true
    end
    
    if (y < limit_y_down) and (x < limit_x / limit_y_down * y) and (x > limit_x_down / limit_y_down * y) then 
        x = x * limit_y_down / y
        y = limit_y_down 
        limited_y = true
    end
    
    local limited = (limited_x or limited_y) and 1 or 0
    return x, y, limited, limited_x, limited_y
end
