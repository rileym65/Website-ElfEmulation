
; ************************************************
; ***** Scalable Add.  M[R7]=M[R7]+M[R8]     *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
scadd:   plo      re                ; save count
         push     r7                ; save consumed registers
         push     r8
         ldi      0                 ; zero the carry flag
         shr
         sex      r8                ; set X=second number
scaddlp: ldn      r7                ; get byte from first number
         adc                        ; add second number
         str      r7                ; save result
         inc      r7                ; point to next byte
         inc      r8
         dec      re                ; decrement byte count
         glo      re                ; need to check if done
         lbnz     scaddlp           ; loop back if more bytes
         sex      r2                ; restore x
         pop      r8                ; restore consumed registers
         pop      r7
         sep      sret              ; return to caller
        
    

; ************************************************
; ***** Scalable Sub.  M[R7]=M[R7]-M[R8]     *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
scsub:   plo      re                ; save count
         push     r7                ; save consumed registers
         push     r8
         ldi      1                 ; set the borrow flag
         shr
         sex      r8                ; set X=second number
scsublp: ldn      r7                ; get byte from first number
         smb                        ; subtract second number
         str      r7                ; save result
         inc      r7                ; point to next byte
         inc      r8
         dec      re                ; decrement byte count
         glo      re                ; need to check if done
         lbnz     scsublp           ; loop back if more bytes
         sex      r2                ; restore x
         pop      r8                ; restore consumed registers
         pop      r7
         sep      sret              ; return to caller
        

    
; ************************************************
; ***** Scalable Inc.  M[RF]=M[RF]+1         *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
scinc:   plo      re                ; save count
         push     rf                ; save consumed register
         ldi      1                 ; set the carry flag
         shr
scinclp: ldn      rf                ; get byte from first number
         adci     0                 ; propagate carry
         str      rf                ; save result
         inc      rf                ; point to next byte
         dec      re                ; decrement byte count
         glo      re                ; need to check if done
         lbnz     scinclp           ; loop back if more bytes
         pop      rf                ; recover consumed register
         sep      sret              ; return to caller
        

    
; ************************************************
; ***** Scalable Dec.  M[RF]=M[RF]-1         *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
scdec:   plo      re                ; save count
         push     rf                ; save consumed register
         ldi      0                 ; clear the borrow flag
         shr
scdeclp: ldn      rf                ; get byte from first number
         smbi     0                 ; propagate borrow
         str      rf                ; save result
         inc      rf                ; point to next byte
         dec      re                ; decrement byte count
         glo      re                ; need to check if done
         lbnz     scdeclp           ; loop back if more bytes
         pop      rf                ; recover consumed register
         sep      sret              ; return to caller


; ************************************************
; ***** Scalable cmp.  M[R7]-M[R8]           *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ***** Returns: D=0 if M[R7]=M[R8]          *****
; *****          DF=1 if M[R7]<M[R8]         *****
; ************************************************
sccmp:   plo      re                ; save count
         push     r7                ; save consumed registers
         push     r8
         glo      re
         ldi      1                 ; set the borrow flag
         shr
         phi      r9                ; save zero flag
sccmplp: sex      r8                ; point x to second number
         ldn      r7                ; get byte from first number
         smb                        ; subtract second number
         sex      r2                ; point x back to stack
         str      r2                ; save byte result
         ghi      r9                ; get zero flag
         or                         ; combine with last byte result
         phi      r9                ; and save
         inc      r7                ; point to next byte
         inc      r8
         dec      re                ; decrement byte count
         glo      re                ; need to check if done
         lbnz     sccmplp           ; loop back if more bytes
         ldn      r2                ; get last byte result
         shl                        ; shift sign bit into df
         pop      r8                ; recover consumed registers
         pop      r7
         ghi      r9                ; get zero flag
         sep      sret              ; return to caller
        
; ***************************************
; ***** Scalable is zero            *****
; ***** D=number of bytes in number *****
; ***** returnss: DF=1 if M[RF]=0   *****
; ***************************************
sczero:  plo      re                ; save byte count
         push     rf                ; save consumed register
sczero1: lda      rf                ; get byte from number
         lbnz     sczeron           ; jump if it was not zero
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     sczero1           ; loop if more bytes to check
         pop      rf                ; recover consumed register
         ldi      1                 ; number was zero
         shr                        ; shift into df
         sep      sret              ; and return
sczeron: pop      rf                ; recover consumed register
         ldi      0                 ; signal not zero
         shr
         sep      sret              ; and return
        
; ***************************************
; ***** M[RF] = 0                   *****
; ***** D=number of bytes in number *****
; ***************************************
scnull:  plo      re                ; save byte count
         push     rf                ; save consumed register
scnull1: ldi      0                 ; need zero
         str      rf                ; store into destination
         inc      rf                ; point to next byte
         dec      re                ; decrement count
         glo      re                ; check if done
         lbnz     scnull1           ; jump if not
         pop      rf                ; recover consumed register
         sep      sret              ; otherwise return
    
