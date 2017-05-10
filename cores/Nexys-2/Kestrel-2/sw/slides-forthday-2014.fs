start slide

29 left !  7 top ! S" Compiling for Registers" text
31 left !  9 top ! S" Samuel A. Falvo II" text
35 left ! 10 top ! S" 2014-Nov-15" text


\ \\ \\\\  Five-minute block 1

slide S" Why Compile for Register Machines?" title

S" Registers are everywhere!" bullet
2 left +!
  S" Intel IA32, IA64, AMD-64, and EM64T Processors" bullet
  S" ARM cores -- too many to count" bullet
  S" ColdFire, Parallax, and other embedded microcontrollers" bullet
  S" MIPS, PowerPC, SPARC architectures" bullet
  S" Most recently, Berkeley RISC-V CPUs" bullet
-2 left +!

slide S" Why Compile for Register Machines?" title

S" MISC abandoned for Kestrel-3" bullet
S" Going with RISC-V instead." bullet
2 left +!
  S" Offers best blend of code density and implementation simplicity." bullet
  S" Stack architecture required a CISC-style instruction decoder." bullet
  S" Pure MISC would have gratuitously wasted memory." bullet
-2 left +!

slide S" Aren't Registers Harder to Compile For?" title

S" Yes....ish." bullet
S" But, not impossible!" bullet
S" Algorithmic Toolbox for Competitive Performance" bullet
2 left +!
  S" Abstract Syntax Tree Reconstruction" bullet
  S" Internal Representation: Static Single Assignment" bullet
  S" Register Allocator: Linear Scan or Clairvoyant" bullet
  S" Code Generator: Destination-Directed" bullet
-2 left +!

slide S" Reconstructing the Abstract Syntax Tree" title

S" Boolean operators behave differently inside or outside of IF, WHILE, etc." bullet
S" They can be bit-masks ..." bullet
2 left +!
  S" [CHAR] A [CHAR] Z 1+ WITHIN $20 AND XOR" text 1 top +! 6 left +!
    S" CALL _within" text 1 top +!
    S" AND  EAX,20H" text 1 top +!
    S" XOR  EAX,[EBP]" text 1 top +!
    S" ADD  EBP,4" text 2 top +!
  -6 left +!
-2 left +!

slide S" Reconstructing the Abstract Syntax Tree" title

S" Boolean operators behave differently inside or outside of IF, WHILE, etc." bullet
S" They can be bit-masks ..." bullet
2 left +!
  S" [CHAR] A [CHAR] Z 1+ WITHIN IF $20 XOR THEN" text 1 top +! 2 left +!
    S"     CALL _within" text 1 top +!
    S"     OR   EAX,EAX" text 1 top +!
    S"     JZ   L1" text 1 top +!
    S"     MOV  EAX,[EBP]" text 1 top +!
    S"     ADD  EBP,4" text 1 top +!
    S"     XOR  EAX,20H" text 1 top +!
    S"     JMP  L2" text 1 top +!
    S" L1: MOV  EAX,[EBP]" text 1 top +!
    S"     ADD  EBP,4" text 1 top +!
    S" L2: ..." text 1 top +!
  -2 left +!
-2 left +!

slide S" Reconstructing the Abstract Syntax Tree" title

S" Boolean operators behave differently inside or outside of IF, WHILE, etc." bullet
S" They can be bit-masks, or they can be flag bits, ...." bullet
2 left +!
  S" [CHAR] A [CHAR] Z 1+ WITHIN IF $20 XOR THEN" text 1 top +! 2 left +!
    S"     CMP AL,65" text 1 top +!
    S"     JB  L1" text 1 top +!
    S"     CMP AL,92" text 1 top +!
    S"     JAE L1" text 1 top +!
    S"     XOR EAX,20H" text 1 top +!
    S" L1: ..." text 1 top +!
  -2 left +!
-2 left +!

slide S" Reconstructing the Abstract Syntax Tree" title

S" Boolean operators behave differently inside or outside of IF, WHILE, etc." bullet
S" They can be bit-masks, or they can be flag bits, or simply NOT EXIST!" bullet
2 left +!
  S" [CHAR] A [CHAR] Z 1+ WITHIN IF $20 XOR THEN" text 1 top +! 2 left +!
    S"     ORI X2, X0, 65" text 1 top +!
    S"     BLT X1, X2, L1" text 1 top +!
    S"     ORI X2, X0, 92" text 1 top +!
    S"     BGE X1, X2, L1" text 1 top +!
    S"     ORI X2, X0, 0x20" text 1 top +!
    S"     XOR X1, X1, X2" text 1 top +!
    S" L1: ..." text 1 top +!
  -2 left +!
-2 left +!

slide S" Reconstructing the Abstract Syntax Tree" title

