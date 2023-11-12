-- SPI interface
-- Theodoulos Liontakis (C) 2016

--Library ieee;
--USE ieee.std_logic_1164.all;
--USE ieee.std_logic_unsigned.all ;
--USE ieee.numeric_std.all ;
--
--entity SPI is
--	port
--	(
--		SCLK, MOSI: OUT std_logic ;
--		MISO  : IN std_logic ;
--		clk, reset, w : IN std_logic ;
--		ready : OUT std_logic;
--		data_in : IN std_logic_vector (7 downto 0);
--		data_out :OUT std_logic_vector (7 downto 0);
--		divider: IN natural range 0 to 255:=10
--	);
--end SPI;
--
--Architecture Behavior of SPI is
--
----constant divider:natural :=10; --36; --  74  124=200Khz
--Signal inb,outb: std_logic_vector(7 downto 0);
--Signal rcounter :natural range 0 to 127;
--Signal state :natural range 0 to 7:=7;
--
--begin
--	process (clk,reset)
--	begin
--		if (reset='1') then 
--			rcounter<=0; ready<='0';
--			SCLK<='0'; MOSI<='0'; state<=7;
--		elsif  clk'EVENT  and clk = '1' then
--			rcounter<=rcounter+1; 
--			MOSI<=data_in(state);
--			if rcounter=divider or (w='1' and ready='0') then
--				rcounter<=0;
--				if state=7 and SCLK='0' and w='1' then
--					ready<='1'; 
--					SCLK<='1';
--				elsif state=7 and SCLK='1' then
--					state<=6;
--					data_out(state)<=MISO;
--					SCLK<='0';
--				elsif state=6 and SCLK='0' then
--					SCLK<='1';
--				elsif state=6 and SCLK='1' then
--					state<=5;
--					data_out(state)<=MISO;
--					SCLK<='0';
--				elsif state=5 and SCLK='0' then
--					SCLK<='1';
--				elsif state=5 and SCLK='1' then
--					state<=4;
--					data_out(state)<=MISO;
--					SCLK<='0';
--				elsif state=4 and SCLK='0' then
--					SCLK<='1';
--				elsif state=4 and SCLK='1' then
--					state<=3;
--					data_out(state)<=MISO;
--					SCLK<='0';
--				elsif state=3 and SCLK='0' then
--					SCLK<='1';
--				elsif state=3 and SCLK='1' then
--					state<=2;
--					data_out(state)<=MISO;
--					SCLK<='0';
--				elsif state=2 and SCLK='0' then
--					SCLK<='1';
--				elsif state=2 and SCLK='1' then
--					state<=1;
--					data_out(state)<=MISO;
--					SCLK<='0';
--				elsif state=1 and SCLK='0' then
--					SCLK<='1';
--				elsif state=1 and SCLK='1' then
--					state<=0;
--					data_out(state)<=MISO;
--					SCLK<='0';
--				elsif state=0 and SCLK='0' then
--					SCLK<='1';
--				elsif state=0 and SCLK='1' then
--					data_out(state)<=MISO;
--					SCLK<='0';
--					state<=7;
--					ready<='0';
--					--ww:='0';
--				else	
--					SCLK<='0';
--					ready<='0';
--				end if;
--			end if;
--		end if;
--	end process;
--end behavior;


Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity SPI is
	port
	(
		SCLK, MOSI: OUT std_logic ;
		MISO  : IN std_logic ;
		clk, reset, w : IN std_logic ;
		ready : OUT std_logic;
		data_in : IN std_logic_vector (7 downto 0);
		data_out :OUT std_logic_vector (7 downto 0);
		divider: IN natural range 0 to 255:=10
	);
end SPI;

Architecture Behavior of SPI is

