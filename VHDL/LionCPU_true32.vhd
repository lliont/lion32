-- 32bit Lion CPU
-- Theodoulos Liontakis (C) 2020 

Library ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all ; 
USE ieee.std_logic_unsigned."+" ;
USE ieee.std_logic_unsigned."-" ;
USE ieee.std_logic_unsigned."*" ; 

entity LionCPU32 is
	port
	(
		Di32  : IN  Std_logic_vector(31 downto 0);
		DO32  : OUT  Std_logic_vector(31 downto 0);
		ADo  : OUT  Std_logic_vector(19 downto 0); 
		RW,AS,DS : OUT Std_logic;
		RD, Reset, Clock, Int, HOLD: IN Std_Logic;
		IO,HOLDA, RDW: OUT std_logic;
		I  : IN std_logic_vector(1 downto 0);
		IACK : OUT std_logic;
		IA : OUT std_logic_vector(1 downto 0);
		BACS: OUT std_logic:='0';
		WACS: OUT std_logic:='1'
	);
end LionCPU32;

Architecture Behavior of LionCPU32 is
constant CA:natural:=0; 
constant OV:natural:=1;
constant ZR:natural:=2;
constant NG:natural:=3; 
constant JXAD:natural:=4;  
constant TRAP:natural:=5;
constant INT_DIS:natural:=6;  

constant ZERO8 : std_logic_vector(7 downto 0):= (OTHERS => '0');
constant ZERO16 : std_logic_vector(15 downto 0):= (OTHERS => '0');
constant ONE16: std_logic_vector(15 downto 0) := "0000000000000001";
constant TWO16: std_logic_vector(15 downto 0) := "0000000000000010";
constant InitialState:Std_logic_vector(2 downto 0):="000";
constant FetchState:Std_logic_vector(2 downto 0):="001";
constant Fetch2State:Std_logic_vector(2 downto 0):="010";
constant IndirectState:Std_logic_vector(2 downto 0):="011";
constant RelativeState:Std_logic_vector(2 downto 0):="100";
constant ExecutionState:Std_logic_vector(2 downto 0):="110";
constant StoreState:Std_logic_vector(2 downto 0):="111";

SIGNAL IDX: Std_logic_vector(31 downto 0):=ZERO16&ZERO16;
SIGNAL Di,X2,Ao,AoII: Std_logic_vector(31 downto 0);
SIGNAL PC: Std_logic_vector(31 downto 0):=ZERO16&"0000000001000000";
SIGNAL RPC:Std_logic_vector(31 downto 0):=ZERO16&ZERO16;
SIGNAL Z1: Std_logic_vector(31 downto 0):=ZERO16&ZERO16;
SIGNAL SR: Std_logic_vector(15 downto 0):="0000000001000000";
SIGNAL IST: Std_logic_vector(31 downto 0):=ZERO8&"000000000100000111111100";
SIGNAL ST: Std_logic_vector(31 downto 0):= ZERO8&"000000011111111111111100";
SIGNAL FF: Std_logic_vector(2 downto 0):=InitialState;
SIGNAL Dob: Std_logic_vector(15 downto 0);
SIGNAL TT: natural range 0 to 15;
SIGNAL carry, overflow, zero, neg, carry32, overflow32, zero32, neg32: Std_logic;
SIGNAL mem_trans: boolean;

COMPONENT ALU_LA4 IS
PORT (X, Y 	: IN STD_LOGIC_VECTOR(15 DOWNTO 0) ;
		Z 		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0) ;
		sub, half, cin: IN STD_LOGIC ;
		carry,overflow,zero,neg: OUT STD_LOGIC ) ;
END COMPONENT ;

COMPONENT ALU_LA4_32 IS
PORT (X, Y 	: IN STD_LOGIC_VECTOR(15 DOWNTO 0) ;
		Z 		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0) ;
		sub, cin: IN STD_LOGIC ;
		carry,overflow,zero,neg: OUT STD_LOGIC ) ;
END COMPONENT ;

COMPONENT regs IS
PORT (Ai : IN STD_logic_vector(15 downto 0);
		Ao, AoII : OUT STD_logic_vector(15 downto 0);
		clk,Wen,half: IN Std_logic;
		R,RR: IN std_logic_vector(2 downto 0) ) ;
END COMPONENT;

shared variable Do,X1,Y1,X,Y,Ai: Std_logic_vector(31 downto 0):=ZERO16&ZERO16;
shared variable IR: Std_logic_vector(15 downto 0):=ZERO16;
shared variable AD: Std_logic_vector(31 downto 0);
shared variable cin,Wen,DWen,sub,half,rhalf: Std_logic;
shared variable M : Std_logic_vector(63 downto 0);
shared variable R,RR: std_logic_vector(2 downto 0);
shared variable restart,restart2,restart3,rest4,rel,setreg:boolean:=false;
shared variable fetch,fetch1,fetch2,fetch3:boolean;
shared variable tmp,tmp2:Std_logic_vector(31 downto 0);
shared variable r1,r2: Std_logic_vector(2 downto 0);
shared variable bt: natural range 0 to 31;
shared variable op: natural range 0 to 127;
shared variable bwb, DACS, DACS2, IND, FTCH, WAC, BAC, SWAP :Std_logic; 

procedure set_reg(ri:Std_logic_vector(2 downto 0); v:std_logic_vector(31 downto 0); byte: std_Logic:='0'; f:std_logic:='1') is
begin
	R:=ri; Ai:=v; rhalf:=not byte; 
	if byte='1' then
		if f='1' then
			if v(7 downto 0) = ZERO8 then SR(ZR)<='1'; else SR(ZR)<='0'; end if;
			SR(NG)<=V(7); 
		end if;
	elsif WAC='1' then
		if f='1' then
			if v(15 downto 0) = ZERO16 then SR(ZR)<='1'; else SR(ZR)<='0'; end if;
			SR(NG)<=V(15); 
		end if;
	else
		if f='1' then
			if v = ZERO16&ZERO16 then SR(ZR)<='1'; else SR(ZR)<='0'; end if;
			SR(NG)<=V(31); 
		end if;
		DWen:='1';
	end if;
	Wen:='1';
end set_reg;


procedure set_flags is
begin
	SR(3 downto 0) <= neg & zero & overflow & carry ;
end set_flags;

procedure set_flags32 is
begin
	SR(3 downto 0) <= neg32 & (zero32 AND zero) & overflow32 & carry32 ;
end set_flags32;

procedure relative(offset: natural range 2 to 4) is
begin
	if fetch then RPC<=PC+X+offset; else RPC<=PC+X1+offset; end if;
end;

constant param1_dw:std_logic_vector(0 to 127):=
"00000111010010000001110000000101"&
"10011101110011111101010111111110"&
"11111110010100000000000100011100"&
"00000001111001001111101111100111";

constant param3_dw:std_logic_vector(0 to 127):=
"00000011111110000001110000000111"&
"10011101110011111101010111111110"&
"11101110001100001111100001010000"&
"00000001000101001011101111100111";

constant param2_swap:std_logic_vector(0 to 127):=
"01111000001001111110000000000000"&
"01000000000000000010100000000000"&
"00000000000011100000000000100011"&
"00101100000000000000010000011000";

constant param4_relative:std_logic_vector(0 to 127):=
"00000000000000000000000000000000"&
"00000000010100000000000000000000"&
"00000000000000000000000000000000"&
"00000000000000001100001111111111";

constant param5_dfetch:std_logic_vector(0 to 127):=
"00000000000000000000000000000000"&
"00000000010100000000000000000000"&
"00000000000000000000000000000000"&
"11111101000000000010000000000000";

begin
	ALU0: ALU_LA4
	PORT MAP ( X1(15 downto 0),Y1(15 downto 0),Z1(15 downto 0), sub, half, cin, carry, overflow, zero, neg ) ;
	ALU1: ALU_LA4_32
	PORT MAP ( X1(31 downto 16),Y1(31 downto 16),Z1(31 downto 16), sub, carry, carry32, overflow32, zero32, neg32 ) ;
	REG0:REGs
	PORT MAP ( Ai(15 downto 0),Ao(15 downto 0),AoII(15 downto 0),clock,Wen,rhalf,R,RR );	
	REG1:REGs
	PORT MAP ( Ai(31 downto 16),Ao(31 downto 16),AoII(31 downto 16),clock,DWen,'1',R,RR );	

