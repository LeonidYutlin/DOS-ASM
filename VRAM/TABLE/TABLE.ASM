.model tiny
.code
org 100h

LINE         equ 3d
OFFSET__     equ 32d
SIZE__       equ 10h ; 16d
DIGIT_START  equ 30h
DIGIT_END    equ 39h
ALPHA        equ 40h ; 'A'

Start:
	mov ax, 0b800h
	mov es, ax ; es = 0b800h

	mov cx, SIZE__ ; top line counter
	mov ax, 0e00h + ALPHA + SIZE__ - 1 + DIGIT_START - DIGIT_END
	mov bx, LINE * 80d + OFFSET__
	add bx, cx
	shl bx, 1 ; * 2 for all the affromentioned
	LOOP_TOP_LINE:
	test al, ALPHA - 1 ; test for the char before 'A'
	jnz NO_CHANGE_TOP_LINE
	mov al, DIGIT_END  ; if so, change it to '9'
	NO_CHANGE_TOP_LINE:
	mov es:word ptr[bx], ax
	sub bx, 2d
	dec al
	loop LOOP_TOP_LINE

	mov cx, SIZE__ ; top line counter
	mov ax, 0e00h + ALPHA + SIZE__ - 1 + DIGIT_START - DIGIT_END
	mov bx, LINE
	add bx, cx
	shl bx, 4
	mov dx, bx
	shl dx, 2
	add bx, dx
	add bx, OFFSET__
	shl bx, 1 ; * 2 for all the affromentioned
	LOOP_SIDE_LINE:
	test al, ALPHA - 1
	jnz NO_CHANGE_SIDE_LINE
	mov al, DIGIT_END
	NO_CHANGE_SIDE_LINE:
	mov es:word ptr[bx], ax
	sub bx, 2d * 80d
	dec al
	loop LOOP_SIDE_LINE

	mov cx, SIZE__ * SIZE__ ; table counter
	; we will divide by 16 and decide from there
	LOOP_BODY:
	mov bx, (LINE + 1) * 2d * 80d + (OFFSET__ + 1) * 2d ; base pos
	mov ax, cx
	mov dx, SIZE__
	div dl       ; al is ax / dx, ah is ax % dx
	shl ax, 1
	add bl, ah
	xor ah, ah
	shl ax, 4
	mov dx, ax
	shl dx, 2
	add ax, dx   ; this whole baloney is al * 80d :)
	add bx, ax
	mov es:byte ptr[bx], 04h
	mov es:byte ptr[bx + 1], cl
	loop LOOP_BODY

	mov ax, 4c00h
	int 21h

end Start
