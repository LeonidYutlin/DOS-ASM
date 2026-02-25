.model tiny
.code
org 100h

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
	
	in al, 60h
	cmp al, 3d
	jne Original

	mov bx, 0b800h
	push bx
	pop es

	mov bx, (5 * 80d + 40d) * 2
	mov ah, 05h
	mov al, 03h
	mov es:[bx], ax

	;in al, 61h
	;or al, 80h
	;out 61h, al
	;and al, not 80h
	;out 61h, al
	;mov al, 20h
	;out 20h, al

	Original:	

	pop es
	pop bx
	pop ax

	;iret

	db 0eah ; JMP FAR

	OriginalOffset dw 0
	OriginalSegment dw 0	

	endp

EOP:

end Start
