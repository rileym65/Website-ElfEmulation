; *******************************************************************
; *** This software is copyright 2006 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

; #define ELFOS
#define LEVEL 2
; #define ELF2K

; R7 - Group 7 subroutines
; R8 - GOSUB stack
; R9 - Expression stack
; RA - Current token
; RC - Current line pointer

#ifdef ELF2K
#include "config.inc"
#endif
include    bios.inc
#ifdef ELFOS
include    kernel.inc
#endif

TKN_USTR:  equ     0fch
TKN_QSTR:  equ     0fdh
TKN_NUM:   equ     0feh
TKN_TERM:  equ     0ffh

ERR_BREAK:  equ    0
ERR_DIRECT: equ    1
ERR_SYN:    equ    2
ERR_NOLIN:  equ    3
ERR_INVRET: equ    4
ERR_VAL:    equ    5
ERR_FILE:   equ    6
ERR_INVLP:  equ    7
ERR_NOFOR:  equ    8
ERR_NODATA: equ    9
ERR_NOMEM:  equ     10
ERR_BADDIM: equ     11
ERR_UNSUP:  equ     12

CMD_START:  equ    26

#ifdef ELFOS
#define     BASE   2000h
#define     BASE2  2100h
#define     MSG    o_msg
#define     TYPE   o_type
#define     INPUT  o_input
#define     INMSG  o_inmsg
#else
#ifdef ELF2K
#define     BASE   BASIC
#define     BASE2  (BASIC+0100h)
#else
#define     BASE   0c000h
#define     BASE2  0c100h
#endif
#define     MSG    f_msg
#define     TYPE   f_type
#define     INPUT  f_input
#define     INMSG  f_inmsg
#endif


#ifdef ELFOS
           org     8000h
#if LEVEL==1
           db      'RCBASIC',0
#endif
#if LEVEL==2
           db      'RCBASICL2',0
#endif
#if LEVEL==3
           db      'RCBASICL3',0
#endif
           dw      9000h
           dw      endrom+7000h
           dw      2000h
           dw      endrom-2000h
           dw      2000h
           db      0
#endif

           org     BASE

#ifdef ELFOS
           br      start1              ; jump to start
include    date.inc
start1:    lbr     start
#else
           lbr     begin               ; jump to program start
           lbr     begin2
#endif

           sep     r3                  ; return to caller
group_7:   lda     r3                  ; retrieve get subcode
           plo     r7                  ; and jump to it
set_buf:   ldi     high buffer         ; point to input buffer
           phi     rf
           ldi     low buffer
           plo     rf
           br      group_7-1           ; and return
set_tkn:   ldi     high tokens         ; point to input buffer
           phi     ra
           ldi     low tokens
           plo     ra
           br      group_7-1           ; and return

; ***************************************
; *** Find a line                     ***
; *** RD - line number to find        ***
; *** Returns - RC - address of line  ***
; ***           DF=1 - exact match    ***
; ***           DF=0 - line is higher ***
; ***************************************
find_ln:   ldi     high basic          ; point to beginning of basic storage
           phi     rc
           ldi     low basic
           plo     rc
find_lp:   lda     rc                  ; get line size
           bz      find_eof            ; jump if no more lines
           inc     rc                  ; point to lsb
           sex     rc                  ; point data to line number
           glo     rd                  ; get requested line
           sm                          ; and subtract
           plo     re                  ; save result
           dec     rc                  ; point to msb
           ghi     rd                  ; get msb of search line
           smb                         ; complete comparison
           sex     r2                  ; point X back to stack
           str     r2                  ; place into memory
           glo     re                  ; get previous result
           or                          ; and or them together
           bz      find_ex             ; found an exact match
           bnf     find_eof            ; jump if line was high
           dec     rc                  ; point to line size
           sex     rc                  ; point to size
           glo     rc                  ; and add into line position
           add
           plo     rc
           ghi     rc                  ; propogate carry
           adci    0
           phi     rc
           sex     r2                  ; point X back to stack
           br      find_lp             ; and keep searching
find_ex:   dec     rc                  ; point back to line size
           smi     0                   ; signal exact match
           br      group_7-1           ; and return
find_eof:  dec     rc                  ; last position is pointer
           adi     0                   ; signal line is higher/non existant
           br      group_7-1           ; return to caller
; ******************************************
; *** Find next basic line               ***
; *** RC - pointer to basic line         ***
; *** Returns: RF - pointer to next line ***
; ******************************************
next_ln:   sex     rc                  ; use rc as data pointer
           glo     rc                  ; get current low pointer
           add                         ; and add in offset
           plo     rf                  ; place into rf
           ghi     rc                  ; get msb of address
           adci    0                   ; propagate carry
           phi     rf                  ; rf now points to next line
           sex     r2                  ; point x back to stack
           br      group_7-1           ; return to caller

; **************************************
; *** Add inline character to buffer ***
; *** RF - buffer                    ***
; **************************************
add_char:  lda     r3                  ; get byte to add to buffer
           str     rf                  ; store into buffer
           inc     rf                  ; increment it
           br      group_7-1           ; and return to caller

ex_pop:    sex     r9                  ; point X to expression stack
           irx                         ; recover value
           ldxa
           phi     rf
           ldx
           plo     rf
           sex     r2                  ; point x back to proper stack
           br      group_7-1

ex_pop_rd: sex     r9                  ; point X to expression stack
           irx                         ; recover value
           ldxa
           phi     rd
           ldx
           plo     rd
           sex     r2                  ; point x back to proper stack
           br      group_7-1

ex_push:   sex     r9                  ; point X to expression stack
           glo     rf                  ; place RF onto it
           stxd
           ghi     rf
           stxd
           sex     r2                  ; reset x back to main stack
           br      group_7-1

rf_rd:     ghi     rf                  ; copy rf to rd
           phi     rd
           glo     rf
           plo     rd
           br      group_7-1

get_flags: ldi     0                   ; start with zero
           bn1     no_ef1              ; jump if ef1 not asserted
           ori     1                   ; indicate set
no_ef1:    bn2     no_ef2              ; jump if ef2 not asserted
           ori     2                   ; indicate set
no_ef2:    bn3     no_ef3              ; jump if ef2 not asserted
           ori     4                   ; indicate set
no_ef3:    bn4     group_7-1           ; jump if ef2 not asserted
           ori     8                   ; indicate set
           br      group_7-1

; ************************************
; *** process statement jump table ***
; ************************************
do_cmd:    glo     rf                  ; get command
           shl                         ; multiply command by 2
           str     r2                  ; prepare for add
           ldi     low cmd_table       ; lsb of command table address
           add                         ; add in command offset
           plo     r3                  ; place into R3
           ldi     high cmd_table      ; msb of command table
           phi     r3                  ; r3 now has command
           lda     r3                  ; read command address
           plo     re
           ldn     r3
           plo     r3
           glo     re
           phi     r3
           br      group_7-1

push_rf:   glo     rf
           stxd
           ghi     rf
           stxd
           br      group_7-1

pop_rf:    irx
           ldxa
           phi     rf
           ldx
           plo     rf
           br      group_7-1

push_rb:   glo     rb
           stxd
           ghi     rb
           stxd
           br      group_7-1

pop_rb:    irx
           ldxa
           phi     rb
           ldx
           plo     rb
           br      group_7-1

push_rd:   glo     rd
           stxd
           ghi     rd
           stxd
           br      group_7-1

pop_rd:    irx
           ldxa
           phi     rd
           ldx
           plo     rd
           br      group_7-1

set_byte:  lda     r3                  ; get msb of address
           phi     rf                  ; place into RF
           lda     r3
           plo     rf
byte_go:   lda     r3                  ; get value
           str     rf                  ; and store
           br      group_7-1

set_word:  lda     r3                  ; get msb of address
           phi     rf                  ; place into RF
           lda     r3
           plo     rf
           lda     r3                  ; get value
           str     rf                  ; and store
           inc     rf
           br      byte_go
           
set_rf:    lda     r3                  ; get msb
           phi     rf                  ; place into rf
           lda     r3
           plo     rf
           br      group_7-1

get_rb:    lda     r3                  ; get msb of address
           phi     rb
           lda     r3           
           plo     rb
           lda     rb                  ; retrieve it
           plo     re
           ldn     rb
           plo     rb
           glo     re
           phi     rb                  ; rb is not pointing to for stack
           br      group_7-1

func_call: ghi     r6                  ; save last value to stack
           stxd
           glo     r6
           stxd
           ghi     r3                  ; copy R3 to R6
           phi     r6
           glo     r3
           plo     r6
           lda     r8                  ; get function address
           phi     r3                  ; and put into r3
           lda     r8
           plo     r3
           br      group_7-1           ; now execute it

; ***************************************************************************
; ***                    End of group 7 subroutines                       ***
; ***************************************************************************

           org     BASE2
cmd_table: dw      ex_print            ; 0
           dw      ex_print            ; 1
           dw      ex_let              ; 2
           dw      ex_goto             ; 3
           dw      ex_if               ; 4
           dw      syn_err             ; 5 (THEN)
           dw      ex_end              ; 6
           dw      ex_gosub            ; 7
           dw      ex_return           ; 8
           dw      exec_dn             ; 9 (REM)
           dw      ex_input            ; 10
           dw      ex_poke             ; 11
           dw      ex_out              ; 12
           dw      ex_plot             ; 13
           dw      ex_run              ; 14
           dw      ex_list             ; 15
           dw      ex_new              ; 16
#if LEVEL>=2
           dw      ex_for              ; 17
           dw      syn_err             ; 18 (TO)
           dw      ex_next             ; 19
           dw      syn_err             ; 20 (NEXT)
           dw      ex_on               ; 21
           dw      exec_dn             ; 22 (DATA)
           dw      ex_read             ; 23
           dw      ex_restore          ; 24
           dw      ex_dim              ; 25
           dw      ex_random           ; 26
           dw      syn_err             ; 27 (VARPTR)
           dw      ex_clear            ; 28
           dw      syn_err             ; 29 (LEN)
           dw      syn_err             ; 30 (ASC)
           dw      syn_err             ; 31 (VAL)
           dw      syn_err             ; 32 (STR)
           dw      syn_err             ; 33 (CHR)
           dw      syn_err             ; 34 (LEFT)
           dw      syn_err             ; 35 (RIGHT)
           dw      syn_err             ; 35 (MID)
#endif
           dw      ex_bye              ; 21
#ifdef ELFOS
           dw      ex_save             ; 22
           dw      ex_load             ; 23
#endif
            
restart:   ldi     high group_7        ; setup group 7 subroutines
           phi     r7
           ldi     low group_7
           plo     r7
           sep     scall               ; setup variable table
           dw      rst_vars
           lbr     mainlp

start:     sep     scall               ; display welcome message
#ifndef ELFOS
;           dw      f_setbd
;           sep     scall               ; display welcome message
#endif
           dw      INMSG
#if LEVEL==1
           db      'RC/Basic L1',10,13
#endif
#if LEVEL==2
           db      'RC/Basic L2',10,13
#endif
           db      '(c) Copyright 2006 by Michael H. Riley',10,13,10,13,0
           ldi     high group_7        ; setup group 7 subroutines
           phi     r7
           ldi     low group_7
           plo     r7
           sep     r7                  ; mark no program loaded
           db      set_byte.0
           dw      basic
           db      0
           sep     r7                  ; set initial value in lfsr
           db      set_word.0
           dw      lfsr
           dw      0
           sep     r7                  ; set initial value in lfsr
           db      set_word.0
           dw      (lfsr+2)
           dw      1
           sep     scall               ; setup variable table
           dw      rst_vars

mainlp:    sep     scall               ; display prompt
           dw      INMSG
           db      '>',0
           sep     r7                  ; setup input buffer
           db      set_buf.0
           sep     scall               ; get input from user
           dw      INPUT
           sep     scall               ; setup CR/LF
           dw      do_crlf
           sep     r7                  ; setup input buffer
           db      set_buf.0
           sep     r7                  ; setup token buffer
           db      set_tkn.0
           sep     scall               ; tokenize input
           dw      tokenize
           ghi     ra                  ; save ending of tokens
           phi     rb
           glo     ra
           plo     rb
           sep     r7                  ; setup token buffer
           db      set_tkn.0
           ldn     ra                  ; get first token
           smi     TKN_NUM             ; is it numeric
           lbz     insert_ln           ; need to insert new line
           ldi     0                   ; no current line
           plo     rc
           phi     rc
           sep     r7                  ; set token address into RA
           db      set_tkn.0
           sep     scall               ; execute commands
           dw      execute
           lbdf    error               ; jump if error occurred
           sep     scall               ; display error message
           dw      INMSG
           db      10,13,0
           lbr     mainlp              ; back to main loop
error:     plo     rd                  ; put error code into RD
           ldi     0                   ; high byte is zero
           phi     rd
           sep     scall               ; display error message
           dw      INMSG
           db      10,13,'ERROR:',0
           sep     r7                  ; setup buffer
           db      set_buf.0
           sep     scall               ; convert error code
           dw      f_uintout
           ldi     0                   ; terminate error code
           str     rf
           sep     r7                  ; setup buffer
           db      set_buf.0
           sep     scall               ; display error code
           dw      MSG
           glo     rc                  ; see if program was running
           lbnz    was_run
           ghi     rc
           lbnz    was_run
error_cnt: sep     scall               ; display error message
           dw      INMSG
           db      10,13,0
           lbr     mainlp
was_run:   sep     scall               ; add to error message
           dw      INMSG
           db      ' in line ',0
           inc     rc                  ; move past line size
           lda     rc                  ; get line number
           phi     rd
           ldn     rc
           plo     rd
           sep     r7                  ; setup buffer
           db      set_buf.0
           sep     scall               ; convert error code
           dw      f_uintout
           ldi     0                   ; terminate error code
           str     rf
           sep     r7                  ; setup buffer
           db      set_buf.0
           sep     scall               ; display error code
           dw      MSG
           lbr     error_cnt           ; then continue 



; ******************************************************************************
; ***                    Start of utility functions                          ***
; ******************************************************************************

; **************************************************
; *** Find end of basic program area             ***
; *** Returns: RF - pointing to terminating null ***
; **************************************************
bas_end:   sep     r7                  ; point to basic program area
           db      set_rf.0
           dw      basic
bas_endlp: ldn     rf                  ; see if at end
           lbnz    bas_end2            ; jump if not
           sep     sret                ; return to caller
bas_end2:  sex     rf                  ; need to add in offset
           glo     rf
           add
           plo     rf
           ghi     rf                  ; propagate carry
           adci    0
           phi     rf
           sex     r2                  ; point X back to stack
           lbr     bas_endlp           ; loop until end is found

; *********************************************
; *** copy tokenized line into basic memory ***
; *** RA - tokenized line pointer           ***
; *** RC - basic memory pointer             ***
; *** RF.0 - count of bytes                 ***
; *********************************************
copy_ln:   glo     rf                  ; get count
           adi     1                   ; 1 higher
           str     rc                  ; store into buffer
           inc     rc
copy_lp:   lda     ra                  ; get byte from tokenized line
           str     rc                  ; store into basic buffer
           inc     rc
           dec     rf                  ; decrement count
           glo     rf                  ; need to see if done
           lbnz    copy_lp             ; jump if not
return:    sep     sret

; *******************************************
; *** Delete line from BASIC program area ***
; *******************************************
delete_ln: dec     ra                  ; move back to line number
           dec     ra
           lda     ra                  ; get line
           phi     rd                  ; and setup for search
           ldn     ra
           plo     rd
           dec     ra                  ; ra back msb of line number
           sep     r7                  ; find line
           db      find_ln.0
           lbdf    do_delete           ; jump if line was found
           sep     scall               ; setup variable table
           dw      rst_vars
           lbr     mainlp              ; nothing to delete
do_delete: ghi     rc                  ; current line is copy destination
           phi     rd
           glo     rc
           plo     rd
           sep     r7                  ; next line is source
           db      next_ln.0
           sep     scall               ; get size of basic block
           dw      size_end
           sep     scall               ; perform the copy
           dw      memcpy
           sep     scall               ; setup variable table
           dw      rst_vars
           lbr     mainlp              ; and back to main loop

; ****************************
; *** Detokenize a string  ***
; *** RA - pointer to line ***
; *** RF - where to put    ***
; ****************************
detoken:   inc     ra                  ; move past line size
           lda     ra                  ; get line number
           phi     rd
           lda     ra
           plo     rd
           sep     scall               ; convert it to ascii
           dw      f_uintout
           sep     r7                  ; add a space
           db      add_char.0
           db      32
detkn_lp:  ldn     ra                  ; get next byte from token stream
           lbz     detkn_dn            ; jump if end of line
           ani     80h                 ; see if it is a token
           lbnz    detkn_tk            ; it is
           lda     ra                  ; if not get get it
           str     rf                  ; and place into output
           inc     rf
           lbr     detkn_lp            ; loop back for next
detkn_tk:  lda     ra                  ; retrieve token
           plo     re                  ; keep a copy
           smi     TKN_QSTR            ; check for quoted string
           lbz     detkn_qs            ; jump if so
           smi     1                   ; check for number
           lbz     detkn_nm            ; jump if so
           glo     re                  ; recover token
           ani     07fh                ; strip off token bit
           plo     re                  ; re will be the counter
           ldi     high functable      ; point to function table
           phi     rd
           ldi     low functable
           plo     rd
tkn_lp_1:  glo     re                  ; see if pointing at correct token
           lbz     tkn_yes             ; jump if so
           dec     re                  ; decrement count
tkn_lp_2:  lda     rd                  ; get byte from token table
           ani     080h                ; see if last char
           lbz     tkn_lp_2            ; keep looking if not
           lbr     tkn_lp_1            ; see if at correct token
tkn_yes:   dec     rf                  ; point to previous character
           lda     rf                  ; retrieve it
           sep     scall               ; see if alphanumeric
           dw      f_isalnum
           lbnf    tkn_yes_l           ; jump if not
           ldn     rd                  ; see what first char of token is
           ani     07fh
           sep     scall               ; need to know if it is alpha
           dw      f_isalpha
           lbnf    tkn_yes_l           ; jump if not
           sep     r7                  ; otherwise add  space
           db      add_char.0
           db      ' '
tkn_yes_l: ldn     rd                  ; get byte from token
           ani     07fh                ; strip token bit
           str     rf                  ; place character into buffer
           inc     rf
           lda     rd                  ; get byte back
           shl                         ; shift high bit into DF
           lbnf    tkn_yes_l           ; jump if not at end
           shr
           sep     scall               ; see if alphs
           dw      f_isalpha
           lbnf    detkn_lp            ; jump if not
           sep     r7                  ; otherwise add trailing space
           db      add_char.0
           db      ' '
           lbr     detkn_lp            ; and continue processing
detkn_nm:  lda     ra                  ; get msb of number
           phi     rd                  ; and prepare for output
           lda     ra
           plo     rd
           sep     scall               ; convert number
           dw      f_intout
           lbr     detkn_lp            ; and look for more tokens
