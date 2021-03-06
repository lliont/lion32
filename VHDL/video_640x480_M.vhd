-- Color Video Controller 
-- Theodoulos Liontakis (C) 2016 - 2017

-- 640x480 @60 Hz
-- Vertical refresh	31.46875 kHz
-- Pixel freq.	25.175 MHz  (25 Mhz)

--Scanline part	Pixels	Time [µs]
--Visible area	640	25.422045680238
--Front porch	16	   0.63555114200596
--Sync pulse	96		3.8133068520357
--Back porch	48		1.9066534260179
--Whole line	800	31.777557100298

--Frame part	Lines	Time [ms]
--Visible area	480	15.253227408143
--Front porch	10		0.31777557100298
--Sync pulse	2		0.063555114200596
--Back porch	33		1.0486593843098
--Whole frame	525	16.683217477656

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity VideoRGB80 is
	port
	(
		sclk, vclk, EN: IN std_logic;
		R,G,B,BRI0,VSYN,HSYN, VSINT, HSINT: OUT std_logic;
		addr : OUT natural range 0 to 32767; 
		Q : IN std_logic_vector(15 downto 0);
		hline: OUT std_logic_vector(15 downto 0)
	);
end VideoRGB80;

Architecture Behavior of VideoRGB80 is

constant vbase: natural:= 0;
constant ctbl: natural:= 12000+16384;
constant l1:natural:=35;
constant lno:natural:=240;
constant p1:natural :=142;
constant pno:natural:=640;
constant cxno:natural:=80;
constant p2:natural:=p1+pno;
constant l2:natural:=l1+lno*2;

Signal lines,pix: natural range 0 to 1023;
Signal pixel, prc : natural range 0 to 1023;
Signal addr2,addr3: natural range 0 to 32767;
signal m8,p6: natural range 0 to 127;
Signal vidc: boolean:=false;
Signal FG,BG: std_logic_vector(3 downto 0);

shared variable addr1:natural range 0 to 32767;

begin

addr<=addr1;
vidc<=not vidc when rising_edge(vclk);
HSYN<='0' when (pixel<96)  else '1'; 
VSYN<='0' when lines<2 else '1';
VSINT<='0' when (lines=0) and (pixel<6) else '1';
HSINT<='0' when pixel<6 and lines>=l1 and lines<=l2 else '1';
hline<=std_logic_vector(to_unsigned(lines,16));

process (sclk,EN)
variable m78: natural range 0 to 31;
variable lin, p16, pd4, pm4: natural range 0 to 1023;

begin
	if  rising_edge(sclk) and EN='0' then
		if  vidc then 
			if pixel=799 then
				pixel<=0; pix<=0; p6<=0; prc<=0; 
				if lines<524 then	lines<=lines+1; else lines<=0; end if;
				if lines=l1-1 then m8<=0; addr2<=vbase/2; else
					if m8=15 then m8<=0; addr2<=addr2+pno/2; else m8<=m8+1; end if;
				end if;
			else
				pixel<=pixel+1;
			end if;
			if (p6=0) and (pixel>=p1-1) and (pixel<p2) then addr1:=addr3+prc/2; end if;
			 
			if (lines>=l1 and lines<l2 and pixel>=p1 and pixel<p2) then
				if Q(m78)='1' then BRI0<=FG(3); R<=FG(2); G<=FG(1); B<=FG(0);
				else BRI0<=BG(3); R<=BG(2); G<=BG(1); B<=BG(0); end if;
			else  
				B<='0'; R<='0'; G<='0'; BRI0<='0';
			end if;
			
		else   ------ vidc false VIDEO 0---------------------------------------
			
			if (lines>=l1) and (lines<l2) and (pixel>=p1) and (pixel<p2) then
				pix<=pix+1;
				if pix mod 2=0 then	m78:=15-m8/2; addr1:= pix/2 + addr2; else m78:=7-m8/2; end if;  -- m78<= not m8
			end if;
			
			if pixel=799 then
				if lines=l1-1 then 
					addr3<=(ctbl)/2;  --p8<=0;
				else
					if m8=15 then addr3<=addr3+cxno/2; end if;
				end if;
				prc<=0; p6<=0;
			else
				if pixel>=p1 and pixel<p2 then
					if p6=7 then p6<=0; prc<=prc+1; else p6<=p6+1;  end if;
				end if;
			end if;
			
			if p6=0 then 
				if prc mod 2=0 then
					FG<=Q(15 downto 12);
					BG<=Q(11 downto 8);
				else 
					FG<=Q(7 downto 4);
					BG<=Q(3 downto 0);
				end if;
			end if;
		end if;
	end if; --falling_edge