; *************************************************
; ***** Check if M[RF] is negative            *****
; ***** D=number of bytes in number           *****
; ***** Returns: DF=1 if number is negative   *****
; *************************************************
scismn:  smi      1                 ; need count - 1
         str      r2                ; store for add
         glo      rf                ; need to point to MSB
         add
         plo      rf
         ghi      rf
         adci     0                 ; propagate carry
         phi      rf                ; RF now points to MSB
         ldn      rf                ; get MSB
         shl                        ; shift sign bit into DF
         sep      sret              ; and then return
        
    

; ************************************************
; ***** 2s compliment  M[R7]=-M[R7]          *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
comp2s:  plo      re                ; save count
         push     r7                ; save consumed registers
         ldi      1                 ; set the carry flag
         shr
comp2s2: ldn      r7                ; get byte from number
         xri      0ffh              ; invert it
         adci     0                 ; propagate carry
         str      r7                ; save result
         inc      r7                ; point to next byte
         dec      re                ; decrement byte count
         glo      re                ; need to check if done
         lbnz     comp2s2           ; loop back if more bytes
         pop      r7                ; restore consumed registers
         sep      sret              ; return to caller

; ************************************************
; ***** Scalable shift left.  M[RF]=M[RF]<<1 *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
scshl:   plo      re                ; save count
         push     rf                ; save consumed register
         ldi      0                 ; zero the carry flag
         shr
scshllp: ldn      rf                ; get byte from number
         shlc                       ; shift it left
         str      rf                ; save result
         inc      rf                ; point to next byte
         dec      re                ; decrement byte count
         glo      re                ; need to check if done
         lbnz     scshllp           ; loop back if more bytes
         pop      rf                ; recover consumed register
         sep      sret              ; return to caller
        
    

; ************************************************
; ***** Scalable shift right. M[RF]=M[RF]>>1 *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
scshr:   plo      re                ; save count
         push     rf                ; save consumed register
         glo      re
         str      r2                ; need to move R7 to MSB
         glo      rf                ; add count
         add
         plo      rf
         ghi      rf                ; propagate carry
         adci     0
         phi      rf
         dec      rf                ; minus 1, now pointing at MSB
         ldi      0                 ; zero the carry flag
         shr
scshrlp: ldn      rf                ; get byte from number
         shrc                       ; shift it right
         str      rf                ; save result
         dec      rf                ; point to previous byte
         dec      re                ; decrement byte count
         glo      re                ; need to check if done
         lbnz     scshrlp           ; loop back if more bytes
         pop      rf                ; recover consumed register
         sep      sret              ; return to caller

; ************************************************
; ***** Scalable multiply. M[R7]=M[R7]*M[R8] *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ***** In routine:                          *****
; *****    R7 - points to answer             *****
; *****    RF - points to first number       *****
; *****    R8 - points to second number      *****
; ************************************************
scmul:   plo      re                ; store byte count
         plo      r9                ; need to keep a copy of it
scmul1:  ldi      0                 ; need to zero the answer
         stxd                       ; will use the stack to hold the answer
         dec      re                ; decrement count
         glo      re                ; get count
         lbnz     scmul1            ; loop until done
         mov      rf,r7             ; rf will point to first number
         mov      r7,r2             ; r7 will point to where the answer is
         inc      r7                ; point to LSB of answer
scmul2:  push     rf                ; save rf
         mov      rf,r8             ; need second number
         glo      r9                ; get size
         sep      scall             ; check for zero
         dw       sczero
         pop      rf                ; recover rf
         lbnf     scmul4            ; jump if number was not zero
         inc      r2                ; now pointing at lsb of answer
         glo      r9                ; need byte count
         plo      re                ; store for count
scmul5:  lda      r2                ; get number from stack
         str      rf                ; store into destination
         inc      rf
         dec      re                ; decrement count
         glo      re                ; check if done
         lbnz     scmul5            ; jump if not
         sep      sret              ; all done, so just return
scmul4:  ldn      r8                ; get lsb of second number
         shr                        ; shift low bit into df
         lbnf     scmulno           ; no add needed
         push     r7                ; save position of first number
         push     r8                ; save position of second number
         mov      r8,rf             ; r8 needs to be first number
         glo      r9                ; get byte count
         sep      scall             ; call add routine
         dw       scadd
         pop      r8                ; recover positions
         pop      r7
scmulno: push     rf                ; save first number pointer
         glo      r9                ; get byte count
         sep      scall             ; shift left
         dw       scshl
         mov      rf,r8             ; now need pointer to second number
         glo      r9                ; get byte count
         sep      scall             ; shift right
         dw       scshr
         pop      rf                ; recover answer pointer
         lbr      scmul2            ; loop until done


