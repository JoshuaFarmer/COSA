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
        total_sects: dw 5
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
	jmp 0x1000:0000

spin:
	hlt
inf:
	jmp inf

times 510-($ - $$) db 0
dw 0xAA55
