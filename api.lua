modRespawn = {}

if minetest.setting_getbool("gohome_eatdust")~=true then
	minetest.setting_set("gohome_eatdust","false")
end

minetest.register_privilege("gohome", "O jogador pode teleportar para o seu respawn.")

modRespawn.doWayPoint = function(player)
	if player~= nil and player:is_player() then
	
		lunogauges.huds.gaugehp[player:get_player_name()].bg = player:hud_add({
			hud_elem_type = "statbar",
			position = {x=0.5,y=1},
			size = {x=32, y=32}, --{x=24, y=24},
			text = "hud_heart_bg.png",
			number = 20,
			alignment = {x=-1,y=-1},
			offset = {x=-330, y=-97}, --{x=-215, y=-97},
		})
	
		if not ctf.hud:exists(player, hud) then
			ctf.hud:add(player, hud, {
				hud_elem_type = "waypoint",
				name = flag_name,
				number = color,
				world_pos = {
					x = flag.x,
					y = flag.y,
					z = flag.z
				}
			})
		end
	end
end

modRespawn.on_newplayer = function(player)
	if player ~= nil and player:is_player() then
		local playername = player:get_player_name()
		local toPos = modsavevars.getGlobalValue("posRespawnAll") --Retorna um string de cooredenada se existir, cado nao retorna ''.
		if toPos and toPos~="" then
			toPos = minetest.string_to_pos(toPos)
			if toPos and type(toPos)=="table" and toPos.x and toPos.y and toPos.z then
				player:setpos(toPos) --Favor nao por som antes do player ser instaciado no servidor
				minetest.log('action',"[RESPAWNALL] Novo jogador '"..playername.."' nasceu em '"..dump(toPos).."'...")
				return true --Tem q dar retorno ou nao vai funcionar.
			else
				minetest.log('error',"[RESPAWNALL:ERROR] modRespawn.on_newplayer(player='"..playername.."')] toPos='"..dump(toPos).."'")
			end
		else
			minetest.log('error',"[RESPAWNALL:ERROR] modRespawn.on_newplayer(player='"..playername.."')] Variavel 'toPos' nao definida!!")
		end
	else
		minetest.log('error',"[RESPAWNALL:ERROR] modRespawn.on_newplayer(player='???????')] Erro => Variavel 'player' nao foi declarada.")
	end
	return false
end

modRespawn.getRespawnPlayer = function(playername)
	local posRespawn = modsavevars.getCharValue(playername, "posRespawn")
	if posRespawn and posRespawn~="" then
		return minetest.string_to_pos(posRespawn)
	end
end

modRespawn.getRespawnAll = function()
	local posRespawnAll = modsavevars.getGlobalValue("posRespawnAll")
	if posRespawnAll and posRespawnAll~="" then
		return minetest.string_to_pos(posRespawnAll)
	end
end

modRespawn.getRespawnRandom = function()
	local newpos = {
		x = math.random(-1000,1000),
		y = 0,
		z = math.random(-1000,1000)
	}
	--for _, player in ipairs(minetest.get_connected_players()) do
	repeat
		newpos.y = newpos.y + 1
		local nodename1 = minetest.env:get_node(newpos).name
		local nodename2 = minetest.env:get_node({x=newpos.x,y=newpos.y+1,z=newpos.z}).name
		--print("############################# C"..minetest.pos_to_string(newpos)..".name = '"..dump(nodename1).."' D"..minetest.pos_to_string({x=newpos.x,y=newpos.y+1,z=newpos.z})..".name = '"..dump(nodename2).."' ")
	until ((nodename1=="air" or nodename1=="ignore") and (nodename2=="air" or nodename2=="ignore")) or newpos.y>=40
	return newpos
end

modRespawn.getPosShotString = function(pos)
	if pos and pos.x and pos.y and pos.z then
		pos.x = math.floor(pos.x)
		pos.y = math.floor(pos.y)
		pos.z = math.floor(pos.z)
		return minetest.pos_to_string(pos)
	else
		return "ERRO"
	end
end

modRespawn.setPosForced = function(player, pos)
	local try = 0 --tentativas
	repeat
		if try >= 40 then
			local playername = player:get_player_name()
			minetest.log('action',"[LIB_RESPAWNALL] O jogador '"..playername.."' foi chutado por possuir muita lantencia de conexão!")
			minetest.kick_player(playername, " Chutado por latencia em sua conexão!!!")
			return false
		end
		try = try + 1
		player:setpos(pos) --Favor nao por som antes do player ser instaciado no servidor
	until (player:getpos().x==pos.x and player:getpos().z==pos.z)
