"""Code generator for the RISC-V assembler."""

from __future__ import print_function


rdMask = 0x1F << 7
rs1Mask = 0x1F << 15
rs2Mask = 0x1F << 20
ofsHMask = 0x7F << 25


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
        else: # self.lc > self.size()
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


def _toR(i, rd, rs1, rs2):
    i = i & ~rdMask & ~rs1Mask & ~rs2Mask
    return i | (rd << 7) | (rs1 << 15) | (rs2 << 20)


def _toS(i, rs, rb, ofs):
    ofsL = ofs & 0x1F
    ofsH = ofs >> 5
    i = i & ~rdMask & ~rs1Mask & ~rs2Mask & ~ofsHMask
    return i | (ofsL << 7) | (rb << 15) | (rs << 20) | (ofsH << 25)

