.include "spg2xx.inc"
.define hi(addr) ((addr >> 16) & 0x3f)
.define lo(addr) (addr & 0xffff)

.unsp
.low_address 0
.high_address 0x1ffff

tmp1: .resw 1 ; temporary (global) variable used in loop

.org 0x10

; allocate space for tile and attribute maps, which are stored in standard RAM
; the low part of the bitmap address of each line is stored in the tile map
; the high part of the bitmap address of each line is stored in the attribute map
; each word in the attribute map store data for two lines, one in each half
tilemap:
.resw 240
tilemap_end:
attrmap:
.resw 240/2
attrmap_end:

; put the program code in suitable ROM area
.org 0x8000
start:
int off ; turn off interrupts as soon as possible

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
; bit 0-1: color depth (3 = 8-bit)
; bit 2: horizontal flip (0 = no flip)
; bit 3: vertical flip (0 = no flip)
; bit 4-5: X size (0 = 8 pixels)
; bit 6-7: Y size (0 = 8 pixels)
; bit 8-11: palette (0 = palette 0, colors 0-3 for 2-bit)
; bit 12: depth (0 = deepest level)
ld r2, #0x03
st r2, [PPU_BG1_ATTR] ; set attribute of bg 1

; initialize control config for bg 1
; bit 0: bitmap mode (1 = enable)
; bit 1: attribute map mode or register mode (0 = map mode)
; bit 2: wallpaper mode (0 = disable)
; bit 3: enable bg (1 = enable)
; bit 4: horizontal line-specific movement (0 = disable)
; bit 5: horizontal compression (0 = disable)
; bit 6: vertical compression (0 = disable)
; bit 7: 16-bit color mode (0 = disable)
; bit 8: blend (0 = disable)
ld r2, #0x09
st r2, [PPU_BG1_CTRL] ; enable bg1 in register mode

st r1, [PPU_BG2_CTRL] ; disable bg2 since bit 3 = 0

st r1, [PPU_FADE_CTRL] ; clear fade control

st r1, [PPU_SPRITE_CTRL] ; disable sprites

ld r1, #lo(image) ; low part of line address
ld r2, #hi(image) ; high part of line address

ld r3, #tilemap
ld r4, #attrmap

; configure the tile and attribute maps
configure_bitmap_loop:
st r1, [r3++] ; set low part of address for odd line
st r2, [tmp1] ; save high part of address for later

; update line address for next line
add r1, #160
adc r2, #0 ; add 1 to high part if low part overflows

st r1, [r3++] ; set low part of address for even line

ld r5, r2 lsl 4
ld r5, r5 lsl 4
or r5, [tmp1]
st r5, [r4++] ; set high part of address for a pair of lines

; update line address for next line
add r1, #160
adc r2, #0

cmp r3, #tilemap_end
jb configure_bitmap_loop

; copy palette into palette memory
ld r2, #PPU_COLOR_MEM
ld r3, #palette
ld r4, #(palette_end - palette)
copy_palette_loop:
ld r1, [r3++]
st r1, [r2++]
sub r4, #1
jne copy_palette_loop

; set address of bg 1 tilemap
ld r2, #tilemap
st r2, [PPU_BG1_TILE_ADDR]

; set address of bg 1 attrmap
ld r2, #attrmap
st r2, [PPU_BG1_ATTR_ADDR]

; now done, run infinite loop
loop: jmp loop

palette:
.binfile "palette_8bit.bin"
palette_end:

; configure interrupt vector
; we disabled interrupts, but still need to set the start address
.org 0xfff5
.dw 0 ;break
.dw 0 ;fiq
.dw start ;reset
.dw 0 ;irq 0
.dw 0 ;irq 1
.dw 0 ;irq 2
.dw 0 ;irq 3
.dw 0 ;irq 4
.dw 0 ;irq 5
.dw 0 ;irq 6
.dw 0 ;irq 7

image:
.binfile "image_8bit.bin"


