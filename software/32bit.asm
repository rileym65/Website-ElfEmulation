; **********************************
; ***** 32-bit integer library *****
; **********************************

; ************************************************
; ***** 32-bit Add.    M[R7]=M[R7]+M[R8]     *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
add32:   sex      r8                ; point x to second number
         ldn      r7                ; get lsb
         add                        ; add second lsb of second number
         str      r7                ; store it
         inc      r7                ; point to 2nd byte
         inc      r8
         ldn      r7                ; get second byte
         adc                        ; add second byte of second number
         str      r7                ; store it
         inc      r7                ; point to 3rd byte
         inc      r8
         ldn      r7                ; get third byte
         adc                        ; add third byte of second number
         str      r7                ; store it
         inc      r7                ; point to msb
         inc      r8
         ldn      r7                ; get msb byte
         adc                        ; add msb byte of second number
         str      r7                ; store it
         sex      r2                ; restore stack
         dec      r7                ; restore registers to original values
         dec      r7
         dec      r7
         dec      r8
         dec      r8
         dec      r8
         sep      sret              ; return to caller
        
    

; ************************************************
; ***** 32-bit subtract.  M[R7]=M[R7]-M[R8]  *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
sub32:   sex      r8                ; point x to second number
         ldn      r7                ; get lsb
         sm                         ; subtract second lsb of second number
         str      r7                ; store it
         inc      r7                ; point to 2nd byte
         inc      r8
         ldn      r7                ; get second byte
         smb                        ; subtract second byte of second number
         str      r7                ; store it
         inc      r7                ; point to 3rd byte
         inc      r8
         ldn      r7                ; get third byte
         smb                        ; subtract third byte of second number
         str      r7                ; store it
         inc      r7                ; point to msb
         inc      r8
         ldn      r7                ; get msb byte
         smb                        ; subtract msb byte of second number
         str      r7                ; store it
         sex      r2                ; restore stack
         dec      r7                ; restore registers to original values
         dec      r7
         dec      r7
         dec      r8
         dec      r8
         dec      r8
         sep      sret              ; return to caller
        

    
; ************************************************
; ***** 32-bit Inc.  M[RF]=M[RF]+1           *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
inc32:   ldn      rf                ; get lsb
         adi      1                 ; add 1
         str      rf                ; store it
         inc      rf                ; point to next byte
         ldn      rf                ; get second byte
         adci     0                 ; propagate carry
         str      rf                ; store it
         inc      rf                ; point to 3rd byte
         ldn      rf                ; retreive it
         adci     0                 ; propagate carry
         str      rf                ; store it
         inc      rf                ; point to msb
         ldn      rf                ; get it
         adci     0                 ; propagate carry
         str      rf                ; store msb
         dec      rf                ; restore rf
         dec      rf
         dec      rf
         sep      sret              ; and return


    
; ************************************************
; ***** 32-bit Dec.  M[RF]=M[RF]-1           *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
dec32:   ldn      rf                ; get lsb
         smi      1                 ; subtract 1
         str      rf                ; store it
         inc      rf                ; point to next byte
         ldn      rf                ; get second byte
         smbi     0                 ; propagate borrow
         str      rf                ; store it
         inc      rf                ; point to 3rd byte
         ldn      rf                ; retreive it
         smbi     0                 ; propagate borrow
         str      rf                ; store it
         inc      rf                ; point to msb
         ldn      rf                ; get it
         smbi     0                 ; propagate borrow
         str      rf                ; store msb
         dec      rf                ; restore rf
         dec      rf
         dec      rf
         sep      sret              ; and return


