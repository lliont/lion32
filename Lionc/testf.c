#include "stdio.h"
#include "clib.h"
#include "float.h"

char s[20]="Hello              ";

main()
{
	int f1,f2,f3;
	f1=stof("2");
	f1=fneg(f1);
	f2=TEN;
	f3=fadd(f2,f1);
	ftos(s,f3);
	printf(s);
	printf("\n");
}
