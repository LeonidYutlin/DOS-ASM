.model tiny
.code
org 100h

locals @@

VIDEOSEG   equ 0b800h
ROW_LEN    equ 80d
CMD_LINE   equ 80h
LINE_N     equ 7d
SHIFT      equ 15d
F_VER      equ 0bah ; ║
F_HOR      equ 0cdh ; ═
F_UR       equ 0bbh ; ╗
F_UL       equ 0c9h ; ╔
F_DR       equ 0bch ; ╝
F_DL       equ 0c8h ; ╚
F_WS       equ ' '
PAD_HOR    equ 2d
PAD_VER    equ 1d
BACKGROUND equ 79h
TEXT_COLOR equ 7ch

Start:
	mov ax, 3509h
	int 21h
	mov OriginalOffset, bx
	mov bx, es
	mov OriginalSegment, bx

	xor ax, ax
	push ax
	pop es

 	cli
	mov bx, 09h * 4
	mov es:[bx], offset Handler
	mov ax, cs
	mov es:[bx + 2], ax
	sti

	mov ax, 3100h
	mov dx, offset EOP
	shr dx, 4
	inc dx
	int 21h

Handler proc
	push ax
	push bx
	push es
	push cx
	push dx
	push si
	push di

	in al, 60h
	cmp al, 3d
	jne Original

	mov bx, VIDEOSEG
	push bx
	pop es

	mov dx, ((LINE_N + PAD_VER + 2) * ROW_LEN + SHIFT + PAD_HOR + 1) * 2d
	mov bx, offset MSG
	mov cl, MSGLEN ; command line length
	mov si, bx
	add si, cx
	dec cl ; skip first space
	call RenderString

	;in al, 61h
	;or al, 80h
	;out 61h, al
	;and al, not 80h
	;out 61h, al
	;mov al, 20h
	;out 20h, al

	Original:

	pop di
	pop si
	pop dx
	pop cx
	pop es
	pop bx
	pop ax

	;iret

	db 0eah ; JMP FAR

	OriginalOffset dw 0
	OriginalSegment dw 0

	endp

MSG db 'I have been summoned'
MSGLEN equ $ - MSG

;-------------
; RenderFrame - renders CX by AX bytes from SI
;		 to ES starting from pos DX,
;		 with BACKGROUND color attribute
; Input:  AX =  height
;         CX =  length
;         DX =  vram offset in bytes
; Destr:  BX, DI, SI, CX, AX, DX
;-------------
RenderFrame 	proc
	test cx, cx
	jz @@EXIT
	test ax, ax
	jz @@EXIT

	; dx += ax * 160
	mov bx, ax
	shl bx, 5
	mov di, bx
	shl di, 2
	add bx, di
	add dx, bx

	push cx
	mov cx, ax
	mov al, 2
	@@LOOP_LINES:
		push cx ; save ax'ed cx
		mov bx, sp
		add bx, 2
		mov cx, [bx]; retrieve arg cx to cx
		call RenderFrameLine

		cmp al, 1
		je @@DONT_SET
		mov al, 1 ; switch to middle mode

		@@DONT_SET:
		sub dx, ROW_LEN * 2 ; go one line up
		pop cx ; restore ax'ed cx

		cmp cx, 2 ; check if it is time to change the frame to bottom mode
		jne @@LOOP_CHECK
		mov al, 0

		@@LOOP_CHECK:
			loop @@LOOP_LINES
	add sp, 2

	@@EXIT:
		ret
		        endp

; MACRO for RenderFrameLine's repeated code
; isn't meant for use outside RenderFrameLine
RenderLineMode macro firstSymbol, middleSymbol, lastSymbol, loopName
		mov es:word ptr[bx],     firstSymbol
		mov es:byte ptr[bx + 1], BACKGROUND
		sub bx, 2
		sub cx, 2
		loopName:
			mov es:word ptr[bx],     middleSymbol
			mov es:byte ptr[bx + 1], BACKGROUND
			sub bx, 2
			loop loopName
		mov es:word ptr[bx],     lastSymbol
		mov es:byte ptr[bx + 1], BACKGROUND
		jmp @@EXIT
		   endm

;-------------
; RenderFrameLine - renders a line of CX bytes
;		 to ES starting from pos DX,
;		 with BACKGROUND color attribute
; Input:  AL =  frame part:
;		0 = top,
;		1 = middle,
;		2 = bottom,
;	        other = space-filled line
;         CX =  number of bytes to render
;         DX =  vram offset in bytes
; Destr:  BX, CX
;-------------
RenderFrameLine	proc
	test cx, cx
	jnz @@SKIP_RET
	ret ; too far to JMP to @@EXIT (govnocode)
	@@SKIP_RET:
	mov bx, cx
	dec bx
	shl bx, 1
	add bx, dx
	test al, al
	jz @@TOP
	cmp al, 1
	je @@MIDDLE
	cmp al, 2
	je @@BOTTOM
	jmp @@SPACE_FILLED
	@@TOP:
		RenderLineMode F_UR, F_HOR, F_UL,  @@LOOP_BODY_T
	@@MIDDLE:
		RenderLineMode F_VER, F_WS, F_VER, @@LOOP_BODY_M
	@@BOTTOM:
		RenderLineMode F_DR, F_HOR, F_DL,  @@LOOP_BODY_B
	@@SPACE_FILLED:
		RenderLineMode F_WS, F_WS, F_WS,   @@LOOP_BODY_S
	@@EXIT:
		ret
		endp

;-------------
; RenderString - renders CX bytes from SI
;		 to ES starting from pos DX,
;		 with TEXT_COLOR color attribute
; Input:  SI -> string to render
;         CX =  number of bytes to render
;         DX =  vram offset in bytes
; Destr:  BX, DI, SI, CX
;-------------
RenderString	proc
	test cx, cx
	jz @@EXIT
	mov bx, cx
	dec bx
	shl bx, 1
	add bx, dx
	@@LOOP_BODY:
		mov di, [si]
		mov es:word ptr[bx], di
		mov es:byte ptr[bx + 1], TEXT_COLOR
		dec si
		sub bx, 2
		loop @@LOOP_BODY
	@@EXIT:
		ret
		endp

EOP:

end Start
