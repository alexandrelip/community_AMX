-- =====================================================================
-- [Fase 27] Sounds Callouts BR - hook play API
-- =====================================================================
-- Modulo que centraliza play de callouts PT-BR (voz Madame Bertha FAB).
-- Lista de IDs sincronizada com .sdef em Sounds/sdef/.../Callouts/BR/.
--
-- Tentamos play via API Sound.play_sound() do DCS - se nao disponivel
-- no contexto, cai em set_command (canal 9001+) ou no-op silencioso.
-- =====================================================================

local M = {}

-- Mapa de ID -> sdef path (relativo ao mod)
M.CALLOUTS = {
    Bingo          = "Sounds/Aircrafts/Cockpits/Callouts/BR/Bingo",
    FuelCrit       = "Sounds/Aircrafts/Cockpits/Callouts/BR/FuelCrit",
    PullUp         = "Sounds/Aircrafts/Cockpits/Callouts/BR/PullUp",
    OverG          = "Sounds/Aircrafts/Cockpits/Callouts/BR/OverG",
    Stall          = "Sounds/Aircrafts/Cockpits/Callouts/BR/Stall",
    MissileInbound = "Sounds/Aircrafts/Cockpits/Callouts/BR/MissileInbound",
    Fox2           = "Sounds/Aircrafts/Cockpits/Callouts/BR/Fox2",
    Fox3           = "Sounds/Aircrafts/Cockpits/Callouts/BR/Fox3",
    Guns           = "Sounds/Aircrafts/Cockpits/Callouts/BR/Guns",
    Winchester     = "Sounds/Aircrafts/Cockpits/Callouts/BR/Winchester",
    Contact        = "Sounds/Aircrafts/Cockpits/Callouts/BR/Contact",
    Splash         = "Sounds/Aircrafts/Cockpits/Callouts/BR/Splash",
    DecisionAlt    = "Sounds/Aircrafts/Cockpits/Callouts/BR/DecisionAlt",
    Minimum        = "Sounds/Aircrafts/Cockpits/Callouts/BR/Minimum",
}

-- Set commands canal callouts (9001-9012) - mapeados em command_defs.lua se
-- usuario adicionar binding manual. Fallback silencioso preserva engine.
M.CMD_BASE = 9001
M.CALLOUT_ORDER = {
    "Bingo", "FuelCrit", "PullUp", "OverG", "Stall", "MissileInbound",
    "Fox2", "Fox3", "Guns", "Winchester", "Contact", "Splash",
    "DecisionAlt", "Minimum",
}

-- Cache de cooldowns por ID (evita repeticao em <3s)
M._last_play = {}
M.COOLDOWN_S = 3.0

local function get_time()
    if type(LoGetModelTime) == "function" then
        return LoGetModelTime() or 0
    end
    if type(get_absolute_model_time) == "function" then
        return get_absolute_model_time() or 0
    end
    return 0
end

--- Toca callout PT-BR por ID
-- @param id (string) ID do callout (ver M.CALLOUTS)
-- @return boolean true se tocou, false se em cooldown ou indisponivel
function M.play(id)
    local sdef = M.CALLOUTS[id]
    if not sdef then return false end

    local now = get_time()
    local last = M._last_play[id] or 0
    if (now - last) < M.COOLDOWN_S then
        return false
    end
    M._last_play[id] = now

    -- Tenta API Sound.play_sound (disponivel em alguns contextos)
    if type(Sound) == "table" and type(Sound.play_sound) == "function" then
        local ok = pcall(Sound.play_sound, sdef)
        if ok then return true end
    end

    -- Fallback: dispatch set_command no canal callouts
    if type(dispatch_action) == "function" then
        local idx = nil
        for i, cid in ipairs(M.CALLOUT_ORDER) do
            if cid == id then idx = i; break end
        end
        if idx then
            local cmd = M.CMD_BASE + (idx - 1)
            pcall(dispatch_action, nil, cmd, 1)
            return true
        end
    end

    return false
end

--- Lista todos IDs disponiveis
function M.list()
    return M.CALLOUT_ORDER
end

--- Forca tocar ignorando cooldown
function M.play_force(id)
    M._last_play[id] = 0
    return M.play(id)
end

return M
