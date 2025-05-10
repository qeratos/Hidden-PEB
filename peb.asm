section .data
    module_array     times 256 dq 0   
    name_array       times 256 dq 0   
    module_count     dq 0             
    buffer           times 128 dq 0
    lib_name         dw "K","E","R","N","E","L","3","2",".","D","L","L", 0,0,0
    ; function         dw "C","R","E","A","T","E","P","R","O","C","E","S","S","A", 0,0,0
    function         dw "CREATEPROCESSA"
    ; lib_size         equ $ - lib_name-1
    dll_addr         dq 0

section .text
    global _start



_start:
    ; Получаем PEB
    mov rax, [gs:0x60]           ; PEB
    mov rax, [rax + 0x18]        ; PEB_LDR_DATA
    mov rsi, [rax + 0x10]        ; InLoadOrderModuleList | _LDR_DATA_TABLE_ENTRY
    
    xor rdi, rdi             
    lea r15, [rel module_array]    
    lea r14, [rel name_array]       

modules_loop:
    mov rbx, [rsi + 0x30]        ; 0x30 DllBase

    cmp rbx, 0
    je done

    mov [rel dll_addr], rbx
    mov rcx, qword[rsi + 0x60]  
    push rsi 
    push rax

    mov rsi, lib_name
    mov rdi, rcx
    call compare_str

    cmp rax, 1
    je pass

    call dll_parce

    pass:
    pop rax
    pop rsi

    mov rsi, [rsi]         ; [+0x000] Flink   
    cmp rsi, [rax + 0x20]

    je done             
    loop modules_loop

done:
    mov [rel module_count], rdi
    leave
    ret


dll_parce:
    push rbp
    mov rbp, rsp

    mov rax, [rel dll_addr]     ; DLL PTR    

    mov ebx, dword[rax + 0x180] ; EXPORT RVA
    add rax, rbx                ; EXPORT TABLE HEADER

    mov r11, [rax + 0x16]
    mov ebx, [rax + 0x20]               ; ADDRESS OF NAMES

    mov rax, [rel dll_addr] 

    mov r10, rax
    add r10, rbx                ; DLL ADDRESS OF NAMES

    xor rcx, rcx

    .dll_loop:                  ; SEARCH NEED FUNCTION BY NAME
        mov edi, dword[r10+rcx*4]
    
        add rdi, [rel dll_addr]

        mov rsi, function
        call compare_str

        cmp rax, 0
        je .loop_end

        cmp rax, r11
        jge .loop_end

        inc rcx
        jmp .dll_loop

    .loop_end:
    


    leave
    ret



;Вход: rsi = строка1, rdi = строка2
compare_str:
    push rbp
    mov rbp, rsp

    xor rax, rax
    xor rbx, rbx

    .compare:
        mov ax, [rsi]       ; Загружаем символ (2 байта)
        mov bx, [rdi]

        cmp ax, bx
        jne .not_equal      ; Выход если не равны

        test ax, ax         ; Проверка на нуль-терминатор
        jz .equal           ; Если 0 - строки равны

        add rsi, 2          ; Следующий символ
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
