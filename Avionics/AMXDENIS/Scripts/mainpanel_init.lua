shape_name = "AMX_COCKPIT_REV07_184"
is_EDM = true
new_model_format = true
draw_pilot = false
use_external_views = false
use_external_shape = false
external_model_canopy_arg = 38
cockpit_local_point = {2.9698572158813477, 1.3359999656677246, 0}
ambient_light = {255,255,255}
ambient_color_day_texture = {72,100,160}
ambient_color_night_texture = {40,60,150}
ambient_color_from_devices = {50,50,40}
ambient_color_from_panels = {35,25,25}
dusk_border = 0.4
day_texture_set_value = 0
night_texture_set_value = 0.1
controllers = LoRegisterPanelControls()
local controls = dofile(LockOn_Options.script_path .. "Controls/data.lua")
for _, spec in ipairs(controls.controls) do
    if spec.mouse and spec.argument then
        local gauge = CreateGauge("parameter")
        gauge.parameter_name = spec.feedback
        gauge.arg_number = spec.argument
        gauge.input = {spec.minimum, spec.maximum}
        gauge.output = {spec.minimum, spec.maximum}
    end
end
local throttle = CreateGauge()
throttle.arg_number = 5
throttle.input = {0,1}
throttle.output = {0,1}
throttle.controller = controllers.base_gauge_ThrottleLeftPosition
Z_test = {near=0.05, far=4}
need_to_be_closed = true