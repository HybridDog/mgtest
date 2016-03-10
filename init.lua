local load_time_start = os.clock()

local inform
local c_air = minetest.get_content_id("air")
local c_water = minetest.get_content_id("default:water_source")

local rarity = 0.1
local scale = 10

local perlin_scale = rarity*scale*100
local inverted_rarity = 1-rarity

local generating = true
minetest.register_on_generated(function(minp, maxp, seed)

	--avoid calculating perlin noises for unneeded places
	if maxp.y <= -150
	or minp.y >= 150
	or not generating then
		return
	end

	local perlin1 = minetest.get_perlin(11,3, 0.5, perlin_scale)	--Get map specific perlin
	local x0,z0,x1,z1 = minp.x,minp.z,maxp.x,maxp.z	-- Assume X and Z lengths are equal

	if not ( perlin1:get2d( {x=x0, y=z0} ) > inverted_rarity ) 					--top left
	and not ( perlin1:get2d( { x = x0 + ( (x1-x0)/2), y=z0 } ) > inverted_rarity )--top middle
	and not (perlin1:get2d({x=x1, y=z1}) > inverted_rarity) 						--bottom right
	and not (perlin1:get2d({x=x1, y=z0+((z1-z0)/2)}) > inverted_rarity) 			--right middle
	and not (perlin1:get2d({x=x0, y=z1}) > inverted_rarity)  						--bottom left
	and not (perlin1:get2d({x=x1, y=z0}) > inverted_rarity)						--top right
	and not (perlin1:get2d({x=x0+((x1-x0)/2), y=z1}) > inverted_rarity) 			--left middle
	and not (perlin1:get2d({x=(x1-x0)/2, y=(z1-z0)/2}) > inverted_rarity) 			--middle
	and not (perlin1:get2d({x=x0, y=z1+((z1-z0)/2)}) > inverted_rarity) then		--bottom middle
		return
	end

	local t1 = os.clock()
	inform("[mgtest] generates at "..minetest.pos_to_string(vector.round(vector.divide(vector.add(minp, maxp), 2))))

	local heightmap = minetest.get_mapgen_object("heightmap")
	if not heightmap then
		generating = false
		return
	end
	local hmi = 1

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	local node_changed

	for z=minp.z,maxp.z do
		for x=minp.x,maxp.x do
			local test = math.abs(perlin1:get2d({x=x, y=z}))
			if test <= 0.1 then
				for y=math.max(minp.y, math.floor(test*100-10+0.5)),math.min(heightmap[hmi]+15, maxp.y) do
					local p_pos = area:index(x, y, z)
					if y <= 1 then
						data[p_pos] = c_water
					else
						data[p_pos] = c_air
					end
					node_changed = true
				end
			end
			hmi = hmi+1
		end
	end

	if node_changed then
		vm:set_data(data)
		vm:calc_lighting()
		vm:update_liquids()
		vm:write_to_map()
	end

	inform(string.format("[mgtest] done after ca. %.2fs", os.clock() - t1))
end)

function inform(msg)
	minetest.log("info", msg)
	--minetest.chat_send_all(msg)
end


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[mgtest] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end





