DisplayDexMonEvos:
; print stage 1 first, then sus out how many evos it has
; zero out the counters/flags 
	xor a
	ld [wStatsScreenFlags], a
	ld [wPokedexEvoStage2], a
	ld [wPokedexEvoStage3], a

	call DisableSpriteUpdates
	callfar InitPartyMenuPalettes
	callfar ClearSpriteAnims2

	farcall Pokedex_GetSelectedMon
	ld a, [wTempSpecies]
	ld [wCurPartySpecies], a
	ld [wCurSpecies], a
	callfar GetPreEvolution
	callfar GetPreEvolution
	ld a, [wCurPartySpecies]
	ld [wCurSpecies], a
	ld [wTempMonSpecies], a
;;;; loops?
.loop
	ld [wTempSpecies], a
	ld [wCurSpecies], a
	dec a
	ld b, 0
	ld c, a
	ld hl, EvosAttacksPointers
	add hl, bc
	add hl, bc
	ld a, BANK(EvosAttacksPointers)
	call GetFarWord
	ld a, BANK("Evolutions and Attacks")
	call GetFarByte ; if zero, no evos
	push hl ; rn pointing to 1st EevoAttkPtr byte
	push af
;;;; print info
	hlcoord 6, 2
	call EVO_adjusthlcoord
	; call DisplayDexMonType
	call GetPokemonName
	hlcoord 5, 1
	call EVO_adjusthlcoord
	call PlaceString ; mon species
	ld a, [wStatsScreenFlags]
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
	ld a, BANK("Evolutions and Attacks")
	call GetFarByte ; if zero, no evos
	ld b, a ; species
	ld a, [wStatsScreenFlags]
	inc a ; evo stage
	ld [wStatsScreenFlags], a
	ld a, b
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
	xor a
	ld [wStatsScreenFlags], a
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
	ld a, [wStatsScreenFlags]
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
	ld a, BANK("Evolutions and Attacks")
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
	db "LVL@"

EVO_item:
	push hl
	hlcoord 6, 4
	call EVO_adjusthlcoord
	ld de, .item_text
	call PlaceString ; mon species
	pop hl
	ld a, BANK("Evolutions and Attacks")
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
	ld a, BANK("Evolutions and Attacks")
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
	ld a, BANK("Evolutions and Attacks")
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
	push hl
	hlcoord 6, 4
	call EVO_adjusthlcoord
	ld de, .stats_text
	call PlaceString ; mon species
	pop hl
	ld a, BANK("Evolutions and Attacks")
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
	ld a, BANK("Evolutions and Attacks")
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