detkn_qs:  sep     r7                  ; need to add a quote
           db      add_char.0
           db      '"'
qs_lp:     lda     ra                  ; get next byte
           xri     0ffh                ; see if at end
           lbz     qs_done             ; jump if so
           xri     0ffh                ; restore character
           str     rf                  ; place into output buffer
           inc     rf
           lbr     qs_lp               ; and keep looking
qs_done:   sep     r7                  ; need terminating quote
           db      add_char.0
           db      '"'
           lbr     detkn_lp            ; and loop back for more tokens
detkn_dn:  ldi     0                   ; need a terminator
           str     rf                  ; place into buffer
           sep     sret                ; and return

do_crlf:   ldi     high crlf           ; point to input buffer
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall               ; display it
           dw      MSG
           sep     sret                ; and return

; ********************************
; *** Get random bit from LFSR ***
; ********************************
fn_lfsr:   ldi     high lfsr           ; point to lfsr
           phi     rd
           ldi     low lfsr
           plo     rd
           inc     rd                  ; point to lsb
           inc     rd
           inc     rd
           ldn     rd                  ; retrieve it
           plo     re                  ; put into re  ( have bit 0)
           shr                         ; shift bit 1 into first position
           str     r2                  ; xor with previous value
           glo     re
           xor
           plo     re                  ; keep copy
           ldn     r2                  ; get value
           shr                         ; shift bit 2 into first position
           str     r2                  ; and combine
           glo     re
           xor
           plo     re
           ldn     r2                  ; now shift to bit 4
           shr
           shr
           str     r2                  ; and combine
           glo     re
           xor
           plo     re
           ldn     r2                  ; now shift to bit 6
           shr
           shr
           str     r2                  ; and combine
           glo     re
           xor
           plo     re
           dec     rd                  ; point to lfsr msb
           dec     rd
           dec     rd
           ldn     rd                  ; retrieve it
           shl                         ; shift high bit to low
           shlc
           str     r2                  ; combine with previous value
           glo     re
           xor
           shr                         ; shift new bit into DF
           ldn     rd                  ; now shift the register
           shrc
           str     rd
           inc     rd                  ; now byte 1
           ldn     rd                  ; now shift the register
           shrc
           str     rd
           inc     rd                  ; now byte 2
           ldn     rd                  ; now shift the register
           shrc
           str     rd
           inc     rd                  ; now byte 3
           ldn     rd                  ; now shift the register
           shrc
           str     rd
           shr                         ; shift result bit into DF
           sep     sret                ; and return

#if LEVEL>=2
get_sinput: glo    rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           sep     scall               ; display ?
           dw      INMSG
           db      '? ',0
           sep     r7                  ; setup input buffer
           db      set_buf.0
           sep     scall               ; get input from user
           dw      INPUT
sinput_go: ldi     0ffh                ; need different kind of terminator
           str     rf
           sep     scall               ; setup CR/LF
           dw      do_crlf
           sep     r7                  ; setup input buffer
           db      set_buf.0
           sep     scall               ; copy string into heap
           dw      str2heap
           sep     r7                  ; retrieve address
           db      ex_pop.0
           sep     r7                  ; transfer to rd
           db      rf_rd.0
           irx                         ; recover consumed register
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rf
           ldx
           plo     rf
           lbdf    err_ret             ; jump if error occurred

           adi     0                   ; signal success
           sep     sret                ; and return
#endif

; ********************************
; *** Get input from user      ***
; *** returns: RD - next value ***
; ********************************
get_input: glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           ldi     high inp_pos        ; need to get position
           phi     rf
           ldi     low inp_pos
           plo     rf
           lda     rf                  ; get buffer position
           phi     ra
           ldn     rf
           plo     ra
input_go:  ldn     ra                  ; is there stil input in the buffer
           lbnz    input_gd            ; jump if not
           sep     scall               ; get input from user
           dw      need_inp
           lbr     input_go
input_gd:  sep     scall               ; evaluate input
           dw      new_expr
           lbdf    syn_err             ; jump if error occurred
           ldn     ra                  ; get next token
           lbz     input_go2           ; terminator is acceptable
           smi     08dh                ; otherwise must be a comma
           lbnz    inp_err             ; else syntax error
           inc     ra                  ; move past the comma
input_go2: ldi     high inp_pos        ; need to get position
           phi     rf
           ldi     low inp_pos
           plo     rf
           ghi     ra                  ; save new pointer
           str     rf
           inc     rf
           glo     ra
           str     rf
           sep     r7                  ; get expression value
           db      ex_pop.0
           sep     r7                  ; move it to RD
           db      rf_rd.0
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rf
           ldx
           plo     rf
           adi     0                   ; signal no errors
           sep     sret                ; and return

need_inp:  glo     rc
           stxd
           ghi     rc
           stxd
           glo     r7
           stxd
           ghi     r7
           stxd
           sep     scall               ; display ?
           dw      INMSG
           db      '? ',0
           sep     r7                  ; setup input buffer
           db      set_buf.0
           sep     scall               ; get input from user
           dw      INPUT
;           lbnf    need_go
;           ldi     0
;           lbr     inp_err
need_go:   sep     scall               ; need a cr/lf
           dw      INMSG
           db      10,13,0
           sep     r7                  ; point to input buffer
           db      set_buf.0
           ldi     high ibuffer        ; buffer for tokenized input
           phi     ra
           ldi     low ibuffer
           plo     ra
           sep     scall               ; tokenize input
           dw      tokenize
           irx                         ; recover consumed registers
           ldxa
           phi     r7
           ldxa
           plo     r7
           ldxa
           phi     rc
           ldx
           plo     rc
           ldi     high inp_pos        ; need to setup input pointer
           phi     rf
           ldi     low inp_pos
           plo     rf
           ldi     high ibuffer        ; set to beginning of buffer
           phi     ra
           str     rf
           inc     rf
           ldi     low ibuffer
           plo     ra
           str     rf
           adi     0                   ; signal no error
           sep     sret                ; return to calelr
inp_err:   plo     re
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rf
           ldx
           plo     rf
           glo     re
           lbr     syn_err

; *****************************************************
; *** Insert tokenized line into basic program area ***
; *** RA - pointer to tokens                        ***
; *** RB - pointer to end of tokens                 ***
; *****************************************************
insert_ln: sep     scall               ; setup variable table
           dw      rst_vars
           inc     ra                  ; move to next token
           inc     ra
           inc     ra
           ldn     ra                  ; retrieve it
           lbz     delete_ln           ; need to delete instead of insert
           dec     ra                  ; move back to line number
           dec     ra
           lda     ra                  ; get line
           phi     rd                  ; and setup for search
           ldn     ra
           plo     rd
           dec     ra                  ; ra back msb of line number
           glo     ra                  ; need to get size of tokens
           str     r2
           glo     rb
           sm
           adi     1                   ; account for terminator
           stxd                        ; keep it stored on stack
           sep     r7                  ; find line
           db      find_ln.0
           lbnf    notexact            ; jump if not an exact match
           sep     r7                  ; get address of next line
           db      next_ln.0           ; rf now has source
           irx                         ; point to line size
           glo     rc                  ; need to compute dest
           add                         ; add token size
           plo     rd                  ; and place into rd
           ghi     rc                  ; high of address
           adci    0                   ; propagate carry
           phi     rd                  ; rd now has dest
           inc     rd
           dec     r2                  ; protect size
           glo     rc                  ; need to save RC
           stxd
           ghi     rc
           stxd
           sep     scall               ; find size of block
           dw      size_end
           lbr     insert_1            ; process the copy
notexact:  ldn     rc                  ; get line size
           lbz     end_line            ; jump if at end of program
           irx                         ; point to token size
           glo     rc                  ; get source address
           add
           plo     rd
           ghi     rc
           adci    0                   ; propagate carry
           phi     rd                  ; RD is copy destination
           inc     rd
           dec     r2                  ; keep token count safe
           glo     rc                  ; need to save RC
           stxd
           plo     rf                  ; which is also source
           ghi     rc
           stxd
           phi     rf                  ; RF now has source
           sep     scall               ; compute block size
           dw      size_end
insert_1:  sep     scall               ; move memory
           dw      memcpy
           irx                         ; recover basic pointer
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldx                         ; and token count
           plo     rf
           sep     scall               ; copy tokenized line into memory
           dw      copy_ln   
           sep     scall               ; setup variable table
           dw      rst_vars
           lbr     mainlp              ; and then back to main loop
end_line:  irx                         ; recover count
           ldx
           plo     rf                  ; and setup for copy
           sep     scall               ; copy the line to basic mmeory
           dw      copy_ln
           ldi     0                   ; zero next line start
           str     rc
           sep     scall               ; setup variable table
           dw      rst_vars
           lbr     mainlp

; ************************************************
; *** copy memory, detects overlaps and copies ***
; *** in corrrect direction                    ***
; *** RF - Source memory                       ***
; *** RD - Destination memory                  ***
; *** RC - count                               ***
; ************************************************
memcpy:    glo     rd                  ; perform RF-RD
           str     r2
           glo     rf
           sm
           ghi     rd
           str     r2
           ghi     rf
           smb
           lbnf    cpy_rev             ; if RF is lower, need to copy in reverse
cpy_1:     lda     rf                  ; get source byte
           str     rd                  ; store into destination
           inc     rd
           dec     rc                  ; decrement count
           glo     rc                  ; see if done
           lbnz    cpy_1               ; jump if not done
           ghi     rc                  ; check high byte as well
           lbnz    cpy_1
           sep     sret                ; return to caller
cpy_rev:   dec     rc                  ; need to add count-1 to both pointers
           glo     rc                  ; start with low byte
           str     r2
           glo     rf                  ; add to source
           add
           plo     rf
           shlc                        ; get carry
           plo     re                  ; and save it
           glo     rd                  ; now add count to destination
           add
           plo     rd
           ghi     rc                  ; now high byte
           str     r2
           ghi     rd                  ; do RD first since we have its carry
           adc
           phi     rd                  ; rd is now correct
           glo     re                  ; get carry from rf
           shr                         ; and put back into carry
           ghi     rf                  ; now finish add on source
           adc
           phi     rf
           inc     rc                  ; put count back
cpy_2:     ldn     rf                  ; get byte from source
           str     rd                  ; store into destination
           dec     rf                  ; decrement pointers
           dec     rd
           dec     rc                  ; decrement count
           glo     rc                  ; see if done
           lbnz    cpy_2               ; jump if not
           ghi     rc                  ; check high byte as well
           lbnz    cpy_2
           sep     sret                ; done with copy

; *****************************************************
; *** Shift top 2 expression stack entries upwards  ***
; *** 0000-7FFF -> 8000-FFFF                        ***
; *** 8000-FFFF -> 0000-7FFF                        ***
; *****************************************************
roll_up:   inc     r9                  ; point to msb of first number
           ldn     r9                  ; retrieive
           xri     080h                ; shift upwards
           str     r9                  ; and put back
           inc     r9                  ; move to msb of next arg
           inc     r9
           ldn     r9                  ; retrieive
           xri     080h                ; shift upwards
           str     r9                  ; and put back
           dec     r9                  ; move r9 back to where it belongs
           dec     r9
           dec     r9
           sep     sret                ; return to caller

; ***********************
; *** Reset Variables ***
; ***********************
#if LEVEL==1
rst_vars:  sep     sret                ; return to caller
#else
rst_vars:  sep     scall               ; find end of basic
           dw      bas_end
           inc     rf                  ; 1 past
           ldi     0                   ; make variable table empty
           str     rf
           ldi     high var_pos        ; pointer for variable table
           phi     rd
           ldi     low var_pos
           plo     rd
           ghi     rf                  ; store address of variable table
           str     rd
           inc     rd
           glo     rf
           str     rd
#ifdef ELF2K
           sep     scall               ; call bios to get end of memory
           dw      f_freemem
           ldi     0                   ; zero terminator in heap memory
           str     rf
           ldi     high heap           ; point to heap storage
           phi     ra
           ldi     low heap
           plo     ra
           ghi     rf                  ; store heap address
           str     ra
           inc     ra
           glo     rf
           str     ra
#else
           sep     r7                  ; clear the heap
           db      set_byte.0
           dw      07effh
           db      0ffh
           sep     r7                  ; set heap pointer
           db      set_word.0
           dw      heap
           dw      07effh
#endif
           sep     sret                ; return to caller
#endif


; *************************************
; *** Tokenize a string             ***
; *** RA - Buffer for tokens        ***
; *** RF - Ascii string to tokenize ***
; *** Returns: RC - token count     ***
; ***          DF=1 - error         ***
; *************************************
tokenize:  ldi     0                   ; set initial token count to zero
           phi     rc
           plo     rc
           glo     r7                  ; save consumed register
           stxd
           ghi     r7
           stxd
tokenlp:   sep     scall               ; move past any whitespace
           dw      f_ltrim
           ldn     rf                  ; get pointed at character
           lbz     tokendn             ; jump if terminator
           smi     34                  ; check for string
           lbz     charstr             ; jump if so
           sep     scall               ; see if numeric
           dw      f_idnum
           lbnf    tokennum            ; jump if numeric
           ldi     high functable      ; point to function table
           phi     r7
           ldi     low functable
           plo     r7
           sep     scall               ; check for token
           dw      f_findtkn
           lbdf    tokenfunc           ; jump if function

           ldn     rf                  ; get next character
           sep     scall               ; see if alnum
           dw      f_isalnum
           lbdf    ustrlpa             ; jump if it is
           lda     rf                  ; otherwise it is a single character
           str     ra
           inc     ra
           lbr     tokenlp             ; and keep looking for tokens

ustrlpa:   lda     rf                  ; get first byte
ustrlp:    str     ra                  ; store into token stream
           inc     ra
           lda     rf                  ; get next byte
           sep     scall               ; see if alphanumeric
           dw      f_isalnum
           lbdf    ustrlp              ; loop back if so, store, and keep going
           dec     rf                  ; move back to non-string char
           lbr     tokenlp             ; loop back for more tokens
charstr:   inc     rf                  ; move past opening quote
           ldi     TKN_QSTR            ; token for quoted string
charstrlp: str     ra                  ; store it
           inc     ra
           lda     rf                  ; get next byte of string
           plo     re                  ; save a copy
           lbz     tokenterm           ; jump if end
           smi     34                  ; check for ending quote
           lbz     tokenterm           ; also done
           glo     re                  ; recover byte
           lbr     charstrlp           ; and loop back til done
tokenterm: ldi     0ffh                ; quoted string termination
           str     ra
           inc     ra
           lbr     tokenlp
tokennum:  lbz     numisdec            ; jump if decimal number
           sep     scall               ; convert hex number
           dw      f_hexin
           lbr     numcont             ; continue processing number
numisdec:  sep     scall               ; convert number
           dw      f_atoi
numcont:   ldi     TKN_NUM             ; get token for number
           str     ra                  ; place into token stream
           inc     ra
           ghi     rd                  ; now write number
           str     ra
           inc     ra
           glo     rd                  ; and low byte
           str     ra
           inc     ra
           lbr     tokenlp             ; loop back for more tokens
tokenfunc: glo     rd                  ; get token number
           ori     080h                ; set high bit
           str     ra                  ; store into token stream
           inc     ra                  ; point to next free space
           smi     CMD_START           ; remove command bias
           smi     89h                 ; check for REM 
           lbnz    tokenlp             ; jump if not
rem_lp:    lda     rf                  ; read from input
           lbz     tokendn             ; jump if end of line found
           str     ra                  ; store into token stream
           inc     ra
           lbr     rem_lp              ; loop back until full line is copied
tokendn:   ldi     0                   ; need to terminate token sequence
           str     ra
           adi     0                   ; signal no error
           irx                         ; recover R7
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; and return to caller

; ******************************************************************************
; ***                      end of utility functions                          ***
; ******************************************************************************

#if LEVEL>=2
; ******************************************************************************
; ***                    Start of L2 utility functions                       ***
; ******************************************************************************
; ***********************************************
; *** Find end of heap                        ***
; *** Returns: RF - last address used by heap ***
; ***********************************************
end_heap:  ldi     high heap           ; point to heap pointer
           phi     rf
           ldi     low heap
           plo     rf
           lda     rf                  ; retrieve it
           plo     re
           ldn     rf
           plo     rf
           glo     re
           phi     rf
           sep     sret                ; and return

; **********************************
; *** Find end of variable table ***
; *** Returns: RF - end of table ***
; **********************************
end_vars:  ldi     high var_pos        ; point to variable table
           phi     rf
           ldi     low var_pos
           plo     rf
           lda     rf                  ; retrieve it
           plo     re
           ldn     rf
           plo     rf
           glo     re
           phi     rf
endvarslp: ldn     rf                  ; get size
           lbz     endvarsdn           ; jump if found ind
           sex     rf                  ; set x to size address
           glo     rf                  ; and add into rf
           add
           plo     rf
           sex     r2                  ; ponit x back to stack
           ghi     rf                  ; propagate carry
           adci    0
           phi     rf
           lbr     endvarslp           ; loop until end is found
endvarsdn: sep     sret                ; return to caller

; ************************************************
; *** Get next data item from a DATA statement ***
; ************************************************
get_data:  glo     ra                  ; need to save RA
           stxd
           ghi     ra
           stxd
           ldi     high data_pos       ; need current data position
           phi     rd
           ldi     low data_pos
           plo     rd
           lda     rd                  ; get pointer
           phi     ra
           ldn     rd
           plo     ra
           ldn     ra                  ; see if valid data
           lbz     data_err            ; jump if not
           sep     scall               ; otherwise evaluate it
           dw      new_expr
           lbdf    bad_data            ; jump if error in data
           ldn     ra                  ; see if at terminator
           lbz     data_ne             ; jump if end of data
           smi     8dh                 ; otherwise must be a comma
           lbnz    bad_data            ; jump if not
           inc     ra                  ; move to next item
           ldi     high data_pos       ; need current data position
           phi     rd
           ldi     low data_pos
           plo     rd
           ghi     ra                  ; save new data pointer
           str     rd
           inc     rd
           glo     ra
           str     rd
data_cnt:  sep     r7                  ; retrieve data value
           db      ex_pop.0
           sep     r7                  ; transfer it to RD
           db      rf_rd.0
           adi     0                   ; signal no error
           lbr     data_dn             ; and clean up
data_err:  ldi     ERR_NODATA          ; no more data, so error
           lskp
bad_data:  ldi     ERR_SYN             ; signal syntax error
           smi     0                   ; signal an error
data_dn:   plo     re                  ; save possible error code
           irx                         ; recover ra
           ldxa
           phi     ra
           ldx
           plo     ra
           glo     re
           sep     sret                ; and return
data_ne:   sep     scall               ; find next data line
           dw      find_data
           adi     0                   ; signal no error
           lbr     data_cnt            ; finish up

