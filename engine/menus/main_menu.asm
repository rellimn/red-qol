MainMenu:
; Check save file
	call InitOptions
	xor a
	ld [wOptionsInitialized], a
	inc a
	ld [wSaveFileStatus], a
	call CheckForPlayerNameInSRAM
	jr nc, .mainMenuLoop

	predef LoadSAV

.mainMenuLoop
	ld c, 20
	call DelayFrames
	xor a ; LINK_STATE_NONE
	ld [wLinkState], a
	ld hl, wPartyAndBillsPCSavedMenuItem
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [wDefaultMap], a
	ld hl, wd72e
	res 6, [hl]
	call ClearScreen
	call RunDefaultPaletteCommand
	call LoadTextBoxTilePatterns
	call LoadFontTilePatterns
	ld hl, wd730
	set 6, [hl]
	ld a, [wSaveFileStatus]
	cp 1
	jr z, .noSaveFile
; there's a save file
	hlcoord 0, 0
	ld b, 9
	ld c, 13
	call TextBoxBorder
	hlcoord 2, 2
	ld de, ContinueText
	call PlaceString
	jr .next2
.noSaveFile
	hlcoord 0, 0
	ld b, 6
	ld c, 13
	call TextBoxBorder
	hlcoord 2, 2
	ld de, NewGameText
	call PlaceString
.next2
	ld hl, wd730
	res 6, [hl]
	call UpdateSprites
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld [wMenuJoypadPollCount], a
	inc a
	ld [wTopMenuItemX], a
	inc a
	ld [wTopMenuItemY], a
	ld a, A_BUTTON | B_BUTTON | START
	ld [wMenuWatchedKeys], a
	ld a, [wSaveFileStatus]
	inc a; Adds third menu item
	ld [wMaxMenuItem], a
	call HandleMenuInput
	bit BIT_B_BUTTON, a
	jp nz, DisplayTitleScreen ; if so, go back to the title screen
	ld c, 20
	call DelayFrames
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wSaveFileStatus]
	cp 2
	jp z, .skipInc
; If there's no save file, increment the current menu item so that the numbers
; are the same whether or not there's a save file.
	inc b
.skipInc
	ld a, b
	and a
	jr z, .choseContinue
	cp 1
	jp z, StartNewGame
	cp 2
	call z, DisplayOptionMenu
	cp 3
	call z, DisplayHackMenu
	ld a, 1
	ld [wOptionsInitialized], a
	jp .mainMenuLoop
.choseContinue
	call DisplayContinueGameInfo
	ld hl, wCurrentMapScriptFlags
	set 5, [hl]
.inputLoop
	xor a
	ldh [hJoyPressed], a
	ldh [hJoyReleased], a
	ldh [hJoyHeld], a
	call Joypad
	ldh a, [hJoyHeld]
	bit 0, a
	jr nz, .pressedA
	bit 1, a
	jp nz, .mainMenuLoop ; pressed B
	jr .inputLoop
.pressedA
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	ld a, PLAYER_DIR_DOWN
	ld [wPlayerDirection], a
	ld c, 10
	call DelayFrames
	ld a, [wNumHoFTeams]
	and a
	jp z, SpecialEnterMap
	ld a, [wCurMap] ; map ID
	cp HALL_OF_FAME
	jp nz, SpecialEnterMap
	xor a
	ld [wDestinationMap], a
	ld hl, wd732
	set 2, [hl] ; fly warp or dungeon warp
	call SpecialWarpIn
	jp SpecialEnterMap

InitOptions:
	ld a, TEXT_DELAY_FAST
	ld [wLetterPrintingDelayFlags], a
	ld a, TEXT_DELAY_MEDIUM
	ld [wOptions], a
	ret

LinkMenu:
	xor a
	ld [wLetterPrintingDelayFlags], a
	ld hl, wd72e
	set 6, [hl]
	ld hl, LinkMenuEmptyText
	call PrintText
	call SaveScreenTilesToBuffer1
	ld hl, WhereWouldYouLikeText
	call PrintText
	hlcoord 5, 5
	ld b, $6
	ld c, $d
	call TextBoxBorder
	call UpdateSprites
	hlcoord 7, 7
	ld de, CableClubOptionsText
	call PlaceString
	xor a
	ld [wUnusedCD37], a
	ld [wd72d], a
	ld hl, wTopMenuItemY
	ld a, $7
	ld [hli], a
	ld a, $6
	ld [hli], a
	xor a
	ld [hli], a
	inc hl
	ld a, $2
	ld [hli], a
	inc a
	; ld a, A_BUTTON | B_BUTTON
	ld [hli], a ; wMenuWatchedKeys
	xor a
	ld [hl], a
