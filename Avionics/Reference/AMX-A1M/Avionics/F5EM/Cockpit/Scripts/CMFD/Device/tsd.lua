dofile(LockOn_Options.script_path.."Systems/ufcp_api.lua")
local LINK_FUSION = dofile(LockOn_Options.script_path.."Systems/F5EM_Link_BR2_Fusion.lua")
local Terrain = Terrain
if type(Terrain) ~= "table" then
    local ok, terrain_api = pcall(require, "terrain")
    if ok and type(terrain_api) == "table" then Terrain = terrain_api end
end

local hsd_rad_sel = 20
local M_TO_NM = 0.000539957

local HSD_RAD_SEL = get_param_handle("HSD_RAD_SEL")

local ADHSI_DTK_HDG = get_param_handle("ADHSI_DTK_HDG")
local ADHSI_DTK_DIST = get_param_handle("ADHSI_DTK_DIST")
local ADHSI_DTK = get_param_handle("ADHSI_DTK")
local CMFD_NAV_FYT = get_param_handle("CMFD_NAV_FYT")
local STORMSCOPE_CLEAR_REQ = get_param_handle("STORMSCOPE_CLEAR_REQ")
local stormscope_clear_seq = 0

-- [Fase 3 -- Link-BR2 (datalink simulado)]
-- DCS nao tem datalink nativo Link-BR2. Aproximamos compartilhamento de
-- tracks reusando os Track Files do TWS (Fase 1 -- Grifo-F) e projetando
-- em coords mundiais do mapa para exibir no HSI/TSD como se viessem de
-- outras aeronaves da flight. Mantemos ate 8 tracks (limite tipico de
-- displays datalink intra-flight).
local DL_MAX_TRACKS = 8
local DL = {
    MODE       = get_param_handle("DL_MODE"),         -- 0=OFF, 1=STBY, 2=OPR
    MODE_STR   = get_param_handle("DL_MODE_STR"),     -- "OFF" | "STBY" | "OPR"
    SRC        = get_param_handle("DL_SRC"),          -- "BR2" (world tracks) or "OWN" fallback
    COUNT      = get_param_handle("DL_TRACK_COUNT"),
}
local DL_TRACKS = {}
for i = 1, DL_MAX_TRACKS do
    local s = string.format("%02d", i)
    DL_TRACKS[i] = {
        VALID = get_param_handle("DL_TRACK_"..s.."_VALID"),
        BRG   = get_param_handle("DL_TRACK_"..s.."_BRG"),
        DIST  = get_param_handle("DL_TRACK_"..s.."_DIST"),
        FRIEND= get_param_handle("DL_TRACK_"..s.."_FRIEND"),
        CLASS = get_param_handle("DL_TRACK_"..s.."_CLASS"), -- 0 unknown, 1 hostile, 2 friendly
        ID    = get_param_handle("DL_TRACK_"..s.."_ID"),
        ALT   = get_param_handle("DL_TRACK_"..s.."_ALT_KFT"),
        HDG   = get_param_handle("DL_TRACK_"..s.."_HDG_DEG"),
        RAID  = get_param_handle("DL_TRACK_"..s.."_RAID"),
        AGE   = get_param_handle("DL_TRACK_"..s.."_AGE"),
        SOURCE= get_param_handle("DL_TRACK_"..s.."_SOURCE"), -- 0 local, 1 remote
        SOURCE_KIND=get_param_handle("DL_TRACK_"..s.."_SOURCE_KIND"), -- 0 local, 1 peer, 2 E-99
        SOURCES=get_param_handle("DL_TRACK_"..s.."_SOURCES"),
    }
end
local dl_state = { mode = 0 }
-- Handles auxiliares para projetar tracks do radar em coords mundo.
local RADAR_NORM_AZ    = get_param_handle("RADAR_NORM_AZIMUTH")
local RADAR_NORM_RANGE = get_param_handle("RADAR_NORM_RANGE")
local RDR_TRACK_COUNT  = get_param_handle("RDR_TRACK_COUNT")

