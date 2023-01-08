ORG 0
_XY EQU $4868
PLOTM EQU $484E
COLTBL EQU 61152

_Sprite_buffer:
 MOV.D A0,(A7)
 OUT 20,A0
 POP A1
 PUSH A0
 JMP A1

_Vscrollc:      ;( int x, int lx, int y, int ly, int sl)
 PUSH A7
 MOV.D A0,(A7)
 MOV.D A1,-4(A7)
 MOV.D A2,-8(A7)
 MOV.D A3,-12(A7)
 MOV.D A4,-16(A7)
 OUT 96778,A4   
 OUT 96776,A3
 OUT 96774,A2 
 OUT 96772,A1   
 OUT 96770,A0   
 MOVI A0,15  
 INT  4
 POP A7
 POP A1
 PUSH A0
 JMP A1


_Hscrollc:    ;( int x, int lx, int y, int ly, int sp)
 PUSH A7
 MOV.D A0,(A7)
 MOV.D A1,-4(A7)
 MOV.D A2,-8(A7)
 MOV.D A3,-12(A7)
 MOV.D A4,-16(A7)
 OUT 96778,A4   
 OUT 96776,A3
 OUT 96774,A2 
 OUT 96772,A1   
 OUT 96770,A0   
 MOVI A0,15  
 INT  5
 POP A7
 POP A1
 PUSH A0
 JMP A1

_Vscrollf:       ;( int x, int lx, int y, int ly, int sl, int adr)
 PUSH A7
 MOV.D A0,28(A6)
 MOV.D A1,24(A6)
 MOV.D A2,20(A6)
 MOV.D A3,16(A6)
 MOV.D A4,12(A6)
 MOV.D A7,8(A6)
 OUT 96778,A4   
 OUT 96776,A3
 OUT 96774,A2 
 OUT 96772,A1   
 OUT 96770,A0   
 MOV.D A0,18  
 INT  5
 POP A7
 POP A1
 PUSH A0
 JMP A1


_Hscrollf:      ;( int x, int lx, int y, int ly, int sp, int adr)
 PUSH A7
 MOV.D A0,(A7)
 MOV.D A1,-4(A7)
 MOV.D A2,-8(A7)
 MOV.D A3,-12(A7)
 MOV.D A4,-16(A7)
 MOV.D A7,-20(A7)
 OUT 96778,A4   
 OUT 96776,A3
 OUT 96774,A2 
 OUT 96772,A1   
 OUT 96770,A0   
 MOV.D A0,19  
 INT  5
 POP A7
 POP A1
 PUSH A0
 JMP A1

_Sound:     ;(chan,freq,dur) int freq,dur,chan;
 MOV.D A4,(A7)
 MOV.D A2,-4(A7)
 MOV.D A3,-8(A7)
 MOVI A1,0
 CMP A2,15
 JRC 16
 SLL.D A3,13
 MOV.D A1,A2
 MOV.D A2,200000
 MOVI A0,6
 INT 5
 ADD.D A1,A3
 SLL.D A4,1
 ADDI A4,8
 OUT A4,A1
 POP A1
 PUSH A0
 JMP A1

_Noise:    ;(int ch)
 MOV.D A0,(A7)
 OUT 11,A0
 POP A1
 PUSH A0
 JMP A1

_Rnd:     ;(int rand)
  MOV.D A0,(A7)
  MOV.D A2,48271
  MULU.D A2,A0
  MOV.D A1,65521
  MOVI A0,6
  INT 5
  MOV.D (_RAND),A0
  POP A1
  MOV.D A2,A0
  MOVI A0,6
  INT 5
  ADDI A0,1
  MOV.D A1,A0
 POP A0
 PUSH A1
 JMP A0

_GMode:     ;(m) int m;
 MOV.D A0,(A7)
 OUT 24,A0
 POP A1
 PUSH A0
 JMP A1

_Isplaying:      ; (c) int c;
 MOV.D A0,(A7)
 MOVI A1,0
 IN A2,9
 BTST A2,A0
 JRZ 2
 MOVI A1,1
 POP A0
 PUSH A1
 JMP A0

_Plot:   ; (x,y,mode) int x,y,mode;
  MOV.D A1,(A7)
  MOV.D A2,-4(A7)
  MOV.D A3,-8(A7)
  MOV.B (PLOTM),A3
  MOVI A0,2
  INT 4
 POP A1
 PUSH A0
 JMP A1

