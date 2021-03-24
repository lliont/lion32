-- Lion Computer 
-- Theodoulos Liontakis (C) 2015 

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity LionSystem32 is
	port
	(
		D  : INOUT  Std_logic_vector(15 downto 0);
		ADo  : OUT  Std_logic_vector(19 downto 0); 
		RWo,ASo,DSo,ERH,ERL,ER_SEL,RWo2 : OUT Std_logic;
		RD,Reset,iClock,HOLD: IN Std_Logic;
		Int: IN Std_Logic;
		IOo,Holdao : OUT std_logic;
		Iv  : IN std_logic_vector(1 downto 0);
		IACK: OUT std_logic;
		IA : OUT std_logic_vector(1 downto 0);
		R,G,B,VSYN,HSYN,VSYN2,HSYN2,BRIR,BRIG,BRIB : OUT std_Logic;
		PB, PG, PR : OUT std_Logic;
		Tx,Tx2  : OUT std_logic ;
		Rx,Rx2 : IN std_logic ;
		AUDIOA,AUDIOB,AUDIOC,NOISEO: OUT std_logic;
		SCLK,MOSI,SPICS: OUT std_logic;
		MISO: IN std_logic;
		JOYST1,JOYST2: IN std_logic_vector(4 downto 0);
		KCLK,KDATA:INOUT std_logic;
		RTC_CE,RTC_CLK:OUT std_logic;
		RTC_DATA:INOUT std_logic;
		SCLK2,MOSI2,MOSI3,MOSI4,SPICS2,LDAC: OUT std_logic
	);
end LionSystem32;

Architecture Behavior of LionSystem32 is

Component LionCPU32 is
	port
	(
		Di32   : IN  Std_logic_vector(31 downto 0);
		DO32  : OUT  Std_logic_vector(31 downto 0);
		ADo   : OUT  Std_logic_vector(19 downto 0); 
		RW, AS, DS: OUT Std_logic;
		RD, Reset, clock, Int,HOLD: IN Std_Logic;
		IO,HOLDA, RDW : OUT std_logic;
		I  : IN std_logic_vector(1 downto 0);
		IACK: OUT std_logic;
		IA : OUT std_logic_vector(1 downto 0);
		BACS: OUT std_logic;
		WACS: OUT std_logic
	);
end Component;


Component LPLL32 is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		outclk_1 : out std_logic;         -- outclk1.clk
		outclk_2 : out std_logic;         -- outclk1.clk
		outclk_3 : out std_logic         -- outclk1.clk
	);
	
end Component;

Component lfsr_II is
  port (
    cout   :out std_logic;      -- Output
    clk    :in  std_logic;      -- Input rlock
    reset  :in  std_logic;       -- Input reset
	 Vol    :in std_logic_vector(7 downto 0)
	 --bw     :in std_logic_vector(15 downto 0) --band width
  );
end Component;

Component VideoRGB80 is
	port
	(
		sclk, vclk, EN : IN std_logic;
		R,G,B,BRI0,VSYN,HSYN,VSINT, HSINT : OUT std_logic;
		addr : OUT natural range 0 to 32767;
		Q : IN std_logic_vector(15 downto 0);
		hline: OUT std_logic_vector(15 downto 0)
	);
end Component;

Component VideoRGB1 is
	port
	(
		sclk,vclk, EN : IN std_logic;
		R,G,B,BRI,R2,G2,B2,BRI2,VSYN,HSYN,VSINT, HSINT : OUT std_logic;
		addr : OUT natural range 0 to 32767;
		Q : IN std_logic_vector(15 downto 0);
		hline: OUT std_logic_vector(15 downto 0)
	);
end Component;

Component dual_port_ram_dual_clock is

	generic 
	(
		DATA_WIDTH : natural := 16;
		ADDR_WIDTH : natural := 14
	);

	port 
	(
		clka,clkb: in std_logic;
		addr_a	: in natural range 0 to 2**ADDR_WIDTH - 1;
		addr_b	: in natural range 0 to 2**ADDR_WIDTH - 1;
		data_b	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		we_b	   : in std_logic := '1';
		q_a		: out std_logic_vector((DATA_WIDTH -1) downto 0);
		q_b		: out std_logic_vector((DATA_WIDTH -1) downto 0);
		be      : in  std_logic_vector (1 downto 0)
	);
end Component;


Component UART is
	port
	(
		Tx  : OUT std_logic ;
		Rx  : IN std_logic ;
		clk, reset, r, w : IN std_logic ;
		data_ready, ready : OUT std_logic;
		data_in : IN std_logic_vector (7 downto 0);
		data_out :OUT std_logic_vector (7 downto 0)
	);
end Component;

Component SoundI is
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
end Component;

COMPONENT single_port_ram is
	port (
		clk     : in  std_logic;
		addr    : in  integer range 0 to 65535 ;
		data    : in  std_logic_vector(15 downto 0);
		we      : in  std_logic;
		q       : out std_logic_vector(15 downto 0);
		De      : in  std_logic
		);
end COMPONENT;