; *******************************************
; *** Find next DATA statement in program ***
; *******************************************
find_data: glo     rc                  ; save current line pointer
           stxd
           ghi     rc
           stxd
           ldi     high data_lin       ; need to get current data line
           phi     rf
           ldi     low data_lin
           plo     rf
           lda     rf                  ; get it
           phi     rc
           ldn     rf
           plo     rc
fnd_datlp: sep     r7                  ; get next line
           db      next_ln.0
           ldn     rf                  ; are we at end of program
           lbz     fnd_daten           ; jump if so
           inc     rf                  ; need to get first token
           inc     rf
           inc     rf
           ldn     rf                  ; get the token
           smi     CMD_START           ; shift into command range
           smi     96h                 ; check for DATA
           lbz     fnd_datys           ; jump if it is
           dec     rf                  ; back to line start
           dec     rf
           dec     rf
           ghi     rf                  ; transfer line number
           phi     rc
           glo     rf
           plo     rc
           lbr     fnd_datlp           ; keep looking
fnd_datys: inc     rf                  ; move past data token
           ldi     high data_pos       ; need to set data position
           phi     rc
           ldi     low data_pos
           plo     rc
           ghi     rf                  ; write new pointer
           str     rc
           inc     rc
           glo     rf
           str     rc
           dec     rf                  ; move back to beginning
           dec     rf
           dec     rf
           dec     rf
           lbr     fnd_datdn           ; and finish
fnd_daten: ldi     high data_pos       ; need to set data position
           phi     rc
           ldi     low data_pos
           plo     rc
           ghi     rf                  ; write new pointer
           str     rc
           inc     rc
           glo     rf
           str     rc
fnd_datdn: ldi     high data_lin       ; need to write new opinter
           phi     rc
           ldi     low data_lin
           plo     rc
           ghi     rf                  ; write new pointer
           str     rc
           inc     rc
           glo     rf
           str     rc
           irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldx
           plo     rc
           sep     sret                ; and return

; ******************************************************************************
; ***                      End of L2 utility functions                       ***
; ******************************************************************************
#endif


; ******************************************************************************
; ***                    Integer expression functions                        ***
; ******************************************************************************
; ******************************
; *** Add top 2 stack values ***
; ******************************
ex_add:    sep     r7                  ; get top of expression stack
           db      ex_pop.0
           sep     r7                  ; copy rf to rd
           db      rf_rd.0
           sep     r7                  ; get next stack value
           db      ex_pop.0
           glo     rf                  ; add them together
           str     r2
           glo     rd
           add
           plo     rf
           ghi     rf
           str     r2
           ghi     rd
           adc
           phi     rf
           sep     r7                  ; place back onto stack
           db      ex_push.0
           sep     sret                ; and return

; ******************************
; *** And top 2 stack values ***
; ******************************
ex_and:    sep     r7                  ; get top of expression stack
           db      ex_pop.0
           sep     r7                  ; copy rf to rd
           db      rf_rd.0
           sep     r7                  ; get next stack value
           db      ex_pop.0
           glo     rf                  ; and them together
           str     r2
           glo     rd
           and
           plo     rf
           ghi     rf
           str     r2
           ghi     rd
           and
           phi     rd
           sep     r7                  ; place back onto stack
           db      ex_push.0
           sep     sret                ; and return
          
; *********************************
; *** Divide top 2 stack values ***
; *********************************
ex_div:    sep     r7                  ; get top of expression stack
           db      ex_pop.0
           sep     r7                  ; copy to rD
           db      rf_rd.0
           sep     r7                  ; get next value
           db      ex_pop.0
           glo     r9                  ; save consumed register
           stxd
           ghi     r9
           stxd
           glo     r8                  ; save consumed register
           stxd
           ghi     r8
           stxd
           sep     scall               ; call bios to divide
           dw      f_div16
           glo     rb                  ; transfer answer
           plo     rf
           ghi     rb
           phi     rf
           irx                         ; recover consumed register
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r9
           ldx
           plo     r9
           sep     r7                  ; write back to stack
           db      ex_push.0
           sep     sret                ; and return

; *************************************
; *** see if top 2 values are equal ***
; *************************************
ex_eq:     sep     scall               ; subtract top 2 values
           dw      ex_sub
           sep     r7                  ; get result
           db      ex_pop.0
           glo     rf                  ; check for equality
           lbnz    false               ; jump if not equal
           ghi     rf                  ; check high byte
           lbz     true                ; jump if true
false:     ldi     0                   ; need zero on stack
           lskp
true:      ldi     0ffh                ; place -1 on stack
           phi     rf
           plo     rf
           sep     r7
           db      ex_push.0
           sep     sret                ; and return to caller

; **************************
; *** see if tos-1 > tos ***
; **************************
ex_gt:     sep     scall               ; bias numbers upwards
           dw      roll_up
           sep     scall               ; subtract top 2 values
           dw      ex_sub
           sep     r7                  ; get result
           db      ex_pop.0
           glo     rf                  ; check for equal
           lbnz    ex_gt_go            ; jump if not
           ghi     rf                  ; check high byte
           lbz     false               ; they are equal, so fasle
ex_gt_go:  lbdf    true                ; true if subtraction was positive
           lbr     false               ; otherwise false

; ***************************
; *** see if tos-1 >= tos ***
; ***************************
ex_gte:    sep     scall               ; bias numbers upwards
           dw      roll_up
           sep     scall               ; subtract top 2 values
           dw      ex_sub
           sep     r7                  ; get result
           db      ex_pop.0
           lbdf    true                ; true if subtraction was positive
           lbr     false               ; otherwise false

; **************************
; *** see if tos-1 < tos ***
; **************************
ex_lt:     sep     scall               ; bias numbers upwards
           dw      roll_up
           sep     scall               ; subtract top 2 values
           dw      ex_sub
           sep     r7                  ; get result
           db      ex_pop.0
           lbnf    true                ; true if subtraction was negative
           lbr     false               ; otherwise false

; ***************************
; *** see if tos-1 <= tos ***
; ***************************
ex_lte:    sep     scall               ; bias numbers upwards
           dw      roll_up
           sep     scall               ; subtract top 2 values
           dw      ex_sub
           sep     r7                  ; get result
           db      ex_pop.0
           glo     rf                  ; check for equal
           lbnz    ex_lte_go           ; jump if not
           ghi     rf                  ; check high byte
           lbz     true                ; they are equal, so true
ex_lte_go: lbnf    true                ; true if subtraction was negative
           lbr     false               ; otherwise false
          
; *********************************
; *** Modulo top 2 stack values ***
; *********************************
ex_mod:    sep     r7                  ; get top of expression stack
           db      ex_pop.0
           sep     r7                  ; copy to rD
           db      rf_rd.0
           sep     r7                  ; get next value
           db      ex_pop.0
           glo     r9                  ; save consumed register
           stxd
           ghi     r9
           stxd
           glo     r8                  ; save consumed register
           stxd
           ghi     r8
           stxd
           sep     scall               ; call bios to divide
           dw      f_div16
           irx                         ; recover consumed register
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r9
           ldx
           plo     r9
           sep     r7                  ; write back to stack
           db      ex_push.0
           sep     sret                ; and return

; ***********************************
; *** Multiply top 2 stack values ***
; ***********************************
ex_mul:    sep     r7                  ; get top of expression stack
           db      ex_pop.0
           sep     r7                  ; copy rf to rd
           db      rf_rd.0
           sep     r7                  ; get next stack value
           db      ex_pop.0
           glo     rc                  ; preserver consumed register
           stxd
           ghi     rc
           stxd
           sep     scall               ; call bios to multiply numbers
           dw      f_mul16
           ghi     rb                  ; move answer to rf
           phi     rf
           glo     rb
           plo     rf
           irx                         ; and recover RC
           ldxa
           phi     rc
           ldx
           plo     rc
           sep     r7                  ; place back onto stack
           db      ex_push.0
           sep     sret                ; and return

; **************************************
; *** Negate top of expression stack ***
; **************************************
ex_neg:    sep     r7                  ; get top of expression stack
           db      ex_pop.0
           glo     rf                  ; subtract it from 0
           sdi     0
           plo     rf
           ghi     rf                  ; carry through upper byte
           sdbi    0
           phi     rf
           sep     r7                  ; put back onto stack
           db      ex_push.0
           sep     sret                ; and return

; ***************************************
; *** see if top 2 values are unequal ***
; ***************************************
ex_neq:    sep     scall               ; subtract top 2 values
           dw      ex_sub
           sep     r7                  ; get result
           db      ex_pop.0
           glo     rf                  ; check for equality
           lbnz    true                ; jump if not equal
           ghi     rf                  ; check high byte
           lbz     false               ; jump if true
           lbr     true

; *****************************
; *** Or top 2 stack values ***
; *****************************
ex_or:     sep     r7                  ; get top of expression stack
           db      ex_pop.0
           sep     r7                  ; copy rf to rd
           db      rf_rd.0
           sep     r7                  ; get next stack value
           db      ex_pop.0
           glo     rf                  ; and them together
           str     r2
           glo     rd
           or
           plo     rf
           ghi     rf
           str     r2
           ghi     rd
           or
           phi     rd
           sep     r7                  ; place back onto stack
           db      ex_push.0
           sep     sret                ; and return

; ***********************************
; *** Subtract top 2 stack values ***
; ***********************************
ex_sub:    sep     r7                  ; get top of expression stack
           db      ex_pop.0
           sep     r7                  ; copy rf to rd
           db      rf_rd.0
           sep     r7                  ; get next stack value
           db      ex_pop.0
           glo     rf                  ; subtract them
           str     r2
           glo     rd
           sd
           plo     rf
           ghi     rf
           str     r2
           ghi     rd
           sdb
           phi     rf
           sep     r7                  ; place back onto stack
           db      ex_push.0
           sep     sret                ; and return

; ******************************************************************************
; ***                  End of Integer expression functions                   ***
; ******************************************************************************



; ******************************************************************************
; ***                     Start of expression evaluator                      ***
; ******************************************************************************
; ****************************
; *** Expression Evaluator ***
; *** RA points to tokens  ***
; ****************************
new_expr:  ldi     high expstack       ; setup expression stack
           phi     r9
           ldi     low expstack
           plo     r9
expr:      ldn     ra                  ; get first token
           smi     081h                ; see if negative sign
           lbnz    expr_pos            ; jump if not
           inc     ra                  ; move past minus sign
           sep     scall               ; call level 2
           dw      level_1
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; then call negate
           dw      ex_neg
           lbr     expr_1              ; continue
expr_pos:  ldn     ra                  ; check for plus sign
           smi     080h
           lbnz    expr_0              ; jump if not
           inc     ra                  ; ignore it
expr_0:    sep     scall               ; call level 2 to get value
           dw      level_1
           lbdf    err_ret             ; jump on syntax error
expr_1:    ldn     ra                  ; get token
           smi     086h                ; check for =
           lbnz    expr_1a             ; jump if not
           inc     ra                  ; move past =
           sep     scall               ; call level 1 to get value
           dw      level_1
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; now check for equality
           dw      ex_eq
           lbr     expr_1              ; look for more
expr_1a:   smi     1                   ; check for <=
           lbnz    expr_1b             ; jump if not
           inc     ra                  ; move past symbol
           sep     scall               ; call level 1 to get value
           dw      level_1
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; now check
           dw      ex_lte
           lbr     expr_1              ; look for more
expr_1b:   smi     1                   ; check for >=
           lbnz    expr_1c             ; jump if not
           inc     ra                  ; move past symbol
           sep     scall               ; call level 1 to get value
           dw      level_1
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; now check
           dw      ex_gte
           lbr     expr_1              ; look for more
expr_1c:   smi     1                   ; check for <>
           lbnz    expr_1d             ; jump if not
           inc     ra                  ; move past symbol
           sep     scall               ; call level 1 to get value
           dw      level_1
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; now check
           dw      ex_neq
           lbr     expr_1              ; look for more
expr_1d:   smi     1                   ; check for <
           lbnz    expr_1e             ; jump if not
           inc     ra                  ; move past symbol
           sep     scall               ; call level 1 to get value
           dw      level_1
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; now check
           dw      ex_lt
           lbr     expr_1              ; look for more
expr_1e:   smi     1                   ; check for >
           lbnz    expr_1f             ; jump if not
           inc     ra                  ; move past symbol
           sep     scall               ; call level 1 to get value
           dw      level_1
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; now check
           dw      ex_gt
           lbr     expr_1              ; look for more
expr_1f:   adi     0                   ; signal no errors
           ldi     2                   ; signal integer result
           sep     sret                ; and return to caller

; ***********************************
; *** Level 1, find AND, OR, &, | ***
; ***********************************
level_1:   sep     scall               ; call level 2 to get value
           dw      level_2
           lbdf    err_ret             ; jump on syntax error
level_1c:  ldn     ra                  ; get next byte
           smi     08eh                ; see if AND
           lbnz    level_1a            ; jump if not
level_and: inc     ra                  ; move past plus
           sep     scall               ; call level 2 to get value
           dw      level_2
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; and top 2 stack values
           dw      ex_and
           lbr     level_1c            ; keep looking
level_1a:  smi     1                   ; check for &
           lbz     level_and           ; compute and
           smi     1                   ; check for OR
           lbnz    level_1b            ; jump if not
level_or:  inc     ra                  ; move past minus sign
           sep     scall               ; call level 2 to get value
           dw      level_2
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; or top 2 stack values
           dw      ex_or
           lbr     level_1c            ; keep looking
level_1b:  smi     1                   ; check for |
           lbz     level_or            ; jump if so
level_1n:  adi     0                   ; signal no error in level
           sep     sret                ; return from level 2

; **************************
; *** Level 2, find +, - ***
; **************************
level_2:   sep     scall               ; call level 3 to get value
           dw      level_3
           lbdf    err_ret             ; jump on syntax error
level_2c:  ldn     ra                  ; get next byte
           smi     080h                ; see if plus
           lbnz    level_2a            ; jump if not
           inc     ra                  ; move past plus
           sep     scall               ; call level 3 to get value
           dw      level_3
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; add top 2 stack values
           dw      ex_add
           lbr     level_2c            ; keep looking
level_2a:  smi     1                   ; check for minus
           lbnz    level_2n            ; jump if not
           inc     ra                  ; move past minus sign
           sep     scall               ; call level 3 to get value
           dw      level_3
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; subtract top 2 stack values
           dw      ex_sub
           lbr     level_2c            ; keep looking
level_2n:  adi     0                   ; signal no error in level
           sep     sret                ; return from level 2

; **************************
; *** Level 2, find *, / ***
; **************************
level_3:   sep     scall               ; call level 4 to get value
           dw      level_4
           lbdf    err_ret             ; jump on syntax error
level_3c:  ldn     ra                  ; get next token
           smi     082h                ; check for *
           lbnz    level_3a            ; jump if not
           inc     ra                  ; move past multiply symbol
           sep     scall               ; call level 4 to get value
           dw      level_4
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; multiply values
           dw      ex_mul
           lbr     level_3c            ; then continue
level_3a:  smi     1                   ; check for division
           lbnz    level_3n            ; jump if not
           inc     ra                  ; move past /
           sep     scall               ; call level 4 to get value
           dw      level_4
           lbdf    err_ret             ; jump on syntax error
           sep     scall               ; perform division
           dw      ex_div
           lbr     level_3c            ; then keep processing
level_3n:  adi     0                   ; signal no error
           sep     sret                ; and return

; ***********************************************
; *** Check for numbers, variables, functions ***
; ***********************************************
level_4:   ldn     ra                  ; get token
           smi     TKN_NUM             ; check for number
           lbnz    level_4a            ; jump if not
           inc     ra                  ; move past token
           lda     ra                  ; retrieve actual number
           phi     rf
           lda     ra
           plo     rf
push_it:   sep     r7                  ; place onto stack
           db      ex_push.0
           adi     0                   ; signal no error
           sep     sret                ; and return
level_4a:  ldn     ra                  ; get token
           smi     84h                 ; check for open parens
           lbnz    level_4b            ; jump if not
           inc     ra                  ; move past parens
           sep     scall               ; evaluate inside parens
           dw      expr
           lbdf    err_ret
closed:    lda     ra                  ; check for closing parens
           smi     085h
           lbnz    syn_err             ; no closing parens is a syntax error
           adi     0                   ; otherwise good value computed
           sep     sret                ; return
level_4b:  ldn     ra                  ; get token
           sep     scall               ; see if variable name
           dw      f_isalnum
           lbnf    level_4c            ; jump if not
           sep     scall               ; get variable address
           dw      get_var  
           lbdf    err_ret
           lda     rf                  ; retrieve value from variable
           plo     re
           lda     rf
           plo     rf
           glo     re
           phi     rf
           lbr     push_it             ; put onto stack and return
level_4c:  lda     ra                  ; last try, functions
           shl                         ; is high bit set
           lbnf    syn_err             ; syntax error if not
           shr     
           smi     020                 ; check for PEEK
           lbz     fn_peek             ; jump if so
           smi     1                   ; check for FRE
           lbz     fn_fre              ; jump if so
           smi     1                   ; check for RND
           lbz     fn_rnd              ; jump if so
           smi     1                   ; check for INP
           lbz     fn_inp              ; jump if so
           smi     1                   ; check for FLG
           lbz     fn_flg              ; jump if so
#if LEVEL>=2
           smi     29                  ; check for VARPTR
           lbz     fn_varptr           ; jump if so
           smi     2                   ; check for LEN
           lbz     fn_len              ; jump if so
           smi     1                   ; check for ASC
           lbz     fn_asc              ; jump if so
           smi     1                   ; check for VAL
           lbz     fn_val              ; jump if so
#endif
           smi     0                   ; signal an error
           sep     sret                ; and return

; ******************************************************************************
; ***                       End of expression evaluator                      ***
; ******************************************************************************


; ******************************************************************************
; ***                         Start of L1 functions                          ***
; ******************************************************************************
; *******************
; *** Process FLG ***
; *******************
fn_flg:    sep     r7                  ; get flags
           db      get_flags.0
           plo     rf                  ; place into rf
           ldi     0                   ; high byte is zero
           phi     rf
           sep     r7                  ; place onto stack 
           db      ex_push.0
           lbr     closed              ; be sure function is closed

; *******************
; *** Process FRE ***
; *******************
#if LEVEL==1
fn_fre:    sep     scall               ; get end of basic
           dw      bas_end
           sep     r7                  ; move to rd
           db      rf_rd.0
           ldi     07fh                ; end of memory
           phi     rf
           ldi     0ffh
           plo     rf
#else
fn_fre:    sep     scall               ; get end of basic
           dw      end_vars
           sep     r7                  ; move to rd
           db      rf_rd.0
           sep     scall               ; get end of heap
           dw      end_heap
#endif
           glo     rd                  ; subtract end of variables
           str     r2
           glo     rf
           sm
           plo     rf
           ghi     rd
           str     r2
           ghi     rf
           smb
           phi     rf
           sep     r7                  ; put value onto stack
           db      ex_push.0
           lbr     closed              ; check to be sure function is closed 
           
