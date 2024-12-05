.include "symbols.s"
.include "macros.s"

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

.segment "VECTORS"
.addr nmi
.addr reset
.addr irq

.segment "ZEROPAGE"
nmi_lock:      .res 1 ; prevents NMI re-entry
nmi_count:     .res 1 ; is incremented every NMI
nmi_signal:    .res 1 ; set to 1 to push a PPU frame update, 2 to turn rendering off next NMI
nt_update_len: .res 1 ; number of bytes in nt_update buffer    
nt_update: .res 128; nametable update entry buffer for PPU update

.segment "OAM"
  oam: .res 256

.include "day01.s"
.include "ppu.s"

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

; place all sprites offscreen at Y=255
  lda #255
  ldx #0
@set_sprite:
  sta oam, X
  inx
  inx
  inx
  inx
  bne @set_sprite
; load default palette

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

  ; Otherwise the signal must've been PpuSignal::FrameRead
  ; Upload sprites via OAM DMA
  MOVE OAMADDR, #0
  MOVE OAMDMA, #>oam

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
  .byte $0f, $32, $22, $00
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

  jsr copy_input_to_ram

  LOAD16 ptr1, #<nums1, #>nums1
  jsr insertion_sort

@loop:
  jsr ppu_update
  jmp @loop
