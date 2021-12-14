;  Lion System Rom
;  (C) 2015-2018 Theodoulos Liontakis 

VBASE		EQU		32768
VBASE1	EQU		32768
COLTBL      EQU		61152
VSBLOCK     EQU		96770
HSBLOCK     EQU		96780
SCRLBUF     EQU         96790
XDIM		EQU		640    ; XDIM Screen Horizontal Dim. 
XDIM22	EQU		320     ; mode xdim 
YDIM		EQU		240    ; Screen Vertical Dimention
YDIM2		EQU		200
XCC		EQU	80   ; Horizontal Lines
YCC		EQU	30     ; Vertical Rows
XCC2		EQU	53
YCC2		EQU	25
MAXFILES    EQU	12

	  	ORG 		0    ; Rom 
INT0_3      DA		RHINT0 ; hardware interrupts (ram)
		DA          RHINT1 ; (ram)
		DA		RHINT2 ; (ram)
		DA		HINT   ; (ram)
INT4        DA        	INTR4     ; interrupt vector 4 system calls
INT5 		DA		INTR5	    ; fixed point & fat routines
INT6        DA          RINT6     ; address in ram
INT7		DA		RINT7	    
INT8        DA          RINT8
INT9		DA		RINT9
INT10		DA          INTEXIT
INT11		DA          INTEXIT
INT12		DA          INTEXIT
INT13		DA          INTEXIT
INT14		DA          INTEXIT
INT15		DA		RINT15   ; trace interrupt in ram	

BOOTC:	CLI
		MOV.D        A1,ISTACK
		ADD.D		 A1,508
		SETISP       A1
            MOV.D		(FMEMORG),START
		MOV.D		(FMEMLPTR),START
		MOV.D		(FMEMLOWL),START
		MOV.B		(VMODE),0
		MOV.B		(BCOL),$03
		MOV.B		(FCOL),$FF
		MOV.B		(SCOL),$03
		SETX		1589       ; Set default color 
		MOV.D		A1,COLTBL
		NTOI		A1,$1F1F		
		MOV		(SDFLAG),0
		MOV		 A0,$8400 ; fill initially with RETI
		MOV		(HINT),A0
		MOV		(RHINT0),A0
		MOV		(RHINT1),A0
		MOV		(RHINT2),A0
		MOV		(RINT15),A0
		MOV.B		(SHIFT),0
		MOV.B		(CAPSL),0
		MOV.B		(PLOTM),1
		SETX		4095
		MOV.D		A1,98304
CXYBUF:	OUT		A1,0
		JXAW		A1,CXYBUF
		MOV.D		A1,64530
		SETSP		A1
		;MOV.D		A2,32767
		;  memory test
		MOV.D		A6,START
MEMTST:     MOV.D		A2,(A6)
		MOV.D		A3,A2
		NOT.D		A3
		MOV.D		(A6),A3
		MOV.D		($FFFFC),$0F
		MOV.D		A0,(A6)
		MOV.D		(A6),A2
		CMP.D		A0,A3
		JNZ		MEMNOK
MEMOK:	MOV		A2,$3404
		ADDI		A6,4
		MOV.D		A0,A6
		BTST		A0,1
		JRNZ		6
		IJSR		PRNHEX
		CMP.D		A6,$00FFFFFF
		JC		MEMTST
		
MEMNOK:	MOV.D		(MEMTOP),A6
		MOVI	A0,0
		INT	4 
		MOVI	A0,7
		INT   4
		MOVI	A0,0
		INT	4
		MOVI	A0,7
		INT   4 
		SETX		80
SDRETR:	MOVI		A0,11        ; sd card init
		INT		4
		CMP		A0,256
		JZ		SDOKO
		JMPX		SDRETR
		JMP		SDNOT
SDOKO:	MOVI		A0,5        ; sd card ok
		MOV.D		A1,SDOK
		MOV		A2,$0103
		INT		4            ; print ok
		MOVI		A0,3
		INT		5            ; mount volume, get params
		;MOV		A0,(SDFLAG)
		CMP		(SDFLAG),256
		JNZ		SDNOT
		MOV.D		A4,BOOTBIN
		IJSR		FINDFN        ; Find BOOT.BIN
		CMP		A0,0
		JZ		SDNOT
		PUSHI		A0
		PUSHI		A1
		MOV		A0,A1
		MOV	      A2,$2804
		IJSR		PRNHEX
		MOVI		A0,5           
		MOV.D		A1,SDBOK
		MOV		A2,$0104
		INT		4	         ; print 
		POPI		A1
		POPI		A0
		MOV.D		A3,START
		MOV		A4,A0
		IJSR		FLOAD   ; Load boot file
		STI
		JMP		START  ; address at RAM
SDNOT:
		MOVI		A0,5
		MOV.D		A1,SDNOTOK
		MOVI		A2,5
		INT		4
		JMP		MEMNOK

PRNHEX:	; print num in A0 in hex for debugging 
		PUSHXI
		PUSHI	A0
		PUSHI	A1
		PUSHI	A3
		MOV.D	A3,A0  
		SETX	7
PHX1:		MOV.D	A1,A3
		AND.D	A1,$0000000F
		ADD.D	A1,48
		CMP.D	A1,57
		JBE	PHX2
		ADDI	A1,7
PHX2:		MOVI	A0,4
		SUB	A2,$0100
		INT	4
		SRL.D	A3,4
		JMPX	PHX1
		POPI	A3
		POPI	A1
		POPI	A0
		POPXI
		IRET 


;   End of boot code
;--------------------------------------------------

;  INT4 FUNCTION TABLE  function in a0
INT4T0	DA	SERIN    ; Serial port in A1  A0(0)=1 
INT4T1	DA	SEROUT   ; Serial port out A1  
INT4T2	DA	PLOT     ; at X=A1,Y=A2 A4=1 set A4=0 clear
INT4T3	DA	CLRSCR   ; CLEAR SCREEN
INT4T4	DA	PUTC     ; Print char A1 at x A2.H  y A2.L
INT4T5	DA	PSTR     ; Print zero & cr terminated string
INT4T6	DA	SCROLL   ; Scrolls screen 1 char (8 points) up
INT4T7	DA	SKEYBIN  ; Serial Keyboard port in A1 A0(2)=1
INT4T8	DA	MULT     ; Multiplcation A1*A2 res in A2A1, a0<>0 overflow 
INT4T9	DA	DIV      ; 16bit  Div A2 by A1 res in A1,A0
INT4T10	DA	KEYB     ; converts to ascii the codes from serial keyboard
INT4T11	DA	SPI_INIT ; initialize spi sd card
INT4T12	DA	SPIS     ; spi send/rec byt in A1 mode A2 1=CS low 3=CS h res a0
INT4T13	DA	READSEC  ; read in buffer at A2, n in A1
INT4T14	DA	WRITESEC ; WRITE BUFFER at A2 TO A1 BLOCK
INT4T15	DA	VSCROLL  ; loop horizontal scroll
INT4T16	DA	OPENFILE ; open A1=type A4=ptr to fname, A0=ID success A0=0 failure
INT4T17     DA	CLOSEFILE ; A1=file handle
INT4T18     DA    FREAD    ; A1=File handle  A2=number of bytes A3=pointer to buffer
INT4T19     DA	FSEEK    ; A1=file handle  A2=new pos
INT4T20     DA	FGETPOS  ; A1=file handle, A0=file pos
INT4T21     DA	FGETSZ   ; A1=file handle, A0=file size
INT4T22	DA	FWRITE   ; A1=file handle, A2=byte


;  INT5 FUNCTION TABLE  function in a0
INT5T0	DA	INTEXIT   ; Ex fixed point multiply A1*A2
INT5T1	DA	INTEXIT   ; Ex fixed point divide A2.(FRAC2)/A1.(FRAC1)
INT5T2	DA	FILELD   ; Load file A4 points to filename, at A3
INT5T3	DA	VMOUNT   ; Load First Volume, return A0=fat root 1st cluster
INT5T4	DA	FILEDEL  ; Delete file A4 points to filename
INT5T5	DA	FILESAV  ; Save memory to file A4 filename, a6 address, a7 size
INT5T6	DA	UDIV     ; Unsigned 32bit  Div A2 by A1 res in A1,A0
INT5T7      DA	MEMALOC  ; Reserve mem above and adjust FMEMORG A1=bytes  A0=new FMO
INT5T8      DA	MEMFREE  ; free memory A1=bytes A2=base mem
INT5T9      DA	FLMUL    ; float mult A1A2*A3A4 res A1A2 
INT5T10     DA	FLDIV    ; float div A1A2/A3A4 res A1A2
INT5T11     DA	FLADD    ; float add A1A2+A3A4 res A1A2 
INT5T12     DA	FCMP     ; float cmp  A1A2,A3A4 res A0 
INT5T13     DA	LDSCR    ; Load Screen A4 fname @A3 
INT5T14     DA    LINEXY   ; plot a line a1,a2 to a3,a4
INT5T15	DA	HSCROLL  ; loop horizontal scroll
INT5T16	DA	FINDF    ;  A4 ptr to filename, A0->cluster relative to (FSTCLST)
INT5T17	DA	CIRC     ; Circle A1,A2,A3     
INT5T18     DA	VSCROLL2 ; vertical scroll with data feed	                              
INT5T19     DA	HSCROLL2 ; horizontal scroll with data

;Hardware interrupt
;HINT:		;ADD		(COUNTER),1
INTEXIT:	RETI        ; trace interrupt
		
INTR4:		
		SRCLR		4
		AND.D		A0,$000000FF
		SLL.D		A0,2
		ADD.D		A0,INT4T0
		JMP		(A0)

INTR5:	SRCLR		4
		AND.D		A0,$000000FF
		SLL.D		A0,2
		ADD.D		A0,INT5T0
		JMP		(A0)

MEMALOC:	PUSHXI
		PUSHI A2
		MOV.D A0,(FMEMORG)
		PUSHI	A0
            ADD.D	A0,A1
		CMP.D A0,(MEMTOP)
		JRC   4
		MOVI  A0,0
  		RETI
		BTST	A0,0  ; word align
		JRZ	2
		ADDI	A0,1
		MOV.D	(FMEMORG),A0
		POPI	A0
		MOV.D	A2,A1
		SRL.D	A2,1
		SETX	A2
		NTOM	A0,0  ; fill with 0
		POPI	A2
		POPXI	
            RETI

MEMFREE:	PUSHI	A3
		MOV.D	A3,(FMEMORG)
		SUB.D	A3,A1
		CMP.D A3,A2
		JNZ   MFEXIT
		MOV.D (FMEMORG),A2
MFEXIT:	POPI	A3
		RETI

;---------------------------------------------------

; General Horizontal Scroll INT5 A0=15 for MODE 1
; Block at 64780 
; +0 line
; +2 lenght lines
; +4 pixel
; +6 length pixels
; +8 pixels to scroll
; Buffer at 96790 to 98303 (1514 bytes) up to 7 pixels full screen 
;---------------------------------------------------

HSCROLL2: 	PUSHI	A7
		IN	A0,24
		CMPI	A0,1    
		JZ	HSCROLL1
		POPI	A7
		RETI


HSCROLL:	PUSHI A7
		IN	A0,24
		CMPI	A0,1 
		MOV.D	A7,SCRLBUF
		JZ	HSCROLL1
		POPI	A7
		RETI

HSCROLL1:	PUSHXI
		PUSHI	A1
		PUSHI	A2
		PUSHI	A3	
		PUSHI	A4
		PUSHI	A5

		MOVI	A1,0
		MOVI	A2,0
		MOVI	A3,0
		MOVI	A5,0
		IN	A5,8+HSBLOCK ; A5 pixels to scroll 
		CMP 	A5,0
		JZ	HS1EX
		JL    HS1NG
		IN  	A1,HSBLOCK  ; l1
		MULU  A1,320
		IN	A2,4+HSBLOCK   ;p1
		ADD.D	A1,A2
		IN	A3,6+HSBLOCK   ; length pix/2
		ADD   A1,A3
		SUBI	A1,1
		ADD.D	A1,VBASE1
		PUSHI	A1 
		MOV.D	A4,SCRLBUF
		IN	A2,2+HSBLOCK   ; lines
		MOV.D	A3,A5
		SUBI	A3,1
		SRSET 4    ; set decrease to direction bit
HSCRL1:	SETX 	A3
		MOV.D	A0,A1
            ITOI.B  A4,A0
		ADD.D	A4,A5
		ADD.D	A1,320
		SUBI  A2,1
		JNZ	HSCRL1
		POPI	A1
		PUSHI	A1 
		IN	A2,2+HSBLOCK   ; lines
		IN	A3,6+HSBLOCK   ; pixels
		MOV.D	A0,A5
		SUB.D	A3,A0
		SUBI	A3,1
		MOV.D	A4,A1
		SUB.D	A4,A0
