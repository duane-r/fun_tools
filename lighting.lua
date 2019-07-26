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
-- Torchlight
------------------------------------------------


if mod.torchlight then
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

			local l = minetest.get_node_light(pos, nil) or 15
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
