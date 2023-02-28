;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood Library                         *
;*                                                                         *
;*                    File Name : PAL.ASM                                  *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : May 30, 1992                             *
;*                                                                         *
;*                  Last Update : April 27, 1994   [BR]                    *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Set_Palette_Range -- Sets changed values in the palette.              *
;*   Bump_Color -- adjusts specified color in specified palette            *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;********************** Model & Processor Directives ************************
IDEAL
P386
MODEL USE32 FLAT


;include "keyboard.inc"
FALSE = 0
TRUE  = 1

;****************************** Declarations ********************************
GLOBAL 		C Set_Palette_Range:NEAR
GLOBAL 		C Bump_Color:NEAR
GLOBAL  	C CurrentPalette:BYTE:768
GLOBAL		C PaletteTable:byte:1024


;********************************** Data ************************************
LOCALS ??

	DATASEG

CurrentPalette	DB	768 DUP(255)	; copy of current values of DAC regs
PaletteTable	DB	1024 DUP(0)

IFNDEF LIB_EXTERNS_RESOLVED
VertBlank	DW	0		; !!!! this should go away
ENDIF


;********************************** Code ************************************
	CODESEG

;***************************************************************************
;* SET_PALETTE_RANGE -- Sets a palette range to the new pal                *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:	This routine is optimized for changing a small number of   *
;*		colors in the palette.
;*                                                                         *
;* HISTORY:                                                                *
;*   03/07/1995 PWG : Created.                                             *
;*=========================================================================*
	PROC	Set_Palette_Range C NEAR
	ARG	palette:DWORD

	GLOBAL	Set_DD_Palette_:near
	GLOBAL	Wait_Vert_Blank_:near
	
	pushad
	mov	esi,[palette]
	mov	ecx,768/4
	mov	edi,offset CurrentPalette
	cld
	rep	movsd
	;call	Wait_Vert_Blank_
	mov	eax,[palette]
	call	Set_DD_Palette_
	popad
	ret
	ENDP

;***************************************************************************
;* Bump_Color -- adjusts specified color in specified palette              *
;*                                                                         *
;* INPUT:                                                                  *
;*	VOID *palette	- palette to modify				   *
;*	WORD changable	- color # to change				   *
;*	WORD target	- color to bend toward				   *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   04/27/1994 BR : Converted to 32-bit.                                  *
;*=========================================================================*
; BOOL cdecl Bump_Color(VOID *palette, WORD changable, WORD target);
PROC Bump_Color C NEAR
	USES ebx,ecx,edi,esi
	ARG	pal:DWORD, color:WORD, desired:WORD
	LOCAL	changed:WORD		; Has palette changed?
	
		mov	edi,[pal]		; Original palette pointer.
		mov	esi,edi
		mov	eax,0
		mov	ax,[color]
		add	edi,eax
		add	edi,eax
		add	edi,eax			; Offset to changable color.
		mov	ax,[desired]
		add	esi,eax
		add	esi,eax
		add	esi,eax			; Offset to target color.

		mov	[changed],FALSE		; Presume no change.
		mov	ecx,3			; Three color guns.

		; Check the color gun.
	colorloop:
		mov	al,[BYTE PTR esi]
		sub	al,[BYTE PTR edi]	; Carry flag is set if subtraction needed.
		jz	short gotit
		mov	[changed],TRUE
		inc	[BYTE PTR edi]		; Presume addition.
		jnc	short gotit		; oops, subtraction needed so dec twice.
		dec	[BYTE PTR edi]
		dec	[BYTE PTR edi]
	gotit:
		inc	edi
		inc	esi
		loop	colorloop

		movzx	ax,[changed]
		ret
	ENDP

END
