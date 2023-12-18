; to test the disk loader
nop
push 8000h
pop es
jmp start

putc:        
	mov ah, 0eh 
	int 10h     
ret      
    
puts:
	mov al, [es:di]
	cmp al, 0
	jne __puts__next
ret
__puts__next:
	call putc
	inc di
	jmp puts
start:   
	mov di, msg
	call puts
; exit program
mov ah, 0
int 16h
mov bx, 0x1000   
mov es, bx
mov bx, 0
jmp 0x1000:0000 
dat:
	msg db "hello world!", 10, 13, 0
