.include "spg2xx.inc"
.define color(r,g,b) ((r << 10) | (g << 5) | (b << 0))

.unsp
.low_address 0
.high_address 0x1ffff

.org 0x10

; allocate space for the tilemap, which is stored in standard RAM
; put the tilemap somewhere other than 0 for test purposes
tilemap:
.resw (512/8)*(256/8) ;8x8 sized tiles = 64*32 sized tilemap
tilemap_end:

; put the program code in suitable ROM area
.org 0x8000
start:
int off ;turn off interrupts as soon as possible

ld r1, #0

; initialize system ctrl
st r1, [SYSTEM_CTRL]

; clear watchdog just to be safe
ld r2, #0x55aa
st r2, [WATCHDOG_CLEAR]

; initialize background scroll values
st r1, [PPU_BG1_SCROLL_X] ; scroll X offset of bg 1 = 0
st r1, [PPU_BG1_SCROLL_Y] ; scroll Y offset of bg 1 = 0

; initialize attribute config
; bit 0-1: color depth (0 = 2-bit)
; bit 2: horizontal flip (0 = no flip)
; bit 3: vertical flip (0 = no flip)
; bit 4-5: X size (0 = 8 pixels)
; bit 6-7: Y size (0 = 8 pixels)
; bit 8-11: palette (0 = palette 0, colors 0-3 for 2-bit)
; bit 12: depth (0 = deepest level)
st r1, [PPU_BG1_ATTR] ; set attribute of bg 1

; initialize control config for bg 1
; bit 0: bitmap mode (0 = disable)
; bit 1: attribute map mode or register mode (1 = register mode)
; bit 2: wallpaper mode (0 = disable)
; bit 3: enable bg (1 = enable)
; bit 4: horizontal line-specific movement (0 = disable)
; bit 5: horizontal compression (0 = disable)
; bit 6: vertical compression (0 = disable)
; bit 7: 16-bit color mode (0 = disable)
; bit 8: blend (0 = disable)
ld r2, #0x0a
st r2, [PPU_BG1_CTRL] ; enable bg1 in register mode

st r1, [PPU_BG2_CTRL] ; disable bg2 since bit 3 = 0

st r1, [PPU_FADE_CTRL] ; clear fade control

st r1, [PPU_SPRITE_CTRL] ; disable sprites

; initialize stack pointer to end of RAM space
ld sp, #0x27ff

; clear tile map
ld r2, #' ' ; ASCII space
ld r3, #tilemap
ld r4, #tilemap_end
clear_tilemap_loop:
st r2, [r3++]
cmp r3, r4
jb clear_tilemap_loop

 ;set address of bg 1 tilemap
ld r2, #tilemap
st r2, [PPU_BG1_TILE_ADDR]

; set address of tile graphics data
; the register only stores the 16 most significant bits of a 22-bit address
; lowest 6 bits are expected to be zero, graphics therefore need to be 64-word aligned.
ld r2, #(font >> 6)
st r2, [PPU_BG1_SEGMENT_ADDR]

; set color 0 of palette
ld r2, #color(29,26,15)
st r2, [PPU_COLOR(0)]

; set color 1 of palette
ld r2, #color(0,8,16)
st r2, [PPU_COLOR(1)]

; current palette also uses color 2 and 3
; though our graphics only use color 0-1

; write string into tilemap

; the position of a specific tile can be calculated by:
; tilemap start address + (row * number of columns) + column
; where row and column values are 0-indexed
; number of columns is 512 / horizontal size
; number of rows is 256 / vertical size

; start string in row 2, column 3
ld r3, #(tilemap + 64*2 + 3)

; the start address of the sprite to draw is determined by
; graphics start address + sprite size in words * tile ID
; where sprite size in words is calculated by:
; (vertical size * horizontal size * color depth in bits) / 16

ld r2, #'H' ; write some characters
st r2, [r3++]

ld r2, #'e'
st r2, [r3++]

ld r2, #'y'
st r2, [r3++]

ld r2, #'!'
st r2, [r3++]

ld r2, #' '
st r2, [r3++]

ld r2, #'V'
st r2, [r3++]

ld r2, #'.'
st r2, [r3++]

ld r2, #'S'
st r2, [r3++]

ld r2, #'m'
st r2, [r3++]

ld r2, #'i'
st r2, [r3++]

ld r2, #'l'
st r2, [r3++]

ld r2, #'e'
st r2, [r3++]

ld r2, #'!'
st r2, [r3++]

; now done, run infinite loop
loop: jmp loop

; configure interrupt vector
; we disabled interrupts, but still need to set the start address
.org 0xfff5
.dw 0 ;break
.dw 0 ;fiq
.dw start; reset
.dw 0 ;irq 0
.dw 0 ;irq 1
.dw 0 ;irq 2
.dw 0 ;irq 3
.dw 0 ;irq 4
.dw 0 ;irq 5
.dw 0 ;irq 6
.dw 0 ;irq 7

; the graphics data needs to be 64-word aligned as mentioned earlier
.align_bits 64*16
font:
.binfile "font.bin"
