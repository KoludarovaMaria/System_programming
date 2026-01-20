format ELF64 executable
entry main

section '.data' writeable
    msg db 'Hello NCurses from FASM!',0

section '.text' executable

extrn initscr
extrn endwin
extrn printw
extrn refresh
extrn getch

main:
    call    initscr
    lea     rdi, [msg]
    call    printw
    call    refresh
    call    getch
    call    endwin
    
    xor     rdi, rdi
    mov     rax, 60
    syscall

section '.idata' import
library ncurses, 'libncurses.so.6'
import ncurses,\
    initscr, 'initscr',\
    endwin, 'endwin',\
    printw, 'printw',\
    refresh, 'refresh',\
    getch, 'getch'