COMPONENT byte_enabled_ram0 is
	port (
		clk     : in  std_logic;
		addr    : in  integer range 0 to 16383 ;
		data    : in  std_logic_vector(15 downto 0);
		we      : in  std_logic;
		q       : out std_logic_vector(15 downto 0);
		be      : in  std_logic_vector (1 downto 0)
		);
end COMPONENT;

COMPONENT byte_enabled_ram1 is
	port (
		clk     : in  std_logic;
		addr    : in  integer range 0 to 16383 ;
		data    : in  std_logic_vector(15 downto 0);
		we      : in  std_logic;
		q       : out std_logic_vector(15 downto 0);
		be      : in  std_logic_vector (1 downto 0)
		);
end COMPONENT;

COMPONENT SPI is
	port
	(
		SCLK, MOSI : OUT std_logic ;
		MISO  : IN std_logic ;
		clk, reset, w: IN std_logic ;
		ready : OUT std_logic;
		data_in  : IN std_logic_vector (7 downto 0);
		data_out :OUT std_logic_vector (7 downto 0)
	);
end COMPONENT;

COMPONENT VideoSp is
	generic 
	(
		DATA_LINE : natural := 1
	);
	port
	(
		sclk, vclk: IN std_logic;
		R,G,B,BRI,SPDET: OUT std_logic;
		reset, pbuffer, dbuffer : IN std_logic;
		spaddr: OUT natural range 0 to 2047;
		SPQ: IN std_logic_vector(15 downto 0)
	);
end COMPONENT;

COMPONENT PS2KEYB is
	port
	(
		Rx , kclk : IN std_logic ;
		clk, reset, r : IN std_logic ;
		data_ready,caps,shift : OUT std_logic;
		data_out :OUT std_logic_vector (7 downto 0)
	);
end COMPONENT;

COMPONENT XY_Display_MCP4822 is
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
end COMPONENT;


constant ZERO16 : std_logic_vector(15 downto 0):= (OTHERS => '0');
type Sprite_color is array (1 to 4) of std_logic;
--Signal SR,SB,SG,SBRI,SPDET:Sprite_color;
Signal pdelay: natural range 0 to 2047 :=0;
Signal R0,B0,G0,BRI0,R2,G2,B2,BRI2,R1,G1,B1,BRI1: std_logic:='0';
Signal SR3,SG3,SB3,SBRI3,SPDET3,SR1,SB1,SG1,SBRI1,SPDET1,SR4,SB4,SG4,SBRI4,SPDET4,SR2,SG2,SB2,SBRI2,SPDET2: std_logic:='0';
Signal clock0,clock1,clockxy,clockxy2,lfsr_clk,xyplay:std_logic;
Signal hsyn0,vsyn0,hsyn1,vsyn1,Vmod: std_logic:='0';
Signal vq,Do: std_logic_vector (15 downto 0);
Signal AD,AD_HI,AD2: std_logic_vector (19 downto 0);
Signal harm1,harm2,harm3 : std_logic_vector(3 downto 0):="0000";
Signal qro,aq,aq2,aq3,q16,hline,hline0,hline1,Qin1,Qin0,Qout0,Qout1: std_logic_vector(15 downto 0);
Signal Di32,Do32: std_logic_vector(31 downto 0);
Signal ncnt : std_logic_vector(13 downto 0);
Signal count,count2,count3 : std_logic_vector(31 downto 0);
Signal lfsr_bw : std_logic_vector(15 downto 0):="0010000000000000";
Signal WAud, WAud2,WAud3, PB0, PG0, PR0, WACS: std_logic:='1';
Signal HOLDA,IO,nen1,nen2,nen3,ne1,ne2,ne3, RDW,caps,shift: std_logic:='0';
Signal rst, rst2, AS, DS, RW, Int_in,vint,vint0,vint1,hint,hint0,hint1,xyd: std_logic:='1';
Signal w1,spw1, spw2, spw3, spw4, xyw,xyen: std_logic:='0';
Signal SPQ1,spvq1,SPQ2,spvq2,SPQ3,spvq3,SPQ4,spvq4,xyq1,xyq2: std_logic_vector(15 downto 0);
Signal Ii : std_logic_vector(1 downto 0);
Signal ad1,vad0,vad1 :  natural range 0 to 32767;
Signal spad1,spad3,spad5,spad7:  natural range 0 to 2047;
Signal xyadr :  natural range 0 to 4095;
Signal pperiod: natural range 0 to 65535:=3600;
Signal sr,sw,ser2,sw2,sdready,sready,kr,kready,sdready2,sready2, noise: std_Logic;
Signal sdi,sdo,sdi2,sdo2,kdo : std_logic_vector (7 downto 0);
Signal Vol1,Vol2,Vol3,Voln : std_logic_vector (7 downto 0):="11111111";
SIGNAL Spi_in,Spi_out: STD_LOGIC_VECTOR (7 downto 0);
Signal Spi_w, spi_rdy, play,play2,play3: std_logic;
Signal XYmode,PCM, stereo, BACS, HINT_EN,BRI,PLLrst:std_Logic:='0';
Signal BSEL,BSEL_LOW,BSEL_HI,BSEL0,BSEL1: std_logic_vector (1 downto 0);
Signal spb, sdb: std_logic_vector (7 downto 0):="00000000";
Signal aligned,VW,VR: boolean;
Signal SPal: std_logic_vector(15 downto 0):="0111011101110111"; 

