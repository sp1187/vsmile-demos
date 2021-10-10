.include "spg2xx.inc"
.define color(r,g,b) ((r << 10) | (g << 5) | (b << 0))

.unsp
.low_address 0
.high_address 0x1ffff

.org 0x10

; allocate space for the tilemaps, which is stored in standard RAM
; put the tilemap somewhere other than 0 for test purposes
tilemap1:
.resw (512/64)*(256/64) ;64x64 sized tiles = 8*4 sized tilemap
tilemap1_end:
tilemap2:
.resw (512/64)*(256/64) ;64x64 sized tiles = 8*4 sized tilemap
tilemap2_end:

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

; set background scroll values
st r1, [PPU_BG1_SCROLL_X] ; scroll X offset of bg 1 = 0
st r1, [PPU_BG1_SCROLL_Y] ; scroll Y offset of bg 1 = 0
st r1, [PPU_BG2_SCROLL_X] ; scroll X offset of bg 2 = 0
st r1, [PPU_BG2_SCROLL_Y] ; scroll Y offset of bg 2 = 0

; set attribute config for bg 1
; bit 0-1: color depth (0 = 2-bit)
; bit 2: horizontal flip (0 = no flip)
; bit 3: vertical flip (0 = no flip)
; bit 4-5: X size (3 = 64 pixels)
; bit 6-7: Y size (3 = 64 pixels)
; bit 8-11: palette (0 = palette 0, colors 0-3 for 2-bit)
; bit 12-13: depth (0 = bottom layer)
ld r2, #0xf0
st r2, [PPU_BG1_ATTR] ; set attribute of bg 1

; set attribute config for bg 2
; bit 0-1: color depth (0 = 2-bit)
; bit 2: horizontal flip (0 = no flip)
; bit 3: vertical flip (0 = no flip)
; bit 4-5: X size (3 = 64 pixels)
; bit 6-7: Y size (3 = 64 pixels)
; bit 8-11: palette (1 = palette 1, colors 16-19 for 2-bit)
; bit 12-13: depth (3 = top layer)
or r2, #0x31f0
st r2, [PPU_BG2_ATTR]

; set control config for bg 1
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
st r2, [PPU_BG1_CTRL]

; set control config for bg 1
; bit 0: bitmap mode (0 = disable)
; bit 1: attribute map mode or register mode (1 = register mode)
; bit 2: wallpaper mode (0 = disable)
; bit 3: enable bg (1 = enable)
; bit 4: horizontal line-specific movement (0 = disable)
; bit 5: horizontal compression (0 = disable)
; bit 6: vertical compression (0 = disable)
; bit 7: 16-bit color mode (0 = disable)
; bit 8: blend (1 = enable)
ld r2, #0x10a
st r2, [PPU_BG2_CTRL]

st r1, [PPU_FADE_CTRL] ; clear fade control

ld r2, #1
st r2, [PPU_BLEND_LEVEL] ; set blend level to 50%

ld r2, #1
st r2, [PPU_SPRITE_CTRL] ; enable sprites

; clear bg 1 tile map
ld r2, #1
ld r3, #tilemap1
ld r4, #tilemap1_end
clear_tilemap1_loop:
st r2, [r3++]
cmp r3, r4
jb clear_tilemap1_loop

; clear bg 2 tile map
ld r2, #0
ld r3, #tilemap2
ld r4, #tilemap2_end
clear_tilemap2_loop:
st r2, [r3++]
cmp r3, r4
jb clear_tilemap2_loop

; clear sprite memory
ld r2, #0
ld r3, #PPU_SPRITE_MEM
ld r4, #PPU_SPRITE_MEM + 0x400
clear_sprite_loop:
st r2, [r3++]
cmp r3, r4
jb clear_sprite_loop

; set address of bg 1 tilemap
ld r2, #tilemap1
st r2, [PPU_BG1_TILE_ADDR]

; set address of bg 2 tilemap
ld r2, #tilemap2
st r2, [PPU_BG2_TILE_ADDR]

; set address of tile graphics data
; the register only stores the 16 most significant bits of a 22-bit address
; lowest 6 bits are expected to be zero, graphics therefore need to be 64-word aligned.
ld r2, #(graphics >> 6)
st r2, [PPU_BG1_SEGMENT_ADDR]
st r2, [PPU_BG2_SEGMENT_ADDR]
st r2, [PPU_SPRITE_SEGMENT_ADDR]

; set color 0 of palette 0
ld r2, #color(29,26,15)
st r2, [PPU_COLOR(0)]

;set color 0 of other palettes
ld r2, #0x8000
st r2, [PPU_COLOR(16)]
st r2, [PPU_COLOR(32)]
st r2, [PPU_COLOR(48)]
st r2, [PPU_COLOR(64)]

