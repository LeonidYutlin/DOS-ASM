.model tiny
.code
org 100h

Start:
	mov bx, 0b800h
	push bx
	pop es

	mov bx, (5 * 80d + 40d) * 2
	mov ah, 4eh
	Continue:
		in al, 60h
		mov es:[bx], ax
		cmp al, 1
		jne Continue

	mov ax, 4c00h
	int 21h
end Start