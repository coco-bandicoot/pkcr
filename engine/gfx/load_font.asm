INCLUDE "gfx/font.asm"

EnableHDMAForGraphics:
	db FALSE

; Get1bppOptionalHDMA: ; unreferenced
; 	ld a, [EnableHDMAForGraphics]
; 	and a
; 	jp nz, Get1bppViaHDMA
; 	jp Get1bpp

; Get2bppOptionalHDMA: ; unreferenced
; 	ld a, [EnableHDMAForGraphics]
; 	and a
; 	jp nz, Get2bppViaHDMA
; 	jp Get2bpp

_LoadStandardFont::
	ld de, Font
	ld hl, vTiles1
	lb bc, BANK(Font), 128 ; "A" to "9"
	ldh a, [rLCDC]
	bit rLCDC_ENABLE, a
	jp z, Copy1bpp

	ld de, Font
	ld hl, vTiles1
	lb bc, BANK(Font), 32 ; "A" to "]"
	call Get1bppViaHDMA
	ld de, Font + 32 * LEN_1BPP_TILE
	ld hl, vTiles1 tile $20
	lb bc, BANK(Font), 32 ; "a" to $bf
	call Get1bppViaHDMA
	ld de, Font + 64 * LEN_1BPP_TILE
	ld hl, vTiles1 tile $40
	lb bc, BANK(Font), 32 ; "Ä" to "←"
	call Get1bppViaHDMA
	ld de, Font + 96 * LEN_1BPP_TILE
	ld hl, vTiles1 tile $60
	lb bc, BANK(Font), 32 ; "'" to "9"
	call Get1bppViaHDMA
	ret

_LoadFontsExtra1::
	ld de, FontsExtra_SolidBlackGFX
	ld hl, vTiles2 tile "■" ; $60
	lb bc, BANK(FontsExtra_SolidBlackGFX), 1
	call Get1bppViaHDMA
	ld de, PokegearPhoneIconGFX
	ld hl, vTiles2 tile "☎" ; $62
	lb bc, BANK(PokegearPhoneIconGFX), 1
	call Get2bppViaHDMA
	ld de, FontExtra + 9 tiles ; "<BOLD_V>"
	ld hl, vTiles2 tile "<BOLD_V>"
	lb bc, BANK(FontExtra), 16 ; "<BOLD_V>" and "<BOLD_S>"
	call Get2bppViaHDMA
	jr LoadFrame

_LoadFontsExtra2::
	ld de, FontsExtra2_UpArrowGFX
	ld hl, vTiles2 tile "▲" ; $61
	ld b, BANK(FontsExtra2_UpArrowGFX)
	ld c, 1
	call Get2bppViaHDMA
	ret

_LoadFontsBattleExtra::
	ld de, FontBattleExtra
	ld hl, vTiles2 tile $60
	lb bc, BANK(FontBattleExtra), 16
	call Get2bppViaHDMA
	ld de, FontBattleExtra + 4 tiles
	ld hl, vTiles2 tile $74
	lb bc, BANK(FontBattleExtra), 12
	call Get2bppViaHDMA
	jr LoadFrame

LoadFrame:
	ld a, [wTextboxFrame]
	maskbits NUM_FRAMES
	ld bc, TEXTBOX_FRAME_TILES * LEN_1BPP_TILE
	ld hl, Frames
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, vTiles2 tile "┌" ; $79
	lb bc, BANK(Frames), TEXTBOX_FRAME_TILES ; "┌" to "┘"
	call Get1bppViaHDMA
	ld hl, vTiles2 tile " " ; $7f
	ld de, TextboxSpaceGFX
	lb bc, BANK(TextboxSpaceGFX), 1
	call Get1bppViaHDMA
	ret

LoadBattleFontsHPBar:
	ld de, FontBattleExtra
	ld hl, vTiles2 tile $60
	lb bc, BANK(FontBattleExtra), 12
	call Get2bppViaHDMA
	; ld hl, vTiles2 tile $70
	; ld de, FontBattleExtra + 16 tiles ; "<DO>"
	; lb bc, BANK(FontBattleExtra), 3 ; "<DO>" to "『"
	; call Get2bppViaHDMA
	call LoadFrame

LoadHPBar:
	ld de, EnemyHPBarBorderGFX
	ld hl, vTiles2 tile $6c
	lb bc, BANK(EnemyHPBarBorderGFX), 4
	call Get1bppViaHDMA
	ld de, HPExpBarBorderGFX + 8;+ 1 tiles
	ld hl, vTiles2 tile $74
	lb bc, BANK(HPExpBarBorderGFX), 5
	call Get1bppViaHDMA
	ld de, ExpBarGFX
	ld hl, vTiles2 tile $55
	lb bc, BANK(ExpBarGFX), 9
	call Get2bppViaHDMA
; genders
	ld de, StatsScreenPageTilesGFX + 1 tiles
	ld hl, vTiles2 tile $5e
	lb bc, BANK(StatsScreenPageTilesGFX), 2 ; 17
	call Get2bppViaHDMA
; shiny
	ld de, StatsScreenPageTilesGFX + 14 tiles
	ld hl, vTiles2 tile $5b
	lb bc, BANK(StatsScreenPageTilesGFX), 1 ; 17
	call Get2bppViaHDMA
; Bold PP
	ld de, StatsScreenPageTilesGFX + 13 tiles
	ld hl, vTiles2 tile $76
	lb bc, BANK(StatsScreenPageTilesGFX), 1 ; 17
	call Get2bppViaHDMA
	ret

StatsScreen_LoadFont:
	call _LoadFontsBattleExtra
	ld de, EnemyHPBarBorderGFX
	ld hl, vTiles2 tile $6c
	lb bc, BANK(EnemyHPBarBorderGFX), 4
	call Get1bppViaHDMA
	ld de, HPExpBarBorderGFX
	ld hl, vTiles2 tile $78
	lb bc, BANK(HPExpBarBorderGFX), 1
	call Get1bppViaHDMA
	ld de, HPExpBarBorderGFX + 3 * LEN_1BPP_TILE
	ld hl, vTiles2 tile $76
	lb bc, BANK(HPExpBarBorderGFX), 2
	call Get1bppViaHDMA
	ld de, ExpBarGFX
	ld hl, vTiles2 tile $55
	lb bc, BANK(ExpBarGFX), 8
	call Get2bppViaHDMA
	ld de, FontBattleExtra + 17 tiles
	ld hl, vTiles2 tile $71
	lb bc, BANK(FontBattleExtra), 4
	call Get2bppViaHDMA
LoadStatsScreenPageTilesGFX:
	ld de, StatsScreenPageTilesGFX
	ld hl, vTiles2 tile $31
	lb bc, BANK(StatsScreenPageTilesGFX), 27 ; 17
	call Get2bppViaHDMA
	ret
