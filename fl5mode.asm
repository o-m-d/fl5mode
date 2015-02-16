;
; FL5Mode
; Version 0.0.1 Feb, 2015
; Copyright (c) 2015 Olexandr Davydenko
; License: http://opensource.org/licenses/MIT
;
; Driver for five mode LED fLashlight with magnetic rotary switch
; and Hall-effect sensors inside.
;
; MCU: PIC12F629
; asm: mpasmx v. 5.60
; Internal OSC 4MHz
; GP0, GP1, GP3, GP4 - inputs from Hall-effect sensors, active level - low.
;
; GP5 unused in some original drivers.
; In this case lowbright-mode have same input state as off-mode and can be distinguish
; by checking previous modes.
;
; GP2 - output to LED driver on PNP transistor, emitter wired to +Vbat,
; collector wired to 1A LED, LED wired to -Vbat.
;
; Brightness by PWM at 2.315kHz: full - 100%, half - 40%, low - 10%.
; Flash: 10ms at one second.
; SOS: ...---... with 500ms dot length.

	list p=12f629
	#include <p12f629.inc>
	radix hex

	__config _CP_OFF & _CPD_OFF & _BODEN_ON & _MCLRE_OFF & _PWRTE_ON & _WDTE_ON & _INTRC_OSC_NOCLKOUT

; inputs
	#define	IN_HALF		GP0
	#define	IN_FULL		GP1
	#define	IN_SOS		GP3
	#define	IN_FLASH	GP4
	#define	IN_LOW		GP5

	#define	NEAR_LOW	0

	#define	LED_ON			bcf GPIO, GP2
	#define	LED_OFF			bsf GPIO, GP2
	#define	BANK_0			bcf STATUS, RP0
	#define	BANK_1			bsf STATUS, RP0
	#define	SET_NEAR_LOW	bsf	FLAG, NEAR_LOW
	#define	CLR_NEAR_LOW	bcf	FLAG, NEAR_LOW

; premature end long SOS cycle if mode changed
CHECK_SOS_MODE MACRO
	btfsc	GPIO, IN_SOS
	goto	MAIN
	ENDM

	CBLOCK 0x20
CNT0
CNT1
CNT2
DELAY_0
DELAY_1
DELAY_2
FLAG
	ENDC

	org	0x000
	goto INIT

INIT:
	BANK_0
	clrf	GPIO			; init GPIO
	movlw	b'00000111'		; Comparator off, GPIO - digital i/o
	movwf	CMCON
	BANK_1
	clrwdt
	movlw	b'01111110'		; Pullups enable (Hall sensors have open collector output), prescaler set up and connect to WDT
	movwf	OPTION_REG
	movlw	b'00111011'		; GP2 - output, other - input
	movwf	TRISIO
	movlw	b'00110011'
	movwf	WPU
	movlw	0x03
	movwf	PCON
	call	0x3ff
	movwf	OSCCAL
	BANK_0
	clrf	FLAG


MAIN:
; select mode
	btfss	GPIO, IN_FULL
	goto	BRIGHT_FULL
	btfss	GPIO, IN_HALF
	goto	BRIGHT_HALF
	btfss	GPIO, IN_LOW
	goto	BRIGHT_LOW
	btfss	GPIO, IN_FLASH
	goto	FLASH
	btfss	GPIO, IN_SOS
	goto	SOS
; emulate missing Hall sensor for low light mode (BRIGHT_LOW)
	btfsc	FLAG, NEAR_LOW
	goto	BRIGHT_LOW
; none mode selected - off
	LED_OFF
	sleep
	goto	MAIN

BRIGHT_FULL:
	CLR_NEAR_LOW
	LED_ON
	call	DOT
	call	DELAY

	goto	MAIN

BRIGHT_HALF:
	SET_NEAR_LOW
	LED_ON
	movlw	0x01
	movwf	DELAY_2
	movlw	0x01
	movwf	DELAY_1
	movlw	0x32
	movwf	DELAY_0
	call	DELAY
	clrwdt

	LED_OFF
	movlw	0x01
	movwf	DELAY_2
	movlw	0x01
	movwf	DELAY_1
	movlw	0x4d
	movwf	DELAY_0
	call	DELAY
	clrwdt

	goto	MAIN

BRIGHT_LOW:
	LED_ON
	movlw	0x01
	movwf	DELAY_2
	movlw	0x01
	movwf	DELAY_1
	movlw	0x07
	movwf	DELAY_0
	call	DELAY
	clrwdt

	LED_OFF
	movlw	0x01
	movwf	DELAY_2
	movlw	0x01
	movwf	DELAY_1
	movlw	0x78
	movwf	DELAY_0
	call	DELAY
	clrwdt

	goto	MAIN

FLASH:
	SET_NEAR_LOW
	LED_ON
	movlw	0x01
	movwf	DELAY_2
	movlw	0x10
	movwf	DELAY_1
	movlw	0xd7
	movwf	DELAY_0
	call	DELAY

	LED_OFF
	call	DOT
	call	DELAY
	call	DELAY

	goto	MAIN

SOS:
	CLR_NEAR_LOW
; S symbol
	LED_ON
	call	DOT
	call	DELAY
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
	LED_ON
	call	DOT
	call	DELAY
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
	LED_ON
	call	DOT
	call	DELAY
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
; O symbol
	LED_ON
	call	DOT
	call	DELAY
	CHECK_SOS_MODE
	call	DELAY
	CHECK_SOS_MODE
	call	DELAY
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
	LED_ON
	call	DOT
	call	DELAY
	CHECK_SOS_MODE
	call	DELAY
	CHECK_SOS_MODE
	call	DELAY
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
	LED_ON
	call	DOT
	call	DELAY
	CHECK_SOS_MODE
	call	DELAY
	CHECK_SOS_MODE
	call	DELAY
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
; S symbol
	LED_ON
	call	DOT
	call	DELAY
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
	LED_ON
	call	DOT
	call	DELAY
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
	LED_ON
	call	DOT
	call	DELAY
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
; pause
	LED_OFF
	CHECK_SOS_MODE
	call	DOT
	call	DELAY
	CHECK_SOS_MODE
	call	DELAY
	CHECK_SOS_MODE
	call	DELAY

	goto	MAIN

; dot (from Morse code) subroutine, setup 500ms delay at 4MHz INTOSC
DOT:
	movlw	0x10
	movwf	DELAY_2
	movlw	0x40
	movwf	DELAY_1
	movlw	0xa8
	movwf	DELAY_0
	return

; delay subroutine
DELAY:
	movf	DELAY_2, W
	movwf	CNT2
D2:
	movf	DELAY_1, W
	movwf	CNT1
	clrwdt

D1:
	movf	DELAY_0, W
	movwf	CNT0
	clrwdt
D0:
	decfsz	CNT0, 1
	goto	D0
	decfsz	CNT1, 1
	goto	D1
	decfsz	CNT2, 1
	goto	D2
	return

	end
