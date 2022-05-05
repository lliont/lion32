#include "stdio.h"
#include "clib.h"
#include "syslib.h"
#include "float.h"


int side; //=3.75f;
int real; //=-0.5f;
int imag; //=0.0f;
int aspect;
int dist,re,im,ci,cr,zr,zi,a,b; //float
int key,counter,colr,tim1,tim2,lcolr;
int scrw,scrh,maxiter;

main()
{
int x,y,lim;

scrw=320;  scrh=200; maxiter=254;
aspect=fdiv(itof(scrw),itof(scrh));
side=stof("3.5");
real=stof("-0.5");
imag=stof("0.0");  
lim=stof("8.0");
key=0;

	dist=fdiv(side,itof(scrw));
	re=fsub(real,fdiv(side,TWO));
	im=fsub(imag,fdiv(fdiv(side,aspect),TWO));
	IOout(24,1);
	Screen(0,15);
	Cls();
	tim1=Timer();
	lcolr=0;
	for (y=0; 2*y-1<scrh; y++)
	{
		ci=fadd(im,fmult(itof(y),dist));
		
		for (x=0; x<scrw; x++)
		{
			cr=fadd(re,fmult(itof(x),dist));
			zr=cr;
			zi=ci;
			counter=254;
			do {
				a=fmult(zr,zr);
				b=fmult(zi,zi);
				zi=fadd(fmult(TWO,fmult(zr,zi)),ci);
				zr=fsub(fadd(a,cr),b);
				counter--;
				//if (fcomp(fadd(a,b),lim)>0) break;
			} while (counter>1 && fcomp(fadd(a,b),lim)<0);
			colr=255-counter;
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

