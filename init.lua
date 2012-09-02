minetest.register_globalstep(function(dtime)
	for _,player in ipairs(minetest.get_connected_players()) do
		local pos = player:getpos()
		pos.y = pos.y+0.5
		local inv = player:get_inventory()
		
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
			if not object:is_player() and object:get_luaentity().name == "__builtin:item" then
				if inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
					inv:add_item("main", ItemStack(object:get_luaentity().itemstring))
					if object:get_luaentity().itemstring ~= "" then
						minetest.sound_play("item_drop_pickup", {
							to_player = player:get_player_name(),
						})
					end
					object:get_luaentity().itemstring = ""
					object:remove()
				end
			end
		end
		
		for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 2)) do
			if not object:is_player() and object:get_luaentity().name == "__builtin:item" then
				if object:get_luaentity().collect then
					if inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
						local pos1 = pos
						pos1.y = pos1.y+0.2
						local pos2 = object:getpos()
						local vec = {x=pos1.x-pos2.x, y=pos1.y-pos2.y, z=pos1.z-pos2.z}
						vec.x = vec.x*3
						vec.y = vec.y*3
						vec.z = vec.z*3
						object:setvelocity(vec)
						
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
									})
								end
								object:get_luaentity().itemstring = ""
								object:remove()
							else
								object:setvelocity({x=0,y=0,z=0})
							end
						end, {player, object})
						
					end
				else
					minetest.after(0.5, function(entity)
						entity.collect = true
					end, object:get_luaentity())
				end
			end
		end
	end
end)


function minetest.get_node_drops(nodename, toolname)
	return {}
end

function minetest.get_drops(nodename, toolname)
	local drop = ItemStack({name=nodename}):get_definition().drop
	if drop == nil then
		-- default drop
		return {ItemStack({name=nodename})}
	elseif type(drop) == "string" then
		-- itemstring drop
		return {ItemStack(drop)}
	elseif drop.items == nil then
		-- drop = {} to disable default drop
		return {}
	end

	-- Extended drop table
	local got_items = {}
	local got_count = 0
	local _, item, tool
	for _, item in ipairs(drop.items) do
		local good_rarity = true
		local good_tool = true
		if item.rarity ~= nil then
			good_rarity = item.rarity < 1 or math.random(item.rarity) == 1
		end
		if item.tools ~= nil then
			good_tool = false
			for _, tool in ipairs(item.tools) do
				if tool:sub(1, 1) == '~' then
					good_tool = toolname:find(tool:sub(2)) ~= nil
				else
					good_tool = toolname == tool
				end
				if good_tool then
					break
				end
			end
        	end
		if good_rarity and good_tool then
			got_count = got_count + 1
			for _, add_item in ipairs(item.items) do
				got_items[#got_items+1] = add_item
			end
			if drop.max_items ~= nil and got_count == drop.max_items then
				break
			end
		end
	end
	return got_items
end

minetest.register_on_dignode(function(pos, oldnode, digger)
	local drop = minetest.get_drops(oldnode.name, digger:get_wielded_item():get_name())
	if drop == nil then
		return
	end
	for _,item in ipairs(drop) do
		if type(item) == "string" then
			local obj = minetest.env:add_item(pos, item)
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
		else
			for i=1,item:get_count() do
				local obj = minetest.env:add_item(pos, item:get_name())
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
end)
