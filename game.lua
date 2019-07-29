-- Fun_tools game.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local mod = fun_tools
local mod_name = 'fun_tools'


------------------------------------------------
-- Recipes To Fix The Default Game
------------------------------------------------

if mod.remove_bronze then
	-- Remove the crappy bronze stuff.
	local bad_recipes = {
		'binoculars:binoculars',
		'default:axe_bronze',
		'default:bronzeblock',
		'default:bronze_ingot',
		'default:copper_ingot',
		'default:pick_bronze',
		'default:shovel_bronze',
		'default:sword_bronze',
		'default:tinblock',
		'default:tin_ingot',
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
		output = 'binoculars:binoculars',
		recipe = {
			{'default:obsidian_glass', '', 'default:obsidian_glass'},
			{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
			{'default:obsidian_glass', '', 'default:obsidian_glass'},
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

	minetest.register_craft({
		output = 'default:paper',
		type = 'shapeless',
		recipe = { 'farming:cotton', 'farming:cotton', 'farming:cotton' }
	})

	minetest.register_craft({
		output = 'default:paper',
		type = 'shapeless',
		recipe = { 'group:wood', 'group:stone', mod.magic_ingredient }
	})
end


do
	local bad_recipes = {
		'default:torch',
		'default:coalblock',
		'tnt:gunpowder',
	}

	for _, rec in pairs(bad_recipes) do
		local res = minetest.clear_craft({
			output = rec,
		})
		if not res then
			print(mod_name..': Can\'t clear '..rec..' recipe.')
		end
	end

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


-- This is hard to place, so I'm putting it here.
if minetest.get_modpath('mapgen') then
	local cnode = mod.clone_node('default:glass')
	cnode.description = 'Moon Glass'
	cnode.light_source = 14
	minetest.register_node(mod_name..':moon_glass', cnode)

	minetest.register_craft({
		output = mod_name..':moon_glass',
		type = 'shapeless',
		recipe = { 'default:glass', 'mapgen:glowing_fungus', mod.magic_ingredient },
	})
end
