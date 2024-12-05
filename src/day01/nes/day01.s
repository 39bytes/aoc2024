NUMS_LEN = 1000
NUMS_PAGES = 12

.segment "ZEROPAGE"
  answer: .res 3 ; Answer fits in a 24 bit int
  answer_bcd: .res 8

.segment "BSS"
  ; Input number lists have 1000 numbers, each 3 bytes long
  nums1: .res (NUMS_LEN * 3)
  nums2: .res (NUMS_LEN * 3)

.segment "RODATA"
  input_left: .incbin "input_left.bin"
  input_right: .incbin "input_right.bin"

.segment "CODE"

.macro COPY_PAGES dest, src, n_pages
  LOAD16 ptr1, #<src, #>src
  LOAD16 ptr2, #<dest, #>dest

  ldy #0
  ldx #n_pages

:
  ; Copy 1 page
  lda (ptr1), Y
  sta (ptr2), Y
  iny
  bne :-
  ; After finishing a page, increment the high bytes of both pointers
  inc ptr1+1
  inc ptr2+1
  dex
  bne :-

.endmacro

; Add a 16 bit immediate to a variable and store it in dest.
.macro ADD16 dest, var, imm
  MOVE16 p1_16, var
  LOAD16 p2_16, #<imm, #>imm
  jsr add16
  MOVE16 dest, r1_16
.endmacro

; Subtract a 16 bit immediate from a variable and store it in dest.
.macro SUB16 dest, var, imm
  MOVE16 p1_16, var
  LOAD16 p2_16, #<imm, #>imm
  jsr sub16
  MOVE16 dest, r1_16
.endmacro

.macro SUB24 dest, var, imm_lo, imm_mid, imm_hi
  MOVE24 p1_24, var
  LOAD24 p2_24, #imm_lo, #imm_mid, imm_hi
  jsr sub24
  MOVE24 dest, r1_24
.endmacro

.macro CMP16 first, second
  MOVE16 p1_16, first
  MOVE16 p2_16, second
  jsr cmp16
.endmacro

str_loading_input: .asciiz "Loading input"
str_sorting_first: .asciiz "Sorting first.."
str_sorting_second: .asciiz "Sorting second.."
str_calculating: .asciiz "Calculating.."
str_answer: .asciiz "Answer:"

run_part1:
  jsr ppu_update
  DRAW_STRING str_loading_input, 1, 1
  jsr ppu_update
  jsr copy_input_to_ram

  DRAW_STRING str_sorting_first, 1, 2
  jsr ppu_update
  LOAD16 ptr1, #<nums1, #>nums1
  jsr insertion_sort

  DRAW_STRING str_sorting_second, 1, 3
  jsr ppu_update
  LOAD16 ptr1, #<nums2, #>nums2
  jsr insertion_sort

  DRAW_STRING str_calculating, 1, 4
  jsr ppu_update
  jsr calculate_answer
  jsr answer_to_decimal

  DRAW_STRING str_answer, 1, 5
  jsr ppu_update
  
  ldx #8
  ldy #5
  jsr draw_answer_bcd
  jsr ppu_update

@loop:
  jmp @loop


copy_input_to_ram:
  COPY_PAGES nums1, input_left, NUMS_PAGES
  COPY_PAGES nums2, input_right, NUMS_PAGES
  rts

; Insertion sort for the number lists.
; ---Parameters---
; ptr1: Pointer to the beginning of the list
; ----------------
insertion_sort:
  start = t1_16
  end = t2_16

  MOVE16 start, ptr1
  ; Compute where the end of the array should be
  ADD16 end, ptr1, $0BB8 ; 3000 in hex = 0x0BB8

  ; ptr1 points to the first element after the sorted portion
  ; so need to add 1 to it first.
  ADD16 ptr1, ptr1, $0003

