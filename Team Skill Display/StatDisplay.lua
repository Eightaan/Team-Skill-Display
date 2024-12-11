local fade_duration = 0.4
local fade_steps = 25

if RequiredScript == "lib/managers/menumanager" then
    if not _G.Skillinfo then
        _G.Skillinfo = _G.Skillinfo or {}
        Skillinfo._path = ModPath
        Skillinfo._data = {}
        Skillinfo._data_path = SavePath .. "Skillinfo.txt"
        Skillinfo.Players = {}
        for i=1,4 do
            Skillinfo.Players[i] = {}
            for j=1,9 do
                Skillinfo.Players[i][j] = 0
            end
        end
    end
	
	function Skillinfo:Save()
	    local file = io.open( self._data_path, "w+" )
	    if file then
	    	file:write( json.encode( self._data ) )
	    	file:close()
    	end
    end

    function Skillinfo:Load()
    	local file = io.open( self._data_path, "r" )
    	if file then
    		self._data = json.decode( file:read("*all") )
    		file:close()
    	end
    end
	
	function Skillinfo:GetOption(id)
	    return self._data[id]
    end

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_Skillinfo", function( loc )
		loc:load_localization_file( Skillinfo._path .. "Loc/en.json")
	end)

	Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_Skillinfo", function(menu_manager)
		MenuCallbackHandler.SkillInfo = function(self)
			MenuCallbackHandler:Skill_Show()
		end
		MenuCallbackHandler.callback_detailed_skills = function(self, item)
    		Skillinfo._data.detailed_skills = (item:value() == "on" and true or false)
    		Skillinfo:Save()
    	end
		MenuCallbackHandler.callback_delay_time = function(self, item)
            Skillinfo._data.delay_time = item:value()
		    Skillinfo:Save()
        end
		MenuCallbackHandler.callback_font_size = function(self, item)
            Skillinfo._data.font_size = item:value()
		    Skillinfo:Save()
        end
		MenuCallbackHandler.callback_use_tab = function(self, item)
    		Skillinfo._data.use_tab = (item:value() == "on" and true or false)
    		Skillinfo:Save()
    	end
		Skillinfo:Load()
		MenuHelper:LoadFromJsonFile(Skillinfo._path .. "Options/options.json", Skillinfo, Skillinfo._data)
	end)

	function MenuCallbackHandler:Skill_Show()
		if managers.network:session() and Utils:IsInHeist() then
			Skillinfo:Information_To_HUD(managers.network:session():peer(_G.LuaNetworking:LocalPeerID()))
			for _, peer in pairs(managers.network:session():peers()) do
				Skillinfo:Information_To_HUD(peer)
			end
			Skillinfo:InfoPanel()
		end
	end

    function Skillinfo:FadeEffect(panel, fade_direction, duration, steps)
        local fade_increment = 1 / steps
        for step = 1, steps do
            local alpha_value = fade_direction == "in" and fade_increment * step or 1 - fade_increment * step
            DelayedCalls:Add("Skillinfo:Fade_" .. panel:name() .. "_" .. step, (step - 1) * (duration / steps), function()
                panel:set_alpha(alpha_value)
            end)
        end
    end

	function Skillinfo:NumberFormat(input_data)
		local array = {}
		for i=1,#input_data do
			if tonumber(input_data[i]) < 10 then
				input_data[i] = "0" .. input_data[i]
			end
			table.insert(array, input_data[i])
		end
		return array
	end

	function Skillinfo:Text_Formatting(skills, perk_deck, completion)
		local sk = {}
		local skill_string = {}
		if #skills == 15 then
			if not Skillinfo:GetOption("detailed_skills") then
				sk[1] = skills[1] + skills[2] + skills[3]
				sk[2] = skills[4] + skills[5] + skills[6]
				sk[3] = skills[7] + skills[8] + skills[9]
				sk[4] = skills[10] + skills[11] + skills[12]
				sk[5] = skills[13] + skills[14] + skills[15]
				skill_string = Skillinfo:NumberFormat(sk)
				if perk_deck and completion then
					return string.format("\n|M:%02u|E:%02u|T:%02u|G:%02u|F:%02u| \n %s %s/9", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], perk_deck, completion)
				else
					return string.format("\n|M:%02u|E:%02u|T:%02u|G:%02u|F:%02u|", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5])
				end
			else
				skill_string = Skillinfo:NumberFormat(skills)
				if perk_deck and completion then
					return string.format("\n M|%02u:%02u:%02u| E|%02u:%02u:%02u| T|%02u:%02u:%02u| G|%02u:%02u:%02u| F|%02u:%02u:%02u| \n %s %s/9", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], skill_string[6], skill_string[7], skill_string[8], skill_string[9], skill_string[10], skill_string[11], skill_string[12], skill_string[13], skill_string[14], skill_string[15], perk_deck, completion)
				else
					return string.format("\n M|%02u:%02u:%02u| E|%02u:%02u:%02u| T|%02u:%02u:%02u| G|%02u:%02u:%02u| F|%02u:%02u:%02u|", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], skill_string[6], skill_string[7], skill_string[8], skill_string[9], skill_string[10], skill_string[11], skill_string[12], skill_string[13], skill_string[14], skill_string[15])
				end
			end
		else
			return "invalid data received"
		end
	end

	function Skillinfo:UpdatePanelPositions()
		local pos = 5

		for i = 1, 4 do
			if Skillinfo.Players[i][3] ~= 0 then
				Skillinfo.stats[i]:set_position(
					-(RenderSettings.resolution.x / 2.1) + 0.5 * RenderSettings.resolution.x,
					-(RenderSettings.resolution.y / 1) + pos / 4 * RenderSettings.resolution.y
				)
				pos = pos + 0.3
			end
		end
	end

	function Skillinfo:Information_To_HUD(peer)
		if peer ~= nil then
			if peer:is_outfit_loaded() then
				local skills_perk_deck_info = string.split(peer:skills(), "-") or {}
				if #skills_perk_deck_info == 2 then
					local skills = string.split(skills_perk_deck_info[1], "_")
					local perk_deck = string.split(skills_perk_deck_info[2], "_")
					local perk_deck_id = tonumber(perk_deck[1])
					local p = perk_deck_id < 24 and managers.localization:text("menu_st_spec_" .. perk_deck_id) or "Custom Perk Deck"
					Skillinfo.Players[peer:id()][3] = peer:name() .. Skillinfo:Text_Formatting(skills, p, perk_deck[2])    
				end
			end
		end
	end

	function Skillinfo:InfoPanel()
		if not Skillinfo.overlay then
			Skillinfo.overlay = Overlay:newgui():create_screen_workspace() or {}
			Skillinfo.stats = {}
			local pos = 5

			for i=1, 4 do
				Skillinfo.stats[i] = Skillinfo.overlay:panel():text{
					name = "name" .. i, 
					x = - (RenderSettings.resolution.x/2.1) + 0.5 * RenderSettings.resolution.x, 
					y = - (RenderSettings.resolution.y/1) + pos/4 * RenderSettings.resolution.y, 
					font = tweak_data.menu.pd2_small_font,
					color = tweak_data.chat_colors[i],
					alpha = 0
				}
				pos = pos + 0.3
			end
		end

		Skillinfo:UpdatePanelPositions()

		for i=1, 4 do
			if Skillinfo.Players[i][3] ~= 0 then
				Skillinfo.stats[i]:set_text(Skillinfo.Players[i][3])
				Skillinfo.stats[i]:set_font_size(Skillinfo:GetOption("font_size") or 20)
				Skillinfo.stats[i]:show()
				Skillinfo:FadeEffect(Skillinfo.stats[i], "in", fade_duration, fade_steps)
			end
		end

		local delay_time = Skillinfo:GetOption("delay_time") or 8
		DelayedCalls:Add("Skillinfo:Timed_Remove", delay_time, function()
			for i=1, 4 do
				if Skillinfo.stats[i]:alpha() > 0 then
					Skillinfo:FadeEffect(Skillinfo.stats[i], "out", fade_duration, fade_steps)
				end
			end

			DelayedCalls:Add("Skillinfo:HidePanels", fade_duration, function()
				for i=1, 4 do
					Skillinfo.stats[i]:hide()
				end
			end)
		end)
	end
