#include "stdio.h"

char str[601],fn[12];



main (int argc, int *argv)
{
	char c;
	char *fp;
	int i,cc;
	cc=0;
	fp=0;
	i=getarg(2,fn,11, argc, argv);
	
	if (i!=NULL) {
		fix_fname(fn);
		printf("\nFile: %s\n",fn);
		fp=fopen(fn,"r");
	}	
	if (fp<=0) { 
		printf(" Error Opening File: %s\n",fn); 
	} 
	else 
	{
		printf("\n");
		do
		{
			cc=read(fp,str,600);
			str[cc]=0;
			for (i=0;i<cc;i++) putchar(str[i]);
			c=getkey();
		} while (cc==600);
		printf("\n");
		fclose(fp);
	}
}