HSCRL3:	SETX 	A3
		ITOI.B A1,A4
		ADD.D	A1,320
		ADD.D	A4,320
		SUBI  A2,1
		JNZ	HSCRL3
		POPI	A1
		IN	A3,6+HSBLOCK   ; pixels
		SUB.D	A1,A3
		MOV.D	A3,A5
		ADD.D	A1,A3
		MOV.D	A4,A7  ;SCRLBUF
		IN	A2,2+HSBLOCK   ; lines
		SUBI	A3,1
		PUSHI	A1 ; store fill pos
HSCRL5:	SETX 	A3
		MOV.D	A0,A1
		ITOI.B A0,A4
		ADD	A4,A5
		ADD.D	A1,320
		SUBI  A2,1
		JNZ	HSCRL5
		SRCLR 4
		POPI	A0
		JMP	HS1EX

HS1NG:	NEG	A5
		IN  	A1,HSBLOCK  ; l1
		MULU  A1,320
		IN	A2,4+HSBLOCK  ;p1 
		ADD.D	A1,A2
		ADD.D	A1,VBASE1
		PUSHI	A1  
		MOV.D	A4,SCRLBUF
		IN	A2,2+HSBLOCK   ; lines
		MOV.D	A3,A5
		SUBI	A3,1
HSCRL7:	SETX 	A3
		ITOI.B  A4,A1
		ADDI	A4,1
		ADD.D	A1,320
		SUBI  A2,1
		JNZ	HSCRL7
		POPI	A1
		PUSHI	A1 
		IN	A2,2+HSBLOCK   ; lines
		IN	A3,6+HSBLOCK   ; pixels
		MOV.D	A0,A5
		SUB.D	A3,A0
		SUBI	A3,1
HSCRL9:	SETX 	A3
		MOV.D	A0,A5
		MOV.D	A4,A1
		ADD.D	A4,A0
		ITOI.B  A1,A4
		ADD.D	A1,320
		SUBI  A2,1
		JNZ	HSCRL9
		POPI	A1
		IN	A3,6+HSBLOCK   ; pixels
		ADD.D	A1,A3
		MOV.D	A3,A5
		SUB.D	A1,A3
		MOV.D	A4,A7 ;SCRLBUF
		IN	A2,2+HSBLOCK   ; lines
		PUSHI	A1
		SUBI	A3,1
HSCRL11:	SETX 	A3
		ITOI.B  A1,A4
		ADDI	A4,1
		ADD.D	A1,320
		SUBI  A2,1
		JNZ	HSCRL11
		POPI	A0
	
HS1EX:	POPI	A5
		POPI	A4
		POPI	A3
		POPI	A2
		POPI	A1
		POPXI
		POPI	A7
		RETI

;----------------------------------------------

;General Vertical Scroll INT4 A0=15 MODE 1
; Block starts at 64770
; +0 line
; +2 lenght lines
; +4 point
; +6 length points
; +8 lines to scroll
; Buffer at 96790 to 98303 (1514 bytes) up to 4 lines full screen 
;----------------------------------------------
VSCROLL2:	PUSHI	A7
		IN	A0,24
		CMPI	A0,1 
		JZ	VSCROLL1
		POPI  A7
		RETI

VSCROLL:	PUSHI	A7
		IN	A0,24
		CMPI	A0,1 
		MOV.D	A7,SCRLBUF
		JZ	VSCROLL1
		POPI	A7
		RETI

VSCROLL1:	PUSHXI
		PUSHI	A1
		PUSHI	A2
		PUSHI	A3	
		PUSHI	A4
		PUSHI	A5
		PUSHI	A6
		MOVI	A1,0
		MOVI	A2,0
		MOVI	A3,0
		MOVI	A4,0
		MOVI	A5,0
		MOVI	A6,0
		IN	A6,8+VSBLOCK    ; A6 is lines to scroll
		CMP 	A6,0

		JZ	VS1EX
		JL    VS1NG
		IN  	A1,VSBLOCK  ; l1
		MULU  A1,320
		ADD.D	A1,VBASE1
		IN	A2,4+VSBLOCK     ;p1
		ADD.D	A1,A2
		PUSHI	A1  
		MOV.D	A2,A6
		IN	A3,6+VSBLOCK    ; length pix
		MOV	A5,A3
		SRL	A3,1 
		SUBI	A3,1
		MOV.D	A4,SCRLBUF
		;IN	A5,6+VSBLOCK   ; length pix
VSCRL1:	SETX	A3
		ITOI  A4,A1
		ADD.D A4,A5
		ADD.D	A1,320
		SUBI	A2,1
		JNZ   VSCRL1
		POPI	A1     ; scroll start address l1*320
		MOV.D	A4,A6  ;lines
		MULU	A4,320 
		ADD.D	A4,A1  ; scroll end address
		IN	A2,2+VSBLOCK    ; length in lines
		MOV.D	A5,A6
		SUB.D	A2,A5
VSCRL2:	SETX	A3
		ITOI A1,A4
		ADD.D	A1,320
		ADD.D	A4,320
		SUBI	A2,1
		JNZ	VSCRL2
		MOV.D	A4,A7 ;SCRLBUF
		MOV.D	A2,A5
		IN	A5,6+VSBLOCK    ; length pix
		PUSHI	A1
VSCRL3:	SETX  A3
		ITOI  A1,A4
		ADD.D	A1,320
		ADD.D A4,A5
		SUBI	A2,1
		JNZ	VSCRL3
		POPI	A0
		JMP	VS1EX

VS1NG:	NEG   A6
		IN  	A1,VSBLOCK ; LINE
		IN	A2,2+VSBLOCK    ; length in lines
		ADD.D	A1,A2
		SUBI	A1,1
		MULU  A1,320
		ADD.D	A1,VBASE1
		IN	A2,4+VSBLOCK    ;p1
		ADD.D	A1,A2
		PUSHI	A1  
		MOV.D	A2,A6
		IN	A3,6+VSBLOCK    ; length pix/2
		MOV	A5,A3
		SRL.D	A3,1
		SUBI	A3,1
		MOV.D	A4,SCRLBUF
		;IN	A5,6+VSBLOCK  
VSCRL4:	SETX	A3
		ITOI  A4,A1
		ADD.D A4,A5
		SUB.D	A1,320
		SUBI	A2,1
		JNZ   VSCRL4
		POPI	A1
		MOV.D	A4,A6
		MULU	A4,320
		SUB.D	A4,A1
		NEG.D	A4
		IN	A2,2+VSBLOCK    ; length in lines
		MOV.D	A5,A6
		SUB.D	A2,A5
VSCRL5:	SETX	A3
		ITOI A1,A4
		SUB.D	A1,320
		SUB.D	A4,320
		SUBI	A2,1
		JNZ	VSCRL5
		MOV.D	A4,A7 ;SCRLBUF
		MOV.D	A2,A5
		IN	A5,6+VSBLOCK
		PUSHI A1  
VSCRL6:	SETX  A3
		ITOI  A1,A4
		SUB.D	A1,320
		ADD.D A4,A5
		SUBI	A2,1
		JNZ	VSCRL6
		POPI	A0
		
VS1EX:	POPI	A6
		POPI	A5
		POPI	A4
		POPI	A3
		POPI	A2
		POPI	A1
		POPXI
		POPI	A7
		RETI
;----------------------------------------

FCMP:
  PUSHI A1
  PUSHI A3
  PUSHI A5
  PUSHI A7
  MOVI A0,0
  BTST A1,31
  JZ CFLT_1
  BTST A3,31
  JZ CFLT_2
CFLP_4:  
  XCHG A1,A3  ;// both negative
  JMP CFLT_3
CFLT_1:
  BTST A3,31
  JZ CFLT_3
  MOVI A0,1  ;// 1st  pos  2nd neg
  JMP CFLT_E
CFLT_2:
  BTST A3,31
  JNZ CFLP_4
  MOV.D A0,-1  ;// 1st neg  2nd pos
  JMP CFLT_E
CFLT_3:      ; // both pos
  ;AND.D A1,$7FFFFFFF
  ;AND.D A3,$7FFFFFFF
  BCLR A1,31
  BCLR A3,31
  MOV.D A5,A3
  SRL.D A5,8
  SRL.D A5,15    ;// A5 has exponent 2
  AND.D A3,$007FFFFF  ;// A3 has hi part of fraction A4 the rest
  MOV.D A7,A1
  SRL.D A7,8
  SRL.D A7,15
  AND.D A1,$007FFFFF
  CMP.D A7,A5    ; // A1 has hi part of fraction A2 the rest
  JL CFLT_5
  JZ CFLT_6
CFLT_7:
  MOVI A0,1
  JMP CFLT_E
CFLT_5:
  MOV.D A0,-1  
  JMP CFLT_E
CFLT_6:      ;// equal exp compare mantisa
  CMP.D A1,A3
  JL CFLT_5
  JNZ CFLT_7
  MOVI A0,0
CFLT_E:
  POPI A7
  POPI A5
  POPI A3
  POPI A1
  RETI

FLMUL:
  PUSHI A5
  PUSHI A6
  PUSHI A7
  MOV.D A6,A3
  XOR.D A6,A1
  AND.D A6,$80000000
  MOV.D A5,A3
  AND.D A3,$007FFFFF  ;// A3 has hi part of fraction A4 the rest
  ;AND.D A5,$7FFFFFFF
  BCLR  A5,31
  SRL.D A5,8   ;// A5 has exponent 2
  SRL.D A5,15
  MOV.D A0,A3
  OR.D A0,A5
  JRNZ 8     ;// if num2 = 0 exit result = num1
  MOVI A1,0
  JMP FMUL_E
  ;OR.D A3,$800000
  BSET  A3,23
  SUB.D A5,127
  MOV.D A7,A1
  AND.D A1,$007FFFFF   ;// A1 has hi part of fraction A2 the rest
  ;AND.D A7,$7FFFFFFF
  BCLR  A7,31
  SRL.D A7,8      ;// A7 has exponent 1
  SRL.D A7,15
  MOV.D A0,A1
  OR.D A0,A7
  JZ FMUL_E
  ;OR.D A1,$800000
  BSET  A1,23
  SUB.D A7,127
  ADD.D A7,A5
  MULU.D A1,A3
FMUL_1: 
  CMPI A3,0
  JZ FMUL_6	
  ADDI A7,1
  SRLL.D A3,A1  ;,8
  JMP FMUL_1
FMUL_6:  
  SRL.D A1,9
  ADD.D A7,113 ;127-14
FMUL_4:
  BTST A1,23
  JNZ FMUL_5
  SLL.D A1,1
  SUBI A7,1
  CMPI A7,0
  JA FMUL_4
FMUL_5:
  AND.D A1,$007FFFFF  ;// build float 
  SLL.D A7,8
  SLL.D A7,15
  OR.D A1,A7
  OR.D A1,A6     ;// Set sign
FMUL_E:
  POPI A7
  POPI A6
  POPI A5
  RETI

FLDIV: 
  PUSHI A2
  PUSHI A6
  PUSHI A7
  MOV.D A6,A3
  XOR.D A6,A1
  AND.D A6,$80000000
  MOV.D A2,A3
  AND.D A3,$007FFFFF  ;// A3 has fraction 
  ;AND.D A2,$7FFFFFFF
  BCLR  A2,31
  SRL.D A2,8     ;// A2 has exponent 2
  SRL.D A2,15
  MOV.D A0,A2
  OR.D A0,A3
  JRNZ 14       ;// if num2 = 0 exit
  MOV.D A1,$7f800000
  OR.D  A1,A6
  JMP FDIV_E
  ;OR.D A3,$800000
  BSET  A3,23
  MOV.D A7,A1
  AND.D A1,$007FFFFF    ;// A1 has hi part of fraction A2 the rest
  ;AND.D A7,$7FFFFFFF
  BCLR  A7,31
  SRL.D A7,8       ;// A7 has exponent 1
  SRL.D A7,15
  MOV.D A0,A1
  OR.D  A0,A7
  JZ FDIV_E
  ;OR.D A1,$800000
  BSET  A1,23
  ADD.D A7,127
  SUB.D A7,A2
  SLL.D A1,8
  ADDI  A7,15

  ;SRL.D A3,7
  MOVI A0,10
FDIV_3:
  BTST A3,0
  JNZ FDIV_6
  SRL.D A3,1
  SUBI A7,1
  SUBI A0,1
  JNZ FDIV_3

FDIV_6:
  MOV.D A2,A1
  MOV.D A1,A3
  MOVI A0,6
  INT 5

FDIV_4:
  BTST A1,23
  JNZ FDIV_5
  SLL.D A1,1
  SUBI A7,1
  JNZ FDIV_4
FDIV_5:    
  AND.D A1,$007FFFFF  ;// build float 
  SLL.D A7,8
  SLL.D A7,15
  OR.D A1,A7
  OR.D A1,A6   ; // Set sign
FDIV_E:
  POPI A7
  POPI A6
  POPI A2
  RETI

