AnimateDexSearchSlowpoke:
	ld hl, .FrameIDs
	ld b, 25
.loop
	ld a, [hli]

	; Wrap around
	cp $fe
	jr nz, .ok
	ld hl, .FrameIDs
	ld a, [hli]
.ok

	ld [wDexSearchSlowpokeFrame], a
	ld a, [hli]
	ld c, a
	push bc
	push hl
	call DoDexSearchSlowpokeFrame
	pop hl
	pop bc
	call DelayFrames
	dec b
	jr nz, .loop
	xor a
	ld [wDexSearchSlowpokeFrame], a
	call DoDexSearchSlowpokeFrame
	ld c, 32
	call DelayFrames
	ret

.FrameIDs:
	; frame ID, duration
	db 0, 7
	db 1, 7
	db 2, 7
	db 3, 7
	db 4, 7
	db -2

DoDexSearchSlowpokeFrame:
	ld a, [wDexSearchSlowpokeFrame]
	ld hl, .SlowpokeSpriteData
	ld de, wShadowOAMSprite00
.loop
	ld a, [hli]
	cp -1
	ret z
	ld [de], a ; y
	inc de
	ld a, [hli]
	ld [de], a ; x
	inc de
	ld a, [wDexSearchSlowpokeFrame]
	ld b, a
	add a
	add b
	add [hl]
	inc hl
	ld [de], a ; tile id
	inc de
	ld a, [hli]
	ld [de], a ; attributes
	inc de
	jr .loop

.SlowpokeSpriteData:
	dbsprite  9, 11, 0, 0, $00, 0
	dbsprite 10, 11, 0, 0, $01, 0
	dbsprite 11, 11, 0, 0, $02, 0
	dbsprite  9, 12, 0, 0, $10, 0
	dbsprite 10, 12, 0, 0, $11, 0
	dbsprite 11, 12, 0, 0, $12, 0
	dbsprite  9, 13, 0, 0, $20, 0
	dbsprite 10, 13, 0, 0, $21, 0
	dbsprite 11, 13, 0, 0, $22, 0
	db -1

DisplayDexEntry:
	call Dex_PrintMonTypeTiles

	lb bc, 8, SCREEN_WIDTH - 1
	hlcoord 1, 8
	call ClearBox
	ld a, [wTempSpecies]
	ld [wCurSpecies], a

	call GetPokemonName
	hlcoord 9, 4
	call PlaceString ; mon species
	ld a, [wTempSpecies]
	ld b, a
	call GetDexEntryPointer
	ld a, b
	push af
	hlcoord 3, 9
	call PlaceFarString ; dex species nickname
	hlcoord 1, 8
	ld bc, 19
	ld a, $55
	call ByteFill
	
	ld h, b
	ld l, c
	push de
	hlcoord 12, 9
.check_tile
	ld a, [hld]
	cp $e2
	jr z, .print_dex_num
	cp $7f ; empty tile
	jr z, .check_tile
	
	inc hl
	inc hl
	ld [hl], " "
	inc hl
	ld [hl], $e1
	inc hl
	ld [hl], $e2 

.print_dex_num
; Print dex number
	hlcoord 9, 2
	ld a, $5c ; No
	ld [hli], a
	ld a, $5d ; .
	ld [hli], a
	ld de, wTempSpecies
	lb bc, PRINTNUM_LEADINGZEROS | 1, 3
	call PrintNum
; Check to see if we caught it.  Get out of here if we haven't.
	ld a, [wTempSpecies]
	dec a
	call CheckCaughtMon
	pop hl
	pop bc
	ret z
; Get the height of the Pokemon.
	ld a, [wCurPartySpecies]
	ld [wCurSpecies], a
	inc hl
	ld a, b

	push af
	inc hl
	inc hl
	inc hl
	push hl

; Page 1
	hlcoord 1, 8
	ld [hl], $56 ; P.
	inc hl
	ld [hl], $57 ; 1
	pop de
	inc de
	pop af
	hlcoord 2, 11
	push af
	call PlaceFarString
	pop bc
	ld a, [wPokedexStatus]
	or a ; check for page 2
	ret z

; Page 2
	push bc
	push de

	hlcoord 1, 8
	ld [hl], $56 ; P.
	inc hl
	ld [hl], $58 ; 2
	pop de
	inc de
	pop af
	hlcoord 2, 11
	call PlaceFarString
	ret

