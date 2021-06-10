ORG 00H
	SJMP MAIN	;jump to the location where the main program starts

ORG 40H			;data of 2 numbers for multiplication 
	N1: DB "143"
	DB 0
	N2: DB "234"
	DB 0

MATH:
	MOV R0, #7	;store 7 into R0 because we want to first convert the digit in R7
	MOV R4, #0	;R4 is the register we want to store the number in hex format
CALC:
	MOV A, @R0	;move the first digit into accumulator
	SUBB A, #30H	;convert the first digit into decimal first
	CJNE R3, #3, TWO	;if current number is not three digits then jump to the place where we handle 2 digits number
THREE:
	MOV B, #64H	;store 64H into B since 64H is same as 100 in decimal because we want to convert the third digit of a decimal number into hex 
	MUL AB		;multiply the first digit by 64H
	MOV R4, A	;move the result into R4
	SJMP FINISH	;finish processing the current digit
TWO:
	CJNE R3, #2, ONE	;if current number is not 2 digits then jump to the place where we handle 1 digit number
	MOV B, #0AH		;store 0AH into B since 0AH is same as 10 in decimal because we want to convert the second digit of a decimal number into hex
	MUL AB			;multiply the second digit by 0AH
	ADD A, R4		;add the result with R4
	MOV R4, A		;store the result into R4
	SJMP FINISH		;finish processing the current digit
ONE:
	ADD A, R4	;add the last digit of number with R4
	MOV R4, A	;store the result into R4
FINISH:
	DEC R0		;decrement R0 to process next digit of a number		
	DJNZ R3, CALC	;repeat the conversion until all the digits are finished
	RET

LOOP:				;place where we read a number
	MOV A, R2		;put the offset into the accumulator
	MOVC A, @A+DPTR		;put the X-th digit of a number into the accumulator
	INC R2 			;increment the offset by 1 to get to next digit
	JZ BACK			;if the current digit is a terminating character, which is 0, then we break out
	MOV @R0, A		;store the digit into a register
	INC R3			;increment R3 by 1 to keep track the number of digit
	DEC R0			;decrement R0 by 1 to store the next digit
	SJMP LOOP 		;keep reading the number until it reaches a terminating character

MAIN:
	MOV DPTR, #N1	;base address of N1
	MOV R2, #0	;offset from base address
	MOV R1, #40H 	;memory location to store the first number
	MOV 70H, #2 	;store 2 into memory location 70H because we will read 2 numbers
START:
	MOV R7, #0 	;clear the first digit of a number
	MOV R6, #0 	;clear the second digit of a number
	MOV R5, #0 	;clear the third digit of a number
	MOV R0, #7	;we will store the first digit in R7, second digit in R6, and third digit in R5 so we store 7 to start with
	MOV R3, #0	;keep track of number of digit
	SJMP LOOP 	;jump to the location where we read a number digit by digit
BACK:
	ACALL MATH	;jump to the place where we convert the string into a hex number
	MOV A, R4	;move the R4 into accumulator
	MOV @R1, A	;store the converted hex number into memory
	INC R1		;increment the memory location by 1 to store the next number
	DJNZ 70H, START ;keep reading the numbers until both of the 2 numbers are read

	MOV A, 40H	;move the first number into accumulator
	MOV B, 41H	;move the second number into B
	MUL AB		;multiply the 2 numbers
	MOV 40H, B	;store the MSB into 40H
	MOV 41H, A	;store the LSB into 41H
END