@outer: ; while ptr1 < end
  CMP16 ptr1, end 
  bcc :+
    jmp @done
  :

  SUB16 ptr2, ptr1, $0003 ; j = i - 3 bytes
  @inner: 
    CMP16 ptr2, start
    bcc @done_inner

    ; Load A[j] and A[j+1]
    ldy #0
    MOVE p1_24, {(ptr2), Y}
    iny
    MOVE p1_24+1, {(ptr2), Y}
    iny
    MOVE p1_24+2, {(ptr2), Y}
    iny
    MOVE p2_24, {(ptr2), Y}
    iny
    MOVE p2_24+1, {(ptr2), Y}
    iny
    MOVE p2_24+2, {(ptr2), Y}

    jsr cmp24 ; if A[j+1] >= A[j], we don't need to swap
    bcc @done_inner
    ; Swap A[j+1] and A[j]
    ldy #0
    MOVE {(ptr2), Y}, p2_24
    iny
    MOVE {(ptr2), Y}, p2_24+1
    iny
    MOVE {(ptr2), Y}, p2_24+2
    iny
    MOVE {(ptr2), Y}, p1_24
    iny
    MOVE {(ptr2), Y}, p1_24+1
    iny
    MOVE {(ptr2), Y}, p1_24+2
    
    SUB16 ptr2, ptr2, $0003
    jmp @inner
@done_inner:
  ADD16 ptr1, ptr1, $0003
  jmp @outer

@done:
  rts

calculate_answer:
  @end = t1_16

  LOAD16 ptr1, #<nums1, #>nums1
  LOAD16 ptr2, #<nums2, #>nums2
  ; nums1 and nums2 are contiguous in memory,
  ; so we know we're done when ptr1 hits the start of nums2.
  MOVE16 @end, ptr2

  ldy #0

@loop:
  CMP16 ptr1, @end ; while ptr1 < end
  bcc :+
    jmp @done
  :

  ; Load nums1[i] and nums2[i]
  ldy #0
  MOVE p1_24, {(ptr1), Y}
  MOVE p2_24, {(ptr2), Y}
  iny
  MOVE p1_24+1, {(ptr1), Y}
  MOVE p2_24+1, {(ptr2), Y}
  iny
  MOVE p1_24+2, {(ptr1), Y}
  MOVE p2_24+2, {(ptr2), Y}

  jsr cmp24 
  ; if nums1[i] >= nums2[i], then compute nums1[i] - nums2[i]
  bcc @less
    jsr sub24
    jmp @after
@less:
    ; otherwise compute nums2[i] - nums1[i]
    ; so we need to swap the two first
    MOVE24 t1_24, p1_24
    MOVE24 p1_24, p2_24
    MOVE24 p2_24, t1_24
    jsr sub24
@after:
  ; add the result to the answer 
  ; inlined here to make it faster
  clc
  ; Add byte 0
  lda answer
  adc r1_24
  sta answer
  ; Add byte 1
  lda answer+1
  adc r1_24+1
  sta answer+1
  ; Add byte 2
  lda answer+2
  adc r1_24+2
  sta answer+2

  ADD16 ptr1, ptr1, $0003
  ADD16 ptr2, ptr2, $0003
  jmp @loop

@done:
  rts

; Convert the answer to binary coded decimal.
.proc answer_to_decimal
  ldy #'0'

  ten_millions = answer_bcd
  millions = answer_bcd+1
  hundred_thousands = answer_bcd+2
  ten_thousands = answer_bcd+3
  thousands = answer_bcd+4
  hundreds = answer_bcd+5
  tens = answer_bcd+6
  ones = answer_bcd+7

  sty ten_millions
  sty millions
  sty hundred_thousands
  sty ten_thousands
  sty thousands
  sty hundreds
  sty tens
  sty ones

@calc_ten_millions:
  MOVE24 p1_24, answer
  LOAD24 p2_24, #$80, #$96, #$98 ; 10 mil in hex
  jsr cmp24
  bcc @calc_millions
  jsr sub24
  MOVE24 answer, r1_24
  inc ten_millions
  jmp @calc_ten_millions
@calc_millions:
  MOVE24 p1_24, answer
  LOAD24 p2_24, #$40, #$42, #$0F ; 1 mil in hex
  jsr cmp24
  bcc @calc_hundred_thousands
  jsr sub24
  MOVE24 answer, r1_24
  inc millions
  jmp @calc_millions
@calc_hundred_thousands:
  MOVE24 p1_24, answer
  LOAD24 p2_24, #$A0, #$86, #$01 ; 100000 in hex
  jsr cmp24
  bcc @calc_ten_thousands
  jsr sub24
  MOVE24 answer, r1_24
  inc hundred_thousands
  jmp @calc_hundred_thousands
