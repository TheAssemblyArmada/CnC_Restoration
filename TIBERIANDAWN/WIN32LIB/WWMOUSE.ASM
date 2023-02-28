IDEAL
P386
MODEL USE32 FLAT

LOCALS ??

GLOBAL C Get_Shape_Uncomp_Size : NEAR
GLOBAL C Get_Shape_Width : NEAR
GLOBAL C Get_Shape_Original_Height : NEAR
GLOBAL C LCW_Uncompress : NEAR
GLOBAL C ShapeBuffer:DWORD

struc Shape_Type
	ShapeType      dw   ?
	Height         db   ?
	Width          dw   ?
	OriginalHeight db	?
	Size           dw	?
	DataLength     dw	?
	Colortable     db	16 dup (?)
ends Shape_Type

MAKESHAPE_NORMAL		EQU	0
MAKESHAPE_COMPACT		EQU	1
MAKESHAPE_NOCOMP		EQU	2
MAKESHAPE_VARIABLE	    EQU	4

INCLUDE "GBUFFER.INC"
INCLUDE "MOUSE.INC"

GLOBAL C Draw_Mouse:NEAR
GLOBAL C Mouse_Shadow_Buffer:NEAR
GLOBAL C ASM_Set_Mouse_Cursor:NEAR

CODESEG

    PROC Mouse_Shadow_Buffer C NEAR
    USES eax,ebx,ecx,edx,edi,esi

    ARG mouse   :DWORD
    ARG viewport:DWORD
    ARG buffer  :DWORD
    ARG x       :DWORD
    ARG y       :DWORD
    ARG hotx    :DWORD
    ARG hoty    :DWORD
    ARG store   :DWORD

    LOCAL x_pixel :DWORD
    LOCAL y_pixel :DWORD
    LOCAL x1_pixel:DWORD
    LOCAL y1_pixel:DWORD
    LOCAL scr_x   :DWORD
    LOCAL cursor  :DWORD
    
                cld;not sure if compiler doesn't make this
                mov     esi, [mouse]

                mov     edi, [viewport]

                mov     eax, [x]
                mov     ebx, [y]
                sub     eax, [hotx]
                sub     ebx, [hoty]

                mov     [x_pixel], eax
                mov     [y_pixel], ebx

                add     eax, [esi+MouseType.CursorWidth]
                add     ebx, [esi+MouseType.CursorHeight]

                mov     [x1_pixel], eax
                mov     [y1_pixel], ebx

                mov     [scr_x], 0

                mov     eax, [buffer]
                mov     [cursor], eax

                xor     eax, eax
                xor     edx, edx

                mov     ecx, [x_pixel]
                mov     ebx, [x1_pixel]
                shld    eax, ecx, 1
                shld    edx, ebx, 1

                mov     ecx, [x_pixel]
                mov     ebx, [x1_pixel]
                sub     ecx, [edi+GraphicViewPort.GVPWidth]
                sub     ebx, [edi+GraphicViewPort.GVPWidth]
                dec     ecx
                dec     ebx
                shld    eax, ecx, 1
                shld    edx, ebx, 1

                mov     ecx, [y_pixel]
                mov     ebx, [y1_pixel]
                shld    eax, ecx, 1
                shld    edx, ebx, 1

                mov     ecx, [y_pixel]
                mov     ebx, [y1_pixel]
                sub     ecx, [edi+GraphicViewPort.GVPHeight]
                sub     ebx, [edi+GraphicViewPort.GVPHeight]
                dec     ecx
                dec     ebx
                shld    eax, ecx, 1
                shld    edx, ebx, 1

                xor     al, 5
                xor     dl, 5
                mov     ah, al
                test    dl, al
                jnz     ??done

                or      al, dl
                jz      short ??do_blit

                ; do clipping if needed
                test    ah, 1000b
                jz      short ??left_ok

                mov     ebx, [x_pixel]
                neg     ebx
                mov     [scr_x], ebx
                mov     [x_pixel], 0

