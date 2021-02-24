import net.mikekohn.java_grinder.Lionsys;

public class trig
{
   public static String strMsg = "Hello Lion from JAVA";

  static float r,f1,f2;
  static int i,x,y;
  
  
  static public void main()
  {	
		Lionsys.screen( 0, 63);
		Lionsys.cls();
		r=-3.14159f;
		do
		{
			f1=100f+Lionsys.sin(r)*50f;
			f2=100f-Lionsys.cos(r)*50f;
			Lionsys.plot((int)f1,(int)f2,1);
			r=r+0.01f;
		} while (r<3.14159f);
  }
}
