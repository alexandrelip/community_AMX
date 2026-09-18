dofile(LockOn_Options.script_path.."devices.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."functions.lua")
dofile(LockOn_Options.script_path.."CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path.."Systems/electric_system_api.lua")
dofile(LockOn_Options.script_path.."Systems/alarm_api.lua")
dofile(LockOn_Options.script_path.."Systems/avionics_api.lua")
dofile(LockOn_Options.script_path.."Systems/weapon_system_api.lua")
dofile(LockOn_Options.script_path.."utils.lua")

startup_print("cmfd_right: load")

dev = GetSelf()
local FLIR_PILOT_ENABLED = get_param_handle("FLIR_PILOT_ENABLED")

update_time_step = 0.05 -- CMFD host: 20 Hz
make_default_activity(update_time_step)

sensor_data = get_base_data()

dofile(LockOn_Options.script_path.."CMFD/Device/cmfd_text.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/flir_text.lua")

function text_from_lua_function(number)
    return text_from_lua_function_flir(number) or ""
end

update_list = {}
SetCommand_list = {}
post_initialize_list = {}

function register_as_cmfd_item(id, post_initialize_fcn, update_fcn, SetCommand_fcn)
    -- Do not let a missing sub-page ID kill the whole CMFD device.
    if id == nil then return end
    if post_initialize_fcn ~= nil then post_initialize_list[id] = post_initialize_fcn end
    -- O id acompanha o callback para o gate de paginas pesadas em update().
    if update_fcn ~= nil then update_list[#update_list + 1] = {id = id, fn = update_fcn} end
    if SetCommand_fcn ~= nil then SetCommand_list[id] = SetCommand_fcn end
end

dofile(LockOn_Options.script_path.."CMFD/Device/menu1.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/menu2.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/dtu.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/emer.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/pfl.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/nav.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/tsd.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/hud.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/sms.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/ew.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/adhsi.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/ufc.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/eicas.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/hmd.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/rdr.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/dvr.lua")
-- [Fase 21] Tactical overlay (bullseye, threat rings, bingo)
dofile(LockOn_Options.script_path.."CMFD/Device/tactical_overlay.lua")
-- SURV composes the reconciled TSD/Link-BR2/radar picture without feeding weapons.
dofile(LockOn_Options.script_path.."CMFD/Device/surv.lua")
-- [Fase 23] TGP Litening simulado
dofile(LockOn_Options.script_path.."CMFD/Device/tgp_litening.lua")
-- [Variant pages] IFR (F-5EM) e LDP/TGP (F-5TH)
dofile(LockOn_Options.script_path.."CMFD/Device/ifr.lua")
dofile(LockOn_Options.script_path.."CMFD/Device/ldp.lua")
-- [BIT] Built-In Test (status GO/NO-GO dos subsistemas)
dofile(LockOn_Options.script_path.."CMFD/Device/bit.lua")

dev:listen_command(device_commands.CMFD2OSS1)
dev:listen_command(device_commands.CMFD2OSS2)
dev:listen_command(device_commands.CMFD2OSS3)
dev:listen_command(device_commands.CMFD2OSS4)
dev:listen_command(device_commands.CMFD2OSS5)
dev:listen_command(device_commands.CMFD2OSS6)
dev:listen_command(device_commands.CMFD2OSS7)
dev:listen_command(device_commands.CMFD2OSS8)
dev:listen_command(device_commands.CMFD2OSS9)
dev:listen_command(device_commands.CMFD2OSS10)
dev:listen_command(device_commands.CMFD2OSS11)
dev:listen_command(device_commands.CMFD2OSS12)
dev:listen_command(device_commands.CMFD2OSS13)
dev:listen_command(device_commands.CMFD2OSS14)
dev:listen_command(device_commands.CMFD2OSS15)
dev:listen_command(device_commands.CMFD2OSS16)
dev:listen_command(device_commands.CMFD2OSS17)
dev:listen_command(device_commands.CMFD2OSS18)
dev:listen_command(device_commands.CMFD2OSS19)
dev:listen_command(device_commands.CMFD2OSS20)
dev:listen_command(device_commands.CMFD2OSS21)
dev:listen_command(device_commands.CMFD2OSS22)
dev:listen_command(device_commands.CMFD2OSS23)
dev:listen_command(device_commands.CMFD2OSS24)
dev:listen_command(device_commands.CMFD2OSS25)
dev:listen_command(device_commands.CMFD2OSS26)
dev:listen_command(device_commands.CMFD2OSS27)
dev:listen_command(device_commands.CMFD2OSS28)
dev:listen_command(device_commands.CMFD2ButtonOn)
dev:listen_command(device_commands.CMFD2ButtonGain)
dev:listen_command(device_commands.CMFD2ButtonSymb)
dev:listen_command(device_commands.CMFD2ButtonBright)

dev:listen_command(device_commands.CMFD1OSS1)
dev:listen_command(device_commands.CMFD1OSS2)
dev:listen_command(device_commands.CMFD1OSS3)
dev:listen_command(device_commands.CMFD1OSS4)
dev:listen_command(device_commands.CMFD1OSS5)
dev:listen_command(device_commands.CMFD1OSS6)
dev:listen_command(device_commands.CMFD1OSS7)
dev:listen_command(device_commands.CMFD1OSS8)
dev:listen_command(device_commands.CMFD1OSS9)
dev:listen_command(device_commands.CMFD1OSS10)
dev:listen_command(device_commands.CMFD1OSS11)
dev:listen_command(device_commands.CMFD1OSS12)
dev:listen_command(device_commands.CMFD1OSS13)
dev:listen_command(device_commands.CMFD1OSS14)
dev:listen_command(device_commands.CMFD1OSS15)
dev:listen_command(device_commands.CMFD1OSS16)
dev:listen_command(device_commands.CMFD1OSS17)
dev:listen_command(device_commands.CMFD1OSS18)
dev:listen_command(device_commands.CMFD1OSS19)
dev:listen_command(device_commands.CMFD1OSS20)
dev:listen_command(device_commands.CMFD1OSS21)
dev:listen_command(device_commands.CMFD1OSS22)
dev:listen_command(device_commands.CMFD1OSS23)
dev:listen_command(device_commands.CMFD1OSS24)
dev:listen_command(device_commands.CMFD1OSS25)
dev:listen_command(device_commands.CMFD1OSS26)
dev:listen_command(device_commands.CMFD1OSS27)
dev:listen_command(device_commands.CMFD1OSS28)
dev:listen_command(device_commands.CMFD1ButtonOn)
dev:listen_command(device_commands.CMFD1ButtonGain)
dev:listen_command(device_commands.CMFD1ButtonSymb)
dev:listen_command(device_commands.CMFD1ButtonBright)
dev:listen_command(device_commands.FLIR_POWER_TOGGLE)
dev:listen_command(device_commands.ATDL_POWER)

dev:listen_command(Keys.DisplayMngt)

-- [Fase 5.2] Roteia comando UFCP_DVR para o handler do DVR no CMFD.
-- O switch fisico de DVR (REC/STBY/STOP) fica no UFCP, mas o estado
-- e atualizado dentro do sub-page DVR do CMFD. Sem essa escuta o
-- toggle do switch nao alcanca o state machine do DVR. Esse era o
-- TODO confessado pelo autor original em dvr.lua:230 ("I couldn't
-- find a way for it to listen to device_commands.UFCP_DVR. Help.").
dev:listen_command(device_commands.UFCP_DVR)

local CMFDNumber=get_param_handle("CMFDNumber")
CMFDNumber:set(0)

local CMFD1Format=get_param_handle("CMFD1Format")
CMFD1Format:set(SUB_PAGE_ID.RDR)

local CMFD2Format=get_param_handle("CMFD2Format")
CMFD2Format:set(SUB_PAGE_ID.EICAS)

local CMFDDoi=get_param_handle("CMFDDoi")
CMFDDoi:set(1)  -- Set FWD LCMFD as default DOI. This is set by DTE, but usually the aircraft has this as set.

local CMFD1FULL=get_param_handle("CMFD1FULL")
CMFD1FULL:set(0)

local CMFD2FULL=get_param_handle("CMFD2FULL")
CMFD2FULL:set(1)

local CMFD1Primary=get_param_handle("CMFD1Primary")
CMFD1Primary:set(0) -- 0=Left or OSS 19     1=Right or PSS 16

local CMFD2Primary=get_param_handle("CMFD2Primary")
CMFD2Primary:set(0) -- 0=Left or OSS 19     1=Right or PSS 16

local CMFD1Sel=get_param_handle("CMFD1Sel")
CMFD1Sel:set(SUB_PAGE_ID.ADHSI)

local CMFD2Sel=get_param_handle("CMFD2Sel")
CMFD2Sel:set(SUB_PAGE_ID.EICAS)

local CMFD1SelTop=get_param_handle("CMFD1SelTop")
CMFD1SelTop:set(SUB_PAGE_ID.RDR)

local CMFD2SelTop=get_param_handle("CMFD2SelTop")
CMFD2SelTop:set(SUB_PAGE_ID.EICAS)

local CMFD1SelTopName=get_param_handle("CMFD1SelTopName")
CMFD1SelTopName:set(SUB_PAGE_NAME[CMFD1SelTop:get()])

local CMFD2SelTopName=get_param_handle("CMFD2SelTopName")
CMFD2SelTopName:set(SUB_PAGE_NAME[CMFD2SelTop:get()])

local CMFD1SelLeft=get_param_handle("CMFD1SelLeft")
CMFD1SelLeft:set(SUB_PAGE_ID.ADHSI)

local CMFD2SelLeft=get_param_handle("CMFD2SelLeft")
CMFD2SelLeft:set(SUB_PAGE_ID.SMS)

local CMFD1SelLeftName=get_param_handle("CMFD1SelLeftName")
CMFD1SelLeftName:set(SUB_PAGE_NAME[CMFD1SelLeft:get()])

local CMFD2SelLeftName=get_param_handle("CMFD2SelLeftName")
CMFD2SelLeftName:set(SUB_PAGE_NAME[CMFD2SelLeft:get()])

local CMFD1SelRight=get_param_handle("CMFD1SelRight")
CMFD1SelRight:set(SUB_PAGE_ID.EW)

local CMFD2SelRight=get_param_handle("CMFD2SelRight")
CMFD2SelRight:set(SUB_PAGE_ID.NAV)

local CMFD1SelRightName=get_param_handle("CMFD1SelRightName")
CMFD1SelRightName:set(SUB_PAGE_NAME[CMFD1SelRight:get()])

local CMFD2SelRightName=get_param_handle("CMFD2SelRightName")
CMFD2SelRightName:set(SUB_PAGE_NAME[CMFD2SelRight:get()])

local CMFD1On=get_param_handle("CMFD1On")
local CMFD2On=get_param_handle("CMFD2On")

local F5EM_CMFD_FLIR_STATUS = get_param_handle("FLIR_STATUS")
local F5EM_CMFD_FLIR_POD = get_param_handle("FLIR_POD_PRESENT")
local f5em_cmfd_diag_last_state = nil
local f5em_cmfd_command_name = {}

for name, id in pairs(device_commands) do
    f5em_cmfd_command_name[id] = name
end

local function f5em_cmfd_diag_log(reason)
    local state = table.concat({
        tostring(CMFD1Format:get() or 0),
        tostring(CMFD2Format:get() or 0),
        tostring(CMFDDoi:get() or 0),
        tostring(CMFD1On:get() or 0),
        tostring(CMFD2On:get() or 0),
        tostring(FLIR_PILOT_ENABLED:get() or 0),
        tostring(F5EM_CMFD_FLIR_POD:get() or 0),
        tostring(F5EM_CMFD_FLIR_STATUS:get() or 0),
    }, ":")
    if state == f5em_cmfd_diag_last_state then return end
    f5em_cmfd_diag_last_state = state
    log.info(string.format(
        "F5EM_CMFD_STATE reason=%s t=%.1f fmt1=%s fmt2=%s doi=%s on1=%s on2=%s flir_enabled=%s pod=%s flir_status=%s",
        reason or "update",
        get_absolute_model_time(),
        tostring(CMFD1Format:get() or 0),
        tostring(CMFD2Format:get() or 0),
        tostring(CMFDDoi:get() or 0),
        tostring(CMFD1On:get() or 0),
        tostring(CMFD2On:get() or 0),
        tostring(FLIR_PILOT_ENABLED:get() or 0),
        tostring(F5EM_CMFD_FLIR_POD:get() or 0),
        tostring(F5EM_CMFD_FLIR_STATUS:get() or 0)))
end

local CMFD1SwOn=get_param_handle("CMFD1SwOn")
local CMFD2SwOn=get_param_handle("CMFD2SwOn")

local CMFD1_BRIGHT=get_param_handle("CMFD1_BRIGHT")
local CMFD2_BRIGHT=get_param_handle("CMFD2_BRIGHT")

CMFD1_BRIGHT:set(1)
CMFD2_BRIGHT:set(1)


local DMSLeftElapsed = -1
local DMSRightElapsed = -1
local cmfd_bright = {}
cmfd_bright[1] = 1
cmfd_bright[2] = 1
local cmfd_oss_press_time = 0
local cmfd_oss_press_command = 0

-- Variantes de aeronave suportadas pelo mesmo cockpit:
--   F-5EM (FAB): IFR/REVO
--   F-5TH (RTAF): LDP/TGP
local CMFD_VARIANT_F5EM = get_param_handle("CMFD_VARIANT_F5EM")
local CMFD_VARIANT_F5TH = get_param_handle("CMFD_VARIANT_F5TH")
local CMFD_HAS_IFR = get_param_handle("CMFD_HAS_IFR")
local CMFD_HAS_LDP = get_param_handle("CMFD_HAS_LDP")

CMFD_VARIANT_F5EM:set(1)
CMFD_VARIANT_F5TH:set(0)
CMFD_HAS_IFR:set(1)
CMFD_HAS_LDP:set(0)

local variant_last_scan_t = -1

local function detect_aircraft_name()
    if type(get_aircraft_type) == "function" then
        local ok, name = pcall(get_aircraft_type)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if type(LoGetSelfData) == "function" then
        local ok, self = pcall(LoGetSelfData)
        if ok and type(self) == "table" then
            local name = self.Name or self.type or self.UnitName
            if type(name) == "string" and name ~= "" then return name end
        end
    end
    return "F-5EM"
end

local function update_variant_handles(force)
    local now = get_absolute_model_time()
    if (not force) and variant_last_scan_t >= 0 and (now - variant_last_scan_t) < 1.0 then return end
    variant_last_scan_t = now

    local name = string.upper(detect_aircraft_name())
    local is_f5th = (string.find(name, "F-5TH", 1, true) ~= nil) or
                     (string.find(name, "F5TH", 1, true) ~= nil)

    CMFD_VARIANT_F5TH:set(is_f5th and 1 or 0)
    CMFD_VARIANT_F5EM:set(is_f5th and 0 or 1)
    CMFD_HAS_LDP:set(is_f5th and 1 or 0)
    -- [2026-07-27] Paridade F-5TH = F-5EM: a pagina IFR/REVO fica disponivel
    -- nas duas variantes. Para rediferenciar, volte a publicar
    -- CMFD_HAS_IFR:set(is_f5th and 0 or 1).
    CMFD_HAS_IFR:set(1)
end

-- [Paridade A-29 -- FPS] Gate de paginas pesadas. Uma pagina selecionada em
-- qualquer CMFD roda na cadencia cheia (20 Hz); oculta cai para 5 Hz apenas
-- como heartbeat de frescor. Somente paginas puramente de apresentacao entram
-- aqui: NAV/ADHSI/EW/EICAS publicam estado consumido por outros dispositivos
-- (CCRP, alarmes, HUD) e por isso permanecem a 20 Hz. LDP/LT ficam de fora
-- porque ldp.lua ja tem divisor proprio que considera as duas paginas.
local HIDDEN_HEAVY_PAGE_TICK_DIVIDER = 4 -- 20 Hz / 4 = 5 Hz quando oculta
local hidden_heavy_page_tick = 0
local HEAVY_PAGES = {
    [SUB_PAGE_ID.RDR] = true,
    [SUB_PAGE_ID.SMS] = true,
    [SUB_PAGE_ID.TSD] = true,
    [SUB_PAGE_ID.SURV] = true,
}

local function should_update_cmfd_item(id, fmt1, fmt2)
    if not HEAVY_PAGES[id] then return true end
    if fmt1 == id or fmt2 == id then return true end
    if id == SUB_PAGE_ID.TSD
        and (fmt1 == SUB_PAGE_ID.SURV or fmt2 == SUB_PAGE_ID.SURV) then
        return true
    end
    return hidden_heavy_page_tick == 0
end

local function is_fixed_full_page(id)
    return id == SUB_PAGE_ID.TSD or id == SUB_PAGE_ID.SURV
end

function update()
    update_variant_handles(false)

    if is_fixed_full_page(CMFD1Format:get()) then CMFD1FULL:set(1) end
    if is_fixed_full_page(CMFD2Format:get()) then CMFD2FULL:set(1) end

    CMFD1On:set(get_elec_essential_dc_bus_ok() and get_cockpit_draw_argument_value(1843) > 0 and 1 or 0)
    CMFD2On:set(get_elec_essential_dc_bus_ok() and get_cockpit_draw_argument_value(1843) > 0 and 1 or 0)
    f5em_cmfd_diag_log("update")

    local fmt1 = CMFD1Format:get()
    local fmt2 = CMFD2Format:get()
    for _, item in ipairs(update_list) do
        if should_update_cmfd_item(item.id, fmt1, fmt2) then item.fn() end
    end
    hidden_heavy_page_tick = (hidden_heavy_page_tick + 1) % HIDDEN_HEAVY_PAGE_TICK_DIVIDER
   
    CMFD1_BRIGHT:set(2^(-10+cmfd_bright[1]*10))
    CMFD2_BRIGHT:set(2^(-10+cmfd_bright[2]*10))

    if cmfd_oss_press_time > 0 and (get_absolute_model_time() - cmfd_oss_press_time) > 0.4 then
        SetCommand(cmfd_oss_press_command, 200)
        cmfd_oss_press_time = 0
    end
end


function post_initialize()
    startup_print("cmfd_right: postinit start")
    update_variant_handles(true)
    
    local birth = LockOn_Options.init_conditions.birth_place
    if birth=="GROUND_HOT" or birth=="AIR_HOT" then
        GetDevice(devices.ELEC_INTERFACE):performClickableAction(device_commands.AviMst, 1)
    end
    dev:performClickableAction(device_commands.CMFD1ButtonOn,1)
    dev:performClickableAction(device_commands.CMFD2ButtonOn,1)

    for k,v in pairs(post_initialize_list) do v() end

    startup_print("environ: postinit end")
end

local CMFD = {{},{}}
CMFD[1]["Number"]          = 1
CMFD[1]["FULL"]            = CMFD1FULL
CMFD[1]["Primary"]         = CMFD1Primary
CMFD[1]["Format"]          = CMFD1Format
CMFD[1]["SelTop"]          = CMFD1SelTop
CMFD[1]["SelLeft"]         = CMFD1SelLeft
CMFD[1]["SelRight"]        = CMFD1SelRight
CMFD[1]["SelTopName"]      = CMFD1SelTopName
CMFD[1]["SelLeftName"]     = CMFD1SelLeftName
CMFD[1]["SelRightName"]    = CMFD1SelRightName
CMFD[1]["Sel"]             = CMFD1Sel
CMFD[1]["On"]              = CMFD1On
CMFD[1]["SwOn"]            = CMFD1SwOn

CMFD[2]["Number"]          = 2
CMFD[2]["FULL"]            = CMFD2FULL
CMFD[2]["Primary"]         = CMFD2Primary
CMFD[2]["Format"]          = CMFD2Format
CMFD[2]["SelTop"]          = CMFD2SelTop
CMFD[2]["SelLeft"]         = CMFD2SelLeft
CMFD[2]["SelRight"]        = CMFD2SelRight
CMFD[2]["SelTopName"]      = CMFD2SelTopName
CMFD[2]["SelLeftName"]     = CMFD2SelLeftName
CMFD[2]["SelRightName"]    = CMFD2SelRightName
CMFD[2]["Sel"]             = CMFD2Sel
CMFD[2]["On"]              = CMFD2On
CMFD[2]["SwOn"]            = CMFD2SwOn


function SetCommand(command,value)
    -- print_message_to_user("cmfd: " ..  command .. "=" .. value)
    if command == device_commands.ATDL_POWER then
        local handler = SetCommand_list[SUB_PAGE_ID.TSD]
        if handler then handler(command, value, nil) end
        return 0
    end
    if command == device_commands.FLIR_POWER_TOGGLE then
        if value == 1 then
            -- Toggle real: o F-5EM inicia ligado, mas o piloto ainda pode
            -- cortar a camera nativa e recuperar o custo do render target.
            local old = (FLIR_PILOT_ENABLED:get() or 0) > 0.5
            local new = old and 0 or 1
            log.info(string.format(
                "F5EM_CMFD_CMD t=%.1f action=flir_power_toggle old=%s new=%s",
                get_absolute_model_time(), tostring(old and 1 or 0), tostring(new)))
            FLIR_PILOT_ENABLED:set(new)
        end
        return 0
    end

    local cmfdnumber = 0
    if command >= device_commands.CMFD1OSS1 and command <= device_commands.CMFD1ButtonBright then 
        cmfdnumber=1
    elseif command >= device_commands.CMFD2OSS1 and command <= device_commands.CMFD2ButtonBright then 
        cmfdnumber=2
    end

    if cmfdnumber > 0 then
        log.info(string.format(
            "F5EM_CMFD_CMD t=%.1f name=%s id=%s value=%.2f cmfd=%s fmt_before=%s",
            get_absolute_model_time(),
            f5em_cmfd_command_name[command] or "UNKNOWN",
            tostring(command),
            tonumber(value) or 0,
            tostring(cmfdnumber),
            tostring(CMFD[cmfdnumber]["Format"]:get() or 0)))
    end

    if command == device_commands.CMFD1OSS1 and value == -100 then -- Salvo Pressed
        CMFD1Format:set(SUB_PAGE_ID.SMS)
        SetCommand_list[SUB_PAGE_ID.SMS](command, value, CMFD[cmfdnumber])
        return 0
    elseif command == device_commands.CMFD1OSS1 and value == -200 then -- E-J Finished
        SetCommand_list[SUB_PAGE_ID.SMS](command, value, CMFD[cmfdnumber])
        CMFD1Format:set(CMFD1Sel:get())
        return 0
    elseif command == device_commands.NAV_INC_FYT or command == device_commands.NAV_DEC_FYT or command == device_commands.NAV_SET_FYT then
        SetCommand_list[SUB_PAGE_ID.NAV](command, value)
        return 0
    elseif command == device_commands.UFCP_DVR then
        -- [Fase 5.2] Encaminha o switch UFCP DVR (REC/STBY/STOP) direto
        -- ao handler do sub-page DVR. Como nao depende do CMFD numero,
        -- chamamos apenas se o handler estiver registrado.
        if SetCommand_list[SUB_PAGE_ID.DVR] ~= nil then
            SetCommand_list[SUB_PAGE_ID.DVR](command, value, nil)
        end
        return 0
    end
    if command == Keys.DisplayMngt then
        if value == 1 then -- Fwd
            CMFDDoi:set(0)
        elseif value == 3 then -- Left
            CMFDDoi:set(1)
        elseif value == 4 then -- Right
            CMFDDoi:set(2)
        end
        return 0
    end

    if command == device_commands.CMFD1ButtonOn or command == device_commands.CMFD2ButtonOn then
        -- Quando se liga o CMFD, as imagens tornam-se visíveis depois de aproximadamente 30 segundos e o seu desempenho é total depois de 5 minutos.
        -- O CMFD liga na hora. Essa lógica acima é do MDP.
        CMFD[cmfdnumber]["SwOn"]:set(value)
    end

    if CMFD[cmfdnumber]["On"]:get() == 0 then return end

    if CMFD[cmfdnumber]["FULL"]:get() == 1
        or CMFD[cmfdnumber]["Format"]:get() == SUB_PAGE_ID.MENU1
        or CMFD[cmfdnumber]["Format"]:get() == SUB_PAGE_ID.MENU2 then
        SetCommandFunc = SetCommand_list[CMFD[cmfdnumber]["Format"]:get()]
        if SetCommandFunc ~= nil then SetCommandFunc(command, value, CMFD[cmfdnumber]) end
    else
        SetCommandFunc = SetCommand_list[CMFD[cmfdnumber]["SelLeft"]:get()]
        if (command >= device_commands.CMFD1OSS21 and command <= device_commands.CMFD1OSS28) or (command >= device_commands.CMFD2OSS21 and command <= device_commands.CMFD2OSS28) then 
            if SetCommandFunc ~= nil then SetCommandFunc(command, value, CMFD[cmfdnumber]) end
        end
        SetCommandFunc = SetCommand_list[CMFD[cmfdnumber]["SelRight"]:get()]
        if (command >= device_commands.CMFD1OSS12 and command <= device_commands.CMFD1OSS14) or (command >= device_commands.CMFD2OSS12 and command <= device_commands.CMFD2OSS14) then 
            if SetCommandFunc ~= nil then SetCommandFunc(command, value, CMFD[cmfdnumber]) end
        end
        SetCommandFunc = SetCommand_list[CMFD[cmfdnumber]["Format"]:get()]
        local tsd_clear_cmd = (CMFD[cmfdnumber]["Format"]:get() == SUB_PAGE_ID.TSD)
            and (command == device_commands.CMFD1OSS12 or command == device_commands.CMFD2OSS12)
        if (command >= device_commands.CMFD1OSS2 and command <= device_commands.CMFD1OSS11) or (command >= device_commands.CMFD2OSS2 and command <= device_commands.CMFD2OSS11) or (command >= device_commands.CMFD1OSS24 and command <= device_commands.CMFD1OSS28) or (command >= device_commands.CMFD2OSS24 and command <= device_commands.CMFD2OSS28) or tsd_clear_cmd then 
            if SetCommandFunc ~= nil then SetCommandFunc(command, value, CMFD[cmfdnumber]) end
        end
    end

    if command == device_commands.CMFD1ButtonBright or command == device_commands.CMFD2ButtonBright then
        if value == -1 then
            cmfd_bright[cmfdnumber] = cmfd_bright[cmfdnumber] - 0.1
            if cmfd_bright[cmfdnumber] < 0 then cmfd_bright[cmfdnumber] = 0 end
        elseif value == 1 then
            cmfd_bright[cmfdnumber] = cmfd_bright[cmfdnumber] + 0.1
            if cmfd_bright[cmfdnumber] > 1 then cmfd_bright[cmfdnumber] = 1 end
        end
    end

    if value == 1 then
        -- print_message_to_user("CMFD: command "..tostring(command).." = "..tostring(value) .. " Tela=" .. tostring(CMFD["Selected"]))
        cmfd_oss_press_time = get_absolute_model_time()
        cmfd_oss_press_command = command

        if command == device_commands.CMFD1OSS1 or command == device_commands.CMFD2OSS1 then
        elseif command == device_commands.CMFD1OSS15 or command == device_commands.CMFD2OSS15 then
            if is_fixed_full_page(CMFD[cmfdnumber]["Format"]:get()) then
                CMFD[cmfdnumber]["FULL"]:set(1)
            else
                CMFD[cmfdnumber]["FULL"]:set((CMFD[cmfdnumber]["FULL"]:get()+1)%2)
            end
        elseif command == device_commands.CMFD1OSS16 or command == device_commands.CMFD2OSS16 then
        elseif command == device_commands.CMFD1OSS19 or command == device_commands.CMFD2OSS19 then
        elseif command == device_commands.CMFD1OSS17 or command == device_commands.CMFD2OSS17 then
            local temp

            temp = CMFD1SelTop:get()
            CMFD1SelTop:set(CMFD2SelTop:get())
            CMFD1SelTopName:set(SUB_PAGE_NAME[CMFD1SelTop:get()])
            CMFD2SelTop:set(temp)
            CMFD2SelTopName:set(SUB_PAGE_NAME[temp])

            temp = CMFD1SelLeft:get()
            CMFD1SelLeft:set(CMFD2SelLeft:get())
            CMFD1SelLeftName:set(SUB_PAGE_NAME[CMFD1SelLeft:get()])
            CMFD2SelLeft:set(temp)
            CMFD2SelLeftName:set(SUB_PAGE_NAME[temp])

            temp = CMFD1SelRight:get()
            CMFD1SelRight:set(CMFD2SelRight:get())
            CMFD1SelRightName:set(SUB_PAGE_NAME[CMFD1SelRight:get()])
            CMFD2SelRight:set(temp)
            CMFD2SelRightName:set(SUB_PAGE_NAME[temp])

            temp = CMFD1FULL:get()
            CMFD1FULL:set(CMFD2FULL:get())
            CMFD2FULL:set(temp)

            CMFD1Format:set(CMFD1SelTop:get())
            CMFD2Format:set(CMFD2SelTop:get())
        elseif command == device_commands.CMFD1OSS18 or command == device_commands.CMFD2OSS18 then
        elseif command == device_commands.CMFD1OSS20 or command == device_commands.CMFD2OSS20 then
        elseif command == device_commands.CMFD1ButtonOn or command == device_commands.CMFD2ButtonOn then
            cmfd_oss_press_time = 0
            cmfd_oss_press_command = 0
        end
    elseif value == 0 then
        if cmfd_oss_press_time > 0 then
            if command == device_commands.CMFD1OSS1 or command == device_commands.CMFD2OSS1 then
                CMFDDoi:set(cmfdnumber)
            elseif command == device_commands.CMFD1OSS16 or command == device_commands.CMFD2OSS16 then
                local temp = CMFD[cmfdnumber]["SelTop"]:get()
                CMFD[cmfdnumber]["SelTop"]:set(CMFD[cmfdnumber]["SelRight"]:get())
                CMFD[cmfdnumber]["SelTopName"]:set(CMFD[cmfdnumber]["SelRightName"]:get())
                CMFD[cmfdnumber]["SelRight"]:set(temp)
                CMFD[cmfdnumber]["SelRightName"]:set(SUB_PAGE_NAME[temp])
                CMFD[cmfdnumber]["Format"]:set(CMFD[cmfdnumber]["SelTop"]:get())
            elseif command == device_commands.CMFD1OSS19 or command == device_commands.CMFD2OSS19 then
                local temp = CMFD[cmfdnumber]["SelTop"]:get()
                CMFD[cmfdnumber]["SelTop"]:set(CMFD[cmfdnumber]["SelLeft"]:get())
                CMFD[cmfdnumber]["SelTopName"]:set(CMFD[cmfdnumber]["SelLeftName"]:get())
                CMFD[cmfdnumber]["SelLeft"]:set(temp)
                CMFD[cmfdnumber]["SelLeftName"]:set(SUB_PAGE_NAME[temp])
                CMFD[cmfdnumber]["Format"]:set(CMFD[cmfdnumber]["SelTop"]:get())
            elseif command == device_commands.CMFD1OSS20 or command == device_commands.CMFD2OSS20 then
                -- OSS20 "IND" opens MENU1 (indicator page picker).
                local menu_cmd = (cmfdnumber == 1) and device_commands.CMFD1OSS1 or device_commands.CMFD2OSS1
                if SetCommand_list[SUB_PAGE_ID.MENU1] ~= nil then
                    SetCommand_list[SUB_PAGE_ID.MENU1](menu_cmd, 100, CMFD[cmfdnumber])
                end
            end
        end
        cmfd_oss_press_time = 0
        cmfd_oss_press_command = 0
    elseif value == 200 then
        if command == device_commands.CMFD1OSS1 or command == device_commands.CMFD2OSS1 then
            SetCommand_list[SUB_PAGE_ID.MENU1](command,100,CMFD[cmfdnumber])
        elseif command == device_commands.CMFD1OSS16 or command == device_commands.CMFD2OSS16 then
            SetCommand_list[SUB_PAGE_ID.MENU1](command,100,CMFD[cmfdnumber])
        elseif command == device_commands.CMFD1OSS19 or command == device_commands.CMFD2OSS19 then
            SetCommand_list[SUB_PAGE_ID.MENU1](command,100,CMFD[cmfdnumber])
        elseif command == device_commands.CMFD1OSS20 or command == device_commands.CMFD2OSS20 then
            local menu_cmd = (cmfdnumber == 1) and device_commands.CMFD1OSS1 or device_commands.CMFD2OSS1
            SetCommand_list[SUB_PAGE_ID.MENU1](menu_cmd,100,CMFD[cmfdnumber])
        end
    end
end

dev:listen_event("WeaponRearmComplete")
dev:listen_event("ReloadDone")
dev:listen_event("RefuelDone")

-- dev:listen_event("WeaponRearmFirstStep")
-- dev:listen_event("GroundPowerOn")
-- dev:listen_event("GroundPowerOff")
-- dev:listen_event("DisableTurboGear")
-- dev:listen_event("EnableTurboGear")
-- dev:listen_event("switch_datalink")
-- dev:listen_event("WeaponRearmSingleStepComplete")
-- dev:listen_event("WheelChocksOn")
-- dev:listen_event("WheelChocksOff")
-- dev:listen_event("setup_HMS")
-- dev:listen_event("setup_NVG")
-- dev:listen_event("LinkNOPtoNet")
-- dev:listen_event("UnlinkNOPfromNet")
-- dev:listen_event("initChaffFlarePayload")
-- dev:listen_event("OnNewNetPlane")
-- dev:listen_event("Repair")
-- dev:listen_event("UnlimitedWeaponStationRestore")
-- dev:listen_event("GroundAirOff")
-- dev:listen_event("GroundAirOn")
-- dev:listen_event("EGI_TurnOff")
-- dev:listen_event("EGI_TurnOn")
-- dev:listen_event("RestoreEGIoperation")
-- dev:listen_event("TISLmodeChange")
-- dev:listen_event("cockpit_release")
-- dev:listen_event("CanopyOpen")
-- dev:listen_event("CanopyClose")
dev:listen_event("refuel")
-- dev:listen_event("refuelcomplete")
-- dev:listen_event("refueldone")
-- dev:listen_event("")
-- dev:listen_event("onRadioMessage")
-- "NetCrewMemberAttach"
-- "NetCrewMemberDetach"
-- "NetCrewMemberTakeControl"
-- "livery_change"


function CockpitEvent(command, val)
    -- val seems to mostly be empty table: {}
    -- log.alert("CockpitEvent event: "..tostring(command).."="..tostring(val))
    -- if val then
    --     local str=dump("event",val)
    --     local lines=strsplit("\n",str)
    --     for k,v in ipairs(lines) do
    --         log.alert(v)
    --     end
    -- end
    -- print_message_to_user("CockpitEvent event: "..tostring(command).."="..tostring(val))
    -- log.alert("CockpitEvent event: "..tostring(command).."="..tostring(val))
    -- if val then
    --     local str=dump("event",val)
    --     local lines=strsplit("\n",str)
    --     for k,v in ipairs(lines) do
    --         log.alert(v)
    --         print_message_to_user(v)
    --     end
    -- end
    if command == "refuel" then 
        fuel_init=round_to(sensor_data.getTotalFuelWeight() + fuel_random,5)
    elseif command == "WeaponRearmComplete" then
        fuel_joker=round_to(fuel_init/2,5)
    else
        log.info("F5EM CMFD CockpitEvent: "..tostring(command).."="..tostring(val))
        if val then
            local str=dump("event",val)
            local lines=strsplit("\n",str)
            for k,v in ipairs(lines) do
                log.info("F5EM CMFD: "..tostring(v))
            end
        end
end
    
end


startup_print("CMFD2: load end")
need_to_be_closed = false -- close lua state after initialization


