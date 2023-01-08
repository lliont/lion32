#include "stdio.h"
#include "clib.h"

int _fstatus[5+MAXFILES]= {OPNBIT, OPNBIT, OPNBIT, OPNBIT, OPNBIT};
int _fcnt;
int _cnt=0;             /* arg count for main */
char *_vec[12];           /* arg vectors for main */
char clbuf[81];
char *_memptr;
char *cmdlbuf;
char _arg1[]="*";
char fnameb[14];
const int FMEMORG = 18532; 
const int FMEMLOWL = 18538;
const int ftab = 18600;

abort() {
   return 0;
}

/*
** Parse command line and setup argc and argv.
*/
void parse() {
  int i,j;
  for (i=1;i<12;i++) {_vec[i]=NULL; }
  i=0; j=0;
  while (cmdlbuf[i]!=CR && cmdlbuf[i]!=' ') i++;
  //while (cmdlbuf[i]==' ') i++;
  while (cmdlbuf[i]!=CR && i<80) { clbuf[j]=cmdlbuf[i]; j++; i++; }
  clbuf[++j]=0;
  cmdlbuf=clbuf;
  _vec[0]= clbuf;       /* first arg = "*" */
  while (*cmdlbuf!=0) {
    if(isspace(*cmdlbuf)) {++cmdlbuf; continue;}
    if(_cnt < 12) _vec[_cnt++] = cmdlbuf;
    while(*cmdlbuf!=0) {
      if(isspace(*cmdlbuf)) {*cmdlbuf = NULL; ++cmdlbuf; break;}
      ++cmdlbuf;
      }
    }
  }

int _main()
{
	parse();
	return main(_cnt, _vec);
}

/*
** Cleared-memory allocation of n items of size bytes.
** n     = Number of items to allocate space for.
** size  = Size of the items in bytes.
** Returns the address of the allocated block,
** else NULL for failure.
*/
calloc(n, size) int n, size; {
  return (_alloc(n*size, YES));
  }
  
avail(int abort) {
  char x;
  if(&x < _memptr) {
    if(abort) exit(1);
    return (0);
    }
  return (&x - _memptr);
  }
  
/*
** free(ptr) - Free previously allocated memory block.
** Memory must be freed in the reverse order from which
** it was allocated.
** ptr    = Value returned by calloc() or malloc().
** Returns ptr if successful or NULL otherwise.
*/
free(ptr) char *ptr; {
int *fmorg, *fmeml;
	fmorg = (int *) FMEMORG;
	fmeml = (int *) FMEMLOWL;
   if ((int) ptr< *fmorg && (int) ptr>*fmeml)
   {
	   return _free(ptr);
   }  
   else return NULL;
}

void fix_fname(fnp) char *fnp; {
	int i,j;
	i=0; 
	while ((fnp[i]!='.') && (i<11)) i++;
	if (fnp[i]=='.') {
		for (j=2;j>-1;j--) if (fnp[i+1+j]>=' ') fnp[8+j]=fnp[i+1+j]; else fnp[8+j]=' '; 
		for (j=0;j<(8-i);j++) fnp[i+j]=' ';  
	}
	fnp[11]=0;
} 

/*
** copy t to s 
*/
char *strcpy(s, t) char *s, *t; {
  char *d;
  d = s;
  while (*s++ = *t++) ;
  return (d);
  }


int fopen(fn, mode) char *fn, *mode; {
	strncpy(fnameb,fn,13);
	fix_fname(fnameb);
	return	(_fopen(fnameb,mode));
}

/*
** Close fd 
** Entry: fd = file descriptor for file to be closed.
** Returns NULL for success, otherwise ERR
*/
fclose(fd) int fd; {
  _fclose(fd);
  if (fd>4) { fd=5+(fd-ftab)/34; 
  return (_fstatus[fd] = NULL); } else return 0;
  }


