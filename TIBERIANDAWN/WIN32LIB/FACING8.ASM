;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Support Library                          *
;*                                                                         *
;*                    File Name : FACING8.ASM                              *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : May 8, 1991                              *
;*                                                                         *
;*                  Last Update : February 6, 1995  [BWG]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Desired_Facing8 -- Determines facing to reach a position.             *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


IDEAL
P386
MODEL USE32 FLAT

GLOBAL	 C Desired_Facing8	:NEAR
;	INCLUDE	"wwlib.i"

	DATASEG

; 8 direction desired facing lookup table.  Build the index according
; to the following bits:
;
; bit 3 = Is y2 < y1?
; bit 2 = Is x2 < x1?
; bit 1 = Is the ABS(x2-x1) < ABS(y2-y1)?
; bit 0 = Is the facing closer to a major axis?
NewFacing8	DB	1,2,1,0,7,6,7,0,3,2,3,4,5,6,5,4

	CODESEG



;***************************************************************************
;* DESIRED_FACING8 -- Determines facing to reach a position.               *
;*                                                                         *
;*    This routine will return with the most desirable facing to reach     *
;*    one position from another.  It is accurate to a resolution of 0 to   *
;*    7.                                                                   *
;*                                                                         *
;* INPUT:       x1,y1   -- Position of origin point.                       *
;*                                                                         *
;*              x2,y2   -- Position of target.                             *
;*                                                                         *
;* OUTPUT:      Returns desired facing as a number from 0..255 with an     *
;*              accuracy of 32 degree increments.                          *
;*                                                                         *
;* WARNINGS:    If the two coordinates are the same, then -1 will be       *
;*              returned.  It is up to you to handle this case.            *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/15/1991 JLB : Documented.                                          *
;*   08/08/1991 JLB : Same position check.                                 *
;*   08/14/1991 JLB : New algorithm                                        *
;*   02/06/1995 BWG : Convert to 32-bit                                    *
;*=========================================================================*
	PROC	Desired_Facing8 C near
	USES	ebx, ecx, edx

	ARG	x1:DWORD
	ARG	y1:DWORD
	ARG	x2:DWORD
	ARG	y2:DWORD

	xor	ebx,ebx			; Index byte (built).

	; Determine Y axis difference.
	mov	edx,[y1]
	mov	ecx,[y2]
	sub	edx,ecx			; DX = Y axis (signed).
	jns	short ??absy
	inc	ebx			; Set the signed bit.
	neg	edx			; ABS(y)
??absy:

	; Determine X axis difference.
	shl	ebx,1
	mov	eax,[x1]
	mov	ecx,[x2]
	sub	ecx,eax			; CX = X axis (signed).
	jns	short ??absx
	inc	ebx			; Set the signed bit.
	neg	ecx			; ABS(x)
??absx:

	; Determine the greater axis.
	cmp	ecx,edx
	jb	short ??dxisbig
	xchg	ecx,edx
??dxisbig:
	rcl	ebx,1			; Y > X flag bit.

	; Determine the closeness or farness of lesser axis.
	mov	eax,edx
	inc	eax			; Round up.
	shr	eax,1

	cmp	ecx,eax
	rcl	ebx,1			; Close to major axis bit.

	xor	eax,eax
	mov	al,[NewFacing8+ebx]

	; Normalize to 0..FF range.
	shl	eax,5

	ret

	ENDP	Desired_Facing8


	END