.waitForInputLoop
	call HandleMenuInput
	and A_BUTTON | B_BUTTON
	add a
	add a
	ld b, a
	ld a, [wCurrentMenuItem]
	add b
	add $d0
	ld [wLinkMenuSelectionSendBuffer], a
	ld [wLinkMenuSelectionSendBuffer + 1], a
.exchangeMenuSelectionLoop
	call Serial_ExchangeLinkMenuSelection
	ld a, [wLinkMenuSelectionReceiveBuffer]
	ld b, a
	and $f0
	cp $d0
	jr z, .asm_5c7d
	ld a, [wLinkMenuSelectionReceiveBuffer + 1]
	ld b, a
	and $f0
	cp $d0
	jr nz, .exchangeMenuSelectionLoop
.asm_5c7d
	ld a, b
	and $c ; did the enemy press A or B?
	jr nz, .enemyPressedAOrB
; the enemy didn't press A or B
	ld a, [wLinkMenuSelectionSendBuffer]
	and $c ; did the player press A or B?
	jr z, .waitForInputLoop ; if neither the player nor the enemy pressed A or B, try again
	jr .doneChoosingMenuSelection ; if the player pressed A or B but the enemy didn't, use the player's selection
.enemyPressedAOrB
	ld a, [wLinkMenuSelectionSendBuffer]
	and $c ; did the player press A or B?
	jr z, .useEnemyMenuSelection ; if the enemy pressed A or B but the player didn't, use the enemy's selection
; the enemy and the player both pressed A or B
; The gameboy that is clocking the connection wins.
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr z, .doneChoosingMenuSelection
.useEnemyMenuSelection
	ld a, b
	ld [wLinkMenuSelectionSendBuffer], a
	and $3
	ld [wCurrentMenuItem], a
.doneChoosingMenuSelection
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr nz, .skipStartingTransfer
	call DelayFrame
	call DelayFrame
	ld a, START_TRANSFER_INTERNAL_CLOCK
	ldh [rSC], a
.skipStartingTransfer
	ld b, " "
	ld c, " "
	ld d, "▷"
	ld a, [wLinkMenuSelectionSendBuffer]
	and (B_BUTTON << 2) ; was B button pressed?
	jr nz, .updateCursorPosition
; A button was pressed
	ld a, [wCurrentMenuItem]
	cp $2
	jr z, .updateCursorPosition
	ld c, d
	ld d, b
	dec a
	jr z, .updateCursorPosition
	ld b, c
	ld c, d
.updateCursorPosition
	ld a, b
	ldcoord_a 6, 7
	ld a, c
	ldcoord_a 6, 9
	ld a, d
	ldcoord_a 6, 11
	ld c, 40
	call DelayFrames
	call LoadScreenTilesFromBuffer1
	ld a, [wLinkMenuSelectionSendBuffer]
	and (B_BUTTON << 2) ; was B button pressed?
	jr nz, .choseCancel ; cancel if B pressed
	ld a, [wCurrentMenuItem]
	cp $2
	jr z, .choseCancel
	xor a
	ld [wWalkBikeSurfState], a ; start walking
	ld a, [wCurrentMenuItem]
	and a
	ld a, COLOSSEUM
	jr nz, .next
	ld a, TRADE_CENTER
.next
	ld [wd72d], a
	ld hl, PleaseWaitText
	call PrintText
	ld c, 50
	call DelayFrames
	ld hl, wd732
	res 1, [hl]
	ld a, [wDefaultMap]
	ld [wDestinationMap], a
	call SpecialWarpIn
	ld c, 20
	call DelayFrames
	xor a
	ld [wMenuJoypadPollCount], a
	ld [wSerialExchangeNybbleSendData], a
	inc a ; LINK_STATE_IN_CABLE_CLUB
	ld [wLinkState], a
	ld [wEnteringCableClub], a
	jr SpecialEnterMap
.choseCancel
	xor a
	ld [wMenuJoypadPollCount], a
	vc_hook Network_STOP
	call Delay3
	call CloseLinkConnection
	ld hl, LinkCanceledText
	vc_hook Network_END
	call PrintText
	ld hl, wd72e
	res 6, [hl]
	ret

WhereWouldYouLikeText:
	text_far _WhereWouldYouLikeText
	text_end

