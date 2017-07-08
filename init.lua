-- Fun_tools init.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

fun_tools_mod = {}
fun_tools_mod.version = "1.0"
fun_tools_mod.path = minetest.get_modpath(minetest.get_current_modname())
fun_tools_mod.world = minetest.get_worldpath()
fun_tools_mod.which_dry_fiber = 'fun_tools'


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

	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local data = vm:get_data()
	local drops = {}
	local names = {}
	local diggable = {}
	local tree_like = {}
	local leaf_like = {}
	local stone_like = {}
	local count = 0
	local p = {}
	for y = yloop_a, yloop_b, yloop_c do
		p.y = y
		for z = minp.z, maxp.z do
			p.z = z
			local ivm = area:index(minp.x, y, z)
			for x = minp.x, maxp.x do
				p.x = x
				if not names[data[ivm]] then
					names[data[ivm]] = minetest.get_name_from_content_id(data[ivm])
				end

				if not diggable[data[ivm]] then
					diggable[data[ivm]] = minetest.get_item_group(names[data[ivm]], node_type) or 0
					if node_type == 'choppy' then
						diggable[data[ivm]] = diggable[data[ivm]] + minetest.get_item_group(names[data[ivm]], 'snappy') or 0
						diggable[data[ivm]] = diggable[data[ivm]] + minetest.get_item_group(names[data[ivm]], 'fleshy') or 0
					end

					if names[data[ivm]] and names[data[ivm]]:find('^door') then
						diggable[data[ivm]] = 0
					end
				end

				if count < max_nodes and diggable[data[ivm]] > 0 and not minetest.is_protected(p, player_name) then
					drops[data[ivm]] = (drops[data[ivm]] or 0) + 1
					data[ivm] = air
					count = count + 1
				end
				ivm = ivm + 1
			end
		end
	end
	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()

	local tool = player:get_wielded_item()
	for id, number in pairs(drops) do
		for i = 1, number do
			local drops = minetest.get_node_drops(names[id], tool:get_name())
			minetest.handle_node_drops(pos, drops, player)
		end

		local tp = tool:get_tool_capabilities()
		local def = ItemStack({name=names[id]}):get_definition()
		local dp = minetest.get_dig_params(def.groups, tp)
		if not dp then
			return
		end

    --print(dp.wear * number)
		tool:add_wear(dp.wear * number)
	end

	return tool
end

