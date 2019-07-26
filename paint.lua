-- Fun_tools paint.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local mod = fun_tools
local mod_name = 'fun_tools'


------------------------------------------------
-- Magic Paint... really!
------------------------------------------------


do
	for _, i in pairs({ 'bucket:bucket_empty', 'wooden_bucket:bucket_wood_empty' }) do
		local n = minetest.registered_items[i]
		if n then
			local groups = n.groups
			local ct = 0
			for k, v in pairs(groups) do
				ct = ct + 1
			end
			if ct == 0 then
				groups = {}
			end
			groups.buckets = 1
			n.groups = groups
			minetest.override_item(i, { groups = groups })
		end
	end

	local descs = {
		{ 'Stone', 'stone', 'elixirs_paint_gray', 'grey', {
			['default:desert_stonebrick'] = 'default:stonebrick',
			['default:sandstonebrick'] = 'default:stonebrick',
		}, },
		{ 'Desert Stone', 'desert_stone', 'elixirs_paint_red', 'red', {
			['default:stonebrick'] = 'default:desert_stonebrick',
			['default:sandstonebrick'] = 'default:desert_stonebrick',
		}, },
		{ 'Sandstone', 'sandstone', 'elixirs_paint_sand', 'white', {
			['default:stonebrick'] = 'default:sandstonebrick',
			['default:desert_stonebrick'] = 'default:sandstonebrick',
		}, },
	}

	local convert = { }

	for _, desc in pairs(descs) do
		local name = desc[1]
		local material = desc[2]
		local image = desc[3]..'.png'
		local dye = 'dye:'..desc[4]
		convert[material] = desc[5]

		minetest.register_craftitem(mod_name..':paint_'..material, {
			description = 'Dr Robertson\'s Patented '..name..' Paint',
			drawtype = 'plantlike',
			paramtype = 'light',
			tiles = { image },
			inventory_image = image,
			groups = { dig_immediate = 3, vessel = 1 },
			--sounds = default.node_sound_glass_defaults(),
			on_use = function(itemstack, user, pointed_thing)
				if not (itemstack and user and pointed_thing and pointed_thing.under) then
					return
				end

				--print(dump(pointed_thing))
				local n = minetest.get_node_or_nil(pointed_thing.under)
				if not n then
					return
				end

				local dn = minetest.registered_items[n.name]
				if not dn or not dn.groups then
					return
				end

				local dto = convert[material][n.name]
				if dto then
					minetest.swap_node(pointed_thing.under, { name=dto, param2 = n.param2 })
				else
					--print(n.name)
					return
				end

				itemstack:take_item()
				return itemstack
			end,
		})

		minetest.register_craft({
			type = 'shapeless',
			output = mod_name..':paint_'..material..' 20',
			recipe = {
				mod.magic_ingredient,
				dye,
				dye,
				'group:buckets',
			},
		})
	end
end