PleaseWaitText:
	text_far _PleaseWaitText
	text_end

LinkCanceledText:
	text_far _LinkCanceledText
	text_end

StartNewGame:
	ld hl, wd732
	res 1, [hl]
StartNewGameDebug:
	call OakSpeech
	ld c, 20
	call DelayFrames
	
; enter map after using a special warp or loading the game from the main menu
SpecialEnterMap::
	xor a
	ldh [hJoyPressed], a
	ldh [hJoyHeld], a
	ldh [hJoy5], a
	ld [wd72d], a
	ld hl, wd732
	set 0, [hl] ; count play time
	call ResetPlayerSpriteData
	ld c, 20
	call DelayFrames
	ld a, [wEnteringCableClub]
	and a
	ret nz
	jp EnterMap

ContinueText:
	db "CONTINUE"
	next ""
	; fallthrough

NewGameText:
	db   "NEW GAME"
	next "OPTION"
	next "HACKS@"

CableClubOptionsText:
	db   "TRADE CENTER"
	next "COLOSSEUM"
	next "CANCEL@"

DisplayContinueGameInfo:
	xor a
	ldh [hAutoBGTransferEnabled], a
	hlcoord 4, 7
	ld b, 8
	ld c, 14
	call TextBoxBorder
	hlcoord 5, 9
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 12, 9
	ld de, wPlayerName
	call PlaceString
	hlcoord 17, 11
	call PrintNumBadges
	hlcoord 16, 13
	call PrintNumOwnedMons
	hlcoord 13, 15
	call PrintPlayTime
	ld a, 1
	ldh [hAutoBGTransferEnabled], a
	ld c, 30
	jp DelayFrames

PrintSaveScreenText:
	xor a
	ldh [hAutoBGTransferEnabled], a
	hlcoord 4, 0
	ld b, $8
	ld c, $e
	call TextBoxBorder
	call LoadTextBoxTilePatterns
	call UpdateSprites
	hlcoord 5, 2
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 12, 2
	ld de, wPlayerName
	call PlaceString
	hlcoord 17, 4
	call PrintNumBadges
	hlcoord 16, 6
	call PrintNumOwnedMons
	hlcoord 13, 8
	call PrintPlayTime
	ld a, $1
	ldh [hAutoBGTransferEnabled], a
	ld c, 30
	jp DelayFrames

PrintNumBadges:
	push hl
	ld hl, wObtainedBadges
	ld b, $1
	call CountSetBits
	pop hl
	ld de, wNumSetBits
	lb bc, 1, 2
	jp PrintNumber

PrintNumOwnedMons:
	push hl
	ld hl, wPokedexOwned
	ld b, wPokedexOwnedEnd - wPokedexOwned
	call CountSetBits
	pop hl
	ld de, wNumSetBits
	lb bc, 1, 3
	jp PrintNumber

PrintPlayTime:
	ld de, wPlayTimeHours
	lb bc, 1, 3
	call PrintNumber
	ld [hl], $6d
	inc hl
	ld de, wPlayTimeMinutes
	lb bc, LEADING_ZEROES | 1, 2
	jp PrintNumber

SaveScreenInfoText:
	db   "PLAYER"
	next "BADGES    "
	next "#DEX    "
	next "TIME@"

DrawOptionMenu:
	hlcoord 0, 0
	ld b, 3
	ld c, 18
	call TextBoxBorder
	hlcoord 0, 5
	ld b, 3
	ld c, 18
	call TextBoxBorder
	hlcoord 0, 10
	ld b, 3
	ld c, 18
	call TextBoxBorder
	ret

DrawOptionRows:
	hlcoord 1, 1
	call PlaceString
	inc de
	hlcoord 1, 6
	call PlaceString
	inc de
	hlcoord 1, 11
	call PlaceString
	ret

DisplayHackMenu:
	call DrawOptionMenu
	ld de, TextBoxSpeedText
	call DrawOptionRows
	hlcoord 2, 16
	ld de, HacksMenuCancelText
	call PlaceString
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	inc a
	ld [wLetterPrintingDelayFlags], a
	;ld [wOptionsCancelCursorX], a
	ld [wHacksNavRowCursorX], a
	ld a, 3 ; text speed cursor Y coordinate
	ld [wTopMenuItemY], a
	call SetCursorPositionsFromHacks
	ld a, [wHacksTextBoxSpeedCursorX] ; text speed cursor X coordinate
	ld [wTopMenuItemX], a
	ld a, $01
	ldh [hAutoBGTransferEnabled], a ; enable auto background transfer
	call Delay3
