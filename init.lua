-- Fun_tools init.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

fun_tools_mod = {}
local mod = fun_tools_mod
local mod_name = 'fun_tools'
mod.version = '20190614'
mod.path = minetest.get_modpath(minetest.get_current_modname())
mod.world = minetest.get_worldpath()
mod.which_dry_fiber = 'fun_tools'


function clone_node(name)
	if not (name and type(name) == 'string') then
		return
	end

	local node = minetest.registered_nodes[name]
	local node2 = table.copy(node)
	return node2
end


local fuel_source = 'default:coalblock'
if minetest.registered_items['elixirs:bucket_of_naptha'] then
	fuel_source = 'elixirs:bucket_of_naptha'
end

local precision_tool = 'default:diamond'
if minetest.registered_items['inspire:inspiration'] then
	precision_tool = 'inspire:inspiration'
end


local function power(player, pos, tool_type, max)
	if not (player and pos and tool_type) then
		return
	end

	local player_pos = vector.round(player:getpos())
	local player_name = player:get_player_name()
	local inv = player:get_inventory()
	pos = vector.round(pos)
	local node = minetest.get_node_or_nil(pos)
	if not (node and player_pos and player_name and inv) then
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

	if minetest.get_item_group(node.name, node_type) == 0 then
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

	local air = minetest.get_content_id('air')
	local vm = minetest.get_voxel_manip()
	if not vm then
		return
	end

	local drops = {}
	local diggable = {}
	local count = 0
	local p = {}
	for y = yloop_a, yloop_b, yloop_c do
		p.y = y
		for z = minp.z, maxp.z do
			p.z = z
			for x = minp.x, maxp.x do
				p.x = x
				local node = minetest.get_node_or_nil(p)

				if node then
					if not diggable[node.name] then
						diggable[node.name] = minetest.get_item_group(node.name, node_type) or 0
						if node_type == 'choppy' then
							diggable[node.name] = diggable[node.name] + minetest.get_item_group(node.name, 'snappy') or 0
							diggable[node.name] = diggable[node.name] + minetest.get_item_group(node.name, 'fleshy') or 0
						end

						if node.name and node.name:find('^door') then
							diggable[node.name] = 0
						end
					end

					if count < max_nodes and diggable[node.name] > 0 then
						minetest.node_dig(p, node, player)
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
			itemstack:add_wear(800)
			return itemstack
		else
			return power(user, pointed_thing.under, 'axe')
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
	on_use = function(itemstack, user, pointed_thing)
		if not (user and pointed_thing) then
			return
		end

		minetest.sound_play('jackhammer', {
			object = user,
			gain = 0.1,
			max_hear_distance = 30
		})

		return power(user, pointed_thing.under, 'pick')
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
		{'default:steel_ingot', precision_tool, 'default:copper_ingot'},
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
		{mod_name..':precision_component', fuel_source, mod_name..':precision_component'},
	}
})

minetest.register_craft({
	output = mod_name..':chainsaw',
	recipe = {
		{'', fuel_source, ''},
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
		{mod_name..':precision_component', fuel_source, mod_name..':precision_component'},
		{'', mod_name..':internal_combustion_engine', ''},
		{'', 'default:mese_crystal', ''},
	}
})

minetest.register_craft({
	output = mod_name..':jackhammer',
	recipe = {
		{'', fuel_source, ''},
		{'', mod_name..':jackhammer', ''},
		{'', mod_name..':precision_component', ''},
	}
})


------------------------------------------------
--  Flaregun
------------------------------------------------

local function flares(player)
	local dir = player:get_look_dir()
	local pos = player:getpos()
	if not pos then
		return
	end
	pos.x = pos.x + dir.x * 10
	pos.y = pos.y + dir.y * 10
	pos.z = pos.z + dir.z * 10
	pos = vector.round(pos)

	local air = minetest.get_content_id('air')
	local gas = minetest.get_content_id('fun_caves:inert_gas')
	local water = minetest.get_content_id('default:water_source')
	local flare_air = minetest.get_content_id(mod_name..':flare_air')
	local flare_gas = minetest.get_content_id(mod_name..':flare_gas')
	local flare_water = minetest.get_content_id(mod_name..':flare_water')
	local vm = minetest.get_voxel_manip()
	if not vm then
		return
	end

	local r = 8
	local minp = vector.subtract(pos, r)
	local maxp = vector.add(pos, r)
	local count = 0
	for i = 1, 50 do
		local fpos = {}
		fpos.x = pos.x + math.random(2 * r + 1) - r - 1
		fpos.y = pos.y + math.random(2 * r + 1) - r - 1
		fpos.z = pos.z + math.random(2 * r + 1) - r - 1
		local n = minetest.get_node_or_nil(fpos)
		if n and n.name == 'air' then
			minetest.set_node(fpos, {name=mod_name..':flare_air'})
			local timer = minetest.get_node_timer(fpos)
			timer:set(math.random(60), 0)
			count = count + 1
		elseif n and n.name == 'fun_caves:inert_gas' then
			minetest.set_node(fpos, {name=mod_name..':flare_gas'})
			local timer = minetest.get_node_timer(fpos)
			timer:set(math.random(60), 0)
			count = count + 1
		elseif n and n.name == 'default:water_source' then
			minetest.set_node(fpos, {name=mod_name..':flare_water'})
			local timer = minetest.get_node_timer(fpos)
			timer:set(math.random(60), 0)
			count = count + 1
		end
	end

	return count
