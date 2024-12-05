.segment "CODE"

.enum PpuSignal
  FrameReady = 1
  DisableRendering = 2
.endenum

; Makes the background all black.
; Rendering must be turned off before this is called.
clear_background:
  lda PPUSTATUS ; clear write latch

  ; Set base address for the first nametable
  MOVE PPUADDR, #$20
  MOVE PPUADDR, #$00

  ldy #30  ; 30 rows
  :
    ldx #32
    :
      sta PPUDATA
      dex
      bne :-
    dey
    bne :--

  rts

; Block until NMI returns
; Clobbers A
ppu_update:
  MOVE nmi_signal, #PpuSignal::FrameReady
  :
    lda nmi_signal
    bne :-
  rts

; Set tile at X/Y to A next time ppu_update is called
; Can be used with rendering on
; Preserves X, Y and A
ppu_update_tile:
  ; This function just stores a nametable address + a tile ID for nametable $2000
  ; into the buffer.
  ; The address is gonna have the form 0010 00YY YYYX XXXX

  ; Preserve registers
  sta t1 ; t1 = A
  stx t2 ; t2 = X
  sty t3 ; t3 = Y

  ; Computing the high byte of the address
  ; Take only the top 2 bits of Y
  tya
  lsr
  lsr
  lsr
  ora #$20 

  ldx nt_update_len ; nt_update[nt_update_len] = addr high byte
  sta nt_update, X
  inx               ; nt_update_len++;

  ; Computing the lower byte of the address
  tya ; Put the low 3 bits of Y into the top
  asl
  asl
  asl
  asl
  asl
  sta t4
  ; load X
  lda t2 
  ora t4           ; OR in X so we get YYYX XXXX
  sta nt_update, X ; nt_update[nt_update_len] = addr high byte
  inx              ; nt_update_len++; 
  ; load A
  lda t1
  sta nt_update, X
  inx
  ; Write back the new length of nt_update 
  stx nt_update_len

  ; Restore registers
  lda t1
  ldx t2
  ldy t3

  rts

; Draws a null terminated string beginning at X, Y
; ---Parameters---
; ptr - Address of null terminated string
; X - Tile X
; Y - Tile Y
.proc draw_string
  ; Push saved registers
  PUSH s1
  PUSH s2
  
  tile_y = s1
  sty tile_y

  ldy #0
@loop:
  lda (ptr1), Y ; while (str[y] != '\0')
  beq @loop_end
  sty s2     ; Preserve the y index
  ldy tile_y
  jsr ppu_update_tile
  ldy s2
  
  inx        ; x++
  iny        ; y++
  jmp @loop
@loop_end:
  ; Restore registers
  POP s2
  POP s1
  rts
.endproc

; Draw a string literal at immediate tile coordinates
.macro DRAW_STRING static_str, tile_x, tile_y
  MOVE ptr1,     #<static_str ; write low byte
  MOVE {ptr1+1}, #>static_str ; write high byte
  ldx #tile_x
  ldy #tile_y
  jsr draw_string
.endmacro