-- [R3.8] Link-BR2 world-coordinate publisher feed (preferred source).
local LINK_BR2_TRACK_COUNT = get_param_handle("LINK_BR2_TRACK_COUNT")
local LINK_BR2_TIMESTAMP = get_param_handle("LINK_BR2_TIMESTAMP")
local LINK_BR2_TRACKS = {}
for i = 1, DL_MAX_TRACKS do
    local s = string.format("%02d", i)
    LINK_BR2_TRACKS[i] = {
        VALID = get_param_handle("LINK_BR2_TRACK_"..s.."_VALID"),
        LAT   = get_param_handle("LINK_BR2_TRACK_"..s.."_LAT"),
        LON   = get_param_handle("LINK_BR2_TRACK_"..s.."_LON"),
        ALT   = get_param_handle("LINK_BR2_TRACK_"..s.."_ALT"),
        HDG   = get_param_handle("LINK_BR2_TRACK_"..s.."_HDG"),
        SIDE  = get_param_handle("LINK_BR2_TRACK_"..s.."_SIDE"),
        ID    = get_param_handle("LINK_BR2_TRACK_"..s.."_ID"),
        RAID  = get_param_handle("LINK_BR2_TRACK_"..s.."_RAID"),
    }
end

-- [R9] Remote peer feed published by the optional UDP Export bridge.
local LINK_BR2_RX_COUNT = get_param_handle("LINK_BR2_RX_COUNT")
local LINK_BR2_RX_TRACKS = {}
for i = 1, DL_MAX_TRACKS do
    local s = string.format("%02d", i)
    LINK_BR2_RX_TRACKS[i] = {
        VALID   = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_VALID"),
        LAT     = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_LAT"),
        LON     = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_LON"),
        ALT     = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_ALT"),
        HDG     = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_HDG"),
        SIDE    = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_SIDE"),
        ID      = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_ID"),
        RAID    = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_RAID"),
        AGE     = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_AGE"),
        SOURCES = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_SOURCES"),
        SOURCE_KIND = get_param_handle("LINK_BR2_RX_TRACK_"..s.."_SOURCE_KIND"),
    }
end

local function finite_number(value, fallback)
    local number = tonumber(value)
    if number == nil or number ~= number or number == math.huge or number == -math.huge then
        return fallback
    end
    return number
end

local function clamp_number(value, low, high, fallback)
    local number = finite_number(value, fallback)
    if number == nil then return nil end
    return math.max(low, math.min(high, number))
end

local function lat_lon_to_meters(lat, lon)
    lat = finite_number(lat, nil)
    lon = finite_number(lon, nil)
    if lat == nil or lon == nil or not (Terrain and Terrain.convertLatLonToMeters) then return nil end
    local ok, lat_m, lon_m = pcall(Terrain.convertLatLonToMeters, lat, lon)
    lat_m = finite_number(lat_m, nil)
    lon_m = finite_number(lon_m, nil)
    if not ok or lat_m == nil or lon_m == nil then return nil end
    return lat_m, lon_m
end

local RAP = {
    BULL = {
        VALID   = get_param_handle("CMFD_RAP_BULL_VALID"),
        BRG     = get_param_handle("CMFD_RAP_BULL_BRG"),
        DIST    = get_param_handle("CMFD_RAP_BULL_DIST"),
        BRG_DEG = get_param_handle("CMFD_RAP_BULL_BRG_DEG"),
        RNG_NM  = get_param_handle("CMFD_RAP_BULL_RNG_NM"),
    },
    BINGO = {
        BRG_DEG = get_param_handle("CMFD_RAP_BINGO_BRG_DEG"),
        RNG_NM  = get_param_handle("CMFD_RAP_BINGO_RNG_NM"),
    },
    THREAT = {},
}
local RAP_SOURCE = {
    BULL_BRG  = get_param_handle("BULLSEYE_BRG"),
    BULL_RNG  = get_param_handle("BULLSEYE_RNG"),
    BINGO_BRG = get_param_handle("BINGO_HOME_BRG"),
    BINGO_RNG = get_param_handle("BINGO_HOME_RNG"),
    THREAT    = {},
}
for i = 1, 8 do
    RAP.THREAT[i] = {
        VALID  = get_param_handle("CMFD_RAP_THREAT_"..i.."_VALID"),
        BRG    = get_param_handle("CMFD_RAP_THREAT_"..i.."_BRG"),
        DIST   = get_param_handle("CMFD_RAP_THREAT_"..i.."_DIST"),
        RADIUS = get_param_handle("CMFD_RAP_THREAT_"..i.."_RADIUS"),
    }
    RAP_SOURCE.THREAT[i] = {
        LAT = get_param_handle("THREAT_RING_"..i.."_LAT"),
        LON = get_param_handle("THREAT_RING_"..i.."_LON"),
        RNG = get_param_handle("THREAT_RING_"..i.."_RNG"),
    }