/*
** Test for end-of-file status.
** Entry: fd = file descriptor
** Returns non-zero if fd is at eof, else zero.
*/
feof(fd) int fd; {
  //if (fd>4) fd=5+(fd-ftab)/34;
  //return (_fstatus[fd] & EOFBIT);
  if (ftell(fd)>=fsize(fd)) return 1; else return 0;
  }  
  
ferror(fd) int fd; {
  if (fd>4) fd=5+(fd-ftab)/34;
  return (_fstatus[fd] & ERRBIT);
  }
  
int read(int fd,char *buf,int n);

/*
** Item-stream read from fd.
** Entry: buf = address of target buffer
**         sz = size of items in bytes
**          n = number of items to read
**         fd = file descriptor
** Returns a count of the items actually read.
** Use feof() and ferror() to determine file status.
*/
fread(buf, sz, n, fd) char *buf; unsigned sz, n, fd; {
  return (read(fd, buf, n*sz)/sz);
  }

/*
** Binary-stream read from fd.
** Entry:  fd = file descriptor
**        buf = address of target buffer
**          n = number of bytes to read
** Returns a count of the bytes actually read.
** Use feof() and ferror() to determine file status.
*/


iscons(fd) int fd; {
	if (fd<5) return 1; else return 0;
}

char *_gets(str, size, fd, nl) char *str; int size, fd, nl; {
  int backup; char *next;
  next = str;
  while(--size > 0) {
    switch (*next = fgetc(fd)) {
      case  EOF: *next = NULL;
                 if(next == str) return (NULL);
                 return (str);
      case '\n': *(next + nl) = NULL;
                 return (str);
      /* case  RUB: if(next > str) backup = 1; else backup = 0;
                 goto backout;
      case WIPE: backup = next - str;
        backout: if(iscons(fd)) {
                   ++size;
                   while(backup--) {
                     fputs("\b \b", stderr);
                     --next; ++size;
                     }
                   continue;
                   } */
        default: ++next;
      }
    }
  *next = NULL;
  return (str);
  }
  
/*
** Gets an entire string (including its newline
** terminator) or size-1 characters, whichever comes
** first. The input is terminated by a null character.
** Entry: str  = Pointer to destination buffer.
**        size = Size of the destination buffer.
**        fd   = File descriptor of pertinent file.
** Returns str on success, else NULL.
*/
char* fgets(str, size, fd) char *str; unsigned size, fd; {
  return ((char *) _gets(str, size, fd, 1));
  }

/*
** Gets an entire string from stdin (excluding its newline
** terminator) or size-1 characters, whichever comes
** first. The input is terminated by a null character.
** The user buffer must be large enough to hold the data.
** Entry: str  = Pointer to destination buffer.
** Returns str on success, else NULL.
*/
char *gets(str) char *str; {
  return ((char *) _gets(str, 32767, stdin, 0));
  }
  

/*
** Character-stream output of a character to fd.
** Entry: ch = Character to write.
**        fd = File descriptor of perinent file.
** Returns character written on success, else EOF.
*/
int fputc(ch, fd) char ch; int fd; {
/*   switch(ch) {
    case  EOF: _write(DOSEOF, fd); break;
    case '\n': _write(CR, fd); _write(LF, fd); break;
      default: _write(ch, fd);
    }
  if(_status[fd] & ERRBIT) return (EOF); */
  if (fd==stdout) {
	  if (ch=='\n') putchar(13); else putchar(ch);
	  return (ch);
  } else {
	return(_fputc(ch, fd));
  }
 }
 
 /*
** Write a string to fd. 
** Entry: string = Pointer to null-terminated string.
**        fd     = File descriptor of pertinent file.
*/
void fputs(string, fd) char *string; int fd; {
  while(*string) {fputc(*string, fd); string++  ; }
  }
  
