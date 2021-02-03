; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

global main

section .bss
display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		    resq	1
gc:		        resq	1

c_r     resd 0
c_i     resd 0
z_r     resd 0
z_i     resq 0
i       resd 0

tmp     resd 0

image_x resd 0
image_y resd 0

section .data

print_test: db " %d ",0

event:		times	24 dq 0

x               dd  0
y               dd  0

x1              dd -2.1
x2              dd  0.6
y1              dd -1.2
y2              dd  1.2
zoom            dd  100
iteration_max   dd  50

two             dd  2
four            dd  4

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

; display_name structure
; screen = DefaultScreen(display_name);
mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,400	; largeur
mov r9,400	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

boucle: ; boucle de gestion des évènements
mov rdi,qword[display_name]
mov rsi,event
call XNextEvent

cmp dword[event],ConfigureNotify	; à l'apparition de la fenêtre
je drawing							; on saute au label 'dessin'

cmp dword[event],KeyPress			; Si on appuie sur une touche
je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
jmp boucle

;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:

;couleur de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x000000	; Couleur du crayon
call XSetForeground
; coordonnées de la ligne 1
;mov dword[x],50
;mov dword[y],50
; dessin de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x]	; coordonnée source en x
mov r8d,dword[y]	; coordonnée source en y
mov r9d,dword[x]	; coordonnée destination en x
push qword[y]		; coordonnée destination en y
call XDrawLine

jmp continue_loop

drawing:
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
    mov dword [x], 0 ; set x to 0
    
    loop1:
        nop
        ; x++
        inc dword [x]
        
        ; inside the first loop
        
        ; for (y = 0; y < image_y; y++)
        mov dword [y], 0
        
        loop2:
            nop
            ; y++
            inc dword [y]
            
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
            xor r9, r9
            
            ; while (z_r * z_r + z_i * z_i < 4 && i < iteration_max)
            mov ax, 1
            loop3:
                nop
                
                ; inside while loop
                
                ; tmp = z_r
                movss XMM4, dword [z_r]
                
                ; z_r = z_r * z_r - z_i * z_i + c_r
                movss XMM0, dword [z_r]
                mulss XMM0, XMM0
                movss XMM1, dword [z_i]
                mulss XMM1, XMM1
                subss XMM0, XMM1
                addss XMM0, dword [c_r]
                movss dword [z_r], XMM0
                
                ; z_i = 2 * z_i * tmp + c_i
                movss XMM3, dword [z_i]
                mulss XMM3, dword [two]
                mulss XMM3, XMM4
                addss XMM3, dword [c_i]
                movss dword [z_i], XMM3
                
                
                ; i++
                inc r9
                
                ; loop condition
                ; z_r * z_r + z_i * z_i < 4
                movss XMM5, dword [z_r]
                mulss XMM5, XMM5
                movss XMM6, dword [z_i]
                mulss XMM6, XMM6
                addss XMM5, XMM6

                ucomiss XMM5, dword [four]
                jge loopend
                
                ; i < iteration_max
                ; ...
                
                cmp r9, [iteration_max]
                jge loopend

                jmp loop3
                
            loopend:
            
            ; if (i == iteration_max)
            cmp r9, [iteration_max]
            je dessin ; draw the pixel at x, y (aka call a function)
            
            continue_loop:
            
            ; y < image_y
            mov eax, [y]
            cmp eax, [image_y] ; Compare cx to the limit
            jle loop2
            
        
        ; x < image_x
        mov eax, [x]
        cmp eax, [image_x] ; Compare cx to the limit
        jle loop1

; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################
jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	