end

local function heading_deg(value)
    value = finite_number(value, 0)
    if math.abs(value) <= (2 * math.pi + 0.1) then value = math.deg(value) end
    return value % 360
end

local function dl_clear_slot(i)
    local track = DL_TRACKS[i]
    track.VALID:set(0)
    track.BRG:set(0)
    track.DIST:set(0)
    track.FRIEND:set(0)
    track.CLASS:set(0)
    track.ID:set(0)
    track.ALT:set(0)
    track.HDG:set(0)
    track.RAID:set(0)
    track.AGE:set(0)
    track.SOURCE:set(0)
    track.SOURCE_KIND:set(0)
    track.SOURCES:set(0)
end

local function dl_publish_slot(i, brg_deg, dist_nm_scaled, class, id, alt_m,
                               hdg, raid, age, source, source_kind, sources)
    local track = DL_TRACKS[i]
    class = clamp_number(class, 0, 2, 0)
    track.VALID:set(1)
    track.BRG:set(heading_deg(brg_deg))
    track.DIST:set(math.max(0, finite_number(dist_nm_scaled, 0)))
    track.FRIEND:set(class == 2 and 1 or 0)
    track.CLASS:set(class)
    track.ID:set(math.floor(clamp_number(id, 0, 99, i)))
    track.ALT:set(clamp_number(finite_number(alt_m, 0) / 304.8, -2, 99, 0))
    track.HDG:set(heading_deg(hdg))
    track.RAID:set(math.floor(clamp_number(raid, 1, 99, 1)))
    track.AGE:set(clamp_number(age, 0, 99, 0))
    track.SOURCE:set(source == 1 and 1 or 0)
    track.SOURCE_KIND:set(math.floor(clamp_number(source_kind, 0, 2, 0)))
    track.SOURCES:set(math.floor(clamp_number(sources, 1, 99, 1)))
end

local TSD_FRAME = {}

local function calc_brg_dist_elev_time(dest_lat_m, dest_lon_m, dest_alt_m, orig_lat_m, orig_lon_m, orig_alt_m)
    orig_lat_m = orig_lat_m or TSD_FRAME.x
    orig_lon_m = orig_lon_m or TSD_FRAME.z
    orig_alt_m = orig_alt_m or TSD_FRAME.y

    local brg, dist

    local lat = dest_lat_m - orig_lat_m
    local lon = dest_lon_m - orig_lon_m

    brg = math.atan2(lon, lat)
    dist = math.sqrt(lat * lat + lon * lon)

    return brg, dist
end

local function coord_project(orig_lat_m, orig_lon_m, brg, dist)
    orig_lat_m = orig_lat_m + dist * math.cos(math.rad(brg))
    orig_lon_m = orig_lon_m + dist * math.sin(math.rad(brg))
    return orig_lat_m, orig_lon_m
end

-- [Fase 14b] Areas taticas do DTC (avoid zones / contact line / flight area):
-- handles de origem (publicados por dtu.lua) em cache, e um helper que converte
-- cada ponto (lat/lon graus) em polar BRG/DIST (mesma matematica dos waypoints)
-- para o CMFD_TSD desenhar marcadores.
local DTC_AREA_SRC = { AVD = {}, CNT = {}, FLT = {} }
for k = 1, 10 do
    local a = string.format("%02d", k)
    DTC_AREA_SRC.AVD[k] = {
        LAT = get_param_handle("DTC_AVD_AREA_"..a.."_LAT"), LON = get_param_handle("DTC_AVD_AREA_"..a.."_LON"),
        BRG = get_param_handle("CMFD_HSD_AVD"..k.."_BRG"), DIST = get_param_handle("CMFD_HSD_AVD"..k.."_DIST"),
    }
    DTC_AREA_SRC.CNT[k] = {
        LAT = get_param_handle("DTC_CNT_LINE_"..a.."_LAT"), LON = get_param_handle("DTC_CNT_LINE_"..a.."_LON"),
        BRG = get_param_handle("CMFD_HSD_CNT"..k.."_BRG"), DIST = get_param_handle("CMFD_HSD_CNT"..k.."_DIST"),
    }