; *******************
; *** Process INP ***
; *******************
fn_inp:    sep     scall               ; get argument
           dw      expr
           lbdf    err_ret
           sep     r7                  ; retrieve port
           db      ex_pop.0
           ldi     high buffer         ; need somewhere for command
           phi     rd
           ldi     low buffer
           plo     rd
           glo     rf
           ani     7                   ; mask for range
           lbz     val_err             ; jump if error
           adi     68h                 ; convert to INP instructino
           str     rd                  ; store into memory
           inc     rd
           ldi     0d3h                ; function to reset P=3
           str     rd
           dec     rd                  ; point rd back to inp instruction
           sep     rd                  ; and execute it
           plo     rf                  ; put read value into rf
           ldi     0                   ; zero high byte
           phi     rf
           sep     r7                  ; put read value on expr stack
           db      ex_push.0
           lbr     closed              ; and be sure function is closed

; ********************
; *** Process PEEK ***
; ********************
fn_peek:   sep     scall               ; get argument
           dw      expr
           lbdf    err_ret             ; jump if error occured
           sep     r7                  ; get address
           db      ex_pop.0
           ldn     rf                  ; read value from memory
           plo     rf                  ; put back into rf
           ldi     0                   ; zero high byte
           phi     rf
           sep     r7                  ; put value onto stack
           db      ex_push.0
           lbr     closed              ; check to be sure function is closed 
           
; *******************
; *** Process RND ***
; *******************
fn_rnd:    ldi     16                  ; need to get 16 bits
rnd_lp:    stxd                        ; save count
           sep     scall               ; get random bit
           dw      fn_lfsr
           glo     rf                  ; shift into result
           shlc
           plo     rf
           ghi     rf
           shlc
           phi     rf
           irx                         ; recover count
           ldx
           smi     1                   ; minus 1
           lbnz    rnd_lp              ; keep looping until all bits read
           sep     r7                  ; put result onto stack
           db      ex_push.0
           sep     scall               ; evaluate argument
           dw      expr
           sep     scall               ; get modulo
           dw      ex_mod
           lbr     closed              ; then be sure function is closed

; ******************************************************************************
; ***                           End of L1 functions                          ***
; ******************************************************************************



#if LEVEL>=2
; ******************************************************************************
; ***                         Start of L2 functions                          ***
; ******************************************************************************
; **********************
; *** Process VARPTR ***
; **********************
fn_varptr: ldn     ra                 ; get next token
           sep     scall              ; must be alpha, indicating a variable
           dw      f_isalpha
           lbnf    syn_err            ; otherwise syntax error
           sep     scall              ; get variables location
           dw      get_var
           lbdf    err_ret            ; jump if error occurred
           sep     r7                 ; place onto expression stack
           db      ex_push.0
           lbr     closed              ; check to be sure function is closed 

; ******************************************************************************
; ***                       Start of String functions                        ***
; ******************************************************************************

; *******************
; *** Process ASC ***
; *******************
fn_asc:    sep     scall              ; get argument
           dw      sexpr
           lbdf    err_ret            ; jump if error occurred
           sep     r7                 ; retrieve string address
           db      ex_pop.0
           sep     scall              ; deallocate temporary storage
           dw      dealloc
           ldn     rf                 ; get first byte for string
           plo     rf                 ; set RF to value
           ldi     0
           phi     rf
           lbr     len_dn             ; put answer on stack and finish

; *******************
; *** Process CHR ***
; *******************
fn_chr:    sep     scall              ; evaluate argument
           dw      expr
           lbdf    err_ret            ; jump if error occurred
           sep     r7                 ; get buffer
           db      set_buf.0
           sep     r7                 ; put into rd
           db      rf_rd.0
           sep     r7                 ; get argument
           db      ex_pop.0
           glo     rf                 ; put answer into buffer
           str     rd
           inc     rd
str_term:  ldi     0ffh               ; terminate it
           str     rd
           inc     rd
           lbr     copy_str           ; copy string into heap

; *********************
; *** Process LEFT$ ***
; *********************
fn_left:   sep     scall              ; get first argument
           dw      sexpr
           lbdf    err_ret            ; jump if error occurred
           lda     ra                 ; get next token
           smi     08dh               ; must be a comma
           lbnz    syn_err            ; else syntax error
           sep     scall              ; get length argument
           dw      expr
           lbdf    err_ret            ; jump if error occurred
left_go2:  sep     r7                 ; get number of characters
           db      ex_pop.0
           glo     rf                 ; save number of characters
           stxd                      
           sep     r7                 ; get source address
           db      ex_pop.0
           sep     scall              ; deallocate temporary storage
           dw      dealloc
           irx                        ; recover character count
           ldx
           plo     re                 ; into re
left_go:   ldi     high buffer        ; setup destination buffer
           phi     rd
           ldi     low buffer
           plo     rd
left_lp:   glo     re                 ; see if done
           lbz     str_term           ; jump if so
           dec     re                 ; decrement re
           lda     rf                 ; get byte from source
           str     rd                 ; place into destination
           inc     rd
           lbr     left_lp            ; loop until done

; *******************
; *** Process LEN ***
; *******************
fn_len:    sep     scall              ; get argument
           dw      sexpr
           lbdf    err_ret            ; jump if error occurred
           sep     r7                 ; retrieve string address
           db      ex_pop.0
           sep     scall              ; deallocate temporary storage
           dw      dealloc
           sep     r7                 ; put it in RD
           db      rf_rd.0
           ldi     0                  ; set count to 0
           phi     rf
           plo     rf
len_lp:    lda     rd                 ; get byte from string
           xri     0ffh               ; see if last byte was read
           lbz     len_dn             ; jump if so
           inc     rf                 ; increment count
           lbr     len_lp
len_dn:    sep     r7                 ; push answer onto stack
           db      ex_push.0
           lbr     closed             ; finish up

; ********************
; *** Process MID$ ***
; ********************
fn_mid:    sep     scall              ; get first argument
           dw      sexpr
           lbdf    err_ret            ; jump if error occurred
           lda     ra                 ; get next token
           smi     08dh               ; must be a comma
           lbnz    syn_err            ; else syntax error
           sep     scall              ; get start argument
           dw      expr
           lbdf    err_ret            ; jump if error occurred
           sep     r7                 ; get start
           db      ex_pop.0
           dec     r9                 ; keep on stack as well
           dec     r9
           glo     rf                 ; zero is not allowed
           lbz     val_err
           lda     ra                 ; get next token
           smi     08dh               ; must be a comma
           lbnz    syn_err            ; else syntax error
           sep     scall              ; get count argument
           dw      expr
           lbdf    err_ret            ; jump if error occurred
           sep     r7                 ; retrieve count
           db      ex_pop.0
           glo     rf                 ; save it
           stxd
           sep     r7                 ; get position
           db      ex_pop.0
           glo     rf                 ; save position on stack
           stxd
           sep     r7                 ; get source string address
           db      ex_pop.0
           dec     r9                 ; keep address on stack
           dec     r9
           sep     scall              ; clear temporary storage
           dw      dealloc
           sep     r7                 ; get source string address
           db      ex_pop.0
           irx                        ; recover star position
           ldx                        ; into low re
           plo     re
mid_lp1:   dec     re
           glo     re                 ; see if done
           lbz     mid_dn             ; jump if so
           ldn     rf                 ; get character
           xri     0ffh               ; check for terminator
           lbz     mid_dn             ; jump if found
           inc     rf                 ; move source forward
           lbr     mid_lp1            ; loop until start found
mid_dn:    ldi     high buffer        ; setup destination buffer
           phi     rd
           ldi     low buffer
           plo     rd
           irx                        ; recover count
           ldx
           plo     re
mid_lp2:   glo     re                 ; see if done
           lbz     mid_dn2            ; jump if so
           dec     re                 ; decrement count
           lda     rf                 ; get byte from string
           xri     0ffh               ; see if end of string
           lbz     mid_dn2            ; jump if so
           xri     0ffh               ; recover character
           str     rd                 ; store into result
           inc     rd
           lbr     mid_lp2            ; loop back until done
mid_dn2:   ldi     0ffh               ; terminate string
           str     rd
           ldi     high buffer        ; setup destination buffer
           phi     rf
           ldi     low buffer
           plo     rf
           sep     scall              ; copy string to heap
           dw      str2heap
           lbr     closed             ; finish up

          

; **********************
; *** Process RIGHT$ ***
; **********************
fn_right:  sep     scall              ; get first argument
           dw      sexpr
           lbdf    err_ret            ; jump if error occurred
           lda     ra                 ; get next token
           smi     08dh               ; must be a comma
           lbnz    syn_err            ; else syntax error
           sep     scall              ; get length argument
           dw      expr
           lbdf    err_ret            ; jump if error occurred
           sep     r7                 ; get number of characters
           db      ex_pop.0
           glo     rf                 ; move to re
           stxd                       ; place on stack
           sep     r7                 ; point to buffer
           db      set_buf.0
           sep     r7                 ; get source address
           db      ex_pop.0
           sep     scall              ; deallocate temporary storage
           dw      dealloc 
           ldi     0                  ; setup character count
           plo     re
right_lp1: lda     rf                 ; get byte from source
           xri     0ffh               ; see if terminator
           lbz     right_1            ; jump if so
           inc     re                 ; increment count
           lbr     right_lp1          ; keep looking for end
right_1:   irx                        ; point to requested count
           ldx                        ; read it 
           plo     rb                 ; copy it here
           phi     rb
           dec     rf                 ; point to terminator
right_lp2: glo     rb                 ; done yet
           lbz     right_f            ; jump if so
           glo     re                 ; also check against length
           lbz     right_f
           dec     rf                 ; move back one char
           dec     rb                 ; decrement request count
           dec     re                 ; and size
           lbr     right_lp2          ; and loop until 1 is zero
right_f:   ghi     rb                 ; get request count
           plo     re                 ; place into re
           lbr     left_go            ; copy the string to the buffer


; ********************
; *** Process STR$ ***
; ********************
fn_str:    sep     scall              ; get argument
           dw      expr
           lbdf    err_ret            ; jump if error resulted
           sep     r7                 ; retrieve value
           db      ex_pop.0
           sep     r7                 ; transfer to RD
           db      rf_rd.0
           sep     r7                 ; need a buffer
           db      set_buf.0
           sep     scall              ; convert number to ascii
           dw      f_intout
           ldi     0ffh               ; terminate it
           str     rf
           inc     rf
           sep     r7                 ; move address to rd
           db      rf_rd.0
copy_str:  sep     r7                 ; point to beginning of buffer
           db      set_buf.0
           sep     scall              ; copy string to heap
           dw      str2heap
           lbdf    err_ret            ; jump on error
           lbr     closed             ; finish up

om_err:    ldi     ERR_NOMEM          ; indicate out of memory
           smi     0
           sep     sret               ; adn return
; *******************
; *** Process VAL ***
; *******************
fn_val:    sep     scall              ; get argument
           dw      sexpr
           lbdf    err_ret            ; jump if error occurred
           sep     r7                 ; retrieve string address
           db      ex_pop.0
           sep     scall              ; deallocate temporary storage
           dw      dealloc
           sep     scall              ; convert to integer
           dw      f_atoi
           ghi     rd                 ; put back into rf
           phi     rf
           glo     rd
           plo     rf
           lbr     len_dn             ; finish

new_mexpr: ldi     high expstack       ; setup expression stack
           phi     r9
           ldi     low expstack
           plo     r9
mexpr:     ldn     ra                  ; get first char from expression
           smi     TKN_QSTR            ; see if a string
           lbz     mexpr_s             ; jump if so
           smi     1                   ; see if numeric
           lbz     mexpr_n             ; jump if so
           ldn     ra                  ; see if starts with a variable
           sep     scall
           dw      f_isalpha
           lbnf    mexpr_nv            ; jump if not a variable
           glo     ra                  ; save variable address
           stxd
           ghi     ra
           stxd
           sep     scall               ; and retrieve variable
           dw      get_var
           plo     re
           irx                         ; recover original ra
           ldxa
           phi     ra
           ldx
           plo     ra
           glo     re
           smi     3                   ; is it a string variable
           lbz     mexpr_s             ; jump if so
           lbr     mexpr_n             ; otherwise numeric
mexpr_nv:  ldn     ra                  ; recover character
           smi     CMD_START           ; check if string function
           lbnf    mexpr_n             ; jump if numeric function
           smi     0a0h
           lbnf    mexpr_n             ; jump if numeric function
           smi     5                   ; check high range of string functions
           lbnf    mexpr_s
           lbr     mexpr_n
mexpr_s:   sep     scall               ; call string evaluator
           dw      sexpr
           ldi     3                   ; signal string result
           sep     sret                ; and return
mexpr_n:   sep     scall               ; call numeric evaluator
           dw      expr
mexpr_r:   ldi     2                   ; signal string result
           sep     sret                ; and return

; *****************************************************************
; **** Strcmp compares the strings pointing to by R(D) and R(F) ***
; **** Returns:                                                 ***
; ****    R(F) = R(D)     0                                     ***
; ****    R(F) < R(D)     -1 (255)                              ***
; ****    R(F) > R(D)     1                                     ***
; *****************************************************************
strcmp:  lda     rd          ; get next byte in string
         xri     0ffh        ; check for end
         bz      strcmpe     ; found end of first string
         xri     0ffh        ; restore character
         str     r2          ; store into memory
         lda     rf          ; get byte from first string
         sm                  ; subtract 2nd byte from it
         bz      strcmp      ; so far a match, keep looking
         bnf     strcmp1     ; jump if first string is smaller
         ldi     1           ; indicate first string is larger
         lskp                ; and return to caller
strcmp1: ldi     255         ; return -1, first string is smaller
         sep     sret        ; return to calelr
strcmpe: lda     rf          ; get byte from second string
         xri     0ffh        ; check for end of 2nd string
         bz      strcmpm     ; jump if also zero
         ldi     1           ; first string is smaller (returns -1)
         sep     sret        ; return to caller
strcmpm: ldi     0           ; strings are a match
         sep     sret        ; return to caller

docmp:     inc     ra                  ; move past =
           sep     scall               ; get next argument
           dw      sexpr_l1
           lbdf    err_ret             ; jump in case of error
           sep     r7                  ; retrieve second argument
           db      ex_pop.0
           sep     r7                  ; move it to rd
           db      rf_rd.0
           sep     r7                  ; retrieve first argument
           db      ex_pop.0
           sep     scall               ; compare teh strings
           dw      strcmp
           adi     0                   ; signal no error
           sep     sret                ; return

; *****************************
; *** Copy string into heap ***
; *** RF - String to copy   ***
; *** Returns: RF - address ***
; *****************************
str2heap:  ldi     0                   ; setup count
           phi     rd
           plo     rd
           glo     rf                  ; save string address
           stxd
           ghi     rf
           stxd
str_hp_l1: inc     rd                  ; increment count
           lda     rf                  ; get byte from string
           xri     0ffh                ; check for terminator
           lbnz    str_hp_l1           ; jump if not yet found
           glo     rd                  ; save count
           stxd
           plo     rf                  ; and put into rf
           ghi     rd
           stxd
           phi     rf
           sep     scall               ; allocate the memory
           dw      alloc
           irx                         ; recover count
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa                        ; and source address
           phi     rd
           ldx
           plo     rd
           lbdf    err_ret             ; jump if error occurred
           sep     r7                  ; put address onto expression stack
           db      ex_push.0
str_hp_l2: lda     rd                  ; read byte from source
           str     rf                  ; store into destination
           inc     rf
           dec     rb                  ; decrement count
           glo     rb                  ; see if done
           str     r2
           ghi     rb
           or
           lbnz    str_hp_l2
           adi     0                   ; signal no error
           sep     sret                ; and return

; **************************************************
; *** Process string expression pointed to by RA ***
; **************************************************
new_sexpr: ldi     high expstack       ; setup expression stack
           phi     r9
           ldi     low expstack
           plo     r9
sexpr:     sep     scall               ; get argument
           dw      sexpr_l1
           lbdf    err_ret             ; jump on error
           ldn     ra                  ; check for relational symbols
           smi     86h                 ; check for =
           lbnz    sexpr_a             ; jump if not
           sep     scall               ; call string comparison
           dw      docmp
           lbdf    err_ret             ; jump on error
           lbnz    sfalse              ; jump if falst
strue:     ldi     0ffh                ; put -1 on stack
s_stack:   sex     r9                  ; point to expression stack
           stxd
           stxd
           sex     r2                  ; point x back to correct stack
sfix:      ldi     high mexpr_r        ; change to numeric return
           phi     r6
           ldi     low mexpr_r
           plo     r6
           adi     0                   ; signal success
           sep     sret                ; and return
sfalse:    ldi     0                   ; need a zero on the stack
           lbr     s_stack             ; finish up
sexpr_a:   smi     1                   ; check for <=
           lbnz    sexpr_b             ; jump if not
           sep     scall               ; call string comparison
           dw      docmp
           lbdf    err_ret             ; jump on error
           lbz     strue               ; jump if equal
           xri     0ffh             
           lbz     strue
           lbr     sfalse
sexpr_b:   smi     1                   ; check for >=
           lbnz    sexpr_c             ; jump if not
           sep     scall               ; call string comparison
           dw      docmp
           lbdf    err_ret             ; jump on error
           lbz     strue               ; jump if equal
           xri     0ffh             
           lbnz    strue
           lbr     sfalse
sexpr_c:   smi     1                   ; check for >=
           lbnz    sexpr_d             ; jump if not
           sep     scall               ; call string comparison
           dw      docmp
           lbdf    err_ret             ; jump on error
           lbnz    strue               ; jump if equal
           lbr     sfalse
sexpr_d:   smi     1                   ; check for <
           lbnz    sexpr_e             ; jump if not
           sep     scall               ; call string comparison
           dw      docmp
           lbdf    err_ret             ; jump on error
           lbz     sfalse              ; false if they were equal
           xri     0ffh             
           lbz     strue
           lbr     sfalse
sexpr_e:   smi     1                   ; check for >
           lbnz    sexpr_f             ; jump if not
           sep     scall               ; call string comparison
           dw      docmp
           lbdf    err_ret             ; jump on error
           lbz     sfalse              ; false if they were equal
           xri     0ffh             
           lbnz    strue
           lbr     sfalse

sexpr_f:   ldn     ra                  ; recover symbol
           smi     80h
           lbnz    sexpr_g             ; jump if not +
           inc     ra                  ; move past plus
           sep     scall               ; get next argument
           dw      sexpr_l1
           lbdf    err_ret             ; jump in case of error
           sep     r7                  ; recover 2nd string
           db      ex_pop.0
           sep     scall               ; deallocate temporary storage
           dw      dealloc
           sep     r7                  ; move to rd
           db      rf_rd.0
           sep     r7                  ; recover 1st string
           db      ex_pop.0
           sep     scall               ; deallocate temporary storage
           dw      dealloc
           ldi     high buffer         ; setup buffer
           phi     rb
           ldi     low buffer
           plo     rb
