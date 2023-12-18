#fasm#         ; use flat assembler syntax
#make_boot#
org 0x7C00

; Bootloader By HighBit.

; We need a BPB, since some BIOS'es override this section of memory.
        jmp _start
        nop
        
        sector_bytes: dw 512
        cluster_sects: db 0
        reserved_bpb: dw 0
        FATs: db 2
        roots: dw 0
        total_sects: dw 1
        media: db 0x80
        FAT_sects: dw 0
        track_sects: dw 18
        head_cnt: dw 2
        hidden_sects: dd 0
        large_sects: dd 0

        sects_per_32: dd 0
        flags: dw 0
        fat_v: dw 0
        root_clust: dd 0
        fsinfo: dw 0
        backup: dw 0
        reserved_e: dd 0 
                    dd 0 
                    dd 0
        drive_num: db 0x80
        nt_flags: db 0
        sig: db 0x28
        volume: dd 0
        volume_name: db "SMTH     "
        sys: db "FAT32 "

; We have to start somewhere, we use _start out of convention.
_start:
        ; We don't want to be disturbed.
        cli
        xor ax, ax
        mov ss, ax
        mov ds, ax
        mov es, ax
        
        mov sp, 0x7C00
        sti     
        ; Now we're fine.

   
        ; Prepare ourselves for 80x25 text mode.
        mov al, 3
        int 0x10

        ; Now we're going to load data from disk.
        ; No filesystem yet.
        mov ah, 2
        mov al, 10
        mov cx, 2
        ; Some bad BIOS'es don't pass the disk number.
        cmp dl, 0xFF
        je from_floppy
        cmp dl, 0x80
        jge from_disk
        mov dl, 0x80
        jmp from_disk       
        
        ; Floppies are unreliable, so we have to try a few times.
from_floppy:
        mov bp, 5
        jmp from_disk
check_if_repeat:
        sub bp, 1
        cmp bp, 0
        je spin
from_disk: 
        mov bx, 0x1000
        mov es, bx
        xor bx, bx
        int 0x13
        cmp dl, 0xFF
        je check_for_errors
check_for_errors:
        jnc done_with_disk
        cmp ah, 0
        je done_with_disk
        jmp spin 

done_with_disk:
        jmp 0x1000:0x0000

spin:
        hlt
inf:
        jmp inf

times 510-($ - $$) db 0
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
	
dat:      
	SYS_help_text	db "A List of commands for COSA.", 10, 13
			db "restart     |       restart the computer", 10, 13
			db "splash      |       display the splash screen", 10, 13 
			db "help        |       show this list", 10, 13, 0
		
	SYS_desc	db "Computer Operating System A.", 10, 13, "Kernel Version 0.1 Revision 0", 10, 13, "(C) Joshua Farmer 2023", 10, 13, 0
	SYS_keyboard 	db 0      
	SYS_prompt	db "> ", 0
	SYS_user	db "computer", 20h, 0
	
	INST_shutdown	db "restart", 0   
	INST_desc	db "splash", 0 
	INST_help	db "help", 0  
dat_t:	  
