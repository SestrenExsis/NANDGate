pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- nandgate
-- by sestrenexsis
-- github.com/sestrenexsis/nandgate

_me="sestrenexsis"
_cart="nandgate"
-- "bredbord"?
-- ace circuits?
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
_clk=16

function log(l)
	printh(l,_cart)
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

function hex(n,l)
	local str=tostr(n,true)
	local res=""
	for i=7-l,6 do
		res=res..sub(str,i,i)
	end
	return res
end
-->8
-- grid

grid={}

function grid:new(
	w, -- width      : number
	h  -- height     : number
	)
	local obj={
		wd=w,
		ht=h,
		sx=12,
		sy=12,
		x=flr(0.5*w),
		y=flr(0.5*h),
		dat={},
		dvcs={},
		dirs={
			 w-1, w  , w+1, -- 123
			  -1,   0,   1, -- 456
			-w-1,-w  ,-w+1  -- 789
		},
		stk={},
		hst={}
	}
	for i=1,w*h do
		add(obj.dat,0)
	end
	return setmetatable(
		obj,{__index=self}
	)
end

function grid:idxof(x,y)
	local res=(y-1)*self.wd+self.x
	return res
end

function grid:xof(i)
	local res=(i-1)%self.wd+1
	return res
end

function grid:yof(i)
	local res=flr((i-1)/self.wd)+1
	return res
end

function grid:device(
	i, -- device index : number
	d  -- direction    : number
	)
	local res=nil
	if d==nil then
		d=5
	end
	local j=i+self.dirs[d]
	if j>=1 and j<=#self.dat then
		local dvc=self.dat[j]
		if dvc!=nil and dvc!=0 then
			res=dvc
		end
	end
	return res
end

function grid:connect(
	sx,sy, -- start pos : numbers
	ex,ey  -- end pos   : numbers
	)
	local si=self.wd*(sy-1)+sx
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
	if self.dat[si]==0 then
		self.dat[si]=newwire(so)
		add(self.dvcs,si)
	elseif sdx!=0 or sdy!=0 then
		addifnew(self.dat[si].outs,so)
	end
end

function grid:run(
	cmds -- commands : table
)
	local i=1
	while i<#cmds do
		local cmd=cmds[i]
		if cmd==1 then
			local a=cmds[i+1]
			local b=cmds[i+2]
			self:setx(0x10*a+b)
			i+=3
		elseif cmd==2 then
			local a=cmds[i+1]
			local b=cmds[i+2]
			self:sety(0x10*a+b)
			i+=3
		elseif cmd==3 then
			self:push()
			i+=1
		elseif cmd==4 then
			self:pull()
			i+=1
		elseif cmd==5 then
			local a=cmds[i+1]
			self:make(a)
			i+=2
		elseif cmd==6 then
			local a=cmds[i+1]
			self:fuse(a)
			i+=2
		elseif cmd==7 then
			local a=cmds[i+1]
			local b=cmds[i+2]
			self:move(a,b)
			i+=3
		else
			break
		end
	end
end

function grid:setx(aa)
	log("1"..hex(aa,2))
	self.x=aa
	add(self.hst,1)
	add(self.hst,flr(aa/0x10))
	add(self.hst,aa%0x10)
end

function grid:sety(aa)
	log("2"..hex(aa,2))
	self.y=aa
	add(self.hst,2)
	add(self.hst,flr(aa/0x10))
	add(self.hst,aa%0x10)
end

function grid:push()
	log("3")
	add(self.stk,self.x)
	add(self.stk,self.y)
	add(self.hst,3)
end

function grid:pull()
	log("4")
	local n=#self.stk
	if n>1 then
		self.y=deli(self.stk,n)
		self.x=deli(self.stk,n-1)
	end
	add(self.hst,4)
end

