-- Fun_tools beds.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local mod = fun_tools
local mod_name = 'fun_tools'


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
		{'default:pine_bush_needles', 'default:pine_bush_needles',},
		{'default:pine_bush_needles', 'default:pine_bush_needles',},
	}
})

minetest.register_craft({
	output = mod_name..':nest',
	recipe = {
		{'default:blueberry_bush_leaves', 'default:blueberry_bush_leaves',},
		{'default:blueberry_bush_leaves', 'default:blueberry_bush_leaves',},
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

minetest.register_craft({
	output = mod_name..':nest',
	recipe = {
		{'mapgen:leaves_oak', 'mapgen:leaves_oak',},
		{'mapgen:leaves_oak', 'mapgen:leaves_oak',},
	}
})

minetest.register_craft({
	output = mod_name..':nest',
	recipe = {
		{'default:dry_shrub', 'default:dry_shrub',},
		{'default:dry_shrub', 'default:dry_shrub',},
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
		local filename	= mod.path..'/textures/body_pillow_'..string.format('%02d', i)..'.png'
		local file = io.open(filename, 'r')
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