end process;

end;


-----------------------------------------------------------------------------
-- Color Video Controller Mode 1
-- Theodoulos Liontakis (C) 2018

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity VideoRGB1 is
	port
	(
		sclk, vclk, EN: IN std_logic;
		R,G,B,BRI,R2,G2,B2,BRI2,VSYN,HSYN, VSINT, HSINT: OUT std_logic;
		addr : OUT natural range 0 to 32767;
		Q : IN std_logic_vector(15 downto 0);
		hline: OUT std_logic_vector(15 downto 0)
	);
end VideoRGB1;

Architecture Behavior of VideoRGB1 is

constant vbase: natural:= 0;
constant l1:natural:=74;
constant lno:natural:=200;
constant p1:natural :=142;
constant pno:natural:=320;
constant p2:natural:=p1+pno*2;
constant l2:natural:=l1+lno*2;

Signal lines: natural range 0 to 1023;
Signal pixel : natural range 0 to 1023;
Signal addr2: natural range 0 to 32767;
signal m8: natural range 0 to 31;
Signal vidc: boolean:=true;
Signal BBGGGRRR: std_logic_vector(7 downto 0);

begin
--addr<=addr1;
vidc<=not vidc when rising_edge(vclk);
VSYN<='0' when lines<2 else '1';	
VSINT<='0' when (lines=0) and (pixel<6) else '1';	
HSYN<='0' when pixel<96 else '1';
HSINT<='0' when pixel<6 and lines>=l1 and lines<=l2 else '1';
hline<=std_logic_vector(to_unsigned(lines,16));

process (sclk,EN)

variable pixm4: natural range 0 to 1023;
variable pix: natural range 0 to 1023;

begin
	if  rising_edge(sclk) and EN='1' then
		if  vidc then 
			if (lines>=l1 and lines<l2 and pixel>=p1 and pixel<p2) then
					R<=BBGGGRRR(2); R2<=BBGGGRRR(1); BRI<=BBGGGRRR(0);  G<=BBGGGRRR(5); 
					G2<=BBGGGRRR(4); BRI2<=BBGGGRRR(3);   B<=BBGGGRRR(7);  B2<=BBGGGRRR(6);
			else  -- vsync  0.01 us = 1 pixels
				B<='0'; R<='0'; G<='0'; BRI<='0';
				B2<='0'; R2<='0'; G2<='0'; BRI2<='0';
			end if;
			if pixel=799 then
				pixel<=0; pix:=0; pixm4:=0;
				if lines<524 then	lines<=lines+1; else lines<=0; end if;
				if lines<l1 or lines>l2  then 
					m8<=0; addr2<=vbase/2; 
				else
					if m8=1 then m8<=0; addr2<=addr2+pno/2; else m8<=1; end if;
				end if;
			else
				pixel<=pixel+1;
			end if;
			 
		else   ------ vidc false ---------------------------------------
			
			if (lines>=l1) and (lines<l2) and (pixel>=p1) and (pixel<p2) then
				if (pixel mod 2)=1 then 
					pix:=pix+1; 
				end if;
			end if;
			addr<= pix/2 + addr2;
			case pixm4 is
			when 0 => BBGGGRRR<=Q(15 downto 8);  --end if;  --Q(12)&Q(13)&Q(14)&Q(15);
			when 1 => BBGGGRRR<=Q(7 downto 0);   --end if; --Q(8)&Q(9)&Q(10)&Q(11);
			--when 2 => BBGGGRRR<=Q(15 downto 8);    --end if; -- Q(4)&Q(5)&Q(6)&Q(7);
			--when 3 => BBGGGRRR<=Q(7 downto 0);    --end if; --Q(0)&Q(1)&Q(2)&Q(3);
			when others=>
			end case;
			pixm4:=pix mod 2;
			-- sprites
		end if;
	end if; --falling
end process;


end;


-----------------------------------------------------------------------------
-- Multicolor Sprites for Lion Computer 
-- Theodoulos Liontakis (C) 2018

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity VideoSpo is
	generic 
	(
		DATA_LINE : natural := 1
	);
	port
	(
		sclk,vclk: IN std_logic;
		R,G,B,BRI,SPDET: OUT std_logic;
		reset, pbuffer, dbuffer : IN std_logic;
		spaddr: OUT natural range 0 to 2047;
		SPQ: IN std_logic_vector(15 downto 0)
	);
end VideoSpo;


Architecture Behavior of VideoSpo is

