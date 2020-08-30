pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- nandgate
-- by sestrenexsis
-- github.com/sestrenexsis/nandgate

_me="sestrenexsis"
_cart="nandgate"
cartdata(_me.."_".._cart.."_1")
_version=1

--disable button repeating
poke(0x5f5c,255)
poke(0x5f5d,255)

function newgrid(
	w, -- width      : number
	h, -- height     : number
	x, -- x position : number
	y  -- y position : number
	)
	local res={
		wd=w,
		ht=h,
		lft=x,
		top=y,
		dat={},
		dvcs={}
	}
	for i=1,w*h do
		add(res.dat,0)
	end
	assert(#res.dat==w*h)
	return res
end

function addflip(
	g, -- grid       : table
	x, -- x position : number
	y, -- y position : number
	o  -- output     : number
	)
	local res={
		name="flip",
		outs={o},
		ltik=-1, -- last powered tick
		on=true
	}
	local i=g.wd*(y-1)+x
	g.dat[i]=res
	add(g.dvcs,i)
	return res
end

function addwire(
	g, -- grid       : table
	x, -- x position : number
	y, -- y position : number
	o  -- output     : number
	)
	local res={
		name="wire",
		outs={o},
		ltik=-1 -- last powered tick
	}
	local i=g.wd*(y-1)+x
	g.dat[i]=res
	add(g.dvcs,i)
	return res
end

function _init()
	-- common vars
	_tick=0
	-- alter color palette
	_pals={
		{[0]=   1, 13,  2, 14,  7},
		{[0]=   0,  5,  3, 11,  7},
		{[0]= 129,131,  3, 11,138}
		}
		_pal=_pals[1]
	for i=0,#_pal do
		pal(i,_pal[i],1)
	end
	-- grid
	_grid=newgrid(16,16,15,15)
	_rw=1
	_cl=1
	local w=_grid.wd
	_dirs={
		-- {row,col,index}
		{ 0, 0,   0}, -- none
		{-1, 0,-w  }, -- north
		{-1, 1,-w+1}, -- northeast
		{ 0, 1,   1}, -- east
		{ 1, 1, w+1}, -- southeast
		{ 1, 0, w  }, -- south
		{ 1,-1, w-1}, -- southwest
		{ 0,-1,  -1}, -- west
		{-1,-1,-w-1}, -- northwest
		}
	_opps={1,6,7,8,9,2,3,4,5}
	-- add starting devices
	addflip(_grid,1,8,4)
	local wire=addwire(_grid,2,8,4)
	add(wire.outs,2)
	add(wire.outs,6)
end

function tick(
	g -- grid : table
	)
	_tick=(_tick+1)%32768
	local srcs={}
	for i in all(g.dvcs) do
		local dvc=g.dat[i]
		if (
			dvc!=0 and
			dvc.name=="flip" and
			dvc.on
		) then
			add(srcs,i)
		end
	end
	while #srcs>0 do
		local idx=srcs[1]
		local dvc=g.dat[idx]
		for out in all(dvc.outs) do
			local ofs=_dirs[out][3]
			local n=idx+ofs
			if (
				n>=1 and
				n<=#g.dat and
				g.dat[n]!=0 and
				g.dat[n].ltik<_tick
			) then
				add(srcs,n)
			end
		end
		deli(srcs,1)
		-- update the device
		dvc.ltik=_tick
	end
end

function _update()
	-- input
	local lcl=_cl
	local lrw=_rw
	if btnp(⬅️) then
		_cl=max(1,_cl-1)
	elseif btnp(➡️) then
		_cl=min(_grid.wd,_cl+1)
	end
	if btnp(⬆️) then
		_rw=max(1,_rw-1)
	elseif btnp(⬇️) then
		_rw=min(_grid.ht,_rw+1)
	end
	local lidx=(lrw-1)*_grid.wd+lcl
	local cidx=(_rw-1)*_grid.wd+_cl
	if btn(❎) then
		-- add wire if cell is free
		if _grid.dat[cidx]==0 then
			local drw=mid(-1,_rw-lrw,1)
			local dcl=mid(-1,_cl-lcl,1)
			for k,v in pairs(_dirs) do
				if (
					v[1]==drw and
					v[2]==dcl
				) then
					addwire(_grid,lcl,lrw,k)
					break
				end
			end
		elseif btnp(❎) then
			local dvc=_grid.dat[cidx]
			if dvc.name=="flip" then
				dvc.on=not dvc.on
			end
		end
	elseif btn(🅾️) then
		-- remove device if exists
		-- add new flip if empty
		if btnp(🅾️) or cidx!=lidx then
			if _grid.dat[cidx]==0 then
				addflip(_grid,_cl,_rw,4)
			else
				_grid.dat[cidx]=0
				del(_grid.dvcs,cidx)
			end
		end
	end
	if btnp(⬆️,1) then
		tick(_grid)
	end
end

function _draw()
	cls(0)
	-- draw palette
	for i=0,4 do
		local lf=1
		local tp=6*i+1
		print(tostr(i),lf+1,tp+1,1)
		print(tostr(i),lf,tp,4)
		rect(lf+5,tp+1,lf+9,tp+5,1)
		rect(lf+4, tp,lf+8,tp+4,4)
		rectfill(
			lf+5,tp+1,
			lf+7,tp+3,
			i)
	end
	-- draw grid and wires
	for rw=1,_grid.ht do
		for cl=1,_grid.wd do
			local x=cl*3+_grid.lft
			local y=rw*3+_grid.top
			local idx=(rw-1)*_grid.wd+cl
			pset(x,y,1)
			if _grid.dat[idx]!=0 then
				local dvc=_grid.dat[idx]
				local dvcn=dvc.name
				if dvcn=="wire" then
					local c=2
					if dvc.ltik==_tick then
						c=3
					end
					for out in all(dvc.outs) do
						local dr=_dirs[out]
						local dy=dr[1]
						local dx=dr[2]
						pset(x,y,c)
						pset(x+dx,y+dy,c)
						pset(x+2*dx,y+2*dy,c)
					end
				elseif dvcn=="flip" then
					rect(x-1,y-1,x+1,y+1,4)
					local c=2
					if dvc.ltik==_tick then
						c=3
					end
					for out in all(dvc.outs) do
						local dr=_dirs[out]
						local dy=dr[1]
						local dx=dr[2]
						pset(x,y,c)
						pset(x+dx,y+dy,c)
						pset(x+2*dx,y+2*dy,c)
					end
				end
			end
		end
	end
	-- draw cursor
	local lt=_cl*3+_grid.lft
	local tp=_rw*3+_grid.top
	rect(lt-2,tp-2,lt+2,tp+2,1)
	print(#_grid.dvcs,116,120,1)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
