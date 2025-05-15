section .data
    module_array     times 256 dq 0   
    name_array       times 256 dq 0   
    module_count     dq 0             
    buffer           times 128 dq 0

    lib_name         dw "K","E","R","N","E","L","3","2",".","D","L","L", 0,0,0
    function         dw "CreateProcessA", 0
    dll_addr         dq 0
    dll_export       dq 0
    proc_name        db 'powershell -c "iwr http://google.com -UseBasicParsing"', 0
    arguments        db "", 0

    startup_info times 104 db 0
    proc_info    times 24 db 0 

section .text
    global _start



_start:
    sub rsp, 28h 

    mov rax, [gs:0x60]           ; PEB
    mov rax, [rax + 0x18]        ; PEB_LDR_DATA
    mov rsi, [rax + 0x10]        ; InLoadOrderModuleList | _LDR_DATA_TABLE_ENTRY
    
    xor rdi, rdi             
    lea r15, [rel module_array]    
    lea r14, [rel name_array]       

    .modules_loop:
        mov rbx, [rsi + 0x30]        ; 0x30 DllBase

        cmp rbx, 0
        je .done

        mov [rel dll_addr], rbx
        mov rcx, qword[rsi + 0x60]  
        push rsi 
        push rax

        mov rsi, lib_name
        mov rdi, rcx
        call compare_str

        cmp rax, 1
        je .pass

        call dll_parce
        jmp .done

    .pass:
        pop rax
        pop rsi

        mov rsi, [rsi]         ; [+0x000] Flink   
        cmp rsi, [rax + 0x20]

        je .done             
        loop .modules_loop

    .done:
        add rsp, 28h
        xor eax,eax
        jmp $

dll_parce:
    push rbp
    mov rbp, rsp

    mov rax, [rel dll_addr]     ; DLL PTR    

    mov ebx, dword[rax + 0x180] ; EXPORT RVA
    add rax, rbx                ; EXPORT TABLE HEADER

    mov [rel dll_export], rax

    mov edi, dword[rax + 0x14]
    mov [rel module_count], edi

    mov ebx, [rax + 0x20]               ; ADDRESS OF NAMES

    mov rax, [rel dll_addr] 

    mov r10, rax
    add r10, rbx                ; DLL ADDRESS OF NAMES

    xor rcx, rcx

    .dll_loop:
        mov edi, dword[r10+rcx*4]
    
        add rdi, [rel dll_addr]
        mov rsi, function

        call compare_str

        cmp rax, 0
        je .fided_func

        cmp rcx, [rel module_count]
        jge .loop_end

        inc rcx
        jmp .dll_loop
    
    .fided_func:

        mov rax, [rel dll_export]
        add rax, 0x28

        sal ecx, 2
        add rax, rcx


        mov ebx, dword[rax]

        mov rdx, [rel dll_addr] 
        add rdx, rbx

        mov rax, rdx
        xor rdx, rdx
        xor rdi, rdi
        xor rbx, rbx



        mov dword [rel startup_info], 104

        xor rcx, rcx                 ; lpApplicationName (NULL)
        lea rdx, [rel proc_name]               ; lpCommandLine
         
        xor r8, r8            ; lpProcessAttributes 
        xor r9, r9            ; lpThreadAttributes 
        
        mov qword [rsp+20h], 0       ; bInheritHandles (FALSE)
        mov qword [rsp+28h], 0       ; dwCreationFlags (0)
        mov qword [rsp+30h], 0       ; lpEnvironment (NULL)
        mov qword [rsp+38h], 0       ; lpCurrentDirectory (NULL)
        lea rbx, [rel startup_info]

        mov qword [rsp+40h], rbx     ; lpStartupInfo
        lea rbx, [rel proc_info]

        mov qword [rsp+48h], rbx     ; lpProcessInformation

        call rax





    .loop_end:

    leave
    ret

;Вход: rsi = str1, rdi = str2
compare_str:
    push rbp
    mov rbp, rsp

    xor rax, rax
    xor rbx, rbx

    .compare:
        mov ax, [rsi]       ; load symbols (2 байта)
        mov bx, [rdi]

        test ax, ax         ; check is null term
        jz .equal           ; if 0 string are the same

        cmp ax, bx
        jne .not_equal      ; out if not same


        add rsi, 2          ; next symbol
        add rdi, 2

        jmp .compare

    .equal:
        xor eax, eax 
        leave
        ret
    
    .not_equal:
        mov eax, 1  
        leave
        ret