function grid:make(a)
	log("5"..hex(a,1))
	local x=self.x
	local y=self.y
	if a==0 then
		local idx=self:idxof(x,y)
		self.dat[idx]=0
		del(self.dvcs,idx)
	elseif a==1 then
		self:connect(x,y,x,y)
	else
		local i=self.wd*(y-1)+x
		local dvc=0
		if a==2 then
			dvc={
				name="flip",
				outs={},
				ltik=-1,
				on=true
			}
		elseif a==3 then
			dvc={
				name="nand",
				outs={6},
				tiks={}
			}
		elseif a==4 then
			dvc={
				name="feed",
				outs={},
				tiks={}
			}
		elseif a==5 then
			dvc={
				name="lamp",
				tiks={}
			}
		else
			assert(1==2)
		end
		self.dat[i]=dvc
		addifnew(self.dvcs,i)
	end
	add(self.hst,5)
	add(self.hst,a%0x10)
end

function grid:fuse(a)
	log("6"..hex(a,1))
	local d=_dirs[a]
	local dx=d[1]
	local dy=d[2]
	self:connect(
		self.x,self.y,
		self.x+dx,self.y+dy
	)
	local idx=self:idxof(
		self.x,self.y
	)
	local dvc=self:device(idx)
	local ndvc=self:device(idx,a)
	if (
		dvc!=nil and
		dvc.name=="wire" and
		ndvc!=nil and
		ndvc.name=="wire"
	) then
		self:connect(
			self.x+dx,self.y+dy,
			self.x,self.y
		)
	end
	self.x+=dx
	self.y+=dy
	add(self.hst,6)
	add(self.hst,a%0x10)
end

function grid:move(a,b)
	log("7"..hex(a,1)..hex(b,1))
	local d=_dirs[a]
	local dx=b*d[1]
	local dy=b*d[2]
	self.x=mid(1,self.x+dx,self.wd)
	self.y=mid(1,self.y+dy,self.ht)
	add(self.hst,7)
	add(self.hst,flr(a%0x10))
	add(self.hst,b%0x10)
end

