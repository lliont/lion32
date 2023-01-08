ORG 0 
 
_exp:
    MOV.D A1,(A7)
    MOV.D A3,$3FB8AA3B  ; 1.44
    MOVI A0,9  ;MULT
    INT 5  
_exp2:
    PUSH A5
    PUSH A6
    PUSH A7
    MOVI A6,0  
    BTST A1,15
    JRZ 6  
    MOV.D A6,1 ;$3F800000  ; A6=sign = 1
    MOV.D A5,A1 ; A1=p  
    MOV.D A3,$42F28C55   ;121.274
    MOVI A0,11 ;ADD
    INT 5
    PUSH A1  ; save p + 121  
    PUSH A5  ; save p   
    MOV.D A3,A5  ;  w = p to long  
    JRSR __ftoi ;A1A2= long p = w
    POP A4
    JRSR __itof ;A3A4= (float) w
    POP A3
    POP A1   ; get p
    XOR.D A3,$80000000   ; A3A4= -w 
    MOVI A0,11 
    INT 5   ; A1,A2 = p-w
    MOV.D A3,A6
    MOVI A0,11 
    INT 5     ;A1A2 = z = p-w+sign
    POP A5 
    PUSH A1 ;push z
    MOV.D A1,$409AF5F8 
    POP A3
    PUSH A3 ;save again
    XOR.D A3,$80000000 ; -z
    MOVI A0,11 
    INT 5 
    MOV.D A3,A1  
    MOV.D A1,$41DDD2FE 
    MOVI A0,10   ;DIV
    INT 5        ; 27.7/(4.8-z)
    MOV.D A3,A5  
    MOVI A0,11 
    INT 5
    MOV.D A5,A1 ;save p+121.2..  + 27.7/(4.8-z)
    POP A1  ;get z
    MOV.D A3,$3FBEBC8D 
    MOVI A0,9 
    INT 5   ; z*1.49
    MOV.D A3,A1   
    XOR.D A3,$80000000
    MOV.D A1,A5   
    MOVI A0,11 
    INT 5  
    MOV.D A3,$4b000000  ; (1<<23)* 
    MOVI A0,9 
    INT 5
    MOV.D A3,A1  
    JRSR __ftoi
    POP A1
    POP A7
    POP A6
    POP A5
    POP A0
    PUSH A1
    JMP A0 
	
	 
	
__sin:
  MOV.D A1,(A7)
  PUSH A7
  PUSH A6
  PUSH A5
  MOV.D A3,$40490fda  ; pi
  MOVI A0,12
  INT 5     
  CMPI A0,1    
  JRNZ SIN_2
  MOV.D A3,$C0C90fdb
  MOVI A0,11
  INT 5 
  JR SIN_1  
 SIN_2:
  MOV.D A3,$c0490fdb
  MOVI A0,12
  INT 5    
  CMP.D A0,-1   
  JRNZ SIN_1
  MOV.D A3,$40C90fdb 
  MOVI A0,11
  INT 5  
 SIN_1:
  MOV.D A5,A1 
  MOV.D A3,$3ECF817B 
  MOVI A0,9
  INT 5
  MOV.D A3,$3fa2f983
  XCHG A1,A3
  BTST A5,31
  JRNZ 6
  OR.D A3,$80000000 
  MOVI A0,11 
  INT 5  
  XCHG A5,A3
  MOVI A0,9 
  INT 5
  MOV.D A5,A1
  MOV.D A3,A1
  BTST A5,31 
  JRZ 6 
  XOR.D A3,$80000000 
  MOVI A0,9
  INT 5 
  MOV.D A3,A5
  XOR.D A3,$80000000 
  MOVI A0,11
  INT 5 
  MOV.D A3,$3e828f5c  
  MOVI A0,9
  INT 5 
  MOV.D A3,A5   
  MOVI A0,11
  INT 5
  POP A5
  POP A6
  POP A7
  POP A0
  PUSH A1
  JMP A0 

_sqrt:
  PUSH A7
  PUSH A6
  PUSH A5
  MOV.D A1,(A7)
  MOV.D A5,A1 
  MOV.D A3,$bf000000
  MOVI A0,9
  INT 5  
  XCHG A5,A1 
  SRL.D A1,1
  MOV.D A3,$5f375a86
  SUB.D A3,A1  
  XCHG A3,A5  
  XCHG A4,A7  
  MOV.D A1,A5
  MOVI A0,9
  INT 5   
  MOV.D A3,A5
  MOVI A0,9
  INT 5  
  MOV.D A3,$3fc00000  
  MOVI A0,11
  INT 5    
  MOV.D A3,A5
  MOVI A0,9
  INT 5 
  MOV.D A3,A1  
  MOV.D A1,$3f800000
  MOVI A0,10 
  INT 5
  POP A5
  POP A6
  POP A7
  POP A0
  PUSH A1
  JMP A0 