FLADD: 
  PUSHI A5
  PUSHI A6
  PUSHI A7
  MOV.D A6,A3
  MOV.D A5,A3
  AND.D A3,$007FFFFF  ;// A3 has hi part of fraction A4 the rest
  ;AND.D A5,$7FFFFFFF
  BCLR  A5,31
  SRL.D A5,8    ;// A5 has exponent 2
  SRL.D A5,15
  MOV.D A0,A3
  OR.D A0,A5
  JZ FADD_E      ;// if num2 = 0 exit result = num1
  ;OR.D A3,$800000
  BSET A3,23
  MOV.D A0,A1
  MOV.D A7,A1
  AND.D A1,$007FFFFF  ; // A1 has hi part of fraction A2 the rest
  ;AND.D A7,$7FFFFFFF
  BCLR  A7,31
  SRL.D A7,8    ;// A7 has exponent 1
  SRL.D A7,15
  PUSHI A0
  MOV.D A0,A1
  OR.D A0,A7
  POPI A0
  JNZ FADD_9
  MOV.D A1,A6
  JMP FADD_E
FADD_9:
  ;OR.D A1,$800000
  BSET A1,23
  CMP.D A7,A5   ;//  make A1A2 the bigger number
  JA FADD_3
  JZ FADD_4
  XCHG A1,A3
  XCHG A7,A5
  XCHG A0,A6
FADD_3:      ;// make exps equal
  CMP.D A7,A5
  JZ FADD_4
  SRL.D A3,1
  ADDI A5,1
  JMP FADD_3
FADD_4:
  BTST A0,31
  JZ FADD_1
  BTST A6,31
  JZ FADD_2
  MOV.D A0,$80000000   ;//both negative add
FADD_6:     ;// both positive add
  ADD.D A1,A3
  JMP FADD_5
FADD_1:
  BTST A6,31
  MOVI A0,0
  JZ FADD_6
FADD_7:
  MOV.D A0,$80000000  ;// 1st positive 2nd negative subtract
  SUB.D A1,A3           ; // or the oposite
  JC FADD_8
  MOVI A0,0
  JMP FADD_10
FADD_8:
  NEG.D A1
  JMP FADD_10
FADD_2:
  XCHG A1,A3
  JMP FADD_7
FADD_5:
  BTST A1,24   ;//normalize 
  JRZ 4
  SRL.D A1,1
  ADDI A7,1
  JMP FADD_11
FADD_10:
  OR.D A5,A1
  JRNZ 2
  MOVI A7,0
  JZ FADD_E   ; // is subtraction result zero then exit
FADD_12:
  BTST A1,23     ;// matanormalize
  JNZ FADD_11
  SLL.D A1,1
  SUBI A7,1
  JNZ FADD_12
FADD_11:
  AND.D A1,$007FFFFF  ; // build float 
  SLL.D A7,8
  SLL.D A7,15
  OR.D A1,A7
  OR.D A1,A0
FADD_E:
  POPI A7
  POPI A6
  POPI A5
  RETI


;------- save fat cluster A1 to fat copy cluster from sdcbuf2  
SFATC:
	PUSHI A0
	PUSHI A1
	IJSR	DELAY
	ADD	A1,(SECPFAT)   ; add second fat offset
	MOVI	A0,14
	INT	4      ; Save FAT copy
	IJSR	DELAY
	POPI A1
	POPI A0
	IRET

;---------INT5 A0=5 Save -----------------------------
; A4 filename, a6 address, a7 size
;-------------------------------------------

FREEFAT:     ;find next free cluster in a0 and mark it with FFF8
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	MOVI	A4,0
	MOVI	A3,0
FRFT1:
	MOVI	A0,13
	MOV	A1,(FSTFAT)
	ADD	A1,A4
	MOV.D	A2,SDCBUF2
	INT	4              ; Load FAT
FRFT3:	
	CMP	(A2),0
	JZ	FRFT2
	ADD.D	A2,2
	INC	A3
	CMPI.B A3,0
	JNZ	FRFT3
	INC	A4
	CMP	A4,238
	JA	FRFT4
	JMP	FRFT1
FRFT4: 
	MOVI	A3,0
	JMP	FRFT5	
FRFT2: 
	MOV	(A2),$FFF8
	MOVI	A0,14
	MOV	A1,(FSTFAT)
	ADD	A1,A4
	MOV.D	A2,SDCBUF2
	INT	4    ; Save FAT
	IJSR   SFATC ; Save fat copy
FRFT5: 
	MOV	A0,A3
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	IRET

;---------------------------
; A0 first file cluster, A7 data length, A6 source ptr
SVDATA: 
	MOV	A3,A0   ;first target cluster
SVD1:	IJSR	DELAY
	MOVI  A4,0
	MOV	A4,A3
	SRL	A4,8    ; divide 256
	MOV	A1,(FSTCLST)
	ADD	A1,A3   ; to cluster
	SUBI	A1,2
	MOVI	A0,14
	MOV.D	A2,A6   ; from pointer
	INT	4
	CMP	A7,512  ; size
	JBE	SVD2
	ADD.D	A6,512
	SUB	A7,512
	IJSR	FREEFAT   ; find free fat entry
	CMPI	A0,0     ; Is it full
	JZ	SVDE

	SWAP	A0
	CMP.B A0,A4    ; same fat offset
	SWAP	A0
	JZ	NORELD

	IJSR	DELAY
	PUSHI	A0
	MOV	A1,(FSTFAT)
	ADD	A1,A4
	MOVI	A0,13
	MOV.D	A2,SDCBUF2
	INT	4
	POPI	A0
NORELD:
	IJSR	DELAY
	AND	A3,$00FF
	SLL	A3,1
	ADD.D	A3,SDCBUF2   ;store next cluster
	SWAP	A0
	MOV	(A3),A0
	SWAP	A0
	PUSHI	A0

	MOV.D	A2,SDCBUF2
	MOV	A1,(FSTFAT)
	ADD	A1,A4
	MOVI	A0,14
	INT	4
	IJSR	SFATC    ; save to fat copy
	POPI	A3
	JMP	SVD1
SVD2:	
	MOV	A1,(FSTFAT)
	ADD	A1,A4
	MOVI	A0,13
	MOV.D	A2,SDCBUF2
	INT	4

	AND.D	A3,$00FF
	SLL	A3,1
	ADD.D	A3,SDCBUF2   ;store last cluster
	MOV	(A3),$FFFF
	MOV.D	A2,SDCBUF2
	MOV	A1,(FSTFAT)
	IJSR	DELAY
	ADD	A1,A4
	MOVI	A0,14
	INT	4         ;write $FFFF 
	IJSR	SFATC    ; save to fat copy 
	MOV	A0,256    ; and exit ok
SVDE:
	IRET
;----------------------------

FILESAV:
	PUSHXI
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI	A5	
	PUSHI	A6
	PUSHI	A7
	IJSR	FINDFN
	CMPI	A0,0
	JZ	FSV7
	MOVI	A0,0
	JMP	FSVE
FSV7:	MOVI	A5,0

FSV4:	MOV	A1,(CURDIR)
	ADD	A1,A5
	MOVI	A0,13
	MOV.D	A2,SDCBUF1
	INT	4              ; Load Root Folder 1st sector
	MOVI	A0,0
	MOVI	A3,0
	IJSR	DELAY
FSV1:	
	CMP.B (A2),0
	JZ	FSV2
	CMP.B	(A2),$E5
	JNZ	FSV3
FSV2:	                 ; Found free slot
	SETX	10
	MTOM.B A2,A4
	ADDI  A2,11
	MOV.B	(A2),32    ;set archive bit
	ADDI  A2,3
	MOV   (A2),0   ; create time
	ADDI	A2,2
	MOV   (A2),$8750 ; create date
	ADDI  A2,6
	MOV   (A2),0   ; mod. time
	ADDI	A2,2
	MOV   (A2),$8750 ; mod. date
	ADDI	A2,4
	SWAP	A7	     ;store FILE SIZE
	MOV	(A2),A7
	SWAP	A7     
	SWAP.D A7
	SWAP	A7
	ADDI	A2,2
	MOV	(A2),A7
	SWAP	A7
	SWAP.D A7  
	SUBI	A2,4
	IJSR	FREEFAT     ; free
	CMPI	A0,0
	JZ	FSVE
	PUSHI	A0
	SWAP	A0	
	MOV	(A2),A0
	MOVI	A0,14
	MOV	A1,(CURDIR)
	ADD	A1,A5
	MOV.D	A2,SDCBUF1
	INT	4         ; save header
	IJSR	DELAY
	POPI	A0        ; CLUSTER NUM
	PUSHI	A0
	IJSR	SVDATA
	POPI  A0
	JMP	FSVE
FSV3:	
	ADD	A2,32
	ADD	A3,32
	CMP	A3,512
	JNZ	FSV1  ; search same sector
	INC	A5

	MOV	A1,(CURDIR)
	CMP	(FATROOT),A1 ;  *** to be implemented ***
	JNZ   FSVE

	CMP	A5,32  ;if not last root dir sector 
	JNZ	FSV4   ;load next sector and continue search
FSVE:	
	POPI	A7
	POPI	A6
	POPI	A5
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	POPXI
	RETI

;--------INT5 A0=4 DELETE FILE -----------------------

FILEDEL:
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI	A5	
	IJSR	FINDFN
	CMPI	A0,0
	JZ	FDELX
	MOV.B	(A2),$E5  ; Delete file entry
	MOV	A4,A0
	MOVI	A0,14
	MOV	A1,(CURDIR)
	ADD	A1,A5
	MOV.D	A2,SDCBUF1
	INT	4          ; save file header
	IJSR	DELAY
FDL1:	
	MOVI  A5,0
	MOV	A5,A4
	SRL	A5,8   ; DIVIDE BY 256
	MOV	A1,(FSTFAT)
	ADD	A1,A5
	MOVI	A0,13
	MOV.D	A2,SDCBUF2
	INT	4         ; Load FAT cluster
	AND.D	A4,$00FF  ; mod 256	
	SLL	A4,1  
	MOV.D	A5,SDCBUF2
	ADD.D	A5,A4
	MOV	A4,(A5)
	MOV	(A5),0  ; free cluster
	MOVI	A0,14
	INT	4        ; write fat back
	IJSR	DELAY
	IJSR	SFATC  ; write fat copy
	SWAP	A4
	CMP	A4,$FFF0 ; EOF
	JAE	FDELX
	CMPI	A4,0
	JNZ	FDL1
FDELX:
	POPI	A5
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1

	RETI


;-------- MOUNT VOUME ---------------------------

VMOUNT:
	PUSHI	A1
	PUSHI	A2
	MOVI	A0,13
	MOVI	A1,0
	MOV.D	A2,SDCBUF1
	INT	4             ; read MBR
	IJSR	DELAY
      CMP	A0,256
	JNZ	VMEX
	MOV.D	A2,SDCBUF1      
	ADD.D	A2,$1C6
	MOV	A0,(A2)        ; Get 1st partition boot sector 
	SWAP	A0		   ; little endian
	MOV	(FATBOOT),A0  
	MOV	A1,A0           ; A1 fatboot
	MOVI	A0,13
	MOV.D	A2,SDCBUF1
	INT	4              ; Load FAT boot sector
      CMP	A0,256
	JNZ	VMEX
	MOV	(SDFLAG),A0
	ADDI	A2,14
	MOV	A0,(A2)   ; Reserved sectors
	SWAP	A0
	ADD	A1,A0
	MOV	(FSTFAT),A1  ; save first fat cluster num
	ADDI	A2,5
	MOV.B	A0,(A2)      ; Total num of sectors<65536
	ADDI	A2,1
	MOVHH A0,(A2)
	MOV	(SECNUM),A0
	ADDI	A2,2
	MOV	A0,(A2)   ; sectors per fat
	SWAP	A0
	MOV	(SECPFAT), A0
	SLL	A0,1        ; 2 fats
	ADD	A1,A0	    ; Root Folder
	MOV	(CURDIR),A1
	MOV	(FATROOT),A1
	ADD	A1,32     ; 32 bytes * 512 entries =32 sectors
	MOV	(FSTCLST),A1
	MOV	A0,(CURDIR)
VMEX:	POPI	A2
	POPI	A1
	RETI

;-------------------------------------------------
; INT 5,A0=13 Load screen
LDSCR:	IJSR	FINDFN   
		MOV.D	A4,A0
		CMPI	A0,0
		JZ	INTEXIT
		IJSR	SCLOAD
		RETI

;-------------------------------------------------
SCLOAD:	; A4 cluster, A3 Dest address
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI	A5
	PUSHI	A6

	MOVI	A6,0
SLD1:	MOV	A6,A4
	MOVI	A1,0
	SRL	A6,8   ; DIVIDE BY 256
	MOV	A1,(FSTFAT)
	ADD	A1,A6
	MOVI	A0,13
	MOV.D	A2,SDCBUF2
	INT	4              ; Load FAT
	MOVI	A0,13          ;
	MOV	A1,(FSTCLST)
	ADD	A1,A4
	SUBI	A1,2
	MOV.D	A2,SDCBUF1     ; Dest
	INT 	4              ; Load sector
	SETX  255
	MOV.D	A2,SDCBUF1
	MTOI	A3,A2
	CMP.D	A3,64768
	ADD.D	A3,512
	AND.D	A4,$00FF  ; mod 256
	SLL	A4,1  
	MOV.D	A5,SDCBUF2
	ADD.D	A5,A4
	MOV	A4,(A5)
	SWAP	A4
	CMP	A4,0
	;JAZ	A4,SLDE
	JZ	SLDE
	CMP	A4,$FFF0
	JBE	SLD1
