obs              = obslua
source_name      = ""
total_seconds    = 0
work_seconds     = 0
break_seconds    = 0
cur_seconds      = 0
cycle	         = 0
last_text        = ""
finish_text      = ""
cycle_text       = 1
break_text       = ""
work_text        = ""
activated        = false
etapes 	         = 1
text_add         = ""
bigbreak_text 	 = ""
bigbreak_seconds = 0
hotkey_id        = obs.OBS_INVALID_HOTKEY_ID

function set_time_text()
	local seconds       = math.floor(cur_seconds % 60)
	local total_minutes = math.floor(cur_seconds / 60)
	local minutes       = math.floor(total_minutes % 60)
	local hours         = math.floor(total_minutes / 60)
	local text          = string.format("%02d:%02d:%02d", hours, minutes, seconds)

	if etapes == 9 then
		if cycle > 0 then
			etapes = 1
			cycle = cycle - 1
			cycle_text = cycle_text + 1
			cur_seconds = work_seconds
			text_add = work_text
		else
			local source = obs.obs_get_source_by_name(source_name)
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", finish_text)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
			obs.remove_current_callback()
		end
	elseif text ~= last_text then
		local source = obs.obs_get_source_by_name(source_name)
		if source ~= nil then
			text2 = string.format("Cycles: %s/%s \n%s \n%s", cycle_text, num_rep, text_add, text)
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", text2)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end
	end
	last_text = text
end


function timer_callback()
	cur_seconds = cur_seconds - 1
	if cur_seconds < 0 then
		if etapes == 1 then
			etapes = etapes + 1
			cur_seconds = break_seconds
			text_add = break_text
		elseif etapes == 2 then
			etapes = etapes + 1
			cur_seconds = work_seconds
			text_add = work_text
		elseif etapes == 3 then
			etapes = etapes + 1
			cur_seconds = break_seconds
			text_add = break_text
		elseif etapes == 4 then
			etapes = etapes + 1
			cur_seconds = work_seconds
			text_add = work_text
		elseif etapes == 5 then
			etapes = etapes + 1
			cur_seconds = break_seconds
			text_add = break_text
		elseif etapes == 6 then
			etapes = etapes + 1
			cur_seconds = work_seconds
			text_add = work_text
		elseif etapes == 7 then
			if cycle <= 0 then
				etapes = etapes + 2
			else
				etapes = etapes + 1
				cur_seconds = bigbreak_seconds
				text_add = bigbreak_text
			end
		elseif etapes == 8 then
			etapes = etapes + 1
			cur_seconds = 0
		end
	end
	set_time_text()
end


function activate(activating)
	if activated == activating then
		return
	end
	activated = activating
	if activating then
		cycle = 0
		cycle_text = 1
		etapes = 1
		bigbreak_seconds = 0
		cur_seconds = work_seconds
		cycle = num_rep - 1
		text_add = work_text
		set_time_text()
		obs.timer_add(timer_callback, 1000)
	else
		obs.timer_remove(timer_callback)
	end
end


function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end


function source_activated(cd)
	activate_signal(cd, true)
end


function source_deactivated(cd)
	activate_signal(cd, false)
end


function reset(pressed)
	if not pressed then
		return
	end
	activate(false)
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
		activate(active)
	end
end


function reset_button_clicked(props, p)
	reset(true)
	return false
end


function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_int(props, "work_duration", "Work duration", 1, 100000, 1)
	obs.obs_properties_add_text(props, "text_work_time", "Work time Text", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_int(props, "break_duration", "Break duration", 1, 100000, 1)
	obs.obs_properties_add_text(props, "text_break_time", "Break time Text", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_int(props, "bigbreak_duration", "Big break duration", 1, 100000, 1)
	obs.obs_properties_add_text(props, "text_bigbreak_time", "Big break time Text", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_int(props, "number_repetition", "Number of cycle", 1, 100000, 1)
	obs.obs_properties_add_text(props, "text_finish", "Finish Text", obs.OBS_TEXT_DEFAULT)
	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)
	obs.obs_properties_add_button(props, "reset_button", "Reset", reset_button_clicked)

	return props
end


function script_description()
	return "Pomodoro Timer.\n \nBy Bov"
end


function script_update(settings)
	activate(false)
	break_seconds = obs.obs_data_get_int(settings, "break_duration") * 60
	work_seconds = obs.obs_data_get_int(settings, "work_duration") * 60
	source_name = obs.obs_data_get_string(settings, "source")
	finish_text = obs.obs_data_get_string(settings, "text_finish")
	break_text = obs.obs_data_get_string(settings, "text_break_time")
	work_text = obs.obs_data_get_string(settings, "text_work_time")
	bigbreak_text = obs.obs_data_get_string(settings, "text_bigbreak_time")
	num_rep = obs.obs_data_get_int(settings, "number_repetition")
	bigbreak_seconds = obs.obs_data_get_int(settings, "bigbreak_duration") * 60

	reset(true)
end


function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "work_duration", 25)
	obs.obs_data_set_default_int(settings, "break_duration", 5)
	obs.obs_data_set_default_string(settings, "text_finish", "It's finish")
	obs.obs_data_set_default_string(settings, "text_work_time", "Work time")
	obs.obs_data_set_default_string(settings, "text_break_time", "Break time")
	obs.obs_data_set_default_int(settings, "number_repetition", 1)
	obs.obs_data_set_default_string(settings, "text_bigbreak_time", "Big break time")
	obs.obs_data_set_default_int(settings, "bigbreak_duration", 15)

end


function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end


function script_load(settings)
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Reset Timer", reset)
	local hotkey_save_array = obs.obs_data_get_array(settings, "reset_hotkey")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end