cat_lp1:   lda     rf                  ; read byte from 1st string
           str     rb                  ; store into buffer
           inc     rb
           xri     0ffh                ; was terminator written
           lbnz    cat_lp1             ; loop back if not
           dec     rb                  ; need to overwrite terminator
cat_lp2:   lda     rd                  ; read byte from 2nd string
           str     rb                  ; store into buffer
           inc     rb
           xri     0ffh                ; was terminator written
           lbnz    cat_lp2             ; loop back if not
           sep     r7                  ; get beginning of buffer
           db      set_buf.0
           sep     scall               ; and copy string to heap
           dw      str2heap
           lbdf    err_ret             ; jump if error
           lbr     sexpr_f             ; loop back for possibly more plusses

sexpr_g:   adi     0                   ; signal no error
           sep     sret                ; and return

sexpr_l1:  ldn     ra                  ; get next byte
           smi     TKN_QSTR            ; is it a quoted string
           lbnz    sexpr_l1a           ; jump if not
           inc     ra                  ; point to string
           sex     r9                  ; place address on expression stack
           glo     ra
           stxd
           ghi     ra
           stxd
           sex     r2                  ; point X back to real stack
sexpr_lp1: lda     ra                  ; need to find end
           xri     0ffh                ; check for terminator
           lbnz    sexpr_lp1           ; loop until found
           adi     0                   ; signal no error
           sep     sret                ; return with value
sexpr_l1a: lda     ra                  ; get token again
           smi     CMD_START           ; remove bias
           smi     0a0h                ; check for str$
           lbz     fn_str              ; jump if so
           smi     1                   ; check for chr$
           lbz     fn_chr              ; jump if so
           smi     1                   ; check for left$
           lbz     fn_left             ; jump if so
           smi     1                   ; check for right$
           lbz     fn_right            ; jump if so
           smi     1                   ; check for mid$
           lbz     fn_mid              ; jump if so

           dec     ra                  ; move back
           ldn     ra                  ; see if possible variable
           sep     scall
           dw      f_isalpha
           lbnf    syn_err             ; jump if not a possible variable
           sep     scall               ; get variable address
           dw      get_var
           smi     3                   ; must be a string variable
           lbnz    syn_err             ; else error
           lda     rf                  ; get pointed to data
           plo     re
           ldn     rf
           plo     rf                  ; and set rf to it
           glo     re
           phi     rf
           sep     r7                  ; place onto expression stack
           db      ex_push.0
           adi     0                   ; no errors
           sep     sret                ; return

sclosed:   lda     ra                  ; next token must be a )
           smi     085h
           lbnz    syn_err             ; else syntax error
           adi     0                   ; signal no error
           sep     sret                ; and return

; ******************************************************************************
; ***                           End of L2 functions                          ***
; ******************************************************************************
#endif

; **********************************************
; *** Find variable address pointed to by RA ***
; *** Returns: RF - address of value         ***
; **********************************************
#if LEVEL==1
get_var:   ldn     ra                  ; get value
           smi     'a'                 ; see if lowercase
           ldn     ra                  ; recover value
           lbnf    var_uc              ; jump if uppercase
           smi     32                  ; make it uppercase
var_uc:    smi     'A'                 ; convert to offset
           shl                         ; D is now offset
           str     r2                  ; place into memory for a moment
           ldi     low vars            ; point to variable storage
           add                         ; add in offset
           plo     rf                  ; set rf to address
           ldi     high vars
           adci    0                   ; propagate carry
           phi     rf
var_lp:    lda     ra                  ; need to get past variable name
           lbz     var_end             ; jump if terminator found
           shl                         ; check high bit
           lbnf    var_lp              ; loop until a high bit is found
var_end:   dec     ra                  ; move back to terminating carh
           adi     0                   ; signal no error
           ldi     2                   ; signal an integer variable
           sep     sret                ; return to caller
#else
 
get_var:   ldi     high var_pos        ; need variable table
           phi     rf
           ldi     low var_pos
           plo     rf
           lda     rf                  ; read variable table address
           plo     re                  ; save high byte for a moment
           ldn     rf                  ; get low byte
           plo     rf                  ; make RF variable table pointer
           glo     re
           phi     rf
var_lp:    ldn     rf                  ; see if at end of table
           lbz     var_new             ; yep, so new variable
           sep     r7                  ; make a copy of this position
           db      rf_rd.0
           inc     rf                  ; move past size
           glo     ra                  ; also keep RA
           plo     rb
           ghi     ra
           phi     rb
           sex     ra                  ; make X point to data stream
var_slp:   lda     rf                  ; get next byte from variable table
           plo     re
           shl                         ; shift high bit to DF
           glo     re                  ; and then value back
           lbdf    var_lst             ; jump if on last character
           sm                          ; compare entries
           inc     ra                  ; move ra to next character before testing
           lbz     var_slp             ; jump on match
no_mtch:   ghi     rb                  ; no match, so reset ra
           phi     ra
           glo     rb
           plo     ra
           sex     rd                  ; point X to next variable offset
           glo     rd                  ; add into position
           add
           plo     rf                  ; and place into RF
           ghi     rd
           adci    0
           phi     rf                  ; rf now pointing at next variable entry
           sex     r2                  ; point X back to stack
           lbr     var_lp              ; and check next entry
var_lst:   ani     07fh                ; clear high bit
           plo     re                  ; keep a copy
           smi     4                   ; is variable an arry
           lbz     is_array            ; jump if so
           glo     re                  ; recover re
           sm                          ; check for match
           lbnz    no_mtch             ; jump if not
           inc     ra                  ; move ra past variable name
           ldn     ra                  ; need to make sure variable is ended
           sep     scall
           dw      f_isalnum
           lbdf    no_mtch             ; no match if still variable name
           plo     re
           smi     '$'                 ; make sure not a string
           lbz     no_mtch
           glo     re
           smi     084h                ; make sure not an array
           lbz     no_mtch             ; else no match
           lda     rf                  ; get type
           sex     r2                  ; point X back to stack
           adi     0                   ; signal no error
           sep     sret                ; so return
is_array:  lda     ra                  ; next token must also be a (
           smi     84h
           lbnz    no_mtch             ; else no match
           lbr     array               ; item found was an array, proccess it

var_new:   glo     rf                  ; save this position
           plo     rd
           ghi     rf
           phi     rd
           inc     rf                  ; move past size
var_nmlp:  lda     ra                  ; read byte from token stream
           sep     scall               ; see if valid for variable name
           dw      f_isalnum
           lbnf    var_nmdn            ; jump if done with name
           str     rf                  ; store into variable entry
           inc     rf
           lbr     var_nmlp            ; loop back until full name is copied
var_nmdn:  smi     '$'                 ; check for string variables
           lbnz    var_notst           ; jump if not a string
           ldi     ('$')+80h           ; append to variable name
           str     rf
           inc     rf
           ldi     3                   ; signify a string
           str     rf
           inc     rf
           ldi     high term           ; point to a null string
           str     rf
           inc     rf
           ldi     low term
           str     rf
           inc     rf
           glo     rf                  ; need to find offset
           str     r2
           glo     rd
           sd
           str     rd                  ; store offset at beginning of entry
           ldi     0                   ; write end of variable table entry
           str     rf
           dec     rf                  ; move back to address field
           dec     rf
           adi     0                   ; signal no error
           ldi     3                   ; signal string variable
           sep     sret                ; and return to caller

var_notst: dec     ra                  ; move RA back
           dec     rf                  ; point to last char of varname
           ldn     rf                  ; and retrieve it
           ori     80h                 ; set high bit
           str     rf                  ; and write it back
           inc     rf                  ; move to type field
           ldi     2                   ; only integers for now
           str     rf
           inc     rf
           ldi     0                   ; new vars have zero for their value
           str     rf
           inc     rf                  ; move past value field
           str     rf
           inc     rf
           glo     rf                  ; need to find offset
           str     r2
           glo     rd
           sd
           str     rd                  ; store offset at beginning of entry
           ldi     0                   ; write end of variable table entry
           str     rf
           dec     rf                  ; move rf to value field
           dec     rf
           adi     0                   ; signal no error
           ldi     2                   ; signal integer variable
           sep     sret                ; and return to caller
; ******************************************
; *** process an array variable location ***
; ******************************************
array:     sex     r2                  ; point X back to stack
           inc     rf                  ; should now be pointing to array address
           lda     rf                  ; retreive it
           plo     re
           ldn     rf
           plo     rf
           glo     re
           phi     rf                  ; rf now points to array descriptor
           ghi     r9                  ; see if expression stack is defined
           lbnz    array_1             ; jump if it is
           glo     r9 
           lbnz    array_1
           ldi     high expstack       ; setup expression stack
           phi     r9
           ldi     low expstack
           plo     r9
array_1:   sep     r7                  ; move address to RD
           db      rf_rd.0
           ldi     0                   ; set initial accumulation to 0
           phi     rf
           plo     rf
           sep     r7
           db      ex_push.0           ; tos now has accumultaion
           lda     rd                  ; get number of dimensions
           stxd                        ; save it
           sep     r7                  ; save this position
           db      push_rd.0
; Number of dimensions is on stack, RD->dimension size, on top of stack
ar_mullp2: sep     scall               ; get next dimension
           dw      expr
           lbdf    err3_ret            ; exit if error
           sep     r7                  ; recvoer array descriptor address
           db      pop_rd.0
           lda     rd                  ; get dimension size
           stxd                        ; place onto stack
           ldn     rd                  ; lsb of size
           str     r2                  ; also on stack
           dec     rd
           sep     r7                  ; recover first dimension
           db      ex_pop.0
           dec     r9                  ; and keep on expression stack
           dec     r9
           glo     rf                  ; check range
           sm
           irx                         ; point x to msb
           ghi     rf                  ; continue subtraction
           smb
           lbdf    dim_err             ; jump on dimension error
           irx                         ; recover dimension count
           ldx
           smi     1                   ; and subtract 1
           lbz     array_dn            ; jump if done processing arguments
           plo     re                  ; save this
           sep     r7                  ; put dimension pointer on stack
           db      push_rd.0
           glo     re                  ; get it back
           stxd                        ; put dim count back on stack
           inc     rd
           inc     rd
ar_mullp:  stxd                        ; save dimension count
           lda     rd                  ; get next dimension size
           phi     rf                  ; into rf
           lda     rd
           plo     rf
           sep     r7                  ; place onto expression stack
           db      ex_push.0
           sep     r7                  ; save pointer
           db      push_rd.0
           sep     scall               ; multiply numbers
           dw      ex_mul
           sep     r7                  ; recover rd
           db      pop_rd.0
           irx                         ; and dimension count
           ldx
           smi     1                   ; minus 1
           lbnz    ar_mullp            ; morre multiplications to go
           sep     scall               ; add total to accumulation
           dw      ex_add
           irx                         ; recover dimentsion count
           ldx
           plo     re                  ; set aside
           sep     r7                  ; get dimension pointer
           db      pop_rd.0
           inc     rd                  ; move to next dimension
           inc     rd
           glo     re                  ; get dimension count
           stxd                        ; and save
           sep     r7                  ; and put back on stack
           db      push_rd.0
           lda     ra                  ; get next token
           smi     08dh                ; must be a comma
           lbnz    err3_ret            ; error if not
           lbr     ar_mullp2           ; loop back
array_dn:  inc     rd                  ; move past final dimension
           inc     rd
           sep     r7                  ; save location
           db      push_rd.0
           sep     scall               ; add last dimension to toal
           dw      ex_add
           sep     r7                  ; get cell number
           db      ex_pop.0
           glo     rf                  ; multiply by 2
           shl
           plo     rf
           ghi     rf
           shlc
           phi     rf
           sep     r7                  ; and put back onto stack
           db      ex_push.0
           sep     r7                  ; recover location
           db      pop_rf.0
           sep     r7                  ; add to base addres
           db      ex_push.0
           sep     scall
           dw      ex_add
           sep     r7                  ; get final cell number
           db      ex_pop.0
           lda     ra                  ; last token must be a )
           smi     85h
           lbnz    syn_err             ; else error
           ldi     2                   ; array is integer
           adi     0                   ; signal success
           sep     sret                ; return to caller


dim_err:   ldi     ERR_BADDIM          ; signal bad dimensions
           smi     0
           lbr     err1_ret            ; and return
err3_ret:  irx                         ; dump 3 bytes off the stack
err2_ret:  irx
err1_ret:  irx
           sep     sret                ; and return

#endif


; ******************************************************************************
; ***                         Start of L1 statements                         ***
; ******************************************************************************
; *******************
; *** Process END ***
; *******************
ex_end:    ldi     0                   ; terminate program execution
           phi     rc
           plo     rc
           lbr     exec_dn             ; finish up

; *********************
; *** Process GOSUB ***
; *********************
ex_gosub:  sep     scall               ; evaluate expression for line number
           dw      new_expr
           lbdf    syn_err             ; jump on error
           sep     r7                  ; retrieve line number
           db      ex_pop.0
           sep     r7                  ; move it to rd
           db      rf_rd.0
           glo     rc                  ; save line in case of error
           stxd
           ghi     rc
           stxd
           ghi     rc                  ; save current line to gosub stack
           str     r8
           inc     r8
           glo     rc
           str     r8
           inc     r8
           sep     r7                  ; find line
           db      find_ln.0
           lbnf    no_line             ; jump if line was not found
           ghi     ra                  ; save current pointer to gosub stack
           str     r8
           inc     r8
           glo     ra
           str     r8
           inc     r8
           lbr     goto_go             ; then treat like goto

; ********************
; *** Process GOTO ***
; ********************
ex_goto:   sep     scall               ; evaluate expression for line number
           dw      new_expr
           lbdf    err_ret             ; jump on error
           ldn     ra                  ; must be terminator
           lbnz    syn_err
goto_go2:  sep     r7                  ; retrieve line number
           db      ex_pop.0
           sep     r7                  ; move it to rd
           db      rf_rd.0
           glo     rc                  ; save line in case of error
           stxd
           ghi     rc
           stxd
           sep     r7                  ; find line
           db      find_ln.0
           lbnf    no_line             ; jump if line was not found
           irx                         ; get rid of old line
           irx
goto_go:   ghi     rc                  ; copy line address to RA
           phi     ra
           glo     rc
           plo     ra
           lbr     exec_tst            ; execute from new line
no_line:   irx                         ; recover current line
           ldxa
           phi     rc
           ldx
           plo     rc
err_noln:  ldi     ERR_NOLIN           ; signal line not found
           smi     0                   ; signal error
           sep     sret                ; and return

; ******************
; *** Process IF ***
; ******************
ex_if:     sep     scall               ; evaluate expression
#if LEVEL==1
           dw      new_expr
#else
           dw      new_mexpr
#endif
           lbdf    err_ret             ; jump on error
           sep     r7                  ; retrieve result
           db      ex_pop.0
           glo     rf                  ; see if success
           str     r2
           ghi     rf
           or
           lbz     exec_dn             ; jump if IF failed test
if_chk:    ldn     ra                  ; check for optional THEN
           smi     09fh
           lbnz    execute             ; not there, so just continue
           inc     ra                  ; move past it
           lbr     execute             ; and continue

; *********************
; *** Process INPUT ***
; *********************
ex_input:  ldn     ra                  ; get next token
           smi     TKN_QSTR            ; is it a quoted string
           lbz     input_pr            ; jump if so
input_lp:  ldn     ra                  ; see if done
           lbz     chk_term            ; jump if so
           ldn     ra                  ; get character
           sep     scall               ; must be a variable name
           dw      f_isalpha
           lbnf    syn_err             ; otherwise error
           sep     scall               ; get variable address
           dw      get_var
           lbdf    err_ret
#if LEVEL>=2
           smi     2                   ; is variable an integer
           lbz     inp_num             ; jump if so
           sep     scall               ; deallocate previous value
           dw      de_str
           ldi     high expstack       ; setup expression stack
           phi     r9
           ldi     low expstack
           plo     r9
           sep     scall               ; get string input
           dw      get_sinput
           lbr     inp_cnt             ; store value
   lbr  syn_err
#endif
inp_num:   sep     scall               ; get input
           dw      get_input
           lbdf    err_ret             ; jump on error
inp_cnt:   ghi     rd                  ; store into variable
           str     rf
           inc     rf
           glo     rd
           str     rf
           ldn     ra                  ; get next token
           lbz     chk_term            ; jump if terminator
           smi     093h                ; colon also ends input
           lbz     chk_term
           lda     ra                  ; get next token
           smi     08dh                ; must be a comma
           lbz     input_lp            ; process next variable
           lbr     syn_err             ; otherwise error
input_pr:  inc     ra                  ; move past quote token
prompt_lp: lda     ra                  ; get byte from token stream
           xri     0ffh                ; see if last character
           lbz     prompt_dn           ; jump if so
           xri     0ffh                ; otherwise restore character
           sep     scall               ; and output it
           dw      TYPE
           lbr     prompt_lp           ; loop back until done
prompt_dn: lda     ra                  ; get next token
           smi     08ch                ; must be a semicolon
           lbnz    syn_err             ; otherwise error
           lbr     input_lp            ; loop back to get input

; *******************
; *** Process LET ***
; *******************
ex_let:    ldn     ra                  ; get next char
           sep     scall               ; it must be alph
           dw      f_isalpha
           lbnf    syn_err             ; otherwise syntax error
           ldi     0                   ; mark expression stack as undefined
           phi     r9
           plo     r9
           sep     scall               ; get variable address
           dw      get_var
           lbdf    err_ret
           plo     re                  ; save variable type
           lda     ra                  ; next token must be an =
           smi     86h
           lbnz    syn_err             ; jump on error
           glo     rf                  ; save variable address
           stxd
           ghi     rf
           stxd
           glo     re                  ; save variable type
           stxd
#if LEVEL>=2
           sep     scall               ; dealloate possible string variable
           dw      de_str
#endif
           sep     scall               ; evaluate expression
#if LEVEL==1
           dw      new_expr
#else
           dw      new_mexpr
#endif
           lbdf    err_ret             ; jump if error occurred
           irx                         ; need to check types
           xor
           plo     re
           irx                         ; get variable address
           ldxa
           phi     rd
           ldx
           plo     rd
           glo     re
           lbnz    syn_err             ; syntax error if types do not match
           sep     r7                  ; recover result
           db      ex_pop.0
           ghi     rf                  ; write value to variable
           str     rd
           inc     rd
           glo     rf
           str     rd
           lbr     chk_term            ; done

