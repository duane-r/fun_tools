---------------------------------------------------------------
-- Wallhammer
---------------------------------------------------------------
-- This is a cut-down version of DonBatman's mymasonhammer
-- (https://github.com/DonBatman/mymasonhammer). This version only
-- does toeholds, and makes them more ladder-like.
---------------------------------------------------------------


local USES = 100

local default_material = {}

for _, i in pairs({
  {"default:cobble", "default_cobble", "Cobble", {cracky = 3, not_in_creative_inventory=1}, nil},
  {"default:stone","default_stone", "Stone", {cracky = 3, not_in_creative_inventory=1}, "default:cobble"},
  {"default:desert_stone","default_desert_stone", "Desert Stone", {cracky = 3, not_in_creative_inventory=1}, nil},
  {"default:desert_cobble","default_desert_cobble", "Desert Cobble", {cracky = 3, not_in_creative_inventory=1}, nil},
  {"default:sandstone","default_sandstone", "Sandstone", {cracky = 3, not_in_creative_inventory=1}, nil},
  {"fun_caves:stone_with_lichen","default_stone", "Stone", {cracky = 3, not_in_creative_inventory=1}, "default:cobble"},
  {"fun_caves:stone_with_algae","default_stone", "Stone", {cracky = 3, not_in_creative_inventory=1}, "default:cobble"},
  {"fun_caves:stone_with_moss","default_stone", "Stone", {cracky = 3, not_in_creative_inventory=1}, "default:cobble"},
  {"default:mossycobble","default_stone", "Stone", {cracky = 3, not_in_creative_inventory=1}, "default:cobble"},
  {"fun_caves:stone_with_salt","caverealms_salty2", "Stone", {cracky = 3, not_in_creative_inventory=1}, "fun_caves:stone_with_salt"},
}) do
  if minetest.registered_items[i[1]] then
    table.insert(default_material, i)
  end
end
--print(dump(default_material))


local function parti(pos)
  if not pos then
    return
  end

  minetest.add_particlespawner(25, 0.3, pos, pos, {x=2, y=0.2, z=2}, {x=-2, y=2, z=-2}, {x=0, y=-6, z=0}, {x=0, y=-10, z=0}, 0.2, 1, 0.2, 2, true, "wallhammer_parti.png")
end

minetest.register_tool( "fun_tools:wall_hammer",{
  description = "Wall Hammer",
  inventory_image = "wallhammer_hammer.png",
  wield_image = "wallhammer_hammer.png",
  tool_capabilities = {
    full_punch_interval = 1.0,
    max_drop_level=1,
    groupcaps={
      cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=20, maxlevel=0},
    },
    damage_groups = {fleshy=4},
  },
  on_use = function(itemstack, user, pointed_thing)
    if not (pointed_thing and user and itemstack) then
      return
    end

    if pointed_thing.type ~= "node" then
      return
    end

    local pos = pointed_thing.under
    if not pos then
      return
    end

    local node = minetest.get_node(pos)
    if not node then
      return
    end

    for i in ipairs (default_material) do
      local item = default_material [i][1]
      local mat = default_material [i][2]
      local desc = default_material [i][3]

      if minetest.is_protected(pos, user:get_player_name()) then
        minetest.record_protection_violation(pos, user:get_player_name())
        return
      end

      if node.name == item then
        local node = {
          name = "fun_tools:"..mat.."_foot",
          param2=minetest.dir_to_facedir(user:get_look_dir())
        }
        minetest.set_node(pos, node)
        parti(pos)
      end
    end

    if not minetest.setting_getbool("creative_mode") then
      itemstack:add_wear(65535 / (USES - 1))
    end

    return itemstack
  end,
})

minetest.register_craft({
  output = "fun_tools:wall_hammer",
  recipe = {
    {"", fun_tools_mod.which_dry_fiber..":dry_fiber", ""},
    {"default:steel_ingot", "default:steel_ingot", "group:stick"},
    {"", fun_tools_mod.which_dry_fiber..":dry_fiber", ""},
  },
})

minetest.register_craft({
  output = "fun_tools:wall_hammer",
  type = "shapeless",
  recipe = {
    "fun_tools:wall_hammer", "default:steel_ingot",	
  },
})


for i in ipairs (default_material) do
  local item = default_material [i][1]
  local mat = default_material [i][2]
  local desc = default_material [i][3]
  local gro = default_material [i][4]
  local drop = default_material[i][5]

  if not drop then
    drop = item
  end

  minetest.register_node("fun_tools:"..mat.."_foot", {
    description =  desc.." Foot Hold Block",
    drawtype = "nodebox",
    tiles = {
      mat..".png^[colorize:#FFFFFF:40",
      mat..".png^[colorize:#000000:80",
      mat..".png^[colorize:#000000:60",
      mat..".png^[colorize:#000000:60",
      mat..".png^[colorize:#000000:60",
      mat..".png^[colorize:#FFFFFF:20",
    },
    paramtype = "light",
    paramtype2 = "facedir",
    walkable = true,
    climbable = true,
    drop = drop,
    groups = gro,
    node_box = {
      type = "fixed",
      fixed = {
        {-0.5, -0.5, 0.4, 0.5, 0.5, 0.5},
        {-0.375, -0.3125, 0.3, -0.125, -0.125, 0.4},
        {0.125, 0.1875, 0.3, 0.375, 0.375, 0.4},
      }
    },
    selection_box = {
      type = "fixed",
      fixed = {
        {-0.5, -0.5, 0.45, 0.5, 0.5, 0.5},
      }
    },
    collision_box = {
      type="fixed",
      fixed = {
        {-0.5, -0.5, 0.4, 0.5, 0.5, 0.5},
      }
    },
  })

end
