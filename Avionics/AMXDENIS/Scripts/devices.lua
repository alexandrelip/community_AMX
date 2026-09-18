-- Preserve the source suite's numeric namespace; do not instantiate foreign interfaces.
dofile(LockOn_Options.script_path .. "devices_donor.lua")
for name, value in pairs(devices) do devices[name] = value + 64 end
devices.HOST_POWER = 3
devices.HOST_MECHANISMS = 8
devices.HOST_HYDRAULICS = 9
devices.HOST_STARTER = 15
devices.PILOT_INPUT = 60
devices.PADLOCK = 63
return devices