??left_ok:
                test    ah, 10b
                jz      short ??bottom_ok

                mov     ebx, [y_pixel]
                neg     ebx
                imul    ebx, [esi+MouseType.CursorWidth]
                add     [cursor], ebx
                mov     [y_pixel], 0


??bottom_ok:
                test    dl, 100b
                jz      short ??right_ok

                mov     eax, [edi+GraphicViewPort.GVPWidth]
                mov     [x1_pixel], eax


??right_ok:
                test    dl, 0001b
                jz      short ??do_blit

                mov     eax, [edi+GraphicViewPort.GVPHeight]
                mov     [y1_pixel], eax


??do_blit:
                ; do actual blitting
                mov     eax, [y_pixel]
                mov     edx, [edi+GraphicViewPort.GVPWidth]
                add     edx, [edi+GraphicViewPort.GVPXAdd]
                add     edx, [edi+GraphicViewPort.GVPPitch]
                imul    eax, edx
                add     eax, [x_pixel]
                mov     edi, [edi+GraphicViewPort.GVPOffset]
                add     edi, eax
                mov     ebx, [esi+MouseType.CursorWidth]
                mov     esi, [cursor]
                add     esi, [scr_x]
                mov     eax, [x1_pixel]
                mov     ecx, [y1_pixel]
                sub     eax, [x_pixel]
                jle     short ??done

                ; get how much on Y wen need to process
                sub     ecx, [y_pixel]
                jle     short ??done

                ; get by how much we need to incriment the buffers
                sub     edx, eax
                sub     ebx, eax
                
                push    ebp
                
                ; should we store or restore?
                cmp     [store], 1
                jz      short restore

                mov     ebp, ecx


store_loop:
				; store viewport to buffer
                mov     ecx, eax
                rep movsb
                add     esi, ebx
                add     edi, edx
                dec     ebp
                jnz     short store_loop

                pop     ebp

                ret

				; swap buffers
restore:
                xchg    esi, edi
                mov     ebp, ecx
				
				; restore from buffer to viewport
restore_loop:
                mov     ecx, eax
                rep movsb
                add     esi, edx
                add     edi, ebx
                dec     ebp
                jnz     short restore_loop

                pop     ebp


??done:
                ret

    ENDP Mouse_Shadow_Buffer
	
	
    PROC Draw_Mouse C near
    
    USES eax,ebx,ecx,edx,edi,esi
    
    ARG mouse   :DWORD
    ARG viewport:DWORD
    ARG hotx    :DWORD
    ARG hoty    :DWORD

    LOCAL x_pixel :DWORD
    LOCAL y_pixel :DWORD
    LOCAL x1_pixel:DWORD
    LOCAL y1_pixel:DWORD
    LOCAL scr_x   :DWORD
    LOCAL cursor  :DWORD

                mov     esi, [mouse]
                
                mov     edi, [viewport]
                
                mov     eax, [hotx]
                mov     ebx, [hoty]
                sub     eax, [esi+MouseType.MouseXHot]
                sub     ebx, [esi+MouseType.MouseYHot]
                
                mov     [x_pixel], eax
                mov     [y_pixel], ebx
                
                add     eax, [esi+MouseType.CursorWidth]
                add     ebx, [esi+MouseType.CursorHeight]
                
                mov     [x1_pixel], eax
                mov     [y1_pixel], ebx
                
                mov     [scr_x], 0
                
                mov     eax, [esi+MouseType.MouseCursor]
                mov     [cursor], eax
                
                xor     eax, eax
                xor     edx, edx
                
                mov     ecx, [x_pixel]
                mov     ebx, [x1_pixel]
                shld    eax, ecx, 1
                shld    edx, ebx, 1
                
                mov     ecx, [x_pixel]
                mov     ebx, [x1_pixel]
                sub     ecx, [edi+GraphicViewPort.GVPWidth]
                sub     ebx, [edi+GraphicViewPort.GVPWidth]
                dec     ecx
                dec     ebx
                shld    eax, ecx, 1
                shld    edx, ebx, 1
                
                mov     ecx, [y_pixel]
                mov     ebx, [y1_pixel]
                shld    eax, ecx, 1
                shld    edx, ebx, 1
                
                mov     ecx, [y_pixel]
                mov     ebx, [y1_pixel]
                sub     ecx, [edi+GraphicViewPort.GVPHeight]
                sub     ebx, [edi+GraphicViewPort.GVPHeight]
                dec     ecx
                dec     ebx
                shld    eax, ecx, 1
                shld    edx, ebx, 1
                
                xor     al, 5
                xor     dl, 5
                mov     ah, al
                test    dl, al
                jnz     ??done
                
                ; do clipping if needed
                or      al, dl
                jz      short ??do_blit

                test    ah, 1000b
                jz      short ??left_ok

                mov     ebx, [x_pixel]
                neg     ebx
                mov     [scr_x], ebx
                mov     [x_pixel], 0

