;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood 32 Bit Library		   *
;*                                                                         *
;*                    File Name : GBUFFER.INC                              *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : May 26, 1994                             *
;*                                                                         *
;*                  Last Update : May 26, 1994   [PWG]                     *
;*                                                                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

;******************************************************************************
; Much testing was done to determine that only when there are 14 or more bytes
; being copied does it speed the time it takes to do copies in this algorithm.
; For this reason and because 1 and 2 byte copies crash, is the special case
; used.  SKB 4/21/94.  Tested on 486 66mhz.  Copied by PWG 6/7/04.
OPTIMAL_BYTE_COPY	equ	14

struc GraphicViewPort
GVPOffset		DD		?		; offset to virtual viewport
GVPWidth			DD		?		; width of virtual viewport
GVPHeight		DD		?		; height of virtual viewport
GVPXAdd			DD		?		; x mod to get to next line
GVPXPos			DD		?		; x pos relative to Graphic Buff
GVPYPos			DD		?		; y pos relative to Graphic Buff
GVPPitch		dd		?		; modulo of graphic view port
GVPBuffPtr		DD		?		; ptr to associated Graphic Buff
ends GraphicViewPort