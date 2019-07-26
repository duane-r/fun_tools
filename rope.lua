-- Fun_tools rope.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local mod = fun_tools
local mod_name = 'fun_tools'


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
-- After taking out the underground fiber sources, it's too
--  hard to gather to bother with short ropes.
for length = 50, 50, 10 do
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

	--[[
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
	--]]
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

do
	local newnode = mod.clone_node('farming:straw')
	newnode.description = 'Dry Fiber'
	minetest.register_node(mod_name..':dry_fiber', newnode)

	minetest.register_craft({
		type = 'fuel',
		recipe = mod_name..':dry_fiber',
		burntime = 5,
	})
end

do
	local newnode = mod.clone_node('farming:straw')
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
		{'group:grass', '', 'group:grass', },
		{'group:grass', 'group:grass', 'group:grass', },
		{'group:grass', '', 'group:grass', },
	}
})

minetest.register_craft({
	output = mod_name..':bundle_of_grass',
	recipe = {
		{'group:dry_grass', '', 'group:dry_grass', },
		{'group:dry_grass', 'group:dry_grass', 'group:dry_grass', },
		{'group:dry_grass', '', 'group:dry_grass', },
	}
})

minetest.register_craft({
	output = mod_name..':bundle_of_grass',
	recipe = {
		{'default:marram_grass_1', '', 'default:marram_grass_1', },
		{'default:marram_grass_1', 'default:marram_grass_1', 'default:marram_grass_1', },
		{'default:marram_grass_1', '', 'default:marram_grass_1', },
	}
})

minetest.register_craft({
	type = 'cooking',
	output = mod_name..':dry_fiber',
	recipe = mod_name..':bundle_of_grass',
	cooktime = 3,
})

do
	local fib = mod_name..':dry_fiber'
	minetest.register_craft({
		output = mod_name..':rope_ladder_50',
		recipe = {
			{fib, '', fib},
			{fib, fib, fib},
			{fib, '', fib},
		}
	})
end
