.segment "HEADER"
INES_MAPPER = 1 ; 1 = MMC1
INES_MIRROR = 1 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0 ; 1 = battery backed SRAM at $6000-7FFF

.byte 'N', 'E', 'S', $1A ; ID
.byte $02 ; 16k PRG chunk count
.byte $01 ; 8k CHR chunk count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding

.segment "TILES"
  .incbin "bg_tiles.chr"

.segment "VECTORS"
  .addr nmi
  .addr reset
  .addr irq

PPUCTRL = $2000
; PPUCTRL bit flags
NMI_ENABLE          = 1 << 7
SPRITE_8X16         = 1 << 5
BG_PT_RIGHT         = 1 << 4
SPRITE_PT_RIGHT     = 1 << 3
VRAM_INCREMENT_DOWN = 1 << 2

PPUMASK = $2001
; PPUMASK bit flags
ENABLE_SPRITES    = 1 << 4
ENABLE_BG         = 1 << 3
SHOW_SPRITES_LEFT = 1 << 2
SHOW_BG_LEFT      = 1 << 1

PPUSTATUS = $2002
OAMADDR = $2003
OAMDATA = $2004
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007
OAMDMA = $4014

CONTROLLER1 = $4016

NUMS_LEN = 1000
NUMS_PAGES = 12

.segment "ZEROPAGE"
  nmi_lock:      .res 1 ; prevents NMI re-entry
  nmi_count:     .res 1 ; is incremented every NMI
  nmi_signal:    .res 1 ; set to 1 to push a PPU frame update, 2 to turn rendering off next NMI
  nt_update_len: .res 1 ; number of bytes in nt_update buffer    
  nt_update: .res 160; nametable update entry buffer for PPU update

  ; Temp registers - volatile
  t1: .res 1
  t2: .res 1
  t3: .res 1
  t4: .res 1
  t1_16: .res 2
  t2_16: .res 2
  t1_24: .res 3
  t2_24: .res 3

  ; Parameter registers - volatile
  p1_24:
    p1_16:
      p1: .res 1
      p2: .res 1
    p2_16:
      p3: .res 1
  p2_24:
      p4: .res 1
      p5: .res 1
      p6: .res 1

  ; Saved registers - non-volatile
  s1_16:
    s1: .res 1
    s2: .res 1
  s2_16:
    s3: .res 1
    s4: .res 1
  s5: .res 1
  s6: .res 1

  ; Return registers - volatile
  r1_24:
    r1_16:
      r1: .res 1
      r2: .res 1
      r3: .res 1

  ; Pointer registers
  ptr1: .res 2
  ptr2: .res 2

  ; Common state
  answer: .res 3 ; Answer fits in a 24 bit int
  answer_bcd: .res 8
  buttons: .res 1

.segment "BSS"
  ; Input number lists have 1000 numbers, each 3 bytes long
  nums1: .res (NUMS_LEN * 3)
  nums2: .res (NUMS_LEN * 3)

.segment "RODATA"
  input_left: .incbin "input_left.bin"
  input_right: .incbin "input_right.bin"

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

.enum PpuSignal
  FrameReady = 1
  DisableRendering = 2
.endenum

.segment "CODE"
reset:
  sei           ; disable IRQs
  cld           ; disable decimal mode
  ldx #$40
  stx $4017     ; disable APU frame IRQ
  ldx #$ff      ; Set up stack
  txs           ;  .
  inx           ; now X = 0
  stx PPUCTRL	; disable NMI
  stx PPUMASK	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
@vblankwait1:
  bit PPUSTATUS
  bpl @vblankwait1

@clear_memory:
  lda #$00
  sta $0000, X
  sta $0100, X
  sta $0200, X
  sta $0300, X
  sta $0400, X
  sta $0500, X
  sta $0600, X
  sta $0700, X
  sta $6000, X
  sta $6100, X
  sta $6200, X
  sta $6300, X
  sta $6400, X
  sta $6500, X
  sta $6600, X
  sta $6700, X
  sta $6800, X
  sta $6900, X
  sta $6A00, X
  sta $6B00, X
  sta $6C00, X
  sta $6D00, X
  sta $6E00, X
  sta $6F00, X
  sta $7000, X
  sta $7100, X
  sta $7200, X
  sta $7300, X
  sta $7400, X
  sta $7500, X
  sta $7600, X
  sta $7700, X
  sta $7800, X
  sta $7900, X
  sta $7A00, X
  sta $7B00, X
  sta $7C00, X
  sta $7D00, X
  sta $7E00, X
  sta $7F00, X
  inx
  bne @clear_memory