/*
** Write string to standard output. 
*/
void puts(string) char *string; {
  //fputs(string, stdout);
  while(*string) fputc(*string++, stdout) ;
  //while(*string) { putchar(*string); string++; }
  //putchar(13);
  }
 
 sign(nbr)  int nbr;  {
  if(nbr > 0)  return 1;
  if(nbr == 0) return 0;
  return -1;
  }
  
 
 int strlen(char *string )
{
	int counter ;
	counter = 0 ;
	while( *string++ )
		counter++ ;
	return counter ;
}


/*
** return <0,   0,  >0 a_ording to
**       s<t, s=t, s>t
*/
strcmp(s, t) char *s, *t; {
  while(*s == *t) {
    if(*s == 0) return (0);
    ++s; ++t;
    }
  return (*s - *t);
  }

/*
** return pointer to 1st occurrence of c in str, else 0
*/
char *strchr(str, c) char *str, c; {
  while(*str) {
    if(*str == c) return (str);
    ++str;
    }
  return (0);
  }

/*
** concatenate t to end of s 
** s must be large enough
*/
char *strcat(s, t) char *s, *t; {
  char *d;
  d = s;
  --s;
  while (*++s) ;
  while (*s++ = *t++) ;
  return (d);
  }
  
  /*
** reverse string in place 
*/
void reverse(s) char *s; {
  char *j;
  int c;
  j = s + strlen(s) - 1;
  while(s < j) {
    c = *s;
    *s++ = *j;
    *j-- = c;
    }
  }
  
/*
** return ASCII equivalent of c
*/
toascii(c) int c; {
  return (c);
  }

/*
** strrchr(s,c) - Search s for rightmost occurrance of c.
** s      = Pointer to string to be searched.
** c      = Character to search for.
** Returns pointer to rightmost c or NULL.
*/
char *strrchr(s, c) char *s, c; {
  char *ptr;
  ptr = 0;
  while(*s) {
    if(*s==c) ptr = s;
    ++s;
    }
  return (ptr);
  }

/*
** copy n characters from sour to dest (null padding)
*/
char *strncpy(dest, sour, n) char *dest, *sour; int n; {
  char *d;
  d = dest;
  while(n-- > 0) {
    if(*d++ = *sour++) continue;
    while(n-- > 0) *d++ = 0;
    }
  *d = 0;
  return (dest);
  }

/*
** strncmp(s,t,n) - Compares two strings for at most n
**                  characters and returns an integer
**                  >0, =0, or <0 as s is >t, =t, or <t.
*/
strncmp(s, t, n) char *s, *t; int n; {
  while(n && *s==*t) {
    if (*s == 0) return (0);
    ++s; ++t; --n;
    }
  if(n) return (*s - *t);
  return (0);
  }

/*
** concatenate n bytes max from t to end of s 
** s must be large enough
*/
char *strncat(s, t, n) char *s, *t; int n; {
  char *d;
  d = s;
  --s;
  while(*++s) ;
  while(n--) {
    if(*s++ = *t++) continue;
    return(d);
    }
  *s = 0;
  return(d);
  }

/*
** itoa(n,s) - Convert n to characters in s 
*/
void itoa(n, s) char *s; int n; {
  int sign;
  char *ptr;
  ptr = s;
  if ((sign = n) < 0) n = -n;
  do {
    *ptr++ = n % 10 + '0';
    } while ((n = n / 10) > 0);
  if (sign < 0) *ptr++ = '-';
  *ptr = '\0';
  reverse(s);
  }
  
/*
** itoab(n,s,b) - Convert "unsigned" n to characters in s using base b.
**                NOTE: This is a non-standard function.
*/
void itoab(n, s, b) int n; char *s; int b; {
  char *ptr;
  int lowbit;
  ptr = s;
  b >>= 1;
  do {
    lowbit = n & 1;
    n = (n >> 1);
    *ptr = ((n % b) << 1) + lowbit;
    if(*ptr < 10) *ptr += '0'; else *ptr += 55;
    ++ptr;
    } while(n /= b);
  *ptr = 0;
  reverse (s);
  }
  
