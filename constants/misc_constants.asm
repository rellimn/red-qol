; Boolean checks
FALSE EQU 0
TRUE  EQU 1

; flag operations
	const_def
	const FLAG_RESET ; 0
	const FLAG_SET   ; 1
	const FLAG_TEST  ; 2

; wOptions
TEXT_DELAY_FAST    EQU %001 ; 1
TEXT_DELAY_MEDIUM  EQU %011 ; 3
TEXT_DELAY_SLOW    EQU %101 ; 5

	const_def 6
	const BIT_BATTLE_SHIFT     ; 6
	const BIT_BATTLE_ANIMATION ; 7

; wHacks Bits 0 and 1
TEXT_BOX_NORMAL   EQU %00
TEXT_BOX_INSTANT  EQU %01
TEXT_BOX_AUTO     EQU %10

	const_def
	const BIT_TEXT_BOX_INSTANT ; 0
	const BIT_TEXT_BOX_AUTO ; 1
	const BIT_PLACEHOLDER0 ; 2
	const BIT_FIX_MISS ; 3
	const BIT_QUICK_SAVE ; 4
	const_def 6
	const BIT_TRAINER_GENDER ; 6   (-th bit in wHacks)
	const BIT_RUNNING_SHOES   ; 7   (-th bit in wHacks)