POKeString: ; unreferenced
	db "#@"

GetDexEntryPointer:
; return dex entry pointer b:de
	push hl
	ld hl, PokedexDataPointerTable
	ld a, b
	dec a
	ld d, 0
	ld e, a
	add hl, de
	add hl, de
	add hl, de
	; b = bank
	ld a, [hli]
	ld b, a
	; de = address
	ld a, [hli]
	ld e, a
	ld d, [hl]
	pop hl
	ret

GetDexEntryPagePointer:
	call GetDexEntryPointer
	push hl
	ld h, d
	ld l, e
; skip species name
.loop1
	ld a, b
	call GetFarByte
	inc hl
	cp "@"
	jr nz, .loop1
; skip height and weight
rept 4
	inc hl
endr
; if c != 1: skip entry
	dec c
	jr z, .done
; skip entry
.loop2
	ld a, b
	call GetFarByte
	inc hl
	cp "@"
	jr nz, .loop2

.done
	ld d, h
	ld e, l
	pop hl
	ret

INCLUDE "data/pokemon/dex_entry_pointers.asm"

Pokedex_Clearbox:
	;clear Area BC @ HL
	lb bc, 6, SCREEN_WIDTH - 1
	hlcoord 1, 10
	call ClearBox
	ret
Pokedex_PrintPageNum:
	and %00001111
	; a = page num
	push bc
	push hl
	ld b, 0
	ld c, a
	ld hl, .PgNumPtrs
	add hl, bc
	ld a, [hl]
	pop hl
	ld [hl], $56
	inc hl 
	ld [hl], a
	pop bc
	ret
.PgNumPtrs
	db $57, $58, $61, $62, $63, $64, $65, $6B, $6C

DisplayDexMonStats:
	ret

DisplayDexMonMoves:
	ld a, [wTempSpecies]
	ld [wCurSpecies], a

; Step 1 ClearBox, Page Num
	call Pokedex_Clearbox
	ld a, [wPokedexPagePos2]
	cp 0
	jr z, .LvlUpLearnset
	; cp 1
	; jr z, .EggMoves
	jr .Done
.LvlUpLearnset
	call .print_page_num
	call Pokedex_Calc_LvlMovesPtr
	call Pokedex_Print_NextLvlMoves
.Done
	; We want to reset the Dex Entry back to 1 when we click "Page"
	ld a, 1
	ld [wPokedexStatus], a
	ld a, [wPokedexPagePos2]
	bit 7, a
	call nz, .Restart_loop
	ret
.Restart_loop:
	xor a
	ld [wPokedexPagePos1], a
	ld [wPokedexPagePos2], a
	ret
.print_page_num:
	ld a, [wPokedexPagePos1]
	hlcoord 1, 8
	call Pokedex_PrintPageNum
	ret

DisplayDexMonType:
	push hl
	call GetBaseData
	ld a, [wBaseType1]
; Skip Bird
	cp BIRD
	jr c, .type1_adjust_done
	cp UNUSED_TYPES
	dec a
	jr c, .type1_adjust_done
	sub UNUSED_TYPES
.type1_adjust_done
; ; load the 1st type pal 
; 	ld c, a
; 	ld de, wBGPals1 palette 7 + 2
; 	push af
; 	farcall LoadMonBaseTypePal	
; 	pop af
; load the tiles
	ld hl, TypeLightIconGFX
	ld bc, 4 * LEN_2BPP_TILE
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, vTiles2 tile $70
	lb bc, BANK(TypeLightIconGFX), 4
	call Request2bpp
; 2nd Type
	ld a, [wBaseType2]
; Skip Bird
	cp BIRD
	jr c, .type2_adjust_done
	cp UNUSED_TYPES
	dec a
	jr c, .type2_adjust_done
	sub UNUSED_TYPES
