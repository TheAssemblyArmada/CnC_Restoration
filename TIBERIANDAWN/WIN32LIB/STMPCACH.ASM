IDEAL
P386
MODEL USE32 FLAT

LOCALS ??


STRUC IconSetType
    IconSetPtr dd ?
    IconListOffset dd ?
ENDS IconSetType

GLOBAL C IconSetList:DWORD
GLOBAL C IconCacheLookup:WORD

GLOBAL LastIconset:DWORD
GLOBAL StampPtr:DWORD
GLOBAL MapPtr:DWORD
GLOBAL IconSize:DWORD
GLOBAL IconCount:DWORD

GLOBAL C Init_Stamps:near
GLOBAL C Cache_New_Icon:near
GLOBAL C Get_Free_Cache_Slot:near
GLOBAL Cache_Copy_Icon_:NEAR
GLOBAL Is_Icon_Cached_:NEAR
GLOBAL Is_Stamp_Registered:NEAR

    DATASEG

IconData	DD	0
IconEntry	DD	0

    CODESEG

    PROC Cache_Copy_Icon_ near
    
        pusha
        mov esi, eax
        mov edi, edx
        sub ebx, 24
        mov dl, 24
        
cache:
        mov ecx, 6
        rep movsd
        lea edi, [edi+ebx]
        dec dl
        jnz short cache
    
        popa
        ret
	
	ENDP
	
	
    PROC Is_Icon_Cached_ near

        mov     [IconData], eax
        push    edx
        test    eax, eax
        jz      invalid

        cmp     [LastIconset], eax
        jz      short skip_init

        push    eax
        call    Init_Stamps

        add     esp, 4

skip_init:
        cmp     [MapPtr], 0
        jz      short from_ptr

        push    edi
        mov     edi, [MapPtr]
        mov     dl, [edi+edx]
        pop     edi


from_ptr:
        cmp     edx, [IconCount]
        jl      short is_registered

        pop     edx
        mov     eax, -1
        retn

is_registered:
        mov     eax, [IconData]
        call    Is_Stamp_Registered

        cmp     eax, -1
        jnz     short check_lookup

        pop     edx
        retn

check_lookup:
        mov     eax, [eax+IconSetType.IconListOffset]
        cmp     [IconCacheLookup+eax+edx*2], 65535
        jz      short make_entry

        movzx   eax, [IconCacheLookup+eax+edx*2]
        pop     edx
        retn

make_entry:
        mov     [IconEntry], eax
        add     [IconEntry], edx
        add     [IconEntry], edx
        call    Get_Free_Cache_Slot

        test    eax, eax
        jge     short cache_new

        pop     edx
        retn

cache_new:
        imul    edx, [IconSize]
        add     edx, [StampPtr]
        push    eax
        call    Cache_New_Icon

        test    eax, eax
        jz      short cache_failed

        pop     eax
        mov     edx, [IconEntry]
        mov     [IconCacheLookup+edx], ax
        and     eax, 65535
        pop     edx
        retn

cache_failed:
        pop     eax


invalid:
        pop     edx
        mov     eax, -1
        retn

    ENDP
	
	
    PROC Is_Stamp_Registered near
        push edi
        push ecx
        mov edi, offset IconSetList
        mov ecx, 100

search:
        cmp eax, [edi+IconSetType.IconSetPtr]
        jz  short exit

        add edi, size IconSetType
        dec ecx
        jnz short search

        mov eax, -1
        pop ecx
        pop edi
        retn

exit:
        mov eax, edi
        pop ecx
        pop edi
        ret
	
	ENDP
	
END
