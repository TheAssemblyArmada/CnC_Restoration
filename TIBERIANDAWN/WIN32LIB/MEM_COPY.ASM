IDEAL
P386
MODEL USE32 FLAT

GLOBAL    C Mem_Copy    :NEAR

CODESEG

; void __cdecl Mem_Copy(const void *source, void *dest, unsigned int bytes)
PROC Mem_Copy C near
USES ecx,esi,edi,ebx

ARG source:DWORD
ARG dest:DWORD
ARG bytes:DWORD

    cld
    mov     esi, [source]
    mov     edi, [dest]
    mov     ecx, [bytes]
    cmp     esi, edi
    jz      short done

    or      esi, 0
    jz      short done

    or      edi, 0
    jz      short done

    cmp     ecx, 14
    jge     short backward

    cmp     esi, edi
    jge     short simple

    lea     esi, [esi+ecx-1]
    std
    lea     edi, [edi+ecx-1]

simple:
    rep movsb
    cld

done:
    ret

backward:
    mov     ebx, ecx
    cmp     esi, edi
    jge     short forward
    
    lea     ecx, [edi+ebx]
    std
    lea     edi, [edi+ebx-1]
    and     ecx, 3
    lea     esi, [esi+ebx-1]
    sub     ebx, ecx
    rep movsb
    
    sub     esi, 3
    mov     ecx, ebx
    sub     edi, 3
    shr     ecx, 2
    rep movsd
    
    mov     ecx, ebx
    add     esi, 3
    add     edi, 3
    and     ecx, 3
    rep movsb
    cld

    ret

forward:
    cld
    
    mov     ecx, edi
    neg     ecx
    and     ecx, 3
    sub     ebx, ecx
    rep movsb
    
    mov     ecx, ebx 
    shr     ecx, 2
    rep movsd
    mov     ecx, ebx
    and     ecx, 3
    
    rep movsb

    ret

ENDP Mem_Copy

END