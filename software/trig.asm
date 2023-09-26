; ************************
; ***** Trig Library *****
; ************************

getargs:  lda      r6           ; get passed argument
          str      r2           ; store for add
          glo      r2           ; add stack offset
          add
          plo      rf           ; put into first argument
          ghi      r2           ; high of stack
          adci     0            ; propagate carry
          phi      rf           ; rf now has argument address
          inc      rf           ; remove last call offset
          inc      rf
          lda      r6           ; get passed argument
          str      r2           ; store for add
          glo      r2           ; add stack offset
          add
          plo      rd           ; put into second argument
          ghi      r2           ; high of stack
          adci     0            ; propagate carry
          phi      rd           ; rd now has argument address
          inc      rd           ; remove last call offset
          inc      rd
          sep      sret         ; return to caller

addtows:  irx                   ; retrieve return address
          ldxa
          phi      r7
          ldx
          plo      r7
          inc      rd           ; move to msb
          inc      rd
          inc      rd
          ldn      rd           ; retrieve
          stxd                  ; and place on stack
          dec      rd
          ldn      rd           ; retrieve next byte
          stxd                  ; and place on stack
          dec      rd
          ldn      rd           ; retrieve next byte
          stxd                  ; and place on stack
          dec      rd
          ldn      rd           ; retrieve next byte
          stxd                  ; and place on stack
          glo      r7           ; put return address back on stack
          stxd
          ghi      r7
          stxd
          sep      sret         ; return to caller

fpcopy:   lda      rd           ; copy source to destination
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          sep      sret         ; return to caller

; ******************************************************
; ***** sin                                        *****
; ***** RF - Pointer to floating point number      *****
; ***** RD - Pointer to floating point destination *****
; ***** internal:                                  *****
; *****       R2+1  R7 - sum                       *****
; *****       R2+5  R8 - pwr                       *****
; *****       R2+9  R9 - last                      *****
; *****       R2+13 RA - fct                       *****
; *****       R2+17 RB - fctCount                  *****
; *****       R2+21 RC - tmp                       *****
; *****       R2+25 RD - sgn                       *****
; *****       R2+29    - angle                     *****
; ******************************************************
fpsin:    push     rd           ; save destination
          mov      rd,rf        ; angle = argument
          sep      scall        ; add to workspace
          dw       addtows
          mov      rd,fp_1      ; sgn = 1.0
          sep      scall        ; add to workspace
          dw       addtows
          stxd                  ; make space for tmp
          stxd
          stxd
          stxd
          mov      rd,fp_2      ; fctCount = 2.0
          sep      scall        ; add to workspace
          dw       addtows
          mov      rd,fp_1      ; fct = 1.0
          sep      scall        ; add to workspace
          dw       addtows
          stxd                  ; make space for last
          stxd
          stxd
          stxd
          mov      rd,rf        ; pwr = argument
          sep      scall        ; add to workspace
          dw       addtows
          mov      rd,rf        ; sum = argument
          sep      scall        ; add to workspace
          dw       addtows
          
sincos:   sep      scall        ; angle = angle * angle
          dw       getargs
          db       29,29
          sep      scall        ; angle = angle * angle
          dw       fpmul
sincos_l: sep      scall        ; need to see if sum == last
          dw       getargs
          db       9,1
          ldi      4            ; 4 bytes to check
          plo      rc
          ldi      0            ; clear comparison flag
          plo      re
