-- Mini-Cons represented by individual toggle items in PopTracker.
MINICON_CODES = {
    "skirmish",
    "firefight",
    "aftershock",
    "sparkjump",
    "jumpstart",
    "overwatch",
    "aurora",
    "corona",
    "flashbang",
    "hailstorm",
    "knockdown",
    "airburst",
    "slapshot",
    "lock-on",
    "watchdog",
    "claymore",
    "lookout",
    "twister",
    "shockpunch",
    "slipstream",
    "discord",
    "safeguard",
    "bulletproof",
    "stronghold",
    "highgear",
    "smackdown",
    "shieldwall",
    "hawkeye",
    "deflector",
    "fullspeed",
    "pressurepoint",
    "shepherd",
    "rangefinder",
    "kickback",
    "covert",
    "tractor",
    "buildup",
    "comeback",
    "highjump",
    "failsafe"
}

REQUIRED_MINICONS = nil
OFFLINE_REQUIRED_MINICONS = 30

BOSS_LOCATIONS = {
    "@Amazon/Amazon Boss/Amazon Boss",
    "@Antarctica/Antarctica Boss/Antarctica Boss",
    "@Deep Amazon/Deep Amazon Boss/Deep Amazon Boss",
    "@Mid Atlantic/Mid Atlantic Boss/Mid Atlantic Boss",
    "@Alaska/Alaska Complete/Alaska Complete",
    "@Starship/Starship Boss/Starship Boss",
    "@Pacific Island/Pacific Island Boss/Pacific Island Boss",
}

function UpdateBossesBeaten()
    local bosses_goal = Tracker:FindObjectForCode("bosses_goal")
    local bosses_beaten = Tracker:FindObjectForCode("bosses_beaten")

    if not bosses_goal or not bosses_beaten then
        return
    end

    -- This goal only applies when the selected goal is bosses.
    if not bosses_goal.Active then
        if not bosses_beaten.Active then
			bosses_beaten.Active = true
		end
        return
    end

    local count = 0

    for _, location_code in ipairs(BOSS_LOCATIONS) do
        local section = Tracker:FindObjectForCode(location_code)

        if section and section.AvailableChestCount == 0 then
            count = count + 1
        end
    end

    local beaten = count >= 7
	if bosses_beaten.Active ~= beaten then
		bosses_beaten.Active = beaten
	end
end

function UpdateMiniconCounter()
    local count = 0

    for _, code in ipairs(MINICON_CODES) do
        local item = Tracker:FindObjectForCode(code)

        if item and item.Active then
            count = count + 1
        end
    end

    local counter = Tracker:FindObjectForCode("minicon_counter")
	
	local ap_connected =
		Archipelago ~= nil
		and Archipelago.PlayerNumber ~= nil
		and Archipelago.PlayerNumber > -1
	local required
	if ap_connected then
		required = REQUIRED_MINICONS
	else
		required = OFFLINE_REQUIRED_MINICONS
	end

    if counter then
		if required == nil then
            counter:SetOverlay("Minicons:" .. tostring(count) .. "/?")
        else
            counter:SetOverlay(
                "Minicons:" .. tostring(count) .. "/" .. tostring(required)
            )
        end
    end
	
	local minicons_reached = Tracker:FindObjectForCode("minicons_reached")
	if minicons_reached then
		local reached = count >= required and required ~= nil
		if minicons_reached.Active ~= reached then
			minicons_reached.Active = reached
		end
	end
end