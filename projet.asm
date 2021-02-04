extern printf


section .data
    x1:             dq -2.1
    x2:             dq  0.6
    y1:             dq -1.2
    y2:             dq  1.2
    zoom:           dq  100
    iteration_max:  dq  50
    pi:             dq  3.14159

    print_test:     db " %f ",0


segment .bss
    x       resq 0
    y       resq 0

    c_r     resq 0
    c_i     resq 0
    z_r     resq 0
    z_i     resq 0
    i       resq 0
    
    tmp     resq 0

    image_x resq 0
    image_y resq 0

section .text

global main
    

main:
    ; image_x = (x2 - x1) * zoom
    movsx rax, qword[x2]
    sub rax, qword[x1]
    imul rax, qword[zoom]
    movsx [image_x], rax
    
    ; image_y = (y2 - y1) * zoom
    movsx eax, [y2]
    sub eax, [y1]
    imul eax, [zoom]
    movsx [image_y], eax

    movsx rdi,print_test
    movsx rsi,0
    movsx rax,word[pi]
    call printf
    
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
            movsx ax, [x]
            movsx bx, [zoom]
            xor dx, dx
            div bx ; ax=résultat(dx:ax/bx), dx=reste(dx:ax/bx) :
            add ax, [x1]
            movsx [c_r], ax
            
            ; c_i = y / zoom + y1
            movsx ax, [y]
            movsx bx, [zoom]
            xor dx, dx
            div bx
            add ax, [y1]
            movsx [c_i], ax
            
            ; z_r = 0
            movsx [z_r], dword 0
            
            ; z_i = 0
            movsx [z_i], dword 0
            
            ; i = 0
            xor di, di
            
            ; while (z_r * z_r + z_i * z_i < 4 && i < iteration_max)
            movsx ax, 1
            loop3:
                nop
                
                ; inside while loop
                
                ; tmp = z_r
                movsx r8d, [z_r]
                
                ; z_r = z_r * z_r - z_i * z_i + c_r
                xor eax, eax
                movsx eax, [z_r]
                imul eax, eax
                movsx ebx, [z_i]
                imul ebx, ebx
                sub eax, ebx
                add eax, [c_r]
                movsx [z_r], eax
                
                ; z_i = 2 * z_i * tmp + c_i
                xor eax, eax
                movsx eax, [z_i]
                imul eax, 2
                imul eax, r8d
                add eax, [c_i]
                movsx [z_i], eax
                
                
                ; i++
                inc di
                
                ; loop condition
                ; z_r * z_r + z_i * z_i < 4
                xor eax, eax
                movsx eax, [z_r]
                imul eax, eax
                movsx ebx, [z_i]
                imul ebx, ebx
                add eax, ebx

                cmp eax, dword 4
                jge loopend
                
                ; i < iteration_max
                ; ...
                
                cmp di, [iteration_max]
                jge loopend

                jmp loop3
                
            loopend:
            
            ; if (i == iteration_max)
            cmp eax, [iteration_max]
            
            ; draw the pixel at x, y (aka call a function)
            ;je dessin
            
            continue_loop:
            
            ; y < image_y
            cmp si, [image_y] ; Compare cx to the limit
            jle loop2
            
        
        ; x < image_x
        cmp cx, [image_x] ; Compare cx to the limit
        jle loop1
