IDEAL
P386
MODEL USE32 FLAT

CODESEG

global C Reverse_Long : NEAR
PROC Reverse_Long C near

	ARG	number:DWORD

    mov	eax,[number]
    xchg	al,ah
    ror	eax,16
    xchg	al,ah
    ret
        
    ENDP
    
global C Reverse_Short : NEAR
PROC Reverse_Short C near

	ARG	number:WORD

    mov	ax,[number]
    xchg	ah,al
    ret
ENDP

global C Swap_Long : NEAR
PROC Swap_Long C near

    ARG	number:DWORD

    mov	eax,[number]
    ror	eax,16
    ret
ENDP

END