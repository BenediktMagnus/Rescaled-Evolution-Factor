require "util"

pollution = {}
pollution.surface = nil
pollution.chunks = nil
pollution.summe = 0
pollution.count = 0

function Initialisierung ()
	pollution.surface = game.surfaces["nauvis"]
	pollution.chunks = pollution.surface.get_chunks()
end

script.on_init(Initialisierung)
script.on_load(Initialisierung)

script.on_configuration_changed(
	function(data)
		--if data.mod_changes ~= nil and data.mod_changes["Rescaled-Evolution-Factor"] ~= nil and data.mod_changes["Rescaled-Evolution-Factor"].old_version == nil then
		--	global.pollution_spawner = 0
		--	game.map_settings.enemy_evolution.time_factor = 0.000008 * 0
		--	game.map_settings.enemy_evolution.pollution_factor = 0.00003 * 0
		--end
	end
)

function pollutiontest(event)
	local summe = 0
	local count = 0

	for i = 1, 10 do
		local chunk = pollution.chunks(nil, nil)
		if (chunk == nil) then
			summe = pollution.summe
			count = pollution.count
			pollution.summe = 0
			pollution.count = 0
			pollution.chunks = pollution.surface.get_chunks()
		else
			pollution.summe = pollution.summe + pollution.surface.get_pollution({chunk.x*32, chunk.y*32})
			pollution.count = pollution.count + 1
		end
	end

--[[
	if anzahl < 1000 then --Mindestwert für die Anzahl, erleichtert den Start.
		anzahl = 1000
	end

	local pollution_summe = summe/math.log(anzahl)/100000 * 5 --(Gewichtung = 50%)

	if pollution_summe > 5 then
		pollution_summe = 5
	end

	local vergangene_zeit = 2

	if game.tick < 5184000 then --5184000 Ticks = 24 Stunden
		vergangene_zeit = math.pow(game.tick / 5184000, 2) * 2 --(Gewichtung = 20%)
	end

	local pollution_spawner_anzahl = 3

	if global.pollution_spawner < 60 then
		pollution_spawner_anzahl = global.pollution_spawner / 20 -- /60 * 3 (Gewichtung = 30%)
	end

	local faktor = (pollution_summe + pollution_spawner_anzahl + vergangene_zeit) / 10 --Wieder "entwichten".

	if faktor > 1 then
		faktor = 1
	end

	game.evolution_factor = faktor

    if (game.tick % 216000 == 25 and global.pollution_spawner > 0) then
		global.pollution_spawner = global.pollution_spawner -1 --Vergiss mit der Zeit alte Fehden.
	end
]]--
end

function spawnertot(event)
   if (global.pollution_spawner < 60 and (event.entity.name == "spitter-spawner" or event.entity.name == "biter-spawner")) then
      global.pollution_spawner = global.pollution_spawner + 1
   end
end

script.on_nth_tick(3, pollutiontest)
--script.on_event(defines.events.on_entity_died, spawnertot)