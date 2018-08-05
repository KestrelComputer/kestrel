; Forth VM register allocations
;
; Indirect- or direct-threaded Forth virtual machines define a
; small number of working registers:
;
;	I	(Virtual) Instruction pointer
;	S	(Data) Stack pointer
;	R	Return stack pointer
;	T	Top of data stack
;	W	Current Forth word being executed
;
; To execute the next sequential Forth word, a code fragment
; not too dissimilar to the following is used at the end of
; each Forth primitive or custom CODE word:
;
;	LOAD	W,(I)+
;	JMP	W	; or (W) if indirect-threaded, etc.
;
; For an RV64 environment, this implies that word addresses are
; 64-bits wide.  This is too big to be useful on an environment
; where the dictionary size is expected to be around 12KB.  To
; facilitate smaller dictionary sizes, DX-Forth uses 16-bit
; execution tokens.  This means our inner interpreter must
; first convert these abstract tokens into absolute addresses
; manually.
;
; 	LOAD	W,(I)+
;	ADD	W,DictBase
;	JMP	W
;
; Thus, we introduce a new pseudo-register D to hold the base
; address of the dictionary.

D = s2
I = s1
R = sp
S = s0
T = a0
W = t0

