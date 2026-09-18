amx_gun_mount_fm = {
		gun_mount("DEFA_554",
		{
			count = 275
		},
		{
			muzzle_pos				= {.155,  -0.635, -0.242},
			muzzle_pos_connector	= "gunPoint2",
			supply_position			= {4.8753, 0, -0.2},	-- approx
			drop_cartridge			= 204,		-- cartridge_50cal
			--ejector_pos_connector	= "ejector_1",
			ejector_dir 			= {-2,0,0},
			effects = {
				{name = "SmokeEffect",gas_deflector_arg = 327  , add_speed = {0, -3, 3}},
			},
		}),			-- LEFT
		gun_mount("DEFA_554",
		{
			count = 275
		},
		{
			muzzle_pos				= {6.155,  -0.635, 0.242},
			muzzle_pos_connector	= "gunPoint1",
			supply_position			= {4.8753, 0,  0.2},	-- approx
			drop_cartridge 			= 204,		-- cartridge_50cal
			--ejector_pos_connector	= "ejector_2",
			ejector_dir 			= {-2,0,0},
			effects = {
				{name = "SmokeEffect",gas_deflector_arg = 328, add_speed = {0,  3, 3}},
			},
		})			-- RIGHT
	}