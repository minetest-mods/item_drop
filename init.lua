if minetest.settings:get_bool("item_drop.enable_item_pickup") ~= false then
	local pickup_gain = tonumber(
		minetest.settings:get("item_drop.pickup_sound_gain")) or 0.4
	local pickup_radius = tonumber(
		minetest.settings:get("item_drop.pickup_radius")) or 0.75
	local magnet_radius = tonumber(
		minetest.settings:get("item_drop.magnet_radius")) or -1
	local pickup_age = tonumber(
		minetest.settings:get("item_drop.pickup_age")) or 0.5
	local key_triggered = minetest.settings:get_bool(
		"item_drop.enable_pickup_key") ~= false
	local keytype
	if key_triggered then
		keytype = minetest.settings:get("item_drop.pickup_keytype") or "Use"
	end
	local damage_enabled = minetest.settings:get_bool("enable_damage")

	local magnet_mode = magnet_radius > pickup_radius
	local zero_velocity_mode = pickup_age == -1
	if magnet_mode
	and zero_velocity_mode then
		error"zero velocity mode can't be used together with magnet mode"
	end

	-- adds the item to the inventory and removes the object
	local function collect_item(inv, item, ent, object, pos)
		inv:add_item("main", item)
		minetest.sound_play("item_drop_pickup", {
			pos = pos,
			gain = pickup_gain,
		})
		ent.itemstring = ""
		object:remove()
	end

	-- opt_get_ent gets the object's luaentity if it can be collected
	local opt_get_ent
	if zero_velocity_mode then
		function opt_get_ent(object)
			if object:is_player()
			or not vector.equals(object:getvelocity(), {x=0, y=0, z=0}) then
				return
			end
			local ent = object:get_luaentity()
			if not ent
			or ent.name ~= "__builtin:item"
			or ent.itemstring == "" then
				return
			end
			return ent
		end
	else
		function opt_get_ent(object)
			if object:is_player() then
				return
			end
			local ent = object:get_luaentity()
			if not ent
			or ent.name ~= "__builtin:item"
			or (ent.dropped_by and ent.age < pickup_age)
			or ent.itemstring == "" then
				return
			end
			return ent
		end
	end

	local afterflight
	if magnet_mode then
		-- take item or reset velocity after flying a second
		function afterflight(object, inv)
			local ent = opt_get_ent(object)
			if not ent then
				return
			end
			local item = ItemStack(ent.itemstring)
			if inv
			and inv:room_for_item("main", item) then
				collect_item(inv, item, ent, object, object:get_pos())
			else
				object:setvelocity({x=0,y=0,z=0})
				ent.physical_state = true
				ent.object:set_properties({
					physical = true
				})
			end
		end
	end

	local function pickupfunc(player)
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
			magnet_mode and magnet_radius or pickup_radius)
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
				local item = ItemStack(ent.itemstring)
				if inv:room_for_item("main", item) then
					local pos2 = object:getpos()
					local distance = vector.distance(pos, pos2)
					if distance <= pickup_radius then
						collect_item(inv, item, ent, object, pos)
					else
						local vel = vector.multiply(
							vector.subtract(pos, pos2), 3)
						vel.y = vel.y + 0.6
						object:setvelocity(vel)
						ent.physical_state = false
						ent.object:set_properties({
							physical = false
						})

						minetest.after(1.0, afterflight, object, inv)
					end
				end
			end
		end
	end

	local function pickup_step()
		local players = minetest.get_connected_players()
		for i = 1,#players do
			pickupfunc(players[i])
		end
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
