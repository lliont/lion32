#include "stdio.h"
#include "clib.h"
#include "syslib.h"

char fn[12];
char *buf;

main (int argc, int *argv)
{
	char c;
	char *fp;
    char *pcmbuf;
	int i,cc;
	cc=0;
	fp=0;
	i=getarg(2,fn,11, argc, argv);
	pcmbuf=PCMbase;
	if (i!=NULL) {
		printf("\nFile: %s\n",fn);
		fix_fname(fn);
		fp=fopen(fn,"r");
	}	
	if (fp<=0) { 
		printf(" Error Opening File: %s\n",fn); 
	} 
	else 
	{
		buf=calloc(8192);
		printf("\n");
		for (i=0; i<8192; i++) IOoutb(pcmbuf+i,0);
		cc=read(fp,buf,8192);
		while (cc>0)
		{
			IOout(30,2);
			MEMtoIO(buf,pcmbuf,cc);
			IOout(30,3);
			cc=read(fp,buf,8192);
			do { } while ((IOin(9) & 8)!=0);
		} 
		IOout(30,2);
		free(buf);
		fclose(fp);
	}
}