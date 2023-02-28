;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood Library                         *
;*                                                                         *
;*                    File Name : CRC.ASM                                  *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : June 12, 1992                            *
;*                                                                         *
;*                  Last Update : February 10, 1995 [BWG]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

GLOBAL    C Calculate_CRC    :NEAR

    CODESEG

PROC    Calculate_CRC C near

USES    esi
    
        LOCAL crc:dword

        ARG    buffer:dword
        ARG    len:dword
        
        ; Load pointer to data block.
        mov    [crc],0
        pushad
        mov    esi,[buffer]
        cld
    
        ; Clear CRC to default (NULL) value.
        xor    ebx,ebx
    
        ; Fetch the length of the data block to CRC.       
        mov    ecx,[len]
        jecxz    short fini
    
        ; Prepare the length counters.
        mov    edx,ecx
        and    dl,011b
        shr    ecx,2
    
        ; Perform the bulk of the CRC scanning.
        jecxz    short remainder2
    accumloop:
        lodsd
        rol    ebx,1
        add    ebx,eax
        loop    accumloop
    
        ; Handle the remainder bytes.
    remainder2:
        or    dl,dl
        jz    short fini
        mov    ecx,edx
        xor    eax,eax
    
        and     ecx,0FFFFh
        push    ecx
    nextbyte:
        lodsb
        ror    eax,8
        loop    nextbyte
        pop    ecx
        neg    ecx
        add    ecx,4
        shl    ecx,3
        ror    eax,cl
    
    ;nextbyte:
    ;    shl    eax,8
    ;    lodsb
    ;    loop    nextbyte
        rol    ebx,1
        add    ebx,eax
    
    fini:
        mov    [crc],ebx
        popad
        mov    eax,[crc]
        ret
    ENDP Calculate_CRC
    
END
