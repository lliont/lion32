#define Vbase  32768
#define XYbase 98304
#define PCMbase 98304
#define _XY 0x4868
#define SCOL 0x4847
#define FCOL 0x485d
#define BCOL 0x485c
#define MAXMEM 0x4858
#define FMEMORG 0x4864
#define PLOTM 0x484E
#define CIRCX 0x484A
#define CIRCY 0x484C
#define SPRBASE 16384

#asm
PLOTM EQU $484E
COLTBL EQU	61152
SPRBASE EQU 16384
RAND DD 197
#endasm