end
for k = 1, 12 do
    local a = string.format("%02d", k)
    DTC_AREA_SRC.FLT[k] = {
        LAT = get_param_handle("DTC_FLT_AREA_"..a.."_LAT"), LON = get_param_handle("DTC_FLT_AREA_"..a.."_LON"),
        BRG = get_param_handle("CMFD_HSD_FLT"..k.."_BRG"), DIST = get_param_handle("CMFD_HSD_FLT"..k.."_DIST"),
    }
end

local function publish_area_marker(area)
    local lat_deg, lon_deg = area.LAT:get(), area.LON:get()
    local lat_m, lon_m = lat_lon_to_meters(lat_deg, lon_deg)
    if (lat_deg == 0 and lon_deg == 0) or lat_m == nil or lon_m == nil then
        area.BRG:set(0); area.DIST:set(0)
        return
    end
    local hdg, distance = calc_brg_dist_elev_time(lat_m, lon_m, 0)
    area.BRG:set(heading_deg(math.deg(hdg)))
    area.DIST:set(math.max(0, finite_number(distance, 0) * M_TO_NM / hsd_rad_sel))
end

local function update_rap_overlay()
    local bull_rng = math.max(0, finite_number(RAP_SOURCE.BULL_RNG:get(), 0))
    if bull_rng > 0 then
        local bull_brg = (heading_deg(RAP_SOURCE.BULL_BRG:get()) + 180) % 360
        RAP.BULL.VALID:set(1)
        RAP.BULL.BRG:set(bull_brg)
        RAP.BULL.DIST:set(bull_rng * M_TO_NM / hsd_rad_sel)
        RAP.BULL.BRG_DEG:set(bull_brg)
        RAP.BULL.RNG_NM:set(bull_rng * M_TO_NM)
    else
        RAP.BULL.VALID:set(0)
        RAP.BULL.BRG:set(0)
        RAP.BULL.DIST:set(0)
        RAP.BULL.BRG_DEG:set(0)
        RAP.BULL.RNG_NM:set(0)
    end

    RAP.BINGO.BRG_DEG:set(heading_deg(RAP_SOURCE.BINGO_BRG:get()))
    RAP.BINGO.RNG_NM:set(math.max(0, finite_number(RAP_SOURCE.BINGO_RNG:get(), 0)) * M_TO_NM)

    for i = 1, 8 do
        local source = RAP_SOURCE.THREAT[i]
        local target = RAP.THREAT[i]
        local lat = finite_number(source.LAT:get(), nil)
        local lon = finite_number(source.LON:get(), nil)
        local radius_m = math.max(0, finite_number(source.RNG:get(), 0))
        local lat_m, lon_m = lat_lon_to_meters(lat, lon)
        if radius_m > 0 and lat ~= nil and lon ~= nil and not (lat == 0 and lon == 0)
            and lat_m ~= nil and lon_m ~= nil then
            local brg, distance = calc_brg_dist_elev_time(lat_m, lon_m, 0)
            target.VALID:set(1)
            target.BRG:set(math.deg(brg) % 360)
            target.DIST:set(distance * M_TO_NM / hsd_rad_sel)
            target.RADIUS:set(radius_m * M_TO_NM / hsd_rad_sel)
        else
            target.VALID:set(0)
            target.BRG:set(0)
            target.DIST:set(0)
            target.RADIUS:set(0)
        end
    end
end

local TSD_WAYPOINTS = {}
for index = 1, 100 do
    local waypoint_prefix = "CMFD_HSD_WP" .. index
    local dtk_prefix = "CMFD_HSD_DTK" .. index
    TSD_WAYPOINTS[index] = {
        label = string.format("%02d", index - 1),
        ID = get_param_handle(waypoint_prefix .. "_ID"),
        BRG = get_param_handle(waypoint_prefix .. "_BRG"),
        DIST = get_param_handle(waypoint_prefix .. "_DIST"),
        DTK_BRG = get_param_handle(dtk_prefix .. "_BRG"),
        DTK_DIST = get_param_handle(dtk_prefix .. "_DIST"),
        DTK = get_param_handle(dtk_prefix),
    }
