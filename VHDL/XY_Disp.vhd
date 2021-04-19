-----------------------------------------------------------------------------
-- XY Display controller for Lion Computer 
-- Theodoulos Liontakis (C) 2019  MCP4822

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all ;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity XY_Display_MCP4822 is
	port
	(
		sclk: IN std_logic;
		reset: IN std_logic;
		addr: OUT natural range 0 to 4095;
		Q: IN std_logic_vector(15 downto 0);
		CS,SCK,SDI,SDI2,SDI3: OUT std_logic;
		LDAC,isplaying: OUT std_logic:='0';
		MODE: IN std_logic:='0';
		PCM,stereo: IN std_logic:='0';
		pperiod: IN natural range 0 to 65535
	);
end XY_Display_MCP4822;


Architecture Behavior of XY_Display_MCP4822 is

Signal spi_rdy,spi_w: std_logic:='0';
Shared variable mcnt,cnt,maxd :  natural range 0 to 255;
Shared variable mcnt2:  natural range 0 to 65535;
Signal x,y: std_logic_vector(9 downto 0);
Signal z: std_logic_vector(7 downto 0);
Signal spi_in,spi_in2,spi_in3: std_logic_vector(15 downto 0);
Shared variable caddr: natural range 0 to 4095:=0;
Shared variable e,sx,sy:integer range -2048 to 2047;
Shared variable lx,ly,cx,cy,dx,dy,dx2,dy2:integer range -2048 to 2047;
Shared variable restart: natural range 0 to 3;
Shared variable onetime,swait,lpcm,lowbyte: std_logic:='0';
--Shared variable lz: std_logic_vector(7 downto 0);

Component SPI16_fast is
	port
	(
		SCLK, MOSI,MOSI2,MOSI3: OUT std_logic ;
		clk, reset: IN std_logic ;
		w : IN std_logic:='0'; 
		ready : OUT std_logic;
		data_in,data_in2,data_in3 : IN std_logic_vector (15 downto 0)
	);
end Component;
 

begin
FSPI: spi16_fast
	PORT MAP ( SCK,SDI,SDI2,SDI3,sclk,reset,spi_w,spi_rdy,spi_in,spi_in2,spi_in3);
	
addr<=caddr;

process (sclk,reset)

begin
	if  rising_edge(sclk)  then
		if (lpcm/=pcm) or (reset='1') or (pcm='1' and mode='0') then
			mcnt:=0; mcnt2:=0; lowbyte:='0'; spi_w<='0'; 
			caddr:=0; swait:='0'; onetime:='0'; cs<='1';
			x<="0000000000"; y<="0000000000"; Z<="00000000"; isplaying<='0'; 
			cnt:=0; restart:=1; cx:=0; cy:=0; LDAC<='0';  lpcm:=pcm;
		else
			if PCM='0' then
				case mcnt is
				when 0 =>
				when 1 =>
					lx:=cx; ly:=cy;  
					z<=Q(7 downto 0);
					y(1)<=Q(8); x(1)<=Q(12);
				when 2 =>
					if caddr<4095 then caddr:=caddr+1; else caddr:=0;  end if;
					swait:='0';	onetime:='0';
				when 3 =>
					y(9 downto 2)<=Q(7 downto 0); 
					x(9 downto 2)<=Q(15 downto 8);
				when 4 =>
					if caddr<4095 then caddr:=caddr+1; else caddr:=0;  end if;
					if mode='1' or z=0 then cs<='0'; mcnt:=8; cnt:=maxd; end if;
					cx:=to_integer(signed("0"&x)); cy:=to_integer(signed("0"&y)); 
					if z=0 or mode='1' then lx:=cx; ly:=cy; end if;
				when 5 =>
					if cx>lx then sx:=1; dx:=cx-lx; elsif lx>cx then sx:=-1; dx:=lx-cx; else sx:=0; dx:=0; end if;
					if cy>ly then sy:=1; dy:=cy-ly; elsif ly>cy then sy:=-1; dy:=ly-cy; else sy:=0; dy:=0; end if;
					dx2:=2*dx; dy2:=2*dy;
				when 6 =>
					if dx>=dy then maxd:=dx; e:=dy2-dx; else maxd:=dy; e:=dx2-dy; end if;
					if maxd=0 then mcnt:=8; cnt:=maxd; end if;
				when 7 =>  -- loop start
						if e>=0 then
							swait:='1';
							if dy>dx then lx:=lx+sx; e:=e-dy2;	else ly:=ly+sy; e:=e-dx2;	end if;
						else swait:='0'; end if;
				when 8 =>
						if dy>dx then ly:=ly+sy; e:=e+dx2; else lx:=lx+sx; e:=e+dy2; end if;
				when 9 => 
					cs<='0';
					If stereo='0' then
						spi_in<= "00110"&std_logic_vector(to_unsigned(ly,10))&"0";
						spi_in3<="00110"&std_logic_vector(to_unsigned(lx,10))&"0";
					else
						spi_in<= "0011"&std_logic_vector(to_unsigned(ly,10))&"00";
						spi_in3<="0011"&std_logic_vector(to_unsigned(lx,10))&"00";
					end if;
					spi_in2<="00110"&z&"000";
				when 10 =>
					spi_w<='1';
				when 11 =>
				when 12 =>
				when 13 =>
					spi_w<='0';
					swait:=spi_rdy;
				when 14 =>
					cnt:=cnt+1;
				when 15 =>
					cs<='1'; 
				when 16 =>
					if cnt>=maxd then restart:=1; else restart:=2; end if;
				when 17 =>
					if onetime='0' then restart:=2; onetime:='1'; else restart:=1; end if; 
				when others=>
					restart:=1; swait:='0';
				end case;
				if restart=1 then mcnt:=0; cnt:=0; restart:=0; 
				elsif restart=2 then mcnt:=7; restart:=0; elsif swait='0' then mcnt:=mcnt+1; end if;
			else --  PCM ------------------------------------------------------------------------------------------
			   if (caddr/=4095) and (mode='1') then isplaying<='1'; else isplaying<='0';   end if;
				case mcnt2 is
				when 0 =>
					swait:='0';  cs<='1';
					--if mode='0' then mcnt2:=8; end if;
					y(9 downto 0)<=Q(7 downto 0)&"00"; 
					x(9 downto 0)<=Q(15 downto 8)&"00";
					z<="00000000";
				when 1 =>
					if lowbyte='1' or stereo='1' then
						if caddr<4095 then caddr:=caddr+1;   end if; --else caddr:=0;
					end if;
				when 2 =>
					cs<='0'; 
					if stereo='0' then
						if lowbyte='0' then
							spi_in3<= "1011000000000000";
							spi_in<="1011000000000000";
							spi_in2<="1001"&x&"00";
						else
							spi_in3<= "1011000000000000";
							spi_in<="1011000000000000";
							spi_in2<="1001"&y&"00";
						end if;
					else 
						spi_in3<= "1011000000000000";
						spi_in<= "1001"&x&"00";
						spi_in2<="1001"&y&"00";
					end if;
				when 3 =>
					spi_w<='1';
				when 4 =>
				when 5 =>
				when 6 =>
					spi_w<='0';
					swait:=spi_rdy;
				when 7 =>
				when 8 =>
				when others=>
					swait:='0'; cs<='1'; 
				end case;
				if swait='0' or mode='0' then 
					if mcnt2<pperiod then mcnt2:=mcnt2+1; else mcnt2:=0; lowbyte:=not lowbyte; end if; 
				end if;
			end if; -- PCM
		end if; --reset
	end if;