end

modRespawn.on_respawnplayer = function(player)
	if player ~= nil and player:is_player() then
		local playername = player:get_player_name()
		--print("[modRespawn/on_command_respawnall.lua ==> (modRespawn.on_respawnplayer(player='"..playername.."'))]")
		local posRespawn = modRespawn.getRespawnPlayer(playername)
		local posRespawnAll = modRespawn.getRespawnAll()
		
		if posRespawn then
			player:setpos(posRespawn)
			minetest.log('action',"[RESPAWNALL] "..playername.." renasceu no carpete em '"..modRespawn.getPosShotString(posRespawn).."'.")
			minetest.chat_send_all(playername.." renasceu no carpete em '"..modRespawn.getPosShotString(posRespawn).."'.")
			return true
		elseif posRespawnAll then
			player:setpos(posRespawnAll)
			minetest.log('action',"[RESPAWNALL] "..playername.." renasceu no respawn principal.")
			minetest.chat_send_all(playername.." renasceu no respawn principal.")
			return true
		else
			local posRandom = modRespawn.getRespawnRandom()
			modRespawn.setPosForced(player, posRandom)
			minetest.log('action',"[RESPAWNALL] "..playername.." renasceu aleatoriamente em '"..modRespawn.getPosShotString(posRandom).."'.")
			minetest.chat_send_all(playername.." renasceu aleatoriamente em '"..modRespawn.getPosShotString(posRandom).."'.")
			return true
		end
	else
		minetest.log('error',"[RESPAWNALL:ERRO] modRespawn.on_respawnplayer(player) ==> Variavel 'player' nao foi declarada.")
	end
	return false
end

modRespawn.setRespawnAll = function(playername) --name=nome do admin
	if playername~=nil and playername~="" then
		local player = minetest.get_player_by_name(playername)
		if player ~= nil and player:is_player() then --Verifica de o player esta online
			local posRespawnAll = player:getpos()
			modsavevars.setGlobalValue("posRespawnAll", minetest.pos_to_string(posRespawnAll))
			minetest.chat_send_player(playername, "Todos os jogadores renascerao em "..minetest.pos_to_string(posRespawnAll)..".", false)
			return true -- Handled chat message
		else
			minetest.log('error',"[RESPAWNALL:ERROR] modRespawn.setRespawnAll(playername='"..playername.."')] O jogador precisa esta online para configurar o Respawn principal.")
		end
	else
		minetest.log('error',"[RESPAWNALL:ERROR] modRespawn.setRespawnAll(playername='?????')] Variavel 'playername' nao foi definida.")
	end
end

modRespawn.goHome = function(playername)
	if playername~=nil and playername~="" then
		local player = minetest.get_player_by_name(playername)
		if player ~= nil and player:is_player() then
			if minetest.check_player_privs(playername, {gohome=true}) then
				local pos = player:getpos()

				local consumir = "lunorecipes:magicdust"
				local posRespawn = modsavevars.getCharValue(playername, "posRespawn")
				local posRespawnAll = modsavevars.getGlobalValue("posRespawnAll")
				local toPos = nil
	
				local item = player:get_wielded_item()
				if not minetest.setting_getbool("gohome_eatdust") or minetest.get_modpath("lunorecipes")==nil or item:get_name() == consumir then
					if posRespawn~=nil and posRespawn~="" then
						toPos = minetest.string_to_pos(posRespawn)
					elseif posRespawnAll~=nil and posRespawnAll~="" then
						toPos = minetest.string_to_pos(posRespawnAll)
					end

					if pos~=nil and toPos~=nil then
						--minetest.sound_play("sfx_teleporte", {pos=pos, max_hear_distance = 10}) --toca som "sfx_teleporte".ogg a distancia de 10 blocos do usuario.
						player:setpos(toPos)
						--minetest.sound_play("sfx_teleporte", {pos=toPos, max_hear_distance = 10}) --toca som "sfx_teleporte".ogg a distancia de 10 blocos do usuario.
			
						if 
							minetest.setting_getbool("gohome_eatdust")
							and minetest.get_modpath("lunomobs")~=nil
							and not minetest.setting_getbool("creative_mode") 
							--and not minetest.check_player_privs(playername, {server=true}) 
						then
							item:take_item()
							player:set_wielded_item(item)
						end
						--local inv=player:get_inventory()
						--inv=minetest.get_inventory({type="player",name=player:get_player_name()})
				  		--inv:remove_item("main",ItemStack(consumir))

						return true
					else
						minetest.log('error',"[RESPAWNALL:ERROR] modRespawn.goHome(playername='"..playername.."')")
					end
				else
					minetest.chat_send_player(playername, "Voce precisa segurar um 'Po Encantado' para executar esse comando.")
					minetest.sound_play("sfx_falha", {object=player, max_hear_distance = 10}) --toca som "sfx_teleporte".ogg a distancia de 10 blocos do usuario.
				end
			else
				minetest.chat_send_player(playername, "Voce nao possui o privilegio para este comando.")
				minetest.sound_play("sfx_falha", {object=player, max_hear_distance = 10}) --toca som "sfx_teleporte".ogg a distancia de 10 blocos do usuario.
			end
		else
			minetest.log('error',"[RESPAWNALL:ERROR] modRespawn.goHome(playername='"..playername.."') <== player de gohome invalido.")
		end
	else
		print("Erro => nao foi declarado o nome no modRespawn.goHome('????????').")
		minetest.log('error',"[RESPAWNALL:ERROR] modRespawn.goHome(playername='????????') <== playername nao declarado!")
	end
