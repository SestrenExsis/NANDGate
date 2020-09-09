pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- nandgate
-- by sestrenexsis
-- github.com/sestrenexsis/nandgate

_me="sestrenexsis"
_cart="nandgate"
-- "bredbord"?
cartdata(_me.."_".._cart.."_1")
_version=1

--disable button repeating
poke(0x5f5c,255)
poke(0x5f5d,255)

-- directions
_dirs={ -- {row,col}
	{ 1,-1},{ 1, 0},{ 1, 1}, --123
	{ 0,-1},{ 0, 0},{ 0, 1}, --456
	{-1,-1},{-1, 0},{-1, 1}  --789
	}
_opps={9,8,7,6,5,4,3,2,1}

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
			 w-1, w  , w+1, -- 123
			  -1,   0,   1, -- 456
			-w-1,-w  ,-w+1  -- 789
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
		outs={},
		ltika=-1, -- last input ticks
		ltikb=-1
	}
	local i=g.wd*(y-1)+x
	g.dat[i]=res
	add(g.dvcs,i)
	return res
end

function addfeed(
	g, -- grid       : table
	x, -- x position : number
	y  -- y position : number
	)
	local res={
		name="feed",
		outs={2,6},
		tiks={
			-1,-1,-1, --123
			-1,-1,-1, --546
			-1,-1,-1  --789
		}
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
	elseif sdx!=0 or sdy!=0 then
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
		g.dat[ei].name=="wire" and
		(edx!=0 or edy!=0)
	) then
		--addifnew(g.dat[ei].outs,eo)
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
	_grid=newgrid(32,32,12,12)
	_rw=1
	_cl=1
	local w=_grid.wd
	-- add starting devices
	addflip(_grid,1,1)
	addflip(_grid,1,4)
	addnand(_grid,3,2)
	addnand(_grid,5,2)
	addnand(_grid,4,5)
	addnand(_grid,3,6)
	addnand(_grid,5,6)
	addnand(_grid,4,7)
	addfeed(_grid,2,4)
	connect(_grid,1,1,2,1)
	connect(_grid,2,1,3,1)
	connect(_grid,3,1,3,2)
	connect(_grid,2,1,2,2)
	connect(_grid,2,2,2,3)
	connect(_grid,2,3,2,4)
	connect(_grid,2,4,2,5)
	connect(_grid,2,5,2,6)
	connect(_grid,2,6,2,7)
	connect(_grid,2,7,2,8)
	connect(_grid,2,8,3,8)
	connect(_grid,3,8,3,7)
	connect(_grid,3,7,3,6)
	connect(_grid,3,8,4,8)
	connect(_grid,4,8,4,7)
	connect(_grid,1,4,2,4)
	connect(_grid,2,4,3,4)
	connect(_grid,3,4,4,4)
	connect(_grid,4,4,4,5)
	connect(_grid,3,4,3,3)
	connect(_grid,3,3,3,2)
	connect(_grid,3,4,3,5)
	connect(_grid,3,5,3,6)
	connect(_grid,3,2,4,2)
	connect(_grid,4,2,4,1)
	connect(_grid,4,1,5,1)
	connect(_grid,5,1,5,2)
	connect(_grid,4,2,4,3)
	connect(_grid,4,3,5,3)
	connect(_grid,5,3,5,2)
	connect(_grid,5,2,6,2)
	connect(_grid,4,5,5,5) -- !!!
	connect(_grid,5,5,5,6)
	connect(_grid,4,6,4,5)
	connect(_grid,3,6,4,6) -- !!!
	connect(_grid,4,6,4,7)
	connect(_grid,5,5,5,6)
	connect(_grid,4,7,5,7)
	connect(_grid,5,7,5,6)
	connect(_grid,5,6,6,6)
end

