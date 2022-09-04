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
	ld a, [wTempSpecies]
	ld [wCurSpecies], a
	call DisplayDexMonType
	call GetPokemonName
	hlcoord 9, 4
	call PlaceString ; mon species
	ld a, [wTempSpecies]
	ld b, a
	call GetDexEntryPointer
	ld a, b
	push af
	hlcoord 1, 9
	ld [hl], $3b
	inc hl
	inc hl
	call PlaceFarString ; dex species nickname
	ld h, b
	ld l, c
	push de

	hlcoord 12, 9
.check_tile
	ld a, [hld]
	cp $3c
	jr z, .print_dex_num
	cp $32
	jr z, .print_dex_num
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
	
	inc hl
	inc hl
	ld [hl], $3c
	hlcoord 19, 9
	; push hl
.check_tile2
	ld [hl], $32
	dec hl
	ld a, [hl]
	cp $3c
	jr nz, .check_tile2

.print_dex_num
; Print dex number
	hlcoord 9, 2
	ld a, $5c ; No
	ld [hli], a
	ld a, $5d ; .
	ld [hli], a
	push hl
	ld a, [wTempSpecies]
	call GetPokemonIndexFromID
	ld b, l
	ld c, h
	ld hl, sp + 0
	ld d, h
	ld e, l
	pop hl
	push bc
	lb bc, PRINTNUM_LEADINGZEROS | 2, 3
	call PrintNum
	pop bc
; Check to see if we caught it.  Get out of here if we haven't.
	ld a, [wTempSpecies]
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

	hlcoord 1, 8
	ld bc, 19
	ld a, $39 ; $55
	call ByteFill
	hlcoord 1, 10
	ld bc, 19
	ld a, $34 ; $55
	call ByteFill


; Page 1
	lb bc, 5, SCREEN_WIDTH - 2
	hlcoord 2, 11
	call ClearBox
	hlcoord 18, 10
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
	lb bc, 5, SCREEN_WIDTH - 2
	hlcoord 2, 11
	call ClearBox
	hlcoord 18, 10
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
	ld a, b
	call GetPokemonIndexFromID
	dec hl
	ld d, h
	ld e, l
	add hl, hl
	add hl, de
	ld de, PokedexDataPointerTable
	add hl, de
	ld a, [hli]
	ld b, a
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
Pokedex_setup_HLCoord: ; Y coord in b, X in c
	push bc
	ld hl, hMultiplicand
	ld a, 0
	ld [hli], a
	ld [hli], a
	ld a, b ;Y Coord in B, X in C
	ld [hl], a
	ld a, SCREEN_WIDTH
	ld [hMultiplier], a
	call Multiply
	ld hl, hProduct
	inc hl
	inc hl
	ld b, [hl]
	inc hl
	ld c, [hl]
	ld hl, wTilemap
	add hl, bc
	pop bc
	ld b, 0
	;ld c, ; X Coord thanks to popped bc
	add hl, bc
	;ld \1, (\3) * SCREEN_WIDTH + (\2) + wTilemap
	ret
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
	cp 0
	call nz, .Restart_loop
	ret
.Restart_loop:
	xor a
	ld [wPokedexPagePos1], a
	ld [wPokedexPagePos2], a
	ret
.print_page_num:
	ld a, [wPokedexPagePos1]
	hlcoord 1, 9
	call Pokedex_PrintPageNum
	ret

DisplayDexMonEvos:
	ret

DisplayDexMonType:
	call GetBaseData
; Print type b at hl.
	ld a, [wBaseType1]
	ld b, a
	ld a, [wBaseType2]
	cp b
	jr z, .SingleType
.DualType
	ld a, [wBaseType2]
	add a
	ld e, a
	ld d, 0
	ld a, BANK(TypeNames)
	ld hl, TypeNames
	add hl, de
	call GetFarWord
	ld d, h
	ld e, l
	hlcoord 10,7
	ld a, BANK(TypeNames)
	call FarPlaceString
.SingleType
	;ld a, b
	ld a, [wBaseType1]
	add a
	ld e, a
	ld d, 0
	ld a, BANK(TypeNames)
	ld hl, TypeNames
	add hl, de
	call GetFarWord
	ld d, h
	ld e, l
	hlcoord 10,6
	ld a, BANK(TypeNames)
	call FarPlaceString
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
	set 1, a
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