.type2_adjust_done
; ; load the 2nd type pal 
; 	ld c, a
; 	ld de, wBGPals1 palette 7 + 4
; 	push af
; 	farcall LoadMonBaseTypePal	
; 	pop af
; load type 2 tiles
	ld hl, TypeDarkIconGFX
	ld bc, 4 * LEN_2BPP_TILE
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, vTiles2 tile $74
	lb bc, BANK(TypeDarkIconGFX), 4
	call Request2bpp

	; call SetPalettes
	hlcoord 9, 1
	; push hl
	ld [hl], $70
	inc hl
	ld [hl], $71
	inc hl
	ld [hl], $72
	inc hl
	ld [hl], $73
	inc hl
	ld a, [wBaseType1]
	ld b, a
	ld a, [wBaseType2]
	; pop hl
	cp b
	ret z
	; ld bc, 20
	; add hl, bc
	ld [hl], $74
	inc hl
	ld [hl], $75
	inc hl
	ld [hl], $76
	inc hl
	ld [hl], $77
	ret

Pokedex_Calc_LvlMovesPtr:
	ld a, [wTempSpecies]
	call GetPokemonIndexFromID
	ld b, h
	ld c, l
	ld hl, EvosAttacksPointers
	ld a, BANK(EvosAttacksPointers)
	call LoadDoubleIndirectPointer
	ld [wStatsScreenFlags], a ; bank
	call FarSkipEvolutions
.CalcPageoffset
	ld a, [wPokedexPagePos1]
	ld c, 5
	call SimpleMultiply 
	; double this num and add to first byte after Evo's 0
	; for p16, triple the num
	ld b, 0
	ld c, a
	add hl, bc
	add hl, bc
	add hl, bc
	ret

Pokedex_Print_NextLvlMoves:
; Print No more than 5 moves
; check the next byte
; if 0, set Lvl Up Done flag, or zero out
; else, inc Page Counter wPokedexPagePos1 before exit
; Start at 1, 11
; LXX:@@
	ld b, 0
	ld c, 0 ; our move counter, max of 5
	push bc ; our move counter
	push hl ; our offset for the start of Moves
	ld de, .lvl_moves_text
	hlcoord 2, 10
	call PlaceString ; TEXT for 'LVL - Move'
	pop hl
	pop bc
.learnset_loop
	ld a, [wStatsScreenFlags]
	call GetFarByte
	cp 0
	jr z, .FoundEnd
	push hl
	ld [wTextDecimalByte], a
	hlcoord 1, 11
	call .adjusthlcoord
	ld de, wTextDecimalByte
	push bc
	; lb bc, PRINTNUM_LEFTALIGN | 1, 2
	lb bc, 1, 2
	call PrintNum
	pop bc 
	pop hl
	inc hl
	push hl
	ld a, [wStatsScreenFlags]
	call GetFarWord ; our move index
	
	call GetMoveIDFromIndex
	ld [wNamedObjectIndex], a
	call GetMoveName
	hlcoord 4, 11
	call .adjusthlcoord
	push bc
	call PlaceString
	pop bc
	pop hl
	inc hl
	inc hl
	inc bc
	ld a, 5
	cp c
	jr nz, .learnset_loop
	jr .MaxedPage

.FoundEnd ; Set the LvlUp Learnset DONE bit (5?)
	; DEBUG just zero-out to test effect
	ld a, [wPokedexPagePos2]
	;xor %00010000 ; setting the "egg" bit
	set 7, a
	ld [wPokedexPagePos2], a
.MaxedPage ; Printed 5 moves. Moves are still left. Inc the Page counter
	; Shouldn't NEED to, but added check to make sure doesnt go over 8 rn
	ld a, [wPokedexPagePos1]
	inc a
	ld [wPokedexPagePos1], a
	ret

.lvl_moves_text:
	db "LVL Move@"
.moveslvl_colon_Text:
	;db "<COLON> @"
	db ": @"	
.adjusthlcoord:
	push de
	ld a, 20
	; the num of moves already printed should still be in bc
	call SimpleMultiply
	; result in a
	ld d, 0
	ld e, a
	add hl, de ; allows us to print on the proper row lol
	pop de
	ret

EggMenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 7, 1, SCREEN_WIDTH - 1, TEXTBOX_Y - 1
	dw .MenuData
	db 1 ; default option

.MenuData:
	db STATICMENU_ENABLE_SELECT | STATICMENU_ENABLE_LEFT_RIGHT | STATICMENU_ENABLE_START | STATICMENU_WRAP | STATICMENU_CURSOR ; flags
	db 5, 8 ; rows, columns
	db SCROLLINGMENU_ITEMS_QUANTITY ; item format
	dbw 0, wNumItems
	dba PlaceMenuItemName
	dba PlaceMenuItemQuantity
	dba UpdateItemDescription