constant sp1: natural:= 0; 
constant sp2: natural:= 256/2;
constant sd1: natural:= 512/2;
constant sd2: natural:= 2304/2;
constant l1:natural:=36;
constant lno:natural:=240;
constant p1:natural :=133;
constant pno:natural:=320;
constant maxd:natural:=16;
constant spno:natural:=13;
constant p2:natural:=p1+pno*2;
constant l2:natural:=l1+lno*2;

type sprite_dim is array (0 to spno*4+3) of natural range 0 to 511;
type sprite_line_data is array (spno downto 0) of std_logic_vector(63 downto 0);
type dist is array (0 to spno) of natural range 0 to 2047;
type sprite_enable is array (0 to spno) of std_logic;

shared variable addr1: natural range 0 to 2047;
shared variable lines: natural range 0 to 1023;
shared variable det: std_logic:='0';
Signal vidc: boolean:=false;
Signal SX,SY: sprite_dim;
Signal SEN:sprite_enable;
Signal pixel : natural range 0 to 1023;
Signal sldata: sprite_line_data; 

begin
vidc<=not vidc when rising_edge(vclk);
spaddr<=addr1;
SPDET<=det;

process (sclk,reset)

variable BRGB: std_logic_vector(3 downto 0);
variable d1,d2:dist;
variable p16,datab: natural range 0 to 2047;
variable pixi, lin, pm4,pd4: natural range 0 to 1023;
variable blvec:natural range 0 to 15;
variable buf64:std_logic_vector(63 downto 0);

begin
	if  rising_edge(sclk) then
		if (reset='0') then
			pixel<=6; lines:=0; det:='0';
			if dbuffer='0' then datab:=sd1; else datab:=sd2; end if;
		elsif  vidc then 
			if (lines>=l1 and lines<l2 and pixel>=p1 and pixel<p2) then		