sincos_1: ldn      rd           ; get byte from sum
          str      r2           ; save for comparison
          ldn      rf           ; get point from last
          sm                    ; compare them
          str      r2           ; store to combine with comparison flag
          glo      re           ; get comparison flag
          or                    ; combine
          plo      re           ; put back into comparison
          ldn      rd           ; get byte from sum
          str      rf           ; store into last
          inc      rd           ; increment pointers
          inc      rf
          dec      rc           ; decrement count
          glo      rc           ; see if done
          lbnz     sincos_1     ; jump if not
          glo      re           ; get comparison flag
          lbz      sincos_d     ; jump if done
          glo      r2           ; point to msb of sgn
          adi      28
          plo      r7
          ghi      r2
          adci     0
          phi      r7
          ldn      r7           ; get msb of sgn
          xri      080h         ; flip the sign
          str      r7           ; and put it back
          sep      scall        ; pwr = pwr * angle
          dw       getargs
          db       5,29
          sep      scall
          dw       fpmul
          sep      scall        ; fct = fct * fctCount
          dw       getargs
          db       13,17
          sep      scall
          dw       fpmul
          glo      r2           ; fctCount = fctCount + 1
          adi      17
          plo      rf
          ghi      r2
          adci     0
          phi      rf
          mov      rd,fp_1
          sep      scall
          dw       fpadd
          sep      scall        ; fct = fct * fctCount
          dw       getargs
          db       13,17
          sep      scall
          dw       fpmul
          glo      r2           ; fctCount = fctCount + 1
          adi      17
          plo      rf
          ghi      r2
          adci     0
          phi      rf
          mov      rd,fp_1
          sep      scall
          dw       fpadd
          sep      scall        ; tmp = sgn
          dw       getargs
          db       21,25
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          sep      scall        ; tmp = tmp * pwr
          dw       getargs
          db       21,5
          sep      scall
          dw       fpmul
          sep      scall        ; tmp = tmp / fct
          dw       getargs
          db       21,13
          sep      scall
          dw       fpdiv
          sep      scall        ; sum = sum + tmp
          dw       getargs
          db       1,21
          sep      scall
          dw       fpadd
          lbr      sincos_l     ; loop until done
sincos_d: irx                   ; recover answer
          ldxa
          plo      r8
          ldxa
          phi      r8
          ldxa
          plo      r7
          ldx
          phi      r7
          glo      r2           ; clean workspace off stack
          adi      28
          plo      r2
          ghi      r2
          adci     0
          phi      r2
          pop      rd           ; recover destination address
          glo      r8           ; store answer
          str      rd
          inc      rd
          ghi      r8
          str      rd
          inc      rd
          glo      r7
          str      rd
          inc      rd
          ghi      r7
          str      rd
          sep      sret         ; and return to caller

; ******************************************************
; ***** cos                                        *****
; ***** RF - Pointer to floating point number      *****
; ***** RD - Pointer to floating point destination *****
; ***** internal:                                  *****
; *****       R2+1  R7 - sum                       *****
; *****       R2+5  R8 - pwr                       *****
; *****       R2+9  R9 - last                      *****
; *****       R2+13 RA - fct                       *****
; *****       R2+17 RB - fctCount                  *****
; *****       R2+21 RC - tmp                       *****
; *****       R2+25 RD - sgn                       *****
; *****       R2+29    - angle                     *****
; ******************************************************
fpcos:    push     rd           ; save destination
          mov      rd,rf        ; angle = argument
          sep      scall        ; add to workspace
          dw       addtows
          mov      rd,fp_1      ; sgn = 1.0
          sep      scall        ; add to workspace
          dw       addtows
          stxd                  ; make space for tmp
          stxd
          stxd
          stxd
          mov      rd,fp_1      ; fctCount = 1.0
          sep      scall        ; add to workspace
          dw       addtows
          mov      rd,fp_1      ; fct = 1.0
          sep      scall        ; add to workspace
          dw       addtows
          stxd                  ; make space for last
          stxd
          stxd
          stxd
          mov      rd,fp_1      ; pwr = 1.0
          sep      scall        ; add to workspace
          dw       addtows
          mov      rd,fp_1      ; sum = 1.0
          sep      scall        ; add to workspace
          dw       addtows
          lbr      sincos       ; now compute

