ORG 0H

	MOV R7, #14 ;store N into R7

	MOV R0, #40H ;store the starting address of fib(0) in R0

	MOV R1, #41H ;store the starting address of fib(1) in R1

	MOV @R0, #0 ;store 0 which is fib(0) into memory location 40H

	MOV @R1, #1 ;store 1 which is fib(1) into memory location 41H

	MOV A, R7 ;move the content of R7 into accumulator

	MOV R6, A ;move the value in accumulator into R6

	DEC R6 ;decrease the value of R6 by 1 because that's the number of time the fibonacci function will execute

	DEC R6 ;decrease the value of R6 by 1 because that's the number of time the fibonacci function will execute

FIB:

	MOV A, @R0 ;move the value of fib(N-2) into accumulator

	MOV R2, A ;move the value of fib(N-2) into R2

	MOV A, @R1 ;move the value of fib(N-1) into accumulator

	ADD A, R2 ;add fib(N-1) in accumulator with fib(N-2) in R2

	INC R1 ;increase R1 by 1 so R1 become the address to store fib(N) and will also be the address of fib(N-1) during next iteration

	MOV @R1, A ;store the value in accumulator which is fib(N) into its proper memory location

	INC R0 ;increase R0 by 1 so that R0 becomes the address of fib(N-2) during the next iteration

	DJNZ R6, FIB ;keep executing FIB until R6 reaches 0

END
