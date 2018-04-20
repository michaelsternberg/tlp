;*******************************************************************************
;*                                                                             *
;*                    T H E   L E A R N I N G   P H O N E                      *
;*                                                                             *
;*                  for the Atari 8-bit Home Computer System                   *
;*                                                                             *
;*       Reverse engineered and documented assembly language source code       *
;*                                                                             *
;*                                     by                                      *
;*                                                                             *
;*                             [LIST GOES HERE]                                *
;*                                                                             *
;*                                                                             *
;*                               First Release                                 *
;*                                DD-MMM-YYYY                                  *
;*                                                                             *
;*                                Last Update                                  *
;*                                DD-MMM-YYYY                                  *
;*                                                                             *
;*         THE LEARNING PHONE was created by Vicent Wu / Lane Winner           *
;*              THE LEARNING PHONE was published by Atari Inc.                 *
;*                                                                             *
;*******************************************************************************
; Input file: tlp.bin

;*******************************************************************************
;*                                                                             *
;*                             M E M O R Y   M A P                             *
;*                                                                             *
;*******************************************************************************
; $0400..$057F	Table of addresses to start of each Display List #1 scan line
; $1000..$10C9	Display List #1
; $10C9..$130F	Display List #2
;
; $2010..$3DFF	8K frame buffer for Display List #1
; $4000..$9FFF	24K frame buffer for Display List #2
; $A000..$BFFF	8K Cart ROM

	.setcpu "6502"

.macro  RString       Arg
	.repeat .strlen(Arg), I
		.byte .strat(Arg, .strlen(Arg)-1-I)
	.endrep
.endmacro

.macro	ldi	arg1, arg2
	lda	#arg2
	sta	arg1
.endmacro

.macro	ori	arg1, arg2
	lda	arg1
	ora	#arg2
	sta	arg1
.endmacro

.macro	add16i8	arg1, arg2
	clc
	lda	arg1
	adc	#arg2
	sta	arg1
	bcc	:+
	inc	arg1+1
:
.endmacro

.macro	inc16 arg1
	inc	arg1
	bcc	:+
	inc	arg1+1
	:
.endmacro

	.segment "SEG1"

;*******************************************************************************
;*                                                                             *
;*                         S Y S T E M   S Y M B O L S                         *
;*                                                                             *
;*******************************************************************************

TSTDAT		:= $0007
POKMSK		:= $0010			; POKEY interrupt mask.
RTCLOK		:= $0012			; RTCLOK+0: increments every 65536 VBLANKS (NTSC 18.2 minutes)
						; RTCLOK+1: increments every 256 VBLANKS   (NTSC 4.27 seconds)
						; RTCLOK+2: increments every VBLANK	   (NTSC 1/60 second)
ICAX1Z		:= $002A
ATRACT		:= $004D			; Attract mode timer and flag 
VPRCED		:= $0202			; Vector to serial peripheral proceed line interrupt
VSERIN		:= $020A			; Vector to serial receive-data-ready interrupt
VTIMR1		:= $0210			; Vector to POKEY timer 1 interrupt
CDTMA1		:= $0226			; System timer one jump address
SRTIMR		:= $022B
SDMCTL		:= $022F			; Direct memory access control
DLIST		:= $0230			; Starting address of the display list.
SSKCTL		:= $0232			; Serial port control register
GPRIOR		:= $026F			; Priority selection register for screen objects
STICK0		:= $0278			; Joystick 0
STRIG0		:= $0284
SHFLOK		:= $02BE			; Flag for shift and control keys
PCOLR0		:= $02C0			; Color for player 0 and missile 0
COLOR1		:= $02C5			; Playfield 1 color register
COLOR2		:= $02C6			; Playfield 2 color register
COLOR3		:= $02C7			; Playfield 3 color register
COLOR4		:= $02C8			; Playfield 4 color register
HELPFG		:= $02DC			; Help key status
DVSTAT		:= $02EA			; Device status register.
CH		:= $02FC                        ; Keyboard character code.

; Device Control Block
DDEVIC		:= $0300			; Device bus ID (RS232 is $50).
DUNIT		:= $0301			; Device unit number.
DCOMND		:= $0302			; Device command.
DSTATS		:= $0303
DBUF		:= $0304
DTIMLO		:= $0306			; Time-out value for a handler in seconds
DBYT		:= $0308			; Number of bytes transferred to/from data buffer
DBYTLO		:= DBYT 			; Number of bytes transferred to/from data buffer
DBYTHI		:= $0308		        ; Number of bytes transferred to/from data buffer
DAUX1		:= $030A			; Device Command Arg 1
DAUX2		:= $030B			; Device Command Arg 1
HATABS		:= $031A			; Handler Address Table

; I/O Control Block
ICCOM		:= $0342
ICBA		:= $0344			; Address to buffer for read/write operations
ICBL		:= $0348			; IO buffer length
ICAX1		:= $034A
ICAX2		:= $034B


; GTIA (D000-D01F)

HPOSM0		:= $D004                        ; Position of touch screen cross-shaped cursor (right half)
HPOSM1		:= $D005                        ; Position of touch screen cross-shaped cursor (left half)
HPOSM2		:= $D006                        ; Position of "=" part of "F" in joystick function key mode
HPOSM3		:= $D007                        ; Position of "|" part of "F" in joystick function key mode
SIZEM		:= $D00C			; Size for all missiles
GRACTL		:= $D01D			; Turn on/off player missiles or latch triggers
CONSOL		:= $D01F                        ;

; POKEY (D200-D21F)

AUDCTL		:= $D208                        ; Audio control.
AUDF1		:= $D200                        ; Audio channel 1 frequency.
AUDF2		:= $D202                        ; Audio channel 2 frequency.
AUDF3		:= $D204                        ; Audio channel 3 frequency.
AUDF4		:= $D206                        ; Audio channel 4 frequency.
AUDC1		:= $D201                        ; Audio channel 1 control.
AUDC2		:= $D203                        ; Audio channel 2 control.
AUDC3		:= $D205                        ; Audio channel 3 control.
AUDC4		:= $D207                        ; Audio channel 4 control.
STIMER		:= $D209                        ; Start timer.
SKREST		:= $D20A                        ; Reset serial port status.
RANDOM		:= SKREST                       ; Random number generator.
SEROUT		:= $D20D                        ; Serial port input.
SERIN		:= SEROUT                       ; Serial port output.
IRQEN		:= $D20E                        ; Interrupt request (IRQ) enable.
IRQST		:= IRQEN                        ; IRQ status.
SKCTL		:= $D20F                        ; Serial port control.
SKSTAT		:= $D20F                        ; Serial port status.

; PIA (D300-D31F)

PIA		:= $D300                        ; Port A.
PORTA		:= PIA                          ; Port A.
PACTL		:= $D302                        ; Port A control.
PBCTL		:= $D303                        ; Port B control.

; ANTIC (D400-D41F)

DMACTL		:= $D400			; Direct Memory Access (DMA) control
PMBASE		:= $D407			; MSB of the player/missile base address
WSYNC		:= $D40A			; Wait for horizontal sync.

; OS ROM (D800-FFFF)

CIOV		:= $E456
SIOV		:= $E459			; Serial Input/Output utility entry point
SETVBV		:= $E45C
XITVBV		:= $E462


;*******************************************************************************
;*                                                                             *
;*                          C A R T   S Y M B O L S                            *
;*                                                                             *
;*******************************************************************************

; MPP Microbit 300 Driver Symbols
BAUD		:= $45				; Divide by n frequency for 300 baud. Noted in MPP Smart Term 4.1 Source Page 32
INPBIT          := $00FD			; Input bit
OUTBIT          := $00FE			; Output bit
INPBUF		:= $0F00
INPBFPT		:= $133E			; Used for offset to INPBUF
BUFLEN		:= $133F
OUTBFPT		:= $1340
character	:= $1347                        ; placeholder for now TODO
INP		:= $1348
OUTBUF		:= $1349
OUTINT		:= $134A
INPINT		:= $134B
ISTOP		:= $134C

; Other

L0070           := $0070
L0080           := $0080

CURSOR2_X	:= $009C			; X coord for cursor (zoomed display) (0->left boundary, 511->right)
CURSOR2_Y	:= $009E			; Y coord for cursor (zoomed display) (0->bottom of screen, 383->top)
byte_9F		:= $009F
CURSOR2_X_OLD	:= $00A0
CURSOR2_Y_OLD	:= $00A2
CURSOR1_X	:= $00A4			; X coord for cursor (full screen display) (0->left boundary, 311->right)
CURSOR1_Y	:= $00A6			; Y coord for cursor (full screen display) (0->bottom of screen, 191->top)
REND		:= $00A7			; Right mask for BLOCK
CURSOR1_X_OLD	:= $00A8
CURSOR1_Y_OLD	:= $00AA
LEND		:= $00AB			; Left mask for BLOCK
MARGIN2		:= $00AC			; 2-byte Left margin (zoomed display)
MARGIN1		:= $00AE			; 2-byte Left margin (full screen)
SCREEN_MODE	:= $00B0			; char mode $00->mode rewrite,$40->inverse video screen mode,$80->mode write,$C0->mode erase
CURRENT_BAUD	:= $00B1			; Current 850 baud rate: $FF->300 $00->1200
byte_B2		:= $00B2			; Used during init
IS_MPP		:= $00B2			; If Microbits 300 then 1 else 0
byte_B3		:= $00B3			; 7 = print_char2
byte_B4		:= $00B4			; $00->ESC {R,S,T,V} $01->ESC 2 (Load Coordinate) $02->ESC Q (SSF) $03->ESC Y (Load Echo commnd)  $04->ESC W (Load Memory Address command)  $05->ESC U (select mode 6) 
byte_B5		:= $00B5
DATA_MODE	:= $00B5			; $80->graphic (point, line, or block) $01->text
SERIN_BUF_IDX	:= $00B6			; Index or count of characters received from PLATO
CURRENT_CHSET	:= $00B7			; $00->M2 $01->M3 $02->M0 $03->M1
CURRENT_DL	:= $00B8			; Current Display List (80 or FF = DL #1, 00 = DL #2)
byte_B9		:= $00B9
SEND_FLG	:= $00B9			; $00->Nothing to send
byte_BA		:= $00BA			; 
IS_16K		:= $00BA			; TODO Flag for system < 48K RAM? (no support for zoomed display)
CORDX		:= $00BB			; 2-byte explicit X coordinate from PLATO
CORDY		:= $00BD			; 2-byte explicit Y coordinate from PLATO
byte_BC		:= $00BC
byte_BD		:= $00BD
byte_BE		:= $00BE
TOUCH_X		:= $00BF			; Current X position of simulated touch screen - resolution is 16 positions ($00-$0F)
TOUCH_Y		:= $00C0			; Current Y position of simulated touch screen - resolition is 16 positions ($00-$0F)
UI_MODE		:= $00C1			; Current user interface mode ($00->full-screen, $FF->zoomed, $01->touch screen, $FE->zoomed from touch screen, $02->joystick func keys)
JSTICK_DIR	:= $00C2			; Direction of joystick (normal 14->up, 7->right, etc, but center = 0)
CROSS_Y		:= $00C3			; Touch screen cross-shaped cursor vertical position
CROSS_X		:= $00C4			; Touch screen cross-shaped cursor horizontal position
JSTICK_FN_DLY	:= $00C5			; Counter that restricts handle events to no
JSTICK_TR_DLY	:= $00C6			; Counter that restricts trigger events to no more than 2 times per second.
JSTICK_TR	:= $00C7			; State of joystick trigger ($00=pressed, $FF->clear)
JSTICK_FN	:= $00C8			; Direction of joystick-mapped function keys: 0D->U(NEXT),02->D(BACK),0C->L(LAB),$12->R(DATA)
COMPR		:= $00C9			; Compressed graphics mode flag (full screen display)
CURRENT_SIZE	:= $00CA			; Character Size $00->size 0 (normal) $FF->size 2 (bold/doubled)
byte_CB		:= $00CB
byte_CC		:= $00CC
SERIN_FLG	:= $00CC			; SERIN_FLG
byte_CD		:= $00CD
off_CE		:= $00CE
FG_COLOR_DL2	:= $00D0			; Text luminance used in Display List #2 (zoomed)
BG_COLOR_DL2	:= $00D1			; Background / border hue/luminance used in Display List #2
FG_COLOR_DL1	:= $00D2			; Text luminance used in Display List #1 (small text)
BG_COLOR_DL1	:= $00D3			; Background / border hue/luminance used in Display List #1
XDLO		:= $00D4			; TODO Delta X when calculating slope?
XDHI		:= $00D5
YDLO		:= $00D6			; TODO Delta Y when calculating slope?
YDHI		:= $00D7
VAR		:= $00D8			; temporaries
TMP		:= $00D9
byte_DA		:= $00DA
PLATO_WORD	:= $00DB			; 16-bit PLATO word (See s0ascers 3.1.2.4.2)
off_DD		:= $00DD			; Temp variable
JSTICK_X	:= $00DD			; VBI: Current joystick direction X-axis (-1=left +1=right)
JSTICK_Y	:= $00DE			; VBI: Current joystick direction Y-axis (-1=up   +1=down)
DL2_TEMP	:= $00DF			; Pointer used while deriving display list #2
DL2_WIND	:= $00E1			; Pointer into 24K frame buffer for origin (0,0) of zoomed display
YOUT		:= $00E3			; absolute display address 00->TODO, $40->TODO, $80->TODO, $C0->TODO
off_E5		:= $00E5
byte_E5		:= $00E5
byte_E6		:= $00E6
plato_char	:= $00E7			; PLATO/ASCII character code to be sent to PLATO
CHSET_BASE 	:= $00E8			; current charset address lo/hi at E8/E9
byte_EA		:= $00EA
byte_EB		:= $00EB			; E0 or E1? TODO
off_EC		:= $00EC
X1LO		:= $00EC			; Line endpoint X1
X1HI		:= $00ED
Y1LO		:= $00EE			; Line endpoint Y1
Y1HI		:= $00EF
X0LO		:= $00F0			; Line endpoint X0
X0HI		:= $00F1			; 
Y0LO		:= $00F2			; Line endpoint Y0
Y0HI		:= $00F3			; 

TCRSX		:= $00F0			; block erase cursor position
TCRSY		:= $00F2			; block erase cursor position

SUMLO		:= $00F4			; vector draw work variables
SUMHI		:= $00F5			; 

INDLO		:= $00F6
INDHI		:= $00F7

INVX		:= $00F8			; X0<X1 or X1<X0
INVY		:= $00F9			; Y0<Y1 or Y1<Y0

off_FA		:= $00FA
CURSX		:= $00F8
CURSY		:= $00FA

DELLO		:= $00FA			; 
DELHI		:= $00FB
YM		:= $00FC			; Which axis (X or Y) is the major axis between 2 coords (1->Y-axis, 0->X-axis)
byte_FF		:= $00FF			; Initialized to #$FF at start

byte_1310	:= $1310
byte_1330	:= $1330
byte_133a	:= $133A
byte_133c	:= $133C
byte_133d	:= $133D
byte_133e	:= $133E
byte_133f	:= $133F
byte_1340	:= $1340
byte_1341	:= $1341
byte_1342	:= $1342
byte_1343	:= $1343
byte_1344	:= $1344
byte_1345	:= $1345
byte_1346	:= $1346			; Handler Device Type (R:)???
byte_1347	:= $1347
byte_1348	:= $1348
byte_134c	:= $134C
off_134d	:= $134D
byte_134f	:= $134F
byte_1350	:= $1350
word_1351	:= $1351
CURRENT_ECHO	:= $1353			; $00->local echo $80->remote echo
CURRENT_SELECT	:= $1355			; Which color aspect is modified with SELECT ($00->c, $80->b, $C0->t)
L2000           := $2000
L3E2E		:= $3E2E
SERIN_BUF	:= $3E2E			; Buffer for characters received from PLATO
L3E33           := $3E33
test_if_rom	:= $3E33
SCREEN_24K	:= $4000			; Start of 24k framebuffer for video
L6000           := $6000
L8000           := $8000

ch_mem_m2_DL1	= $0C00				; Base address for programmable font M2
ch_mem_m3_DL1	= $0D80				; Base address for programmable font M3

; Keyboard scan codes
key_0		= $32
key_1		= $1F
key_3		= $1A
key_a		= $3F
key_b		= $15
key_c		= $12
key_d		= $3A
key_e		= $2A
key_f		= $38
key_h		= $39
key_l		= $00
key_m		= $25
key_n		= $23
key_p		= $0A
key_s		= $3E
key_t		= $2D
key_z		= $17
key_apos	= $73					; apostrophe / single-quote
key_at		= $75					; '@'
key_hash	= $5A					; '#'
key_amper	= $5B					; '&'
key_tab		= $2C
key_backs	= $34					; backspace
key_return	= $0C
key_space	= $21
key_equal	= $0F					; '='
key_pipe	= $4F					; '='
key_gt		= $37					; '>'
key_lt		= $36					; '<'
key_plus	= $06					; '+'
key_bkslash	= $46
key_minus 	= $0E					; '-'
key_mult	= $07					; '*'
key_caret	= $47
key_div		= $26					; '/'
key_caps	= $3C					; 'CAPS/LOWR'
key_atari	= $27					; '/|\'

mod_shift	= $40
mod_ctrl	= $80

;*******************************************************************************
;*                                                                             *
;*                                 cart_start                                  *
;*                                                                             *
;*                    Second entry point after system restart                  *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; After a cold or warm start, the OS runs the cart_init routine found towards
; the end of the cart's address space, then jumps to here.
 
cart_start:					; A000
	jsr     sub_register_R			; Add R device to HATABS
	jsr     init_graphics			; Initialize display lists, colors
	jsr     display_title			; Display program title and copyright

	ldy     #open_k-tab_iocb		; 
	jsr     call_cio_or_err			; Open K: on channel #2

;**(n) Attempt to open an Atari direct connect modem using T: handler **********
	ldy     #open_t-tab_iocb 		; 
	jsr     call_cio			; Try to open T: on channel #1
	bmi     :++				; If cio returned error then skip ahead

;**(n) Atari direct-connect modem detected *************************************
	lda     #$1A    			; Move cursor
	sta     CURSOR2_X
	ldy     #$33    			; String length - 1
	lda     #<LB8DF				; "After the phone has a high..."
	ldx     #>LB8DF				;
	jsr     print_string			;

:	lda     CH				; Wait for key press
	cmp     #$FF    			;
	beq     :-				; 

	ldx     #$FF    			; Some key press occurred
	stx     CH				; Clear keyboard register

;** (n) If user presses '1' instead of RETURN try to set baud to 1200 **********
	cmp     #key_1				; if last key press <> '1'
	bne     :+++				; then skip ahead
	jsr     display_title			; otherwise clear screen and..

;** (n) Try changing baud rate and re-opening channel #1 ***********************
:	jsr     close_ch1			; Close CIO channel #1
	jsr     open_modem			; Attempt to open R: on channel #1 at CURRENT_BAUD
	bmi     :+				; if unsuccessful then default to Microbits 300
	lda     #<LB91C				; otherwise print "1200 baud"
	ldx     #>LB91C				; 
	ldy     #$08    			; String length - 1
	jsr     print_string			; 
	jmp     kernel   			; and proceed to main loop

;** (n) If all else fails assume Microbits 300 ********************************
:	jsr     config_mpp			; 
	jmp     kernel   			; Skip test and goto main loop

;** (n) Test 850 or direct-connect modem **************************************
:	lda	#$4C				; x100 1100
	jsr	test_baud			; Send test??
:	lda     #$46    			; x100 0110 
	jsr     test_baud			; Send test??
	lda     DVSTAT+1			; Keep trying until successful...
	bpl     :-				; ...then fall through to main loop.

;*******************************************************************************
;*                                                                             *
;*                                  kernel                                     *
;*                                                                             *
;*                             main program loop                               *
;*                                                                             *
;*******************************************************************************
kernel:						; A05E
	jsr     proc_keyboard			; Process/send keyboard events
	jsr     proc_joystick			; Process/send joystick events
	jsr     send_data			; Send data to PLATO if any

	lda     SERIN_FLG			; Any data received?
	beq     kernel   			; No? -->

	jsr     proc_serial_in			; Process incoming data
	bcc     kernel   			; Any more work? No? -->
	jsr     draw				; Process graphic data

	lda     #$00    			; 
	sta     SERIN_BUF_IDX  			; Clear counter/index
	beq     kernel   			; -->

;*******************************************************************************
;*                                                                             *
;*                              proc_serial_in                                 *
;*                                                                             *
;*           Read data from serial. Could be instruction or data.              *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; This subroutine reads byte from the serial port. The byte could be:
; a) the second character in an escape sequence (previous character was ESC). 
; b) a control code (ASCII code in non-printable range (< #$20)
; c) an alpha code (data mode is alpha/text and ASCII code in printable range)
; d) a graphics code (data mode is graphic)
;
; Returns to kernel with carry flag set or unset.
; If carry is clear then there's nothing left to do in kernel and  the main loop
; can begin from the top.

proc_serial_in:					; A079
	ldy     #read_ch1-tab_iocb		; Prepare CIO for get char
	jsr     call_cio_or_err			; A = char read from CIO
	and     #$7F    			; Remove/ignore parity bit

;** Process escape sequence ****************************************************
	bit     byte_B3 			; Bit 7 set if prev char was ESC
	bmi     proc_esc_seq   			; 

;** Process control code *******************************************************
	cmp     #$20    			; is it a control code?
	bcs     :++				; no? skip.

	jsr     proc_control_ch 		; yes? process control code.
:	clc             			; All done. Tell kernel
	rts             			; ...to go to next iteration.

;** Process character depending on current data mode ***************************
:	ldx     SERIN_BUF_IDX			; Get PLATO input buffer index
	sta     SERIN_BUF,x 			; Store char (A) to buffer
	inx             			; 
	stx     SERIN_BUF_IDX  			; Increment index

	ldy     DATA_MODE 			; Is mode currently $01->alpha?
	bpl     :+				; Yes? skip ahead.

;** Here if data mode is $80->graphic. *****************************************
;** If data >= #$60 return to kernel with more work to do. *********************
	cmp     #$60    			; 0110 0000
	bcs     :--				; Return with carry set.

	cmp     #$40    			; 
	rts             			; A09F 60                       `

;** Here if data mode is $01->alpha. Return to kernel with more work to do *****
:	cpx     DATA_MODE 			; 
	rts             			; Return with carry set.

;*******************************************************************************
;*                                                                             *
;*                                   draw                                      *
;*                                                                             *
;*      Depending on current data mode, draw point, line, block, or text       *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
draw:						; ABA3
	ldy     #$00    			; 
	sty     SERIN_BUF_IDX    		; Clear 
	bvc     :+++				; A0A7 50 1C                    P.

	ldy     byte_B4    			; 
	cpy     #$05    			; Mode 6?
	beq     :+				; yes? skip to unpack_word.

; Unstash $B5 from $1354, Unset bit 6 from $B3 *********************************
	jsr     sub_a120   			; A0AF 20 20 A1                   .
	tya             			; A0B2 98                       .
	bne     :+				; A0B3 D0 01                    ..
	rts             			; A0B5 60                       `

:	dey             			; A0B6 88                       .
	beq     :+				; A0B7 F0 03                    ..
	jsr     unpack_word

;** Trick RTS to jump to vector by pushing the MSB/LSB to the stack ***********
:	lda     LBAE2,y 			; Get MSB of subroutine
	pha             			; 

	lda     LBAE7,y 			; Get LSB of subroutine
	pha             			; 
	rts             			; Goto vector

:	ldx     byte_B3 			; Get jump table offset (7 = print_char2)
	lda     LBACA,x 			; Get MSB of subroutine
	beq     :+				; RTS to main loop if subroutine is undefined

	pha             			; Otherwise trick RTS to return to 
	lda     LBAD2,x 			; jump table subroutine
	pha             			; 
:	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                               proc_esc_seq                                  *
;*                                                                             *
;*           Remove ESC flag and that signaled previous char was ESC.          *
;*                                                                             *
;*******************************************************************************
proc_esc_seq:					; A0D2
	asl     byte_B3 			; Strip bit 7 flag that told us
	lsr     byte_B3 			; ... prev char was ESC.
	jsr     proc_esc_seq2			; 
	clc             			; Clear carry to tell kernel
:	rts             			; ...all pending work is done.

;*******************************************************************************
;*                                                                             *
;*                               proc_esc_seq2                                 *
;*                                                                             *
;*        Examine which escape character was received and do what it says      *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This subroutine examines the 

proc_esc_seq2:					; A0DB
;** If ESC sequence is > ESC Z then it's undefined, return *********************
	cmp     #$5B    			; is escape sequence > "Z"?
	bcs     :-				; yes? undefined. RTS

	cmp     #$3D    			; is sequence ESC '=' (color)?
	beq     get_colorf   			; yes? Jump.

;** If ESC sequence is >= ESC ! then use character code as-is as index *********
	cmp     #$20    			; is ESC seq >= "!"?
	bcs     :+				; yes? Skip "adc #$20"

;** If ESC sequence is < ESC ! then add 32 *************************************
	adc     #$20    			; Change offset into jump
	bcc     proc_control_ch 		; ...table and process

;** If ESC 2 doesn't have a lookup table entry, check for it here **************
:	cmp     #'2'				; if ESC 2 (or GS?) then process 
	beq     load_coord   			; ..."Load Coordinate".

;** If ESC sequence < ESC @ then it's undefined, return ************************
	cmp     #'@'    			; Anything else less than 
	bcc     :--				; ...ESC @ is undefined. RTS

;*******************************************************************************
;*                                                                             *
;*                              proc_control_ch                                *
;*                                                                             *
;*              Jumps to a subroutine for a received control code.             *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Control codes are those less than $20 (space). This subroutine derives
; an address to a subroutine that will handle the details of the control code. 
; Any unexpected control codes should result in an RTS.
;
; (excerpt from s0ascers 3.2.3.1)
;-------------------------------------------------------------------------------
; Control codes and escape sequences are used to control the terminal's 
; mode (text, point, line, etc.) and to issue commands (such as erase screen, 
; set writing mode, and so forth).  
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 6.1)
;-------------------------------------------------------------------------------
;  CONTROL    HEX
;  CHARACTER  CODE
;    BS       08      Backspace.  Moves one character width back.
;    HT       09      Tab.  Moves one character width.
;    LF       0A      Linefeed.  Moves one character height down.
;    VT       0B      Vertical tab.  Moves one character height up.
;    FF       0C      Form feed.  Set (X,Y) position to top of page.
;    CR       0D      Carriage return.  Set (X,Y) to margin on next line.
;    EM       19      Selects block write/erase mode (mode 4).
;    ESC      1B      Causes terminal to examine the next character to 
;		      determine if it is a valid escape sequence.
;    FS       1C      Selects point-plot mode (mode 0).
;    GS       1D      Selects draw line mode (mode 1).
;    US       1F      Selects alpha mode (mode 3).
; 
;   Note: control codes received not included here should be ignored.
;-------------------------------------------------------------------------------
proc_control_ch:				; A0F3
	tax             			; Save control code into X

;** Lookup address for control char's subroutine from table ********************
	clc             			; 
	lda     #<(esc_seq_ff-1) 		; Lookup LSB for subroutine using
	adc     JUMTAB,x 			; ...control code as offset into table.
	tay             			; Stash into Y

	lda     #$00    			; 
	sta     SERIN_BUF_IDX  			; 
	adc     #>(esc_seq_ff-1) 		; Set MSB for subroutine (all are page A3)

;** Trick RTS to jump to the derived address using address found on stack ******
	pha             			; Push subroutine's MSB
	tya             			; 
	pha             			; Push subroutine's LSB
	rts             			; Jump to control code routine

;*******************************************************************************
;*                                                                             *
;*                                get_colorf                                   *
;*                                                                             *
;*                    Received ESC = from PLATO host (color)
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Get foreground and background color bytes and do nothing (unsupported)
get_colorf:					; A185
	ldx     #$02    			; Read 2 bytes
	lda     #$00    			; and do nothing
	beq     LA111   			; -->

;*******************************************************************************
;*                                                                             *
;*                                load_coord                                   *
;*                                                                             *
;*                         ESC 2 - 
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
load_coord:					; A10B
	ror     byte_B5 			; Let $B5 = $B5 / 2
	lda     #$01    			; Let A = 1
	bne     :+				; --> Save A to B4

;*******************************************************************************
;*                                                                             *
;*                                ???????????                                  *
;*                                                                             *
;*                    ?????????????????????????????????                        *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Stashes $B5 into $1354, Sets $B4 = A, $B5 = X, sets bit 6 in $B3
;
; Parameters:
; X = Number of bytes to read TODO?
; A = index into jump table TODO?
LA111:  ldy     byte_B5 			; 
	sty     $1354   			; 
	stx     byte_B5 			; 
:	sta     byte_B4     			; 

	lda     byte_B3 			; 
	ora     #$40    			; Set bit 6 of A and save in $B3
	bne     :+				; -->

;*******************************************************************************
;*                                                                             *
;*                                ???????????                                  *
;*                                                                             *
;*                    ?????????????????????????????????                        *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Unstashes $B5 from $1354, clears bit 6 in $B3
sub_a120:  
	lda     $1354   			; Let A = $1354
	sta     byte_B5 			; Let $B5 = A

	lda     byte_B3 			; Clear bit 6 of A and save in $B3
	and     #$BF    			; Let $B3 = A && 1011 1111
:	sta     byte_B3 			; Let $B3 = A
:	rts             			; 

; ----------------------------------------------------------------------------
sub_a12c:
send_data:
	lda     SEND_FLG     			; Anything to send?
	beq     :-				; No? Return to kernel
	jmp     (off_134d)			; 

;*******************************************************************************
;*                                                                             *
;*                                ?????????????                                *
;*                                                                             *
;*                 ??????????????????????????????????????????                  *
;*                                                                             *
;*******************************************************************************
sub_a133:
	ldy     PLATO_WORD+1  			; A133 A4 DC                    ..
	lda     PLATO_WORD     			; A135 A5 DB                    ..
	ldx     byte_FF 			; A137 A6 FF                    ..
	bpl     :+++				; A139 10 10                    ..

	iny             			; A13B C8                       .
	bne     :+				; A13C D0 05                    ..

	tax             			; A13E AA                       .
	bmi     :++				; A13F 30 03                    0.

	sta     byte_FF 			; A141 85 FF                    ..
:	rts             			; A143 60                       `

:	inx             			; A144 E8                       .
	stx     byte_134f
	jmp     sub_a1fe

:	bit     byte_134f
	bpl     :+
	rts             			; A150 60                       `

:	ldx     byte_FF 			; A151 A6 FF                    ..
	beq     :+

	dex             			; A155 CA                       .
	beq     :++				; A156 F0 15                    ..

	dex             			; A158 CA                       .
	beq     LA18C   			; A159 F0 31                    .1

	dex             			; A15B CA                       .
	beq     :+++				; A15C F0 16                    ..

	dex             			; A15E CA                       .
	beq     LA180   			; A15F F0 1F                    ..
	rts             			; A161 60                       `

:	sty     off_CE+1
	sta     off_CE
	ldy     #$00    			; A166 A0 00                    ..
	lda     (off_CE),y
	jmp     LA1DD   			; A16A 4C DD A1                 L..

:	sty     off_CE+1
	sta     off_CE
	jmp     sub_a1fe

:	sty     off_134d+1
	sta     off_134d
	dex             			; A17A CA                       .
	stx     SEND_FLG     			; A17B 86 B9                    ..
	jmp     sub_a1fe

LA180:  sty     off_134d+1
	sta     off_134d
	jsr     sub_a1fe
	jmp     (off_134d)

LA18C:  bit     byte_1350
	bmi     :+
	sta     word_1351
	sty     word_1351+1
	dex             			; A197 CA                       .
	stx     byte_1350
	rts             			; A19B 60                       `

:	tya             			; A19C 98                       .
	ldy     #$00    			; A19D A0 00                    ..
	sta     (off_CE),y
	iny             			; A1A1 C8                       .
	dec     word_1351   			; A1A2 CE 51 13                 .Q.
	bne     :+				; A1A5 D0 09                    ..
	tya             			; A1A7 98                       .
	ldx     word_1351+1
	beq     LA1C8   			; A1AB F0 1B                    ..
	dec     word_1351+1
:	lda     $DB     			; A1B0 A5 DB                    ..
	sta     (off_CE),y
	dec     word_1351
	bne     :++				; A1B7 D0 0B                    ..
	ldx     word_1351+1
	beq     :+
	dec     word_1351+1
	bvs     :++				; A1C1 70 01                    p.
:	clv             			; A1C3 B8                       .
:	lda     #$02    			; A1C4 A9 02                    ..
	bne     :+				; A1C6 D0 01                    ..
LA1C8:  clv             			; A1C8 B8                       .
:	php             			; A1C9 08                       .
	clc             			; A1CA 18                       .
	adc     off_CE
	sta     off_CE
	bcc     :+
	inc     off_CE+1
