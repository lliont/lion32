#include "stdio.h"
#include "float.h"

fadd(int a, int b)
{
	#asm
	MOV.D A3,8(A6)
    MOV.D A1,12(A6)
    MOVI A0,11
    INT 5
	#endasm
}

fsub(int a, int b)
{
	#asm
	MOV.D A3,8(A6)
    MOV.D A1,12(A6)
	XOR.D A3,$80000000
    MOVI A0,11
    INT 5
	#endasm
}

fneg(int a)
{
	#asm
	MOV.D A1,8(A6)
    XOR.D A1,$80000000
	#endasm
}

fmult(int a, int b)
{
	#asm
	MOV.D A3,8(A6)
    MOV.D A1,12(A6)
    MOVI A0,9
    INT 5
	#endasm
}

fdiv(int a, int b)
{
	#asm
	MOV.D A3,8(A6)
    MOV.D A1,12(A6)
    MOVI A0,10
    INT 5
	#endasm
}

ftoi(int f)
{
  #asm
  MOV.D	A3,8(A6)
  MOV.D A5,A3
  MOV.D A2,A3
  AND.D A2,$80000000
  AND.D A3,$007FFFFF
  AND.D A5,$7FFFFFFF 
  SRL.D A5,8
  SRL.D A5,15
  MOV.D A0,A3
  OR.D A0,A5
  JRNZ 8
  MOVI A1,0
  JR FTOI_E  
  OR.D A3,$800000
  SUB.D A5,127
  MOV.D A1,$7FFFFFFF
  CMP.D A5,30
  JRG FTOI_E
  MOVI A1,1
  CMPI A5,0
  JRL FTOI_E
  FTOI_1: CMPI A5,0
  JRZ FTOI_E
  SLL.D A1,1
  BTST A3,22
  JRZ 2
  BSET A1,0
  SLL.D A3,1
  SUBI A5,1
  JR FTOI_1
  FTOI_E: BTST A2,31
  JRZ 2
  NEG.D A1
  #endasm
}

itof(int i)
{
  #asm
  MOV.D	A4,8(A6)
  MOVI A5,0
  MOVI A3,0
  MOVI A1,0
  CMPI A4,0
  JRZ ITOF_3
  BTST A4,31
  JRZ 8
  NEG.D A4
  MOV.D  A5,$80000000
  MOV.D  A7,=24+31+127
  ITOF_1: BTST A3,23
  JRNZ ITOF_2
  SLLL.D A3,A4
  SUBI A7,1
  JR ITOF_1
  ITOF_2: AND.D A3,$7FFFFF
  SLL.D A7,8 
  SLL.D A7,15
  OR.D A5,A7
  OR.D A3,A5
  MOV.D A1,A3
  ITOF_3:
  #endasm
}

fcomp(int a, int b)
{
#asm
 MOV.D A3,8(A6)
 MOV.D A1,12(A6)
 MOVI A0,12
 INT 5
 MOV.D A1,A0
#endasm
}