end

function update_tsd()
    TSD_FRAME.x, TSD_FRAME.y, TSD_FRAME.z = sensor_data.getSelfCoordinates()
    for k=1,100 do
        local output = TSD_WAYPOINTS[k]
        local waypoint = nav_fyt_list[k]
        local waypoint_lat = waypoint and finite_number(waypoint.lat, nil)
        local waypoint_lon = waypoint and finite_number(waypoint.lon, nil)
        if waypoint and waypoint_lat and waypoint_lon
            and waypoint_lat >= -90 and waypoint_lat <= 90
            and waypoint_lon >= -180 and waypoint_lon <= 180 then

            local dest_lat_m = finite_number(waypoint.lat_m, 0)
            local dest_lon_m = finite_number(waypoint.lon_m, 0)
            local dest_alt_m = finite_number(waypoint.altitude, 0) / 3.28084

            local hdg, distance = calc_brg_dist_elev_time(dest_lat_m, dest_lon_m, dest_alt_m)
            hdg = math.deg(hdg) % 360

            output.ID:set(output.label)
            output.BRG:set(hdg)
            output.DIST:set(distance * M_TO_NM / hsd_rad_sel)

            output.DTK_BRG:set(output.BRG:get())
            output.DTK_DIST:set(output.DIST:get())
            output.DTK:set((ADHSI_DTK:get() == 1 and CMFD_NAV_FYT:get() == k-1) and 1 or 0)

            if ADHSI_DTK:get() == 1 and CMFD_NAV_FYT:get() == k-1 then 
                dest_lat_m, dest_lon_m = coord_project(dest_lat_m, dest_lon_m, ADHSI_DTK_HDG:get()+180, ADHSI_DTK_DIST:get()/M_TO_NM)
                
                hdg, distance = calc_brg_dist_elev_time(dest_lat_m, dest_lon_m, dest_alt_m)
                hdg = math.deg(hdg) % 360

                output.BRG:set(hdg)
                output.DIST:set(distance * M_TO_NM / hsd_rad_sel)
            end


        else
            output.ID:set(output.label)
            output.BRG:set(0)
            output.DIST:set(0)
        end
    end

    HSD_RAD_SEL:set(hsd_rad_sel)
    update_rap_overlay()

    -- [Fase 14b] Marcadores das areas taticas do DTC (mesma projecao polar dos
    -- waypoints). O CMFD_TSD desenha: avoid zones (10), contact line (10),
    -- flight area (12).
    for k = 1, 10 do
        publish_area_marker(DTC_AREA_SRC.AVD[k])
        publish_area_marker(DTC_AREA_SRC.CNT[k])
    end
    for k = 1, 12 do
        publish_area_marker(DTC_AREA_SRC.FLT[k])
    end

    -- [Fase 3] Datalink Link-BR2 simulado: projeta ate 8 track files do
    -- TWS para coords mundo e publica BRG/DIST relativos ao ownship.
    -- [R3.8] Prioriza tracks Link-BR2 ja publicados em world coords;
    -- fallback para TWS local caso a feed BR2 nao esteja disponivel.
    -- Only OPR publishes tactical tracks. OFF and STBY keep every display
    -- output neutral, so standby cannot be mistaken for an active datalink.
    DL.MODE:set(dl_state.mode)
    DL.MODE_STR:set(({[0]="OFF",[1]="STBY",[2]="OPR"})[dl_state.mode] or "OFF")
    local dl_count = 0
    if dl_state.mode == 2 then
        local used_br2 = false
        local now = get_absolute_model_time and get_absolute_model_time() or 0
        local timestamp = finite_number(LINK_BR2_TIMESTAMP:get(), now)
        local link_age = clamp_number(now - timestamp, 0, 99, 0)

        -- Preferred source: fuse local Link-BR2 publisher tracks with remote
        -- peers. LINK_FUSION preserves local authority and merges nearby peers.
        local local_candidates = {}
        for i = 1, DL_MAX_TRACKS do
            local src = LINK_BR2_TRACKS[i]
            local valid = finite_number(src.VALID:get(), 0)
            local lat = finite_number(src.LAT:get(), nil)
            local lon = finite_number(src.LON:get(), nil)
            if valid > 0 and lat ~= nil and lon ~= nil and not (lat == 0 and lon == 0)
                and lat_lon_to_meters(lat, lon) ~= nil then
                local_candidates[#local_candidates+1] = {
                    id=src.ID:get(), lat=lat, lon=lon, alt=src.ALT:get(),
                    hdg=src.HDG:get(), side=src.SIDE:get(), raid=src.RAID:get(),
                    age=link_age, source_kind=0, sources=1, remote=false,
                }
            end
        end

        local remote_candidates = {}
        if finite_number(LINK_BR2_RX_COUNT:get(), 0) > 0 then
            for i = 1, DL_MAX_TRACKS do
                local src = LINK_BR2_RX_TRACKS[i]
                local valid = finite_number(src.VALID:get(), 0)
                local lat = finite_number(src.LAT:get(), nil)
                local lon = finite_number(src.LON:get(), nil)
                if valid > 0 and lat ~= nil and lon ~= nil and not (lat == 0 and lon == 0)
                    and lat_lon_to_meters(lat, lon) ~= nil then
                    remote_candidates[#remote_candidates+1] = {
                        id=src.ID:get(), lat=lat, lon=lon, alt=src.ALT:get(),
                        hdg=src.HDG:get(), side=src.SIDE:get(), raid=src.RAID:get(),
                        age=src.AGE:get(), sources=src.SOURCES:get(), remote=true,
                        source_kind=math.max(1,
                            math.floor(clamp_number(src.SOURCE_KIND:get(), 0, 2, 1))),
                    }
                end
            end
        end

        local fused = LINK_FUSION.fuse(local_candidates, remote_candidates,
            {limit=DL_MAX_TRACKS, merge_nm=1.0})
        local has_remote = false
        local has_local = false
        local has_peer = false
        local has_awacs = false
        for i = 1, DL_MAX_TRACKS do
            local track = fused[i]
            if track then
                local trk_lat_m, trk_lon_m = lat_lon_to_meters(track.lat, track.lon)
                local hdg2, dist2 = calc_brg_dist_elev_time(trk_lat_m, trk_lon_m, 0)
                hdg2 = math.deg(hdg2) % 360
                dl_publish_slot(i, hdg2, dist2 * M_TO_NM / hsd_rad_sel,
                    track.side, track.id, track.alt, track.hdg, track.raid,
                    track.age, track.remote and 1 or 0,
                    track.source_kind or 0, track.sources)
                dl_count = dl_count + 1
                used_br2 = true
                if track.remote or (track.sources or 1) > 1 then has_remote = true end
                if track.source_kind == 0 then has_local = true end
                if track.has_peer or track.source_kind == 1 then has_peer = true end
                if track.has_awacs or track.source_kind == 2 then has_awacs = true end
            else
                dl_clear_slot(i)
            end
        end

        -- Fallback source: local radar track files (legacy behavior).
        if not used_br2 then
            local self_lat_m, self_alt_m, self_lon_m = TSD_FRAME.x, TSD_FRAME.y, TSD_FRAME.z
            local self_hdg = sensor_data.getHeading() or 0  -- rad
            local norm_az    = finite_number(RADAR_NORM_AZ:get(), 0)    -- rad
            local norm_range = math.max(0, finite_number(RADAR_NORM_RANGE:get(), 0)) -- m
            dl_count = 0
            for i = 1, DL_MAX_TRACKS do
                local a = string.format("%02.0f", i)
                local active = finite_number(get_param_handle("RADAR_TRACK_"..a.."_ACTIVE"):get(), 0)
                if active > 0 then
                    local az_norm  = finite_number(get_param_handle("RADAR_TRACK_"..a.."_AZIMUTH_NORM"):get(), 0)
                    local rng_norm = finite_number(get_param_handle("RADAR_TRACK_"..a.."_RANGE_NORM"):get(), 0)
                    local az_rad   = az_norm * norm_az
                    local range_m  = rng_norm * norm_range
                    if range_m > 0 then
                        local bearing = self_hdg + az_rad
                        local trk_lat_m = self_lat_m + range_m * math.cos(bearing)
                        local trk_lon_m = self_lon_m + range_m * math.sin(bearing)
                        local hdg2, dist2 = calc_brg_dist_elev_time(trk_lat_m, trk_lon_m, 0)
                        hdg2 = math.deg(hdg2) % 360
                        local alt_ft = get_param_handle("RADAR_TRACK_"..a.."_ALT"):get() or 0
                        local hdg = get_param_handle("RADAR_TRACK_"..a.."_HDG"):get() or 0
                        local raid = get_param_handle("RADAR_TRACK_"..a.."_RAID_SIZE"):get() or 1
                        dl_publish_slot(i, hdg2, dist2 * M_TO_NM / hsd_rad_sel,
                            0, i, alt_ft * 0.3048, hdg, raid, 0, 0, 0, 1)
                        dl_count = dl_count + 1
                    else
                        dl_clear_slot(i)
                    end
                else
                    dl_clear_slot(i)
                end
            end
            DL.SRC:set("OWN")
        else
            if has_awacs then
                DL.SRC:set((has_local or has_peer) and "BR2+E99" or "E99")
            else
                DL.SRC:set(has_remote and "BR2+MP" or "BR2")
            end
        end
    else
        for i = 1, DL_MAX_TRACKS do
            dl_clear_slot(i)
        end
        DL.SRC:set("OFF")
    end
    DL.COUNT:set(dl_count)
