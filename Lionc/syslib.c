#include "stdio.h"
#include "syslib.h"

Set_sprite(s,buf,en,x,y) int s,buf,en,x,y;
{
	int bank,ss;
	bank=s/14; ss=s % 14;
	IOout(SPRBASE+bank*4096+256*buf+ss*8,x);   
	IOout(SPRBASE+bank*4096+2+256*buf+ss*8,y); 
	IOout(SPRBASE+bank*4096+6+256*buf+ss*8,en); 
}

Disable_sprite(s)  int s;
{
	int bank,ss;
	bank=s/14; ss=s%14;
	IOout(SPRBASE+bank*4096+6+256+ss*8,0);
	IOout(SPRBASE+bank*4096+6+ss*8,0);
}
	
Set_sprite_data(s,sbuf,data,frame) int s,sbuf,frame; char data[]; 
{
	int bank,ss,j,adr;
	bank=s/14; ss=s%14; adr=SPRBASE+512+bank*4096+1792*sbuf+ss*128;
	for (j=0; j<128; j++)  {
			IOoutb(adr+j,data[j+frame*128]);
	}
}

Sprite_buffer (int b)
{
 #asm
 MOV.D A0,8(A6)
 OUT 20,A0
 #endasm
}

Vscrollc( int x, int lx, int y, int ly, int sl)
{
 #asm
 MOV.D A0,24(A6)
 MOV.D A1,20(A6)
 MOV.D A2,16(A6)
 MOV.D A3,12(A6)
 MOV.D A4,8(A6)
 OUT 96778,A4   
 OUT 96776,A3
 OUT 96774,A2 
 OUT 96772,A1   
 OUT 96770,A0   
 MOVI A0,15  
 INT  4
 #endasm
}

Hscrollc( int x, int lx, int y, int ly, int sp)
{
 #asm
 MOV.D A0,24(A6)
 MOV.D A1,20(A6)
 MOV.D A2,16(A6)
 MOV.D A3,12(A6)
 MOV.D A4,8(A6)
 OUT 96778,A4   
 OUT 96776,A3
 OUT 96774,A2 
 OUT 96772,A1   
 OUT 96770,A0   
 MOVI A0,15  
 INT  5
 #endasm
}

Vscrollf( int x, int lx, int y, int ly, int sl, int adr)
{
 #asm
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
 #endasm
}

Hscrollf( int x, int lx, int y, int ly, int sp, int adr)
{
 #asm
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
 MOV.D A0,19  
 INT  5
 #endasm
}

Sound(chan,freq,dur) int freq,dur,chan;
{
 #asm
 MOV.D A4,16(A6)
 MOV.D A2,12(A6)
 MOV.D A3,8(A6)
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
 #endasm
}

Noise(int ch)
{
  #asm
  MOV.D A0,8(A6)
  OUT 11,A0
  #endasm
}

Rnd(int rand)
{
  #asm
  MOV.D A0,8(A6)
  MOV.D A2,48271
  MULU.D A2,A0
  MOV.D A1,65521
  MOVI A0,6
  INT 5
  MOV.D (RAND),A0
  POP A1
  MOV.D A2,A0
  MOVI A0,6
  INT 5
  ADDI A0,1
  MOV.D A1,A0
  #endasm
}

GMode (m) int m;
{
 #asm
 MOV.D A0,8(A6)
 OUT 24,A0
 #endasm
}

Isplaying (c) int c;
{
 #asm
 MOV.D A0,8(A6)
 MOVI A1,0
 IN A2,9
 BTST A2,A0
 JRZ 2
 MOVI A1,1
 #endasm
}

Plot (x,y,mode) int x,y,mode;
{
  #asm
  MOV.D A1,16(A6)
  MOV.D A2,12(A6)
  MOV.D A3,8(A6)
  MOV.B (PLOTM),A3
  MOVI A0,2
  INT 4
  #endasm
}

Line (x,y,x2,y2) int x,y,x2,y2;
{
  #asm
  MOV.D A1,20(A6)
  MOV.D A2,16(A6)
  MOV.D A3,12(A6)
  MOV.D A4,8(A6)
  MOVI A0,14
  INT 5
  #endasm
}

Circle (x,y,r) int x,y,r;
{
  #asm
  MOV.D A1,16(A6)
  MOV.D A2,12(A6)
  MOV.D A3,8(A6)
  MOV.D A0,17
  INT 5
  #endasm
}

Inkey()
{
 #asm
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
 #endasm
}

Joy1()
{
 #asm
 IN A1,22
 NOT A1
 AND A1,31
 #endasm
}

Joy2()
{
 #asm
 IN A1,22
 SWAP A1
 NOT A1
 AND A1,31
 #endasm
}

Scroll_up()
{
 #asm
 MOVI A0,6
 INT 4
 #endasm
}

Timer()
{
#asm
MOVI A0,0
MOVI A1,0
IN	A0,21
SWAP.D	A0
IN	A1,20
OR.D A1,A0 
#endasm
}

Cls()
{
 #asm
 MOVI A0,3
 INT 4
 #endasm
}

PutcYX (y,x,c) int y,x; char c;
{
 #asm
 MOV.D A2,16(A6)
 MOV.D A3,12(A6)
 MOV.D A1,8(A6)
 MOVHL A2,A3
 MOVI A0,4
 INT 4
 #endasm
}

PrintstrYX(y,x,s) int y,x,s;
{
  #asm
  MOV.D A2,16(A6)
  MOV.D A3,12(A6)
  MOV.D A1,8(A6)
  MOVHL A2,A3
  MOVI A0,5
  INT 4
  #endasm
}

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
  ADD A1,COLTBL
  SLL A4,3
  OR A3,A4
  OUT.B A1,A3
  #endasm
}

Screen (bcol,fcol) int fcol,bcol;
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
  MOV.D A0,COLTBL
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