shared variable Di1:std_logic_vector(15 downto 0); --,Di2
shared variable ramwait1,ramwait2:std_logic:='0';
shared variable Dbuf,Dbuf2: std_logic_vector (15 downto 0);
Signal wstate,rstate: natural range 0 to 3:=0;

begin
CPU: LionCPU32
	PORT MAP ( Di32,Do32,AD,RW,AS,DS,RD and not (ramwait1 or ramwait2),rst,clock0,Int_in,Hold,IO,Holda,RDW,Ii,Iack,IA,BACS,WACS ); 
IRAM0: byte_enabled_ram0
	PORT MAP ( clock1, to_integer(unsigned(AD_HI(15 downto 2))),Qin0,RW or IO or DS or AD(16) or AD(17) or AD(18) or AD(19),Qout0,BSEL0);
IRAM1:  byte_enabled_ram1
	PORT MAP ( clock1, to_integer(unsigned(AD(15 downto 2))),Qin1,RW or IO or DS or AD(16) or AD(17) or AD(18) or AD(19),Qout1,BSEL1);
VRAM: dual_port_ram_dual_clock
	GENERIC MAP (DATA_WIDTH  => 16,	ADDR_WIDTH => 15)
	PORT MAP ( clock0, clock1, ad1, to_integer(unsigned((not AD(15))&AD(14 downto 1))), Do, w1, vq, q16,BSEL);
SPRAM: dual_port_ram_dual_clock
	GENERIC MAP (DATA_WIDTH  => 16,	ADDR_WIDTH => 11)
	PORT MAP ( clock0,clock1, spad1, to_integer(unsigned(AD(11 downto 1))), Do, spw1, spvq1, SPQ1, BSEL  );
SPRAM2: dual_port_ram_dual_clock
	GENERIC MAP (DATA_WIDTH  => 16,	ADDR_WIDTH => 11)
	PORT MAP ( clock0,clock1, spad3, to_integer(unsigned(AD(11 downto 1))), Do,  spw2, spvq2, SPQ2, BSEL );
SPRAM3: dual_port_ram_dual_clock
	GENERIC MAP (DATA_WIDTH  => 16,	ADDR_WIDTH => 11)
	PORT MAP ( clock0,clock1, spad5, to_integer(unsigned(AD(11 downto 1))), Do, spw3, spvq3, SPQ3, BSEL );
SPRAM4: dual_port_ram_dual_clock
	GENERIC MAP (DATA_WIDTH  => 16,	ADDR_WIDTH => 11)
	PORT MAP ( clock0,clock1, spad7, to_integer(unsigned(AD(11 downto 1))), Do, spw4, spvq4, SPQ4, BSEL );
XYRAM: dual_port_ram_dual_clock
	GENERIC MAP (DATA_WIDTH  => 16,	ADDR_WIDTH => 12)
	PORT MAP ( clockxy2,clock1, xyadr, to_integer(unsigned(AD(12 downto 1))), Do, xyw, xyq1, xyq2, BSEL );
XYC:XY_Display_MCP4822
	PORT MAP (clockxy,rst,xyadr,xyq1,SPICS2,SCLK2,MOSI2,MOSI3,MOSI4,LDAC,xyplay,XYmode,PCM,stereo,pperiod);
VIDEO0: videoRGB80
	PORT MAP ( clock1,clock0,Vmod,R0,G0,B0,BRI0,VSYN0,HSYN0,vint0,hint0,vad0,vq, hline0);
VIDEO1: videoRGB1
	PORT MAP ( clock1,clock0,Vmod,R1,G1,B1,BRI1,R2,G2,B2,BRI2,VSYN1,HSYN1,vint1,hint1,vad1,vq, hline1);
SPRTG1: VideoSp
	GENERIC MAP (DATA_LINE  => 3)
	PORT MAP ( clock1, clock0,SR1,SG1,SB1,SBRI1,SPDET1,vint,spb(0),sdb(0),spad1,spvq1);
SPRTG2: VideoSp
	GENERIC MAP (DATA_LINE  => 2)
	PORT MAP ( clock1, clock0,SR2,SG2,SB2,SBRI2,SPDET2,vint,spb(1),sdb(1),spad3,spvq2);
SPRTG3: VideoSp
	GENERIC MAP (DATA_LINE  => 1)
	PORT MAP ( clock1, clock0,SR3,SG3,SB3,SBRI3,SPDET3,vint,spb(2),sdb(2),spad5,spvq3);
SPRTG4: VideoSp
	GENERIC MAP (DATA_LINE  => 4)
	PORT MAP ( clock1, clock0,SR4,SG4,SB4,SBRI4,SPDET4,vint,spb(3),sdb(3),spad7,spvq4);
Serial: UART
	PORT MAP ( Tx,Rx,clock0,rst,sr,sw,sdready,sready,sdi,sdo );
Serial2: UART
	PORT MAP ( Tx2,Rx2,clock0,rst,ser2,sw2,sdready2,sready2,sdi2,sdo2 );
