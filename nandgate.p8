pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- nandgate
-- by sestrenexsis
-- github.com/sestrenexsis/nandgate

_version=1
cartdata("sestrenexsis_nandgate_1")

function _init()
	-- common vars
	---[[
	_pal={[0]=
		 1, -- 1 or  0
		13, --13 or  5
		 2, -- 2 or  3
		14, --14 or 11
		 7  -- 7 or  7
		}
	-- alter color palette
	for i=0,#_pal do
		pal(i,_pal[i],1)
	end
	-- grid
	_rows=16 --36
	_cols=16 --36
	_grid={[0]=0}
	for i=1,_rows*_cols-1 do
		add(_grid,0)
	end
	_grdtp=15
	_grdlt=15
	_rw=0
	_cl=0
	_wires={}
	_dirs={[0]= -- {row,col,index}
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
end

function _update()
	-- input
	local lcl=_cl
	local lrw=_rw
	if btnp(⬅️) then
		_cl=max(0,_cl-1)
	elseif btnp(➡️) then
		_cl=min(_cols-1,_cl+1)
	end
	if btnp(⬆️) then
		_rw=max(0,_rw-1)
	elseif btnp(⬇️) then
		_rw=min(_rows-1,_rw+1)
	end
	if btn(🅾️) then
		-- add wire if cell is free
		local idx=_rw*_cols+_cl
		if _grid[idx]==0 then
			local wire=0
			local drw=mid(-1,_rw-lrw,1)
			local dcl=mid(-1,_cl-lcl,1)
			for k,v in pairs(_dirs) do
				if v[1]==drw and v[2]==dcl then
					wire=k
					break
				end
			end
			add(_wires,wire)
			_grid[idx]=#_wires
		end
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
	for rw=0,_rows-1 do
		for cl=0,_cols-1 do
			local x=cl*3+_grdlt
			local y=rw*3+_grdtp
			local idx=rw*_cols+cl
			if _grid[idx]==0 then
				pset(x,y,1)
			else
				local w=_wires[_grid[idx]]
				local dr=_dirs[w]
				local dx=dr[2]
				local dy=dr[1]
				pset(x,y,3)
				pset(x+dx,y+dy,3)
				pset(x+2*dx,y+2*dy,3)
			end
		end
	end
	-- draw cursor
	local lt=_cl*3+_grdlt
	local tp=_rw*3+_grdtp
	if t()%0.5<0.25 then
		rect(lt-1,tp-1,lt+1,tp+1,4)
	else
		rect(lt-1,tp-1,lt+1,tp+1,1)
	end
	print(#_wires,120,120,1)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
