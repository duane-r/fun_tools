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

mod.creative = minetest.setting_getbool('creative_mode')


mod.environ_mod = 'mapgen'
local environ_mod = mod.environ_mod


local fast_load = minetest.setting_getbool('fun_tools_fast_load')
if fast_load == nil then
	fast_load = true
end

local remove_bronze = minetest.setting_getbool('fun_tools_remove_bronze')
if remove_bronze == nil then
	remove_bronze = true
end

local torchlight = minetest.setting_getbool('fun_tools_torchlight')
if torchlight == nil then
	torchlight = true
end


function mod.clone_node(name)
	if not (name and type(name) == 'string') then
		return
	end

	local node = minetest.registered_nodes[name]
	local node2 = table.copy(node)
	return node2
end
local clone_node = mod.clone_node


function mod.puff(p)
	local radius = 1
	local velocity = 1.9*math.log(radius + 1)
	local q = 20*math.log(radius + 1)
	minetest.add_particlespawner({
		amount = q,
		time = 0.3,
		minpos = vector.subtract(p, radius),
		maxpos = vector.add(p, radius),
		minvel = {x = -velocity, y = -velocity, z = -velocity},
		maxvel = {x = velocity, y = velocity, z = velocity},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 9,
		maxsize = 10,
		texture = "tnt_smoke.png",
	})
	radius = 1
	velocity = 1.9*math.log(radius + 1)
	q = 20*math.log(radius + 1)
	minetest.add_particlespawner({
		amount = q,
		time = 0.3,
		minpos = vector.subtract(p, radius),
		maxpos = vector.add(p, radius),
		minvel = {x = -velocity, y = -velocity, z = -velocity},
		maxvel = {x = velocity, y = velocity, z = velocity},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 9,
		maxsize = 10,
		texture = "tnt_smoke.png",
	})
end


function mod.ranged_attack(itemstack, user, range)
	local shot
	local dir = user:get_look_dir()
	local playerpos = user:getpos()
	local p = table.copy(playerpos)
	p.y = p.y + 1.5

	local eps = {}
	for id, ent in pairs(minetest.luaentities) do
		if ent and ent.object and ent.object.get_pos and (ent._is_a_mob or ent.health) then
			local ep = ent.object:get_pos()
			if vector.distance(ep, p) < range then
				eps[id] = ep
			end
		end
	end

	for _ = 1, range do
		p = vector.add(p, dir)

		for id in pairs(eps) do
			if vector.distance(eps[id], p) < 1 then
				local ent = minetest.luaentities[id]
				if ent and ent._printed_name then
					local player_name = user:get_player_name()
					if player_name then
						minetest.chat_send_player(player_name, 'You hit the ' .. ent._printed_name)
					end
				end

				ent.object:punch(user, nil, itemstack:get_tool_capabilities(), nil)
				shot = true
				break
			end
		end

		if shot then
			mod.puff(p)
			break
		end
	end
end


function mod.use_inventory_items(user, items)
	if not (user and items) then
		return
	end

	local inv = user:get_inventory()
	if not inv then
		return
	end

	for _, item in pairs(items) do
		if not inv:contains_item('main', item) then
			return
		end
	end

	for _, item in pairs(items) do
		inv:remove_item('main', item)
	end

	return true
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
	on_use = function(_, user, pointed_thing)
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
		{'default:steel_ingot', precision_tool, 'default:gold_ingot'},
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

	local vm = minetest.get_voxel_manip()
	if not vm then
		return
	end

	local r = 8
	local count = 0
	for _ = 1, 50 do
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
		elseif n and n.name == environ_mod..':inert_gas' then
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
	newnode.on_timer = function(pos)
		minetest.remove_node(pos)
	end
	minetest.register_node(mod_name..':flare_air', newnode)

	newnode = clone_node('default:water_source')
	newnode.light_source = 14
	newnode.liquid_alternative_flowing = mod_name..':flare_water'
	newnode.liquid_alternative_source = mod_name..':flare_water'
	newnode.on_timer = function(pos)
		minetest.remove_node(pos)
	end
	minetest.register_node(mod_name..':flare_water', newnode)

	if minetest.registered_items[environ_mod..':inert_gas'] then
		newnode = clone_node(environ_mod..':inert_gas')
		newnode.light_source = 14
		newnode.on_timer = function(pos)
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
	on_use = function(itemstack, user)
		if not user then
			return
		end

		local wear = (flares(user) or 0) * 400

		if itemstack:get_wear() + wear > 50000 then
			if mod.use_inventory_items(user, { 'tnt:gunpowder', }) then
				itemstack:clear()
				itemstack:add_item(mod_name..':flare_gun')
			end
		else
			if not mod.creative then
				itemstack:add_wear(wear)
			end
		end

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
		after_place_node = function(_, _, _, pointed_thing)
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
		local rec = {}
		for _ = 10, length, 10 do
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

