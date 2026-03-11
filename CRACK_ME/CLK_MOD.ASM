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
    push cx
    push dx
    push ds

	in al, 60h
	cmp al, 5d
    jne @@SKIP
    mov cl, 10
    mov ah, 2dh
    int 21h
    cmp al, 0d
    jne @@FAILED
    mov ah, 2ch
    int 21h
    mov ah, 09h
    push cs
    pop ds
	lea dx, MSG
	int 21h
    jmp @@SKIP
    @@FAILED:
    mov ah, 2ch
    int 21h
    mov ah, 09h
    push cs
    pop ds
	lea dx, MSG_FAILED
	int 21h

    @@SKIP:

	;in al, 61h
	;or al, 80h
	;out 61h, al
	;and al, not 80h
	;out 61h, al
	;mov al, 20h
	;out 20h, al

    pop ds
    pop dx
    pop cx
	pop ax

	;iret

	db 0eah ; JMP FAR

OriginalOffset dw 0
OriginalSegment dw 0

	endp

MSG db 'Time Modified!!!!', 0ah, 0ah, '$'
MSG_FAILED db 'Time Modification Failed...', 0ah, 0ah, '$'

EOP:

end Start