.loop
	call PlaceMenuCursor
	call SetHacksFromCursorPositions
.getJoypadStateLoop
	call JoypadLowSensitivity
	ldh a, [hJoy5]
	ld b, a
	and A_BUTTON | B_BUTTON | START | D_RIGHT | D_LEFT | D_UP | D_DOWN ; any key besides select pressed?
	jr z, .getJoypadStateLoop
	bit BIT_B_BUTTON, b
	jr nz, .exitMenu
	bit BIT_START, b
	jr nz, .exitMenu
	bit BIT_A_BUTTON, b
	jr z, .checkDirectionKeys
	ld a, [wTopMenuItemY]
	cp 16 ; is the cursor in Nav Row?
	jr nz, .loop
	ld a, [wTopMenuItemX]
	cp 10
	call z, DisplayHackMenu2
	cp 1 ; is cursor on Cancel?
	jr nz, .loop
.exitMenu
	ld a, SFX_PRESS_AB
	call PlaySound
	ret
.eraseOldMenuCursor
	ld [wTopMenuItemX], a
	call EraseMenuCursor
	jp .loop
.checkDirectionKeys
	ld a, [wTopMenuItemY]
	bit BIT_D_DOWN, b
	jr nz, .downPressed
	bit BIT_D_UP, b
	jr nz, .upPressed
	cp 8 ; cursor in Running Shoes section?
	jr z, .cursorInRunningShoes
	cp 13 ; cursor in Trainer Gender section?
	jr z, .cursorInTrainerGender
	cp 16 ; cursor on Cancel?
	jr z, .cursorInNavRow
	jr z, .loop ; cannot be reached
.cursorInTextSpeed
	bit BIT_D_LEFT, b
	jp nz, .pressedLeftInTextSpeed
	jp .pressedRightInTextSpeed
.downPressed
	cp 16
	ld b, -13
	ld hl, wHacksTextBoxSpeedCursorX
	jr z, .updateMenuVariables
	ld b, 5
	cp 3
	inc hl
	jr z, .updateMenuVariables
	cp 8
	inc hl
	jr z, .updateMenuVariables
	ld b, 3
	inc hl
	jr .updateMenuVariables
.upPressed
	cp 8
	ld b, -5
	ld hl, wHacksTextBoxSpeedCursorX
	jr z, .updateMenuVariables
	cp 13
	inc hl
	jr z, .updateMenuVariables
	cp 16
	ld b, -3
	inc hl
	jr z, .updateMenuVariables
	ld b, 13
	inc hl
.updateMenuVariables
	add b
	ld [wTopMenuItemY], a
	ld a, [hl]
	ld [wTopMenuItemX], a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.cursorInRunningShoes
	ld a, [wHacksRunningShoesCursorX] ; battle animation cursor X coordinate
	xor $0b ; toggle between 1 and 10
	ld [wHacksRunningShoesCursorX], a
	jp .eraseOldMenuCursor
.cursorInTrainerGender
	ld a, [wHacksTrainerGenderCursorX] ; battle style cursor X coordinate
	xor $0b ; toggle between 1 and 10
	ld [wHacksTrainerGenderCursorX], a
	jp .eraseOldMenuCursor
.cursorInNavRow
	ld a, [wHacksNavRowCursorX] ; battle style cursor X coordinate
	xor $0b ; toggle between 1 and 10
	ld [wHacksNavRowCursorX], a
	jp .eraseOldMenuCursor
	;
.pressedLeftInTextSpeed
	ld a, [wHacksTextBoxSpeedCursorX] ; text speed cursor X coordinate
	cp 1
	jr z, .updateTextSpeedXCoord
	cp 7
	jr nz, .fromSlowToMedium
	sub 6
	jr .updateTextSpeedXCoord
.fromSlowToMedium
	sub 7
	jr .updateTextSpeedXCoord
.pressedRightInTextSpeed
	ld a, [wHacksTextBoxSpeedCursorX] ; text speed cursor X coordinate
	cp 14
	jr z, .updateTextSpeedXCoord
	cp 7
	jr nz, .fromFastToMedium
	add 7
	jr .updateTextSpeedXCoord
.fromFastToMedium
	add 6
.updateTextSpeedXCoord
	ld [wHacksTextBoxSpeedCursorX], a ; text speed cursor X coordinate
	jp .eraseOldMenuCursor

