local enable_item_pickup = minetest.settings:get_bool("enable_item_pickup")
if enable_item_pickup == nil then enable_item_pickup = true end
local enable_item_drops = minetest.settings:get_bool("enable_item_drops")
if enable_item_drops == nil then enable_item_drops = true end
local item_pickup_key = minetest.settings:get_bool("item_pickup_key")
if item_pickup_key == nil then item_pickup_key = true end
local item_pickup_keytype = minetest.settings:get("item_pickup_keytype") or "use"
local item_pickup_gain = tonumber(minetest.settings:get("item_pickup_gain")) or 0.4

local item_pickup_key_press = false

if enable_item_pickup then
	minetest.register_globalstep(function(dtime)
		for _,player in ipairs(minetest.get_connected_players()) do
			if item_pickup_keytype == "sneak" then
				item_pickup_key_press = player:get_player_control().sneak
			elseif item_pickup_keytype == "ad" then
				item_pickup_key_press = player:get_player_control().left and player:get_player_control().right
			else
				item_pickup_key_press = player:get_player_control().aux1
			end
			if item_pickup_key_press or not item_pickup_key then
				if player:get_hp() > 0 or not minetest.settings:get_bool("enable_damage") then
					local pos = player:getpos()
					pos.y = pos.y+0.5
					local inv = player:get_inventory()

					for _,object in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
						if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
							if inv and inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
								inv:add_item("main", ItemStack(object:get_luaentity().itemstring))
								if object:get_luaentity().itemstring ~= "" then
									minetest.sound_play("item_drop_pickup", {
										to_player = player:get_player_name(),
										gain = item_pickup_gain,
									})
								end
								object:get_luaentity().itemstring = ""
								object:remove()
							end
						end
					end

					for _,object in ipairs(minetest.get_objects_inside_radius(pos, 2)) do
						if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
							if object:get_luaentity().collect then
								if inv and inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
									local pos1 = pos
									pos1.y = pos1.y+0.2
									local pos2 = object:getpos()
									local vec = {x=pos1.x-pos2.x, y=pos1.y-pos2.y, z=pos1.z-pos2.z}
									vec.x = vec.x*3
									vec.y = vec.y*3
									vec.z = vec.z*3
									object:setvelocity(vec)
									object:get_luaentity().physical_state = false
									object:get_luaentity().object:set_properties({
										physical = false
									})

									minetest.after(1, function(args)
										local lua = object:get_luaentity()
										if object == nil or lua == nil or lua.itemstring == nil then
											return
										end
										if inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
											inv:add_item("main", ItemStack(object:get_luaentity().itemstring))
											if object:get_luaentity().itemstring ~= "" then
												minetest.sound_play("item_drop_pickup", {
													to_player = player:get_player_name(),
													gain = item_pickup_gain,
												})
											end
											object:get_luaentity().itemstring = ""
											object:remove()
										else
											object:setvelocity({x=0,y=0,z=0})
											object:get_luaentity().physical_state = true
											object:get_luaentity().object:set_properties({
												physical = true
											})
										end
									end, {player, object})

								end
							end
						end
					end
				end
			end
		end
	end)
end

if enable_item_drops then
	function minetest.handle_node_drops(pos, drops, digger)
		local inv
		if minetest.settings:get_bool("creative_mode") and digger and digger:is_player() then
			inv = digger:get_inventory()
		end
		for _,item in ipairs(drops) do
			local count, name
			if type(item) == "string" then
				count = 1
				name = item
			else
				count = item:get_count()
				name = item:get_name()
			end
			if not inv or not inv:contains_item("main", ItemStack(name)) then
				for i=1,count do
					local obj = minetest.add_item(pos, name)
					if obj ~= nil then
						obj:get_luaentity().collect = true
						local x = math.random(1, 5)
						if math.random(1,2) == 1 then
							x = -x
						end
						local z = math.random(1, 5)
						if math.random(1,2) == 1 then
							z = -z
						end
						obj:setvelocity({x=1/x, y=obj:getvelocity().y, z=1/z})
					end
				end
			end
		end
	end
end

if minetest.settings:get("log_mods") then
	minetest.log("action", "item_drop loaded")
end
