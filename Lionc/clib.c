#include "stdio.h"
#include "clib.h"

int
  _cnt=1,             /* arg count for main */
  _vec[12];           /* arg vectors for main */
char cmdlbuf[81];

int _fstatus[5+MAXFILES]= {OPNBIT, OPNBIT, OPNBIT, OPNBIT, OPNBIT};
int _fcnt;

char
 *_memptr,           /* pointer to free memory. */
  _arg1[]="*";       /* first arg for main */
  
#define ftab = 18600
#define FMEMORG = 18532
#define FMEMLOWL = 18538

_main() {
  int fd;
  parse();
  //for(fd = 0; fd < MAXFILES; ++fd) auxbuf(fd, 32);
  //if(!isatty(stdin))  _bufuse[stdin]  = EMPTY;
  //if(!isatty(stdout)) _bufuse[stdout] = EMPTY;
  main(_cnt, _vec);
  exit(0);
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
fmorg=FMEMORG;
fmeml=FMEMLOWL;
   if (ptr<*fmorg && ptr>*fmeml)
   {
	   #asm
	   MOV.D A2,8(A6)
	   MOV.D A1,-4(A6)
	   SUB.D A1,A2
	   MOVI	 A0,8
	   INT   5
	   MOV.D A1,8(A6)
	   #endasm
   }   else return NULL;
}

/*
** Get command line argument. 
** Entry: n    = Number of the argument.
**        s    = Destination string pointer.
**        size = Size of destination string.
**        argc = Argument count from main().
**        argv = Argument vector(s) from main().
** Returns number of characters moved on success,
** else EOF.
*/
getarg(n, s, size, argc, argv)
  int n; char *s; int size, argc, argv[]; {
  char *str;
  int i;
  if(n < 0 | n >= argc) {
    *s = NULL;
    return EOF;
    }
  i = 0;
  str=argv[n];
  while(i<size) {
    if((s[i]=str[i])==NULL) break;
    ++i;
    }
  s[i]=NULL;
  return i;
  }

/*
** Parse command line and setup argc and argv.
*/
parse() {
  char *ptr;
  int i;
  #asm
	MOV.D -4(A6),A7
  #endasm
  for (i=1;i<12;i++) {_vec[i]=NULL; cmdlbuf[i]=NULL; }
  i=0;
  while (ptr[i]!=CR && i<80) { cmdlbuf[i]=ptr[i]; i++; }
  cmdlbuf[++i]=0;
  ptr=cmdlbuf;
  _vec[0]=_arg1;       /* first arg = "*" */
  while (*ptr!=0) {
    if(isspace(*ptr)) {++ptr; continue;}
    if(_cnt < 12) _vec[_cnt++] = ptr;
    while(*ptr!=0) {
      if(isspace(*ptr)) {*ptr = NULL; ++ptr; break;}
      ++ptr;
      }
    }
  }

 
fix_fname(fnp) char *fnp; {
	int i,j;
	i=0; j=0;
	while ((fnp[i]!='.') && (i<11)) i++;
	if (fnp[i]=='.') {
		for (j=2;j>-1;j--) fnp[8+j]=fnp[i+1+j];
		for (j=0;j<(8-i);j++) fnp[i+j]=' ';  
	}
	fnp[11]=0;
}  

/* return file size */
fsize(fd) int fd; {
  #asm
  MOV.D A1,8(A6)
  MOV.D	A0,21
  INT 4
  MOV.D A1,A0
  #endasm
}

/* set file pos to pos */
/* A0=0 success, A0=1 file not open, A0=2 read only file smaller than pos */
fseek(fd,pos) int fd; int pos; {
  #asm
  MOV.D A1,12(A6)
  MOV.D A2,8(A6)
  MOV.D	A0,19
  INT 4
  MOV.D A1,A0
  #endasm
}

/* return file current pos */
ftell(fd) int fd; {
  #asm
  MOV.D A1,8(A6)
  MOV.D	A0,20
  INT 4
  MOV.D A1,A0
  #endasm
}
  
/*
** Close fd 
** Entry: fd = file descriptor for file to be closed.
** Returns NULL for success, otherwise ERR
*/
fclose(fd) int fd; {
  #asm
  MOV.D A1,8(A6)
  MOV.D	A0,17
  INT 4
  #endasm
  if (fd>4) { fd=5+(fd-ftab)/34; 
  return (_fstatus[fd] = NULL); } else return 0;
  }
  
