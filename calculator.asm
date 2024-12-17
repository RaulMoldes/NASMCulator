section .data
    welcome_msg db "*********************************", 10
                db "*       Welcome to the          *", 10
                db "*   NASM Integer Calculator!    *", 10
                db "*********************************", 10, 10, 0 ; Newline and null terminator
    prompt db "Enter a number: ", 0
    input_length equ 20         ; Maximum input length
    result_msg db "The result is: ", 0
    newline db 10, 0               ; Newline character
    div_by_zero_msg db "Error: Division by zero", 10, 0
    prompt_op db "Enter operation (+ , -, * or /): ", 0

section .bss
    input_buffer resb input_length  ; Reserve 20 bytes for the input buffer
    num1 resd 1                     ; Reserve space for the first number
    num2 resd 1                     ; Reserve space for the second number
    result_buffer resb 12          ; Buffer to hold the string result (enough for a 32-bit number)
    op resb 1                     ; Reserve space for the operation character

section .text
    global _start

%macro str_to_int 1
    ; %1: El puntero al string (por ejemplo, ESI)
    xor eax, eax        ; Limpiar EAX (acumulador de resultados)
    xor ebx, ebx        ; EBX se usa para almacenar cada dígito

%%convert_loop:
    mov bl, [%1]        ; Cargar el carácter actual en BL
    cmp bl, 10          ; ¿Es un salto de línea (ASCII 10)?
    je %%end_convert    ; Si es un salto de línea, termina la conversión
    cmp bl, 0           ; ¿Es un terminador nulo?
    je %%end_convert    ; Si es un terminador nulo, termina la conversión

    sub bl, '0'         ; Convertir carácter ASCII a dígito ('0' -> 0, '1' -> 1, etc.)
    imul eax, eax, 10   ; Multiplicar el resultado actual por 10
    add eax, ebx        ; Agregar el nuevo dígito al resultado

    inc %1              ; Avanzar al siguiente carácter
    jmp %%convert_loop  ; Repetir el bucle

%%end_convert:
%endmacro


%macro int_to_str 2
    ; Convert integer to string
    ; %1: the integer in EAX
    ; %2: pointer to the output buffer
    mov ecx, 10         ; Base 10 for decimal conversion
    mov edi, %2         ; Destination buffer
    mov ebx, edi        ; Save start of buffer

    xor edx, edx        ; Clear EDX for division

%%convert_digit:
    div ecx             ; Divide EAX by 10, quotient in EAX, remainder in EDX
    add dl, '0'         ; Convert remainder to ASCII
    dec edi             ; Move buffer pointer backward
    mov [edi], dl       ; Store ASCII character in buffer
    xor edx, edx        ; Clear EDX for next iteration
    test eax, eax       ; Check if quotient is zero
    jnz %%convert_digit ; If not, continue dividing

    mov eax, ebx        ; Load start of buffer into EAX
%endmacro


_start:
    ; Display welcome message
    mov eax, 4          ; sys_write
    mov ebx, 1          ; file descriptor (stdout)
    mov ecx, welcome_msg ; message to write
    mov edx, 138        ; length of the welcome message (count manually or use a tool)
    int 0x80            ; make syscall

    ; Display prompt to user
    mov eax, 4          ; sys_write
    mov ebx, 1          ; file descriptor (stdout)
    mov ecx, prompt     ; message to write
    mov edx, 16         ; length of the prompt
    int 0x80            ; make syscall

    ; Read user input
    mov eax, 3          ; sys_read
    mov ebx, 0          ; file descriptor (stdin)
    mov ecx, input_buffer ; buffer to store input
    mov edx, input_length ; max input length
    int 0x80            ; make syscall

    ; Convert string to integer using the macro
    mov esi, input_buffer ; Point ESI to the input buffer
    str_to_int esi        ; Call the macro with ESI as argument

    ; Store the result (integer) in 'num1'
    mov [num1], eax

    ; clear eax
    xor eax, eax

    ; Display prompt to user
    mov eax, 4          ; sys_write
    mov ebx, 1          ; file descriptor (stdout)
    mov ecx, prompt     ; message to write
    mov edx, 16         ; length of the prompt
    int 0x80            ; make syscall

    ; Read user input
    mov eax, 3          ; sys_read
    mov ebx, 0          ; file descriptor (stdin)
    mov ecx, input_buffer ; buffer to store input
    mov edx, input_length ; max input length
    int 0x80            ; make syscall

    ; Convert string to integer using the macro
    mov esi, input_buffer ; Point ESI to the input buffer
    str_to_int esi        ; Call the macro with ESI as argument

    ; Store the result (integer) in 'num2'
    mov [num2], eax
    ; clear eax
    xor eax, eax

     ; Display prompt for operation
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt_op
    mov edx, 33
    int 0x80

    ; Read operation
    mov eax, 3
    mov ebx, 0
    mov ecx, op
    mov edx, 1
    int 0x80

    ; Perform the chosen operation
    mov eax, [num1]     ; Load first number into EAX
    mov ebx, [num2]     ; Load second number into EBX

    cmp byte [op], '+'  ; Check if the operation is addition
    je do_addition
    cmp byte [op], '-'  ; Check if the operation is subtraction
    je do_subtraction
    cmp byte [op], '*'  ; Comprobar si la operación es multiplicación
    je do_multiplication
    cmp byte [op], '/'  ; Comprobar si la operación es división
    je do_division
    ; Default case (if no valid operation is entered)
    jmp exit


do_addition:
    add eax, ebx        ; Perform addition
    jmp convert_and_print

do_subtraction:
    sub eax, ebx        ; Perform subtraction
    jmp convert_and_print

do_multiplication:
    imul eax, ebx
    jmp convert_and_print

do_division:
    cmp ebx, 0          ; Comprobar si el divisor es cero
    je div_by_zero      ; Si es cero, mostrar error
    xor edx, edx        ; Limpiar EDX para la división
    div ebx             ; Dividir EAX por EBX
    jmp convert_and_print

div_by_zero:
    ; Mostrar mensaje de error por división entre cero
    mov eax, 4
    mov ebx, 1
    mov ecx, div_by_zero_msg
    mov edx, 24
    int 0x80
    jmp exit

convert_and_print:
    ; Convert result to string
    mov edi, result_buffer + 11    ; Point to the end of the buffer
    mov byte [edi], 0              ; Null-terminate the buffer
    int_to_str eax, edi            ; Convert integer to string

    ; Display result message
    xor edx, edx ; clean edx
    mov eax, 4
    mov ebx, 1
    mov ecx, result_msg
    mov edx, 14
    int 0x80

    ; Display the result string
    mov eax, 4
    mov ebx, 1
    mov ecx, edi                   ; Pointer to the result string
    mov edx, 12                    ; Max length of the result buffer
    int 0x80

    ; Print a newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

exit:
    ; Exit the program
    mov eax, 1
    xor ebx, ebx
    int 0x80