/* #define FRAC_LEN 23
#define EXP_LEN  8  
#define SIG_LEN  1
#define BIAS 127
#define BIT_FLOAT 32
  
float itof(int x)
{
	float fx = 0.0;
    int sig_area = 0;
	unsigned int frac_area;
	unsigned int bit_num;
	int frac_width; int exp_area,result;

	if (x == 0)     
		return fx;
    else if (x < 0)
    {
        x = -x;
    	sig_area = 1;
    }    
    	frac_area = x;	
	 bit_num = 0;  
    while (x != 1)
    {
    	int temp = (unsigned int)x>>1;
    	x = temp;
    	bit_num++;
    }
    frac_width = BIT_FLOAT - FRAC_LEN;         
    frac_area = frac_area<<(BIT_FLOAT - bit_num);    
    frac_area = frac_area>>frac_width; 
    exp_area = 0;
    exp_area = BIAS + bit_num;
    exp_area = exp_area<<FRAC_LEN;
    sig_area = sig_area<<(BIT_FLOAT - SIG_LEN);
    result = 0;
    result |= exp_area;
    result |= frac_area;
    result |= sig_area;
    fx = *(float*)&result;
    return fx; 
}*/

 char *ftoa(x, p, n) char *p; int x;  int n; {
    char *s;
    unsigned decimals; 
    int units,i,di10;
	float d10;  
	union fc {
		float fx;
		int xf;
	} f;
		
	f.xf=x;
	for (i=0;i<24;i++) p[i]=0;
	s	= p + 20; // go to end of buffer
	d10=1.0; di10=1; 
	for (i=0; i<n; i++) {d10*=10.0; di10*=10;}
    if (f.fx < 0) { 
        decimals = ((int) (-d10*f.fx)) % di10; 
        units = (int) -f.fx;
    } else { 
        decimals = ((int) (d10*f.fx)) % di10;
        units = (int) f.fx;
    }
    *--s = (decimals % 10) + '0';
    for (i=0; i<n-1; i++) {
	decimals = decimals / 10; // repeat for as many decimal places as you need
    *--s = (decimals % 10) + '0';
	}
    *--s = '.';
	do {
        *--s = (units % 10) + '0';
        units=units/10;
    } while (units > 0);
    if (f.fx < 0) *--s = '-'; // unary minus sign for negative numbers
    return  s;
}


/*
** fprintf(fd, ctlstring, arg, arg, ...) - Formatted print.
** Operates as described by Kernighan & Ritchie.
** c, d, o, s, u, and x specifications are supported.
*/
int fprintf(fd,argc) int argc; {
  int argb = argbase();
  return(_print(fd, argb)); 
  }

/*
** printf(ctlstring, arg, arg, ...) - Formatted print.
** Operates as described by Kernighan & Ritchie.
** c, d, o, s, u, and x specifications are supported.
*/
int printf(argc) int argc; {
  int argb = argbase();
  //int argn = argcnt();
  return(_print(stdout, argb)); 
  }

char _buf_str[24]; 