@calc_ten_thousands:
  MOVE24 p1_24, answer
  LOAD24 p2_24, #$10, #$27, #$00 ; 10000 in hex
  jsr cmp24
  bcc @calc_thousands
  jsr sub24
  MOVE24 answer, r1_24
  inc ten_thousands
  jmp @calc_ten_thousands
@calc_thousands:
  MOVE16 p1_16, answer
  LOAD16 p2_16, #$E8, #$03 ; 1000 in hex
  jsr cmp16
  bcc @calc_hundreds
  jsr sub16
  MOVE16 answer, r1_16
  inc thousands
  jmp @calc_thousands
@calc_hundreds:
  MOVE16 p1_16, answer
  LOAD16 p2_16, #$64, #$00 ; 100 in hex
  jsr cmp16
  bcc @calc_tens
  jsr sub16
  MOVE16 answer, r1_16
  inc hundreds
  jmp @calc_hundreds
@calc_tens:
  lda answer
  cmp #10
  bcc @calc_ones
  sbc #10
  sta answer
  inc tens
  jmp @calc_tens
@calc_ones:
  lda answer
  clc
  adc #'0'
  sta ones

  rts
.endproc


; Draws answer_bcd.
; ---Parameters---
; X - X position of the first digit
; Y - Y position
.proc draw_answer_bcd
  lda answer_bcd
  jsr ppu_update_tile
  inx

  lda answer_bcd+1
  jsr ppu_update_tile
  inx

  lda answer_bcd+2
  jsr ppu_update_tile
  inx

  lda answer_bcd+3
  jsr ppu_update_tile
  inx

  lda answer_bcd+4
  jsr ppu_update_tile
  inx

  lda answer_bcd+5
  jsr ppu_update_tile
  inx

  lda answer_bcd+6
  jsr ppu_update_tile
  inx
  
  lda answer_bcd+7
  jsr ppu_update_tile
  inx

  rts
.endproc

; ---------------
; Math operations
; ---------------

; 16 bit addition: B + C
; Preserves: X, Y
; ---Parameters---
; p1_16 - B
; p2_16 - C
; ---Returns---
; r1_16 - Result
add16:
  clc
  ; Add low bytes
  lda p1_16
  adc p2_16
  sta r1_16
  ; Add high bytes
  lda p1_16+1
  adc p2_16+1
  sta r1_16+1

  rts


; 16 bit subtraction: B - C
; Preserves: X, Y
; ---Parameters---
; p1_16 - B
; p2_16 - C
; ---Returns---
; r1_16 - Result
sub16:
  sec
  ; Subtract low bytes
  lda p1_16
  sbc p2_16
  sta r1_16
  ; Subtract middle bytes
  lda p1_16+1
  sbc p2_16+1
  sta r1_16+1

  rts

; 24 bit subtraction: B - C
; Preserves: X, Y
; ---Parameters---
; p1_24 - B
; p2_24 - C
; ---Returns---
; r1_24 - Result
sub24:
  sec
  ; Subtract low bytes
  lda p1_24
  sbc p2_24
  sta r1_24
  ; Subtract middle bytes
  lda p1_24+1
  sbc p2_24+1
  sta r1_24+1
  ; Subtract high bytes
  lda p1_24+2
  sbc p2_24+2
  sta r1_24+2

  rts

; 16 bit comparison between two numbers B and C
; Preserves: X, Y
; ---Parameters----
; p1_16 - B
; p2_16 - C
; ---Returns---
; Sets Z if B == C
; Sets C if B >= C
cmp16:
  ; Compare high bytes
  lda p1_16+1
  cmp p2_16+1
  beq :+
    rts
:
  ; Compare low bytes
  lda p1_16
  cmp p2_16
  rts

; 24 bit comparison between two numbers B and C
; Preserves: X, Y
; ---Parameters----
; p1_24 - B
; p2_24 - C
; ---Returns---
; Sets Z if B == C
; Sets C if B >= C
cmp24:
  ; Compare high bytes
  lda p1_24+2
  cmp p2_24+2
  beq :+
    rts
:
  ; Compare middle bytes
  lda p1_24+1
  cmp p2_24+1
  beq :+
    rts
:
  ; Compare low bytes
  lda p1_24
  cmp p2_24
  rts