??left_ok:
                test    ah, 10b
                jz      short ??bottom_ok

                mov     ebx, [y_pixel]
                neg     ebx
                imul    ebx, [esi+MouseType.CursorWidth]
                add     [cursor], ebx
                mov     [y_pixel], 0


??bottom_ok:
                test    dl, 100b
                jz      short ??right_ok

                mov     eax, [edi+GraphicViewPort.GVPWidth]
                mov     [x1_pixel], eax


??right_ok:
                test    dl, 0001b
                jz      short ??do_blit

                mov     eax, [edi+GraphicViewPort.GVPHeight]
                mov     [y1_pixel], eax

                
??do_blit:
                ; do actual blitting
                mov     eax, [y_pixel]
                mov     edx, [edi+GraphicViewPort.GVPWidth]
                add     edx, [edi+GraphicViewPort.GVPXAdd]
                add     edx, [edi+GraphicViewPort.GVPPitch]
                imul    eax, edx
                add     eax, [x_pixel]
                mov     edi, [edi+GraphicViewPort.GVPOffset]
                add     edi, eax
                mov     ebx, [esi+MouseType.CursorWidth]
                mov     esi, [cursor]
                add     esi, [scr_x]
                mov     eax, [x1_pixel]
                mov     ecx, [y1_pixel]
                sub     eax, [x_pixel]
                jle     short ??done
                
                ; get how much on Y wen need to process
                sub     ecx, [y_pixel]
                jle     short ??done
                
                ; get by how much we need to incriment the buffers
                sub     edx, eax
                sub     ebx, eax

get_iter:
                ; get how much need to iteratate for this line
                mov     ah, al

copy_loop:
                mov     ch, [esi]
                inc     esi
                ; check if the pixel is transparent
                test    ch, ch
                ; if so get the next pixel
                jz      short next

                ; write pixel to buffer
                mov     [edi], ch

next:
                inc     edi
                dec     ah
                jnz     short copy_loop

                ; incriment the buffers
                add     esi, ebx
                add     edi, edx
                
                ; decriment the iterator
                dec     cl
                
                jnz     short get_iter