--				if blvec<14 then
--				   buf64:=SLData(blvec);
--					buf64:= std_logic_vector(shift_left(unsigned(buf64),d1(blvec)));
--					BRGB:=buf64(63 downto 60);
--					det:='1';
--				else 
--					det:='0'; BRGB:="0000";
--				end if;
				
				case blvec is
				when 0 => 	
					BRGB:=SLData(0)(3+d1(0) downto d1(0)); det:='1';
				when 1 => 
					BRGB:=SLData(1)(3+d1(1) downto d1(1)); det:='1';
				when 2 => 
					BRGB:=SLData(2)(3+d1(2) downto d1(2)); det:='1';
				when 3 => 
					BRGB:=SLData(3)(3+d1(3) downto d1(3)); det:='1';
				when 4 => 	
					BRGB:=SLData(4)(3+d1(4) downto d1(4)); det:='1';
				when 5 => 	
					BRGB:=SLData(5)(3+d1(5) downto d1(5)); det:='1';
				when 6 => 	
					BRGB:=SLData(6)(3+d1(6) downto d1(6)); det:='1';
				when 7 => 	
					BRGB:=SLData(7)(3+d1(7) downto d1(7)); det:='1';
				when 8 => 	
					BRGB:=SLData(8)(3+d1(8) downto d1(8)); det:='1';
				when 9 => 
					BRGB:=SLData(9)(3+d1(9) downto d1(9)); det:='1';
				when 10 => 
					BRGB:=SLData(10)(3+d1(10) downto d1(10)); det:='1';
				when 11 => 
					BRGB:=SLData(11)(3+d1(11) downto d1(11)); det:='1';
				when 12 => 
					BRGB:=SLData(12)(3+d1(12) downto d1(12)); det:='1';
				when 13 => 
					BRGB:=SLData(13)(3+d1(13) downto d1(13)); det:='1';
				when others =>
					det:='0'; BRGB:="0000";
				end case;
				BRI<=BRGB(3); R<=BRGB(2); G<=BRGB(1); B<=BRGB(0); 
			else  
				det:='0';
			end if;
			
			if pixel=799 then
				pixel<=0; p16:=0;
				if lines<524 then	lines:=lines+1; else lines:=0; end if;
			else
				pixel<=pixel+1; pixi:=(pixel-p1)/2;
			end if;	
			if (lines=DATA_LINE) and (pixel<spno*4+4)  then	
				if pm4 = 0 then SX(pd4)<=to_integer(unsigned(SPQ(8 downto 0))); end if; 
				if pm4 = 1 then SY(pd4)<=to_integer(unsigned(SPQ(8 downto 0))); end if;
				if pm4 = 3 then SEN(pd4)<=SPQ(0); end if;
			end if;
			if (lines>=l1 and lines<l2 and (pixel<(spno*4+4))) then
				case pm4 is
				when 0 =>
					SLData(pd4)(15 downto 0)<=SPQ(3 downto 0)&SPQ(7 downto 4)&SPQ(11 downto 8)&SPQ(15 downto 12);
				when 1 =>
					SLData(pd4)(31 downto 16)<=SPQ(3 downto 0)&SPQ(7 downto 4)&SPQ(11 downto 8)&SPQ(15 downto 12);
				when 2 =>
					SLData(pd4)(47 downto 32)<=SPQ(3 downto 0)&SPQ(7 downto 4)&SPQ(11 downto 8)&SPQ(15 downto 12);
				when others =>
					SLData(pd4)(63 downto 48)<=SPQ(3 downto 0)&SPQ(7 downto 4)&SPQ(11 downto 8)&SPQ(15 downto 12);
				end case;
			end if;
			blvec:=15; 
		else   ------ vidc false ---------------------------------------
			lin:=(lines-l1)/2;
			d1(0):=(pixi-SX(0))*4; d2(0):=lin-SY(0);
			d1(1):=(pixi-SX(1))*4; d2(1):=lin-SY(1);
			d1(2):=(pixi-SX(2))*4; d2(2):=lin-SY(2);
			d1(3):=(pixi-SX(3))*4; d2(3):=lin-SY(3);
			d1(4):=(pixi-SX(4))*4; d2(4):=lin-SY(4);
			d1(5):=(pixi-SX(5))*4; d2(5):=lin-SY(5);
			d1(6):=(pixi-SX(6))*4; d2(6):=lin-SY(6);
			d1(7):=(pixi-SX(7))*4; d2(7):=lin-SY(7);
			d1(8):=(pixi-SX(8))*4; d2(8):=lin-SY(8);
			d1(9):=(pixi-SX(9))*4; d2(9):=lin-SY(9);
			d1(10):=(pixi-SX(10))*4; d2(10):=lin-SY(10);
			d1(11):=(pixi-SX(11))*4; d2(11):=lin-SY(11);
			d1(12):=(pixi-SX(12))*4; d2(12):=lin-SY(12);
			d1(13):=(pixi-SX(13))*4; d2(13):=lin-SY(13);		
			pm4:= pixel mod 4; pd4:=pixel/4;
			if (pixel<(spno*4+4)) then 
				if (lines=DATA_LINE) then
					if pbuffer='0' then addr1:=(sp1+pixel); else addr1:=(sp2+pixel); end if;
				elsif (lines>=l1) and (lines<l2) then
					addr1:=(datab+p16+d2(pd4)*4+pm4);
					if pm4=3 then p16:=p16+64; end if;
				end if;
			end if;
			   if (d1(0)<maxd*4) and (d2(0)<maxd) and (SEN(0)='1') and (SLData(0)(3+d1(0) downto d1(0))/="1111") then blvec:=0;
			elsif (d1(1)<maxd*4) and (d2(1)<maxd) and (SEN(1)='1') and (SLData(1)(3+d1(1) downto d1(1))/="1111") then blvec:=1;
			elsif (d1(2)<maxd*4) and (d2(2)<maxd) and (SEN(2)='1') and (SLData(2)(3+d1(2) downto d1(2))/="1111") then blvec:=2;
			elsif (d1(3)<maxd*4) and (d2(3)<maxd) and (SEN(3)='1') and (SLData(3)(3+d1(3) downto d1(3))/="1111") then blvec:=3;
			elsif (d1(4)<maxd*4) and (d2(4)<maxd) and (SEN(4)='1') and (SLData(4)(3+d1(4) downto d1(4))/="1111") then blvec:=4;
			elsif (d1(5)<maxd*4) and (d2(5)<maxd) and (SEN(5)='1') and (SLData(5)(3+d1(5) downto d1(5))/="1111") then blvec:=5;
			elsif (d1(6)<maxd*4) and (d2(6)<maxd) and (SEN(6)='1') and (SLData(6)(3+d1(6) downto d1(6))/="1111") then blvec:=6;
			elsif (d1(7)<maxd*4) and (d2(7)<maxd) and (SEN(7)='1') and (SLData(7)(3+d1(7) downto d1(7))/="1111") then blvec:=7;
			elsif (d1(8)<maxd*4) and (d2(8)<maxd) and (SEN(8)='1') and (SLData(8)(3+d1(8) downto d1(8))/="1111") then blvec:=8;
			elsif (d1(9)<maxd*4) and (d2(9)<maxd) and (SEN(9)='1') and (SLData(9)(3+d1(9) downto d1(9))/="1111") then blvec:=9;
			elsif (d1(10)<maxd*4) and (d2(10)<maxd) and (SEN(10)='1') and (SLData(10)(3+d1(10) downto d1(10))/="1111") then blvec:=10;
			elsif (d1(11)<maxd*4) and (d2(11)<maxd) and (SEN(11)='1') and (SLData(11)(3+d1(11) downto d1(11))/="1111") then blvec:=11;
			elsif (d1(12)<maxd*4) and (d2(12)<maxd) and (SEN(12)='1') and (SLData(12)(3+d1(12) downto d1(12))/="1111") then blvec:=12;
			elsif (d1(13)<maxd*4) and (d2(13)<maxd) and (SEN(13)='1') and (SLData(13)(3+d1(13) downto d1(13))/="1111") then blvec:=13; end if;	
		end if;
	end if; --reset
