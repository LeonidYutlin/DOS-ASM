.model tiny
.code
org 100h

locals @@

VIDEOSEG   equ 0b800h
ROW_LEN    equ 80d
MAX_LINE   equ 25d
LINE_N     equ 4d
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
MSG_LENGTH_TOTAL equ 3 + 4
MSG_LINES_TOTAL equ (MSG_LEN + 1) / (MSG_LENGTH_TOTAL + 1)
MSG_LINES_TOTAL_PADDED equ MSG_LINES_TOTAL + (PAD_VER + 1) * 2
MSG_LENGTH_TOTAL_PADDED equ	MSG_LENGTH_TOTAL + (PAD_HOR + 1) * 2 ; we add padding to 'XX FFFF'


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
	mov es:[bx], offset KeyHandler
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
	push ss
	push es
	push ds
	push sp
	push bp
	push di
	push si
	push dx
	push cx
	push bx
	push ax
	pushf
	endm

UpdatePopRegs macro
	popf ; pomoysya
	pop ax
	pop bx
	pop cx
	pop dx
	pop si
	pop di
	pop bp
	pop sp
	pop ds
	pop es
	pop ss
	endm

Switch db 0
Position dw (LINE_N * ROW_LEN + SHIFT) * 2
Background db 79h
TextColor db 7ch

UpdateHandler proc
	UpdatePushRegs

	push cs
	pop ds

	lea bx, Switch
	cmp byte ptr [bx], 1
	jne @@Original

	mov bx, VIDEOSEG
	push bx
	pop es

	cld
	lea bx, Position
	mov di, [bx]
	mov ax, MSG_LINES_TOTAL_PADDED
	mov cx, MSG_LENGTH_TOTAL_PADDED
	call RenderFrame

	mov cx, 14
	mov bx, sp
	lea di, MSG + 3
	@@ModifyMsgLoop:
	mov ax, ss:[bx]
	push cx
	push bx
	call Int16ToHex
	pop bx
	mov [di],     cx
	mov [di + 2], ax
	add di, MSG_LENGTH_TOTAL + 1 ; + 1 for '$'
	add bx, 2
	pop cx
	loop @@ModifyMsgLoop

	mov di, ((PAD_VER + 1) * ROW_LEN + PAD_HOR + 1) * 2
	lea bx, Position
	add di, [bx]
	mov cx, MSG_LEN
	lea si, MSG
	call RenderStringEscaped

	@@Original:

	UpdatePopRegs

	;iret

	db 0eah ; JMP FAR

	Original08Offset dw 0
	Original08Segment dw 0
endp

KeyPushRegs macro
	push ds
	push bx
	push ax
	push cx
	endm

KeyPopRegs macro
	pop cx
	pop ax
	pop bx
	pop ds
	endm

IsCtrlDown db 0

