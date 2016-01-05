; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

; BSPL cannot produce direct-to-ROM-image binaries, so we need to wrap
; its output in something that can.

		include "bios.inc.asm"
		include	"bspl-abi/bspl-regs.i"

; The following extra register definitions are required for the non-BSPL
; code linked into the STS code image.

rt		= ra	; Alias return stack for BSPL and non-BSPL code
rp		= rsp

		include	"romtag.asm"
		include	"stsv1.asm"
		include "hello.asm"
		include "m2.asm"
		include	"m2slides.asm"
		include "fbtest.asm"
		include "blitter.asm"
		include "lbutest.asm"
		include "stsv1.bios.asm"
		include "m2slidesRiscv3.asm"
		include "img.kestrel.asm"
		include "prg.show.asm"

; The following string-compare software comes from a ROM-resident Forth
; interpreter.  It's been unit-tested and shown to work in that project.

		include "compareNames.asm"
		include	"compareNamesUpToLength.asm"

asmstrcmp:	addi	rsp, rsp, -8
		sd	rt, 0(rsp)
		ld	a0, 3*8(dsp)
		ld	a2, 2*8(dsp)
		ld	a1, 1*8(dsp)
		ld	a3, 0(dsp)
		jal	rt, compareNames
		sd	a0, 3*8(dsp)
		addi	dsp, dsp, 24
		ld	rt, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(rt)

; This must always be the last thing to appear in any BSPL program intended
; to run under the Kestrel-3 BIOS.

		include	"bspl-abi/bspl-suffix.asm"
		include "bios.asm"
