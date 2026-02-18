.model tiny
.code
org 100h

Start:
mov ah, 09h
mov dx, offset HelloAppledog
int 21h
mov ax, 4c00h
int 21h

AnotherString db 'Hi i am an another string$'
HelloAppledog db 'Hello, I am an appledog! I live inside your DOSBOX, and i like to bark!', 0dh, 0ah, 'Bark!', 0dh, 0ah, '$'
end Start