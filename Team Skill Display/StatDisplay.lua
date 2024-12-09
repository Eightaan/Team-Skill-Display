local display_time = 8

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
	
Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_Skillinfo", function( loc )
    loc:load_localization_file( Skillinfo._path .. "loc/en.json")
end)
	
Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_Skillinfo", function(menu_manager)
	MenuCallbackHandler.SkillInfo = function(self)
	    MenuCallbackHandler:Skill_Show()
    end
	MenuHelper:LoadFromJsonFile(Skillinfo._path .. "keybind.json", Skillinfo, Skillinfo._data)
end)

function MenuCallbackHandler:Skill_Show()
	if managers.network:session() and Utils:IsInHeist()then
		Skillinfo:Information_To_HUD(managers.network:session():peer(_G.LuaNetworking:LocalPeerID()))
		for _, peer in pairs(managers.network:session():peers()) do
			Skillinfo:Information_To_HUD(peer)
		end
		Skillinfo:InfoPanel()
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
	local skill_string = {}
	if #skills == 15 then
		skill_string = Skillinfo:NumberFormat(skills)
		if perk_deck and completion then
			return string.format("\n M(%02u:%02u:%02u) E(%02u:%02u:%02u) T(%02u:%02u:%02u) G(%02u:%02u:%02u) F(%02u:%02u:%02u) \n %s %s/9", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], skill_string[6], skill_string[7], skill_string[8], skill_string[9], skill_string[10], skill_string[11], skill_string[12], skill_string[13], skill_string[14], skill_string[15], perk_deck, completion)
		else
			return string.format("\n M(%02u:%02u:%02u) E(%02u:%02u:%02u) T(%02u:%02u:%02u) G(%02u:%02u:%02u) F(%02u:%02u:%02u)", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], skill_string[6], skill_string[7], skill_string[8], skill_string[9], skill_string[10], skill_string[11], skill_string[12], skill_string[13], skill_string[14], skill_string[15])
		end
	end
end

-- Adding a function to clear a player's data when they disconnect
function Skillinfo:RemovePlayerData(peer_id)
    -- Check if the peer exists in the Players table
    if Skillinfo.Players[peer_id] then
        -- Reset their skill info
        Skillinfo.Players[peer_id] = {}
        -- Optionally, you can also clear any other relevant data for this player
    end
end

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

function Skillinfo:InfoPanel()
    if not Skillinfo.overlay then
        Skillinfo.overlay = Overlay:newgui():create_screen_workspace() or {}
        Skillinfo.fonttype = tweak_data.menu.pd2_small_font
        Skillinfo.fontsize = tweak_data.menu.pd2_small_font_size
        -- Adjust font size based on resolution
        if RenderSettings.resolution.x >= 800 and RenderSettings.resolution.x < 1024 then
            Skillinfo.fontsize = 14
        elseif RenderSettings.resolution.x >= 1024 and RenderSettings.resolution.x < 1360 then
            Skillinfo.fontsize = 18
        elseif RenderSettings.resolution.x >= 1360 and RenderSettings.resolution.x < 1920 then
            Skillinfo.fontsize = 22
        elseif RenderSettings.resolution.x >= 1920 and RenderSettings.resolution.x < 2560 then
            Skillinfo.fontsize = 28
        else
            Skillinfo.fontsize = 32
        end
        Skillinfo.stats = {}
        local pos = 5
        -- Set up stats display for each player
        for i=1, 4 do
            Skillinfo.stats[i] = Skillinfo.overlay:panel():text{name = "name" .. i, x = - (RenderSettings.resolution.x/2.1) + 0.5 * RenderSettings.resolution.x, y = - (RenderSettings.resolution.y/1) + pos/4 * RenderSettings.resolution.y, font = Skillinfo.fonttype, font_size = Skillinfo.fontsize, color = tweak_data.chat_colors[i], layer = 1}
            pos = pos + 0.3
        end
    end

    -- Display the simplified player stats
    for i=1,4 do
        if Skillinfo.Players[i][3] ~= 0 then
            Skillinfo.stats[i]:set_text(Skillinfo.Players[i][3])  -- Only display the simplified skill data
            Skillinfo.stats[i]:show()
        end
    end

    -- Hide after the display time
    DelayedCalls:Add("Skillinfo:Timed_Remove", display_time, function()
        if Skillinfo.overlay then
            for i=1,4 do
                Skillinfo.stats[i]:hide()
            end
        end
    end)
end