; second wait for vblank, PPU is ready after this
@vblankwait2:
  bit PPUSTATUS
  bpl @vblankwait2

  MOVE PPUCTRL, #%10000000	; Enable NMI
  MOVE PPUMASK, #%00011110	; Enable rendering
  jmp main


nmi: 
  PUSH_AXY
  ; Lock the NMI, if the NMI takes too long then it will re-enter itself, 
  ; this will make it return immediately if that does happen.
  lda nmi_lock
  beq :+
    jmp @nmi_end
:
  MOVE nmi_lock, #1 

  ; Rendering logic
  ; Check what the NMI signal is
  lda nmi_signal 
  bne :+          ; If the signal is 0, that means the next frame isn't ready yet
    jmp @ppu_update_done
:
  cmp #PpuSignal::DisableRendering 
  bne :+
    MOVE PPUMASK, #%00000000 ; Disable rendering then exit NMI
    jmp @ppu_update_done
:

  ; Update the nametables with the buffered tile updates
  ldx #0
  cpx nt_update_len
  bcs @scroll
  
  @nt_update_loop: 
    MOVE PPUADDR, {nt_update, X} ; Write addr high byte
    inx
    MOVE PPUADDR, {nt_update, X} ; Write addr low byte
    inx
    MOVE PPUDATA, {nt_update, X} ; Write tile ID    
    inx
    ; while (x < nt_update_len)
    cpx nt_update_len
    bcc @nt_update_loop

  ; Clear the buffer
  MOVE nt_update_len, #0

@scroll:
  ora #(NMI_ENABLE | SPRITE_PT_RIGHT) ; Append other flags
  sta PPUCTRL
  lda PPUSTATUS ; Clear write latch
  lda #0        
  sta PPUSCROLL 
  sta PPUSCROLL
  MOVE PPUMASK, #(ENABLE_SPRITES | ENABLE_BG | SHOW_SPRITES_LEFT | SHOW_BG_LEFT) ; Enable rendering

@ppu_update_done:
  ; Done rendering, unlock NMI and acknowledge frame as complete
  lda #0
  sta nmi_lock
  sta nmi_signal

@nmi_end:
  POP_YXA
  rti

irq:
  rti

palette:
  ; Background Palette
  .byte $0f, $00, $10, $30
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

  ; Sprite Palette
  .byte $0f, $10, $20, $30
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

main:
  ldx #0
  MOVE PPUADDR, #$3F
  MOVE PPUADDR, #$00
@load_palettes:   ; Load all 32 bytes of palettes
  MOVE PPUDATA, {palette, X}
  inx
  cpx #32
  bne @load_palettes

  jmp run_part1

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

; ----------------
; Drawing routines
; ----------------
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
draw_string:
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

; Draw a string literal at immediate tile coordinates
.macro DRAW_STRING static_str, tile_x, tile_y
  MOVE ptr1,     #<static_str ; write low byte
  MOVE {ptr1+1}, #>static_str ; write high byte
  ldx #tile_x
  ldy #tile_y
  jsr draw_string
.endmacro

; --------------
; Input handling
; --------------
;
; I would use an enum for this, but 'A' is not allowed since
; it conflicts with register A...
BUTTON_RIGHT  = 1 << 0
BUTTON_LEFT   = 1 << 1
BUTTON_DOWN   = 1 << 2
BUTTON_UP     = 1 << 3
BUTTON_START  = 1 << 4
BUTTON_SELECT = 1 << 5
BUTTON_B      = 1 << 6
BUTTON_A      = 1 << 7

; Reads the input bitset of buttons from the controller.
; Stores it in `buttons` on the zeropage.
; Preserves: X, Y
.proc poll_input
  ; Turn strobe on and off to poll input state once
  lda #1
  sta CONTROLLER1
  sta buttons     ; Insert a bit here that will be shifted out into the carry after 8 reads to end the loop
  lda #0
  sta CONTROLLER1
  
@read_button:
  lda CONTROLLER1
  lsr a        ; bit 0 -> Carry
  rol buttons  ; Carry -> bit 0; bit 7 -> Carry
  bcc @read_button

  rts
.endproc

.macro IS_PRESSED btn
  lda buttons
  and #btn
.endmacro

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


str_loading_input: .asciiz "Loading input"
str_sorting_first: .asciiz "Sorting first.."
str_sorting_second: .asciiz "Sorting second.."
str_calculating: .asciiz "Calculating.."
str_answer: .asciiz "Answer:"

run_part1:
  jsr ppu_update

  jsr poll_input
  IS_PRESSED BUTTON_START
  bne @start
  jmp run_part1

@start:
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
answer_to_decimal:
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
