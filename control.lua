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

function pollutiontest(event)
   if game.tick % 600 == 0 then
      local summe = 0
	  local anzahl = 0
      
	  local s = game.surfaces["nauvis"]
	  
	  for c in s.get_chunks() do
	    summe = summe + s.get_pollution({c.x *32,c.y *32})
		anzahl = anzahl + 1
	  end
	  
	  --summe = (math.sqrt(summe/1000000) + math.sqrt(summe/anzahl/200)) / 2
	  
	  if anzahl < 1000 then --Mindestwert für die Anzahl, erleichtert den Start.
	    anzahl = 1000
	  end
	  
	  summe = math.sqrt(summe/math.log(anzahl)/100000) * 7 --(Gewichtung = 70%)
	  
	  if summe > 7 then
	     summe = 7
	  end
	  
	  local pollution_spawner_anzahl = 2
	  
	  if global.pollution_spawner < 50 then
	     pollution_spawner_anzahl = global.pollution_spawner / 25 -- /50 * 2 (Gewichtung = 20%)
	  end
	  
	  local vergangene_zeit = 1
	  
	  if game.tick < 5184000 then --5184000 Ticks = 24 Stunden
	     vergangene_zeit = game.tick / 5184000 --(Gewichtung = 10%)
	  end
	  
	  summe = (summe + pollution_spawner_anzahl + vergangene_zeit) / 10 --Wieder "entwichten".
	  
	  if summe > 1 then
	     summe = 1
	  end
	  
	  game.evolution_factor = summe	  
   end
end

function spawnertot(event)
   if (global.pollution_spawner < 50 and (event.entity.name == "spitter-spawner" or event.entity.name == "biter-spawner")) then
      global.pollution_spawner = global.pollution_spawner + 1
   end   
end

script.on_event(defines.events.on_tick, pollutiontest)
script.on_event(defines.events.on_entity_died , spawnertot)