; ************************************************
; ***** 32-bit cmp.  M[R7]-M[R8]             *****
; ***** Numbers in memory stored LSB first   *****
; ***** Returns: D=0 if M[R7]=M[R8]          *****
; *****          DF=1 if M[R7]<M[R8]         *****
; ************************************************
cmp32:   lda      r8                ; get lsb from second number
         str      r2                ; store for subtract
         lda      r7                ; get lsb from first number
         sm                         ; subtract
         plo      re                ; save as zero test
         lda      r8                ; get 2nd byte of second number
         str      r2                ; store for subtract
         lda      r7                ; get 2nd byte of first number
         smb                        ; perform subtraction
         str      r2                ; store for combining with zero test
         glo      re                ; get zero test
         or                         ; or last result
         plo      re                ; and put back
         lda      r8                ; get 3rd byte of second number
         str      r2                ; store for subtract
         lda      r7                ; get 3rd byte of first number
         smb                        ; perform subtraction
         str      r2                ; store for combining with zero test
         glo      re                ; get zero test
         or                         ; or last result
         plo      re                ; and put back
         ldn      r8                ; get msb of second number
         str      r2                ; store for subtract
         ldn      r7                ; get msb of first number
         smb                        ; perform subtraction
         str      r2                ; store for combining with zero test
         shl                        ; shift sign bit into df
         glo      re                ; get zero test
         or                         ; or last result
         dec      r7                ; restore registers
         dec      r7
         dec      r7
         dec      r8
         dec      r8
         dec      r8
         sep      sret              ; return to caller

; ************************************************
; ***** 32-bit cmp.  M[R8]-M[R7]             *****
; ***** Numbers in memory stored LSB first   *****
; ***** Returns: D=0 if M[R7]=M[R8]          *****
; *****          DF=1 if M[R8]<M[R7]         *****
; ************************************************
icmp32:  lda      r8                ; get lsb from second number
         str      r2                ; store for subtract
         lda      r7                ; get lsb from first number
         sd                         ; subtract
         plo      re                ; save as zero test
         lda      r8                ; get 2nd byte of second number
         str      r2                ; store for subtract
         lda      r7                ; get 2nd byte of first number
         sdb                        ; perform subtraction
         str      r2                ; store for combining with zero test
         glo      re                ; get zero test
         or                         ; or last result
         plo      re                ; and put back
         lda      r8                ; get 3rd byte of second number
         str      r2                ; store for subtract
         lda      r7                ; get 3rd byte of first number
         sdb                        ; perform subtraction
         str      r2                ; store for combining with zero test
         glo      re                ; get zero test
         or                         ; or last result
         plo      re                ; and put back
         ldn      r8                ; get msb of second number
         str      r2                ; store for subtract
         ldn      r7                ; get msb of first number
         sdb                        ; perform subtraction
         str      r2                ; store for combining with zero test
         shl                        ; shift sign bit into df
         glo      re                ; get zero test
         or                         ; or last result
         dec      r7                ; restore registers
         dec      r7
         dec      r7
         dec      r8
         dec      r8
         dec      r8
         sep      sret              ; return to caller


; ***************************************
; ***** is zero check               *****
; ***** returnss: DF=1 if M[RF]=0   *****
; ***************************************
iszero:  push     rf                ; save position
         lda      rf                ; get lsb
         lbnz     notzero           ; jump if not zero
         lda      rf                ; get second number
         lbnz     notzero           ; jumpt if not zero
         lda      rf                ; get third number
         lbnz     notzero           ; jump if not zero
         ldn      rf                ; get msb
         lbnz     notzero           ; jump if not zero
         ldi      1                 ; number was zero
         shr                        ; shift into df
         sep      sret              ; and return
notzero: ldi      0                 ; number was not zero
         shr                        ; shift into df
         pop      rf                ; recover position
         sep      sret              ; and return

        
; ***************************************
; ***** M[RF] = 0                   *****
; ***************************************
null32:  ldi      0                 ; need to zero
         str      rf                ; store to lsb
         inc      rf                ; point to second byte
         str      rf                ; store to second byte
         inc      rf                ; point to third byte
         str      rf                ; store to third byte
         inc      rf                ; point to msb
         str      rf                ; store to msb
         dec      rf                ; restore rf
         dec      rf
         dec      rf
         sep      sret              ; return to caller
    
; *************************************************
; ***** Check if M[RF] is negative            *****
; ***** Returns: DF=1 if number is negative   *****
; *************************************************
isneg:   inc      rf                ; point to msb
         inc      rf
         inc      rf
         ldn      rf                ; retrieve msb
         shl                        ; shift sign bit into df
         dec      rf                ; restore rf
         dec      rf
         dec      rf
         sep      sret              ; and return


