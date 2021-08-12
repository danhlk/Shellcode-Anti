# Shellcode-Anti
Shellcode popup MessageBox combine with Anti-Debugger and Anti-Virtual Machine (Use Assembly language)

- PEfile target: [putty.exe (version latest 7.5)](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)

- Technique: ***Appending Virus***
![image](https://user-images.githubusercontent.com/58476264/129138745-066b44c4-ba0d-40d9-ac8d-d7f1dad40d17.png)

### Anti-Debugger
1. **Check BeingDebugged variable in [PEB](https://www.ired.team/miscellaneous-reversing-forensics/windows-kernel-internals/exploring-process-environment-block)**
```assembly
checkDebugger:
	mov eax, [fs:0x18]          ; load TEB
	mov eax, [eax + 0x30]       ; Load PEB
	movzx edi, byte [eax + 2]   ; check BeingDebugged then store result in edi register
```
2. **Check NtGlobalFlag variable**
```assembly
checkDebugger:
	mov eax, [fs:0x18]
	mov eax, [eax + 0x30]
	cmp dword [eax + 0x68], 0x70
	jz Detected
; do some things
Detected:
	mov edi, 1
```
**Result:**<br>
![image](https://user-images.githubusercontent.com/58476264/129141437-c305f205-435e-4b43-8b3f-5754de07d3dd.png)

![image](https://user-images.githubusercontent.com/58476264/129141467-ba7062ad-67f5-43d6-9316-5fe741c9f79e.png)

### Anti-Virtual Machine
1. **Use `cpuid` instruction**<br>
If process is run on physical, the 31st of ecx register is set to 0, otherwise is 1
```assembly
checkVM:
	mov eax, 1
	cpuid
	shr ecx, 0x1f ; store the 31st bit's value to ecx
```
2. **Check branch (only work on VMWare)**
```assembly
checkVM:
	xor eax, eax
	mov eax, 0x40000000
	cpuid
	cmp ecx, 0x4D566572         ; 'MVer'
	jne getKernel32
	cmp edx, 0x65726177         ; 'eraw'
	jne getKernel32
	mov edi, 1
```
**Result: **<br>
![image](https://user-images.githubusercontent.com/58476264/129141051-a01fed87-308e-4403-beb3-520f60dea030.png)

![image](https://user-images.githubusercontent.com/58476264/129141067-c7520bf5-8e24-43ac-a6d5-d4fe036b2a0a.png)

Entrie code is saved in 2 file [isdebug_cpuid.asm]() and [ntglobal_brand.asm]()<br>
Compile and extract shellcode with ```gcc, objcopy, od```<br>
![image](https://user-images.githubusercontent.com/58476264/129141790-4412315b-e4ef-4952-9686-8abf4413eec0.png)
