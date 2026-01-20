format ELF64 executable

segment readable executable

entry start

start:
    mov     rax, 1          ; sys_write
    mov     rdi, 1          ; stdout
    mov     rsi, msg
    mov     rdx, msg_len
    syscall

    mov     rax, 60         ; sys_exit
    xor     rdi, rdi        ; exit code 0
    syscall

segment readable writeable

msg db 'Hello from FASM!',10
msg_len = $ - msg