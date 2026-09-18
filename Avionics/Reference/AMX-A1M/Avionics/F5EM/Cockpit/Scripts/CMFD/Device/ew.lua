dev:listen_command(ic_commands.Power)

local Terrain = Terrain
if type(Terrain) ~= "table" then
    local ok, terrain_api = pcall(require, "terrain")
    if ok and type(terrain_api) == "table" then Terrain = terrain_api end
end

local EW_DL_MAX_TRACKS = 8
local EW_DL_LANE_COUNT = EW_DL_MAX_TRACKS
local EW_DL_SEPARATION_DEG = 8
local EW_DL_MODE = get_param_handle("DL_MODE")
local EW_DL_RX_ALIVE = get_param_handle("LINK_BR2_RX_ALIVE")
local EW_DL_RX = {}
local EW_DL_OUT = {}
for i = 1, EW_DL_MAX_TRACKS do
    local slot = string.format("%02d", i)
    EW_DL_RX[i] = {
        VALID = get_param_handle("LINK_BR2_RX_TRACK_"..slot.."_VALID"),
        LAT = get_param_handle("LINK_BR2_RX_TRACK_"..slot.."_LAT"),
        LON = get_param_handle("LINK_BR2_RX_TRACK_"..slot.."_LON"),
        AGE = get_param_handle("LINK_BR2_RX_TRACK_"..slot.."_AGE"),
        ID = get_param_handle("LINK_BR2_RX_TRACK_"..slot.."_ID"),
        SOURCE_KIND = get_param_handle("LINK_BR2_RX_TRACK_"..slot.."_SOURCE_KIND"),
    }
    EW_DL_OUT[i] = {
        VALID = get_param_handle("EW_DL_TRACK_"..slot.."_VALID"),
        BRG = get_param_handle("EW_DL_TRACK_"..slot.."_BRG"),
        ID = get_param_handle("EW_DL_TRACK_"..slot.."_ID"),
        LANE = get_param_handle("EW_DL_TRACK_"..slot.."_LANE"),
        SOURCE_KIND = get_param_handle("EW_DL_TRACK_"..slot.."_SOURCE_KIND"),
    }
end
local ew_sensor_data = nil

local function finite_number(value)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return nil
    end
    return value
end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
    if y > 0 then return math.pi * 0.5 end
    if y < 0 then return -math.pi * 0.5 end
    return 0
end

local function bearing_delta(left, right)
    local delta = math.abs((left - right) % 360)
    return delta > 180 and (360 - delta) or delta
end

