	db 0 ; species ID placeholder
	
	db  70,  45,  48,  35,  60,  65
	evs  2,   0,   0,   0,   0,   0
	;   hp  atk  def  spd  sat  sdf
	
	db NORMAL, NORMAL ; type
	db 150 ; catch rate
	db 68 ; base exp
	db MYSTERYBERRY, MOON_STONE ; items
	db GENDER_F75 ; gender ratio
	db 10 ; step cycles to hatch
	INCBIN "gfx/pokemon/clefairy/front.dimensions"
	db GROWTH_FAST ; growth rate
	dn EGG_FAIRY, EGG_FAIRY ; egg groups
	
	; tm/hm learnset
	tmhm DYNAMICPUNCH, HEADBUTT, CURSE, ROLLOUT, TOXIC, ZAP_CANNON, PSYCH_UP, HIDDEN_POWER, SUNNY_DAY, ICE_BEAM, BLIZZARD, PROTECT, RAIN_DANCE, ENDURE, FRUSTRATION, SOLARBEAM, IRON_TAIL, THUNDER, RETURN, PSYCHIC_M, SHADOW_BALL, MUD_SLAP, DOUBLE_TEAM, ICE_PUNCH, SWAGGER, SLEEP_TALK, FIRE_BLAST, TELEPORT, THUNDERPUNCH, DREAM_EATER, FLAMETHROWER, REST, ATTRACT, FIRE_PUNCH, THUNDERBOLT, STRENGTH, FLASH, AEROBLAST, SACRED_FIRE, HYDRO_PUMP
	; end