; ****************************
; *** Process LIST command ***
; ****************************
ex_list:   ldi     0                   ; setup list boundaries
           phi     r8
           plo     r8
           ldi     0ffh
           phi     r9
           plo     r9
           dec     r9
           ldn     ra                  ; get next token
           lbz     ex_flist            ; jump if full list requested
           smi     81h                 ; is it the minus
           lbz     to_end              ; jump if so
           lda     ra                  ; get token again
           smi     TKN_NUM             ; must be a number
           lbnz    syn_err             ; otherwise error
           lda     ra                  ; retrieve number into r8
           phi     r8
           lda     ra
           plo     r8
           ldn     ra                  ; see if single line
           lbz     list_1              ; jump if so
to_end:    lda     ra
           smi     81h                 ; must now be a minus sign
           lbnz    syn_err             ; else error
           ldn     ra                  ; see if open end
           lbz     ex_flist            ; jump if so
           lda     ra                  ; and retrieve it
           smi     TKN_NUM             ; must be a number
           lbnz    syn_err             ; otherwise error
           lda     ra                  ; retrieve number into R9
           phi     r9
           lda     ra
           plo     r9
           ldn     ra                  ; must be followd by terminator
           lbnz    syn_err
ex_flist:  glo     ra                  ; save token address
           stxd
           ghi     ra
           stxd
           glo     rc                  ; save line address
           stxd
           ghi     rc
           stxd
           ldi     high basic          ; point to basic storage
           phi     ra                  ; put into ra and rc
           phi     rc
           ldi     low basic
           plo     ra
           plo     rc
flist_lp:  ldn     ra                  ; get line size
           lbz     flist_dn            ; jump if done
           inc     ra                  ; retrieve line number
           lda     ra
           phi     rd
           ldn     ra
           plo     rd
           dec     ra                  ; put pointer back
           dec     ra
           glo     r8                  ; perform line-R8
           str     r2
           glo     rd
           sm
           ghi     r8
           str     r2
           ghi     rd
           smb
           lbnf    no_show             ; jump if line number was too small
           inc     r9
           glo     r9                  ; now line-R9
           str     r2
           glo     rd
           sm
           ghi     r9
           str     r2
           ghi     rd
           smb
           dec     r9
           lbdf    no_show             ; jump if line number was too large
show:      sep     r7                  ; setup output buffer
           db      set_buf.0
           sep     scall               ; detokenize the line
           dw      detoken
           sep     r7                  ; point to output buffer
           db      set_buf.0
           sep     scall               ; display it
           dw      MSG
           sep     scall               ; need a cr/lf
           dw      do_crlf
no_show:   sep     r7                  ; find next line
           db      next_ln.0
           ghi     rf                  ; transfer address
           phi     ra
           phi     rc
           glo     rf
           plo     ra
           plo     rc
           lbr     flist_lp            ; display next line
flist_dn:  irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     ra
           ldx
           plo     ra
           lbr     chk_term            ; goot at this opint
list_1:    ghi     r8                  ; transfer number
           phi     rd
           glo     r8
           plo     rd
           sep     r7                  ; find the line
           db      find_ln.0
           ghi     rc                  ; transfer address
           phi     ra
           glo     rc
           plo     ra
           ldi     0                   ; zero RC
           phi     rc
           plo     rc
           lbnf    err_noln            ; jump if line was not found
           sep     r7
           db      set_buf.0
           sep     scall               ; detokenize the line
           dw      detoken
           sep     r7                  ; point to output buffer
           db      set_buf.0
           sep     scall               ; display it
           dw      MSG
           sep     scall               ; need a cr/lf
           dw      do_crlf
           ldi     0                   ; make sure no program continues
           phi     rc
           plo     rc
           lbr     chk_term            ; done



chk_term:  ldn     ra                  ; get next token
           lbz     execute   
           smi     093h                ; colon is also valid
           lbnz    syn_err             ; should have been zero
           lbr     exec_coln
exec_good: adi     0                   ; signal no error
           sep     sret                ; return to caller
exec_coln: inc     ra                  ; move past colon
           lbr     execute             ; continue processing line

; *******************
; *** Process NEW ***
; *******************
ex_new:    ldi     0                   ; terminate program execution
           phi     rc
           plo     rc
           sep     r7                  ; set first byte of basic area to 0
           db      set_byte.0
           dw      basic
           db      0
           sep     scall               ; setup variable table
           dw      rst_vars
           lbr     exec_dn             ; finish up

; *******************
; *** Process OUT ***
; *******************
ex_out:    sep     scall               ; get first argument 
           dw      new_expr
           lbdf    err_ret             ; jump on error
           lda     ra                  ; get next token
           smi     08dh                ; must be a comma
           lbnz    syn_err             ; otherwise syntax error
           sep     r7                  ; retrieve value from stack
           db      ex_pop.0
           glo     rf                  ; save address
           ani     7                   ; mask for correct range
           lbz     val_err             ; jump if invalid value
           adi     60h                 ; convert to out instruction
           stxd
           sep     scall               ; now get value
           dw      new_expr
           lbdf    err_ret             ; jump on error
           sep     r7                  ; retrieve value
           db      ex_pop.0
           irx                         ; recover address
           ldx
           phi     rf
           ldi     0d3h                ; instruction to put reset P=3
           stxd
           glo     rf                  ; put value onto stack
           stxd
           ghi     rf                  ; get out instruction
           str     r2
           sep     r2                  ; execute instructions on stack
           dec     r2                  ; move stack back to correct address
           lbr     chk_term            ; check termination

; ********************
; *** Process PLOT ***
; ********************
ex_plot:   sep     scall               ; evaluate argument
           dw      new_expr
           lbdf    err_ret             ; jump if error occurred
           ldn     ra                  ; see if comma is specified
           smi     08dh
           lbnz    ex_plotdn           ; jump if not
           inc     ra                  ; move past comma
           sep     scall               ; evaluate second argument
           dw      expr
           lbdf    err_ret
           sep     r7                  ; point to buffer
           db      set_buf.0
           sep     r7                  ; add escape character
           db      add_char.0
           db      01bh
           sep     r7                  ; add escape character
           db      add_char.0
           db      '['                 
           sep     r7                  ; get top of expr stack in RD
           db      ex_pop_rd.0
           sep     scall               ; convert output
           dw      f_intout
           sep     r7                  ; now need a semicolon
           db      add_char.0
           db      ';'                 
           sep     r7                  ; get top of expr stack in RD
           db      ex_pop_rd.0
           sep     scall               ; convert output
           dw      f_intout
           sep     r7                  ; now need a semicolon
           db      add_char.0
           db      'H'
           sep     r7                  ; now need a semicolon
           db      add_char.0
           db      0
           sep     r7                  ; point to buffer
           db      set_buf.0
           sep     scall               ; send escape sequence
           dw      MSG
           ldn     ra                  ; get next character
           smi     08dh                ; is it a comma
           lbnz    chk_term            ; jump if not
           inc     ra                  ; move past comma
           sep     scall               ; get final argument
           dw      new_expr
           lbdf    err_ret
ex_plotdn: sep     r7                  ; retreive value
           db      ex_pop.0
           glo     rf                  ; get low value
           sep     scall               ; and display it
           dw      TYPE
           lbr     chk_term            ; done

; ********************
; *** Process POKE ***
; ********************
ex_poke:   sep     scall               ; get first argument 
           dw      new_expr
           lbdf    err_ret             ; jump on error
           lda     ra                  ; get next token
           smi     08dh                ; must be a comma
           lbnz    syn_err             ; otherwise syntax error
           sep     r7                  ; retrieve value from stack
           db      ex_pop.0
           glo     rf                  ; save address
           stxd
           ghi     rf
           stxd
           sep     scall               ; now get value
           dw      new_expr
           lbdf    err_ret             ; jump on error
           sep     r7                  ; retrieve value
           db      ex_pop.0
           irx                         ; recover address
           ldxa
           phi     rd
           ldx
           plo     rd
           glo     rf                  ; get byte from value
           str     rd                  ; and poke into memory
           lbr     chk_term            ; check termination

; *********************
; *** process PRINT ***
; *********************
ex_print:  ldn     ra                  ; get next symbol
           lbz     print_dn            ; jump if hit end
           smi     093h                ; colon is also valid terminator
           lbz     print_dn
           lda     ra
           plo     re                  ; keep a copy
           smi     08ch                ; check for semicolon
           lbz     print_sc            ; jump if so
           glo     re                  ; recover symbol
           smi     08dh                ; check for comma
           lbz     print_cm            ; jump if so
           glo     re                  ; recover symbol
#if LEVEL==1
           smi     TKN_QSTR            ; check for quoted string
           lbz     print_qs            ; jump if so
           dec     ra                  ; back to beginning of expr
           sep     scall               ; call expression evaluatore
           dw      new_expr
           lbdf    syn_err             ; jump on syntax error
#else
           dec     ra                  ; point to beginning of expression
           sep     scall               ; evaluate it
           dw      new_mexpr
           lbdf    err_ret             ; jump if error occurred
           smi     2                   ; was result an integer
           lbz     prt_int             ; jump if so
           sep     r7                  ; retrieve string address
           db      ex_pop.0
           sep     scall               ; deallocate temporary storage
           dw      dealloc
print_qs:  lda     rf                  ; get next symbol
           xri     0ffh                ; see if terminator found
           lbz     ex_print            ; jump if so
           xri     0ffh                ; restore character
           sep     scall               ; display the character
           dw      TYPE
           lbr     print_qs            ; loop back until done
#endif
prt_int:   sep     r7                  ; retrieve final value
           db      ex_pop.0
           sep     r7                  ; move to rd
           db      rf_rd.0
           sep     r7                  ; setup a buffer
           db      set_buf.0
           sep     scall               ; and convert number
           dw      f_intout
           ldi     0                   ; place terminator
           str     rf
           sep     r7                  ; setup a buffer
           db      set_buf.0
           sep     scall               ; print value
           dw      MSG
           lbr     ex_print            ; and look for other things to print
#if LEVEL==1
print_qs:  lda     ra                  ; get value
           xri     0ffh                ; see if done
           lbz     ex_print            ; see if more to print
           xri     0ffh                ; restore value
           sep     scall               ; print it
           dw      TYPE
           lbr     print_qs            ; loop back until done
#endif
print_sc:  ldn     ra                  ; get next symbol
           lbz     print_ncr           ; jump if no cr needed
           smi     093h                ; colon is also valid for end
           lbnz    ex_print            ; continue printing
print_ncr: lbr     chk_term
print_cm:  ldi     9                   ; need to output a tab
           sep     scall               ; send to terminal 
           dw      TYPE
           lbr     print_sc            ; then process like semicolon
print_dn:  sep     scall               ; print a cr/lf
           dw      INMSG
           db      10,13,0
           lbr     chk_term            ; and continue processing line

; **********************
; *** Process RETURN ***
; **********************
ex_return: ldn     ra                  ; next token must be zero
           lbnz    syn_err             ; else syntax error
           glo     r8                  ; make sure gosub stack is not empty
           smi     gosub_st.0
           lbnz    ret_good            ; jump if good
           ghi     r8                  ; check high byte as well
           smi     gosub_st.1
           lbnz    ret_good
           smi     0                   ; signal an error
           ldi     ERR_INVRET
           sep     sret                ; and return to caller
ret_good:  dec     r8                  ; retrieve current token pointer
           ldn     r8
           plo     ra
           dec     r8
           ldn     r8
           phi     ra
           dec     r8                  ; retrieve current line pointer
           ldn     r8
           plo     rc
           dec     r8
           ldn     r8
           phi     rc
           lbr     chk_term            ; and continue

; *******************
; *** Process RUN ***
; *******************
ex_run:    ldi     high basic          ; point to first program line
           phi     rc                  ; placei into rc and ra
           phi     ra
           ldi     low basic
           plo     rc
           plo     ra
           ldi     high gosub_st       ; setup gosub stack
           phi     r8
           ldi     low gosub_st
           plo     r8
           sep     r7                  ; zero the input buffer
           db      set_byte.0
           dw      ibuffer
           db      0
           sep     r7                  ; setup input buffer pointer
           db      set_word.0
           dw      inp_pos
           dw      ibuffer
#if LEVEL>=2
           sep     scall               ; setup variable table
           dw      rst_vars
           sep     r7                  ; need to setup FOR stack
           db      set_word.0
           dw      for_pos
           dw      for_st
           sep     r7                  ; need to setup DATA pointers
           db      set_word.0
           dw      data_lin
           dw      basic
           sep     r7                  ; point rf to beginning of basic
           db      set_rf.0
           dw      basic
           inc     rf                  ; move to first token
           inc     rf
           inc     rf
           ldn     rf                  ; and retrieve it
           smi     CMD_START           ; subtract command offset
           smi     96h                 ; check for DATA
           lbnz    nodata
           inc     rf                  ; otherwise point to first data item
           ldi     high data_pos       ; setup data position
           phi     rd
           ldi     low data_pos
           plo     rd
           ghi     rf                  ; and write pointer
           str     rd
           inc     rd
           glo     rf
           str     rd
           lbr     yesdata             ; and skip looking for DATA
nodata:    sep     scall               ; find next data statement
           dw      find_data
#endif
yesdata:   lbr     exec_tst            ; start program execution

; ******************************************************************************
; ***                           End of L1 statements                         ***
; ******************************************************************************

; ************************
; *** Exit from basic  ***
; ************************
#ifdef ELF2K
#ifndef ELFOS
ex_bye:    lbr     8003h               ; return to monitor
#endif
#endif

#ifndef ELF2K
#ifndef ELFOS
ex_bye:    lbr     0f900h              ; return to monitor
#endif
#endif

#ifdef ELFOS
; ******************************************************************************
; ***                         Start of Disk statements                       ***
; ******************************************************************************
; ************************
; *** REturn to Elf/OS ***
; ************************
ex_bye:    lbr     o_wrmboot           ; return to OS

setup_fl:  sep     r7                  ; point to buffer to hold filename
           db      set_buf.0
save_lp1:  lda     ra                  ; get next character
           xri     0ffh                ; see if end of string
           lbz     save_go             ; jump if so
           xri     0ffh                ; otherwise restore character
           str     rf                  ; and store into filename buffer
           inc     rf
           lbr     save_lp1            ; loop until full filename is copied
save_go:   ldi     0                   ; terminate filename
           str     rf
           ldi     high fildes         ; point to file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     high dta            ; point to dta
           phi     rf
           ldi     low dta
           plo     rf
           inc     rd                  ; point to dta entry in fildes
           inc     rd
           inc     rd
           inc     rd
           ghi     rf                  ; write DTA address
           str     rd
           inc     rd
           glo     rf
           str     rd
           dec     rd                  ; move descriptor address back
           dec     rd
           dec     rd
           dec     rd
           dec     rd
           sep     r7                  ; point rf back to filename
           db      set_buf.0
           sep     sret                ; return to caller

; ********************
; *** Process SAVE ***
; ********************
ex_save:   lda     ra                  ; get next token
           smi     TKN_QSTR            ; must be quoted string
           lbnz    syn_err             ; else syntax error
           sep     scall               ; setup filename and descriptor
           dw      setup_fl

           glo     r7                  ; save R7
           stxd
           ldi     3                   ; set create/truncate flags
           plo     r7
           sep     scall               ; attempt to open the file
           dw      o_open
           irx                         ; recover r7
           ldx
           plo     r7
           lbnf    s_opened            ; jump if file opened
dsk_err:   ldi     ERR_FILE            ; indicate file error
           smi     0                   ; and error condition
           sep     sret                ; and return to caller
s_opened:  ldi     high basic          ; point to basic space
           phi     rf
           ldi     low basic
           plo     rf
           sep     scall               ; get size of block
           dw      size_end
           sep     scall               ; write block to disk
           dw      o_write
           lbdf    dsk_err             ; jump if disk error occurred
           sep     scall               ; close the file
           dw      o_close
           ldi     0                   ; signal end
           plo     rc
           phi     rc
           lbr     exec_dn             ; finish up

; ********************
; *** Process LOAD ***
; ********************
ex_load:   lda     ra                  ; get next token
           smi     TKN_QSTR            ; must be quoted string
           lbnz    syn_err             ; else syntax error
           sep     scall               ; setup filename and descriptor
           dw      setup_fl

           glo     r7                  ; save R7
           stxd
           ldi     0                   ; set no flags
           plo     r7
           sep     scall               ; attempt to open the file
           dw      o_open
           irx                         ; recover r7
           ldx
           plo     r7
           lbdf    dsk_err
           ldi     high basic          ; point to basic space
           phi     rf
           ldi     low basic
           plo     rf
           ldi     07fh                ; just try to read max
           phi     rc
           ldi     0ffh
           plo     rc
           sep     scall               ; write block to disk
           dw      o_read
           lbdf    dsk_err             ; jump if disk error occurred
           sep     scall               ; close the file
           dw      o_close
           sep     scall               ; setup variable table
           dw      rst_vars
           ldi     0                   ; signal end
           plo     rc
           phi     rc
           lbr     exec_dn             ; finish up
; ******************************************************************************
; ***                           End of Disk statements                       ***
; ******************************************************************************
#endif

#if LEVEL>=2
; ******************************************************************************
; ***                         Start of L2 statements                         ***
; ******************************************************************************
; *********************
; *** Process CLEAR ***
; *********************
ex_clear:  sep     scall              ; reset variables nad heap
           dw      rst_vars
           lbr     chk_term           ; finished

; *******************
; *** Process FOR ***
; *******************
ex_for:    ldn     ra                  ; get next token
           sep     scall               ; it must be alpha (variable)
           dw      f_isalpha
           lbnf    syn_err             ; otherwise syntax error
           sep     scall               ; get variable address
           dw      get_var
           lbdf    err_ret
           ldi     high for_pos        ; get current pointer
           phi     rd
           ldi     low for_pos
           plo     rd
           lda     rd
           phi     rb
           lda     rd
           plo     rb
for_lp:    glo     rb                  ; make sure it is not empty
           xri     for_st.0
           plo     re                  ; save first result
           ghi     rb
           xri     for_st.1
           str     r2                  ; or with first result
           glo     re
           or
           lbz     for_new             ; jump if end of for stack

           inc     rb                  ; point to var address msb
           sex     rb                  ; use this as data pointer
           ghi     rf                  ; compare against IF variable address
           xor
           plo     re                  ; keep temporary value
           inc     rb                  ; move to lsb
           glo     rf
           xor                         ; and compare
           sex     r2                  ; point x back to stack
           str     r2                  ; put temp value here
           glo     re                  ; get high temp value
           or                          ; and combine with first value
           dec     rb                  ; move to beginning of entry
           dec     rb                  ; back to free spot
           lbnz    for_nxt             ; jump if entry was not a match
           glo     rb                  ; clear entry and reuse
           adi     10
           plo     rb
           ghi     rb
           adci    0
           phi     rb
           lbr     for_go
for_nxt:   glo     rb                  ; move to next entry
           adi     10
           plo     rb
           ghi     rb
           adci    0
           phi     rb
           lbr     for_lp


for_new:   ldi     high for_pos        ; get current pointer
           phi     rd
           ldi     low for_pos
           plo     rd
           lda     rd
           phi     rb
           lda     rd
           plo     rb