_Line:    ; (x,y,x2,y2) int x,y,x2,y2;
  MOV.D A1,(A7)
  MOV.D A2,-4(A7)
  MOV.D A3,-8(A7)
  MOV.D A4,-12(A7)
  MOVI A0,14
  INT 5
 POP A1
 PUSH A0
 JMP A1

_Circle:     ;(x,y,r) int x,y,r;
  MOV.D A1,(A7)
  MOV.D A2,-4(A7)
  MOV.D A3,-8(A7)
  MOV.D A0,17
  INT 5
 POP A1
 PUSH A0
 JMP A1

_Inkey:
 MOVI A1,0
 MOVI A0,0
 INT 4
 BTST A0,1
 JRNZ 16
 MOVI A0,7
 INT 4
 BTST A0,2
 JRZ 4
 MOVI A0,10
 INT 4
 POP A0
 PUSH A1
 JMP A0

_Joy1:
 IN A1,22
 NOT A1
 AND A1,31
 POP A0
 PUSH A1
 JMP A0

_Joy2:
 IN A1,22
 SWAP A1
 NOT A1
 AND A1,31
 POP A0
 PUSH A1
 JMP A0

_Scroll_up:
 MOVI A0,6
 INT 4
 POP A1
 PUSH A0
 JMP A1

_Timer:
MOVI A0,0
MOVI A1,0
IN	A0,21
SWAP.D A0
IN	A1,20
OR.D A1,A0 
 POP A0
 PUSH A1
 JMP A0

_Cls:
 MOVI A0,3
 INT 4
 POP A1
 PUSH A0
 JMP A1

_PutcYX: ;(y,x,c) int y,x; char c;

 MOV.D A2,(A7)
 MOV.D A3,-4(A7)
 MOV.D A1,-8(A7)
 MOVHL A2,A3
 MOVI A0,4
 INT 4
 POP A1
 PUSH A0
 JMP A1

_PrintstrYX:      ;(y,x,s) int y,x,s;

  MOV.D A2,(A7)
  MOV.D A3,-4(A7)
  MOV.D A1,-8(A7)
  MOVHL A2,A3
  MOVI A0,5
  INT 4
 POP A1
 PUSH A0
 JMP A1

_PosYX:    ; (y,x) int y,x;
  MOV.D A1,(A7)
  MOV.D A2,-4(A7)
  MOVHL A1,A2
  MOV   (_XY),A1
 POP A1
 PUSH A0
 JMP A1

_ColorYX:    ; (y,x,f,b) int x,y,f,b;
  MOV.D A1,(A7)
  MOV.D A2,-4(A7)
  MOV.D A3,-8(A7)
  MOV.D A4,-12(A7)
  MULU A1,80
  ADD A1,A2
  ADD A1,COLTBL
  SLL A4,3
  OR A3,A4
  OUT.B A1,A3
 POP A1
 PUSH A0
 JMP A1

_Screen:      ;(bcol,fcol) int fcol,bcol;
  MOV.D A0,(A7)
  MOV.D A1,-4(A7)
  IN A3,24
  CMPI.B A3,0
  JRZ 18
  MOV.B ($485c),A0
  MOV.B ($485d),A1 ; //for mode 1
  JR  24
  SLL A1,4
  OR A1,A0
  SETX 2399
  MOV.D A0,COLTBL
  OUT.B A0,A1
  JRXAB A0,-8
 POP A1
 PUSH A0
 JMP A1



_MEMtoIO:    ; (ad1,ad2,n) int ad1,ad2,n;  // from ad1 to ad2
  MOV.D A3,(A7)
  MOV.D A2,-4(A7)
  MOV.D A1,-8(A7)
  SUBI A3,1
  SETX A3
  MTOI.B A2,A1
 POP A1
 PUSH A0
 JMP A1

_MEMtoMEM:     ;(ad1,ad2,n) int ad1,ad2,n; // from ad1 to ad2
  MOV.D A3,(A7)
  MOV.D A2,-4(A7)
  MOV.D A1,-8(A7)
  SUBI A3,1
  SETX A3
  MTOM.B A2,A1
 POP A1
 PUSH A0
 JMP A1

_WtoMEM:         ;(ad1,w,n) int ad1,w,n;
  MOV.D A3,(A7)
  MOV.D A2,-4(A7)
  MOV.D A1,-8(A7)
  SUBI A3,1
  SETX A3
  NTOM A1,A2
  POP A1
 PUSH A0
 JMP A1


