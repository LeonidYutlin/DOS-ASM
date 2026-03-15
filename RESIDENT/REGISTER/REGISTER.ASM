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
	mov Original09Offset, bx
	mov bx, es
	mov Original09Segment, bx

	mov ax, 3508h
	int 21h
	mov Original08Offset, bx
	mov bx, es
	mov Original08Segment, bx

	xor ax, ax
	push ax
	pop es

 	cli
	mov bx, 09h * 4
	mov es:[bx], offset SwitchHandler
	mov ax, cs
	mov es:[bx + 2], ax
	mov bx, 08h * 4
	mov es:[bx], offset UpdateHandler
	mov ax, cs
	mov es:[bx + 2], ax
	sti

	mov ax, 3100h
	mov dx, offset EOP
	shr dx, 4
	inc dx
	int 21h

UpdatePushRegs macro
	push ax
	push bx
	push es
	push cx
	push dx
	push si
	push di
	push ds
	push ss
	push bp
	endm

UpdatePopRegs macro
	pop bp
	pop ss
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop es
	pop bx
	pop ax
	endm

Switch db 0

UpdateHandler proc
	UpdatePushRegs

	push cs
	pop ds

	cmp Switch, 1
	jne @@Original

	mov bx, VIDEOSEG
	push bx
	pop es

	cld
	mov di, (LINE_N * ROW_LEN + SHIFT) * 2d ;
	mov ax, (PAD_VER + 1) * 2d + 1 ; we add padding and one line for text
	mov cx, MSG_LEN
	add cx, (PAD_HOR + 1) * 2d - 1 ; we add padding and remove the space
	call RenderFrame

	mov di, ((LINE_N + PAD_VER + 1) * ROW_LEN + SHIFT + PAD_HOR + 1) * 2d
	mov cx, MSG_LEN
	lea si, MSG
	call RenderString

	@@Original:

	UpdatePopRegs

	;iret

	db 0eah ; JMP FAR

	Original08Offset dw 0
	Original08Segment dw 0
endp

SwitchPushRegs macro
	push ds
	push bx
	push ax
	endm

SwitchPopRegs macro
	pop ax
	pop bx
	pop ds
	endm

SwitchHandler proc
	SwitchPushRegs

	in al, 60h
	cmp al, 3d
	jne @@Original

	push cs
	pop ds

	lea bx, Switch
	cmp byte ptr [bx], 0
	jne @@TurnOff
	mov Switch, 1
	jmp @@Original
	@@TurnOff:
		mov Switch, 0

	;in al, 61h
	;or al, 80h
	;out 61h, al
	;and al, not 80h
	;out 61h, al
	;mov al, 20h
	;out 20h, al

	@@Original:

	SwitchPopRegs

	;iret

	db 0eah ; JMP FAR

	Original09Offset dw 0
	Original09Segment dw 0

	endp

MSG db 'AX$BX$CX$DX$SI$DI'
MSG_LEN equ $ - MSG

;-------------
; RenderFrame - renders CX by AX bytes from SI
;		 to ES starting from pos DX,
;		 with BACKGROUND color attribute
; Input:  AX =  height
;         CX =  length
;         DI =  vram offset in bytes
; Destr:  BX, DI, SI, CX, AX, BP
; Expect: CLD
;-------------
RenderFrame 	proc
	test cx, cx
	jz @@EXIT
	test ax, ax
	jz @@EXIT
	mov bp, sp

	push cx
	mov bx, ROW_LEN
	inc bx
	sub bx, cx ; potential overflow here but no solution for now
	shl bx, 1 ; now bx contains how much we need to shift per iteration
	mov cx, ax
	mov al, 0
	@@LOOP_LINES:
		push cx ; save ax'ed cx
		mov cx, ss:[bp - 2]; retrieve arg cx to cx
		call RenderFrameLine

		cmp al, 1
		je @@DONT_SET
		mov al, 1 ; switch to middle mode

		@@DONT_SET:
		add di, bx
		pop cx ; restore ax'ed cx

		cmp cx, 2 ; check if it is time to change the frame to bottom mode
		jne @@LOOP_CHECK
		mov al, 2

		@@LOOP_CHECK:
			loop @@LOOP_LINES

	add sp, 2

	@@EXIT:
		ret
		        endp

