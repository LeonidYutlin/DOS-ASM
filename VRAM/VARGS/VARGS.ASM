.model tiny
.code
org 100h

VIDEOSEG equ 0b800h
ROW_LEN  equ 80d
CMD_LINE equ 80h
LINE_N   equ 18d
SHIFT    equ 30d
 
Start:
	mov ax, VIDEOSEG
	mov es, ax

	mov dx, LINE_N * ROW_LEN * 2d + SHIFT * 2d

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
	mov es:byte ptr[bx + 1], 7ch
	dec si
	loop LOOP_BODY
	jmp EXIT

	MISUSAGE:
	mov ah, 09h
	mov dx, offset USAGE
	int 21h
	jmp EXIT

	EXIT:
	mov ax, 4c00h
	int 21h

USAGE db 'Usage: vargs <message>', 0ah, '$'
USAGE_LEN equ $ - USAGE

end Start