; ******************************************************
; ***** tan                                        *****
; ***** RF - Pointer to floating point number      *****
; ***** RD - Pointer to floating point destination *****
; ***** internal:                                  *****
; *****       R2+1     - s                         *****
; *****       R2+5     - c                         *****
; ******************************************************
fptan:    push     rd           ; save destination
          mov      rd,rf        ; s = argument
          sep      scall
          dw       addtows
          mov      rd,rf        ; c = argument
          sep      scall
          dw       addtows
          glo      r2           ; setup for computing sin
          plo      rf
          plo      rd
          ghi      r2
          phi      rf
          phi      rd
          inc      rf
          inc      rd
          sep      scall        ; compute sin
          dw       fpsin
          glo      r2           ; setup to compute cos
          adi      5
          plo      rd
          plo      rf
          ghi      r2
          adci     0
          phi      rd
          phi      rf
          sep      scall        ; compute cos
          dw       fpcos
          sep      scall        ; get arguments for division
          dw       getargs
          db       1,5
          sep      scall        ; s = s / c
          dw       fpdiv
          irx                   ; recover answer
          ldxa
          plo      r8
          ldxa
          phi      r8
          ldxa
          plo      r7
          ldxa
          phi      r7
          irx                   ; move past c
          irx
          irx
          pop      rd           ; recover destination address
          glo      r8           ; store answer
          str      rd
          inc      rd
          ghi      r8
          str      rd
          inc      rd
          glo      r7
          str      rd
          inc      rd
          ghi      r7
          str      rd
          sep      sret         ; and return to caller

; ******************************************************
; ***** Natural logarithm                          *****
; ***** RF - Pointer to floating point number      *****
; ***** RD - Pointer to floating point destination *****
; ***** internal:                                  *****
; *****       R2+1     - sum                       *****
; *****       R2+5     - last                      *****
; *****       R2+9     - k                         *****
; *****       R2+13    - pwr                       *****
; *****       R2+17    - tmp                       *****
; *****       R2+21    - n                         *****
; ******************************************************
fplog:    push     rd           ; save destination
          mov      rd,rf        ; n = argument
          sep      scall
          dw       addtows
          mov      rd,rf        ; tmp = argument
          sep      scall
          dw       addtows
          stxd                  ; reserve space for pwr
          stxd
          stxd
          stxd
          mov      rd,fp_1      ; k = 1.0
          sep      scall        ; add to workspace
          dw       addtows
          mov      rd,fp_1      ; last = 1.0
          sep      scall        ; add to workspace
          dw       addtows
          ldi      0            ; sum = 0
          stxd
          stxd
          stxd
          stxd
          glo      r2           ; point to tmp
          adi      17
          plo      rf
          ghi      r2
          adci     0
          phi      rf
          mov      rd,fp_1      ; point to 1.0
          sep      scall        ; compute n+1
          dw       fpadd
          glo      r2           ; point to n
          adi      21
          plo      rf
          ghi      r2
          adci     0
          phi      rf
          mov      rd,fp_1      ; point to 1.0
          sep      scall        ; compute n-1
          dw       fpsub
          sep      scall        ; compute (n-1)/(n+1)
          dw       getargs
          db       21,17
          sep      scall
          dw       fpdiv
          sep      scall        ; pwr = n
          dw       getargs
          db       13,21
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          sep      scall        ; n = n * n
          dw       getargs
          db       21,21
          sep      scall
          dw       fpmul
fplog_l:  sep      scall        ; need to see if sum == last
          dw       getargs
          db       5,1
          ldi      4            ; 4 bytes to check
          plo      rc
          ldi      0            ; clear comparison flag
          plo      re
fplog_1:  ldn      rd           ; get byte from sum
          str      r2           ; save for comparison
          ldn      rf           ; get point from last
          sm                    ; compare them
          str      r2           ; store to combine with comparison flag
          glo      re           ; get comparison flag
          or                    ; combine
          plo      re           ; put back into comparison
          ldn      rd           ; get byte from sum
          str      rf           ; store into last
          inc      rd           ; increment pointers
          inc      rf
          dec      rc           ; decrement count
          glo      rc           ; see if done
          lbnz     fplog_1      ; jump if not
          glo      re           ; get comparison flag
          lbz      fplog_d      ; jump if done
          sep      scall        ; tmp = pwr
          dw       getargs
          db       17,13
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          sep      scall        ; tmp = tmp / k
          dw       getargs
          db       17,9
          sep      scall
          dw       fpdiv
          sep      scall        ; sum = sum + tmp
          dw       getargs
          db       1,17
          sep      scall
          dw       fpadd
          sep      scall        ; pwr = pwr * n
          dw       getargs
          db       13,21
          sep      scall
          dw       fpmul
          glo      r2           ; k = k + 2
          adi      9
          plo      rf
          ghi      r2
          adci     0
          phi      rf
          mov      rd,fp_2
          sep      scall
          dw       fpadd
          lbr      fplog_l      ; loop until done
