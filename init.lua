local pickup = minetest.settings:get_bool("enable_item_pickup")
local drop = minetest.settings:get_bool("enable_item_drop")
local key = minetest.settings:get_bool("enable_item_pickup_key")

if pickup == nil then pickup = true end
if drop == nil then drop = true end
if key == nil then key = true end

local keytype = minetest.settings:get("item_pickup_keytype") or "Use"
local pickup_gain = tonumber(minetest.settings:get("item_pickup_gain")) or 0.4
local pickup_radius = tonumber(minetest.settings:get("item_pickup_radius")) or 0.75

local timer = 0

if pickup then
	minetest.register_globalstep(function(dtime)

		timer = timer + dtime
		if timer < 0.2 then return end
		timer = 0

		for _,player in ipairs(minetest.get_connected_players()) do
			local keys_pressed = false

			local control = player:get_player_control()

			if keytype == "Use" then
				if control.aux1 == true then keys_pressed = true end
			elseif keytype == "Sneak" then
				if control.sneak == true then keys_pressed = true end
			elseif keytype == "LeftAndRight" then -- LeftAndRight combination
				if control.left and control.right then keys_pressed = true end
			elseif keytype == "RMB" then
				if control.RMB == true then keys_pressed = true end
			elseif keytype == "SneakAndRMB" then -- SneakAndRMB combination
				if control.sneak and control.RMB then keys_pressed = true end
			end

			if keys_pressed or not key then

				if player:get_hp() > 0 or not minetest.settings:get_bool("enable_damage") then
					local pos = player:getpos()
					pos.y = pos.y+0.5
					local inv = player:get_inventory()

					for _,object in ipairs(minetest.get_objects_inside_radius(pos, pickup_radius)) do
						if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
							if inv and inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
								inv:add_item("main", ItemStack(object:get_luaentity().itemstring))
								if object:get_luaentity().itemstring ~= "" then
									--minetest.chat_send_player(player:get_player_name(), "[ItemPickup] You picked up " .. object:get_luaentity().itemstring)
									minetest.sound_play("item_drop_pickup", {
										to_player = player:get_player_name(),
										gain = pickup_gain,
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
										if object == nil or lua == nil or lua.itemstring == nil then return end

										if inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
											inv:add_item("main", ItemStack(object:get_luaentity().itemstring))
											if object:get_luaentity().itemstring ~= "" then
												minetest.sound_play("item_drop_pickup", {
													to_player = player:get_player_name(),
													gain = pickup_gain,
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

if drop then
	function minetest.handle_node_drops(pos, drops, digger)

		local inv
		local diggerPos = pos

		if minetest.settings:get_bool("creative_mode") and digger and digger:is_player() then
			inv = digger:get_inventory()
			diggerPos = digger:getpos()
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

					local adjustedPos = {x=diggerPos.x, y=diggerPos.y, z=diggerPos.z}
					local obj = minetest.add_item(adjustedPos, name)

					if obj ~= nil then
						obj:get_luaentity().collect = true
						local x = math.random(1, 5)
						if math.random(1,2) == 1 then x = -x end

						local z = math.random(1, 5)
						if math.random(1,2) == 1 then z = -z end

						obj:setvelocity({x=1/x, y=obj:getvelocity().y, z=1/z})
					end
				end
			end
		end
	end
end

if minetest.settings:get("log_mods") then minetest.log("action", "[Mod] item_drop loaded") end
