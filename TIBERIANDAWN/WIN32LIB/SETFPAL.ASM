IDEAL
P386
MODEL USE32 FLAT


GLOBAL    C ColorXlat:BYTE
GLOBAL    C Set_Font_Palette_Range:NEAR

CODESEG

; void cdecl Set_Font_Palette_Range(void const *palette, INT start_idx, INT end_idx)

    PROC    Set_Font_Palette_Range C near
    USES    eax,ebx,ecx,edi,esi

    ARG    palette:DWORD
    ARG    start_idx:DWORD
    ARG    end_idx:DWORD

        cld
        mov esi, [palette]
        mov ebx, [start_idx]
        and ebx, 15
        mov ecx, [end_idx]
        and ecx, 15
        cmp ecx, ebx
        jl  short ??exit
        
        sub ecx, ebx
        inc ecx
        mov edi, OFFSET ColorXlat
        add edi, ebx
        shl ebx, 4
        add ebx, OFFSET ColorXlat

??setpal:
        lodsb
        stosb
        mov [ebx], al
        add ebx, 16
        dec ecx
        jnz short ??setpal
        
??exit:
        ret

    ENDP    Set_Font_Palette_Range

END
