dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."Systems/electric_system_api.lua")

need_to_be_closed = false -- close lua state after initialization

local update_time_step = 0.1 -- 10 Hz; only power and brightness are published
make_default_activity(update_time_step) -- enables call to update

EFI = {
    ON = get_param_handle("EFI_ON"),
    BRIGHT = get_param_handle("EFI_BRIGHT"),
}

local efi_bright = 1
function update()
    EFI.ON:set(get_elec_main_dc_bus_ok() and 1 or 0)
    EFI.BRIGHT:set(efi_bright)
end

function post_initialize()
end


function SetCommand(command,value)
    -- Debug-only: ative habilitando o log nivel INFO do DCS.
    log.info("F5EM efi: " .. tostring(command) .. "=" .. tostring(value))
end

