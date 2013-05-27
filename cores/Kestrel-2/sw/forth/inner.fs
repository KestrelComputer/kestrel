\ Dependencies
\ 
\ pc ( -- a )	Variable	Virtual Program Counter
\ w  ( -- a )	Variable	Virtual Word to Execute (aka Execution Token)

:, _nxt		pc @, @, w !,  pc @, 2 #, +, pc !,  w @, @, go, ;,

\ docolon has a magic constant built-into its definition as a direct result of
\ how dictionary entries appear in RAM.  So as to conserve space, Forth considers
\ only the first three characters of a word's name.
\ 
\	 +-----------------+
\ W ---> | Code Field      | +0
\	 +-----------------+
\	 | Link Field      | +2
\	 +-----------------+
\	 | Length | Name 0 | +4
\	 +-----------------+
\	 | Name 1 | Name 2 | +6
\	 +-----------------+
\	 | (CFA list here) | +8
\	 ~                 ~
\ 
\ NOTE: if the name field ever expands beyond the 3 character + length system
\ used presently, the entire Forth system will need to be rebuilt, as all the
\ relevant offsets will change.  One work-around, of course, is to put a name-
\ field address at offset +4, pointing to the name belonging to the word.
\ It's an extra pointer, but it also yields the smallest possible change to the
\ code.

:, docolon	rc @, -2 #, +, rc !,  pc @, rc @, !,  w @, 8 #, +, pc !,  _nxt ;,
:, doexit	rc @, @, pc !,  rc @, 2 #, +, rc !,  _nxt ;,