; *********************************************
; ***** 2s compliment the number in M[RF] *****
; *********************************************
comp2s:  ldn      rf                ; get lsb
         xri      0ffh              ; invert it
         adi      1                 ; +1
         str      rf
         inc      rf                ; point to 2nd byte
         ldn      rf                ; retrieve it
         xri      0ffh              ; invert it
         adci     0                 ; propagate carry
         str      rf                ; and put back
         inc      rf                ; point to 3rd byte
         ldn      rf                ; retrieve it
         xri      0ffh              ; invert it
         adci     0                 ; propagate carry
         str      rf                ; and put back
         inc      rf                ; point to msb
         ldn      rf                ; retrieve it
         xri      0ffh              ; invert it
         adci     0                 ; propagate carry
         str      rf                ; and put back
         dec      rf                ; restore rf
         dec      rf
         dec      rf
         sep      sret              ; return


; ************************************************
; ***** 32-bit shift left.  M[RF]=M[RF]<<1   *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
shl32:   ldn      rf                ; get lsb
         shl                        ; shift it
         str      rf                ; put it back
         inc      rf                ; point to second byte
         ldn      rf                ; get it
         shlc                       ; shift it
         str      rf
         inc      rf                ; point to third byte
         ldn      rf                ; get it
         shlc                       ; shift it
         str      rf
         inc      rf                ; point to msb
         ldn      rf                ; get it
         shlc                       ; shift it
         str      rf
         dec      rf                ; restore rf
         dec      rf
         dec      rf
         sep      sret              ; and return

    

; ************************************************
; ***** 32-bit shift right. M[RF]=M[RF]>>1   *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
shr32:   inc      rf                ; point to msb
         inc      rf
         inc      rf
         ldn      rf                ; get msb
         shr                        ; shift it right
         str      rf                ; put it back
         dec      rf                ; point to third byte
         ldn      rf                ; get third byte
         shrc                       ; shift it
         str      rf                ; put it back
         dec      rf                ; point to second byte
         ldn      rf                ; get second byte
         shrc                       ; shift it
         str      rf                ; put it back
         dec      rf                ; point to lsb
         ldn      rf                ; get lsb
         shrc                       ; shift it
         str      rf                ; put it back
         sep      sret              ; return to caller


; ************************************************
; ***** 32-bit multiply. M[R7]=M[R7]*M[R8]   *****
; ***** Numbers in memory stored LSB first   *****
; ***** In routine:                          *****
; *****    R7 - points to answer             *****
; *****    R9 - points to first number       *****
; *****    R8 - points to second number      *****
; ************************************************
mul32:   push     r7                ; save consumed registers
         push     r8
         push     r9
         push     rf
         ldi      0                 ; need to zero answer
         stxd
         stxd
         stxd
         stxd
         mov      r9,r7             ; rf will point to first number
         mov      r7,r2             ; r7 will point to where the answer is
         inc      r7                ; point to LSB of answer
scmul2:  mov      rf,r8             ; need second number
         sep      scall             ; check for zero
         dw       iszero
         lbnf     scmul4            ; jump if number was not zero
         inc      r2                ; now pointing at lsb of answer
         lda      r2                ; get number from stack
         str      r9                ; store into destination
         inc      r9                ; point to 2nd byte
         lda      r2                ; get number from stack
         str      r9                ; store into destination
         inc      r9                ; point to 3rd byte
         lda      r2                ; get number from stack
         str      r9                ; store into destination
         inc      r9                ; point to msb
         ldn      r2                ; get number from stack
         str      r9                ; store into destination
         pop      rf                ; recover consumed registers
         pop      r9
         pop      r8
         pop      r7
         sep      sret              ; return to caller
scmul4:  ldn      r8                ; get lsb of second number
         shr                        ; shift low bit into df
         lbnf     scmulno           ; no add needed
         push     r7                ; save position of first number
         push     r8                ; save position of second number
         mov      r8,r9             ; r8 needs to be first number
         sep      scall             ; call add routine
         dw       add32
         pop      r8                ; recover positions
         pop      r7
scmulno: mov      rf,r9             ; point to first number
         sep      scall             ; shift left
         dw       shl32
         mov      rf,r8             ; now need pointer to second number
         sep      scall             ; shift right
         dw       shr32
         lbr      scmul2            ; loop until done