end


do
	local newnode = clone_node('air')
	newnode.light_source = 14
	newnode.on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end
	minetest.register_node(mod_name..':flare_air', newnode)

	newnode = clone_node('default:water_source')
	newnode.light_source = 14
	newnode.liquid_alternative_flowing = mod_name..':flare_water'
	newnode.liquid_alternative_source = mod_name..':flare_water'
	newnode.on_timer = function(pos, elapsed)
		minetest.remove_node(pos)
	end
	minetest.register_node(mod_name..':flare_water', newnode)

	if minetest.registered_items['fun_caves:inert_gas'] then
		newnode = clone_node('fun_caves:inert_gas')
		newnode.light_source = 14
		newnode.on_timer = function(pos, elapsed)
			minetest.remove_node(pos)
		end
		minetest.register_node(mod_name..':flare_gas', newnode)
	end
end

minetest.register_tool(mod_name..':flare_gun', {
	description = 'Flare Gun',
	inventory_image = 'fun_tools_flare_gun.png',
	tool_capabilities = {
		full_punch_interval = 1.2,
		max_drop_level=0,
		groupcaps={
			snappy={times={[2]=1.6, [3]=0.40}, uses=10, maxlevel=1},
		},
		damage_groups = {fleshy=2},
	},
	on_use = function(itemstack, user, pointed_thing)
		if not user then
			return
		end

		--print(itemstack:get_wear())
		if itemstack:get_wear() > 50000 then
			local inv = user:get_inventory()
			if inv then
				if inv:contains_item('main', 'tnt:gunpowder') then
					inv:remove_item('main', 'tnt:gunpowder')
					itemstack:clear()
					itemstack:add_item(mod_name..':flare_gun')
				end
			end
		end

		local count = flares(user)
		itemstack:add_wear(count * 400)
		return itemstack
	end,
})

minetest.register_craft({
	output = mod_name..':flare_gun',
	recipe = {
		{'', '', ''},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		{'', 'tnt:gunpowder', 'group:stick'},
	}
})

minetest.register_craft({
	output = mod_name..':flare_gun',
	type = 'shapeless',
	recipe = { mod_name..':flare_gun', 'tnt:gunpowder', }
})


------------------------------------------------
--  Rope Ladders (like water, but less stupid)
------------------------------------------------

local function rope_remove(pos)
	if not pos then
		return
	end

	for i = 1, 100 do
		local newpos = table.copy(pos)
		newpos.y = newpos.y - i
		local node = minetest.get_node_or_nil(newpos)
		if node and node.name and node.name == mod_name..':rope_ladder_piece' then
			minetest.set_node(newpos, {name='air'})
		else
			break
		end
	end
end

