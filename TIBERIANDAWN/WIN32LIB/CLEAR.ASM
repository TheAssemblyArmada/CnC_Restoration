IDEAL
P386
MODEL USE32 FLAT

INCLUDE "GBUFFER.INC"

GLOBAL C Buffer_Clear 		:NEAR

CODESEG  
;***************************************************************************
;* VVPC::CLEAR -- Clears a virtual viewport instance                       *
;*                                                                         *
;* INPUT:	UBYTE the color (optional) to clear the view port to	   *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* NOTE:	This function is optimized to handle viewport with no XAdd *
;*		value.  It also handles DWORD aligning the destination	   *
;*		when speed can be gained by doing it.			   *
;* HISTORY:                                                                *
;*   06/07/1994 PWG : Created.                                             *
;*   08/23/1994 SKB : Clear the direction flag to always go forward.       *
;*=========================================================================*
PROC Buffer_Clear C
    USES eax,ebx,ecx,edx,esi,edi
    
	ARG    	this_object:DWORD				; this is a member function
	ARG    	color:BYTE				; what color should we clear to

		cld 		 				; always go forward

		mov	ebx,[this_object]			; get a pointer to viewport
		mov	edi,[(GraphicViewPort ebx).GVPOffset]	; get the correct offset
		mov	edx,[(GraphicViewPort ebx).GVPHeight]	; get height from viewport
		mov	esi,[(GraphicViewPort ebx).GVPWidth]		; get width from viewport
		push	[dword (GraphicViewPort ebx).GVPPitch]	; extra pitch of direct draw surface

		mov	ebx,[(GraphicViewPort ebx).GVPXAdd]		; esi = add for each line
		add	ebx,[esp]				; Yes, I know its nasty but
		add	esp,4					;      it works!

		;*===================================================================
		; Convert the color byte to a DWORD for fast storing
		;*===================================================================
		mov	al,[color]				; get color to clear to
		mov	ah,al					; extend across WORD
		mov	ecx,eax					; extend across DWORD in
		shl	eax,16					;   several steps
		mov	ax,cx

		;*===================================================================
		; Find out if we should bother to align the row.
		;*===================================================================

		cmp	esi , OPTIMAL_BYTE_COPY			; is it worth aligning them?
		jl	byte_by_byte				;   if not then skip

		;*===================================================================
		; Figure out the alignment offset if there is any
		;*===================================================================
		push	ebx
	
	dword_aligned_loop:
		    mov	ecx , edi
		    mov	ebx , esi
		    neg	ecx
		    and	ecx , 3
		    sub	ebx , ecx
		    rep	stosb
		    mov	ecx , ebx
		    shr	ecx , 2
		    rep	stosd
		    mov	ecx , ebx
		    and	ecx , 3
		    rep	stosb
		    add	edi , [ esp ]
		    dec	edx					; decrement the height
		    jnz	dword_aligned_loop				; if more to do than do it
		    pop	eax
			ret

		;*===================================================================
		; If not enough bytes to bother aligning copy each line across a byte
		;    at a time.
		;*===================================================================
	byte_by_byte:
		mov	ecx,esi					; get total width in bytes
		rep	stosb					; store the width
		add	edi,ebx					; handle the xadd
		dec	edx					; decrement the height
		jnz	byte_by_byte				; if any left then next line
	done:
        ret
    ENDP
    
END