; called when clicking next on hack menu 1
DisplayHackMenu2:
	call DrawOptionMenu
	ld de, PLACEHOLDER0Text
	call DrawOptionRows
	hlcoord 2, 16
	ld de, OptionMenuCancelText ; TODO: implement Prev button to return to hack menu 1
	call PlaceString
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	inc a
	ld [wLetterPrintingDelayFlags], a
	ld [wHacksNavRowCursorX], a
	ld a, 3 ; top row cursor Y coordinate
	ld [wTopMenuItemY], a
	call SetCursorPositionsFromHacks2
	ld a, [wHacksPLACEHOLDER0CursorX] ; PLACEHOLDER0 cursor X coordinate
	ld [wTopMenuItemX], a
	ld a, $01
	ldh [hAutoBGTransferEnabled], a ; enable auto background transfer
	call Delay3
.loop
	call PlaceMenuCursor
	call SetHacks2FromCursorPositions
.getJoypadStateLoop
	call JoypadLowSensitivity
	ldh a, [hJoy5]
	ld b, a
	and A_BUTTON | B_BUTTON | START | D_RIGHT | D_LEFT | D_UP | D_DOWN ; any key besides select pressed?
	jr z, .getJoypadStateLoop
	bit BIT_B_BUTTON, b
	jr nz, .exitMenu
	bit BIT_START, b
	jr nz, .exitMenu
	bit BIT_A_BUTTON, b
	jr z, .checkDirectionKeys
	ld a, [wTopMenuItemY]
	cp 16 ; is the cursor in Nav Row?
	jr nz, .loop ; if yes, continue to .exitMenu, else jump to .loop
.exitMenu
	ld a, SFX_PRESS_AB
	call PlaySound
	ret
.eraseOldMenuCursor
	ld [wTopMenuItemX], a
	call EraseMenuCursor
	jp .loop
.checkDirectionKeys
	ld a, [wTopMenuItemY]
	bit BIT_D_DOWN, b
	jr nz, .downPressed
	bit BIT_D_UP, b
	jr nz, .upPressed
	cp 3 ; cursor in PLACEHOLDER0 section?
	jr z, .cursorInPLACEHOLDER0
	cp 8 ; cursor in Gen 1 Miss section?
	jr z, .cursorInFixMiss
	cp 13 ; cursor in Quick Save section?
	jr z, .cursorInQuickSave
	cp 16 ; cursor on Cancel?
	jr z, .loop 
.downPressed
	cp 16
	ld b, -13
	ld hl, wHacksPLACEHOLDER0CursorX
	jr z, .updateMenuVariables
	ld b, 5
	cp 3
	inc hl
	jr z, .updateMenuVariables
	cp 8
	inc hl
	jr z, .updateMenuVariables
	ld b, 3
	inc hl
	jr .updateMenuVariables
.upPressed
	cp 8
	ld b, -5
	ld hl, wHacksPLACEHOLDER0CursorX
	jr z, .updateMenuVariables
	cp 13
	inc hl
	jr z, .updateMenuVariables
	cp 16
	ld b, -3
	inc hl
	jr z, .updateMenuVariables
	ld b, 13
	inc hl
.updateMenuVariables
	add b
	ld [wTopMenuItemY], a
	ld a, [hl]
	ld [wTopMenuItemX], a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.cursorInPLACEHOLDER0
	ld a, [wHacksPLACEHOLDER0CursorX] ; PLACEHOLDER0 X coordinate
	xor $0b ; toggle between 1 and 10
	ld [wHacksPLACEHOLDER0CursorX], a
	jp .eraseOldMenuCursor
.cursorInFixMiss
	ld a, [wHacksFixMissCursorX] ; Gen 1 Miss  X coordinate
	xor $0b ; toggle between 1 and 10
	ld [wHacksFixMissCursorX], a
	jp .eraseOldMenuCursor
.cursorInQuickSave
	ld a, [wHacksQuickSaveCursorX] ; Quick Save X coordinate
	xor $0b ; toggle between 1 and 10
	ld [wHacksQuickSaveCursorX], a
	jp .eraseOldMenuCursor

