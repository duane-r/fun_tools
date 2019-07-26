-- Fun_tools power_tools.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local mod = fun_tools
local mod_name = 'fun_tools'


function mod.power(player, pos, tool_type, max)
	if not (player and pos and tool_type) then
		return
	end

	local player_pos = vector.round(player:getpos())
	local inv = player:get_inventory()
	pos = vector.round(pos)
	local pointed_node = minetest.get_node_or_nil(pos)
	if not (pointed_node and player_pos and inv) then
		return
	end

	local maxr, node_type
	if tool_type == 'axe' then
		node_type = 'choppy'
		maxr = {x = 2, y = 20, z = 2}
	elseif tool_type == 'pick' then
		node_type = 'cracky'
		maxr = {x = 2, y = 4, z = 2}
	else
		return
	end

	if minetest.get_item_group(pointed_node.name, node_type) == 0 then
		return
	end

	local max_nodes = max or 100
	local minp = vector.subtract(pos, 2)
	local maxp = vector.add(pos, maxr)
	local yloop_a, yloop_b, yloop_c
	if pos.y >= player_pos.y then
		minp.y = player_pos.y
		yloop_a, yloop_b, yloop_c = minp.y, maxp.y, 1
		if node_type == 'cracky' and pos.y - player_pos.y < 3 then
			maxp.y = player_pos.y + 3
		end
	else
		maxp.y = player_pos.y
		yloop_a, yloop_b, yloop_c = maxp.y, minp.y, -1
	end

	local vm = minetest.get_voxel_manip()
	if not vm then
		return
	end

	local diggable = {}
	local count = 0
	local p = {}
	for y = yloop_a, yloop_b, yloop_c do
		p.y = y
		for z = minp.z, maxp.z do
			p.z = z
			for x = minp.x, maxp.x do
				p.x = x
				local p_node = minetest.get_node_or_nil(p)

				if p_node then
					if not diggable[p_node.name] then
						diggable[p_node.name] = minetest.get_item_group(p_node.name, node_type) or 0
						if node_type == 'choppy' then
							diggable[p_node.name] = diggable[p_node.name] + minetest.get_item_group(p_node.name, 'snappy') or 0
							diggable[p_node.name] = diggable[p_node.name] + minetest.get_item_group(p_node.name, 'fleshy') or 0
						end

						if p_node.name and p_node.name:find('^door') then
							diggable[p_node.name] = 0
						end
					end

					if count < max_nodes and diggable[p_node.name] > 0 then
						minetest.node_dig(p, p_node, player)
						count = count + 1
					end
				end
			end
		end
	end

	return player:get_wielded_item()
end


------------------------------------------------
--  Chainsaw
------------------------------------------------

local chainsaw_time = {}
minetest.register_tool(mod_name..':chainsaw', {
	description = 'Chainsaw',
	inventory_image = 'fun_tools_chainsaw.png',
	tool_capabilities = {
		full_punch_interval = 2.0,
		max_drop_level=1,
		groupcaps={
			choppy={times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=80, maxlevel=2},
		},
		damage_groups = {fleshy=15},
	},
	on_use = function(itemstack, user, pointed_thing)
		if not (user and pointed_thing and itemstack) then
			return
		end

		local user_name = user:get_player_name()
		if not user_name or user_name == '' then
			return
		end

		local ctime = 0
		if not chainsaw_time[user_name] then
			chainsaw_time[user_name] = ctime
		else
			ctime = chainsaw_time[user_name]
		end

		local time = minetest.get_gametime()
		if time - ctime < 2 then
			return
		end
		chainsaw_time[user_name] = time

		minetest.sound_play('chainsaw2', {
			object = user,
			gain = 1.0,
			max_hear_distance = 30
		})

		if pointed_thing.type == 'object' then
			pointed_thing.ref:punch(user, nil, itemstack:get_tool_capabilities(), nil)
			if not mod.creative then
				itemstack:add_wear(800)
			end
			return itemstack
		else
			return mod.power(user, pointed_thing.under, 'axe')
		end
	end,
})

minetest.register_tool(mod_name..':jackhammer', {
	description = 'Jackhammer',
	inventory_image = 'fun_tools_jackhammer.png',
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=80, maxlevel=2},
		},
		damage_groups = {fleshy=4},
	},
	on_use = function(_, user, pointed_thing)
		if not (user and pointed_thing) then
			return
		end

		minetest.sound_play('jackhammer', {
			object = user,
			gain = 0.1,
			max_hear_distance = 30
		})

		return mod.power(user, pointed_thing.under, 'pick')
	end,
})

minetest.register_craftitem(mod_name..':precision_component', {
	description = 'Precision Component',
	drawtype = 'plantlike',
	paramtype = 'light',
	tiles = {'fun_tools_component.png'},
	inventory_image = 'fun_tools_component.png',
	groups = {dig_immediate = 3},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_craft({
	output = mod_name..':precision_component',
	recipe = {
		{'', '', ''},
		{'default:steel_ingot', mod.precision_tool, 'default:gold_ingot'},
		{'', '', ''},
	}
})

minetest.register_craftitem(mod_name..':internal_combustion_engine', {
	description = 'Internal Combustion Engine',
	drawtype = 'plantlike',
	paramtype = 'light',
	tiles = {'fun_tools_engine.png'},
	inventory_image = 'fun_tools_engine.png',
	groups = {dig_immediate = 3},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_craft({
	output = mod_name..':internal_combustion_engine',
	recipe = {
		{'', mod_name..':precision_component', ''},
		{mod_name..':precision_component', 'default:steelblock', mod_name..':precision_component'},
		{'', mod_name..':precision_component', ''},
	}
})

minetest.register_craft({
	output = mod_name..':chainsaw',
	recipe = {
		{'', 'default:mese_crystal', ''},
		{'', mod_name..':internal_combustion_engine', ''},
		{mod_name..':precision_component', mod.ice_fuel_source, mod_name..':precision_component'},
	}
})

minetest.register_craft({
	output = mod_name..':chainsaw',
	recipe = {
		{'', mod.ice_fuel_source, ''},
		{'', mod_name..':chainsaw', ''},
		{'', mod_name..':precision_component', ''},
	}
})


------------------------------------------------
--  Jackhammer
------------------------------------------------

minetest.register_craft({
	output = mod_name..':jackhammer',
	recipe = {
		{mod_name..':precision_component', mod.ice_fuel_source, mod_name..':precision_component'},
		{'', mod_name..':internal_combustion_engine', ''},
		{'', 'default:mese_crystal', ''},
	}
})

minetest.register_craft({
	output = mod_name..':jackhammer',
	recipe = {
		{'', mod.ice_fuel_source, ''},
		{'', mod_name..':jackhammer', ''},
		{'', mod_name..':precision_component', ''},
	}
})
