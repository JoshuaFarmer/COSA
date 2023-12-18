start:

call clear_scr
push 0
pop ds
push 1000h
pop es

mov ax, 0
mov bx, 0
mov cx, 0
mov dx, 0
  
KeyBoardBuffer = 0xe820

mov ah, 09h
mov cx, 1000h
mov al, 20h
mov bl, 17h
int 10h

mov ah, 02h
int 10h

;call splash    
jmp dat_t 

clear_scr:
	pusha
	mov ah, 0x00
	mov al, 0x03  ; text mode 80x25 16 colours
	int 0x10
	popa
	ret

dat:
	DAT_run_error	  db "unable to start program :(", 10, 13, 0
	times 10-($ - $) db 0

	DAT_user_prompt	db "enter your name: ", 0
	times 10-($ - $) db 0
	
	SYS_help_text	db "A List of commands for COSA.", 10, 13
			db "restart     |       restart the computer", 10, 13
			db "splash      |       display the splash screen", 10, 13 
			db "help        |       show this list", 10, 13
			db "disk        |       read the contents of disk 1", 10, 13
			db "run         |       run code from 8000h", 10, 13, 0
	times 10-($ - $) db 0	
	SYS_desc	db "Computer Operating System A.", 10, 13, "Kernel Version 0.1 Revision 0", 10, 13, "(C) Joshua Farmer 2023", 10, 13, 0
	times 10-($ - $) db 0
	SYS_keyboard 	db 0   
	times 10-($ - $) db 0   
	SYS_prompt	db "> ", 0    
	times 10-($ - $) db 0
	SYS_user	db "sys", 20h, 0
	times 30-($ - $) db 0  
	
	INST_shutdown	db "restart", 0        
	times 10-($ - $) db 0
	INST_desc	db "splash", 0     
	times 10-($ - $) db 0
	INST_help	db "help", 0    
	times 10-($ - $) db 0
	INST_user	db "set-user", 0
	times 10-($ - $) db 0
	INST_cls	db "cls", 0
	times 10-($ - $) db 0
	  
	INST_disk	db "disk", 0
	times 10-($ - $) db 0 
	INST_run	db "run", 0
	times 10-($ - $) db 0
dat_t:

jmp kernel_mainloop
           

splash:
	mov di, SYS_desc
	call puts
ret 
	
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
	
getc:    
	mov ah, 0
	int 16h  
ret  

gets:  
	call getc
	call putc 
	cmp al, 8
	je gets_backspace 
	mov [es:di], al 
	inc di 
	gets_:
	cmp al, 13 
	jne gets 
	
	mov al, 10
	int 10h
ret          
gets_backspace:
	mov al, 20h  
	call putc
	mov al, 8    
	call putc
	
	dec di
	mov byte[es:di], 0
	jmp gets_

; si = source
; di = destination
strCpy:
; Compare strings in a loop
    strCpy_loop:
        ; Load characters from each string
	mov al, [es:si]   ; Load byte at ES:SI into AL,
	mov [es:di], al
	inc si
	inc di  
	; Check for null terminator 
	cmp al, 0
	je strCpy_done   ; Jump if null terminator is reached
	
	; Continue loop
	jmp strCpy_loop
strCpy_done:
	ret
	
strCmp:
; Compare strings in a loop
    cmp_loop:
        ; Load characters from each string
	mov al, [es:SI]   ; Load byte at ES:SI into AL,
	mov bl, [es:DI]
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
	mov byte[es:di], 0
	inc di
	cmp byte[es:di], 0
	jne clearBuffer_
ret 
 
 
_INST_desc:
	call splash
jmp kernel_mainloop

_INST_help:
	mov di, SYS_help_text
	call puts
jmp kernel_mainloop

_INST_user:    
	call clearBuffer
	mov di, DAT_user_prompt 
	call puts       
	mov di, SYS_user        
	call gets       
	dec di
	mov byte[es:di], 20h  
jmp kernel_mainloop

_INST_disk:     
	mov     ah, 02h ; read function.
	mov     al, 10  ; sectors to read.
	mov     ch, 0   ; cylinder.
	mov     cl, 1   ; sector.
	mov     dh, 0   ; head.
	mov     dl, 1   ; drive.
	
	; es:bx points to receiving
	;  data buffer:
	mov     bx, 0x8000   
	mov     es, bx
	mov     bx, 0
	
	; read!
	int     13h 
	
	mov     bx, 0x1000   
	mov     es, bx
	mov     bx, 0
jmp kernel_mainloop

_INST_run:     
	mov al, 0x90   
	
	mov bx, 0x8000   
	mov es, bx
	mov bx, 0   
	
	mov si, 0
	
	cmp [es:si], al 
	je _run_success
_run_error:
	mov bx, 0x1000   
	mov es, bx
	mov bx, 0  
	mov di, DAT_run_error
	call puts
jmp kernel_mainloop
_run_success:
	mov bx, 0x8000   
	mov es, bx
	mov bx, 0
	jmp 0x8000:0000

_INST_cls:
	call clear_scr
	mov ah, 09h
	mov cx, 1000h
	mov al, 20h
	mov bl, 17h
	int 10h
jmp kernel_mainloop

kernel_mainloop:        
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
	
	; change user command
	mov si, INST_user
	mov di, KeyBoardBuffer  
	call strCmp
	cmp ax, 1 
	je _INST_user
	
	; load disk
	mov si, INST_disk
	mov di, KeyBoardBuffer  
	call strCmp
	cmp ax, 1 
	je _INST_disk  
	
	; run
	mov si, INST_run
	mov di, KeyBoardBuffer  
	call strCmp
	cmp ax, 1 
	je _INST_run

	; clear command
	mov si, INST_cls
	mov di, KeyBoardBuffer  
	call strCmp
	cmp ax, 1 
	je _INST_cls

	; check if the user wants to restart
	mov si, INST_shutdown   
	mov di, KeyBoardBuffer  
	call strCmp 
	cmp ax, 1     
	je restart
	
	jmp kernel_mainloop
restart:
	int 19h 
