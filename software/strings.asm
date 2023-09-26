; **************************
; ***** String library *****
; **************************

; ***********************************
; ***** Copy string             *****
; ***** RD - destination string *****
; ***** RF - source string      *****
; ***********************************
strcpy:    push    rd           ; save consumed registers
           push    rf
strcpy_1:  lda     rf           ; get byte from source string
           str     rd           ; store into destination
           inc     rd
           lbnz    strcpy_1     ; loop back until terminator copied
           pop     rf           ; recover consumed registers
           pop     rd
           sep     sret         ; return to caller
           
; ***********************************
; ***** Concatenate string      *****
; ***** RD - destination string *****
; ***** RF - source string      *****
; ***********************************
strcat:    push    rd           ; save consumed registers
           push    rf
strcat_1:  lda     rd           ; look for terminator
           lbnz    strcat_1     ; loop back until terminator found
           dec     rd           ; move back to terminator
           lbr     strcpy_1     ; and then copy source string to end

; **********************************
; ***** String length          *****
; ***** RF - pointer to string *****
; ***** Returns: RC - length   *****
; **********************************
strlen:    push    rf           ; save consumed register
           ldi     0            ; set count to zero
           plo     rc
           phi     rc
strlen_1:  lda     rf           ; get byte from string
           lbz     strlen_2     ; jump if terminator found
           inc     rc           ; otherwise increment count
           lbr     strlen_1     ; and keep looking
strlen_2:  pop     rf           ; recover consumed register
           sep     sret         ; return to caller

; *****************************************
; ***** Left portion of string        *****
; ***** RF - pointer to source string *****
; ***** RD - pointer to destination   *****
; ***** RC - Count of characters      *****
; *****************************************
left:      push    rf           ; save consumed registers
           push    rd
           push    rc
left_1:    glo     rc           ; see if characters left
           str     r2
           ghi     rc
           or
           lbz     left_dn      ; jump if not
           dec     rc           ; decrement count
           lda     rf           ; get byte from source
           str     rd           ; write into destination
           inc     rd
           lbnz    left_1       ; jump if terminator not found
left_rt:   pop     rc           ; recover consumed registers
           pop     rd
           pop     rf
           sep     sret         ; otherwise return to caller
left_dn:   ldi     0            ; write terminator to destination
           str     rd
           lbr     left_rt      ; then return

; *****************************************
; ***** Middle portion of string      *****
; ***** RF - pointer to source string *****
; ***** RD - pointer to destination   *****
; ***** RB - Starting point           *****
; ***** RC - Count of characters      *****
; *****************************************
mid:       push    rb           ; save consumed register
mid_1:     glo     rb           ; see if starting position found
           str     r2
           ghi     rc
           or
           lbz     mid_2        ; use left to copy characters
           dec     rb           ; decrement count
           lda     rf           ; get byte from source string
           lbz     mid_dn       ; jump if terminator found, will be empty destination
           lbr     mid_1        ; keep looping until start point 
mid_dn:    ldi     0            ; write terminator to destination
           str     rd
           pop     rb           ; recover consumed register
           sep     sret         ; and return
mid_2:     sep     scall        ; call left to copy characters
           dw      left
           pop     rb           ; pop consumed register
           sep     sret         ; and return to caller

; *****************************************
; ***** Right portion of string       *****
; ***** RF - pointer to source string *****
; ***** RD - pointer to destination   *****
; ***** RC - Count of characters      *****
; *****************************************
right:     push    rc           ; save consumed register
           ldi     0            ; zero counter
           plo     rb
           phi     rb
right_1:   lda     rf           ; get byte from source
           lbz     right_2      ; jump if terminator found
           inc     rb           ; increment length
           lbr     right_1      ; keep looking for terminator
right_2:   dec     rf           ; point back to previous character
           glo     rb           ; check RB counter
           str     r2
           ghi     rb
           or
           lbz     right_dn     ; start found, so now just copy
           glo     rc           ; check rc counter
           str     r2
           ghi     rc
           or
           lbz     right_dn     ; start found, so now just copy
           dec     rb           ; decrement counters
           dec     rc
           lbr     right_2      ; keep looking for start point
right_dn:  sep     scall        ; call strcpy to copy the string
           dw      strcpy
           pop     rc           ; recover consumed register
           sep     sret         ; and return

; ***************************************
; ***** Convert string to lowercase *****
; ***** RF - Pointer to string      *****
; ***************************************
lower:     push    rf           ; save consumed register
lower_1:   ldn     rf           ; get byte from buffer
           lbz     return       ; jump if terminator found
           smi     'A'          ; Check for lower range
           lbnf    lowernxt     ; jump if below range
           smi     26           ; check for above range
           lbdf    lowernxt     ; jump if above range
           ldn     rf           ; get character
           adi     32           ; convert to lowercvase
           str     rf           ; and put it back
lowernxt:  inc     rf           ; point to next character
           lbr     lower_1      ; process rest of string
return:    pop     rf           ; recover consumed register
           sep     sret         ; return to caller

; ***************************************
; ***** Convert string to uppercase *****
; ***** RF - Pointer to string      *****
; ***************************************
upper:     push    rf           ; save consumed register
upper_1:   ldn     rf           ; get byte from buffer
           lbz     return       ; jump if terminator found
           smi     'a'          ; Check for lower range
           lbnf    uppernxt     ; jump if below range
           smi     26           ; check for above range
           lbdf    uppernxt     ; jump if above range
           ldn     rf           ; get character
           smi     32           ; convert to lowercvase
           str     rf           ; and put it back
uppernxt:  inc     rf           ; point to next character
           lbr     upper_1      ; process rest of string

; *********************************************
; ***** String compare                    *****
; ***** RF - string1                      *****
; ***** RD - string2                      *****
; ***** Returns: DF=0 - strings unequal   *****
; *****          DF=1 - strings equal     *****
; *****          D=1  - string1 > string2 *****
; *****          D=0  - string1 < string2 *****
; *********************************************
strcmp:    push    rd           ; save consumed registers
           push    rf
strcmp_2:  lda     rf           ; get byte from string1
           str     r2
           lbnz    strcmp_1     ; jump if terminator not found
           lda     rd           ; get byte from second string
           lbz     strcmp_eq    ; jump if strings are equal
           lbr     strcmp_lt    ; jump if string1 is smaller
strcmp_1:  lda     rd           ; get byte from second string
           lbz     strcmp_gt    ; jump if string2 is lower
           sd                   ; subtract from first string
           lbz     strcmp_2     ; loop to check remaining bytes
           lbdf    strcmp_gt    ; jump if 
strcmp_lt: ldi     0            ; signal string 1 is lower
           lbr     strcmp_rt
strcmp_eq: ldi     1            ; signal strings equal
           lbr     strcmp_rt
strcmp_gt: ldi     2            ; signal string 2 is lower
strcmp_rt: shr
           plo     re           ; preserve result
           pop     rf           ; recover consumed registers
           pop     rd
           glo     re           ; recover result
           sep     sret

