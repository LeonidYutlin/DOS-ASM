.model tiny
.code
org 100h

Start:
mov ah, 09h
mov dx, offset Hello
int 21h
mov ax, 4c00h
int 21h

AnotherString db 'Hi i am an another string$'
Hello db 'Hello! I live inside your DOSBOX!', 0dh, 0ah, '$'
end Start