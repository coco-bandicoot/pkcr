	const_def
	const DEXENTRY_LORE      ; bit 0, $1
	const DEXENTRY_BASESTATS ; bit 1, $2
	const DEXENTRY_LVLUP     ; bit 2, $4
	const DEXENTRY_FIELD     ; bit 3, $8
	const DEXENTRY_EGG		 ; bit 4, $10, 16
	const DEXENTRY_TMS       ; bit 5, $20, 32
	; const DEXENTRY_HMS       ; bit 6, $40, 64
	const DEXENTRY_MTS       ; bit 7, $80, 128

EXPORT DEXENTRY_LORE
EXPORT DEXENTRY_BASESTATS
EXPORT DEXENTRY_LVLUP
EXPORT DEXENTRY_FIELD
EXPORT DEXENTRY_EGG
EXPORT DEXENTRY_TMS
; EXPORT DEXENTRY_HMS
EXPORT DEXENTRY_MTS

DEF NUM_FIELD_MOVES EQU 14 
DEF MOVESPAGES_CONT_MASK EQU %00000011

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

HandlePageNumReset:
	ld b, a
	ld a, [wPokedexEntryType]
	cp b
	ret z
	ld a, b
	ld [wPokedexEntryType], a
	xor a
	ld [wPokedexEntryPageNum], a
	ret

DisplayDexEntry:
; Check to see if we caught it.  Get out of here if we haven't.
	ld a, [wTempSpecies]
	dec a
	call CheckCaughtMon
	ret z

	ld a, 1 << DEXENTRY_LORE
	call HandlePageNumReset

	lb bc, 8, SCREEN_WIDTH - 1
	hlcoord 1, 8
	call ClearBox

	hlcoord 1, 8
	ld bc, 19
	ld a, $55
	call ByteFill

	ld a, [wTempSpecies]
	ld b, a
	call GetDexEntryPointer
	ld a, b
	push af
	hlcoord 2, 9
	call PlaceFarString ; dex species nickname
	ld h, b
	ld l, c
	push de
	hlcoord 12, 9
.check_tile
	; this prints the "PKMN" symbols after the species nickname
	ld a, [hld]
	cp $e2
	jr z, .cont
	cp $7f ; empty tile
	jr z, .check_tile
	inc hl
	inc hl
	ld [hl], " "
	inc hl
	ld [hl], $e1
	inc hl
	ld [hl], $e2 
.cont
	pop hl
	pop bc
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
	ld a, [wPokedexEntryPageNum]
	and a ; check for page 2
	jr nz, .page2
; Page 1
	call Pokedex_PrintPageNum
	pop de
	inc de
	pop af
	hlcoord 2, 11
	push af
	call PlaceFarString
	pop bc
	call DexEntry_IncPageNum
	ret

; Page 2
.page2
	pop de
	inc de
	pop af
	hlcoord 2, 11
	push af
	call PlaceFarString
	pop bc
	push bc
	push de
	lb bc, 5, SCREEN_WIDTH - 1
	hlcoord 1, 11
	call ClearBox
	hlcoord 1, 8
	ld bc, 19
	ld a, $55
	call ByteFill
	call Pokedex_PrintPageNum
	pop de
	inc de
	pop af
	hlcoord 2, 11
	call PlaceFarString
	xor a
	ld [wPokedexEntryPageNum], a
	ret

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
	;dec c
	and c
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

DisplayDexMonType:
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
; load the tiles
	ld hl, TypeLightIconGFX
	ld bc, 4 * LEN_2BPP_TILE
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, vTiles2 tile $47
	lb bc, BANK(TypeLightIconGFX), 4
	call Request2bpp
	hlcoord 9, 6
	ld [hl], $47
	inc hl
	ld [hl], $48
	inc hl
	ld [hl], $49
	inc hl
	ld [hl], $4a
; 2nd Type
	ld a, [wBaseType1]
	ld b, a
	ld a, [wBaseType2]
	cp b
	ret z
; Skip Bird
	cp BIRD
	jr c, .type2_adjust_done
	cp UNUSED_TYPES
	dec a
	jr c, .type2_adjust_done
	sub UNUSED_TYPES