function tick(
	g -- grid : table
	)
	_tick=(_tick+1)%32768
	-- find initial signal sources
	local srcs={}
	for idx in all(g.dvcs) do
		local dvc=g.dat[idx]
		local outs={}
		if dvc!=0 then
			if dvc.name=="nand" then
				if dvc.ltikb!=_tick-1 then
					outs=dvc.outs
				end
			elseif dvc.name=="flip" then
				if dvc.on then
					dvc.ltik=_tick
					outs=dvc.outs
				end
			elseif dvc.name=="feed" then
				if dvc.tiks[6]==_tick-1 then
					add(outs,6)
				end
				if dvc.tiks[2]==_tick-1 then
					add(outs,2)
				end
			end
		end
		for out in all(outs) do
			local ofs=g.dirs[out]
			local nidx=idx+ofs
			if nidx!=idx then
				add(srcs,nidx)
			end
		end
	end
	-- process signals
	while #srcs>0 do
		local idx=srcs[1]
		if (
			idx>=1 and
			idx<=#g.dat and
			g.dat[idx]!=0 and
			g.dat[idx].ltik!=_tick
		) then
			-- update the device
			local dvc=g.dat[idx]
			if dvc.name=="nand" then
				if dvc.ltika==_tick then
					dvc.ltikb=_tick
				else
					dvc.ltika=_tick
				end
			elseif dvc.name=="feed"then
				-- todo: feed logic here
				local dvc1=g.dat[idx-1]
				if dvc1.ltik==_tick then
					dvc.tiks[6]=_tick
				end
				local idx2=idx-_grid.wd
				local dvc2=g.dat[idx2]
				if dvc2.ltik==_tick then
					dvc.tiks[2]=_tick
				end
			else
				dvc.ltik=_tick
			end
			-- only traverse wires
			if dvc.name=="wire" then
				for out in all(dvc.outs) do
					local ofs=g.dirs[out]
					local nidx=idx+ofs
					if nidx!=idx then
						add(srcs,nidx)
					end
				end
			end
		end
		deli(srcs,1)
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
		for i=1,#_grid.dirs do
			local ncl=_cl+_dirs[i][2]
			local nrw=_rw+_dirs[i][1]
			local nidx=cidx+_grid.dirs[i]
			local ndvc=_grid.dat[nidx]
			if (
				ndvc!=0 and
				nidx>=1 and
				nidx<=#_grid.dat and
				nidx!=cidx
			) then
				for out in all(ndvc.outs) do
					if _opps[out]==i then
						if (
							ndvc.name=="wire" or
							out==4
						) then
							connect(
								_grid,_cl,_rw,ncl,nrw
							)
						end
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
		-- cycle through devices
		if _grid.dat[cidx]==0 then
			addflip(_grid,_cl,_rw)
		else
			local dvc=_grid.dat[cidx]
			if dvc.name=="flip" then
				_grid.dat[cidx]=0
				del(_grid.dvcs,cidx)
				addnand(_grid,_cl,_rw)
			elseif dvc.name=="nand" then
				_grid.dat[cidx]=0
				del(_grid.dvcs,cidx)
				addfeed(_grid,_cl,_rw)
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
	-- draw grid
	for rw=1,_grid.ht do
		for cl=1,_grid.wd do
			local x=cl*3+_grid.lft
			local y=rw*3+_grid.top
			local idx=(rw-1)*_grid.wd+cl
			pset(x,y,1)
		end
	end
	-- draw wires
	local todo={}
	for idx in all(_grid.dvcs) do
		local cl=(idx-1)%_grid.wd+1
		local rw=flr(
			(idx-1)/_grid.wd
		)+1
		local x=cl*3+_grid.lft
		local y=rw*3+_grid.top
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
				line(x,y,x+2*dx,y+2*dy,c)
			end
		else
			add(todo,idx)
		end
	end
	-- draw other devices
	for idx in all(todo) do
		local cl=(idx-1)%_grid.wd+1
		local rw=flr(
			(idx-1)/_grid.wd
		)+1
		local x=cl*3+_grid.lft
		local y=rw*3+_grid.top
		local dvc=_grid.dat[idx]
		local dvcn=dvc.name
		if dvcn=="flip" then
			rect(x-1,y-1,x+1,y+1,4)
			local c=2
			if dvc.ltik==_tick then
				c=3
			end
			for out in all(dvc.outs) do
				local dr=_dirs[out]
				local dy=dr[1]
				local dx=dr[2]
				line(x,y,x+2*dx,y+2*dy,c)
			end
			c=2
			if dvc.on then
				c=3
			end
			pset(x,y,c)
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
			for out in all(dvc.outs) do
				local dr=_dirs[out]
				local dy=dr[1]
				local dx=dr[2]
				pset(x+2*dx,y+2*dy,c)
				--line(x,y,x+2*dx,y+2*dy,c)
			end
		elseif dvcn=="feed" then
			pset(x,y,4)
			for out in all(dvc.outs) do
				local ofs=_grid.dirs[out]
				local nidx=idx+ofs
				local ndvc=_grid.dat[nidx]
				if (
					nidx!=idx and
					ndvc!=nil and
					ndvc!=0 and
					nidx>=1 and
					nidx<=#_grid.dat
				) then
					local c=2
					local dr=_dirs[out]
					local dy=dr[1]
					local dx=dr[2]
					if dvc.tiks[out]==_tick then
						c=3
					end
					line(
						x+dx,y+dy,x+2*dx,y+2*dy,c
					)
				end
			end
		end
	end
	-- draw cursor
	local lt=_cl*3+_grid.lft
	local tp=_rw*3+_grid.top
	rect(lt-2,tp-2,lt+2,tp+2,1)
	-- draw debug info
	print(#_grid.dvcs,1,120,1)
	local cidx=(_rw-1)*_grid.wd+_cl
	local cdvc=_grid.dat[cidx]
	if (
		cdvc!=0 and
		cdvc.outs!=nil
	) then
		local x=_cl*3+_grid.lft
		local y=_rw*3+_grid.top
		for out in all(cdvc.outs) do
			local dr=_dirs[out]
			local dy=dr[1]
			local dx=dr[2]
			pset(x+2*dx,y+2*dy,11)
		end
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