fplog_d:  sep      scall        ; sum = sum + sum
          dw       getargs
          db       1,1
          sep      scall
          dw       fpadd
          irx                   ; recover answer
          ldxa     
          plo      r8
          ldxa
          phi      r8
          ldxa
          plo      r7
          ldx
          phi      r7
          glo      r2           ; clean up the stack
          adi      20
          plo      r2
          ghi      r2
          adci     0
          phi      r2
          pop      rd           ; recover destination address
          glo      r8           ; store answer
          str      rd
          inc      rd
          ghi      r8
          str      rd
          inc      rd
          glo      r7
          str      rd
          inc      rd
          ghi      r7
          str      rd
          sep      sret         ; and return to caller

; ******************************************************
; ***** Natural exp                                *****
; ***** RF - Pointer to floating point number      *****
; ***** RD - Pointer to floating point destination *****
; ***** internal:                                  *****
; *****       R2+1     - sum                       *****
; *****       R2+5     - last                      *****
; *****       R2+9     - fct                       *****
; *****       R2+13    - fctCount                  *****
; *****       R2+17    - pwr                       *****
; *****       R2+21    - tmp                       *****
; *****       R2+25    - n                         *****
; ******************************************************
fpexp:    push     rd           ; save destination
          mov      rd,rf        ; n = argument
          sep      scall
          dw       addtows
          stxd                  ; space for tmp
          stxd
          stxd
          stxd
          mov      rd,rf        ; pwr = argument
          sep      scall
          dw       addtows
          mov      rd,fp_2      ; fctCount = 2.0
          sep      scall
          dw       addtows
          mov      rd,fp_1      ; fct = 1.0
          sep      scall
          dw       addtows
          mov      rd,fp_0      ; last = 0
          sep      scall
          dw       addtows
          mov      rd,rf        ; sum = argument
          sep      scall
          dw       addtows
          mov      rf,r2        ; sum = sum + 1
          inc      rf
          mov      rd,fp_1
          sep      scall
          dw       fpadd
fpexp_l:  sep      scall        ; need to see if sum == last
          dw       getargs
          db       5,1
          ldi      4            ; 4 bytes to check
          plo      rc
          ldi      0            ; clear comparison flag
          plo      re
fpexp_1:  ldn      rd           ; get byte from sum
          str      r2           ; save for comparison
          ldn      rf           ; get point from last
          sm                    ; compare them
          str      r2           ; store to combine with comparison flag
          glo      re           ; get comparison flag
          or                    ; combine
          plo      re           ; put back into comparison
          ldn      rd           ; get byte from sum
          str      rf           ; store into last
          inc      rd           ; increment pointers
          inc      rf
          dec      rc           ; decrement count
          glo      rc           ; see if done
          lbnz     fpexp_1      ; jump if not
          glo      re           ; get comparison flag
          lbz      fpexp_d      ; jump if done
          sep      scall        ; pwr = pwr * n
          dw       getargs
          db       17,25
          sep      scall
          dw       fpmul
          sep      scall        ; fct = fct * fctCount
          dw       getargs
          db       9,13
          sep      scall
          dw       fpmul
          glo      r2           ; fctCount = fctCount + 1
          adi      13
          plo      rf
          ghi      r2
          adci     0
          phi      rf
          mov      rd,fp_1
          sep      scall
          dw       fpadd
          sep      scall        ; tmp = pwr
          dw       getargs
          db       21,17
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          inc      rf
          lda      rd
          str      rf
          sep      scall        ; tmp = tmp / fct
          dw       getargs
          db       21,9
          sep      scall
          dw       fpdiv
          sep      scall        ; sum = sum + tmp
          dw       getargs
          db       1,21
          sep      scall
          dw       fpadd
          lbr      fpexp_l      ; loop until done
fpexp_d:  irx                   ; recover answer
          ldxa
          plo      r8
          ldxa
          phi      r8
          ldxa
          plo      r7
          ldx
          phi      r7
          glo      r2           ; clean workspace off stack
          adi      24
          plo      r2
          ghi      r2
          adci     0
          phi      r2
          pop      rd           ; recover destination address
          glo      r8           ; store answer
          str      rd
          inc      rd
          ghi      r8
          str      rd
          inc      rd
          glo      r7
          str      rd
          inc      rd
          ghi      r7
          str      rd
          sep      sret         ; and return to caller