FrameBits db F_UL, F_HOR, F_UR, F_VER, F_WS, F_VER, F_DL, F_HOR, F_DR, F_WS, F_WS, F_WS

;-------------
; RenderFrameLine - renders a line of CX bytes
;		 to ES starting from pos DX,
;		 with BACKGROUND color attribute
; Input:  AL =  frame part:
;		0 = top,
;		1 = middle,
;		2 = bottom,
;	        other = whitespace-filled line
;         CX =  number of bytes to render
;         DI =  vram offset in bytes
; Destr:  CX, AX, SI, DI
; Expect: CLD
;-------------
RenderFrameLine	proc
	test cx, cx
	jnz @@SKIP_RET
	ret ; too far to JZ to @@EXIT
	@@SKIP_RET:

	; set background color attributes
	xor ah, ah
	push di
	inc di

	push ax
	mov ax, BACKGROUND
	push cx
	rep stosw
	pop cx
	pop ax
	pop di

	; decide the mode
	cmp al, 2
	jna @@START_RENDER
	mov al, 3

	@@START_RENDER:
	mov si, offset FrameBits
	add si, ax
	shl ax, 1
	add si, ax
	mov al, [si] ; set to first symbol
	mov es:byte ptr[di], al
	add di, 2
	sub cx, 2 ; remove 2 cause we wont draw the first and the last symbol in a loop
	test cx, cx
	jz @@LAST
	inc si
	mov al, [si] ; set to middle symbol
	@@LOOP:
		mov es:byte ptr[di], al
		add di, 2
		loop @@LOOP
	@@LAST:
	inc si
	mov al, [si] ; set to last symbol
	mov es:byte ptr[di], al
	@@EXIT:
		ret
		endp

;-------------
; RenderString - renders CX bytes from SI
;		 to ES starting from pos DX,
;		 with TEXT_COLOR color attribute
; Input:  SI -> string to render
;         CX =  number of bytes to render
;         DI =  vram offset in bytes
; Destr:  BX, DI, SI, CX
; Expect: CLD
;-------------
RenderString	proc
	test cx, cx
	jz @@EXIT
        mov ah, TEXT_COLOR
	@@LOOP_BODY:
                lodsb
                stosw
		loop @@LOOP_BODY
	@@EXIT:
		ret
		endp

;-------------
; RenderHexBytes - renders CX bytes as hex codes from SI
;		 to ES starting from pos DX,
;		 with TEXT_COLOR color attribute
; Input:  SI -> string to render
;         CX =  number of bytes to render
;         DI =  vram offset in bytes
; Destr:  AX, SI, CX, DI
;-------------
RenderHexBytes	proc
	test cx, cx
	jz @@EXIT
	@@LOOP_BODY:
		mov al, [si]
		call CharToHex
		mov es:byte ptr[di],     al
		mov es:byte ptr[di + 1], TEXT_COLOR
		mov es:byte ptr[di + 2], ah
		mov es:byte ptr[di + 3], TEXT_COLOR
		inc si
		add di, 4
		loop @@LOOP_BODY
	@@EXIT:
		ret
		endp

HEX_ALPHA db '0123456789ABCDEF'

;-------------
; CharToHex - takes char at AL and converts it to
;			  it's 2-byte hex code (upper byte is stored in AH, lower in AL)
; Input:	AL = char to convert
; Output:	AH = first hex byte
;			AL = second hex byte
; Destr:    BX
;-------------
CharToHex	proc
		mov ah, al
		shr al, 4
		and ah, 0fh

		mov bx, offset HEX_ALPHA
		add bl, al
		mov al, [bx]

		mov bx, offset HEX_ALPHA
		add bl, ah
		mov ah, [bx]
		ret
		endp


EOP:

end Start