SLDE:	POPI	A6
	POPI	A5
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	IRET 



;---------------------------------------------------
; INT 5,A0=2 Load file at A3, ->A1 size
FILELD:	PUSHI	A5
		IJSR	FINDFN    
		MOV.D	A4,A0
		CMPI	A0,0
		JZ	FLEXIT
		IJSR	FLOAD
FLEXIT:	POPI	A5
		RETI
;-------------------------------------------------

DELAY: PUSHXI
	SETX	50000
LDDL: JMPX	LDDL    ;delay
	POPXI
	IRET

FLOAD:	; A4 #cluster, A3 Dest address, A1 size
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI	A5
	PUSHI	A6
	PUSHI	A7
	MOV.D	A5,$FFFFFFFF
	MOV.D	A7,A1
FLD1:	MOVI	A6,0
	MOV	A6,A4
	SRL	A6,8   ; DIVIDE BY 256
	CMP	A6,A5
	JZ    _SKIPLDFAT
	MOV.D	A5,A6
	MOV	A1,(FSTFAT)
	ADD	A1,A6
	MOVI	A0,13
	MOV.D	A2,SDCBUF2
	INT	4              ; Load specific cluster FAT
_SKIPLDFAT:
	MOVI	A0,13          ;
	MOV	A1,(FSTCLST)
	ADD	A1,A4
	SUB	A1,2   ; because cluster start with cluster #2 
      CMP.D A7,512
	JG    _NOTLAST1
	PUSHI	A3
	MOV.D A3,SDCBUF2
_NOTLAST1:
	MOV.D	A2,A3          ; Dest
	INT 	4               ; Load sector
	CMP.D A7,512
 	JG    _NOTLAST2
	SUBI	A7,1 
	SETX	A7
	POPI	A3
	MOV.D	A2,SDCBUF2
	MTOM.B A3,A2
	JMP	FLXT
_NOTLAST2:
	ADD.D	A3,512
	SUB.D	A7,512
	AND	A4,$00FF  ; mod 256
	SLL	A4,1  
	MOV.D	A2,SDCBUF2
	ADD.D	A2,A4
	MOV	A4,(A2)
	SWAP	A4
	CMP	A4,0
	JZ	FLXT
	CMP	A4,$FFF0
	JBE	FLD1
FLXT: POPI	A7
	POPI	A6
	POPI	A5
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	IRET 

FINDF:
	PUSHI	A1
	PUSHI	A2
	PUSHI	A5
	IJSR	FINDFN
	POPI	A5
	POPI	A2
	POPI	A1
	RETI

;Find filename in root directory
; A4 pointer to filename, A0 return cluster(FSTCLST=2nd cluster),  A1 SIZE
; file name in header at A2, directory #cluster at A5 relative to CURDIR 
; changes A1,A2,A5! 
FINDFN:     PUSHXI
		PUSHI	A3
		PUSHI	A4
		MOVI	A5,0
TFF4:		MOV	A1,(CURDIR)
		ADD	A1,A5
		MOVI	A0,13
		MOV.D	A2,SDCBUF1
		INT	4              ; Load directory sector
		MOVI	A0,0
		MOVI	A3,0
TFF1:		CMP.B (A2),0
		JZ	TFF6
		SETX	10
		PUSHI	A2
		PUSHI	A4
TFF2:		CMP.B	(A2),(A4)
		JNZ	TFF3
		ADDI	A2,1
		JXAB	A4,TFF2
		POPI	A4
		POPI	A2
		MOVI	A0,0
		MOV	A0,26(A2)
		SWAP	A0
		MOV.D	A1,28(A2)
		SWAP	A1	         ;FILE SIZE
		SWAP.D A1
		SWAP	A1
		JMP	TFF5
TFF3:		POPI	A4
		POPI	A2
		ADD.D	A2,32
		ADD	A3,32
		CMP	A3,512
		JNZ	TFF1  ; search same sector
		INC	A5

		MOV	A1,(CURDIR) ; if not root search only first 
		;MOV	A0,(FATROOT)
		CMP	(FATROOT),A1 ;  *** to be implemented ***
		JNZ   TFF6

		CMP	A5,32  ;if not last root dir sector 
		JNZ	TFF4   ;load next sector and continue search
TFF6:		MOVI	A0,0
TFF5:		POPI	A4
		POPI	A3
		POPXI
		IRET




;--------------------------------------
WRITESEC:
	PUSHXI
	SETX	5
WRSCR:
	MOVI	A0,14
	IJSR	WSEC
	IJSR 	DELAY
	CMP	A0,256
	JRZ	6
	JMPX	WRSCR
	POPXI	
	RETI

WSEC:
	PUSHXI
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI  A2   ; save buffer address
	OUT	19,0
	MOVI	A3,0
	MOVI	A4,0
	MOV	A4,A1
	MOV.B	A2,(SDHC)
	CMPI.B A2,1
	JZ	WSHC ; is sdhc skip multiply
	;SETX 8
WSLP:	;SLLL	A3,A4 ; multiply 512 to convert block to byte
	SLL.D	A4,9
;	JMPX	WSLP
	SWAP.D A4
	MOV	A3,A4
	MOV	A4,0
	SWAP.D A4
WSHC:
	MOVI	A2,1
	MOV 	A1,$FF  ; send clocks 
	IJSR	SPIS

	MOV 	A1,$58  ; write block
	IJSR	SPIS
	MOVLH	A1,A3
	IJSR	SPIS
	MOV.B	A1,A3
	IJSR	SPIS
	MOVLH	A1,A4
	IJSR	SPIS
	MOV.B	A1,A4
	IJSR	SPIS
	MOVI 	A1,$01 
	IJSR	SPIS 

	SETX 10
WRS0:
	MOV	A1,$FF  
	IJSR	SPIS
	CMPI.B A0,0
	JRZ	6
	JMPX	WRS0
	CMPI.B A0,0
	JNZ	WSHC

	MOV	A1,$FF  
	IJSR	SPIS

	MOV	A1,$FE    ; SEND START OF DATA
	IJSR	SPIS	

	POPI 	A3         ;	MOV	A3,SDCBUF1    ; buffer
	SETX	511        ; WRITE DATA 512 BYTES + 2 CRC bytes
WRI6:	MOV.B	A1,(A3)
	IJSR	SPIS
	JXAB	A3,WRI6
	IJSR	SPIS  ; CRC
	MOVI	A1,1
	IJSR	SPIS  ; CRC

	SETX	9999          ; READ ANSWER until $05 is found
WRS8:	MOV	A1,$FF
	IJSR	SPIS
	AND	A0,$001F
	CMPI.B A0,$5
	JRZ	6
	JMPX	WRS8

	CMPI.B A0,$5
	MOVI	A0,7
	JNZ	WRIF

	SETX	19999          ; READ ANSWER until no $00 is found
WRS9: MOV	A1,$FF
	IJSR	SPIS
	CMPI.B A0,0
	JRNZ	6
	JMPX	WRS9
	
	CMPI.B A0,0
	JZ	WRIF

	MOV	A0,$0100  ; ALL OK

WRIF:	MOV 	A1,$FF  ; send clocks 
	IJSR	SPIS
	OUT	19,2
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	POPXI
	IRET

;-----------------------------------------

READSEC:
	PUSHXI
	SETX	4
RDSCR:
	MOVI	A0,13
	IJSR	READSC
	IJSR	DELAY
	CMP	A0,256
	JRNZ	RDSCR ;6
	;JMPX	RDSCR
	POPXI
	;IJSR	PRNHEX
	RETI
READSC:
	PUSHXI
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4

	PUSHI	A2
	MOVI	A3,0
	MOVI	A4,0
	MOV	A4,A1
	MOV.B	A2,(SDHC)
	CMPI.B  A2,1 ; is sdhc skip multiply
	JZ	RSHC
	;SETX 8
RSLP:	SLL.D	A4,9 ; multiply 512 to convert block to byte
	;JMPX	RSLP
	SWAP.D A4
	MOV	A3,A4
	MOV	A4,0
	SWAP.D A4
RSHC:	OUT	19,0
	MOVI	A2,1
	MOV 	A1,$FF  ; send 8 clocks 
	IJSR	SPIS

	MOV 	A1,$51  ; READ block
	IJSR	SPIS
	MOVLH	A1,A3
	IJSR	SPIS
	MOV.B	A1,A3
	IJSR	SPIS
	MOVLH	A1,A4
	IJSR	SPIS
	MOV.B	A1,A4
	IJSR	SPIS
	MOVI 	A1,$01 
	IJSR	SPIS 

	SETX	9999          ; READ ANSWER until $FE is found
RDS5:	MOV	A1,$FF
	IJSR	SPIS
	CMP.B	A0,$FE
	JZ	SDRD2
	JMPX	RDS5

SDRD2:
	POPI	A3   		; read to buffer
	MOV.B (SDERROR),1
	CMP.B	A0,$FE  
	MOVI	A0,7
	JNZ	RDIF       ; data ready ?
	SETX	513        ; READ DATA 512 BYTES + 2 CRC bytes
RDI6:	MOV	A1,$FF
	IJSR	SPIS
	MOV.B	(A3),A0
	JXAB	A3,RDI6

	MOV 	A1,$FF  ; send clocks 
	IJSR	SPIS

	MOV.B (SDERROR),0
	MOV	A0,$0100  ; ALL OK
	OUT	19,2

RDIF: OUT	19,2
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	POPXI
	IRET


;----------------------------------------------
SPIS:
	OUT	18,A1
	PUSHI	A2
	BSET  A2,0
	OUT	19,A2
	BCLR	A2,0
	OUT	19,A2
SPIC: IN	A0,17
	BTST  A0,0
	JNZ	SPIC
	IN	A0,16
	POPI	A2
	IRET

;--------------- * SD CARD INIT * ----------------
SPI_INIT:
	PUSHXI
	PUSHI 	A1
	PUSHI	A2
	PUSHI	A3
	MOV   (SDHC),0
	MOVI	A3,0

SPIN:	MOV	A0,40
	CMP	A3,20
	JA	SPIF  ; 40 RETRIES FAIL
	OUT	19,2
	SETX	7
	MOVI	A2,3
SPI0: MOV	A1,255	
	IJSR	SPIS
	JMPX	SPI0    ; SEND 80 CLK PULSES WITH CS HIGH
	
	OUT   19,0
	IJSR 	DELAY
	MOVI	A2,1
	;MOV	A1,$FF	
	;IJSR	SPIS
	
	MOV 	A1,$40  ; RESET IN SPI MODE   
	IJSR	SPIS
	MOVI 	A1,$0
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	MOV 	A1,$95
	IJSR	SPIS	

	SETX	7	         ;READ RESPONCES 8 
SPI3:	MOV	A1,$FF
	IJSR	SPIS
	CMPI.B A0,1
	JZ	SPNF
	IJSR	DELAY
	JMPX	SPI3
	
	ADDI 	A3,1	
	JMP	SPIN
SPNF:
	;MOV	A1,$FF
	;JSR	SPIS
; ----- CMD 8 --------------

	OUT	19,2
	IJSR	DELAY
	OUT	19,0	

	MOV 	A1,$48  ; spi cmd 8
	IJSR	SPIS
	MOV 	A1,$00
	IJSR	SPIS
	IJSR	SPIS
	MOVI 	A1,$01
	IJSR	SPIS
	MOV 	A1,$AA
	IJSR	SPIS
	MOV 	A1,$87 ; $86
	IJSR	SPIS 

	SETX  7         ; READ 8 ANSWERS
SP8:  MOV	 A1,$FF
	IJSR	 SPIS
	CMPI.B A0,1
	JBE	 SP8X
	JMPX  SP8
	JMP	SP8END

SP8X:	SETX	3         ; read 4 more
SP82: MOV	 A1,$FF
	IJSR	 SPIS
	JMPX	 SP82
SP8END:
;------------- CMD 55 + ACMD 41 ------------
	MOV	A1,$FF
	IJSR	SPIS
	MOV	A3,0
SPN55:
	OUT	19,2
	IJSR	DELAY
	OUT	19,0
	;MOV	A1,$FF
	;JSR	SPIS

	CMP	A3,50
	MOV	A0,41
	JA	TRYCMD1
	INC	A3

	MOV 	A1,$77  ; spi cmd 55
	IJSR	SPIS
	MOVI 	A1,$00
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	MOV 	A1,$01 
	IJSR	SPIS 

	SETX   7         ; READ 8 ANSWERS
SP55: MOV	 A1,$FF
	IJSR	 SPIS
	CMPI.B A0,1
	JBE	 SP55X
      JMPX   SP55
	JMP    SPN55	
