pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- nandgate
-- by sestrenexsis
-- github.com/sestrenexsis/nandgate

_me="sestrenexsis"
_cart="nandgate" -- "bredbord"?
cartdata(_me.."_".._cart.."_1")
_version=1

--disable button repeating
poke(0x5f5c,255)
poke(0x5f5d,255)

-- directions
_dirs={ -- {x,y}
	{-1, 1},{ 0, 1},{ 1, 1}, --123
	{-1, 0},{ 0, 0},{ 1, 0}, --456
	{-1,-1},{ 0,-1},{ 1,-1}  --789
	}
_opps={9,8,7,6,5,4,3,2,1}
_ortho={2,4,6,8}
_llog=""
_clk=16

function log(l)
	if l!=_llog then
		printh(l,_cart)
	end
	_llog=l
end

function newgrid(
	w, -- width      : number
	h, -- height     : number
	x, -- x position : number
	y  -- y position : number
	)
	local res={
		wd=w,
		ht=h,
		sx=x,
		sy=y,
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
	local l="addflip(_grid,"
	l=l..x..","..y..")"
	log(l)
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
	local l="addnand(_grid,"
	l=l..x..","..y..")"
	log(l)
	local res={
		name="nand",
		outs={6},
		tiks={}  -- signals received
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
	local l="addfeed(_grid,"
	l=l..x..","..y..")"
	log(l)
	local res={
		name="feed",
		outs={},
		tiks={}  -- signals received
	}
	local i=g.wd*(y-1)+x
	g.dat[i]=res
	add(g.dvcs,i)
	return res
end

function addlamp(
	g, -- grid       : table
	x, -- x position : number
	y  -- y position : number
	)
	local l="addlamp(_grid,"
	l=l..x..","..y..")"
	log(l)
	local res={
		name="lamp",
		tiks={}  -- signals received
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
	local l="connect(_grid,"
	l=l..sx..","..sy..","
	l=l..ex..","..ey..")"
	log(l)
	local si=g.wd*(sy-1)+sx
	local sdy=mid(-1,ey-sy,1)
	local sdx=mid(-1,ex-sx,1)
	local so=1
	for k,v in pairs(_dirs) do
		if (
			v[1]==sdx and
			v[2]==sdy
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
			v[1]==edx and
			v[2]==edy
		) then
			eo=k
			break
		end
	end
	if (
		g.dat[ei]!=0 and
		g.dat[ei].name=="wire" and
		g.dat[si].name=="wire" and
		(edx!=0 or edy!=0)
	) then
		--addifnew(g.dat[ei].outs,eo)
	end
end

function _setx(aa)
	_gx=aa
end

function _sety(aa)
	_gy=aa
end

function _push()
	add(_stk,_gx)
	add(_stk,_gy)
end

function _pull()
	if #_stk>1 then
		_gy=deli(_stk,#_stk)
		_gx=deli(_stk,#_stk)
	end
end

function _make(a)
	local g=_grid
	if a==0 then
		local idx=(_gy-1)*g.wd+_gx
		g.dat[idx]=0
		del(g.dvcs,idx)
	elseif a==1 then
		connect(g,_gx,_gy,_gx,_gy)
	elseif a==2 then
		addflip(g,_gx,_gy)
	elseif a==3 then
		addnand(g,_gx,_gy)
	elseif a==4 then
		addfeed(g,_gx,_gy)
	elseif a==5 then
		addlamp(g,_gx,_gy)
	end
end

function _fuse(a)
	local g=_grid
	local d=_dirs[a]
	local dx=d[1]
	local dy=d[2]
	connect(g,
		_gx,_gy,
		_gx+dx,_gy+dy
	)
	_gx+=dx
	_gy+=dy
end

function _move(a,b)
	local d=_dirs[a]
	local dx=d[1]
	local dy=d[2]
	_gx=mid(1,_gx+b*dx,_grid.wd)
	_gy=mid(1,_gy+b*dy,_grid.ht)
end

function makehalfadder(x,y)
	local msg="-- half adder"
	printh(msg,_cart)
	_setx(x)
	_sety(y)
	_move(2,1)
	_make(2) -- flip
	_fuse(6)
	_fuse(6)
	_push()
	_fuse(8)
	_fuse(6)
	_fuse(2)
	_make(3) -- nand
	_fuse(6)
	_push()
	_fuse(8)
	_fuse(6)
	_fuse(2)
	_make(3) -- nand
	_fuse(6)
	_make(5) -- lamp
	_pull()
	_fuse(2)
	_fuse(6)
	_fuse(8)
	_pull()
	_fuse(2)
	_fuse(2)
	_fuse(2)
	_make(4) -- feed
	_push()
	_fuse(2)
	_fuse(2)
	_fuse(2)
	_fuse(6)
	_push()
	_fuse(6)
	_fuse(8)
	_make(3) -- nand
	_pull()
	_fuse(8)
	_fuse(8)
	_make(3) -- nand
	_pull()
	_move(4,2)
	_move(2,1)
	_make(2) -- flip
	_fuse(6)
	_fuse(8)
	_fuse(6)
	_fuse(6)
	_push()
	_fuse(8)
	_push()
	_fuse(8)
	_fuse(8)
	_pull()
	_fuse(6)
	_fuse(2)
	_make(3) -- nand
	_fuse(6)
	_fuse(2)
	_make(3) -- nand
	_fuse(6)
	_make(5) -- lamp
	_pull()
	_fuse(2)
	_fuse(6)
	_push()
	_fuse(8)
	_pull()
	_fuse(2)
	_fuse(6)
	_fuse(8)
end

function makesrflipflop(x,y)
	local msg="-- sr flip flop"
	printh(msg,_cart)
	_setx(x)
	_sety(y)
	_push()
	_make(2) -- flip
	_fuse(6)
	_fuse(2)
	_make(3) -- nand
	_fuse(6)
	_fuse(8)
	_fuse(6)
	_fuse(2)
	_make(3) -- nand
	_fuse(6)
	_fuse(6)
	_fuse(6)
	_fuse(6)
	_make(5) -- lamp
	_move(4,1)
	_fuse(2)
	_fuse(2)
	_fuse(4)
	_make(4) -- feed
	_fuse(4)
	_fuse(4)
	_fuse(2)
	_pull()
	_move(2,2)
	_make(2) -- flip
	_fuse(6)
	_fuse(8)
	_move(2,1)
	_fuse(2)
	_make(3) -- nand
	_move(1,1)
	_make(2) -- flip
	_fuse(6)
	_fuse(8)
	_fuse(6)
	_fuse(2)
	_fuse(2)
	_fuse(6)
	_fuse(8)
	_make(3) -- nand
	_fuse(6)
	_fuse(6)
	_push()
	_fuse(6)
	_fuse(6)
	_make(5) -- lamp
	_pull()
	_fuse(8)
	_fuse(8)
	_fuse(4)
	_fuse(4)
	_fuse(8)
end
-->8
-- game loops

function nextpal()
	if _pal==nil then
		_pal=0
	end
	_pal+=1
	if _pal>#_pals then
		_pal=1
	end
	for i=0,#_pals[_pal] do
		pal(i,_pals[_pal][i],1)
	end
end

function _init()
	-- common vars
	_tick=0
	-- grid
	printh("",_cart,true)
	_grid=newgrid(32,32,12,12)
	_gx=1
	_gy=1
	_stk={}
	-- add starting devices
	makehalfadder(1,1)
	makehalfadder(9,5)
	makesrflipflop(1,16)
	printh("-- interactive",_cart)
	-- alter color palette
	_pals={
		{[0]=   1, 13,  2, 14,  7},
		{[0]=   0,  5,  3, 11,  7},
		{[0]= 129,131,  3, 11,138},
		{[0]= 128,133,134,143,15}
		}
	nextpal()
	menuitem(
		1,"next palette",nextpal
	)
end

function idxof(x,y)
	local res=(y-1)*_grid.wd+x
	return res
end

function xof(idx)
	local res=(idx-1)%_grid.wd+1
	return res
end

function yof(idx)
	local res=flr(
		(idx-1)/_grid.wd
	)+1
	return res
end

function device(
	g, -- grid         : table
	i, -- device index : number
	d  -- direction    : number
	)
	local res=nil
	if d==nil then
		d=5
	end
	local j=i+g.dirs[d]
	if j>=1 and j<=#g.dat then
		local dvc=g.dat[j]
		if dvc!=nil and dvc!=0 then
			res=dvc
		end
	end
	return res
end

function output(
	d -- device : table
	)
	local res={}
	if d!=0 then
		local dnm=d.name
		if dnm=="nand" then
			local pulses=0
			local s8=false
			local s2=false
			local dtk=d.tiks
			while #dtk>0 do
				local tik=deli(dtk,#dtk)
				pulses+=1
			end
			if pulses<2 then
				res=d.outs
			end
		elseif dnm=="flip" then
			if d.on then
				d.ltik=_tick
				res=d.outs
			end
		elseif dnm=="feed" then
			local dtk=d.tiks
			while #dtk>0 do
				add(res,deli(dtk,#dtk))
			end
		end
	end
	return res
end

function tick(
	g -- grid : table
	)
	_tick=(_tick+1)%32768
	-- find initial signal sources
	local srcs={}
	for idx in all(g.dvcs) do
		local dvc=g.dat[idx]
		for out in all(output(dvc)) do
			local nidx=idx+g.dirs[out]
			if nidx!=idx then
				add(srcs,{idx,nidx,out})
			end
		end
	end
	-- process signals
	while #srcs>0 do
		local src=srcs[1]
		local lidx=src[1]
		local idx=src[2]
		local lout=src[3]
		local dvc=device(g,idx)
		if (
			dvc!=nil and
			dvc.ltik!=_tick
		) then
			-- update the device
			if dvc.name=="nand" then
				add(dvc.tiks,lout)
			elseif dvc.name=="feed" then
				add(dvc.tiks,lout)
			else
				dvc.ltik=_tick
			end
			-- only traverse wires
			-- or lamp-to-lamp
			if dvc.name=="wire" then
				for out in all(dvc.outs) do
					local nidx=idx+g.dirs[out]
					if nidx!=idx then
						add(srcs,{idx,nidx,out})
					end
				end
			elseif dvc.name=="lamp" then
				for out in all(_ortho) do
					local nidx=idx+g.dirs[out]
					local ndvc=g.dat[nidx]
					if (
						nidx!=idx and
						ndvc!=0 and
						ndvc.name=="lamp"
					) then
						add(srcs,{idx,nidx,out})
					end
				end
			end
		end
		deli(srcs,1)
	end
end

function _update()
	-- input
	local lgx=_gx
	local lgy=_gy
	if btnp(⬅️) then
		_move(4,1)
	elseif btnp(➡️) then
		_move(6,1)
	end
	if btnp(⬆️) then
		_move(8,1)
	elseif btnp(⬇️) then
		_move(2,1)
	end
	local lidx=idxof(lgx,lgy)
	local cidx=idxof(_gx,_gy)
	local cdvc=device(_grid,cidx)
	if (
		btnp(❎) and
		cdvc!=nil and
		cdvc.name=="flip"
	) then
		-- toggle the flip
		cdvc.on=not cdvc.on
	elseif btn(❎) then
		connect(_grid,lgx,lgy,_gx,_gy)
	elseif (
		btnp(🅾️) or
		(btn(🅾️) and cidx!=lidx)
	) then
		-- cycle through devices
		if _grid.dat[cidx]==0 then
			addflip(_grid,_gx,_gy)
		else
			local dvc=_grid.dat[cidx]
			if dvc.name=="flip" then
				_grid.dat[cidx]=0
				del(_grid.dvcs,cidx)
				addnand(_grid,_gx,_gy)
			elseif dvc.name=="nand" then
				_grid.dat[cidx]=0
				del(_grid.dvcs,cidx)
				addfeed(_grid,_gx,_gy)
			elseif dvc.name=="feed" then
				_grid.dat[cidx]=0
				del(_grid.dvcs,cidx)
				addlamp(_grid,_gx,_gy)
			else
				_grid.dat[cidx]=0
				del(_grid.dvcs,cidx)
			end
		end
	end
	if btnp(⬆️,1) then
		tick(_grid)
	elseif btnp(➡️,1) then
		for i=1,_clk do
			tick(_grid)
		end
	end
end

function _draw()
	cls(0)
	-- draw palette
	for i=0,4 do
		local sx=1
		local sy=6*i+1
		print(tostr(i),sx+1,sy+1,1)
		print(tostr(i),sx,sy,4)
		rect(sx+5,sy+1,sx+9,sy+5,1)
		rect(sx+4,sy,sx+8,sy+4,4)
		rectfill(
			sx+5,sy+1,
			sx+7,sy+3,
			i)
	end
	-- draw grid
	for gy=1,_grid.ht do
		for gx=1,_grid.wd do
			local sx=gx*3+_grid.sx
			local sy=gy*3+_grid.sy
			pset(sx,sy,1)
		end
	end
	-- draw wires
	local todo={}
	for idx in all(_grid.dvcs) do
		local gx=xof(idx)
		local gy=yof(idx)
		local sx=gx*3+_grid.sx
		local sy=gy*3+_grid.sy
		local dvc=_grid.dat[idx]
		local dvcn=dvc.name
		if dvcn=="wire" then
			local c=2
			if dvc.ltik==_tick then
				c=3
			end
			for out in all(dvc.outs) do
				local d=_dirs[out]
				local dx=d[1]
				local dy=d[2]
				line(
					sx,sy,sx+2*dx,sy+2*dy,c
				)
			end
		else
			add(todo,idx)
		end
	end
	-- draw other devices
	for idx in all(todo) do
		local gx=xof(idx)
		local gy=yof(idx)
		local sx=gx*3+_grid.sx
		local sy=gy*3+_grid.sy
		local dvc=_grid.dat[idx]
		local dvcn=dvc.name
		if dvcn=="flip" then
			rect(sx-1,sy-1,sx+1,sy+1,4)
			local c=2
			if dvc.ltik==_tick then
				c=3
			end
			for out in all(dvc.outs) do
				local d=_dirs[out]
				local dx=d[1]
				local dy=d[2]
				line(
					sx,sy,sx+2*dx,sy+2*dy,c
				)
			end
			c=2
			if dvc.on then
				c=3
			end
			pset(sx,sy,c)
		elseif dvcn=="nand" then
			rectfill(sx-1,sy-1,sx,sy+1,4)
			pset(sx+1,sy,4)
			local c=3
			if #dvc.tiks==2 then
				c=2
			end
			for out in all(dvc.outs) do
				local d=_dirs[out]
				local dx=d[1]
				local dy=d[2]
				pset(sx+2*dx,sy+2*dy,c)
			end
		elseif dvcn=="feed" then
			pset(sx,sy,4)
			local tk={0,0,0,0,0,0,0,0,0}
			for out in all(dvc.tiks) do
				tk[out]=1
			end
			for out in all(dvc.outs) do
				local ndvc=device(
					_grid,idx,out
				)
				if ndvc!=nil and out!=5 then
					local c=2
					local d=_dirs[out]
					local dx=d[1]
					local dy=d[2]
					if tk[out]==1 then
						c=3
					end
					line(
						sx+dx,sy+dy,
						sx+2*dx,sy+2*dy,c
					)
				end
			end
		elseif dvcn=="lamp" then
			local c=2
			if dvc.ltik==_tick then
				c=3
			end
			rectfill(
				sx-1,sy-1,sx+1,sy+1,c
			)
		end
	end
	-- draw cursor
	local sx=_gx*3+_grid.sx
	local sy=_gy*3+_grid.sy
	rect(sx-2,sy-2,sx+2,sy+2,1)
	-- draw debug info
	print(#_grid.dvcs,1,120,1)
	print(stat(0)/2048,96,114,1)
	print(stat(1),96,120,1)
	local cidx=idxof(_gx,_gy)
	local cdvc=_grid.dat[cidx]
	if (
		cdvc!=0 and
		cdvc.outs!=nil
	) then
		local sx=_gx*3+_grid.sx
		local sy=_gy*3+_grid.sy
		for out in all(cdvc.outs) do
			local d=_dirs[out]
			local dx=d[1]
			local dy=d[2]
			pset(sx+2*dx,sy+2*dy,11)
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