SoundC1: SoundI
	PORT MAP (AUDIOA,rst,clock1,Waud,aq,Vol1,harm1,count,play);
SoundC2: SoundI
	PORT MAP (AUDIOB,rst,clock1,Waud2,aq2,Vol2,harm2,count2,play2);     
SoundC3: SoundI
	PORT MAP (AUDIOC,rst,clock1,Waud3,aq3,Vol3,harm3,count3,play3); 
MSPI: SPI 
	PORT MAP ( SCLK,MOSI,MISO,clock1,rst,spi_w,spi_rdy,spi_in,spi_out);
NOIZ:lfsr_II
	PORT MAP ( noise, lfsr_clk, rst, Voln);
CPLL:LPLL32
	PORT MAP (iClock,PLLrst,Clock0,Clock1,Clockxy,Clockxy2);
PS2:PS2KEYB
	PORT MAP (KDATA,KCLK,clock1,rst,kr,kready,caps,shift,kdo);

	
rst2<=not reset when rising_edge(clock0);
rst<=rst2 when rising_edge(clock0);

HOLDAo<=HOLDA;
ASo<=AS when HOLDA='0' else 'Z'; 
DSo<=DS when HOLDA='0'  else 'Z'; 
IOo<=IO when HOLDA='0' else 'Z'; 
RWo<=RW when HOLDA='0' else 'Z';
RWo2<='0' when RW='0' and HOLDA='0' and RDW='1' else '1'; --and (wstate/=0 or wacs='1' or bacs='1')

VW<= (DS='0' and AS='0' and RW='0');
VR<= (AS='0' and RW='1');

D<= Do when RW='0' and DS='0' AND HOLDA='0' else "ZZZZZZZZZZZZZZZZ";
ADo<= AD2 when HOLDA='0' and (rstate=3 or wstate=3 or rstate=2 or wstate=2) else
      AD when HOLDA='0' else "ZZZZZZZZZZZZZZZZZZZZ";

ERL<='1' when bacs='1' and AD(0)='0' and RW='0' else '0';  -- external ram
ERH<='1' when bacs='1' and AD(0)='1' and RW='0' else '0';  -- external ram
ER_SEL<= AS or not (((AD(16) or AD(17) or AD(18)) and not AD(19)) or ( AD(19) and not (AD(17) or AD(18) or AD(16))));  -- external ram

Di32<= ZERO16&Di1 when IO='1' and AD(1)='1' 
  else Di1&ZERO16 when IO='1' and AD(1)='0' 
  else Qout1&Qout0 when not aligned and (AD(16) OR AD(17) OR AD(18) or AD(19))='0'
  else Qout0&Qout1 when (AD(16) OR AD(17) OR AD(18) or AD(19))='0'
  else Dbuf2&Dbuf2 when (wacs='1' or bacs='1') 
  else Dbuf2&Dbuf;
  
Qin1<=Do32(15 downto 0)  when aligned else Do32(31 downto 16);
Qin0<=Do32(31 downto 16) when aligned else Do32(15 downto 0);
	
Do<= Do32(31 downto 16) when AD(1)='0' and IO='1' and RW='0' else 
      Do32(15 downto 0)  when AD(1)='1' and IO='1' and RW='0' else
	   Do32(31 downto 16) when AD(1)='0' and (wacs='1' or bacs='1' ) and RW='0' else
	   Do32(15 downto 0) when AD(1)='1' and (wacs='1' or bacs='1' ) and RW='0' else
		Do32(31 downto 16) when RW='0' and (wstate=1 or wstate=0) else Do32(15 downto 0);
		
--IACK<=IAC;
AD2<=AD+2;
AD_HI<=AD2 when (WACS='0' AND BACS='0' and IO='0') else AD;
aligned<= AD(1)='0' or IO='1' or WACS='1' or BACS='1'; --(AD_HI(2)=AD(2));

process (RW,clock1) --external ram 32 bit accesss as 2 X 16 bit
begin
if rising_edge(clock1) then
	if  IO='0' and (((AD(19)='0') and (AD(18 downto 16)/="000")) or (AD(19 downto 16)="1000")) and VR then
		if rstate=0 and ramwait1='0'  then
			rstate<=1; 
			ramwait1:='1';
		elsif rstate=1 and RDW='1' then
			if bacs='1' or wacs='1' then 
				rstate<=0; ramwait1:='0';
			else
				rstate<=2;
			end if;
			Dbuf2:=D;
		elsif rstate=2 and RDW='1' then
			rstate<=3;
		elsif rstate=3 and RDW='1' then
			ramwait1:='0';
			rstate<=0;
			Dbuf:=D;
		end if;
	else rstate<=0; end if;
end if;
end process;

process (RW,clock1) --external ram 32 bit accesss  as 2 X 16 bit
begin
if rising_edge(clock1) then
	if IO='0' and (((AD(19)='0') and AD(18 downto 16)/="000") or (AD(19 downto 16)="1000")) and VW then
		if wstate=0 and ramwait2='0'  then
			ramwait2:='1';
			wstate<=1; 
		elsif wstate=1 and RDW='1' then
			if bacs='1' or wacs='1' then 
				wstate<=0; ramwait2:='0';
			else
				wstate<=2;
			end if;
		elsif wstate=2 and RDW='1' then
			wstate<=3;
			ramwait2:='1';
		elsif wstate=3 and RDW='1' then
			wstate<=0;
			ramwait2:='0';
		end if; 
	else wstate<=0; end if ;