end process;
end;

-----------------------------------------------------------------------------
-- Multicolor Sprites for Lion Computer 
-- Theodoulos Liontakis (C) 2021

Library ieee;
USE ieee.std_logic_1164.all;
--USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity VideoSp is
	generic 
	(
		DATA_LINE : natural := 1
	);
	port
	(
		sclk,vclk: IN std_logic;
		R,G,B,BRI,SPDET: OUT std_logic;
		reset, pbuffer, dbuffer : IN std_logic;
		spaddr: OUT natural range 0 to 2047;
		SPQ: IN std_logic_vector(15 downto 0)
	);
end VideoSp;

Architecture Behavior of VideoSp is

constant sp1: natural:= 0; 
constant sp2: natural:= 256/2;
constant sd1: natural:= 512/2;
constant sd2: natural:= 2304/2;
constant l1:natural:=36;
constant lno:natural:=240;
constant p1:natural :=133;
constant pno:natural:=320;
constant maxd:natural:=16;
constant spno:natural:=13;
constant p2:natural:=p1+pno*2;
constant l2:natural:=l1+lno*2;

type sprite_dim is array (0 to spno*4+3) of natural range 0 to 511;
type sprite_line_data is array (spno downto 0) of std_logic_vector(3 downto 0);
type sprite_transp_data is array (spno downto 0) of std_logic_vector(15 downto 0);
type dist is array (0 to spno) of natural range 0 to 2047;
type sprite_enable is array (0 to spno) of std_logic;

shared variable addr1: natural range 0 to 2047;
shared variable lines: natural range 0 to 1023;
shared variable det: std_logic:='0';
Signal vidc: boolean:=false;
Signal SX,SY: sprite_dim;
Signal SEN:sprite_enable;
Signal pixel : natural range 0 to 1023;
shared variable sldata: sprite_line_data; 

begin
vidc<=not vidc when rising_edge(vclk);
spaddr<=addr1;
SPDET<=det;

process (sclk,reset)

variable BRGB: std_logic_vector(3 downto 0);
variable d1,d2:dist;
variable p16,datab: natural range 0 to 2047;
variable pixi, lin, pm4,pd4: natural range 0 to 1023;
variable blvec:natural range 0 to 15;
variable transp: sprite_transp_data;