S" Boolean operators behave differently inside or outside of IF, WHILE, etc." bullet
S" They can be bit-masks, or they can be flag bits, or simply NOT EXIST!" bullet
S" The only way to know for sure is to check the context of the expression." bullet
4 left +! 2 top +!
S" [CHAR] A" text 2 top +!
S"    [65]  " text
-4 left +!

slide S" Reconstructing the Abstract Syntax Tree" title

S" Boolean operators behave differently inside or outside of IF, WHILE, etc." bullet
S" They can be bit-masks, or they can be flag bits, or simply NOT EXIST!" bullet
S" The only way to know for sure is to check the context of the expression." bullet
4 left +! 2 top +!
S" [CHAR] A [CHAR] Z" text 2 top +!
S" [65] [91]" text
-4 left +!

slide S" Reconstructing the Abstract Syntax Tree" title

S" Boolean operators behave differently inside or outside of IF, WHILE, etc." bullet
S" They can be bit-masks, or they can be flag bits, or simply NOT EXIST!" bullet
S" The only way to know for sure is to check the context of the expression." bullet
4 left +! 2 top +!
S" [CHAR] A [CHAR] Z 1+" text 2 top +!
S" [65] [92]" text
-4 left +!

slide S" Reconstructing the Abstract Syntax Tree" title

S" Boolean operators behave differently inside or outside of IF, WHILE, etc." bullet
S" They can be bit-masks, or they can be flag bits, or simply NOT EXIST!" bullet
S" The only way to know for sure is to check the context of the expression." bullet
4 left +! 2 top +!
S" [CHAR] A [CHAR] Z 1+ WITHIN" text 2 top +!
S"    [AND]" text 1 top +!
S"   /      \" text 1 top +!
S" [>=]    [<]" text 1 top +!
S"  / \     / \" text 1 top +!
S" x [65] x [92]" text 1 top +!
-4 left +!

slide S" Reconstructing the Abstract Syntax Tree" title

S" Boolean operators behave differently inside or outside of IF, WHILE, etc." bullet
S" They can be bit-masks, or they can be flag bits, or simply NOT EXIST!" bullet
S" The only way to know for sure is to check the context of the expression." bullet
4 left +! 2 top +!
S" [CHAR] A [CHAR] Z 1+ WITHIN IF ... ELSE ... THEN" text 2 top +!
S"           [IF]" text 1 top +!
S"      /      |     \" text 1 top +!
S"    [AND]  .....  ....." text 1 top +!
S"   /      \" text 1 top +!
S" [>=]    [<]" text 1 top +!
S"  / \     / \" text 1 top +!
S" x [65] x [92]" text 1 top +!
-4 left +!

slide S" Static Single Assignment" title

S" Stack cells receive unique names in space AND time." bullet
S" Cells assigned to once and ONLY once." bullet
4 left +!  2 top +!
S"     input           C@     [CHAR] A [CHAR] Z 1+     WITHIN" text  2 top +!

S" | Sa0 = input | Sa1 = *Sa0   | Sa1 = *Sa0   | Sa2 = 65 <= Sa1 < 92 |" text 1 top +!
S" |             |              | Sb0 = 65     |                      |" text 1 top +!
S" |             |              | Sc0 = 92     |                      |" text 1 top +!

slide S" Static Single Assignment" title

S" Stack cells receive unique names in space AND time." bullet
S" Cells assigned to once and ONLY once." bullet
4 left +!  1 top +!
S" Sa0 = input" text 1 top +!
S" Sa1 = *Sa0" text 1 top +!
S" Sb0 = 65" text 1 top +!
S" Sc0 = 92" text 1 top +!
S" Sa2 = (Sb0 <= Sa1 < Sc0)" text 1 top +!
-4 left +!

slide S" Static Single Assignment" title

S" Stack cells receive unique names in space AND time." bullet
S" Cells assigned to once and ONLY once." bullet
S" Essentially, turns any imperative program into a functional program." bullet
S" Substantially eases bookkeeping processes, such as register allocation." bullet
S" NOTE: Equations are a human-readable syntax; internally, only a table." bullet

slide S" Clairvoyant Register Allocation" title

S" Optimal register allocator." bullet
S" SSA form can be traversed forward and backward in time." bullet
S" Allocate registers to SSA terms as needed." bullet
S" If you need to spill," bullet
2 left +!
  S" Prefer to spill a `dead' term first." bullet
  S" Else, prefer to spill a term which is needed furthest in the future." bullet
  S" If more than one candidate, pick one randomly." bullet
-2 left +!

slide S" Linear Scan Register Allocation" title
S" Perhaps 3rd best register allocator you can have." bullet
2 left +!
  S" (2nd is graph coloring allocator, but it's complex.)" text 1 top +!
