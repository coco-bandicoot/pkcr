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
DisplayDexMonStats:
	ret
DisplayDexMonMoves:
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