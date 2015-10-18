; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

; BSPL cannot produce direct-to-ROM-image binaries, so we need to wrap
; its output in something that can.

		include	"bspl-abi/csrs.i"
		include "bspl-abi/regs.i"
		include	"bspl-abi/bspl-regs.i"

		include	"stsv1.asm"

		include	"bspl-abi/bspl-suffix.asm"
