pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- nandgate
-- by sestrenexsis
-- github.com/sestrenexsis/nandgate

_version=1
cartdata("sestrenexsis_nandgate_1")

_colors={[0]=1,13,2,14,7}
--[[
_colors={[0]=0,4,3,11,7}
--]]

function _init()
	-- init
	for i=0,4 do
		pal(i,_colors[i],1)
	end
	_rows=8 --36
	_cols=8 --36
	_rw=0
	_cl=0
	_grdtp=15
	_grdlt=15
	_wires={}
end

function _update()
	-- input
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
	if btnp(🅾️) then
		-- add wire if cell is free
		local wire={_rw,_cl}
		local free=true
		for w in all(_wires) do
			if (
				w[1]==wire[1] and
				w[2]==wire[2]
			) then
				free=false
				break
			end
		end
		if free then
			add(_wires,wire)
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
		rect(lf+4,tp,lf+8,tp+4,4)
		rectfill(lf+5,tp+1,lf+7,tp+3,i)
	end
	-- draw grid
	for rw=0,_rows-1 do
		for cl=0,_cols-1 do
			local x=cl*3+_grdlt
			local y=rw*3+_grdtp
			pset(x,y,1)
		end
	end
	-- draw wires
	for w in all(_wires) do
		local rw=w[1]
		local cl=w[2]
		local x=cl*3+_grdlt
		local y=rw*3+_grdtp
		pset(x,y,3)
	end
	-- draw cursor
	local lt=_cl*3+_grdlt
	local tp=_rw*3+_grdtp
	if t()%0.5<0.25 then
		rect(lt-1,tp-1,lt+1,tp+1,4)
	else
		rect(lt-1,tp-1,lt+1,tp+1,1)
	end
	print(#_wires,120,120)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