:	plp             			; A1D3 28                       (
	bvs     :+				; A1D4 70 06                    p.
	jsr     sub_a1fe
	inc     byte_1350
:	rts             			; A1DC 60                       `

; ----------------------------------------------------------------------------
LA1DD:  lda     #$1B    			; Send ESC
	jsr     send_to_plato2			;

	ldy     #$00    			; A1E2 A0 00                    ..
	sty     $E7     			; A1E4 84 E7                    ..

	lda     (off_CE),y
	tay             			; Stash A

	asl     a       			; A1E9 0A                       .
	rol     $E7     			; A1EA 26 E7                    &.
	asl     a       			; A1EC 0A                       .
	rol     $E7     			; A1ED 26 E7                    &.

	tya             			; Restore A
	and     #$3F    			; Clear bits 7,6
	ora     #$40    			; Force bit 6
	jsr     send_to_plato2

	lda     $E7     			; A1F7 A5 E7                    ..
	ora     #$68    			; A1F9 09 68                    .h
	jsr     send_to_plato2

sub_a1fe:
	jsr     sub_a120   			; A1FE 20 20 A1                   .

	lda     #$FF    			; A201 A9 FF                    ..
	sta     byte_FF 			; A203 85 FF                    ..

	lda     #$1B    			; A205 A9 1B                    ..
	jsr     send_to_plato2

	lda     #$46    			; A20A A9 46                    .F
	jsr     send_to_plato2

	lda     #$68    			; A20F A9 68                    .h
	jmp     send_to_plato2

;*******************************************************************************
;*                                                                             *
;*                                init_graphics                                *
;*                                                                             *
;*                 Initialize display lists, colors, player-missiles           *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; This subroutine initializes 2 display lists, colors, player missiles.
;
; Display List 1 is a mostly straightforward ANTIC mode F screen. Except that 
; screen RAM shifts from a range beginning at $2010 to a 2nd range beginning 
; at $3000 a little after midway down the screen.
;
; Display List 2 is an ANTIC mode F screen with horizontal and vertical 
; scrolling.
;
; Display List 1         Display List 2
; --------------         --------------
; $1000: $70 8 SCANS     $10CA: $70
; $1001: $70 8 SCANS     $10CB: $70
; $1002: $70 8 SCANS     $10CC: $70
; $1003: $4F ANTIC F     $10CD: $4F
; $1004: $10 SCRNLO      $10CE: $00 SCRNLO
; $1005: $20 SCRNHI      $10CD: $40 SCRNHI
; $1006: $0F ANTIC F     $10CE: $4F
; ...                    $10CF: $40 SCRNLO
; ...                    $10D0: $40 SCRNHI
; ...                    ...
; ...                    $130A: $4F ANTIC F
; ...                    $130B: $C0 SCRNLO
; $10C6: $0F ANTIC F     $130C: $6F SCRNHI
; $10C7: $41 WAIT SYNC   $130C: $41 WAIT SYNC
; $10C8: $00 DLSTLO      $130D: $CA DLSTLO
; $10C9: $10 DLSTHI      $130E: $10 DLSTHI

sub_a214:					; A214
init_graphics:
	lda     #$00    			; 
	sta     DMACTL  			; Turn off ANTIC
	sta     GRACTL				; Turn off PMG, unlatch triggers
	sta     SHFLOK				; Force keyboard to lower case

;** (n) Clear RAM at 0080-00FF and  0580-05FF **********************************
	ldx     #$7F    			; Clear 128 bytes at ...
:       sta     $0580,x 			; 0580-05FF and ...
	sta     L0080,x 			; 0080-00FF 
	dex             			; 
	bpl     :-      			; End Loop

;** (n) TODO Why storing FF in these two locations??? **************************
	stx     CURRENT_DL			; display list for full-screen
	stx     byte_FF 			; Store FF in byte_FF TODO

;** (n) Prepare values for head of display lists *******************************
	lda     #$70                            ;
	ldx     #$02    			; 
	stx     CURRENT_CHSET			; Select character set M0 ($02->M0)
	stx     byte_B2				; Let byte_B2 = 2 TODO

;** (n) Write head of display list # 1 *****************************************
	inx             			; Store 3 x $70 
:       sta     $10C9,x 			; at $1000 and $10CA
	sta     $0FFF,x 			; 8 blank scan lines each
	dex             			; 
	bne     :-      			; End Loop

;** (n) Point to screen RAM at $2010 in display list #1 ************************
	lda     #<$2010    			; 
	sta     $1004   			; 
	sta     SUMLO				; Store Screen location
	lda     #>$2010    			; in zero page varibles, too
	sta     $1005   			; 
	sta     SUMHI				; 

;** (n) Write body of display list #1 ******************************************
	lda     #$0F    			; Store entry for ANTIC mode F
:       sta     $1006,x 			; in body of display list
	inx             			; 
	cpx     #$C1    			; 
	bne     :-      			; End Loop

;** (n) Write 2 display list entries to point to screen RAM ********************
	lda     #$4F    			; Write ANTIC mode F & screen
	sta     $1003   			; location at top of disp list
	sta     $106B   			; again after 102 mode F lines

;** (n) Point to screen RAM at $3000 in display list #1 ************************
	lda     #<$3000				;
	sta     $106C   			; point to screen RAM to $3000
	lda     #>$3000				;
	sta     $106D   			; 

;** (n) Write tail end of display list #1 **************************************
	lda     #$41    			; Write Wait for sync
	sta     $1006,x 			; to bottom of list
	sta     $130D   			; 
	lda     #<$1000    			; Tell ANTIC to jump
	sta     $1007,x 			; back to the top of the display
	sta     DLIST				; list at $1000.
	lda     #>$1000    			;
	sta     $1008,x 			; Also register the new display
	sta     DLIST+1 			; list loc with the hardware

;** (n) Screen RAM for display list #2 will begin at $4000 *********************
	lda     #<SCREEN_24K			; Init pointers to 1st scan line in DL2.
	sta     DL2_TEMP			; The difference between the two 
	sta     DL2_WIND			; pointers is that DL2 will 
	lda     #>SCREEN_24K			; get clobbered during processing
	sta     DL2_TEMP+1			; and ZOOM is changed only 
	sta     DL2_WIND+1 			; when panning with joystick.

;** (n) Call sub to derive body of display list #2 *****************************
	jsr     create_DL2_body 		; Initialize the zoomed display

;** (n) Write tail of display list #2 ******************************************
	lda     #$CA    			; Tell ANTIC to jump
	sta     $130E   			; back to the top of the display
	lda     #$10    			; list at $10CA.
	sta     $130F   			;

;** (n) Create a table of addresses to 192 display list #1 scan lines **********
	ldx     #$00    			; Create a table of pointers...
:	lda     SUMHI				; to the screen RAM for 192 scan
	sta     $04C0,x 			; lines. LSB in $0400-$04BF...
	lda     SUMLO				; MSB in $04C0-$057F...
	sta     $0400,x 			; starting with $2010, $0238, ..., $3DE8
	inx             			;
	cpx     #$C0    			; Quit at 192 iterations
	beq	:+                              ;
	lda     SUMLO				;
	adc     #$28    			; Add 40 bytes (1 row)
	sta     SUMLO				;
	bcc	:-                              ;
	inc     SUMHI				;
	bne	:-				; End Loop

;** (n) Configure Player Missile Graphics ***************************************
:	ldi     GRACTL, $03    			; Enable display of PMG

	lda     #$04    			; TODO Confused - page 4 contains pointers to scan line addresses
	sta     PMBASE  			; PMG will be stored in page 4

	lda     #$55    			; SIZEM = 01 01 01 01
	sta     SIZEM   			; Set missiles 0-3 to double wide

	lda     #$00    			; Loop through each missile
	ldx     #$03    			; Set horiz pos to 0 (offscreen)
:       sta     HPOSM0,x			;
	dex             			;
	bpl     :-      			; End Loop

;** (n) *************************************************************************
	ldx     #$32    			; Set initial graphic coordinate...
	stx     CROSS_X				; ...for touch screen cross-shaped cursor.

	ldx     #$0F    			; Set initial simulated touch screen
	stx     TOUCH_Y 			; position to 16

	ldx     #$07    			; Load bitmaps for missiles.
	stx     byte_B3 			; 
:       lda     LBA67,x 			; One is a large 'F' and the ...
	sta     $058C,x 			; ...other is a cross-shaped cursor.
	dex             			;
	bpl     :-      			; 

	stx     JSTICK_TR 			; Initialize trigger state to -1

;** (n) Set default background and border color for Display List #1 *************
	lda     #$01    			; Set initial Y location for touch screen 
	sta     CROSS_Y 			; cross-shaped cursor.
	sta     byte_B5 			; Set priority for screen objects...
	sta     GPRIOR  			; 0000 0001 = Player 0-3, Playfied 0-3, BAK
	lda     #$16				; $10 = rust + $06 luminance
	sta     COLOR4  			; for the border and background
	sta     COLOR2  			; to hue: 1 (orange), luminance: 6
	sta     BG_COLOR_DL1    		; Save color value to RAM

;** (n) Change Player/Missile colors to something different than background *****
	jsr     set_pm_colors

;** (n) Set default background and border color for Display List #2 *************
	lda     #$94    			; $90 = dark blue + $04 luminance
	sta     BG_COLOR_DL2    		; Save color value to RAM

;** (n) Set default text luminance **********************************************
	lda     #$E1    			; Default text luminance value for Display List #1
	sta     COLOR1  			; Save value to color register
	sta     FG_COLOR_DL1    		; Save color value to RAM

	lda     #$CA    			; Default text luminance value for Display List #2
	sta     FG_COLOR_DL2    		; Save color value to RAM

;** (n) Store base address of 6x6 charset in Zero Page RAM **********************
	lda     #>ch_mem_m0_DL1
	sta     CHSET_BASE+1			; Save MSB of ch_mem_m0_DL1 to RAM

	lda     #<ch_mem_m0_DL1
	sta     CHSET_BASE			; Save LSB of ch_mem_m0_DL1 to RAM

;** (n) Disable break key interrupt *********************************************
	lda     POKMSK				; 1100 000 is the default on power up
	and     #$7F    			; Clear flag for break key interrupt
	jsr     sub_irqen			; Enable new set of interrupts

;** (n) Set system timer for vector #7  ******************************************
	ldy     #<sub_b013      		; LSB of new vector routine
	ldx     #>sub_b013      		; MSB of new vector routine
	lda     #$07    			; Number of the vector to change
	jmp     SETVBV  			; Set system timers (SETVBV will rts)

;*******************************************************************************
;*                                                                             *
;*                              set_pm_colors                                  *
;*                                                                             *
;*      Set Player/Missile Colors to something different than background.      *
;*                                                                             *
;*******************************************************************************
set_pm_colors:					; A324
	tay             			; Let Y = current background color
	clc             			;
	adc     #$04    			; Increment luminance by 4
	and     #$0F    			; Clear hue bits
	sta     TMP	 			; Save new luminance to D9
	tya             			; Retrieve original background color
	and     #$F0    			; Clear luminance bits
	clc             			;
	adc     #$30    			; Increment hue by 3
	ora     TMP	 			; Merge new hue with new luminance

	ldx     #$03    			;
:	sta     PCOLR0,x			; Store new hue and luminance
	dex             			; to PCOLR0-PCOLR3
	bpl     :-      			; End Loop
	rts             			; Return with N flag set

;*******************************************************************************
;*                                                                             *
;*                               display_title                                 *
;*                                                                             *
;*                   Print program title and copyright notice                  *
;*                                                                             *
;*******************************************************************************

display_title:					; A33D
;** (1) Clear screen ***********************************************************
	jsr     esc_seq_ff			; Clear screen
	jsr     proc_ff   			; Set X,Y to top of page.

;** (2) Print "WELCOME TO THE LEARNING PHONE" **********************************
	lda     #$50    			; Set X coordinate for text
	sta     CURSOR1_X     			; Save X coordinate for full-screen display
	sta     CURSOR2_X     			; Save X coordinate for zoomed display
	ldy     #$1C    			; String length - 1
	lda     #<LB8C2				; "WELCOME..."
	ldx     #>LB8C2
	jsr     print_string
	jsr     proc_lf   			; A352 20 C2 A3                  ..

;** (3) Print "COPYRIGHT 1984 ATARI" *******************************************
	lda     #$67    			; Set X coordinate for text
	sta     CURSOR1_X     			; Save X coordinate for full-screen display
	sta     CURSOR2_X     			; Save X coordinate for zoomed display
	ldy     #$13    			; String length - 1
	lda     #<LB8AE				; "COPYRIGHT..."
	ldx     #>LB8AE
	jsr     print_string
	jmp     proc_lf   			; A364 4C C2 A3                 L..

;*******************************************************************************
;*                                                                             *
;*                                esc_seq_ff                                   *
;*                                                                             *
;*               Received ESC FF from PLATO host (Erase Screen)                *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.4)  
;-------------------------------------------------------------------------------
;  Erase Screen (ESC FF, 1B 0C hex)
;
; This erases the screen.  The (X,Y) position should not be changed.  When the 
; screen is erased all dots must be turned 'off' in monochrome or set to the 
; background color in color.  The palette should be reset if the underlying 
; color hardware is palette-based (see section 3.2.3.1.8).
;-------------------------------------------------------------------------------
esc_seq_ff:					; A367
	jmp     clear_screen

;*******************************************************************************
;*                                                                             *
;*                               sel_data_mode                                 *
;*                                                                             *
;*        Received ESC {EM,FS,GS,US} from PLATO to change drawing mode         *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This subroutine is called when one of the following control codes have
; been received from PLATO: ($19, $1C, $1D, $1F). See s0ascers Appendix B.
; 
; This changes the terminal's intermediate mode. In s0ascerrs, this is called 
; the "data mode" that sits between the higher-level "terminal modes" (PLATO vs 
; TTY) and the lower-level "screen modes" (rewrite, write, erase, and inverse).
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.1.2)
;-------------------------------------------------------------------------------
; The intermediate level of 'mode' is how the resident interprets the data it 
; receives (data mode).  For example, the resident will be in text (character 
; generation) mode when displaying text, line mode when drawing lines, block
; mode when drawing filled boxes, etc.  There are eight or more of these modes,
; depending on how one counts.
;-------------------------------------------------------------------------------
;
; Parameters:
; X: control code received from PLATO
; 
; The original control code is stripped of all but the lowest 3 bits leaving
; a simpler value. 
;
; control        AND 111 = x -> lookup value
; $19 = 0001 1001 -> 001 = 1 -> $80 -> (PLATO mode 4) block write/erase mode 
; $1C = 0001 1100 -> 100 = 4 -> $80 -> (PLATO mode 0) point-plot mode
; $1D = 0001 1101 -> 101 = 5 -> $80 -> (PLATO mode 1) draw line mode 
; $1F = 0001 1111 -> 111 = 7 -> $01 -> (PLATO mode 3) alpha mode
;
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1)
;-------------------------------------------------------------------------------
; Control codes and escape sequences are used to control the terminal's mode 
; (text, point, line, etc.) and to issue commands (such as erase screen, set 
; writing mode, and so forth).
;-------------------------------------------------------------------------------
sel_data_mode:					; A36A
;** Convert control codes to an 0-7 index and save to byte_B3 ******************
	txa             			; Let A = original control code
	and     #$07    			; Modulus 8 to use as index
	sta     byte_B3 			; Save index (4->point,5->line,1->block,7->text)

;** Use index into table *******************************************************
	tax             			; Use index to get another value from lookup
	lda     LBADA,x 			; ...table ($80->graphic, $01->text)
	sta     byte_B5 			; Save lookup value to B5

;** Clear TODO *****************************************************************
	ldx     #$00    			; 
	stx     $DA     			; Clear $DA

	rts             			; A379 60                       `

;*******************************************************************************
;*                                                                             *
;*                              sel_screen_mode                                *
;*                                                                             *
;*          Select inverse or write or erase or rewrite video mode             *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This subroutine is called when one of the following escape sequences have
; been received from PLATO: ESC {DC1,DC2,DC3,DC4}. See s0ascers Appendix B.
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1)
;-------------------------------------------------------------------------------
; There are four 'screen modes' that control how graphics are written to the 
; screen.  They are called mode write, mode erase, mode rewrite and mode 
; inverse.  All four screen modes are available in text mode.  In the other 
; data modes, mode rewrite reduces to mode write and mode inverse reduces to
; mode erase (i.e., a line drawn in mode inverse will be black on a monochrome 
;-------------------------------------------------------------------------------
; Parameters:
; X: escape sequence received from PLATO
; 
; The original escape sequence is stripped of all but the lowest 2 bits leaving
; a simpler value. 
;
; esc sequence AND 0000 0011 = x -> SCREEN_MODE
; $11->DC1 = 0001 0001 -> 01 = 1 -> $40 -> Select mode inverse.
; $12->DC2 = 0001 0010 -> 10 = 2 -> $80 -> Select mode write.
; $13->DC3 = 0001 0011 -> 11 = 3 -> $C0 -> Select mode erase.
; $14->DC4 = 0001 0100 -> 00 = 0 -> $00 -> Select mode rewrite.
;-------------------------------------------------------------------------------
sel_screen_mode:
	txa             			; Let A = original escape code
	and     #$03    			; Strip all but 2 lowest bits
	lsr     a       			; Rotate so bits are on left.
	ror     a       			; This will be helpful when 
	ror     a       			; ...used with BIT later.
	sta     SCREEN_MODE    			; Save screen mode
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                              sel_term_plato                                 *
;*                                                                             *
;*          Received command from the PLATO host to enter PLATO mode.          *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Change echo to full duplex.
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.1.2)
;-------------------------------------------------------------------------------
; The word 'mode' is used in three different ways when discussing the resident's
; operation.  
;
; The highest level is the PLATO versus TTY mode.  In PLATO mode graphics 
; commands are received and interpreted.  In TTY mode only very simple functions
; are performed.  Therefore a PLATO resident must actually be two programs in 
; one: the first is a 'dumb TTY' emulator, which is used to get the user into 
; the PLATO host; the second is the PLATO resident proper.
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.1)
;-------------------------------------------------------------------------------
; The PLATO system runs in full duplex.  That is, the host, rather than the 
; modem, network or terminal, echos all characters to the screen.
;-------------------------------------------------------------------------------
; (excerpt fro s0ascers 3.2.3.1.10)
;-------------------------------------------------------------------------------
; The PLATO, TTY and 'graphics' modes of resident operation are selected by 
; three escape sequences (ESC {STX,ETX,SOH}).  ESC STX (1B 02 hex) selects PLATO
; operation.  The host will always send this command to the terminal at the 
; beginning of the session.
;-------------------------------------------------------------------------------
sel_term_plato:					; A383
	lda     #$80    			; $80->remote echo (full duplex)
	bne     :+				; Jump ahead set CURRENT_ECHO

;*******************************************************************************
;*                                                                             *
;*                               sel_term_tty                                  *
;*                                                                             *
;*          Received ESC ETX or SOH to enter TTY or Tektronix mode.            *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Change echo to half duplex.
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.2)
;-------------------------------------------------------------------------------
; The TTY mode of the resident must be able to respond to the standard ASCII 
; character set and control set.  It should operate in half duplex (the network
; connecting the terminal to the PLATO host runs in half duplex).
;
; The TTY mode must be able to recognize at least one escape sequence: ESC STX.  
; This is the command from the PLATO host to the terminal to enter PLATO mode.
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.10)
;-------------------------------------------------------------------------------
; Resident mode change commands
; 
; ESC ETX (1B 03 hex) selects the TTY mode of operation.  At the end of the 
; PLATO session the host will send this sequence to the terminal to reset to TTY.
;
; ESC SOH (1B 01 hex) is used to select the 'graphics' mode in the Viking 
; 721-30 and IST III graphics residents.  In this mode the terminal emulates a 
; Tektronix 401x graphics terminal.  Other machines should treat this as a 
; command to enter TTY mode.
;-------------------------------------------------------------------------------

sel_term_tty:					; A887
;** Set echo to half duplex ****************************************************
	lda     #$00    			; $00->local echo (half duplex)
:	sta     CURRENT_ECHO   			; 
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                sel_size_0                                   *
;*                                                                             *
;*     Received command from the PLATO host to select normal size text         *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.2)
;-------------------------------------------------------------------------------
; Two character sizes should be available: size 0 (normal) and size 2 (bold).  
; Size 0 is the default size when the resident starts up.
;-------------------------------------------------------------------------------
sel_size_0:					; A38D
	lda     #$00    			; $00->normal text
	beq     :+				; Jump to set CURRENT_SIZE

;*******************************************************************************
;*                                                                             *
;*                                sel_size_2                                   *
;*                                                                             *
;*       Received command from the PLATO host to select bold size text         *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Set size to bold (normal characters doubled in size)
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.2)
;-------------------------------------------------------------------------------
; Two character sizes should be available: size 0 (normal) and size 2 (bold).  
;
; Size 2 characters are simply normal characters doubled in size, and are 
; therefore 32 high by 16 wide.  Size 2 also causes all character (and control
; functions) to perform on this greater scale.  That is, after a size 2 
; character is plotted, the current X position will be increased by 16 rather 
; than by 8.
;-------------------------------------------------------------------------------
sel_size_2:					; A391
	lda     #$FF    			; $FF->bold text (double-sized)
:	sta     CURRENT_SIZE 			; 
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                 set_super                                   *
;*                                                                             *
;*             Received ESC @ from PLATO host to print superscript             *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.4)  
;-------------------------------------------------------------------------------
; Superscript (ESC @, 1B 40)
;
; This increases the the screen position along the perpendicular axis by five 
; pixels.
;-------------------------------------------------------------------------------
set_super:					; A396
	clc             			; Carry clear->UP
	jmp     move_cur_vert  			; 

;*******************************************************************************
;*                                                                             *
;*                                  set_sub                                    *
;*                                                                             *
;*              Received ESC A from PLATO host to print subscript              *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION:
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.4)  
;-------------------------------------------------------------------------------
; Subscript (ESC A, 1B 41 hex)
;
; This decreases the screen position along the perpendicular axis by five 
; pixels.
;-------------------------------------------------------------------------------
set_sub:					; A39A
	sec             			; Carry set->DOWN
	jmp     move_cur_vert  			; 

;*******************************************************************************
;*                                                                             *
;*                                set_margin                                   *
;*                                                                             *
;*               Received ESC Z from PLATO host to set margin                  *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION:
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.4)  
;-------------------------------------------------------------------------------
; Set Margin (ESC Z, 1B 5A hex)
;
; This command sets the margin used with the CR control code. The margin is set 
; to the current X coordinate if horizontal writing is selected, and the current
; Y coordinate if vertical writing is selected.
;-------------------------------------------------------------------------------
set_margin:					; A38E

;** Zoomed display ************************************************************
	lda     CURSOR2_X			; 
	sta     MARGIN2				;
	lda     CURSOR2_X+1			;
	sta     MARGIN2+1			;

;** Full screen display ********************************************************
	lda     CURSOR1_X			; 
	sta     MARGIN1				;
	lda     CURSOR1_X+1			;
	sta     MARGIN1+1			;
	rts

;*******************************************************************************
;*                                                                             *
;*                                  proc_ht                                    *
;*                                                                             *
;                  Received TAB character from PLATO host                      *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION:
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.4)  
;-------------------------------------------------------------------------------
; Tab (TAB, 09 hex)
;
; This causes the terminal to advance one character width along the current 
; axis.  This function is like plotting an empty character.
;-------------------------------------------------------------------------------
proc_ht:					; A3AF
	jmp     LABD3   			; A3AF 4C D3 AB                 L..

;*******************************************************************************
;*                                                                             *
;*                                  proc_cr                                    *
;*                                                                             *
;*             Received Carriage Return character from PLATO host              *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION:
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.4)  
;-------------------------------------------------------------------------------
; Carriage Return (CR, 0D hex)
;
; This goes to the next line and sets the position along the current axis to 
; the current margin.
;-------------------------------------------------------------------------------
proc_cr:					; A3B2

;** Zoomed display ************************************************************
	lda     MARGIN2				;
	sta     CURSOR2_X			;
	lda     MARGIN2+1			;
	sta     CURSOR2_X+1			;

;** Full screen display ********************************************************
	lda     MARGIN1				;
	sta     CURSOR1_X			;
	lda     MARGIN1+1			;
	sta     CURSOR1_X+1			; Fall into linefeed (CRLF)

;*******************************************************************************
;*                                                                             *
;*                                  proc_lf                                    *
;*                                                                             *
;*                Received Line Feed character from PLATO server               *
;*                                                                             *
; *******************************************************************************

; DESCRIPTION:
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.4)  
;-------------------------------------------------------------------------------
; Line Feed (LF, 0A hex)
;
; This function decreases the display position by one character height 
; perpendicular to the current axis (i.e., goes to the next line.)  On the 
; horizontal axis this moves down one line.  On the vertical axis this moves 
; right one character height.
;-------------------------------------------------------------------------------
proc_lf:					; A3C2
	jsr     get_font_hgt2			; A3C2 20 82 A8                  ..
	jmp     move_cur_dn   			; A3C5 4C 57 A8                 LW.

;*******************************************************************************
;*                                                                             *
;*                                  proc_ff                                    *
;*                                                                             *
;*               Received Form Feed character from PLATO host.                 *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION:
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.4)  
;-------------------------------------------------------------------------------
; Form Feed (FF, 0C hex)
;
; This function sets the screen position to the first character on the top line 
; of the display.  The screen is not erased.
;-------------------------------------------------------------------------------
; Move the cursor to the top of the display. 
; The CURSOR variables contain screen coordinates such that (0,0) is the lower 
; left corner of the display. So for the full screen display the cursor will
; be set to (0,186) of a 192 scan line display. And for the zoomed display
; the cursor will be set to (0,372) of a 384 scan line display.
;-------------------------------------------------------------------------------
proc_ff:					; A3C8

;** Full screen display ********************************************************
	lda     #186    			; 186 scan lines from bottom
	sta     CURSOR1_Y     			; 

;** Zoomed display ************************************************************
	lda     #(<372)    			; 372 scan lines from bottom
	sta     CURSOR2_Y     			; 
	ldx     #(>372)    			;
	stx     CURSOR2_Y+1			;

	dex             			; X is now 0
	stx     CURSOR2_X			;
	stx     CURSOR2_X+1			;

;** Full screen display ********************************************************
	stx     CURSOR1_X			; 
	stx     CURSOR1_X+1			; Fall through to RTS

;*******************************************************************************
;*                                                                             *
;*                                  gen_rts                                    *
;*                                                                             *
;*                    Generic RTS called from jump tables                      *
;*                                                                             *
;*******************************************************************************
gen_rts:					; A3DD
	rts

;*******************************************************************************
;*                                                                             *
;*                                  proc_bs                                    *
;*                                                                             *
;*                      Move one character width back.                         *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This subroutine is called when a control code $08 (BS) is received.

proc_bs:					; A3DE
	jsr     get_font_width

;** Decrement full-screen cursor X by current font's character width ***********
	sta     TMP	 			; A is 5 or 9 depending on character size
	sec             			; 
	lda     CURSOR1_X     			; Get current cursor X (lo)
	sbc     TMP	 			; Decrement by char width
	sta     CURSOR1_X     			; Save new cursor X
	bcs     :+				; is hi byte affected? no? skip
	dec     CURSOR1_X+1    			; Decrement cursor X (hi) by char width

;** Decrement zoomed display cursor X by current font's character width ********
:	lda     CURSOR2_X			; Get current cursor X (lo)
	sec             			; 
	sbc     VAR     			; D8 is 8 or 16 depending on character size
	sta     CURSOR2_X			; Save new zoomed cursor X (lo)
	bcs     gen_rts   			; is hi byte affected? no? RTS 
	dec     CURSOR2_X+1			; Decrement zoomed cursor X (hi)

	bpl     gen_rts   			; Backspace too far left? no? rts

;** Backspaced too far left. Adjust cursor locations ***************************
	lda     #$40    			; 
	clc             			; 
	adc     CURSOR1_X     			; 
	sta     CURSOR1_X     			; 
	lda     #$01    			; 
	sta     CURSOR1_X+1    			; 
	sta     CURSOR2_X+1    			; 
	bne     gen_rts   			; Always jump. RTS

;*******************************************************************************
;*                                                                             *
;*                                  proc_vt                                    *
;*                                                                             *
;*                       Move one character height up.                         *
;*                                                                             *
;*******************************************************************************
proc_vt:
	jsr     get_font_hgt2			; A40A 20 82 A8                  ..
	jmp     move_cur_up   			; A40D 4C 2D A8                 L-.

;*******************************************************************************
;*                                                                             *
;*                               sel_char_set                                  *
;*                                                                             *
;*                        Select Character set M0-M3.                          *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This subroutine is called when one of the following escape sequences have
; been received from PLATO: ($42, $43, $44, $45). See s0ascers Appendix B.
;
; Parameters:
; X: escape sequence received from PLATO
; 
; The original escape sequence is stripped of all but the lowest 2 bits leaving
; a simpler value used for indexing into a table. 
;
; esc sequence   AND 11 = x -> character set
; $42 = 0100 0010 -> 10 = 2 -> Character set M0
; $43 = 0100 0011 -> 11 = 3 -> Character set M1
; $44 = 0100 0100 -> 00 = 0 -> Character set M2
; $45 = 0100 0101 -> 01 = 1 -> Character set M3

sel_char_set:					; A410
	txa             			; Let A = orig escape sequence
	and     #$03    			; Strip all but 2 lowest bits
	tay             			; ...and use it for indexing

;** Point to 4x6 character set for full screen display *************************
	lda     tab_ch_mem_DL1,y		; Get LSB from table
	sta     CHSET_BASE			; ...and save it to variable.

	lda     tab_ch_mem_DL1+4,y 		; Get MSB from table
	sta     CHSET_BASE+1			; ...and save it to variable.

;** Point to 8x8 character set for zoomed display ******************************
	lda     tab_ch_mem_DL2,y		; Get LSB from table
	sta     $EB     			; ...and save it to variable.

	sty     CURRENT_CHSET			; Remember which set is active
	lda     tab_ch_mem_DL2+4,y 		; Get MSB from table
	sta     $EA     			; ...and save it to variable.
	rts             			; A42A 60                       `

;*******************************************************************************
;*                                                                             *
;*                                  set_esc                                    *
;*                                                                             *
;*       Set bit to inform proc_serial_in start of an escape sequence.         *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This subroutine is called when the ESC character has been encountered. The
; next character to be received needs to be interpreted as an escape sequence 
; code and not as its literal value. Set bit 7 of byte_B3 as a flag that we're 
; starting an escape sequence. Another routine will examine this flag and 
; branch accordingly.
set_esc:					; A42B
	asl     byte_B3 			; Shift bits left
	sec             			; Set carry
	ror     byte_B3 			; Rotate carry onto value
	rts             			; and return.

;*******************************************************************************
;*                                                                             *
;*                                set_mode_7                                   *
;*                                                                             *
;*                    PLATO host sent ESC R, S, T, or V 	               *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Set the index for a jump table to process a Select Mode 7 command
set_mode_7:					; A431
	lda     #$00    			; A431 A9 00                    ..
LA433:  ldx     #$03    			; A433 A2 03                    ..
	jmp     LA111   			; A435 4C 11 A1                 L..

;*******************************************************************************
;*                                                                             *
;*                                set_mode_6                                   *
;*                                                                             *
;*                           PLATO host sent ESC U                             *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Set the index for a jump table to process a Select Mode 6 command
set_mode_6:					; A438
	lda     #$05    			; A438 A9 05                    ..
	bne     LA433   			; A43A D0 F7                    ..

;*******************************************************************************
;*                                                                             *
;*                                  set_ssf                                    *
;*                                                                             *
;*             PLATO host sent ESC Q (SSF - Select Special Function)           *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Set the index for a jump table to process an SSF command. For the Atari SSF 
; commands are used to enable or disable the touch panel.
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.6)
;-------------------------------------------------------------------------------
; The SSF (Select Special Function) command is used by the PLATO host to 
; communicate with special devices attached to the terminal.  The command 
; consists of the sequence ESC Q (1B 51 hex) followed by three bytes formatted 
; as a word (see section 3.1.2.4.2).  Only the lower fifteen bits of the word 
; are used.
;-------------------------------------------------------------------------------
set_ssf:					; A43C
	lda     #$02    			; A43C A9 02                    ..
	bne     LA433   			; A43E D0 F3                    ..

;*******************************************************************************
;*                                                                             *
;*                               set_load_echo                                 *
;*                                                                             *
;*                      PLATO host sent ESC Y (Load Echo)                      *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Set the index for a jump table to process a Load Echo command
set_load_echo:					; A440
	lda     #$03    			; A440 A9 03                    ..
	bne     LA433   			; A442 D0 EF                    ..

;*******************************************************************************
;*                                                                             *
;*                               set_load_mem                                  *
;*                                                                             *
;*              PLATO host sent ESC W (Load Memory Address command)            *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Set the index for a jump table to process a Load Memory Address command
set_load_mem:					; A444
	lda     #$04    			; 
	bne     LA433   			; Always -->

; ----------------------------------------------------------------------------
sub_a448:
	jsr     get_tek_vects
	ldx     $DA     			; A44B A6 DA                    ..
	bne     :++				; A44D D0 10                    ..


	ldx     #$03    			; A44F A2 03                    ..
:	lda     CURSOR1_X,x   			; save 1st X-Y pair
	sta     CURSOR1_X_OLD,x   		; A453 95 A8                    ..
	lda     CURSOR2_X,x   			; A455 B5 9C                    ..
	sta     TCRSX,x   			; A457 95 F0                    ..
	dex             			; A459 CA                       .
	bpl     :-				; A45A 10 F5                    ..

	stx     $DA     			; A45C 86 DA                    ..
	rts             			; A45E 60                       `

:	lda     IS_16K     			; A45F A5 BA                    ..
	sta     COMPR     			; Compressed display (full screen)?
	bne     :+				; Yes? -->

;** Zoomed display *************************************************************
	lda     CURSOR2_Y+1			; A465 A5 9F                    ..
	sta     CURSY+1     			; A467 85 FB                    ..

	lda     CURSOR2_X     			; A469 A5 9C                    ..
	ldx     CURSOR2_X+1    			; A46B A6 9D                    ..
	ldy     CURSOR2_Y			; A46D A4 9E                    ..

	jsr     :++				; Process zoomed display then
	dec     COMPR     			; ...return to do full screen

;** Full screen: Copy old CURSOR (X,Y) to TCRS(X,Y)
:	ldx     #$04    			; 
@LOOP2: lda     CURSOR1_Y_OLD-3,x  		; 
	sta     TCRSY-3,x   			; 
	dex             			; 
	bne     @LOOP2  			; 

	stx     CURSY+1     			; 0: Full screen < 192
	stx     TCRSY+1    			; 0: Full screen < 192
	stx     $DA     			; TODO A481 86 DA                    ..

	lda     CURSOR1_X     			; A483 A5 A4                    ..
	ldx     CURSOR1_X+1    			; A485 A6 A5                    ..
	ldy     CURSOR1_Y     			; A487 A4 A6                    ..

;** Full Screen and Zoomed displays *********************************************
:	sta     CURSX     			; A489 85 F8                    ..
	stx     CURSX+1    			; A48B 86 F9                    ..
	sty     CURSY     			; A48D 84 FA                    ..

	cpx     TCRSX+1     			; A48F E4 F1                    ..
	bcc     :++				; A491 90 12                    ..
	bne     :+				; A493 D0 04                    ..

	cmp     TCRSX     			; A495 C5 F0                    ..
	bcc     :++				; A497 90 0C                    ..

:	ldy     TCRSX+1     			; A499 A4 F1                    ..
	stx     TCRSX+1     			; A49B 86 F1                    ..
	sty     CURSX+1     			; A49D 84 F9                    ..

	ldy     TCRSX     			; A49F A4 F0                    ..
	sta     TCRSX     			; A4A1 85 F0                    ..
	sty     CURSX     			; A4A3 84 F8                    ..

:	lda     CURSY     			; A4A5 A5 FA                    ..
	ldx     TCRSY+1    			; A4A7 A6 F3                    ..
	cpx     CURSY+1     			; A4A9 E4 FB                    ..
	bcc     :++				; A4AB 90 12                    ..
	bne     :+				; A4AD D0 04                    ..

	cmp     TCRSY     			; A4AF C5 F2                    ..
	bcs     :++				; A4B1 B0 0C                    ..

:	ldy     CURSY+1     			; A4B3 A4 FB                    ..
	stx     CURSY+1     			; A4B5 86 FB                    ..
	sty     TCRSY+1     			; A4B7 84 F3                    ..

	ldy     TCRSY     			; A4B9 A4 F2                    ..
	sta     TCRSY     			; A4BB 85 F2                    ..
	sty     CURSY     			; A4BD 84 FA                    ..

:	ldx     #$03    			; 
	bit     COMPR     			; Are we currently full-screen?
@LOOP3:	lda     $F8,x   			; 
	bvs     :+				; Yes? skip zoomed logic 
	sta     CURSOR2_X,x   			; Copy from $F8,x
	ldy     #$40    			; 64 bytes per scan line
	bvc     :++				; If zoomed skip full screen logic.
:	sta     CURSOR1_X,x   			; Copy from $F8,x
	ldy     #$28    			; 40 bytes per scan line
:	dex             			; 
	bpl     @LOOP3				; 

	sty     TMP	 			; Store bytes per scan line (64 or 40)
	bvs     :+				; Is currently full screen? Skip
	bit     IS_16K     			; Running on 48K RAM?
	bpl     :+				; Yes? Skip.
	rts             			; 

:	jsr     get_pfaddr			; set YOUT to upper left corner
	bit     SCREEN_MODE			; Which mode are we in?
	lda     $F8     			; A4E2 A5 F8                    ..
	and     #$07    			; Get modulus 8 and use as index
	tax             			; A4E6 AA                       .
	lda     LTAB,x				; A4E7 BD 4E B9                 .N.
	beq     :++				; no lmask --> no round up byte count
	bvc     :+				; 
	eor     #$FF    			; else invert bits
:	inc     SUMLO				; points to next whole byte boundary
:	sta     LEND     			; A4F2 85 AB                    ..
	lda     TCRSX+1     			; right whole byte boundry
	lsr     a       			; A4F6 4A                       J
	lda     TCRSX     			; A4F7 A5 F0                    ..
	ror     a       			; A4F9 6A                       j
	lsr     a       			; A4FA 4A                       J
	lsr     a       			; A4FB 4A                       J
	sta     SUMHI     			; A4FC 85 F5                    ..
	lda     TCRSX     			; get right mask
	and     #$07    			; A500 29 07                    ).
	tax             			; A502 AA                       .
	lda     RTAB,x				; A503 BD 56 B9                 .V.
	bne     :+
	inc     SUMHI     			; A508 E6 F5                    ..
