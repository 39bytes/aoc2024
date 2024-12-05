; Shortcut for lda + sta boilerplate
; Clobbers A
.macro MOVE to, from
  lda from
  sta to
.endmacro

; lda + pla
.macro PUSH var
  lda var
  pha
.endmacro

.macro POP var
  pla
  sta var
.endmacro

; Push the A, X and Y registers to the stack
; Use this at the beginning of a function that preserves registers
.macro PUSH_AXY
  pha
  txa
  pha
  tya
  pha
.endmacro

; Pop the Y, X and A registers from the stack
; Use this when returning from a function that preserves registers.
.macro POP_YXA
  pla
  tay
  pla
  tax
  pla
.endmacro

.macro MOVE16 to, from
  lda from
  sta to
  lda from+1
  sta to+1
.endmacro

.macro MOVE24 to, from
  lda from
  sta to
  lda from+1
  sta to+1
  lda from+2
  sta to+2
.endmacro

.macro LOAD16 to, low_byte, high_byte
  lda low_byte
  sta to
  lda high_byte
  sta to+1
.endmacro

.macro LOAD24 to, low_byte, mid_byte, high_byte
  lda low_byte
  sta to
  lda mid_byte
  sta to+1
  lda high_byte
  sta to+2
.endmacro
