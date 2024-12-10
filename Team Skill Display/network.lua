if RequiredScript == "lib/network/base/networkpeer" then

	Hooks:Add("NetworkManagerOnPeerAdded", "NoobJoin:PeerAdded", function(peer, peer_id)
	end)

	Hooks:Add("BaseNetworkSessionOnPeerRemoved", "NoobJoin:PeerRemoved", function(peer, peer_id, ...)
		for j=1,9 do -- Skill printed, cheater, skills for overlay, join time, hours played
			Skillinfo.Players[peer_id][j] = 0
		end
	end)
end