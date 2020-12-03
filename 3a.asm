; Advent of Code 2020
;   in x86-64 assembly for Linux
; Day 3 (part 1)
;   by Alicja Piecha

; Place input in 3.in (<= 16384 bytes)
; nasm -f elf64 3a.asm && ld 3a.o -o 3a && ./3a

; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED but it does work on my input so idk.

global _start
section .data
  input: db "3.in", 0
section .text
_start:
  mov rbp, rsp
  
  ; r12: anonymous pages
  ; r13: fd
  ; r14: bytes read so far

  ; mmap
  mov rax, 9      ; mmap
  ;xor edi, edi   ; addr (registers start out zeroed)
  mov rsi, 16384  ; len (my input fits in 2.5 pages so 4 should be enough headroom)
  mov rdx, 3      ; prot (PROT_READ | PROT_WRITE)
  mov r10, 34     ; flags (MAP_PRIVATE | MAP_ANONYMOUS) 
  mov r8, -1      ; fd (-1 for compat)
  ;xor r9d, r9d   ; offset (doesn't matter)
  syscall
  mov r12, rax    ; save allocation's address

  ; open
  mov rax, 2      ; open
  mov rdi, input  ; filename 
  xor esi, esi    ; flags (O_RDONLY)
  ;xor edx, edx   ; mode (doesn't matter)
  syscall
  mov r13, rax    ; save the fd

read:
  ; read
  xor eax, eax    ; read
  mov rdi, r13    ; fd (from last syscall)
  mov rsi, r12    ; buf (saved allocation's address)
  mov rdx, 16384  ; count
  sub rdx, r14    ; don't overflow the buffer
  syscall
  add r14, rax    ; add bytes read
  test rax, rax   ; check if read 0 bytes
  jnz read        ;   which means EOF

  ; r12: base pointer
  ; r14: total bytes
  ; rbx: x
  ; rcx: y
  ; r15: count
  ; r10: thirty one (for mod)

  ; lines are 32 bytes (including \n)
  ; rows wrap after 31
  ; x, y => x%31 + y*32

  xor r15d, r15d
  xor ebx, ebx
  xor ecx, ecx
  mov r10, 31  

tick:
  xor edx, edx
  mov rax, rbx
  div r10        ; x%31
  mov r8, rcx
  imul r8, 32    ; y*32
  add rdx, r8    ; index
  add rdx, r12   ; final address
  mov r13, rdx
  sub r13, r12   ; number of bytes processed
  cmp r13, r14   ; check if out of bounds
  jge itoa

  cmp byte [rdx], 35  ; '#'
  jne .after
  inc r15
.after:
  add rbx, 3
  add rcx, 1
  jmp tick

  ; r15: total count
  ; r10: ten (for div)

itoa:
  mov r10, 10
  sub rsp, 22            ; longest string possible from u64 plus newline plus one
                         ; (we inc r9 every time so we have to compensate)
  mov byte [rbp-1], 10   ; '\n'
  lea r12, [rbp-2]
  ; r12: string pointer
  mov rax, r15

.loop:
  xor edx, edx           ; rdx is used as upper bytes for division
  div r10
  add rdx, 48            ; '0'
  mov [r12], dl
  dec r12
  cmp r12, rsp
  jne .loop

  mov r9, rsp
  mov r11, 22
.trim:
  inc r9
  dec r11
  cmp byte [r9], 48      ; '0'
  je .trim

  mov rax, 1             ; write
  mov rdi, 1             ; fd (stdout)
  mov rsi, r9            ; buf
  mov rdx, r11           ; count
  syscall

  mov rax, 60            ; exit
  mov rdi, 0             ; exit code
  syscall