if minetest.registered_items[environ_mod..':dry_fiber'] then
	minetest.register_alias(mod_name..':dry_fiber', environ_mod..':dry_fiber')
	mod.which_dry_fiber = environ_mod
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

do
	local newnode = clone_node('farming:straw')
	newnode.description = 'Bundle of Grass'
	newnode.tiles = {'farming_straw.png^[colorize:#00FF00:50'}
	minetest.register_node(mod_name..':bundle_of_grass', newnode)
end

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
	output = mod_name..':bundle_of_grass',
	recipe = {
		{'default:marram_grass_1', 'default:marram_grass_1', 'default:marram_grass_1', },
		{'default:marram_grass_1', 'default:marram_grass_1', 'default:marram_grass_1', },
		{'default:marram_grass_1', 'default:marram_grass_1', 'default:marram_grass_1', },
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

if remove_bronze then
	-- Remove the crappy bronze stuff.
	local bad_recipes = {
		'default:bronze_ingot',
		'default:copper_ingot',
		'default:tin_ingot',
		'default:axe_bronze',
		'default:pick_bronze',
		'default:sword_bronze',
		'default:shovel_bronze',
		'default:bronzeblock',
		'stairs:slab_bronzeblock',
		'stairs:stair_bronzeblock',
		'stairs:stair_inner_bronzeblock',
		'stairs:stair_outer_bronzeblock',
	}

	for _, rec in pairs(bad_recipes) do
		local res = minetest.clear_craft({
			output = rec,
		})
		if not res then
			print(mod_name..': Can\'t clear '..rec..' recipe.')
		end
	end

	minetest.register_craft({
		output = "binoculars:binoculars",
		recipe = {
			{"default:obsidian_glass", "", "default:obsidian_glass"},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
			{"default:obsidian_glass", "", "default:obsidian_glass"},
		}
	})
end

do
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
end

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
			on_punch = function(pos, node, puncher)
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


------------------------------------------------
-- Flintlock Pistol
------------------------------------------------


minetest.register_tool(mod_name..':flintlock_pistol_unloaded', {
	description = 'Flintlock Pistol (unloaded)',
	drawtype = 'plantlike',
	paramtype = 'light',
	tiles = {'fun_tools_flintlock_pistol.png'},
	inventory_image = 'fun_tools_flintlock_pistol.png',
	groups = {dig_immediate = 3},
	sounds = default.node_sound_metal_defaults(),
	on_use = function(itemstack, user, pointed_thing)
		if not (fast_load and user and pointed_thing) then
			return
		end

		if mod.use_inventory_items(user, { 'tnt:gunpowder', mod_name..':gold_ball' }) then
			itemstack:clear()
			itemstack:add_item(mod_name..':flintlock_pistol_loaded')
			return itemstack
		end
	end,
})

minetest.register_craftitem(mod_name..':gold_ball', {
	description = 'Gold Ball',
	inventory_image = 'fun_tools_gold_balls.png',
	--groups = {dig_immediate = 3},
})

minetest.register_craft({
	output = mod_name..':gold_ball 10',
	type = 'cooking',
	recipe = 'default:gold_ingot',
	cooktime = 2,
})

minetest.register_craft({
	output = mod_name..':flintlock_pistol_loaded',
	type = 'shapeless',
	recipe = {'tnt:gunpowder', mod_name..':gold_ball', mod_name..':flintlock_pistol_unloaded',},
})

minetest.register_craft({
	output = mod_name..':flintlock_pistol_unloaded',
	recipe = {
		{'', '', ''},
		{'default:steel_ingot', 'group:wood', 'default:flint'},
		{'', '', precision_tool},
	},
})

minetest.register_tool(mod_name..':flintlock_pistol_loaded', {
	description = 'Flintlock Pistol (loaded)',
	drawtype = 'plantlike',
	paramtype = 'light',
	tiles = {'fun_tools_flintlock_pistol.png'},
	inventory_image = 'fun_tools_flintlock_pistol.png',
	groups = {dig_immediate = 3},
	sounds = default.node_sound_metal_defaults(),
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=80, maxlevel=2},
		},
		damage_groups = {fleshy=15},
	},
	on_use = function(itemstack, user, pointed_thing)
		if not (user and pointed_thing) then
			return
		end

		minetest.sound_play('flintlock', {
			object = user,
			gain = 0.1,
			max_hear_distance = 30
		})
		mod.ranged_attack(itemstack, user, 25)

		itemstack:clear()
		itemstack:add_item(mod_name..':flintlock_pistol_unloaded')
		return itemstack
	end,
})


