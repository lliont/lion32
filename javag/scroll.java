import net.mikekohn.java_grinder.Lionsys;

public class scroll
{
	static byte pg[];
	
	static void main()
	{
		int i; int j; int tim1,tim2;
		Lionsys.out(24,1);
		tim1=Lionsys.timer();
		//Lionsys.cls();
		Lionsys.print_str(14,10,"*** SMOOTH VERTICAL SCROLL TEST ***"); 
		for (i=0; i<700; i++) {
			Lionsys.vscroll(10,180,10,140*2,1);
			//for (j=0; j<1200; j++) { int k=i+1; }
		}
		for (i=0; i<700; i++) {
			Lionsys.vscroll(10,180,10,140*2,-1);
			//for (j=0; j<1200; j++) { int k=i+1; }
		}
		//Lionsys.cls();
		Lionsys.print_str(14,11,"*** SMOOTH HORIZONTAL SCROLL TEST ***"); 
		for (i=1; i<700; i++) {
			Lionsys.hscroll(10,180,10,140*2,1);
			//for (j=0; j<1000; j++) { int k=i+1; }
		}
		for (i=1; i<700; i++) {
			Lionsys.hscroll(10,180,10,140*2,-1);
			//for (j=0; j<1000; j++) { int k=i+1; }
		}
		for (i=0; i<720; i++) {
			Lionsys.vscroll(10,180,10,80*2,1);
			Lionsys.vscroll(10,180,171,60*2,-1);
			//for (j=0; j<1200; j++) { int k=i+1; }
		}
		int key=0;
		Lionsys.print_str(16,16,"*** DONE! ***"); 
		tim2=Lionsys.timer();
		tim1=tim2-tim1;
		Lionsys.print_num(20,46,tim1);
		while (key!=' ')
		{
			key=Lionsys.inkey();
		}
	}
}
