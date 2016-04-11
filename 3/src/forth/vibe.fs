\
\ VIBE Release 2.2
\ Copyright (c) 2001-2016 Samuel A. Falvo II
\ All Rights Reserved.
\
\ Highly portable block editor -- works under nearly every ANS Forth
\ I can think of, and with only a single screenful of words, will
\ work under Pygmy and FS/Forth too.
\
\ USAGE: vibe ( n -- ) Edits block 'n'.  Sets SCR variable to 'n'.
\        ed ( -- ) From Pygmy.  Re-edits last edited block.
\
\ I use CREATE instead of VARIABLE because I can statically initialize
\ the variables at load-time with no overhead.  Stole this idea from a7r
\ in the #Forth IRC channel.
\
\ 2.2 -- Reworked how O works; added x and $, which behave as they do in
\        VIM in command-mode.  D now deletes a line in-place.
\
\ 2.1 -- Fixed stack overflow bugs; forgot to DROP in the non-default
\        key handlers.
\
    
( Editor Constants )

\ I don't like this technique; should have used a bitmap.  Will fix later.
CHAR i tconstant 'i   \ Insert mode
CHAR r tconstant 'r   \ Replace mode
CHAR c tconstant 'c   \ Command mode

CHAR y tconstant 'y
CHAR n tconstant 'n

CHAR A tconstant 'A
CHAR Z tconstant 'Z
CHAR $ tconstant '$

( Editor State )

tuser scr	  \ Current block
tuser x		  \ Cursor X position 0..63
tuser y		  \ Cursor Y position 0..15
tuser mode	  \ Change to bitmap later.
tuser wordname	  \ Temporary buffer for dynamic name lookup

t: 0editor	1 scr ! 0 x ! 0 y ! 'c mode !
		$242405 wordname ! ;

( Editor Display )

t: mode. 63 0 AT-XY mode @ EMIT ;
t: scr. 0 0 AT-XY ." Block: " scr @ . ."      " ;
t: header scr. mode. ;
t: 64-s 64 45 CHARS ;
t: border SPACE 64-s CR ;
t: row DUP 64 TYPE 64 + ;
t: line ." |" row ." |" CR ;
t: 16lines scr @ BLOCK 15 FOR line NEXT DROP ;
t: card 0 1 AT-XY border 16lines border ;
t: cursor x @ 1+ y @ 2 + AT-XY ;
t: screen header card cursor ;

( Editor State Control )

t: insert 'i mode ! ;
t: replace 'r mode ! ;
t: cmd 'c mode ! ;

t: bounds ;
t: prevblock -2 scr +! bounds ;
t: nextblock  2 scr +! bounds ;
t: toggleshadow 1 scr @ XOR scr ! ;

( Editor Cursor Control )

t: 64* 6 LSHIFT ;
t: where scr @ BLOCK SWAP 64* + SWAP + ;
t: wh x @ y @ where ;
t: -space? 33 U< NOT ;
t: flushLeft 0 x ! ;
t: seekLeft BEGIN x @ 0 = IF EXIT THEN wh C@ -space? IF EXIT THEN -1 x +! AGAIN ;
t: flushRight 63 x ! seekLeft ;
t: boundX x @ 0 MAX 63 MIN x ! ;
t: boundY y @ 0 MAX 15 MIN y ! ;
t: bounds boundX boundY ;
t: left -1 x +! bounds ;
t: right 1 x +! bounds ;
t: up -1 y +! bounds ;
t: down 1 y +! bounds ;
t: beep 7 EMIT ;
t: nextline y @ 15 < IF flushLeft down THEN ;
t: nextchar x @ 63 = IF nextline EXIT THEN right ;

( Editor Insert/Replace Text )

t: curln 0 y @ where ;
t: eol 63 y @ where ;
t: place wh C! UPDATE nextchar ;
t: -eol? x @ 63 < ;
t: openr wh DUP 1+ 63 x @ - MOVE ;
t: openRight -eol? IF openr THEN ;
t: inserting? mode @ 'i = ;
t: chr inserting? IF openRight THEN place ;

( Editor Commands: Quit, cursor, block, et. al. )

