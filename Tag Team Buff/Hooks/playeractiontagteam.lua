PlayerAction.TagTeam = {
	Priority = 1,
	Function = function (tagged, owner)
		local base_values = managers.player:upgrade_value("player", "tag_team_base")
		local cooldown_drain = managers.player:upgrade_value("player", "tag_team_cooldown_drain")
		local absorption_bonus = managers.player:has_category_upgrade("player", "tag_team_damage_absorption") and managers.player:upgrade_value("player", "tag_team_damage_absorption")
		local timer = TimerManager:game()
		local end_time = timer:time() + base_values.duration
        local end_cd_time = timer:time() + (5 * base_values.duration)
		local absorption = 0
		local absorption_key = {}
		local on_damage_key = {}
		local on_damage_cooldown_key = {}
		--addition
		local on_throwable_key = {}

		-- Lines 18-21
		local function update_ability_radial()
			local time_left = end_time - timer:time()

			managers.hud:activate_teammate_ability_radial(HUDManager.PLAYER_PANEL, time_left, base_values.duration)
		end

		-- Lines 23-38
		local function on_damage(damage_info)
			local was_killed = damage_info.result.type == "death"
			local valid_player = damage_info.attacker_unit == owner or damage_info.attacker_unit == tagged

			if was_killed and valid_player then
				end_time = math.min(end_time + base_values.kill_extension, timer:time() + base_values.duration)

				update_ability_radial()
				owner:character_damage():restore_health(base_values.kill_health_gain, true)

				if absorption_bonus then
					absorption = absorption + absorption_bonus.kill_gain
					absorption = math.min(absorption, absorption_bonus.max)

					managers.player:set_damage_absorption(absorption_key, absorption)
				end
			end
		end

		-- Lines 40-46
		local function on_damage_cooldown(damage_info)
			local was_killed = damage_info.result.type == "death"
			local valid_player = damage_info.attacker_unit == owner or damage_info.attacker_unit == tagged

			if was_killed and valid_player then
				managers.player:speed_up_grenade_cooldown(damage_info.attacker_unit == owner and cooldown_drain.owner or cooldown_drain.tagged)
			end
		end

		CopDamage.register_listener(on_damage_key, {
			"on_damage"
		}, on_damage)
		CopDamage.register_listener(on_damage_cooldown_key, {
			"on_damage"
		}, on_damage_cooldown)
		managers.network:session():send_to_peers("sync_tag_team", tagged, owner)
		update_ability_radial()

		while alive(owner) and timer:time() < end_time do
			coroutine.yield()
		end

		CopDamage.unregister_listener(on_damage_key)
		managers.network:session():send_to_peers("end_tag_team", tagged, owner)

		tagged = nil

		--addition, added fixed cooldown time that begins after effect duration ends
		local end_cd_time = timer:time() + (5 * base_values.duration)
		local function on_throwable()
			end_cd_time = timer:time()
		end
		--register an event listener in playerstandard, listens to throwable keybind
		--will reduce fixed cooldown time to now
		PlayerStandard.register_listener(on_throwable_key, {
			"on_throwable"
		}, on_throwable)

		--addition, wait till fixed cooldown time ends
		while (alive(owner) and timer:time() < end_cd_time) do
			coroutine.yield()
		end

		--addition, unregister the event listener
		PlayerStandard.unregister_listener(on_throwable_key)

		while not managers.player:got_max_grenades() do
			coroutine.yield()
		end
		CopDamage.unregister_listener(on_damage_cooldown_key)
		managers.player:set_damage_absorption(absorption_key, nil)
	end
}