.type2_adjust_done
; load type 2 tiles
	ld hl, TypeDarkIconGFX
	ld bc, 4 * LEN_2BPP_TILE
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, vTiles2 tile $4b
	lb bc, BANK(TypeDarkIconGFX), 4
	call Request2bpp

	hlcoord 13, 6
	ld [hl], $4b
	inc hl
	ld [hl], $4c
	inc hl
	ld [hl], $4d
	inc hl
	ld [hl], $4e
	ret

INCLUDE "data/pokemon/dex_entry_pointers.asm"
INCLUDE "engine/pokedex/pokedex_evolution_page.asm"
INCLUDE "engine/pokedex/pokedex_stats_page.asm"

Pokedex_Clearbox:
	;clear Area BC @ HL
	lb bc, 7, SCREEN_WIDTH - 1
	hlcoord 1, 9
	call ClearBox
	ret

DexEntry_adjusthlcoord:
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

DexEntry_IncPageNum:
	ld a, [wPokedexEntryPageNum]
	inc a
	ld [wPokedexEntryPageNum], a
	ret

Pokedex_PrintPageNum:
	push hl
	push de
	ld a, [wPokedexEntryPageNum]
.print
	; a = page num
	push bc
	ld b, 0
	ld c, a
	ld hl, .PgNumPtrs
	add hl, bc
	ld a, [hl]
	hlcoord 18, 8
	ld [hl], $56
	inc hl 
	ld [hl], a
	pop bc
	pop de
	pop hl
	ld a, [wPokedexEntryPageNum]
	ret
.PgNumPtrs
	db $57, $58, $61, $62, $63, $64, $65, $6B, $6C

DexEntry_NextCategory:
	ld [wPokedexEntryType], a
	xor a
	ld [wPokedexEntryPageNum], a
	ld [wPokedexStatus], a
	ret

DexEntry_NONE_text:
	db "NONE@"

DisplayDexMonStats::
	ld a, [wTempSpecies]
	ld [wCurSpecies], a

	ld a, 1 << DEXENTRY_BASESTATS
	call HandlePageNumReset

	call Pokedex_Clearbox
	ld de, .Base_stats_text
	hlcoord 2, 9
	call PlaceString
	call Pokedex_PrintPageNum ; page num is also returned in a
	and a
	jr z, .print_page1
	cp 1
	jr z, .print_page2
	cp 2
	jr z, .print_page3
	jr .print_page4
.print_page1
	call Pokedex_GBS_Stats ; 4 lines
	call Pokedex_CatchRate ; 1 line
	jp DexEntry_IncPageNum
.print_page2
	call Pokedex_PrintBaseEVs ; 4 lines
	call Pokedex_PrintBaseExp ; 1 line
	call Pokedex_Get_Growth ; 1 lines
	jp DexEntry_IncPageNum
.print_page3
	; these ones NEED to be in this order
	call Pokedex_HeightWeight ; 2 lines
	call Pokedex_Get_Items ; 3 lines
	jp DexEntry_IncPageNum
.print_page4
	call Pokedex_EggG_SetUp ; 3 lines
	call Pokedex_PrintHatchSteps ; 1 line
	call Pokedex_Get_GenderRatio ; 1 line
	xor a
	ld [wPokedexEntryPageNum], a
	ret
.Base_stats_text:
	db "BASE STATS@"

DisplayDexMonMoves::
	ld a, [wTempSpecies]
	ld [wCurSpecies], a
	ld [wCurPartySpecies], a
	call Pokedex_Clearbox

	; the byte flag that tells us which type of table we're currently on
	; 0 = Info, 1 = Stats, 2 = LVL UP, 3 = FIELD, 4 =  EGG, 5 = TMs, 6 = HMs, 7 = MTs

	ld a, [wPokedexEntryType] 
	and MOVESPAGES_CONT_MASK
	; if we had just been printing lore or basestats, start with lvlup moves
	jr nz, .LvlUpLearnset_new
	
	ld a, [wPokedexEntryType]
	bit DEXENTRY_LVLUP, a
	jr nz, .LvlUpLearnset
	ld a, [wPokedexEntryType]
	bit DEXENTRY_EGG, a
	jr nz, .EggMoves
	bit DEXENTRY_FIELD, a
	jr nz, .Field_Moves
	bit DEXENTRY_TMS, a
	jr nz, .TMs
	; bit DEXENTRY_HMS, a
	; jr nz, .HMs
	bit DEXENTRY_MTS, a
	jr nz, .MTs
