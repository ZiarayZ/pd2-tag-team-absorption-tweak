PlayerStandard._event_listeners = EventListenerHolder:new()

-- Lines 21-23
function PlayerStandard.register_listener(key, event_types, clbk)
	PlayerStandard._event_listeners:add(key, event_types, clbk)
end

-- Lines 25-27
function PlayerStandard.unregister_listener(key)
	PlayerStandard._event_listeners:remove(key)
end

-- Lines 29-31
function PlayerStandard._notify_listeners(event, ...)
	PlayerStandard._event_listeners:call(event, ...)
end

Hooks:PreHook(PlayerStandard, "_check_action_use_ability", "addlistener", function(self, t, input)
    local action_wanted = input.btn_throw_grenade_press
    if action_wanted then
        self._notify_listeners("on_throwable")
    end
end)