; ******************************************************
; ***** Power x^y                                  *****
; ***** RF - Pointer to floating point number x    *****
; ***** RC - Pointer to floating point number y    *****
; ***** RD - Pointer to floating point destination *****
; ***** internal:                                  *****
; *****       R2+1     - x                         *****
; *****       R2+5     - y                         *****
; ******************************************************
fppow:    push     rd           ; save destination
          mov      rd,rc        ; put y in workspace
          sep      scall
          dw       addtows
          mov      rd,rf        ; put x in workspace
          sep      scall
          dw       addtows
          glo      r2           ; x = log(x)
          plo      rf
          plo      rd
          ghi      r2
          phi      rf
          phi      rd
          inc      rf
          inc      rd
          sep      scall
          dw       fplog
          sep      scall        ; now x = x * y
          dw       getargs
          db       1,5
          sep      scall
          dw       fpmul
          sep      scall        ; x = exp(x)
          dw       getargs
          db       1,1
          sep      scall
          dw       fpexp
          irx                   ; recover result
          ldxa
          plo      r8
          ldxa
          phi      r8
          ldxa
          plo      r7
          ldxa
          phi      r7
          irx                   ; clean rest of stack
          irx
          irx
          pop      rd           ; recover destination
          glo      r8           ; store answer
          str      rd
          inc      rd
          ghi      r8
          str      rd
          inc      rd
          glo      r7
          str      rd
          inc      rd
          ghi      r7
          str      rd
          sep      sret         ; and return to caller


; ******************************************************
; ***** Square root                                *****
; ***** RF - Pointer to floating point number x    *****
; ***** RD - Pointer to floating point destination *****
; ******************************************************
fpsqrt:   mov      rc,fpdot5    ; need to do x**(1/2)
          lbr      fppow


; ******************************************************
; ***** atan                                       *****
; ***** RF - Pointer to floating point number      *****
; ***** RD - Pointer to floating point destination *****
; ***** internal:                                  *****
; *****       R2+1     - count                     *****
; *****       R2+3     - sum                       *****
; *****       R2+7     - sign                      *****
; *****       R2+8     - pwr                       *****
; *****       R2+12    - last                      *****
; *****       R2+16    - k                         *****
; *****       R2+20    - tmp                       *****
; *****       R2+24    - sgn                       *****
; *****       R2+28    - n                         *****
; *****       R2+32    - tmp2
; ******************************************************
fpatan:       sep       scall          ; check for 0 argument
              dw        iszero
              lbnf      fpatan_go      ; jump if not zero
fpzero:       ldi       0              ; result is zero
              str       rd
              inc       rd
              str       rd
              inc       rd
              str       rd
              inc       rd
              str       rd
              sep       sret           ; and return
fpatan_go:    push      rd             ; save destination
              stxd                     ; space for tmp2
              stxd
              stxd
              stxd
              mov       rd,rf          ; n = argument
              sep       scall
              dw        addtows
              mov       rd,fp_1        ; sgn = 1
              sep       scall
              dw        addtows
              stxd                     ; space for tmp
              stxd
              stxd
              stxd
              mov       rd,fp_3        ; k = 3
              sep       scall
              dw        addtows
              mov       rd,fp_0        ; last = 0
              sep       scall
              dw        addtows
              mov       rd,rf          ; pwr = argument
              sep       scall
              dw        addtows
              inc       rf             ; point to msb of argument
              inc       rf
              inc       rf
              ldn       rf             ; retreive it
              dec       rf             ; move pointer back
              dec       rf
              dec       rf
              ani       080h           ; keep only sign bit
              stxd                     ; sign = sign of argument
              mov       rd,rf          ; sum = argument
              sep       scall
              dw        addtows
              ldi       3              ; count = 1000
              stxd
              ldi       0e8h
              stxd
              sep       scall          ; n = n * n
              dw        getargs
              db        28,28
              sep       scall
              dw        fpmul

              glo       r2             ; point exponent of n
              adi       30
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              lda       rf             ; get low bit of exponent
              shl                      ; shift into DF
              ldn       rf             ; get high bits of exponent
              shlc                     ; shift in low bit
              shl                      ; see if high bit is set (>= 2)
              lbdf      fpatan_2       ; jump if so
              shrc                     ; shift bit back in
              smi       07fh           ; check for less than 1
              lbnz      fpatan_1       ; jump if less than 1
              dec       rf             ; back to high byte of mantissa
              ldn       rf             ; retrieve it
              ani       07fh           ; clear high byte
              lbnz      fpatan_2       ; jump if greater than 1
              dec       rf             ; middle byte of mantissa
              ldn       rf
              lbnz      fpatan_2
              dec       rf             ; low byte of mantissa
              ldn       rf
              lbnz      fpatan_2
