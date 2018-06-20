require "util"

script.on_init(function()
		global.pollution_spawner = 0
		game.map_settings.enemy_evolution.time_factor = 0.000008 * 0
		game.map_settings.enemy_evolution.pollution_factor = 0.00003 * 0
	end)

script.on_configuration_changed(function(data)
		if data.mod_changes ~= nil and data.mod_changes["Rescaled-Evolution-Factor"] ~= nil and data.mod_changes["Rescaled-Evolution-Factor"].old_version == nil then
			global.pollution_spawner = 0
			game.map_settings.enemy_evolution.time_factor = 0.000008 * 0
			game.map_settings.enemy_evolution.pollution_factor = 0.00003 * 0
		end
	end)

script.on_load(function()

	end)

function pollutiontest(event)
	if game.tick % 60 == 24 then
		local summe = 0
		local anzahl = 0

		local s = game.surfaces["nauvis"]

		for c in s.get_chunks() do
			summe = summe + s.get_pollution({c.x *32,c.y *32})
			anzahl = anzahl + 1
		end

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
	end

    if (game.tick % 216000 == 25 and global.pollution_spawner > 0) then
		global.pollution_spawner = global.pollution_spawner -1 --Vergiss mit der Zeit alte Fehden.
	end
end

function spawnertot(event)
   if (global.pollution_spawner < 60 and (event.entity.name == "spitter-spawner" or event.entity.name == "biter-spawner")) then
      global.pollution_spawner = global.pollution_spawner + 1
   end
end

script.on_event(defines.events.on_tick, pollutiontest)
script.on_event(defines.events.on_entity_died , spawnertot)