int _print(fd, nxtarg ) int fd; int *nxtarg;
 {
  int  arg, left, pad, cc, len, maxchr, width;
  char *ctl, *sptr; 
  cc = 0;                                         
  ctl = (char *) *nxtarg; nxtarg--;
  while(*ctl!=0 ) {
    if(*ctl!='%') {fputc(*ctl++, fd); ++cc; continue;}
    else ++ctl;
    if(*ctl=='%') {fputc(*ctl++, fd); ++cc; continue;}
    if(*ctl=='-') {left = 1; ++ctl;} else left = 0;       
    if(*ctl=='0') pad = '0'; else pad = ' ';           
    if(isdigit(*ctl)) {
      width = atoi(ctl++);
      while(isdigit(*ctl)) ++ctl;
      }
    else width = 0;
    if(*ctl=='.') {            
      maxchr = atoi(++ctl);
      while(isdigit(*ctl)) ++ctl;
      }
    else maxchr = 0;
    arg = *nxtarg--; //argn--;
    sptr = _buf_str;
	
    switch(*ctl++) {
      case 'c': _buf_str[0] =  arg; _buf_str[1] = 0; break;
      case 's': sptr = (char *) arg;    break;
      case 'd': itoa(arg,_buf_str);     break;
	case 'f': if (maxchr) {sptr=ftoa(arg,_buf_str,maxchr); maxchr=width;} else sptr=ftoa(arg,_buf_str,3);  break;
      //case 'b': itoab(arg,_buf_str,2);  break;
      case 'o': itoab(arg,_buf_str,8);  break;
      case 'u': itoab(arg,_buf_str,10); break;
      case 'x': itoab(arg,_buf_str,16); break;
      default:  return (cc);
      }
    len = strlen(sptr);
    if(maxchr && maxchr<len) len = maxchr;
    if(width>len) width = width - len; else width = 0; 
    if(!left) while(width--) {fputc(pad,fd); ++cc;}
    while(len--) {fputc(*sptr++,fd); ++cc; }
    if(left) while(width--) {fputc(pad,fd); ++cc;}  
    }
  return(cc);
  }
  
/*
** utoi -- convert unsigned decimal string to integer nbr
**          returns field size, else ERR on error
*/
utoi(decstr, nbr)  char *decstr;  int *nbr;  {
  int d,t; d=0;
  *nbr=0;
  while((*decstr>='0')&(*decstr<='9')) {
    t=*nbr;t=(10*t) + (*decstr++ - '0');
    if ((t>=0)&(*nbr<0)) return ERR;
    d++; *nbr=t;
    }
  return d;
  }
  
int uget=-1;
  
void ungetc(ch,fd) int ch; int fd;{
	uget=ch;
}  
  
char fgetc(fd) int fd; {
	char bch;
	if (fd==stdin) {
		if (uget==-1) return(getkey()); else { bch=uget; uget=-1; return(bch); }
	} else
	{
		return(_fgetc(fd));
	}
}
  
/*
** fscanf(fd, ctlstring, arg, arg, ...) - Formatted read.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
fscanf(fd,argc) int argc; {
	int argb = argbase();
	return (_scan(fd, argb));
  }

/*
** scanf(ctlstring, arg, arg, ...) - Formatted read.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
scanf(argc) int argc; {
	int argb = argbase();
	return (_scan(stdin, argb));
  }
  
_scan(fd,nxtarg) int fd, *nxtarg; {
  char *carg, *ctl;
  int u;
  int  *narg, wast, ac, width, ch, cnv, base, ovfl, sign;
  ac = 0;
  ctl = (char *) *nxtarg--;
  while(*ctl) {
    if(isspace(*ctl)) {++ctl; continue;}
    if(*ctl++ != '%') continue;
    if(*ctl == '*') {narg = &wast;  carg =(char*) &wast; ++ctl;}
    else           {  narg =(int *) *nxtarg--; carg =(char *) *nxtarg--; }
    ctl += utoi(ctl, &width);
    if(!width) width = 32767;
    if(!(cnv = *ctl++)) break;
    while(isspace(ch = fgetc(fd))) ;
    if(ch == EOF) {if(ac) break; else return(EOF);}
    ungetc(ch,fd);
    switch(cnv) {
      case 'c':
        *carg = fgetc(fd);
        break;
      case 's':
        while(width--) {
          if((*carg = fgetc(fd)) == EOF) break;
          if(isspace(*carg)) break;
          if(carg != (char *) &wast) ++carg;
          }
        *carg = 0;
        break;
      default:
        switch(cnv) {
          case 'b': base =  2; sign = 1; ovfl = 32767; break;
          case 'd': base = 10; sign = 0; ovfl =  32767; break;
          case 'o': base =  8; sign = 1; ovfl =  32767; break;
          case 'u': base = 10; sign = 1; ovfl =  32767; break;
          case 'x': base = 16; sign = 1; ovfl =  32767; break;
          default:  return (ac);
          }
        *narg = u = 0;
        while(width-- && !isspace(ch=fgetc(fd)) && ch!=EOF) {
          if(!sign)
            if(ch == '-') {sign = -1; continue;}
            else sign = 1;
          if(ch < '0') return (ac);
          if(ch >= 'a')      ch -= 87;
          else if(ch >= 'A') ch -= 55;
          else               ch -= '0';
          if(ch >= base || u > ovfl) return (ac);
          u = u * base + ch;
          }
        *narg = sign * u;
      }
    ++ac;                          
    }
  return (ac);
  }  
  
/*
** return 'true' if c is an ASCII character (0-127)
*/
int isascii(c) int c; {
  return (c < 128);
  }
  