--constant divider:natural :=10; --36; --  74  124=200Khz
Signal rcounter :natural range 0 to 127;
Signal state :natural range 0 to 7:=7;
shared variable ww:std_logic:='0';
begin
	
	process (clk,reset)
	begin
	
		if (reset='1') then 
			rcounter<=0; ready<='0';
			SCLK<='0'; state<=7; ww:='0';
		elsif  rising_edge(clk) then
			rcounter<=rcounter+1; 
			MOSI<=data_in(state);
			if rcounter>=divider or (ww='0' and w='1' and ready='0') then
				rcounter<=0;
				if state=7 and SCLK='0' and ww='0' and w='1' then
					ready<='1'; 
					SCLK<='1';
					ww:=w;
				elsif state=7 and SCLK='1' then
					state<=6;
					data_out(state)<=MISO;
					SCLK<='0';
				elsif state=6 and SCLK='0' then
					SCLK<='1';
				elsif state=6 and SCLK='1' then
					state<=5;
					data_out(state)<=MISO;
					SCLK<='0';
				elsif state=5 and SCLK='0' then
					SCLK<='1';
				elsif state=5 and SCLK='1' then
					state<=4;
					data_out(state)<=MISO;
					SCLK<='0';
				elsif state=4 and SCLK='0' then
					SCLK<='1';
				elsif state=4 and SCLK='1' then
					state<=3;
					data_out(state)<=MISO;
					SCLK<='0';
				elsif state=3 and SCLK='0' then
					SCLK<='1';
				elsif state=3 and SCLK='1' then
					state<=2;
					data_out(state)<=MISO;
					SCLK<='0';
				elsif state=2 and SCLK='0' then
					SCLK<='1';
				elsif state=2 and SCLK='1' then
					state<=1;
					data_out(state)<=MISO;
					SCLK<='0';
				elsif state=1 and SCLK='0' then
					SCLK<='1';
				elsif state=1 and SCLK='1' then
					state<=0;
					data_out(state)<=MISO;
					SCLK<='0';
				elsif state=0 and SCLK='0' then
					SCLK<='1';
				elsif state=0 and SCLK='1' then
					data_out(state)<=MISO;
					SCLK<='0';
					state<=7;
					ready<='0';
					ww:=w;
				else	
					SCLK<='0';
					ready<='0';
					ww:=w;
				end if;
			end if;
		end if;
	end process;
end behavior;



----------------------------------------------------------------------------------------

-- triple SPI interface for mcp4822 
-- Theodoulos Liontakis (C) 2016,2019

Library ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity RTC_SPI is   -- 3 wire spi
	port
	(
		SCLK: OUT std_logic ;
		DAT: INOUT std_logic;
		clk, reset : IN std_logic ;
		GO,w : IN std_logic:='0';
		ready : OUT std_logic:='0';
		data_in : IN std_logic_vector (7 downto 0);
		data_out : OUT std_logic_vector (7 downto 0)
	);
end RTC_SPI;
 
Architecture Behavior of RTC_SPI is

constant divider:natural :=1; 
Signal rcounter :natural range 0 to 3:=0;
Signal state :natural range 0 to 15:=15;

begin

process (clk,reset)
	begin
		if rising_edge(clk) then
			if  (reset='1') then
				rcounter<=0; ready<='0';
				SCLK<='0'; state<=7; DAT<='Z';
			else
				if rcounter=divider or (ready='0' and GO='1') then
					rcounter<=0;
					if state=7 and SCLK='0' and GO='1' then
						ready<='1'; SCLK<='1';
						if w='1' then DAT<=data_in(state); else DAT<='Z'; end if;
					elsif state=7 and SCLK='1' then
						state<=6; SCLK<='0';
						if w='0' then data_out(state)<=DAT; end if;
					elsif state=6 and SCLK='0' then
						if w='1' then DAT<=data_in(state); else DAT<='Z'; end if;
						SCLK<='1';
					elsif state=6 and SCLK='1' then
						state<=5; SCLK<='0';
						if w='0' then data_out(state)<=DAT; end if;
					elsif state=5 and SCLK='0' then
						if w='1' then DAT<=data_in(state); else DAT<='Z'; end if;
						SCLK<='1';
					elsif state=5 and SCLK='1' then
						state<=4; SCLK<='0';
						if w='0' then data_out(state)<=DAT; end if;
					elsif state=4 and SCLK='0' then
						if w='1' then DAT<=data_in(state); else DAT<='Z'; end if;
						SCLK<='1';
					elsif state=4 and SCLK='1' then
						state<=3; SCLK<='0';
						if w='0' then data_out(state)<=DAT; end if;
					elsif state=3 and SCLK='0' then
						if w='1' then DAT<=data_in(state); else DAT<='Z'; end if;
						SCLK<='1';
					elsif state=3 and SCLK='1' then
						state<=2; SCLK<='0';
						if w='0' then data_out(state)<=DAT; end if;
					elsif state=2 and SCLK='0' then
						if w='1' then DAT<=data_in(state); else DAT<='Z'; end if;
						SCLK<='1';
					elsif state=2 and SCLK='1' then
						state<=1; SCLK<='0';
						if w='0' then data_out(state)<=DAT; end if;
					elsif state=1 and SCLK='0' then
						if w='1' then DAT<=data_in(state); else DAT<='Z'; end if;
						SCLK<='1';
					elsif state=1 and SCLK='1' then
						state<=0; SCLK<='0'; 
						if w='0' then data_out(state)<=DAT; end if;
					elsif state=0 and SCLK='0' then
						if w='1' then DAT<=data_in(state); else DAT<='Z'; end if;
						SCLK<='1';
					elsif state=0 and SCLK='1' then
						state<=7; SCLK<='0'; ready<='0';
						if w='0' then data_out(state)<=DAT; end if;
					else	
						SCLK<='0';
						ready<='0';
						state<=7;
					end if;
				else 
					rcounter<=rcounter+1; 
				end if;
			end if;
		end if;
	end process;
end behavior;
