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
mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf
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
xor cx, cx ; set x to 0

mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf

loop1:
nop
; x++
inc cx

; inside the first loop

; for (y = 0; y < image_y; y++)
xor si, si
mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf

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
mov dword[i], 0

; while (z_r * z_r + z_i * z_i < 4 && i < iteration_max)
mov ax, 1
mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf

loop3:
nop

; inside while loop

; tmp = z_r
mov r8d, [z_r]

; z_r = z_r * z_r - z_i * z_i + c_r
mov eax, 0
mov eax, [z_r]
imul eax, eax
mov ebx, [z_i]
imul ebx, ebx
sub eax, ebx
add eax, [c_r]
mov [z_r], eax

; z_i = 2 * z_i * tmp + c_i
xor eax, eax
mov eax, [z_i]
imul eax, 2
imul eax, r8d
add eax, [c_i]
mov [z_i], eax


; i++
inc dword[i]

; loop condition
; z_r * z_r + z_i * z_i < 4
xor eax, eax
mov eax, [z_r]
imul eax, eax
mov ebx, [z_i]
imul ebx, ebx
add eax, ebx

cmp eax, dword 4
jge loopend

; i < iteration_max
; ...
mov eax, dword[i]
cmp eax, [iteration_max]
jge loopend

jmp loop3

loopend:

; if (i != iteration_max)
mov rdi,phrase
movsx rsi,dword[i]
mov rax,0
call printf
cmp eax, [iteration_max]

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
movsx ecx,cx	; coordonnée source en x
movsx r8d,si	; coordonnée source en y
movsx r9d,cx	; coordonnée destination en x
push si		; coordonnée destination en y
call XDrawLine

continue_loop:

; y < image_y
cmp si, [image_y] ; Compare cx to the limit
jle loop2


; x < image_x
cmp cx, [image_x] ; Compare cx to the limit
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
	