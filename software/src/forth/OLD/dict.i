; Each Forth word is prefixed with "word header."  This header lets
; the Forth interpreter locate implementations behind various Forth
; words.
; 
; Word headers form a singly-linked list, with the head of the list
; being the most recently defined word on that list.  Note that nodes
; from several lists may be interleaved and yet be completely unaware
; of each other.
;
; If a word header is found at address H, then the implementation for
; that word will appear at H+wh_sizeof.

wh_next		= 0
wh_name		= wh_next+8
wh_len		= wh_name+8
wh_sizeof	= wh_len+8

