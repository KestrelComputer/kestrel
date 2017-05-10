; The following program was built and converted into Verilog hex-dump
; format with the following commands.  Your assembler may use slightly
; different syntax or command-line options.
;
; Note that the call to xxd and awk must sit on one line or it won't work.
;
; a from example.asm to example.bin
; xxd -g 8 -c 8 example.bin |                                    \
;   awk -e '{print substr($2,15,2)substr($2,13,2)substr($2,11,2) \
;   substr($2,9,2)substr($2,7,2)substr($2,5,2)substr($2,3,2)     \
;   substr($2,1,2);}' >example.hex
;

		adv	$F00, $CC
		jal	1, main		; Call our main program, setting
					; X1 to point at our string.

		byte	"Hello world!",13,10,0
		align	4

main:		jal	2, writeStr	; Write the string the console.
		csrrwi	0, 2, $0FF	; End the simulation successfully.

writeStr:	lb	3, 0(1)		; Get next byte to transmit
		beq	3, 0, done	; If we're done, return.
		ori	3, 3, $100	; Set start bit.
		slli	3, 3, 3		; Send it via OUTPUT.
		csrrw	0, 3, $0FF
		addi	1, 1, 1		; Advance to the next byte.
		jal	0, writeStr	; Repeat as often as necessary.
done:		jalr	0, 0(2)

		adv	$1000, 0