; ************************************************
; ***** Scalable division. M[R7]=M[R7]/M[R8] *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ***** In routine:                          *****
; *****    R7=a                              *****
; *****    R8=b                              *****
; *****    RA=result                         *****
; *****    RB=shift                          *****
; ************************************************
scdiv:   plo      r9                ; save byte count
         str      r9                ; save count
         glo      r2                ; need to reserve bytes on stack
         sm 
         plo      r2
         ghi      r2
         smbi     0                 ; propagate carry
         phi      r2
         mov      ra,r2             ; set ra here
         inc      ra                ; plus 1
         glo      r9                ; now need space for shift
         str      r2
         glo      r2
         sm
         plo      r2
         ghi      r2
         smbi     0
         phi      r2
         mov      rb,r2             ; set location for shift
         inc      rb                ; move to correct location
         mov      rf,ra             ; point to result
         glo      r9                ; get byte count
         sep      scall             ; set answer to 0
         dw       scnull            ; set to zero
         mov      rf,rb             ; point to result
         glo      r9                ; get byte count
         sep      scall             ; set answer to 0
         dw       scnull            ; set to zero
scdiv1:  mov      rf,r8             ; need b
         glo      r9                ; get byte count
         sep      scall             ; see if high bit set
         dw       scismn
         lbdf     scdiv2            ; jump if set
         mov      rf,r8             ; point to b
         glo      r9                ; get byte count
         sep      scall             ; shift b left
         dw       scshl
         mov      rf,rb             ; point to shift
         glo      r9                ; get number of bytes
         sep      scall             ; increment shift
         dw       scinc
         lbr      scdiv1            ; loop until high bit of b is set
scdiv2:  mov      rf,r7             ; point to a
         glo      r9                ; get byte count
         sep      scall             ; see if high bit set
         dw       scismn
         lbdf     scdiv3            ; jump if set
         mov      rf,r7             ; point to b
         glo      r9                ; get byte count
         sep      scall             ; shift a left
         dw       scshl
         mov      rf,rb             ; point to shift
         glo      r9                ; get number of bytes
         sep      scall             ; decrement shift
         dw       scdec
         lbr      scdiv2            ; loop until high bit of a is set
scdiv3:  mov      rf,rb             ; point to shift
         glo      r9                ; get number of bytes
         sep      scall             ; and increment shift
         dw       scinc
scdiv4:  mov      rf,r7             ; point to a
         glo      r9                ; get byte count
         sep      scall             ; is a zero
         dw       sczero
         lbdf     scdivd1           ; jump if it was zero
         mov      rf,r8             ; point to b
         glo      r9                ; get byte count
         sep      scall             ; is b zero
         dw       sczero
         lbdf     scdivd1           ; jump if so
         mov      rf,ra             ; point to result
         glo      r9                ; get byte count
         sep      scall             ; need to shift result left
         dw       scshl
         glo      r9                ; get byte count
         sep      scall             ; compare a to b
         dw       sccmp
         lbdf     scdiv6            ; jump if a < b
         ldn      ra                ; get LSB of result
         ori      1                 ; set low bit
         str      ra                ; and but it back
         glo      r9                ; get byte count
         sep      scall             ; subtract a from b
         dw       scsub
scdiv6:  ldn      r8                ; get lsb of b
         shr                        ; see if low bit is set
         lbnf     scdiv5            ; jump if not
         mov      rf,r8             ; need to zero b
         glo      r9                ; get byte count
         sep      scall             ; null out b
         dw       scnull
scdiv5:  mov      rf,r8             ; point to b
         glo      r9                ; get byte count
         sep      scall             ; need to shift b right
         dw       scshr
         mov      rf,rb             ; point to shift
         glo      r9                ; get byte count
         sep      scall             ; decrement it
         dw       scdec
         lbr      scdiv4            ; loop back until done
scdivd1: mov      rf,rb             ; point to shift
         glo      r9                ; get byte count
         sep      scall             ; need to see if minus
         dw       scismn
         lbdf     scdivd2           ; jump if so
scdivd3: mov      rf,rb             ; point to shift
         glo      r9                ; get byte count
         sep      scall             ; see if zero
         dw       sczero
         lbdf     scdivdn           ; jump if so
         mov      rf,ra             ; point to shift
         glo      r9                ; get byte count
         sep      scall             ; shift it left
         dw       scshl
         mov      rf,rb             ; point to shift
         glo      r9
         sep      scall             ; and decrement it
         dw       scdec
         lbr      scdivd3           ; loop back
scdivd2: mov      rf,rb             ; point to shift
         glo      r9                ; get byte count
         sep      scall             ; see if zero
         dw       sczero
         lbdf     scdivdn           ; jump if so
         mov      rf,ra             ; point to shift
         glo      r9                ; get byte count
         sep      scall             ; shift it right
         dw       scshr
         mov      rf,rb             ; point to shift
         glo      r9
         sep      scall             ; and increment it
         dw       scinc
         lbr      scdivd2
scdivdn: push     r7                ; save answer position
scdivd5: lda      ra                ; get result byte
         str      r7                ; store into answer
         inc      r7
         dec      r9                ; decrement count
         glo      r9                ; see if done
         lbnz     scdivd5           ; jump if not
         pop      r7                ; recover answer
         mov      r2,ra             ; need clean up the stack
         glo      r9
         str      r2
         glo      r2
         add
         plo      r2
         ghi      r2
         adci     0
         phi      r2
         sep      sret              ; return to caller
