/*
** CLIB.H -- Definitions for Small-C library functions.
**
** Copyright 1983  L. E. Payne and J. E. Hendrix
*/

/*
** Misc parameters
*/
#define MAXFILES 12  /* maximum open files */
#define DOSEOF   26  /* DOS end-of-file byte */
#define ARCHIVE  32  /* file archive bit */

/*
** File status bits
*/
#define OPNBIT   1  /* open condition */
#define EOFBIT   2  /* end-of-file condition */
#define ERRBIT   4  /* error condition */

/*
** File positioning origins
*/
#define FROM_BEG  0  /* from beginning of file */
#define FROM_CUR  1  /* from current position */
#define FROM_END  2  /* from end of file */

/*
** Buffer usage codes
** NULL means the buffer is not used.
*/
#define EMPTY     1  /* buffer is currently empty */
#define IN        2  /* buffer is currently holding input data */
#define OUT       3  /* buffer is currently holding output data */

/*
** ASCII characters
*/
#define ABORT    3
#define RUB      8
#define PAUSE   19
#define WIPE    24
#define DEL    127

int putchar(char c);
char *strcpy(char *s, char *t);
int argbase();
int argcnt();
int ftoi(float f);
float itof(int i);
int _fopen(char *fn, char *mode);
int fopen(char *fn, char *mode);
int fseek(int fd, int pos);
int fsize(int fd);
int fseek(int fd,int pos); /* A0=0 success, A0=1 file not open, A0=2 read only file smaller than pos */
int ftell(int fd);
_alloc(int size,int init);
int _fputc(char c, int fd);