:	ldy     #$FF    			; A50A A0 FF                    ..
	bvc     :+
	iny             			; A50E C8                       .
	tax             			; A50F AA                       .
	beq     :+
	eor     #$FF    			; A512 49 FF                    I.
:	sta     REND     			; A514 85 A7                    ..
	sty     plato_char     			; A516 84 E7                    ..
	sec             			; get Y delta: # of scan lines
	lda     CURSY				; cursy >= tcrsy
	sbc     TCRSY     			; 
	eor     #$FF    			; 
	sta     INDLO     			; C flag intact thru EOR
	lda     CURSY+1
	sbc     TCRSY+1     			; A523 E5 F3                    ..
	eor     #$FF    			; A525 49 FF                    I.
	sta     INDHI     			; A527 85 F7                    ..
	lda     SUMHI     			; A529 A5 F5                    ..
	sec             			; A52B 38                       8
	sbc     SUMLO
	sta     SUMLO
	bmi     LA565   			; not on boundary special case
BLOOP:	bit     SCREEN_MODE			; check need for complement
	ldy     #$00    			; init displacement reg
	lda     LEND     			; do left edge
	beq     :+				; lmask=0 --> skip
	jsr     sub_a596
:	ldx     SUMLO
	beq     :++				; A53F F0 08                    ..
	lda     plato_char     			; A541 A5 E7                    ..
:	jsr     sub_a596
	dex             			; A546 CA                       .
	bne     :-				; A547 D0 FA                    ..
:	lda     REND     			; A549 A5 A7                    ..
	beq     :+				; A54B F0 03                    ..
	jsr     sub_a596
:	inc     INDLO     			; A550 E6 F6                    ..
	bne     :+				; A552 D0 04                    ..
	inc     INDHI    			; A554 E6 F7                    ..
	beq     :++				; A556 F0 1B                    ..
:	lda     TMP	 			; A558 A5 D9                    ..
	clc             			; A55A 18                       .
	adc     YOUT
	sta     YOUT
	bcc     BLOOP   			; A55F 90 D1                    ..
	inc     YOUT+1
	bne     BLOOP   			; A563 D0 CD                    ..
LA565:  lda     LEND     			; create special mask
	ora     REND     			; A567 05 A7                    ..
	sta     LEND     			; A569 85 AB                    ..
	lda     #$00    			; A56B A9 00                    ..
	sta     REND     			; A56D 85 A7                    ..
	sta     SUMLO
	beq     BLOOP   			; A571 F0 BF                    ..
:	bit     COMPR     			; A573 24 C9                    $.
	bvc     :++				; A575 50 15                    P.
	lda     CURSOR2_Y			; A577 A5 9E                    ..
	sec             			; A579 38                       8
	sbc     #$0B    			; A57A E9 0B                    ..
	sta     CURSOR2_Y			; A57C 85 9E                    ..
	bcs     :+	   			; A57E B0 02                    ..
	dec     CURSOR2_Y+1			; A580 C6 9F                    ..
:	lda     CURSOR2_Y+1			; A582 A5 9F                    ..
	lsr     a       			; A584 4A                       J
	lda     CURSOR2_Y			; A585 A5 9E                    ..
	ror     a       			; A587 6A                       j
	adc     #$00    			; A588 69 00                    i.
	sta     CURSOR1_Y     			; A58A 85 A6                    ..
:	lda     #<(obf_code-1)			; Point to obfuscated code used...
	ldy     #>(obf_code-1)			; ...for copy-protection check.
	ldx     #$0C				; Init counter for 12 bytes of obfuscated code
	jsr     check_if_pirated		; 
	rts             			; 

; ----------------------------------------------------------------------------
sub_a596:
	bvc     :+
	and     (YOUT),y
	bvs     :++
:  	ora     (YOUT),y
:	sta     (YOUT),y
	iny             			; A5A0 C8                       .
	rts             			; A5A1 60                       `

;*******************************************************************************
;*                                                                             *
;*                               div_cx1_by_8                                  *
;*                                                                             *
;*             Derives the byte offset in a scan line for CURSOR1_X            *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This subroutine calculates the offset in whole bytes from the start of any 
; full screen display scan line given the 16-bit CURSOR1_X value and saves it 
; to SUMLO. Each scan line is 40 bytes. There's 320 pixels in the full screen
; display. Therefore, SUMLO = INT (CURSOR1_X / 8)

div_cx1_by_8:					; A5A2
	lda     CURSOR1_X+1    			; 
	lsr     a       			; Divide by 2
	lda     CURSOR1_X     			; 
	jmp     :+				; Re-use the divide-by-2s below

;*******************************************************************************
;*                                                                             *
;*                               div_cx2_by_8                                  *
;*                                                                             *
;*             Derives the byte offset in a scan line for CURSOR2_X            *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION:
; This subroutine calculates the offset in whole bytes from the start of any 
; zoomed display scan line given the 16-bit CURSOR2_X value and saves it in SUMLO. 
; Each scan line is 64 bytes. There's 512 pixels in the zoomed display.
; Therefore, SUMLO = INT (CURSOR2_X / 8)

div_cx2_by_8:					; A5AA
	lda     CURSOR2_X+1    			; 
	lsr     a       			; Divide by 2
	lda     CURSOR2_X     			; 
:	ror     a       			; Divide by 2
	lsr     a       			; Divide by 2
	lsr     a       			; Divide by 2
	sta     SUMLO				; Save the whole byte boundary offset
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                 proc_ssf                                    *
;*                                                                             *
;*                Process SSF command (Select Special Function)                *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; The SSF (Select Special Function) command is used by the PLATO host to 
; communicate with special devices attached to the terminal. On the Atari, the
; simulated touch panel is activated by an SSF command.
proc_ssf:					; A5B5
	lda     PLATO_WORD+1   			; A5B5 A5 DC                    ..
	and     #$04    			; A5B7 29 04                    ).
	beq     LA5E3   			; RTS

	lda     PLATO_WORD     			; A5BB A5 DB                    ..
	and     #$20    			; A5BD 29 20                    ) 
	beq     LA5E4   			; A5BF F0 23                    .#

	jsr     hide_big_f   			; A5C1 20 F6 A5                  ..
	ldx     UI_MODE  			; A5C4 A6 C1                    ..bb
	beq     :+				; full-screen? jump.
	bmi     :++				; zoomed? jump.
	dex             			; 
	beq     LA5E3   			; touch-screen? RTS

:	lda     #$01    			; here if joystick-mapped
	bne     :++				; Set UI_MODE = $01->touch screen

:	lda     #$FE    			; Set UI_MODE = $FE->zoomed from touch screen
	ldx     #$00    			; Set touch panel cursor to off-screen
	beq     LA5D9   			; Jump to 

:	ldx     CROSS_X 			; Retrieve touch panel cursor position

;** Save update UI_MODE and touch panel cursor position ***********************
LA5D9:  sta     UI_MODE  			; 
	stx     HPOSM1				; Set position for left half...
	inx             			; ...of cross-shaped cursor.
	inx             			; Right half of cross-shaped cursor...
	stx     HPOSM0				; ...is a couple ticks further.
LA5E3:  rts             			; 

; ----------------------------------------------------------------------------
LA5E4:  lda     UI_MODE     			; A5E4 A5 C1                    ..
	beq     LA5E3   			; A5E6 F0 FB                    ..
	bmi     LA5F0   			; A5E8 30 06                    0.
	lsr     a       			; A5EA 4A                       J
	bne     LA5E3   			; A5EB D0 F6                    ..
	tax             			; A5ED AA                       .
	beq     LA5D9   			; A5EE F0 E9                    ..
LA5F0:  ldx     #$00    			; A5F0 A2 00                    ..
	lda     #$FF    			; A5F2 A9 FF                    ..
	bne     LA5D9   			; A5F4 D0 E3                    ..

;*******************************************************************************
;*                                                                             *
;*                                 hide_big_f                                  *
;*                                                                             *
;*                             Hide big letter "F"                             *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; Hide the big letter "F" that is displayed when UI_MODE is using the
; joystick-mapped function key mode. The "F" is composed using two missiles.
; By setting the missiles locations to 0, the letter is outside the boundary
; of the video display.

hide_big_f:					; A5F6
	ldx     #$00    			; 
	stx     HPOSM3				; Hide "|" part of large "F"
	stx     HPOSM2				; Hide "=" part of large "F"
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                 proc_echo                                   *
;*                                                                             *
;*                     Respond to PLATO server echo codes                      *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.4)
;
; The Echo command asks the terminal for information or requests a function.  
; This command is used to query the terminal for its type, subtype, load file, 
; configuration, terminal ID and memory contents.  Seven bits of data (encoded 
; in a three-byte response whose format is detailed in section 3.2.3.3.2) are 
; sent up to the host. The Echo command is also used to sound the terminal's 
; alarm.
;-------------------------------------------------------------------------------
;
; This subroutine processes PLATO Echo commands. If a response is required, a
; 2-byte escape sequence is sent to PLATO of which the 7-lowest bits contain
; the response.
;
; Bit 7 of each byte will be assigned a parity value during "send_to_plato". 
; Bit 6 of each byte must be 1 so the character is the normal-ish range of 
; printable characters.
;
; P1..,...X P1XX,XXXX (7 bit response)
; <-- #2--> <-- #1-->
;
; Echo 50: (Unknown)
; P100,0011 P101,0000 (Protocol suggests responding an unknown code with same)
;    4 3       5 0  -> 7 bits = 101 0000 = $50
;
; Echo 71: Terminal subtype response:
; P100,0010 P100,1110
;    4 0       4 E  -> 7 bits = 000 1110 = $0E (14. Atari terminal subtype)
;
; Echo 72: Terminal resident load file (applies only to CDC terminals)
; P100,0010 P100,0000
;    4 2       4 0  -> 7 bits = 000 0000 = $00
;
; Echo 73: Terminal configuration
; P100,0010 P100,0000
;    4 2       4 0  -> 7 bits = 000 0000 = $00
; 

proc_echo:					; A5FF
	lda     SERIN_BUF   			; Get char received from PLATO

;** Echo code 50 hex: (Unknown) ************************************************
	cmp     #$50    			; Couldn't find code in s0ascers
	bne     :+				; #$50? no? skip to next.

	lda     #$1B    			; Send escape
	jsr     send_to_plato2

	lda     #$50    			; Respond with same echo code
	jsr     send_to_plato2

	lda     #$43    			; Unsure why #$43. Others are
	bne     @SEND1				; #$42. Maybe #$42 is affirmative.

;** Echo code 71 hex: Terminal subtype ****************************************
:	cmp     #$71    			; is termainl subtype?
	bne     :+				; no? skip to next.

	lda     #$1B    			; else send $1B $4E $42
	jsr     send_to_plato2			; 

	lda     #$4E    			; $0E->Atari terminal
	bne     @SEND2				; 

;** Echo code 72 hex: Resident load file ***************************************
:	cmp     #$72    			; is resident load file?
	beq     @SEND3				; yes? send $1B $40 $42

;** Echo code 73 hex: Terminal configuration ***********************************
	cmp     #$73    			; is terminal configuration?
	beq     @SEND3				; yes? send $1B $40 $42

;** Echo code 7B hex: Sound alarm **********************************************
	cmp     #$7B    			; is sound alarm?
	bne     :+				; no? RTS

	jsr     play_beep			; else play sound
:	rts             			; and RTS

;** Depending on entry point Send 1 to 3 bytes. *******************************
@SEND3:	lda     #$1B    			; Send escape
	jsr     send_to_plato2			;
	lda     #$40    			; 
@SEND2: jsr     send_to_plato2			;
	lda     #$42    			; 
@SEND1: jmp     send_to_plato2			; 

; ----------------------------------------------------------------------------

sub_a640:
	lda     PLATO_WORD+1   			; A640 A5 DC                    ..
	ldx     PLATO_WORD     			; A642 A6 DB                    ..
	and     #$07    			; A644 29 07                    ).
	lsr     a       			; A646 4A                       J
	sta     YOUT+1
	sta     PLATO_WORD+1   			; A649 85 DC                    ..
	txa             			; A64B 8A                       .
	ror     a       			; A64C 6A                       j
	sta     YOUT
	lsr     PLATO_WORD+1  			; A64F 46 DC                    F.
	ror     a       			; A651 6A                       j
	sta     TMP	 			; A652 85 D9                    ..
	ldx     PLATO_WORD+1   			; A654 A6 DC                    ..
	stx     VAR     			; A656 86 D8                    ..
	lsr     PLATO_WORD+1   			; A658 46 DC                    F.
	ror     a       			; A65A 6A                       j
	adc     TMP	 			; A65B 65 D9                    e.
	sta     SUMLO
	lda     #$0C    			; A65F A9 0C                    ..
	adc     VAR     			; A661 65 D8                    e.
	sta     SUMHI
	lda     YOUT
	adc     TMP	 			; A667 65 D9                    e.
	sta     YOUT
	lda     YOUT+1
	adc     VAR     			; A66D 65 D8                    e.
	adc     #$06    			; A66F 69 06                    i.
	sta     YOUT+1
LA673:  lda     #$00    			; A673 A9 00                    ..
	sta     TMP	 			; A675 85 D9                    ..
	sta     VAR     			; A677 85 D8                    ..

;** Clear 29 bytes *************************************************************
	ldx     #$1D    			; A679 A2 1D                    ..
:	sta     $3E10,x 			; A67B 9D 10 3E                 ..>
	dex             			; A67E CA                       .
	bpl     :-
	rts             			; A681 60                       `

; ----------------------------------------------------------------------------

sub_a682:
	jsr     get_tek_vects
	lda     IS_16K     			; A685 A5 BA                    ..
	sta     COMPR     			; A687 85 C9                    ..
	bne     :+				; Full screen only? -->

;** Zoomed display *************************************************************
	jsr     get_pfaddr
	lda     CURSOR2_X     			; A68E A5 9C                    ..
	jsr     :++				; A690 20 9A A6                  ..
	dec     COMPR     			; Now do it for full screen

;** Full screen display ********************************************************
:	jsr     get_pfaddr
	lda     CURSOR1_X     			; A698 A5 A4                    ..

:	and     #$07    			; Modulus 8 on cursor X to use
	tax             			; ...as index later
	ldy     #$00    			; 
	jmp     plot				; Write to screen and RTS

;*******************************************************************************
;*                                                                             *
;*                                 clear_screen                                *
;*                                                                             *
;*******************************************************************************
clear_screen:					; A6A2
;** (n) Turn off ANTIC to hide the work and speed things up ********************
	ldy     #$00    			; 
	sty     SDMCTL  			; Turn off ANTIC

;** (n) Load self modifying code #1 into zero page RAM *************************
	ldx     #$1B    			; Copy instructions from ROM to RAM
:	lda     LA6D0,x 			; Must be self-modifying code
	sta     a:L0080,x       		;
	dex             			;
	bpl     :-				; End loop after 27 iterations

;** (n) Run self modifying code #1 *******************************************
	tya             			; Let Y = $00. Used for background
	bit     $BA     			; A6B3 24 BA                    $.
	jsr     L0080   			; Run self-modifying code #1

;** (n) Load self modifying code #2 into zero page RAM *************************
	ldx     #$09    			; Copy instructions from ROM to RAM
:	lda     LA6EC,x 			; Must be self-modifying code
	sta     a:$82,x 			; Leave 'sta' instruction from code #1
	dex             			; 
	bpl     :-				; End loop after 9 iterations

;** (n) Run self modifying code #2 *******************************************
	ldx     #$08    			; A6C3 A2 08                    ..
	lda     #$20    			; A6C5 A9 20                    . 
	jsr     L0080   			; self-modifying code #2

;** (n) Turn ANTIC back on and restore previous playfield/dma settings *******
	lda     #$26    			;
	sta     SDMCTL   			; Turn on ANTIC, DMA, etc 
	rts             			; 

; ----------------------------------------------------------------------------
; Self-modifying code #1 to be copied from ROM to RAM
; ----------------------------------------------------------------------------
LA6D0:  sta     L2000,y 			; A6D0 99 00 20                 .. 
	bvs     :+
	sta     SCREEN_24K,y			; A6D5 99 00 40                 ..@
	sta     SCREEN_24K+$2000,y 		; A6D8 99 00 60                 ..`
	sta     SCREEN_24K+$4000,y 		; A6DB 99 00 80                 ...
:	iny             			; A6DE C8                       .
	bne     LA6D0   			; A6DF D0 EF                    ..
	inc     $82     			; Self modifying code
	inc     $87     			; Self modifying code
	inc     $8D     			; Self modifying code
	inc     $8A     			; Self modifying code
	bpl	LA6D0				; points to L0080 at runtime
	rts

; ----------------------------------------------------------------------------
; Self-modifying code #2 to be copied from ROM to RAM
; ----------------------------------------------------------------------------
; LA6EC-2:					; first two bytes are reused from
;	sta	L1800,y				; LA6D0 above when this is copied
LA6EC:  .byte	$18         			; to $0082
	iny             			; A6ED C8                       .
	bne     LA6EC-2   			; A6EE D0 FA                    ..
	inc     $82     			; Self modifying code
	dex             			; A6F2 CA                       .
	bne     LA6EC-2   			; A6F3 D0 F5                    ..
	rts             			; A6F5 60                       `


;	Receive Downloaded Character Set  ------------------
DLOAD:						; A6F6
	jsr     unpack_word			; load alternate character set
	ldx     VAR     			; A6F9 A6 D8                    ..
	ldy     #$0F    			; A6FB A0 0F                    ..
@DLX:	lsr     PLATO_WORD+1   			; A6FD 46 DC                    F.
	ror     PLATO_WORD     			; A6FF 66 DB                    f.
	lda     MTAB,x				; A701 BD 3A B9                 .:.
	and     (YOUT),y
	bcc     @DL0				; A706 90 1E                    ..
	inc     TMP	 			; A708 E6 D9                    ..
	pha             			; A70A 48                       H
	lda     LB9BE,y 			; A70B B9 BE B9                 ...
	tax             			; A70E AA                       .
	lda     LB9F4,x 			; A70F BD F4 B9                 ...
	sta     LEND     			; A712 85 AB                    ..
	ldx     VAR     			; A714 A6 D8                    ..
	lda     LB9CE,x 			; A716 BD CE B9                 ...
	clc             			; A719 18                       .
	adc     LEND     			; A71A 65 AB                    e.
	tax             			; A71C AA                       .
	inc     $3E10,x 			; A71D FE 10 3E                 ..>
	pla             			; A720 68                       h
	ldx     VAR     			; A721 A6 D8                    ..
	ora     BTAB,x				; A723 1D 42 B9                 .B.
@DL0:	sta     (YOUT),y
	dey             			; A728 88                       .
	bpl     @DLX				; A729 10 D2                    ..
	inx             			; A72B E8                       .
	cpx     #$08    			; A72C E0 08                    ..
	bcs     LA733   			; A72E B0 03                    ..
	stx     VAR     			; A730 86 D8                    ..
	rts             			; A732 60                       `

; ----------------------------------------------------------------------------
LA733:  lda     #$00    			; A733 A9 00                    ..
	tax             			; A735 AA                       .
	ldy     #$05    			; A736 A0 05                    ..
LA738:  sta     (SUMLO),y
	dey             			; A73A 88                       .
	bpl     LA738   			; A73B 10 FB                    ..
	lda     TMP	 			; A73D A5 D9                    ..
	cmp     #$36    			; A73F C9 36                    .6
	bcc     LA771   			; A741 90 2E                    ..
	dex             			; A743 CA                       .
	cmp     #$55    			; A744 C9 55                    .U
	bcs     LA771   			; A746 B0 29                    .)
	ldy     #$05    			; A748 A0 05                    ..
LA74A:  ldx     #$04    			; A74A A2 04                    ..
	stx     LEND     			; A74C 86 AB                    ..
LA74E:  lda     LB9F4,y 			; A74E B9 F4 B9                 ...
	clc             			; A751 18                       .
	adc     LEND     			; A752 65 AB                    e.
	tax             			; A754 AA                       .
	lda     LB9D6,x 			; A755 BD D6 B9                 ...
	cmp     $3E10,x 			; A758 DD 10 3E                 ..>
	bcc	:+
	bne     LA768   			; A75D D0 09                    ..
:	lda     (SUMLO),y
	ldx     LEND     			; A761 A6 AB                    ..
	ora     BTAB,x				; A763 1D 42 B9                 .B.
	sta     (SUMLO),y
LA768:  dec     LEND     			; A768 C6 AB                    ..
	bpl     LA74E   			; A76A 10 E2                    ..
	dey             			; A76C 88                       .
	bpl     LA74A   			; A76D 10 DB                    ..
	bmi     LA7AD   			; A76F 30 3C                    0<
LA771:  stx     TMP	 			; A771 86 D9                    ..
	bit     TMP	 			; A773 24 D9                    $.
	ldy     #$0F    			; A775 A0 0F                    ..
LA777:  lda     (YOUT),y
	bvc     :+
	eor     #$FF    			; A77B 49 FF                    I.
:	sta     VAR     			; A77D 85 D8                    ..
	ldx     #$07    			; A77F A2 07                    ..
	lda     #$00    			; A781 A9 00                    ..
LA783:  rol     VAR     			; A783 26 D8                    &.
	bcc     LA78A   			; A785 90 03                    ..
	ora     LB9B6,x 			; A787 1D B6 B9                 ...
LA78A:  dex             			; A78A CA                       .
	bpl     LA783   			; A78B 10 F6                    ..
	pha             			; A78D 48                       H
	lda     LB9BE,y 			; A78E B9 BE B9                 ...
	sty     VAR     			; A791 84 D8                    ..
	tay             			; A793 A8                       .
	pla             			; A794 68                       h
	ora     (SUMLO),y
	sta     (SUMLO),y
	ldy     VAR     			; A799 A4 D8                    ..
	dey             			; A79B 88                       .
	bpl     LA777   			; A79C 10 D9                    ..
	bvc     LA7AD   			; A79E 50 0D                    P.
	ldy     #$05    			; A7A0 A0 05                    ..
LA7A2:  lda     (SUMLO),y
	eor     #$FF    			; A7A4 49 FF                    I.
	and     #$F8    			; A7A6 29 F8                    ).
	sta     (SUMLO),y
	dey             			; A7AA 88                       .
	bpl     LA7A2   			; A7AB 10 F5                    ..
LA7AD:  ldy     #$02    			; A7AD A0 02                    ..
	sty     Y1LO     			; A7AF 84 EE                    ..
	iny             			; A7B1 C8                       .
	sty     X1LO     			; A7B2 84 EC                    ..
LA7B4:  ldy     X1LO     			; A7B4 A4 EC                    ..
	lda     (YOUT),y
	ldy     Y1LO     			; A7B8 A4 EE                    ..
	bvc     LA7C0   			; A7BA 50 04                    P.
	and     (YOUT),y
	bvs     LA7C2   			; A7BE 70 02                    p.
LA7C0:  ora     (YOUT),y
LA7C2:  sta     (YOUT),y
	ldx     #$02    			; A7C4 A2 02                    ..
LA7C6:  inc     Y1LO     			; A7C6 E6 EE                    ..
	inc     X1LO     			; A7C8 E6 EC                    ..
	ldy     X1LO     			; A7CA A4 EC                    ..
	cpy     #$10    			; A7CC C0 10                    ..
	bcs     LA7DD   			; A7CE B0 0D                    ..
	lda     (YOUT),y
	ldy     Y1LO     			; A7D2 A4 EE                    ..
	sta     (YOUT),y
	dex             			; A7D6 CA                       .
	bpl     LA7C6   			; A7D7 10 ED                    ..
	inc     X1LO     			; A7D9 E6 EC                    ..
	bne     LA7B4   			; A7DB D0 D7                    ..
LA7DD:  lda     #$0C    			; A7DD A9 0C                    ..
	clc             			; A7DF 18                       .
	adc     YOUT
	sta     YOUT
	bcc     LA7E8   			; A7E4 90 02                    ..
	inc     YOUT+1
LA7E8:  clc             			; A7E8 18                       .
	lda     SUMLO
	adc     #$06    			; A7EB 69 06                    i.
	sta     SUMLO
	bcc	:+
	inc     SUMHI
:	jmp     LA673   			; A7F3 4C 73 A6                 Ls.

;*******************************************************************************
;*                                                                             *
;*                             fetch_serin_ch                                  *
;*                                                                             *
;*               Fetch char recvd from PLATO and advance index                 *
;*                                                                             *
;*******************************************************************************
fetch_serin_ch:					; A7F6
	ldx     SERIN_BUF_IDX  			; A7F6 A6 B6                    ..
	lda     SERIN_BUF,x 			; A7F8 BD 2E 3E                 ..>
	inc     SERIN_BUF_IDX  			; A7FB E6 B6                    ..
	rts             			; A7FD 60                       `

;*******************************************************************************
;*                                                                             *
;*                               unpack_word                                   *
;*                                                                             *
;*                  Unpack 16 bit word from 3 byte packet                      *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION

; This subroutine unpacks a 16 bits of a Plato Word. The s0ascers describes
; a PLATO word as being up to 18 bits however this routine only unpacks
; 16 and stores them in addresses $DB and $DC. 
;
; Bits 1..0 of byte #2 + bits 5..0 of byte #1 -> PLATO_WORD
; Bits 3..0 of byte #3 + bits 5..2 of byte #2 -> PLATO_WORD+1
;
;-------------------------------------------------------------------------------
; Excerpt from s0ascers - 3.1.2.4.2  Words:
;-------------------------------------------------------------------------------
; Words are used to transmit logical quantities greater than eight bits in 
; length.  For example, when loading character sets, sixteen bits at a time are
; transmitted in character set load mode.  Each word is encoded in three eight 
; bit bytes.  The format of these three bytes is:
; 
; 
;      3rd Character      2nd Character      1st character
;        received           received           received
;      P 1 X X X X X X    P 1 X X X X X X    P 1 X X X X X X
;          b18-----b13        b12------b7        b6-------b1
; 
; 
; Each byte contains six bits of data in the lower part of the byte.  The next 
; bit of the byte is always a 1.  This ensures that data will not be interpreted
; as a command.
; 
; The high bit is the parity bit, and is not relevant at this point.
;-------------------------------------------------------------------------------

unpack_word:					; A7FE
;** Get first 6 bits of word from byte #1 and store it in $DB ******************
	jsr     fetch_serin_ch			; Get byte #1
	and     #$3F    			; Save 6-bits of 1st byte
	sta     PLATO_WORD     			; 

;** Get second 6 bits of word from byte #2 and store it in $DC *****************
	jsr     fetch_serin_ch			; Get byte #2
	and     #$3F    			; Keep only lower 6 bits
	sta     PLATO_WORD+1   			; Save

;** Concatonate the 2 lowest bits of byte #2 to the 6 bits from byte #1 ********
	lda     #$00    			; Clear A

	lsr     PLATO_WORD+1   			; Shift lowest bit from char #2
	ror     a       			; ...to highest bit in A

	lsr     PLATO_WORD+1   			; Shift lowest bit from char #2
	ror     a       			; ...to highest bit in A 

	ora     PLATO_WORD     			; Merge 6 bits from byte #1 with 
	sta     PLATO_WORD     			; ...these 2 bits and save

;** Concatontate 4 lowest bits of byte #3 to the 4 remaining bits of byte #2 ***
	jsr     fetch_serin_ch			; Get byte #3

	asl     a       			; Move the 4 lowest bits to 
	asl     a       			; ...the upper nybble,
	asl     a       			; ...leaving lower nybble
	asl     a       			; ...clear.

	ora     PLATO_WORD+1   			; And merge with nybble 
	sta     PLATO_WORD+1   			; ...left over from byte #2
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                              move_cur_vert                                  *
;*                                                                             *
;*     Move cursor position up or down. Direction determined by carry bit.     *
;*                                                                             *
;*******************************************************************************
move_cur_vert:					; A824
	lda     #$02    			; Cursor delta Y for full-screen
	ldy     #$04    			; Cursor delta Y for zoomed (VAR)
	jsr     get_font_hgt   			; 
	bcs     move_cur_dn			; is subscript? yes? jump.

;*******************************************************************************
;*                                                                             *
;*                                move_cur_up                                  *
;*                                                                             *
;*                          Move cursor position up                            *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Move cursor position up on the screen. Because the CURSOR variables
; are oriented such that (0,0) is the bottom left corner of screen, Moving the
; cursor down means *increasing* the current cursor position.
; Register A contains the distance in scan lines for full screen display.
; VAR contains the distance in scan lines for zoomed display.
move_cur_up:					; A82D
;** Full screen display ********************************************************
	adc     CURSOR1_Y			; A82D 65 A6                    e.
	sta     CURSOR1_Y			; A82F 85 A6                    ..

;** Zoomed display *************************************************************
	lda     VAR     			; Distance for zoomed
	clc             			; A833 18                       .
	adc     CURSOR2_Y			; A834 65 9E                    e.
	sta     CURSOR2_Y			; A836 85 9E                    ..

	bcc     :+				; If no carry skip hi -->
	inc     CURSOR2_Y+1			; 

:	lda	CURSOR2_Y+1
	cmp     #$01    			; A83E C9 01                    ..
	bcc     :+				; is cursor(hi)<#$01 --> RTS

	lda     CURSOR2_Y			; A842 A5 9E                    ..
	cmp     #$80    			; cursor < 
	bcc     :+				; is cursor(lo)<#$80 --> RTS

;** Zoomed display *************************************************************
	sec             			; A848 38                       8
	sbc     #$80    			; A849 E9 80                    ..
	sta     CURSOR2_Y			; A84B 85 9E                    ..
	lsr     CURSOR2_Y+1			; A84D 46 9F                    F.

;** Full screen display ********************************************************
	sec             			; A84F 38                       8
	lda     CURSOR1_Y			; A850 A5 A6                    ..
	sbc     #$C0    			; A852 E9 C0                    ..
	sta     CURSOR1_Y			; A854 85 A6                    ..
:	rts             			; A856 60                       `

;*******************************************************************************
;*                                                                             *
;*                               move_cur_dn                                   *
;*                                                                             *
;*                         Move cursor position down                           *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; Move cursor position down on the screen. Because the CURSOR variables
; are oriented such that (0,0) is the bottom left corner of screen, Moving the
; cursor down means *decreasing* the current cursor position.
; Register A contains the distance in scan lines to move
move_cur_dn:					; A857
	sta     TMP	 			; A857 85 D9                    ..
	lda     CURSOR1_Y			; A859 A5 A6                    ..
	sec             			; A85B 38                       8
	sbc     TMP	 			; A85C E5 D9                    ..
	sta     CURSOR1_Y			; A85E 85 A6                    ..
	sec             			; A860 38                       8
	lda     CURSOR2_Y			; A861 A5 9E                    ..
	sbc     VAR     			; VAR contains current text size for zoomed display
	sta     CURSOR2_Y			; A865 85 9E                    ..
	bcs     LA86B   			; A867 B0 02                    ..
	dec     CURSOR2_Y+1			; A869 C6 9F                    ..
LA86B:  lda     CURSOR2_Y+1			; A86B A5 9F                    ..
	bpl     LA881   			; A86D 10 12                    ..
	lda     CURSOR2_Y			; A86F A5 9E                    ..
	clc             			; A871 18                       .
	adc     #$80    			; A872 69 80                    i.
	sta     CURSOR2_Y			; A874 85 9E                    ..
	lda     #$01    			; A876 A9 01                    ..
	sta     CURSOR2_Y+1			; A878 85 9F                    ..
	lda     CURSOR1_Y			; A87A A5 A6                    ..
LA87C:  clc             			; A87C 18                       .
	adc     #$C0    			; A87D 69 C0                    i.
	sta     CURSOR1_Y			; A87F 85 A6                    ..
LA881:  rts             			; A881 60                       `

;*******************************************************************************
;*                                                                             *
;*                               get_font_hgt2                                  *
;*                                                                             *
;*                      Return height for current font                         *
;*                                                                             *
;*******************************************************************************
; if CA like x1xx xxxx
; then A = 12 and D8 = 24
; else A = 6  and D8 = 12
get_font_hgt2:					; A882
	lda     #$06    			; 
	ldy     #$0C    			; Fall into get_font_hgt

;*******************************************************************************
;*                                                                             *
;*                               get_font_hgt                                  *
;*                                                                             *
;*                      Return height for current font                         *
;*                                                                             *
;*******************************************************************************
get_font_hgt:					; A886
;** If bit 6 of $CA is clear then let leave A and VAR as-is ********************
	bit     CURRENT_SIZE			; 
	sty     VAR     			; 
	bvs     :+				; Is bit 6 of $CA set?
	rts             			; it isn't. leave now.
;** Otherwise double A and VAR *************************************************
:	asl     a       			; A = A * 2
	bvs     :+				; VAR = VAR * 2 and RTS

;*******************************************************************************
;*                                                                             *
;*                              get_font_width                                 *
;*                                                                             *
;*                       Return width for current font                         *
;*                                                                             *
;*******************************************************************************
; 
; if CA like x1xx xxxx 
; then A = 9 and VAR = 16
; else A = 5 and VAR = 8
;
sub_a890:  
get_font_width:					; A890
;** If bit 6 of $CA is clear then let A = 5 and VAR = 8 ***********************
	bit     CURRENT_SIZE 			; Test bits 7,6 in CURRENT_SIZE
	lda     #$05    			; Let A = 5 pixels wide
	ldy     #$08    			; 
	sty     VAR     			; Let VAR = #$08
	bvc     :++				; 
;** Otherwise let A = 8 and VAR = 16 ******************************************
	lda     #$09    			; Let A = 9 pixels wide
:	asl     VAR     			; Let VAR = #$10
:	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                               print_string                                  *
;*                                                                             *
;*                        Display text on the screen                           *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; Display text on the screen
; Parameters: 
; A = MSB of address to text string
; X = LSB of address to text string
; Y = String length - 1
print_string:					; A89F
	sty     $EE     			; String length - 1
	sta     off_EC				; Store MSB string address in ZP
	stx     off_EC+1			; Store LSB string address in ZP
:	ldy     $EE     			; Iterate through the characters
	lda     (off_EC),y
	jsr     print_char
	dec     $EE     			; A8AC C6 EE                    ..
	bpl     :-
	jmp     proc_cr   			; A8B0 4C B2 A3                 L..

;*******************************************************************************
;*                                                                             *
;*                               get_tek_vects                                 *
;*                                                                             *
;*                      TEKTRONIX-format vector handler                        *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
GLOOP:						; A8B3
get_tek_vects:					; A8B3
	jsr     fetch_serin_ch			; Get character

	cmp     #$40    			; decode cord
	bcs     parse_vec_coord 		; -->a low X or Y byte
	jsr     LA8DC   			; must be hi Y

	lda     CORDY     			; hi X processed behind low Y
	and     #$1F    			; 

	ora     PLATO_WORD     			; A8C1 05 DB                    ..
	sta     CORDY     			; A8C3 85 BD                    ..

	lda     PLATO_WORD+1   			; A8C5 A5 DC                    ..
	sta     CORDY+1     			; A8C7 85 BE                    ..

	bcc     get_tek_vects			; Get next coordinate

LA8CB:  
HIX:						; hi X into CORDX pr
	jsr     LA8DC   			; HIRO A8CB 20 DC A8                  ..
	lda     CORDX     			; A8CE A5 BB                    ..
	and     #$1F    			; A8D0 29 1F                    ).
	ora     PLATO_WORD     			; A8D2 05 DB                    ..
	sta     CORDX    			; A8D4 85 BB                    ..
	lda     PLATO_WORD+1   			; A8D6 A5 DC                    ..
	sta     CORDX+1     			; A8D8 85 BC                    ..
	bcc     get_tek_vects			; GLOOP

;*******************************************************************************
;*                                                                             *
;*                               ?????????????                                 *
;*                                                                             *
;*                           ?????????????????????                             *
;*                                                                             *
;*******************************************************************************
; DESCRIPTION
;
LA8DC:  
HIRO:
	and     #$1F    			; Save 5-bits of 1st byte
	sta     PLATO_WORD+1   			; 

