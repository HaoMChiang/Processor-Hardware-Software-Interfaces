ORG 0H

	MOV R7, #25 ;store N into R7

	MOV R0, #40H ;store the starting address of fib(0) in R0

	MOV R1, #42H ;store the starting address of fib(1) in R1

	MOV @R0, #0 ;store 0 which is the higher 8 bits of fib(0) into memory location 40H

	INC R0 ;increase R0 by 1 which is the memory location of lower 8 bits of fib(0)

	MOV @R0, #0 ;store 0 which is the lower 8 bits of fib(0) into the memory location

	MOV @R1, #0 ;store 0 which is higher 8 bits of fib(1) into memory location 41H

	INC R1 ;increase R1 by 1 which is the memory location of lower 8 bits of fib(1)

	MOV @R1, #1 ;store 1 which is the lower 8 bits of fib(1) into memory location

	MOV A, R7 ;move the content of R7 into accumulator

	MOV R6, A ;move the value in accumulator into R6

	DEC R6 ;decrease the value of R6 by 1 because that's the number of time the fibonacci function will execute

	DEC R6 ;decrease the value of R6 by 1 because that's the number of time the fibonacci function will execute

FIB:

	MOV A, @R0 ;move lower 8 bits of fib(N-2) into accumulator

	MOV R2, A ;move the value in accumulator into R2

	DEC R0 ;decrease R0 by 1 to get to the memory location of higher 8 bits of fib(N-2)

	MOV A, @R0 ;move higher 8 bits of fib(N-2) into accumulator

	MOV R3, A ;move the value in accumulator into R3

	MOV A, @R1 ;move lower 8 bits of fib(N-1) into accumulator

	MOV R4, A ;move the value in accumulator into R4

	DEC R1 ;decrease R1 by 1 to get to the memory location of higher 8 bits of fib(N-1)

	MOV A, @R1 ;move higher 8 bits of fib(N-1) into accumulator

	MOV R5, A ;move the value in accumulator into R5

	CLR C ;clear all the carry bit from previous calculation

	MOV A, #0 ;clear the accumulator

	ADD A, R2 ;add 8 lower bits of fib(N-2) with 0

	ADD A, R4 ;add 8 lower bits of fib(N-1) with 8 lower bits of fib(N-2)

	MOV R2, A ;move the sum of 8 lower bits of fib(N-1) and fib(N-2) into R2

	MOV A, R3 ;move 8 higher bits of fib(N-2) into accumulator

	ADDC A, R5 ;sum 8 higher bits of fib(N-2), 8 higher bits of fib(N-1), and carry if any

	MOV R3, A ;move the sum of 8 higher bits of fib(N-1) and fib(N-2) into R3

	INC R1 ;increase R1 by 1 to get to the memory location of 8 lower bits of fib(N-1)

	INC R1 ;increase R1 by 1 to get to the memory location of 8 higher bits of fib(N)

	MOV A, R3 ;move higher 8 bits of fib(N) into accumulator

	MOV @R1, A ;move higher 8 bits of fib(N) into its proper memory location

	INC R1 ;increase R1 by 1 to get to the memory location of 8 lower bits of fib(N)

	MOV A, R2 ;move lower 8 bits of fib(N) into accumulator

	MOV @R1, A ;move lower 8 bits of fib(N) into its proper memory location

	INC R0 ;increase R0 by 1 to get to the memory location of 8 lower bits of fib(N-2)

	INC R0 ;increase R0 by 1 to get to the memory location of 8 higher bits of fib(N-1)

	INC R0 ;increase R0 by 1 to get to the memory location of 8 lower bits of fib(N-1)

	DJNZ R6, FIB ;keeps executing FIB until R6 reaches 0

END
