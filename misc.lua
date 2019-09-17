-- Fun_tools misc.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local mod = fun_tools
local mod_name = 'fun_tools'


local metal_and_treasure = {
	'default:chest',
	'default:stone_with_iron',
	'default:stone_with_gold',
	'default:stone_with_mese',
	'default:steel_ingot',
	'default:steelblock',
	'default:gold_ingot',
	'default:goldblock',
	'default:mese',
	'default:sign_wall_steel',
	'default:ladder_steel',
	'doors:door_steel',
	'doors:trapdoor_steel',
}


local function detect_metal(pos, player_name, radius)
	if not pos then
		return
	end

	if not radius then
		radius = 40
	end

	local treas = minetest.find_nodes_in_area(vector.subtract(pos, radius), vector.add(pos, radius), metal_and_treasure)

	if #treas < 1 then
		minetest.chat_send_player(player_name, 'The device is silent.')
		return
	end

	local maxch
	local maxd = 100000
	for i, p in pairs(treas) do
		local d = vector.distance(pos, p)
		if d < maxd then
			maxd = d
			maxch = i
		end
	end

	if not maxch then
		return
	end

	local dir = vector.direction(pos, treas[maxch])
	local dirs = ''
	if math.abs(dir.x) > math.max(math.abs(dir.y), math.abs(dir.z)) then
		if dir.x > 0 then
			dirs = 'to the east'
		else
			dirs = 'to the west'
		end
	elseif math.abs(dir.y) > math.abs(dir.z) then
		if dir.y > 0 then
			dirs = 'above you'
		else
			dirs = 'below you'
		end
	else
		if dir.z > 0 then
			dirs = 'to the north'
		else
			dirs = 'to the south'
		end
	end

	if player_name then
		minetest.chat_send_player(player_name, 'The device senses something ' .. dirs ..'.')
	end

	return dir
end


minetest.register_tool(mod_name .. ':metal_detector', {
	description = 'Primitive Metal Detector',
	inventory_image = 'fun_tools_metal_detector.png',
	tool_capabilities = {
		full_punch_interval = 2.0,
		max_drop_level=1,
		groupcaps={
			choppy={times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=80, maxlevel=2},
		},
		damage_groups = {fleshy=1},
	},
	on_use = function(itemstack, user, pointed_thing)
		if not (user and pointed_thing and itemstack) then
			return
		end

		local player_name = user:get_player_name()
		local pos = user:getpos()
		local tool = user:get_wielded_item()
		local user_name = user:get_player_name()
		if not (pos and tool and user_name and player_name) or user_name == '' then
			return
		end

		detect_metal(pos, player_name)

		tool:add_wear(3000)
		return tool
	end,
})

minetest.register_craft({
	output = mod_name .. ':metal_detector',
	recipe = {
		{'default:gold_ingot', 'default:steel_ingot', ''},
		{'map:mapping_kit', 'group:wood', ''},
		{'', '', ''},
	},
})