-2 left +!
S" Requires less state than a complete SSA IR, but," bullet
S" It tends to spill more frequently than necessary:" bullet
2 left +!
  S" Prefer to spill a `dead' term first." bullet
  S" Else, prefer to spill the term which has the longest life." bullet
  S" If more than one candidate, pick one randomly." bullet
-2 left +!

slide S" Regardless of Register Allocation Algorithm...." title

S" Forth CPU stacks 16-deep considered `effectively infinite'." bullet
S" Modern CISC CPUs have 16 registers." bullet
S" Modern RISC CPUs have 31 registers.  (32nd usually hardwired to 0.)" bullet
S" Estimate 4 registers for VM up-keep, that leaves" bullet
2 left +!
  S" between 12 and 27 registers free for crunching data." text 1 top +!
-2 left +!
S" Most Forth computations can work exclusively in registers," bullet
2 left +!
  S" and sync against memory only on entry and exit." text 1 top +!
-2 left +!
S" Stack permutations (even PICK and ROLL) optimized away." bullet

slide S" Applications for Register Compilation" title

S" Anywhere you have tight inner loops (e.g., graphics)" bullet
S" System Software (task switchers, device drivers, ...)" bullet
S" Applications (real-time user interfaces, ...)" bullet
S" Anywhere you have lots of stack permutation (e.g., fuzzy logic, calculus)" bullet

slide S" Limitations of Register Compilation" title

S" Looping tricks discouraged! (BEGIN WHILE WHILE WHILE REPEAT THEN UNTIL)" bullet
S" Relatively complex for interactive environment" bullet
S" No substantial benefit for hierarchical call trees" bullet

slide S" EXAMPLE" title

2 left +!
  S" : F2C,K   32 - 180 / 100 * DUP 273 + ;" text  2 top +!
-2 left +!

slide S" EXAMPLE" title

2 left +!
  S" : F2C,K   32 - 180 / 100 * DUP 273 + ;" text  2 top +!
  S" 1      Sa0=32" text 1 top +!
  S" 2      Sa1=in0 - Sa0" text 1 top +!
  S" 3      Sb0=180" text 1 top +!
  S" 4      Sa2=Sa1 / Sb0" text 1 top +!
  S" 5      Sb1=100" text 1 top +!
  S" 6      Sa3=Sa2 * Sb1" text 1 top +!
  S" 7      Sb2=273" text 1 top +!
  S" 8      Sb3=Sb2+Sa3" text 1 top +!
-2 left +!

slide S" EXAMPLE" title

2 left +!
  S" : F2C,K   32 - 180 / 100 * DUP 273 + ;" text  2 top +!
  S"    1  2  3  4  5  6  7  8  9..." text 1 top +!
  S" 1  ----                      " text 1 top +!
  S" 2     -------                " text 1 top +!
  S" 3        ----                " text 1 top +!
  S" 4           -------          " text 1 top +!
  S" 5              ----          " text 1 top +!
  S" 6                 ---------- " text 1 top +!
  S" 7                    ----    " text 1 top +!
  S" 8                       ---- " text 1 top +!
-2 left +!


slide S" EXAMPLE" title

2 left +!
  S" : F2C,K   32 - 180 / 100 * DUP 273 + ;" text  2 top +!
  S" 1  X2  Sa0=32" text 1 top +!
  S" 2  X3  Sa1=in0 - Sa0" text 1 top +!
  S" 3  X2  Sb0=180" text 1 top +!
  S" 4  X4  Sa2=Sa1 / Sb0" text 1 top +!
  S" 5  X2  Sb1=100" text 1 top +!
  S" 6  X3  Sa3=Sa2 * Sb1" text 1 top +!
  S" 7  X2  Sb2=273" text 1 top +!
  S" 8  X4  Sb3=Sb2+Sa3" text 1 top +!
-2 left +!


slide S" EXAMPLE" title

2 left +!
  S" : F2C,K   32 - 180 / 100 * DUP 273 + ;" text  2 top +!
  S" 1      ori x2,x0,32  | 7      ori x2,x0,273" text 1 top +!
  S" 2      ld  x5,0(sp)  | 8      add x4,x3,x2" text 1 top +!
  S"        sub x3,x5,x2  |        sd  x3,0(sp)" text 1 top +!
  S" 3      ori x2,x0,180 |        sd  x4,-8(sp)" text 1 top +!
  S" 4      div x4,x3,x2  |        sub sp,sp,8" text 1 top +!
  S" 5      ori x2,x0,100 |        jal 0(x1)"     text 1 top +!
  S" 6      mul x3,x4,x2  |" text 1 top +!
-2 left +!

slide S" Fin" title
S" Q & A" bullet

end done
out" sts/imgs/m2.slides"