;** Shift bits 2..0 from PLATO_WORD+1 to bits 7..5 of A ************************
	lda     #$00    			; Clear
	lsr     PLATO_WORD+1   			; Shift bit to A using C
	ror     a       			; A8E4 6A                       j
	lsr     PLATO_WORD+1   			; A8E5 46 DC                    F.
	ror     a       			; A8E7 6A                       j
	lsr     PLATO_WORD+1   			; A8E8 46 DC                    F.
	ror     a       			; A8EA 6A                       j

;** Save 
	sta     PLATO_WORD     			; A8EB 85 DB                    ..
	rts             			; A8ED 60                       `

;*******************************************************************************
;*                                                                             *
;*                              parse_vec_coord                                *
;*                                                                             *
;*                  Parse Tektronix-format vector coordinates                  *
;*                                                                             *
;*******************************************************************************
; DESCRIPTION
;
; A8EE
LOWY:
:	and     #$1F    			; low Y byte
	sta     PLATO_WORD     			; A8F0 85 DB                    ..

	lda     CORDY     			; A8F2 A5 BD                    ..
	and     #$E0    			; A8F4 29 E0                    ).
	ora     PLATO_WORD     			; A8F6 05 DB                    ..
	sta     CORDY    			; A8F8 85 BD                    ..

	jsr     fetch_serin_ch			; get next byte
	cmp     #$40    			; a hi X byte?
	bcc     HIX				; -->a not low X nor Y byte
LOWT:
parse_vec_coord:				; A901
	cmp     #$60    			; A901 C9 60                    .`
	bcs     :-				; --> low Y byte
	and     #$1F    			; low X byte
	sta     PLATO_WORD     			; 

	lda     CORDX     			; 
	and     #$E0    			; 
	ora     PLATO_WORD     			; 
	sta     CORDX     			; low X ends cord sequence

;** Update the working display cursor ******************************************
	ldx     #$03    			; 
:	lda     CORDX,x   			; 
	sta     CURSOR2_X,x   			; A915 95 9C                    ..
	dex             			; A917 CA                       .
	bpl     :-				; A918 10 F9                    ..

;** Zoomed display *************************************************************
	lda     CURSOR2_X+1
	lsr     a       			; shift hibyte into carry
	lda     CURSOR2_X
	sta     VAR     			; 
	ror     a       			; 9th bit into A
	sta     TMP	 			; save 1/2 in TMP
	lsr     a       			; 
	lsr     a       			; div by 8
	bcs     :+				; 
	lsr     VAR     			; A928 46 D8                    F.
:	adc     TMP	 			; (1/2)+(1/8) CURSX
	sta     CURSOR1_X     			; A92C 85 A4                    ..

	ldx     #$00    			; A92E A2 00                    ..
	stx     CURSOR1_X+1    			; A930 86 A5                    ..
	bcc     :+				; A932 90 02                    ..
	inc     CURSOR1_X+1    			; A934 E6 A5                    ..
:	lda     CURSOR2_Y			; A936 A5 9E                    ..
	and     #$07    			; A938 29 07                    ).
	tax             			; A93A AA                       .
	lsr     CURSOR2_Y+1			; A93B 46 9F                    F.
	lda     CURSOR2_Y			; A93D A5 9E                    ..
	ror     a       			; A93F 6A                       j
	sta     VAR     			; A940 85 D8                    ..
	lsr     a       			; A942 4A                       J
	sta     TMP	 			; A943 85 D9                    ..
	lsr     a       			; A945 4A                       J
	clc             			; A946 18                       .
	adc     LB9FA,x 			; A947 7D FA B9                 }..
	adc     TMP	 			; A94A 65 D9                    e.
	cmp     #$C0    			; A94C C9 C0                    ..
	bcc     :+				; A94E 90 02                    ..
	lda     #$BF    			; A950 A9 BF                    ..
:	sta     CURSOR1_Y			; A952 85 A6                    ..
	lda     CURSOR2_Y			; A954 A5 9E                    ..
	and     #$03    			; A956 29 03                    ).
	cmp     #$01    			; A958 C9 01                    ..
	lda     VAR     			; A95A A5 D8                    ..
	adc     TMP	 			; A95C 65 D9                    e.
	sta     CURSOR2_Y			; A95E 85 9E                    ..
	rol     CURSOR2_Y+1			; A960 26 9F                    &.
:	rts             			; A962 60                       `

;*******************************************************************************
;*                                                                             *
;*                               proc_keyboard                                 *
;*                                                                             *
;*                           Handle keyboard input                             *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; Handles user input from keyboard.
;
; This subroutine processes keyboard events. Some key presses are intended to be 
; forwarded onto the PLATO service. Some key presses are intended to not be sent 
; to PLATO and instead alter some aspect of THE LEARNING PHONE program, such as 
; communication settings or user interface preferences.
;
; CH contains the last keyboard scan code observed from an IRQ event. In its raw 
; form, the Atari's keyboard scan code is meaningless to the PLATO system. It 
; must be translated to an ASCII code on the Atari side that is in turn mapped 
; to a PLATO code on the PLATO side. For most keys (A-Z, 0-9, etc) this 
; transformation is trivial. For special PLATO terminal keys (STOP, NEXT, etc.),
; cross-reference tables are needed.  TODO

; To convert the raw Atari keyboard scan code to an ASCII code, a CIO call to 
; the K: device can be used.
;
; If the keyboard scan code maps to a PLATO terminal function key, then the 
; PLATO character code is resolved using one of three cross-reference tables.
;
; PLATO terminal function keys are usually mapped to a START + key 
; combination. Some exceptions exist. For example the PLATO NEXT key can be
; entered on the Atari by pressing the START + n key combination or pressing
; just the "RETURN" key. 
; 
; For the START + key combinations, the table at $BA12-$BA44 maps an Atari
; keyboard scan code to (usually) two ASCII codes. One ASCII code for 
; unshifted and the other unshifted. These ASCII codes are mapped again
; on the PLATO side to PLATO's special terminal function keys such as 
; NEXT, LAB, STOP, and so on.
; ------------------------------------------------------------------------------

proc_keyboard:					; A963
	ldx     CH				; Get key code ($FF if none)
	inx             			; Is key pressed?
	bne     :+				; Yes, skip ahead.

;** (n) Test HELP key or RTS ***************************************************
	lda     HELPFG				; Is HELP pressed?
	beq     :-				; No, jump to nearby RTS.

;** (n) TODO Jump to HELP key routine? (Undocumented?) *************************
	stx     HELPFG				; X = HELP (clobbered later?)
	lda     #$0B    			; A = $0B
	jmp     send_to_plato			; Called routine will RTS

;** (n) Test if CTRL + key was pressed *****************************************
:	dex             			; X = key code
	bmi     LA9CE   			; Is CTRL pressed? Yes, skip way ahead.
	stx     VAR     			; VAR = key code

; ------------------------------------------------------------------------------
;                             ATARI FUNCTION KEYS
;                           ENTERED WITH [START] KEY
;
; PLATO was designed to be used with a Control Data keyboard. This keyboard has
; special function keys which are not on the Atari keyboard. PLATO function 
; commands can be generated on the Atari by holding down START and the first 
; letter of the PLATO function key, such as PLATO [BACK] = Atari [START] + [B].
; An exception is the PLATO [MICRO] and [FONT] keys. These are mapped to the 
; Atari logo ("/|\") key and are handled as a special case later.
; ------------------------------------------------------------------------------
	lda     CONSOL				; Get CONSOL status.
	lsr     a       			; START pressed?
	bcs     LA9AB   			; no START, skip way ahead.

; ------------------------------------------------------------------------------
; The "SHIFTED" function key commands used in PLATO can be used on the Atari
; keyboard by pressing [SHIFT] or [SELECT] while pressing the two keys that
; translate the PLATO function key.
;
; If SELECT or SHIFT key was also pressed then skew BA12 table lookup.
; ------------------------------------------------------------------------------
	ldy     #$FF    			; Let Y = -1
	lsr     a       			; is SELECT also pressed?
	bcc     :+				; yes, skip ahead (Y becomes 0)

	cpx     #$40    			; is SHIFT pressed?
	bcc     :++				; no, skip ahead (Y remains -1).
:	iny             			; yes, (Y becomes 0)

:	sty     TMP	 			; $00->SHIFTED $FF->NOT SHIFTED

; ------------------------------------------------------------------------------
; Scan through the $BA12 table looking for a match to the current Atari key code.
; The $BA12 table contains Atari key codes that correspond to a special 
; PLATO function key that must be entered using the Atari's [START] console key. 
; ------------------------------------------------------------------------------
	lda     VAR     			; Let A = original key code
	and     #$3F    			; Strip off SHIFT and/or CTRL 

	ldy     #$30    			; Loop through BA12 table
:	cmp     LBA12,y 			; Compare key code to lookup entry
	beq     :+				; if match found, skip ahead
	dey             			; otherwise keep looking
	dey             			; 
	dey             			; 
	bpl     :-				; End loop 
	bmi     LA9CE   			; Skip ahead and RTS if no match.

; ------------------------------------------------------------------------------
; An Atari key code match was found. Get the corresponding ASCII code (shifted or
; unshifted) that will be sent to PLATO. 
; ------------------------------------------------------------------------------
:	ldx     TMP	 			; D9 is the shifted key modifier
	bmi     :+				; was SHIFT key pressed earlier?
	iny             			; no,  set offset mod = 2
:	iny             			; yes, set offset mod = 1
	lda     LBA12,y 			; Let A = translated character
LA9A8:  jmp     LAA91   			; TODO

; ------------------------------------------------------------------------------
;                         PLATO [MICRO] and [FONT] keys
;
; The mapping for PLATO function keys for MICRO and FONT are a special case for
; the mapping of terminal function keys.. These two keys are not translated from
; a [START] key combination. Instead, the ATARI logo "/|\" key (or inverse key on 
; later models) alone is bound to MICRO and [SHIFT] + "/|\" is bound to FONT.

;                   MICRO
;   PLATO KEY      PLATO KEY       ASCII CHAR.     ASCII CHAR.
;                  CODE (HEX)      GENERATED       CODE (HEX)
;     SYMBOL          SHIFT          SYMBOL          SHIFT
;   LOWER  UPPER     OFF  ON       LOWER  UPPER     OFF  ON
; 
;     MICRO  FONT    14   34          {     DEL     7B   7F
; ------------------------------------------------------------------------------
LA9AB:  lda     VAR     			; Let A = original keycode
	cmp     #key_atari			; was Atari key pressed?
	bne     :+				; no, skip to next
	lda     #$7B    			; ASCII code that translates to PLATO MICRO
	bne	LA9A8				; let plato_char = MICRO and RTS

:	cmp     #key_atari + mod_shift    	; was SHIFT + Atari key pressed?
	bne     :+				; no, skip to next
	lda     #$7F    			; ASCII code that translates to PLATO FONT
	bne     LA9A8   			; let plato_char = FONT and RTS

; ------------------------------------------------------------------------------
;                              TOGGLE SHIFT LOCK
; ------------------------------------------------------------------------------
:	cmp     #key_caps    			; was CAPS/LOWR key pressed?
	bne     :+				; no, skip to next
	lda     #$00    			; 
	beq     :++				; let SHFLOK = lower case

:	cmp     #key_caps + mod_shift		; was SHIFT + CAPS/LOWR pressed?
	bne     LA9DD   			; no, skip
	lda     #$40    			; 
:	sta     SHFLOK				; Set SHFLOK to upper case

; ------------------------------------------------------------------------------
;                                WAIT AND RTS
; ------------------------------------------------------------------------------
LA9CE:  ldx     #$7F    			; for X = 127 to 0 step -1
:	stx     CONSOL				; 
	stx     WSYNC				; 127 WSYNCs?
	dex             			; 
	bpl     :-				; next X
	stx     CH				; Clear key code (X = $FF)
	rts             			; 

; ------------------------------------------------------------------------------
;                   TRANSLATE NORMAL KEY PRESSES TO (AT)ASCII
; ------------------------------------------------------------------------------
LA9DD:  ldy     #read_k-tab_iocb		; Prepare CIO call to read keyboard
	jsr     call_cio_or_err			; Make CIO call 
	sta     plato_char     			; CIO returns with ATASCII from keyboard
	lda     CONSOL				; check console keys
	and     #$07				; mask irrelevant bits
	cmp     #$03				; is OPTION pressed?
	bne     LAA62				; no, skip ahead
	lda     SRTIMR				; check key repeat timer
	beq     LAA62   			; A9F0 F0 70                    .p
	lda     VAR     			; Load original key press
	and     #$3F    			; Strip off CTRL and SHIFT

; ------------------------------------------------------------------------------
;                                 OPTION KEYS
;
; The next set of key presses are not meant to be sent to the PLATO server. 
; Instead these affect the behavior or appearance of THE LEARNING PHONE program.
;
; [OPTION] + 0 - Toggle local echo / remote echo
; [OPTION] + 1 - Force baud rate to 1200 bps if non-MPP modem is being used
; [OPTION] + 3 - Force baud rate to 300 bps
; [OPTION] + c - Pressing SELECT will cycle through background colors
; [OPTION] + b - Pressing SELECT will cycle through background brightnesses
; [OPTION] + t - Pressing SELECT will cycle through foreground brightnesses
; [OPTION] + f - Toggle joystick-mapped function key entry
; [OPTION] + z - Toggle between full-screen and zoomed displays
; [OPTION] + m - Force Microbits MPP modem
; [OPTION] + p - Print screen
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; OPTION + '0'
; ------------------------------------------------------------------------------
	cmp     #key_0    			; was OPTION + 0 pressed?
	bne     :+				; no, skip to next
	lda     CURRENT_ECHO   			; 
	eor     #$80    			; 
	sta     CURRENT_ECHO   			; toggle echo setting
	rts             			; and return

; ------------------------------------------------------------------------------
; OPTION + '1'
; ------------------------------------------------------------------------------
:	cmp     #key_1    			; did user press '1'?
	bne     :++				; no, skip further ahead
	lda     #$00    			;   $00 -> baud = 1200

;** (1) Ignore key press if using Microbits 300 ********************************
:	ldy     IS_MPP				; are we using the MPP modem? 1->MPP 0->Modem
	bne     LAA23   			; yes, skip this part

;** (2) Change baud rate setting  **********************************************
	sta     CURRENT_BAUD			; Save new baud (FF=300 00=1200)
	jmp     sub_user_baud			; sub_user_baud will RTS

; ------------------------------------------------------------------------------
; OPTION + '3'
; ------------------------------------------------------------------------------
:	cmp     #key_3    			; did user press '3'?
	bne     :+				; no, skip to next
	lda     #$FF    			;   $FF -> baud = 300
	bne     :--				;   Jump back to store baud in $B1

; ------------------------------------------------------------------------------
; OPTION + 'c'
; ------------------------------------------------------------------------------
:	cmp     #key_c    			; did user press 'c'?
	bne     :+				; no, skip to next
	lda     #$00    			; 
LAA20:  sta     CURRENT_SELECT  		; Change flag in $1355 and RTS
LAA23:  rts             			; 

; ------------------------------------------------------------------------------
; OPTION + 'b'
; ------------------------------------------------------------------------------
:	cmp     #key_b    			; did user press 'b'?
	bne     :+				; no, skip to next
	lda     #$80    			; 
	bne     LAA20   			; Change flag in $1355 and RTS

; ------------------------------------------------------------------------------
; OPTION + 't'
; ------------------------------------------------------------------------------
:	cmp     #key_t				; did user press 't'?
	bne     :+				; no, skip to next
	lda     #$C0    			; 
	bne     LAA20   			; Change flag in $1355 and RTS

; ------------------------------------------------------------------------------
; OPTION + 'f'
; ------------------------------------------------------------------------------
:	cmp     #key_f    			; did user press 'f'?
	bne     :+++				; no, skip out
	ldx     CURRENT_DL			; is display currently zoomed?
	beq     :+++				; yes, skip to OPTION + 'z'
	lda     UI_MODE				; is display full-screen (no touch screen)?
	beq     :+				; yes, skip to OPTION + 'z'
	cmp     #$02    			; is joystick in function key mode?
	bne     LAA23   			; no, jump to nearby RTS
:	eor     #$02    			; toggle current mode
	sta     UI_MODE				; 
	tax             			; if new mode is full-screen with no touch screen
	beq     :+				; then hide the cross-shaped cursor (x=0)
	ldx     #$32    			; else show the large "F".
:	stx     HPOSM3				; Position "|" part of "F"
	inx             			;
	inx             			;
	stx     HPOSM2				; Position "=" part of "F"
	rts             			;

; ------------------------------------------------------------------------------
; OPTION + 'z'
; ------------------------------------------------------------------------------
:	cmp     #key_z    			; did user press 'z'?
	beq     swap_display			; yes, swap display mode and RTS

; ------------------------------------------------------------------------------
; OPTION + 'm'
; ------------------------------------------------------------------------------
	cmp     #key_m    			; did user press 'm'?
	beq     jmp_config_mpp  		; call config_mpp and RTS

; ------------------------------------------------------------------------------
; OPTION + 'p'
; ------------------------------------------------------------------------------
	cmp     #key_p  			; was OPTION + 'p'?
	beq     jmp_printscreen 		; yes, call print_screen and RTS

; ------------------------------------------------------------------------------
;			      ATARI FUNCTION KEYS 
;			   ENTERED WITHOUT [START] KEY
;
; This set of PLATO terminal keys do not require a [START] + key combination.
; For example, the PLATO [NEXT] key is mapped to the Atari [RETURN] key and 
; the PLATO [NEXT1] is mapped to the Atari [SHIFT] + [RETURN] keys.
;
; Scan through the $BA45 table looking for a match to the current Atari key code.
; ------------------------------------------------------------------------------
LAA62:  ldy     #$0C    			; Loop through $BA45 table
	lda     VAR     			; Load original key code
:	cmp     LBA45,y 			; Compare key code to lookup entry
	beq     LAA8A   			; if match found, skip ahead
	dey             			; otherwise keep looking.
	dey             			; 
	bpl     :-				; 

; ------------------------------------------------------------------------------
;                       PROCESS PLATO 2-BYTE CHARACTERS
;
; The original PLATO terminal had no keys defined for the characters: \^|#&@
; Later PLATO terminals implemented these characters using a two-byte sequence.
; The first character is byte code $00 (the PLATO character is called ACCESS) 
; followed by a second byte as defined in the table at $BA53.
; 
; Search for the keyboard scan code entered by the user in the table #3 at 
; $BA53. If a match is found, send a $00 (ACCESS) to PLATO, then send the 
; translation character from the table.
; ------------------------------------------------------------------------------
	ldy     #$0A    			; Initialize loop counter
:	cmp     LBA53,y 			; Does key code match table key?
	beq     LAA7C   			; yes, send $00 (ACCESS) to PLATO
	dey             			; no, keep looking
	dey             			; 
	bpl     :-				; 
	bmi     LAA96   			; no match. send original key code to PLATO

; ------------------------------------------------------------------------------
; An Atari key code match was found in table #3. Send a two-byte character 
; sequence. The first character is a PLATO ACCESS character ($00) followed by 
; the translation character.
; ------------------------------------------------------------------------------
LAA7C:  sty     plato_char     			; Temporarily save the table offet
	lda     #$00    			; Send a PLATO 'ACCESS' character
	jsr     send_to_plato2		; to the PLATO server.
	ldy     plato_char     			; Restore table offset.
	lda     LBA54,y 			; Use it to get the translation 
	bne     LAA8D   			; character and send it to PLATO.

LAA8A:  lda     LBA46,y 			; Load translation character from table #2
LAA8D:  sta     plato_char     			; Save character destined for PLATO
	bne     LAA96   			; and send it to PLATO.

LAA91:  sta     plato_char     			; Let A = value associated with key code
	jsr     LA9CE   			; 

; ----------------------------------------------------------------------------
; If local echo is enabled and the character is printable, render a bitmap
; for the character in video memory
; ----------------------------------------------------------------------------
LAA96:  bit     CURRENT_ECHO   			; is remote echo enabled?
	bmi     LAB00   			; yes, don't print, send $E7, RTS
	lda     plato_char     			; 
	cmp     #$20    			; is $E7 a printable char? 
	bcs     LAAFD   			; yes, print char, send $E7, RTS
	jsr     proc_control_ch 		; AAAD 20 F6 A5
	jmp     LAB00   			; and send $E7, and RTS

; ----------------------------------------------------------------------------
jmp_config_mpp:					; AAA7  
	jmp     config_mpp

; ----------------------------------------------------------------------------
jmp_printscreen:				; AAAA
	jmp     print_screen

;*******************************************************************************
;*                                                                             *
;*                               swap_display                                  *
;*                                                                             *
;*     Change display/input mode from full-screen to zoomed or vice-versa.     *
;*                                                                             *
;*******************************************************************************
swap_display:					; AAAD  
	jsr     hide_big_f   			; Hide "F" displayed in function key mode
	lda     UI_MODE  			; is current display full-screen with...
	cmp     #$02    			; ...joystick-mapped function keys?
	bne     :+				; no, skip ahead.
	lda     #$00    			; yes. well not any more. stick now needed for scrolling.
:	eor     #$FF    			; Toggle current input/display mode
	sta     UI_MODE  			; Store new input/display mode.
	bmi     @DL_ZOOMED			; UI_MODE < 0 -> zoomed mode
	beq     @DL_SCALED			; UI_MODE = 0 -> full-screen mode (no cursor)
						; UI_MODE > 0 -> full-screen mode (with cursor)

;** (n) Restore touch screen cross-shaped cursor position **********************
	ldx     CROSS_X 			; Retrieve previous cursor position
	stx     HPOSM1				; Left half of cross-shaped cursor
	inx             			; 
	inx             			; 
	stx     HPOSM0				; Right half of cross-shaped cursor

;** (n) Change to full-screen display ***********************************************
@DL_SCALED:	
	lda     FG_COLOR_DL1    		; Restore foreground color for...
	sta     COLOR1  			; ...full-screen display mode.
	ldy     #$80    			; 
	sty     CURRENT_DL			; $80->full-screen mode
	ldy     BG_COLOR_DL1    		; Get the color for the display mode
	lda     #<$1000 			; LSB of Display List #1
	ldx     #>$1000 			; MSB of Display List #1
	bne     LAAF0   			; Jump to DLIST pointer and RTS

;**(n) Change to zoomed display ***********************************************
@DL_ZOOMED:	
	ldx     #$00    			; 
	stx     HPOSM1				; Move cursor off screen
	stx     HPOSM0				;
	stx     CURRENT_DL			; $00->zoomed mode
	lda     FG_COLOR_DL2    		; Change forground color
	sta     COLOR1  			; 
	ldy     BG_COLOR_DL2    		; Get the background color
	lda     #<$10CA				; LSB of Display List #2
	ldx     #>$10CA				; MSB of Display List #2

;**(n) Change display list pointers *******************************************
LAAF0:  sta	DLIST				; Point to new display list
	stx	DLIST+1				;
	sty     COLOR2  			; Set colors for background
	sty     COLOR4  			; and border for the new mode
	rts             			; 

; ----------------------------------------------------------------------------
LAAFD:  jsr     print_char   			; AAFD 20 5D AB                  ].
LAB00:  lda     plato_char     			; AB00 A5 E7                    ..
LAB02:  jmp     send_to_plato

;*******************************************************************************
;*                                                                             *
;*                           ?????????????????????                             *
;*                                                                             *
;*                        ????????????????????????????                         *
;*                                                                             *
;*******************************************************************************
LAB05:  dey             			; clear trigger state to -1
	sty     JSTICK_TR 			; 
	txa             			; AB08 8A                       .
	dex             			; AB09 CA                       .
	bmi     swap_display			; AB0A 30 A1                    0.
	bne     LAB53   			; AB0C D0 45                    .E
	jsr     play_beep
	lda     #$1B    			; AB11 A9 1B                    ..
	jsr     send_to_plato2
	lda     #$00    			; AB16 A9 00                    ..
	sta     $E7     			; AB18 85 E7                    ..
	sta     $4D     			; AB1A 85 4D                    .M
	lda     TOUCH_X     			; AB1C A5 BF                    ..
	lsr     a       			; AB1E 4A                       J
	ror     $E7     			; AB1F 66 E7                    f.
	lsr     a       			; AB21 4A                       J
	ror     $E7     			; AB22 66 E7                    f.
	pha             			; AB24 48                       H
	lda     $E7     			; AB25 A5 E7                    ..
	lsr     a       			; AB27 4A                       J
	lsr     a       			; AB28 4A                       J
	ora     #$40    			; AB29 09 40                    .@
	ora     $C0     			; AB2B 05 C0                    ..
	jsr     send_to_plato2
	pla             			; AB30 68                       h
	ora     #$44    			; AB31 09 44                    .D
	bne     LAB02   			; always jumps

;*******************************************************************************
;*                                                                             *
;*                               proc_joystick                                 *
;*                                                                             *
;*                            Handle joystick input                            *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; This subroutine processes the joystick events related to a) sending a PLATO 
; terminal key entered using the joystick handle or b) swapping the display mode 
; between full-screen and zoomed using the joystick trigger. 
;
; Other events like moving the touch screen cross-shaped cursor and panning the 
; zoomed display are handled during the vertical blank, when the joystick is 
; polled and the variables JSTICK_FN and JSTICK_TR are updated.
; 
; If the joystick-mapped function key mode is active and JSTICK_FN is non-zero 
; (that is, it contains a PLATO function key code), send its value to PLATO.
;
; If the joystick-mapped function key mode is not active and JSTICK_TR is zero
; (pressed) then swap between full-screen and zoomed display mode or vice-versa.
;

proc_joystick:					; AB35

;** Skip to joystick trigger if not in joystick-mapped function key mode *******
	ldx     UI_MODE     			; 
	cpx     #$02    			; Using joystick-mapped mode?
	bne     @TRIG				; no, skip to trigger check.

;** Examine joystick-mapped key code *******************************************
	lda     JSTICK_FN			; Let A = char to send to PLATO
	beq     @TRIG				; Skip if nothing (0) to send.

;** Clear variables to avoid re-sending ****************************************
	ldx     #$00    			; 
	stx     JSTICK_FN    			; Clear joystick key press
	stx     ATRACT  			; Clear attract mode

	dex             			; 
	stx     JSTICK_TR 			; Clear trigger state (-1)

;** Play Beep ***********************************************************************
	pha             			; Stash A 
	jsr     play_beep			; beep
	pla             			; Restore A

;** Send to PLATO **************************************************************
	bne     LAB02   			; Send A to PLATO and RTS

;** Process joystick trigger ***************************************************
@TRIG:	ldy     JSTICK_TR 			; is trigger pressed? (0=yes)
	beq     LAB05   			; yes, swap display mode (full-screen vs zoomed)
LAB53:  rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                send_to_plato2                               *
;*                                                                             *
;*            Send character to PLATO, reset system timer, and RTS             *
;*                                                                             *
;*******************************************************************************
send_to_plato2:					; AB54
	jsr     send_to_plato
	jmp     set_sys_tm1

;*******************************************************************************
;*                                                                             *
;*                                print_char2                                  *
;*                                                                             *
;*                 Entry point #2 for draw character on the screen             *
;*                                                                             *
;*******************************************************************************
; DESCRIPTION
; Same as print_char except char is what was received from PLATO
print_char2:					; AB5A
	lda     SERIN_BUF   			; Char from PLATO

;*******************************************************************************
;*                                                                             *
;*                                 print_char                                  *
;*                                                                             *
;*                        Draw character on the screen                         *
;*                                                                             *
;*******************************************************************************
; DESCRIPTION
; Parameters:
; A = character to be printed
print_char:					; AB5D
	sta     plato_char     			; Character to be displayed
	sec             			; Test to see if non-printing character 
	sbc     #$20    			;
	bcs     :+				;
	rts             			; RTS now if non-printing character

:	pha             			; Stash character-#$20
	ldx     IS_16K     			; 
	stx     COMPR     			; 
	bne     :+				; Full screen only? -->

;** Zoomed display *************************************************************
	stx     $E6     			; Let $E6 = 0 TODO
	stx     VAR     			; Let VAR = 0 TODO
	jsr	sub_abff

	dec     COMPR     			; AB73 C6 C9                    ..
	ldx     COMPR     			; AB75 A6 C9                    ..

;** Full screen display ********************************************************
:	pla             			; AB77 68                       h
	inx             			; AB78 E8                       .
	stx     $E6     			; AB79 86 E6                    ..
	ldx     CURRENT_SIZE 			; Current text/font size
	beq     LAB94   			; normal text? -->
	jsr     sub_ab88			; bold text? JSR
	ldx     #$FF    			; AB82 A2 FF                    ..
	stx     CURRENT_SIZE   			; AB84 86 CA                    ..
	bne     LABD3   			; always branches

; ----------------------------------------------------------------------------
sub_ab88:
	inc     CURSOR1_X     			; AB88 E6 A4                    ..
	bne     :+
	inc     CURSOR1_X+1    			; AB8C E6 A5                    ..
:	ldx     #$7F    			; AB8E A2 7F                    ..
	stx     CURRENT_SIZE 			; AB90 86 CA                    ..
	bne     sub_abff

; ----------------------------------------------------------------------------
LAB94:  jsr     LAD05   			; AB94 20 05 AD                  ..
	bit     SCREEN_MODE			; AB97 24 B0                    $.
	bvs     LABD3   			; AB99 70 38                    p8

;** Get the byte offset from start of the scan line for 16-bit CURSOR2_X *******
	jsr     div_cx2_by_8			; Offset saved to SUMLO
	lda     CURSOR2_X
	and     #$04    			; ABA0 29 04                    ).
	beq     :+				; ABA2 F0 02                    ..
	inc     SUMLO
:	lda     CURSOR1_Y			; ABA6 A5 A6                    ..
	ldy     #$20    			; ABA8 A0 20                    . 
	sec             			; ABAA 38                       8
:	sbc     #$06    			; ABAB E9 06                    ..
	dey             			; ABAD 88                       .
	bcs     :-
	tya             			; ABB0 98                       .
	and     #$03    			; ABB1 29 03                    ).
	tax             			; ABB3 AA                       .
	tya             			; ABB4 98                       .
	lsr     a       			; ABB5 4A                       J
	lsr     a       			; ABB6 4A                       J
	clc             			; ABB7 18                       .
	adc     #$18    			; ABB8 69 18                    i.
	sta     YOUT+1
	lda     PAGE,x				; ABBC BD 36 B9                 .6.
	sta     YOUT
	lda     $E7     			; ABC1 A5 E7                    ..
	ldy     SUMLO
	cmp     #$5F    			; ABC5 C9 5F                    ._
	bne     :+				; ABC7 D0 08                    ..
	lda     (YOUT),y
	cmp     #$20    			; ABCB C9 20                    . 
	bne     LABD3   			; ABCD D0 04                    ..
	lda     #$5F    			; ABCF A9 5F                    ._
:	sta     (YOUT),y
LABD3:  jsr     get_font_width
	ldy     VAR     			; ABD6 A4 D8                    ..
	clc             			; ABD8 18                       .
	adc     CURSOR1_X     			; ABD9 65 A4                    e.
	sta     CURSOR1_X     			; ABDB 85 A4                    ..
	bcc     :+				; ABDD 90 02                    ..
	inc     CURSOR1_X+1    			; ABDF E6 A5                    ..
:	tya             			; ABE1 98                       .
	clc             			; ABE2 18                       .
	adc     CURSOR2_X     			; ABE3 65 9C                    e.
	sta     CURSOR2_X     			; ABE5 85 9C                    ..
	bcc     :+
	inc     CURSOR2_X+1
:	lda     CURSOR2_X+1
	cmp     #$02    			; ABED C9 02                    ..
	bcc     LABFE   			; ABEF 90 0D                    ..
	lda     CURSOR1_X     			; ABF1 A5 A4                    ..
	sec             			; ABF3 38                       8
	sbc     #$40    			; ABF4 E9 40                    .@
	sta     CURSOR1_X     			; ABF6 85 A4                    ..
	lda     #$00    			; ABF8 A9 00                    ..
	sta     CURSOR1_X+1    			; ABFA 85 A5                    ..
	sta     CURSOR2_X+1    			; ABFC 85 9D                    ..
LABFE:  rts             			; ABFE 60                       `

; ----------------------------------------------------------------------------
sub_abff:
	ldx     CURRENT_CHSET
	cpx     #$02    			; is curr char set M0?
	bcc     LAC24   			; Carry set back in print_char SBC #$20
	bne     :+				; AC05 D0 0A                    ..

	cmp     #$40    			; AC07 C9 40                    .@
	tax             			; AC09 AA                       .
	lda     #$E0    			; AC0A A9 E0                    ..
	adc     #$00    			; Copy Carry to bit 0 (E0 or E1) TODO
	sta     $EB     			; 

;** Rotate bits 7,6,5 from A into E6 *******************************************
;** If A = 41 in the end E6 = 02 and A = 08
	txa             			; Fetch serin char - #$20
:	asl     a       			; 
	rol     byte_E6				; Xfer A's bit 7 into E6

	asl     a       			; 
	rol     byte_E6				; Xfer A's bit 6 into E6

	asl     a       			; 
	rol     byte_E6				; Xfer A's bit 5 into E6
	sta     byte_E5				; Save what's left of A

	ldx     CURRENT_CHSET				; 
	cpx     #$03    			; AC1E E0 03                    ..
	bcs     LAC37   			; AC20 B0 15                    ..
	bcc     LAC3C   			; AC22 90 18                    ..

LAC24:  asl     a       			; AC24 0A                       .
	asl     a       			; AC25 0A                       .
	rol     $E6     			; AC26 26 E6                    &.
	sta     TMP	 			; AC28 85 D9                    ..
	ldx     $E6     			; AC2A A6 E6                    ..
	stx     VAR     			; AC2C 86 D8                    ..
	asl     a       			; AC2E 0A                       .
	rol     $E6     			; AC2F 26 E6                    &.
	adc     TMP	 			; AC31 65 D9                    e.
	bcc     LAC37   			; AC33 90 02                    ..
	inc     $E6     			; AC35 E6 E6                    ..
LAC37:  clc             			; AC37 18                       .
	adc     $EA     			; AC38 65 EA                    e.
	sta     off_E5
LAC3C:  lda     VAR     			; AC3C A5 D8                    ..
	adc     $E6     			; AC3E 65 E6                    e.
	adc     $EB     			; AC40 65 EB                    e.
	sta     $E6     			; AC42 85 E6                    ..
	jsr     get_pfaddr

	lda     CURRENT_SIZE 			; AC47 A5 CA                    ..
	cmp     #$7F    			; AC49 C9 7F                    ..

	bne     LAC56   			; AC4B D0 09                    ..
	lda     #$00    			; AC4D A9 00                    ..
	sta     COMPR     			; AC4F 85 C9                    ..
	lda     CURSOR1_X     			; AC51 A5 A4                    ..
	jmp     LAC58   			; AC53 4C 58 AC                 LX.

; ----------------------------------------------------------------------------
LAC56:  lda     CURSOR2_X     			; AC56 A5 9C                    ..
LAC58:  jsr     sub_adcb
	ldx     #$0B    			; AC5B A2 0B                    ..
LAC5D:  ldy     #$00    			; AC5D A0 00                    ..
	sty     VAR     			; AC5F 84 D8                    ..
	lda     CURRENT_CHSET
	lsr     a       			; AC63 4A                       J
	beq     LAC78   			; AC64 F0 12                    ..
	cpx     #$0A    			; AC66 E0 0A                    ..
	bcs     :+
	cpx     #$02    			; AC6A E0 02                    ..
	bcc     :+
	txa             			; AC6E 8A                       .
	sbc     #$02    			; AC6F E9 02                    ..
	bcs     LAC79   			; AC71 B0 06                    ..