end if;
end process;

w1<='1'   when VW and IO='1' and (AD(19 downto 15)="00010" or AD(19 downto 15)="00001") else '0'; 
spw1<='1' when VW and IO='1' and  AD(19 downto 12)="00000100" else '0';
spw2<='1' when VW and IO='1' and  AD(19 downto 12)="00000101" else '0';
spw3<='1' when VW and IO='1' and  AD(19 downto 12)="00000110" else '0';
spw4<='1' when VW and IO='1' and  AD(19 downto 12)="00000111" else '0';
xyw<='1'  when VW and IO='1' and  AD(19 downto 13)="0001100"  else '0';
			
BSEL0 <= "11" when (WACS='0' and BACS='0') or
		             (WACS='1' and BACS='0' and AD(1)='0') else
		   "10" when (BACS='1' and AD(1 downto 0)="00") else
		   "01" when (BACS='1' and AD(1 downto 0)="01") else "00";
			
BSEL1 <= "11" when (WACS='0' and BACS='0') or
			          (WACS='1' and BACS='0' and AD(1)='1') else
		   "10" when (BACS='1' and AD(1 downto 0)="10") else
		   "01" when (BACS='1' and AD(1 downto 0)="11") else "00";

BSEL<= "01" when BACS='1' and AD(0)='1' else "10" when BACS='1' and AD(0)='0' else "11";

nen1<='1' when (ne1='1') and (play='1') and (aq(12 downto 0)/="0000000000000") else '0';
nen2<='1' when (ne2='1') and (play2='1') and (aq2(12 downto 0)/="0000000000000") else '0';
nen3<='1' when (ne3='1') and (play3='1') and (aq3(12 downto 0)/="0000000000000") else '0';

NOISEO<=NOISE and (nen1 or nen2 or nen3);
ncnt<=ncnt+1 when rising_edge(Clock0);
lfsr_clk<= AUDIOA when (nen1='1' and aq(12 downto 0)<=512) 
      else AUDIOB when (nen2='1' and aq2(12 downto 0)<=512) 
		else AUDIOC when(nen3='1' and aq3(12 downto 0)<=512) 
		else ncnt(13) when nen1='1'  or nen2='1'  or nen3='1'  else '0';

R<= SR1 when  SPDET1='1' else SR2 when  SPDET2='1' else SR3 when SPDET3='1' 
        else SR4 when SPDET4='1' else R1 when Vmod='1' else R0;
G<= SG1 when  SPDET1='1' else SG2 when  SPDET2='1' else SG3 when SPDET3='1' 
		  else SG4 when SPDET4='1' else G1 when Vmod='1' else G0;
B<= SB1 when  SPDET1='1' else SB2 when  SPDET2='1' else SB3 when SPDET3='1' 
        else SB4 when SPDET4='1' else B1 when Vmod='1' else B0;

BRIR<=(SBRI1 AND SPal(14)) when SPDET1='1' else (SBRI2 AND SPal(10)) when  SPDET2='1' else (SBRI3 AND SPal(6)) when SPDET3='1' 
		  else (SBRI4 AND SPal(2)) when SPDET4='1' else R2 when Vmod='1' else BRI0;
BRIG<=(SBRI1 AND SPal(13)) when SPDET1='1' else (SBRI2 AND SPal(9)) when  SPDET2='1' else (SBRI3 AND SPal(5)) when SPDET3='1' 
        else (SBRI4 AND SPal(1)) when SPDET4='1' else G2 when Vmod='1' else BRI0;
BRIB<=(SBRI1 AND SPal(12)) when  SPDET1='1' else (SBRI2 AND SPal(8)) when  SPDET2='1' else (SBRI3 AND SPal(4)) when SPDET3='1' 
        else (SBRI4 AND SPal(0)) when SPDET4='1' else B2 when Vmod='1' else BRI0;

PR<=SR1 when  SPDET1='1' else SR2 when  SPDET2='1' else SR3 when SPDET3='1' 
	     else SR4 when SPDET4='1' else BRI1 when Vmod='1' else R0;
PG<=SG1 when  SPDET1='1' else SG2 when  SPDET2='1' else SG3 when SPDET3='1' 
        else SG4 when SPDET4='1' else BRI2 when Vmod='1' else G0;
PB<=SB1 when  SPDET1='1' else SB2 when  SPDET2='1' else SB3 when SPDET3='1' 
        else SB4 when SPDET4='1' else '0'  when Vmod='1' else B0;


ad1<=vad1 when Vmod='1'  else vad0;
HSYN<=HSYN1 when Vmod='1' else HSYN0;
VSYN<=VSYN1 when Vmod='1' else VSYN0;
HSYN2<=HSYN1 when Vmod='1' else HSYN0;
VSYN2<=VSYN1 when Vmod='1' else VSYN0;
VINT<=Vint1 when Vmod='1' else Vint0;
hline<=hline1 when Vmod='1' else hline0;
hint<=hint1 when Vmod='1' and HINT_EN='1' else hint0 when Vmod='0' and HINT_EN='1' else '1';