local good_params = {nil, true, true, true, true}
for length = 10, 50, 10 do
	minetest.register_node(mod_name..':rope_ladder_'..length, {
		description = 'Rope Ladder ('..length..' meter)',
		drawtype = 'signlike',
		tiles = {'fun_tools_rope_ladder.png'},
		inventory_image = 'fun_tools_rope_ladder.png',
		wield_image = 'fun_tools_rope_ladder.png',
		paramtype = 'light',
		paramtype2 = 'wallmounted',
		sunlight_propagates = true,
		walkable = false,
		climbable = true,
		is_ground_content = false,
		selection_box = {
			type = 'wallmounted',
		},
		groups = {snappy = 2, oddly_breakable_by_hand = 3, flammable = 2},
		legacy_wallmounted = true,
		sounds = default.node_sound_leaves_defaults(),
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			if not (pointed_thing and pointed_thing.above) then
				return
			end

			local pos_old = pointed_thing.above
			local orig = minetest.get_node_or_nil(pos_old)
			if orig and orig.name and orig.param2 and good_params[orig.param2] then
				for i = 1, length do
					local newpos = table.copy(pos_old)
					newpos.y = newpos.y - i
					local node = minetest.get_node_or_nil(newpos)
					if node and node.name and node.name == 'air' then
						minetest.set_node(newpos, {name=mod_name..':rope_ladder_piece', param2=orig.param2})
					else
						break
					end
				end
			end
		end,
		on_destruct = rope_remove,
	})

	if length > 10 then
		rec = {}
		for i = 10, length, 10 do
			rec[#rec+1] = mod_name..':rope_ladder_10'
		end
		minetest.register_craft({
			output = mod_name..':rope_ladder_'..length,
			type = 'shapeless',
			recipe = rec,
		})
	end
end

minetest.register_node(mod_name..':rope_ladder_piece', {
	description = 'Rope Ladder',
	drawtype = 'signlike',
	tiles = {'fun_tools_rope_ladder.png'},
	inventory_image = 'fun_tools_rope_ladder.png',
	wield_image = 'fun_tools_rope_ladder.png',
	drop = {},
	paramtype = 'light',
	paramtype2 = 'wallmounted',
	buildable_to = true,
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = 'wallmounted',
	},
	groups = {snappy = 2, oddly_breakable_by_hand = 3, flammable = 2},
	legacy_wallmounted = true,
	sounds = default.node_sound_leaves_defaults(),
	on_destruct = rope_remove,
})

if minetest.registered_items['fun_caves:dry_fiber'] then
	minetest.register_alias(mod_name..':dry_fiber', 'fun_caves:dry_fiber')
	mod.which_dry_fiber = 'fun_caves'
else
	local newnode = clone_node('farming:straw')
	newnode.description = 'Dry Fiber'
	minetest.register_node(mod_name..':dry_fiber', newnode)

	minetest.register_craft({
		type = 'fuel',
		recipe = mod_name..':dry_fiber',
		burntime = 5,
	})
end

newnode = clone_node('farming:straw')
newnode.description = 'Bundle of Grass'
newnode.tiles = {'farming_straw.png^[colorize:#00FF00:50'}
minetest.register_node(mod_name..':bundle_of_grass', newnode)

minetest.register_craft({
	output = mod_name..':bundle_of_grass',
	type = 'shapeless',
	recipe = {
		'default:junglegrass', 'default:junglegrass',
		'default:junglegrass', 'default:junglegrass',
	}
})

minetest.register_craft({
	output = mod_name..':bundle_of_grass',
	recipe = {
		{'default:grass_1', 'default:grass_1', 'default:grass_1', },
		{'default:grass_1', 'default:grass_1', 'default:grass_1', },
		{'default:grass_1', 'default:grass_1', 'default:grass_1', },
	}
})

minetest.register_craft({
	type = 'cooking',
	output = mod.which_dry_fiber..':dry_fiber',
	recipe = mod_name..':bundle_of_grass',
	cooktime = 3,
})

do
	local fib = mod.which_dry_fiber..':dry_fiber'
	minetest.register_craft({
		output = mod_name..':rope_ladder_10',
		recipe = {
			{fib, '', fib},
			{fib, fib, fib},
			{fib, '', fib},
		}
	})
end


------------------------------------------------
-- Miscellaneous Recipes
------------------------------------------------

