.model tiny
.code
org 100h
Start:
	mov ax, 0b800h
	mov es, ax ; es = 0b800h
	mov bx, 160d

	mov dx, 5d * 2d * 80d - 2d

	mov cx, APPLEDOG_LEN
	mov si, offset APPLEDOG + APPLEDOG_LEN - 1
	LOOP_BODY:
	mov bx, cx
	shl bx, 1
	add bx, dx
	mov di, [si]
	mov es:word ptr[bx], di
	mov es:byte ptr[bx + 1], 7ch
	dec si
	loop LOOP_BODY

	mov ax, 4c00h
	int 21h

APPLEDOG db 'Hello, I am an Appledog inside your computer! Bark :3'
APPLEDOG_LEN equ $-APPLEDOG

end Start