.LvlUpLearnset_new
	ld a, 1 << DEXENTRY_LVLUP
	call DexEntry_NextCategory
.LvlUpLearnset
	ld a, 1 << DEXENTRY_LVLUP
	ld [wPokedexEntryType], a
	call Pokedex_Calc_LvlMovesPtr
	call Pokedex_Print_NextLvlMoves
	ret
.EggMoves
	ld a, 1 << DEXENTRY_EGG
	ld [wPokedexEntryType], a
	call Pokedex_Calc_EggMovesPtr
	ret z
	call Pokedex_Print_Egg_moves
	ret
.Field_Moves
	ld a, 1 << DEXENTRY_FIELD
	ld [wPokedexEntryType], a

	call Pokedex_PrintFieldMoves
	ret
.TMs
	ld a, 1 << DEXENTRY_TMS
	ld [wPokedexEntryType], a
	call Pokedex_PrintTMs
	ret
; .HMs
; 	ld a, 1 << DEXENTRY_HMS
; 	ld [wPokedexEntryType], a
; 	call Pokedex_PrintHMs
; 	ret
.MTs
	ld a, 1 << DEXENTRY_MTS
	ld [wPokedexEntryType], a
	call Pokedex_PrintMTs
	ret

Pokedex_Calc_LvlMovesPtr:
	ld a, [wTempSpecies]
	dec a
	ld b, 0
	ld c, a
	ld hl, EvosAttacksPointers
	add hl, bc
	add hl, bc
	ld a, BANK(EvosAttacksPointers)
	call GetFarWord
.SkipEvoBytes	
	ld a, BANK("Evolutions and Attacks")
	call GetFarByte
	inc hl
	and a ; cp 0
	jr nz, .SkipEvoBytes
.CalcPageoffset
	call Pokedex_PrintPageNum ; page num is also returned in a
	ld c, 6
	call SimpleMultiply 
	; double this num and add to first byte after Evo's 0
	; for p16, triple the num
	ld b, 0
	ld c, a
	add hl, bc
	add hl, bc
	; add hl, bc
	ret

Pokedex_Print_NextLvlMoves:
; Print No more than 5 moves
	ld b, 0
	ld c, 0 ; our move counter, max of 5
	push bc ; our move counter
	push hl ; our offset for the start of Moves
	ld de, .lvl_moves_text
	hlcoord 1, 9
	call PlaceString ; TEXT for 'LVL - Move'
	pop hl
	pop bc
.learnset_loop
	ld a, BANK("Evolutions and Attacks")
	call GetFarByte
	and a
	jr z, .FoundEnd
	push hl
	ld [wTextDecimalByte], a
	hlcoord 2, 10
	call DexEntry_adjusthlcoord
	ld [hl], $5d
	hlcoord 3, 10
	call DexEntry_adjusthlcoord
	ld de, wTextDecimalByte
	push bc
	lb bc, PRINTNUM_LEFTALIGN | 1, 2
	call PrintNum
	pop bc 
	pop hl
	inc hl
	push hl
	ld a, BANK("Evolutions and Attacks")
	call GetFarByte
	ld [wNamedObjectIndex], a
	call GetMoveName
	hlcoord 7, 10
	call DexEntry_adjusthlcoord
	push bc
	call PlaceString
	pop bc
	pop hl
	inc hl
	inc bc
	ld a, 6
	cp c
	jr nz, .learnset_loop
	jr .MaxedPage
.MaxedPage ; Printed 5 moves. Moves are still left. Inc the Page counter
	; check to see if really any moves left, we dont want a blank page
	ld a, BANK("Evolutions and Attacks")
	call GetFarByte
	and a
	jr z, .FoundEnd
	call DexEntry_IncPageNum
	ret