fpatan_1:     irx                      ; recover count
              ldxa
              plo       rc
              ldx
              phi       rc
              dec       rc             ; decrement count
              ghi       rc             ; put it back
              stxd
              glo       rc
              stxd
              glo       rc             ; check for nonzero
              lbnz      fpatan_1a      ; jump if not
              ghi       rc
              lbz       fpatan_dn      ; otherwise done
fpatan_1a:    sep       scall          ; need to see if sum == last
              dw        getargs
              db        12,3
              ldi       4              ; 4 bytes to check
              plo       rc
              ldi       0              ; clear comparison flag
              plo       re
fpatan_1b:    ldn       rd             ; get byte from sum
              str       r2             ; save for comparison
              ldn       rf             ; get point from last
              sm                       ; compare them
              str       r2             ; store to combine with comparison flag
              glo       re             ; get comparison flag
              or                       ; combine
              plo       re             ; put back into comparison
              ldn       rd             ; get byte from sum
              str       rf             ; store into last
              inc       rd             ; increment pointers
              inc       rf
              dec       rc             ; decrement count
              glo       rc             ; see if done
              lbnz      fpatan_1b      ; jump if not
              glo       re             ; get comparison flag
              lbz       fpatan_dn      ; jump if done
              sep       scall          ; pwr = pwr * n
              dw        getargs
              db        8,28
              sep       scall
              dw        fpmul
              glo       r2             ; sgn = -sgn
              adi       27
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              ldn       rf
              xri       080h
              str       rf
              sep       scall          ; tmp = sgn
              dw        getargs
              db        20,24
              lda       rd
              str       rf
              inc       rf
              lda       rd
              str       rf
              inc       rf
              lda       rd
              str       rf
              inc       rf
              lda       rd
              str       rf
              sep       scall          ; tmp = tmp * pwr
              dw        getargs
              db        20,8
              sep       scall
              dw        fpmul
              sep       scall          ; tmp = tmp / k
              dw        getargs
              db        20,16
              sep       scall
              dw        fpdiv
              sep       scall          ; sum = sum + tmp
              dw        getargs
              db        3,20
              sep       scall
              dw        fpadd
              glo       r2             ; k = k + 2
              adi       16
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              mov       rd,fp_2
              sep       scall
              dw        fpadd
              lbr       fpatan_1       ; loop until done
     

fpatan_2:     glo       r2             ; tmp = 1
              adi       20
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              mov       rd,fp_1
              sep       scall
              dw        fpcopy
              sep       scall          ; tmp = tmp / sum
              dw        getargs
              db        20,3
              sep       scall
              dw        fpdiv
              sep       scall          ; sum = tmp
              dw        getargs
              db        3,20
              sep       scall
              dw        fpcopy
              glo       r2             ; tmp = pi / 2
              adi       20
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              mov       rd,fp_halfpi
              sep       scall
              dw        fpcopy
              sep       scall          ; tmp = tmp - sum
              dw        getargs
              db        20,3
              sep       scall
              dw        fpsub
              sep       scall          ; sum = tmp
              dw        getargs
              db        3,20
              sep       scall
              dw        fpcopy
              glo       r2             ; sgn = -sgn
              adi       27
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              ldn       rf
              xri       080h
              str       rf
