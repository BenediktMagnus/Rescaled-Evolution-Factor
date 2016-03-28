require "util"
require "defines"

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
	if remote.interfaces.EvoGUI ~= nil then registriere_sensoren() end
 end)

function pollutiontest(event)
    if game.tick % 60 == 24 then
		if remote.interfaces.EvoGUI ~= nil then registriere_sensoren() end

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
		
		if remote.interfaces.EvoGUI ~= nil then
			remote.call("EvoGUI", "update_remote_sensor", "rescaled_evolution_factor_sensor_pollution", {"", {"rescaled_evolution_factor_sensor_pollution_prefix"}, " ", summe_formatieren(summe)})
			remote.call("EvoGUI", "update_remote_sensor", "rescaled_evolution_factor_sensor_spawner", {"", {"rescaled_evolution_factor_sensor_spawner_prefix"}, " ", global.pollution_spawner})
			remote.call("EvoGUI", "update_remote_sensor", "rescaled_evolution_factor_sensor_anteile", {"", {"rescaled_evolution_factor_sensor_anteile_prefix"}, " ", string.format("%.1f", vergangene_zeit * 10).."%|", string.format("%.1f", pollution_spawner_anzahl * 10).."%|", string.format("%.1f", pollution_summe * 10).."%"})
		end
	end
   
    if (game.tick % 216000 == 25 and global.pollution_spawner > 0) then
		global.pollution_spawner = global.pollution_spawner -1 --Vergiss mit der Zeit alte Fehden.
	end
end

function spawnertot(event)
   if (global.pollution_spawner < 50 and (event.entity.name == "spitter-spawner" or event.entity.name == "biter-spawner")) then
      global.pollution_spawner = global.pollution_spawner + 1
   end   
end

function registriere_sensoren()
	if global.ist_registriert == nil then
		local sensor_data = {mod_name = "Evolve Factor",
							 name = "rescaled_evolution_factor_sensor_pollution",
							 text = {"rescaled_evolution_factor_sensor_pollution_display", 42},
							 caption = {"rescaled_evolution_factor_sensor_pollution_caption"}}
   
		remote.call("EvoGUI", "create_remote_sensor", sensor_data)
   
		sensor_data = {mod_name = "Evolve Factor",
					   name = "rescaled_evolution_factor_sensor_spawner",
					   text = {"rescaled_evolution_factor_sensor_spawner_display", 42},
					  caption = {"rescaled_evolution_factor_sensor_spawner_caption"}}
   
		remote.call("EvoGUI", "create_remote_sensor", sensor_data)
   
		sensor_data = {mod_name = "Evolve Factor",
					   name = "rescaled_evolution_factor_sensor_anteile",
					   text = {"rescaled_evolution_factor_sensor_anteile_display", 42},
					   caption = {"rescaled_evolution_factor_sensor_anteile_caption"}}
   
		remote.call("EvoGUI", "create_remote_sensor", sensor_data)
		
		global.ist_registriert = true
	end
end

function summe_formatieren(v)
	local s = string.format("%d", math.floor(v))
	local pos = string.len(s) % 3
	if pos == 0 then pos = 3 end
	return string.sub(s, 1, pos) .. string.gsub(string.sub(s, pos+1), "(...)", " %1")
end

function prozent_formatieren(v)
    local whole_number = math.floor(v)
    local fractional_component = math.floor((v - whole_number) * 10)
	
	return string.format("%d.%d%%", whole_number, fractional_component)
end

script.on_event(defines.events.on_tick, pollutiontest)
script.on_event(defines.events.on_entity_died , spawnertot)