begin
	if  rising_edge(sclk) then
		if (reset='0') then
			pixel<=6; lines:=0; det:='0';
			if dbuffer='0' then datab:=sd1; else datab:=sd2; end if;
		elsif  vidc then 
			if (lines>=l1 and lines<l2 and pixel>=p1 and pixel<p2) then	
				case d1(blvec) mod 4 is
				when 0 => SLData(0):=SPQ(15 downto 12);
				when 1 => SLData(0):=SPQ(11 downto 8);
				when 2 => SLData(0):=SPQ(7 downto 4);
				when others => SLData(0):=SPQ(3 downto 0);
				end case;
				if blvec<14 and SLData(0)/="1111" then 
					BRGB:=SLData(0); det:='1';
				else
					det:='0'; BRGB:="0000";
				end if;
				BRI<=BRGB(3); R<=BRGB(2); G<=BRGB(1); B<=BRGB(0); 
			else  
				det:='0';
			end if;
			if pixel=799 then
				pixel<=0; p16:=0;
				if lines<524 then	lines:=lines+1; else lines:=0; end if;
			else
				pixel<=pixel+1; pixi:=(pixel-p1)/2;
			end if;	
			if (lines=DATA_LINE) and (pixel<spno*4+4)  then	
				if pm4 = 0 then SX(pd4)<=to_integer(unsigned(SPQ(8 downto 0))); end if; 
				if pm4 = 1 then SY(pd4)<=to_integer(unsigned(SPQ(8 downto 0))); end if;
				if pm4 = 3 then SEN(pd4)<=SPQ(0); end if;
			end if;
			if (lines>=l1 and lines<l2 and (pixel<(spno*4+4))) then
				case pm4 is
				when 0 =>
					if SPQ(15 downto 12)="1111" then transp(pd4)(0):='1'; else transp(pd4)(0):='0'; end if;
					if SPQ(11 downto 8)="1111" then transp(pd4)(1):='1'; else transp(pd4)(1):='0'; end if;
					if SPQ(7 downto 4)="1111" then transp(pd4)(2):='1'; else transp(pd4)(2):='0'; end if;
					if SPQ(3 downto 0)="1111" then transp(pd4)(3):='1'; else transp(pd4)(3):='0'; end if;
				when 1 =>
					if SPQ(15 downto 12)="1111" then transp(pd4)(4):='1'; else transp(pd4)(4):='0'; end if;
					if SPQ(11 downto 8)="1111" then transp(pd4)(5):='1'; else transp(pd4)(5):='0'; end if;
					if SPQ(7 downto 4)="1111" then transp(pd4)(6):='1'; else transp(pd4)(6):='0'; end if;
					if SPQ(3 downto 0)="1111" then transp(pd4)(7):='1'; else transp(pd4)(7):='0'; end if;
				when 2 =>
					if SPQ(15 downto 12)="1111" then transp(pd4)(8):='1'; else transp(pd4)(8):='0'; end if;
					if SPQ(11 downto 8)="1111" then transp(pd4)(9):='1'; else transp(pd4)(9):='0'; end if;
					if SPQ(7 downto 4)="1111" then transp(pd4)(10):='1'; else transp(pd4)(10):='0'; end if;
					if SPQ(3 downto 0)="1111" then transp(pd4)(11):='1'; else transp(pd4)(11):='0'; end if;
				when others =>
					if SPQ(15 downto 12)="1111" then transp(pd4)(12):='1'; else transp(pd4)(12):='0'; end if;
					if SPQ(11 downto 8)="1111" then transp(pd4)(13):='1'; else transp(pd4)(13):='0'; end if;
					if SPQ(7 downto 4)="1111" then transp(pd4)(14):='1'; else transp(pd4)(14):='0'; end if;
					if SPQ(3 downto 0)="1111" then transp(pd4)(15):='1'; else transp(pd4)(15):='0'; end if;
				end case;
			end if;
			blvec:=15; 
		else   ------ vidc false ---------------------------------------
			lin:=(lines-l1)/2;
			d1(0):=(pixi-SX(0)); d2(0):=lin-SY(0);
			d1(1):=(pixi-SX(1)); d2(1):=lin-SY(1);
			d1(2):=(pixi-SX(2)); d2(2):=lin-SY(2);
			d1(3):=(pixi-SX(3)); d2(3):=lin-SY(3);
			d1(4):=(pixi-SX(4)); d2(4):=lin-SY(4);
			d1(5):=(pixi-SX(5)); d2(5):=lin-SY(5);
			d1(6):=(pixi-SX(6)); d2(6):=lin-SY(6);
			d1(7):=(pixi-SX(7)); d2(7):=lin-SY(7);
			d1(8):=(pixi-SX(8)); d2(8):=lin-SY(8);
			d1(9):=(pixi-SX(9)); d2(9):=lin-SY(9);
			d1(10):=(pixi-SX(10)); d2(10):=lin-SY(10);
			d1(11):=(pixi-SX(11)); d2(11):=lin-SY(11);
			d1(12):=(pixi-SX(12)); d2(12):=lin-SY(12);
			d1(13):=(pixi-SX(13)); d2(13):=lin-SY(13);		
			pm4:= pixel mod 4; pd4:=pixel/4;
			if (pixel<(spno*4+4)) then 
				if (lines=DATA_LINE) then
					if pbuffer='0' then addr1:=(sp1+pixel); else addr1:=(sp2+pixel); end if;
				elsif (lines>=l1) and (lines<l2) then
					addr1:=(datab+p16+d2(pd4)*4+pm4);
					if pm4=3 then p16:=p16+64; end if;
				end if;
			end if;
			   if (d1(0)<maxd) and (d2(0)<maxd) and (SEN(0)='1') and transp(0)(d1(0))='0' then blvec:=0;
			elsif (d1(1)<maxd) and (d2(1)<maxd) and (SEN(1)='1') and transp(1)(d1(1))='0' then blvec:=1;
			elsif (d1(2)<maxd) and (d2(2)<maxd) and (SEN(2)='1') and transp(2)(d1(2))='0' then blvec:=2;
			elsif (d1(3)<maxd) and (d2(3)<maxd) and (SEN(3)='1') and transp(3)(d1(3))='0' then blvec:=3;
			elsif (d1(4)<maxd) and (d2(4)<maxd) and (SEN(4)='1') and transp(4)(d1(4))='0' then blvec:=4;
			elsif (d1(5)<maxd) and (d2(5)<maxd) and (SEN(5)='1') and transp(5)(d1(5))='0' then blvec:=5;
			elsif (d1(6)<maxd) and (d2(6)<maxd) and (SEN(6)='1') and transp(6)(d1(6))='0' then blvec:=6;
			elsif (d1(7)<maxd) and (d2(7)<maxd) and (SEN(7)='1') and transp(7)(d1(7))='0' then blvec:=7;
			elsif (d1(8)<maxd) and (d2(8)<maxd) and (SEN(8)='1') and transp(8)(d1(8))='0' then blvec:=8;
			elsif (d1(9)<maxd) and (d2(9)<maxd) and (SEN(9)='1') and transp(9)(d1(9))='0' then blvec:=9;
			elsif (d1(10)<maxd) and (d2(10)<maxd) and (SEN(10)='1') and transp(10)(d1(10))='0' then blvec:=10;
			elsif (d1(11)<maxd) and (d2(11)<maxd) and (SEN(11)='1') and transp(11)(d1(11))='0' then blvec:=11;
			elsif (d1(12)<maxd) and (d2(12)<maxd) and (SEN(12)='1') and transp(12)(d1(12))='0' then blvec:=12;
			elsif (d1(13)<maxd) and (d2(13)<maxd) and (SEN(13)='1') and transp(13)(d1(13))='0' then blvec:=13; end if;	
			if blvec<14 and (lines>=l1) and (lines<l2) then
				addr1:=datab+blvec*4*16+d2(blvec)*4+d1(blvec)/4;
			end if;
		end if;
	end if; --reset