/*
** atoi(s) - convert s to integer.
*/
int atoi(s) char *s; {
  int sign, n;
  while(isspace(*s)) ++s;
  sign = 1;
  switch(*s) {
    case '-': sign = -1;
    case '+': ++s;
    }
  n = 0;
  while(isdigit(*s)) n = 10 * n + *s++ - '0';
  return (sign * n);
  }
  
#define ALNUM     1
#define ALPHA     2
#define CNTRL     4
#define DIGIT     8
#define GRAPH    16
#define LOWER    32
#define PRINT    64
#define PUNCT   128
#define BLANK   256
#define UPPER   512
#define XDIGIT 1024

unsigned char _is[128] = {
 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04,
 0x40, 0xD0, 0xD0, 0xD0, 0xD0, 0xD0, 0xD0, 0xD0,
 0xD0, 0xD0, 0xD0, 0xD0, 0xD0, 0xD0, 0xD0, 0xD0,
 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59,
 0x59, 0x59, 0xD0, 0xD0, 0xD0, 0xD0, 0xD0, 0xD0,
 0xD0, 0x53, 0x53, 0x53, 0x53, 0x53, 0x53, 0x53,
 0x53, 0x53, 0x53, 0x53, 0x53, 0x53, 0x53, 0x53,
 0x53, 0x53, 0x53, 0x53, 0x53, 0x53, 0x53, 0x53,
 0x53, 0x53, 0x53, 0xD0, 0xD0, 0xD0, 0xD0, 0xD0,
 0xD0, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73,
 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73,
 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73, 0x73,
 0x73, 0x73, 0x73, 0xD0, 0xD0, 0xD0, 0xD0, 0x04
 };
  
isalnum (c) char c; {return (_is[c] & ALNUM );} /* 'a'-'z', 'A'-'Z', '0'-'9' */
isalpha (c) char c; {return (_is[c] & ALPHA );} /* 'a'-'z', 'A'-'Z' */
iscntrl (c) char c; {return (_is[c] & CNTRL );} /* 0-31, 127 */
isdigit (c) char c; {return (_is[c] & DIGIT );} /* '0'-'9' */
isgraph (c) char c; {return (_is[c] & GRAPH );} /* '!'-'~' */
islower (c) char c; {return (_is[c] & LOWER );} /* 'a'-'z' */
isprint (c) char c; {return (_is[c] & PRINT );} /* ' '-'~' */
ispunct (c) char c; {return (_is[c] & PUNCT );} /* !alnum && !cntrl && !space */
isspace (c) char c; {return ( c==' ' || c==13 || c==10 || c==9 );} /* HT, LF, VT, FF, CR, ' ' */
isupper (c) int c; {return (c>='A' && c<='Z');}  /* 'A'-'Z' */
isxdigit(c) int c; {return ((c>='0' && c<='9') || (c>='a' && c<='f') || (c>='A' && c<='F'));} /* '0'-'9', 'a'-'f', 'A'-'F' */ 
  

