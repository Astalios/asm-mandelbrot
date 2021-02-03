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
window:		resq	1
gc:		resq	1

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

section .data
phrase: dd "%d - printf ",10,0
event:		times	24 dq 0

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
mov r8,400	; width
mov r9,400	; height
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
;#     DEBUT DE LA ZONE DE DESSIN	 #
;#########################################

; printf de i
mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf


drawing:
; image_x = (x2 - x1) * zoom
mov eax, dword [x2]
sub eax, dword [x1]
imul eax, dword [zoom]
mov dword [image_x], eax

; image_y = (y2 - y1) * zoom
mov eax, dword [y2]
sub eax, dword [y1]
imul eax, dword [zoom]
mov dword [image_y], eax

; for (x = 0; x < image_x; x++)
mov dword [x], 0 ; set x to 0

; printf de i
mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf

loop1:
nop
; x++
inc dword [x]

; inside the first loop

; for (y = 0; y < image_y; y++)
mov dword [y], 0

; printf de i
mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf

loop2:
nop
; y++
inc dword [y]

; inside the second loop

; c_r = x / zoom + x1
movss XMM7, dword [x]
movss XMM8, dword [zoom]
divss XMM7, XMM8
addss XMM7, dword [x1]
movss dword [c_r], XMM7

; c_i = y / zoom + y1
movss XMM9, dword [y]
movss XMM10, dword [zoom]
divss XMM9, XMM10
addss XMM9, dword [y1]
movss dword [c_i], XMM9

; z_r = 0
mov dword [z_r], 0

; z_i = 0
mov dword [z_i], 0

; i = 0
mov dword [i], 0

; while (z_r * z_r + z_i * z_i < 4 && i < iteration_max)
mov ax, 1

; printf de i
mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf

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
inc dword[i]

; loop condition
; z_r * z_r + z_i * z_i < 4
movss XMM5, dword [z_r]
mulss XMM5, XMM5
movss XMM6, dword [z_i]
mulss XMM6, XMM6
addss XMM5, XMM6

ucomiss XMM5, dword [four]
jle loopend

; i < iteration_max
; ...

mov eax, dword [i]
cmp eax, dword [iteration_max]
jge loopend

jmp loop3

loopend:

; printf de i
mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf

; if (i != iteration_max)
mov eax, dword [i]
cmp eax, dword [iteration_max]

; call 'dessin' function if not even
jne continue_loop

dessin:

;line 1 color
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0xFF0000	; Couleur du crayon ; rouge
call XSetForeground
; coordonnées de la ligne 1
;mov dword[x1],50
;mov dword[y1],50
;mov dword[x2],200
;mov dword[y2],350
;dessin de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x]	; coordonnée source en x
mov r8d,dword[y]	; coordonnée source en y
mov r9d,dword[x]	; coordonnée destination en x
push qword[y]		; coordonnée destination en y
call XDrawLine

continue_loop:

; y < image_y
mov eax, dword [y]
cmp eax, dword [image_y] ; Compare cx to the limit
jle loop2

; x < image_x
mov eax, dword [x]
cmp eax, dword [image_x] ; Compare cx to the limit
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
	