RTC_DATA<='Z';
RTC_CLK<='0';
RTC_CE<='0';

-- Interrupts 
process (clock1,INT)
begin
if rising_edge(clock1) then
	if INT='0' then  II<=Iv; elsif HINT='0' then II<="10"; else II<="11"; end if;
	Int_in<= INT and VINT and HINT;
end if;
end process;

Vmod<='0' when rst='1' and rising_edge(clock1) else Do(0) when AD=24 and IO='1' and VW and rising_edge(clock1);

-- UART SKEYB SPI IO decoding
sdi<=Do(7 downto 0) when AD=0 and IO='1' and VW and rising_edge(clock1);
sdi2<=Do(7 downto 0) when AD=1 and IO='1' and VW and rising_edge(clock1);
sr<=Do(1) when AD=2 and IO='1' and VW and rising_edge(clock1);
sw<=Do(0) when AD=2 and IO='1' and VW and rising_edge(clock1);
kr<=Do(1) when AD=15 and IO='1' and VW and rising_edge(clock1); 
ser2<=Do(1) when AD=3 and IO='1' and VW and rising_edge(clock1);
sw2<=Do(0) when AD=3 and IO='1' and VW and rising_edge(clock1);
spi_w<=Do(0) when AD=19 and IO='1' and VW and rising_edge(clock1);
SPICS<=Do(1) when AD=19 and IO='1' and VW and rising_edge(clock1);
spi_in<=Do(7 downto 0) when AD=18 and IO='1' and VW and rising_edge(clock1);
spb(3 downto 0)<=Do(3 downto 0) when AD=20 and IO='1' and VW and rising_edge(clock1);
sdb(3 downto 0)<=Do(7 downto 4) when AD=20 and IO='1' and VW and rising_edge(clock1);

 --Sound, XY IO decoding 
aq<=Do(15 downto 0) when AD=8 and IO='1' and VW and rising_edge(clock1);     -- port 8
aq2<=Do(15 downto 0) when  AD=10 and IO='1' and VW and rising_edge(clock1);  -- port 10
aq3<=Do(15 downto 0) when  AD=12 and IO='1' and VW and rising_edge(clock1);  -- port 12
Vol1<=Do(7 downto 0) when AD=25 and IO='1' and VW and rising_edge(clock1);   -- port 25
Vol2<=Do(7 downto 0) when  AD=26 and IO='1' and VW and rising_edge(clock1);  -- port 26
Vol3<=Do(7 downto 0) when  AD=27 and IO='1' and VW and rising_edge(clock1);  -- port 27
Voln<=Do(7 downto 0) when  AD=28 and IO='1' and VW and rising_edge(clock1);  -- port 28
ne1<=Do(0) when  AD=11 and IO='1' and VW and rising_edge(clock1);    -- noise enable 11
ne2<=Do(1) when  AD=11 and IO='1' and VW and rising_edge(clock1);    -- noise enable 11
ne3<=Do(2) when  AD=11 and IO='1' and VW and rising_edge(clock1);    -- noise enable 11
Waud<='0' when AD=8  and IO='1' and VW and rising_edge(clock1) else '1' when rising_edge(clock1);
Waud2<='0' when AD=10 and IO='1' and VW and rising_edge(clock1) else '1' when rising_edge(clock1);
Waud3<='0' when AD=12 and IO='1' and VW and rising_edge(clock1) else '1' when rising_edge(clock1);
HINT_EN<=Do(0) when  AD=13 and IO='1' and VW and rising_edge(clock1);
XYmode<=Do(0) when  AD=30 and IO='1' and VW and rising_edge(clock1);
PCM   <=Do(1) when  AD=30 and IO='1' and VW and rising_edge(clock1); 
stereo<=Do(2) when  AD=30 and IO='1' and VW and rising_edge(clock1); 
harm1<=Do(3 downto 0) when AD=31 and IO='1' and VW and rising_edge(clock1);   -- port 31
harm2<=Do(3 downto 0) when  AD=32 and IO='1' and VW and rising_edge(clock1);  -- port 32
harm3<=Do(3 downto 0) when  AD=33 and IO='1' and VW and rising_edge(clock1);  -- port 33
pperiod<=to_integer(unsigned(Do)) when  AD=34 and IO='1' and VW and rising_edge(clock1);  
SPal<=Do when  AD=40 and IO='1' and VW and rising_edge(clock1);

