warning off
marker ==end==
include asm.f

( Target Image Memory and its Accessors )

: t00.1     -1 ['] t@ catch 0= abort" t00.1 : negative address" drop ;
: t00.2     16384 ['] t@ catch 0= abort" t00.2 : address out of bounds" drop ;
: t00.3     0 ['] t@ catch abort" t00.3 : valid address" drop ;
: t00.4     16382 ['] t@ catch abort" t00.4 : valid address" drop ;
: t00.5     16383 ['] t@ catch 0= abort" t00.5 : one byte out of bounds" drop ;
: t00       t00.1 t00.2 t00.3 t00.4 t00.5 ;
t00

: t01.1     1234 -1 ['] t! catch 0= abort" t01.1 : negative address" 2drop ;
: t01.2     1234 16384 ['] t! catch 0= abort" t01.2 : address out of bounds" 2drop ;
: t01.3     1234 0 ['] t! catch abort" t01.3 : valid address" ;
: t01.4     1234 16382 ['] t! catch abort" t01.4 : valid address" ;
: t01.5     1234 16383 ['] t! catch 0= abort" t01.5 : one byte out of bounds" 2drop ;
: t01       t01.1 t01.2 t01.3 t01.4 t01.5 ;
t01

: t02.1     1234 0 t!  0 t@  1234 xor abort" t02.1 : t! t@ should preserve bit order" ;
: t02       t02.1 ;
t02

( Compilation Pointer )

: t10.1     0 org  there abort" t10.1 : compilation pointer should be reset" ;
: t10       t10.1 ;
t10

: s         0 org 1234 ,, ;
: t11.1     s  there 2 xor abort" t11.1 : Placing data into dictionary must advance ptr" ;
: t11.2     0 t@ 1234 xor abort" t11.2 : I placed 1234" ;
: t11       t11.1 t11.2 ;
t11

( Symbol Table and Related Tools )

: s1        0symtab 15360 org ;
: s2        S" aLabel" defined ;
: t20.1     s1  #syms abort" t20.1 : haven't defined any symbols yet" ;
: t20.2     s1 s2  #syms 1 xor abort" t20.2 : defined only a single symbol" ;
: t20.3     s1 s2  S" aLabel" isDefined? 0= abort" t20.3 : symbol 0 must be defined" ;
: t20.4     s1 s2  0 length 6 xor abort" t20.4 : aLabel has six characters" ;
: t20.5     s1 s2  0 name S" aLabel" compare abort" t20.5 : aLabel should be its name" ;
: t20.6     s1 s2  0 definition 15360 xor abort" t20.6 : I defined it as 15360" ;
: t20.7     s1 s2  0 isImmediate? abort" t20.7 : By default, words shouldn't be immediate" ;
: t20.8     s1 s2  #visible #syms 1- xor abort" t20.8 : I haven't unsmudged the new definition yet" ;
: t20.9     s1 s2  0 isVisible? abort" t20.9 : by default, created words shouldn't be visible" ;
: t20.10    s1 s2  reveal  0 isVisible? 0= abort" t20.10 : revealing should make latest definition visible" ;
: t20       t20.1 t20.2 t20.3 t20.4 t20.5 t20.6 t20.7 t20.8 t20.9 t20.10 ;
t20

: s1        0symtab 15360 org S" aLabel" defined ;
: s2        32767 org S" anotherLabel" defined ;
: t21.1     s1  #syms 1 xor abort" t21.1 : I defined one symbol" ;
: t21.2     s1 s2  #syms 2 xor abort" t21.2 : I defined two symbols" ;
: t21.3     s1 s2  S" aLabel" isDefined? 0= abort" t21.3 : aLabel is defined" ;
: t21.4     s1 s2  S" anotherLabel" isDefined? 0= abort" 21.4 : anotherLabel is defined" ;
: t21.5     s1 s2  0 length 6 xor abort" 21.5 : aLabel's length = 6" ;
: t21.6     s1 s2  1 length 12 xor abort" t21.6 : anotherLabel's length = 12" ;
: t21.7     s1 s2  0 definition 15360 xor abort" t21.7 : aLabel=15360" ;
: t21.8     s1 s2  1 definition 32767 xor abort" t21.8 : anotherLabel=32767" ;
: t21.9     s1 s2 reveal #syms #visible xor abort" t21.9 : #syms=#visible" ;
: t21       t21.1 t21.2 t21.3 t21.4 t21.5 t21.6 t21.7 t21.8 t21.9 ;
t21

==end==
bye