minetest.clear_craft({
	recipe = {
		{'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
		{'default:copper_ingot', 'default:tin_ingot', 'default:copper_ingot'},
		{'default:copper_ingot', 'default:copper_ingot', 'default:copper_ingot'},
	}
})
minetest.register_craft({
	type = 'shapeless',
	output = 'default:bronze_ingot',
	recipe = {
		'default:tin_ingot',
		'default:copper_ingot',
	},
})

minetest.register_craft({
	type = 'shapeless',
	output = 'farming:cotton',
	recipe = {
		'farming:string',
	},
})

minetest.register_craft({
	output = 'default:stick 2',
	recipe = {
		{'group:sapling'}
	}
})

minetest.register_craft({
	output = 'default:stick 2',
	recipe = {
		{'default:cactus'}
	}
})

minetest.register_craft({
	output = 'default:glass',
	type = 'shapeless',
	recipe = {
		'xpanes:pane_flat',
		'xpanes:pane_flat',
		'xpanes:pane_flat',
	}
})

------------------------------------------------


------------------------------------------------
-- easier bed, for early in the game
------------------------------------------------

beds.register_bed(mod_name..':nest', {
	description = 'Nest of Leaves',
	tiles = {
		bottom = {'default_leaves.png^[noalpha'},
		top = {'default_leaves.png^[noalpha'},
	},
	inventory_image = 'default_leaves.png',
	wield_image = 'default_leaves.png',
	nodebox = {
		bottom = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		top = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
	},
	selectionbox = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
	recipe = {
		{'default:leaves', 'default:leaves',},
		{'default:leaves', 'default:leaves',},
	},
})

minetest.register_craft({
	output = mod_name..':nest',
	recipe = {
		{'default:pine_needles', 'default:pine_needles',},
		{'default:pine_needles', 'default:pine_needles',},
	}
})

minetest.register_craft({
	output = mod_name..':nest',
	recipe = {
		{'default:bush_leaves', 'default:bush_leaves',},
		{'default:bush_leaves', 'default:bush_leaves',},
	}
})

minetest.register_craft({
	output = mod_name..':nest',
	recipe = {
		{'default:acacia_leaves', 'default:acacia_leaves',},
		{'default:acacia_leaves', 'default:acacia_leaves',},
	}
})

minetest.register_craft({
	output = mod_name..':nest',
	recipe = {
		{'default:acacia_bush_leaves', 'default:acacia_bush_leaves',},
		{'default:acacia_bush_leaves', 'default:acacia_bush_leaves',},
	}
})


------------------------------------------------
-- Body Pillow
------------------------------------------------

do
	-- Count the pillow images.
	-- Todo: Support choosing images somehow.
	local pillows = 0
	for i = 1, 16 do
		local filename	= mod.path.."/textures/body_pillow_"..string.format('%02d', i)..".png"
		local file = io.open(filename, "r")
		if file then
			io.close(file)
			pillows = pillows + 1
		end
	end

	if pillows % 4 ~= 0 then
		print(mod_name..': There should be four images for the pillow.')
		return
	end

	-- shift-punch to turn the pillow over.
	local function over_p(rev)
		local n1 = mod_name..':body_pillow'
		local n2 = mod_name..':body_pillow_reversed'
		if rev then
			n1, n2 = n2, n1
		end

		minetest.override_item(n1..'_bottom', {
			on_punch = function(pos, node, puncher, pointed_thing)
				if not (puncher and puncher:get_player_control().sneak) then
					return
				end

				local dir = minetest.facedir_to_dir(node.param2)
				local p = vector.add(pos, dir)
				minetest.set_node(p, {name = n2..'_top', param2 = node.param2})
				minetest.swap_node(pos, {name=n2..'_bottom', param2=node.param2})
			end,
		})

		if rev then
			minetest.registered_items[n1].groups.not_in_creative_inventory = 1
		end
	end

	-- Each side is defined as a separate bed.
	local def = {
		description = 'Body Pillow',
		tiles = {
			bottom = {
				'body_pillow_'..string.format('%02d', pillows - 2)..'.png',
				mod_name..'_white_t.png',
			},
			top = {
				'body_pillow_'..string.format('%02d', pillows - 3)..'.png',
				mod_name..'_white_t.png',
			},
		},
		inventory_image = 'body_pillow_icon.png',
		nodebox = {
			bottom = {
				{-0.45, -0.5, -0.5, 0.45, -0.45, 0.5},
				{-0.5, -0.45, -0.5, 0.5, -0.35, 0.5},
				{-0.45, -0.35, -0.5, 0.45, -0.3, 0.5},
			},
			top = {
				{-0.45, -0.5, -0.5, 0.45, -0.45, 0.5},
				{-0.5, -0.45, -0.5, 0.5, -0.35, 0.5},
				{-0.45, -0.35, -0.5, 0.45, -0.3, 0.5},
			},
		},
		selectionbox = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		recipe = {
			{'', 'farming:string', ''},
			{'dye:red', 'dye:yellow', 'dye:blue'},
			{'farming:cotton', 'group:wool', 'farming:cotton'},
		},
	}
	beds.register_bed(mod_name..':body_pillow', def)
	over_p()

	def = table.copy(def)
	def.tiles.bottom[1] = 'body_pillow_'..string.format('%02d', pillows)..'.png'
	def.tiles.top[1] = 'body_pillow_'..string.format('%02d', pillows - 1)..'.png'
	beds.register_bed(mod_name..':body_pillow_reversed', def)
	over_p(true)
end


dofile(mod.path .. '/wallhammer.lua')