; ************************************************
; ***** 32-bit division. M[R7]=M[R7]/M[R8]   *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ***** In routine:                          *****
; *****    R7=a                              *****
; *****    R8=b                              *****
; *****    RA=result                         *****
; *****    RB=shift                          *****
; ************************************************
div32:   push     r7                ; save consumed registers
         push     r8
         push     ra
         push     rb
         push     rf
         ldi      0                 ; set sign flag as positive
         str      r2                ; place on the stack
         inc      r7                ; point to msb of first number
         inc      r7
         inc      r7
         ldn      r7                ; retrieve it
         dec      r7                ; restore position
         dec      r7
         dec      r7
         ani      080h              ; is number negative
         lbz      div32_1           ; jump if not
         ldi      1                 ; set sign flag
         xor
         stxd                       ; save flag
         mov      rf,r7             ; 2s compliment number
         sep      scall
         dw       comp2s
         irx                        ; point back to sign flag
div32_1: inc      r8                ; point to msb of second number
         inc      r8
         inc      r8
         ldn      r8                ; retrieve it
         dec      r8                ; restore position
         dec      r8
         dec      r8
         ani      080h              ; is number negative
         lbz      div32_2           ; jump if not
         ldi      1                 ; adjust sign flag
         xor
         stxd                       ; save sign flag
         mov      rf,r8             ; 2s compliment second number
         sep      scall
         dw       comp2s
         irx
div32_2: dec      r2                ; preserve sign flag
         dec      r2                ; reserve bytes on stack for result
         dec      r2
         dec      r2
         mov      ra,r2             ; set RA here
         dec      r2
         mov      rf,ra             ; point to result
         sep      scall             ; set answer to 0
         dw       null32            ; set to zero
         ldi      1                 ; set shift to 1
         plo      rb
scdiv1:  sep      scall             ; compare a to b
         dw       icmp32
         lbnf     scdiv4            ; jump if b>=a
         mov      rf,r8             ; need to shift b
         sep      scall 
         dw       shl32
         inc      rb                ; increment shift
         lbr      scdiv1            ; loop until b>=a
scdiv4:  mov      rf,r7             ; point to a
         sep      scall             ; is a zero
         dw       iszero
         lbdf     scdivd1           ; jump if it was zero
         mov      rf,r8             ; point to b
         sep      scall             ; is b zero
         dw       iszero
         lbdf     scdivd1           ; jump if so
         mov      rf,ra             ; point to result
         sep      scall             ; need to shift result left
         dw       shl32
         sep      scall             ; compare a to b
         dw       cmp32
         lbdf     scdiv6            ; jump if a < b
         ldn      ra                ; get LSB of result
         ori      1                 ; set low bit
         str      ra                ; and but it back
         sep      scall             ; subtract a from b
         dw       sub32
scdiv6:  ldn      r8                ; get lsb of b
         shr                        ; see if low bit is set
         lbnf     scdiv5            ; jump if not
         dec      rb                ; mark final shift
         lbr      scdivd1           ; and then done
scdiv5:  mov      rf,r8             ; point to b
         sep      scall             ; need to shift b right
         dw       shr32
         dec      rb                ; decrement shift
         lbr      scdiv4            ; loop back until done
scdivd1: glo      rb                ; get shift
         shl                        ; shift sign into df
         lbdf     scdivd2           ; jump if so
scdivd3: glo      rb                ; get shift
         lbz      scdivdn           ; jump if zero
         mov      rf,ra             ; point to result
         sep      scall             ; shift it left
         dw       shl32
         dec      rb                ; decrement shift
         lbr      scdivd3           ; loop back
scdivd2: glo      rb                ; get shift
         lbz      scdivdn           ; jump if zero
         mov      rf,ra             ; point to result
         sep      scall             ; shift it right
         dw       shr32
         inc      rb                ; increment shift
         lbr      scdivd2
scdivdn: push     r7                ; save answer position
         ldi      4                 ; 4 bytes to transfer
         plo      r9
