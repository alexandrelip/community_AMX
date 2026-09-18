local M = {
    GMT = 0,
    SEA = 1,
    MAP = 2,
    DOMAIN_LAND = 1,
    DOMAIN_SEA = 2,
    PRF_LOW = 0,
    PRF_MED = 1,
    DEFAULT_MOVING_THRESHOLD_MS = 1,
}

function M.normalize_submode(value)
    value = math.floor((tonumber(value) or M.GMT) + 0.5)
    if value < M.GMT or value > M.MAP then return M.GMT end
    return value
end

function M.prf(submode)
    return M.normalize_submode(submode) == M.MAP and M.PRF_MED or M.PRF_LOW
end

function M.matches(submode, domain, speed_ms, moving_threshold_ms)
    submode = M.normalize_submode(submode)
    domain = math.floor((tonumber(domain) or 0) + 0.5)
    speed_ms = math.max(0, tonumber(speed_ms) or 0)
    moving_threshold_ms = math.max(0,
        tonumber(moving_threshold_ms) or M.DEFAULT_MOVING_THRESHOLD_MS)

    if submode == M.GMT then
        return domain == M.DOMAIN_LAND and speed_ms >= moving_threshold_ms
    end
    if submode == M.SEA then
        return domain == M.DOMAIN_SEA
    end
    return domain == M.DOMAIN_LAND or domain == M.DOMAIN_SEA
end

return M