for_go:    sex     rb                  ; point X to for stack
           glo     rc                  ; put RC onto stack
           stxd
           ghi     rc
           stxd
           sex     r2                  ; point X back to stack
           lda     ra                  ; get next token
           smi     086h                ; must be =
           lbnz    syn_err             ; otherwise error
           glo     rf                  ; save variable address for now
           stxd
           ghi     rf
           stxd
           glo     rb                  ; save rb
           stxd
           ghi     rb
           stxd
           sep     scall               ; get start value
           dw      new_expr
           irx                         ; recover rb
           ldxa
           phi     rb
           ldx
           plo     rb
           lbdf    err_ret             ; jump if error 
           sep     r7                  ; get value
           db      ex_pop.0
           irx                         ; recover variable address
           ldxa
           phi     rd
           ldx
           plo     rd
           dec     r2                  ; keep variable address on stack
           dec     r2
           ghi     rf                  ; write start into variable
           str     rd
           inc     rd
           glo     rf
           str     rd
           lda     ra                  ; get next token
           smi     CMD_START           ; offset for commands
           smi     092h                ; must be TO
           lbnz    syn_err             ; else syntax error
           glo     rb                  ; save rb
           stxd
           ghi     rb
           stxd
           sep     scall               ; evaluate ending value
           dw      new_expr
           plo     re
           irx                         ; recover rb
           ldxa
           phi     rb
           ldx
           plo     rb
           glo     re
           lbdf    err_ret             ; jump on error
           ldi     1                   ; default step is 1
           plo     rf
           ldi     0
           phi     rf
           sep     r7                  ; put step onto stack
           db      ex_push.0
           ldn     ra                  ; need to check for STEP
           smi     CMD_START           ; offset for commands
           smi     094h                ; check for STEP
           lbnz    no_step             ; jump if not
           sep     r7                  ; drop default step from stack
           db      ex_pop.0
           glo     rb                  ; save rb
           stxd
           ghi     rb
           stxd
           inc     ra                  ; move past STEP token
           sep     scall               ; evaluate step
           dw      expr
           plo     re
           irx                         ; recover rb
           ldxa
           phi     rb
           ldx
           plo     rb
           glo     re
           lbdf    err_ret             ; jump on error

no_step:   sep     r7                  ; retrieve end value
           db      ex_pop.0
           sep     r7                  ; transfer to rd
           db      rf_rd.0
           sep     r7                  ; retrieve end value
           db      ex_pop.0
           sex     rb                  ; write RA onto stack
           glo     ra
           stxd
           ghi     ra
           stxd
           glo     rf                  ; now end value
           stxd
           ghi     rf
           stxd
           glo     rd                  ; now step
           stxd
           ghi     rd
           stxd
           sex     r2                  ; need to retrieve variable address
           irx
           ldxa
           phi     rf
           ldx
           plo     rf
           sex     rb                  ; need to write to for stack
           glo     rf
           stxd
           ghi     rf
           stxd
           sex     r2                  ; point X back to proper stack
           ldi     high for_pos        ; need to write new forstack value
           phi     rf
           ldi     low for_pos
           plo     rf
           ghi     rb
           str     rf
           inc     rf
           glo     rb
           str     rf
           lbr     chk_term            ; done processing

; ********************
; *** Process NEXT ***
; ********************
ex_next:   ldn     ra                  ; need to see if a variable is specified
           lbz     next_nv             ; jump for no variable version
           smi     093h                ; colon is also valid
           lbz     next_nv
           ldn     ra                  ; recover token
           sep     scall               ; must now be a variable
           dw      f_isalpha
           lbnf    syn_err             ; else syntax error
           sep     scall               ; get address for specified variable
           dw      get_var
           lbdf    err_ret
           sep     r7                  ; get FOR stack into RB
           db      get_rb.0
           dw      for_pos

next_lp:   glo     rb                  ; make sure it is not empty
           xri     for_st.0
           plo     re                  ; save first result
           ghi     rb
           xri     for_st.1
           str     r2                  ; or with first result
           glo     re
           or
           lbz     next_nf             ; jump if next without for
           sex     rb                  ; get inner loop variable
           irx
           ldxa
           phi     rd
           ldx
           plo     rd
           dec     rb                  ; move pointer back
           dec     rb
           sex     r2                  ; X back to stack
           glo     rf                  ; compare addresses
           str     r2
           glo     rd
           xor
           plo     re                  ; keep result
           ghi     rf
           str     r2
           ghi     rd
           xor
           str     r2                  ; or with first result
           glo     re
           or
           lbz     next_nv             ; match, so continue
           glo     rb                  ; need to drop loop
           adi     10
           plo     rb
           ghi     rb
           adci    0
           phi     rb
           ghi     re                  ; save baud constant
           str     r2
           ldi     high for_pos        ; need to write new pointer
           phi     re
           ldi     low for_pos
           plo     re
           ghi     rb
           str     re
           inc     re
           glo     rb
           str     re
           ldx                         ; recover baud constant
           phi     re
           lbr     next_lp             ; see if next loop is correct
next_nv:   sep     r7                  ; get FOR stack into RB
           db      get_rb.0
           dw      for_pos
           glo     rb                  ; make sure it is not empty
           xri     for_st.0
           plo     re                  ; save first result
           ghi     rb
           xri     for_st.1
           str     r2                  ; or with first result
           glo     re
           or
           lbz     next_nf             ; jump if next without for
           sex     rb                  ; use RB for the stack
           irx                         ; recover variable address
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa                        ; retrieve step
           phi     rd
           plo     re                  ; keep copy of high byte of step
           ldxa
           plo     rd
           sex     rf                  ; now poiht X to variable
           irx                         ; sb
           glo     rd                  ; add in step to variable value
           add
           stxd                        ; store back into variable
           plo     rd                  ; and keep in rd
           ghi     rd                  ; now high byte
           adc
           str     rf                  ; place back into variable
           phi     rd
           sex     rb                  ; now point at end value
           irx                         ; lsb
           glo     re                  ; get sign of step
           shl                         ; shift into df
           lbnf    next_p              ; jump if positive
           glo     rd                  ; do RD-end
           sm
           dec     rb
           ghi     rd
           sdb
           lbdf    next_ne             ; jump if not at end
           lbr     next_ok
next_p:    glo     rd                  ; do end-RD
           sd
           dec     rb                  ; point to msb
           ghi     rd
           sdb
           lbdf    next_ne             ; jump if not at end
next_ok:   irx                         ; lsb of end
           irx                         ; msb or ra
           irx                         ; lsb of ra
           irx                         ; msb of rc
           irx                         ; lsb of rc, item is now off the stack
           sex     r2                  ; put X back on proper stack
           ldi     high for_pos        ; need to write new forstack value
           phi     rf
           ldi     low for_pos
           plo     rf
           ghi     rb
           str     rf
           inc     rf
           glo     rb
           str     rf
           lbr     chk_term            ; done processing
next_ne:   irx                         ; lsb of end
           irx                         ; msb of ra
           ldxa                        ; retrieve token pointer
           phi     ra
           ldxa
           plo     ra
           ldxa                        ; retrieve current line
           phi     rc
           ldx
           plo     rc
           lbr     chk_term            ; continue
next_nf:   ldi     ERR_NOFOR
           smi     0                   ; signal an error
           sep     sret                ; and return

; ***********************
; *** Process ON GOTO ***
; ***********************
ex_on:     sep     scall               ; get first argument
           dw      new_expr
           lbdf    err_ret             ; jump if error occurred
           lda     ra                  ; get next token
           smi     CMD_START           ; offset for commands
           smi     83h                 ; look for GOTO
           lbz     on_goto             ; jump if so
           lbr     syn_err             ; otherwise syntax error
on_goto:   sep     r7                  ; retrieve value
           db      ex_pop.0
           glo     rf                  ; get low byte
on_gotolp: stxd                        ; and preserve
           ldn     ra                  ; see if hit terminator
           lbz     chk_term            ; jump if so
           smi     093h                ; colon is also valid
           lbz     chk_term
           sep     scall               ; evaluate line number
           dw      new_expr
           lbdf    err_ret             ; jump if error occurred
           irx                         ; recover ON expression
           ldx
           smi     1                   ; subtract 1
           lbz     goto_go2            ; jump if correct entry is found
           plo     re                  ; save count
           ldn     ra                  ; check next token
           lbz     chk_term            ; jump if terminator
           smi     093h                ; or colon
           lbz     chk_term
           lda     ra                  ; now must be a comma
           smi     8dh
           lbnz    syn_err             ; jump if not
           glo     re                  ; recover count
           lbr     on_gotolp           ; and keep lookin

; **********************
; *** Process RANDOM ***
; **********************
ex_random: sep     scall              ; get input from user
           dw      get_input
           lbdf    err_ret
           ldi     high lfsr          ; point to lfsr register
           phi     rf
           ldi     low lfsr
           plo     rf
           ldi     0
           str     rf
           inc     rf
           ldi     1
           str     rf
           inc     rf
           ghi     rd                 ; write new seed to it
           str     rf
           inc     rf
           glo     rd
           str     rf
           lbr     chk_term           ; done


; ********************
; *** Process READ ***
; ********************
ex_read:   ldn     ra                  ; get next token
read_lp:   ldn     ra                  ; see if done
           lbz     chk_term            ; jump if so
           ldn     ra                  ; get character
           sep     scall               ; must be a variable name
           dw      f_isalpha
           lbnf    syn_err             ; otherwise error
           sep     scall               ; get variable address
           dw      get_var
           lbdf    err_ret
           glo     rf                  ; save variable position
           stxd
           ghi     rf
           stxd
           sep     scall               ; get input
           dw      get_data
           lbdf    err_ret             ; jump on error
           irx                         ; recover variable address
           ldxa
           phi     rf
           ldx
           plo     rf
           ghi     rd                  ; store into variable
           str     rf
           inc     rf
           glo     rd
           str     rf
           ldn     ra                  ; get next token
           lbz     chk_term            ; jump if terminator
           smi     093h                ; colon also ends input
           lbz     chk_term
           lda     ra                  ; get next token
           smi     08dh                ; must be a comma
           lbz     read_lp             ; process next variable
           lbr     syn_err             ; otherwise error

; ***********************
; *** Process RESTORE ***
; ***********************
ex_restore: ldn    ra                  ; see if there is an argument
           lbz     rst_strt            ; jump if not
           smi     093h                ; colon is also valid
           lbz     rst_strt
           sep     scall               ; otherwise evaluate argument
           dw      new_expr
           lbdf    err_ret             ; jump if error occurrecd
           glo     rc                  ; save rc
           stxd
           ghi     rc
           stxd
           sep     r7                  ; retrieve line number
           db      ex_pop.0
           sep     r7                  ; transfer to rd
           db      rf_rd.0
           sep     r7                  ; then find line number
           db      find_ln.0
           ghi     rc                  ; move to rd
           phi     rd
           glo     rc
           plo     rd
           irx                         ; retrieve original rc
           ldxa
           phi     rc
           ldx
           plo     rc
           lbnf    err_noln            ; no line error
           ldi     high data_lin       ; point to pointer location
           phi     rf
           ldi     low data_lin
           plo     rf
           ghi     rd                  ; save pointer
           str     rf
           inc     rf
           glo     rd
           str     rf
           lbr     rest_cnt            ; ok, continue
rst_strt:  ldi     high data_lin       ; point to pointer location
           phi     rf
           ldi     low data_lin
           plo     rf
           ldi     high basic          ; restore to beginning of basic
           str     rf
           inc     rf
           ldi     low basic
           str     rf
rest_cnt:  dec     rf                  ; retrieve pointer
           lda     rf                  ; into rd
           phi     rd
           lda     rf
           plo     rd
           inc     rd                  ; move to first token
           inc     rd
           inc     rd
           ldn     rd                  ; and get it
           smi     CMD_START           ; subtract command offset
           smi     96h                 ; check for DATA
           lbnz    nodata2
           inc     rd                  ; otherwise point to first data item
           ldi     high data_pos       ; setup data position
           phi     rf
           ldi     low data_pos
           plo     rf
           ghi     rd                  ; and write pointer
           str     rf
           inc     rf
           glo     rd
           str     rf
           lbr     chk_term            ; done
nodata2:   sep     scall               ; find next data statement
           dw      find_data
           lbr     chk_term            ; done

; **************************************************
; *** See if an address is bound to a string var ***
; *** RF - Address to check                      ***
; *** Returns: DF=1 - address in use             ***
; **************************************************
chk_var:   glo     rf                  ; put address to check on the stack
           stxd
           ghi     rf
           stxd      
           ldi     high var_pos        ; need to get variable pointer
           phi     rf
           ldi     low var_pos
           plo     rf
           lda     rf                  ; retrieve the pointer into RF
           plo     re
           ldn     rf
           plo     rf
           glo     re
           phi     rf
chk_varlp: ldn     rf                  ; get byte
           lbz     chk_no              ; jump if at end of table
           str     r2                  ; add to address
           glo     rf
           add
           plo     rf
           ghi     rf
           adci    0
           phi     rf
           dec     rf                  ; move to type
           dec     rf
           dec     rf
           lda     rf                  ; get type
           smi     3                   ; is it a string var
           lbnz    chk_nst             ; jump if not a string
           irx                         ; move to low value of address
           lda     rf                  ; get byte from variable address
           sm                          ; compare the values
           irx                         ; point to high byte of value
           lbnz    chk_n1              ; jump if no match
           ldn     rf                  ; get low byte
           sm                          ; and compare it
           lbnz    chk_n1              ; jump if no match
           dec     r2                  ; move stack pointer back
           dec     r2
           smi     0                   ; signal variable in use
           lbr     chk_dn              ; finished
chk_n1:    dec     r2                  ; move stack pointer back
           dec     r2
           inc     rf                  ; move to next variable
           lbr     chk_varlp           ; and check it
chk_nst:   inc     rf                  ; move to next variable
           inc     rf
           lbr     chk_varlp
chk_no:    adi     0                   ; signal not in use
chk_dn:    irx                         ; recover address
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; and return

; ******************************************************
; *** Deallocate a string variables prior assignment ***
; *** RD - pointer to string variable address field  ***
; ******************************************************
de_str:    dec     rf                  ; get variable type
           lda     rf                  ; and get it
           smi     3                   ; is it a string 
           lbnz    return              ; jump if not
           glo     rf                  ; save address
           stxd
           ghi     rf
           stxd
           ldn     rf                  ; get variable binding
           plo     re
           ldi     0                   ; delete binding
           str     rf
           inc     rf
           ldn     rf
           plo     rf                  ; into rf
           glo     re
           phi     rf
           sep     scall               ; dealloate current binding
           dw      dealloc
           irx                         ; recover address
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; and return

; **************************************
; *** Consolidate heap memory blocks ***
; **************************************
consol:    glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           ldi    high heap            ; need to see if below heap
           phi    rf
           ldi    low heap
           plo    rf
           lda    rf                   ; retrieve the pointer
           plo    re
           ldn    rf
           plo    rf
           glo    re
           phi    rf
cons_lp:   ldn    rf                   ; get flag byte
           lbz    cons_z               ; jump if free block
           xri    0ffh                 ; see if end of heap
           lbz    cons_dn              ; jump if so
cons_nxt:  sep    r7                   ; copy rf to rd
           db     rf_rd.0
           inc    rd                   ; point to lsb of size
           inc    rd
           sex    rd                   ; use this as data pointer
           glo    rf                   ; and add to rf
           add
           plo    rf
           dec    rd
           ghi    rf
           adc
           phi    rf
           sex    r2                   ; put stack back
           lbr    cons_lp              ; loop until done
cons_dn:   irx                         ; recover consumed registers
           ldxa
           phi    rd
           ldxa
           plo    rd
           ldxa
           phi    rf
           ldx
           plo    rf
           sep    sret                 ; and return
cons_z:    sep    r7                   ; copy rf to rd
           db     rf_rd.0
           inc    rf                   ; point to lsb of block size
           inc    rf
           sex    rf                   ; use this as data pointer
           glo    rd                   ; add block size to address
           add
           plo    rd
           dec    rf
           ghi    rd
           adc
           phi    rd
           dec    rf                   ; rf back to flag byte
           sex    r2                   ; X back to stack
           ldn    rd                   ; get flag byte of next entry
           xri    0ffh                 ; check for end
           lbz    cons_dn              ; jump of at end
           xri    0ffh
           lbnz   cons_nxt             ; jump if not an empty block
           inc    rd                   ; move next entry pointer to lsb of size
           inc    rd
           inc    rf                   ; move curernt pointer to lsb
           inc    rf
           sex    rd                   ; use 2nd entry as data
           ldn    rf                   ; add sizes together
           add
           str    rf
           dec    rf                   ; move poitners to msb
           dec    rd
           ldn    rf
           adc
           str    rf
           sex    r2                   ; set x back to stack
           dec    rf                   ; move back to flag byte
           lbr    cons_lp              ; and keep looking
           
; *******************************
; *** Deallocate heap memory  ***
; *** RF - address to dealloc ***
; *******************************
dealloc:   sep    scall                ; see if variable uses address
           dw     chk_var
           lbdf   return               ; do not deallocate if variable is using
           glo    rd                   ; preserve RD
           stxd
           ghi    rd
           stxd
           ldi    high heap            ; need to see if below heap
           phi    rd
           ldi    low heap
           plo    rd
           inc    rd                   ; point to low byte
           sex    rd                   ; use rd as data pointer
           glo    rf                   ; subtract request address
           sm
           dec    rd                   ; point to msb
           ghi    rf
           smb
           sex    r2                   ; point X back to stack
           irx                         ; recover RD
           ldxa
           phi    rd
           ldx
           plo    rd
           lbnf   return               ; jump if address is not in heap
           dec    rf                   ; move to flag byte
           dec    rf
           dec    rf
           ldi    0                    ; mark as unused block
           str    rf
           inc    rf                   ; restore rf
           inc    rf
           inc    rf
           sep    scall                ; consolidate free blocks
           dw     consol
           sep    sret                 ; and return to caller

; ******************************************
; *** Check for heap/var table collision ***
; *** Returns: DF=1 out of memory        ***
; ******************************************
chk_om:    glo     rf                   ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     rd                   ; save consumed registers
           stxd
           ghi     rd
           stxd
           sep     scall                ; get end of variables
           dw      end_vars
           ldi     high heap            ; point to heap pointer
           phi     rd
           ldi     low heap
           plo     rd
           inc     rd                   ; point to lsb
           sex     rd                   ; point x to heap pointer
           glo     rf                   ; perform vars-heap
           sm
           dec     rd
           ghi     rf
           smb
           sex     r2                   ; point X back to stack
           lbnf    not_om               ; jump if no overlap
           smi     0                    ; signal memory error
           ldi     ERR_NOMEM
           lskp
not_om:    adi     0                    ; signal good
           plo     re                   ; save return value
           irx                          ; recover consumed registers
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf
           glo     re                  ; recover result code
           sep     sret                ; and return