end

local function set_dl_mode(mode)
    dl_state.mode = mode
    DL.MODE:set(mode)
    DL.MODE_STR:set(({[0]="OFF",[1]="STBY",[2]="OPR"})[mode])
    if mode ~= 2 then
        DL.COUNT:set(0)
        DL.SRC:set("OFF")
        for index = 1, DL_MAX_TRACKS do dl_clear_slot(index) end
    end
end

local function post_initialize_tsd()
    set_dl_mode(0)
end

function SetCommandTsd(command,value, CMFD)
    if command == device_commands.ATDL_POWER then
        if value == -1 or value == 0 or value == 1 then set_dl_mode(value == 1 and 2 or 0) end
        return
    end
    if value == 1 then 
        local selected=-1

        -- Change zoom
        if command==device_commands.CMFD1OSS27 or command==device_commands.CMFD2OSS27 then 
            hsd_rad_sel = math.max(20, hsd_rad_sel / 2) -- increase zoom
        elseif command==device_commands.CMFD1OSS28 or command==device_commands.CMFD2OSS28 then 
            hsd_rad_sel = math.min(1280, hsd_rad_sel * 2) -- decrease zoom

        -- Select ADHSI format
        elseif command==device_commands.CMFD1OSS26 or command==device_commands.CMFD2OSS26 then 
            selected=SUB_PAGE_ID.ADHSI

        -- [Fase 3] Cicla modo DL (OFF -> STBY -> OPR -> OFF) no OSS UD3.
        elseif command==device_commands.CMFD1OSS3 or command==device_commands.CMFD2OSS3 then
            set_dl_mode((dl_state.mode + 1) % 3)

        -- [Phase R3.7] CLR STRM (clear Stormscope cells)
        elseif command==device_commands.CMFD1OSS12 or command==device_commands.CMFD2OSS12
            or command==device_commands.CMFD1OSS11 or command==device_commands.CMFD2OSS11 then
            stormscope_clear_seq = stormscope_clear_seq + 1
            STORMSCOPE_CLEAR_REQ:set(stormscope_clear_seq)
        
        end

        if selected > 0 then
            CMFD["Format"]:set(selected)
            CMFD["Sel"]:set(selected)
            if CMFD["Primary"]:get()==1 then
                CMFD["SelRight"]:set(selected)
                CMFD["SelRightName"]:set(SUB_PAGE_NAME[selected])
            else 
                CMFD["SelLeft"]:set(selected)
                CMFD["SelLeftName"]:set(SUB_PAGE_NAME[selected])
            end
        end
    end
end


register_as_cmfd_item(SUB_PAGE_ID.TSD, post_initialize_tsd, update_tsd, SetCommandTsd)
register_as_cmfd_item(SUB_PAGE_ID.MAP, nil, nil, SetCommandTsd)
register_as_cmfd_item(SUB_PAGE_ID.DLSET, nil, nil, SetCommandTsd)
