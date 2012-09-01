function item_drop(pos, oldnode, digger)
	local anzahl = 1
	if oldnode.name.items ~= nil then
		local drops = {}
		local max_items = oldnode.name.max_items
		for i,item in ipairs(oldnode.name.items) do
			local rarity
			if item.rarity == nil then
				rarity = 1
			else
				rarity = item.rarity
			end
			if math.random(1, rarity) == 1 then
				table.insert(drops, item.items[1])
			end
			if #drops == max_items then
				for j,it in ipairs(drops) do
					item_drop(pos, {name=it}, digger)
				end
				return
			end
		end
		return
	else
		if string.find(oldnode.name, " ") ~= nil then
			oldnode.name = oldnode.name:gsub('"',""):gsub("craft ",""):gsub("item ",""):gsub("node ","")
			anzahl = string.sub(oldnode.name, string.find(oldnode.name, " ")+1, string.len(oldnode.name))
			oldnode.name = string.sub(oldnode.name, 1, string.find(oldnode.name, " ")-1)
		end
	end
	
	if oldnode.name == "" then
		return
	end
	
	for i=1,anzahl do
		if digger:get_inventory():room_for_item("main", ItemStack(oldnode.name)) then
			digger:get_inventory():remove_item("main", ItemStack(oldnode.name))
		end
		local item = minetest.env:add_item(pos, oldnode)
		if item ~= nil then
			item:get_luaentity().collect = true
			local x = math.random(1, 5)
			if math.random(1,2) == 1 then
				x = -x
			end
			local z = math.random(1, 5)
			if math.random(1,2) == 1 then
				z = -z
			end
			item:setvelocity({x=1/x, y=item:getvelocity().y, z=1/z})
		end
	end
end

local item_timer = {}

minetest.register_globalstep(function(dtime)
	for i,player in ipairs(minetest.get_connected_players()) do
		local pos = player:getpos()
		pos.y = pos.y+0.5
		local items = minetest.env:get_objects_inside_radius(pos,1)
		for j,item in ipairs(items) do
			if not item:is_player() and item:get_luaentity().itemstring ~= nil then
				if item:get_luaentity().itemstring ~= "" and player:get_inventory():room_for_item("main", ItemStack(item:get_luaentity().itemstring)) and item:get_luaentity().collect then
					player:get_inventory():add_item("main", ItemStack(item:get_luaentity().itemstring))
					minetest.sound_play("item_drop_pickup", {
						to_player = player,
					})
					item:remove()
					item:get_luaentity().itemstring = ""
				end
			end
		end
		
		items = minetest.env:get_objects_inside_radius(pos, 2)
		for j,item in ipairs(items) do
			if not item:is_player() and item:get_luaentity().itemstring ~= nil then
				if player:get_inventory():room_for_item("main", ItemStack(item:get_luaentity().itemstring)) and item:get_luaentity().collect then
					local p = player:getpos()
					p.y = p.y+0.5
					local i = item:getpos()
					local move = {x=(p.x-i.x)*15, y=(p.y-i.y)*15, z=(p.z-i.z)*15}
					item:setacceleration(move)
				end
				
				if item:get_luaentity().collect == nil and item:get_luaentity().itemstring ~= "" then
					if item:get_luaentity().timer == nil then
						item:get_luaentity().timer = 0
						table.insert(item_timer, item)
					end
				end
			end
		end
	end
	
	for i,item in ipairs(item_timer) do
		if item:get_luaentity() == nil then
			table.remove(item_timer, i)
		else
			item:get_luaentity().timer = item:get_luaentity().timer + dtime
			if item:get_luaentity().timer > 1 then
				item:get_luaentity().collect = true
				table.remove(item_timer, i)
			end
		end
	end
end)

minetest.after(0, function()
	for name,node in pairs(minetest.registered_nodes) do
		local func
		if node.drop == nil then
			if node.after_dig_node == nil then
				func = function(pos, oldnode, oldmetadata, digger)
					item_drop(pos, oldnode, digger)
				end
			else
				func = function(pos, oldnode, oldmetadata, digger)
					item_drop(pos, oldnode, digger)
				end
			end
		else
			if node.after_dig_node == nil then
				func = function(pos, oldnode, oldmetadata, digger)
					oldnode.name = node.drop
					item_drop(pos, oldnode, digger)
				end
			else
				func = function(pos, oldnode, oldmetadata, digger)
					oldnode.name = node.drop
					item_drop(pos, oldnode, digger)
				end
			end
		end
		
		local new_node = {
			after_dig_node = func,
		}
		for str,val in pairs(node) do
			new_node[str] = val
		end
		minetest.register_node(":"..new_node.name, new_node)
	end
end)

