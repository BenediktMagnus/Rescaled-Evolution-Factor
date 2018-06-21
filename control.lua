require "util"

-- Constants:

local weighting = {}
weighting.time = 0.15
weighting.tech = 0.10

local maximum = {}
maximum.pollution = 0.8
maximum.spawners = 0.6

local config = {}
config.count_every_ticks = 3
config.chunks_per_counting_tick = 100
config.ticks_for_max_value = 60 * 60 * 60 * 24 -- = 24 hours
config.spawners_for_maximum = 60
config.spawner_forget_time = 60 * 60 * 12 -- = 12 minutes
config.adjustment_per_calculation = 0.08

-- Globals:

local pollution = {}
pollution.surface = nil
pollution.chunks = nil
pollution.amount = 0
pollution.count = 0

-- Functions:

function init ()
	game.map_settings.enemy_evolution.enabled = false

	global.spawner_died = 0

	load()
end

function load ()
	pollution.surface = game.surfaces["nauvis"]
	pollution.chunks = pollution.surface.get_chunks()
end

function change_config (data)
	--if data.mod_changes ~= nil and data.mod_changes["Rescaled-Evolution-Factor"] ~= nil and data.mod_changes["Rescaled-Evolution-Factor"].old_version == nil then
	--	global.pollution_spawner = 0
	--	game.map_settings.enemy_evolution.time_factor = 0.000008 * 0
	--	game.map_settings.enemy_evolution.pollution_factor = 0.00003 * 0
	--end
end

-- Iterate over the chunk list (only some per tick) and count the pollution:
function count_pollution()
	local amount = 0
	local count = 0

	for i = 1, config.chunks_per_counting_tick do
		local chunk = pollution.chunks(nil, nil)
		if (chunk == nil) then
			amount = pollution.amount
			count = pollution.count
			pollution.amount = 0
			pollution.count = 0
			pollution.chunks = pollution.surface.get_chunks()
		else
			pollution.amount = pollution.amount + pollution.surface.get_pollution({chunk.x*32, chunk.y*32})
			pollution.count = pollution.count + 1
		end
	end

	if (count ~= 0) then
		calculate_factor()
	end
end

function calculate_factor ()

	-- time factor

	local past_time = 1
	if game.tick < config.ticks_for_max_value then
		past_time = math.pow(game.tick / config.ticks_for_max_value, 2)
	end

	local factor_time = past_time * weighting.time

	-- technology factor

	local technologies = game.forces['player'].technologies
	local technology_count = 0

	for _, technology in pairs(technologies) do
		if (technology.researched) then
			technology_count = technology_count + 1
		end
	end

	local factor_tech = technology_count / #technologies * weighting.tech

	-- spawner factor

	local factor_spawner = global.spawner_died * maximum.spawners / config.spawners_for_maximum

	if (factor_spawner > maximum.spawners) then
		factor_spawner = maximum.spawners
	end

	-- pollution factor

--[[
	if anzahl < 1000 then --Mindestwert für die Anzahl, erleichtert den Start.
		anzahl = 1000
	end

	local pollution_summe = summe/math.log(anzahl)/100000 * 5 --(Gewichtung = 50%)

	if pollution_summe > 5 then
		pollution_summe = 5
	end

	local faktor = (pollution_summe + pollution_spawner_anzahl + vergangene_zeit) / 10 --Wieder "entwichten".

	if faktor > 1 then
		faktor = 1
	end
]]--

	-- factor calculation

	local new_factor = factor_time + factor_tech + factor_spawner

	local old_factor = game.forces["enemy"].evolution_factor

	local temp = new_factor

	new_factor = old_factor + (new_factor - old_factor) * config.adjustment_per_calculation

	if (new_factor > 1) then
		new_factor = 1
	end

	game.forces["enemy"].evolution_factor = new_factor
end

-- Count every killed spawner:
function entity_died (entity)
	if (entity.type == 'unit-spawner') then
		global.spawner_died = global.spawner_died + 1
	end
end

-- Reduce the number of known killed spawners so the evolution factor decreases if you are nice again:
function forget_spawner_death ()
	if (global.spawner_died > 0) then
		global.spawner_died = global.spawner_died - 1
	end
end

-- Initialising:

script.on_init(init)
script.on_load(load)

script.on_configuration_changed(change_config)

script.on_nth_tick(config.count_every_ticks, count_pollution)

script.on_event(defines.events.on_entity_died, entity_died)
script.on_nth_tick(config.spawner_forget_time, forget_spawner_death)