local chainsaw_time = {}
minetest.register_tool("fun_tools:chainsaw", {
	description = "Chainsaw",
	inventory_image = "fun_tools_chainsaw.png",
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

minetest.register_tool("fun_tools:jackhammer", {
	description = "Jackhammer",
	inventory_image = "fun_tools_jackhammer.png",
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

minetest.register_craftitem("fun_tools:precision_component", {
  description = 'Precision Component',
  drawtype = "plantlike",
  paramtype = "light",
  tiles = {'fun_tools_component.png'},
  inventory_image = 'fun_tools_component.png',
  groups = {dig_immediate = 3},
  sounds = default.node_sound_metal_defaults(),
})

minetest.register_craft({
	output = 'fun_tools:precision_component',
	recipe = {
		{'', '', ''},
		{'default:steel_ingot', precision_tool, 'default:copper_ingot'},
		{'', '', ''},
	}
})

minetest.register_craftitem("fun_tools:internal_combustion_engine", {
  description = 'Internal Combustion Engine',
  drawtype = "plantlike",
  paramtype = "light",
  tiles = {'fun_tools_engine.png'},
  inventory_image = 'fun_tools_engine.png',
  groups = {dig_immediate = 3},
  sounds = default.node_sound_metal_defaults(),
})

minetest.register_craft({
	output = 'fun_tools:internal_combustion_engine',
	recipe = {
		{'', 'fun_tools:precision_component', ''},
		{'fun_tools:precision_component', 'default:steelblock', 'fun_tools:precision_component'},
		{'', 'fun_tools:precision_component', ''},
	}
})

minetest.register_craft({
	output = 'fun_tools:chainsaw',
	recipe = {
		{'', 'default:diamond', ''},
		{'', 'fun_tools:internal_combustion_engine', ''},
		{'fun_tools:precision_component', fuel_source, 'fun_tools:precision_component'},
	}
})

minetest.register_craft({
	output = 'fun_tools:chainsaw',
	recipe = {
		{'', fuel_source, ''},
		{'', 'fun_tools:chainsaw', ''},
		{'', 'fun_tools:precision_component', ''},
	}
})

minetest.register_craft({
	output = 'fun_tools:jackhammer',
	recipe = {
		{'fun_tools:precision_component', fuel_source, 'fun_tools:precision_component'},
		{'', 'fun_tools:internal_combustion_engine', ''},
		{'', 'default:diamond', ''},
	}
})

minetest.register_craft({
	output = 'fun_tools:jackhammer',
	recipe = {
		{'', fuel_source, ''},
		{'', 'fun_tools:jackhammer', ''},
		{'', 'fun_tools:precision_component', ''},
	}
})


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
	local flare_air = minetest.get_content_id('fun_tools:flare_air')
	local flare_gas = minetest.get_content_id('fun_tools:flare_gas')
  local flare_water = minetest.get_content_id('fun_tools:flare_water')
	--local flare = minetest.get_content_id('fun_tools:flare')
	local vm = minetest.get_voxel_manip()
	if not vm then
		return
	end

	local r = 8
	local minp = vector.subtract(pos, r)
	local maxp = vector.add(pos, r)
	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local data = vm:get_data()
	local count = 0
	for i = 1, 50 do
		local x = pos.x + math.random(2 * r + 1) - r - 1
		local y = pos.y + math.random(2 * r + 1) - r - 1
		local z = pos.z + math.random(2 * r + 1) - r - 1
		local ivm = area:index(x, y, z)
		if data[ivm] == air then
			data[ivm] = flare_air
			count = count + 1
    elseif data[ivm] == gas then
			data[ivm] = flare_gas
			count = count + 1
    elseif data[ivm] == water then
			data[ivm] = flare_water
			count = count + 1
		end
	end
	vm:set_data(data)
	vm:calc_lighting(minp, maxp)
	vm:update_liquids()
	vm:write_to_map()
	vm:update_map()

	return count
end

do
  local newnode = clone_node("air")
  newnode.light_source = 14
  minetest.register_node('fun_tools:flare_air', newnode)

  newnode = clone_node("default:water_source")
  newnode.light_source = 14
	newnode.liquid_alternative_flowing = "fun_tools:flare_water"
	newnode.liquid_alternative_source = "fun_tools:flare_water"
  minetest.register_node('fun_tools:flare_water', newnode)

  if minetest.registered_items['fun_caves:inert_gas'] then
    newnode = clone_node("fun_caves:inert_gas")
    newnode.light_source = 14
    minetest.register_node('fun_tools:flare_gas', newnode)
  end
end

--minetest.register_node("fun_tools:flare", {
--	description = "Flare Gun",
--	drawtype = "plantlike",
--	visual_scale = 0.75,
--	tiles = {"fun_tools_flare.png"},
--	paramtype = "light",
--	sunlight_propagates = true,
--	light_source = 14,
--	walkable = false,
--	diggable = false,
--	pointable = false,
--	is_ground_content = false,
--})

minetest.register_tool("fun_tools:flare_gun", {
	description = "Flare Gun",
	inventory_image = "fun_tools_flare_gun.png",
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
          itemstack:add_item('fun_tools:flare_gun')
        end
      end
    end

		local count = flares(user)
		itemstack:add_wear(count * 400)
		return itemstack
	end,
})

minetest.register_craft({
	output = 'fun_tools:flare_gun',
	recipe = {
		{'', '', ''},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		{'', 'tnt:gunpowder', 'group:stick'},
	}
})

minetest.register_craft({
	output = 'fun_tools:flare_gun',
  type = 'shapeless',
	recipe = { 'fun_tools:flare_gun', 'tnt:gunpowder', }
})


minetest.register_abm({
	nodenames = {"fun_tools:flare_air",},
	interval = 5,
	chance = 10,
	action = function(pos, node)
		if not (pos and node) then
			return
		end

		minetest.remove_node(pos)
	end,
})

minetest.register_abm({
	nodenames = {"fun_tools:flare_gas",},
	interval = 5,
	chance = 10,
	action = function(pos, node)
		if not (pos and node) then
			return
		end

		minetest.set_node(pos, {name='fun_caves:inert_gas'})
	end,
})

minetest.register_abm({
	nodenames = {"fun_tools:flare_water",},
	interval = 5,
	chance = 10,
	action = function(pos, node)
		if not (pos and node) then
			return
		end

		minetest.set_node(pos, {name='default:water_source'})
	end,
})

--minetest.register_abm({
--	nodenames = {"fun_tools:flare",},
--	interval = 5,
--	chance = 10,
--	action = function(pos, node)
--		if not (pos and node) then
--			return
--		end
--
--		minetest.remove_node(pos)
--	end,
--})


local function rope_remove(pos)
	if not pos then
		return
	end

	for i = 1, 100 do
		local newpos = table.copy(pos)
		newpos.y = newpos.y - i
		local node = minetest.get_node_or_nil(newpos)
		if node and node.name and node.name == 'fun_tools:rope_ladder_piece' then
			minetest.set_node(newpos, {name='air'})
		else
			break
		end
	end
end

local good_params = {nil, true, true, true, true}
for length = 10, 50, 10 do
	minetest.register_node("fun_tools:rope_ladder_"..length, {
		description = "Rope Ladder ("..length.." meter)",
		drawtype = "signlike",
		tiles = {"fun_tools_rope_ladder.png"},
		inventory_image = "fun_tools_rope_ladder.png",
		wield_image = "fun_tools_rope_ladder.png",
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		walkable = false,
		climbable = true,
		is_ground_content = false,
		selection_box = {
			type = "wallmounted",
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
						minetest.set_node(newpos, {name='fun_tools:rope_ladder_piece', param2=orig.param2})
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
			rec[#rec+1] = 'fun_tools:rope_ladder_10'
		end
		minetest.register_craft({
			output = 'fun_tools:rope_ladder_'..length,
			type = 'shapeless',
			recipe = rec,
		})
	end
end

minetest.register_node("fun_tools:rope_ladder_piece", {
	description = "Rope Ladder",
	drawtype = "signlike",
	tiles = {"fun_tools_rope_ladder.png"},
	inventory_image = "fun_tools_rope_ladder.png",
	wield_image = "fun_tools_rope_ladder.png",
	drop = {},
	paramtype = "light",
	paramtype2 = "wallmounted",
	buildable_to = true,
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
	},
	groups = {snappy = 2, oddly_breakable_by_hand = 3, flammable = 2},
	legacy_wallmounted = true,
	sounds = default.node_sound_leaves_defaults(),
	on_destruct = rope_remove,
})

if minetest.registered_items['fun_caves:dry_fiber'] then
  minetest.register_alias('fun_tools:dry_fiber', 'fun_caves:dry_fiber')
  fun_tools_mod.which_dry_fiber = 'fun_caves'
else
  local newnode = clone_node("farming:straw")
  newnode.description = "Dry Fiber"
  minetest.register_node("fun_tools:dry_fiber", newnode)

  minetest.register_craft({
    type = "fuel",
    recipe = "fun_tools:dry_fiber",
    burntime = 5,
  })
end

newnode = clone_node("farming:straw")
newnode.description = 'Bundle of Grass'
newnode.tiles = {'farming_straw.png^[colorize:#00FF00:50'}
minetest.register_node("fun_tools:bundle_of_grass", newnode)

minetest.register_craft({
	output = 'fun_tools:bundle_of_grass',
	type = 'shapeless',
	recipe = {
		'default:junglegrass', 'default:junglegrass',
		'default:junglegrass', 'default:junglegrass',
	}
})

minetest.register_craft({
  output = 'fun_tools:bundle_of_grass',
  recipe = {
    {'default:grass_1', 'default:grass_1', 'default:grass_1', },
    {'default:grass_1', 'default:grass_1', 'default:grass_1', },
    {'default:grass_1', 'default:grass_1', 'default:grass_1', },
  }
})

minetest.register_craft({
	type = "cooking",
	output = fun_tools_mod.which_dry_fiber..":dry_fiber",
	recipe = 'fun_tools:bundle_of_grass',
	cooktime = 3,
})

do
  local fib = fun_tools_mod.which_dry_fiber..':dry_fiber'
  minetest.register_craft({
    output = 'fun_tools:rope_ladder_10',
    recipe = {
      {fib, '', fib},
      {fib, fib, fib},
      {fib, '', fib},
    }
  })
end


dofile(fun_tools_mod.path .. "/wallhammer.lua")


minetest.register_craft({
	output = "default:stick 2",
	recipe = {
		{"group:sapling"}
	}
})

minetest.register_craft({
	output = "default:stick 2",
	recipe = {
		{"default:cactus"}
	}
})


minetest.register_craft({
	output = "default:glass",
  type = 'shapeless',
	recipe = {
		"xpanes:pane_flat",
		"xpanes:pane_flat",
		"xpanes:pane_flat",
	}
})


beds.register_bed("fun_tools:nest", {
	description = "Nest of Leaves",
  tiles = {
    bottom = {"default_leaves.png^[noalpha"},
    top = {"default_leaves.png^[noalpha"},
  },
	inventory_image = "default_leaves.png",
	wield_image = "default_leaves.png",
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
