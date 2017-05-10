program progmem.ram10
start slide

35 left !  7 top ! S" MILESTONE-4" text
25 left !  8 top ! S" First Application for Kestrel-2" text
31 left ! 10 top ! S" Samuel A. Falvo II" text
35 left ! 11 top ! S" 2012-Dec-10" text

slide S" Some Kestrel-2 Background" title

S" CPU: 16-bit S16X4 (Steamer16 superset)" bullet
S" Program memory: 16K (Expandable to 32K)" bullet
S" Video: Monochrome, bitmapped graphics only" bullet
S" Video memory: 16K" bullet
S" PS/2 keyboard interface" bullet

slide S" Kestrel-2 Memory Map" title
3 top !
 S" 0000 | Program memory |" text  1 top +!  5 left +!
 S" |                |" text  1 top +! -5 left +!
 S" 4000 | Unused         |" text  1 top +! 5 left +!
 S" |" text 17 left +! S" |" text  1 top +! -17 left +!
 S" |" text 17 left +! S" |" text  1 top +! -17 left +!
 S" |" text 17 left +! S" |" text  1 top +! -22 left +!
 S" B000 | I/O            |" text  1 top +!
 S" C000 | Video Memory   |" text  1 top +! 5 left +!
 S" |                |" text

slide S" About Milestone-2 (original)" title

S" Wanted a presentation program written in Forth for years" bullet
S" Wanted ability to draw text, horizontal and vertical lines" bullet
S" Wanted it to retrieve data from flash-based block storage" bullet
S" Wanted it to have a cool, hip name" bullet
S" Wanted a simple domain-specific language to make authoring slides easy" bullet

slide S" About Milestone-2 (reality)" title

S" Written in Machine Forth in 4 days flat" bullet
S" Can draw text.  (It's a start.)" bullet
S" ROM-based retrieval." bullet
S" It became the Kestrel's second milestone, hence its name" bullet
S" Quick and dirty DSL to author slides" bullet

slide S" More about Milestone-2" title

S" Written very nearly entirely using Dr. Harlan Mills' Cleanroom methodology" bullet
S" 'Completed' 5 minutes past midnight on 2012-Sep-22.  :-)" bullet
S" Scope reduction due to starting new employment at Rackspace" bullet
S" This slide deck was finished much later, though." bullet

slide S" Milestone-2 Structure" title

S" Constants" bullet
S" 2KB of Font Data -- mostly unused." bullet
S" Multiplication tables to make up for lack of shifts/multiply instructions" bullet
S" Only 11 variables!" bullet
S" MGIA Driver Code" bullet
S" Graphics Command Language (GCL) Interpreter" bullet
S" User Interface Driver" bullet
1 top +!
S" Full program just barely fits in 4KB of memory!" bullet

slide S" Milestone-2 Development Experience" title

S" Cleanroom code: little to no defects" bullet
S" Mere minutes fixing what few defects were injected" bullet
S" As deadline loomed, corners cut." bullet
S" HOURS fixing defects!" bullet
2 left +!
  S" CREATE instead of CREATE," bullet
  S" Misuse of KIA resulted in flakey UX" bullet
  S" GCL interpreter pointer arithmetic" bullet
40 left +! -3 top +!
  S" Missing #," bullet
  S" Fencepost error in PgDn handler" bullet
  S" Silent redefinition of words" bullet

slide S" Milestone-2 Development Experience (Con't)" title

S" Conclusion: Cleanroom WORKS." bullet
S" 4 days delivery time, despite defects from cut corners!" bullet
S" Spent an average three hours a day" bullet
S" More than 80% of that time spent away from the keyboard" bullet
S" See notebook" bullet

slide S" Lessons Learned from S16X4 Coding" title

S" Return stack NOT needed." bullet
S" Surprisingly useful apps still possible with care" bullet
S" Lack of R-stack forbids continuation management/abuse" bullet
S" Enforced structured programming" bullet
2 left +!
  S" Cleanroom PDL to Forth easier" bullet
  S" Correctness proofs much easier" bullet
  S" Sometimes innovative loop exit conditions needed" bullet
  S" No jump tables in Machine Forth, though" bullet

slide S" Lessons Learned from S16X4 Coding (Con't)" title

S" Multiply instruction desperately needed" bullet
2 left +!
  S" Multiplies by fixed term through look-up table" bullet
  S" Fast, but memory hungry" bullet

slide S" Lessons Learned from S16X4 Coding (Con't)" title

S" JSR instruction desperately needed" bullet
S" A call takes 6 bytes of memory." bullet
2 left +!
  S" |LIT LIT GO  NOP|" text 1 top +!
  S" |Return Addr    |" text 1 top +!
  S" |Subr Address   |" text 1 top +!
-2 left +!
S" JSR insn takes only 2." bullet
2 left +!
  S" |JSR| Subr Addr |" text 1 top +!
-2 left +!
S" Save an est. 1.5KB of ROM" bullet

slide S" Lessons Learned from S16X4 Coding (Con't)" title

S" Flash storage desperately needed" bullet
2 left +!
  S" Font uses 2KB of ROM" bullet
  S" Only used when printing" bullet
-2 left +!
S" I estimate I could save 3.5KB of the 4KB image." bullet

slide S" Navigation" title

S" Home: first slide." bullet
S" End : last" bullet
S" PgDn: next" bullet
S" PgUp: previous" bullet

slide S" Making Slides for Milestone-2 (con't)" title

S" $ gforth slide-asm.fs slides.fs" bullet
S" Cut/paste results into Xilinx IDE" bullet
S" Program FPGA, and hope for the best." bullet

slide S" ok" title

S" Fin." bullet
S" Q & A" bullet

end done

out" slides.bin"
\ To make the final binary, do the following script:
\ 
\ $ gforth asm.fs sdimage.fs				( compile Milestone 2 executable )
\ $ gforth slide-asm.fs slides.fs			( compile slides )
\ $ dd if=slides.bin of=sd.bin bs=1024 count=4 seek=8	( embed slide data into binary image )
\ $ sudo cp sd.bin /dev/sdi				( write blocks to SD card )
\ $ sync						( verify Linux flushes buffers )
\ 
\ The iamge should then boot on any Kestrel with the Milestone-3 bootstrap image.

