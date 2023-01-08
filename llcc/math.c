#include "math.h"

float trunc(float f) {
	int v=(int) f;
	return (float) v;
}

float round(float f) {
   int v=(int) (f+0.5f);
	return (float) v; 
}

float fmod(float f, float mod)
{
    return (f - trunc(f/mod)*mod);
}

float sin(float f)
{
  return _sin(fmod(f,2*PI));
}

float cos(float f)
{
  return _sin(PI/2.0f-fmod(f,2*PI));
}

float log2(float x)  // compute log2(x) by reducing x to [0.75, 1.5)
{
	//Copyright (C) 2011 Paul Mineiro  
    // a*(x-1)^2 + b*(x-1) approximates log2(x) when 0.75 <= x < 1.5
    const float a =  -.6296735;    //$bf21, $3248
    const float b =   1.466967;    //$3fbb, $c593
    float signif, fexp;
    int exp;
    float lg2;
    union { float f; unsigned int i; } ux1, ux2;
    int greater; // really a boolean 

    // get exponent
    ux1.f = x;
    exp = (ux1.i & 0x7F800000) >> 23; 
    // actual exponent is exp-127, will subtract 127 later

    greater = ux1.i & 0x00400000;  // true if signif > 1.5
    if (greater) {
        // signif >= 1.5 so need to divide by 2.  Accomplish this by 
        // stuffing exp = 126 which corresponds to an exponent of -1 
        ux2.i = (ux1.i & 0x007FFFFF) | 0x3f000000;
        signif = ux2.f;
        fexp = exp - 126;    // 126 instead of 127 compensates for division by 2
    } else {
        // get signif by stuffing exp = 127 which corresponds to an exponent of 0
        ux2.i = (ux1.i & 0x007FFFFF) | 0x3f800000;
        signif = ux2.f;
        fexp = exp - 127;
        
    }
	signif = signif - 1.0;                    
    lg2 = fexp + a*signif*signif + b*signif;  
    return(lg2);
}

float log (float x)
{//Copyright (C) 2011 Paul Mineiro  
  return 0.69314718f * log2 (x);
}

float fastpow2 (float p)
{ //Copyright (C) 2011 Paul Mineiro
  float offset = (p < 0) ? 1.0f : 0.0f;
  float clipp = (p < -126) ? -126.0f : p;
  int w = clipp;
  float z = clipp - w + offset;
  union { unsigned int  i; float f; } v;
  v.i =  (unsigned int) ( (1 << 23) * (clipp + 121.2740575f + 27.7280233f / (4.84252568f - z) - 1.49012907f * z) ) ;

  return v.f;
}

float pow (float x, float p)
{//Copyright (C) 2011 Paul Mineiro  
  return fastpow2 (p * log2 (x));
}

float fabs(float f){
	return (float) ( (int) f & 0x7FFFFFFF );  
}


float atan( float x )
{
    static const unsigned int sign_mask = 0x80000000;
    static const float b = 0.596227f;

    // Extract the sign bit
    int ux_s  = sign_mask & (int)x;

    // Calculate the arctangent in the first quadrant
    float bx_a = fabs( b * x );
    float num = bx_a + x * x;
    float atan_1q = num / ( 1.f + bx_a + num );

    // Restore the sign bit
    int atan_2q = ux_s | (int)atan_1q;
    return ((float)atan_2q)*PI/2.0f;
}

// Approximates atan2(y, x) normalized to the [0,4) range
// with a maximum error of 0.1620 degrees

float atan2( float y, float x )
{
    static const unsigned int sign_mask = 0x80000000;
    static const float b = 0.596227f;

    // Extract the sign bits
    int ux_s  = sign_mask & (int)x;
    int uy_s  = sign_mask & (int)y;

    // Determine the quadrant offset
    float q = (float)( ( ~ux_s & uy_s ) >> 29 | ux_s >> 30 ); 

    // Calculate the arctangent in the first quadrant
    float bxy_a = fabs( b * x * y );
    float num = bxy_a + y * y;
    float atan_1q =  num / ( x * x + bxy_a + num + (float).000001 );

    // Translate it to the proper quadrant
    int uatan_2q = (ux_s ^ uy_s) | (int)atan_1q;
    return (q + (float)uatan_2q)*PI/2.0f;
} 