ftos(char *s, int f)
{
  #asm
  MOV.D A3,8(A6)
  MOV.D A2,12(A6)	
  MOV.D A1,A3
  AND.D A1,$7FFFFFFF
  CMP.D A1,$7f800000
  JRNZ PFLT_NINF
  MOV.B  A1,'I'  
  MOV.B (A2),A1
  ADDI  A2,1  
  JR PRTNUMEND
 PFLT_NINF:
  CMP.D A1,0
  JRNZ 14
  MOV.B  A1,'0'
  MOV.B (A2),A1
  ADDI  A2,1
  JR PRTNUMEND
  BTST A3,31
  JRZ PFLT_1
  BCLR A3,31
  MOV A1,'-'  
  MOV.B (A2),A1
  ADDI  A2,1  
 PFLT_1:
  MOV.D A0,A3
  SRL.D A0,8  
  SRL.D A0,15
  AND.D A3,$007FFFFF  
  MOV.D  A5,A3
  OR.D  A5,A0
  JRZ PFLT_0  
  MOVI A1,0  
  SUB.D A0,127
  BSET A3,24
  CMPI A0,0  
  JRL PFLT_9
  
 PFLT_3:        
  CMP.D A0,23
  JRL PFLT_7
  ADDI A1,1
  PUSH A0
  PUSH A1
  MOVI A1,10
  PUSH A2
  MOV.D A2,A3
  MOVI A0,9
  INT 4
  POP A2
  MOV.D A3,A1
  POP A1
  POP A0
 PFLT_8:
  SUBI A0,1
  SLL.D A3,1
  BTST A3,23
  JRZ PFLT_8
  JR PFLT_3

 PFLT_9:        
  CMP.D A0,-1  
  JRG PFLT_7
  SUBI A1,1
  MUL.D A3,10
 PFLT_10:
  ADDI A0,1
  SRL.D A3,1
  MOV.D A4,A3
  AND.D A4,$FF000000
  JRNZ PFLT_10
  JR PFLT_9
  
PFLT_7:  
  MOVR.D (EXP_1),A1
  MOVI A1,0
  MOVI A5,1  
  CMPI A0,0
 PFLT_4:
  CMPI A0,0
  JRZ PFLT_2
  SLL.D A5,1
  SLL.D A3,1
  BTST A3,23
  JRZ 2
  BSET A5,0
  SUBI A0,1
  ADDI A1,1
  JR PFLT_4
  PFLT_2:
  MOVR.D (NUM_1),A5
  CMP.D A1,24
  JRZ PFLT_E

  SUB.D A1,24
  NEG.D A1
  MOV.D A5,$004c4b40 
  SETX A1 
  MOVI A1,0
  ;MOVI A2,0
 PFLT_11:
  SLL.D A3,1
  BTST A3,23
  JRZ 2
  ADD.D A1,A5
  SRL.D A5,1
  JRX PFLT_11
  MOVR.D (FRACT_1),A1
  
  JR PFLT_E
 PFLT_0:
  MOV.D A1,'0'
  MOV.B (A2),A1
  ADDI  A2,1 
  JR PRTNUMEND
 PFLT_E:  
  MOVR.D A1,(NUM_1)
  JRSR PRTNUM
  MOVR.D A3,(FRACT_1)
  OR.D  A3,A3
  JRZ PFLT_12
  MOV.D A1,'.'
  MOV.B (A2),A1
  ADDI  A2,1
  MOVR.D A1,(FRACT_1)
  JRSR Longp_2
  PFLT_12:
  MOVR.D A0,(EXP_1)  
  OR.D A0,A0
  JRZ PFLT_6
  MOV.D A1,'E'  
  MOV.B (A2),A1
  ADDI  A2,1
  MOVR.D A1,(EXP_1)
  JRSR PRTNUM
  PFLT_6:
  JR PRTNUMEND
  
  
  
 PRTNUM:
  PUSH A3
  PUSH A4
  MOV.D A4,A2
  MOVI A3,0   
  BTST A1,31
  JRNZ 6
  JR PRTNUM1
  MOV A2,A1
  MOV.B A1,'-'
  MOV.B (A4),A1
  ADDI  A4,1 
  MOV.D A1,A2
 PRTNUM1:
  MOV.D A2,A1
  MOVI A1,10
  MOVI A0,9
  INT 4
  PUSH A0
  ADDI A3,1
  CMPI A1,0
  JRNZ PRTNUM1
  SUBI A3,1
  SETX A3
 PRTNUM2:
  POP A1
  ADD A1,48
  MOV.B (A4),A1
  ADDI  A4,1
  JRX PRTNUM2
  MOV.D A2,A4
  POP A4
  POP A3
  RET
	
Longp_2:
  PUSH A4
  MOVI A7,0
  MOV.D A4,A2
Longp_3:
  MOV.D A2,A1
  MOVI A1,10
  MOVI A0,9
  INT 4
  INC A7
  PUSH A0
  CMPI A1,0
  JRNZ Longp_3
DPART_1:
  CMPI A7,7
  JRGE 14
  PUSH 0
  ADDI A7,1
  JR DPART_1
  SUBI A7,1
  SETX A7
Longp_4:
  POP A1
  ADD.D A1,48
  MOV.B (A4),A1
  ADDI A4,1
  JRX Longp_4
  MOV.D A2,A4
  POP A4
  RET	
  
  EXP_1  DD 0
  NUM_1 DD 0
  FRACT_1 DD 0
  PRTNUMEND:
  MOV.B (A2),0
  #endasm
}

stof(char *s)
{
	int res;
    int val, power;
    int sign, i;
 
     for (i = 0; isspace(s[i]); i++)  ;
    sign = (s[i] == '-') ? -1 : 1;
     if (s[i] == '+' || s[i] == '-')  i++;
     for (val = 0; isdigit(s[i]); i++)
         val = fadd(fmult(TEN, val), itof((s[i] - '0')));
     if (s[i] == '.')
         i++;
     for (power = ONE; isdigit(s[i]); i++) {
         val = fadd(fmult(TEN, val), itof((s[i] - '0')));
         power=fmult(power,TEN);
     }
     res =  fdiv( val , power);
	 if (sign==-1) fneg(res);
	 return res;
}