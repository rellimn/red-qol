; This function is used to wait a short period after printing a letter to the
; screen unless the player presses the A/B button or the delay is turned off
; through the [wd730] or [wLetterPrintingDelayFlags] flags.
PrintLetterDelay::
	ld a, [wHacks] ; Loads Hacks config into A
	bit BIT_TEXT_BOX_INSTANT, a ; Sets Z to 1 if bit BIT_TEXT_BOX_INSTANT of A (wHacks) is 0
	jp nz, .noPrintLetterDelay ; If Z is not set, i. e. Text Box Speed is Instant, continue to .noPrintLetterDelay
	;
	ld a, [wd730]
	bit 6, a
	ret nz
	ld a, [wLetterPrintingDelayFlags]
	bit 1, a
	ret z
	push hl
	push de
	push bc
	ld a, [wLetterPrintingDelayFlags]
	bit 0, a
	jr z, .waitOneFrame
	ld a, [wOptions]
	and $f
	ldh [hFrameCounter], a
	jr .checkButtons
.waitOneFrame
	ld a, 1
	ldh [hFrameCounter], a
.checkButtons
	call Joypad
	ldh a, [hJoyHeld]
.checkAButton
	bit BIT_A_BUTTON, a
	jr z, .checkBButton
	jr .endWait
.checkBButton
	bit BIT_B_BUTTON, a
	jr z, .buttonsNotPressed
.endWait
	call DelayFrame
	jr .done
.buttonsNotPressed ; if neither A nor B is pressed
	ldh a, [hFrameCounter]
	and a
	jr nz, .checkButtons
.done
	pop bc
	pop de
	pop hl
.noPrintLetterDelay
	ret
