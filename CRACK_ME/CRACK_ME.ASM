.model tiny
.code
org 100h

locals @@

;-------------
; Exit - macro that exits the program with a given exit code
; Destr: AX
;-------------
Exit		macro exitCode
	mov ah, 4ch
	mov al, exitCode
	int 21h
		endm

;-------------
; Puts - macro that puts a string into stdout, using 09h'th DOS fn via int 21
; Destr: AX, DX
;-------------
Puts  		macro str
	mov ah, 09h
	lea dx, str
	int 21h
		endm

Start:
    Puts PROMPT_MSG

    mov ah, 0ah
    lea dx, BUFFER_START
    int 21h
    Puts Newline

    cld
    lea si, BUFFER_START + 1
    xor cx, cx
    mov cl, [si]
    lea si, BUFFER
    call hash
    lea si, PASSWORD_HASH_UPPER
    cmp bx, [si]
    jne @@INCORRECT
    lea si, PASSWORD_HASH_LOWER
    cmp dx, [si]
    jne @@INCORRECT

    @@CORRECT:
    Puts CORRECT_MSG
	Exit 0d

    @@INCORRECT:
    Puts INCORRECT_MSG
    Exit 0d

PROMPT_MSG    db 'Mirror mirror on the wall, who is the fairest of them all?', 0dh, 0ah, '$'
INCORRECT_MSG db 'Wrong!$'
TIMEOUT_MSG_1 db 'Try again in $'
TIMEOUT_MSG_2 db ' seconds', 0dh, 0ah, '$'
CORRECT_MSG   db 'Correct!', 0dh, 0ah, '$'
NEWLINE db 0dh, 0ah, '$'
PASSWORD_HASH_UPPER dw 05b96h
PASSWORD_HASH_LOWER dw 0bc0eh

BUFFER_START db 0ffh, 00h
BUFFER db 16 dup(?)

;-------------
;
; Input:
; Output:
; Destr:
; Expect:
;-------------

; Macros for Hash proc only!
SHL_ALL macro
    shl bx, 1
    shl dx, 1
    adc bx, 0h
endm

ADD_SELF_TO_ALL macro
	add dx, [bp - 2]
    adc bx, [bp - 4]
endm

;-------------
; Hash - calculates 32-bit hash of a CX bytes starting from SI
;        if CX = 0, nothing happens
; Input:  CX =  number of bytes
;         SI -> string of bytes
; Output: BX - higher 16 bits of a hash
;         DX - lower  16 bits of a hash
; Destr: AX, SI, CX, BP
; Expect: CLD
;-------------
Hash proc
    test cx, cx
    jnz @@START
    ret
    @@START:
    xor dx, dx
    xor bx, bx
    xor ah, ah
    mov bp, sp
    @@LOOP:
        push dx
        push bx
        ; hash *= 37
        shl_all
        shl_all
        shl_all
        add_self_to_all
        shl_all
        shl_all
        add_self_to_all
        add sp, 4

        ; hash += <next_char>
        lodsb
        add dx, ax
        adc bx, 0h
    loop @@LOOP
    ret
endp

end 	Start
