if minetest.settings:get_bool("item_drop.enable_item_pickup") ~= false then
	local pickup_gain = tonumber(
		minetest.settings:get("item_drop.pickup_sound_gain")) or 0.4
	local pickup_radius = tonumber(
		minetest.settings:get("item_drop.pickup_radius")) or 0.75
	local pickup_age = tonumber(
		minetest.settings:get("item_drop.pickup_age")) or 0.5
	local key_triggered = minetest.settings:get_bool(
		"item_drop.enable_pickup_key") ~= false
	local keytype
	if key_triggered then
		keytype = minetest.settings:get("item_drop.pickup_keytype") or "Use"
	end
	local damage_enabled = minetest.settings:get_bool("enable_damage")

	-- gets the object's luaentity if it can be collected
	local function opt_get_ent(object)
		if object:is_player() then
			return
		end
		local ent = object:get_luaentity()
		if not ent
		or ent.name ~= "__builtin:item"
		or (ent.dropped_by and ent.age < pickup_age) then
			return
		end
		return ent
	end

	local function pickupfunc()
		for _,player in ipairs(minetest.get_connected_players()) do
			local keys_pressed = not key_triggered

			local control = player:get_player_control()

			if keytype == "Use" then
				keys_pressed = control.aux1
			elseif keytype == "Sneak" then
				keys_pressed = control.sneak
			elseif keytype == "LeftAndRight" then -- LeftAndRight combination
				keys_pressed = control.left and control.right
			elseif keytype == "RMB" then
				keys_pressed = control.RMB
			elseif keytype == "SneakAndRMB" then -- SneakAndRMB combination
				keys_pressed = control.sneak and control.RMB
			end

			if not keys_pressed
			or (damage_enabled and player:get_hp() <= 0) then
				return
			end

			local pos = player:getpos()
			pos.y = pos.y+0.5
			local inv

			local objectlist = minetest.get_objects_inside_radius(pos,
				pickup_radius)
			for i = 1,#objectlist do
				local object = objectlist[i]
				local ent = opt_get_ent(object)
				if ent then
					if not inv then
						inv = player:get_inventory()
						if not inv then
							minetest.log("error", "[item_drop] Couldn't " ..
								"get inventory")
							return
						end
					end
					if inv:room_for_item("main",
						ItemStack(ent.itemstring)
					) then
						local pos2 = object:getpos()
						local distance = vector.distance(pos, pos2)
						if distance <= 1 then
							inv:add_item("main", ItemStack(
								ent.itemstring))
							minetest.sound_play("item_drop_pickup", {
								to_player = player:get_player_name(),
								gain = pickup_gain,
							})
							ent.itemstring = ""
							object:remove()
						else
							local vel = vector.multiply(
								vector.subtract(pos, pos2), 3)
							vel.y = vel.y + 0.6
							object:setvelocity(vel)
							ent.physical_state = false
							ent.object:set_properties({
								physical = false
							})

							minetest.after(1, function()
								local lua = object:get_luaentity()
								if not lua or not lua.itemstring then
									return
								end
								if inv:room_for_item("main",
									ItemStack(object:get_luaentity(
									).itemstring)
								) then
									inv:add_item("main",
										ItemStack(object:get_luaentity(
										).itemstring))
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

	local function pickup_step()
		pickupfunc()
		minetest.after(0.01, pickup_step)
	end
	minetest.after(3.0, pickup_step)
end

if minetest.settings:get_bool("item_drop.enable_item_drop") ~= false then
	function minetest.handle_node_drops(pos, drops, digger)

		local inv
		local diggerPos = pos

		if minetest.settings:get_bool("creative_mode")
		and digger
		and digger:is_player() then
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

					local adjustedPos = {x=diggerPos.x, y=diggerPos.y,
						z=diggerPos.z}
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

if minetest.settings:get("log_mods") then
	minetest.log("action", "[Mod] item_drop loaded")
end
