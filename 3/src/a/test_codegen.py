import unittest

import codegen


class TestSegment(unittest.TestCase):
    def test_construction(self):
        g = codegen.Segment()
        self.assertEqual(g.lc, 0)
        self.assertEqual(g.size(), 0)

    def test_byte(self):
        g = codegen.Segment()
        g.byte(1)
        self.assertEqual(g.lc, 1)
        self.assertEqual(g.size(), 1)
        self.assertEqual(g.buf[0], 1)

    def test_hword(self):
        g = codegen.Segment()
        g.hword(0x0102)
        self.assertEqual(g.lc, 2)
        self.assertEqual(g.size(), 2)
        self.assertEqual(g.buf[0], 2)
        self.assertEqual(g.buf[1], 1)

    def test_word(self):
        g = codegen.Segment()
        g.word(0x01020304)
        self.assertEqual(g.lc, 4)
        self.assertEqual(g.size(), 4)
        self.assertEqual(g.buf[0], 4)
        self.assertEqual(g.buf[1], 3)
        self.assertEqual(g.buf[2], 2)
        self.assertEqual(g.buf[3], 1)

    def test_dword(self):
        g = codegen.Segment()
        g.dword(0x0102030405060708)
        self.assertEqual(g.lc, 8)
        self.assertEqual(g.size(), 8)
        self.assertEqual(g.buf[0], 8)
        self.assertEqual(g.buf[1], 7)
        self.assertEqual(g.buf[2], 6)
        self.assertEqual(g.buf[3], 5)
        self.assertEqual(g.buf[4], 4)
        self.assertEqual(g.buf[5], 3)
        self.assertEqual(g.buf[6], 2)
        self.assertEqual(g.buf[7], 1)

    def test_advance(self):
        g = codegen.Segment()
        g.word(0xCCCCCCCC)
        g.advance(16, 0xCC)
        self.assertEqual(g.lc, 16)
        self.assertEqual(g.size(), 16)
        for i in range(16):
            self.assertEqual(g.buf[i], 0xCC)

    def test_putR(self):
        g = codegen.Segment()
        g.putR(0xFFFFFFFF, 0, 0, 0)
        self.assertEqual(g.lc, 4)
        self.assertEqual(g.getWord(0), 0xFE00707F)
        g.putR(0xFFFFFFFF, 6, 6, 6)
        self.assertEqual(g.lc, 8)
        self.assertEqual(g.getWord(4), 0xFE63737F)

    def test_putS(self):
        g = codegen.Segment()
        g.putS(0xFFFFFFFF, 30, 6, 0xAAA)
        self.assertEquals(g.lc, 4)
        self.assertEquals(g.getWord(0), 0xABE3757F)

if __name__ == '__main__':
    unittest.main()