DisplayOptionMenu:
	call DrawOptionMenu
	ld de, TextSpeedOptionText
	call DrawOptionRows
	hlcoord 2, 16
	ld de, OptionMenuCancelText
	call PlaceString
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	inc a
	ld [wLetterPrintingDelayFlags], a
	ld [wOptionsCancelCursorX], a
	ld a, 3 ; text speed cursor Y coordinate
	ld [wTopMenuItemY], a
	call SetCursorPositionsFromOptions
	ld a, [wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	ld [wTopMenuItemX], a
	ld a, $01
	ldh [hAutoBGTransferEnabled], a ; enable auto background transfer
	call Delay3
.loop
	call PlaceMenuCursor
	call SetOptionsFromCursorPositions
.getJoypadStateLoop
	call JoypadLowSensitivity
	ldh a, [hJoy5]
	ld b, a
	and A_BUTTON | B_BUTTON | START | D_RIGHT | D_LEFT | D_UP | D_DOWN ; any key besides select pressed?
	jr z, .getJoypadStateLoop
	bit BIT_B_BUTTON, b
	jr nz, .exitMenu
	bit BIT_START, b
	jr nz, .exitMenu
	bit BIT_A_BUTTON, b
	jr z, .checkDirectionKeys
	ld a, [wTopMenuItemY]
	cp 16 ; is the cursor on Cancel?
	jr nz, .loop
.exitMenu
	ld a, SFX_PRESS_AB
	call PlaySound
	ret
.eraseOldMenuCursor
	ld [wTopMenuItemX], a
	call EraseMenuCursor
	jp .loop
.checkDirectionKeys
	ld a, [wTopMenuItemY]
	bit BIT_D_DOWN, b
	jr nz, .downPressed
	bit BIT_D_UP, b
	jr nz, .upPressed
	cp 8 ; cursor in Battle Animation section?
	jr z, .cursorInBattleAnimation
	cp 13 ; cursor in Battle Style section?
	jr z, .cursorInBattleStyle
	cp 16 ; cursor on Cancel?
	jr z, .loop
.cursorInTextSpeed
	bit BIT_D_LEFT, b
	jp nz, .pressedLeftInTextSpeed
	jp .pressedRightInTextSpeed
.downPressed
	cp 16
	ld b, -13
	ld hl, wOptionsTextSpeedCursorX
	jr z, .updateMenuVariables
	ld b, 5
	cp 3
	inc hl
	jr z, .updateMenuVariables
	cp 8
	inc hl
	jr z, .updateMenuVariables
	ld b, 3
	inc hl
	jr .updateMenuVariables
.upPressed
	cp 8
	ld b, -5
	ld hl, wOptionsTextSpeedCursorX
	jr z, .updateMenuVariables
	cp 13
	inc hl
	jr z, .updateMenuVariables
	cp 16
	ld b, -3
	inc hl
	jr z, .updateMenuVariables
	ld b, 13
	inc hl
.updateMenuVariables
	add b
	ld [wTopMenuItemY], a
	ld a, [hl]
	ld [wTopMenuItemX], a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.cursorInBattleAnimation
	ld a, [wOptionsBattleAnimCursorX] ; battle animation cursor X coordinate
	xor $0b ; toggle between 1 and 10
	ld [wOptionsBattleAnimCursorX], a
	jp .eraseOldMenuCursor
.cursorInBattleStyle
	ld a, [wOptionsBattleStyleCursorX] ; battle style cursor X coordinate
	xor $0b ; toggle between 1 and 10
	ld [wOptionsBattleStyleCursorX], a
	jp .eraseOldMenuCursor
.pressedLeftInTextSpeed
	ld a, [wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	cp 1
	jr z, .updateTextSpeedXCoord
	cp 7
	jr nz, .fromSlowToMedium
	sub 6
	jr .updateTextSpeedXCoord
.fromSlowToMedium
	sub 7
	jr .updateTextSpeedXCoord
.pressedRightInTextSpeed
	ld a, [wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	cp 14
	jr z, .updateTextSpeedXCoord
	cp 7
	jr nz, .fromFastToMedium
	add 7
	jr .updateTextSpeedXCoord
.fromFastToMedium
	add 6
.updateTextSpeedXCoord
	ld [wOptionsTextSpeedCursorX], a ; text speed cursor X coordinate
	jp .eraseOldMenuCursor

TextBoxSpeedText:
	db   "TEXT BOX SPEED"
	next " NORM  INST   AUTO@"

RunningShoesText:
	db   "RUNNING SHOES"
	next " OFF      ON@"

TrainerGenderText:
	db   "TRAINER GENDER"
	next " MALE     FEMALE@"

TextSpeedOptionText:
	db   "TEXT SPEED"
	next " FAST  MEDIUM SLOW@"

BattleAnimationOptionText:
	db   "BATTLE ANIMATION"
	next " ON       OFF@"

BattleStyleOptionText:
	db   "BATTLE STYLE"
	next " SHIFT    SET@"

OptionMenuCancelText:
	db "CANCEL        @" ; Spaces are for clearing previous text

HacksMenuCancelText:
	db "CANCEL   NEXT@"

PLACEHOLDER0Text:
	db   "PLACEHOLDER0"
	next " OFF      ON@"

FixMissText:
	db   "REMOVE GEN 1 MISS"
	next " OFF      ON@"

QuickSaveText:
	db   "SKIP SAVE DIALOGUE"
	next " OFF      ON@"

SetHacksFromCursorPositions:
	ld hl, TextBoxSpeedOptionData
	ld a, [wHacksTextBoxSpeedCursorX] ; text box speed cursor X coordinate
	ld c, a
.loop
	ld a, [hli]
	cp c
	jr z, .textSpeedMatchFound
	inc hl
	jr .loop
.textSpeedMatchFound
	ld a, [wHacks]
	or $3
	ld d, a
	ld a, [hl]
	or $FC
	and d
	ld d, a
	ld a, [wHacksRunningShoesCursorX] ; running shoes cursor X coordinate
	dec a
	jr z, .RunningShoesOn
.battleRunningShoesOff
	set 7, d
	jr .checkTrainerGender
.RunningShoesOn
	res 7, d
.checkTrainerGender
	ld a, [wHacksTrainerGenderCursorX] ; trainer gender cursor X coordinate
	dec a
	jr z, .battleStyleShift
.TrainerGenderMale
	set 6, d
	jr .storeOptions
.battleStyleShift
	res 6, d
.storeOptions
	ld a, d
	ld [wHacks], a
	ret

SetHacks2FromCursorPositions:
	ld a, [wHacks]
	ld d, a
	ld a, [wHacksPLACEHOLDER0CursorX] ; PLACEHOLDER0 cursor x coordinate
	dec a ; If cursor is on "off", its x value will be 1 (now stored in a)
	jr nz, .PLACEHOLDER0On ; If cursor x value is not zero after decrement, jump to .PLACEHOLDER0On
.PLACEHOLDER0Off ; else continue to PLACEHOLDER0Off
	res BIT_PLACEHOLDER0, d
	jr .checkFixMiss
.PLACEHOLDER0On
	set BIT_PLACEHOLDER0, d
.checkFixMiss
	ld a, [wHacksFixMissCursorX]
	dec a
	jr nz, .fixMissOn
.fixMissOff
	res BIT_FIX_MISS, d
	jr .checkQuickSave
.fixMissOn
	set BIT_FIX_MISS, d
.checkQuickSave
	ld a, [wHacksQuickSaveCursorX]
	dec a
	jr nz, .quickSaveOn
.quickSaveOff
	res BIT_QUICK_SAVE, d
	jr .storeOptions
.quickSaveOn
	set BIT_QUICK_SAVE, d
.storeOptions
	ld a, d
	ld [wHacks], a
	ret

; sets the options variable according to the current placement of the menu cursors in the options menu
SetOptionsFromCursorPositions:
	ld hl, TextSpeedOptionData
	ld a, [wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	ld c, a
.loop
	ld a, [hli]
	cp c
	jr z, .textSpeedMatchFound
	inc hl
	jr .loop
.textSpeedMatchFound
	ld a, [hl]
	ld d, a
	ld a, [wOptionsBattleAnimCursorX] ; battle animation cursor X coordinate
	dec a
	jr z, .battleAnimationOn
.battleAnimationOff
	set 7, d
	jr .checkBattleStyle
.battleAnimationOn
	res 7, d
.checkBattleStyle
	ld a, [wOptionsBattleStyleCursorX] ; battle style cursor X coordinate
	dec a
	jr z, .battleStyleShift
.battleStyleSet
	set 6, d
	jr .storeOptions
.battleStyleShift
	res 6, d
.storeOptions
	ld a, d
	ld [wOptions], a
	ret

; reads the hacks variable and places menu cursors accordingly
SetCursorPositionsFromHacks:
	ld hl, TextBoxSpeedOptionData + 1
	ld a, [wHacks]
	ld c, a
	and $3
	push bc
	ld de, 2
	call IsInArray
	pop bc
	dec hl
	ld a, [hl]
	ld [wHacksTextBoxSpeedCursorX], a ; text box speed cursor X coordinate
	hlcoord 0, 3
	call .placeUnfilledRightArrow
	sla c
	ld a, 1 ; On
	jr nc, .storeRunningShoeCursorX
	ld a, 10 ; Off
.storeRunningShoeCursorX
	ld [wHacksRunningShoesCursorX], a ; running shoes (battle animation) cursor X coordinate
	hlcoord 0, 8
	call .placeUnfilledRightArrow
	sla c
	ld a, 1
	jr nc, .storeTrainerGenderCursorX
	ld a, 10
.storeTrainerGenderCursorX
	ld [wHacksTrainerGenderCursorX], a ; trainer gender (battle style) cursor X coordinate
	hlcoord 0, 13
	call .placeUnfilledRightArrow
; cursor in front of Cancel
	hlcoord 0, 16
	ld a, 1
.placeUnfilledRightArrow
	ld e, a
	ld d, 0
	add hl, de
	ld [hl], "▷"
	ret

SetCursorPositionsFromHacks2:
	ld a, [wHacks]
	ld c, a
	sra c
	sra c
	sra c
	ld a, 1 ; On
	jr nc, .storePLACEHOLDER0CursorX
	ld a, 10 ; Off
.storePLACEHOLDER0CursorX
	ld [wHacksPLACEHOLDER0CursorX], a
	hlcoord 0, 3
	call .placeUnfilledRightArrow
	sra c
	ld a, 1
	jr nc, .storeFixMissCursorX
	ld a, 10
.storeFixMissCursorX
	ld [wHacksFixMissCursorX], a ; Gen 1 Miss cursor X coordinate
	hlcoord 0, 8
	call .placeUnfilledRightArrow
	sra c 
	ld a, 1
	jr nc, .storeQuickSaveCursorX
	ld a, 10
.storeQuickSaveCursorX
	ld [wHacksQuickSaveCursorX], a ; Quick Save cursor X coordinate
	hlcoord 0, 13
	call .placeUnfilledRightArrow
; cursor in front of Cancel
	hlcoord 0, 16
	ld a, 1
.placeUnfilledRightArrow
	ld e, a
	ld d, 0
	add hl, de
	ld [hl], "▷"
	ret

; reads the options variable and places menu cursors in the correct positions within the options menu
SetCursorPositionsFromOptions:
	ld hl, TextSpeedOptionData + 1
	ld a, [wOptions]
	ld c, a
	and $3f
	push bc
	ld de, 2
	call IsInArray
	pop bc
	dec hl
	ld a, [hl]
	ld [wOptionsTextSpeedCursorX], a ; text speed cursor X coordinate
	hlcoord 0, 3
	call .placeUnfilledRightArrow
	sla c
	ld a, 1 ; On
	jr nc, .storeBattleAnimationCursorX
	ld a, 10 ; Off
.storeBattleAnimationCursorX
	ld [wOptionsBattleAnimCursorX], a ; battle animation cursor X coordinate
	hlcoord 0, 8
	call .placeUnfilledRightArrow
	sla c
	ld a, 1
	jr nc, .storeBattleStyleCursorX
	ld a, 10
.storeBattleStyleCursorX
	ld [wOptionsBattleStyleCursorX], a ; battle style cursor X coordinate
	hlcoord 0, 13
	call .placeUnfilledRightArrow
; cursor in front of Cancel
	hlcoord 0, 16
	ld a, 1
.placeUnfilledRightArrow
	ld e, a
	ld d, 0
	add hl, de
	ld [hl], "▷"
	ret

; table that indicates how the 3 text speed options affect frame delays
; Format:
; 00: X coordinate of menu cursor
; 01: delay after printing a letter (in frames)
TextSpeedOptionData:
	db 14, TEXT_DELAY_SLOW
	db  7, TEXT_DELAY_MEDIUM
	db  1, TEXT_DELAY_FAST
	db  7, -1 ; end (default X coordinate)

TextBoxSpeedOptionData:
	db 14, TEXT_BOX_AUTO
	db  7, TEXT_BOX_INSTANT
	db  1, TEXT_BOX_NORMAL
	db 1, -1

CheckForPlayerNameInSRAM:
; Check if the player name data in SRAM has a string terminator character
; (indicating that a name may have been saved there) and return whether it does
; in carry.
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a
	ld b, NAME_LENGTH
	ld hl, sPlayerName
.loop
	ld a, [hli]
	cp "@"
	jr z, .found
	dec b
	jr nz, .loop
; not found
	xor a
	ld [MBC1SRamEnable], a
	ld [MBC1SRamBankingMode], a
	and a
	ret
.found
	xor a
	ld [MBC1SRamEnable], a
	ld [MBC1SRamBankingMode], a
	scf
	ret