.FoundEnd
	ld a, 1 << DEXENTRY_FIELD
	call DexEntry_NextCategory
	ret
.lvl_moves_text:
	db "LVL-UP MOVES@"

Pokedex_PrintFieldMoves:
; CheckLvlUpMoves, 1 for fail, 0 for yes, in c
	hlcoord 1, 9
	ld de, .Field_Moves_text
	call PlaceString
	call Pokedex_PrintPageNum ; page num is also returned in a
	ld a, [wPokedexStatus] ; machine moves index
	ld b, a
	ld c, 0 ; current line
.fm_loop
	push bc
	ld c, b
	ld b, 0
	ld hl, Field_Moves_List
	add hl, bc
	ld a, [hl]
	ld d, a
	farcall CheckLvlUpMoves
	ld a, c ; c has lvl we learn move
	ld e, c
	pop bc
	and a
	jr nz, .print_move_name
.check_machines
; check TM/HM
	push bc
	ld c, b 
	ld b, 0
	ld hl, Field_Moves_List
	add hl, bc
	ld a, [hl]
	ld d, a
	ld [wPutativeTMHMMove], a
	farcall CanLearnTMHMMove
	ld a, c
	pop bc
	and a
	jr z, .notcompatible
; check TM/HM done
.print_move_name
	push de
	ld a, d
	ld [wNamedObjectIndex], a
	call GetMoveName
	push bc ; our count is in c
	hlcoord 7, 10
	call DexEntry_adjusthlcoord
	call PlaceString
	pop bc
; print TM/HM num
	ld d, 0
	ld e, b
	ld hl, Field_Moves_Method_List
	add hl, de
	ld a, [hl]
	pop de
	and a
	jr nz, .tm_or_hm
	push bc
	hlcoord 3, 10
	call DexEntry_adjusthlcoord
	ld [hl], $5d ; <LVL>
	inc hl
	lb bc, PRINTNUM_LEFTALIGN | 1, 2
	ld a, e
	ld [wTextDecimalByte], a
	ld de, wTextDecimalByte
	call PrintNum
	pop bc
	jr .inc_line_count  
.tm_or_hm
	ld [wNamedObjectIndex], a
	call GetItemName
	push bc
	hlcoord 2, 10
	call DexEntry_adjusthlcoord
	call PlaceString
	pop bc
; print TM/HM num done
.inc_line_count
	inc c ; since we printed a line
	ld a, $6
	cp c
	jr nz, .notcompatible ; not yet printed all 5 slots
	; We've printed all 5 slots
	; check if we need to move to next category or if there are moves left
	call Pokedex_anymoreFieldMoves
	jr z, .done ; there are no moves left
	; moves left
	call DexEntry_IncPageNum
	ret
.notcompatible
	ld a, NUM_FIELD_MOVES - 1
	cp b
	jr z, .done
	inc b
	ld a, b
	ld [wPokedexStatus], a ; moves machines index
	jp .fm_loop
.done
	ld a, 1 << DEXENTRY_EGG
	call DexEntry_NextCategory
	ld a, c
	and a
	ret nz ; we've had at least one HM Move
	hlcoord 2, 11
	ld de, DexEntry_NONE_text
	call PlaceString
	ret
.Field_Moves_text:
	db "FIELD MOVES@"

Field_Moves_List:
	db TELEPORT, SOFTBOILED, MILK_DRINK, \
		HEADBUTT, ROCK_SMASH, SWEET_SCENT, DIG,\
		CUT, FLY, SURF, STRENGTH, FLASH, WATERFALL, WHIRLPOOL
Field_Moves_Method_List:
	db 0, 0, 0, TM01 + 1, TM01 + 7, TM01 + 11, TM01 + 27, HM01, \
	HM01 + 1, HM01 + 2, HM01 + 3, HM01 + 4, HM01 + 5, HM01 + 6

Pokedex_anymoreFieldMoves:
	; b has the current machine index
	inc b