/*
** Test for end-of-file status.
** Entry: fd = file descriptor
** Returns non-zero if fd is at eof, else zero.
*/
feof(fd) int fd; {
  if (fd>4) fd=5+(fd-ftab)/34;
  return (_fstatus[fd] & EOFBIT);
  }  
  
ferror(fd) int fd; {
  if (fd>4) fd=5+(fd-ftab)/34;
  return (_fstatus[fd] & ERRBIT);
  }
  
/*
** Binary-stream input of one byte from fd.
*/
_read(fd) int fd; {
  char ch;
  if (fd==stdin) { return(getkey()); } else
  {
	#asm
	MOV.D  A5,SP
	MOV.D  A1,16(A5)
	MOVI   A2,1
	MOV.D   A3,A6
	SUBI	A3,1
	MOV.D  A0,18
	INT    4
	MOVI   A1,0
	GADR   A3,__fcnt
	MOV.D  (A3),A0
	#endasm
	return(ch);
  }
  }

/*
** Item-stream read from fd.
** Entry: buf = address of target buffer
**         sz = size of items in bytes
**          n = number of items to read
**         fd = file descriptor
** Returns a count of the items actually read.
** Use feof() and ferror() to determine file status.
*/
fread(buf, sz, n, fd) unsigned char *buf; unsigned sz, n, fd; {
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
read(fd, buf, n) unsigned fd, n; unsigned char *buf; {
  unsigned cnt;
  cnt = 0;
  while(n--) {
    *buf++ = _read(fd);
    //if(_status[fd] & (ERRBIT | EOFBIT)) break;
	if(!_fcnt) break;
    ++cnt;
    }
  return (cnt);
  }
  

fopen(fn, mode) char *fn, *mode; {
  #asm
	MOV.D A5,SP
	MOV.D A1,12(A5)
    MOV.D A4,16(A5)
	MOV.D A0,16
	INT  4
	XCHG A1,A0
  #endasm
  }

_alloc(size,init) int size,init; {
//int ptr;
#asm
MOV.D A1,12(A6) 
MOVI A0,7
INT 5
MOV.D A1,A0
#endasm
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

/*
** fscanf(fd, ctlstring, arg, arg, ...) - Formatted read.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
fscanf(argc) int argc; {
  int *nxtarg;
  nxtarg = CCARGC() + &argc;
  return (_scan(*(--nxtarg), --nxtarg));
  }

/*
** scanf(ctlstring, arg, arg, ...) - Formatted read.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
scanf(argc) int argc; {
  return (_scan(stdin, CCARGC() + &argc - 1));
  }
  
getchar () {
	return (getkey());
}
  
int uget=-1;
//char chbuf;

fgetc(fd) int fd; {
	char bch;
	if (fd==stdin) {
		if (uget==-1) return(getkey()); else { bch=uget; uget=-1; return(bch); }
	} else
	{
	#asm
	MOV.D  A5,SP
	MOV.D  A1,16(A5)
	MOVI   A2,1
	MOV.D   A3,A6
	SUBI	A3,7
	MOV.D  A0,18
	INT    4
	#endasm
	//return(bch);
	}
  }
  
ungetc(ch,fd) int ch; int fd;{
	uget=ch;
}

/*
** _scan(fd, ctlstring, arg, arg, ...) - Formatted read.
** Called by fscanf() and scanf().
*/
_scan(fd,nxtarg) int fd, *nxtarg; {
  char *carg, *ctl;
  int u;
  int  *narg, wast, ac, width, ch, cnv, base, ovfl, sign;
  ac = 0;
  ctl = *nxtarg--;
  while(*ctl) {
    if(isspace(*ctl)) {++ctl; continue;}
    if(*ctl++ != '%') continue;
    if(*ctl == '*') {narg = carg = &wast; ++ctl;}
    else             narg = carg = *nxtarg--;
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
          if(carg != &wast) ++carg;
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
** xtoi -- convert hex string to integer nbr
**         returns field size, else ERR on error
*/
xtoi(hexstr, nbr) char *hexstr; int *nbr; {
  int d, b;  char *cp;
  d = *nbr = 0; cp = hexstr;
  while(*cp == '0') ++cp;
  while(1) {
    switch(*cp) {
      case '0': case '1': case '2':
      case '3': case '4': case '5':
      case '6': case '7': case '8':
      case '9':                     b=48; break;
      case 'A': case 'B': case 'C':
      case 'D': case 'E': case 'F': b=55; break;
      case 'a': case 'b': case 'c':
      case 'd': case 'e': case 'f': b=87; break;
       default: return (cp - hexstr);
      }
    if(d < 4) ++d; else return (ERR);
    *nbr = (*nbr << 4) + (*cp++ - b);
    }
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

/*
** return upper-case of c if it is lower-case, else c
*/
toupper(c) int c; {
  if(c<='z' && c>='a') return (c-32);
  return (c);
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
strrchr(s, c) char *s, c; {
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
strncpy(dest, sour, n) char *dest, *sour; int n; {
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
strncat(s, t, n) char *s, *t; int n; {
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
** return length of string s (fast version)
*/
strlen(s) char *s; {
  #asm
  MOV.D A1,-1
  MOV.D A5,8(A6)   
  MOV.B A0,(A5)
  ADDI A1,1
  ADDI A5,1
  OR.B A0,A0
  JRNZ -14
  #endasm
  }

/*
** copy t to s 
*/
strcpy(s, t) char *s, *t; {
  char *d;
  d = s;
  while (*s++ = *t++) ;
  return (d);
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
strchr(str, c) char *str, c; {
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
strcat(s, t) char *s, *t; {
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
reverse(s) char *s; {
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
** Write a string to fd. 
** Entry: string = Pointer to null-terminated string.
**        fd     = File descriptor of pertinent file.
*/
fputs(string, fd) char *string; int fd; {
  while(*string) {fputc(*string, fd); string++  ; }
  }
  
/*
** Write string to standard output. 
*/
puts(string) char *string; {
  //fputs(string, stdout);
  while(*string) fputc(*string++, stdout) ;
  //while(*string) { putchar(*string); string++; }
  //putchar(13);
  }
  
/*
** Character-stream output of a character to fd.
** Entry: ch = Character to write.
**        fd = File descriptor of perinent file.
** Returns character written on success, else EOF.
*/
fputc(ch, fd) int ch, fd; {
/*   switch(ch) {
    case  EOF: _write(DOSEOF, fd); break;
    case '\n': _write(CR, fd); _write(LF, fd); break;
      default: _write(ch, fd);
    }
  if(_status[fd] & ERRBIT) return (EOF); */
  if (fd==stdout) {
	  if (ch=='\n') putchar(13); else putchar(ch);
  } else {
	  #asm
	  MOV.D A1,8(A6)
      MOV.D A2,12(A6)
	  MOV.D A0,22
	  INT  4
	  MOV.D A1,A2
	  #endasm
  }
 }

poll(pause) int pause; {
  int i;
  if(i = _hitkey())  i = _getkey();
  if(pause) {
    if(i == PAUSE) {
      i = _getkey();           /* wait for next character */
      if(i == ABORT) exit(2);  /* indicate abnormal exit */
      return (0);
      }
    if(i == ABORT) exit(2);
    }
  return (i);
  }

/*
** Place n occurrences of ch at dest.
*/
pad(dest, ch, n) char *dest; int n, ch; {
  while(n--) *dest++ = ch;
  }

/*
** otoi -- convert unsigned octal string to integer nbr
**          returns field size, else ERR on error
*/
otoi(octstr, nbr)  char *octstr;  int *nbr;  {
  int d,t; d=0;
  *nbr=0;
  while((*octstr>='0')&(*octstr<='7')) {
    t=*nbr;
    t=(t<<3) + (*octstr++ - '0');
    if ((t>=0)&(*nbr<0)) return ERR;
    d++; *nbr=t;
    }
  return d;
  }

/*
** return lower-case of c if upper-case, else c
*/
tolower(c) int c; {
  if(c<='Z' && c>='A') return (c+32);
  return (c);
  }
  
 /*
** sign -- return -1, 0, +1 depending on the sign of nbr
*/
sign(nbr)  int nbr;  {
  if(nbr > 0)  return 1;
  if(nbr == 0) return 0;
  return -1;
  }
  

// abs -- returns absolute value of nbr
abs(nbr)  int nbr; {
  if(nbr < 0) return (-nbr);
  return (nbr);
  } 
  
/*
** atoi(s) - convert s to integer.
*/
atoi(s) char *s; {
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

/*
** atoib(s,b) - Convert s to "unsigned" integer in base b.
**              NOTE: This is a non-standard function.
*/
atoib(s, b) char *s; int b; {
  int n, digit;
  n = 0;
  while(isspace(*s)) ++s;
  while((digit = (127 & *s++)) >= '0') {
    if(digit >= 'a')      digit -= 87;
    else if(digit >= 'A') digit -= 55;
    else                  digit -= '0';
    if(digit >= b) break;
    n = b * n + digit;
    }
  return (n);
  }

/*
** dtoi -- convert signed decimal string to integer nbr
**         returns field length, else ERR on error
*/
dtoi(decstr, nbr)  char *decstr;  int *nbr;  {
  int len, s;
  if((*decstr)=='-') {s=1; ++decstr;} else s=0;
  if((len=utoi(decstr, nbr))<0) return ERR;
  if(*nbr<0) return ERR;
  if(s) {*nbr = -*nbr; return ++len;} else return len;
  }
  
/*
** fprintf(fd, ctlstring, arg, arg, ...) - Formatted print.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
fprintf(argc) int argc; {
  int *nxtarg;
  nxtarg = CCARGC() + &argc;
  return(_print(*(--nxtarg), --nxtarg));
  }

/*
** printf(ctlstring, arg, arg, ...) - Formatted print.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
printf(argc) int argc; {
  return(_print(stdout, CCARGC() + &argc - 1));
  }

/*
** _print(fd, ctlstring, arg, arg, ...)
** Called by fprintf() and printf().
*/
char _buf_str[19]; 

_print(fd, nxtarg) int fd, *nxtarg; {
  int  arg, left, pad, cc, len, maxchr, width;
  char *ctl, *sptr; //, str[17];
  cc = 0;                                         
  ctl = *nxtarg--;                          
  while(*ctl) {
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
    arg = *nxtarg--;
    sptr = _buf_str;
    switch(*ctl++) {
      case 'c': _buf_str[0] = arg; _buf_str[1] = NULL; break;
      case 's': sptr = arg;        break;
      case 'd': itoa(arg,_buf_str);     break;
      case 'b': itoab(arg,_buf_str,2);  break;
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
** return 'true' if c is an ASCII character (0-127)
*/
isascii(c) int c; {
  return (c < 128);
  }
  
/*
** itoa(n,s) - Convert n to characters in s 
*/
itoa(n, s) char *s; int n; {
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
itoab(n, s, b) int n; char *s; int b; {
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
  
/*
** itod -- convert nbr to signed decimal string of width sz
**         right adjusted, blank filled; returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itod(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  char sgn;
  if(nbr<0) {nbr = -nbr; sgn='-';}
  else sgn=' ';
  if(sz>0) str[--sz]=NULL;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=NULL) ++sz;
  while(sz) {
    str[--sz]=(nbr%10+'0');
    if((nbr=nbr/10)==0) break;
    }
  if(sz) str[--sz]=sgn;
  while(sz>0) str[--sz]=' ';
  return str;
  }
  
/*
** itoo -- converts nbr to octal string of length sz
**         right adjusted and blank filled, returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itoo(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  int digit;
  if(sz>0) str[--sz]=0;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=0) ++sz;
  while(sz) {
    digit=nbr&7; nbr=(nbr>>3)&8191;
    str[--sz]=digit+48;
    if(nbr==0) break;
    }
  while(sz) str[--sz]=' ';
  return str;
  }
  
/*
** itou -- convert nbr to unsigned decimal string of width sz
**         right adjusted, blank filled; returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itou(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  int lowbit;
  if(sz>0) str[--sz]=NULL;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=NULL) ++sz;
  while(sz) {
    lowbit=nbr&1;
    nbr=(nbr>>1);  /* divide by 2 */
    str[--sz]=((nbr%5)<<1)+lowbit+'0';
    if((nbr=nbr/5)==0) break;
    }
  while(sz) str[--sz]=' ';
  return str;
  }
  
/*
** itox -- converts nbr to hex string of length sz
**         right adjusted and blank filled, returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itox(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  int digit, offset;
  if(sz>0) str[--sz]=0;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=0) ++sz;
  while(sz) {
    digit=nbr&15; nbr=(nbr>>4)&4095;
    if(digit<10) offset=48; else offset=55;
    str[--sz]=digit+offset;
    if(nbr==0) break;
    }
  while(sz) str[--sz]=' ';
  return str;
  }
  
/*
** left -- left adjust and null terminate a string
*/
left(str) char *str; {
  char *str2;
  str2=str;
  while(*str2==' ') ++str2;
  while(*str++ = *str2++);
  }
  
char _lex[128] = {
       0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  /* NUL - /       */
      10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
      20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
      30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
      40, 41, 42, 43, 44, 45, 46, 47,
      65, 66, 67, 68, 69, 70, 71, 72, 73, 74,  /* 0-9           */
      48, 49, 50, 51, 52, 53, 54,              /* : ; < = > ? @ */
      75, 76, 77, 78, 79, 80, 81, 82, 83, 84,  /* A-Z           */
      85, 86, 87, 88, 89, 90, 91, 92, 93, 94,
      95, 96, 97, 98, 99,100,
      55, 56, 57, 58, 59, 60,                  /* [ \ ] ^ _ `   */
      75, 76, 77, 78, 79, 80, 81, 82, 83, 84,  /* a-z           */
      85, 86, 87, 88, 89, 90, 91, 92, 93, 94,
      95, 96, 97, 98, 99,100,
      61, 62, 63, 64,                          /* { | } ~       */
     127};                                     /* DEL           */

/*
** lexcmp(s, t) - Return a number <0, 0, or >0
**                as s is <, =, or > t.
*/
lexcmp(s, t) char *s, *t; {
  while(lexorder(*s, *t) == 0)
    if(*s++) ++t;
    else return (0);
  return (lexorder(*s, *t));
  }

/*
** lexorder(c1, c2)
**
** Return a negative, zero, or positive number if
** c1 is less than, equal to, or greater than c2,
** based on a lexicographical (dictionary order)
** colating sequence.
**
*/
lexorder(c1, c2) int c1, c2; {
  return(_lex[c1] - _lex[c2]);
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

int _is[128] = {
 0x004, 0x004, 0x004, 0x004, 0x004, 0x004, 0x004, 0x004,
 0x004, 0x104, 0x104, 0x104, 0x104, 0x104, 0x004, 0x004,
 0x004, 0x004, 0x004, 0x004, 0x004, 0x004, 0x004, 0x004,
 0x004, 0x004, 0x004, 0x004, 0x004, 0x004, 0x004, 0x004,
 0x140, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0,
 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0,
 0x459, 0x459, 0x459, 0x459, 0x459, 0x459, 0x459, 0x459,
 0x459, 0x459, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0,
 0x0D0, 0x653, 0x653, 0x653, 0x653, 0x653, 0x653, 0x253,
 0x253, 0x253, 0x253, 0x253, 0x253, 0x253, 0x253, 0x253,
 0x253, 0x253, 0x253, 0x253, 0x253, 0x253, 0x253, 0x253,
 0x253, 0x253, 0x253, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x0D0,
 0x0D0, 0x473, 0x473, 0x473, 0x473, 0x473, 0x473, 0x073,
 0x073, 0x073, 0x073, 0x073, 0x073, 0x073, 0x073, 0x073,
 0x073, 0x073, 0x073, 0x073, 0x073, 0x073, 0x073, 0x073,
 0x073, 0x073, 0x073, 0x0D0, 0x0D0, 0x0D0, 0x0D0, 0x004
 };

isalnum (c) int c; {return (_is[c] & ALNUM );} /* 'a'-'z', 'A'-'Z', '0'-'9' */
isalpha (c) int c; {return (_is[c] & ALPHA );} /* 'a'-'z', 'A'-'Z' */
iscntrl (c) int c; {return (_is[c] & CNTRL );} /* 0-31, 127 */
isdigit (c) int c; {return (_is[c] & DIGIT );} /* '0'-'9' */
isgraph (c) int c; {return (_is[c] & GRAPH );} /* '!'-'~' */
islower (c) int c; {return (_is[c] & LOWER );} /* 'a'-'z' */
isprint (c) int c; {return (_is[c] & PRINT );} /* ' '-'~' */
ispunct (c) int c; {return (_is[c] & PUNCT );} /* !alnum && !cntrl && !space */
isspace (c) int c; {return (_is[c] & BLANK );} /* HT, LF, VT, FF, CR, ' ' */
isupper (c) int c; {return (_is[c] & UPPER );} /* 'A'-'Z' */
isxdigit(c) int c; {return (_is[c] & XDIGIT);} /* '0'-'9', 'a'-'f', 'A'-'F' */