:	lda     #$00    			; AC73 A9 00                    ..
	tay             			; AC75 A8                       .
	beq     LAC7C   			; AC76 F0 04                    ..
LAC78:  txa             			; AC78 8A                       .
LAC79:  tay             			; AC79 A8                       .
	lda     (off_E5),y
LAC7C:  ldy     CURRENT_SIZE     		; AC7C A4 CA                    ..
	bpl     LACB3   			; AC7E 10 33                    .3
	sta     $E7     			; AC80 85 E7                    ..
	lsr     a       			; AC82 4A                       J
	lsr     a       			; AC83 4A                       J
	lsr     a       			; AC84 4A                       J
	lsr     a       			; AC85 4A                       J
	tay             			; AC86 A8                       .
	lda     LBA02,y 			; AC87 B9 02 BA                 ...
	sta     DELHI     			; AC8A 85 FB                    ..
	lda     plato_char     			; AC8C A5 E7                    ..
	and     #$0F    			; AC8E 29 0F                    ).
	tay             			; AC90 A8                       .
	lda     LBA02,y 			; AC91 B9 02 BA                 ...
	sta     off_FA

	lda     #$80    			; AC96 A9 80                    ..
	sta     CURRENT_SIZE 			; AC98 85 CA                    ..

LAC9A:  ldy     #$00    			; AC9A A0 00                    ..
	lda     off_FA+1
	jsr     sub_ad3a   			; AC9E 20 3A AD                  :.
	lda     DELLO     			; ACA1 A5 FA                    ..
	jsr     sub_ad3a

	bit     CURRENT_SIZE   			; ACA6 24 CA                    $.
	bvs     LACB8   			; ACA8 70 0E                    p.
	jsr     sub_accd

	lda     #$FF    			; ACAD A9 FF                    ..
	sta     CURRENT_SIZE 			; ACAF 85 CA                    ..

	bne     LAC9A   			; ACB1 D0 E7                    ..
LACB3:  ldy     #$00    			; ACB3 A0 00                    ..
	jsr     sub_ad3a
LACB8:  dex             			; ACB8 CA                       .
	bmi     LACE2   			; ACB9 30 27                    0'

	lda     CURRENT_SIZE			; ACBB A5 CA                    ..
	cmp     #$7F    			; ACBD C9 7F                    ..
	bne     LACC7   			; ACBF D0 06                    ..

	jsr	sub_ace3
	jmp     LAC5D   			; ACC4 4C 5D AC                 L].

; ----------------------------------------------------------------------------
LACC7:  jsr     sub_accd   			; ACC7 20 CD AC                  ..
	jmp     LAC5D   			; ACCA 4C 5D AC                 L].

; ----------------------------------------------------------------------------
sub_accd:
	sec             			; ACCD 38                       8
	lda     YOUT
	sbc     #$40    			; ACD0 E9 40                    .@
	sta     YOUT
	bcs     LACE2
	dec     YOUT+1
	lda     YOUT+1
	cmp     #$40    			; ACDA C9 40                    .@
	bcs     LACE2
	lda     #$9F    			; ACDE A9 9F                    ..
	sta     $E4     			; ACE0 85 E4                    ..
LACE2:	rts             			; ACE2 60                       `

; ----------------------------------------------------------------------------
sub_ace3:
	sec             			; ACE3 38                       8
	lda     YOUT
	sbc     #$28    			; ACE6 E9 28                    .(
	sta     YOUT
	bcs     LAD04   			; ACEA B0 18                    ..
	dec     YOUT+1
	lda     YOUT+1
	cmp     #>L2000
	beq     :+
	bcs     LAD04   			; ACF4 B0 0E                    ..
	lda     #$3D    			; ACF6 A9 3D                    .=
	bne     LAD02   			; ACF8 D0 08                    ..

; ----------------------------------------------------------------------------
:	lda     YOUT
	cmp     #$10    			; ACFC C9 10                    ..
	bcs     LAD04   			; ACFE B0 04                    ..
	lda     #$3E    			; AD00 A9 3E                    .>
LAD02:  sta     YOUT+1
LAD04:  rts             			; AD04 60                       `

; ----------------------------------------------------------------------------
LAD05:  asl     a       			; AD05 0A                       .
	sta     TMP	 			; AD06 85 D9                    ..
	asl     a       			; AD08 0A                       .
	rol     $E6     			; AD09 26 E6                    &.
	clc             			; AD0B 18                       .
	adc     TMP	 			; AD0C 65 D9                    e.
	bcc     :+
	inc     $E6     			; AD10 E6 E6                    ..
	clc             			; AD12 18                       .
:	adc     CHSET_BASE			; AD13 65 E8                    e.
	sta     off_E5
	lda     off_E5+1
	adc     CHSET_BASE+1			; AD19 65 E9                    e.
	sta     off_E5+1
	jsr     get_pfaddr
	lda     CURSOR1_X     			; AD20 A5 A4                    ..
	jsr     sub_adcb
	ldx     #$05    			; AD25 A2 05                    ..
:	jsr     sub_ad34   			; AD27 20 34 AD                  4.
	dex             			; AD2A CA                       .
	bmi	:+
	jsr     sub_ace3
	jmp     :-

; ----------------------------------------------------------------------------
:	rts

; ----------------------------------------------------------------------------
sub_ad34:  
	txa             			; AD34 8A                       .
	tay             			; AD35 A8                       .
	lda     (off_E5),y
	ldy     #$00    			; AD38 A0 00                    ..

sub_ad3a:
	bit     SCREEN_MODE			; AD3A 24 B0                    $.
	bvc     :+
	eor     #$FF    			; AD3E 49 FF                    I.
	bit     COMPR     			; AD40 24 C9                    $.
	bvc     :+
	and     #$F8    			; AD44 29 F8                    ).
:	sty     $FC     			; AD46 84 FC                    ..
;
;   fine coord, need to shift char pattern
;
	ldy     #$00    			; AD48 A0 00                    ..
	sty     VAR     			; use VAR for rt portion
	ldy     SUMLO				; recover shift ct
	beq     LAD56   			; AD4E F0 06                    ..
:	lsr     a       			; into C
	ror     VAR     			; AD51 66 D8                    f.
	dey             			; AD53 88                       .
	bne     :-
LAD56:  sta     TMP	 			; AD56 85 D9                    ..
	ldy     YM				; AD58 A4 FC                    ..
	lda     (YOUT),y			; fetch affected byte
	bit     SCREEN_MODE			; ck plot mode
	bmi     LAD67   			; overstrike[WR,ER]-->
; here non-overstrike, need to mask then just OR in
	and     LEND     			; 
LAD62:  ora     TMP	 			; put 1st byte for[WR,RW,INV]
	jmp     LAD6F   			; finish 1st byte

; ----------------------------------------------------------------------------
LAD67:  bvc     LAD62   			; AD67 50 F9                    P.
	lda     TMP	 			; AD69 A5 D9                    ..
	ora     LEND     			; AD6B 05 AB                    ..
	and     (YOUT),y			
LAD6F:  sta     (YOUT),y			; display it
	iny             			; AD71 C8                       .
	lda     REND     			; DO 2nd byte?
	beq     LAD8D   			; nope,done 1 scan line
	lda     (YOUT),y
	bit     SCREEN_MODE			; AD78 24 B0                    $.
	bmi     LAD83   			; AD7A 30 07                    0.
; here non-overstrike, need to mask then just OR in
	and     REND     			; 
LAD7E:  ora     VAR     			; put 2nd byte for[WR,RW,INV]
	jmp     LAD8B   			; finish 2nd byte
LAD83:  bvc     LAD7E   			; WR mode-->
	lda     VAR     			; AD85 A5 D8                    ..
	ora     REND     			; AD87 05 A7                    ..
	and     (YOUT),y
LAD8B:  sta     (YOUT),y			; and display it
LAD8D:  rts             			; AD8D 60                       `

;*******************************************************************************
;*                                                                             *
;*                                get_pfaddr                                   *
;*                                                                             *
;*                         Compute playfield address                           *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This subroutine calculates the address in screen RAM where the next draw
; operation will take place. This is done for both the full screen and zoomed
; displays. COMPR is meant to skip the zoomed display on machines having less
; than 48K but does not function properly.
;
; YOUT is the 
get_pfaddr:					; AD8E
	bit     COMPR     			; Do we skip zoomed display logic?
	bvs     :+				; Full screen only? -->

;** Zoomed display *************************************************************

;-------------------------------------------------------------------------------
; Invert Y coordinate. PLATO's native screen origin (0,0) is the lower left. 
; On the Atari the same screen coordinate is (0,383). Convert the PLATO cursor
; position to an Atari screen RAM address. 
;-------------------------------------------------------------------------------

;** Use CURSOR2_Y to find the scan line. 
;** Calculate the difference between two 16-bit integers: (383 - CURSOR2_Y) .
;** 1) Calculate the difference between lo bytes.
	lda     #(<383)				; 
	sec             			; 
	sbc     CURSOR2_Y			; 383(LO) - CURSOR2_Y(LO)
	tax             			; Stash result in X
	and     #$03    			; While here, grab modulus 4 and...
	tay             			; ...use later as table index

;** 2) Calculate the difference betwen hi bytes.
	lda     #(>383)   			; 
	sbc     CURSOR2_Y+1			; 383(HI) - CURSOR2_Y(HI)
	lsr     a       			; 

	txa             			; ADA0 8A                       .
	ror     a       			; ADA1 6A                       j
	lsr     a       			; ADA2 4A                       J
	clc             			; ADA3 18                       .
	adc     #(>SCREEN_24K)  		; Offset from start of 24K framebuffer
	sta     YOUT+1				; Save MSB for character start address

;** Use CURSOR2_X to find the whole byte offset from the start of the scan line.
	jsr     div_cx2_by_8			; Byte offset returned to A
	clc             			; 

;** Get LSB for start of scanline (cycles every 4 lines $xx00,$xx40,$xx80,$xxC0)
;** and fine tune it by adding the byte offset for CURSOR2_X *******************
	adc     PAGE,y				; 
	sta     YOUT				; 
	rts             			; 

;** Full screen displsy ********************************************************
:	lda     #$BF    			; Invert Y coordinate from PLATO's lower left origin
	sec             			; 
	sbc     CURSOR1_Y			; 
	tax             			; 
	lda     $04C0,x 			; Table of pointers to screen HI
	sta     YOUT+1				; Save MSB for character start address
	jsr     div_cx1_by_8			; A = f(CURSOR1_X)
	clc             			; 
	adc     $0400,x 			; Offset from table of scan line addresses
	sta     YOUT				; Save LSB for character start address
	bcc     :+
	inc     $E4     			; ADC8 E6 E4                    ..
:	rts

;
;   got CHAR table and Disp Mem ptrs
;   ck fine coord and create left+rt masks
;
sub_adcb:					; ADCB
	and     #$07    			; see if fine coord
	sta     SUMLO				; keep shift ct in SUMLO
	bit     COMPR     			; compressed?
	bvs     :+				; yes-->
	tax             			; 
	beq     :++				; coarse coord-->
	lda     LTAB,x				; fetch left mask
;
;  left mask table is for block erase; used here to preserve partial byte
;  hence can used for REND and complemented for LEND
;
	sta     REND     			; 
	eor     #$FF    			; 
	bne     LADEE   			; uncond branch cuz LEND<>0
:	tax             			; 
	lda     CMRTAB,x 			; get right mask, if any
	sta     REND     			; 
	lda     CMTAB,x 			; get compressed left mask
	bne     LADEE   			; 
:	lda     #$00    			; preserve nothing, whole byte changed
	sta     REND     			; no need for right byte
LADEE:  sta     LEND     			; 
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                ???????????                                  *
;*                                                                             *
;*                       ?????????????????????????????                         *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; The initial coordinates for (X0,Y0) and (X1,Y1) are obtained from the current
; and previous cursor positions. There are two drawing algorithms depending
; on whether the line's slope > 1 (Major Axis = Y) or slope < 1 (Major Axis = X)
; The coordinate pairs may be swapped to ensure the (X0,Y0) pair is left-most
; and/or bottom-most.
;-------------------------------------------------------------------------------
;
;           DX   
;         x-----x
;         |     |
;         |       (X1,Y1)
;         |     #  ---x                            DX
;         |     #     |             x-------------------------------x
;         |    #      |             |                               |
;         |    #      |             |                                 (X1,Y1)
;         |   #       |             |                               #  ----x
;         |   #       |             |                           ####       |
;         |  #     DY |             |                       ####           |
;         |  #        |             |                   ####               |
;         | #         |             |               ####                DY |
;         | #         |             |           ####                       |
;         |#          |             |       ####                           |
;          #          |                 ####                               |
; (X0,Y0) #  -------- x             ####  ---------------------------------x
;                                   (X0,Y0)
;        Major Axis: Y                              Major Axis: X
;        YM  = 1                                    YM  = 0
;        SUM = DX (#Steps)                          SUM = DY (#Steps)
;        IND = $FF - SUM
;        
;
;-------------------------------------------------------------------------------
sub_adf1:
	jsr     get_tek_vects
	lda     IS_16K     			; Memory constrained?
	sta     COMPR     			; If so, only 1 pass as full-screen.
	bne     :+				; 
	jsr     :+	   			; Else two passes. Once for full
	dec     COMPR     			; ...screen and again for zoomed.
:	bit     COMPR     			; 
	bvs     :+				; Full screen? -->

;-------------------------------------------------------------------------------
; (X0,Y0) = (CURSOR_X_OLD, CURSOR_Y_OLD)
; (X1,Y1) = (CURSOR_X, CURSOR_Y)
;-------------------------------------------------------------------------------

;** Zoomed display *************************************************************
	lda     CURSOR2_X_OLD  			;
	ldx     CURSOR2_X_OLD+1 		;

	ldy     CURSOR2_X     			; 
	sty     X1LO     			; X1LO = CURSOR2_X
	sty     CURSOR2_X_OLD  			;

	ldy     CURSOR2_X+1
	sty     CURSOR2_X_OLD+1  		;
	bvc     :++				; Zoomed display? -->

;** Full screen display ********************************************************
:	lda     CURSOR1_X_OLD  			;
	ldx     CURSOR1_X_OLD+1 		; 

	ldy     CURSOR1_X     			; 
	sty     X1LO     			; X1LO = CURSOR2_X
	sty     CURSOR1_X_OLD  			; 

	ldy     CURSOR1_X+1    			; 
	sty     CURSOR1_X_OLD+1 		; 

;** Both Full screen and zoomed displays ***************************************
:	sta     X0LO     			; X0LO = CURSOR{1,2}_X_OLD
	stx     X0HI     			; X0HI = CURSOR{1,2}_X_OLD+1
	sty     X1HI     			; X1HI = CURSOR{1,2}_X+1
	bvs     :+				; Full screen? -->

;** Zoomed display *************************************************************
	lda     CURSOR2_Y_OLD  			; 
	ldx     CURSOR2_Y_OLD+1 		; 
	bvc     :++				; Zoomed display? -->

;** Full screen display ********************************************************
:	lda     CURSOR1_Y_OLD  			; 
	ldx     #$00    			; Y0HI < 192 on full screen so MSB = 0

;** Both Full screen and zoomed displays ***************************************
:	sta     Y0LO     			; Y0LO = CURSOR{1,2}_Y_OLD
	stx     Y0HI     			; Y0HI = 0 or CURSOR2_Y_OLD+1  
	sec             			; 
	bvc     :+				; Zoomed display? -->

;** Full display: Invert Y (bottom is 0) ***************************************
	lda     #191    			; Scan lines in full screen
	sbc     CURSOR1_Y			; AE3C E5 A6                    ..
	sta     Y1LO    			; Y1LO = 191 - CURSOR1_Y
	sta     CURSOR1_Y_OLD  			; 
	lda     #$00    			; Y1HI always 0 (192 < 256)
	beq     :++				; -->

;** Zoomed display: Invert Y (bottom is 0) *************************************
:	lda     #(<383)    			; Scan lines in zoomed display (lo)
	sbc     CURSOR2_Y			; 
	sta     Y1LO     			; Y1LO = 383 - CURSOR2_Y
	sta     CURSOR2_Y_OLD  			; 

	lda     #(>383)    			; Scan lines in zoomed display (hi)
	sbc     CURSOR2_Y+1			; 
	sta     CURSOR2_Y_OLD+1 		; AE52 85 A3                    ..

;** Both Full screen and zoomed displays ***************************************
:	sta     Y1HI     			; Y1HI = 0 or 383 - CURSOR2_Y+1


	lda     $DA     			; AE56 A5 DA                    ..
	bne     :+				; AE58 D0 03                    ..
	jmp     LAF94   			; If compressed then set DA = 0, RTS

;-------------------------------------------------------------------------------
; Calculate delta X
;-------------------------------------------------------------------------------
:	ldy     #$00    			; Y = $00
	lda     X1HI     			; 
	cmp     X0HI     			; X1HI - X0HI
	bcc     :+				; X1HI < X0HI? -->
	bne     :++				; X1HI > X0HI? -->

	lda     X1LO     			; Here if X1HI == X0HI  
	cmp     X0LO     			; X1LO - X0LO
	bcs     :++				; X1LO >= X0LO? -->

;** Calculate delta X when X1LO < X0LO or X1HI <= X0HI *************************
:	sec             			; 
	lda     X0LO     			; 
	sbc     X1LO    			; 
	sta     XDLO     			; Delta X (LO) = X0LO - X1LO

	lda     X0HI     			; 
	sbc     X1HI     			; A = X0HI - X1HI
	dey             			; Y = $FF
	bne     :++				; -->

;** Calculate delta X when X1LO >= X0LO or X1HI > X0HI *************************
:	lda     X1LO     			; 
	sbc     X0LO     			; 
	sta     XDLO     			; Delta X (LO) = X1LO - X0LO

	lda     X1HI     			; 
	sbc     X0HI     			; A = X1HI - X0HI

:	sty     INVX     			; $00->(X0 <= X1), $FF->(X0 > X1)
	sta     XDHI     			; Delta X (HI) = A

;-------------------------------------------------------------------------------
; Calculate delta Y
;-------------------------------------------------------------------------------
	ldy     #$00    			; AE89 A0 00                    ..
	lda     Y1HI     			; 
	cmp     Y0HI     			; Y1HI - Y0HI
	bcc     :+				; Y1HI < Y0HI? -->
	bne     :++				; Y1HI > Y0HI? -->

;** Here if Y1HI = Y0HI ********************************************************
	lda     Y1LO     			; AE93 A5 EE                    ..
	cmp     Y0LO     			; Y1LO - Y0LO
	bcs     :++				; Y1LO >= Y0LO? -->

;** Calculate delta Y when Y1LO < Y0LO *****************************************
:	sec             			; AE99 38                       8
	lda     Y0LO     			; 
	sbc     Y1LO     			; 
	sta     YDLO     			; YDLO = Y0LO - Y1LO

	lda     Y0HI     			; 
	sbc     Y1HI     			; A = Y0HI - Y1HI
	dey             			; Y = $FF
	bne     :++				; -->

; Calculate delta Y when Y1LO > Y0LO *******************************************
:	lda     Y1LO     			;
	sbc     Y0LO     			; 
	sta     YDLO     			; YDLO = Y1LO - Y0LO

	lda     Y1HI     			; 
	sbc     Y0HI     			; A = Y1HI - Y0HI

:	sty     INVY     			; $FF->(Y0>Y1) $00->(Y0<Y1)
	sta     YDHI     			; Delta Y (HI) = A

;-------------------------------------------------------------------------------
; Calculate number of steps to store in SUM. Is it Delta X or Delta Y?
;-------------------------------------------------------------------------------
	bit     COMPR     			; FF->zoomed 1->full screen

;** Compare HI byte of Delta X and Delta Y *************************************
	lda     XDHI     			; 
	cmp     YDHI     			; XDHI - YDHI
	bcc     :+				; XDHI < YDHI -->
	bne     @TR2				; XDHI > YDHI -->
						; 
;** Here if XDHI = YDHI. Look to LSB for tie-breaker ***************************
	lda     XDLO     			; decide which is major axis
	cmp     YDLO     			; XDLO - YDLO
	bcs     @TR2				; XDLO >= YDLO? -->

;** Here if XDLO < YDLO ********************************************************
:	lda     #$01    			; Y-axis *is* the major axis
	sta     YM				; ...since YD > XD

;** Delta Y won. Set SUM using YD (number of iterations needed) ****************
	lda     YDLO     			; 
	sta     SUMLO				; 
	lda     YDHI     			;
	sta     SUMHI     			;

;** Normalize coordinates. Swap if necessary ***********************************
	lda     INVY     			; 
	beq     :+				; Already normalized? Yes? -->
	jsr     swap_coords			; Otherwise swap coordinates
:	ldx     INVX     			; 
	beq     @TR3				; AEDA F0 21                    .!

;** TODO This seems backwards?
@TR1:	bvc     :+				; Is zoomed display? -->
	lda     #216    			; DELLO = 216 (Full-screen)
	bne     @DM				; -->
:	lda     #192    			; DELLO = 192 (Zoomed)
	bne     @DM	   			; -->

;** Here if XD >= YD ***********************************************************
@TR2:	lda     #$00    			; Y-axis is *not* the major axis
	sta     YM				; ...since XD >= YD

;** Delta X won. Set SUM using XD (number of steps needed) *********************
	lda     XDLO     			; 
	sta     SUMLO				;
	lda     XDHI     			;
	sta     SUMHI     			;

;** Normalize coordinates. Swap if necessary ***********************************
	lda     INVX     			; 
	beq     :+				; Already normalized? Yes? -->
	jsr     swap_coords			; Otherwise swap coordinates
:	ldx     INVY     			; Set DELLO 
	bne     @TR1				; 

@TR3:	bvc     :+				; is Zoomed display? -->
	lda     #40				; DELLO = 40 AEFF A9 28                    .(
	bne     @DM	   			; -->
:	lda     #64				; DELLO = 64 AF03 A9 40                    .@

;-------------------------------------------------------------------------------
; Save number of steps needed to draw 
;-------------------------------------------------------------------------------
@DM:	stx     DELHI     			; X = either INVX or INVY
	sta     DELLO     			; AF07 85 FA                    ..

	lda     SUMLO				; Convert from "count-down to zero"
	eor     #$FF    			; ...to "count-up to zero"
	sta     INDLO     			; ...and save it.

	lda     SUMHI     			; Convert from "count-down to zero"
	eor     #$FF    			; ...to "count-up to zero"
	sta     INDHI     			; ...and save it.

	lsr     SUMHI     			; 
	ror     SUMLO				; SUM = INT (SUM / 2)

;-------------------------------------------------------------------------------
; Get screen RAM address
;-------------------------------------------------------------------------------
	lda     Y0LO     			; AF19 A5 F2                    ..
	bvc     :+				; Zoomed display? -->

;** Full screen display ********************************************************
	tax             			; 
	ldy     $0400,x 			; Table of scan line addresses (LO)
	lda     $04C0,x 			; Table of scan line addresses (HI)
	bne     :++				; -->

;** Zoomed display *************************************************************
:	and     #$03    			; Y0LO modulus 4
	tax             			; ...for indexing later
	lda     Y0HI    			; AF29 A5 F3                    ..
	lsr     a       			; AF2B 4A                       J
	lda     Y0LO     			; AF2C A5 F2                    ..
	ror     a       			; AF2E 6A                       j
	lsr     a       			; AF2F 4A                       J
	clc             			; AF30 18                       .
	adc     #(>SCREEN_24K)  		; offset # pages from screen RAM
	ldy     PAGE,x				; ...and then scan lines

;-------------------------------------------------------------------------------
; Save screen RAM address where data is to be written
;-------------------------------------------------------------------------------
:	sty     YOUT
	sta     YOUT+1

;-------------------------------------------------------------------------------
; Draw line? TODO
;-------------------------------------------------------------------------------
	lda     X0LO     			; AF3A 
	and     #$07    			; X0LO modulus 8 for index later
	tax             			; Prepare for indexing

	lda     X0HI     			; Divide X0 by 8
	lsr     a       			; Move bit 0 to Carry
	lda     X0LO     			; 
	ror     a       			; Pull bit from Carry
	lsr     a       			; 
	lsr     a       			; 
	tay             			; Y = X0 / 8

BRA1:	jsr     plot				; AF48
	inc     INDLO     			; Increment counter LO
	bne     :+				; Rollover?
	inc     INDHI     			; Yes. Increment counter HI.
	beq     LAF94   			; AF51 F0 41                    .A

:	clc             			; AF53 18                       .
	lda     YM				; Which axis is major axis (X or Y)? 
	bne     LAF9D   			; (1->Y-Axis)? -->

;-------------------------------------------------------------------------------
; Draw routine for X-axis major (iterate horizontally)
;-------------------------------------------------------------------------------
	lda     SUMLO				; check various terminating
	adc     YDLO     			; conditions...
	sta     SUMLO				; SUMLO = SUMLO + YDLO

	lda     SUMHI     			; (this could be rewritten)
	adc     YDHI     			; 
	sta     SUMHI     			; SUMHI = SUMHI + YDHI

	cmp     XDHI     			; SUMHI - XDHI
	bcc     :++				; SUMHI < XDHI? -->
	bne     :+				; SUMHI > XDHI? -->

	lda     SUMLO				; Here if SUMHI == XDHI
	cmp     XDLO     			; SUMLO - XDLO (tie-breaker)
	bcc     :++				; SUMLO < XDLO? --> 

:	lda     SUMLO				;
	sbc     XDLO     			;
	sta     SUMLO				; SUMLO = SUMLO - XDLO

	lda     SUMHI				; 
	sbc     XDHI     			; 
	sta     SUMHI				; SUMHI = SUMHI - XDHI

	clc             			; 
	lda     YOUT				;
	adc     DELLO    			; 
	sta     YOUT				; YOUT = YOUT + DELLO

	lda     YOUT+1				;
	adc     DELHI     			; 
	sta     YOUT+1				; YOUT+1 = YOUT+1 + DELHI

:	inx             			; 
	cpx     #$08    			; X - 8
	bcc     BRA1				; X < 8? -->

	ldx     #$00    			; Here if X >= 8, reset X
	iny             			; ...and increment Y
LAF91:  jmp     BRA1				; -->

; ----------------------------------------------------------------------------
LAF94:  ldx     COMPR     			; Compressed display?
	bne	:+				; yes -->
	rts             			; 
:	dex             			; Make it 0
	stx     $DA     			; TODO AF9A 86 DA                    ..
	rts             			; AF9C 60                       `

;-------------------------------------------------------------------------------
; Draw routine for Y-axis major (iterate vertically)
;-------------------------------------------------------------------------------
LAF9D:  
	lda     SUMLO				; AF9D
	adc     XDLO     			; 
	sta     SUMLO				; SUMLO = SUMLO + XDLO

	lda     SUMHI				; 
	adc     XDHI     			; 
	sta     SUMHI				; SUMHI = SUMHI + XDHI

	cmp     YDHI     			; SUMHI - YDHI
	bcc     :+++				; SUMHI < YDHI? -->
	bne     :+				; SUMHI > YDHI? -->

	lda     SUMLO				; Here if SUMHI == YDHI 
	cmp     YDLO     			; SUMLO - YDLO (tie-breaker)
	bcc     :+++				; SUMLO < YDLO? --> TODO Doublecheck

:	lda     SUMLO				;
	sbc     YDLO     			;
	sta     SUMLO				; SUMLO = SUMLO - YDLO

	lda     SUMHI				; 
	sbc     YDHI     			; 
	sta     SUMHI				; SUMHI = SUMHI - YDHI

	bit     DELHI     			; AFC1 24 FB                    $.
	bvs     :+				; 

	inx             			; AFC5 E8                       .
	cpx     #$08    			; X - 8
	bcc     :++				; X < 8? -->

	ldx     #$00    			; Here if X >= 8, reset X
	iny             			; ...and increment Y
	bne     :++				; Y <> 0? -->

:	dex             			; AFCF CA                       .
	bpl     :+				; AFD0 10 05                    ..

	ldx     #$07    			; AFD2 A2 07                    ..
	dey             			; AFD4 88                       .
	bmi     LAF94   			; AFD5 30 BD                    0.

;** Calculate to next scan line?? TODO *****************************************
:	clc             			; 
	lda     COMPR     			; Is compressed display?
	beq     :+				; 1->Full screen 0->Zoomed -->
	lda     #$28    			; Full screen, 40 byte scan line
	bne     :++				; -->
:	lda     #$40    			; Zoomed display, 64 byte scan line
:	adc     YOUT				; Point to byte immediately below
	sta     YOUT				; 
	bcc     LAF91   			; No carry? --> (BRA1)
	inc     YOUT+1				; Yes carry
	bne     LAF91   			; -->  (BRA1)

;*******************************************************************************
;*                                                                             *
;*                                swap_coords                                  *
;*                                                                             *
;*                       Exchange start and end points                         *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This subroutine exchanges the values between  X0 & X1 and Y0 and Y1
; X0LO <--> X1LO  Y0LO <--> Y1LO
; X0HI <--> X1HI  Y0HI <--> Y1HI
swap_coords:
; ** Iterate through the X/Y LO/HI *********************************************
	ldx     #$03    			; swap start/endpoints
:	ldy     X1LO,x   			; 
	lda     X0LO,x   			; 
	sta     X1LO,x   			; 
	sty     X0LO,x   			; 
	dex             			; 
	bpl     :-	   			; 

; ** Flip all bits in INVX and INVY ********************************************
	txa             			; A = $FF
	eor     INVX     			; Flip all bits in INVX
	sta     INVX     			; ...and save

	txa             			; A = $FF
	eor     INVY     			; Flip all bits in INVY
	sta     INVY     			; ...and save
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                   plot                                      *
;*                                                                             *
;*                          Write byte in screen RAM                           *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
plot:						; B004
	lda     MTAB,x				; Main Deposit Loop
	and     (YOUT),y			; what's on the screen now
	bit     SCREEN_MODE			; which mode are we in?
	bvs	:+				; if $C0 (ERASE) -->
	ora     BTAB,x				; if WRITE, OR it back
:	sta     (YOUT),y			; and update screen memory
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                  sub_b013                                   *
;*                                                                             *
;*                           deferred VBI handler                              *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; This subroutine executes during the Vertical Blank. It processes the inputs 
; from the joystick trigger and direction switches and from the SELECT console 
; key. 
;
; The joystick direction switches provide three modes of input depending on 
; the current UI_MODE:
; 1. When current input mode is joystick-mapped function keys, translate four 
;    stick directions to eight PLATO keys: NEXT(1), BACK(1), LAB(1), DATA(1).
; 2. When the PLATO terminal touch screen is being simulated, change the 
;    location of an on-screen cursor.
; 3. When the current display mode is "zoomed", pan the view port.
; 
; Similarly, the joystick trigger switch has three contexts for input:
; 1. When current input mode is joystick-mapped function keys, closing the 
;    trigger simulates the SHIFT key being pressed when combined with a
;    direction.
; 2. When the PLATO terminal touch screen is simulated, closing the trigger
;    simulates the screen being pressed.
; 3. If the current display mode is "zoomed", closing the trigger switch
;    changes the display mode to "full-screen". If the current display mode
;    is "full-screen" (and not in touch screen nor joytick-mapped function key
;    modes) closing the trigger switch changes the current display mode to 
;    "zoomed".
;
; The polling of the joystick trigger is restricted to once every 30 calls of 
; this routine. On a 60 Hz NTSC system, this equates to two times per second.
; Presumably this ensures the trigger-based event has had time to complete 
; before the next event can be entered. JSTICK_TR_DLY ($C6) is used to enforce 
; the restriction. Whenever a new trigger event is initiated, JSTICK_TR_DLY
; is set to 30 and is decremented with each vertical blank.
; 
; The SELECT console key is used to alter color preferences. The SELECT key
; provides three color change modes:
; 1. Background and border hue (color)
; 2. Background and border luminance (brightness)
; 3. Text luminance (text brightness)
; 
; Which mode is active is determined earlier from the user by pressing the 
; OPTION + {'c','b','t'}. The initial mode is OPTION + 'c'.
;
; The polling of the SELECT console key is restricted to once every 16 calls
; of this routine (or ~0.27 secs) . This is accomplished by examining the 
; least significant bits in register RTCLOK+2 which increments with each 
; vertical blank.

sub_b013:
	sec             			; 
	lda     UI_MODE				; 
	sbc     #$02    			; using joystick-mapped function keys?
	bne     :+				; no, skip ahead.

;** In joystick-mapped mode. Skip polling if a delay is active *****************
	ldx     JSTICK_TR_DLY   			; is delay active?
	bne     :++				; yes, skip polling

;** Poll joystick trigger ******************************************************
:	lda     STRIG0				; is joystick trigger pressed?
	bne     LB02D   			; no, skip ahead.

;** Trigger pressed and a delay is active, skip joystick direction logic *******
	ldx     JSTICK_TR_DLY   			; 
	bne     LB045   			; 

;** Trigger pressed and a delay is not active. Initialize a new delay. *********
	ldx     #$1E    			; $1E = 30 (that's 0.5 seconds to run down in 60Hz VBI time)
	stx     JSTICK_TR_DLY   			; Start new delay
:	sta     JSTICK_TR 			; $00->{pressed,joystick mapped mode} $FF->not pressed

;** Poll joystick direction ****************************************************
LB02D:  ldx     STICK0				; Read joystick 0
	lda     tab_stick_x,x 			; Get X-axis unit vector
	sta     JSTICK_X                        ; Save X vector
	lda     tab_stick_y,x 			; Get Y-axis unit vector
	sta     JSTICK_Y			; Save Y vector

;** If joystick is pointing in any direction then call vbi_joystick ************
	ora     JSTICK_X			; Any direction?
	bne     :+				; yes, jump to jsr call.
	sta     JSTICK_DIR    			; no, let JSTICK_DIR = 0
	beq     LB045   			; and skip over jsr call.
:	jsr     vbi_joystick   			; call to stick direction routine.

;** Decrement delay counter if a delay is active *******************************
LB045:  ldx     JSTICK_TR_DLY     		; Don't decrement delay counter
	beq     LB04B   			; if we've reached 0.
	dec     JSTICK_TR_DLY  			; otherwise 

;** Check for SELECT press every 16 VBLANKS (0.27 secs) ************************
LB04B:  lda     RTCLOK+2     			; Get current jiffy
	and     #$0F    			; Skip unless lower nybble...
	bne     LB087   			; ...of clock is 0

;** Was SELECT pressed? Exit if no *********************************************
	lda     CONSOL  			; test if SELECT is pressed
	and     #$03    			; mask irrelevant bits
	cmp     #$01    			; 
	bne     LB087   			; XITBV if no SELECT

	lda     CURRENT_DL			; what is current display mode? ($80->1, $00->2)
	asl     a       			; 
	ldy     COLOR2  			; get current background color 
	bit     CURRENT_SELECT 			; Which color register to change ($00->bgc $80->bgb $C0->fgb)
	bvs     LB08A   			; jump if SELECT changes foreground luminance
	bmi     LB09A   			; jump if SELECT changes background luminance
						; otherwise fall into background color

;** Change background hue *****************************************************
	php             			; stash processor flags
	tya             			; get current background hue + luminance
	clc             			; 
	adc     #$10    			; increment background hue
	and     #$F0    			; clear luminance bits
	sta     off_DD				; stash current background hue
	tya             			; get current background hue + luminance again
	and     #$0F    			; clear hue bits
	ora     off_DD				; merge with new hue and save in $DD
	plp             			; restore processor flags
LB076:  sta     COLOR2  			; save new hue + luminance to...
	sta     COLOR4  			; ...background and border registers
	bcc     LB085   			; skip if current display mode is zoomed
	sta     BG_COLOR_DL1    		; current display is full-screen. save color
	jsr     set_pm_colors			; change missile color, too
	bmi     LB087   			; returns with N flag set to force jump to XITBV
LB085:  sta     BG_COLOR_DL2    		; current display mode is zoomed, save color
LB087:  jmp     XITVBV				; Call OS VBI Deferred Exit and RTI

