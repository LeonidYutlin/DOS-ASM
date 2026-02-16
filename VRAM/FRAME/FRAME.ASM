.model tiny
.code
org 100h

locals @@

VIDEOSEG   equ 0b800h
ROW_LEN    equ 80d
CMD_LINE   equ 80h
LINE_N     equ 18d
SHIFT      equ 30d
F_VER      equ 0bah ; ║
F_HOR      equ 0cdh ; ═
F_UR       equ 0bbh ; ╗
F_UL       equ 0c9h ; ╔
F_DR       equ 0bch ; ╝
F_DL       equ 0c8h ; ╚
PADDING    equ 2d
BACKGROUND equ 7ch
TEXT_COLOR equ 7ch

;-------------
;
; Input:
; Output:
; Destr:
; Expect:
;-------------

;-------------
; RenderString - renders CX bytes from SI
;				 to ES starting from pos DX,
;				 with TEXT_COLOR color attribute
; Input:  SI -> string to render
;         CX =  number of bytes to render
;         DX =  vram offset in bytes
; Destr:  BX, DI, SI
;-------------
RenderString:
	proc
	test cx, cx
	jz EXIT
	@@LOOP_BODY:
		mov bx, cx
		dec bx
		shl bx, 1
		add bx, dx
		mov di, [si]
		mov es:word ptr[bx], di
		mov es:byte ptr[bx + 1], TEXT_COLOR
		dec si
		loop @@LOOP_BODY
	@@EXIT:
		ret
	endp

;-------------
; Exit - exits the program with AL as the exit code
; Input: AL = exit code
; Destr: AH
;-------------
Exit:
	proc
	mov ah, 4ch
	int 21h
	ret
	endp

Start:
	mov ax, VIDEOSEG
	mov es, ax

	mov dx, (LINE_N + 2) * ROW_LEN * 2d + (SHIFT + 2) * 2d

	mov bx, CMD_LINE
	mov cl, [bx] ; command line length
	mov si, CMD_LINE
	add si, cx
	test cl, cl
	jz MISUSAGE
	dec cl ; skip first space
	LOOP_BODY:
	mov bx, cx
	dec bx
	shl bx, 1
	add bx, dx
	mov di, [si]
	mov es:word ptr[bx], di
	mov es:byte ptr[bx + 1], TEXT_COLOR
	dec si
	loop LOOP_BODY
	jmp EXIT

	MISUSAGE:
	mov ah, 09h
	mov dx, offset USAGE
	int 21h
	jmp EXIT

	EXIT:
	mov ah, 4ch
	int 21h

USAGE db 'Usage: vargs <message>', 0ah, '$'
USAGE_LEN equ $ - USAGE

end Start
