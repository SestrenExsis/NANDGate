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

-- directions
_dirs={ -- {row,col}
	{ 0, 0}, -- none
	{-1, 0}, -- north
	{-1, 1}, -- northeast
	{ 0, 1}, -- east
	{ 1, 1}, -- southeast
	{ 1, 0}, -- south
	{ 1,-1}, -- southwest
	{ 0,-1}, -- west
	{-1,-1}, -- northwest
	}
_opps={1,6,7,8,9,2,3,4,5}

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
		dvcs={},
		dirs={
			   0,
			-w  ,
			-w+1,
			   1,
			 w+1,
			 w  ,
			 w-1,
			  -1,
			-w-1
		}
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
	y  -- y position : number
	)
	local res={
		name="flip",
		outs={},
		ltik=-1, -- last powered tick
		on=true
	}
	local i=g.wd*(y-1)+x
	g.dat[i]=res
	add(g.dvcs,i)
	return res
end

function addnand(
	g, -- grid       : table
	x, -- x position : number
	y  -- y position : number
	)
	local res={
		name="nand",
		ltika=-1, -- last input ticks
		ltikb=-1
	}
	local i=g.wd*(y-1)+x
	g.dat[i]=res
	add(g.dvcs,i)
	return res
end

function newwire(
	o  -- output     : number
	)
	local res={
		name="wire",
		outs={o},
		ltik=-1 -- last powered tick
	}
	return res
end

function addifnew(l,n)
	local new=true
	for i in all(l) do
		if i==n then
			new=false
			break
		end
	end
	if new then
		add(l,n)
	end
end

function connect(
	g,     -- grid      : table
	sx,sy, -- start pos : numbers
	ex,ey  -- end pos   : numbers
	)
	local si=g.wd*(sy-1)+sx
	local sdy=mid(-1,ey-sy,1)
	local sdx=mid(-1,ex-sx,1)
	local so=1
	for k,v in pairs(_dirs) do
		if (
			v[1]==sdy and
			v[2]==sdx
		) then
			so=k
			break
		end
	end
	if g.dat[si]==0 then
		g.dat[si]=newwire(so)
		add(g.dvcs,si)
	else
		addifnew(g.dat[si].outs,so)
	end
	local ei=g.wd*(ey-1)+ex
	local edy=mid(-1,sy-ey,1)
	local edx=mid(-1,sx-ex,1)
	local eo=1
	for k,v in pairs(_dirs) do
		if (
			v[1]==edy and
			v[2]==edx
		) then
			eo=k
			break
		end
	end
	if (
		g.dat[ei]!=0 and
		g.dat[ei].name=="wire"
	) then
		addifnew(g.dat[ei].outs,eo)
	end
end
-->8
-- game loops

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
	_grid=newgrid(32,32,15,15)
	_rw=1
	_cl=1
	local w=_grid.wd
	-- add starting devices
	-- f+..
	-- .n--
	-- f+..
	addflip(_grid,1,1)
	addnand(_grid,2,2)
	addflip(_grid,1,3)
	connect(_grid,1,1,2,1)
	connect(_grid,2,1,2,2)
	connect(_grid,1,3,2,3)
	connect(_grid,2,3,2,2)
	--connect(_grid,2,2,3,2)
	--connect(_grid,3,2,4,2)
	--addnand(_grid,
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
			dvc.on!=nil and
			dvc.on
		) then
			add(srcs,i)
		end
	end
	while #srcs>0 do
		local idx=srcs[1]
		local dvc=g.dat[idx]
		for out in all(dvc.outs) do
			local ofs=g.dirs[out]
			local n=idx+ofs
			if (
				n>=1 and
				n<=#g.dat and
				g.dat[n]!=0
			) then
				local ndvc=g.dat[n]
				if ndvc.name=="nand" then
					if ndvc.ltikb<_tick then
						add(srcs,n)
					end
				else
					if ndvc.ltik<_tick then
						add(srcs,n)
					end
				end
			end
		end
		deli(srcs,1)
		-- update the device
		if dvc.name=="nand" then
			if dvc.ltika==_tick then
				dvc.ltikb=_tick
			else
				dvc.ltika=_tick
			end
		else
			dvc.ltik=_tick
		end
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
	local cdvc=_grid.dat[cidx]
	if (
		btnp(❎) and
		cdvc!=0 and
		cdvc.name=="flip"
	) then
		-- toggle the flip
		cdvc.on=not cdvc.on
	elseif btn(❎) then
		connect(_grid,lcl,lrw,_cl,_rw)
		--[[
		connect 2 cells with wire,
		then search neighbors for 
		wires connecting to this cell
		and add "bridge" connections
		as necessary
		--]]
		for i=2,#_grid.dirs do
			local ncl=_cl+_dirs[i][2]
			local nrw=_rw+_dirs[i][1]
			local nidx=cidx+_grid.dirs[i]
			local ndvc=_grid.dat[nidx]
			if (
				ndvc!=0 and
				nidx>=1 and
				nidx<=#_grid.dat
			) then
				for out in all(ndvc.outs) do
					if _opps[out]==i then
						connect(_grid,_cl,_rw,ncl,nrw)
						break
					end
				end
			end
		end
		--]]
	elseif (
		btnp(🅾️) or
		(btn(🅾️) and cidx!=lidx)
	) then
		-- remove device if exists
		-- add new flip if empty
		if _grid.dat[cidx]==0 then
			addflip(_grid,_cl,_rw)
		else
			_grid.dat[cidx]=0
			del(_grid.dvcs,cidx)
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
				elseif dvcn=="nand" then
					line(x,y-1,x,y+1,4)
					pset(x+1,y,4)
					local c=3
					if (
						dvc.ltika==_tick and
						dvc.ltikb==_tick
					) then
						c=2
					end
					print(dvc.ltika,104,114,1)
					print(dvc.ltikb,104,120,1)
					rectfill(x+2,y-1,x+2,y+1,c)
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