KeyHandler proc
	KeyPushRegs

	push cs
	pop ds

	in al, 60h

	cmp al, 1dh ; Ctrl Pressed Down
	jne @@NotCtrlDown
	lea bx, IsCtrlDown
	mov byte ptr [bx], 1
	jmp @@JMP_CHAIN_Original
	@@NotCtrlDown:
	cmp al, 1dh + 128d ; Ctrl Unpressed
	jne @@NotCtrlUp
	lea bx, IsCtrlDown
	mov byte ptr [bx], 0
	jmp @@JMP_CHAIN_Original
	@@NotCtrlUp:

	lea bx, IsCtrlDown
	cmp byte ptr [bx], 1
	jne @@JMP_CHAIN_Original

	cmp al, 23h ; 'H'
	jne @@NotH
	lea bx, Background
	inc byte ptr [bx]
	jmp @@Consume
	@@NotH:

	cmp al, 24h ; 'J'
	jne @@NotJ
	lea bx, Background
	dec byte ptr [bx]
	jmp @@Consume
	@@NotJ:

	cmp al, 25h ; 'K'
	jne @@NotK
	lea bx, TextColor
	inc byte ptr [bx]
	jmp @@Consume
	@@NotK:

	cmp al, 26h ; 'L'
	jne @@NotL
	lea bx, TextColor
	dec byte ptr [bx]
	jmp @@Consume
	@@NotL:

	cmp al, 12h ; 'E'
	je @@SwitchKey
	cmp al, 48h ; Up Arrow Key
	je @@MoveUpKey
	cmp al, 50h ; Down Arrow Key
	je @@MoveDownKey
	cmp al, 4bh ; Left Arrow Key
	je @@MoveLeftKey
	cmp al, 4dh ; Right Arrow Key
	je @@MoveRightKey
	jmp @@Original

	@@MoveLeftKey:
		lea bx, Position
		mov cx, [bx]
		test cx, cx
		jz @@Original
		sub word ptr [bx], 2
		jmp @@Consume

	@@MoveRightKey:
		lea bx, Position
		cmp word ptr [bx], ((MAX_LINE - MSG_LINES_TOTAL_PADDED + 1) * ROW_LEN - MSG_LENGTH_TOTAL_PADDED) * 2
		je @@Original
		add word ptr [bx], 2
		jmp @@Consume

	@@JMP_CHAIN_Original:
	jmp @@Original

	@@MoveUpKey:
		lea bx, Position
		cmp word ptr [bx], ROW_LEN * 2
		jb @@Original
		sub word ptr [bx], ROW_LEN * 2
		jmp @@Consume

	@@MoveDownKey:
		lea bx, Position
		cmp word ptr [bx], (MAX_LINE - MSG_LINES_TOTAL_PADDED) * ROW_LEN * 2
		jae @@Original
		add word ptr [bx], ROW_LEN * 2
		jmp @@Consume

	@@SwitchKey:
		lea bx, Switch
		cmp byte ptr [bx], 0
		jne @@TurnOff
		mov Switch, 1
		jmp @@Consume
		@@TurnOff:
			mov Switch, 0
		jmp @@Consume

	@@Consume:

	in al, 61h
	or al, 80h
	out 61h, al
	and al, not 80h
	out 61h, al
	mov al, 20h
	out 20h, al

	KeyPopRegs
	iret

	@@Original:

	KeyPopRegs

	db 0eah ; JMP FAR

	Original09Offset dw 0
	Original09Segment dw 0

	endp

MSG db 'FL 0000$AX 0000$BX 0000$CX 0000$DX 0000$SI 0000$DI 0000$BP 0000$SP 0000$DS 0000$SS 0000$ES 0000$IP 0000$CS 0000'
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
;		 with Background color attribute
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
	push bx
	lea bx, Background
	mov al, [bx]
	pop bx
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
; RenderStringEscaped - renders CX bytes from SI
;		 to ES starting from pos DX,
;		 with TEXT_COLOR color attribute.
;		 When encounters '$' character,
;		 shifts in vram by one line down,
;		 effectively mimicking a newline escape
; Input:  SI -> string to render
;         CX =  number of bytes to render
;         DI =  vram offset in bytes
; Destr:  BX, DI, SI, CX
; Expect: CLD
;-------------
RenderStringEscaped	proc
	test cx, cx
	jz @@EXIT
	lea bx, TextColor
    mov ah, [bx]
	push di
	@@LOOP_BODY:
                lodsb
				cmp al, '$'
				jne @@RENDER_CHAR
				pop di
				add di, ROW_LEN * 2
				push di
				jmp @@SKIP_RENDER_CHAR
				@@RENDER_CHAR:
                stosw
				@@SKIP_RENDER_CHAR:
		loop @@LOOP_BODY
	pop di
	@@EXIT:
		ret
		endp

HEX_ALPHA db '0123456789ABCDEF'

;-------------
; Int16ToHex - takes int16 at AX and converts it to
;			  it's 4 char long hex code
; Input:	AX = int16 to convert
; Output:	AH = first hex byte
;			AL = second hex byte
;			CH = third hex byte
;			CL = fourth hex byte
; Destr:    BX
;-------------
Int16ToHex	proc
		push ax
		mov ah, al
		shr al, 4
		and ah, 0fh

		mov bx, offset HEX_ALPHA
		add bl, al
		mov al, [bx]

		mov bx, offset HEX_ALPHA
		add bl, ah
		mov ah, [bx]
		pop cx
		mov cl, ch
		shr cl, 4
		and ch, 0fh

		mov bx, offset HEX_ALPHA
		add bl, cl
		mov cl, [bx]

		mov bx, offset HEX_ALPHA
		add bl, ch
		mov ch, [bx]
		ret
		endp


EOP:

end Start