------------------------------------------------
-- Golden Tesseract
------------------------------------------------


mod.item_used = {}
function mod.teleport(itemstack, user, sound)
	local delay = 1.5

	if not user then
		return
	end

	local player_name = user:get_player_name()
	if os.time() - (mod.item_used[player_name] or 0) < (delay or 1) then
		return
	end

	mod.item_used[player_name] = os.time()

	if sound then
		minetest.sound_play(sound, {
			object = user,
			gain = 0.1,
			max_hear_distance = 30
		})
	end

	local range = 100
	local dir = user:get_look_dir()
	local playerpos = user:getpos()
	local p = table.copy(playerpos)
	local lp = playerpos
	p.y = p.y + 1.5

	for dist = 1, range do
		p = vector.add(p, dir)
		local n = minetest.get_node_or_nil(p)
		if (n and n.name and n.name ~= 'air')
			or (dist == range and n and n.name and n.name == 'air') then
			user:set_pos(lp)
			if not mod.creative then
				itemstack:add_wear(dist * 100)
			end
			return itemstack
		end
		lp = p
	end
end

minetest.register_tool(mod_name..':gold_tess', {
	description = 'Golden Tesseract',
	drawtype = "plantlike",
	paramtype = "light",
	tiles = { mod_name..'_gold_tess.png' },
	inventory_image = mod_name..'_gold_tess.png',
	groups = {dig_immediate = 3},
	tool_capabilities = {
		full_punch_interval = 1.5,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=2.00, [2]=0.80, [3]=0.40}, uses=80, maxlevel=2},
		},
		damage_groups = {},
	},
	on_use = function(itemstack, user, pointed_thing)
		if not user then
			return
		end

		local sound
		return mod.teleport(itemstack, user, sound)
	end,
})

minetest.register_craft({
	output = mod_name..':gold_tess',
	recipe = {
		{'default:gold_ingot', '', 'default:gold_ingot'},
		{'', 'default:mese_crystal', ''},
		{'default:gold_ingot', '', 'default:gold_ingot'},
	},
})