end

if RequiredScript == "lib/network/base/networkpeer" then
	Hooks:Add("NetworkManagerOnPeerAdded", "Skillinfo:PeerAdded", function()
		Skillinfo:UpdatePanelPositions()
	end)

	Hooks:Add("BaseNetworkSessionOnPeerRemoved", "Skillinfo:PeerRemoved", function(peer, peer_id)
        for j = 1, 9 do
            Skillinfo.Players[peer_id][j] = 0
        end

		for i = 1, 4 do
			if Skillinfo.stats and Skillinfo.stats[i]:alpha() > 0 then
				Skillinfo.stats[i]:hide()
			end
		end

        Skillinfo:UpdatePanelPositions()
	end)
end

if RequiredScript == "lib/managers/hudmanagerpd2" then	
	Hooks:PostHook(HUDManager, "show_stats_screen", "HUDManager_show_stats_screen_skillinfo", function (self)
		if managers.network:session() and Utils:IsInHeist() and Skillinfo:GetOption("use_tab") then
			Skillinfo:Information_To_HUD(managers.network:session():peer(_G.LuaNetworking:LocalPeerID()))
			for _, peer in pairs(managers.network:session():peers()) do
				Skillinfo:Information_To_HUD(peer)
			end
			Skillinfo:InfoPanel()
		end
	end)
	
	Hooks:PostHook(HUDManager, "hide_stats_screen", "HUDManager_hide_stats_screen_skillinfo", function (self)
		if managers.network:session() and Utils:IsInHeist() and Skillinfo:GetOption("use_tab") then
			for i = 1, 4 do
				if Skillinfo.stats and Skillinfo.stats[i]:alpha() > 0 then
					Skillinfo:FadeEffect(Skillinfo.stats[i], "out", fade_duration, fade_steps)
				end
			end
		end
	end)
end