_cmds={
	or_gate={
		5,4,6,6,3,6,6,6,
		2,5,3,6,6,6,2,5,
		3,6,6,3,6,6,5,4,
		6,6,4,3,6,8,6,6,
		5,4,6,6,4,6,2,6,
		6,5,4,6,6,4,6,2,
		6,8,7,1,1,5,4,6,
		6,6,6,7,1,2,5,4,
		6,6,3,6,6,5,3,6,
		6,6,8,4,6,2,6,8,
		7,1,1,5,4,6,6,6,
		6,6,8
	},
	half_adder={
		3,5,4,6,6,6,2,6,
		6,6,6,5,3,6,6,6,
		2,5,3,6,6,3,6,6,
		5,4,6,6,4,6,8,3,
		6,6,5,4,6,6,4,6,
		8,6,6,5,4,6,6,4,
		7,2,1,5,4,6,6,7,
		1,1,5,4,6,6,3,6,
		8,4,6,2,5,3,6,6,
		3,6,8,6,6,3,6,8,
		4,6,2,5,3,6,6,6,
		8,4,6,2,5,4,6,2,
		3,6,6,6,2,5,3,6,
		6,6,6,3,6,8,6,6,
		5,4,6,6,4,3,6,6,
		5,4,6,6,4,6,2,6,
		6,5,4,6,6,4,6,2,
		6,6,7,4,3,7,2,1,
		3,5,4,6,6,6,8,6,
		8,6,8,3,6,8,4,6,
		6,6,6,6,8,4,7,8,
		1,5,4,6,6,7,7,1,
		5,4,6,6
	},
	sr_flip_flop={
		3,5,2,6,6,6,2,5,
		3,6,6,6,8,6,6,6,
		2,5,3,6,6,6,6,6,
		6,6,6,5,5,7,4,1,
		6,2,6,2,6,4,5,4,
		6,4,6,4,6,2,4,7,
		2,2,5,2,6,6,6,8,
		7,2,1,6,2,5,3,7,
		1,1,5,2,6,6,6,8,
		6,6,6,2,6,2,6,6,
		6,8,5,3,6,6,6,6,
		3,6,6,6,6,5,5,4,
		6,8,6,8,6,4,6,4,
		6,8
	}
}
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
	_tools={
		"delete",
		"feed",
		"lamp",
		"flip",
		"interact",
		"wire",
		"-",
		"nand",
		"-"
		}
	_toolidx=5
	_toolbox=false
	_g=grid:new(32,32)
	cmds={}
	for y=0,127 do
		for x=0,127 do
			local c=sget(x,y)
			add(cmds,c)
		end
	end
	--_g:run(cmds)
	-- add starting devices
	---[[
	_g:setx(3)
	_g:sety(6)
	_g:run(_cmds.half_adder)
	_g:setx(10)
	_g:sety(1)
	_g:run(_cmds.half_adder)
	_g:setx(17)
	_g:sety(7)
	_g:run(_cmds.or_gate)
	_g:setx(5)
	_g:sety(16)
	_g:run(_cmds.sr_flip_flop)
	_g:setx(15)
	_g:sety(16)
	_g:run(_cmds.sr_flip_flop)
	--]]
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
		local dvc=_g:device(idx)
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
						ndvc!=nil and
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
	local lgx=_g.x
	local lgy=_g.y
	if btn(🅾️) then
		_toolbox=true
		local lf=btn(⬅️)
		local rt=btn(➡️)
		local up=btn(⬆️)
		local dn=btn(⬇️)
		if lf and not rt then
			_toolidx=1
		elseif rt and not lf then
			_toolidx=3
		else
			_toolidx=2
		end
		if dn and not up then
			_toolidx+=0
		elseif up and not dn then
			_toolidx+=6
		else
			_toolidx+=3
		end
	else
		_toolbox=false
		if btnp(⬅️) then
			_g:move(4,1)
		elseif btnp(➡️) then
			_g:move(6,1)
		end
		if btnp(⬆️) then
			_g:move(8,1)
		elseif btnp(⬇️) then
			_g:move(2,1)
		end
	end
	local tool=_tools[_toolidx]
	local lidx=_g:idxof(lgx,lgy)
	local cidx=_g:idxof(_g.x,_g.y)
	local cdvc=_g:device(cidx)
	if tool=="interact" then
		if (
			btnp(❎) and
			cdvc!=nil and
			cdvc.name=="flip"
		) then
			-- toggle the flip
			cdvc.on=not cdvc.on
		elseif btnp(❎) then
			-- advance 1 tick
			tick(_g)
		end
	elseif tool=="wire" then
		if btn(❎) then
			_g:connect(lgx,lgy,_g.x,_g.y)
		end
	elseif tool=="delete" then
		if btn(❎) then
			_g:make(0)
		end
	else
		if btnp(❎) then
			if tool=="flip" then
				_g:make(2)
			elseif tool=="nand" then
				_g:make(3)
			elseif tool=="feed" then
				_g:make(4)
			elseif tool=="lamp" then
				_g:make(5)
			end
		end
	end
	if btnp(⬆️,1) then
		tick(_g)
	elseif btnp(➡️,1) then
		for i=1,_clk do
			tick(_g)
		end
	elseif btnp(⬅️,1) then
		-- save history to spritesheet
		for i=1,#_g.hst+32 do
			local x=(i-1)%128
			local y=flr((i-1)/128)
			local c=0
			if i<=#_g.hst then
				c=_g.hst[i]
			end
			sset(x,y,c)
		end
		cstore(0x0000,0x0000,0x2000)
	end
end