-- Read decoder
process (clock0,VR,IO)
begin
	if rising_edge(clock0) and VR AND IO='1'  then
		--Di2:="0000000000000000";
		if   (AD(19 downto 15)="00010" 
		   or AD(19 downto 15)="00001") then Di1:=q16;   --video
		elsif AD(19 downto 12)="00000100" then Di1:=SPQ1;
	   elsif AD(19 downto 12)="00000101" then Di1:=SPQ2;
		elsif AD(19 downto 12)="00000110" then Di1:=SPQ3;
		elsif AD(19 downto 12)="00000111" then Di1:=SPQ4;
		elsif AD(19 downto 13)="0001100" then Di1:=xyq2;
		elsif AD=4 then Di1:="00000000"&sdo; --end if; -- serial1
		elsif AD=5 then Di1:="00000000"&sdo2; --end if; -- serial1
		elsif AD=14 then Di1:="000000"&caps&shift&kdo; --end if; --keyboard
		elsif AD=6 then Di1:="00000000000" & sdready2 & sready2 & kready & sdready & sready; --end if; -- serial status
		elsif AD=16 then Di1:="00000000"&spi_out; --end if; --spi 
		elsif AD=17 then Di1:="000000000000000" & spi_rdy; --end if; --spi 
		elsif AD=9 then Di1:="000000000000"& xyplay & play3 & play2 & play; --end if; -- audio status
		elsif AD=20 then Di1:=count(15 downto 0); --Di2:=count(15 downto 0); --end if;
		elsif AD=21 then Di1:=count(31 downto 16); --Di2:=count(31 downto 16);  --end if;
		elsif AD=22 then Di1:="000"&JOYST2&"000"& JOYST1; --end if;     -- joysticks
		elsif AD=23 then Di1:="00000000000000"&Vsyn&hsyn; --end if;  -- VSYNCH HSYNCH STATUS
		elsif AD=24 then Di1:="000000000000000"&Vmod; --end if;
		elsif AD=35 then Di1:=hline; --end if;
		end if;
	end if;
end process;
	
end Behavior;

-----------------------------------------------------------------------------------------
-- changed for Lion 

library ieee;
use ieee.std_logic_1164.all;

entity dual_port_ram_dual_clock is

	generic 
	(
		DATA_WIDTH : natural := 16;
		ADDR_WIDTH : natural := 12
	);

	port 
	(
		clka,clkb: in std_logic;
		addr_a	: in natural range 0 to 2**ADDR_WIDTH - 1;
		addr_b	: in natural range 0 to 2**ADDR_WIDTH - 1;
		data_b	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		we_b	: in std_logic := '1';
		q_a		: out std_logic_vector((DATA_WIDTH -1) downto 0);
		q_b		: out std_logic_vector((DATA_WIDTH -1) downto 0);
		be      : in  std_logic_vector (1 downto 0)
	);

end dual_port_ram_dual_clock;

architecture rtl of dual_port_ram_dual_clock is

subtype word_t is std_logic_vector(7 downto 0);
type memory_t is array(0 to 2**ADDR_WIDTH-1) of word_t;
    
signal ram0,ram1 : memory_t;
attribute ramstyle : string;
attribute ramstyle of ram0 : signal is "no_rw_check";
attribute ramstyle of ram1 : signal is "no_rw_check";
begin
	process(clkb, we_b)
	variable b:word_t;
	begin
		if(rising_edge(clkb)) then 
			if we_b='1' then	
				if (be = "11") then
					b:=data_b(15 downto 8);
				elsif  be = "10" then 
					b:=data_b(7 downto 0);
				end if;
				if be(1)='1' then ram0(addr_b) <= b; end if;
			else
				q_b(15 downto 8) <= ram0(addr_b);
			end if;
		end if;
	end process;
	
	process(clkb, we_b)
	variable a:word_t;
	begin
		if(rising_edge(clkb)) then 
			if we_b='1' then	
				a:= data_b(7 downto 0);
				if be(0)='1' then ram1(addr_b) <= a; end if;
			else
				q_b(7 downto 0) <=  ram1(addr_b);
			end if;
		end if;
	end process;

	process(clka)
	begin
		if(rising_edge(clka)) then 
			q_a<= ram0(addr_a)&ram1(addr_a);
		end if;
	end process;
end rtl;

--------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library work;

entity byte_enabled_ram0 is
  
	port (
		clk     : in  std_logic;
		addr    : in  integer range 0 to 16383 ;
		data    : in  std_logic_vector(15 downto 0);
		we      : in  std_logic;
		q       : out std_logic_vector(15 downto 0);
		be      : in  std_logic_vector (1 downto 0)
		);
end byte_enabled_ram0;

architecture rtl of byte_enabled_ram0 is
	--  build up 2D array to hold the memory
	type word_t is array (0 to 1) of std_logic_vector(7 downto 0);
	type ram_t is array (16383 downto 0) of word_t;
	-- declare the RAM
	signal ram : ram_t;
	attribute ram_init_file : string;
	attribute ram_init_file of ram : signal is ".\Lionasm\bin\Debug\lionrom320.mif";
	attribute ramstyle : string;
   attribute ramstyle of ram : signal is "no_rw_check";

begin  -- rtl
        
	process(clk)
	begin
		if(rising_edge(clk)) then 
			if (we = '0') and (addr>=4000) then
				if be = "11" then
					ram(addr)(0) <= data(15 downto 8);
					ram(addr)(1) <= data(7 downto 0);
				elsif  be = "10" then 
					ram(addr)(0) <= data(15 downto 8);
				elsif  be = "01" then 
					ram(addr)(1) <= data(7 downto 0);
				else
				end if;
			else
				q <= ram(addr)(0)&ram(addr)(1);
			end if;
		end if;
	end process;  