SP55X:

	MOV 	A1,$69  ; INITIALIZE spi cmd 41
	IJSR	SPIS
	MOV	A1,$40  ; $00 or $40 for SDHC support
	IJSR	SPIS
	MOVI 	A1,$00
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	MOV 	A1,$01
	IJSR	SPIS 

	 SETX	7         ; READ 8 ANSWERS
SP413: MOV	A1,$FF
	 IJSR	SPIS
	 CMPI.B A0,0
	 JZ	SKIPCMD1
       JMPX SP413

	SETX	19
BIGD: IJSR	DELAY
	JMPX	BIGD

	JMP	SPN55

;---------------------------
; Command 1 init

TRYCMD1:
	;MOV	A1,$FF
	;JSR	SPIS
	MOV	A3,0
SPNT:	MOVI	A0,1
	OUT	19,2
	IJSR	DELAY
	OUT	19,0
	CMP	A3,50
	MOVI	A0,11
	JA	SPIF
	MOV 	A1,$41  ; INITIALIZE spi
	IJSR	SPIS
	MOVI 	A1,$0
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	MOV 	A1,01 
	IJSR	SPIS 

	SETX	7         ; READ 8 ANSWERS
SPI2:	MOV	A1,$FF
	IJSR	SPIS
	CMPI.B A0,0
	JZ	SPNX
	JMPX	SPI2
	INC	A3
	JMP	SPNT
SPNX:
;-------------------------------------------------------
;---- CMD 58 ---------------------
SKIPCMD1:
	OUT	19,2
	IJSR	DELAY
	OUT	19,0
	MOV	A1,$FF
	IJSR	SPIS

	IJSR DELAY
	MOV 	A1,$7A  ; GET 
	IJSR	SPIS
	MOVI 	A1,$0
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	MOV 	A1,$01
	IJSR	SPIS 

	SETX	7          ; READ ANSWER
SPI7:	MOV	A1,$FF
	IJSR	SPIS
	CMPI.B A0,0
	JZ	SP58NX
	JMPX	SPI7
	JMP	SP58SK
SP58NX:
	MOV	A1,$FF
	IJSR	SPIS
	PUSHI	A0
	IJSR	SPIS
	IJSR	SPIS
	IJSR	SPIS
	POPI	A0
	BTST	A0,6    ; Is it SDHC
	JZ	SP58SK
	MOV.B	(SDHC),1
	JMP	SPSNX
SP58SK:
;--------------------------------------------------------
	;MOV	A1,$FF
	;JSR	SPIS

	OUT	19,2
	IJSR	DELAY
	OUT	19,0
	MOV 	A1,$50  ; SET TRANSFER SIZE
	IJSR	SPIS
	MOVI 	A1,$0
	IJSR	SPIS
	IJSR	SPIS
	MOVI 	A1,$02
	IJSR	SPIS
	MOVI 	A1,$0
	IJSR	SPIS
	MOV 	A1,$01
	IJSR	SPIS 

	SETX	7          ; READ ANSWER
SPI4:	MOV	A1,$FF
	IJSR	SPIS
	CMPI.B A0,0
	JZ	SPSNX
	JMPX	SPI4
	MOVI	A0,8
	JMP	SPIF

SPSNX:
	OUT	19,2
      ; read master boot 
	MOVI	A1,0
	MOV.D	A2,SDCBUF1
	IJSR	READSC
	
	

SPIF: OUT	19,2
	POPI	A3
	POPI	A2
	POPI	A1
	POPXI
	RETI

;---------------------------------------- 
SERIN:	IN		A0,6  ;Read serial byte if availiable
		BTST		A0,1  ;Result in A1, A0(1)=0 if not avail
		JZ		INTEXIT
		IN		A1,4 
		OUT		2,2
		OUT		2,0
		RETI
;----------------------------------------
SEROUT:	IN		A0,6  ;Wite serial byte if ready
		BTST		A0,0  ; A0(0)=0 if not ready
		JZ		SEROUT
		OUT		0,A1
		OUT		2,1
		OUT		2,0
		RETI

;----------------------------------------
 ; VMODE0 PRINT Character in A1 at A2 (XY)
PUTC:		
		PUSHXI   
		PUSHI		A4
		PUSHI		A1
		AND.D		A1,$000000FF  
		IN		A0,24
		CMPI		A0,1   ;(VMODE),1
		JZ		PUTC1  
		BTST		A1,7
		JNZ         P9C
           	SUB.B		A1,32    
		MULU		A1,8
		ADD.D		A1,CTABLE2
		JMP		P10C
P9C:		SUB.B       A1,128
		MULU		A1,8
		ADD.D		A1,CTABLE3		
P10C:		MOV.D		A4,A1      ; character table address
		MOV.B		A0,A2
		MULU		A0,XDIM
		MOVI		A1,0
          	MOVLH 	A1,A2
		MULU		A1,8
		ADD.D		A0,A1
		ADD.D		A0,VBASE   ; video base
		SETX		3          ; 8 bytes
		MTOI		A0,A4
		POPI		A1
		POPI		A4
		POPXI	
		RETI

PUTC1:       ; VMODE1 PRINT Character in A1 at A2 (XY)
		PUSHI		A7
		PUSHI		A6
		PUSHI		A5
		PUSHI		A3
		PUSHI		A2
		BTST		A1,7
		JNZ         P7C		
		SUB.B		A1,32    
		MULU		A1,6
		ADD.D		A1,CTABLE
		JMP		P8C
P7C:		SUB.B       A1,128
		MULU		A1,6
		ADD.D		A1,CTABLE3
P8C:		MOV.D		A4,A1       ; character table address
		MOV.B		A0,A2
		MULU		A0,2560  ;XDIM/2 * 8
		MOVI		A1,0
          	MOVLH 	A1,A2
		MULU		A1,6   ; 6/2
		ADD.D		A0,A1
		ADD.D		A0,VBASE1   ; video base
		MOVI		A2,0
		MOVI		A1,0
		MOV.B		A2,(BCOL)
		MOV.B		A1,(FCOL)
		SETX		2 ; 3 font words
P2C:		
		MOVI		A6,0
		MOV		A7,(A4) ; get font word
		ADDI		A4,2
P1C:		MOVI		A5,0
		MOVI		A3,15
            SUB.D		A3,A6
		BTST		A7,A3
		JZ		P4C
		MOV.B		A5,A1
		JMP		P5C
P4C:		MOV.B		A5,A2
P5C:		SWAP		A5
		SUBI		A3,8
		BTST		A7,A3
		JZ		P6C
		MOV.B		A5,A1
		JMP		P3C
P6C:		MOV.B		A5,A2
P3C:		OUT		A0,A5
		ADD.D		A0,320 ;160
		INC		A6
		CMPI		A6,7
		JBE		P1C
		SUB.D		A0,8*320
		JXAW		A0,P2C
		POPI		A2
		POPI		A3
		POPI		A5
		POPI		A6
		POPI		A7
		POPI		A1
		POPI		A4
		POPXI
		RETI

;----------------------------------------
PSTR:		PUSHI	A3
		PUSHI	A4
		PUSHI	A5
		MOV.B	A3,XCC
		MOV.B	A4,YCC
		MOV.D	A5,A1
		IN	A0,24
		CMPI	A0,0 ;(VMODE),1
      	JZ	PSTR0
		MOV.B	A3,XCC2
		MOV.B	A4,YCC2
PSTR0:	;MOVI	A1,0     ; PRINT 0 OR 13 TERM.STR POINTED BY A1 AT A2
		MOV.B	A1,(A5)
		CMPI.B A1,0
		JZ	STREXIT
		CMPI.B A1,13
		JZ  	STREXIT
PSTR2:	MOVI	A0,4
		INT	4
		ADD.D	A2,$0100
		SWAP	A2
		CMP.B	A2,A3
		SWAP	A2
		JB	PSTR3
		ADDI	A2,1
		AND.D	A2,$00FF
		CMP.B	A2,A4
		JAE	STREXIT
PSTR3:	ADDI	A5,1
		JMP	PSTR0
STREXIT:	POPI	A5
		POPI	A4
		POPI	A3
		RETI

;----------------------------------------

SCROLL:	PUSHXI
		PUSHI		A1
		IN		A0,24
		BTST		A0,0 ;(VMODE),1
		JNZ		SCROLL1
		SETX		9279     ;4639 ;5759	
		MOV.D		A0,VBASE
		MOV.D		A1,33408   ; 49152+384
		ITOI		A0,A1
		MOV.D		A0,51328
		SETX		319
		NTOI		A0,0		
		POPI		A1
		POPXI
		RETI

SCROLL1:	SETX		30719          ;5759	
		MOV.D		A0,VBASE1
		MOV.D		A1,35328       
		ITOI		A0,A1
		MOV.D		A0,94208
		MOV.B		A1,(BCOL)
		MOVHL		A1,(BCOL)
		SETX		1279
		NTOI		A0,A1	
		POPI		A1
		POPXI
		RETI
;----------------------------------------

CLRSCR:	
		IN	A0,24
		CMPI	A0,1 ;(VMODE),1
		JZ	CLRSCR1
		PUSHXI
		SETX	9599      ;5952	
		MOV.D	A0,VBASE
		NTOI  A0,0
		POPXI
		RETI

CLRSCR1:	PUSHXI
		PUSHI	A1
		MOV.B	A1,(BCOL)
		MOVHL A1,(BCOL)
		SETX	31999   
		MOV.D	A0,VBASE1
		NTOI	A0,A1
		POPI	A1
		POPXI
		RETI

;----------------------------------------
PLOT:		IN	A0,24
		;SDP   0
		CMPI	A0,1  ;(VMODE),1
		JZ	PLOT1
		PUSHI		A1
		PUSHI		A2        ; PLOT at A1,A2 mode in (PLOTM)
		PUSHI		A4
		MOVI		A4,0
		MOV.B		A4,(PLOTM)
		MOV.D		A0,A2
		NOT.D		A0
		AND.D		A0,7
		SRL.D		A2,3
		MULU		A2,XDIM
		ADD.D		A2,A1
		ADD.D		A2,VBASE 
		IN		A1,A2
		BTST		A2,0
		JNZ		PL6
		ADDI		A0,8
PL6:		OR.B		A4,A4
		JNZ		PL3
		BCLR		A1,A0   ; mode 0  clear
		JMP		PL4
PL3:		CMP.B		A4,1
		JNZ		PL5
		BTST		A1,A0  ; mode 2  not
		JZ		PL5
		BCLR		A1,A0
		JMP		PL4
PL5:		BSET		A1,A0    ; mode 1  set
PL4:		OUT		A2,A1
		POPI		A4
		POPI		A2
		POPI		A1
		RETI

PLOT1:	PUSHI		A1
		PUSHI		A2        ; PLOT at A1,A2 mode in A4
		MOV.B		A0,(PLOTM)
		MULU		A2,XDIM22
		ADD.D		A2,A1
		ADD.D		A2,VBASE1
P1L7:		BTST		A0,0
		JNZ		P1L6
		MOV.B		A1,(BCOL)
		JMP		P1L5
P1L6:		MOV.B		A1,(FCOL)
P1L5:		OUT.B		A2,A1
		POPI		A2
		POPI		A1
		RETI

;-------------------------------------- 
; plot a line a1,a2 to a3,a4

LINEXY:
	STI
	PUSHXI
	PUSHI 	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI	A5
	PUSHI	A6
	PUSHI	A7
	MOVI  A5,1
	SUB   A3,A1 ; A3=dx
	JNZ   LXY11
	MOVI	A5,0
	JMP   LXY1
LXY11: JNC	LXY1 
	MOV	A5,-1
	NEG	A3
LXY1: MOVI	A6,1 
	SUB	A4,A2 ; A4=dy
	JNZ	LXY22	
	MOVI	A6,0	
	JMP	LXY2
LXY22: JNC	LXY2
	NEG	A4
	MOV	A6,-1
LXY2: CMP	A3,A4
	JC	LXY33
	SETX  A3 
	MOV	A7,A4
	SLA	A7,1
	SUB	A7,A3  ; E=2*dy-dx 
	JMP	LXY3
LXY33: 
	MOV	A7,A3
	SLA	A7,1
	SUB	A7,A4  ; E=2*dx-dy 
	SETX	A4
LXY3: SLL	A4,1  ;2*dy
	SLL	A3,1  ;2*dx
LXY4: MOVI	A0,2
	INT	4     ; plot a point
	MOV	A0,A3
	OR	A0,A4
	JZ    LXY0   ; if both 0 skip interation
LXY7:	CMP	A7,0
	JL	LXY0
	CMP	A3,A4  ; 2dx,2dy	
	JNC   LXY5   ;
	SUB	A7,A4  ; dy>dx
	ADD   A1,A5
	JMP	LXY6
LXY5: SUB   A7,A3  ; dx>=dy
	ADD	A2,A6