;** Change forground luminance *************************************************
LB08A:  inc     COLOR1  			; increment foreground luminance
	lda     COLOR1  			; 
	bcc	:+				; Update full-screen display 
	sta     FG_COLOR_DL1    		; color variable...
	bcs     LB087   			; or zoomed display color 
:	sta     FG_COLOR_DL2    		; variable and...
	bcc     LB087   			; jump to XITBV.

;** Change background luminance ************************************************
LB09A:  tya             			; let a = current COLOR2
	and     #$F0    			; Reserve current hue only...
	sta     off_DD				; ...and save to temp variable.
	iny             			; increment luminance.
	tya             			; 
	and     #$0F    			; merge new luminance with...
	ora     off_DD				; ...current hue.
	jmp     LB076   			; Save new hue + luminance and RTI

;*******************************************************************************
;*                                                                             *
;*                               vbi_joystick                                  *
;*                                                                             *
;*          Called during VBI to process inputs from the joystick handle       *
;*                                                                             *
;*******************************************************************************
; X contains very recent poll of STICK0
vbi_joystick:					; B0A8
	ldy     UI_MODE     			; Check current display/input mode.
	beq     LB103   			; if just full-screen mode ($00) then RTS.
	bpl	:+				; continue if full-screen touch screen or joystick-mapped function keys.
	jmp     pan_zoom_window			; 

;** here if full screen or joystick-mapped function keys
:	cpx     JSTICK_DIR     			; Has there been a change in STICK0?
	bne     LB104   			; Yes, jump ahead

;** Stick is being held in one position. Increment repeat delay ****************
;** RTS if C5 == $7F or C5 > $80 or C5 like xxxxxx11 ***************************
	ldx     JSTICK_FN_DLY			; let X = $C5
	cpx     #$7F    			; Is $C5 == 127?
	beq     LB136   			; yes, RTS

	inx             			; increment delay
	stx     JSTICK_FN_DLY   		; Is $C5 > $80?
	bmi     LB136   			; yes, RTS

	txa             			; 
	and     #$03    			; Is $C5 like xxxxxx11?
	bne     LB136   			; yes

;-------------------------------------------------------------------------------
;                               JSTICK_Y Logic
;-------------------------------------------------------------------------------
LB0C5:  lda     UI_MODE     			; Test bit 0 of UI_MODE
	lsr     a       			; Carry set if touch screen is active (not even here if zoomed)

;** In joystick-mapped function key mode, trigger press acts as SHIFT **********
	ldx     JSTICK_TR			; Let X = trigger ($FF->no press, $00->press)
	inx             			; now X = $00->no press, $01->press

;** Get joystick handle direction, continue only if down ***********************
	lda     JSTICK_Y			; Get handle ($FF->up, $00->center, $01->down)
	beq     LB0E8   			; if centered, skip to JSTICK_X logic
	bpl     LB0DE   			; if up, skip to "up" logic

;** JSTICK_Y is down ***********************************************************
	bcs     LB0D8   			; Touch screen? yes, move cross-shaped cursor

;** Here only if joystick-mapped function key mode, use X as SHIFT modifier ****
	lda     LBA43,x 			; Get function key for NEXT or SHIFT-NEXT
	bne     LB0FD   			; Skip ahead, save function key, and RTS

;** Must be touch screen mode, move cross-shaped cursor ************************
LB0D8:  jsr     vbi_move_touch_dn		; Move touch screen cursor down
	jmp     LB0E8   			; Skip to JSTICK_X logic

;** JSTICK_Y is up *************************************************************
LB0DE:  bcs     :+				; Touch screen? yes, move cross-shaped cursor

;** Here only if joystick-mapped function key mode, use X as SHIFT modifier ****
	lda     LBA40,x 			; Get function key from table for BACK or SHIFT-BACK
	bne     LB0FD   			; Always a jump to save function key, RTS

;** Must be touch screen mode, move cross-shaped cursor ************************
:  	jsr     vbi_move_touch_up		; Touch screen active - move cursor up

;-------------------------------------------------------------------------------
;                               JSTICK_X Logic
;-------------------------------------------------------------------------------
LB0E8:  lda     UI_MODE    			; Test bit 0 of UI_MODE
	lsr     a       			; Carry set if touch screen is active (not even here if zoomed)

	lda     JSTICK_X			; Get handle ($FF->left, $00->center, $01->down)
	beq     LB136   			; if centered, RTS
	bpl     LB0F8   			; if right, skip to "right" logic.

;** JSTICK_X is left ***********************************************************
	bcs     LB157   			; Touch screen? yes, move cross-shaped cursor

;** Here only if joystick-mapped function key mode, use X as SHIFT modifier ****
	lda     LBA3D,x 			; Get function key for LAB or SHIPT-LAB
	bne     LB0FD   			; Always a jump to save function key, RTS

;** JSTICK_X is right ***********************************************************
LB0F8:  bcs     LB16E   			; Touch screen? yes, move cross-shaped cursor

;** Here only if joystick-mapped function key mode, use X as SHIFT modifier ****
	lda     LBA3A,x 			; Get function key for DATA or SHIFT-DATA.

LB0FD:  sta     JSTICK_FN    			; Save PLATO function key.
	ldx     #$80    			; Reset joystick-mapped function 
	stx     JSTICK_FN_DLY  			; key delay.
LB103:  rts             			; 

;** Change has occurred in joystick direction since last check
;** If input mode is joystick-mapped function keys, reset repeat delay else $C5 = $E2 TODO
LB104:  stx     JSTICK_DIR     			; X contains STICK0, save it to variable
	ldx     #$80    			; 
	ldy     UI_MODE     			; 
	cpy     #$02    			; using joystick-mapped function keys?
	beq     LB110   			; yes, let JSTICK_FN_DLY = #$80
	ldx     #$E2    			; no, let $C5 = #$E2
LB110:  stx     JSTICK_FN_DLY  			; 
	jmp     LB0C5   			; 

;*******************************************************************************
;*                                                                             *
;*                             vbi_move_touch_dn                               *
;*                                                                             *
;*                      Move touch screen cursor down                          *
;*                                                                             *
;*******************************************************************************
vbi_move_touch_dn:				; B115
	lda     TOUCH_Y 			; Get current touch screen position
	cmp     #$0F    			; Is position already at upper bound?
	bcs     LB136   			; Yes, RTS.
	inc     TOUCH_Y 			; No. Move position down.

;** Move missile graphics for cross-shaped cursor down *************************
	ldy     #$02    			; Initialize loop counter = 2
	ldx     CROSS_Y 			; Let X = current location
	txa             			; 
	sec             			; 
	sbc     #$06    			; Move bitmap down by 6 pixels
	sta     CROSS_Y 			; Save new Y location.

@LOOP:	lda     $0590,x 			; Copy cursor bits from 
	sta     $058A,x 			; old offset to new offset.
	lda     #$00    			; Erase cursor bits
	sta     $0590,x 			; at old offset.
	inx             			; Point to next row
	dey             			; Decrement loop counter
	bpl     @LOOP

LB136:  rts             			; 

;*******************************************************************************
;*                                                                             *
;*                             vbi_move_touch_up                               *
;*                                                                             *
;*                        Move touch screen cursor up                          *
;*                                                                             *
;*******************************************************************************
vbi_move_touch_up:				; B137
	lda     TOUCH_Y 			; Get current touch screen position
	beq     @RTS				; Is position already at lower bound? Yes RTS (0)
	dec     TOUCH_Y 			; No. Move position up.

;** Move missile graphics for cross-shaped cursor up ***************************
	ldy     #$02    			; Initialize loop counter = 2
	ldx     CROSS_Y 			; Let X = current location
	txa             			; 
	clc             			; 
	adc     #$06    			; Move bitmap up by 6 pixels
	sta     CROSS_Y 			; Save new Y location.

@LOOP:	lda     $0590,x 			; Copy cursor bits from
	sta     $0596,x 			; old offset to new offset.
	lda     #$00    			; Erase cursor bits
	sta     $0590,x 			; at old offset.
	inx             			; Point to next row.
	dey             			; Decrement loop counter.
	bpl     @LOOP
@RTS:	rts             			; 

;** Move missile graphics for cross-shaped cursor left *************************
LB157:  lda     TOUCH_X     			; Is cursor already at left-most
	beq     LB16D   			; position (0)? yes? RTS.
	dec     TOUCH_X				; no, move logical position.

	lda     CROSS_X 			; increment physical location
	sec             			; of missile graphic 
	sbc     #$0A    			; by 10 pixels.

;** Update missle registers and return ****************************************
LB162:  sta     CROSS_X 			; Save new location of the left
	sta     HPOSM1				; half of cross-shaped cursor.
	tax             			; 
	inx             			; 
	inx             			; Save new location for the right
	stx     HPOSM0				; half of the cross-shaped cursor.
LB16D:  rts             			; 

;** Move missile graphics for cross-shaped cursor right *************************
LB16E:  lda     TOUCH_X     			; is cursor already at right-most
	cmp     #$0F    			; position (16)?
	beq     LB16D   			; yes? RTS.
	inc     TOUCH_X     			; no, move logical position.

	lda     CROSS_X 			; increment physical location
	clc             			; of missile graphic 
	adc     #$0A    			; by 10 pixels
	bne     LB162   			; Update missile registers and RTS.

;*******************************************************************************
;*                                                                             *
;*                             pan_zoomed_window                               *
;*                                                                             *
;*     Adjust pointers for display list #2 using JSTICK_X and Y as inputs.     *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; Display list #2 describes a set of 40 byte scan lines within a larger 64 byte 
; wide frame buffer. 
;
; If the joystick is moved left or right, the LSB to the start of the zoomed 
; display is altered by 1 byte (1 byte = 8 pixels). 
;
; If the joystick is moved up or down, then the MSB to the start of the zoomed
; display is altered by 1 page (256 bytes = 4 scan lines).
;
 
pan_zoom_window:				; B17D

;** Process x-axis changes. Ignore if stick centered or window at limits. ******
	lda     JSTICK_X			; $FF->left, $00->center, $01->right
	beq     :+				; Skip ahead if centered

;** Test if window is at x-axis limits (bcs seems to handle both limits) ********
	clc             			; 
	lda     DL2_WIND			; 
	adc     JSTICK_X			; Let A = DL2_WIND + JSTICK_X.
	cmp     #$19    			; $xx18	- right side of window is at limit.
	bcs     :+				; at limits? yes? skip to Y logic.

;** Here only if zoom window's x coordinate is at a new location. **************
	sta     DL2_WIND			; A change to DL2_WIND = panning 8 pixels
	sta     DL2_TEMP			; Resync for display list work later.

;** Process y-axis changes. Ignore if stick is centered or window at limits. ***
:	lda     DL2_WIND+1			; 
	sta     DL2_TEMP+1			; Resync for display list work later.

	lda     JSTICK_Y			; $FF->up, $00->center, $01->right
	beq     create_DL2_body   		; centered? yes? ignore Y and update DL #2.

	clc             			; Let A = DL2_WIND(hi) + JSTICK_Y.
	lda     DL2_WIND+1 			; Note: changing ZOOM by $0100 moves
	adc     JSTICK_Y			; the zoom window 4 scan lines up or down.
	cmp     #$40    			; $4000 is the upper limit of the frame buffer
	bcc     create_DL2_body   		; at limit? yes? ignore and update DL.

	ldx     JSTICK_Y			; 
	bmi     :+				; 
:	cmp     #$71    			; $7000 - bottom of window is at limit.
	bcs     create_DL2_body   		; at limit? yes? ignore and update DL.

;** Here only if zoom window's y coordinate is at a new location. **************
	sta     DL2_WIND+1 			; Save new pointers
	sta     DL2_TEMP+1			; and fall into create_DL2_body.

;*******************************************************************************
;*                                                                             *
;*                              create_DL2_body                                *
;*                                                                             *
;*           Create body of display list 2 used for zoomed display             *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; This subroutine derives the ANTIC instructions that comprise the body of 
; display list #2. The native resolution of a PLATO terminal is 512x512 
; pixels. THE LEARNING PHONE scrunches this down to 512x384 and stores this 
; into a 24K frame buffer at addresses $4000..$9FFF. But the Atari's video 
; hardware maximum resolution is 320x192. The compromise is to display a 
; 320x192 window into the 24K frame buffer that can be panned using the 
; joystick.  This is the job of DL #2.
;
; DL #2 describes (192) 40-byte scan lines. 3 bytes are required for each scan 
; line. 
;
; byte 1: $4F - ANTIC mode F + $40 (expect 2-byte address to follow)
; byte 2: LSB to address of 40-byte scan line start
; byte 3: MSB to address of 40-byte scan line start
;
; By altering the addresses to the start of each scan line, the window can pan
; inside the 24K frame buffer. The scan line addresses will alway be 64 bytes 
; apart in order to maintain a coherent view into the frame buffer.
;
; Conveniently, altering the LSB of the start of the scan line by 1 pans left or 
; right by 8 pixels or 1 character. Altering the MSB of the start of the start 
; of the scan line by 1 pans up or down by 4 scan lines.
;
; In the example below, a window into the 24K frame buffer begins 96 pixels over
; and 4 rows down from the top left corner of the PLATO display. The body of 
; display list #2 would be:
;
; $4F $4B $41, $4F $8B $41, $4F $CB $41, ... , $4F $CB $70
;
;                      2 4 K   ( 5 1 2 x 3 8 4 )   F R A M E B U F F E R
;      
;               |<------------------------ 64 bytes -------------------------->|
;  ---    4000: ................................................................
;   ^     4040: ................................................................
;   |     4080: ................................................................
;   |     40C0: ................................................................
;   |     4100: ............xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx............
;         4140: ............x <- $414B   <-- 40 bytes -->      ^   x............
;   3     4180: ............x <- $418B   <-- 40 bytes -->      |   x............
;   8     41C0: ............x <- $418B   <-- 40 bytes -->      |   x............
;   4     4200: ............x <- $41CB   <-- 40 bytes -->          x............
;         4240: ............x                                  1   x............
;   r     4280: ............x        D L  # 2   W I N D O W    9   x............
;   o     42C0: ............x                                  2   x............
;   w     4300: ............x                                      x............
;   s     4340: ............x                                  |   x............
;                                                              |         
;   |     70C0: ............x <- $70CB   <-- 40 bytes -->      v   x............
;   |     7100: ............xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx............
;   |     7100: ................................................................
;   |     ..
;   v     9F80: ................................................................
;  ---    9FC0: ................................................................
;       
create_DL2_body:				; B1AB

	lda     #<$10CD    			; 
	sta     off_DD				; Create pointer to the start
	lda     #>$10CD    			; of the body of display list #2
	sta     off_DD+1			;

	ldx     #$C0    			; init counter for 192 scan lines

;** Write 3 bytes to DL2: $4F, LSB, MSB ***************************************
@LOOP:  ldy     #$00    			; 

	lda     #$4F    			; ANTIC mode F + addr to scan line
	sta     (off_DD),y			; Write ANTIC instr to DL2

	iny             			; 
	lda     DL2_TEMP			; Get LSB to start of scan line
	sta     (off_DD),y			; Write LSB to DL2

	iny             			; 
	lda     DL2_TEMP+1			; Get MSB to start of scan line
	sta     (off_DD),y			; Write MSB to DL2

	add16i8	DL2_TEMP, $40			; Next scan line is 64 bytes away

;** Advance pointer to DL2 by 3 bytes for next $4F, LSB, MSB *******************
	add16i8	off_DD, $03			; Advance DL2 pointer
	dex             			; decrement counter
	bne     @LOOP   			; loop until x = 0
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                               send_to_plato                                 *
;*                                                                             *
;*         Set the parity bit (1 if odd) and fall through to CIO call.         *
;*                                                                             *
;*******************************************************************************
send_to_plato:					; B1DF
	tay             			; 
	ldx     #$00    			; Count the number of bits
@LOOP:	lsr     a       			; set in A (ex: 01110011 = 5)
	bcc     @SKIP				; 
	inx             			; 
@SKIP:	bne     @LOOP				; 

	txa             			; Let A = # set bits (1s)
	lsr     a       			; Carry set if #1s is odd
	tya             			; Let A = original arg
	bcc     :+				; if #1s even then skip ahead with orig arg
	ora     #$80    			; otherwise set parity bit to orig arg

;*******************************************************************************
;*                                                                             *
;*                               call_cio_putch                                *
;*                                                                             *
;*                      Call CIO put character command                         *
;*                                                                             *
;*******************************************************************************
call_cio_putch:					; B1EF
:	ldy     #write_ch1-tab_iocb		; Prepare CIO put char to channel #1
						; Fall through to CIO call

;*******************************************************************************
;*                                                                             *
;*                               call_cio_or_err                               *
;*                                                                             *
;*                  Call CIOV. Halt if Communications Error.                   *
;*                                                                             *
;*******************************************************************************
call_cio_or_err:				; B1F1
	jsr     call_cio			; Call CIOV using Y as arg
	bpl     LB252   			; Success. Jump to nearby RTS
display_comm_error:
	ldy     #$18    			; Set cursor X coord in full-screen mode
	sty     CURSOR2_X     			; 
	ldy     #$12    			; Set string length - 1
	lda     #<ERRM				; Point to string "COMMUNIC..."
	ldx     #>ERRM				;
	jsr     print_string			;
@HALT:  jmp     @HALT   			; Halt and catch fire