--[[
local c_wood = minetest.get_content_id("default:wood")
local c_nether_dirt_top = minetest.get_content_id("default:dirt_with_grass")
local c_nether_dirt = minetest.get_content_id("default:dirt")
local f_perlins = {}

local f_bottom_scale = 4
local f_h_min = 150
local f_h_max = 400
local f_yscale_top = (f_h_max-f_h_min)/2
local f_yscale_bottom = f_yscale_top/2

minetest.register_on_generated(function(minp, maxp, seed)

	--avoid calculating perlin noises for unneeded places
	if maxp.y <= f_h_min
	or minp.y >= f_h_max then
		return
	end

	local perlin_f_bottom = minetest.get_perlin(11, 3, 0.8, f_yscale_top*4/f_bottom_scale)
	local perlin_f_top = minetest.get_perlin(21, 3, 0.8, f_yscale_top*4)

	local t1 = os.clock()
	local geninfo = "[mg] cc generates..."
	print(geninfo)
	minetest.chat_send_all(geninfo)


	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	for z=minp.z,maxp.z do
		for x=minp.x,maxp.x do
			local p = {x=math.floor(x/f_bottom_scale), z=math.floor(z/f_bottom_scale)}
			local pstr = p.x.." "..p.z
			if not f_perlins[pstr] then
				f_perlins[pstr] = f_h_min+(perlin_f_bottom:get2d({x=x, y=z})+1)*f_yscale_bottom
			end
			local f_bottom = math.floor(f_perlins[pstr]+math.random(0,f_bottom_scale-1)+0.5)
			local f_top = math.floor(f_h_max-(perlin_f_top:get2d({x=x, y=z})+1)*f_yscale_top+0.5)
			if f_bottom < f_top then
				for y=minp.y,maxp.y do
					local pos = {x=x,y=y,z=z}
					local p_pos = area:indexp(pos)
					if y == f_bottom then
						data[p_pos] = c_nether_dirt_top
					elseif y == f_bottom-1
					and math.random(2) == 1 then
						data[p_pos] = c_nether_dirt
					elseif y < f_bottom then
						data[p_pos] = c_stone
					elseif y >= f_top then
						data[p_pos] = c_wood
					end
				end
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map()

	local geninfo = string.format("[mg] cc done after: %.2fs", os.clock() - t1)
	print(geninfo)
	minetest.chat_send_all(geninfo)
end)
]



function zlg(z)
	for a = 2,z/2,1 do
		if z%a == 0 then
			return a
		end
	end
	return false
end

function pri(z)
	local cz = z
	local zgz = zlg(z)

	local tab = {}

	while zgz do
		local tabz = tab[zgz]
		if tabz == nil then
			tab[zgz] = 1
		else
			tab[zgz] = tabz+1
		end
		cz = cz/zgz
		zgz = zlg(cz)
	end
	local tabz = tab[cz]
	if tabz == nil then
		tab[cz] = 1
	else
		tab[cz] = tabz+1
	end
	--print(dump(tab))
	return tab
--[[
	local t = z.." = "
	local g = "*"

	for i,n in pairs(tab) do
		if i == cz then
			g = " "
		end
		if n == 1 then
			t=t..i..g
		else
			t=t..i.."^"..n..g
		end
	end
	print(t)]
end

local disall = {}
for n = 1,20,2 do
	local i = 2^n
	table.insert(disall, {i/2, i})
end


local function ism(x)
	local x = math.abs(x)
	if x%2 == 1 then
		return
	end
	for i = 1,#disall do
		local min,max = unpack(disall[i])
		if (x%max)/max > 0.5--[[x > min
		and x < max ]then
			return false
		end
	end
	return true
	--[[local n = 1
	for i = 1,x do
		n = 2^i
		if n > x then
			return false
		end
		if x/n > 0.5 then
			return true
		end
	end]
end

local c_wood = minetest.get_content_id("default:wood")

minetest.register_on_generated(function(minp, maxp, seed)

	local t1 = os.clock()
	local geninfo = "[mg] cc generates..."
	print(geninfo)
	minetest.chat_send_all(geninfo)


	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	for z=minp.z,maxp.z do
		for y = minp.y, maxp.y do
			for x=minp.x,maxp.x do
				if ism(x) or ism(y) then
				if z == 0 then
				--[[if (ism(x) and ism(y))
				or (ism(x) and ism(z))
				or (ism(z) and ism(y)) then]
					local p_pos = area:index(x,y,z)
					data[p_pos] = c_wood
				end end
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map()

	local geninfo = string.format("[mg] cc done after: %.2fs", os.clock() - t1)
	print(geninfo)
	minetest.chat_send_all(geninfo)
end)

]]
