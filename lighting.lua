-- Fun_tools lighting.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local mod = fun_tools
local mod_name = 'fun_tools'


------------------------------------------------
--  Flaregun
------------------------------------------------

local function flares(player)
	local dir = player:get_look_dir()
	local pos = player:get_pos()
	if not pos then
		return
	end
	pos.x = pos.x + dir.x * 10
	pos.y = pos.y + dir.y * 10
	pos.z = pos.z + dir.z * 10
	pos = vector.round(pos)

	--[[
	local vm = minetest.get_voxel_manip()
	if not vm then
		return
	end
	--]]

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
		elseif n and n.name == mod.environ_mod..':inert_gas' then
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
	local newnode = mod.clone_node('air')
	newnode.light_source = 14
	newnode.on_timer = function(pos)
		minetest.remove_node(pos)
	end
	minetest.register_node(mod_name..':flare_air', newnode)

	newnode = mod.clone_node('default:water_source')
	newnode.light_source = 14
	newnode.liquid_alternative_flowing = mod_name..':flare_water'
	newnode.liquid_alternative_source = mod_name..':flare_water'
	newnode.on_timer = function(pos)
		minetest.remove_node(pos)
	end
	minetest.register_node(mod_name..':flare_water', newnode)

	if minetest.registered_items[mod.environ_mod..':inert_gas'] then
		newnode = mod.clone_node(mod.environ_mod..':inert_gas')
		newnode.light_source = 14
		newnode.on_timer = function(pos)
			minetest.remove_node(pos)
		end
		minetest.register_node(mod_name..':flare_gas', newnode)
	end

	local incendiary_nodebox = {
		type = 'fixed',
		fixed = {
			{ -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
		}
	}

	minetest.register_node(mod_name..':incendiary', {
		description = 'Incendiary Device',
		drawtype = 'nodebox',
		node_box = incendiary_nodebox,
		paramtype2 = 'facedir',
		place_param2 = 0,
		tiles = {  'fun_tools_incendiary_top.png', 'fun_tools_incendiary_top.png',  'fun_tools_incendiary_side.png' },
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
		sounds = default.node_sound_wood_defaults(),
		on_punch = function(pos, node, player, pointed_thing)
			local item = player:get_wielded_item()
			if not item:get_name():find('torch') then
				return
			end

			minetest.set_node(pos, { name = 'fire:basic_flame' })

			for z = -50, 50, 5 do
				for y = -50, 50, 5 do
					for x = -50, 50, 5 do
						local fpos = vector.new(pos.x + x, pos.y + y, pos.z + z)
						local n = minetest.get_node_or_nil(fpos)
						if n and n.name == 'air' then
							minetest.set_node(fpos, {name=mod_name..':flare_air'})
							local timer = minetest.get_node_timer(fpos)
							timer:set(math.random(60), 0)
						elseif n and n.name == mod.environ_mod..':inert_gas' then
							minetest.set_node(fpos, {name=mod_name..':flare_gas'})
							local timer = minetest.get_node_timer(fpos)
							timer:set(math.random(60), 0)
						elseif n and n.name == 'default:water_source' then
							minetest.set_node(fpos, {name=mod_name..':flare_water'})
							local timer = minetest.get_node_timer(fpos)
							timer:set(math.random(60), 0)
						end
					end
				end
			end
		end,
	})

	local inc_element = 'default:steel_ingot'
	if minetest.registered_items['nmobs:bonedust'] then
		inc_element = 'nmobs:bonedust'
	end

	minetest.register_craft({
		output = mod_name..':incendiary',
		recipe = {
			{'', inc_element, ''},
			{'', 'tnt:gunpowder', ''},
			{'default:paper', 'tnt:gunpowder', 'default:paper'},
		}
	})
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

		local wear = (flares(user) or 0) * 200

		if itemstack:get_wear() + wear > 50000 then
			itemstack:clear()
			if mod.use_inventory_items(user, { 'tnt:gunpowder', }) then
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
-- Torchlight
------------------------------------------------


local torches = {
	[ 'default:torch' ] = 300,
	[ 'default:meselamp' ] = true,
	[ 'default:pick_mese' ] = true,
	[ 'default:sword_mese' ] = true,
	[ 'dinv:ring_light' ] = true,
}


if mod.torchlight then
	local torch_burn_time = {}
	minetest.register_globalstep(function(dtime)
		local players = minetest.get_connected_players()
		if not (players and type(players) == 'table') then
			return
		end

		for i = 1, #players do
			local player = players[i]

			local pos = player:get_pos()
			pos = vector.round(pos)
			pos.y = pos.y + 1

			local l = minetest.get_node_light(pos, nil) or 15
			if l > 13 then
				return
			end

			local item = player:get_wielded_item()
			local item_n = item:get_name()
			local torch_time = torches[item_n]
			if not torch_time then
				return
			end

			local n = minetest.get_node_or_nil(pos)
			if n and n.name == 'air' then
				local player_name = player:get_player_name()

				minetest.set_node(pos, { name = mod_name..':flare_air' })
				local timer = minetest.get_node_timer(pos)
				timer:start(2)

				if torch_time ~= true then
					torch_burn_time[player_name] = (torch_burn_time[player_name] or 0) + 1

					if torch_burn_time[player_name] > torch_time then
						item:take_item(1)
						player:set_wielded_item(item)
						torch_burn_time[player_name] = 0
					end
				end
			end
		end
	end)
end