end process;

end;

----------------------------------------------------------------------------------------

-- triple SPI interface for mcp4822 
-- Theodoulos Liontakis (C) 2016,2019

Library ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity SPI16_fast is
	port
	(
		SCLK, MOSI,MOSI2,MOSI3: OUT std_logic ;
		clk, reset : IN std_logic ;
		w : IN std_logic:='0';
		ready : OUT std_logic:='0';
		data_in,data_in2,data_in3 : IN std_logic_vector (15 downto 0)
	);
end SPI16_fast;
 
Architecture Behavior of SPI16_fast is

constant divider:natural :=1; 
Signal rcounter :natural range 0 to 3:=0;
Signal state :natural range 0 to 15:=15;

begin

MOSI<=data_in(state); 
MOSI2<=data_in2(state); 
MOSI3<=data_in3(state);

process (clk,reset,w)
	begin
		if rising_edge(clk) then
			if  (reset='1') then
				rcounter<=0; ready<='0';
				SCLK<='0'; state<=15; 
			else
				
				if rcounter=divider or (w='1' and ready='0') then
					rcounter<=0;
					if state=15 and SCLK='0' and w='1' then
						ready<='1'; SCLK<='1';
					elsif state=15 and SCLK='1' then
						state<=14; SCLK<='0';
					elsif state=14 and SCLK='0' then
						SCLK<='1';
					elsif state=14 and SCLK='1' then
						state<=13; SCLK<='0';
					elsif state=13 and SCLK='0' then
						SCLK<='1';
					elsif state=13 and SCLK='1' then
						state<=12; SCLK<='0';
					elsif state=12 and SCLK='0' then
						SCLK<='1';
					elsif state=12 and SCLK='1' then
						state<=11; SCLK<='0';
					elsif state=11 and SCLK='0' then
						SCLK<='1';
					elsif state=11 and SCLK='1' then
						state<=10; SCLK<='0';
					elsif state=10 and SCLK='0' then
						SCLK<='1';
					elsif state=10 and SCLK='1' then
						state<=9;	SCLK<='0';
					elsif state=9 and SCLK='0' then
						SCLK<='1';
					elsif state=9 and SCLK='1' then
						state<=8; SCLK<='0';
					elsif state=8 and SCLK='0' then
						SCLK<='1';
					elsif state=8 and SCLK='1' then
						state<=7; SCLK<='0';
					elsif state=7 and SCLK='0' then
						SCLK<='1';
					elsif state=7 and SCLK='1' then
						state<=6; SCLK<='0';
					elsif state=6 and SCLK='0' then
						SCLK<='1';
					elsif state=6 and SCLK='1' then
						state<=5; SCLK<='0';
					elsif state=5 and SCLK='0' then
						SCLK<='1';
					elsif state=5 and SCLK='1' then
						state<=4; SCLK<='0';
					elsif state=4 and SCLK='0' then
						SCLK<='1';
					elsif state=4 and SCLK='1' then
						state<=3; SCLK<='0';
					elsif state=3 and SCLK='0' then
						SCLK<='1';
					elsif state=3 and SCLK='1' then
						state<=2; SCLK<='0';
					elsif state=2 and SCLK='0' then
						SCLK<='1';
					elsif state=2 and SCLK='1' then
						state<=1; SCLK<='0';
					elsif state=1 and SCLK='0' then
						SCLK<='1';
					elsif state=1 and SCLK='1' then
						state<=0; SCLK<='0'; 
					elsif state=0 and SCLK='0' then
						SCLK<='1';
					elsif state=0 and SCLK='1' then
						state<=15; SCLK<='0'; ready<='0';
					else	
						SCLK<='0';
						ready<='0';
						state<=15;
					end if;
				else 
					rcounter<=rcounter+1; 
				end if;
			end if;
		end if;
	end process;
end behavior;


-----------------------------------------------------------------------------