DisplayDexMonEvos:
	ld hl, wPokedexPagePos1
	ld [hl], 0 ; evo stage
	xor a
	ld [wPokedexPagePos1], a
	ld [wPokedexPagePos2], a
	call DisableSpriteUpdates
	callfar InitPartyMenuPalettes
	callfar ClearSpriteAnims2

	farcall Pokedex_GetSelectedMon
	ld a, [wTempSpecies]
	ld [wCurPartySpecies], a
	ld [wCurSpecies], a
	callfar GetLowestEvolutionStage
	ld a, [wCurPartySpecies]
	ld [wCurSpecies], a
	ld [wTempMonSpecies], a
	call GetPokemonIndexFromID
;;;; loops?
.loop
	ld b, h
	ld c, l
	call GetPokemonIDFromIndex
	ld [wTempSpecies], a
	ld [wCurSpecies], a
	ld hl, EvosAttacksPointers
	ld a, BANK(EvosAttacksPointers)
	call LoadDoubleIndirectPointer
	ld [wStatsScreenFlags], a ; bank
	call GetFarByte ; if zero, no evos
	push hl ; rn pointing to 1st EevoAttkPtr byte
	push af
;;;; print info
	hlcoord 6, 2
	call EVO_adjusthlcoord
	call DisplayDexMonType
	call GetPokemonName
	hlcoord 5, 1
	call EVO_adjusthlcoord
	call PlaceString ; mon species
	ld a, [wPokedexPagePos1]
	cp 2
	jr z, .stage3
	cp 1
	jr z, .stage2
.stage1
	ld de, .stage1_text
	jr .print_stage
.stage2
	ld de, .stage2_text
	jr .print_stage
.stage3
	ld de, .stage3_text
.print_stage	
	hlcoord 1, 0
	call EVO_adjusthlcoord
	call PlaceString ; mon species	
	pop af
	and a
	jr z, .evoline_done
	; get and print Evo method
	pop hl
	inc hl
	cp EVOLVE_LEVEL
	call z, EVO_level
	cp EVOLVE_ITEM
	call z, EVO_item
	cp EVOLVE_TRADE
	call z, EVO_trade
	cp EVOLVE_HAPPINESS
	call z, EVO_happiness
	cp EVOLVE_STAT
	call z, EVO_stats
	; cp EVOLVE_LOCATION ; TODO
.get_evo_species
	; hl points to species word
	ld a, [wStatsScreenFlags]
	call GetFarWord ; mon species index
	;call GetPokemonIDFromIndex
	ld a, [wPokedexPagePos1]
	inc a ; evo stage
	ld [wPokedexPagePos1], a
	jr .loop ; print next evo stage

;;;;;;;;;;;;;;;;;	
	; ld [wTempIconSpecies], a
	; ld e, MONICON_MOVES
	; farcall LoadMenuMonIcon
;;;;;;;;;;;;;;;;;
; 	ld hl, wPartyCount ; -> Evo Line Num
; 	ld a, [hli]
; 	and a
; 	ret z
; 	ld c, a
; 	xor a
; 	ldh [hObjectStructIndex], a
; .loop
; 	push bc
; 	push hl
; 	ld hl, LoadMenuMonIcon
; 	ld a, BANK(LoadMenuMonIcon)
; 	ld e, MONICON_PARTYMENU
; 	rst FarCall
; 	ldh a, [hObjectStructIndex]
; 	inc a
; 	ldh [hObjectStructIndex], a
; 	pop hl
; 	pop bc
; 	dec c
; 	jr nz, .loop
;;;;;;;;;;;;;;;;;
.evoline_done
	pop hl
.done
	call SetPalettes
	call WaitBGMap
	callfar PlaySpriteAnimations
	call DelayFrame
	ret

.stage1_text:
	db "STAGE 1:@"
.stage2_text:
	db "STAGE 2:@"
.stage3_text:
	db "STAGE 3:@"

EVO_adjusthlcoord:
	push af
	push bc
	push de
	ld a, [wPokedexPagePos1]
.loop
	cp 0
	jr z, .done
	ld b, 0
	ld c, 120
	add hl, bc
	dec a
	jr .loop
.done
	pop de
	pop bc
	pop af
	ret