t: $$c24 DROP flushRight ;            \ $
t: $$c30 DROP flushLeft ;             \ 0
t: $$c49 DROP flushLeft insert ;      \ I
t: $$c51 DROP 0 20 AT-XY R> R> DROP >R ; \ Q -- quits main loop
t: $$c52 DROP replace ;               \ R
t: $$c5B DROP prevblock ;             \ [
t: $$c5C DROP toggleshadow ;          \ \
t: $$c5D DROP nextblock ;             \ ]
t: $$c68 DROP left ;                  \ h
t: $$c69 DROP insert ;                \ i
t: $$c6A DROP down ;                  \ j
t: $$c6B DROP up ;                    \ k
t: $$c6C DROP right ;                 \ l
t: $$i1B DROP cmd ;                   \ (escape)

( Editor Backspace/Delete )

t: padding 32 eol C! UPDATE ;
t: del wh DUP 1+ SWAP 63 x @ - MOVE UPDATE ;
t: delete -eol? IF del THEN padding ;
t: bs left delete ;
t: backspace x @ IF bs THEN ;

t: nextln eol 1+ ;
t: #chrs scr @ BLOCK 1024 + nextln - ;
t: delline nextln curln #chrs MOVE  0 15 where 64 32 FILL ;

( Editor Carriage Return )

t: copydown y @ 14 < IF nextln DUP 64 + #chrs 64 - MOVE THEN ;
t: blankdown nextln 64 32 FILL UPDATE ;
t: splitdown wh nextln 2DUP SWAP - MOVE ;
t: blankrest wh nextln OVER - 32 FILL ;
t: opendown copydown blankdown ;
t: splitline opendown splitdown blankrest ;
t: retrn inserting? IF splitline THEN flushLeft nextline ;
t: return y @ 15 < IF retrn THEN ;
t: vacate flushLeft splitline ;

( Editor Wipe Block )

t: msg 0 20 AT-XY ." Are you sure? (Y/N) " ;
t: valid? DUP 'n = OVER 'y = OR ;
t: uppercase? DUP 'A 'Z 1+ WITHIN ;
t: lowercase DUP uppercase? IF $20 XOR THEN ;
t: validkey BEGIN KEY lowercase valid? UNTIL ;
t: clrmsg 0 20 AT-XY 64 SPACES ;
t: no? msg validkey clrmsg 'n = ;
t: ?confirm no? IF R> DROP THEN ;
t: wipe ?confirm scr @ BLOCK 1024 32 FILL UPDATE 0 x ! 0 y ! ;

( Editor Commands: backspace, delete, et. al. )

t: $$c44 DROP delline ;                   \ D
t: $$c4F DROP vacate insert ;             \ O
t: $$c5A DROP wipe ;                      \ Z
t: $$c6F opendown down $$c49 ;            \ o
t: $$c78 DROP delete ;                    \ x
t: $$i04 DROP delete ;                    \ CTRL-D
t: $$i08 DROP backspace ;                 \ (bs)
t: $$i0D DROP return ;                    \ (cr)
t: $$i7F DROP backspace ;                 \ DEL -- for Unix

( Editor Keyboard Handler )

\ Word name key: $ $ _ _ _
\                    | | |
\ c = command mode --+ | |
\ i = ins/repl mode    | |
\                      | |
\ Key code (hex#) -----+-+
\
\ Called with ( k -- ) where k is the ASCII key code.

t: keyboard KEY ;
t: cmd? mode @ 'c = ;
t: ins? mode @ 'i = mode @ 'r = OR ;
t: mode! ins? 'i AND cmd? 'c AND OR wordname 3 + C! ;
t: >hex DUP 9 > IF 7 + THEN '0 + ;
t: h! DUP $F0 AND 4 RSHIFT >hex wordname 4 + C! ;
t: l! $0F AND >hex wordname 5 + C! ;
t: name! mode! h! l! ;
t: nomapping DROP doLIT beep cmd? AND doLIT chr ins? AND OR ;
t: handlerword name! wordname NAME? IF ELSE nomapping THEN ;
t: handler DUP handlerword EXECUTE ;
t: editor BEGIN keyboard handler screen AGAIN ;
t: ed PAGE screen editor ;
t: vibe scr ! ed ;

