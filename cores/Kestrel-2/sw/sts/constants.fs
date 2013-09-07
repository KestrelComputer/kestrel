\ T_HUNK identifies a module loadable by loadseg.  This must be the first word of the file.
880 constant T_HUNK

\ T_CODE hunks are formatted with a 1-word size field, followed by that many bytes.  These bytes are loaded into a segment of appropriate size, verbatim.
\ After loading the code hunk, it becomes the "current hunk," on which T_RELOC hunks operate on.
881 constant T_CODE

\ T_END must be the last hunk in a module, informing the loader that it has completed loading and relocating its segment.
882 constant T_END

\ T_RELOC must appear _after_ the T_CODE hunk to which it applies.  It contains a single word which informs the loader how many word-sized offsets follow.
\ Each offset points to a 16-bit word in the T_CODE which is to be relocated relative to the segment.
883 constant T_RELOC


\ Stream Control Block
0 cells constant scb_starts
1 cells constant scb_ends
2 cells constant scb_buffer
3 cells constant /scb

\ Type 1 Book Keeping Area

 0 constant dir_filenamelen
 1 constant dir_filename
48 constant dir_type

50 constant dirt1_starts
52 constant dirt1_ends

0 constant dirtype_empty
1 constant dirtype_file
2 constant dirtype_volumelabel