.fmloop
	push bc
	ld d, 0
	ld e, b 
	ld hl, Field_Moves_List
	add hl, de
	ld a, [hl]
	ld d, a

	farcall CheckLvlUpMoves
	ld a, c ; c has lvl we learn move
	ld d, a ; to preserve it for later
	pop bc
	and a
	jr nz, .yes
	push bc
	ld d, 0
	ld e, b
	ld hl, Field_Moves_Method_List
	add hl, de
	ld a, [hl]
	and a
	jr z, .not_tm_or_hm
	ld [wCurItem], a
	farcall GetTMHMItemMove
	ld a, [wTempTMHM]	
	ld [wPutativeTMHMMove], a
	farcall CanLearnTMHMMove
	ld a, c
	pop bc
	and a
	jr nz, .yes
.not_tm_or_hm
	ld a, NUM_FIELD_MOVES - 1
	cp b
	jr z, .none
	inc b
	jr .fmloop	
.yes
	ld a, b
	ld [wPokedexStatus], a ; so we can start off at the next learnable machine
	ld a, 1
	and a
	ret
.none
	xor a
	ret

Pokedex_Calc_EggMovesPtr:
	ld a, 1 << DEXENTRY_EGG
	ld [wPokedexEntryType], a
	call Pokedex_PrintPageNum ; page num is also returned in a
	ld a, [wPokedexEntryPageNum]
	ld c, 6 ; we can print 5 Egg moves per page
	call SimpleMultiply ; double this num and add to first byte after Evo's 0
	ld b, 0
	ld c, a
	push bc
; Step 4: Get First byte of learnset
	push af ; preserve current species or else move sets will be messed up for stage2+ mons
	callfar GetPreEvolution ; changes wCurPartyMon
	callfar GetPreEvolution ; changes wCurPartyMon
	ld a, [wCurPartySpecies]
	dec a ; Bulbasaur is No 1 but entry ZERO
	ld b, 0
	ld c, a
	ld hl, EggMovePointers
	add hl, bc ; trying to add the species number in only 'a' will overflow a
	add hl, bc ; add twice to double the index, words/PTRs are TWO bytes ea
	pop af ; preserve current species or else move sets will be messed up for stage2+ mons
	ld [wTempSpecies], a
	ld [wCurPartySpecies], a
	ld a, BANK(EggMovePointers)
	call GetFarWord
.check_if_any
	ld a, BANK("Egg Moves")
	call GetFarByte
	pop bc
	add hl, bc
	push af ; -1 if no egg moves
	push hl
	hlcoord 1, 9
	ld de, .EggMoves_text
	call PlaceString
	pop hl
	pop af
	cp -1
	ret nz
	; if we reach here, the mon has no egg moves at all
	; will not call Pokedex_Print_Egg_moves
	; increment to next category
	ld a, 1 << DEXENTRY_TMS
	call DexEntry_NextCategory
	;print NONE
	hlcoord 2, 11
	ld de, DexEntry_NONE_text
	call PlaceString
	ret
.EggMoves_text:
	db "EGG MOVES@"

Pokedex_Print_Egg_moves:
; Print No more than 5 moves
	ld b, 0
	ld c, 0 ; our move counter, max of 4 for 5 moves
	; our adjusted pointer based on page num is in hl
.Egg_loop
	ld a, BANK("Egg Moves")
	call GetFarByte ; EGG Move, or -1 for end
	cp -1
	jr z, .FoundEnd
	inc hl ; Moves HL to next Byte
	push hl
	ld [wNamedObjectIndex], a ; all the "Name" Funcs use this 
	call GetMoveName ; returns the string pointer in de
	hlcoord 2, 10
	call DexEntry_adjusthlcoord
	push bc
	call PlaceString ; places Move Name
	pop bc
	pop hl
	ld a, $5 ; means we just printed 6th move
	cp c
	jr z, .MaxedPage
	inc c
	jr .Egg_loop
.MaxedPage ; Printed 5 moves. Moves are still left. Inc the Page counter
; CheckNextByte, we dont want blank screen if we just printed last move in slot 5
	ld a, BANK("Egg Moves")
	call GetFarByte; Move # returned in "a"
	cp -1
	jr z, .FoundEnd
	call DexEntry_IncPageNum
	ret
