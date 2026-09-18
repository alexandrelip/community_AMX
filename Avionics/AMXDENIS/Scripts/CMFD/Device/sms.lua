-- M1 SMS indication is read-only, and uses seven ORIGINAL descriptor stations.
function update_sms()
    get_param_handle("SMS_ON"):set(get_elec_essential_dc_bus_ok() and get_sms_master_on() and 1 or 0)
end
register_as_cmfd_item(SUB_PAGE_ID.SMS, nil, update_sms, function() return false end)