LXY6: JMP	LXY7
LXY0: CMP	A3,A4
	JNC   LXY8
	ADD	A7,A3
	ADD   A2,A6
	JMP	LXY9
LXY8: ADD   A7,A4
	ADD	A1,A5
LXY9:	JMPX  LXY4	
	POPI	A7
	POPI	A6
	POPI	A5
	POPI	A4	
	POPI	A3
	POPI	A2
	POPI	A1
	POPXI
	RETI

;------- CIRCLE ---------------------------

CIRPLT:
	MOV	A1,A5
	ADD	A1,(CIRCX)
	MOV	A2,A6
	ADD	A2,(CIRCY)	
	MOVI	A0,2
	INT	4         ; 1 octant
 	MOV	A1,A5
	NEG	A1
	ADD	A1,(CIRCX)	
	MOVI	A0,2
	INT	4         ; 2 octant
	MOV	A2,A6
	NEG	A2
	ADD	A2,(CIRCY)	
	MOVI	A0,2
	INT	4         ; 3 octant
	MOV	A1,A5
	ADD	A1,(CIRCX)	
	MOVI	A0,2
	INT	4         ; 4 octant
	IRET

CIRC:	
	PUSHI 	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A5
	PUSHI	A6
	PUSHI	A7
	MOV	(CIRCX),A1  
	MOV	(CIRCY),A2  
	MOV	A5,A3  ; A3=r A5=x
	MOVI	A6,0	 ; A6=y
	IJSR	CIRPLT
	XCHG	A5,A6
	IJSR	CIRPLT
	XCHG	A5,A6
	MOVI	A7,1   ; A7=P
	SUB	A7,A3  ; P=1-r
CIR1:	CMP	A5,A6
	JLE	CIRX   ; while x>y
	INC	A6
	MOV	A0,A6
	SLA	A0,1 ; A0=2*y
	INC	A0
	CMP	A7,0
	JL	CIR2
	DEC	A5
	SUB	A7,A5
	SUB	A7,A5
CIR2:	ADD	A7,A0
	IJSR	CIRPLT
	XCHG	A5,A6
	IJSR	CIRPLT
	XCHG	A5,A6
	JMP	CIR1
CIRX:	POPI	A7
	POPI	A6
	POPI	A5	
	POPI	A3
	POPI	A2
	POPI	A1
	RETI

;--------------------------------------------------------------
; Multiplcation A1*A2 res in A1,

MULT:		
		MUL.D       A1,A2
		RETI

;-------------------------------------------------------------
; Div A2 by A1 res in A1,A0

DIV:		
		CMPI		A1,0
		JNZ		DIV0
		MOV.D		A1,$7FFFFFFF
		MOVI		A0,0
		RETI	
DIV0:		PUSHI		A3
		MOVI		A3,0
		MOV.D		A0,A1
		XOR.D		A0,A2
		JP		DIV1     ; Check result sign
		MOVI		A3,1
DIV1:		MOV.D		A0,A2		
		BTST		A1,31
		JRZ		2
		NEG.D		A1
		BTST		A2,31
		JRZ		4
		NEG.D		A2
		BSET		A3,1
		CMP.D		A1,A2
		JLE		DIV4
		MOVI		A1,0    ;A0=A2   id divider > divident res=0 rem=divident	
		JMP		DIVE
DIV4:		PUSHI		A3
		MOV.D		A0,A2
		ALNG		A0,A2
		ALNG		A1,A3
		XCHG		A3,A1
		SUB.D		A1,A2
DIV10:	CMPI		A2,0
		JZ		DIV9
		SRL.D		A3,1  ; align back
		SRL.D		A0,1
		SUBI		A2,1
		JMP		DIV10
DIV9:		MOV.D       A2,A1
		MOVI		A1,0     ; quotient
DIV11:	CMP.D		A0,A3  ; compare remainder with divisor
		JC		DIV8		
		BSET		A1,A2
		SUB.D		A0,A3
DIV8:		SRL.D		A3,1
		SUBI		A2,1
		JP		DIV11 
DIV14:	POPI		A3
		BTST		A3,0
		JRZ		2
		NEG.D		A1
		BTST		A3,1
		JRZ		DIVE
		NEG.D		A0
DIVE:		POPI		A3
		RETI

;-------------------------------------------------------------
; unsigned Div A2 by A1 res in A1,A0

UDIV:		
		CMPI		A1,0
		JNZ		UDIV3
		MOV.D		A1,$FFFFFFFF
		MOVI		A0,0
		RETI
UDIV3:	CMP.D		A1,A2
		JBE		UDIV4
		MOV.D		A0,A2  ; id divider > divident res=0 rem=divident
		MOVI		A1,0
		RETI
UDIV4:	PUSHI		A3
		MOV.D		A0,A2 ; main algorithm
		ALNG		A0,A2
		ALNG		A1,A3
		XCHG		A3,A1
		SUB.D		A1,A2
UDIV10:	CMPI		A2,0
		JZ          UDIV9
		SRL.D		A3,1
		SRL.D		A0,1
		SUBI		A2,1
		JMP		UDIV10
UDIV9:	MOV.D		A2,A1  
		MOVI		A1,0       ; quotient
UDIV11:	CMP.D		A0,A3  ; compare remainder with divisor
		JC		UDIV8		
		BSET		A1,A2
		SUB.D		A0,A3
UDIV8:	SRL.D		A3,1
		SUBI		A2,1
		JP		UDIV11
		POPI		A3
		RETI


; -------------------------------------
SKEYBIN:	
		IN	A0,6  ;Read key byte if availiable
		BTST	A0,2  ;Result in A1, A0(2)=0 if not avail
		JZ	INTEXIT
		IN	A1,14
		OUT	15,2
		OUT	15,0
		RETI
;---------------------------------------
KEYB:		
		PUSHXI
		CMP.B	A1,$5A 
		JNZ	NOTCR
		MOVI	A1,13
		JMP	KB10
NOTCR:	CMP.B	A1,$66
		JNZ	NOTBS
		MOVI	A1,8
		JMP	KB10
NOTBS:	CMP.B	A1,$76
		JNZ	KB1
		MOV	A1,27
		JMP	KB10		
KB1:		SETX 	55           ; Convert Keyboard scan codes to ASCII
		MOV.D	A0,KEYBCD
KB3:		CMP.B	A1,(A0)
		JZ	KB4
		JXAB	A0,KB3
		JMP	KB10
KB4:		SUB.D A0,KEYBCD
		BTST  A1,9
		JZ   KB2
		BTST A1,8
		JNZ	KB2
		ADD.D   A0,KEYASCC
		JMP	KB6
KB2:		BTST  A1,8
		JZ   KB5
		ADD.D   A0,KEYASCS
		JMP   KB6
KB5:		ADD.D	A0,KEYASC
KB6:        MOV.B A1,(A0)
KB10:		POPXI
		RETI

FGETSZ:
	MOV.D A0,18(A1)
	RETI

FGETPOS:
	MOV.D A0,14(A1)
	RETI

FSEEK: PUSHI A3
	 MOVI	A0,1
	 MOV.B A3,(A1)
	 BTST A3,7
	 JZ FSKEXT
	 MOVI	A0,0
	 MOV.B A3,1(A1)
	 CMP.B A3,114    ; is it readonly
	 JNZ  FSEK1      ; 
	 MOV.D A3,18(A1) ; file size
	 CMP.D A2,A3
	 JB  FSEK1
	 MOVI	A0,2
	 SUBI	 A3,1
	 MOV.D A2,A3
FSEK1: MOV.D 14(A1),A2
FSKEXT: POPI A3	 
	 RETI

; fill buffer at A3 with cluster containing the A1th of a file starting at cluster A4
; A0 #cluster in buffer
FILLBUF:     
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI	A5
	PUSHI	A6
	PUSHI	A7
	MOV.D	A5,$FFFFFFFF
	MOV.D	A7,A1
	MOVI	A1,0
FB1:	MOVI	A6,0
	MOV.D	A6,A4
	SRL	A6,8   ; DIVIDE BY 256
	CMP	A6,A5
	JZ    _SKIPBFAT
	MOV.D	A5,A6
	MOV	A1,(FSTFAT)
	ADD	A1,A6
	MOVI	A0,13
	MOV.D	A2,SDCBUF2
	INT	4              ; Load specific cluster FAT
_SKIPBFAT:
	MOV	A1,(FSTCLST)
	ADD	A1,A4
	SUB	A1,2   ; because cluster list starts with cluster #2 
      CMP.D  A7,511
 	JG   _NOTBLAST2
	MOV.D A2,A3
	MOVI	A0,13
	INT 	4
	MOV.D A0,A4
	JMP	FBXT
_NOTBLAST2:
	SUB.D	A7,512
	AND.D	A4,$00FF  ; mod 256
	SLL	A4,1  
	MOV.D	A2,SDCBUF2
	ADD.D	A2,A4
	MOV	A4,(A2)
	SWAP	A4
	CMP	A4,0
	JZ	FBXT
	CMP	A4,$FFF0
	JBE	FB1
FBXT: POPI	A7
	POPI	A6
	POPI	A5
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	IRET


; A1=File handle  A2=number of bytes A3=pointer to buffer
; A1 last char read A0=bytes read
FREAD:
	PUSHI  A4
	PUSHI  A5
	PUSHI	 A6
	PUSHI  A7
	MOVI  A0,0
	CMP.D  A2,0
	JLE	FREXIT
	CMP.B (A1),128  ; is it open
	JB	FREXIT
      MOV.D  A4,14(A1) ; FILEPOS
	MOV.D  A5,18(A1) ; FILESIZE
      MOV.D  A6,10(A1) ; fileblock num in buffer 
	MOVI	A0,0
      MOV.D  A7,A5
	SUB.D  A7,A4 ;filesize-filepos
	JLE	FREXIT
	CMP.D  A7,A2                         
	JNC   FR2
	MOV.D  A2,A7
FR2:	CMPI	 A2,1
	JL    FREXIT
	PUSHI	A2
	MOV.D	 A7,A4  ; FILEPOS
	SRL.D  A7,9
	CMP.D	 A7,A6
	JNZ	FR1	; is filepos in current buffer
FRL4:	MOV.D	A7,A4
	AND.D A7,$000001FF
	MOV.D A5,2(A1) ; buffer pointer
	ADD.D A5,A7
FRL2:	MOV.B A0,(A5)
	MOV.B (A3),A0
 	ADDI	A3,1
	ADDI	A5,1
	ADDI	A4,1  ; inc file pos
	SUBI	A2,1  ; dec byte count
	JZ	FR3
	MOV.D	A7,A4
	AND.D A7,$000001FF
	JNZ	FRL2
FR1:  PUSHI	A0
	PUSHI	A1     ; bring the next data page in buffer
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	IJSR  FLUSH
	MOV.D	A7,A4   ;fill buffer at A3 with cluster containing the A1th of a file starting at cluster A4
	MOV.D	A4,6(A1)
	MOV.D	A3,2(A1)
	MOV.D A1,A7
	IJSR  FILLBUF
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	POPI	A0
	MOV.D	A6,A4  ; current filepos
	SRL.D A6,9
	MOV.D 10(A1),A6 ; update data page num in buffer
	MOV.D 14(A1),A4  ; update file pos idx
	JMP	FRL4
FR3:	MOV.D 14(A1),A4 ; set and exit
	MOVI	A1,0
	MOV.B A1,A0
	POPI	A0
FREXIT:
	POPI	A7
	POPI  A6
	POPI	A5
	POPI	A4
	RETI


OPENRD:	CMPI	A0,0
		JZ	OFEXER
		MOV.B 1(A6),A7  ; type
		MOV.B	(A6),128  ; open 
		MOV.D	18(A6),A1  ; size
 		MOV.D	6(A6),A0  ; First Cluster
		MOVI	A5,0
		MOV.D 10(A6),A5 ; Cluster in buf
            MOV.D 14(A6),A5 ; File pos
		MOVI  A0,7
		MOV.D A1,514
		INT   5        ; reserve file buffer
		MOV.D 2(A6),A0
		MOV.D A2,A0
		MOV.D A1,6(A6)  ; load data page-cluster 512 bytes
		MOVI	A0,0
		MOV	A0,(FSTCLST)
 		ADD.D	A1,A0
		SUBI	A1,2
            MOVI	A0,13
		INT   4
		MOV.D  A0,A6
            MOV.D  A1,2(A6)
		JMP	OFEXIT

WRBUF:     ; write buffer pointed by A3 at A1th cluster of a file starting at cluster A4
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI	A5
	PUSHI	A6
	PUSHI	A7
	MOV.D	A5,$FFFFFFFF
	MOV.D	A7,A1
	MOVI	A1,0
WFB1:	MOVI	A6,0
	MOV.D	A6,A4
	SRL	A6,8   ; DIVIDE BY 256
	CMP	A6,A5
	JZ    _SKIPWFAT
	MOV.D	A5,A6
	MOV	A1,(FSTFAT)
	ADD	A1,A6
	MOVI	A0,13
	MOV.D	A2,SDCBUF2
	INT	4              ; Load specific cluster FAT
