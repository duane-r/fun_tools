-- Fun_tools guns.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local mod = fun_tools
local mod_name = 'fun_tools'


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
		texture = 'tnt_smoke.png',
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
		texture = 'tnt_smoke.png',
	})
end


function mod.ranged_attack(itemstack, user, range)
	local shot
	local dir = user:get_look_dir()
	local playerpos = user:get_pos()
	local p = table.copy(playerpos)
	p.y = p.y + 1.5

	local eps = {}
	for id, ent in pairs(minetest.luaentities) do
		if ent.object:get_luaentity() then
			if ent and ent.object and ent.object.get_pos and (ent._is_a_mob or ent.health) then
				local ep = ent.object:get_pos()
				if ep and vector.distance(ep, p) < range then
					eps[id] = ep
				end
			end
		end
	end

	for _ = 1, range do
		p = vector.add(p, dir)

		for id in pairs(eps) do
			if vector.distance(eps[id], p) < 1 then
				local ent = minetest.luaentities[id]
				if ent.object:get_luaentity() then
					if ent and ent._printed_name then
						local player_name = user:get_player_name()
						if player_name then
							minetest.chat_send_player(player_name, 'You hit the ' .. ent._printed_name)
						end
					end

					ent.object:punch(user, nil, itemstack:get_tool_capabilities(), nil)
				end

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


------------------------------------------------
-- Mattock
------------------------------------------------


minetest.register_tool(mod_name..':mattock', {
	description = 'Mattock',
	drawtype = 'plantlike',
	paramtype = 'light',
	tiles = {'fun_tools_mattock.png'},
	inventory_image = 'fun_tools_mattock.png',
	groups = {dig_immediate = 3},
	sounds = default.node_sound_wood_defaults(),
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=80, maxlevel=2},
		},
		damage_groups = {fleshy=3},
	},
	on_use = function(itemstack, user, pointed_thing)
		if not (user and pointed_thing) then
			return
		end

		if pointed_thing.type == 'node' then
			local n = minetest.get_node(pointed_thing.under)
			if n.name == 'default:cobble' then
				minetest.set_node(pointed_thing.under, {
					name = 'default:gravel',
				})
			elseif n.name == 'default:stone' then
				minetest.set_node(pointed_thing.under, {
					name = 'default:cobble',
				})
			else
				minetest.node_dig(pointed_thing.under, n, user)
			end
		elseif pointed_thing.type == 'object' then
			pointed_thing.ref:punch(user, nil, itemstack:get_tool_capabilities(), nil)
		end

		--minetest.sound_play('', {
		--	object = user,
		--	gain = 0.1,
		--	max_hear_distance = 30
		--})

		return itemstack
	end,
})

minetest.register_craft({
	output = mod_name..':mattock',
	type = 'shapeless',
	recipe = {'group:tree', 'group:stick',},
})


------------------------------------------------
-- Pebble Thrower
------------------------------------------------


minetest.register_tool(mod_name..':pebble_thrower_unloaded', {
	description = 'Pebble Thrower (unloaded)',
	drawtype = 'plantlike',
	paramtype = 'light',
	tiles = {'fun_tools_pebble_thrower.png'},
	inventory_image = 'fun_tools_pebble_thrower.png',
	groups = {dig_immediate = 3},
	sounds = default.node_sound_metal_defaults(),
	on_use = function(itemstack, user, pointed_thing)
		if not (mod.fast_load and user and pointed_thing) then
			return
		end

		if mod.use_inventory_items(user, { 'tnt:gunpowder', mod_name..':pebble' }) then
			itemstack:clear()
			itemstack:add_item(mod_name..':pebble_thrower_loaded')
			return itemstack
		end
	end,
})

minetest.register_craftitem(mod_name..':pebble', {
	description = 'Pebble',
	inventory_image = 'fun_tools_pebble.png',
	--groups = {dig_immediate = 3},
})

minetest.register_craft({
	output = mod_name..':pebble 50',
	type = 'shapeless',
	recipe = {'default:gravel'},
})

minetest.register_craft({
	output = mod_name..':pebble_thrower_loaded',
	type = 'shapeless',
	recipe = {'tnt:gunpowder', mod_name..':pebble', mod_name..':pebble_thrower_unloaded',},
})

minetest.register_craft({
	output = mod_name..':pebble_thrower_unloaded',
	recipe = {
		{'', '', ''},
		{'group:stone', 'mobs:leather', 'default:flint'},
		{'', '', 'group:wood'},
	},
})

minetest.register_tool(mod_name..':pebble_thrower_loaded', {
	description = 'Pebble Thrower (loaded)',
	drawtype = 'plantlike',
	paramtype = 'light',
	tiles = {'fun_tools_pebble_thrower.png'},
	inventory_image = 'fun_tools_pebble_thrower.png',
	groups = {dig_immediate = 3},
	sounds = default.node_sound_stone_defaults(),
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=80, maxlevel=2},
		},
		damage_groups = {fleshy=5},
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
		itemstack:add_item(mod_name..':pebble_thrower_unloaded')
		return itemstack
	end,
})


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
		if not (mod.fast_load and user and pointed_thing) then
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
		{'', '', mod.precision_tool},
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