scdivd5: lda      ra                ; get result byte
         str      r7                ; store into answer
         inc      r7
         dec      r9                ; decrement count
         glo      r9                ; see if done
         lbnz     scdivd5           ; jump if not
         pop      r7                ; recover answer
         glo      ra                ; need to clean up the stack
         plo      r2
         ghi      ra
         phi      r2
         ldn      r2                ; retrieve sign
         shr                        ; shift into df
         lbnf     scdivrt           ; jump if signs were the same
         mov      rf,r7             ; otherwise negate number
         sep      scall
         dw       comp2s
scdivrt: pop      rf                ; recover consumed registers
         pop      rb
         pop      ra
         pop      r8
         pop      r7
         sep      sret              ; return to caller

; *****************************************
; ***** Convert R7:R8 to bcd in M[RF] *****
; *****************************************
tobcd:     push    rf           ; save address
           ldi     10           ; 10 bytes to clear
           plo     re
tobcdlp1:  ldi     0
           str     rf           ; store into answer
           inc     rf
           dec     re           ; decrement count
           glo     re           ; get count
           lbnz    tobcdlp1     ; loop until done
           pop     rf           ; recover address
           ldi     32           ; 32 bits to process
           plo     r9
tobcdlp2:  ldi     10           ; need to process 5 cells
           plo     re           ; put into count
           push    rf           ; save address
tobcdlp3:  ldn     rf           ; get byte
           smi     5            ; need to see if 5 or greater
           lbnf    tobcdlp3a    ; jump if not
           adi     8            ; add 3 to original number
           str     rf           ; and put it back
tobcdlp3a: inc     rf           ; point to next cell
           dec     re           ; decrement cell count
           glo     re           ; retrieve count
           lbnz    tobcdlp3     ; loop back if not done
           glo     r8           ; start by shifting number to convert
           shl
           plo     r8
           ghi     r8
           shlc
           phi     r8
           glo     r7
           shlc
           plo     r7
           ghi     r7
           shlc
           phi     r7
           shlc                 ; now shift result to bit 3
           shl
           shl
           shl
           str     rf
           pop     rf           ; recover address
           push    rf           ; save address again
           ldi     10           ; 10 cells to process
           plo     re
tobcdlp4:  lda     rf           ; get current cell
           str     r2           ; save it
           ldn     rf           ; get next cell
           shr                  ; shift bit 3 into df
           shr
           shr
           shr
           ldn     r2           ; recover value for current cell
           shlc                 ; shift with new bit
           ani     0fh          ; keep only bottom 4 bits
           dec     rf           ; point back
           str     rf           ; store value
           inc     rf           ; and move to next cell
           dec     re           ; decrement count
           glo     re           ; see if done
           lbnz    tobcdlp4     ; jump if not
           pop     rf           ; recover address
           dec     r9           ; decrement bit count
           glo     r9           ; see if done
           lbnz    tobcdlp2     ; loop until done
           sep     sret         ; return to caller

; ***************************************************
; ***** Convert 32-bit binary to ASCII          *****
; ***** RF - Pointer to 32-bit integer          *****
; ***** RD - destination buffer                 *****
; ***************************************************
itoa:      push    rf           ; save consumed registers
           push    r9
           push    r8
           push    r7
           lda     rf           ; retrieve number into R7:R8
           plo     r8
           lda     rf
           phi     r8
           lda     rf
           plo     r7
           lda     rf
           phi     r7
           glo     r2           ; make room on stack for buffer
           smi     11
           plo     r2
           ghi     r2
           smbi    0
           phi     r2
           mov     rf,r2        ; RF is output buffer
           inc     rf
           ghi     r7           ; get high byte
           shl                  ; shift bit to DF
           lbdf    itoan        ; negative number
itoa1:     sep     scall        ; convert to bcd
           dw      tobcd
           mov     rf,r2
           inc     rf
           ldi     10
           plo     r8
           ldi     9            ; max 9 leading zeros
           phi     r8
loop1:     lda     rf
           lbz     itoaz        ; check leading zeros
           str     r2           ; save for a moment
           ldi     0            ; signal no more leading zeros
           phi     r8
           ldn     r2           ; recover character
itoa2:     adi     030h
           str     rd           ; store into output buffer
           inc     rd
itoa3:     dec     r8
           glo     r8
           lbnz    loop1
           glo     r2           ; pop work buffer off stack
           adi     11
           plo     r2
           ghi     r2
           adci    0
           phi     r2
           ldi     0            ; place terminator in destination
           str     rd
           pop     r7
           pop     r8           ; recover consumed registers
           pop     r9
           pop     rf
           sep     sret         ; return to caller