do
	local newnode = clone_node('default:leaves')
	newnode.description = 'Magic Beanstalk'
	newnode.walkable = false
	newnode.climbable = true
	minetest.register_node(mod_name..':magic_beanstalk', newnode)

	local growable = {
		['default:dirt'] = true,
		['default:sand'] = true,
		['air'] = true,
		[mod_name..':magic_bean'] = true,
		['mapgen:cloud'] = true,
		['mapgen:wet_cloud'] = true,
		['mapgen:storm_cloud'] = true,
		['mapgen:wispy_cloud'] = true,
	}
	function mod.grow_beanstalk(pos)
		print('Growing a beanstalk')
		local n = minetest.get_node(pos)
		if n.name == mod_name..':magic_bean' then
			local p = table.copy(pos)
			local ps = table.copy(p)
			for y = pos.y - 1, pos.y + 80 do
				p.y = y
				ps.y = y
				ps.x = pos.x + (y % 4 == 0 and 1 or 0) + (y % 4 == 2 and -1 or 0)
				ps.z = pos.z + (y % 4 == 1 and 1 or 0) + (y % 4 == 3 and -1 or 0)
				local np = minetest.get_node_or_nil(p)
				if np and growable[np.name] then
					minetest.set_node(p, {name = mod_name..':magic_beanstalk'})
				end
				local nps = minetest.get_node_or_nil(ps)
				if nps and growable[nps.name] then
					minetest.set_node(ps, {name = mod_name..':magic_beanstalk'})
				end
			end
		end
	end

	minetest.register_node(mod_name..':magic_bean', {
		description = 'Magic Bean',
		drawtype = 'plantlike',
		tiles = {'fun_tools_magic_bean.png'},
		inventory_image = 'fun_tools_magic_bean.png',
		wield_image = 'fun_tools_magic_bean.png',
		paramtype = 'light',
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,
		on_timer = mod.grow_beanstalk,
		selection_box = {
			type = 'fixed',
			fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, 2 / 16, 4 / 16}
		},
		groups = {snappy = 2, dig_immediate = 3, flammable = 2,
			attached_node = 1, sapling = 1},
		sounds = default.node_sound_leaves_defaults(),

		on_construct = function(pos)
			minetest.get_node_timer(pos):start(math.random(30, 150))
		end,
	})
end

do
	minetest.register_craftitem(mod_name..':charcoal', {
		description = 'Charcoal Briquette',
		inventory_image = 'default_coal_lump.png',
		groups = {coal = 1}
	})

	minetest.register_craft({
		type = 'fuel',
		recipe = mod_name..':charcoal',
		burntime = 50,
	})

	minetest.register_craft({
		type = 'cooking',
		output = mod_name..':charcoal',
		recipe = 'group:tree',
	})

	minetest.register_craft({
		output = 'default:torch 4',
		recipe = {
			{'group:coal'},
			{'group:stick'},
		}
	})

	minetest.register_craft({
		output = 'default:coalblock',
		recipe = {
			{'group:coal', 'group:coal', 'group:coal'},
			{'group:coal', 'group:coal', 'group:coal'},
			{'group:coal', 'group:coal', 'group:coal'},
		}
	})

	if minetest.get_modpath('tnt') then
		minetest.register_craft({
			output = 'tnt:gunpowder',
			type = 'shapeless',
			recipe = {'group:coal', 'default:gravel'}
		})
	end
end


if torchlight then
	local torch_burn_time = {}
	local last_torch_check
	minetest.register_globalstep(function(dtime)
		if not (dtime and type(dtime) == 'number') then
			return
		end

		local time = minetest.get_gametime()
		if not (time and type(time) == 'number') then
			return
		end

		-- Trap check
		if last_torch_check and time - last_torch_check < 2 then
			return
		end

		local players = minetest.get_connected_players()
		if not (players and type(players) == 'table') then
			return
		end

		for i = 1, #players do
			local player = players[i]
			local item = player:get_wielded_item()
			if not item:get_name():find('torch') then
				return
			end

			local pos = player:getpos()
			pos = vector.round(pos)
			pos.y = pos.y + 1

			local l = minetest.get_node_light(pos, nil)
			if l > 13 then
				return
			end

			local n = minetest.get_node_or_nil(pos)
			if n and n.name == 'air' then
				local player_name = player:get_player_name()
				torch_burn_time[player_name] = (torch_burn_time[player_name] or 0) + 1

				minetest.set_node(pos, { name = mod_name..':flare_air' })
				local timer = minetest.get_node_timer(pos)
				timer:start(2)

				if torch_burn_time[player_name] > 300 then
					item:take_item(1)
					player:set_wielded_item(item)
					torch_burn_time[player_name] = 0
				end
			end
		end
	end)
end


--[[
minetest.register_lbm({
	name = mod_name..':flare_killer',
	nodenames = { mod_name..':flare_air' },
	action = function(pos, node)
		minetest.remove_node(pos)
	end,
})
--]]
