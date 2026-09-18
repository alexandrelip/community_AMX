-- [F-5EM 2026-07-12] MANR page — Manual Reticle depression (mils).
--
-- Purpose: configura o retículo depressed usado no master mode MAN
-- (backup bombing). Piloto define o angulo de depressao em mils; o
-- HUD_AG.lua desenha uma cruz FIXA no HUD deslocada dessa quantidade
-- abaixo do boresight (parented ao FPM_origin para acompanhar o vetor).
--
-- Backend: publica UFCP_MANR_MILS (0..300 mils). Consumido pelo
-- HUD_AG.lua no bloco HUD_MANR_origin (gated por AVIONICS_MASTER_MODE_ID.MAN).
--
-- Referência: convenção Elbit F-5EM / A-1M (SO5-1F-1). Retículo depressed
-- é o modo de bombardeio de "backup" -- usado quando CCRP/CCIP/DTOS não
-- estão disponíveis (falha do EGI, alvo sem coords, low-level VMC).
--
-- UFCP layout (baseado em ws.lua):
--   MANR
--
--    *xxx*MILS
--
-- Range válido: 0..300 mils (típico F-5EM real ~100-180 mils para Mk-82
-- em level release @ 400 KIAS / 5000 ft).

local UFCP_MANR = get_param_handle("UFCP_MANR_MILS")

-- Inits
ufcp_manr = 100 -- mils, default típico para bomba livre em level release

UFCP_MANR:set(ufcp_manr)

-- Methods

local function ufcp_manr_validate(text, save)
    if text:len() >= ufcp_edit_lim or save then
        local number = tonumber(text)
        if number ~= nil and number >= 0 and number <= 300 then
            ufcp_manr = number
            UFCP_MANR:set(ufcp_manr)

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local FIELD_INFO = {
    [0] = {3, ufcp_manr_validate},
}

local sel = 0
function update_manr()
    local text = ""
    text = text .. "MANR\n\n"

    -- Depression mils
    text = text .. " *"
    if ufcp_edit_pos > 0 then text = text .. ufcp_print_edit(true) else text = text .. string.format("%3d", ufcp_manr) end
    text = text .. "*MILS\n\n"

    if ufcp_edit_pos > 0 then
        text = replace_pos(text, 12)
        text = replace_pos(text, 16)
    end

    UFCP_TEXT:set(text)
end

function SetCommandManr(command, value)
    if command == device_commands.UFCP_1 and value == 1 then
        ufcp_continue_edit("1", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_2 and value == 1 then
        ufcp_continue_edit("2", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_3 and value == 1 then
        ufcp_continue_edit("3", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_4 and value == 1 then
        ufcp_continue_edit("4", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_5 and value == 1 then
        ufcp_continue_edit("5", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_6 and value == 1 then
        ufcp_continue_edit("6", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_7 and value == 1 then
        ufcp_continue_edit("7", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_8 and value == 1 then
        ufcp_continue_edit("8", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_9 and value == 1 then
        ufcp_continue_edit("9", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_0 and value == 1 then
        ufcp_continue_edit("0", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_ENTR and value == 1 then
        ufcp_continue_edit("", FIELD_INFO[sel], true)
    end
end
