-- Fun_tools teleport.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local mod = fun_tools
local mod_name = 'fun_tools'


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
	drawtype = 'plantlike',
	paramtype = 'light',
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


------------------------------------------------
-- Magic Beanstalks
------------------------------------------------


do
	local newnode = mod.clone_node('default:leaves')
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