itoaz:     ghi     r8           ; see if leading have been used up
           lbz     itoa2        ; jump if so
           smi     1            ; decrement count
           phi     r8
           lbr     itoa3        ; and loop for next character
itoan:     ldi     '-'          ; show negative
           str     rd           ; write to destination buffer
           inc     rd
           glo     r8           ; 2s compliment
           xri     0ffh
           adi     1
           plo     r8
           ghi     r8
           xri     0ffh
           adci    0
           phi     r8
           glo     r7
           xri     0ffh
           adci    0
           plo     r7
           ghi     r7
           xri     0ffh
           adci    0
           phi     r7
           lbr     itoa1        ; now convert/show number

; ****************************************************
; ***** Convert ascii to int32                   *****
; ***** RF - buffer to ascii                     *****
; ***** RD - destinatin int32                    *****
; ***** Returns R7:R8 result                     *****
; *****         RF - First non-numeric character *****
; ****************************************************
atoi:      push    ra           ; save consumed registers
           push    rb
           ldi     0            ; zero result
           phi     r7
           plo     r7
           phi     r8
           plo     r8
           stxd                 ; store sign on stack
           ldn     rf           ; get byte from input
           smi     '-'          ; check for negative number
           lbnz    atoi_lp      ; jump if not a negative number
           ldi     1            ; replace sign
           irx
           stxd
           inc     rf           ; move past sign
atoi_lp:   ldn     rf           ; get byte from input
           smi     '0'          ; see if below digits
           lbnf    atoi_dn      ; jump if not valid digit
           smi     10           ; check for high of range
           lbdf    atoi_dn      ; jump if not valid digit
           glo     r8           ; multiply answer by 2
           shl
           plo     r8
           plo     rb           ; put a copy in RA:RB as well
           ghi     r8
           shlc
           phi     r8
           phi     rb
           glo     r7
           shlc
           plo     r7
           plo     ra
           ghi     r7
           shlc
           phi     r7
           phi     ra
           ldi     2            ; want to shift RA:RB twice
           plo     re
atoi_1:    glo     rb           ; now shift RA:RB
           shl
           plo     rb
           ghi     rb
           shlc
           phi     rb
           glo     ra
           shlc
           plo     ra
           ghi     ra
           shlc
           phi     ra
           dec     re           ; decrement shift count
           glo     re           ; see if done
           lbnz    atoi_1       ; shift again if not
           glo     rb           ; now add RA:RB to R7:R8
           str     r2
           glo     r8
           add
           plo     r8
           ghi     rb
           str     r2
           ghi     r8
           adc
           phi     r8
           glo     ra
           str     r2
           glo     r7
           adc
           plo     r7
           ghi     ra
           str     r2
           ghi     ra
           str     r2
           ghi     r7
           adc
           phi     r7
           lda     rf           ; get byte from input
           smi     '0'          ; conver to binary
           str     r2           ; and add it to R7:R8
           glo     r8
           add
           plo     r8
           ghi     r8
           adci    0
           phi     r8
           glo     r7
           adci    0
           plo     r7
           ghi     r7
           adci    0
           phi     r7
           lbr     atoi_lp      ; loop back for more characters
atoi_dn:   irx                  ; recover sign
           ldx
           shr                  ; shift into DF
           lbnf    atoi_dn2     ; jump if not negative
           glo     r8           ; negate the number
           xri     0ffh
           adi     1
           plo     r8
           ghi     r8
           xri     0ffh
           adci    0
           phi     r8
           glo     r7
           xri     0ffh
           adci    0
           plo     r7
           ghi     r7
           xri     0ffh
           adci    0
           phi     r7
atoi_dn2:  glo     r8           ; store result into destination
           str     rd
           inc     rd
           ghi     r8
           str     rd
           inc     rd
           glo     r7
           str     rd
           inc     rd
           ghi     r7
           str     rd
           dec     rd           ; restore RD
           dec     rd
           dec     rd
           pop     rb           ; recover consumed registers
           pop     ra
           sep     sret         ; and return to caller
