"""Code generator for the RISC-V assembler."""

from __future__ import print_function

import abc


class CGFileLike(object):
    __metaclass__ = abc.ABCMeta

CGFileLike.register(file)


# A mask covering bits in a RISC-V instruction that maps to the destination
# register.  It also covers the low 5 bits of a base displacement for store
# instructions.
rdMask = 0x1F << 7

# A mask covering bits in a RISC-V instruction that maps to the left-hand
# register in a binary operation.
rs1Mask = 0x1F << 15

# A mask covering bits in a RISC-V instruction that maps to the right-hand
# register in a binary operation.
rs2Mask = 0x1F << 20

# A mask covering bits in a RISC-V instruction that maps to the upper 7 bits
# of a 12-bit offset (e.g., as found in S-format instructions).
ofsHMask = 0x7F << 25

# A mask covering the top 12 bits of a RISC-V instruction, used to hold an
# immediate constant.
imm12Mask = 0xFFF << 20

# A mask covering the top 20 bits of a RISC-V instruction, used to hold an
# immediate constant.
imm20Mask = 0xFFFFF << 12


class RawExporter(object):
    """
    This class knows how to export the contents of a Segment instance as a
    plain binary file.  No relocation information is present in the binary
    image.
    """

    def __init__(self, f):
        assert(isinstance(f, CGFileLike))
        self._out = f

    def exportSegment(self, seg):
        """
	    Attempts to write the contents of the provided segment to the file
        provided during construction of this object.
        """
        self._out.write(bytearray(seg.buf))


class Segment(object):
    """A segment contains assembled code and/or data."""

    def __init__(self):
        self.lc = 0
        self.buf = []

    def size(self):
        """The number of bytes comprising the code segment."""
        return len(self.buf)

    def byte(self, b):
        """Lay down a single 8-bit integer."""
        if self.lc < self.size():
            self.buf[self.lc] = b
        elif self.lc == self.size():
            self.buf.append(b)
        else:  # self.lc > self.size()
            raise Exception("Not implemented")

        self.lc = self.lc + 1

    def hword(self, h):
        """Lay down a single 16-bit integer."""
        self.byte(h & 0xFF)
        self.byte(h >> 8)

    def word(self, w):
        """Lay down a single 32-bit integer."""
        self.hword(w & 0xFFFF)
        self.hword(w >> 16)

    def dword(self, d):
        """Lay down a single 64-bit integer."""
        self.word(d & 0xFFFFFFFF)
        self.word(d >> 32)

    def advance(self, to, fill):
        """
        Advance the location counter to the desired address.  Fill in bytes
        as required with the given fill value.
        """
        while self.lc < to:
            self.byte(fill)

    def getByte(self, at):
        """Retrieves a single byte from the segment."""
        return self.buf[at]

    def getHWord(self, at):
        """Retrieve a 16-bit word at a given address within the segment."""
        return (self.getByte(at+1) << 8) | self.getByte(at)

    def getWord(self, at):
        """Retrieve a 32-bit word at a given address within the segment."""
        return (self.getHWord(at+2) << 16) | self.getHWord(at)

    def putR(self, i, rd, rs1, rs2):
        """
        Place an R-format RISC-V instruction.
        :param int i: The 32-bit instruction word template.  The source and
            destination registers will be overwritten.
        :param int rd: The destination register 0 <= rd < 32.
        :param int rs1: The first (or left-hand) source register.
        :param int rs2: The second (or right-hand) source register.
        """
        self.word(_toR(i, rd, rs1, rs2))

    def putS(self, i, rs, rb, ofs):
        """
        Place an S-format RISC-V instruction.
        :param int i: The 32-bit instruction word template.  The source and
            destination registers will be overwritten.
        :param int rs: The source register to store to memory.
        :param int rb: The base address register.
        :param int ofs: The byte offset from rb to store rs to.
        """
        self.word(_toS(i, rs, rb, ofs))

    def putSB(self, i, r1, r2, ofs):
        """
        Place an SB-format RISC-V instruction, used for conditional branches.
        :param int i: The 32-bit instruction word template.  The source and
            destination registers will be overwritten.
        :param int r1: The left-hand comparison register.
        :param int r2: The right-hand comparison register.
        :param int ofs: The byte offset from the current PC to branch to if the
            condition tested is true.
        """
        self.word(_toSB(i, r1, r2, ofs))

    def putI(self, i, rd, rs1, imm12):
        """
        Place an I-format RISC-V instruction.
        :param int i: The 32-bit instruction word template.  The source and
            destination registers will be overwritten.
        :param int rd: The destination register 0 <= rd < 32.
        :param int rs1: The first (or left-hand) source register.
        :param int imm12: The second (or right-hand) immediate value.
        """
        self.word(_toI(i, rd, rs1, imm12))

    def putUJ(self, i, rd, imm21):
        """
        Place an UJ-format RISC-V instruction, used for unconditional branches.
        :param int i: The 32-bit instruction word template.
        :param int rd: The register to receive the current value of PC after
            the branch takes place.
        :param int imm21: A 21-bit, sign-extended displacement from the current
            PC to jump to.
        """
        self.word(_toUJ(i, rd, imm21))

    def putU(self, i, rd, imm20):
        """
        Place an UJ-format RISC-V instruction, used for unconditional branches.
        :param int i: The 32-bit instruction word template.
        :param int rd: The register to receive the current value of PC after
            the branch takes place.
        :param int imm20: A 32-bit constant, of which the top 20 bits are used
            to set the top 20 bits of the destination register (LUI) or as an
            addend with the PC (AUIPC).
        """
        self.word(_toU(i, rd, imm20))


def _toR(i, rd, rs1, rs2):
    i = i & ~rdMask & ~rs1Mask & ~rs2Mask
    return i | (rd << 7) | (rs1 << 15) | (rs2 << 20)


def _toS(i, rs, rb, ofs):
    ofsL = ofs & 0x1F
    ofsH = ofs >> 5
    i = i & ~rdMask & ~rs1Mask & ~rs2Mask & ~ofsHMask
    return i | (ofsL << 7) | (rb << 15) | (rs << 20) | (ofsH << 25)


def _toSB(i, r1, r2, ofs):
    ofsL = (ofs & 0x1E) | ((ofs & 0x800) >> 11)
    ofsH = ((ofs & 0x7E0) >> 5) | ((ofs & 0x1000) >> 6)
    i = i & ~rdMask & ~ofsHMask & ~rs1Mask & ~rs2Mask
    return i | (ofsL << 7) | (r1 << 15) | (r2 << 20) | (ofsH << 25)


def _toI(i, rd, r1, imm12):
    i = i & ~rdMask & ~rs1Mask & ~imm12Mask
    return i | (rd << 7) | (r1 << 15) | (imm12 << 20)


def _toUJ(i, rd, imm21):
    i = i & ~rdMask & ~imm20Mask
    b19_12 = (imm21 & 0x0FF000) >> 12
    b11 = (imm21 & 0x000800) >> 11
    b10_1 = (imm21 & 0x0007FE) >> 1
    b20 = (imm21 & 0x100000) >> 20
    disp = (b20 << 19) | (b10_1 << 9) | (b11 << 8) | b19_12
    return i | (rd << 7) | (disp << 12)


def _toU(i, rd, imm20):
    i = i & ~rdMask & ~imm20Mask
    return i | (rd << 7) | (imm20 & imm20Mask)