; set color 1 of palette 0 and 1
ld r2, #color(31,0,0)
st r2, [PPU_COLOR(1)]
st r2, [PPU_COLOR(17)]

; set color 2 of palette 0 and 1
ld r2, #color(0,0,31)
st r2, [PPU_COLOR(2)]
st r2, [PPU_COLOR(18)]

; set color 3 of palette 0+1
ld r2, #color(0,0,0)
st r2, [PPU_COLOR(3)]
st r2, [PPU_COLOR(19)]

; set color 1 of palette 2
ld r2, #color(0,31,0)
st r2, [PPU_COLOR(33)]

; set color 1 of palette 3
ld r2, #color(0,0,31)
st r2, [PPU_COLOR(49)]

; set color 1 of palette 4
ld r2, #color(31,31,31)
st r2, [PPU_COLOR(65)]

; write tile map contents

; the position of a specific tile can be calculated by:
; tilemap start address + (row * number of columns) + column
; where row and column values are 0-indexed
; number of columns is 512 / horizontal size
; number of rows is 256 / vertical size

; the start address of the tile to draw is determined by
; graphics start address + tile size in words * tile ID
; where tile size in words is calculated by:
; (vertical size * horizontal size * color depth in bits) / 16

ld r2, #2
st r2, [tilemap1+1] ; left red triangle
st r2, [tilemap1+3] ; right red triangle

ld r2, #3
st r2, [tilemap2+1] ; left blue triangle

ld r2, #4
st r2, [tilemap2+(8*1)+1] ; left black square
st r2, [tilemap1+(8*1)+2] ; middle black square

; set tile to use for sprites
ld r2, #3
st r2, [PPU_SPRITE_TILE(0)] ; right blue triangle
ld r2, #4
st r2, [PPU_SPRITE_TILE(1)] ; right black square
ld r2, #2
st r2, [PPU_SPRITE_TILE(2)]
st r2, [PPU_SPRITE_TILE(3)]
st r2, [PPU_SPRITE_TILE(4)]
st r2, [PPU_SPRITE_TILE(5)]

; set tile X positions
; note that the coordinates of a sprite refers to its center point
; with its coordinate system having screen position x=160, y=128 as its origin
; and higher Y values going upwards
ld r2, #64
st r2, [PPU_SPRITE_X(0)]
st r2, [PPU_SPRITE_X(1)]
ld r2, #-64
st r2, [PPU_SPRITE_X(2)]
ld r2, #-48
st r2, [PPU_SPRITE_X(3)]
ld r2, #-32
st r2, [PPU_SPRITE_X(4)]
ld r2, #-16
st r2, [PPU_SPRITE_X(5)]

; set tile Y positions
ld r2, #96
st r2, [PPU_SPRITE_Y(0)]
ld r2, #32
st r2, [PPU_SPRITE_Y(1)]
ld r2, #-32
st r2, [PPU_SPRITE_Y(2)]
st r2, [PPU_SPRITE_Y(3)]
st r2, [PPU_SPRITE_Y(4)]
st r2, [PPU_SPRITE_Y(5)]

; set attribute config for sprites
; bit 0-1: color depth (0 = 2-bit)
; bit 2: horizontal flip (0 = no flip)
; bit 3: vertical flip (0 = no flip)
; bit 4-5: X size (3 = 64 pixels)
; bit 6-7: Y size (3 = 64 pixels)
; bit 8-11: palette (1 = palette 1, colors 16-19 for 2-bit)
; bit 12-13: depth (3 = top layer)
; bit 14: blend (1 = enable)
ld r2, #0x71f0
st r2, [PPU_SPRITE_ATTR(0)]
st r2, [PPU_SPRITE_ATTR(1)]

; bottom triangle sprite attributes
; same as above but with different depths and palettes

; bit 8-11: palette (palette 1, colors 16-19 for 2-bit)
; bit 12-13: depth (0 = bottom layer)
ld r2, #0x41f0
st r2, [PPU_SPRITE_ATTR(2)]

; bit 8-11: palette (palette 2, colors 32-35 for 2-bit)
; bit 12-13: depth (1)
ld r2, #0x52f0
st r2, [PPU_SPRITE_ATTR(3)]

; bit 8-11: palette (palette 3, colors 48-51 for 2-bit)
; bit 12-13: depth (2)
ld r2, #0x63f0
st r2, [PPU_SPRITE_ATTR(4)]

; bit 8-11: palette (palette 4, colors 64-67 for 2-bit)
; bit 12-13: depth (3 = top layer)
ld r2, #0x74f0
st r2, [PPU_SPRITE_ATTR(5)]

; now done, run infinite loop
loop: jmp loop

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

; the graphics data needs to be 64-word aligned as mentioned earlier
.align_bits 64*16
graphics:
.binfile "blendgraphics.bin"
