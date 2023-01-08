#include "clib.h"
#include "syslib.h"

float side=3.75f;
float real=-0.5f;
float imag=0.0f;
float aspect;
float dist,re,im,ci,cr,zr,zi,a,b; //float
int key,counter,colr,tim1,tim2,lcolr;
int scrw,scrh,maxiter;

void main()
{
int x,y,lim;
scrw=320;  scrh=200; maxiter=254;
aspect=(float)scrw/(float)scrh;

lim=8.0f; key=0;

dist=side/(float)scrw;
re=real-side/2.0f;
im=imag-side/aspect/2.0f;
IOout(24,1);
Screen(0,15);
Cls();
tim1=Timer();
lcolr=0;
for (y=0; 2*y-1<scrh; y++)
{
	ci=im+(float)y*dist;	
	for (x=0; x<scrw; x++)
	{
		cr=re+(float)x*dist;
		zr=cr;
		zi=ci;
		counter=64;
		do {
			a=zr*zr;
			b=zi*zi;
			zi=2.0f*zr*zi+ci;
			zr=a+cr-b;
			counter--;
			//if (fcomp(fadd(a,b),lim)>0) break;
		} while (counter>1 && 8.0f>(a+b));
		colr=65-counter;
		if (lcolr!=colr) { Screen( 0, colr); lcolr=colr; }
		Plot(x,y,1);
		Plot(x,scrh-y,1);
	}
}
tim2=Timer();
tim1=tim2-tim1;
Screen(0,30);
PosYX(21,46); printf("%d",tim1);
while (key!=32)
{
	key=Inkey();
}
}


