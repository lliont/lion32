#include "stdio.h"
#include "syslib.h"


PosYX (y,x) int y,x;
{
  #asm
  MOV.D A1,12(A6)
  MOV.D A2,8(A6)
  MOVHL A1,A2
  MOV   (_XY),A1
  #endasm
}

ColorYX (y,x,f,b) int x,y,f,b;
{
  #asm
  MOV.D A1,20(A6)
  MOV.D A2,16(A6)
  MOV.D A3,12(A6)
  MOV.D A4,8(A6)
  MULU A1,80
  ADD A1,A2
  ADD A1,61152
  SLL A4,3
  OR A3,A4
  OUT.B A1,A3
  #endasm
}

Screen (fcol,bcol) int fcol,bcol;
{
  #asm
  MOV.D A0,12(A6)
  MOV.D A1,8(A6)
  IN A3,24
  CMPI.B A3,0
  JRZ 18
  MOV.B ($485c),A0
  MOV.B ($485d),A1 ; //for mode 1
  JR  24
  SLL A1,4
  OR A1,A0
  SETX 2399
  MOV.D A0,61152
  OUT.B A0,A1
  JRXAB A0,-8
  #endasm
}


IOout (ad,b) int ad; char b;
{
  #asm
  MOV.D A1,12(A6)
  MOV.D A2,8(A6)
  OUT	A1,A2
  #endasm
}

IOoutb (ad,b) int ad; char b;
{
  #asm
  MOV.D A1,12(A6)
  MOV.D A2,8(A6)
  OUT.B	A1,A2
  #endasm
}

IOin (ad) int ad;
{
	#asm
	MOV.D A2,8(A6)
	IN	A1,A2
	#endasm
}

IOinb (ad) int ad;
{
	#asm
	MOV.D A2,8(A6)
	IN.B  A1,A2
	#endasm
}

MEMtoIO (ad1,ad2,n) int ad1,ad2,n;  // from ad1 to ad2
{
  #asm
  MOV.D A3,8(A6)
  MOV.D A2,12(A6)
  MOV.D A1,16(A6)
  SUBI A3,1
  SETX A3
  MTOI.B A2,A1
  #endasm
}

MEMtoMEM (ad1,ad2,n) int ad1,ad2,n; // from ad1 to ad2
{
  #asm
  MOV.D A3,8(A6)
  MOV.D A2,12(A6)
  MOV.D A1,16(A6)
  SUBI A3,1
  SETX A3
  MTOM.B A2,A1
  #endasm
}

WtoMEM (ad1,w,n) int ad1,w,n;
{
  #asm
  MOV.D A3,8(A6)
  MOV.D A2,12(A6)
  MOV.D A1,16(A6)
  SUBI A3,1
  SETX A3
  NTOM A1,A2
  #endasm
}