??done:
                ret

    ENDP Draw_Mouse
	
	
    PROC ASM_Set_Mouse_Cursor C near
    USES ebx,ecx,edx,esi,edi

    ARG mouse   :DWORD
    ARG xhotspot:DWORD
    ARG yhotspot:DWORD
    ARG cursor  :DWORD

    LOCAL datasize:DWORD
    LOCAL stype   : WORD 
    LOCAL swidth  :DWORD
    LOCAL sheight :DWORD
    LOCAL ssize   :DWORD

                cld
                mov     esi, [mouse]
                push    [cursor]
                call    Get_Shape_Uncomp_Size

                pop     edx
                
                mov     [datasize], eax
                push    [cursor]
                call    Get_Shape_Width

                pop     edx
                
                mov     [swidth], eax
                cmp     eax, [esi+MouseType.MaxWidth]
                jg      ??end

                push    [cursor]
                call    Get_Shape_Original_Height

                pop     edx
                
                mov     [sheight], eax
                cmp     eax, [esi+MouseType.MaxHeight]
                jg      ??end

                mov     ebx, [sheight]
                mov     eax, [swidth]
                imul    ebx, eax
                
                mov     edi, [esi+MouseType.MouseCursor]
                
                mov     esi, [cursor]
                
                ; is this a uncompressed shape
                mov     ax, [esi+Shape_Type.ShapeType]
                mov     [stype], ax
                test    ax, MAKESHAPE_NOCOMP
                jz      short ??comp_shape


loc_4DBDED:
                ; is this a compact shape with a color table
                test    [stype], MAKESHAPE_COMPACT
                jnz     short color_shape

                ; if so we need to offset the buffer
                add     esi, 10
                mov     eax, [swidth]
                mul     [sheight]
                mov     edx, eax
                xor     ecx, ecx


loc_4DBE02:
                mov     al, [esi]
                inc     esi
                or      al, al
                jz      short loc_4DBE14

                mov     [edi], al
                inc     edi
                dec     edx
                jnz     short loc_4DBE02

                jmp     ??done_copy

loc_4DBE14:
                mov     cl, [esi]
                sub     edx, ecx
                inc     esi
                xor     al, al
                rep stosb
                or      edx, edx
                jnz     short loc_4DBE02

                jmp     ??done_copy
               
color_shape:
                ; this is a compact shape meaning it countains a color table
                add     esi, 10 ; color table offset
                mov     ebx, esi
                add     esi, 16 ; color table entry count
                mov     eax, [swidth]
                mul     [sheight]
                mov     edx, eax
                xor     eax, eax
                xor     ecx, ecx


loc_4DBE3A:
                mov     al, [esi]
                inc     esi
                or      al, al
                jz      short loc_4DBE4C

                mov     al, [ebx+eax]
                mov     [edi], al
                inc     edi
                dec     edx
                jnz     short loc_4DBE3A

                jmp     short ??done_copy

loc_4DBE4C:
                mov     cl, [esi]
                sub     edx, ecx
                inc     esi
                xor     al, al
                rep stosb
                or      edx, edx
                jnz     short loc_4DBE3A

                jmp     short ??done_copy

??comp_shape:
                mov     edi, [ShapeBuffer]
                mov     ax, [esi+Shape_Type.ShapeType]
                add     esi, 2
                or      ax, MAKESHAPE_NOCOMP
                mov     [stype], ax
                mov     [edi], ax
                add     edi, 2
                mov     ecx, 4
                test    eax, MAKESHAPE_COMPACT
                jz      short ??uncomp

                add     ecx, 8

??uncomp:
                rep movsw
                mov     eax, [datasize]
                push    eax
                push    edi
                push    esi
                call    LCW_Uncompress

                pop     eax
                pop     eax
                pop     eax
                mov     esi, [mouse]
                mov     edi, [esi]
                mov     esi, [ShapeBuffer]
                jmp     loc_4DBDED

??done_copy:
                mov     esi, [mouse]
                mov     eax, [xhotspot]
                mov     [esi+MouseType.MouseXHot], eax
                
                mov     eax, [yhotspot]
                mov     [esi+MouseType.MouseYHot], eax
                
                mov     ebx, [sheight]
                mov     [esi+MouseType.CursorHeight], ebx
                
                mov     ebx, [swidth]
                mov     [esi+MouseType.CursorWidth], ebx


??end:
                push    [cursor]
                push    [esi+MouseType.PrevCursor]
                pop     eax
                pop     [esi+MouseType.PrevCursor]

                ret

    ENDP ASM_Set_Mouse_Cursor
	
END
