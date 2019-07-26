-- Fun_tools bombs.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2019
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)

local mod = fun_tools
local mod_name = 'fun_tools'


if minetest.registered_items['nmobs:slime_ball'] then
	mod.magic_ingredient = 'nmobs:slime_ball'
elseif minetest.registered_items['mobs_slimes:green_slimeball'] then
	mod.magic_ingredient = 'mobs_slimes:green_slimeball'
else
	minetest.register_craftitem(mod_name..':magic_placeholder', {
		description = 'Magic Ingredient',
		drawtype = 'plantlike',
		paramtype = 'light',
		tiles = { 'elixirs_elixir.png' },
		inventory_image = 'elixirs_elixir.png',
		groups = { dig_immediate = 3, vessel = 1 },
		sounds = default.node_sound_glass_defaults(),
	})

	mod.magic_ingredient = mod_name..':magic_placeholder'
end


------------------------------------------------
-- Naptha and Molotails
------------------------------------------------


if minetest.get_modpath('elixirs') then
	mod.ice_fuel_source = 'elixirs:bucket_of_naptha'
else
	minetest.register_craftitem(mod_name..':naptha', {
		description = 'Bottle of Naptha',
		inventory_image = 'elixirs_naptha.png',
	})

	minetest.register_craft({
		output = mod_name..':naptha',
		type = 'shapeless',
		recipe = {
			'vessels:glass_bottle', 'group:coal', mod.magic_ingredient,
		},
	})

	if minetest.registered_items['bucket:bucket_empty'] then
		minetest.register_craftitem(mod_name..':bucket_of_naptha', {
			description = 'Bucket of Naptha',
			inventory_image = 'elixirs_bucket_naptha.png',
		})

		minetest.register_craft({
			output = mod_name..':bucket_of_naptha',
			recipe = {
				{mod_name..':naptha', mod_name..':naptha', mod_name..':naptha', },
				{mod_name..':naptha', 'bucket:bucket_empty', mod_name..':naptha', },
				{mod_name..':naptha', mod_name..':naptha', mod_name..':naptha', },
			},
			replacements = {
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
			},
		})
	end

	mod.ice_fuel_source = mod_name..':bucket_of_naptha'

	if minetest.registered_items['wooden_bucket:bucket_wood_empty'] then
		minetest.register_craftitem(mod_name..':wood_bucket_of_naptha', {
			description = 'Wooden Bucket of Naptha',
			inventory_image = 'elixirs_wood_bucket_naptha.png',
		})

		minetest.register_craft({
			output = mod_name..':wood_bucket_of_naptha',
			recipe = {
				{mod_name..':naptha', mod_name..':naptha', mod_name..':naptha', },
				{mod_name..':naptha', 'wooden_bucket:bucket_wood_empty', mod_name..':naptha', },
				{mod_name..':naptha', mod_name..':naptha', mod_name..':naptha', },
			},
			replacements = {
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
				{ mod_name..':naptha', 'vessels:glass_bottle' },
			},
		})
	end

	minetest.register_craft({
		type = 'fuel',
		recipe = mod_name..':naptha',
		burntime = 5,
	})


	dofile(mod.path .. '/bombs_api.lua')

	mod:register_throwitem(mod_name..':molotov_cocktail', 'Molotov Cocktail', {
		textures = 'more_fire_molotov_cocktail.png',
		recipe = { 'farming:cotton', mod_name..':naptha', },
		recipe_type = 'shapeless',
		explosion = {
			shape = 'sphere_cover',
			radius = 5,
			block = 'fire:basic_flame',
			particles = false,
			sound = 'more_fire_shatter'
			--sound = 'more_fire_ignite'
		}
	})

	-- fuel recipes
	minetest.register_craft({
		type = 'fuel',
		recipe = mod_name..':molotov_cocktail',
		burntime = 5,
	})


	mod:register_throwitem(mod_name..':grenade', 'Grenado', {
		textures = 'elixirs_grenade.png',
		recipe = { 'farming:cotton', 'vessels:steel_bottle', 'tnt:gunpowder', },
		recipe_type = 'shapeless',
		hit_node = function (self, pos)
			tnt.boom(pos, { damage_radius=5,radius=1,ignore_protection=false })
		end,
	})
end