; **********************************
; *** Allocate space on the heap ***
; *** RF - size to allocate      ***
; *** Returns: RF - address      ***
; ***          DF=1 - no memory  ***
; **********************************
alloc:     ldi     high heap           ; get heap pointer
           phi     rd
           ldi     low heap
           plo     rd
           lda     rd                  ; and retrieve it
           plo     re
           ldn     rd
           plo     rd
           glo     re
           phi     rd                  ; rd now has heap pointer
           inc     rf                  ; include header size in comparisons
           inc     rf
           inc     rf
alloc_lp1: ldn     rd                  ; get flag byte
           lbz     alloc_z             ; check empty block
           xri     0ffh                ; see if at end of memory
           lbz     alloc_e             ; jump if so

alloc_no:  inc     rd                  ; point to msb of size
           lda     rd                  ; retrieve it
           stxd                        ; place onto stack
           ldn     rd                  ; get lsb
           str     r2                  ; and place in memory
           dec     rd                  ; move rd back to flag byte
           dec     rd
           glo     rd                  ; and add offset
           add
           plo     rd
           irx                         ; point to next location
           ghi     rd
           adc
           phi     rd                  ; rd now has new offset
           lbr     alloc_lp1           ; check this entry
alloc_z:   inc     rd                  ; move to lsb of block size
           inc     rd
           sex     rd                  ; use size as data pointer
           glo     rf                  ; perform SIZEb - SIZEr
           sd
           str     r2                  ; save result
           dec     rd                  ; move to msb
           ghi     rf                  ; and continue subtraction
           sdb
           plo     re                  ; RE:[R2] has difference
           dec     rd                  ; rd now back at flag
           sex     r2                  ; X back to stack
           lbnf    alloc_no            ; jump if not enough space
           ldi     1                   ; allocate this block
           str     rd
           ldn     r2                  ; see if difference is greater than 5 bytes
           smi     5
           glo     re
           smbi    0
           lbnf    no_split            ; jump if block too small to split
           ghi     re                  ; save baud constant
           stxd
           inc     rd                  ; retrieve current block size
           lda     rd                  ; retreive current size
           phi     re
           ldn     rd
           plo     re                  ; re now has original block size
           glo     rf                  ; write new block size
           str     rd
           dec     rd
           ghi     rf
           str     rd                  ; rd is at msb of block size
           glo     re                  ; find size for next block
           str     r2
           glo     rf
           sd
           plo     re
           ghi     re
           str     r2
           ghi     rf
           sdb
           phi     re                  ; re now has size of next block
           dec     rd                  ; move rd back to flags byte
           glo     rd                  ; save this address
           stxd
           ghi     rd
           stxd
           glo     rf                  ; add in block size
           str     r2
           glo     rd
           add
           plo     rd
           ghi     rf
           str     r2
           ghi     rd
           adc
           phi     rd
           ldi     0                   ; signal an empty block
           str     rd
           inc     rd
           ghi     re                  ; write block size
           str     rd
           inc     rd
           glo     re
           str     rd
           irx                         ; recover entry address
           ldxa
           phi     rf                  ; into rf
           ldxa
           plo     rf
           ldx                         ; also recover baud constant
           phi     re
           inc     rf                  ; move to first free memory address
           inc     rf
           inc     rf
           adi     0                   ; signal no error
           sep     sret                ; and return

no_split:  inc     rd                  ; move to first spot in memory
           inc     rd
           inc     rd
           ghi     rd                  ; and transfer to RF
           phi     rf
           glo     rd
           plo     rf
           adi     0                   ; signal success
           sep     sret                ; and return

alloc_e:   dec     rf                  ; rf back to its original value
           dec     rf
           dec     rf
           ldi     high heap           ; get heap pointer
           phi     rd
           ldi     low heap
           plo     rd
           lda     rd                  ; and retrieve it
           plo     re
           glo     rf                  ; subtract size from pointer
           str     r2
           ldn     rd
           sm
           plo     rd
           ghi     rf                  ; now high byte
           str     r2
           glo     re
           smb
           phi     rd
           dec     rd                  ; decrement 3 for flag and offset
           dec     rd
           dec     rd                  ; now pointing at new block
           ghi     re                  ; save baud constant
           str     r2
           ldi     high heap           ; need to save new heap pointer
           phi     re
           ldi     low heap
           plo     re
           ghi     rd                  ; write pointer
           str     re
           inc     re
           glo     rd
           str     re
           ldn     r2                  ; recover re
           phi     re

           sep     scall               ; check if memory error
           dw      chk_om
           lbdf    err_ret             ; jump if error
           inc     rf                  ; change request size to add header
           inc     rf
           inc     rf
           ldi     1                   ; set block as used
           str     rd
           inc     rd
           ghi     rf                  ; store size
           str     rd
           inc     rd
           glo     rf
           str     rd
           inc     rd                  ; move pointer to fisrt of memory block
           glo     rd                  ; and transfer to rf
           plo     rf
           ghi     rd
           phi     rf
           adi     0                   ; signal success
           sep     sret                ; and return
           
           
; *******************
; *** Process DIM ***
; *******************
ex_dim:    ldn     ra                  ; see if terminator
           lbz     chk_term            ; jump if so
           smi     093h                ; colon is also valid
           lbz     chk_term            ; end on colon as well
           ldn     ra                  ; check for valid variable name
           sep     scall
           dw      f_isalpha
           lbnf    syn_err             ; jump if not possible variable
           sep     scall               ; get end of variable table
           dw      end_vars
           sep     r7                  ; copy rf to rd
           db      rf_rd.0
           inc     rf                  ; point to name field
dim_lp1:   lda     ra                  ; get byte from input stream
           sep     scall               ; see if valid for variable names
           dw      f_isalnum
           lbnf    dim_2               ; jump if not
           str     rf                  ; store into variable entry
           inc     rf
           lbr     dim_lp1             ; loop until end of name found
dim_2:     dec     ra                  ; need to reget last char
           lda     ra
           xri     84h                 ; must be a (
           lbnz    syn_err             ; else syntax error
           xri     84h                 ; put it back
           str     rf                  ; and store into output buffer
           inc     rf
           ldi     12h                 ; indicator for integer array
           str     rf
           inc     rf
           glo     rd                  ; can now compute size
           str     r2
           glo     rf
           sm
           adi     2                   ; add in 3 bytes for address and size
           str     rd                  ; store into size
           glo     rf                  ; save address for later
           stxd
           ghi     rf
           stxd
           sep     scall               ; process first argument
           dw      new_expr
           lbdf    ret_2               ; jump if error occurred
           sep     r7                  ; need to add 1
           db      ex_pop.0
           inc     rf
           sep     r7
           db      ex_push
           ldi     1                   ; indicate 1 dimension
           stxd
dim_args:  ldn     ra                  ; need to check next token
           smi     08dh                ; is it a comma
           lbnz    single
           inc     ra                  ; move past comma
           sep     scall               ; evaluate second argument
           dw      expr
           lbdf    ret_2               ; jump if error occurred
           sep     r7                  ; need to add 1
           db      ex_pop.0
           inc     rf
           sep     r7
           db      ex_push
           irx                         ; get argument count
           ldx
           adi     1
           stxd                        ; and keep on stack
           lbr     dim_args            ; loop for possible other dimensions
single:    ghi     r9                  ; set rb=r9
           phi     rb
           glo     r9
           plo     rb
           irx                         ; recover dimension count
           ldx
           dec     r2                  ; and keep on stack
           inc     rb                  ; point rb to first argument
           plo     re                  ; put count into re
copylp1:   lda     rb                  ; get argument
           phi     rf
           lda     rb
           plo     rf
           sep     r7                  ; make copy on top of expression stack
           db      ex_push.0
           dec     re                  ; see if done
           glo     re                  ; get count
           lbnz    copylp1             ; jump if not doen
           irx                         ; get dimension count
           ldx
           stxd                        ; keep on stack twice
           stxd
mullp:     irx                         ; get count
           ldx
           smi     1                   ; minus 1
           lbz     muldn               ; jump if no more multiplies needed
           stxd                        ; put count back on stack
           sep     scall               ; and multiply top 2 elements
           dw      ex_mul
           lbr     mullp               ; jump back and see if done
muldn:     lda     ra                  ; get next token
           smi     085h                ; must be a )
           lbnz    ret_2               ; else syntax error
           sep     r7                  ; get dimension
           db      ex_pop.0
           glo     rf                  ; 2 bytes per entry
           shl
           plo     rf
           ghi     rf
           shlc
           phi     rf
           inc     rf                  ; also space for size and dimensions
           irx                         ; get number of dimensions
           ldx
           dec     r2                  ; and keep on stack
mullp2:    inc     rf
           inc     rf
           smi     1                   ; subtract 1 from count
           lbnz    mullp2              ; loop back if need more space
           sep     scall               ; allocate the memory
           dw      alloc
           lbdf    om_error            ; jump if could not allocate the memory
           irx                         ; retrieve address
           ldxa                        ; first is the dimension count
           plo     rb                  ; set it aside for now
           ldxa
           phi     rd
           ldx
           plo     rd
           ghi     rf                  ; write address into variable record
           str     rd
           inc     rd
           glo     rf
           str     rd
           inc     rd
           ldi     0                   ; werite terminating zero
           str     rd
           glo     rb                  ; get dimension count
           str     rf
           inc     rf
           plo     re                  ; and place into re
           sep     r7                  ; move rf to rd
           db      rf_rd.0
           ghi     r9                  ; set rb=r9
           phi     rb
           glo     r9
           plo     rb
           inc     rb
           glo     re                  ; get dimenstion count
dim_lp4:   inc     rd                  ; move pointer
           inc     rd
           smi     1                   ; subtract from count
           lbnz    dim_lp4             ; loop until done
dim_lp3:   lda     rb
           str     rd
           dec     rd
           lda     rb
           str     rd
           dec     rd
           dec     re                  ; see if done with dimensions
           glo     re
           lbnz    dim_lp3             ; loop back if not

           ldn     ra                  ; check ending
           lbz     chk_term            ; done if terminator found
           smi     093h                ; colon is also valid
           lbz     chk_term            ; end on colon as well
           lda     ra                  ; otherwise must be a comma
           smi     8dh
           lbnz    syn_err
           lbr     ex_dim              ; loop for more 


om_error:  ldi     ERR_NOMEM           ; indicate out of memory
           smi     0
ret_2:     irx                         ; remove rf from stack
           irx
           sep     sret                ; and return

; ******************************************************************************
; ***                           End of L2 statements                         ***
; ******************************************************************************
#endif

; ******************************************
; *** Now for the BASIC execution engine ***
; *** RA - address of tokens to execute  ***
; *** RC - current line number           ***
; *** Returns: DF=0 - success            ***
; ***          DF=1 - Error              ***
; ***             D - Error code         ***
; ******************************************
execute:   bn4     exec_1              ; jump if EF4 not asserted
           ldi     ERR_BREAK           ; otherwise breat
           smi     0
           sep     sret
exec_1:    ldn     ra                  ; get token
           lbz     exec_dn             ; jump if at end of statement
           smi     TKN_QSTR            ; quoted strings  cannot be first command
           lbz     syn_err             ; syntax error
           smi     1                   ; neither can numbers
           lbz     syn_err
           ldn     ra                  ; get token again
           sep     scall               ; see if possible variable
           dw      f_isalpha
           lbdf    ex_let              ; if so, treat as LET
           ani     080h                ; see if token or unquoted string
           lbz     syn_err             ; for now, unqoted strings are erros
           lda     ra                  ; get token
           ani     07fh                ; strip token bit
           smi     CMD_START           ; check for PRINT
           lbnf    syn_err             ; jump if function instead of statement
           plo     rf
           sep     r7                  ; execute command
           db      do_cmd.0

           lbr     syn_err             ; failed to find command

exec_dn:   glo     rc                  ; see if we were in run mode
           str     r2
           ghi     rc
           or
           lbz     good_ret            ; if not, then good return
exec_run:  sep     r7                  ; need to get next line
           db      next_ln.0
           ghi     rf                  ; setup addresses
           phi     rc
           phi     ra
           glo     rf
           plo     rc
           plo     ra
exec_tst:  ldn     ra                  ; see if at end of program
           lbnz    exec_go             ; execute new line if not
good_ret:  adi     0                   ; signal no errors
           sep     sret                ; and return
exec_go:   inc     ra                  ; move past size and line number
           inc     ra
           inc     ra
           lbr     execute             ; and execute new line

syn_err:   ldi     ERR_SYN             ; signal syntax error
           lskp
val_err:   ldi     ERR_VAL             ; signal syntax error
err_ret:   smi     0                   ; be sure error flag is set
           sep     sret                ; and return

; *****************************************
; *** Find size from RF to end of basic ***
; *** RF - start of line                ***
; *** Returns: RC - count of bytes      ***
; *****************************************
size_end:  glo     rf                  ; save RF
           stxd
           ghi     rf
           stxd
           ldi     0                   ; setup count
           plo     rc
           phi     rc
size_lp:   ldn     rf                  ; see if at end
           lbz     size_dn             ; jump if end found
           sex     rf
           glo     rc                  ; add count to total
           add
           plo     rc
           ghi     rc                  ; propagate carry
           adci    0
           phi     rc
           glo     rf                  ; add count into line position
           add
           plo     rf                  ; and set as new line position
           ghi     rf                  ; propagate carry
           adci    0
           phi     rf
           sex     r2
           lbr     size_lp             ; keep looping until end
size_dn:   irx                         ; recover RF
           ldxa
           phi     rf
           ldx
           plo     rf
           inc     rc                  ; add in program terminator
           sep     sret                ; and return to caller

#ifdef ELFOS
o_inmsg:   lda     r6                  ; load byte from message
           lbz     return              ; return if done
           sep     scall               ; display byte
           dw      TYPE
           lbr     o_inmsg
#endif

#ifndef ELFOS
begin2:    ldi     high stack          ; restart address here
           phi     r2
           ldi     low stack
           plo     r2
           ldi     high restart        ; setup for start
           phi     r6
           ldi     low restart
           plo     r6
           sex     r2                  ; point X to stack
           lbr     f_initcall          ; setup SCALL and SRET
begin:     ldi     high stack          ; setup stack
           phi     r2
           ldi     low stack
           plo     r2
           ldi     high start          ; setup for start
           phi     r6
           ldi     low start
           plo     r6
           sex     r2                  ; point X to stack
           lbr     f_initcall          ; setup SCALL and SRET
#endif

functable: db      ('+'+80h)           ; 0
           db      ('-'+80h)           ; 1
           db      ('*'+80h)           ; 2
           db      ('/'+80h)           ; 3
           db      ('('+80h)           ; 4
           db      (')'+80h)           ; 5
           db      ('='+80h)           ; 6
           db      '<',('='+80h)       ; 7
           db      '>',('='+80h)       ; 8
           db      '<',('>'+80h)       ; 9
           db      ('<'+80h)           ; 10
           db      ('>'+80h)           ; 11
           db      (';'+80h)           ; 12
           db      (','+80h)           ; 13
           db      'AN',('D'+80h)      ; 14
           db      ('&'+80h)           ; 15
           db      'O',('R'+80h)       ; 16
           db      ('|'+80h)           ; 17
           db      ('^'+80h)           ; 18
           db      (':'+80h)           ; 19
           db      'PEEK',('('+80h)    ; 20
           db      'FRE',('('+80h)     ; 21
           db      'RND',('('+80h)     ; 22
           db      'INP',('('+80h)     ; 23
           db      'FLG',('('+80h)     ; 24

           db      'USR',('('+80h)      ; 25

           db      'PRIN',('T'+80h)    ; 0
           db      ('?'+80h)           ; 1
           db      'LE',('T'+80h)      ; 2
           db      'GOT',('O'+80h)     ; 3
           db      'I',('F'+80h)       ; 4
           db      'THE',('N'+80h)     ; 5
           db      'EN',('D'+80h)      ; 6
           db      'GOSU',('B'+80h)    ; 7
           db      'RETUR',('N'+80h)   ; 8
           db      'RE',('M'+80h)      ; 9
           db      'INPU',('T'+80h)    ; 10
           db      'POK',('E'+80h)     ; 11
           db      'OU',('T'+80h)      ; 12
           db      'PLO',('T'+80h)     ; 13
           db      'RU',('N'+80h)      ; 14
           db      'LIS',('T'+80h)     ; 15
           db      'NE',('W'+80h)      ; 16
#if LEVEL>=2
           db      'FO',('R'+80h)      ; 17
           db      'T',('O'+80h)       ; 18
           db      'NEX',('T'+80h)     ; 19
           db      'STE',('P'+80h)     ; 20
           db      'O',('N'+80h)       ; 21
           db      'DAT',('A'+80h)     ; 22
           db      'REA',('D'+80h)     ; 23
           db      'RESTOR',('E'+80h)  ; 24
           db      'DI',('M'+80h)      ; 25
           db      'RANDO',('M'+80h)   ; 26
           db      'VARPTR',('('+80h)  ; 27
           db      'CLEA',('R'+80h)    ; 28
           db      'LEN',('('+80h)     ; 29
           db      'ASC',('('+80h)     ; 30
           db      'VAL',('('+80h)     ; 31
           db      'STR$',('('+80h)    ; 32
           db      'CHR$',('('+80h)    ; 33
           db      'LEFT$',('('+80h)   ; 34
           db      'RIGHT$',('('+80h)  ; 35
           db      'MID$',('('+80h)    ; 36
#endif
           db      'BY',('E'+80h)      ; 43
#ifdef ELFOS
           db      'SAV',('E'+80h)     ; 44
           db      'LOA',('D'+80h)     ; 45
#if LEVEL>=3
           db      'OPE',('N'+80h)     ; 46
           db      'CLOS',('E'+80h)    ; 47
           db      'REA',('D'+80h)     ; 48
           db      'WRIT',('E'+80h)    ; 49
           db      'SEE',('K'+80h)     ; 50
#endif
#endif
           db      0
term:      db      0ffh
crlf:      db      10,13,0

endrom:    equ     $

#ifndef ELFOS
           org     100h
#endif

#if LEVEL==1
vars:      ds      52
#endif
#if LEVEL>=2
data_lin:  ds      2
data_pos:  ds      2
var_pos:   ds      2
heap:      ds      2
for_pos:   ds      2
           ds      80
for_st:    ds      1
#endif
lfsr:      ds      4
inp_pos:   ds      2                   ; pointer into INPUT buffer
ibuffer:   ds      80                  ; holds input for INPUT
buffer:    ds      256                 ; input buffer
gosub_pos: ds      2
gosub_st:  ds      256
tokens:    ds      256                 ; buffer for tokenization
           ds      128                 ; space for stack
stack:     ds      1
           ds      128
expstack:  ds      1
#ifdef ELFOS
fildes:    ds      20
dta:       ds      512
#endif
basic:     ds      1

