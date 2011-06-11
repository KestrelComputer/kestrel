warning off
marker ==end==
include asm.f

: fetch     t@ drop ;
: t00.1     -1 ['] fetch catch 0= abort" t00.1 : negative address" ;
: t00.2     16384 ['] fetch catch 0= abort" t00.2 : address out of bounds" ;
: t00.3     0 ['] fetch catch abort" t00.3 : valid address" ;
: t00.4     16382 ['] fetch catch abort" t00.4 : valid address" ;
: t00.5     16383 ['] fetch catch 0= abort" t00.5 : one byte out of bounds" ;
: t00       t00.1 t00.2 t00.3 t00.4 t00.5 ;
t00

: t01.1     1234 -1 ['] t! catch 0= abort" t01.1 : negative address" ;
: t01.2     1234 16384 ['] t! catch 0= abort" t01.2 : address out of bounds" ;
: t01.3     1234 0 ['] t! catch abort" t01.3 : valid address" ;
: t01.4     1234 16382 ['] t! catch abort" t01.4 : valid address" ;
: t01.5     1234 16383 ['] t! catch 0= abort" t01.5 : one byte out of bounds" ;
: t01       t01.1 t01.2 t01.3 t01.4 t01.5 ;
t01

: t02.1     1234 0 t!  0 t@  1234 xor abort" t02.1 : t! t@ should preserve bit order" ;
: t02       t02.1 ;
t02

: t10.1     0 org  there abort" t10.1 : compilation pointer should be reset" ;
: t10       t10.1 ;
t10

==end==
bye

