#include "stdio.h"
#include "clib.h"
#include "syslib.h"

//char fn[12];
//char *buf;

main (int argc, int *argv)
{
	int i,t1,t2,k;
	
	Screen(1,15);
	Cls();
	t1=Timer();
	for (i=0; i<10000; i++) {
		k=i%10;
		PosYX(29, k*5);
		printf("%d",i);
		if (k==9) Scroll_up();
        }
	t2=Timer()-t1;
	k=Inkey();
	PosYX(29, 10);
	printf("%d  %d", t2, k);
	Sound(0,1000,5);
	do {} while (Isplaying(0));
}