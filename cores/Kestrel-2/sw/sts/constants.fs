\ T_HUNK identifies a module loadable by loadseg.  This must be the first word of the file.
880 const, T_HUNK

\ T_CODE hunks are formatted with a 1-word size field, followed by that many bytes.  These bytes are loaded into a segment of appropriate size, verbatim.
\ After loading the code hunk, it becomes the "current hunk," on which T_RELOC hunks operate on.
881 const, T_CODE

\ T_END must be the last hunk in a module, informing the loader that it has completed loading and relocating its segment.
882 const, T_END

\ T_RELOC must appear _after_ the T_CODE hunk to which it applies.  It contains a single word which informs the loader how many word-sized offsets follow.
\ Each offset points to a 16-bit word in the T_CODE which is to be relocated relative to the segment.
883 const, T_RELOC


\ Stream Control Block
 0 const, scb_starts
 2 const, scb_ends
 4 const, scb_buffer
 6 const, scb_index	( 0 <= scb_index < sizeof scb_buffer )
 8 const, scb_sector	( scb_starts <= scb_sector <= scb_ends )
10 const, /scb

\ Type 1 Book Keeping Area

 0 const, dir_filenamelen
 1 const, dir_filename
48 const, dir_type

50 const, dirt1_starts
52 const, dirt1_ends

0 const, dirtype_empty
1 const, dirtype_file
2 const, dirtype_volumelabel