EVO_level:
	push hl
	hlcoord 6, 4
	call EVO_adjusthlcoord
	ld de, .level_text
	call PlaceString ; mon species
	pop hl
	ld a, [wStatsScreenFlags]
	call GetFarByte
	push hl
	ld [wTextDecimalByte], a
	ld de, wTextDecimalByte
	lb bc, 1, 2
	hlcoord 12, 4
	call EVO_adjusthlcoord
	call PrintNum
	pop hl
	inc hl
	ret
.level_text:
	db "LEVEL@"

EVO_item:
	push hl
	hlcoord 6, 4
	call EVO_adjusthlcoord
	ld de, .item_text
	call PlaceString ; mon species
	pop hl
	ld a, [wStatsScreenFlags]
	call GetFarByte
	push hl
	ld [wNamedObjectIndex], a
	call GetItemName
	hlcoord 7, 5
	call EVO_adjusthlcoord
	call PlaceString
	pop hl
	inc hl
	ret
.item_text:
	db "ITEM:@"

EVO_trade:
	push hl
	hlcoord 6, 4
	call EVO_adjusthlcoord
	ld de, .trade_text
	call PlaceString ; mon species
	pop hl
	ld a, [wStatsScreenFlags]
	call GetFarByte
	cp -1
	jr z, .done
	ld [wNamedObjectIndex], a
	push hl
	hlcoord 12, 4
	call EVO_adjusthlcoord
	ld [hl], $e9
	hlcoord 14, 4
	call EVO_adjusthlcoord
	ld de, .hold_text
	call PlaceString
	call GetItemName
	hlcoord 6, 5
	call EVO_adjusthlcoord
	call PlaceString
	pop hl
.done	
	inc hl
	ret
.trade_text:
	db "TRADE@"
.hold_text:
	db "HOLD@"

EVO_happiness:
	push hl
	hlcoord 6, 4
	call EVO_adjusthlcoord
	ld de, .happiness_text
	call PlaceString ; mon species
	pop hl
	ld a, [wStatsScreenFlags]
	call GetFarByte
	inc hl
	push hl
	cp TR_ANYTIME
	jr z, .anytime
	cp TR_MORNDAY
	jr z, .mornday
	cp TR_NITE
	jr z, .nite
.done
	pop hl
	ret

.anytime
	hlcoord 6, 5
	call EVO_adjusthlcoord
	ld de, .anytime_text
	call PlaceString
	jr .done
.mornday
	hlcoord 6, 5
	call EVO_adjusthlcoord
	ld de, .sunup_text
	call PlaceString
	jr .done
.nite
	hlcoord 6, 5
	call EVO_adjusthlcoord
	ld de, .nite_text
	call PlaceString
	jr .done

.happiness_text:
	db "HAPPINESS@"
.anytime_text:
	db "ANYTIME@"
.sunup_text:
	db "MORN/DAY@"
.nite_text:
	db "NITE@"

EVO_stats:
;  ATK_EQ_DEF
;  ATK_GT_DEF
;  ATK_LT_DEF
	ld b,b
	push hl
	hlcoord 6, 4
	call EVO_adjusthlcoord
	ld de, .stats_text
	call PlaceString ; mon species
	pop hl
	ld a, [wStatsScreenFlags]
	call GetFarByte ; level
	inc hl
	push hl
	ld [wTextDecimalByte], a
	ld de, wTextDecimalByte
	lb bc, 1, 2
	hlcoord 12, 4
	call EVO_adjusthlcoord
	call PrintNum
	pop hl
	ld a, [wStatsScreenFlags]
	call GetFarByte ; Stats Const, ATK >= DEF etc
	inc hl
	push hl
	cp ATK_EQ_DEF
	jr z, .atk_eq_def
	cp ATK_LT_DEF
	jr z, .atk_lt_def
	cp ATK_GT_DEF
	jr z, .atk_gt_def
.done
	hlcoord 7, 5
	call EVO_adjusthlcoord
	call PlaceString
	pop hl
	ret

.atk_eq_def
	ld de, .atk_eq_def_text
	jr .done
.atk_gt_def
	ld de, .atk_gt_def_text
	jr .done
.atk_lt_def
	ld de, .atk_lt_def_text
	jr .done

.stats_text:
	db "LVL UP TO@"
.atk_eq_def_text:
	db "& ATK = DEF@"
.atk_gt_def_text:
	db "& ATK > DEF@"
.atk_lt_def_text:
	db "& ATK < DEF@"
