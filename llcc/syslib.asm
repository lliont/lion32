data
export RAND
align 4
LABELV RAND
byte 4 197
export Set_sprite
code
proc Set_sprite 16 8
ADDRFP4 4
ADDRFP4 4
INDIRI4
ASGNI4
ADDRLP4 8
ADDRFP4 0
INDIRI4
ASGNI4
ADDRLP4 12
CNSTI4 14
ASGNI4
ADDRLP4 0
ADDRLP4 8
INDIRI4
ADDRLP4 12
INDIRI4
DIVI4
ASGNI4
ADDRLP4 4
ADDRLP4 8
INDIRI4
ADDRLP4 12
INDIRI4
MODI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 12
LSHI4
CNSTI4 16384
ADDI4
ADDRFP4 4
INDIRI4
CNSTI4 8
LSHI4
ADDI4
ADDRLP4 4
INDIRI4
CNSTI4 3
LSHI4
ADDI4
ARGI4
ADDRFP4 12
INDIRI4
ARGI4
ADDRGP4 IOout
CALLI4
pop
ADDRLP4 0
INDIRI4
CNSTI4 12
LSHI4
CNSTI4 16384
ADDI4
CNSTI4 2
ADDI4
ADDRFP4 4
INDIRI4
CNSTI4 8
LSHI4
ADDI4
ADDRLP4 4
INDIRI4
CNSTI4 3
LSHI4
ADDI4
ARGI4
ADDRFP4 16
INDIRI4
ARGI4
ADDRGP4 IOout
CALLI4
pop
ADDRLP4 0
INDIRI4
CNSTI4 12
LSHI4
CNSTI4 16384
ADDI4
CNSTI4 6
ADDI4
ADDRFP4 4
INDIRI4
CNSTI4 8
LSHI4
ADDI4
ADDRLP4 4
INDIRI4
CNSTI4 3
LSHI4
ADDI4
ARGI4
ADDRFP4 8
INDIRI4
ARGI4
ADDRGP4 IOout
CALLI4
pop
LABELV $1
endproc Set_sprite 16 8
export Disable_sprite
proc Disable_sprite 16 8
ADDRLP4 8
ADDRFP4 0
INDIRI4
ASGNI4
ADDRLP4 12
CNSTI4 14
ASGNI4
ADDRLP4 0
ADDRLP4 8
INDIRI4
ADDRLP4 12
INDIRI4
DIVI4
ASGNI4
ADDRLP4 4
ADDRLP4 8
INDIRI4
ADDRLP4 12
INDIRI4
MODI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 12
LSHI4
CNSTI4 16384
ADDI4
CNSTI4 6
ADDI4
CNSTI4 256
ADDI4
ADDRLP4 4
INDIRI4
CNSTI4 3
LSHI4
ADDI4
ARGI4
CNSTI4 0
ARGI4
ADDRGP4 IOout
CALLI4
pop
ADDRLP4 0
INDIRI4
CNSTI4 12
LSHI4
CNSTI4 16384
ADDI4
CNSTI4 6
ADDI4
ADDRLP4 4
INDIRI4
CNSTI4 3
LSHI4
ADDI4
ARGI4
CNSTI4 0
ARGI4
ADDRGP4 IOout
CALLI4
pop
LABELV $2
endproc Disable_sprite 16 8
export Set_sprite_data
proc Set_sprite_data 28 8
ADDRFP4 8
ADDRFP4 8
INDIRP4
ASGNP4
ADDRFP4 12
ADDRFP4 12
INDIRI4
ASGNI4
ADDRLP4 16
ADDRFP4 0
INDIRI4
ASGNI4
ADDRLP4 20
CNSTI4 14
ASGNI4
ADDRLP4 8
ADDRLP4 16
INDIRI4
ADDRLP4 20
INDIRI4
DIVI4
ASGNI4
ADDRLP4 12
ADDRLP4 16
INDIRI4
ADDRLP4 20
INDIRI4
MODI4
ASGNI4
ADDRLP4 4
ADDRLP4 8
INDIRI4
CNSTI4 12
LSHI4
CNSTI4 16896
ADDI4
CNSTI4 1792
ADDRFP4 4
INDIRI4
MULI4
ADDI4
ADDRLP4 12
INDIRI4
CNSTI4 7
LSHI4
ADDI4
ASGNI4
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $4
ADDRLP4 4
INDIRI4
ADDRLP4 0
INDIRI4
ADDI4
ARGI4
ADDRLP4 0
INDIRI4
ADDRFP4 12
INDIRI4
CNSTI4 7
LSHI4
ADDI4
ADDRFP4 8
INDIRP4
ADDP4
INDIRI1
CVII4 1
ARGI4
ADDRGP4 IOoutb
CALLI4
pop
LABELV $5
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 128
LTI4 $4
LABELV $3
endproc Set_sprite_data 28 8
import IOoutb
import IOout
