-- Fun_tools init.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017, 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

fun_tools = {}
local mod = fun_tools
local mod_name = 'fun_tools'
mod.version = '20190726'
mod.path = minetest.get_modpath(minetest.get_current_modname())
mod.world = minetest.get_worldpath()

mod.creative = minetest.setting_getbool('creative_mode')
mod.environ_mod = 'mapgen'
mod.fast_load = minetest.setting_getbool('fun_tools_fast_load')
mod.ice_fuel_source = 'default:coalblock'
mod.precision_tool = 'default:diamond'
mod.remove_bronze = minetest.setting_getbool('fun_tools_remove_bronze')
mod.torchlight = minetest.setting_getbool('fun_tools_torchlight')


-- These all default to enabled... because I say.
for _, k in pairs({'fast_load', 'remove_bronze', 'torchlight', }) do
	if mod[k] == nil then
		mod[k] = true
	end
end


function mod.clone_node(name)
	if not (name and type(name) == 'string') then
		return
	end

	local node = minetest.registered_nodes[name]
	local node2 = table.copy(node)
	return node2
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


--dofile(mod.path .. '/recipe_list.lua')
dofile(mod.path .. '/beds.lua')
dofile(mod.path .. '/bombs.lua')
dofile(mod.path .. '/game.lua')
dofile(mod.path .. '/guns.lua')
dofile(mod.path .. '/lighting.lua')
dofile(mod.path .. '/misc.lua')
dofile(mod.path .. '/paint.lua')
dofile(mod.path .. '/power_tools.lua')
dofile(mod.path .. '/rope.lua')
dofile(mod.path .. '/travel.lua')
dofile(mod.path .. '/wallhammer.lua')


--mod.print_recipes()


--[[
minetest.register_lbm({
	name = mod_name..':flare_killer',
	nodenames = { mod_name..':flare_air' },
	action = function(pos, node)
		minetest.remove_node(pos)
	end,
})
--]]
