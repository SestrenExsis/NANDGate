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

function newdevice(
	n, -- device name : string
	o  -- output      : number
	)
	local res={
		name=n,
		outs={o},
		ltik=-1 -- last powered tick
	}
	return res
end

function newwire(o)
	local res=newdevice("wire",o)
	return res
end

function newflip(o)
	local res=newdevice("flip",o)
	res.on=true
	return res
end

function _init()
	-- common vars
	_tick=0
	-- alter color palette
	_pals={
		{[0]= 1,13, 2,14, 7},
		{[0]= 0, 5, 3,11, 7}
		}
		_pal=_pals[1]
	for i=0,#_pal do
		pal(i,_pal[i],1)
	end
	-- grid
	_rows=16 --36
	_cols=16 --36
	_grid={}
	for i=1,_rows*_cols do
		add(_grid,0)
	end
	assert(#_grid==_rows*_cols)
	_grdtp=15
	_grdlt=15
	_rw=1
	_cl=1
	_dvcs={}
	_dirs={
		-- {row,col,index}
		{ 0, 0,       0}, -- none
		{-1, 0,-_cols  }, -- north
		{-1, 1,-_cols+1}, -- northeast
		{ 0, 1,       1}, -- east
		{ 1, 1, _cols+1}, -- southeast
		{ 1, 0, _cols  }, -- south
		{ 1,-1, _cols-1}, -- southwest
		{ 0,-1,      -1}, -- west
		{-1,-1,-_cols-1}, -- northwest
		}
	_opps={1,6,7,8,9,2,3,4,5}
	-- add a starting flip
	local i=_cols*flr(_rows*0.5)+1
	_grid[i]=newflip(4)
	add(_dvcs,i)
	local wire=newwire(4)
	add(wire.outs,2)
	add(wire.outs,6)
	_grid[i+1]=wire
	add(_dvcs,i+1)
end

function tick()
	_tick=(_tick+1)%32768
	local srcs={}
	for i in all(_dvcs) do
		local dvc=_grid[i]
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
		local dvc=_grid[idx]
		for out in all(dvc.outs) do
			local ofs=_dirs[out][3]
			local n=idx+ofs
			if (
				n>=1 and
				n<=#_grid and
				_grid[n]!=0 and
				_grid[n].ltik<_tick
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
		_cl=min(_cols,_cl+1)
	end
	if btnp(⬆️) then
		_rw=max(1,_rw-1)
	elseif btnp(⬇️) then
		_rw=min(_rows,_rw+1)
	end
	local lidx=(lrw-1)*_cols+lcl
	local cidx=(_rw-1)*_cols+_cl
	if btn(❎) then
		-- add wire if cell is free
		if _grid[cidx]==0 then
			local drw=mid(-1,_rw-lrw,1)
			local dcl=mid(-1,_cl-lcl,1)
			for k,v in pairs(_dirs) do
				if (
					v[1]==drw and
					v[2]==dcl
				) then
					_grid[lidx]=newwire(k)
					add(_dvcs,lidx)
					break
				end
			end
		elseif btnp(❎) then
			local dvc=_grid[cidx]
			if dvc.name=="flip" then
				dvc.on=not dvc.on
			end
		end
	elseif btn(🅾️) then
		-- remove device if exists
		-- add new flip if empty
		if btnp(🅾️) or cidx!=lidx then
			if _grid[cidx]==0 then
				_grid[cidx]=newflip(4)
				add(_dvcs,cidx)
			else
				_grid[cidx]=0
				del(_dvcs,cidx)
			end
		end
	end
	if btnp(⬆️,1) then
		tick()
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
	for rw=1,_rows do
		for cl=1,_cols do
			local x=cl*3+_grdlt
			local y=rw*3+_grdtp
			local idx=(rw-1)*_cols+cl
			pset(x,y,1)
			if _grid[idx]!=0 then
				local dvc=_grid[idx]
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
	local lt=_cl*3+_grdlt
	local tp=_rw*3+_grdtp
	rect(lt-2,tp-2,lt+2,tp+2,1)
	print(#_dvcs,116,120,1)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