end process;
end;


-----------------------------------------------------------------------------
Library ieee;
Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity SoundI is
	port
	(
		Audio: OUT std_logic;
		reset, clk, wr : IN std_logic;
		Q : IN std_logic_vector(15 downto 0);
		Vol : IN std_logic_vector(7 downto 0);
		harmonic : IN std_logic_vector(3 downto 0);
		count: OUT std_logic_vector(31 downto 0);
		play: OUT  std_logic
	);
end SoundI;


Architecture Behavior of SoundI is

--type wave is array (0 to 255) of std_logic_vector(7 downto 0);

Signal c3:natural range 0 to 255;
Signal c2,c4:std_logic_vector(12 downto 0);
Signal c1:std_logic_vector(9 downto 0);
Signal dur: natural range 0 to 512*1024-1;
signal i: natural range 0 to 511;
Signal Aud,Aud2, temp, temp2:std_logic;
begin

process (clk,reset,wr)	
variable f,f2:std_logic_vector(15 downto 0);
	begin
		if (reset='1') then
		   Aud<='0'; Aud2<='0'; c3<=0;  i<=0;  play<='0'; dur<=0; --count<=(others=>'0');
		elsif  Clk'EVENT AND Clk = '1' then
			if wr='0' then 
				f:=Q; 
				if (harmonic<9) then
					f2:="000"&(Q(12 downto 0)-std_logic_vector(shift_right(unsigned(Q(12 downto 0)),to_integer(unsigned(harmonic)))));
				elsif (harmonic<15) then
					f2:="000"&(std_logic_vector(shift_right(unsigned(Q(12 downto 0)),1))+
					           std_logic_vector(shift_right(unsigned(Q(12 downto 0)),to_integer(unsigned(harmonic-6)))));
				else 
					f2:="000"&(Q(12 downto 0)-std_logic_vector(shift_right(unsigned(Q(12 downto 0)),2))
            					-std_logic_vector(shift_right(unsigned(Q(12 downto 0)),4)));
				end if;
			   play<='1';
				CASE f(15 downto 13) is
					when "000" =>
						dur<=3125;  -- 0.031 sec
					when "001" =>
						dur<=6250;  -- 0.063 sec
					when "010" =>    
						dur<=12500;  -- 0.125
					when "011" =>  
						dur<=25000;  -- 0.250
					when "100" =>
						dur<=50000;  -- 0.5 sec
					when "101" =>
						dur<=100000;  -- 1 sec
					when "110" =>    
						dur<=200000;  -- 2
					when others =>  
						dur<=400000;  -- 4
					end case;
				c1<=(others => '0'); 
			else 
				c1<=c1+1;
				if c3=0 and dur/=0 then dur<=dur-1; end if;
			end if;
			if (Aud='1' or Aud2='1') and c1&"0"<Vol then
				Audio<='1';	
			else
				Audio<='0';
			end if;
			if c1="001111100" then  -- c1=124 200Khz c1=249 100Khz
				c1<="0000000000";
				c3<=c3+1; c2<=c2+1; c4<=c4+1; 
				if dur=0 then
					temp<='0';	temp2<='0'; c2<=(others => '0'); c3<=0; c4<=(others => '0'); play<='0'; 
				else 

				if c2=f(12 downto 0) then
				if c2/="000000000000" then temp<=not temp; end if;
					c2<=(others => '0');			
				end if;
				--if vol > to_integer(unsigned(c2(7 downto 0))) then Aud<=temp;  else Aud<='0'; end if;
				Aud<=temp;
				if c4=f2(12 downto 0)  then 
					if c4/="000000000000" and harmonic>0 then temp2<=not temp2;	end if;
					c4<=(others => '0');			
				end if;
				Aud2<=temp2;
				--if vol > to_integer(unsigned(c4(7 downto 0))) then Aud2<=temp2;  else Aud2<='0'; end if;
				
				end if;
				if i=399 then i<=0; count<=count+'1'; else i<=i+1; end if;
			else
			end if;
		end if;
	end process ;