_SKIPWFAT:
	MOV	A1,(FSTCLST)
	ADD	A1,A4
	SUB	A1,2   ; because cluster start with cluster #2 
      CMPI  A7,0
 	JG   _NOTWLAST2
	MOV.D A2,A3
	MOVI	A0,14
	INT 	4
	JMP	FWXT
_NOTWLAST2:
	SUBI	A7,1
	AND.D	A4,$00FF  ; mod 256
	SLL	A4,1  
	MOV.D	A2,SDCBUF2
	ADD.D	A2,A4
	MOV	A4,(A2)
	SWAP	A4
	CMP	A4,0
	JZ	FWXT
	CMP	A4,$FFF0
	JBE	WFB1
FWXT: POPI	A7
	POPI	A6
	POPI	A5
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	IRET


; A1=File handle
FLUSH:
	PUSHI	A0
	PUSHI	A1
	PUSHI	A3
	PUSHI	A4
	MOV.B A0,(A1)
	BTST	A0,0
	JZ	FLEX
	BCLR  A0,0
	MOV.B (A1),A0
	MOV.D	A0,A1
	MOV.D	A3,2(A0)
	MOV.D	A4,6(A0)
      MOV.D A1,10(A0)
	IJSR	WRBUF
FLEX:	POPI	A4
	POPI  A3
	POPI	A1
	POPI  A0
      IRET

;FTAB:   ; FILE TABLES
;FSTATUS     DS	1  ;0 Open or not 
;FATYPE      DS    1  ;1 r w a 
;FBUFPTR     DS	4  ;2 ptr to buffer
;FCLSTPTR    DS    4  ;6 first file cluster 
;FBUFCNUM    DS    4  ;10 no of file page in buffer 
;FILEPOS	 DS	4  ;14 file position
;FILESIZE    DS	4  ;18 file size
;FFNAME      DS	12 ;22 NAME
;RESTFT      DS    374

; fill buffer at A3 with cluster containing the A1th of a file starting at cluster A4

; A1=file handle 
FWNEWSEC:
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI	A6
	PUSHI	A7
	PUSHXI
	PUSHI	A1 
	MOV.D A4,14(A1) ; pos
	MOV.D A7,18(A1) ; size
	OR.D  A7,$01FF
	CMP.D A7,A4
	JA    NSCE
	IJSR  FLUSH
	MOV.D A3,2(A1)
	MOV.D A7,18(A1)
	MOV.D	A4,6(A1)
	PUSHI	A1
	SUBI	A7,1
	MOV.D A1,A7
	IJSR  FILLBUF ; fill with last file cluster (returns no in A0)
	POPI	A1
	MOV.D	A7,14(A1) ;pos
	SRL	A7,9
	MOV.D 10(A1),A7 ; set page in buffer finaly
	MOV.D	A2,2(A1)
	SETX	255
	NTOM	A2,0
	MOV.D	A7,14(A1) ;pos
      MOV.D A6,18(A1) ;size
	SUB.D	A7,A6  ; space in bytes to add
	ADDI	A7,1
	MOV.D	A6,A1
	MOV.D	A3,A0   ;first (last of file) target cluster from FILLBUF
	MOV.D A4,A3
	SRL.D	A4,8 
	JMP	FNS3
FNS1: IJSR	DELAY
	MOV.D	A4,A3
	SRL.D	A4,8    ; divide 256
	MOV	A1,(FSTCLST)
	ADD.D	A1,A3   ; to cluster
	SUBI	A1,2
	MOVI	A0,14
	MOV.D	A2,2(A6)
	INT	4
	CMP.D	A7,512  ; size
	JBE	FNS2
	SUB.D	A7,512
FNS3:	IJSR	FREEFAT   ; find free fat entry
	CMPI	A0,0     ; Is it full
	JZ	NSCE

	SWAP	A0
	CMP.B A0,A4    ; same fat offset
	SWAP	A0
	JZ	FNORELD

	IJSR	DELAY
	PUSHI	A0
	MOVI	A1,0
	MOV	A1,(FSTFAT)
	ADD	A1,A4
	MOVI	A0,13
	MOV.D	A2,SDCBUF2
	INT	4
	POPI	A0
	
FNORELD:
	IJSR	DELAY
	AND	A3,$00FF
	SLL	A3,1
	ADD.D	A3,SDCBUF2   ;store next cluster
	SWAP	A0
	MOV	(A3),A0
	SWAP	A0
	PUSHI	A0

	MOV.D	A2,SDCBUF2
	MOVI  A1,0
	MOV	A1,(FSTFAT)
	ADD	A1,A4
	MOVI	A0,14
	INT	4
	IJSR	SFATC    ; save to fat copy
	POPI	A3
	JMP	FNS1
FNS2:	
	MOV	A1,(FSTFAT)
	ADD	A1,A4
	MOVI	A0,13
	MOV.D	A2,SDCBUF2
	INT	4

	AND.D	A3,$00FF
	SLL	A3,1
	ADD.D	A3,SDCBUF2   ;store last cluster
	MOV	(A3),$FFFF
	MOV.D	A2,SDCBUF2
	MOV	A1,(FSTFAT)
	IJSR	DELAY
	ADD	A1,A4
	MOVI	A0,14
	INT	4         ;write $FFFF 
	IJSR	SFATC    ; save to fat copy 
	MOV	A0,256    ; and exit ok
NSCE:	POPI	A1
	POPXI
	POPI	A7
	POPI	A6
	POPI	A4
	POPI	A3
	POPI	A2
	IRET

; A1=File handle  A2=byte 
; A0=error code 0=success
FWRITE:    
	PUSHI	 A1
	PUSHI	 A3
	PUSHI  A4
	PUSHI	 A6
	PUSHI  A7
	MOVI  A0,1
	CMP.B (A1),128  ; is it open
	JC	WREXIT
	MOV.B A0,1(A1)
	CMP.B A0,114
	MOVI  A0,2
	JZ	WREXIT
WR1:	MOV.D  A4,14(A1) ; FILEPOS
	MOV.D  A7,18(A1) ; FILESIZE
      MOV.D  A6,10(A1) ; fileblock num in buffer 
	MOVI	A0,0
	CMP.D  A7,A4 ;filesize-filepos
	JA	WR2
	IJSR	FWNEWSEC
	MOV.D	A7,A4
	ADDI	A7,1
	MOV.D 18(A1),A7 ; Set new size
	;MOV.D A7,A4
	;SRL.D  A7,9
	;MOV.D 10(A1),A7
	;MOV.D A6,A7
	;JMP	WR4
WR2:  MOV.D	 A7,A4    ; FILEPOS
	MOV.D  A6,10(A1) 
	SRL.D  A7,9
	CMP.D	 A7,A6
	JNZ	WR3	   ; is filepos in current buffer
WR4:	MOV.D A7,A4
	AND.D	A7,$1FF
	MOV.D	A4,2(A1)
	ADD.D A4,A7
	MOV.B (A4),A2 ; Write the byte
	MOV.B A0,(A1)
	BSET	A0,0
	MOV.B (A1),A0 ; Mark buffer dirty
	MOV.D  A7,14(A1) ; FILEPOS
	ADDI	A7,1
	MOV.D 14(A1),A7 ; advance file pointer
	MOVI	A0,0
	JMP	WREXIT
WR3:  PUSHI A1
	PUSHI	A3
	PUSHI	A4
	IJSR  FLUSH
	MOV.D	A4,6(A1)
	MOV.D	A3,2(A1)
	MOV.D A1,14(A1)
	IJSR  FILLBUF
	POPI	A4
	POPI	A3
	POPI	A1
	MOV.D	 A7,14(A1)
	SRL.D  A7,9
	MOV.D  10(A1),A7
	JMP	WR4
WREXIT:
	POPI	A7
	POPI  A6
	POPI	A4
	POPI	A3
	POPI	A1
	RETI


OPENWR:	PUSHI A4
		PUSHXI
		CMPI	A0,0
		JZ    OWR1
		MOVI  A0,4 ; delete if exitsts
		INT   5
OWR1:		MOV.B 1(A6),A7  ; type
		MOV.B	(A6),128  ; open 
		MOVI  A0,7
		MOV.D A1,514
		INT   5        ; reserve file buffer
		MOV.D 2(A6),A0
		SETX	255
		NTOM  A0,0  ; clear buffer
		PUSHI	A6
		MOV.D A6,A0
		MOV.D	A7,0
		MOVI	A0,5
		INT   5   ; Create file
		POPI  A6
		MOV.D	6(A6),A0 ;first cluster
		MOVI	A0,0
		MOV.D 18(A6),A0
		MOV.D 14(A6),A0
            MOV.D 10(A6),A0
		;IJSR	FINDFN
		MOV.D	A0,A6
		POPXI
		POPI  A4
		JMP	OFEXIT


OPENAP:	CMPI	A0,0
		JZ	OFEXER
		PUSHI A4
		PUSHXI
		MOV.D	6(A6),A0  ; First Cluster
		MOV.B 1(A6),A7  ; type
		MOV.B	(A6),128  ; open 
		MOV.D	18(A6),A1  ; size
            MOV.D 14(A6),A1 ; File pos (at end of file)
		MOVI  A0,7
		MOV.D A1,514
		INT   5        ; reserve file buffer
		MOV.D 2(A6),A0
		MOV.D A2,14(A6)
		MOV.D	A1,A2
		SRL.D A1,9
		MOV.D 10(A6),A1 ; #page in buffer
		AND.D   A2,$01FF
		JNZ   OA1      ; is last data page full?
	      SETX	255
		NTOM  A0,0
		JMP	OAEX
OA1:		; bring the last data page in buffer
		MOV.D	A4,6(A6)
		MOV.D	A3,2(A6)
		MOV.D A1,14(A6)
		IJSR   FILLBUF ;fill at A3 with the containing A1th of a file starting at A4
OAEX:		MOV.D  A0,A6
            MOV.D  A1,2(A6)
		POPXI
		POPI	A4
		JMP	OFEXIT

	; A4=&filename STATUS 128=OPENED 0=NOT OPEN 
OPENFILE:	PUSHI	A2
		PUSHI	A5
		PUSHI	A6
		PUSHI	A7
		PUSHXI
		MOV.D A6,FTAB
		MOV	A0,MAXFILES
OF1:		CMP.B	(A6),0
		JZ	OF2
		ADD.D	A6,34
		DEC	A0
		JNZ  OF1
		MOV.D	A0,-1
		JMP	OFEXER
OF2:		PUSHI	A1
		IJSR	FINDFN
		POPI	A7
		CMP.B	(A7),114  ; 'r'
		JZ    OPENRD
		CMP.B	(A7),119     ; 'w'
		JZ    OPENWR
		CMP.B	(A7),97     ; 'a'
		JZ    OPENAP
		MOV.D	A0,-1
		JMP   OFEXER
OFEXIT:	ADD.D	A0,22
		SETX 11
		MTOM.B A0,A4
		SUB.D A0,22
OFEXER:	POPXI
		POPI	A7
		POPI	A6
		POPI	A5
		POPI	A2
		RETI

; Set file length in directory
FSETLEN:
	PUSHI	A1
	PUSHI	A2
	PUSHI	A3
	PUSHI	A4
	PUSHI	A5
	MOV.D	A3,18(A1)
	MOV.D A4,A1
	ADD.D	A4,22
	IJSR	FINDFN	
	SWAP	A3	         ;FILE SIZE
	SWAP.D A3
	SWAP	A3
	MOV.D	28(A2),A3
	MOV	A1,(CURDIR)
	ADD	A1,A5
	MOVI	A0,14
	MOV.D	A2,SDCBUF1
	INT	4   ; write directory 
	POPI	A5
	POPI	A4
	POPI	A3
	POPI	A2
	POPI	A1
	IRET

; A1=file handle
CLOSEFILE:  
		MOV.B A0,(A1)
		BTST  A0,0
		JZ  CLF1
		IJSR FLUSH
CLF1:		MOV.B A0,1(A1)
		CMP.B A0,114
		JZ  CLF2
		IJSR FSETLEN
CLF2:		MOVI A0,0
		MOV (A1),A0
		MOV.D 2(A1),A0
		MOV.D 6(A1),A0
		MOV.D 10(A1),A0
		MOV.D 14(A1),A0
		MOV.D 18(A1),A0
		MOV.D 22(A1),A0
		RETI


