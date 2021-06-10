E 	EQU P3.2
RS 	EQU P3.3

ORG 00H
SJMP MAIN

;;LCD functions below are modified from the discussion slide

START:
	MOV R0, #60H
	MOV R6, #04H	;counter that keep track of the number of digit to print
	MOV A, #80H		;set the cursor to first column of the first line
	ACALL CMD		;call LCD command function
	ACALL PRINT		;call the print function to display the first three digit on LCD
	MOV A, #30H		;move digit 0 into accumulator
	ACALL DATA		;call the data function to display 0
	MOV A, #30H		;move digit 0 into accumulator
	ACALL DATA		;call the data function to display 0
	RET

PRINT:				;print a digit on LCD
	MOV A,@R0	
	DJNZ R6,CONT
	RET
CONT:
	ACALL DATA
	INC R0
	JMP PRINT

LCD_INIT:			;initializing LCD
	MOV A,#38H		;Set Interface data length to 8 bits, 2 line, 5x7 character font
	ACALL CMD
	MOV A,#06H		;set to increment with no shift
	ACALL CMD
	MOV A,#0FH		;display  on, the cursor on and blinking on	
	ACALL CMD
	RET

CMD:				;send LCD command
	CLR RS
	MOV P1,A
	ACALL PULSE
	RET

DATA:				;send LCD data
	SETB RS
	MOV P1,A
	ACALL PULSE
	RET

PULSE:				;create pulse
	SETB E
	ACALL DELAY
	CLR E
	RET

DELAY:				;create delay
	MOV R7,#50		
LOOP:
	DJNZ R7,LOOP
	RET

WORK:
	MOV TL0, #0EFH		;set the timer delay based on the calculation
	MOV TH0, #0D8H		;set the timer delay based on the calculation
	SETB P3.0			;make the motor rotate clockwise
	CLR P3.1			;make the motor rotate clockwise
	SETB P3.5			;start timer1
	SETB TR0			;start timer0
	SETB TR1			;start timer0
	STAY: JNB TF0, STAY	;keep on waiting by checking TF0, when TF0 goes 1, timer reaches its max
	CLR P3.5			;stop timer1
	CLR TF0				;clear timer0's overflow flag
	CLR TF1				;clear timer1's overflow flag
	RET

MAIN:
	ACALL LCD_INIT			;initializing LCD
	MOV TMOD, #51H			;initializing TMOD for Timer1 in event-counting mode and mode 1; initializing TMOD for Timer0 in mode 1

AGAIN:
	MOV R0, #30H		;starting memory location for storing TH1 and TL1
	MOV TH1, #00H		;reset TH1
	MOV TL1, #00H		;reset TL1
	ACALL WORK			;call work function to start counting number of revolution in 10ms
	MOV A, TH1			;move TH1 into accumulator
	MOV @R0, A			;store TH1 into data memory
	INC R0				;increment memory location to store TL1
	MOV A, TL1			;store TL1 into accumulator
	MOV @R0, A			;store TL1 into data memory
	MOV R1, #42H		;memory location to store the decimal format of TL1
	MOV A, @R0			;move TL1 into accumulator
	MOV 40H, #0H		;clear the previous TL1
	MOV 41H, #0H		;clear the previous TL1
	MOV 42H, #0H		;clear the previous TL1

DIVISION:
	MOV B, #0AH		;store 10 into B
	DIV AB			;divide TL1 by B to get the remainder
	MOV @R1, B		;store the decimal format of TL1 into data memory
	JZ FDIV			;if quotient is 0 then we finish converting TL1 from hex to decimal
	DEC R1			;decrease R1 to get to the next memory location to store the next digit
	SJMP DIVISION	;repeat the division until the quotient is 0

FDIV:				;the part where we convert TH1 from hex to decimal
	DEC R0			;decrease R0 to get to the memory location where TH1 is stored
	MOV A, @R0		;move TH1 into accumulator
	MOV R1, #50H	;starting memory location where decimal format of TH1 will be stored
	JNZ TWO			;if TH1 is not 0 then jump to the place where we handle non-zero case
	MOV @R1, #0H	;store 000 start from memory location 50
	INC R1
	MOV @R1, #0H
	INC R1
	MOV @R1, #0H
	SJMP FCON		;finish convert TH1 from hex to decimal

TWO:				;the part where we handle the case when TH1 is 2
	DEC A			
	JZ ONE			;if TH1 is 1 then jump to the place where we handle this case
	MOV @R1, #05H	;store 512 start from memory location 50
	INC R1
	MOV @R1, #01H
	INC R1
	MOV @R1, #02H
	SJMP FCON		;finish convert TH1 from hex to decimal

ONE:				;the part where we handle the case when TH1 is 1
	MOV @R1, #02H	;store 256 start from memory location 50
	INC R1
	MOV @R1, #05H
	INC R1
	MOV @R1, #06H

FCON:				;the part where we add decimal format of TH1 and TL1
	MOV R0, #62H	;memory location where we will store the result of addition
	MOV R1, #43H	;memory location of TL1
	MOV R4, #04H	;counter to keep track of doing a 3 digit addition
	MOV R5, #0H		;place to store the carry bit

ADDITION:			
	DEC R1			
	MOV A, @R1		
	MOV R2, A		;store a digit of TL1 into R2
	MOV A, R1
	ADD A, #10H
	MOV R1, A		;move to the memory location where we store TH1 
	MOV A, @R1		;store a digit of TH1 into accumulator
	ADD A, R2		;add the accumulator with TL1
	ADD A, R5		;add the accumulator with carry bit
	MOV R3, A		;move the result into R3
	MOV R5, #0H		;reset the carry bit

	SUBB A, #0AH	;determine whether the result of addition is larger than 9
	JZ CARRY		;keep decreasing the result to find out 
	SUBB A, #01H	;if the result is 0 then jump to the part where we handle carry case
	JZ CARRY		
	SUBB A, #01H	
	JZ CARRY
	SUBB A, #01H
	JZ CARRY
	SUBB A, #01H
	JZ CARRY
	SUBB A, #01H
	JZ CARRY
	SUBB A, #01H
	JZ CARRY
	SUBB A, #01H
	JZ CARRY
	SUBB A, #01H
 	JZ CARRY
	SUBB A, #01H
	JZ CARRY	

	MOV A, R3		;if there is no carry then move the value in R3 directly to accumulator
	SJMP STORING	;go to the part where we store the result into memory location
	
CARRY:	
	INC R5			;if there is carry then we set the carry flag
	MOV A, R3		;we add the value in R3 by 6H and subtract 10H to get the correct digit
	ADD A, #6H
	SUBB A, #10H

STORING:
	ADD A, #30H				;add 30H to get the ascii of a digit
	MOV @R0, A				;store the result into memory location
	DEC R0					;get to the next memory location to store the next digit
	MOV A, R1				;get to the memory location to add the next digit
	SUBB A, #10H
	MOV R1, A
	DJNZ R4, ADDITION		;repeat the addition
	
	ACALL START				;jump to LCD-displaying function
	AJMP AGAIN				;repeat the process to count the number of revolution for next 10ms

END