local function assign_link_br2_lanes(tracks)
    table.sort(tracks, function(left, right)
        if left.id ~= right.id then return left.id < right.id end
        return left.index < right.index
    end)
    local assigned = {}
    for _, track in ipairs(tracks) do
        local used = {}
        for _, previous in ipairs(assigned) do
            if bearing_delta(track.bearing, previous.bearing)
                <= EW_DL_SEPARATION_DEG then
                used[previous.lane] = true
            end
        end
        local lane = nil
        for candidate = 0, EW_DL_LANE_COUNT - 1 do
            if not used[candidate] then lane = candidate; break end
        end
        if lane == nil then lane = track.index % EW_DL_LANE_COUNT end
        track.lane = lane
        assigned[#assigned + 1] = track
    end
end

local function clear_link_br2_overlay()
    for i = 1, EW_DL_MAX_TRACKS do
        EW_DL_OUT[i].VALID:set(0)
        EW_DL_OUT[i].BRG:set(0)
        EW_DL_OUT[i].ID:set(0)
        EW_DL_OUT[i].LANE:set(0)
        EW_DL_OUT[i].SOURCE_KIND:set(0)
    end
end

local function update_link_br2_overlay()
    clear_link_br2_overlay()
    if (finite_number(EW_DL_MODE:get()) or 0) < 1.5
        or (finite_number(EW_DL_RX_ALIVE:get()) or 0) < 0.5
        or type(Terrain) ~= "table"
        or type(Terrain.convertLatLonToMeters) ~= "function" then
        return
    end
    if not ew_sensor_data and type(get_base_data) == "function" then
        local ok, value = pcall(get_base_data)
        if ok then ew_sensor_data = value end
    end
    if not ew_sensor_data or type(ew_sensor_data.getSelfCoordinates) ~= "function" then
        return
    end
    local ok, own_north, _, own_east = pcall(ew_sensor_data.getSelfCoordinates)
    own_north = finite_number(own_north)
    own_east = finite_number(own_east)
    if not ok or not own_north or not own_east then return end

    local tracks = {}
    for i = 1, EW_DL_MAX_TRACKS do
        local source = EW_DL_RX[i]
        local source_kind = math.floor(finite_number(source.SOURCE_KIND:get()) or 0)
        local age = finite_number(source.AGE:get()) or math.huge
        if (finite_number(source.VALID:get()) or 0) > 0.5
            and source_kind >= 1 and source_kind <= 2 and age <= 12 then
            local lat = finite_number(source.LAT:get())
            local lon = finite_number(source.LON:get())
            if lat and lon then
                local converted, target_north, target_east = pcall(
                    Terrain.convertLatLonToMeters, lat, lon)
                target_north = finite_number(target_north)
                target_east = finite_number(target_east)
                if converted and target_north and target_east then
                    local bearing = math.deg(atan2(
                        target_east - own_east, target_north - own_north)) % 360
                    local id = math.floor(math.abs(
                        finite_number(source.ID:get()) or i))
                    tracks[#tracks + 1] = {
                        index = i,
                        bearing = bearing,
                        id = id,
                        display_id = id % 100,
                        source_kind = source_kind,
                    }
                end
            end
        end
    end
    assign_link_br2_lanes(tracks)
    for _, track in ipairs(tracks) do
        local output = EW_DL_OUT[track.index]
        output.VALID:set(1)
        output.BRG:set(track.bearing)
        output.ID:set(track.display_id)
        output.LANE:set(track.lane)
        output.SOURCE_KIND:set(track.source_kind)
    end
end

local EW = {
    ON = get_param_handle("RWR_ON"),
    CH_F_MODE = get_param_handle("RWR_CH_F_MODE"),
    SEARCH = get_param_handle("RWR_SEARCH"),
    MODE_PRI = get_param_handle("RWR_MODE_PRI"),
    PROG = get_param_handle("RWR_PROG"),
    STR = get_param_handle("RWR_STR"),
    WARN_CH = get_param_handle("RWR_WARN_CH"),
    WARN_F = get_param_handle("RWR_WARN_F"),
    MAN_PROG = get_param_handle("RWR_MAN_PROG"),
    PFM = get_param_handle("RWR_PFM"),
    SIM = get_param_handle("RWR_SIM"),
    -- [Fase 2B] Parametros do programa EW selecionado (publicados pro CMFD).
    PROG_NAME  = get_param_handle("EW_PROG_NAME"),
    PROG_CHAFF = get_param_handle("EW_PROG_CHAFF"),
    PROG_FLARE = get_param_handle("EW_PROG_FLARE"),
    PROG_SALVO = get_param_handle("EW_PROG_SALVO"),
    PROG_INTV  = get_param_handle("EW_PROG_INTV"),
    -- [Fase 17] Estado do auto-fire programado
    PROG_FIRING       = get_param_handle("EW_PROG_FIRING"),       -- 0/1
    PROG_SALVO_LEFT   = get_param_handle("EW_PROG_SALVO_LEFT"),   -- 0..N
}

-- [Fase 2B] Biblioteca de programas EW (10 perfis), inspirada nos cards
-- operacionais tipicos de F-5BR/F-16. Cada programa define a sequencia que
-- o piloto pretende disparar quando seleciona PROG=N e usa MAN PROG.
-- chaff/flare: numero por salvo. salvo: numero de salvos. intv: segundos
-- entre salvos. NAO altera AN_ALE40V.lua (defaults stock preservados);
-- esta tabela e usada para INFORMACAO/PROGRAMACAO na interface EW.
local EW_PROGRAMS = {
    [1]  = { name = "TRNG",  chaff = 1, flare = 1, salvo = 1, intv = 1.0 },
    [2]  = { name = "FERRY", chaff = 2, flare = 0, salvo = 1, intv = 2.0 },
    [3]  = { name = "PATR",  chaff = 2, flare = 2, salvo = 2, intv = 1.0 },
    [4]  = { name = "BVR",   chaff = 4, flare = 1, salvo = 3, intv = 0.4 },
    [5]  = { name = "WVR",   chaff = 2, flare = 4, salvo = 4, intv = 0.3 },
    [6]  = { name = "SAM-L", chaff = 4, flare = 0, salvo = 4, intv = 0.5 },
    [7]  = { name = "SAM-H", chaff = 6, flare = 2, salvo = 6, intv = 0.3 },
    [8]  = { name = "IR",    chaff = 0, flare = 4, salvo = 6, intv = 0.2 },
    [9]  = { name = "AAA",   chaff = 2, flare = 2, salvo = 3, intv = 0.5 },
    [10] = { name = "PANIC", chaff = 8, flare = 8, salvo = 8, intv = 0.2 },
}


local rwr ={
    dev = nil,
    on = 0,
    ch_f_mode = 0,
    mode_pri = 0,
    search = 0,
    prog = 1,
    warn_ch = 6,
    warn_f = 6,
    str = 1,
    pfm = 1,
    man_prog = 1,
    sim = 0,
    -- [Fase 17] Auto-fire state
    firing = false,
    salvo_left = 0,
    intv_timer = 0,
    last_oss11_time = -1,  -- para deteccao de double-tap
}

-- [Fase 17] Inicia auto-fire do programa EW atualmente selecionado.
-- Dispara salvo apos salvo respeitando o intervalo configurado, usando
-- dispatch_action no CMDS (cmds_commands.FlChButton). Pode ser cancelado
-- chamando stop_ew_program().
function start_ew_program()
    local p = EW_PROGRAMS[rwr.prog]
    if not p then return end
    if p.salvo <= 0 then return end
    rwr.firing = true
    rwr.salvo_left = p.salvo
    rwr.intv_timer = 0  -- primeiro salvo imediato
    debug_message_to_user("EW: Iniciando programa " .. p.name
        .. " (" .. p.salvo .. " salvos, " .. p.intv .. "s)")
end

function stop_ew_program()
    rwr.firing = false
    rwr.salvo_left = 0
    rwr.intv_timer = 0
end

-- Host CMFD opera a 20 Hz. O acumulador preserva a corretude caso a
-- cadencia do host seja alterada novamente: a logica so processa quando
-- acumular pelo menos 0.05 s. `eff_dt = tempo real acumulado` preserva o
-- intv_timer -- disparo de chaff/flare mantem intervalo real do programa
-- selecionado (AN/ALE-40V typical 0.05-0.2s), so a resolucao vira 50ms.
-- Beneficio: reduz CPU em ~60% dessa funcao sem alterar comportamento.
local _ew_tick_accum = 0

-- Chamado a cada tick para gerenciar timer e disparos
local function ew_program_tick(dt)
    _ew_tick_accum = _ew_tick_accum + dt
    if _ew_tick_accum < 0.05 then return end  -- 20Hz cadence
    dt = _ew_tick_accum  -- eff_dt = tempo real acumulado, preserva timing
    _ew_tick_accum = 0

    if not rwr.firing then return end
    if rwr.salvo_left <= 0 then
        rwr.firing = false
        return
    end
    rwr.intv_timer = rwr.intv_timer - dt
    if rwr.intv_timer <= 0 then
        local p = EW_PROGRAMS[rwr.prog]
        if not p then stop_ew_program(); return end
        -- Dispara um salvo: cmds_commands.FlChButton libera 1 chaff + 1 flare
        -- segundo a configuracao do AN/ALE-40V (declarado em F-5EM.lua).
        -- Loops baseados em p.chaff/p.flare nao sao possiveis em single
        -- dispatch -- AN/ALE-40V trata burst internamente.
        if cmds_commands and cmds_commands.FlChButton then
            dispatch_action(nil, cmds_commands.FlChButton)
        end
        rwr.salvo_left = rwr.salvo_left - 1
        rwr.intv_timer = p.intv
        if rwr.salvo_left <= 0 then
            rwr.firing = false
        end
    end
end

    
function update_ew()
    debug_message_to_user("update_ew")
    
    -- Power and CH/F Mode
    rwr.on = rwr.dev and rwr.dev:get_power() and 1 or 0
    if rwr.on == 1 and get_cockpit_draw_argument_value(1790) == 1 then rwr.on = 2 end

    EW.ON:set(rwr.on)
    EW.CH_F_MODE:set(rwr.ch_f_mode)
    EW.PROG:set(rwr.prog)
    EW.SEARCH:set(rwr.search)
    EW.MODE_PRI:set(rwr.mode_pri)
    EW.WARN_CH:set(rwr.warn_ch+0.1)
    EW.WARN_F:set(rwr.warn_f+0.1)
    EW.STR:set(rwr.str)
    EW.PFM:set(rwr.pfm)
    EW.MAN_PROG:set(rwr.man_prog)
    EW.SIM:set(rwr.sim)

    -- [Fase 2B] Publica parametros do programa EW selecionado.
    -- O indice rwr.prog ja gira em 1..10 via OSS24 (modulo 11 + skip 0).
    local p = EW_PROGRAMS[rwr.prog] or EW_PROGRAMS[1]
    EW.PROG_NAME:set(p.name)
    EW.PROG_CHAFF:set(p.chaff)
    EW.PROG_FLARE:set(p.flare)
    EW.PROG_SALVO:set(p.salvo)
    EW.PROG_INTV:set(p.intv)

    -- [Fase 17] Tick do auto-fire programado
    ew_program_tick(update_time_step)
    EW.PROG_FIRING:set(rwr.firing and 1 or 0)
    EW.PROG_SALVO_LEFT:set(rwr.salvo_left)
    update_link_br2_overlay()
end

function SetCommandEw(command,value, CMFD)
    debug_message_to_user("CMFD EW: " ..  command .. "=" .. value)
    if value == 1 and CMFD["SelTop"]:get() == SUB_PAGE_ID.EW then 
        if command == device_commands.CMFD1OSS5 or command == device_commands.CMFD2OSS5 then
            rwr.str = (rwr.str + 1) % 6
            if rwr.str == 0 then rwr.str = 1 end
        elseif command == device_commands.CMFD1OSS6 or command == device_commands.CMFD2OSS6 then
            rwr.pfm = (rwr.pfm + 1) % 6
            if rwr.pfm == 0 then rwr.pfm = 1 end
        elseif command == device_commands.CMFD1OSS7 or command == device_commands.CMFD2OSS7 then
            -- EVENT MARK
        elseif command == device_commands.CMFD1OSS9 or command == device_commands.CMFD2OSS9 then
            if WPN_MASS:get() == WPN_MASS_IDS.SIM then 
                rwr.sim = (rwr.sim + 1) % 2
            end
        elseif command == device_commands.CMFD1OSS10 or command == device_commands.CMFD2OSS10 then
            -- CH/F WARN
            rwr.warn_ch = (rwr.warn_ch + 2) % 30
            if rwr.warn_ch == 0 then rwr.warn_ch = 2 end
            rwr.warn_f = (rwr.warn_f + 2) % 30
            if rwr.warn_f == 0 then rwr.warn_f = 2 end
        elseif command == device_commands.CMFD1OSS11 or command == device_commands.CMFD2OSS11 then
            -- [Fase 17] Double-tap em MAN PROG dispara o programa atual.
            -- Tap simples: cicla man_prog (comportamento original).
            local now = (LoGetModelTime and LoGetModelTime()) or 0
            if rwr.last_oss11_time > 0 and (now - rwr.last_oss11_time) < 0.75 then
                -- Double-tap detectado: inicia programa
                start_ew_program()
                rwr.last_oss11_time = -1  -- reset para evitar triple
            else
                rwr.man_prog = (rwr.man_prog + 1) % 11
                if rwr.man_prog == 0 then rwr.man_prog = 1 end
                rwr.last_oss11_time = now
            end
        elseif command == device_commands.CMFD1OSS24 or command == device_commands.CMFD2OSS24 then
            rwr.prog = (rwr.prog + 1) % 11
            if rwr.prog == 0 then rwr.prog = 1 end
        elseif command == device_commands.CMFD1OSS25 or command == device_commands.CMFD2OSS25 then
            rwr.ch_f_mode = (rwr.ch_f_mode + 1) % 3
        elseif command == device_commands.CMFD1OSS27 or command == device_commands.CMFD2OSS27 then
            rwr.search = (rwr.search + 1) % 2
        elseif command == device_commands.CMFD1OSS28 or command == device_commands.CMFD2OSS28 then
            rwr.mode_pri = (rwr.mode_pri + 1) % 2
        end

    elseif value == 1 and CMFD["FULL"]:get() == 0 and CMFD["SelLeft"]:get() == SUB_PAGE_ID.EW then
        if command == device_commands.CMFD1OSS23 or command == device_commands.CMFD2OSS23 then
            rwr.mode_pri = (rwr.mode_pri + 1) % 2
        elseif command == device_commands.CMFD1OSS22 or command == device_commands.CMFD2OSS22 then
            rwr.search = (rwr.search + 1) % 2
        elseif command == device_commands.CMFD1OSS21 or command == device_commands.CMFD2OSS21 then
            rwr.ch_f_mode = (rwr.ch_f_mode + 1) % 3
        end 
    elseif value == 1 and CMFD["FULL"]:get() == 0 and CMFD["SelRight"]:get() == SUB_PAGE_ID.EW then 
        if command == device_commands.CMFD1OSS12 or command == device_commands.CMFD2OSS12 then
            rwr.mode_pri = (rwr.mode_pri + 1) % 2
        elseif command == device_commands.CMFD1OSS13 or command == device_commands.CMFD2OSS13 then
            rwr.search = (rwr.search + 1) % 2
        elseif command == device_commands.CMFD1OSS14 or command == device_commands.CMFD2OSS14 then
            rwr.ch_f_mode = (rwr.ch_f_mode + 1) % 3
        end 
    end
end


function post_initialize_ew()
    debug_message_to_user("post_initialize_ew")
    rwr.dev = GetDevice(devices.RWR)

end

register_as_cmfd_item(SUB_PAGE_ID.EW, post_initialize_ew, update_ew, SetCommandEw)