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
						pos1.y = pos1.y+0.3
						local pos2 = object:getpos()
						local vec = {x=pos1.x-pos2.x, y=pos1.y-pos2.y, z=pos1.z-pos2.z}
						vec.x = vec.x*15
						vec.y = vec.y*15
						vec.z = vec.z*15
						object:setacceleration(vec)
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

drops = {}
after_dig_nodes = {}

get_drops = function(tab)
	if not tab.items then
		return {tab}
	end
	local ret = {}
	if tab.rarity and math.random(1, tab.rarity) ~= 1 then
		return {}
	end
	local max = tab.max_items
	if not max then
		max = #tab+100
	end
	for i,item in ipairs(tab.items) do
		if #ret>=max then
			break
		end
		if item.items == nil then
			table.insert(ret, item)
		else
			for _,item2 in ipairs(get_drops(item)) do
				table.insert(ret, item2)
			end
		end
	end
	return ret
end

minetest.after(0, function()
	for name,node in pairs(minetest.registered_nodes) do
		if node.drop ~= nil then
			drops[name] = node.drop
		end
		if node.after_dig_node ~= nil then
			after_dig_nodes[name] = node.after_dig_nodes
		end
		local new_node = {}
		new_node.drop = ""
		new_node.after_dig_node = function(pos, oldnode, oldmetadata, digger)
			if after_dig_nodes[oldnode.name] ~= nil then
				after_dig_nodes[oldnode.name](pos, oldnode, oldmetadata, digger)
			end
			local name = oldnode.name
			if drops[name] == nil then
				local obj = minetest.env:add_item(pos, oldnode)
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
				if drops[name].items == nil then
					oldnode.name = drops[name]
					local num = 1
					if string.find(oldnode.name, " ") then
						num = tonumber(string.sub(oldnode.name, string.find(oldnode.name, " ")+1))
						oldnode.name = string.sub(oldnode.name, 1, string.find(oldnode.name, " ")-1)
					end
					for i=1,num do
						local obj = minetest.env:add_item(pos, oldnode)
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
				else
					for _,item in ipairs(get_drops(drops[oldnode.name])) do
						oldnode.name = item
						local obj = minetest.env:add_item(pos, oldnode)
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
		
		for name,value in pairs(node) do
			if name ~= "drop" and name ~= "after_dig_node" then
				new_node[name] = value
			end
		end
		
		minetest.register_node(":"..new_node.name, new_node)
		
	end
end)
