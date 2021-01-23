section .text

global main
    

main:
    ; image_x = (x2 - x1) * zoom
    mov eax, [x2]
    sub eax, [x1]
    imul eax, [zoom]
    mov [image_x], eax
    
    ; image_y = (y2 - y1) * zoom
    mov eax, [y2]
    sub eax, [y1]
    imul eax, [zoom]
    mov [image_y], eax
    
    ; for (x = 0; x < image_x; x++)
    xor cx, cx ; set x to 0
    
    loop1:
        nop
        ; x++
        inc cx
        
        ; inside the first loop
        
        ; for (y = 0; y < image_y; y++)
        xor si, si
        
        loop2:
            nop
            ; y++
            inc si
            
            ; inside the second loop
            
            ; c_r = x / zoom + x1
            mov ax, [x]
            mov bx, [zoom]
            xor dx, dx
            div bx ; ax=résultat(dx:ax/bx), dx=reste(dx:ax/bx) :
            add ax, [x1]
            mov [c_r], ax
            
            ; c_i = y / zoom + y1
            mov ax, [y]
            mov bx, [zoom]
            xor dx, dx
            div bx
            add ax, [y1]
            mov [c_i], ax
            
            ; z_r = 0
            mov [z_r], dword 0
            
            ; z_i = 0
            mov [z_i], dword 0
            
            ; i = 0
            xor di, di
            
            ; while (z_r * z_r + z_i * z_i < 4 && i < iteration_max)
			mov ax, 1
			loop3:
				nop
				
				; inside while loop
				
                ; tmp = z_r
                mov [tmp], dword z_r
                
                ; z_r = z_r * z_r - z_i * z_i + c_r
				mov eax, [z_r]
				imul eax, eax
				mov ebx, [z_i]
				imul ebx, ebx
				sub eax, ebx
				add eax, [c_r]
				mov [z_r], eax
                
                ; z_i = 2 * z_i * tmp + c_i
                mov eax, [z_i]
                imul eax, 2
                imul eax, [tmp]
                add eax, [c_i]
                ;mov [z_i], eax ; doesn't work
                
                
                ; i++
                inc di
				
				; loop condition
				; z_r * z_r + z_i * z_i < 4
				mov eax, [z_r]
				imul eax, eax
				mov ebx, [z_i]
				imul ebx, ebx
				add eax, ebx
				
				; i < iteration_max
				; ...
				
				cmp eax, 4
				jle loop3
                
            ; if (i == iteration_max)
            
                ; draw the pixel at x, y (aka call a function)
            
            ; y < image_y
            cmp si, [image_y] ; Compare cx to the limit
            jle loop2
            
        
        ; x < image_x
        cmp cx, [image_x] ; Compare cx to the limit
        jle loop1
    

section .data
    x1              dd -2.1
    x2              dd  0.6
    y1              dd -1.2
    y2              dd  1.2
    zoom            dd  100
    iteration_max   dd  50


segment .bss
    x       resd 0
    y       resd 0

    c_r     resd 0
    c_i     resd 0
    z_r     resd 0
    z_i     resq 0
    i       resd 0
    
    tmp     resd 0

    image_x resd 0
    image_y resd 0