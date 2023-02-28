;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Support Library                          *
;*                                                                         *
;*                    File Name : FACING16.ASM                             *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : May 8, 1991                              *
;*                                                                         *
;*                  Last Update : February 6, 1995  [BWG]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Desired_Facing16 -- Converts coordinates into a facing number.        *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


IDEAL
P386
MODEL USE32 FLAT

GLOBAL	 C Desired_Facing16	:NEAR
;	INCLUDE	"wwlib.i"

	DATASEG

; 16 direction desired facing lookup table.  Build the index according
; to the following bits:
;
; bit 4 = Is y2 < y1?
; bit 3 = Is x2 < x1?
; bit 2 = Is the ABS(x2-x1) < ABS(y2-y1)?
; bit 1 = Is the lesser absolute difference very close to zero?
; bit 0 = Is the lesser absolute difference very close to the greater dist?
NewFacing16	DB	 3, 2, 4,-1, 1, 2,0,-1
		DB	13,14,12,-1,15,14,0,-1
		DB	 5, 6, 4,-1, 7, 6,8,-1
		DB	11,10,12,-1, 9,10,8,-1

	CODESEG

;***************************************************************************
;* DESIRED_FACING16 -- Converts coordinates into a facing number.          *
;*                                                                         *
;*      This converts coordinates into a desired facing number that ranges *
;*      from 0 to 15 (0 equals North and going clockwise).                 *
;*                                                                         *
;* INPUT:       x1,y1   -- Position of origin point.                       *
;*                                                                         *
;*              x2,y2   -- Position of target.                             *
;*                                                                         *
;* OUTPUT:      Returns desired facing as a number from 0 to 255 but       *
;*              accurate to 22.5 degree increments.                        *
;*                                                                         *
;* WARNINGS:    If the two coordinates are the same, then -1 will be       *
;*              returned.  It is up to you to handle this case.            *
;*                                                                         *
;* HISTORY:                                                                *
;*   08/14/1991 JLB : Created.                                             *
;*=========================================================================*
	PROC	Desired_Facing16 C near
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
	inc	eax			; Round up.
	shr	eax,1			; 1/4 of greater axis.

	cmp	ecx,eax
	rcl	ebx,1			; Very close to major axis bit.

	sub	edx,eax
	cmp	edx,ecx
	rcl	ebx,1			; Very far from major axis bit.

	xor	eax,eax
	mov	al,[NewFacing16+ebx]

	; Normalize to 0..FF range.
	shl	eax,4

	ret

	ENDP	Desired_Facing16

	END
