-- Not So Simple Bombs API
-- Copyright NPX (npx_npx@yahoo.it), 2017
-- Distributed under the GPLv3 (https://www.gnu.org/copyleft/gpl.html)
--
-- Some modifications by Duane

function fun_tools:register_throwitem(
    name,       --used for the craftitem and the entity
    descr,      --used for the craftitem
    def)        --array containing the definition parameters

    minetest.register_craftitem(name, {
        description = descr,
        inventory_image = def.textures,
        on_use = function(itemstack, placer, pointed_thing)
            local velocity = def.velocity or 15

            local dir = placer:get_look_dir()
            local playerpos = placer:getpos()
            local obj = minetest.add_entity({x=playerpos.x+dir.x,y=playerpos.y+2+dir.y,z=playerpos.z+dir.z}, name.."_flying")
            local vec = {x=dir.x*velocity,y=dir.y*velocity,z=dir.z*velocity}
            local acc = {x=0, y=-9.8, z=0}

            obj:setvelocity(vec)
            obj:setacceleration(acc)
            obj:get_luaentity().placer = placer

            itemstack:take_item()
            return itemstack
        end,
    })

    minetest.register_entity(name.."_flying",{
        textures = {def.textures},
		hp_max = 50,
        placer = nil,
		collisionbox = {-0.1,-0.1,-0.1, 0.1,0.1,0.1},
        visual_size = def.visual_size or {x=1, y=1},
        explosion = def.explosion or {},
        on_step = function(self, dtime)
            local pos = self.object:getpos()
            local node = minetest.get_node(pos)
            local name = node.name
            if name ~= "air" then
                if def.hit_node then
                    def.hit_node(self, pos)
                else
                    if self.explosion then
                        default_hit_node(self, self.explosion)
                    else
                        minetest.chat_send_player(self.placer, "No hit_node function defined")
                    end
                end
                self.object:remove()
            end
        end,
    })
    local recepy
    if def.recipe_block then
        recepy = {
            {def.recipe_block, def.recipe_block, def.recipe_block},
    		{"tnt:gunpowder", "default:mese_crystal_fragment", "tnt:gunpowder"},
    		{def.recipe_block, def.recipe_block, def.recipe_block},
        }
    end

    local number = def.recipe_number or 1
    minetest.register_craft({
    	output = name.." "..number,
        type = def.recipe_type or nil,
    	recipe = def.recipe or recepy
    })

end

function perpendicular_vector(vec) --returns a vector rotated of 90° in 2D (x and z directions)
	local ang = math.pi/2
	local c = math.cos(ang)
	local s = math.sin(ang)

	local i = vec.x*c - vec.z*s
	local k = vec.x*s + vec.z*c
	local j = 0

	vec = {x=i, y=j, z=k}
	return vec
end

function default_hit_node(self, explosion)
    local radius = explosion.radius  --size of the explosion
    local shape = explosion.shape   --to choose the explosion type
    local block = explosion.block -- it can be a name of a block, of a schematic or of an entity
    local particles = explosion.particles   --if you want to use the particles (boolean)
    local sound = explosion.sound   -- sound for the explosion, true to use the default sound

    local p = self.object:getpos() --position of the impact between the bomb and the ground
    local center = {x=p.x, y=p.y, z=p.z}

    if shape == "cube" then
        for dx = -radius,radius do
            for dy = -radius,radius do
                for dz = -radius,radius do
                    local pos1 = {x = p.x+dx, y=p.y+dy, z=p.z+dz}
                    if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                        minetest.set_node(pos1, {name=block})
                    end
                end
            end
        end
    elseif shape == "pool" then
        for dx = -radius,radius do
            for dy = -1,0 do
                for dz = -radius,radius do
                    local pos1 = {x = p.x+dx, y=p.y+dy, z=p.z+dz}
                    if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                        minetest.set_node(pos1, {name=block})
                    end
                end
            end
        end
    elseif shape == "sphere" then
        for dx = -radius,radius do
            for dy = -radius,radius do
                for dz = -radius,radius do
                    local pos1 = {x = p.x+dx, y=p.y+dy, z=p.z+dz}
                    if math.abs(vector.length(vector.subtract(pos1,p))) <= radius then
                        if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                            minetest.set_node(pos1, {name=block})
                        end
                    end
                end
            end
        end
    elseif shape == "sphere_cover" then
        for dx = -radius,radius do
            for dy = radius,-radius,-1 do
                for dz = -radius,radius do
                    local pos1 = {x = p.x+dx, y=p.y+dy, z=p.z+dz}
                    if math.abs(vector.length(vector.subtract(pos1,p))) <= radius then
                        local node_at = minetest.get_node_or_nil(pos1)
                        local node_below = minetest.get_node_or_nil({x=pos1.x, y=pos1.y-1, z=pos1.z})
                        if node_at and node_below and node_at.name == 'air' and node_below.name ~= 'air' then
                            if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                                minetest.set_node(pos1, {name=block})
                            end
                        end
                    end
                end
            end
        end
    elseif shape == "sphere_shell" then
        center.y = p.y + radius
        for dx = -radius,radius do
            for dy = 0,2*radius do
                for dz = -radius,radius do
                    local pos1 = {x = p.x+dx, y=p.y+dy, z=p.z+dz}
                    if round(math.abs(vector.length(vector.subtract(pos1,center)))) == radius then
                        if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                            minetest.set_node(pos1, {name=block})
                        end
                    end
                end
            end
        end
    elseif shape == "cubic_shell" then
        center.y = p.y + radius
        for dx = -radius,radius do
            for dy = -radius,radius do
                for dz = -radius,radius do
                    local pos1 = {x = p.x+dx, y=center.y+dy, z=p.z+dz}
                    if ((math.abs(dz)==radius)or(math.abs(dx)==radius)or(math.abs(dy)==radius)) then
                        if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                            minetest.set_node(pos1, {name=block})
                        end
                    end
                end
            end
        end
    elseif shape == "column" then
        local base_side = 0
        if round(radius/4) > 1 then
            base_side = round(radius/4)
        end
        local height = radius
        for dx = -base_side,base_side do
            for dy = 0,height do
                for dz = -base_side,base_side do
                    local pos1 = {x = p.x+dx, y=p.y+dy, z=p.z+dz}
                    if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                        minetest.set_node(pos1, {name=block})
                    end
                end
            end
        end
    elseif shape == "circle" then
        center.y = p.y + 1
        for dx = -radius,radius do
            for dy = 0, 1 do
                for dz = -radius,radius do
                    local pos1 = {x = p.x+dx, y=p.y+1+dy, z=p.z+dz}
                    if round(math.abs(vector.length(vector.subtract(pos1,center)))) == radius then
                        if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                            minetest.set_node(pos1, {name=block})
                        end
                    end
                end
            end
        end
    elseif shape == "disk" then
        center.y = p.y + 1
        for dx = -radius,radius do
            for dy = 0, 1 do
                for dz = -radius,radius do
                    local pos1 = {x = p.x+dx, y=p.y+1+dy, z=p.z+dz}
                    if round(math.abs(vector.length(vector.subtract(pos1,center)))) <= radius then
                        if not minetest.is_protected(pos1, "") or not minetest.get_item_group(minetest.get_node(pos1).name, "unbreakable") == 1 then
                            minetest.set_node(pos1, {name=block})
                        end
                    end
                end
            end
        end
    elseif shape == "wall" then
        local vec = self.object:getvelocity()
        vec.y = 0
        vec = vector.normalize(vec)
        local pr = perpendicular_vector(vec)

        local m = radius/2
        p = vector.subtract(p, vector.multiply(pr, m))

        for i = 0, radius do
            for dy = 0, round(radius/2) do
                local pp = {x = p.x, y = p.y +dy, z = p.z}
                if not minetest.is_protected(pp, "") or not minetest.get_item_group(minetest.get_node(pp).name, "unbreakable") == 1 then
                    minetest.set_node(pp, {name=block})
                end
                if radius >= 10 then
                    local pp2 = vector.add(pp,vec)
                    if not minetest.is_protected(pp2, "") or not minetest.get_item_group(minetest.get_node(pp2).name, "unbreakable") == 1 then
                        minetest.set_node(pp2, {name=block})
                    end
                end
            end
            p = vector.add(p,pr)
        end
    elseif shape == "schematic" then
        --[[
        Adds a defined schematic in the landing position of the bomb.
        If you want the schematic appear with its center in the landing pos of the bomb
        you have to specify the dimensione of the base of the schematic using
        explosion.radius parameter
        --]]
        if radius then
            local angle = {x = p.x - radius/2, y = p.y, z = p.z - radius/2}
            minetest.place_schematic(angle, block, "0", {}, true)
        else
            minetest.place_schematic(p, block, "0", {}, true)
        end
    elseif shape == "add_entity" then
        --[[
        Adds an entity in the landing position.
        In this case "block" contains the name of the entity to be added.
        ]]
        minetest.add_entity(p, block)
    elseif shape == "tnt_explosion" then
        tnt.boom(p, {damage_radius=radius,radius=radius,ignore_protection=false})
    end

    if particles and (shape ~= "tnt_explosion") then
        add_effects(center, radius, block)
    end
    if sound and (shape ~= "tnt_explosion") then
        if sound == true then
            minetest.sound_play("tnt_explode",{
    			object = self.object,
    			max_hear_distance = radius*16
    		})
        else
            minetest.sound_play(sound,{
    			object = self.object,
    			max_hear_distance = radius*16
    		})
        end
    end
end

function add_effects(pos, radius, block)
    local velocity = 1.9*math.log(radius)
    local q = 20*math.log(radius)

	minetest.add_particlespawner({
		amount = q,
		time = 0.3,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -velocity, y = -velocity, z = -velocity},
		maxvel = {x = velocity, y = velocity, z = velocity},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 9,
		maxsize = 10,
		texture = "tnt_smoke.png",
	})

    local texture2 = "tnt_smoke.png"
    local def = minetest.registered_nodes[block]
    if def and def.tiles and def.tiles[1] and type(def.tiles[1])=="string" then
        texture2 = def.tiles[1]
    end

    minetest.add_particlespawner({
        amount = q,
		time = 0.5,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
        minvel = {x = -velocity, y = -velocity, z = -velocity},
		maxvel = {x = velocity, y = velocity, z = velocity},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 9,
		maxsize = 10,
		texture = texture2,
	})
end

function round(num)
  if num >= 0 then
    return math.floor(num+.5) 
  else
    return math.ceil(num-.5)
  end
end