Dob<=Do(7 downto 0)&Do(15 downto 8) when BAC='1' and AD(0)='0' and IO='0' else Do(15 downto 0);
DO32<=Do when WAC='0' and BAC='0' and IO='0' else Dob&ZERO16 when AD(1)='0' else ZERO16&Dob; 
Di<=Di32 when WAC='0' and BAC='0' and IO='0' else ZERO16&Di32(31 downto 16) when AD(1)='0' else ZERO16&Di32(15 downto 0);

WACS<=WAC;
BACS<=BAC;
ADo<=AD(19 downto 0);

Process (Clock,RD,HOLD,INT,RESET)

procedure init_next_ins is 
begin
	 HOLDA<='0';	AD:=PC; half:='0'; 
	AS<='0'; sub:='0'; cin:='0';  setreg:=true;   WAC:='1'; BAC:='0';
	fetch:=false; fetch1:=false; fetch2:=false; mem_trans<=false;
	DACS:='0'; DACS2:='0';  restart2:=false; rest4:=false;
end init_next_ins;

begin
IF rising_edge(clock) THEN
	IF Reset = '1' THEN
		PC<=ZERO16&"0000000001000000"; SR<="0000000001000000";  HOLDA<='0'; FF<=InitialState; TT<=0;
		AS<='1';  DS<='1'; RW<='1';  IO<='0'; restart3:=false; DACS:='0'; DACS2:='0';
		restart2:=false; IA<="00"; IACK<='0'; BAC:='0'; WAC:='1'; IST<=ZERO8&"000000000100000111111100";
		Wen:='0'; DWen:='0'; ST<=ZERO8&"000000011111111111111100"; RDW<='0';
	ELSIF HOLD='0' AND RDW='0' AND (restart3=true)  then
		HOLDA<='1'; RW<='1'; 
	ELSIF RD='0' then
		RDW<='1';-- do nothing but wait
	ELSIF (INT='0') and (restart2=true or restart3=true)  and (SR(INT_DIS)='0') and (IACK='0') THEN   -- Interrupts
		FF<=ExecutionState; IA<=I; IACK<='1'; IR(15 downto 0):="100000100000"&I&"00";
		HOLDA<='0'; restart2:=false; Wen:='0';  DWen:='0'; setreg:=true;  DACS:='1'; DACS2:='1';
		if restart3=true then TT<=0; restart3:=false; end if; RDW<='0';  
	ELSIF SR(TRAP)='1' and IR(15 downto 9)/="1000010" and (restart2=true or restart3=true) then  -- SR(5) = trace flag reti
		IR(15 downto 0):="1000001000111100"; DACS:='1'; DACS2:='1'; --INT 15 
		HOLDA<='0'; restart2:=false; FF<=ExecutionState; Wen:='0'; DWen:='0';
		if restart3=true then TT<=0; restart3:=false; end if; RDW<='0';
	ELSE
		RDW<='0'; restart:=false;   
		case  FF is 
		when InitialState =>      -- Fetch and decode Instruction 
			case TT is
			when 0 =>
				init_next_ins; Wen:='0';  DWen:='0'; DS<='1'; -- most of the times skipped
			when others => --decode
				restart3:=false; restart:=true; rest4:=false; rhalf:='0';   
				Wen:='0'; DWen:='0'; DS<='1'; AS<='1';
				op:=to_integer(unsigned(Di(15 downto 9)));
				DACS:=param1_dw(op);	DACS2:=param3_dw(op); SWAP:=param2_swap(op);
				rel:=(param4_relative(op)='1'); fetch3:=(param5_dfetch(op)='1');
				IR:=Di(15 downto 0); RR:=Di(4 downto 2); R:=Di(8 downto 6);
				bt:=to_integer(unsigned(Di(5 downto 2))); bwb:=Di(5);  	
				IND:=Di(1); FTCH:=Di(0); PC<=PC+2;
				r2:=Di(4 downto 2); r1:=Di(8 downto 6);	
				WAC:= NOT (DACS or (IND and FTCH) or param5_dfetch(op)); 
				if FTCH='1' then 
					FF<=FetchState; AD:=PC+2; AS<='0';  
				elsif IND='1' then
					if rel then FF<=RelativeState; else	FF<=IndirectState; end if;
				else 
					FF<=ExecutionState; 
				end if;
			end case;
		when FetchState =>              -- Fetch next word into X
			X1:=Ao;	Y1:=AoII;
			fetch1:=true; fetch:=true; 
			if WAC='1' then PC<=PC+2; X(15 downto 0):=Di(15 downto 0); X(31 downto 16):=(others => Di(15));  
			else PC<=PC+4; X:=Di;  end if; 
			AS<='1'; 
			if fetch3 then 
				FF<=Fetch2State;
			elsif IND='1' then	
				if rel then 
					if WAC='1' then relative(2); else relative(4); end if;
				end if;
				FF<=IndirectState; 
			else	
				if rel then 
					if WAC='1' then relative(2); else relative(4); end if;
				end if;
				FF<=ExecutionState; 
			end if;
			restart:=true;
		when Fetch2State =>             -- fetch one more into Y
			case TT is
			when 0 =>
				WAC:=not DACS; AD:=PC;  AS<='0'; 
			when others =>
				Y:=Di; AS<='1'; 
				if WAC='1' then PC<=PC+2; else PC<=PC+4; end if; 
				if IND='1' then
					if rel then 
						if WAC='1' then relative(2); else relative(4); end if;
					end if;
					FF<=IndirectState; 
				else	
					if rel then 
						if WAC='1' then relative(2); else relative(4); end if;
					end if;
					FF<=ExecutionState;
				end if;
				restart:=true;
			end case;
		when IndirectState =>              -- indirect
			case TT is
			when 0 =>
				X1:=Ao;	Y1:=AoII;
				WAC:=not dacs;
				fetch2:=true; fetch:=true; AS<='0';   
				if FTCH='1' then	AD:=X; X2<=X; else AD:=Y1; X2<=y1; end if;
			when others =>
				if X2(0)='0' and bwb='1' and SWAP='1' then
					X(7 downto 0):=Di(15 downto 8);
					X(15 downto 8):=Di(7 downto 0);
				else
					X:=Di; 
				end if;
				AS<='1';	FF<=ExecutionState;
				restart:=true;
			end case;
		when RelativeState =>         -- relative
			X1:=Ao;	Y1:=AoII;
			RPC<=PC+X1;
			if IND='1' then FF<=IndirectState; else FF<=ExecutionState; end if;
			restart:=true; 
		when ExecutionState =>        --- F="110" Operation execution cycles   
			if TT=0 and not mem_trans then X1:=Ao;	Y1:=AoII;  end if;
			if TT=0 then WAC:=NOT DACS2; end if;
			case IR(15 downto 9) is
			when "0000000" =>              -- NOP
					restart3:=true;
			when "0000001" =>              -- MOV MOV.B Reg,(Reg,NUM,[reg],[n]) 
				if fetch then	tmp:=X; else tmp:=Y1; end if;
				set_reg(r1,tmp,bwb,'0');
				restart3:=true;
			when "1110101" =>              -- CMOV CMOV.B Reg,(Reg,NUM,[reg],[n]) 
				if bwb='0' then
					if fetch then	tmp:=ZERO16&X(15 downto 0); else tmp:=ZERO16&Y1(15 downto 0); end if;
				else
					if fetch then tmp:=ZERO16&ZERO8&X(7 downto 0); else tmp:=ZERO16&ZERO8&Y1(7 downto 0); end if;
				end if;
				WAC:='0';
				set_reg(r1,tmp,'0','0');
				restart3:=true;
			when "0101000" =>              -- MOV.D Reg,...
				if fetch then	tmp:=X; else tmp:=Y1; end if;
				set_reg(r1,tmp,'0','0'); 
				restart3:=true;
			when "0000010" =>              -- MOV MOV.B <Reg>,(Reg,NUM,[reg],[n])
				AD:=X1;  
				if fetch then Y1:=X;	end if;
				BAC:=bwb;
				FF<=StoreState;
				restart:=true;
			when "0101100" =>              -- MOV.D <Reg>,(Reg,NUM,[reg],[n])
				if bwb='0' then
					AD:=X1;   
					if fetch then Y1:=X;	end if;
					FF<=StoreState;
					restart:=true;
				else 
					AD:=X; FF<=StoreState;    
					restart:=true; 
				end if;
			when "0100100" =>              -- MOV.D (n),Reg 
					AD:=X; FF<=StoreState; 
					BAC:='0';
					restart:=true; 
			when "0000110" =>              --ADD.D SUB.D Reg,(Reg,NUM,[reg],[n])
				case TT is
				when 0 =>
					if fetch=true then Y1:=X; end if; 
					sub:=bwb;
				when others =>
					restart3:=true;
					if setreg then set_reg(r1,Z1,'0','0'); end if;
					set_flags32;
					sub:='0'; cin:='0';
				end case;
			when "1000100" =>              --CMP.D Reg,(Reg,NUM,[reg],[n])
				if fetch then Y1:=X;	end if;
				sub:='1'; bwb:='1'; cin:='0';
				setreg:=false;
				IR(15 downto 9):="0000110"; -- continue as in ADD.D
			when "0000011" =>              --ADD & ADD.B Reg,(Reg,NUM,[reg],[n])
				case TT is
				when 0 =>
					if fetch=true then Y1:=X; end if;
					half:=bwb;
				when others =>
					restart3:=true;
					if setreg then set_reg(r1,Z1,bwb,'0'); end if;
					set_flags;
					sub:='0'; cin:='0';
				end case;
			when "0000100" =>              --SUB & SUB.B Reg,(Reg,NUM,[reg],[n])
				if fetch=true then Y1:=X; end if;
				sub:='1'; half:=bwb;
				IR(15 downto 9):="0000011"; -- continue as in ADD
			when "0000101" =>              --ADC ADC.D Reg,(Reg,NUM,[reg],[n])
				if fetch then	Y1:=X;	end if;
				WAC:= not bwb ; cin:=SR(CA); DACS2:=bwb;
				if WAC='1' then
					IR(15 downto 9):="0000011"; -- continue as in ADD
				else
					IR(15 downto 9):="0000110";
				end if;
				bwb:='0';
			when "0000111" =>              -- OUT (n,Reg),Reg	
				case TT is
				when 0 =>
					Do:=Y1; 
					if fetch then AD:=X; else AD:=X1; end if;
					RW<='0';	IO<='1'; AS<='0'; DS<='0';   	
				when others =>
					restart3:=true;
					end case;
			when "0001000" =>              --SWAP SWAP.D R
				if bwb='0' then
					tmp:=X1(31 downto 16) & X1(7 downto 0) & X1(15 downto 8);
				else
					tmp:=X1(15 downto 0)&X1(31 downto 16);
				end if;
				set_reg(r1,tmp,'0','0'); 
				restart3:=true;
			when "0001001" =>              -- MOV ST,Rn  SETSP SETISP
					if bwb='0' then
						ST<=Y1;
					else
						IST<=Y1;
					end if;
					restart3:=true;
			when "0111010" =>   -- ALNG
				case TT is
				when 0 =>
					if X1=ZERO16&ZERO16 then
						Y1:=ZERO16&ZERO8&"00100000";
						set_reg(r2,Y1,'0','0');
						restart3:=true;
					else
						Y1:=ZERO16&ZERO16; 
					end if;
				when 1 =>
					if X1(31)='1' then
						set_reg(r1,X1,'0','0'); 
						rest4:=false;
					else 
						Y1:=Y1+1;
						X1:=std_logic_vector(shift_left(unsigned (X1),1));
						rest4:=true;
					end if;
				when 2 =>
					Wen:='0'; Dwen:='0';
				when others =>
					set_reg(r2,Y1,'0','0');
					restart3:=true;
				end case;
			when "0001010" =>            --MULU Reg,Reg	MULU.B Reg,(Reg,NUM,[reg],[n])
				case TT is
				when 0 =>
					if fetch then
						if bwb='0' then
							M(31 downto 0):=std_logic_vector(unsigned(X1(15 downto 0)) * unsigned(X(15 downto 0)));
						else
							M(31 downto 0):=std_logic_vector(unsigned("00000000"&X1(7 downto 0)) * unsigned("00000000"&X(7 downto 0)));
						end if;
					else 
						if bwb='0' then
							M(31 downto 0):=std_logic_vector(unsigned(X1(15 downto 0)) * unsigned(Y1(15 downto 0)));
						else
							M(31 downto 0):=std_logic_vector(unsigned("00000000"&X1(7 downto 0)) * unsigned("00000000"&Y1(7 downto 0)));
						end if;
					end if;				
				when others =>
					SR(CA)<='0'; SR(NG) <= '0'; SR(OV) <='0';
					if bwb='1' then 
						 --neg & zero & overflow & carry
						if M(15 downto 0) = ZERO16 then SR(ZR) <= '1'; else SR(ZR) <='0'; end if;
						set_reg(r1,ZERO16&M(15 downto 0),'0','0'); 
					else
						if (M(15 downto 0) OR M(31 downto 16)) = ZERO16 then SR(ZR) <= '1'; else SR(ZR) <='0'; end if;
						set_reg(r1,M(31 downto 0),'0','0'); 
					end if;
					restart3:=true; 
				end case;
			when "0001100" =>            --MULU.D Reg,Reg	MUL.D Reg,(Reg,NUM,[reg],[n])
				case TT is
				when 0 =>
					if fetch then tmp:=X; else tmp:=Y1; end if;
					if bwb='0' then
						M:=std_logic_vector(unsigned(X1) * unsigned(tmp)); SR(OV)<='0';
					else
						M:=std_logic_vector(signed(X1) * signed(tmp)); SR(OV)<='0';
					end if;	
			   when 1 =>		
					SR(CA)<='0'; 
					if bwb='1' then
						SR(NG) <= M(63);
					else
						SR(NG) <= '0';
					end if;
					set_reg(r1,M(31 downto 0),'0','0'); 
				when 2 =>
					Wen:='0';	DWen:='0';
					if fetch then restart3:=true; end if;
				when others =>
					restart3:=true;
					set_reg(r2,M(63 downto 32),'0','0');
				end case;
			when "0001101" =>               -- CMP & CMP.B (n),Reg
				half:=bwb;
				X1:=X; 
				sub:='1'; 
				setreg:=false;
				IR(15 downto 9):="0000011"; -- continue as in ADD
			when "0001110" =>              --CMP & CMP.B Reg,(Reg,NUM,[reg],[n])
				half:=bwb;
				if fetch then Y1:=X;	end if;
				sub:='1'; 
				setreg:=false;
				IR(15 downto 9):="0000011"; -- continue as in ADD
			when "0001111" =>              --AND & AND.B Reg,(Reg,NUM,[reg],[n])
				if fetch=true then tmp:=X1 AND X; else tmp:=X1 AND Y1; end if;
				set_reg(r1,tmp,bwb,'1'); 
				restart3:=true;
			when "0111100" =>              --AND.D OR.D Reg,(Reg,NUM,[reg],[n])
				if bwb='0' then
					if fetch=true then tmp:=X1 AND X; else tmp:=X1 AND Y1; end if;
				else 
					if fetch=true then tmp:=X1 OR X; else tmp:=X1 OR Y1; end if;
				end if;
				set_reg(r1,tmp,'0','1'); 
				restart3:=true;
			when "0010000" =>              --OR & OR.B Reg,(Reg,NUM,[reg],[n])
				if fetch=true then tmp:=X1 OR X; else tmp:=X1 OR Y1; end if;
				set_reg(r1,tmp,bwb);
				restart3:=true;
			when "0010001" =>              --XOR & XOR.B Reg,(Reg,NUM,[reg],[n])
				if fetch=true then tmp:=X1 XOR X; else tmp:=X1 XOR Y1; end if;
				set_reg(r1,tmp,bwb); 
				restart3:=true;
			when "1101101" =>              --  NOT.D XOR.D  Reg,(Reg,NUM,[reg],[n])
				if bwb='0' then
					if fetch=true then tmp:=X1 XOR X; else tmp:=X1 XOR Y1; end if;
				else
					tmp:=NOT X1; 
				end if;
				set_reg(r1,tmp,'0'); 
				restart3:=true;	
			when "0010010" =>              --NOT & NOT.B Reg
				tmp:= NOT X1;
				set_reg(r1,tmp,bwb);
				restart3:=true;
			when "0010011" =>              -- SETX (Reg,NUM,[reg],[n])
				if fetch then tmp:=X; else	tmp:=Y1; end if;
				IDX<=tmp;
				restart3:=true;
			when "0010100" =>              --JMPX 
				if fetch then	tmp:=X; else tmp:=Y1; end if;
				if IDX/=ZERO16&ZERO16 then PC<=tmp; end if;
				IDX<=IDX-1;
				restart2:=true;
			when "0010101" =>              -- MOVX RegA
				tmp:=IDX;
				set_reg(r1,tmp,'0','0');
				restart3:=true;
			when "0010110" =>              -- BTST  R,n
				if X1(bt)= '0' then SR(ZR)<='1'; else SR(ZR)<='0';  end if;
				restart3:=true;
			when "1101110" =>              -- BTST  R,n
				if X1(bt+16)= '0' then SR(ZR)<='1'; else SR(ZR)<='0';  end if;
				restart3:=true;
			when "0010111" =>              -- BSET  R,n
				tmp:=X1;	tmp(bt):='1';	set_reg(r1,tmp,'0','0'); 
				restart3:=true;
			when "0011101" =>              -- BSET  R,n
				tmp:=X1;	tmp(bt+16):='1';	set_reg(r1,tmp,'0','0'); 
				restart3:=true;			
			when "0011000" =>              -- BCLR  R,n
				tmp:=X1;	tmp(bt):='0'; set_reg(r1,tmp,'0','0'); 
				restart3:=true;
			when "0100111" =>              -- BCLR  R,n
				tmp:=X1;	tmp(bt+16):='0'; set_reg(r1,tmp,'0','0'); 
				restart3:=true;
			when "0001011" =>              -- BTST  R,R / SRL.D R,R
				if bwb='0' then
					if X1(to_integer(unsigned(Y1(4 downto 0))))= '0' then SR(ZR)<='1'; else SR(ZR)<='0';  end if;
				else
					SR(CA)<=X1(to_integer(unsigned(Y1(4 downto 0)))-1);
					tmp:= std_logic_vector(shift_right(unsigned (X1),to_integer(unsigned(Y1(4 downto 0)))));
					set_reg(r1,tmp);
				end if;
				restart3:=true;
			when "1110100" =>  -- SRA.D SLA.D  R,R
				if bwb='0' then
					SR(CA)<=X1(16-to_integer(unsigned(Y1(4 downto 0))));
					tmp:= std_logic_vector(shift_right(signed (X1),to_integer(unsigned(Y1(4 downto 0)))));
				else
					SR(CA)<=X1(16-to_integer(unsigned(Y1(4 downto 0))));
					tmp:= std_logic_vector(shift_left(signed (X1),to_integer(unsigned(Y1(4 downto 0)))));
				end if;
				set_reg(r1,tmp,'0','0');
				restart3:=true;
			when "1010001" =>              -- BSET  R,R / SLL.D R,R
				if bwb='0' then
					tmp:=X1;	tmp(to_integer(unsigned(Y1(4 downto 0)))):='1';
				else
					SR(CA)<=X1(16-to_integer(unsigned(Y1(4 downto 0))));
					tmp:= std_logic_vector(shift_left(unsigned (X1),to_integer(unsigned(Y1(4 downto 0)))));
				end if;
				set_reg(r1,tmp,'0',bwb); 
				restart3:=true;
			when "0011110" =>              -- BCLR  R,R
				tmp:=X1;	tmp(to_integer(unsigned(Y1(4 downto 0)))):='0'; set_reg(r1,tmp,'0','0'); 
				restart3:=true;						
			when "0011001" =>              --SRA Reg,n
				tmp(15 downto 0):= std_logic_vector(shift_right(signed (X1(15 downto 0)),bt));
				set_reg(r1,tmp); 
				SR(CA)<=X1(bt-1);
				restart3:=true;
			when "0011010" =>              --SLA Reg,n
				tmp(15 downto 0):= std_logic_vector(shift_left(signed (X1(15 downto 0)),bt));
				set_reg(r1,tmp); 
				restart3:=true;
			when "0011011" =>              --SRL Reg,n
				SR(CA)<=X1(bt-1);
				tmp(15 downto 0):= std_logic_vector(shift_right(unsigned (X1(15 downto 0)),bt));
				set_reg(r1,tmp,'0');  
				restart3:=true;
			when "0011100" =>              --SLL Reg,n
			   SR(CA)<=X1(16-bt);
				tmp(15 downto 0):= std_logic_vector(shift_left(unsigned (X1(15 downto 0)),bt));
				set_reg(r1,tmp,'0');  
				restart3:=true;
			when "0011111" =>  -- XCHG r1,r2
				case TT is
				when 0 =>
					set_reg(r2,X1,'0','0');
				when 1 =>
					Wen:='0'; Dwen:='0';
				when others =>
					set_reg(r1,Y1,'0','0');
					restart3:=true;
				end case;	
			when "0100000" =>              -- MOVI Reg,0-15
				tmp:=ZERO16&"000000000000"&IR(5 downto 2);
				set_reg(r1,tmp,'0','0');
				restart3:=true;
			when "0100001" =>               -- CMP & CMP.B (R),(Reg,NUM,[reg],[n])
				case TT is
				when 0 =>
					half:=bwb;
					IF fetch then Y1:= X; end if; 
					AD:=X1; AS<='0'; 
				when 1 =>
					if bwb='1' then
						if X1(0)='1' then X1(7 downto 0):=Di(7 downto 0);
						             else X1(7 downto 0):=Di(15 downto 8); end if;
					else
						X1:=Di;
					end if;
					sub:='1'; AS<='1'; 
				when others =>
				restart3:=true; sub:='0';
				set_flags;	
				end case;
			when "0100010" =>              -- MOVI.B Reg,0-15
				tmp(7 DOWNTO 0):="0000"&IR(5 downto 2);
				set_reg(r1,tmp,'1','0'); 
				restart3:=true;
			when "0100110" =>              -- SRSET SRCLR n
				SR(to_integer(unsigned(IR(5 downto 2))))<=IR(8); 
				restart3:=true;		
			when "0100101" =>    -- JUMPS 1       
				if fetch then tmp:=X; else	tmp:=Y1; end if;
				case r1 is
					when "001" =>  -- JMP JLE(Reg,NUM,[reg],[n])
						if bwb='0' then
							PC<=tmp; restart2:=true;
						else
							If SR(ZR)='1' or (SR(NG)/=SR(OV)) then	PC<=tmp; restart2:=true; else restart3:=true;	end if;
						end if;
					when "010" =>              -- JZ & JNZ (Reg,NUM,[reg],[n])
						If SR(ZR)=bwb then PC<=tmp;  restart2:=true; else restart3:=true; end if;
					when "011" =>              -- JO & JNO (Reg,NUM,[reg],[n])
						If SR(OV)=bwb then PC<=tmp; restart2:=true;  else restart3:=true; end if;      
					when "100" =>              -- JC,JB & JNC (Reg,NUM,[reg],[n])
						If SR(CA)=bwb then PC<=tmp; restart2:=true;  else restart3:=true; end if;        
					when "101" =>              -- JN & JP (Reg,NUM,[reg],[n])
						If SR(NG)=bwb then PC<=tmp; restart2:=true;  else restart3:=true; end if;
					when "110" =>              -- JAE JBE (Reg,NUM,[reg],[n])   
						If SR(ZR)='1' or SR(CA)=bwb then restart2:=true;PC<=tmp;	 else restart3:=true; end if;
					when "111" =>              -- JA JL(Reg,NUM,[reg],[n])   
						if bwb='0' then
							If SR(ZR)='0' and SR(CA)='0' then restart2:=true; PC<=tmp;  else restart3:=true; end if;
						else
							If  (SR(NG)/=SR(OV)) then restart2:=true; PC<=tmp;  else restart3:=true; end if;
						end if;
					when others =>
						restart3:=true; 
				end case;
			when "0110001" =>              -- JXAD (Reg,NUM,[reg],[n])
				IDX<=IDX-1;	
				if (IDX/=ZERO16&ZERO16) then 
					if fetch then PC<=X; else PC<=Y1; end if;
					if SR(JXAD)='0' then  tmp:=X1+4; else tmp:=X1-4; end if;
					set_reg(r1,tmp,'0','0');
				end if;
				restart2:=true;
			when "0111001" =>              -- JG JGE (Reg,NUM,[reg],[n])
				If SR(ZR)=bwb and (SR(NG)=SR(OV)) then
					if fetch then PC<=X; else	PC<=Y1; end if;
					restart2:=true;
				else
					restart3:=true;
				end if;
				
			when "0110101" =>              -- JSR Reg  /NUM / <reg>/<n>
				case TT is
				when 0 =>
					AD:=ST;	AS<='0'; RW<='0';  Do:=PC;	DS<='0';    
				--when 1 =>
				when others =>
					ST<=ST-4; 
					if fetch then PC<=X; else	PC<=Y1; end if;
					restart2:=true;
				end case;
			when "0101110" =>              -- SEX SEX.B Reg
				if bwb='0' then
					tmp(31 downto 16):=(others => X1(15));
					tmp(15 downto 0):=X1(15 downto 0);
				else 
					tmp(31 downto 8):=(others => X1(7));
					tmp(7 downto 0):=X1(7 downto 0);
				end if;
				set_reg(r1,tmp,'0','0');
				restart3:=true;
			when "0110000" =>              --CMPI.B Reg,0-15
				half:='1';
				Y1:= ZERO16&"000000000000"&IR(5 downto 2);
				sub:='1'; 
				setreg:=false;
				IR(15 downto 9):="0000011"; -- continue as in ADD
         when "0110010" =>              --CMPH Reg,(Reg,NUM,[reg],[n])
				half:='1';
				X1(7 downto 0):=X1(15 downto 8);
				if fetch then Y1(7 downto 0):=X(15 downto 8); else Y1(7 downto 0):=Y1(15 downto 8);	end if;
				sub:='1'; setreg:=false;
				IR(15 downto 9):="0000011"; -- continue as in ADD
			when "0110110" =>              --ROL Reg
				tmp:= std_logic_vector(shift_left(unsigned (X1),bt));
				tmp(0):=X1(bt-1);
				set_reg(r1,tmp);  
				restart3:=true;            
			when "0110111" =>              -- RET
				case TT is
				when 0 =>
					AD:=ST+4; AS<='0'; ST<=ST+4;    
				--when 1 =>
				when others =>
					PC<=Di;
					restart2:=true;
				end case;  
			when "0111000" =>              -- IRET IJSR
				if bwb='1' then
					case TT is
					when 0 =>
						AD:=IST+4; AS<='0'; IST<=IST+4;    
					--when 1 =>
					when others =>
						PC<=Di;
						restart2:=true;
					end case;	
				else 
					case TT is
					when 0 =>
						AD:=IST;	AS<='0'; RW<='0';  Do:=PC;	DS<='0';    
					--when 1 =>
					when others =>
						IST<=IST-4; 
						if fetch then PC<=X; else	PC<=Y1; end if;
						restart2:=true;
					end case;
				end if;
			when "0100011" =>  --PUSHXI POPXI
				if bwb='0' then
					AD:=IST;	
					Y1:=IDX; IST<=IST-4;    
					restart:=true; FF<=StoreState;
				else
					case TT is
					when 0 =>
						AD:=IST+4;	AS<='0';    
						IST<=IST+4;
					when others =>
						IDX<=Di; restart3:=true;
					end case;
				end if;
			when "0111011" =>              -- PUSH Rn, n, (Rn), (n)     PUSHI
			   if fetch then Y1:=X; else Y1:=X1; end if;
				FF<=StoreState;
				if bwb='0' then AD:=ST; ST<=ST-4; else AD:=IST;	IST<=IST-4;  end if;
				restart:=true;
			when "0111101" =>              -- PUSHX | SR
					AD:=ST;	
					if bwb='0' then Y1:=IDX; else Y1:=ZERO16&SR; end if;
					ST<=ST-4;    
					restart:=true; FF<=StoreState;
			when "0111110" =>              -- POPX | POP SR
				case TT is
				when 0 =>
					AD:=ST+4;	AS<='0'; ST<=ST+4;
				when others =>
					if bwb='0' then IDX<=Di; else SR<=Di(15 downto 0); end if;
					restart3:=true;
				end case;

			when "1000000" =>              -- POP Rn , POPI
				if bwb='0' then 
					case TT is
					when 0 =>
						  AD:=ST+4; AS<='0'; ST<=ST+4;
					when others =>
						tmp:=Di;
						set_reg(r1,tmp,'0','0');
						restart3:=true;
					end case;		
				else
					case TT is
					when 0 =>
						  AD:=ist+4; AS<='0';    
					     iST<=iST+4;
					--when 1 =>
					when others =>
						tmp:=Di;
						set_reg(r1,tmp,'0','0');
						restart3:=true;
					end case;		
				end if;
			when "1000001" =>              -- INT n  don't change opcode
				case TT is
				when 0 =>
				   AD:=IST; Do:=PC; RW<='0'; Wen:='0'; DWen:='0';
					AS<='0'; DS<='0'; DACS:='1'; DACS2:='1'; WAC:='0';
				when 1 => 
					IST<=IST-4;
					AS<='1';  DS<='1'; RW<='1';
				when 2 =>
					AD:=IST; Do:=ZERO16&SR;
					AS<='0'; DS<='0';  RW<='0'; 
					SR(INT_DIS)<='1'; 
				when 3 =>
					IST<=IST-4;
					RW<='1'; AS<='1'; DS<='1';  
				when 4 =>
					AD:=ZERO16&"0000000000"&IR(5 downto 2)&"00"; 
					AS<='0'; 
				when others =>
					PC<=Di; SR(TRAP)<='0'; 
					restart2:=true; 
				end case;
			when "1000010" =>              -- RETi  don't change opcode
				case TT is
				when 0 =>
					AD:=IST+4; AS<='0';  WAC:='0'; IST<=IST+4;
				when 1 =>
				--when 2 =>
					  AS<='1'; SR<=Di(15 downto 0); 
				when 2 =>
					AD:=IST+4;	AS<='0';  IST<=IST+4;
				--when 3 =>
				when others =>	
					PC<=Di; 
					if bwb='0' then IA<="11"; IACK<='0'; end if;
					restart2:=true;
				end case;
			when "1000011" =>              -- CLI STI
					SR(INT_DIS)<=bwb;
					restart3:=true;
			when "1000101" =>   -- GETSP / MOV An,SP ; GETISP 
				if bwb='0' then
					set_reg(r1,ST,'0','0');
				else
					set_reg(r1,IST,'0','0');
				end if;
				restart3:=true;
			when "1000110" =>              -- IN IN.B Reg, (Reg, n)
				case TT is
				when 0 =>
					if fetch then AD:=X; else	AD:=Y1;	end if;
					 AS<='0';   IO<='1'; tmp(31 downto 16):=ZERO16;
				when 1 =>
				when others =>
					if (bwb='1') and (AD(0)='0') then
						tmp(7 downto 0):=Di(15 downto 8);
						tmp(15 downto 8):=ZERO8;
					else
						tmp:=Di;
					end if;
					set_reg(r1,tmp,'0','0'); 
					restart3:=true;
				end case;
			when "1000111" | "1001000" =>              -- INC DEC & INC.B DEC.B Rn
				Y1:=ZERO16&"0000000000000001";
				sub:= NOT IR(9);
				half:=bwb;
				IR(15 downto 9):="0000011"; -- continue as in ADD	
			when "1001001" =>              -- MOV MOV.B (n),Reg 
					AD:=X; FF<=StoreState;  
					BAC:=bwb; restart:=true; 
			when "1001100" =>              -- MOVHL .D Reg,(Reg,NUM,[reg],[n])
				if bwb='0' then
					if fetch2 then
						if X2(0)='1'  then tmp(15 downto 0):=X(7 downto 0)&X1(7 downto 0);
									  else tmp(15 downto 0):=X(15 downto 8)&X1(7 downto 0);	end if;
					else
						if fetch1 then	tmp(15 downto 0):=X(7 downto 0)&X1(7 downto 0);
									 else tmp(15 downto 0):=Y1(7 downto 0)&X1(7 downto 0); end if;
					end if; 
				else 
					WAC:='0';
					if fetch1 then	tmp:=X(15 downto 0)&X1(15 downto 0);
									 else tmp:=Y1(15 downto 0)&X1(15 downto 0); end if;
				end if;	
				set_reg(r1,tmp,'0','0'); 
				restart3:=true;
			when "1001101" =>              -- MOVLH .D Reg,(Reg,NUM,[reg],[n])
				if bwb='0' then
					if fetch then	tmp(7 downto 0):=X(15 downto 8);
								 else tmp(7 downto 0):=Y1(15 downto 8); end if;
				else
					WAC:='0';
					if fetch then	tmp:=X1(31 downto 16)&X(31 downto 16);
								 else tmp:=X1(31 downto 16)&Y1(31 downto 16); end if;
				end if;
				set_reg(r1,tmp,'1','0'); 
				restart3:=true;
			when "1001110" =>              -- MOVHH .D Reg,(Reg,NUM,[reg],[n])
				if bwb='0' then
					if fetch then	tmp(15 downto 0):=X(15 downto 8)&X1(7 downto 0);
					else tmp(15 downto 0):=Y1(15 downto 8)&X1(7 downto 0); end if;
				else 
					WAC:='0';
					if fetch then	tmp:=X(31 downto 16)&X1(15 downto 0);
					else tmp:=Y1(31 downto 16)&X1(15 downto 0); end if;
				end if;
				set_reg(r1,tmp,'0','0'); 
				restart3:=true;
			when "1001111" =>              --SRA.D n was SRL.B Reg
				tmp:= std_logic_vector(shift_right(signed (X1),bt));
				set_reg(r1,tmp,'0'); 
				SR(CA)<=X1(bt-1);
				restart3:=true;
			when "1010000" =>              --SLA.D n was SLL.B Reg
				tmp:=  std_logic_vector(shift_left(signed (X1),bt));
				set_reg(r1,tmp,'0');  
				SR(CA)<=X1(32-bt);
				restart3:=true; 
			when "1010010" =>              --CMPI Reg,(0-15)
				Y1:=ZERO16&"000000000000"&IR(5 downto 2);
				sub:='1'; 
				setreg:=false;
				IR(15 downto 9):="0000110"; -- continue as in ADD.D
			when "1010011" =>              --SUBI Reg,0-15   1011001-6275
				Y1:=ZERO16&"000000000000"&IR(5 downto 2);
				sub:='1'; bwb:='1';
				IR(15 downto 9):="0000110"; -- continue as in ADD.D			
			when "1010100" =>              --ADDI Reg,0-15
				Y1:=ZERO16&"000000000000"&IR(5 downto 2);
				bwb:='0'; sub:='0';
				IR(15 downto 9):="0000110"; -- continue as in ADD.D
			when "1010101" =>              -- NEG NEG.D Rn
				tmp:=X1; WAC:= not bwb ; DACS2:=bwb; Y1:=ZERO16&ONE16;
				if bwb='1' then
					X1:=NOT tmp; 
					IR(15 downto 9):="0000110"; -- continue as in ADD.D
				else
					X1:=tmp(31 downto 16)&(NOT tmp(15 downto 0));
					IR(15 downto 9):="0000011"; -- continue as in ADD
				end if;
				bwb:='0';
			when "1010110" =>              -- OUT Reg,n	
				Do:=X; AD:=X1; RW<='0'; IO<='1'; AS<='0';  DS<='0';
				IR(15 downto 9):="0000111"; -- continue as in OUT n,ax
			when "1010111" =>              -- OUT.B (Reg,n),Reg	
				case TT is
				when 0 =>
					if fetch then AD:=X; else AD:=X1; end if;
					IO<='1'; AS<='0'; Do:=Y1;
					RW<='0'; DS<='0'; BAC:='1';
				when others =>
					restart3:=true;
				end case;
			when "1011000" =>                     -- OUT.B Reg,n	
				case TT is
				when 0 =>			
					AD:=X1;  IO<='1'; AS<='0'; --Y1:=X;
					Do:=X; BAC:='1';
					RW<='0'; DS<='0'; 
				when others =>
					restart3:=true;
				end case;				
			when "1001011" =>    --SLL.D n
			   SR(CA)<=X1(32-bt);
				tmp:= std_logic_vector(shift_left(unsigned (X1),bt));
				set_reg(r1,tmp);  
				restart3:=true;
			when "1011001" =>              --SRL.D n
				SR(CA)<=X1(bt-1);
				tmp:= std_logic_vector(shift_right(unsigned (X1),bt));
				set_reg(r1,tmp);  
				restart3:=true;
			when "1001010" =>              --SLLL.D SRLL.D Reg,Reg
				case TT is
				when 0 =>
					if bwb='0' then
						SR(CA)<=X1(31);
						tmp:=X1(30 downto 0)&Y1(31); 
					else 
						tmp:="0"&X1(31 downto 1);
						SR(CA)<=Y1(0);
					end if;
					set_reg(r1,tmp,'0');
				when 1 => 
					Wen:='0'; DWen:='0';
				when others =>
					if bwb='0' then
						tmp:=Y1(30 downto 0)&"0";
					else 
						tmp:=X1(0)&Y1(31 downto 1);  
					end if;
					set_reg(r2,tmp,'0');		
					restart3:=true;  
				end case;	
			when "1100110" =>              -- SLLL SRLL Reg
				case TT is
				when 0 =>
					if bwb='0' then
						SR(CA)<=X1(15);
						tmp:=ZERO16&X1(14 downto 0)&Y1(15); 
					else 
						tmp:=ZERO16&"0"&X1(15 downto 1);
						SR(CA)<=Y1(0);
					end if;
					set_reg(r1,tmp);
				when 1 =>
					Wen:='0'; DWen:='0';
				when others =>
					if bwb='0' then
						tmp:=ZERO16&Y1(14 downto 0)&"0";
					else 
						tmp:=ZERO16&X1(0)&Y1(15 downto 1);   
					end if;
					set_reg(r2,tmp);		
					restart3:=true;
				end case;
			when "1011100" | "1011101" =>              -- ADD SUB [n],reg  ADD.B [n],reg
				X1:=X; sub:=IR(9); 
				half:=bwb;	AD:=X2;
				IR(15 downto 9):="1100100"; -- continue ADD [n],n	
			when "1011110" | "1011111" =>              -- ADD SUB [reg],reg  ADD.B [reg],reg
				X1:=AoII;  Y1:=X; -- assembler reverses X1,Y1 
				sub:=IR(9); 
				half:=bwb; AD:=X2;
				IR(15 downto 9):="1100100"; -- continue ADD [n],n	
			when "0101101" =>                               -- ADD.D SUB.D [reg],reg  
				X1:=AoII;  Y1:=X; -- assembler reverses X1,Y1 
				sub:=bwb;  AD:=X2;
				IR(15 downto 9):="1100100"; -- continue ADD [n],n
			when "0101111" =>          -- ADD.D SUB.D [reg],num  
				case TT is
				when 0 =>
					Y1:=X; AD:=X1;	sub:=bwb;  AS<='0';
				when 1 =>
					X1:=Di; AS<='1'; 
				when others  =>
					Y1:=Z1; 	set_flags;	FF<=StoreState;  	restart:=true;
					sub:='0';
				end case;
			when "1011010" | "0110100" =>   -- ADD SUB [reg],n  ADD.B [reg],n 
				case TT is
				when 0 =>
					Y1:=X; AD:=X1; AS<='0'; half:=bwb;
				when 1 =>
					X1:=Di; sub:= NOT IR(10); AS<='1'; 
				when others  =>
					if half='1' then 
						if X2(0)='0' then 
							Y1:=ZERO16&Z1(7 downto 0)&X(15 downto 8);
						else 
							Y1:=ZERO16&X(15 downto 8)&Z1(7 downto 0);
						end if;
					else 
						Y1:=Z1;
					end if;    
					set_flags;	FF<=StoreState;  	restart:=true;
					sub:='0';
				end case;
				
			when "1011011"  =>              --ADD SUB SP,(Reg,NUM,[reg],[n]) | 
					restart3:=true;
					if fetch then tmp:=X; else tmp:=Y1; end if;
					if bwb='0' then ST<=ST+tmp; else ST<=ST-tmp; end if;
			when "0110011" =>             --JXAB JXAW
					IDX<=IDX-1;	
					if (IDX/=ZERO16&ZERO16) then 
						if fetch then PC<=X; else PC<=Y1; end if;
						if SR(JXAD)='0' then  tmp:=X1+2-bwb; else tmp:=X1-2+bwb; end if;
						set_reg(r1,tmp,'0','0');
					end if;
					restart2:=true;
			when "0111111" =>              -- MTOI An1,An2 | MTOM An1,An2
				case TT is
				when 0 =>
					IO<='0'; AD:=Y1; AS<='0'; RW<='1'; DS<='1'; mem_trans<=true;  
				when 1 =>
				--when 2 =>
					RW<='0'; Do:=Di; AD:=X1;  IO<=bwb; AS<='0'; DS<='0';
				when others =>
					if (IDX/=ZERO16&ZERO16) then 
						IDX<=IDX-1;
						if SR(JXAD)='0' then
							X1:=X1+2;
							Y1:=Y1+2;
						else 
							X1:=X1-2;
							Y1:=Y1-2;
						end if;
						restart:=true;
					else
						restart3:=true;
					end if;
				end case;
			when "0101010" =>              -- NTOI An1,An2 NTOM An1,An2
				case TT is
				when 0 =>
					mem_trans<=true;  
					if fetch then Do:=X; else Do:=Y1; end if;
					AD:=X1; RW<='0';  IO<=bwb; AS<='0'; DS<='0';
				--when 1 =>
				when others =>
					AS<='0'; DS<='0'; RW<='1';
					if (IDX/=ZERO16&ZERO16) then 
						IDX<=IDX-1;
						if SR(JXAD)='0' then
							X1:=X1+2;
						else 
							X1:=X1-2;
						end if;
						restart:=true;
					else
						restart3:=true;
					end if;
				end case;
			when "1101000" =>              -- ITOI ITOM An1,An2 
				case TT is
				when 0 =>
					IO<='1'; AD:=Y1; AS<='0'; RW<='1'; DS<='1'; mem_trans<=true;  
				when 1 =>
				when 2 =>
					Do:=Di; AD:=X1; RW<='0';  IO<=bwb; AS<='0'; DS<='0';
				when others =>
					if (IDX/=ZERO16&ZERO16) then 
						IDX<=IDX-1;
						if SR(JXAD)='0' then
							X1:=X1+2;
							Y1:=Y1+2;
						else 
							X1:=X1-2;
							Y1:=Y1-2;
						end if;
						restart:=true;
					else
						restart3:=true;
					end if;
				end case;
			when "1101001" =>              -- ITOI.B ITOM.B An1,An2 
				case TT is
				when 0 =>
					IO<='1'; AD:=Y1; AS<='0'; RW<='1'; DS<='1'; mem_trans<=true;  
				when 1 =>
				when 2 =>
					if Y1(0)='0' then	Do(7 downto 0):=Di(15 downto 8);
									 else	Do(7 downto 0):=Di(7 downto 0); end if;
					BAC:='1';
					AD:=X1; RW<='0'; IO<=bwb; AS<='0'; DS<='0';
				when others =>
					if (IDX/=ZERO16&ZERO16) then 
						IDX<=IDX-1;
						if SR(JXAD)='0' then
							X1:=X1+1;
							Y1:=Y1+1;
						else 
							X1:=X1-1;
							Y1:=Y1-1;
						end if;
						restart:=true;
					else
						restart3:=true;
					end if;
				end case;
				
			when "1101010" =>              -- MTOI.B An1,An2 | MTOM.B An1,An2
				case TT is
				when 0 =>
					IO<='0'; AD:=Y1; AS<='0'; RW<='1'; DS<='1'; mem_trans<=true;  
				when 1 =>
				--when 2 =>
					if Y1(0)='0' then	Do(7 downto 0):=Di(15 downto 8);
									 else	Do(7 downto 0):=Di(7 downto 0); end if;
					AD:=X1; RW<='0'; IO<=bwb; AS<='0'; DS<='0'; BAC:='1';
				when others =>
					if (IDX/=ZERO16&ZERO16) then 
						IDX<=IDX-1;
						if SR(JXAD)='0' then
							X1:=X1+1;
							Y1:=Y1+1;
						else 
							X1:=X1-1;
							Y1:=Y1-1;
						end if;
						restart:=true;
					else
						restart3:=true;
					end if;
				end case;
			when "1101111" => -- MOV MOV.B  An1,offset(An2)
				case TT is
				when 0 =>
					X1:=X; --half:=bwb; 
				when 1 =>
					AD:=Z1; AS<='0';
				when others =>
					AS<='1';	
					if bwb='1' and AD(0)='0' then
						set_reg(r1,ZERO16&Di(7 downto 0)&Di(15 downto 8),bwb,'0');
					else
						set_reg(r1,Di,bwb,'0'); 
					end if;
					restart3:=true;
				end case;
			when "1101100" => -- MOV MOV.B  offset(An1),An2
				case TT is
				when 0 =>
					tmp:=Y1; 
					Y1:=X; --half:=bwb;
				when others =>
					AD:=Z1; Y1:=tmp; restart:=true; BAC:=bwb; FF<=StoreState; 
				end case;
			when "1101011" => -- MOV.D  An1,offset(An2) offset(An1),An2
				if bwb='0' then
					case TT is
					when 0 =>
						X1(15 downto 0):=X(15 downto 0);
					   X1(31 downto 16):=(others => X(15));	
					when 1 =>
						AD:=Z1; AS<='0';
					when others =>
						AS<='1';	
						set_reg(r1,Di,'0','0');
						restart3:=true;
					end case;
				else
					case TT is
					when 0 =>
						tmp:=Y1; 
						Y1(15 downto 0):=X(15 downto 0);
					   Y1(31 downto 16):=(others => X(15));
					when others =>
						AD:=Z1; Y1:=tmp; restart:=true; FF<=StoreState; 
					end case;
				end if;

