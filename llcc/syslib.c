#include "syslib.h"

int RAND=197;

void Set_sprite(s,buf,en,x,y) int s,buf,en,x,y;
{
	int bank,ss;
	bank=s/14; ss=s % 14;
	IOout(SPRBASE+bank*4096+256*buf+ss*8,x);   
	IOout(SPRBASE+bank*4096+2+256*buf+ss*8,y); 
	IOout(SPRBASE+bank*4096+6+256*buf+ss*8,en); 
}

void Disable_sprite(s)  int s;
{
	int bank,ss;
	bank=s/14; ss=s%14;
	IOout(SPRBASE+bank*4096+6+256+ss*8,0);
	IOout(SPRBASE+bank*4096+6+ss*8,0);
}
	
void Set_sprite_data(s,sbuf,data,frame) int s,sbuf,frame; char data[]; 
{
	int bank,ss,j,adr;
	bank=s/14; ss=s%14; adr=SPRBASE+512+bank*4096+1792*sbuf+ss*128;
	for (j=0; j<128; j++)  {
			IOoutb(adr+j,data[j+frame*128]);
	}
}