;*******************************************************************************
;*                                                                             *
;*                                  call_cio                                   *
;*                                                                             *
;*                  Execute CIO call using IOCB variables                      *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; Populates the IOCB table with device and operation details and calls CIO.
; Similar to a BASIC statement like [XIO cmd, #Channel, Aux1, Aux2, "Rn:"]
;
sub_b206:
call_cio:
	pha
	ldx     tab_iocb,y				; CIO channel number * 16
	lda     tab_iocb+1,y
	sta     ICCOM,x					; CIO command
	lda     tab_iocb+2,y
	sta     ICAX1,x					; CIO aux 1
	lda     tab_iocb+3,y
	sta     ICAX2,x					; CIO aux 2
	lda     tab_iocb+4,y
	sta     ICBA,x					; CIO buffer base address (lo)
	lda     tab_iocb+5,y
	sta     ICBA+1,x				; CIO buffer base address (hi)
	lda     tab_iocb+6,y
	sta     ICBL,x					; CIO buffer size (lo)
	lda     tab_iocb+7,y
	sta     ICBL+1,x				; CIO buffer size (hi)
	pla
	jmp     CIOV					; CIOV executes an RTS


;*******************************************************************************
;*                                                                             *
;*                                  close_ch1                                  *
;*                                                                             *
;*                        Close CIO device on channel #1                       *
;*                                                                             *
;*******************************************************************************
sub_b238:
close_ch1:
	ldx     #$10    			; Set CIO channel #1
						; Fall through to sub_b23a

;*******************************************************************************
;*                                                                             *
;*                                  sub_b23a                                   *
;*                                                                             *
;*                        Close CIO device on channel #x                       *
;*                                                                             *
;*******************************************************************************
sub_b23a:
	lda     #$0C    			
	sta     ICCOM,x				; CIO close channel command
	jmp     CIOV				; CIO will RTS

; ----------------------------------------------------------------------------
;*******************************************************************************
;*                                                                             *
;*                                 test_baud                                   *
;*                                                                             *
;*               User-requested baud change from OPTION + 1 or 3               *
;*                                                                             *
;*******************************************************************************
test_baud:					; B242
;** Send ESC character to PLATO ************************************************
	pha					; Stash parameter character
	lda     #$1B    			; Send ESC code to PLATO
	sta     TSTDAT				; 
	jsr     call_cio_putch			; 

;** Send parameter character to PLATO ******************************************
	pla             			; Retrieve original parameter
	jsr     call_cio_putch			; Send to PLATO
	lda     #$00    			;
	sta     TSTDAT				;
LB252:  rts             			;

;*******************************************************************************
;*                                                                             *
;*                               sub_user_baud                                 *
;*                                                                             *
;*               User-requested baud change from OPTION + 1 or 3               *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; This subroutine is called from the key press combination OPTION + '1' to 
; force 1200 baud. Or OPTION + '3' to force 300 baud.
LB253: 
sub_user_baud:
	jsr     close_ch1
	bmi     display_comm_error
	ldy     #$18    			; B258 A0 18                    ..
	sty     CURSOR2_X     			; B25A 84 9C                    ..
	ldy     #$08    			; B25C A0 08                    ..
	lda     CURRENT_BAUD			; Get baud ($FF=300, $00=1200)
	bne     LB268   			; B260 D0 06                    ..
	lda     #<LB91C				; String "1200 baud"
	ldx     #>LB91C
	bne     LB26C   			; will always branch
LB268:  lda     #<LB913				; "300  baud"
	ldx     #>LB913
LB26C:  jsr     print_string
	jmp     open_modem			; open_modem will RTS

;*******************************************************************************
;*                                                                             *
;*                                 config_mpp                                  *
;*                                                                             *
;*                        Configure for Microbits 300                          *
;*                                                                             *
;*******************************************************************************
sub_b272:
config_mpp:
	jsr     close_ch1			; 
	jsr     sub_register_mpp		; Register Microbits 300 in HATABS
	ldy     #open_r-tab_iocb		; Open "R:" on channel #1
	jsr     call_cio_or_err			; 

;**(n) Set flag that MPP is assumed ********************************************
	ldy     #$01    			; 
	sty     IS_MPP				; Let IS_MPP = 1

;**(n) Print "Microbits 300" message *******************************************
	ldy     #$10    			; String length - 1
	lda     #<LB925				; 'Microbits 300'
	ldx     #>LB925				;
	jmp     print_string			; print_string will RTS

;*******************************************************************************
;*                                                                             *
;*                               print_screen                                  *
;*                                                                             *
;*                      Print whatever's on the screen.	                       *
;*                                                                             *
;*******************************************************************************
print_screen:					; B28A
	ldx     IS_MPP				; which comm device: 1->MPP 0->Modem
	dex             			; 
	beq     :+				; is modem a Microbits 300?
	jsr     close_ch1			; no, close channel #1.
:	ldy     #open_p-tab_iocb		; Open "P:" on channel #3
	jsr     call_cio			; 
	bmi     LB2C0   			; if cio error, goto LB2C0

	lda     #$20    			; Initialize outer loop = 32
	sta     TMP	 			; 

	lda     #<$1800    			; Initialize zero-page pointers
	sta     off_FA				;
	lda     #>$1800    			;
	sta     off_FA+1			;

;**(n) TODO Do something 32 times **********************************************
:	jsr     sub_b2c6   			; B2A5 20 C6 B2                 ..
	dec     TMP	 			; B2A8 C6 D9                    ..
	bne     :-

LB2AC:  ldx     #$30    			; Set CIO Channel #3 (Printer)
	jsr     sub_b23a			; Call CIO close channel
	ldx     IS_MPP
	dex             			; B2B3 CA                       .
	beq     LB2F9   			; Jump to nearby RTS
	bpl     :+
	jmp     LB71C   			; B2B8 4C 1C B7                 L..

; ----------------------------------------------------------------------------
:	ldy     #open_t-tab_iocb		; Atari Modem
	jmp     call_cio_or_err			; Open "T:" for read/write

; ----------------------------------------------------------------------------
LB2C0:  jsr     play_beep
	jmp     LB2AC   			; B2C3 4C AC B2                 L..

; ----------------------------------------------------------------------------
sub_b2c6:
	ldy     #$3F    			; 63
	lda     #$20    			; 32

:	cmp     (off_FA),y
	bne     :+
	dey             			; B2CE 88                       .
	bpl     :-
:	lda     #$9B    			; B2D1 A9 9B                    ..
	iny             			; B2D3 C8                       .
	beq     :+
	iny             			; B2D6 C8                       .
:	sty     ICBL+$30
	ldx     #$30    			; B2DA A2 30                    .0
LB2DC:  ldy     #$09    			; B2DC A0 09                    ..
	sty     ICCOM+$30
	ldy     off_FA
	sty     ICBA+$30
	ldy     off_FA+1
	sty     ICBA+1+$30
	jsr     CIOV
	lda     #$40    			; B2EE A9 40                    .@
	clc             			; B2F0 18                       .
	adc     off_FA
	sta     off_FA
	bcc     LB2F9
	inc     off_FA+1
LB2F9:	rts             			; B2F9 60                       `

; ----------------------------------------------------------------------------

sub_b2fa:
	tsx             			; B2FA BA                       .
	stx     byte_1344
	sta     byte_1347
	ldx     byte_1346
	bne     :+
	ldx     TSTDAT
	beq     LB353   			; B308 F0 49                    .I
	lda     #$80    			; B30A A9 80                    ..
	sta     byte_1346
	ldy     #$01    			; B30F A0 01                    ..
	rts             			; B311 60                       `

; ----------------------------------------------------------------------------
:	bpl     :+
	lda     byte_1347
	sta     byte_1343
	tax             			; B31A AA                       .
	lda     #$00    			; B31B A9 00                    ..
	sta     byte_1346
	beq     LB325   			; branch always

; ----------------------------------------------------------------------------
:	ldx     byte_1343
LB325:  cpx     #$46    			; B325 E0 46                    .F
	beq     LB339   			; B327 F0 10                    ..
	ldx     #$02    			; B329 A2 02                    ..
	jsr     sub_b422
	ori	byte_133c, $01
	ldy     #$01    			; B336 A0 01                    ..
	rts             			; B338 60                       `

; ----------------------------------------------------------------------------
LB339:  lda     byte_133c   			; B339 AD 3C 13                 .<.
	and     #$F1    			; B33C 29 F1                    ).
	sta     DVSTAT+1
	lda     byte_133d
	and     #$F1    			; B344 29 F1                    ).
	sta     DVSTAT  			; B346 8D EA 02                 ...
	ldy     #$00    			; B349 A0 00                    ..
	sty     DVSTAT+3
	sty     byte_133d
	iny             			; B351 C8                       .
	rts             			; B352 60                       `

; ----------------------------------------------------------------------------
LB353:  lda     byte_1340
	cmp     #$1F    			; B356 C9 1F                    ..
	bcs     LB353   			; B358 B0 F9                    ..
	sei             			; B35A 78                       x
	jsr     sub_b369
	lda     $CB     			; B35E A5 CB                    ..
	bne     :+
	jsr     sub_b545			; Enable serial out and timer IRQs
:	cli             			; B365 58                       X
	ldy     #$01    			; B366 A0 01                    ..
	rts             			; B368 60                       `

; ----------------------------------------------------------------------------
; store character into some sort of buffer
sub_b369:
	ldy     byte_1342   			; some sort of buffer offset
	lda     character                       ; load character  byte_1347
	sta     byte_1310,y 			; store character into some sort of buffer
	jsr     sub_b55c                        ; let buffer offset = (buffer offset + 1) && $1F
	sta     byte_1342   			; 
	inc     OUTBFPT				; increment output buffer pointer
	rts             			; 

; ----------------------------------------------------------------------------

sub_b37c:
	tsx             			; B37C BA                       .
	stx     byte_1344
:	cli             			; B380 58                       X
	sei             			; B381 78                       x
	ldy     BUFLEN  			; B382 AC 3F 13                 .?.
	cpy     INPBFPT  
	beq     :-

;*******************************************************************************
;*                                                                             *
;*                                 sub_b39c                                    *
;*                                                                             *
;*                            RS232 Get Status???                              *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; Get character from input buffer
sub_b38a:  
	lda     INPBUF,y 			; Get byte from buffer
	and     #$7F    			; Strip off the PLATO parity bit?
	sta     character                       ; Store character byte_1347
	iny             			; 
	sty     BUFLEN  			; Increment BUFLEN
	dec     byte_CC                         ;
	cli             			; Enable interrupts
	ldy     #$01    			; Return success
	rts             			;

;*******************************************************************************
;*                                                                             *
;*                                 sub_b39c                                    *
;*                                                                             *
;*                            RS232 Get Status???                              *
;*                                                                             *
;*******************************************************************************

sub_b39c:
	cld             			; B39C D8                       .
	tya             			; B39D 98                       .
	pha             			; B39E 48                       H
	lda     SERIN
	jsr     sub_b3b9
	lda     SKSTAT
	sta     SKREST  			; B3A8 8D 0A D2                 ...
	eor     #$FF    			; B3AB 49 FF                    I.
	and     #$C0    			; B3AD 29 C0                    ).
	ora     byte_133d
	sta     byte_133d
LB3B5:  pla             			; B3B5 68                       h
	tay             			; B3B6 A8                       .
	pla             			; B3B7 68                       h
	rti             			; B3B8 40                       @

; MPP Microbit 300 routine to write to Input Buffer?
sub_b3b9:
	ldy     INPBFPT				; 
	sta     INPBUF,y 			; 
	iny             			; 
	sty     INPBFPT				; Move pointer
	inc     byte_CC				;
	rts             			; 

; ----------------------------------------------------------------------------
sub_b3c6:
	cld             			; B3C6 D8                       .
	tya             			; B3C7 98                       .
	pha             			; B3C8 48                       H
	lda     OUTBFPT
	bne     :+

	lda     #$E7    			; Set interrupt flags
	and     POKMSK				;
	jsr     sub_irqen			; Enable interrupts
	jmp     LB3B5   			; Restore Y and return from interrupt

; ----------------------------------------------------------------------------
:	jsr     sub_b3e7
	sta     SEROUT

:	lda     IRQST				; Wait for VSEROC to be re-enabled
	and     #$08    			;
	beq     :-

	bne     LB3B5   			; Restore Y and return from interrupt

; ----------------------------------------------------------------------------
sub_b3e7:  
	ldy     byte_1341   			; B3E7 AC 41 13                 .A.
	lda     byte_1310,y 			; B3EA B9 10 13                 ...
	pha             			; B3ED 48                       H
	jsr     sub_b55c
	sta     byte_1341   			; B3F1 8D 41 13                 .A.
	dec     byte_1340
	pla             			; B3F7 68                       h
	rts             			; B3F8 60                       `

; ----------------------------------------------------------------------------

sub_b3f9:
	cld             			; B3F9 D8                       .
	tya             			; B3FA 98                       .
	pha             			; B3FB 48                       H
	lda     $CB     			; B3FC A5 CB                    ..
	beq     LB415   			; B3FE F0 15                    ..
	lda     #$00    			; B400 A9 00                    ..
	sta     $CB     			; B402 85 CB                    ..
	beq     LB3B5   			; B404 F0 AF                    ..

sub_b406:
	cld             			; B406 D8                       .
	tya             			; B407 98                       .
	pha             			; B408 48                       H
	lda     byte_133c   			; B409 AD 3C 13                 .<.
	eor     #$80    			; B40C 49 80                    I.
	sta     byte_133c   			; B40E 8D 3C 13                 .<.
	and     #$80    			; B411 29 80                    ).
	bne     LB3B5   			; B413 D0 A0                    ..
LB415:  lda     byte_133c   			; B415 AD 3C 13                 .<.
	and     #$3E    			; B418 29 3E                    )>
	sta     byte_133c   			; B41A 8D 3C 13                 .<.
	jmp     LB3B5   			; B41D 4C B5 B3                 L..

; ----------------------------------------------------------------------------
sub_b420:
	ldx     #$00    			; B420 A2 00                    ..

sub_b422:
	lda     $CB     			; 
	bne     sub_b422			; Wait for $CB to be $00
	jsr     sub_b53a

:	lda     IRQST
	and     #$08    			; Wait for VSEROC
	bne     :-

	lda     #$35    			; 
	sta     PBCTL				; 
	sta     $CB     			; Let $CB = $35

	sei             			; Inhibit IRQs
	jsr     sub_b369			; Store character in output buffer
	cli             			; Enable IRQs
	jsr     sub_b53a

sub_b43f:
	ldy     LB47A,x 			; B43F BC 7A B4                 .z.
	ldx     #$00    			; B442 A2 00                    ..
	jsr     sub_b51f
LB447:  lda     $CB     			; B447 A5 CB                    ..
	beq     LB46B   			; B449 F0 20                    . 
	lda     byte_1345
	bne     LB447   			; B44E D0 F7                    ..
	sta     byte_1346
	sta     $CB     			; B453 85 CB                    ..
	lda     #$3D    			; B455 A9 3D                    .=
	sta     PBCTL
	lda     byte_133a
	and     #$10    			; B45D 29 10                    ).
	beq     LB464   			; B45F F0 03                    ..
	sec             			; B461 38                       8
	bcs     LB471   			; B462 B0 0D                    ..
LB464:  ldx     byte_1344
	txs             			; B467 9A                       .
	ldy     #$8B    			; B468 A0 8B                    ..
	rts             			; B46A 60                       `

; ----------------------------------------------------------------------------
LB46B:  lda     #$3D    			; B46B A9 3D                    .=
	sta     PBCTL
	clc             			; B470 18                       .
LB471:  lda     byte_133a
	and     #$EF    			; B474 29 EF                    ).
	sta     byte_133a
	rts             			; B479 60                       `

; ----------------------------------------------------------------------------

LB47A:  .byte   <$0008     			; B47A 08                       .
	.byte   <$003C     			; B47B 3C                       <
	.byte   <$00B4     			; B47C B4                       .

;*******************************************************************************
;*                                                                             *
;*                                  sub_b47d                                   *
;*                                                                             *
;*                        Called during cart_init #1 ????                      *
;*                                                                             *
;*******************************************************************************

sub_b47d:
	sei             			; disable interrupts
	jsr     sub_b4a5                        ; Initialize POKEY

; (n) Clear 8 bytes ************************************************************
	ldy     #$07    			; 
	lda     #$00    			;
:	sta     byte_133c,y                     ; 
	dey             			;
	bpl     :-                              ; End loop after 8 iterations

; (n) Clear ********************************************************************
	sta     TSTDAT                          ; Let TSTDAT    = 0
	sta     byte_1346                       ; Let byte_1346 = 0

; (n) Set serial interrupt flags ***********************************************
	lda     #$C7    			; Disable serial input-data-ready,... 
	and     POKMSK                          ; ...out-transmission-finished interrupts. 
	ora     #$20    			; Enable serial output-data-required interrupt.
	jsr     sub_irqen                       ; Register new interrupt flags.

	cli             			; Enable interrupts
	rts             			; 

; -----------------------------------------------------------------------------

; VSERIN vectors
LB49B:
	.addr	sub_b39c
	.addr	sub_b3c6
	.addr	sub_b3c6

; VPRCED vectors
LB4A1:
	.addr	sub_b3f9
	.addr	sub_b406

;*******************************************************************************
;*                                                                             *
;*                                 sub_b4a5                                    *
;*                                                                             *
;*                              Initialize POKEY                               *
;*                                                                             *
;*******************************************************************************

sub_b4a5:

;**(n) Turn off bits 3-7 in SKCTL (and its shadow SSKCTL) **********************
	lda     #$07    			; Disable bits 3-7 on serial port control
	and     SSKCTL  			; 
	ora     #$70    			; 
	sta     SSKCTL  			; 
	sta     SKCTL                           ;
	sta     SKREST  			; 

	ldi	AUDCTL, $78			; Configure POKEY audio channels

;**(n) Initialize audio tones **************************************************
	ldx     #$07    			; 
	lda     #$A0    			; Set AUDF[1-4] and AUDC[1-4]
:	sta     AUDF1,x 			; for every 160 input pulses 
	dex             			; emit 1 output pulse
	bpl     :-      			; End loop after 8 iterations

	lda     #$0B    			; Set AUDF2 and AUDF4
	sta     AUDF2   			; For every 11 input pulses
	sta     AUDF4   			; emit 1 output pulse

;** (n) Install 3 new Serial Data-Ready Input vector addresses *****************
	ldx     #$05    			; 
:	lda     VSERIN,x 			; Save current vector address
	sta     byte_1330,x 			; to RAM
	lda     LB49B,x 			; Load new vector address
	sta     VSERIN,x 			; from cartridge ROM
	dex             			; 
	bpl     :-      			; End loop after 6 iterations

;** (n) Install 2 new Serial Proceed-Line vector addresses *********************
	ldx     #$03    			; 
:	lda     VPRCED,x 			; Save current vector address
	sta     $1336,x 			; to RAM
	lda     LB4A1,x 			; Load new vector address
	sta     VPRCED,x 			; from cartridge ROM
	dex             			; 
	bpl     :-      			; End loop after 4 iterations

;** (n) Enable Peripheral A interrupt ******************************************
	ori	PACTL, $01
	rts             			; 

; ----------------------------------------------------------------------------
sub_b4f7:
	sei             			; Inhibit IRQs

	ldy     #$05    			; 
:	lda     byte_1330,y 			; Install new vectors for ..
	sta     VSERIN,y 			; VSERIN, VSEROR, VSEROC IRQs
	dey             			; 
	bpl     :-      			; End loop

	ldy     #$03    			; B503 A0 03                    ..
:	lda     $1336,y 			; B505 B9 36 13                 .6.
	sta     $0202,y 			; B508 99 02 02                 ...
	dey             			; B50B 88                       .
	bpl     :-				; B50C 10 F7                    ..

	lda     PACTL
	and     #$FE    			; B511 29 FE                    ).
	sta     PACTL
	lda     #$C7    			; Disable VSERIN, VSEROR...
	and     POKMSK				; ...VSEROC IRQs
	jsr     sub_irqen			; Update the IRQ system
	cli             			; Enable IRQs
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                 sub_b51f                                    *
;*                                                                             *
;*                        Configure System Timer 1 IRQ	                       *
;*                                                                             *
;*******************************************************************************

sub_b51f:
	lda     #<sub_b534			; Point to code that runs on system timer IRQ
	sta     CDTMA1
	lda     #>sub_b534
	sta     CDTMA1+1

	sei             			; Inhibit IRQs
	lda     #$01    			; Set byte_1345 flag (timer event clears it)
	sta     byte_1345
	jsr	SETVBV
	cli             			; Enable IRQs

	rts

;*******************************************************************************
;*                                                                             *
;*                                 sub_b534                                    *
;*                                                                             *
;*                          System Timer 1 IRQ code                            *
;*                                                                             *
;*******************************************************************************

sub_b534:
	lda     #$00    			; Clear byte_1345 flag
	sta     byte_1345			
	rts             			 

; ----------------------------------------------------------------------------
sub_b53a:  
	sei             			; Inhibit IRQs
	jsr     sub_b545			; Enable Serial out and timer IRQs
	cli             			; Enable IRQs

:	lda     byte_1340
	bne     :-				; Wait for byte_1340 to be $00
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                  sub_b545                                   *
;*                                                                             *
;*                    Enable Serial Out and Timer Interrupts                   * 
;*                                                                             *
;*******************************************************************************
sub_b545:
	lda     POKMSK				; Enable IRQs for VSEROR VSEROC...
	ora     #$18    			; ...VTIMR{1,2,4}.
						; Fall through to sub_irqen.

;*******************************************************************************
;*                                                                             *
;*                                  sub_irqen                                  *
;*                                                                             *
;*                              Enable Interrupts                              *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; IRQEN is a write-only register. Thus, we must maintain a current value of that
; register in RAM at address POKMSK. To avoid conflict, IRQs should be inhibited 
; (SEI) before calling sub_irqen and enabled after returning from sub_irqen.
;
sub_irqen:
	sta     POKMSK 			; Save the requested IRQ flags to RAM
	sta     IRQEN  			; and to the hardware register, too.
	rts

;*******************************************************************************
;*                                                                             *
;*                                 set_sys_tm1                                *
;*                                                                             *
;*                       Set system timer 1 IRQ and BV                         *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
set_sys_tm1:					; B54F
	ldx     #>$0003				; Arg for SETVBV??
	ldy     #<$0003   			; Arg for SETVBV??
	jsr     sub_b51f			; Set System Timer 1 IRQ and run SETVBV

:	lda     byte_1345
	bne     :-				; Wait until System Timer 1 IRQ runs
	rts             			; 

; ----------------------------------------------------------------------------
sub_b55c:
	iny             			; increment buffer offset
	tya             			; let a = new buffer offset
	and     #$1F    			; wrap offset if > 31
	rts             			; 

; ----------------------------------------------------------------------------

sub_b561:
	tsx             			; B561 BA                       .
	stx     byte_1344
	lda     ICAX1Z
	sta     byte_133a
	lda     #$00    			; B56A A9 00                    ..
	sta     TSTDAT
	jsr     sub_b47d
	jsr     set_sys_tm1
	lda     #$59    			; 'Y' (echo ?)
	sta     character                       ; byte_1347
	ldx     #$01    			; B579 A2 01                    ..
	jsr     sub_b422
	jmp     LB5A5   			; B57E 4C A5 B5                 L..

; ----------------------------------------------------------------------------

sub_b581:
	tsx             			; B581 BA                       .
	stx     byte_1344
	lda     byte_133a
	beq     LB5A5   			; B588 F0 1B                    ..
	jsr     sub_b53a
	lda     byte_B2
	bne     LB595   			; B58F D0 04                    ..
	lda     #$51    			; B591 A9 51                    .Q
	bne     LB597   			; B593 D0 02                    ..

; ----------------------------------------------------------------------------
LB595:  lda     #$5A    			; 'Z'
LB597:  sta     character                       ; byte_1347
	jsr     sub_b420
	jsr     sub_b4f7
	lda     #$00    			; B5A0 A9 00                    ..
	sta     byte_133a
LB5A5:  ldy     #$01    			; B5A5 A0 01                    ..
	rts             			; B5A7 60                       `

;*******************************************************************************
;*                                                                             *
;*                                  t_handler                                  *
;*                                                                             *
;*                      ?????????????????????????????????                      *
;*                                                                             *
;*******************************************************************************

t_handler:
	.addr	sub_b561-1
	.addr	sub_b581-1
	.addr	sub_b37c-1
	.addr	sub_b2fa-1

;*******************************************************************************
;*                                                                             *
;*                               sub_register_mpp                              *
;*                                                                             *
;*                 Register MPP Microbit 300 modem in IOCB??                   *
;*                                                                             *
;*******************************************************************************
sub_b5b0:
sub_register_mpp:
	lda     #$00    			; B5B0 A9 00                    ..
	sta     PACTL
	ori	PORTA, $50
	lda     #$3C    			; B5BD A9 3C                    .<
	sta     PACTL

;** (n) Find empty slot in HATABS **********************************************
	ldx     #$00    			; Start search at offset 0 of HATABS
	lda     #'R'
	jsr     sub_bf86			; Returns HATABS offset in X
	bne     LB5D5   			; Quit if no slots

;** (n) Add Microbit 300 jump table to HATABS **********************************
	lda     #<handler_mpp			; 
	sta     HATABS+1,x			;

	lda     #>handler_mpp			;
	sta     HATABS+2,x			;

LB5D5:  rts             			; 

; ----------------------------------------------------------------------------
; MPP Microbit 300 Jump Table
; ----------------------------------------------------------------------------
LB5D6:
handler_mpp:
	.addr	JOPEN-1                         ; MPP JOPEN $B667 
	.addr   JCLOSE-1                        ; MPP JCLOSE $B6A4
	.addr	sub_read-1			; Generic get char $B708
	.addr	sub_write-1                     ; Generic put char $B6E8

;*******************************************************************************
;*                                                                             *
;*                                    DRIVER                                   *
;*                                                                             *
;*                 MPP Driver Code similar to MPP Smart Term 4.1               *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; This section closely matches the DRIVER subroutine in MPP's Smart Terminal cart
; available at https://archive.org/details/MPPSmartTerminalv4.1 
; 
sub_b5de:
DRIVER: cld                                     ; Similar to DRIVER in MPP source at A0AC
	tya             			; 
	pha             			; Save Y on stack
	lda     INPBIT  			; 
	bne     GETBIT  			; Middle byte
	lda     #$20    			; 
	and     PIA                             ;
	beq     SENDBIT 			; No start
	lda     #$08    			; Length (8 bits in a byte)
	sta     INPBIT  			; 
	lsr     a       			; # IRQs (A = $04)
	sta     INPINT  			; 
	bne     SENDBIT 			; 
;
; READ A BIT FROM PIA IF IT'S TIME
;
GETBIT: dec     INPINT  			; 
	bne     SENDBIT 			; Not time yet
	lda     ISTOP   			; Any stops
	beq     NOSTOP  			; 
	dec     INPBIT  			; 
	dec     ISTOP   			; 
	beq     SENDBIT 			; 
NOSTOP: lda     #$20    			; 
	and     PIA				;
	beq     ZIPO				; 
	sec             			; 
	bcs     ROTATE   			; 
ZIPO:	clc             			; 
ROTATE: ror     INP				; 
	dec     INPBIT  			; 
	bne     NOBYTE   			; 
	lda     INP         			; 
	eor     #$FF    			; 
	jsr     sub_b3b9			; Store INP to INPBUF
	inc     INPBIT  			;
	inc     ISTOP   			;
NOBYTE: lda     #$03    			;
	sta     INPINT  			;
SENDBIT:					; Similar to SENDBIT found in MPP source A11B
	lda     OUTBIT  			; 
	beq     CHKBUF                          ;
	dec     OUTINT  			;
	bne     LB652                           ;
	dec     OUTBIT  			; 
	beq     CHKBUF                          ;
	clc             			;
	ror     OUTBUF  			;
	bcs     ONEOUT  			;
	lda     #$EF    			;
	and     PIA                             ;
	bcc     ZIPSKIP 			;
LB645:
ONEOUT: lda     #$10    			;
	ora     PIA                             ;
ZIPSKIP:  
	sta     PIA                             ; Start bit
	lda     #$03    			;
	sta     OUTINT  			; 
LB652:	
RETURN: jmp     LB3B5   			; Return RTI
CHKBUF:	lda     OUTBFPT				; Similar to CHKBUF routine found MPP source A146
	beq     RETURN   			; 
	jsr     sub_b3e7			; TODO
	eor     #$FF    			; 
	sta     OUTBUF  			; 
	lda     #$0A    			; 
	sta     OUTBIT  			;
	bne     ONEOUT  			;
; OPEN
;
JOPEN:	lda     #$13    			; Similar to JOPEN found MPP source A913
	sta     SKCTL				;
	sta     SSKCTL  			;
	lda     PIA				;
	and     #$BF    			;
	sta     PIA				;
	lda     #$00    			; 
	sta     OUTBIT  			; Let OUTBIT = 0
	sta     INPBIT  			; Let INPBIT = 0
	sta     ISTOP   			; Let ISTOP  = 0
	sta     AUDCTL				; 
	lda     #BAUD   			; Set BAUD = 300
	sta     AUDF1				; 
	lda     #$A0    			; 
	sta     AUDC1				;
	lda     #<DRIVER			; Register MPP driver with POKEY ...
	sta     VTIMR1				; timer interrupt.
	lda     #>DRIVER			;
	sta     VTIMR1+1			;
	lda     POKMSK				;
	ora     #$01    			; 
	jsr     sub_irqen			; Set interrupt flags
	sta     STIMER	                        ;
	ldy     #$01    			; 
	rts             			;
LB6A6:
JCLOSE: lda     OUTBFPT				; Similar to JCLOSE found in MPP source A1D0
	bne     JCLOSE				; Wait for something to arrive
	lda     OUTBIT  			; 
	bne     JCLOSE  			; 
	lda     #$FE    			; 
	and     POKMSK				;
	jsr     sub_irqen			; Set interrupt flags
	ldy     #$01    			; return code?
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                 sub_b6b8                                    *
;*                                                                             *
;*                                   OPEN                                      *
;*                                                                             *
;*******************************************************************************
sub_b6b8:
;** (1) Initialize variables and return ****************************************
	lda     #$8D    			; 
	sta     byte_133a                       ; Let byte_133a = $8D

	ldy     #$00    			; 
	sty     byte_1342   			; Let $1342	= $00
	sty     byte_133d                       ; Let byte_133d = $00
	iny             			; return code?  = 1
	sty     $CB     			; Let $CB       = $01
	rts             			; 

;*******************************************************************************
;*                                                                             *
;*                                 sub_b6c9                                    *
;*                                                                             *
;*                                  CLOSE                                      *
;*                                                                             *
;*******************************************************************************
sub_b6c9:  
	lda     $CB     			; 
	beq     sub_b6c9                        ; Waiting

;** (n) Restore vector addresses for VSERIN, VSEROR, VSEROC ********************
	ldy     #$05    			; 
	sei             			; Prevent IRQs
:	lda     byte_1330,y 			; Values saved earlier in open_modem
	sta     VSERIN,y 			; are restored to the serial vectors
	dey             			; 
	bpl     :-                              ; End loop after 6 iterations

	cli             			; Enable IRQs
	sty     byte_1346
	iny             			; B6DD C8                       .
	sty     DAUX1   			; B6DE 8C 0A 03                 ...
	sty     byte_133a
	lda     #'W'    			; Let A = Write (verify) command
	jmp     sub_sendsio                     ; Send SIO command frame

;*******************************************************************************
;*                                                                             *
;*                                 sub_write                                   *
;*                                                                             *
;*                      Write character to output buffer.                      *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION

sub_b6e9:
sub_write:
	sta     character                       ; 
	ldx     #$01    			; 
	stx     $21     			; TODO I can't find address $21 being used elsewhere.

:	lda     OUTBFPT                         ; 
	cmp     #$1F    			; 
	bcs     :-                              ; Waiting for something to appear?

	sei             			; Disable interrupts
	jsr     sub_b369                        ; store character into some sort of buffer

	lda     POKMSK                          ; Enable serial output data-required...
	ora     #$18    			; ... and output transmission-finished interrupts
	jsr     sub_irqen			; Enable new interrupt flags

	ldy     #$00    			; 
	sty     $CB     			; Let $CB = 0
	cli             			; Enable interrupts
	iny             			; 
	rts             			; Return success

;*******************************************************************************
;*                                                                             *
;*                                  sub_read                                   *
;*                                                                             *
;*                  High-level read character from input buffer.               *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; TODO This appears to be layer of abstraction for reading a character from 
; the communication device (850, modem, or Microbits 300). So far it looks like
; the different devices will handle populating the input buffer using SERIN 
; (850/modem) or PIA (Microbits 300) interrupts.
; TODO I suspect a timer interrupt breaks out of the "wait" loop.

sub_b709:
sub_read:	

;**(n) Wait for something to appear in the input buffer ************************
	cli             			; Enable IRQ
	sei             			; Disable IRQ
	ldy     BUFLEN  			; 
	cpy     INPBFPT                         ; Wait until IRQ writes to buffer
	beq     sub_read			; 

;**(n) Copy most-recent byte from buffer to "character" ************************
	jsr     sub_b38a			; Using Y as offset, get last char from buffer...
	ldy     #$01    			; ...and store in "character".
	rts             			; Return success

;*******************************************************************************
;*                                                                             *
;*                                open_modem                                   *
;*                                                                             *
;*                           ?????????????????????                             *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; At this point there are 3 possibilites:
; 1) A direct-connect modem was found but user is asking to set it to 1200 baud
;    (by pressing '1' at the connection prompt). If the direct-connect modem 
;    does not support 1200 baud, return with sign flag set.
; 2) A Microbits 300 is connected then return with sign flag set.
; 3) An 850 is connected and will be set to the default 1200 baud and return 
;    with sign flag clear.
open_modem:					; B719
	jsr     sub_setbaud			; Set baud/word/etc and request ACK
LB71C:  ldy     #$00    			; Prepare CIO open R: on channel #1
	jsr     call_cio			; Call CIO
	bpl     :+				; Return if direct connect modem... 
	rts             			; ...could not be set to 1200 baud

;** (n) If here then either an 850 or presumed Microbits is connected **********
:	lda     #$00    			; Let X = 0
	sta     IS_MPP				; Default IS_MPP to modem (0)
	sta     INPBFPT                         ; Let INPBFPT   = 0
	sta     BUFLEN  			; Let BUFLEN    = 0
	sta     byte_1342   			; Let byte_1342 = 0
	sta     byte_1341   			; Let byte_1341 = 0
	sta     DBYT+1 			        ; Set MSB of buffer size to 0

;** (n) Construct SIO command frame for possible 850 ***************************
	lda     #<byte_1330			; 
	sta     DBUF				; 
	lda     #>byte_1330			;
	sta     DBUF+1				;

	lda     byte_133a                       ; Construct SIO command frame
	sta     DAUX1   			; 

	lda     #$09    			; 
	sta     DBYT    			; Tell SIO to receive 9 bytes

	ldy     #$40    			; Prep Y for DSTATS ($40->receive data)
	lda     #$58    			; Prep A for DCOMND ($58->?? ('X'?)

;** (n) Submit SIO command to possible 850 *************************************
	jsr     sub_sendsio                     ; Send SIO command frame
	bpl     :+				; Continue if 850 is present
	rts             			; Return with minus if couldnt talk to 850

;** As far as I can tell, the remainder can only be run if an 850 is connected.

;** (n) 850! Set serial port mode control **************************************
:	sei             			; Inhibit IRQs
	ldi	SKCTL, $73			; Set serial port mode control

;** (n) Set audio control ******************************************************
	lda     $1338   			; B75C AD 38 13                 .8.
	sta     AUDCTL				; Set audio control

;** (n) Copy 8 bytes from $1330-$1337 to AUDF1/C1-AUDF4/C4 *******************
	ldy     #$07    			; B762 A0 07                    ..
@LOOP1:	lda     byte_1330,y 			; B764 B9 30 13                 .0.
	sta     AUDF1,y 			; B767 99 00 D2                 ...
	dey             			; B76A 88                       .
	bpl     @LOOP1      			; B76B 10 F7                    ..

;** (n) Save/replace VSERIN VSEROR VSEROC interrupt vectors ******************
	ldx     #$06    			; 
@LOOP2:	lda     VSERIN-1,x 			; Save currect serial vector...
	sta     byte_1330-1,x 			; ...addresses to RAM
	lda     LB822-2+1,x                       ; Load new vector...
	sta     VSERIN-1,x 			; ...addresses to IRQ registers
	dex             			; 
	bne     @LOOP2     			; End loop

	stx     byte_CC			        ; Let byte_CC = 0
	stx     byte_CD 			; Let byte_CD = 0

	lda     POKMSK                          ; 
	ora     #$20    			; Enable serial data-ready interrupt
	jsr     sub_irqen			; Register new interrupt flags

	ldx     #$01    			;
	stx     byte_1346			; Let byte_1346 = $01

	cli             			; Enable IRQs
	ldy     #$01    			; 
	lda     byte_133a                       ; 
	sta     ICAX1Z				; Let ICAX1Z = byte_133a
	cpy     #$00    			; B796 C0 00                    ..
	rts             			; B798 60                       `

;*******************************************************************************
;*                                                                             *
;*                                  sub_R_status                               *
;*                                                                             *
;*                        Add R to HATABS and run status.                      *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; Add R device to HATABS. Then send SIO status command. 
; From observation in an emulator:
; Returns Y=$8A and sign flag set if no 850 found.
; Returns Y=$01 and sign flag clear if 850 found.

sub_b799:
sub_register_R:

;** (1) Initialize *************************************************************
	lda     #$00    			; Let Y         = 0
	sta     byte_133a       		; Let byte_133a = 0
	sta     DBYT+1  			; Let DBYTHI    = 0
	tax             			; Let X         = 0

;** (2) Find first empty Handler Table slot ************************************
	jsr     sub_hatabs_slot			; Let X = offset to new slot
	beq     :+	   			; If slot was found, create new handler entry
	rts             			; otherwise return

;** (3) Create new handler table record (3 bytes) ******************************
:	lda     #'R'    			; RS232 Device
	sta     byte_1346       		; Save "R" in RAM
	sta     HATABS,x			; Save "R" in the new slot

	lda     #<handler_R 			; LSB of start of handler vector table
	sta     HATABS+1,x      		; Save LSB in the new slot

	lda     #>handler_R 			; MSB of start of handler vector table
	sta     HATABS+2,x      		; Save MSB in the new slot

;** (4) Prepare SIO to load STATUS results into DVSTAT *************************
	lda     #<DVSTAT			; LSB of data buffer address
	sta     DBUF                            ;

	lda     #>DVSTAT    			; MSB of data buffer address
	sta     DBUF+1                          ; By luck, >DVSTAT is 2
	sta     DBYT    			; Tell SIO to load 2 bytes

;** (5) ************************************************************************
	ldy     #$40    			; Prep Y for use by DSTATS ($40->receive data)
	lda     #'S'    			; Prep A for use by DCOMND ($53->STATUS)
	jsr     sub_sendsio			; SIOV returns with Y=($01->850,$8A->No 850)

	lda     character                       ; A = $51 from somewhere earlier
	ora     DVSTAT  			; DSTAT currently ($00,$F0->850, $00,$00->no 850)
	sta     DVSTAT  			; DSTAT become ($51,$F0 or $51,$00)
	cpy     #$00    			; Sign flag set->850
	rts             			; Sign flag clear->850

; ----------------------------------------------------------------------------

sub_b7da:
	lda     byte_1340
	bne     :+
	lda     byte_1346
	sta     $CB     			; B7E2 85 CB                    ..
:	jmp	sub_b3c6

;*******************************************************************************
;*                                                                             *
;*                               sub_setbaud                                   *
;*                                                                             *
;*                             Change baud rate                                *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; Send two command frames to 850 or direct connect modem. First is to change the
; baud rate and a second to request an acknowledgement. Presumably the ACK will
; fail if an unsupported baud rate is requested.

sub_b7e7:
sub_setbaud:

; **(1) Send command frame #1 for setting baud and word size *******************
	lda     #'B'    			; DCOMND for setting baud, parity, stopbits
	bit     CURRENT_BAUD			; 
	bmi     :+				; if CURRENT_BAUD == $FF
	ldx     #$0A    			; then AUX1 = $00 ( 300 baud, 8 bit word)
	bne     LB7F3   			; else AUX1 = $0A (1200 baud, 8 bit word)
:	ldx	#$00    			; 
LB7F3:  jsr     sub_b7fa

; **(2) Send command frame #2 for acknowledgement ******************************
	lda     #'A'    			; DCOMND for requesting an ACK (returns 'C'omplete or 'E'rror)
	ldx     #$F3    			; AUX1 for ????

sub_b7fa:
	stx     DAUX1   			; 
	ldy     #$00    			; AUX2: 1 stop bit, no monitoring of DSR, CTS, CRX
	sty     DAUX2   			; Fall into sub_sendio

;*******************************************************************************
;*                                                                             *
;*                               sub_sendsio                                   *
;*                                                                             *
;*                    Send SIO Command to RS232 Device 1                       *
;*                                                                             *
;*******************************************************************************
sub_b802:
sub_sendsio:
	sta     DCOMND  			; Command code is set in caller

;**(1) Set Device Unit number **************************************************
	ldx     #$01    			; Device 1 (as in R1:)
	stx     DUNIT   			; 
	sty     DSTATS  			; Set the data direction ($40->in, $80->out)

;**(2) Set Device Serial bus ID ************************************************
	ldy     #$50    			; $50 = ID for RS232 port R1:
	sty     DDEVIC  			; 

;**(3) Set Device handler time-out *********************************************
	ldy     #$08    			; 8 seconds time-out
	sty     DTIMLO  			; 

;**(4) Send command frame (DCOMND DAUX1 DAUX2, etc) to SIO bus *****************
	jmp     SIOV    			; SIOV will execute an RTS

;*******************************************************************************
;*                                                                             *
;*                                   LB81A                                     *
;*                                                                             *
;*                             Handler Vector Table?????                       *
;*                                                                             *
;*******************************************************************************
LB81A:
handler_R:
	.addr	sub_b6b8-1      		; OPEN vector???
	.addr	sub_b6c9-1      		; CLOSE vector???
	.addr	sub_read-1      		; Generic get character
	.addr	sub_write-1      		; Generic put character

; the last two vectors and the jump are not included or used

LB822:	.addr	sub_b39c			; GET STATUS vector???
	.addr	sub_b7da			; SPECIAL vector???
	.addr	sub_b7da			; 

;*******************************************************************************
;*                                                                             *
;*                                 play_beep                                   *
;*                                                                             *
;*         Modulates volume bits to generate sound on audio channel 1.         *
;*                                                                             *
;*******************************************************************************
play_beep:					; B828

;** Initialize nested loop counters ********************************************
	ldx     #$00    			; Let X = 0
	ldy     #$04    			; Let Y = 4

;** Modulate X to play a beep **************************************************
@LOOP:	txa             			; Let A = X
	and     #$0F    			; Clear distortion bits for audio
	ora     #$10    			; Set volume-only mode to existing bits
	sta     WSYNC				; Halt CPU until end of current scan line
	sta     AUDC1				; Beep
	inx             			; 
	inx             			; X = X + 2
	sta     WSYNC				; Halt CPU until end of current scan line
	bne     @LOOP				; X Loop 128 times
	dey             			; 
	bne     @LOOP				; Y Loop 4 times

;** Check if program is pirated ***********************************************
	lda     #<(obf_code-1)			; Point to obfuscated code used for...
	ldy     #>(obf_code-1)			; ...copy-protection check
	ldx     #$0C    			; Initialize counter to 12
	jmp     check_if_pirated		; Perform copy-protection check

; ----------------------------------------------------------------------------
	rts             			; Never reached?

;*******************************************************************************
;*                                                                             *
;*                            check_if_pirated                                 *
;*                                                                             *
;*   Copy protection routine that jumps to COLDSV if not running from cart.    *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
;
; This subroutine decrypts 12 bytes of code from ROM at $B863 and copies it to 
; RAM at $3E33. Then jumps to the decrypted code. The code tries to alter $BFFC 
; which is at the tail end of the cartridge's address space. Normally this
; address is read-only. If the program is able to alter the the contents of 
; the address, it is deemed to be an illegal copy because address space is RAM
; and jumps to COLDSV. On a 400/800 this would be the memo pad. On an XL this
; would be the self-diagnostics.
;
; Here is the 12 bytes of code after decryption:
;
; 3E33: CE FC BF          dec $BFFC		; Try to alter a ROM address.
; 3E36: AD FC BF          lda $BFFC		; Is this ROM?
; 3E39: F0 03             beq $3E3E		; Yes? Good. Skip to RTS.
; 3E3B: 4C 77 E4          jmp COLDSV		; No? Reboot.
; 3E3E: 60                rts

check_if_pirated:				; B84B
;** Create pointer to where obfuscated code will be stored *********************
	sta     off_EC				; create pointer in zero page
	sty     off_EC+1
	ldy     #$00    			; initialize pointer index

;** Initialize XOR decryption key **********************************************
	lda     #$55    			; decryption key 01010101
	sec             			; set carry bit. helps with the ROL later.

;** Decrypt instructions at $B863 and save them in RAM ($3E33) *****************
@LOOP:	iny             			; increment pointer index
	rol     a       			; rotate the key with each iteration.
	pha             			; stash key (to be clobbered soon)
	eor     (off_EC),y			; decrypt instruction using XOR
	sta     test_if_rom-1,y			; save decypted instruction to RAM
	pla             			; restore key
	dex             			; decrement counter
	bne     @LOOP				; loop while counter <> 0

;** Run the decrypted code and RTS (or COLDSV) *********************************
	jmp     test_if_rom   			; 

; ----------------------------------------------------------------------------
; Obfuscated code that performs copy-protection check. Decrypted using XOR.
; ----------------------------------------------------------------------------
obf_code:					; B863
	.byte	$65,$AA,$12,$F7,$49,$D5,$25,$A9
	.byte	$19,$DC,$B2,$CD

;*******************************************************************************
;*                                                                             *
;*                                 tab_stick_y                                 *
;*                                                                             *
;*                  joystick direction lookup table (y-axis)                   *
;*                                                                             *
;*******************************************************************************
;*                                                                             *
;*                                   *14*                                      *
;*                                *10* | *6*                                   *
;*                                   \ | /                                     *
;*                              11 -- 15 --  7                                 *
;*                                   / | \                                     *
;*                                 *9* | *5*                                   *
;*                                   *13*                                      *
;* Y AXIS VECTOR                                                               *
;* +1 DOWN {5, 9,13}                                                           *
;* -1 UP   {6,10,14}                                                           *
;*******************************************************************************
LB86F:
tab_stick_y:
	.byte	$00,$00,$00,$00			; - - - -
	.byte	$00,$01,$FF,$00			; - D U -
	.byte	$00,$01,$FF,$00			; - D U -
	.byte	$00,$01,$FF,$00			; - D U -

;*******************************************************************************
;*                                                                             *
;*                                tab_stick_x                                  * 
;*                                                                             *
;*                 joystick direction lookup table (x-axis)                    *
;*                                                                             *
;*******************************************************************************
;*                                                                             *
;*                                    14                                       *
;*                                *10* | *6*                                   *
;*                                   \ | /                                     *
;*                             *11*-- 15 -- *7*                                *
;*                                   / | \                                     *
;*                                 *9* | *5*                                   *
;*                                    13                                       *
;*  X AXIS VECTOR                                                              *
;*  +1 RIGHT {5, 6, 7}                                                         *
;*  -1 LEFT  {9,10,11}                                                         *
;*******************************************************************************
LB87F:	
tab_stick_x:					; B87F
	.byte	$00,$00,$00,$00			; - - - -
	.byte	$00,$01,$01,$01			; - L L L
	.byte	$00,$FF,$FF,$FF			; - R R R
	.byte	$00,$00,$00,$00			; - - - -

LB88F:	.byte	"K:",$9B			; B88F

LB892:	.byte	"R:",$9B			; B892

LB895:	.byte	"T:",$9B			; B895

LB898:	.byte	"P:",$9B			; B898

ERRM:	RString	"COMMUNICATION ERROR"

LB8AE:	RString	"COPYRIGHT 1984 ATARI"

LB8C2:	RString "WELCOME TO THE LEARNING PHONE"

LB8DF:	RString "After the phone has a high pitch tone, PRESS RETURN!"

LB913:	RString "300  baud"

LB91C:	RString "1200 baud"

LB925:	RString "Microbit 300 baud"

PAGE:	.byte	$00,$40,$80,$C0

MTAB:	.byte   $7F,$BF,$DF,$EF
	.byte	$F7,$FB,$FD,$FE

BTAB:	.byte   $80,$40,$20,$10
	.byte	$08,$04,$02,$01
DTAB:	.byte	$E3,$E1,$E0,$E2

LTAB:	.byte	$00,$7F,$3F,$1F,$0F,$07,$03,$01

RTAB:	.byte   $80,$C0,$E0,$F0,$F8,$FC,$FE,$00

CMTAB:	.byte   $07,$83,$C1,$E0
	.byte	$F0,$F8,$FC,$FE

CMRTAB:	.byte	$00,$00,$00,$00
	.byte	$7F,$3F,$1F,$0F

;*******************************************************************************
;*                                                                             *
;*                                 tab_iocb                                    *
;*                                                                             *
;*                     IOCB Device/Operation Lookup Table                      *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; This table contains the parameters for opening/reading/writing to devices
; using the Atari's device handler system.

tab_iocb:
open_r:						; B96E
	.byte   $10				; IOCB Channel #1
	.byte	$03				; ICCOM: open
	.byte	$0D				; ICAX1: (mode) concurrent read/write
	.byte	$00				; 
	.addr	LB892				; "R:" (RS232)
	.word	$0000				; 

open_k:						; B976
	.byte	$20				; IOCB Channel #2
	.byte	$03				; ICCOM: open
	.byte	$04				; ICAX1: (mode) read
	.byte	$00				; 
	.addr	LB88F				; "K:"
	.word	$0000				; 

read_k:						; B97E
	.byte	$20				; IOCB Channel #2
	.byte	$07				; ICCOM: get character
	.byte	$04				; ICAX1: (mode) read
	.byte	$00				;
	.addr	$0000				;
	.word	$0000				;

write_ch1:					; B986
	.byte	$10				; IOCB Channel #1
	.byte	$0B				; ICCOM: put character
	.byte	$0D				; ICAX1: (mode) concurrent read/write
	.byte	$00				;
	.addr	$0000				;
	.word	$0000				;

read_ch1:					; B98E
	.byte	$10				; IOCB Channel #1
	.byte	$07				; ICCOM: get character
	.byte	$0D				; ICAX1: (mode) concurrent read/write
	.byte	$00				; 
	.addr	$0000				; 
	.word	$0000				; 

open_t:						; B996
	.byte	$10				; IOCB Channel #1
	.byte	$03				; ICCOM: open
	.byte	$0D				; ICAX1: (mode) concurrent read/write
	.byte	$00				; 
	.addr	LB895				; "T:" (Microbit???? or Atari????)
	.word	$0000				;

open_p:						; B99E
	.byte	$30				; IOCB Channel #3
	.byte	$03				; ICCOM: open
	.byte	$08				; ICAX1: (mode) write
	.byte	$00				; ICAX2:
	.addr	LB898				; "P:" (Printer)
	.word	$0040

;*******************************************************************************
;*                                                                             *
;*                              tab_ch_mem_DL1                                 *
;*                              tab_ch_mem_DL2                                 *
;*                                                                             *
;*                            Character memories                               *
;*                                                                             *
;*******************************************************************************

; DESCRIPTION
; The next 2 tables points to the bitmaps for 4 character sets. 
;
; tab_ch_mem_DL1: 5x6 font for full screen display
; tab_ch_mem_DL2: 8x8 font for zoomed display
;
;-------------------------------------------------------------------------------
; (excerpt from s0ascers 3.2.3.1.2.4.1  Character memories)
;-------------------------------------------------------------------------------
; There are four character memories, known as M0, M1, M2 and M3. There are 
; provisions built into the protocol to accommodate up to eight character 
; memories, but only these four are currently in use.  M0 and M1 are constant.
; M2 and M3 are the programmable font.
;
; M0 contains the standard 96-character ASCII set.
; 
; M1 contains the PLATO extended character set.  These are the special 
; characters that PLATO uses which are not available in the standard ASCII set.
; The characters are illustrated in appendix A.
;
; M2 is the first half of the programmable font.  Character slots zero through 
; 63 are placed in this character memory.  The character set is loaded in the 
; load memory mode (see section 3.2.3.1.2.3).
;
; M3 is the second half of the programmable font.  Character slots 64 through 
; 127 are placed in this character memory.  
;
; There are eight commands to select the current character memory.  The resident
; must start out with M0 as the default. When the PLATO host requires characters
; from the other character memories it will send down the appropriate command.  
; The sequences for the commands are:
;
;     ESC B (1B 42): select M0
;     ESC C (1B 43): select M1
;     ESC D (1B 44): select M2
;     ESC E (1B 45): select M3
; 
; When a data character is received in text mode it is used as an index into 
; the current character memory, and this bit map is put onto the screen in the 
; current screen mode at the current (X,Y) location.
;-------------------------------------------------------------------------------

;** 8x8 font for zoomed display ************************************************
tab_ch_mem_DL2:					; B9A6
	.byte	>$0600
	.byte	>$0900
	.byte	>$0000
	.byte	>ch_mem_m1_DL2			; Extended PLATO font LO

	.byte	<$0600
	.byte	<$0900
	.byte	<$0000
	.byte	<ch_mem_m1_DL2			; Extended PLATO font HI

;** 5x6 font for full screen display *******************************************
tab_ch_mem_DL1:					; B9AE
	.byte	<ch_mem_m2_DL1			; Programmable font LO
	.byte	<ch_mem_m3_DL1			; Programmable font LO
	.byte	<ch_mem_m0_DL1			; Standard ASCII font LO
	.byte	<ch_mem_m1_DL1			; Extended PLATO font LO

	.byte   >ch_mem_m2_DL1			; Programmable font HI
	.byte	>ch_mem_m3_DL1			; Programmable font HI
	.byte	>ch_mem_m0_DL1			; Standard ASCII font HI
	.byte	>ch_mem_m1_DL1			; Extended PLATO font HI

LB9B6:	.byte	$08,$10,$10,$20,$20,$40,$80,$80

LB9BE:	.byte	$00,$00,$00,$01,$01,$01,$02,$02
	.byte	$03,$03,$04,$04,$04,$05,$05,$05

LB9CE:	.byte	$00,$00,$01,$02,$02,$03,$03,$04

LB9D6:  .byte   $03,$02,$03,$03,$02,$03,$02,$03
	.byte	$03,$02,$02,$01,$02,$02,$01,$02
	.byte	$01,$02,$02,$01,$03,$02,$03,$03
	.byte	$02,$03,$02,$03,$03,$02

LB9F4:  .byte   $00,$05,$0A,$0F,$14,$19

LB9FA:  .byte   $00,$00,$01,$01,$01,$01,$01,$02

LBA02:	.byte	$00,$03,$0C,$0F,$30,$33,$3C,$3F
	.byte	$C0,$C3,$CC,$CF,$F0,$F3,$FC,$FF

; ------------------------------------------------------------------------------
;			ATARI TO PLATO KEYMAPPING TABLE #1
;
; The lookup table at $BA12 approximates Appendix D of the s0ascers document. 
;
; The $BA12 table maps Atari [START] key combinations to the unshifted/shifted 
; ASCII codes that are, in turn, mapped to PLATO codes on the PLATO side.
;
; Provided here is the s0ascers table reduced to strictly the mappings found in 
; the $BA12 table. The ASCII CHAR. CODE values on the right side of the s0ascers
; table are the values that correspond to the Atari key code in the $BA12 table.
; 
;
;  8.1  Original PLATO ASCII mapping
;
;                   MICRO
;   PLATO KEY      PLATO KEY       ASCII CHAR.     ASCII CHAR.
;                  CODE (HEX)      GENERATED       CODE (HEX)
;     SYMBOL          SHIFT          SYMBOL          SHIFT
;   LOWER  UPPER     OFF  ON       LOWER  UPPER     OFF  ON
;  ------- ------    --   --       -----  -----     --   --
;     +      Σ       0E   2E          +     #       2B   23
;     ⇦      shift   0D   2D          ^     \       5E   5C
;     -      Δ       0F   2F          -     ~       2D   7E
;     ÷      ∩       0B   2B          `     '       60   27
;     ×      ∪       0A   2A          &     @       26   40
;     SUPER  SUPER1  10   30          DC3   ETB     13   17
;     SUB    SUB1    11   31          EOT   ENQ     04   05
;     ANS    TERM    12   32          BEL   DC4     07   14
;     COPY   COPY1   1B   3B          ETX   SYN     03   16
;     HELP   HELP1   15   35          VT    HT      0B   09
;     SQUARE ACCESS  1C   3C          }     NULL    7D   00
;     NEXT   NEXT1   16   36          CR    RS      0D   1E
;     EDIT   EDIT1   17   37          SUB   CAN     1A   18
;     BACK   BACK1   18   38          STX   SO      02   0E
;     LAB    LAB1    1D   3D          FF    SI      0C   0F
;     DATA   DATA1   19   39          DC2   GS      12   1D
;     STOP   STOP1   1A   3A          SOH   DC1     01   11
;
; ------------------------------------------------------------------------------
LBA12:	.byte	key_plus			; PLATO: Σ,Δ
	.byte	'#','~'				; ASCII: #,~

	.byte	key_div				; PLATO: ÷,∩
	.byte	'`','''				; ASCII: -,'

	.byte	key_mult			; PLATO: ×,∪
	.byte	'&','@'				; ASCII: &,@

	.byte	key_lt				; PLATO: ⇦,shift
	.byte	'^','\'				; ASCII: ^,\

	.byte	key_s				; PLATO: STOP,STOP1
	.byte	$01,$11				; ASCII: SOH,DC1

	.byte	key_equal			; PLATO: SUB,SUB1
	.byte	$04,$05				; ASCII: EOT,ENQ

	.byte	key_minus			; PLATO: SUPER,SUPER1
	.byte	$13,$17				; ASCII: DC3,ETB

	.byte	key_gt				; PLATO: SQUARE,ACCESS
	.byte	'}',$00				; ASCII: },NUL

	.byte	key_c				; PLATO: COPY,COPY1
	.byte	$03,$16				; ASCII: ETX,SYN

	.byte	key_e				; PLATO: EDIT,EDIT1
	.byte	$1A,$18				; ASCII: SUB,CAN

	.byte	key_a				; PLATO: ANS,ANS
	.byte	$07,$07				; ASCII: BEL,BEL

	.byte	key_t				; PLATO: TERM,TERM
	.byte	$14,$14				; ASCII: DC4,DC4

	.byte	key_h				; PLATO: HELP,HELP1
	.byte	$0B,$09				; ASCII: VT,HT