------instructions  between 1100... and 11010....  double fetch -----------------			

			when "1100000" =>              -- MOV (n),n
				WAC:='1'; 
				AD:=X; Y1:=Y; FF<=StoreState;  
				restart:=true;
			when "1100111" =>              -- MOV.D (n),n
				AD:=X; Y1:=Y; 
				FF<=StoreState;  
				restart:=true;
			when "1100001" =>              -- MOV.B (n),n
				tmp:=X; 	AD:=X2; 
				BAC:='1'; Y1:=Y;
				restart:=true; FF<=StoreState;
			when "1100010" =>               -- CMP & CMP.B (n),n
				Y1:=Y;
				half:=bwb;				
				X1:= X; 
				sub:='1'; 
				setreg:=false;
				IR(15 downto 9):="0000011"; -- continue as in ADD

			when "1100011" =>              -- OUT n,n	
					AD:=X; Do:=Y;  RW<='0'; IO<='1';  AS<='0';  DS<='0';
					IR(15 downto 9):="0000111"; -- continue as in OUT n,ax
					
			when "1100100" | "1100101" =>              -- ADD,SUB  [n],n  ADD.B, SUB.B [n],n
				case TT is
				when 0 =>
					X1:=X; Y1:=Y; sub:=IR(9); half:=bwb;	AD:=X2;  
				when 1  =>
				when others =>
					if bwb='1' then 
						if X2(0)='0' then 
							Y1:=ZERO16&Z1(7 downto 0)&X(15 downto 8);
						else 
							Y1:=ZERO16&X(15 downto 8)&Z1(7 downto 0);
						end if;
					else 
						Y1:=Z1;
					end if;    
					set_flags;	FF<=StoreState;	restart:=true;
					sub:='0';
				end case;
			when "1110010" =>  -- ADD.D,SUB.D  [n],n 
				case TT is
				when 0 =>
					X1:=X; Y1:=Y; half:='0'; sub:=bwb;	AD:=X2;  
				when 1  =>
				when others =>
					Y1:=Z1;
					set_flags;	FF<=StoreState;	restart:=true;
					sub:='0';
				end case;
			when "1110011" =>              -- ADD.D SUB.D [n],reg 
				X1:=X; sub:=bwb; AD:=X2;
				IR(15 downto 9):="1110010"; -- continue ADD.D [n],n	
			when "1110000" =>              -- JR (Reg,NUM,[reg],[n])  JRXAD
				if bwb='0' then
					PC<=RPC; 
				else
					IDX<=IDX-1;	
					if (IDX/=ZERO16&ZERO16) then 
						PC<=RPC;
						if SR(JXAD)='0' then  tmp:=X1+4; else tmp:=X1-4; end if;
						set_reg(r1,tmp,'0','0'); 
					end if;
				end if;
				restart2:=true;
			when "1110001" =>   --JRXAB JRXAW
				IDX<=IDX-1;	
				if (IDX/=ZERO16&ZERO16) then 
					PC<=RPC;
					if SR(JXAD)='0' then  tmp:=X1+2-bwb; else tmp:=X1-2+bwb; end if;
					set_reg(r1,tmp,'0','0'); 
				end if;
				restart2:=true;			
			
			--when "1110111" =>             
			--when "1111000" =>    
			--when "1111001" =>        

			when "1111010" =>   -- JRA (Reg,NUM,[reg],[n])
				If SR(ZR)='0' and SR(CA)='0' then PC<=RPC; restart2:=true; else restart3:=true; end if;
			when "1111110" =>   -- RELATIVE JUMPS
				case r2 is
				when "000"  =>   -- JRGE - JRL (Reg,NUM,[reg],[n])
					if bwb='0' then
						If SR(ZR)='1' or (SR(NG)=SR(OV)) then	PC<=RPC; restart2:=true; else restart3:=true; end if;
					else
						If  (SR(NG)/=SR(OV)) then PC<=RPC; restart2:=true; else restart3:=true; end if;
					end if;
				when "001" =>  --JRZ JRNZ
					if SR(ZR)=bwb then	PC<=RPC; restart2:=true; else restart3:=true; end if;
				when "010" =>  --JRC JRNC JRB JRAE
					if SR(CA)=bwb then	PC<=RPC; restart2:=true; else restart3:=true; end if;
				when "011" =>  --JRN JRP
					if SR(NG)=bwb then	PC<=RPC; restart2:=true; else restart3:=true;	end if;
				when "100" =>  --JRO JRNO
					if SR(OV)=bwb then	PC<=RPC; restart2:=true; else restart3:=true; end if;
				when "101" =>  --JRG
					If SR(ZR)='0' and (SR(NG)=SR(OV)) then	PC<=RPC; restart2:=true; else restart3:=true; end if;
				when "110" =>  --JRBE
					If SR(ZR)='1' or SR(CA)='1' then	PC<=RPC; restart2:=true; else restart3:=true; end if;
				when "111" =>  --JRLE
					If SR(ZR)='1' or (SR(NG)/=SR(OV)) then	PC<=RPC; restart2:=true; else restart3:=true; end if;
				end case;
			when "1110110" =>              -- JRSR (Reg,NUM,[reg],[n])
				case TT is
				when 0 =>
					AD:=ST;	AS<='0'; RW<='0'; Do:=PC;    
					DS<='0'; 
				when others =>
					ST<=ST-4; --ST-2; --DS<='1'; RW<='1'; AS<='1';
					PC<=RPC;
					restart2:=true;
				end case;	
			when "1111011" =>              -- MOVR Reg,([n],[R])  MOVR.B Reg,([n],[R]) 
				case TT is
				when 0 =>
					AD:=RPC;	AS<='0';  
				when 1=>
				when others =>
					restart3:=true;
					if fetch2 then	
						if RPC(0)='0' and bwb='1' then
							tmp:=ZERO16&Di(7 downto 0)&Di(15 downto 8);
						else tmp:=Di; end if;	
					else tmp:=RPC;	
					end if;
					set_reg(r1,tmp,bwb,'0');  
				end case;
			when "1111100" =>              -- MOVR MOVR.B([n],[R]),Reg	 0101001  
				AD:=RPC;  BAC:=bwb;
				AS<='1';	restart:=true; FF<=StoreState;
			when "0101001" =>              -- MOVR.D [n],num	 0101001  
				AD:=RPC;  BAC:='0';
				Y1:=Y;
				AS<='1';	restart:=true; FF<=StoreState;
			when "0101011" =>              -- MOVR MOVR.B[n],num  
				AD:=RPC;  BAC:=bwb;
				Y1:=Y;
				AS<='1';	restart:=true; FF<=StoreState;
			when "1111101" =>   -- MOVR.D GADR  R,  addr (addr)
				if bwb='0' then
					case TT is
					when 0 =>
						if fetch2 then
							AD:=RPC;	AS<='0';  
						else
							tmp:=RPC; set_reg(r1,tmp,'0','0');
							restart3:=true;
						end if;
					when 1=>
					when others =>
						restart3:=true;
						tmp:=Di; set_reg(r1,tmp,'0','0');  
					end case;
				else           -- MOVR.D (addr),Rn
					AD:=RPC;   
					--if fetch then Y1:=X; end if; --***** CHECK AGAIN
					AS<='1';	restart:=true; FF<=StoreState;
				end if;
			when "1111111" =>    --JRX 
				if IDX/=ZERO16&ZERO16 then PC<=RPC; end if;
				IDX<=IDX-1;
				restart2:=true;
			when others => -- instructions  NOP	
				restart3:=true;
			end case;
			
		when StoreState => -- FF="111" write Y1 to mem in AD
 			case TT is
			when 0 =>
				IO<='0'; AS<='0';  Do:=Y1; DS<='0'; RW<='0';	
			when others =>	
				restart3:=true;
			end case;
		when others =>
			restart3:=true;
		end case;
	------------------------------------------------------------------
		if restart or restart2 then 
			TT<=0;  
			if restart2 then 
				RW<='1'; IO<='0'; DS<='1'; AS<='1'; FF<=InitialState;
			end if;
		else
			if restart3 then -- prepare next instruction and skip TT=0 step
				init_next_ins; 
				RW<='1'; IO<='0'; FF<=InitialState;	TT<=1;
			elsif rest4=false then
				TT<=TT+1; 
			end if;
		end if;
	END IF ;
END IF;
end Process;
end Behavior;