end rtl;
-----------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library work;

entity byte_enabled_ram1 is
  
	port (
		clk     : in  std_logic;
		addr    : in  integer range 0 to 16383 ;
		data    : in  std_logic_vector(15 downto 0);
		we      : in  std_logic;
		q       : out std_logic_vector(15 downto 0);
		be      : in  std_logic_vector (1 downto 0)
		);
end byte_enabled_ram1;

architecture rtl of byte_enabled_ram1 is
	--  build up 2D array to hold the memory
	type word_t is array (0 to 1) of std_logic_vector(7 downto 0);
	type ram_t is array (16383 downto 0) of word_t;
	-- declare the RAM
	signal ram : ram_t;
	attribute ram_init_file : string;
	attribute ram_init_file of ram : signal is ".\Lionasm\bin\Debug\lionrom321.mif";
	attribute ramstyle : string;
   attribute ramstyle of ram : signal is "no_rw_check";
	--signal q_local : word_t;

begin  -- rtl
        
	process(clk)
	begin
		if(rising_edge(clk)) then 
			if (we = '0') and (addr>=4000) then --
				if be = "11" then
					ram(addr)(0) <= data(15 downto 8);
					ram(addr)(1) <= data(7 downto 0);
				elsif  be = "10" then 
					ram(addr)(0) <= data(15 downto 8);
				elsif  be = "01" then 
					ram(addr)(1) <= data(7 downto 0);
				else
					
				end if;
			else
				q <= ram(addr)(0)&ram(addr)(1);
			end if;
		end if;
	end process;  
end rtl;



-------------------------------------------------------
Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all ;
USE ieee.numeric_std.all ;

entity PS2KEYB is
	port
	(
		Rx,Kclk : IN std_logic ;
		clk, reset, r : IN std_logic ;
		data_ready,caps,shift : OUT std_logic:='0';
		data_out :OUT std_logic_vector (7 downto 0)
	);
end PS2KEYB;


Architecture Behavior of PS2KEYB is

constant rblen:natural:=8;
type FIFO_r is array (0 to rblen-1) of std_logic_vector(9 downto 2);
Signal rFIFO: FIFO_r;
	attribute ramstyle : string;
	attribute ramstyle of rFIFO : signal is "logic";
Signal inb: std_logic_vector(9 downto 1);
Signal lastkey: std_logic_vector(7 downto 0):="00000000";
--Signal delay:natural range 0 to 65535:=0;
signal dr: boolean:=false;
signal rptr1, rptr2: natural range 0 to rblen := 0; 
signal rstate: natural range 0 to 15 :=0 ;
Signal k0,k1,k2,k3,k4: std_logic:='1';
begin
	--Rx<=RXin when clk'EVENT  and clk = '0';
	
	process (clk,kclk,reset)
	
   variable ra:boolean :=false ;

	begin
		if (reset='1') then 
			rptr1<=0; rptr2<=0; data_ready<='0'; rstate<=0;
			 dr<=false; ra:=false; lastkey<="00000000";
		elsif  clk'EVENT  and clk = '1' then
			if (k0='1') and ((k1 or k2 or k3 or k4)='0') then	
				if rstate=0 and Rx='0' then
					rstate<=1; 
				elsif rstate>0 and rstate<10 then
					inb(rstate)<=Rx;
					rstate<=rstate+1;
				elsif rstate=10 and Rx='1' then
					rstate<=0;
					if (inb(8 downto 1)="00010010" or inb(8 downto 1)="01011001") then 
						if lastkey="11110000" then	shift<='0'; else shift<='1'; 	end if; 
					elsif inb(8 downto 1)="01011000" then
						if lastkey="11110000" then Caps<= not Caps; end if;
					elsif (lastkey/="11110000") and (inb(8 downto 1)/="11110000") and (inb(8 downto 1)/="11100000") then
						if  (lastkey="11100000") then
							rFIFO(rptr2)<="1010"&inb(4 downto 1);
						else
							rFIFO(rptr2)<=inb(8 downto 1);
						end if;
						if rptr2+1<rblen then 
							if rptr2+1 /= rptr1 then
								rptr2<=rptr2+1;
							end if;
						else
							if rptr1/=0 then
								rptr2<=0; 
							end if;
						end if;
						data_ready<='1'; dr<=true;
					end if;
					lastkey<=inb(8 downto 1);
				else
					rstate<=0;
				end if;
			end if;
			
			k4<=kclk;
			k3<=k4;
			k2<=k3;
			k1<=k2;
			k0<=k1;
			
			if r='1' and ra=false then 
				if dr then
					data_out<=rFIFO(rptr1);
					if rptr1+1<rblen then 
						rptr1<=rptr1+1;
						if rptr1+1 = rptr2 then data_ready<='0'; dr<=false; end if;
					else
						rptr1<=0; 
						if rptr2=0 then data_ready<='0'; dr<=false; end if;
					end if;
				end if;
				ra:=true;
			else
				if r='0' then ra:=false; end if;
				if dr=true then data_out<=rFIFO(rptr1); end if;
			end if;
			
		end if;
	end process;
end behavior;