end

modRespawn.showAjuda = function(playername)
	minetest.chat_send_player(playername, "    ", false)
	minetest.chat_send_player(playername, "############################################################################################", false)
	minetest.chat_send_player(playername, "### LIB_RESPAWNALL (TELA DE AJUDA DESTE MODING)                                                ###", false)
	minetest.chat_send_player(playername, "### Desenvolvedor:'Lunovox Heavenfinder'<rui.gravata@gmail.com>                          ###", false)
	minetest.chat_send_player(playername, "############################################################################################", false)
	minetest.chat_send_player(playername, "   * /sra", false)
	minetest.chat_send_player(playername, "   * /setrespawnall", false)
	minetest.chat_send_player(playername, "       -> Configura local de renascimento de todos os jogadores.", false)
	minetest.chat_send_player(playername, "          (Necessita de privilegio 'server')", false)
	minetest.chat_send_player(playername, "   * /gohome", false)
	minetest.chat_send_player(playername, "       -> Teleporta a si mesmo ate seu respawn individual ou ate o respawn publico.", false)
	minetest.chat_send_player(playername, "          (Necessita de privilegio 'gohome')", false)
	minetest.chat_send_player(playername, "############################################################################################", false)
	minetest.chat_send_player(playername, playername..", precione F10 e use a rolagem do mouse para ler todo este tutorial!!!", false)
end

--##############################################################################################################################

minetest.register_on_newplayer(function(player)
	return modRespawn.on_newplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	return modRespawn.on_respawnplayer(player)
end)

minetest.register_chatcommand("setrespawnall", {
	params = "",
	description = "Grava local de renascimento de todos os jogadores do servidor.",
	privs = {server=true},
	func = function(playername, param)
		modRespawn.setRespawnAll(playername)
	end,
})

minetest.register_chatcommand("sra", {
	params = "",
	description = "Grava local de renascimento de todos os jogadores do servidor.",
	privs = {server=true},
	func = function(playername, param)
		modRespawn.setRespawnAll(playername)
	end,
})

minetest.register_chatcommand("gohome", {
	params = "",
	description = "Teletransporta o jogador para o seu ponto de respawn.",
	privs = {gohome=true},
	func = function(playername, param)
		modRespawn.goHome(playername)
	end,
})

minetest.register_chatcommand("return", {
	params = "",
	description = "Teletransporta o jogador para o seu ponto de respawn.",
	privs = {gohome=true},
	func = function(playername, param)
		modRespawn.goHome(playername)
	end,
})

minetest.register_chatcommand("lib_respawnall", {
	params = "",
	description = "Exibe todos os comando deste mod",
	privs = {},
	func = function(playername, param)
		modRespawn.showAjuda(playername)
	end,
})

minetest.register_chatcommand("respawnall", {
	params = "",
	description = "Exibe todos os comando deste mod",
	privs = {},
	func = function(playername, param)
		modRespawn.showAjuda(playername)
	end,
})
