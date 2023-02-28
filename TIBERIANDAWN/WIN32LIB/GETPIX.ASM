IDEAL
P386
MODEL USE32 FLAT

INCLUDE "STAMP.INC"
INCLUDE "GBUFFER.INC"

GLOBAL C Buffer_Get_Pixel 		:NEAR

CODESEG
;***************************************************************************
;* VVPC::GET_PIXEL -- Gets a pixel from the current view port		   *
;*                                                                         *
;* INPUT:	WORD the x pixel on the screen.				   *
;*		WORD the y pixel on the screen.				   *
;*                                                                         *
;* OUTPUT:      UBYTE the pixel at the specified location		   *
;*                                                                         *
;* WARNING:	If pixel is to be placed outside of the viewport then	   *
;*		this routine will abort.				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   06/07/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Buffer_Get_Pixel C near
	USES	ebx,ecx,edx,edi

	ARG    	this_object:DWORD				; this is a member function
	ARG	x_pixel:DWORD				; x position of pixel to set
	ARG	y_pixel:DWORD				; y position of pixel to set

		;*===================================================================
		; Get the viewport information and put bytes per row in ecx
		;*===================================================================
		mov	ebx,[this_object]				; get a pointer to viewport
		xor	eax,eax
		mov	edi,[(GraphicViewPort ebx).GVPOffset]	; get the correct offset
		mov	ecx,[(GraphicViewPort ebx).GVPHeight]	; edx = height of viewport
		mov	edx,[(GraphicViewPort ebx).GVPWidth]	; ecx = width of viewport

		;*===================================================================
		; Verify that the X pixel offset if legal
		;*===================================================================
		mov	eax,[x_pixel]				; find the x position
		cmp	eax,edx					;   is it out of bounds
		jae	short exit_label				; if so then get out
		add	edi,eax					; otherwise add in offset

		;*===================================================================
		; Verify that the Y pixel offset if legal
		;*===================================================================
		mov	eax,[y_pixel]				; get the y position
		cmp	eax,ecx					;  is it out of bounds
		jae	exit_label					; if so then get out
		add	edx,[(GraphicViewPort ebx).GVPXAdd]	; otherwise find bytes per row
		add	edx,[(GraphicViewPort ebx).GVPPitch]	; otherwise find bytes per row
		mul	edx					; offset = bytes per row * y
		add	edi,eax					; add it into the offset

		;*===================================================================
		; Write the pixel to the screen
		;*===================================================================
		xor	eax,eax					; clear the word
		mov	al,[edi]				; read in the pixel
	exit_label:
		ret
		ENDP	Buffer_Get_Pixel
END
