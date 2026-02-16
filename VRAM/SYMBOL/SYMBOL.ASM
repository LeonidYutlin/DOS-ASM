.model tiny
.code
org 100h
Start:
	mov ax, 0b800h
	mov es, ax ; es = 0b800h
	mov bx, 0
	mov es:byte ptr[bx], 05h ; using bx as an offset in es's segment,
				 ; set the vram symbol to 05h
	mov es:byte ptr[bx + 1], 25h

	mov ax, 4c00h
	int 21h

end Start