if RequiredScript == "lib/managers/menumanager" then
	-- Display time for the overlay
	local display_time = 8
	-- Detalied skill display - toggle
	local detailed = false
	
	local Skillinfo.fontsize = 15

	-- Init
	if not _G.Skillinfo then
		_G.Skillinfo = _G.Skillinfo or {}
		Skillinfo._path = ModPath
		Skillinfo._data = {} 
		Skillinfo.Players = {}
		for i=1,4 do
			Skillinfo.Players[i] = {}
			for j=1,9 do
				Skillinfo.Players[i][j] = 0
			end
		end
	end

	--Keybind options menu localization
	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_Skillinfo", function( loc )
		loc:load_localization_file( Skillinfo._path .. "loc/en.json")
	end)

	--Keybind Setup
	Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_Skillinfo", function(menu_manager)
		MenuCallbackHandler.SkillInfo = function(self)
			MenuCallbackHandler:Skill_Show()
		end
		MenuHelper:LoadFromJsonFile(Skillinfo._path .. "keybind.json", Skillinfo, Skillinfo._data)
	end)

	--Callback for the overlay keybind
	function MenuCallbackHandler:Skill_Show()
		if managers.network:session() and Utils:IsInHeist() then
			Skillinfo:Information_To_HUD(managers.network:session():peer(_G.LuaNetworking:LocalPeerID()))
			for _, peer in pairs(managers.network:session():peers()) do
				Skillinfo:Information_To_HUD(peer)
			end
			Skillinfo:InfoPanel()
		end
	end

	--Skill formating
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
			if not detailed then --Setting
				sk[1] = skills[1] + skills[2] + skills[3] -- Mastermind
				sk[2] = skills[4] + skills[5] + skills[6] -- Enforcer
				sk[3] = skills[7] + skills[8] + skills[9] -- Technician
				sk[4] = skills[10] + skills[11] + skills[12] -- Ghost
				sk[5] = skills[13] + skills[14] + skills[15] -- Fugitive
				skill_string = Skillinfo:NumberFormat(sk)
				if perk_deck and completion then
					return string.format("\n|%02u:%02u:%02u:%02u:%02u| \n %s %s/9", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], perk_deck, completion)
				else
					return string.format("\n|%02u:%02u:%02u:%02u:%02u|", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5])
				end
			else
				skill_string = Skillinfo:NumberFormat(skills)
				if perk_deck and completion then
					return string.format("\n M(%02u:%02u:%02u) E(%02u:%02u:%02u) T(%02u:%02u:%02u) G(%02u:%02u:%02u) F(%02u:%02u:%02u) \n %s %s/9", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], skill_string[6], skill_string[7], skill_string[8], skill_string[9], skill_string[10], skill_string[11], skill_string[12], skill_string[13], skill_string[14], skill_string[15], perk_deck, completion)
				else
					return string.format("\n M(%02u:%02u:%02u) E(%02u:%02u:%02u) T(%02u:%02u:%02u) G(%02u:%02u:%02u) F(%02u:%02u:%02u)", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], skill_string[6], skill_string[7], skill_string[8], skill_string[9], skill_string[10], skill_string[11], skill_string[12], skill_string[13], skill_string[14], skill_string[15])
				end
			end
		else
			return "invalid data received"
		end
	end
	
	-- Function to update the positions of skill panels
	function Skillinfo:UpdatePanelPositions()
		local pos = 5  -- Starting position for the first panel

		-- Loop through all the players and update their panel positions
		for i = 1, 4 do
			if Skillinfo.Players[i][3] ~= 0 then  -- Check if there's skill data for this player (i.e., the player is active)
				-- Update the position of the player's skill panel
				Skillinfo.stats[i]:set_position(
					-(RenderSettings.resolution.x / 2.1) + 0.5 * RenderSettings.resolution.x,
					-(RenderSettings.resolution.y / 1) + pos / 4 * RenderSettings.resolution.y
				)
				pos = pos + 0.3  -- Move the position for the next player's panel
			end
		end
	end

	--Skill Information
	function Skillinfo:Information_To_HUD(peer)
		if peer ~= nil then
			if peer:is_outfit_loaded() then
				local skills_perk_deck_info = string.split(peer:skills(), "-") or {}
				if #skills_perk_deck_info == 2 then
					local skills = string.split(skills_perk_deck_info[1], "_")
					local perk_deck = string.split(skills_perk_deck_info[2], "_")
					local p = managers.localization:text("menu_st_spec_" .. perk_deck[1])

					-- Simplified stats display: just store the name and simplified skill data
					Skillinfo.Players[peer:id()][3] = peer:name() .. Skillinfo:Text_Formatting(skills, p, perk_deck[2])    
				end
			end
		end
	end

	--Overlay display
	function Skillinfo:InfoPanel()
		if not Skillinfo.overlay then
			Skillinfo.overlay = Overlay:newgui():create_screen_workspace() or {}
		--	Skillinfo.fontsize = tweak_data.menu.pd2_small_font_size
			-- Adjust font size based on resolution
			-- if RenderSettings.resolution.x >= 800 and RenderSettings.resolution.x < 1024 then
				-- Skillinfo.fontsize = 14
			-- elseif RenderSettings.resolution.x >= 1024 and RenderSettings.resolution.x < 1360 then
				-- Skillinfo.fontsize = 18
			-- elseif RenderSettings.resolution.x >= 1360 and RenderSettings.resolution.x < 1920 then
				-- Skillinfo.fontsize = 22
			-- elseif RenderSettings.resolution.x >= 1920 and RenderSettings.resolution.x < 2560 then
				-- Skillinfo.fontsize = 28
			-- else
				-- Skillinfo.fontsize = 32
			-- end
			Skillinfo.stats = {}
			local pos = 5
			-- Set up stats display for each player
			for i=1, 4 do
				Skillinfo.stats[i] = Skillinfo.overlay:panel():text{
					name = "name" .. i, 
					x = - (RenderSettings.resolution.x/2.1) + 0.5 * RenderSettings.resolution.x, 
					y = - (RenderSettings.resolution.y/1) + pos/4 * RenderSettings.resolution.y, 
					font = tweak_data.menu.pd2_small_font,
					font_size = Skillinfo.fontsize, -- Setting
					color = tweak_data.chat_colors[i], 
					layer = 1
				}
				pos = pos + 0.3
			end
		end
		
		Skillinfo:UpdatePanelPositions()

		-- Display the simplified player stats
		for i=1,4 do
			if Skillinfo.Players[i][3] ~= 0 then
				Skillinfo.stats[i]:set_text(Skillinfo.Players[i][3])  -- Only display the simplified skill data
				Skillinfo.stats[i]:show()
			end
		end

		-- Hide after the display time
		DelayedCalls:Add("Skillinfo:Timed_Remove", display_time, function() --Setting
			if Skillinfo.overlay then
				for i=1,4 do
					Skillinfo.stats[i]:hide()
				end
			end
		end)
	end
end

if RequiredScript == "lib/network/base/networkpeer" then
	Hooks:Add("NetworkManagerOnPeerAdded", "Skillinfo:PeerAdded", function()
		Skillinfo:UpdatePanelPositions()  -- Recalculate and update the positions of all skill
	end)

	Hooks:Add("BaseNetworkSessionOnPeerRemoved", "Skillinfo:PeerRemoved", function(peer, peer_id)
		for j=1,9 do -- Skill printed, cheater, skills for overlay, join time, hours played
			Skillinfo.Players[peer_id][j] = 0
		end
		Skillinfo:UpdatePanelPositions()  -- Recalculate and update the positions of all skill
	end)
end