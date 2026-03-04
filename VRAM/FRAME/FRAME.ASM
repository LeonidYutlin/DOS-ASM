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

;-------------
; Exit - macro that exits the program with a given exit code
; Destr: AX
;-------------
Exit		macro exitCode
	mov ah, 4ch
	mov al, exitCode
	int 21h
		endm

Start:
	mov bx, CMD_LINE
	xor ch, ch
	mov cl, [bx] ; command line length
	test cl, cl
	jz MISUSAGE

	mov ax, VIDEOSEG
	mov es, ax

	cld
	mov di, (LINE_N * ROW_LEN + SHIFT) * 2d ;
	mov ax, (PAD_VER + 1) * 2d + 1 ; we add padding and one line for text
	add cx, (PAD_HOR + 1) * 2d - 1 ; we add padding and remove the space
	call RenderFrame

	mov di, ((LINE_N + PAD_VER + 2) * ROW_LEN + SHIFT + PAD_HOR + 1) * 2d
	mov bx, CMD_LINE
	xor ch, ch
	mov cl, [bx] ; command line length
	mov si, bx
	add si, cx
	dec cl ; skip first space
	call RenderString

	;mov di, ((LINE_N + PAD_VER + 6) * ROW_LEN + SHIFT + PAD_HOR + 1) * 2d
	;mov bx, CMD_LINE
	;mov cl, [bx] ; command line length
	;mov si, bx
	;add si, cx
	;dec cl ; skip first space
	;call RenderHexBytes

	Exit 0d

	MISUSAGE:
	mov ah, 09h
	mov dx, offset USAGE
	int 21h
	Exit 1d

USAGE db 'Usage: frame <message>', 0ah, '$'

;-------------
;
; Input:
; Output:
; Destr:
; Expect:
;-------------

;-------------
; RenderFrame - renders CX by AX bytes from SI
;		 to ES starting from pos DX,
;		 with BACKGROUND color attribute
; Input:  AX =  height
;         CX =  length
;         DI =  vram offset in bytes
; Destr:  BX, DI, SI, CX, AX
;-------------
RenderFrame 	proc
	test cx, cx
	jz @@EXIT
	test ax, ax
	jz @@EXIT

	push cx
	mov cx, ax
	mov al, 0
	@@LOOP_LINES:
		push cx ; save ax'ed cx
		mov bx, sp
		add bx, 2
		mov cx, ss:[bx]; retrieve arg cx to cx
		push di
		call RenderFrameLine

		cmp al, 1
		je @@DONT_SET
		mov al, 1 ; switch to middle mode

		@@DONT_SET:
		pop di
		add di, ROW_LEN * 2 ; go one line down
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
;         DX =  vram offset in bytes
; Destr:  BX, DI, SI, CX
;-------------
RenderString	proc
	test cx, cx
	jz @@EXIT
	@@LOOP_BODY:
		mov bx, [si]
		mov es:word ptr[di], bx
		mov es:byte ptr[di + 1], TEXT_COLOR
		inc si
		add bx, 2
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
; Destr:  AX, BX, SI, CX
;-------------
RenderHexBytes	proc
	test cx, cx
	jz @@EXIT
	mov bx, cx
	dec bx
	shl bx, 1
	add bx, di
	@@LOOP_BODY:
		mov al, [si]
		push bx
		call CharToHex
		pop bx
		mov es:byte ptr[bx],     al
		mov es:byte ptr[bx + 1], TEXT_COLOR
		mov es:byte ptr[bx + 2], ah
		mov es:byte ptr[bx + 3], TEXT_COLOR
		dec si
		sub bx, 4
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

end 	Start
