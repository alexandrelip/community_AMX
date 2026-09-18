local M = {}

local DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function is_leap_year(year)
    return year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)
end

function M.is_valid(text)
    if type(text) ~= "string" then return false end

    local day_text, month_text, year_text = text:match("^(%d%d)/(%d%d)/(%d%d)$")
    if not day_text then return false end

    local day = tonumber(day_text)
    local month = tonumber(month_text)
    local year = 2000 + tonumber(year_text)
    if month < 1 or month > 12 or day < 1 then return false end

    local max_day = DAYS_IN_MONTH[month]
    if month == 2 and is_leap_year(year) then max_day = 29 end
    return day <= max_day
end

return M