.FoundEnd
	ld a, 1 << DEXENTRY_TMS
	call DexEntry_NextCategory
	ret

Pokedex_PrintTMs:
	hlcoord 1, 9
	ld de, .dex_TM_text
	call PlaceString
	call Pokedex_PrintPageNum ; page num is also returned in a
	ld a, [wPokedexStatus] ; machine moves index
	ld b, a
	ld c, 0 ; current line
.tm_loop
	push bc
	ld a, TM01
	add b
	ld [wCurItem], a
	farcall GetTMHMItemMove
	ld a, [wTempTMHM]
	ld [wPutativeTMHMMove], a
	farcall CanLearnTMHMMove
	ld a, c
	pop bc
	and a
	jr z, .notcompatible
	call GetMoveName
	push bc ; our count is in c
	hlcoord 7, 10
	call DexEntry_adjusthlcoord
	call PlaceString
	pop bc
	ld a, TM01
	ld a, [wPokedexStatus]
	ld b, a
	ld a, TM01
	add b
	ld [wNamedObjectIndex], a
	call GetItemName
	push bc
	hlcoord 2, 10
	call DexEntry_adjusthlcoord
	call PlaceString
	pop bc
	inc c ; since we printed a line
	ld a, $6
	cp c
	jr nz, .notcompatible ; not yet printed all 5 slots
	; We've printed all 5 slots
	; check if we need to move to next category or if there are moves left
	call Pokedex_anymoreTMs
	jr z, .done ; there are no moves left
	; moves left
	call DexEntry_IncPageNum
	ret
.notcompatible
	ld a, NUM_TMS - 1
	cp b
	jr z, .done
	inc b
	ld a, b
	ld [wPokedexStatus], a ; moves machines index
	jr .tm_loop
.done
	; ld a, 1 << DEXENTRY_HMS
	ld a, 1 << DEXENTRY_MTS
	call DexEntry_NextCategory
	ld a, c
	and a
	ret nz ; we've had at least one HM Move
	hlcoord 2, 11
	ld de, DexEntry_NONE_text
	call PlaceString
	ret
.dex_TM_text:
	db "TECHNICAL MACHINES@"

Pokedex_anymoreTMs:
	; b has the current HM index
	ld a, NUM_TMS - 1
	cp b
	jr z, .none
	inc b
.tmloop
	push bc
	ld a, TM01
	add b
	ld [wCurItem], a
	farcall GetTMHMItemMove
	ld a, [wTempTMHM]	
	ld [wPutativeTMHMMove], a
	farcall CanLearnTMHMMove
	ld a, c
	pop bc
	and a
	jr nz, .yes
	ld a, NUM_TMS - 1
	cp b
	jr z, .none
	inc b
	jr .tmloop	
.yes
	ld a, b
	ld [wPokedexStatus], a ; so we can start off at the next learnable machine
	ld a, 1
	and a
	ret
.none
	xor a
	ld [wPokedexStatus], a
	ret

Pokedex_PrintMTs:
	hlcoord 1, 9
	ld de, .dex_MT_text
	call PlaceString
	call Pokedex_PrintPageNum ; page num is also returned in a
	ld a, [wPokedexStatus] ; moves machines index
	ld b, a ; result of simple multiply in a
	ld c, 0 ; current line
.mt_loop
	push bc
	ld a, MT01
	add b
	ld [wCurItem], a
	farcall GetTMHMItemMove
	ld a, [wTempTMHM]
	ld [wPutativeTMHMMove], a
	farcall CanLearnTMHMMove
	ld a, c
	pop bc
	and a
	jr z, .notcompatible
	call GetMoveName
	push bc ; our count is in c
	hlcoord 3, 10
	call DexEntry_adjusthlcoord
	call PlaceString
	pop bc
	inc c ; since we printed a line
	ld a, $6
	cp c
	jr nz, .notcompatible
	; We've printed all 5 slots
	; check if we need to move to next category or if there are moves left
	call Pokedex_anymoreMTs
	jr z, .done ; there are no moves left
	; moves left
	call DexEntry_IncPageNum
	ret
