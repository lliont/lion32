#include "stdio.h"

char str[513],fn[12];


void main (int argc, char *argv[])
{
	char c;
	int fp;
	int i,cc,cr;
	cc=0;
	fp=0;
	
	if (argc>0) {
		strncpy(fn,argv[0],11);
		printf("\nFile: %s\n",fn);
		fp=fopen(fn,"r");
	}	
	if ( fp<=0) { 
		printf(" Error Opening File: %s\n",fn); 
	} 
	else 
	{ 
		cr=1;
		do	{
			cc=read(fp,str,512);
			for (i=0;i<(cc);i++) {
				putchar(str[i]);
				if (str[i]=='\n') cr++;
				if (cr%22==0) {c=getkey(); cr++;}
				}
		} while (cc==512 && c!=27);
		printf("\n");
		fclose(fp);
	}
}

