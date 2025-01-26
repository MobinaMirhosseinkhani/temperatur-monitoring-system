
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

my_data segment
    CONTROL EQU 06H
    PORTA   EQU 00H
    PB      EQU 02H
    PC      EQU 04H
my_data ends

mycode segment
    assume cs:mycode, ds:my_data
    mov ax,my_data
    mov ds,ax

Start:
    ; Seven segment codes for 0-9
    mov [1000h], 0C0H    ; 0
    mov [1001h], 0F9H    ; 1
    mov [1002h], 0A4H    ; 2
    mov [1003h], 0B0H    ; 3
    mov [1004h], 099H    ; 4
    mov [1005h], 092H    ; 5
    mov [1006h], 082H    ; 6
    mov [1007h], 0F8H    ; 7
    mov [1008h], 080H    ; 8
    mov [1009h], 090H    ; 9

    ; Initialize 8255 for A as output, PORTB as input
    mov dx,CONTROL                mode 0
    mov al,10000010B     ; Set PORT
    out dx,al

again:
    ; Read from ADC (PORTB)
    mov dx,PB
    in al,dx             ; Read directly into AL
    mov [2000h],al       ; Store the raw value
    
    ; Check if number is odd or even
    mov al,[2000h]
    test al,1            ; Test least significant bit
    jnz odd_number       ; If LSB is 1, number is odd
    
    ; For even numbers, multiply by 2
    mov bl,2
    mul bl               ; AX = AL * 2
    jmp store_result
    
odd_number:
    ; For odd numbers, multiply by 2 and subtract 1
    mov bl,2
    mul bl               ; AX = AL * 2
    dec al               ; Subtract 1 from result
    
store_result:
    mov [2000h],al       ; Store the processed value
    
    ; Convert to BCD
    mov bl,10            ; Divisor
    mov ah,0             ; Clear AH
    div bl               ; AL = tens, AH = ones
    
    ; Store digits separately
    mov [1032h],al       ; Store tens digit
    mov [1031h],ah       ; Store ones digit

    ; Check temperature for LED control (57 degrees threshold)
    mov al,[2000h]       ; Get the processed value
    cmp al,57
    jnc light_on         ; Jump if temperature >= 57
    jmp light_off        ; Otherwise, LED off

light_on:
    mov [1200h],05h      ; First digit select
    mov [1201h],06h      ; Second digit select
    jmp display

light_off:
    mov [1200h],01h      ; First digit select
    mov [1201h],02h      ; Second digit select
    jmp display

display:
    ; Display tens digit
    mov al,[1200h]
    mov dx,PC            ; Select digit using PORTC
    out dx,al
    
    mov bh,10h           ; Segment patterns base address
    mov bl,[1032h]       ; Get tens digit
    mov al,[bx]          ; Get pattern
    mov dx,PORTA
    out dx,al
    call DELAY_S

    ; Display ones digit
    mov al,[1201h]
    mov dx,PC            ; Select digit using PORTC
    out dx,al
    
    mov bh,10h           ; Segment patterns base address
    mov bl,[1031h]       ; Get ones digit
    mov al,[bx]          ; Get pattern
    mov dx,PORTA
    out dx,al
    call DELAY_S

    jmp again

DELAY_S PROC NEAR
    push cx              ; Save CX
    mov cx,0FFh         ; Delay count
RPT2:
    loop RPT2
    pop cx              ; Restore CX
    ret
DELAY_S ENDP

mycode ends
end Start

ret