fpatan_2lp:   irx                      ; recover count
              ldxa
              plo       rc
              ldx
              phi       rc
              dec       rc             ; decrement count
              ghi       rc             ; put it back
              stxd
              glo       rc
              stxd
              glo       rc             ; check for nonzero
              lbnz      fpatan_2a      ; jump if not
              ghi       rc
              lbz       fpatan_dn      ; otherwise done
fpatan_2a:    sep       scall          ; need to see if sum == last
              dw        getargs
              db        12,3
              ldi       4              ; 4 bytes to check
              plo       rc
              ldi       0              ; clear comparison flag
              plo       re
fpatan_2b:    ldn       rd             ; get byte from sum
              str       r2             ; save for comparison
              ldn       rf             ; get point from last
              sm                       ; compare them
              str       r2             ; store to combine with comparison flag
              glo       re             ; get comparison flag
              or                       ; combine
              plo       re             ; put back into comparison
              ldn       rd             ; get byte from sum
              str       rf             ; store into last
              inc       rd             ; increment pointers
              inc       rf
              dec       rc             ; decrement count
              glo       rc             ; see if done
              lbnz      fpatan_2b      ; jump if not
              glo       re             ; get comparison flag
              lbz       fpatan_dn      ; jump if done
              sep       scall          ; pwr = pwr * n
              dw        getargs
              db        8,28
              sep       scall
              dw        fpmul
              glo       r2             ; sgn = -sgn
              adi       27
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              ldn       rf
              xri       080h
              str       rf
              sep       scall          ; tmp = k
              dw        getargs
              db        20,16
              sep       scall
              dw        fpcopy
              sep       scall          ; tmp = tmp * pwr
              dw        getargs
              db        20,8
              sep       scall
              dw        fpmul
              sep       scall          ; tmp2 = sgn
              dw        getargs
              db        32,24
              sep       scall
              dw        fpcopy
              sep       scall          ; tmp2 = tmp2 / tmp
              dw        getargs
              db        32,20
              sep       scall
              dw        fpdiv
              sep       scall          ; sum = sum + tmp2
              dw        getargs
              db        3,32
              sep       scall
              dw        fpadd
              glo       r2             ; k = k + 2
              adi       16
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              mov       rd,fp_2
              sep       scall
              dw        fpadd
              lbr       fpatan_2lp     ; loop until done
fpatan_dn:    irx                      ; remove count from stack
              irx
              irx                      ; recover answer
              ldxa
              plo       r8
              ldxa
              phi       r8
              ldxa
              plo       r7
              ldxa
              phi       r7
              ldx                      ; get sign
              lbz       fpatan_dn1     ; jump if not negative
              ghi       r7             ; make answer negative
              xri       080h
              phi       r7
fpatan_dn1:   glo       r2             ; clean workspace off stack
              adi       28
              plo       r2
              ghi       r2
              adci      0
              phi       r2
              pop       rd             ; recover destination
              glo       r8             ; store answer
              str       rd
              inc       rd
              ghi       r8
              str       rd
              inc       rd
              glo       r7
              str       rd
              inc       rd
              ghi       r7
              str       rd
              sep       sret           ; return to caller
 

; ******************************************************
; ***** asin                                       *****
; ***** RF - Pointer to floating point number x    *****
; ***** RC - Pointer to floating point number y    *****
; ***** RD - Pointer to floating point destination *****
; ***** internal:                                  *****
; *****       R2+1     - n                         *****
; *****       R2+5     - sign                      *****
; *****       R2+6     - tmp                       *****
; ******************************************************
fpasin:       sep       scall          ; check for 0 argument
              dw        iszero
              lbdf      fpzero         ; return 0
              push      rd             ; save destination
              stxd                     ; make space for n
              stxd
              stxd
              stxd
              inc       rf             ; point to sign of argument
              inc       rf
              inc       rf
              ldn       rf             ; retrieve it
              dec       rf             ; move pointer back
              dec       rf
              dec       rf
              ani       080h           ; keep only sign bit
              stxd                     ; sign = sign bit
              mov       rd,rf          ; n = argument
              sep       scall
              dw        addtows
              sep       scall          ; n = n * n
              dw        getargs
              db        1,1
              sep       scall
              dw        fpmul
              glo       r2             ; tmp = 1.0
              adi       6
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              mov       rd,fp_1
              sep       scall
              dw        fpcopy
              sep       scall          ; tmp = tmp - n;
              dw        getargs
              db        6,1
              sep       scall
              dw        fpsub
              sep       scall          ; n = n / tmp
              dw        getargs
              db        1,6
              sep       scall
              dw        fpdiv
              sep       scall          ; n = sqrt(n)
              dw        getargs
              db        1,1
              sep       scall
              dw        fpsqrt
              sep       scall          ; n = atan(n)
              dw        getargs
              db        1,1
              sep       scall
              dw        fpatan
              irx                      ; recover answer
              ldxa
              plo       r8
              ldxa
              phi       r8
              ldxa
              plo       r7
              ldxa
              phi       r7
              ldx                      ; get sign
              lbz       fpasin_dn1     ; jump if not negative
              ghi       r7             ; make answer negative
              xri       080h
              phi       r7