end;



-------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
	USE ieee.std_logic_unsigned.all ;
	USE ieee.numeric_std.all ;

entity lfsr_II is
  port (
    cout   :out std_logic;		-- Output of the counter
    clk    :in  std_logic;    -- Input rlock
    reset  :in  std_logic     -- Input reset
	 --Vol    :in std_logic_vector(7 downto 0)
	 --bw     :in std_logic_vector(15 downto 0) --band width
  );
end entity;

architecture rtl of lfsr_II is
    signal count: std_logic_vector (19 downto 0);
    signal linear_feedback,temp: std_logic:='0';
begin
    linear_feedback <= not(count(19) xor count(2));
	 process (clk, reset) 
	 begin
		  if (reset = '1') then
				count <= (others=>'0'); --cnt:=0;
		  elsif (rising_edge(clk)) then
				count <= ( count(18 downto 0) & linear_feedback);
				temp<=count(19);
		  end if;
	 end process;
	 cout <=temp; -- count(19) when vol > to_integer(unsigned(count(7 downto 0)));
end architecture;

-----------------------------------------------------------------------------

-------------------------------------------------------
-- Design Name : lfsr
-- File Name   : lfsr.vhd
-- Function    : Linear feedback shift register
-- Coder       : Deepak Kumar Tala (Verilog)
-- Translator  : Alexander H Pham (VHDL)
-- adapted to 1bit stream, 20bit counter, band width by Theodoulos Liontakis
-------------------------------------------------------
library ieee;
   use ieee.std_logic_1164.all;
	USE ieee.std_logic_unsigned.all ;
	USE ieee.numeric_std.all ;

entity lfsr is
  port (
    cout   :out std_logic;		-- Output of the counter
    clk    :in  std_logic;    -- Input rlock
    reset  :in  std_logic;     -- Input reset
	 Vol    :in std_logic_vector(7 downto 0);
	 bw     :in std_logic_vector(15 downto 0) --band width
  );
end entity;

architecture rtl of lfsr is
    signal count           :std_logic_vector (19 downto 0);
    signal linear_feedback,temp :std_logic:='0';
begin
    linear_feedback <= not(count(19) xor count(2));

	 process (clk, reset) 
	 variable cnt: natural range 0 to 512*1024;
	 begin
		  if (reset = '1') then
				count <= (others=>'0'); cnt:=0;
		  elsif (rising_edge(clk)) then
				cnt:=cnt+1;
				if cnt=to_integer(unsigned(bw&"111")) then
					count <= ( count(18 downto 0) & linear_feedback);
					if vol > to_integer(unsigned(count(7 downto 0))) then temp<=count(19); else temp<='0'; end if;
					cnt:=0;
				end if;
		  end if;
	 end process;
	 cout <=temp; -- count(19) when vol > to_integer(unsigned(count(7 downto 0)));
end architecture;
