IDEAL
P386
MODEL USE32 FLAT

global C Random : NEAR
global C Get_Random_Mask : NEAR
global C RandNumb : DWORD

	DATASEG

RandNumb	DD	12349876H

	CODESEG

;
; UBYTE Random(VOID);
; int Get_Random_Mask(int maxval);
;
; ----------------------------------------------------------------

;-----------------------------------------------------------------
; RANDOM
;
; UBYTE Random(VOID);
;
;*

	PROC	Random C near
	USES	esi

	lea	esi, [RandNumb]		; get offset in segment of RandNumb
	xor	eax,eax
	mov	al,[esi]
	shr	al,1			; shift right 1 bit (bit0 in carry)
	shr	al,1
	rcl	[BYTE PTR esi+2],1	; rcl byte 3 of RandNumb
	rcl	[BYTE PTR esi+1],1 	; rcl byte 2 of RandNumb
	cmc				; complement carry
	sbb	al,[esi]		; sbb byte 1 of RandNumb
	shr	al,1			; sets carry
	rcr	[BYTE PTR esi],1 	; rcr byte 1 of RandNumb
	mov	al,[esi]		; reload byte 1 of RandNumb
	xor	al,[esi+1]		; xor with byte 2 of RandNumb

	ret

	ENDP	Random


;-----------------------------------------------------------------
; GET_RANDOM_MASK - returns an AND value that is large enough that it
; encloses the 'maxval' parameter.
;
; int Get_Random_Mask(int maxval);
;
;*

	PROC	Get_Random_Mask C near
	USES	ecx
	ARG	maxval:DWORD

; This function takes as a parameter a maximum value, for example, 61.  It
; then tries to create an AND mask that is big enough to enclose that number.
; For our example case, that AND mask would be 0x3F.  It does this by scanning
; for the highest bit in the number, then making an all-1's mask from that
; bit position down to bit 0.
	bsr	ecx,[maxval]		; put bit position of highest bit in ecx
	mov	eax,1			; set one bit on in eax
	jz	??invalid		; if BSR shows maxval==0, return eax=1
	inc	ecx			; get one bit higher than count showed
	shl	eax,cl			; move our EAX bit into position
	dec	eax			; dec it to create the mask.
??invalid:
	ret
	ENDP	Get_Random_Mask
;----------------------------------------------------------------------------

	END