fpasin_dn1:   irx                      ; clean workspace off stack
              irx
              irx
              irx
              pop       rd             ; recover destination
              glo       r8             ; store answer
              str       rd
              inc       rd
              ghi       r8
              str       rd
              inc       rd
              glo       r7
              str       rd
              inc       rd
              ghi       r7
              str       rd
              sep       sret           ; return to caller


; ******************************************************
; ***** acos                                       *****
; ***** RF - Pointer to floating point number x    *****
; ***** RC - Pointer to floating point number y    *****
; ***** RD - Pointer to floating point destination *****
; ***** internal:                                  *****
; *****       R2+1     - n                         *****
; *****       R2+5     - sign                      *****
; *****       R2+6     - tmp                       *****
; ******************************************************
fpacos:       sep       scall          ; check for 0 argument
              dw        iszero
              lbdf      fpzero         ; return 0
              push      rd             ; save destination
              stxd                     ; make space for tmp
              stxd
              stxd
              stxd
              inc       rf             ; point to sign of argument
              inc       rf
              inc       rf
              ldn       rf             ; retrieve it
              dec       rf             ; move pointer back
              dec       rf
              dec       rf
              ani       080h           ; keep only sign bit
              stxd                     ; sign = sign bit
              mov       rd,rf          ; n = argument
              sep       scall
              dw        addtows
              sep       scall          ; n = n * n
              dw        getargs
              db        1,1
              sep       scall
              dw        fpmul
              glo       r2             ; tmp = 1.0
              adi       6
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              mov       rd,fp_1
              sep       scall
              dw        fpcopy
              sep       scall          ; tmp = tmp - n;
              dw        getargs
              db        6,1
              sep       scall
              dw        fpsub
              sep       scall          ; tmp = tmp / n
              dw        getargs
              db        6,1
              sep       scall
              dw        fpdiv
              sep       scall          ; n = sqrt(tmp)
              dw        getargs
              db        6,1
              sep       scall
              dw        fpsqrt
              sep       scall          ; n = atan(n)
              dw        getargs
              db        1,1
              sep       scall
              dw        fpatan

              glo       r2             ; point to sign
              adi       5
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              ldn       rf             ; get sign
              lbz       fpacos_dn      ; jump of argument was positive
              glo       r2             ; tmp = pi
              adi       6    
              plo       rf
              ghi       r2
              adci      0
              phi       rf
              mov       rd,fp_pi
              sep       scall
              dw        fpcopy
              sep       scall          ; tmp = tmp - n
              dw        getargs
              db        6,1
              sep       scall
              dw        fpsub
              sep       scall          ; n = tmp
              dw        getargs
              db        1,6
              sep       scall
              dw        fpcopy
fpacos_dn:    irx                      ; recover answer
              ldxa
              plo       r8
              ldxa
              phi       r8
              ldxa
              plo       r7
              ldxa
              phi       r7
fpacos_dn1:   irx                      ; clean workspace off stack
              irx
              irx
              irx
              pop       rd             ; recover destination
              glo       r8             ; store answer
              str       rd
              inc       rd
              ghi       r8
              str       rd
              inc       rd
              glo       r7
              str       rd
              inc       rd
              ghi       r7
              str       rd
              sep       sret           ; return to caller

