#fasm#         ; use flat assembler syntax
#make_boot#
org 7c00h      ; set location counter.    
 

; initialize the stack:
mov     ax, 07c0h
mov     ss, ax
mov     sp, 03feh ; top of the stack.


; set data segment:
xor     ax, ax
mov     ds, ax

; set default video mode 80x25:
mov     ah, 00h
mov     al, 03h
int     10h

;===================================
; load the kernel at 0800h:0000h
; 10 sectors starting at:
;   cylinder: 0
;   sector: 2
;   head: 0

; BIOS passes drive number in dl,
; so it's not changed:

mov     ah, 02h ; read function.
mov     al, 10  ; sectors to read.
mov     ch, 0   ; cylinder.
mov     cl, 2   ; sector.
mov     dh, 0   ; head.
; dl not changed! - drive number.

; es:bx points to receiving
;  data buffer:
mov     bx, 0AAAh   
mov     es, bx  
mov     bx, 0

; read!
int     13h
jmp start

times (510 - ($ - $$)) db 0
dw 0xAA55

start:

mov ax, 0
mov bx, 0
mov cx, 0
mov dx, 0
  
KeyBoardBuffer = 0x1000

mov ah, 09h
mov cx, 1000h
mov al, 20h
mov bl, 17h
int 10h

mov ah, 02h
int 10h

;call splash    
jmp kernel
           

splash:
	mov di, SYS_desc
	call puts
ret 
	
putc:        
	mov ah, 0eh
	int 10h
ret      
    
puts:
	mov al, [ds:di]
	cmp al, 0
	jne __puts__next
ret
__puts__next:
	call putc
	inc di
	jmp puts    
dat:      
	SYS_help_text	db "A List of commands for COSA.", 10, 13
			db "restart     |       restart the computer", 10, 13
			db "splash      |       display the splash screen", 10, 13 
			db "help        |       show this list", 10, 13, 0
		
	SYS_desc	db "Computer Operating System A.", 10, 13, "Kernel Version 0.1 Revision 0", 10, 13, "(C) Joshua Farmer 2023 lol", 10, 13, 0
	SYS_keyboard 	db 0      
	SYS_prompt	db "> ", 0
	SYS_user	db "computer", 20h, 0
	
	INST_shutdown	db "restart", 0   
	INST_desc	db "splash", 0 
	INST_help	db "help", 0  
dat_t:	 
	
getc:    
	mov ah, 0
	int 16h  
ret  

gets:  
	call getc
	call putc  
	mov [ds:di], al
	inc di
	cmp al, 13 
	jne gets 
	
	mov al, 10
	int 10h
ret

strCmp:
; Compare strings in a loop
    cmp_loop:
        ; Load characters from each string
	mov al, [ds:SI]   ; Load byte at address in DS:SI into AL,
	mov bl, [ds:DI]
	inc si
	inc di
	; Check for null terminator
	cmp al, 0
	je strings_equal   ; Jump if null terminator is reached
	
	; Compare characters
	cmp al, bl
	jne not_equal   ; Jump if characters are not equal
	  
	; Continue loop
	jmp cmp_loop
not_equal:
	; Strings are not equal
	mov ax, 0
ret
strings_equal:
	; Strings are equal
	mov ax, 1
ret 
 
clearBuffer:    
	mov di, KeyBoardBuffer    
	clearBuffer_:
	mov byte[ds:di], 0
	inc di
	cmp byte[ds:di], 0
	jne clearBuffer_
ret 
 
 
_INST_desc:
	call splash
jmp kernel

_INST_help:
	mov di, SYS_help_text
	call puts
jmp kernel

kernel:        
	call clearBuffer
	
	mov di, SYS_user
	call puts
	         
	mov di, SYS_prompt
	call puts
	
	; get user input
	mov di, KeyBoardBuffer   
	call gets       
        
        ; help command
        mov si, INST_help
	mov di, KeyBoardBuffer  
	call strCmp
	cmp ax, 1 
	je _INST_help
	
        ; splash screen command
	mov si, INST_desc
	mov di, KeyBoardBuffer  
	call strCmp
	cmp ax, 1 
	je _INST_desc
	
	; check if the user wants to restart
	mov si, INST_shutdown   
	mov di, KeyBoardBuffer  
	call strCmp 
	cmp ax, 1     
	je restart
	
	jmp kernel
restart:
	int 19h  