; Joystick-mapped function keys
	.byte	key_d				; PLATO: DATA,DATA1
LBA3A:  .byte   $12,$1D				; ASCII: DC2,GS

	.byte	key_l				; PLATO: LAB,LAB1
LBA3D:  .byte   $0C,$0F				; ASCII: FF,SI

	.byte	key_b				; PLATO: BACK,BACK1
LBA40:  .byte   $02,$0E				; ASCII: STX,SO

	.byte	key_n				; PLATO: NEXT,NEXT1
LBA43:  .byte   $0D,$1E				; ASCII: CR,RS

; ------------------------------------------------------------------------------
;			ATARI TO PLATO KEYMAPPING TABLE #2
;
; The lookup table at $BA45 approximates Appendix D of the s0ascers document. 
;
; This table differs slightly from TABLE #1 in that terminal keys are not 
; generated using a [START] key combination.
;
; Provided here is the s0ascers table reduced to strictly the mappings found in 
; the $BA45 table. The ASCII CHAR. CODE values on the right side of the s0ascers
; table are the values that correspond to the Atari key code in the $BA45 table.
; 
;                   MICRO
;   PLATO KEY      PLATO KEY       ASCII CHAR.     ASCII CHAR.
;                  CODE (HEX)      GENERATED       CODE (HEX)
;     SYMBOL          SHIFT          SYMBOL          SHIFT
;   LOWER  UPPER     OFF  ON       LOWER  UPPER     OFF  ON
;  ------- ------    --   --       -----  -----     --   --
;   ERASE  ERASE1    13   33       BS     EM        08   19
;   TAB    CR        0C   2C       LF     FS        0A   1C
;   NEXT   NEXT1     16   36       CR     RS        0D   1E
;   SPACE  BACKSP    40   60       SPACE  US        20   1F
;   7      '         07   27       7      |         37   7C
; ------------------------------------------------------------------------------
LBA45:  .byte   key_space + mod_shift		; PLATO: BACKSP
LBA46:  .byte	$1F				; ASCII: US

	.byte	key_backs + mod_shift		; PLATO: ERASE1
	.byte	$19				; ASCII: EM

	.byte	key_backs			; PLATO: ERASE
	.byte	$08				; ASCII: BS

	.byte	key_apos			; PLATO: '
	.byte	'|'				; ASCII: |

	.byte	key_tab				; PLATO: TAB
	.byte	$0A				; ASCII: LF

	.byte	key_return + mod_shift		; PLATO: NEXT1
	.byte	$1E				; ASCII: RS

	.byte	key_return			; PLATO: NEXT
	.byte	$0D				; ASCII: CR

; ------------------------------------------------------------------------------
;			ATARI TO PLATO KEYMAPPING TABLE #3
;
; From s0ascers 3.2.3.3.1:
;
; Some keyboards have keys that are represented by a single character in the 
; ASCII character set, but by a two-character sequence in the PLATO character 
; set. The two characters are ACCESS (also known as SHIFT-SQUARE, a PLATO key 
; for generating these and other special characters) and another character as 
; specified in the following table.
; 
;      Character    Hex value       Resulting sequence
;                    (ASCII)
; 
;           #         23            ACCESS $
;           &         26            ACCESS +
;           @         40            ACCESS 5
;           \         5C            ACCESS /
;           ^         5E            ACCESS x
;           `         60            ACCESS q
;           {         7B            ACCESS [
;           |         7C            ACCESS I
;           }         7D            ACCESS ]
;           ~         7E            ACCESS n
;
; The ACCESS character code is $00.
;
; The routine that uses this table sends a $00 followed by the PLATO code in 
; this table that corresponds to an Atari keyboard scan code.
; ------------------------------------------------------------------------------
LBA53:  .byte   key_bkslash			; ATARI: \
LBA54:  .byte   '/'				; PLATO: ACCESS, /

	.byte	key_caret			; ATARI: ^
	.byte	'x'				; PLATO: ACCESS, x

	.byte	key_pipe			; ATARI: |
	.byte	'I'				; PLATO: ACCESS, I

	.byte	key_hash			; ATARI: #
	.byte	'$'				; PLATO: ACCESS, $

	.byte	key_amper			; ATARI: &
	.byte	'+'				; PLATO: ACCESS, +

	.byte	key_at				; ATARI: @
	.byte	'5'				; PLATO: ACCESS, 5

; ------------------------------------------------------------------------------

	.byte	$02,$BB,$5A,$30,$5F
	.byte	$EE,$3D,$A8

; Bitmap for 'F' displayed when in joystick-mapped function key mode
LBA67:	.byte	%01110000			; .###....
	.byte	%01000000			; .#......
	.byte	%01110000			; .###....
	.byte	%01000000			; .#......
	.byte	%01000000			; .#......

; Bitmap for touch screen cross-shaped cursor
	.byte	%00000110			; .....##.
	.byte	%00001111			; ....####
	.byte	%00000110			; .....##.

.macro	jt1	arg1
	.byte	(arg1-esc_seq_ff)
.endmacro

JUMTAB:						; BA6F
;** Control Characters *********************************************************
	.repeat 8
		jt1	gen_rts			; 00-07 -> RTS
	.endrepeat
	jt1	proc_bs				; 08 -> BS
	jt1	proc_ht				; 09 -> TAB
	jt1	proc_lf				; 0A -> LF
	jt1	proc_vt				; 0B -> VT
	jt1	proc_ff				; 0C -> FF
	jt1	proc_cr				; 0D -> CR
	.repeat 11
		jt1	gen_rts			; 0E-18 -> RTS
	.endrepeat
	jt1	sel_data_mode			; 19 -> data mode 4 (block write/erase)
	jt1	gen_rts				; 1A -> unknown
	jt1	set_esc				; 1B -> start of escape sequence
	jt1	sel_data_mode			; 1C -> data mode 0 (point-plot)
	jt1	sel_data_mode			; 1D -> data mode 1 (draw line)
	jt1	gen_rts				; 1E -> RTS
	jt1	sel_data_mode			; 1F -> data mode 3 (alpha)

;** Escape Sequences <= #$20 ***************************************************
	jt1	gen_rts				; 00: Undefined -> RTS
	jt1	sel_term_tty			; 01: ESC SOH -> Terminal mode Tektronix
	jt1	sel_term_plato			; 02: ESC STX -> Terminal mode PLATO
	jt1	sel_term_tty			; 03: ESC ETX -> Terminal mode TTY
	.repeat 8
		jt1	gen_rts			; 04-0B: Undefined -> RTS
	.endrepeat
	jt1	esc_seq_ff			; 0C: ESC FF -> Clear screen without resetting (X,Y)
	.repeat 4
		jt1	gen_rts			; 0D-10: Undefined -> RTS
	.endrepeat
	.repeat 4
		jt1	sel_screen_mode		; 11-14: ESC DC1-DC4 -> Select video mode
	.endrepeat
	.repeat 6
		jt1	gen_rts			; 15-1A: Undefined -> RTS
	.endrepeat
	jt1	set_esc				; 1B: ESC ESC -> continue to next char
	.repeat 4
		jt1	gen_rts			; 1C-1F: Undefined -> RTS
	.endrepeat

;** Escape Sequences >= #$40 ***************************************************
	jt1	set_super			; 40 ESC @ -> Superscript
	jt1	set_sub				; 41 ESC A -> Subscript
	.repeat 4
		jt1	sel_char_set		; 42-45 ESC B-E
	.endrepeat
	.repeat 8
		jt1	gen_rts			; 46-4D ESC F-M
	.endrepeat
	jt1	sel_size_0			; 4E ESC N -> Select text size 0 (normal)
	jt1	sel_size_2			; 4F ESC O -> Select text size 2 (double)
	jt1	sel_data_mode			; 50 ESC P -> Load memory
	jt1	set_ssf				; 51 ESC Q -> SSF command.
	.repeat 3
		jt1	set_mode_7		; 52-54 ESC R-T
	.endrepeat
	jt1	set_mode_6			; 55 ESC U -> Select mode 6
	jt1	set_mode_7			; 56 ESC V -> Select mode 7
	jt1	set_load_mem			; 57 ESC W -> Load Memory Address command
	jt1	gen_rts				; 58 ESC X -> RTS
	jt1	set_load_echo			; 59 ESC Y -> Load Echo command
	jt1	set_margin			; 50 ESC Z -> Set margin

LBACA:	.byte	>(DLOAD-1)			; Download character set
	.byte	>(sub_a448-1)
	.byte	$00
	.byte	$00
	.byte	>(sub_a682-1)
	.byte	>(sub_adf1-1)
	.byte	$00
	.byte   >(print_char2-1)		; sub_ab5a

LBAD2:	.byte	<(DLOAD-1)			; Download character set
	.byte	<(sub_a448-1)
	.byte	$00
	.byte	$00
	.byte	<(sub_a682-1)
	.byte	<(sub_adf1-1)
	.byte	$00
	.byte	<(print_char2-1)		; sub_ab5a

LBADA:	
	.byte	$03				; unused?
	.byte	$80				; data mode 4->block write/erase mode
	.byte	$00
	.byte	$00
	.byte	$80				; data mode 0->point-plot mode
	.byte	$80				; data mode 1->draw line mode
	.byte	$00
	.byte	$01				; data mode 3->alpha mode

LBAE2:	.byte	>(get_tek_vects-1)		; byte_B4 = 1 
	.byte	>(proc_ssf-1)			; byte_B4 = 2 ESC Q (SSF)
	.byte	>(proc_echo-1)			; byte_B4 = 3 ESC Y (load Echo)
	.byte	>(sub_a640-1)			; byte_B4 = 4 ESC W (load Memory Address)
	.byte	>(sub_a133-1)			; byte_B4 = 5 ESC U (select mode 6)

LBAE7:	.byte   <(get_tek_vects-1)
	.byte	<(proc_ssf-1)
	.byte	<(proc_echo-1)
	.byte	<(sub_a640-1)
	.byte	<(sub_a133-1)

byte_BAEC:
ch_mem_m1_DL2:
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000010       		; ......#.
	.byte   %00000100       		; .....#..
	.byte   %00001000       		; ....#...
	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %01111100       		; .#####..
	.byte   %00000000       		; ........
	.byte   %01111100       		; .#####..
	.byte   %00000000       		; ........
	.byte   %01111100       		; .#####..
	.byte   %00000000       		; ........

	.byte   %00110010       		; ..##..#.
	.byte   %01001100       		; .#..##..
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00110000       		; ..##....
	.byte   %01011110       		; .#.####.
	.byte   %10000000       		; #.......
	.byte   %01011110       		; .#.####.
	.byte   %00110000       		; ..##....
	.byte   %00010000       		; ...#....

	.byte   %00000000       		; ........
	.byte   %00000010       		; ......#.
	.byte   %00000100       		; .....#..
	.byte   %11111110       		; #######.
	.byte   %00010000       		; ...#....
	.byte   %11111110       		; #######.
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......

	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00111000       		; ..###...
	.byte   %01111100       		; .#####..
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00001000       		; ....#...
	.byte   %00001100       		; ....##..
	.byte   %11111110       		; #######.
	.byte   %00001100       		; ....##..
	.byte   %00001000       		; ....#...
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %01111100       		; .#####..
	.byte   %00111000       		; ..###...
	.byte   %00010000       		; ...#....

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00100000       		; ..#.....
	.byte   %01100000       		; .##.....
	.byte   %11111110       		; #######.
	.byte   %01100000       		; .##.....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00100100       		; ..#..#..
	.byte   %00011000       		; ...##...
	.byte   %00011000       		; ...##...
	.byte   %00100100       		; ..#..#..
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %11111110       		; #######.
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %11111110       		; #######.

	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00101000       		; ..#.#...
	.byte   %00101000       		; ..#.#...
	.byte   %01000100       		; .#...#..
	.byte   %01000100       		; .#...#..
	.byte   %10000010       		; #.....#.
	.byte   %11111110       		; #######.

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %01000100       		; .#...#..
	.byte   %01000100       		; .#...#..
	.byte   %01000100       		; .#...#..
	.byte   %00111000       		; ..###...
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00111000       		; ..###...
	.byte   %01000100       		; .#...#..
	.byte   %01000100       		; .#...#..
	.byte   %01000100       		; .#...#..
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00000000       		; ........
	.byte   %01111100       		; .#####..
	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %01100010       		; .##...#.
	.byte   %10010010       		; #..#..#.
	.byte   %10010100       		; #..#.#..
	.byte   %10001000       		; #...#...
	.byte   %10011000       		; #..##...
	.byte   %01100110       		; .##..##.

	.byte   %00011000       		; ...##...
	.byte   %00100100       		; ..#..#..
	.byte   %01000100       		; .#...#..
	.byte   %01111000       		; .####...
	.byte   %01000100       		; .#...#..
	.byte   %01000010       		; .#....#.
	.byte   %01111100       		; .#####..
	.byte   %01000000       		; .#......

	.byte   %00110000       		; ..##....
	.byte   %01001000       		; .#..#...
	.byte   %00100000       		; ..#.....
	.byte   %00110000       		; ..##....
	.byte   %01001000       		; .#..#...
	.byte   %01000100       		; .#...#..
	.byte   %01000100       		; .#...#..
	.byte   %00111000       		; ..###...

	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00101000       		; ..#.#...
	.byte   %00101000       		; ..#.#...
	.byte   %01000100       		; .#...#..
	.byte   %01000100       		; .#...#..

	.byte   %00000000       		; ........
	.byte   %00100100       		; ..#..#..
	.byte   %00100100       		; ..#..#..
	.byte   %00100100       		; ..#..#..
	.byte   %00111010       		; ..###.#.
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %11000000       		; ##......

	.byte   %00000000       		; ........
	.byte   %00100000       		; ..#.....
	.byte   %01111100       		; .#####..
	.byte   %10101000       		; #.#.#...
	.byte   %00101000       		; ..#.#...
	.byte   %00101000       		; ..#.#...
	.byte   %00101000       		; ..#.#...
	.byte   %00101000       		; ..#.#...

	.byte   %00000000       		; ........
	.byte   %00001100       		; ....##..
	.byte   %00010010       		; ...#..#.
	.byte   %00100010       		; ..#...#.
	.byte   %01100100       		; .##..#..
	.byte   %01011000       		; .#.##...
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00111110       		; ..#####.
	.byte   %01010000       		; .#.#....
	.byte   %10001000       		; #...#...
	.byte   %10001000       		; #...#...
	.byte   %10001000       		; #...#...
	.byte   %01110000       		; .###....

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %01000100       		; .#...#..
	.byte   %10000010       		; #.....#.
	.byte   %10010010       		; #..#..#.
	.byte   %10010010       		; #..#..#.
	.byte   %10010010       		; #..#..#.
	.byte   %01101100       		; .##.##..

	.byte   %00001100       		; ....##..
	.byte   %00110000       		; ..##....
	.byte   %11000000       		; ##......
	.byte   %00110000       		; ..##....
	.byte   %00001100       		; ....##..
	.byte   %00000000       		; ........
	.byte   %11111100       		; ######..
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %00011000       		; ...##...
	.byte   %01100000       		; .##.....
	.byte   %00011000       		; ...##...
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........
	.byte   %01111110       		; .######.
	.byte   %00000000       		; ........

	.byte   %00111000       		; ..###...
	.byte   %01000100       		; .#...#..
	.byte   %10000010       		; #.....#.
	.byte   %11111110       		; #######.
	.byte   %10000010       		; #.....#.
	.byte   %10000010       		; #.....#.
	.byte   %01000100       		; .#...#..
	.byte   %00111000       		; ..###...

	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......
	.byte   %00011000       		; ...##...
	.byte   %00101000       		; ..#.#...
	.byte   %01001000       		; .#..#...
	.byte   %00101000       		; ..#.#...
	.byte   %00011000       		; ...##...
	.byte   %00001100       		; ....##..

	.byte   %00110000       		; ..##....
	.byte   %01001000       		; .#..#...
	.byte   %01001000       		; .#..#...
	.byte   %00110000       		; ..##....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %00110000       		; ..##....
	.byte   %00101000       		; ..#.#...
	.byte   %00100100       		; ..#..#..
	.byte   %00101000       		; ..#.#...
	.byte   %00110000       		; ..##....
	.byte   %01100000       		; .##.....

	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %01001000       		; .#..#...
	.byte   %00100100       		; ..#..#..
	.byte   %00100100       		; ..#..#..
	.byte   %01001000       		; .#..#...
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....

	.byte   %11111110       		; #######.
	.byte   %00000000       		; ........
	.byte   %00111100       		; ..####..
	.byte   %01000010       		; .#....#.
	.byte   %10000000       		; #.......
	.byte   %00111100       		; ..####..
	.byte   %00000000       		; ........
	.byte   %11111110       		; #######.

	.byte   %00101000       		; ..#.#...
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %01111100       		; .#####..
	.byte   %01000100       		; .#...#..
	.byte   %01000100       		; .#...#..
	.byte   %01111100       		; .#####..
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00110000       		; ..##....
	.byte   %01001000       		; .#..#...
	.byte   %01001000       		; .#..#...
	.byte   %00110000       		; ..##....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00111000       		; ..###...
	.byte   %01111100       		; .#####..
	.byte   %11111110       		; #######.
	.byte   %01111100       		; .#####..
	.byte   %00111000       		; ..###...
	.byte   %00010000       		; ...#....

	.byte   %00000000       		; ........
	.byte   %10000010       		; #.....#.
	.byte   %01000100       		; .#...#..
	.byte   %00101000       		; ..#.#...
	.byte   %00010000       		; ...#....
	.byte   %00101000       		; ..#.#...
	.byte   %01000100       		; .#...#..
	.byte   %10000010       		; #.....#.

	.byte   %00000100       		; .....#..
	.byte   %00001000       		; ....#...
	.byte   %00010000       		; ...#....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000100       		; .....#..
	.byte   %00001000       		; ....#...
	.byte   %00010000       		; ...#....

	.byte   %01000100       		; .#...#..
	.byte   %00101000       		; ..#.#...
	.byte   %00010000       		; ...#....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00111000       		; ..###...
	.byte   %01111100       		; .#####..
	.byte   %00010000       		; ...#....
	.byte   %01111100       		; .#####..
	.byte   %00111000       		; ..###...
	.byte   %00010000       		; ...#....

	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....

ch_mem_m0_DL1:
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %01010000       		; .#.#....
	.byte   %01010000       		; .#.#....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %01010000       		; .#.#....
	.byte   %11111000       		; #####...
	.byte   %01010000       		; .#.#....
	.byte   %11111000       		; #####...
	.byte   %01010000       		; .#.#....
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %11110000       		; ####....
	.byte   %11000000       		; ##......
	.byte   %00110000       		; ..##....
	.byte   %11110000       		; ####....
	.byte   %00100000       		; ..#.....

	.byte   %10010000       		; #..#....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %10100000       		; #.#.....
	.byte   %01000000       		; .#......
	.byte   %10110000       		; #.##....
	.byte   %01010000       		; .#.#....
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %11110000       		; ####....
	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %11111000       		; #####...
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01100000       		; .##.....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........

	.byte   %11110000       		; ####....
	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....
	.byte   %00010000       		; ...#....
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01100000       		; .##.....
	.byte   %10100000       		; #.#.....
	.byte   %11110000       		; ####....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %11100000       		; ###.....
	.byte   %10000000       		; #.......
	.byte   %11100000       		; ###.....
	.byte   %00010000       		; ...#....
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10000000       		; #.......
	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %11110000       		; ####....
	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %01110000       		; .###....
	.byte   %00010000       		; ...#....
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %10110000       		; #.##....
	.byte   %10000000       		; #.......
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %11110000       		; ####....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %01110000       		; .###....
	.byte   %10000000       		; #.......
	.byte   %10000000       		; #.......
	.byte   %10000000       		; #.......
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........

	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %11110000       		; ####....
	.byte   %10000000       		; #.......
	.byte   %11100000       		; ###.....
	.byte   %10000000       		; #.......
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........

	.byte   %11110000       		; ####....
	.byte   %10000000       		; #.......
	.byte   %11100000       		; ###.....
	.byte   %10000000       		; #.......
      	.byte   %10000000       		; #.......
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10000000       		; #.......
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........

	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %11110000       		; ####....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %11100000       		; ###.....
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %10010000       		; #..#....
	.byte   %10100000       		; #.#.....
	.byte   %11000000       		; ##......
	.byte   %10100000       		; #.#.....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %10000000       		; #.......
	.byte   %10000000       		; #.......
	.byte   %10000000       		; #.......
	.byte   %10000000       		; #.......
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........

	.byte   %10001000       		; #...#...
	.byte   %11011000       		; ##.##...
	.byte   %10101000       		; #.#.#...
	.byte   %10001000       		; #...#...
	.byte   %10001000       		; #...#...
	.byte   %00000000       		; ........

	.byte   %10010000       		; #..#....
	.byte   %11010000       		; ##.#....
	.byte   %10110000       		; #.##....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %11110000       		; ####....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........

	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %10000000       		; #.......
	.byte   %10000000       		; #.......
	.byte   %00000000       		; ........

	.byte   %11110000       		; ####....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10110000       		; #.##....
	.byte   %11111000       		; #####...
	.byte   %00000000       		; ........

	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %10100000       		; #.#.....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %01110000       		; .###....
	.byte   %10000000       		; #.......
	.byte   %11100000       		; ###.....
	.byte   %00010000       		; ...#....
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %11111000       		; #####...
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........

	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %10001000       		; #...#...
	.byte   %10001000       		; #...#...
	.byte   %10101000       		; #.#.#...
	.byte   %11011000       		; ##.##...
	.byte   %10001000       		; #...#...
	.byte   %00000000       		; ........

	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %11110000       		; ####....
	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........

	.byte   %01110000       		; .###....
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %10000000       		; #.......
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %00010000       		; ...#....
	.byte   %00000000       		; ........

	.byte   %01110000       		; .###....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %00010000       		; ...#....
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %10001000       		; #...#...
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %11110000       		; ####....

	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %11000000       		; ##......
	.byte   %00100000       		; ..#.....
	.byte   %10100000       		; #.#.....
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........

	.byte   %10000000       		; #.......
	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01100000       		; .##.....
	.byte   %10000000       		; #.......
	.byte   %10000000       		; #.......
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %00010000       		; ...#....
	.byte   %01110000       		; .###....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01100000       		; .##.....
	.byte   %10110000       		; #.##....
	.byte   %10000000       		; #.......
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %10000000       		; #.......
	.byte   %11100000       		; ###.....
	.byte   %10000000       		; #.......
	.byte   %10000000       		; #.......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %11110000       		; ####....
	.byte   %00010000       		; ...#....
	.byte   %01100000       		; .##.....

	.byte   %10000000       		; #.......
	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %11000000       		; ##......

	.byte   %10000000       		; #.......
	.byte   %10100000       		; #.#.....
	.byte   %11000000       		; ##......
	.byte   %10100000       		; #.#.....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %10010000       		; #..#....
	.byte   %11110000       		; ####....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %11100000       		; ###.....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %10000000       		; #.......

	.byte   %00000000       		; ........
	.byte   %01110000       		; .###....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01110000       		; .###....
	.byte   %00010000       		; ...#....

	.byte   %00000000       		; ........
	.byte   %01110000       		; .###....
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01110000       		; .###....
	.byte   %11000000       		; ##......
	.byte   %00110000       		; ..##....
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %11100000       		; ###.....
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %10010000       		; #..#....
	.byte   %10100000       		; #.#.....
	.byte   %10100000       		; #.#.....
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %11110000       		; ####....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01110000       		; .###....
	.byte   %00010000       		; ...#....
	.byte   %01100000       		; .##.....

	.byte   %00000000       		; ........
	.byte   %11110000       		; ####....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......
	.byte   %01000000       		; .#......
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %11000000       		; ##......
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %11000000       		; ##......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte	%01101000			; .##.#...
	.byte	%10110000			; #.##....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

ch_mem_m1_DL1:
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......
	.byte   %10000000       		; #.......

	.byte   %00000000       		; ........
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........
	.byte   %11100000       		; ###.....
	.byte   %00000000       		; ........
	.byte   %11100000       		; ###.....

	.byte   %01010000       		; .#.#....
	.byte   %10100000       		; #.#.....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01110000       		; .###....
	.byte   %10000000       		; #.......
	.byte   %01110000       		; .###....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %11110000       		; ####....
	.byte   %00100000       		; ..#.....
	.byte   %11110000       		; ####....
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00100000       		; ..#.....
	.byte   %01110000       		; .###....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00100000       		; ..#.....
	.byte   %11110000       		; ####....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %01110000       		; .###....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %01000000       		; .#......
	.byte   %11110000       		; ####....
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01010000       		; .#.#....
	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %11110000       		; ####....
	.byte   %10000000       		; #.......
	.byte   %01100000       		; .##.....
	.byte   %10000000       		; #.......
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %10001000       		; #...#...
	.byte   %11111000       		; #####...
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........
	.byte   %11110000       		; ####....
	.byte   %00000000       		; ........
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01010000       		; .#.#....
	.byte   %10100000       		; #.#.....
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %10100000       		; #.#.....
	.byte   %10010000       		; #..#....
	.byte   %11100000       		; ###.....
	.byte   %10000000       		; #.......

	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........

	.byte   %10000000       		; #.......
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %10010000       		; #..#....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %01010000       		; .#.#....
	.byte   %01010000       		; .#.#....
	.byte   %01100000       		; .##.....
	.byte   %10000000       		; #.......

	.byte   %00001000       		; ....#...
	.byte   %01111000       		; .####...
	.byte   %11010000       		; ##.#....
	.byte   %01010000       		; .#.#....
	.byte   %01010000       		; .#.#....
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %01010000       		; .#.#....
	.byte   %10100000       		; #.#.....
	.byte   %10000000       		; #.......

	.byte   %00110000       		; ..##....
	.byte   %01000000       		; .#......
	.byte   %10100000       		; #.#.....
	.byte   %10100000       		; #.#.....
	.byte   %01000000       		; .#......
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %10010000       		; #..#....
	.byte   %10110000       		; #.##....
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %11100000       		; ###.....

	.byte   %10000000       		; #.......
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %10000000       		; #.......
	.byte   %11100000       		; ###.....

	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %01110000       		; .###....
	.byte   %01010000       		; .#.#....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %00110000       		; ..##....
	.byte   %01100000       		; .##.....
	.byte   %10100000       		; #.#.....
	.byte   %01100000       		; .##.....
	.byte   %00110000       		; ..##....
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %11000000       		; ##......
	.byte   %01100000       		; .##.....
	.byte   %01010000       		; .#.#....
	.byte   %01100000       		; .##.....
	.byte   %11000000       		; ##......
	.byte   %00000000       		; ........

	.byte   %11000000       		; ##......
	.byte   %10100000       		; #.#.....
	.byte   %01010000       		; .#.#....
	.byte   %01010000       		; .#.#....
	.byte   %10100000       		; #.#.....
	.byte   %11000000       		; ##......

	.byte   %11111000       		; #####...
	.byte   %00100000       		; ..#.....
	.byte   %01000000       		; .#......
	.byte   %01000000       		; .#......
	.byte   %00100000       		; ..#.....
	.byte   %11111000       		; #####...

	.byte   %01010000       		; .#.#....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01110000       		; .###....
	.byte   %01010000       		; .#.#....
	.byte   %01110000       		; .###....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %01100000       		; .##.....
	.byte   %10010000       		; #..#....
	.byte   %01100000       		; .##.....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01110000       		; .###....
	.byte   %11111000       		; #####...
	.byte   %01110000       		; .###....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %10001000       		; #...#...
	.byte   %01010000       		; .#.#....
	.byte   %00100000       		; ..#.....
	.byte   %01010000       		; .#.#....
	.byte   %10001000       		; #...#...
	.byte   %00000000       		; ........

	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00010000       		; ...#....
	.byte   %00100000       		; ..#.....

	.byte   %10100000       		; #.#.....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %01110000       		; .###....
	.byte   %00100000       		; ..#.....
	.byte   %01110000       		; .###....
	.byte   %00100000       		; ..#.....
	.byte   %00000000       		; ........

	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....
	.byte   %00100000       		; ..#.....

;*******************************************************************************
;*                                                                             *
;*                               sub_hatabs_slot                               *
;*                                                                             *
;*                    Return first unused HATABS table entry                   *
;*                                                                             *
;*******************************************************************************
sub_bf86:
sub_hatabs_slot:

;** (n) Return the first empty slot in the Handler Address Table *****************
	cmp     HATABS,x			; Is entry empty?
	beq	:+      			; Quit. Z will be set
	inx             			; Skip the 3 byte entry
	inx
	inx
	cpx     #$20    			; If >= 32 Then Quit. Z will be clear
	bcc     sub_bf86			; Otherwise continue trying.
:	rts             			; Return with Z and X (offset)

;*******************************************************************************
;*                                                                             *
;*                                 cart_init                                   *
;*                                                                             *
;*         OS calls this code before jumping to cart start address             *
;*                                                                             *
;*******************************************************************************

cart_init:
	jsr	sub_b47d                        ; Init POKEY and serial interrupts

;*******************************************************************************
	lda	#$51
	sta	byte_1347                       ; Let byte_1347 = $51
	sta	byte_133a                       ; Let byte_133a = $51

;*******************************************************************************
	lda	$CB				;
	pha             			; Save current value in $CB
	lda     #$00    			;
	sta     $CB     			; Let $CB = $00
	jsr     sub_b420			;
	pla             			;
	sta     $CB     			; Restore original value of $CB

;*******************************************************************************
	lda     #$51    			; BFAB A9 51                    .Q
	sta     byte_133a

;*******************************************************************************
	lda     $08     			;
	beq     LBFC2   			; Skip next part if warmstart

;*******************************************************************************
	ldx     byte_B2
	cpx     #$02    			; BFB6 E0 02                    ..
	bcs     :+
	sec             			; BFBA 38                       8
	bne     LBFD8   			; BFBB D0 1B                    ..

:	ldx     #$02    			; BFBD A2 02                    ..
	jsr     sub_b43f

;*******************************************************************************
LBFC2:  lda     #$FF    			; BFC2 A9 FF                    ..
	sta     byte_133a

	lda     #$00    			; BFC7 A9 00                    ..
	sta     $CB     			; BFC9 85 CB                    ..
	ldx     #$02    			; BFCB A2 02                    ..
	jsr     sub_b422
	lda     #$51    			; BFD0 A9 51                    .Q
	sta     byte_133a
	jsr     sub_b420
LBFD8:  jsr     sub_b4f7
	bcs	:+
	lda     #$00    			; BFDD A9 00                    ..
	sta     byte_133a
	tax             			; BFE2 AA                       .
	jsr     sub_bf86
	bne	:+
	lda     #'T'
	sta     HATABS,x
	lda     #<t_handler
	sta     HATABS+1,x
	lda     #>t_handler
	sta     HATABS+2,x
:	rts

	.byte	$00,$00				;
;*******************************************************************************
;*                                                                             *
;*                                   LBFFA                                     *
;*                                                                             *
;*                              Cartridge Header                               *
;*                                                                             *
;*******************************************************************************
LBFFA:	.addr	cart_start                      ; Cart start address
	.byte   $00                             ; Used by OS to determine if this is ROM
	.byte	$04                             ; Option byte: run Cart init, then run Cart start
	.addr	cart_init                       ; Cart init address - entry point