.notcompatible
	ld a, NUM_TUTORS - 1
	cp b
	jr z, .done
	inc b
	ld a, b
	ld [wPokedexStatus], a ; moves machines index
	jr .mt_loop
.done
	ld a, 1 << DEXENTRY_LVLUP
	call DexEntry_NextCategory
	ld a, c
	and a
	ret nz ; we've had at least one HM Move
	hlcoord 2, 11
	ld de, DexEntry_NONE_text
	call PlaceString
	ret
.dex_MT_text:
	db "MOVE TUTORS@"

Pokedex_anymoreMTs:
	ld a, NUM_TUTORS - 1
	cp b
	jr z, .none
	; b has the current HM index
	inc b
.mtloop
	push bc
	ld a, MT01
	add b
	ld [wCurItem], a
	farcall GetTMHMItemMove
	ld a, [wTempTMHM]	
	ld [wPutativeTMHMMove], a
	farcall CanLearnTMHMMove
	ld a, c
	pop bc
	and a
	jr nz, .yes
	ld a, NUM_TUTORS - 1
	cp b
	jr z, .none
	inc b
	jr .mtloop	
.yes
	ld a, 1
	and a
	ret
.none
	xor a
	ret

; Pokedex_PrintHMs:
; 	hlcoord 1, 9
; 	ld de, .dex_HM_text
; 	call PlaceString
; 	call Pokedex_PrintPageNum ; page num is also returned in a
; 	ld a, [wPokedexStatus]
; 	ld b, a
; 	ld c, 0 ; current line
; .hm_loop
; 	push bc
; 	ld a, HM01
; 	add b
; 	ld [wCurItem], a
; 	farcall GetTMHMItemMove
; 	ld a, [wTempTMHM]
; 	ld [wPutativeTMHMMove], a
; 	farcall CanLearnTMHMMove
; 	ld a, c
; 	pop bc
; 	and a
; 	jr z, .notcompatible
; 	call GetMoveName
; 	push bc ; our count is in c
; 	hlcoord 7, 10
; 	call DexEntry_adjusthlcoord
; 	call PlaceString
; 	pop bc
; 	ld a, HM01
; 	add b
; 	ld [wNamedObjectIndex], a
; 	call GetItemName
; 	push bc
; 	hlcoord 2, 10
; 	call DexEntry_adjusthlcoord
; 	call PlaceString
; 	pop bc
; 	inc c ; since we printed a line
; 	ld a, $6
; 	cp c
; 	jr nz, .notcompatible
; 	call Pokedex_anymoreHMs
; 	jr z, .done
; 	call DexEntry_IncPageNum
; 	ret
; .notcompatible
; 	ld a, NUM_HMS - 1
; 	cp b
; 	jr z, .done
; 	inc b
; 	jr .hm_loop
; .done
; 	ld a, 1 << DEXENTRY_MTS
; 	call DexEntry_NextCategory
; 	ld a, c
; 	and a
; 	ret nz ; we've had at least one HM Move
; 	hlcoord 2, 11
; 	ld de, DexEntry_NONE_text
; 	call PlaceString
; 	ret
; .dex_HM_text:
; 	db "HIDDEN MACHINES@"

; Pokedex_anymoreHMs:
; 	ld a, NUM_HMS - 1
; 	cp b
; 	jr z, .none
; 	; b has the current HM index
; 	inc b
; .hmloop
; 	push bc
; 	ld a, HM01
; 	add b
; 	ld [wCurItem], a
; 	farcall GetTMHMItemMove
; 	ld a, [wTempTMHM]	
; 	ld [wPutativeTMHMMove], a
; 	farcall CanLearnTMHMMove
; 	ld a, c
; 	pop bc
; 	and a
; 	jr nz, .yes
; 	ld a, NUM_HMS - 1
; 	cp b
; 	jr z, .none
; 	inc b
; 	jr .hmloop	
; .yes
; 	ld a, 1
; 	and a
; 	ret
; .none
; 	xor a
; 	ld [wPokedexStatus], a
; 	ret
