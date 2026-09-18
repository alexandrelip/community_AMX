dofile(LockOn_Options.script_path .. "command_defs.lua")

local device = GetSelf()
local sensors = get_base_data()
local power = get_param_handle("ELEC_P1")
local fuel_open = get_param_handle("AMX_ENGINE_FUEL_OPEN")
local starter = get_param_handle("AMX_ENGINE_START_SWITCH")
local start_requests = get_param_handle("AMX_ENGINE_START_REQUESTS")
local stop_requests = get_param_handle("AMX_ENGINE_STOP_REQUESTS")
local command_error = get_param_handle("AMX_ENGINE_COMMAND_ERROR")
local start_pending = false

fuel_open:set(1)
starter:set(0)
start_requests:set(0)
stop_requests:set(0)
command_error:set(0)

device:listen_command(device_commands.Button_20)
device:listen_command(device_commands.Button_26)
make_default_activity(0.1)

local function rpm()
	if type(sensors.getEngineLeftRPM) ~= "function" then return nil end
	local ok, value = pcall(sensors.getEngineLeftRPM)
	if ok and type(value) == "number" and value == value and value >= 0 and value < math.huge then return value end
end

local function send(command, counter)
	if type(dispatch_action) ~= "function" then command_error:set(1); return false end
	local ok = pcall(dispatch_action, nil, command, 1)
	command_error:set(ok and 0 or 1)
	if ok then counter:set(counter:get() + 1) end
	return ok
end

function SetCommand(command, value)
	if command == device_commands.Button_26 and (value == 0 or value == 1) then
		if fuel_open:get() == value then return end
		fuel_open:set(value)
		if value == 0 then
			start_pending = false
			send(Keys.iCommandLeftEngineStop, stop_requests)
		end
	elseif command == device_commands.Button_20 and (value == -1 or value == 0 or value == 1) then
		if starter:get() == value then return end
		starter:set(value)
		local rotation = rpm()
		if value == 1 and power:get() == 1 and fuel_open:get() == 1 and rotation and rotation < 53 then
			start_pending = send(Keys.iCommandLeftEngineStart, start_requests)
		elseif value == -1 and start_pending then
			start_pending = false
			send(Keys.iCommandLeftEngineStop, stop_requests)
		end
	end
end

function update()
	local rotation = rpm()
	if rotation and rotation >= 53 then start_pending = false end
end

function post_initialize()
	device:performClickableAction(device_commands.Button_20, 0, true)
	device:performClickableAction(device_commands.Button_26, 1, true)
end

need_to_be_closed = false