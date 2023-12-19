; for the checker
nop

; put program here

; exit program
mov ah, 0
int 16h
mov bx, 0x1000   
mov es, bx
mov bx, 0
jmp 0x1000:0000