KEYBCD	DB    $29,$45,$16,$1E,$26,$25,$2E,$36,$3D,$3E,$46,$1C,$32,$21,$23,$24,$2B,$34,$33,$43,$3B,$42,$4B
            DB    $3A,$31,$44,$4D,$15,$2D,$1B,$2C,$3C,$2A,$1D,$22,$35,$1A
		DB    $0E,$4E,$55,$5D,$54,$58,$4C,$52,$41,$49,$4A,$72,$6B,$74,$75     ; `-=\[];',./
		DB	$A5,$AB,$A2,$A4

KEYASC	DB    32,48,49,50,51,52,53,54,55,56,57,65,66,67,68,69,70,71,72,73,74,75,76
            DB    77,78,79,80,81,82,83,84,85,86,87,88,89,90
  		DB	96,45,61,92,91,93,59,39,44,46,47,50,52,54,56
            DB    200,201,202,203

KEYASCS	DB    32,41,33,64,35,36,37,94,38,42,40,65,66,67,68,69,70,71,72,73,74,75,76
            DB    77,78,79,80,81,82,83,84,85,86,87,88,89,90
  		DB	126,95,43,124,123,125,58,34,60,62,63,50,52,54,56
		DB    200,201,202,203

KEYASCC	DB    32,48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102,103,104,105,106,107,108
            DB    109,110,111,112,113,114,115,116,117,118,119,120,121,122
  		DB	96,45,61,92,91,93,59,39,44,46,47,50,52,54,56
		DB    200,201,202,203

ROMEND:
; Charcter table Font
CTABLE2	DB	0,0,0,0,0,0,0,0, 0,96,250,250,96,0,0,0;!
CC34_35	DB	0,224,224,0,224,224,0,0, 40,254,254,40,254,254,40,0; # "
CC36_37	DB	36,116,214,214,92,72,0,0, 98,102,12,24,48,102,70,0  ; $ %
CC38_39     DB    12,94,242,186,236,94,18,0, 32,224,192,0,0,0,0,0 ; & '
CC40_41	DB	0,56,124,198,130,0,0,0, 0,130,198,124,56,0,0,0  ; ( )
CC42_43	DB	16,84,124,56,56,124,84,16, 16,16,124,124,16,16,0,0 ; * +
CC44_45	DB	0,1,7,6,0,0,0,0, 16,16,16,16,16,16,0,0; , -
CC46_47	DB	0,0,0,6,6,0,0,0, 6,12,24,48,96,192,128,0 ; . /
CC48_49	DB	124,254,142,154,178,254,124,0, 2,66,254,254,2,2,0,0 ; 0 1
CC50_51	DB	70,206,154,146,246,102,0,0, 68,198,146,146,254,108,0,0 ; 2 3
CC52_53	DB	24,56,104,202,254,254,10,0, 228,230,162,162,190,156,0,0 ; 4 5
CC54_55	DB	60,126,210,146,158,12,0,0, 192,192,142,158,240,224,0,0; 6 7
CC56_57	DB	108,254,146,146,254,108,0,0, 96,242,146,150,252,120,0,0; 8 9
CC58_59	DB	0,0,102,102,0,0,0,0, 0,1,103,102,0,0,0,0 ; : ;
CC60_61	DB	16,56,108,198,130,0,0,0, 36,36,36,36,36,36,0,0; < =
CC62_63	DB	0,130,198,108,56,16,0,0, 64,192,138,154,240,96,0,0 ; > ?
CC64_65	DB	124,254,130,186,186,248,120,0, 62,126,200,200,126,62,0,0  ;@  A
CC66_67	DB	130,254,254,146,146,254,108,0, 56,124,198,130,130,198,68,0;B C
CC68_69	DB	130,254,254,130,198,124,56,0, 130,254,254,146,186,130,198,0 ;D E
CC70_71	DB	130,254,254,146,184,128,192,0, 56,124,198,130,138,206,78,0 ;F G
CC72_73	DB	254,254,16,16,254,254,0,0, 0,130,254,254,130,0,0,0 ; H I
CC74_75	DB	12,14,2,130,254,252,128,0, 130,254,254,16,56,238,198,0 ; J K
CC76_77	DB	130,254,254,130,2,6,14,0, 254,254,112,56,112,254,254,0 ;  L M
CC78_79	DB	254,254,96,48,24,254,254,0, 56,124,198,130,198,124,56,0 ; N O
CC80_81	DB	130,254,254,146,144,240,96,0, 120,252,132,142,254,122,0,0 ; P Q
CC82_83	DB	130,254,254,144,152,254,102,0, 100,246,178,154,206,76,0,0 ; R S
CC84_85	DB	192,130,254,254,130,192,0,0, 254,254,2,2,254,254,0,0; T U
CC86_87	DB	248,252,6,6,252,248,0,0, 254,254,12,24,12,254,254,0  ;V W
CC88_89	DB	194,230,60,24,60,230,194,0, 224,242,30,30,242,224,0,0 ;X Y
CC90_91	DB	226,198,142,154,178,230,206,0, 0,254,254,130,130,0,0,0 ; Z [
CC92_93	DB	128,192,96,48,24,12,6,0, 0,130,130,254,254,0,0,0 ;  \ ]
CC94_95	DB	16,48,96,192,96,48,16,0, 1,1,1,1,1,1,1,1 ;  ^ _
CC96_97	DB	0,0,192,224,32,0,0,0, 4,46,42,42,60,30,2,0 ; ` a
CC98_99	DB	130,254,252,18,18,30,12,0, 28,62,34,34,54,20,0,0 ;b c
CC100_101	DB	12,30,18,146,252,254,2,0, 28,62,42,42,58,24,0,0 ;d e
CC102_103	DB	18,126,254,146,192,64,0,0, 25,61,37,37,31,62,32,0 ;f g 
CC104_105	DB	130,254,254,16,32,62,30,0, 0,34,190,190,2,0,0,0 ; h  i
CC106_107	DB	6,7,1,1,191,190,0,0, 130,254,254,8,28,54,34,0 ; j k
CC108_109	DB	0,130,254,254,2,0,0,0, 62,62,24,28,56,62,30,0 ; l m
CC110_111	DB	62,62,32,32,62,30,0,0, 28,62,34,34,62,28,0,0 ; n o
CC112_113	DB	33,63,31,37,36,60,24,0, 24,60,36,37,31,63,33,0 ; p q
CC114_115	DB	34,62,30,50,32,56,24,0, 18,58,42,42,46,36,0,0 ;r s
CC116_117	DB	0,32,124,254,34,36,0,0, 60,62,2,2,60,62,2,0 ;t u
CC118_119	DB	56,60,6,6,60,56,0,0, 60,62,14,28,14,62,60,0 ;v w
CC120_121	DB    34,54,28,8,28,54,34,0, 57,61,5,5,63,62,0,0 ;x y
CC122_123   DB    50,38,46,58,50,38,0,0, 16,16,124,238,130,130,0,0 ; z {
CC124_125	DB	0,0,0,238,238,0,0,0,  130,130,238,124,16,16,0,0 ; | }
CC126_127	DB	64,192,128,192,64,192,128,0, 14,30,50,98,50,30,14,0 ; ~ triangle


CTABLE	DB	0,0,0,0,0,0,58,0,0,0,0,0
C34_35	DB	96,0,96,0,0,0,20,62,20,62,20,0
C36_37	DB	58,42,127,42,46,0,34,4,8,16,34,0
C38_39      DB    20,62,20,62,20,0,96,0,0,0,0,0
C40_41	DB	0,28,34,0,0,0,0,34,28,0,0,0
C42_43	DB	168,112,32,112,168,0,8,8,62,8,8,0
C44_45	DB	0,3,6,0,0,0,8,8,8,8,8,0
C46_47	DB	0,0,2,2,0,0,0,6,8,48,0,0
C48_49	DB	28,38,42,50,28,0,0,18,62,2,0,0
C50_51	DB	38,42,42,42,18,0,34,42,42,42,54,0
C52_53	DB	60,4,14,4,4,0,58,42,42,42,36,0
C54_55	DB	62,42,42,42,46,0,32,32,38,40,48,0
C56_57	DB	62,42,42,42,62,0,58,42,42,42,62,0
C58_59	DB	34,0,0,0,0,0,35,0,0,0,0,0
C60_61	DB	8,20,34,0,0,0,20,20,20,20,20,0
C62_63	DB	34,20,8,0,0,0,16,32,42,16,0,0
C64_65	DB	62,34,42,42,58,0,62,36,36,36,62,0
C66_67	DB	62,42,42,42,54,0,62,34,34,34,34,0
C68_69	DB	62,34,34,34,28,0,62,42,42,42,34,0
C70_71	DB	62,40,40,40,32,0,62,34,34,42,46,0
C72_73	DB	62,8,8,8,62,0,34,34,62,34,34,0
C74_75	DB	6,2,2,34,62,0,62,8,8,20,34,0
C76_77	DB	62,2,2,2,2,0,62,16,8,16,62,0
C78_79	DB	62,16,8,4,62,0,28,34,34,34,28,0
C80_81	DB	62,40,40,40,16,0,60,36,38,36,60,0
C82_83	DB	62,40,40,40,22,0,58,42,42,42,46,0
C84_85	DB	32,32,62,32,32,0,62,2,2,2,62,0
C86_87	DB	48,12,2,12,48,0,60,2,12,2,60,0
C88_89	DB	34,20,8,20,34,0,48,8,6,8,48,0
C90_91	DB	34,38,42,50,34,0,62,34,0,0,0,0
C92_93	DB	48,8,6,0,0,0,34,62,0,0,0,0
C94_95	DB	0,64,128,64,0,0,2,2,2,2,2,2
C96_97	DB	0,128,0,0,0,0,0,4,42,42,42,30       ; ` a
C98_99	DB	0,254,34,34,34,28,0,28,34,34,34,20  ;b c
C100_101	DB	0,28,34,34,34,254,0,28,42,42,42,16  ;d e
C102_103	DB	0,16,126,144,144,0,0,24,37,37,37,62 ;f g 
C104_105	DB	0,254,32,32,30,0,0,0,0,190,2,0       ; h  i
C106_107	DB	0,2,1,33,190,0,0,254,8,20,34,0    ; j k
C108_109	DB	0,0,0,254,2,0,0,62,32,24,32,30    ; l m
C110_111	DB	0,62,32,32,30,0,0,28,34,34,34,28  ; n o
C112_113	DB	0,63,34,34,34,28,0,28,34,34,34,63 ; p q
C114_115	DB	0,34,30,34,32,16,0,16,42,42,42,4  ;r s
C116_117	DB	0,32,124,34,36,0,0,60,2,4,62,0    ;t u
C118_119	DB	0,56,4,2,4,56,0,60,6,12,6,60      ;v w
C120_121	DB    0,54,8,8,54,0,0,57,5,6,60,0     ;x y
C122_123    DB    0,38,42,42,50,0,0,0,8,62,34,0,0 ; z {
C124_125 	DB	54,0,0,0,0,0,0,34,62,8,0,0
C126  	DB	64,128,64,128,0,0


BOOTBIN     TEXT		"BOOT    BIN"
		DB 	0
SDOK		TEXT		"SD Card OK"
		DB	0
SDBOK		TEXT        "Loading BOOT.BIN"
		DB	0
SDNOTOK	TEXT		"No SDCard Boot"
		DB	0
ORG 16384

ISTACK	DS	512
SDCBUF1	DS	514
SDCBUF2	DS	514
SDCBUF3	DS	514
FATBOOT	DS	2 ; boot sector 
CURDIR	DS	2 ; current root dir
FSTCLST	DS	2 ; first data cluster
FSTFAT	DS	2 ; first fat cluster
SDFLAG	DS	2 ; 256 if sd mounted ok
COUNTER     DS	4 ; Counter for general use increased by VSYNC INT 3 
CURSOR	DS	2 ;  
RHINT0	DS	6 ; RAM redirection of interrupts
RHINT1	DS	6 ; to be filled with jmp to service routine instructions
RHINT2	DS	6		
RINT6		DS	6
RINT7		DS	6
RINT8		DS	6
RINT9		DS	6
RINT15	DS	6 ; TRACE INT service routine
VMODE		DS	1
SCOL		DS    1
SHIFT       DS    1
CAPSL       DS    1
CIRCX		DS	2
CIRCY		DS	2
PLOTM		DS	2  ; Plot mode 1=normal 0=clear
SECNUM	DS	2 ; Total num of sectors in sd
SECPFAT	DS	2 ; Sectors per Fat
FATROOT	DS	2 ; fat root dir
SDHC        DS    1 ; is the sd hc ?
SDERROR     DS    1 ; sd card #error
MEMTOP      DS    4 ; max memory
BCOL		DS    1
FCOL		DS    1
HINT		DS 	6 ;hardware int 3
FMEMORG     DS    4 ; free ram origin
XX          DS    1
YY          DS    1
FMEMLOWL    DS	4
FMEMLPTR    DS	4
RESERVED    DS    6

ORG 18600
FTAB:   ; FILE TABLES
FSTATUS     DS	1  ; bit7=Open, bit0=dirty buffer
FATYPE      DS    1  ; r w a 
FBUFPTR     DS	4  ; ptr to buffer
FCLSTPTR    DS    4  ; first cluster no
FBUFCNUM    DS    4  ; no of cluster in buffer 
FILEPOS	DS	4  ; file position
FILESIZE    DS	4  ; file size
FFNAME      DS	12 ; NAME
RESTFT      DS    374
FTABEND:
CTABLE3     DS    =128*8   ; for caracters >127
CTAB3END:
ORG $5000
START:	