function drawdummy(
	n,  -- name     : string
	x,  -- x pos    : number
	y   -- y pos    : number
	)
	if n=="wire" then
		pset(x,y,2)
	elseif n=="flip" then
		rect(x-1,y-1,x+1,y+1,4)
		pset(x,y,2)
	elseif n=="nand" then
		rectfill(x-1,y-1,x,y+1,4)
		pset(x+1,y,4)
	elseif n=="feed" then
		pset(x,y,4)
	elseif n=="lamp" then
		rectfill(x-1,y-1,x+1,y+1,2)
	elseif n=="delete" then
		line(x-1,y-1,x+1,y+1,4)
		line(x-1,y+1,x+1,y-1,4)
	elseif n=="interact" then
		line(x,y-1,x,y+1,4)
		line(x-1,y,x+1,y,4)
	end
end

function drawdevice(
	g,   -- grid         : table
	idx, -- device index : number
	dvc, -- device       : table
	x,   -- screen x     : number
	y    -- screen y     : number
	)
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
				x,y,x+2*dx,y+2*dy,c
			)
		end
	elseif dvcn=="flip" then
		rect(x-1,y-1,x+1,y+1,4)
		local c=2
		if dvc.ltik==_tick then
			c=3
		end
		for out in all(dvc.outs) do
			local d=_dirs[out]
			local dx=d[1]
			local dy=d[2]
			line(
				x,y,x+2*dx,y+2*dy,c
			)
		end
		c=2
		if dvc.on then
			c=3
		end
		pset(x,y,c)
	elseif dvcn=="nand" then
		rectfill(x-1,y-1,x,y+1,4)
		pset(x+1,y,4)
		local c=3
		if #dvc.tiks==2 then
			c=2
		end
		for out in all(dvc.outs) do
			local d=_dirs[out]
			local dx=d[1]
			local dy=d[2]
			pset(x+2*dx,y+2*dy,c)
		end
	elseif dvcn=="feed" then
		pset(x,y,4)
		local tk={0,0,0,0,0,0,0,0,0}
		for out in all(dvc.tiks) do
			tk[out]=1
		end
		for out in all(dvc.outs) do
			local ndvc=g:device(
				idx,out
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
					x+dx,y+dy,
					x+2*dx,y+2*dy,c
				)
			end
		end
	elseif dvcn=="lamp" then
		local c=2
		if dvc.ltik==_tick then
			c=3
		end
		rectfill(
			x-1,y-1,x+1,y+1,c
		)
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
			sx+5,sy+1,sx+7,sy+3,i
		)
	end
	-- draw grid
	for gy=1,_g.ht do
		for gx=1,_g.wd do
			local sx=gx*3+_g.sx
			local sy=gy*3+_g.sy
			pset(sx,sy,1)
		end
	end
	-- draw wires
	local todo={}
	for idx in all(_g.dvcs) do
		local gx=_g:xof(idx)
		local gy=_g:yof(idx)
		local sx=gx*3+_g.sx
		local sy=gy*3+_g.sy
		local dvc=_g.dat[idx]
		local dvcn=dvc.name
		if dvcn=="wire" then
			drawdevice(_g,idx,dvc,sx,sy)
		else
			add(todo,idx)
		end
	end
	-- draw other devices
	for idx in all(todo) do
		local gx=_g:xof(idx)
		local gy=_g:yof(idx)
		local sx=gx*3+_g.sx
		local sy=gy*3+_g.sy
		local dvc=_g.dat[idx]
		drawdevice(_g,idx,dvc,sx,sy)
	end
	-- draw cursor
	local sx=_g.x*3+_g.sx
	local sy=_g.y*3+_g.sy
	rect(sx-2,sy-2,sx+2,sy+2,1)
	-- draw debug info
	print(#_g.dvcs,1,120,1)
	print(stat(0)/2048,96,114,1)
	print(stat(1),96,120,1)
	print(_tick,64,120,1)
	local cidx=_g:idxof(_g.x,_g.y)
	local cdvc=_g.dat[cidx]
	if (
		cdvc!=0 and
		cdvc.outs!=nil
	) then
		local sx=_g.x*3+_g.sx
		local sy=_g.y*3+_g.sy
		for out in all(cdvc.outs) do
			local d=_dirs[out]
			local dx=d[1]
			local dy=d[2]
			pset(sx+2*dx,sy+2*dy,11)
		end
	end
	-- draw toolbox
	local msg=_toolidx..": "
	msg=msg.._tools[_toolidx]
	print(msg,15,1,4)
	if _toolbox then
		local lf=_g.sx+3*_g.x-6
		local tp=_g.sy+3*_g.y-6
		local lf_=lf
		local tp_=tp
		rectfill(lf,tp,lf+12,tp+12,1)
		lf+=4*((_toolidx-1)%3)
		tp+=4*flr((9-_toolidx)/3)
		rectfill(lf,tp,lf+4,tp+4,0)
		lf=lf_
		tp=tp_
		--drawdummy("-",lf+2,tp+2)
		drawdummy("nand",lf+6,tp+2)
		--drawdummy("-",lf+10,tp+2)
		drawdummy("flip",lf+2,tp+6)
		drawdummy("interact",lf+6,tp+6)
		drawdummy("wire",lf+10,tp+6)
		drawdummy("delete",lf+2,tp+10)
		drawdummy("feed",lf+6,tp+10)
		drawdummy("lamp",lf+10,tp+10)
	end
end
__gfx__
10320635466626666536662536636654664683665466468665466472154667115466368462536636866368462536668462546236662536666368665466436654
664626654664626674372135466686868368466666847815466771546610a2013546662666653666253663665466468366546646866546647215466711546636
84625366368663684625366684625462366625366663686654664366546646266546646266743721354666868683684666668478154667715466111207546636
66253666253663665466436866546646266546646268711546666712546636653666846268711546666681052103526662536668666253666666665574162626
45464646247225266687216253711526668666262666853666636666554686864646810f21035266625366686662536666666655741626264546464624722526
66872162537115266686662626668536666366665546868646468721721721741741741721741741741741741741741721721721741741741741741741721721
72172172174172152537217617815253547615253547615253547615253547615253547615253547815253547415253547415253547415253547415253547415
25354721721525354761525354761525354761525354761525354761525354781741741741741741741761761761761761761761781741741741741741741741
72176176176176176176176172174174174174174174174178176176176178178178178174174174172172176176176176176176176172178176176152537417
21761781741761761761741741741741741741741781741781781781741741741781525354555076152537617415455505276172172152537817817417617217
21781741721761761761781781525372178174174176176174172172174176172172172176176176176174174174174178178178150781721505253547417617
81761781721741721555078150761507417217215072150721507617817215076174178178178178178172172174176150525354741761721721781781781721
72172176178178178178174172172176176174172174176178150525372174178172176178176176176174174178178176152537217217615253781781721781
72172176178174150525354721761781741741781741741761761721721741741761761761721721781781781781761761721721741761761761761761781781
52537217217615253761781781525372172176152537417617815253547817417617217217617817417417817417617217217417417417417417817817417617
61761761741741721721721721721741761761761781781781781721721741741741741781761761761761761741741761505253547617417217217217817817
81781781721721721761781761761761781781741761761761741505253547615052535455741761741721741721761741761781781781741741741741741741
74174174174174174174174174174174172174153545550741761761761781741761505074174172172172172172176176176176176176176176176176176176
17617617617617617610000000000000000000000000000000017417417817417417417417417417417617617617617617617617617617617617615253741741
74174174174174174174176176176176176176176176176178174176178178178174176174174174174174174176176176176176176172172176176178172172
17417617617617817417417817815072155507417617417617417617617417817617417217217217417815072150781781507615072172172174176178150525
35472178178178176172172174174174176176176174172172172174174174178178174176176174172176178174174174174174174174174174174174174176
17617617617617617617617617617617417417417417417617617617617617617617617617617617617617617617617817817817817615253545574174176176
17417417217217217617817817815052535474176176174172172172174176178178178178174174174174174174174174174174174174174174174174174174
17417417417217617217417217217417617617617617817217617417817817817217417417417817817615074174100000000000000000000000000000000000
