.model tiny
.code
org 100h

LEN equ 30d
START_POS equ (7 * 80 + 25d) * 2
UNHIGHLIGHTED equ 0bh
HIGHLIGHTED equ 0ch

Start:
	mov bx, 0b800h
	push bx
	pop es

	mov bx, START_POS
	mov ah, UNHIGHLIGHTED
	jmp FirstCycle
	Continue:
		in al, 60h
		cmp al, cl
		je Continue
		jmp NonFirstCycle
		FirstCycle:
		in al, 60h
		NonFirstCycle:
		mov ah, UNHIGHLIGHTED
		mov es:[bx + 1], ah
		add bx, 2
		cmp bx, START_POS + LEN * 2
		jna NoModReset
		mov bx, START_POS
		NoModReset:
		mov cl, al
		mov ah, HIGHLIGHTED
		mov es:[bx], ax
		cmp al, 1
		jne Continue

	mov ax, 4c00h
	int 21h
end Start