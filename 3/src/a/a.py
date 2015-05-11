#!/usr/bin/env python

from __future__ import print_function

import string
import sys
import os


# The lexer has several contexts in which it operates.
#
# fileScope is the default state of the lexer, where it has no idea what the
# next input token will be.
#
# lexingComment is the state where the lexer processes comments.
#
# lexingIdentifier is the state where the lexer is working with what it thinks
# is an identifier.  After processing is complete, the lexer will determine
# what the token actually is (e.g., a keyword, etc.).
#
# lexingDecimalConstant is the state where the lexer is processing a numeric
# constant expressed in decimal.  By contrast, lexingHexConstant is the same,
# but only with hexadecimal representation instead.
#
# lexingString is the state where the lexer is consuming and processing a
# string of text delimited by double-quotes.
fileScope = 0
lexingComment = 1
lexingIdentifier = 2
lexingDecimalConstant = 3
lexingHexConstant = 4
lexingString = 5

# Tokens types are used primarily to identify tokens provided by the program
# listing being processed.  They need not correspond to single syntactic
# structures (which is to say, they need not represent terminals), although
# they usually do.  Some represent entire classes of input (e.g., commentToken
# and binOpToken), while others are more specific (e.g., dwordToken).
commentToken = 1
identifierToken = 2
integerToken = 3
characterToken = 4
binOpToken = 5
stringToken = 6
dwordToken = 100
wordToken = 101
hwordToken = 102
byteToken = 103
advanceToken = 104
jalToken = 200
luiToken = 201
auipcToken = 202
addiToken = 203
slliToken = 204
sltiToken = 205
sltiuToken = 206
xoriToken = 207
srliToken = 208
sraiToken = 209
oriToken = 210
andiToken = 211
csrrwiToken = 212
csrrsiToken = 213
csrrciToken = 214
addiwToken = 215
slliwToken = 216
srliwToken = 217
sraiwToken = 218
jalrToken = 219
lbToken = 220
lhToken = 221
lwToken = 222
ldToken = 223
lbuToken = 224
lhuToken = 225
lwuToken = 226
sbToken = 227
shToken = 228
swToken = 229
sdToken = 230
beqToken = 231
bneToken = 232
bltToken = 233
bgeToken = 234
bltuToken = 235
bgeuToken = 236
addToken = 237
subToken = 238
sllToken = 239
sltToken = 240
sltuToken = 241
xorToken = 242
srlToken = 243
sraToken = 244
orToken = 245
andToken = 246
addwToken = 247
subwToken = 248
sllwToken = 249
srlwToken = 250
srawToken = 251

endOfInputToken = 999

# When evaluating expressions, we need to know what functions to perform when.
# These indicate the kind of expression nodes used, so we can invoke the
# correct functions.
EN_ADD = 1
EN_SUB = 2
EN_MUL = 3
EN_DIV = 4
EN_NEG = 5
EN_INT = 6
EN_ID = 7
EN_STR = 8

lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
startOfIdentifierChars = lowercaseLetters + uppercaseLetters + '_'
decimalDigits = "0123456789"
completeIdentifierCharSet = startOfIdentifierChars + decimalDigits
hexDigits = decimalDigits + uppercaseLetters[:6]

# Infix arithmetic operators have precedence rules associated with them.
precedenceTable = {
    "*": 20, "/": 20,
    "+": 10, "-": 10,
}


def syntaxError(asm, tok):
    print("Syntax error on line {} near {}".format(asm.getLine(), tok.string))


def toS(x):
    return ((x & 0x1F) << 7) | ((x >> 5) << 25)


def toSB(x):
    return (
        ((x & 0x1E) << 7)
        | ((x & 800) >> 4)
        | ((x & 0x7E0) << 20)
        | ((x & 0x1000) << 19)
    )


def toUJ(x):
    return (
        ((x & 0x100000) << 11)
        | ((x & 0x0007FE) << 20)
        | ((x & 0x000800) << 9)
        | (x & 0x0FF000)
    )

class ExprNode(object):
    def __init__(self, kind, a=None, b=None):
        self.kind = kind
        self.a = a
        self.b = b


class Advance(object):
    def __init__(self, nBytes, fill):
        self.a = nBytes
        self.b = fill
        self.c = None

    def asBytes(self, asm):
        nBytes = evalExpression(asm, self.a)
        fill = evalExpression(asm, self.b)
        if nBytes.kind != EN_INT:
            raise Exception("Expected integer for target")
        if fill.kind != EN_INT:
            raise Exception("Expected integer for fill byte")
        nBytes = nBytes.a
        fill = fill.a & 0xFF
        return [fill] * nBytes

class Declaration(object):
    def __init__(self, value, size):
        self.a = value
        self.b = None
        self.c = None
        self.size = size

    def asBytes(self, _):
        bs = []

        if self.a.kind == EN_INT:
            v = self.a.a
            for _ in range(self.size):
                b = v & 0xFF
                v = v >> 8
                bs = bs + [b]
        elif self.a.kind == EN_STR:
            for c in self.a.a:
                bs = bs + [ord(c)]
        else:
            raise Exception(
                "Unknown constant type ({})".format(self.a.kind)
            )

        return bs

class RInsn(object):
    def __init__(self, insn, rd, rs1, rs2):
        self.insn = insn
        self.a = rd
        self.b = rs1
        self.c = rs2

    def asBytes(self, asm):
        bs = []
        rd = evalExpression(asm, self.a)
        rs1 = evalExpression(asm, self.b)
        rs2 = evalExpression(asm, self.c)
        if rd.kind != EN_INT:
            raise Exception("Integer expected for destination register")
        if rs1.kind != EN_INT:
            raise Exception("Integer expected for src1 register")
        if rs2.kind != EN_INT:
            raise Exception("Integer expected for src2 register")
        rd = rd.a
        rs1 = rs1.a
        rs2 = rs2.a

        i = self.insn | (rd << 7) | (rs1 << 15) | (rs2 << 20)
        for _ in range(4):
            bs = bs + [i & 0xFF]
            i = i >> 8

        return bs


class SInsn(object):
    def __init__(self, lc, insn, rs1, disp, rs2):
        self.lc = lc
        self.insn = insn
        self.a = rs1
        self.b = disp
        self.c = rs2

    def asBytes(self, asm):
        bs = []
        rs1 = evalExpression(asm, self.a)
        rs2 = evalExpression(asm, self.c)
        disp = evalExpression(asm, self.b)

        if rs1.kind != EN_INT:
            raise Exception("Integer expected for src1 reg expression")
        if rs2.kind != EN_INT:
            raise Exception("Integer expected for src2 reg expression")
        if disp.kind != EN_INT:
            print("KIND({})".format(disp.kind), disp.a, disp.b)
            raise Exception("Integer expected for displacement")
        rs1 = rs1.a
        rs2 = rs2.a
        disp = disp.a

        i = (
            self.insn
            | toS(disp)
            | (rs1 << 15)
            | (rs2 << 20)
        )
        for _ in range(4):
            bs = bs + [i & 0xFF]
            i = i >> 8
        return bs

class SBInsn(SInsn):
    def asBytes(self, asm):
        bs = []
        rs1 = evalExpression(asm, self.a)
        rs2 = evalExpression(asm, self.c)
        disp = evalExpression(asm, self.b)

        if rs1.kind != EN_INT:
            raise Exception("Integer expected for src1 reg expression")
        if rs2.kind != EN_INT:
            raise Exception("Integer expected for src2 reg expression")
        if disp.kind != EN_INT:
            raise Exception("Integer expected for displacement")
        rs1 = rs1.a
        rs2 = rs2.a
        disp = disp.a

        i = (
            self.insn
            | toSB(disp - (self.lc + 4))
            | (rs1 << 15)
            | (rs2 << 20)
        )
        for _ in range(4):
            bs = bs + [i & 0xFF]
            i = i >> 8
        return bs


class IInsn(object):
    def __init__(self, insn, rd, rs, imm12):
        self.insn = insn
        self.a = rd
        self.b = rs
        self.c = imm12

    def asBytes(self, asm):
        bs = []
        rd = evalExpression(asm, self.a)
        rs = evalExpression(asm, self.b)
        imm12 = evalExpression(asm, self.c)

        if rd.kind != EN_INT:
            raise Exception("Integer expected for dest reg expression")
        if rs.kind != EN_INT:
            raise Exception("Integer expected for src reg expression")
        if imm12.kind != EN_INT:
            raise Exception("Integer expected for immediate value")
        rd = rd.a & 0x1F
        rs = rs.a & 0x1F
        imm12 = imm12.a & 0xFFF

        i = self.insn | (rd << 7) | (rs << 15) | (imm12 << 20)
        for _ in range(4):
            bs = bs + [i & 0xFF]
            i = i >> 8
        return bs


class IMInsn(IInsn):
    pass


class UInsn(object):
    def __init__(self, insn, rd, imm20):
        self.insn = insn
        self.a = rd
        self.b = imm20
        self.c = None

    def asBytes(self, asm):
        bs = []
        rd = evalExpression(asm, self.a)
        imm20 = evalExpression(asm, self.b)
        if (rd.kind != EN_INT) or (imm20.kind != EN_INT):
            raise Exception("Pass 2 error: Undefined symbols?")
        rd = rd.a
        imm20 = imm20.a

        i = self.insn | (rd << 7) | (imm20 & 0xFFFFF000)
        for _ in range(4):
            bs = bs + [i & 0xFF]
            i = i >> 8
        return bs




class UJInsn(object):
    def __init__(self, lc, insn, rd, disp):
        self.lc = lc
        self.insn = insn
        self.a = rd
        self.b = disp
        self.c = None

    def asBytes(self, asm):
        bs = []
        rd = evalExpression(asm, self.a)
        disp = evalExpression(asm, self.b)
        if (rd.kind != EN_INT) or (disp.kind != EN_INT):
            raise Exception("Pass 2 error: Undefined symbols?")
        rd = rd.a & 0x1F
        disp = disp.a & 0x3FFFFE

        i = self.insn | (rd << 7) | toUJ(disp - (self.lc + 4))
        for _ in range(4):
            bs = bs + [i & 0xFF]
            i = i >> 8
        return bs


class Token(object):
    def __init__(self, tt, tv, string=None):
        self.tokenType = tt
        self.tokenValue = tv
        if string:
            self.string = string
        else:
            self.string = str(tv)


def kindOfIdentifier(s):
    s = string.upper(s)
    kindMap = {
        'DWORD': dwordToken,
        'WORD': wordToken,
        'HWORD': hwordToken,
        'BYTE': byteToken,
        'ADV': advanceToken,
        'JAL': jalToken,
        'LUI': luiToken,
        'AUIPC': auipcToken,
        'ADDI': addiToken,
        'SLLI': slliToken,
        'SLTI': sltiToken,
        'SLTIU': sltiuToken,
        'XORI': xoriToken,
        'SRLI': srliToken,
        'SRAI': sraiToken,
        'ORI': oriToken,
        'ANDI': andiToken,
        'CSRRWI': csrrwiToken,
        'CSRRSI': csrrsiToken,
        'CSRRCI': csrrciToken,
        'ADDIW': addiwToken,
        'SLLIW': slliwToken,
        'SRLIW': srliwToken,
        'SRAIW': sraiwToken,
        'JALR': jalrToken,
        'LB': lbToken,
        'LH': lhToken,
        'LW': lwToken,
        'LD': ldToken,
        'LBU': lbuToken,
        'LHU': lhuToken,
        'LWU': lwuToken,
        'SB': sbToken,
        'SH': swToken,
        'SW': shToken,
        'SD': sdToken,
        'BEQ': beqToken,
        'BNE': bneToken,
        'BLT': bltToken,
        'BGE': bgeToken,
        'BLTU': bltuToken,
        'BGEU': bgeuToken,
        'ADD': addToken,
        'SUB': subToken,
        'SLL': sllToken,
        'SLT': sltToken,
        'SLTU': sltuToken,
        'XOR': xorToken,
        'SRL': srlToken,
        'SRA': sraToken,
        'OR': orToken,
        'AND': andToken,
        'ADDW': addwToken,
        'SUBW': subwToken,
        'SLLW': sllwToken,
        'SRLW': srlwToken,
        'SRAW': srawToken,
    }
    return kindMap.get(s, identifierToken)


def integerExpressionHandler(asm, tok, prec):
    return ExprNode(EN_INT, tok.tokenValue)


def identifierExpressionHandler(asm, tok, prec):
    v = asm.getSymbol(tok.tokenValue)
    if v is not None:
        return v
    else:
        return ExprNode(EN_ID, tok.tokenValue)


def unaryOperatorHandler(asm, tok, prec):
    if tok.tokenValue == '+':
        return expression(asm, precedenceTable['+']+1)

    if tok.tokenValue == '-':
        return ExprNode(EN_NEG, expression(asm, precedenceTable['-']+1))

    if tok.tokenValue == '*':
        return ExprNode(EN_INT, asm.getLC())

    syntaxError(asm, tok)


def expectCharacter(asm, ch):
    t = asm.getToken()
    if t.tokenType != characterToken or t.tokenValue != ch:
        syntaxError(asm, t)
    asm.eatToken()


def expectReg(asm):
    r = expression(asm, 0)
    expectCharacter(asm, ",")
    return r


def expectEA(asm):
    disp = expression(asm, 0)
    expectCharacter(asm, "(")
    r = expression(asm, 0)
    expectCharacter(asm, ")")
    return disp, r


def characterPrefixHandler(asm, tok, prec):
    if tok.tokenValue == '(':
        v = expression(asm, 0)
        expectCharacter(asm, ')')
        return v

    syntaxError(asm, tok)


prefixHandlers = {
    integerToken: integerExpressionHandler,
    identifierToken: identifierExpressionHandler,
    binOpToken: unaryOperatorHandler,
    characterToken: characterPrefixHandler,
    stringToken: lambda x, y, z: ExprNode(EN_STR, y.tokenValue),
}


def getPrefixHandler(tt):
    def exprSyntaxError(asm, tok, prec):
        return syntaxError(asm, tok)

    if tt not in prefixHandlers:
        return exprSyntaxError

    return prefixHandlers[tt]


def commentHandler(asm, tok):
    """ Do nothing; we're a comment. """


def getPrecedence(op):
    return precedenceTable.get(op, -1)


def evalExpression(asm, root):
    if root.kind == EN_ADD:
        l = evalExpression(asm, root.a)
        r = evalExpression(asm, root.b)
        if l.kind == EN_INT and r.kind == EN_INT:
            return ExprNode(EN_INT, l.a + r.a)
        else:
            return root
    elif root.kind == EN_SUB:
        l = evalExpression(asm, root.a)
        r = evalExpression(asm, root.b)
        if l.kind == EN_INT and r.kind == EN_INT:
            return ExprNode(EN_INT, l.a - r.a)
        else:
            return root
    elif root.kind == EN_MUL:
        l = evalExpression(asm, root.a)
        r = evalExpression(asm, root.b)
        if l.kind == EN_INT and r.kind == EN_INT:
            return ExprNode(EN_INT, l.a * r.a)
        else:
            return root
    elif root.kind == EN_DIV:
        l = evalExpression(asm, root.a)
        r = evalExpression(asm, root.b)
        if l.kind == EN_INT and r.kind == EN_INT:
            return ExprNode(EN_INT, l.a / r.a)
        else:
            return root
    elif root.kind == EN_NEG:
        e = evalExpression(asm, root.a)
        if e.kind == EN_INT:
            return ExprNode(EN_INT, -e.a)
        else:
            return root
    elif root.kind == EN_ID:
        v = asm.getSymbol(root.a)
        if v is not None:
            return v
        else:
            return root
    elif root.kind == EN_INT:
        return root
    else:
        raise Exception("Unhandled expression node type: {}".format(root.kind))


def constantExpression(asm, prec):
    e = evalExpression(asm, expression(asm, prec))
    if e.kind != EN_INT:
        raise Exception("Constant expression expected.")
    return e.a


def expression(asm, prec):
    opTable = {
        '+': lambda x, y: ExprNode(EN_ADD, x, y),
        '-': lambda x, y: ExprNode(EN_SUB, x, y),
        '*': lambda x, y: ExprNode(EN_MUL, x, y),
        '/': lambda x, y: ExprNode(EN_DIV, x, y),
    }

    t = asm.nextToken()
    lhs = getPrefixHandler(t.tokenType)(asm, t, prec)

    top = asm.getToken()
    while getPrecedence(top.tokenValue) >= prec:
        asm.eatToken()
        rhs = expression(asm, getPrecedence(top.tokenValue)+1)
        lhs = opTable[top.tokenValue](lhs, rhs)
        top = asm.getToken()

    return lhs


def labelOrAssignmentHandler(asm, tok):
    t = asm.getToken()
    if t.tokenType != characterToken:
        syntaxError(asm, tok)

    elif t.tokenValue == '=':
        asm.eatToken()
        v = expression(asm, 0)
        asm.setSymbol(tok.tokenValue, v)

    elif t.tokenValue == ':':
        asm.eatToken()
        v = asm.getLC()
        asm.setSymbol(tok.tokenValue, ExprNode(EN_INT, v))

    else:
        syntaxError(asm, tok)


def declareConstantHandler(asm, tok):
    recorderMap = {
        dwordToken: asm.recordDWord,
        wordToken: asm.recordWord,
        hwordToken: asm.recordHWord,
        byteToken: asm.recordByte,
    }
    recorder = recorderMap[tok.tokenType]
    while True:
        recorder(expression(asm, 0))
        t = asm.getToken()
        if t.tokenType != characterToken:
            break
        if t.tokenValue != ',':
            break
        asm.eatToken()


def advanceHandler(asm, tok):
    eTarget = ExprNode(EN_INT, constantExpression(asm, 0))
    expectCharacter(asm, ",")
    eFill = expression(asm, 0)
    asm.recordAdvance(eTarget, eFill)


def jalHandler(asm, tok):
    rd = expectReg(asm)
    disp = expression(asm, 0)
    asm.recordUJ(0x0000006F, rd, disp)


def genericUHandler(asm, tok, insn):
    rd = expectReg(asm)
    imm20 = expression(asm, 0)
    asm.recordU(insn, rd, imm20)


def genericIHandler(asm, tok, insn):
    rd = expectReg(asm)
    rs = expectReg(asm)
    imm12 = expression(asm, 0)
    asm.recordI(insn, rd, rs, imm12)


def genericIMHandler(asm, tok, insn):
    rd = expectReg(asm)
    disp, rs1 = expectEA(asm)
    asm.recordIM(insn, rd, rs1, disp)


def genericSHandler(asm, tok, insn):
    rs2 = expectReg(asm)
    disp, rs1 = expectEA(asm)
    asm.recordS(insn, rs1, disp, rs2)


def genericSBHandler(asm, tok, insn):
    rs1 = expectReg(asm)
    rs2 = expectReg(asm)
    disp = expression(asm, 0)
    asm.recordSB(insn, rs1, rs2, disp)


def genericRHandler(asm, tok, insn):
    rd = expectReg(asm)
    rs1 = expectReg(asm)
    rs2 = expression(asm, 0)
    asm.recordR(insn, rd, rs1, rs2,)


fileScopeHandlers = {
    commentToken: commentHandler,
    identifierToken: labelOrAssignmentHandler,
    dwordToken: declareConstantHandler,
    wordToken: declareConstantHandler,
    hwordToken: declareConstantHandler,
    byteToken: declareConstantHandler,
    advanceToken: advanceHandler,
    jalToken: jalHandler,
    luiToken: lambda a, t: genericUHandler(a, t, 0x00000037),
    auipcToken: lambda a, t: genericUHandler(a, t, 0x00000017),
    addiToken: lambda a, t: genericIHandler(a, t, 0x00000013),
    slliToken: lambda a, t: genericIHandler(a, t, 0x00001013),
    sltiToken: lambda a, t: genericIHandler(a, t, 0x00002013),
    sltiuToken: lambda a, t: genericIHandler(a, t, 0x00003013),
    xoriToken: lambda a, t: genericIHandler(a, t, 0x00004013),
    srliToken: lambda a, t: genericIHandler(a, t, 0x00005013),
    sraiToken: lambda a, t: genericIHandler(a, t, 0x40005013),
    oriToken: lambda a, t: genericIHandler(a, t, 0x00006013),
    andiToken: lambda a, t: genericIHandler(a, t, 0x00007013),
    csrrwiToken: lambda a, t: genericIHandler(a, t, 0x00005073),
    csrrsiToken: lambda a, t: genericIHandler(a, t, 0x00006073),
    csrrciToken: lambda a, t: genericIHandler(a, t, 0x00007073),
    addiwToken: lambda a, t: genericIHandler(a, t, 0x0000001B),
    slliwToken: lambda a, t: genericIHandler(a, t, 0x0000101B),
    srliwToken: lambda a, t: genericIHandler(a, t, 0x0000501B),
    sraiwToken: lambda a, t: genericIHandler(a, t, 0x4000501B),
    jalrToken: lambda a, t: genericIMHandler(a, t, 0x00000067),
    lbToken: lambda a, t: genericIMHandler(a, t, 0x00000003),
    lhToken: lambda a, t: genericIMHandler(a, t, 0x00001003),
    lwToken: lambda a, t: genericIMHandler(a, t, 0x00002003),
    ldToken: lambda a, t: genericIMHandler(a, t, 0x00003003),
    lbuToken: lambda a, t: genericIMHandler(a, t, 0x00004003),
    lhuToken: lambda a, t: genericIMHandler(a, t, 0x00005003),
    lwuToken: lambda a, t: genericIMHandler(a, t, 0x00006003),
    sbToken: lambda a, t: genericSHandler(a, t, 0x00000023),
    shToken: lambda a, t: genericSHandler(a, t, 0x00001023),
    swToken: lambda a, t: genericSHandler(a, t, 0x00002023),
    sdToken: lambda a, t: genericSHandler(a, t, 0x00003023),
    beqToken: lambda a, t: genericSBHandler(a, t, 0x00000063),
    bneToken: lambda a, t: genericSBHandler(a, t, 0x00001063),
    bltToken: lambda a, t: genericSBHandler(a, t, 0x00004063),
    bgeToken: lambda a, t: genericSBHandler(a, t, 0x00005063),
    bltuToken: lambda a, t: genericSBHandler(a, t, 0x00006063),
    bgeuToken: lambda a, t: genericSBHandler(a, t, 0x00007063),
    addToken: lambda a, t: genericRHandler(a, t, 0x00000033),
    subToken: lambda a, t: genericRHandler(a, t, 0x40000033),
    sllToken: lambda a, t: genericRHandler(a, t, 0x00001033),
    sltToken: lambda a, t: genericRHandler(a, t, 0x00002033),
    sltuToken: lambda a, t: genericRHandler(a, t, 0x00003033),
    xorToken: lambda a, t: genericRHandler(a, t, 0x00004033),
    srlToken: lambda a, t: genericRHandler(a, t, 0x00005033),
    sraToken: lambda a, t: genericRHandler(a, t, 0x40005033),
    orToken: lambda a, t: genericRHandler(a, t, 0x00006033),
    andToken: lambda a, t: genericRHandler(a, t, 0x00007033),
    addwToken: lambda a, t: genericRHandler(a, t, 0x0000003B),
    subwToken: lambda a, t: genericRHandler(a, t, 0x4000003B),
    sllwToken: lambda a, t: genericRHandler(a, t, 0x0000103B),
    srlwToken: lambda a, t: genericRHandler(a, t, 0x0000503B),
    srawToken: lambda a, t: genericRHandler(a, t, 0x4000503B),
}


def fileScopeHandler(tt):
    if tt not in fileScopeHandlers:
        return syntaxError

    return fileScopeHandlers[tt]


class Assembler(object):
    """The Assembler class encapsulates the state of the assembler as a whole.
    """

    def __init__(self, args):
        """Initializes the assembler to a known good state."""
        self.args = args
        self.lexerState = fileScope
        self.tokenStream = []
        self.cursor = 0
        self.line = 0
        self.symbols = {}
        self.section = []
        self.lc = 0
        self.pass2todo = []

    def _defer(self, obj):
        """This is a two-pass assembler.  While parsing commences in pass one,
        we need to record a list of instructions to execute during pass two.
        The _defer function records a single step for later processing during
        pass two.
        """
        self.pass2todo = self.pass2todo + [obj]

    def recordDWord(self, dw):
        """Records an arbitrary, 64-bit quantity to the object file.
        Note that this method does NOT align the generated bytes to an 8-byte
        boundary first.
        """
        self._defer(Declaration(dw, 8))
        sz = 8
        if dw.kind == EN_STR:
            sz = 8*len(dw.a)
        self.lc = self.lc + sz

    def recordWord(self, w):
        """Records an arbitrary, 32-bit quantity to the object file.
        Note that this method does NOT align the generated bytes to an 4-byte
        boundary first.
        """
        self._defer(Declaration(w, 4))
        sz = 4
        if w.kind == EN_STR:
            sz = 4*len(w.a)
        self.lc = self.lc + sz

    def recordHWord(self, h):
        """Records an arbitrary, 16-bit quantity to the object file.
        Note that this method does NOT align the generated bytes to an 2-byte
        boundary first.
        """
        self._defer(Declaration(h, 2))
        sz = 2
        if h.kind == EN_STR:
            sz = 2*len(h.a)
        self.lc = self.lc + sz

    def recordByte(self, b):
        """Records an arbitrary, 8-bit quantity to the object file."""
        self._defer(Declaration(b, 1))
        sz = 1
        if b.kind == EN_STR:
            sz = len(b.a)
        self.lc = self.lc + sz

    def recordAdvance(self, target, fill):
        """When the programmer specifies the ADV mnemonic, this method is
        called to record its behavior for pass two.
        """
        self._defer(Advance(ExprNode(EN_INT, target.a - self.lc), fill))
        if self.lc < target.a:
            self.lc = target.a

    def recordR(self, insn, rd, rs1, rs2):
        """Records all 3-register operations"""
        self._defer(RInsn(insn, rd, rs1, rs2))
        self.lc = self.lc + 4

    def recordSB(self, insn, rs1, rs2, disp):
        """Records all conditional branch instructions."""
        self._defer(SBInsn(self.lc, insn, rs1, disp, rs2))
        self.lc = self.lc + 4

    def recordS(self, insn, rs1, disp, rs2):
        """Records all store instructions."""
        self._defer(SInsn(None, insn, rs1, disp, rs2))
        self.lc = self.lc + 4

    def recordIM(self, insn, rd, rs, disp):
        """Records all loads and the JALR instructions."""
        self._defer(IMInsn(insn, rd, rs, disp))
        self.lc = self.lc + 4

    def recordI(self, insn, rd, rs, imm12):
        """Records all instructions of the general form INSN rd, rs, imm12"""
        self._defer(IInsn(insn, rd, rs, imm12))
        self.lc = self.lc + 4

    def recordU(self, insn, rd, imm20):
        """Records a LUI or AUIPC instruction."""
        self._defer(UInsn(insn, rd, imm20))
        self.lc = self.lc + 4

    def recordUJ(self, insn, rd, disp):
        """Records an unconditional jump."""
        self._defer(UJInsn(self.lc, insn, rd, disp))
        self.lc = self.lc + 4

    def getLC(self):
        """Retrieves the current location counter."""
        return self.lc

    def setSymbol(self, name, value):
        """Sets a global symbol."""
        assert(type(value).__name__ == "ExprNode")
        self.symbols[name] = value

    def getSymbol(self, name):
        """Retrieves a global symbol; this returns None if the symbol
        is not defined.
        """
        return self.symbols.get(name)

    def tokenTransition(self, ch, token):
        """When transitioning from one kind of lexed token to another, this
        method is invoked.  It takes care of appending the token to the current
        input stream, and resets the lexer for processing the next input
        token.
        """
        self.tokenStream = self.tokenStream + [token]
        self.string = ""
        self.lexerState = fileScope
        self.lexChar(ch)

    def getToken(self):
        """Retrieves the next token in the input stream.  This method does
        NOT pop the token off the input stream.  Use this method for look-
        ahead.
        """
        if self.cursor < len(self.tokenStream):
            return self.tokenStream[self.cursor]
        else:
            return Token(endOfInputToken, None)

    def eatToken(self):
        """Advances the token cursor by one, effectively popping the current
        token off the input stream.  If no further tokens exist, nothing
        happens.
        """
        if self.cursor < len(self.tokenStream):
            self.cursor = self.cursor + 1

    def nextToken(self):
        """Retrieves the next token in the input stream, and pops it.
        """
        t = self.getToken()
        self.eatToken()
        return t

    def getLine(self):
        """Retrieves the current source code line number."""
        return self.line

    def lexEOL(self):
        """Completes line processing by the lexer, and commences parsing.
        When it's done, the input stream will be completely consumed, ready
        for the next line.
        """
        self.cursor = 0
        self.line = self.line + 1
        t = self.nextToken()
        while t.tokenType != endOfInputToken:
            fileScopeHandler(t.tokenType)(self, t)
            t = self.nextToken()

        self.tokenStream = []

    def lexChar(self, ch):
        """Attempt to process a character during pass-1 assembly."""

        if self.lexerState == fileScope:
            # Do nothing if encountering whitespace
            if ch in [' ', '\t', '\n', '\r']:
                return

            # Detect comments
            if ch == ';':
                self.string = ""
                self.lexerState = lexingComment
                return

            # Detect quoted strings
            if ch == '"':
                self.string = ""
                self.lexerState = lexingString
                return

            # Detect identifiers and keywords
            if ch in startOfIdentifierChars:
                self.string = ch
                self.lexerState = lexingIdentifier
                return

            # Detect decimal integers
            if ch in decimalDigits:
                self.string = ch
                self.lexerState = lexingDecimalConstant
                return

            # Detect hexadecimal integers
            if ch == "$":
                self.string = ""
                self.lexerState = lexingHexConstant
                return

            # Miscellaneous
            if ch in precedenceTable:
                self.tokenStream = self.tokenStream + [Token(binOpToken, ch)]
            else:
                self.tokenStream = self.tokenStream + [
                    Token(characterToken, ch)
                ]

            return

        elif self.lexerState == lexingComment:
            # Any character is valid inside a comment except for \n, \r.
            if ch in ['\n', '\r']:
                return self.tokenTransition(
                    ch, Token(commentToken, self.string)
                )

            self.string = self.string + ch
            return

        elif self.lexerState == lexingString:
            if ch == '"':
                return self.tokenTransition(
                    ' ', Token(stringToken, self.string)
                )
            self.string = self.string + ch
            return

        elif self.lexerState == lexingIdentifier:
            if ch not in completeIdentifierCharSet:
                kind = kindOfIdentifier(self.string)
                return self.tokenTransition(ch, Token(kind, self.string))

            self.string = self.string + ch
            return

        elif self.lexerState == lexingDecimalConstant:
            if ch not in decimalDigits:
                return self.tokenTransition(
                    ch, Token(integerToken, int(self.string))
                )

            self.string = self.string + ch
            return

        elif self.lexerState == lexingHexConstant:
            if string.upper(ch) not in hexDigits:
                return self.tokenTransition(
                    ch,
                    Token(
                        integerToken, int(self.string, 16),
                        string=self.string
                    )
                )

            self.string = self.string + ch
            return

    def printUndefs(self, e):
        if e.kind in [EN_ADD, EN_SUB, EN_MUL, EN_DIV]:
            self.printUndefs(e.a)
            self.printUndefs(e.b)
        elif e.kind == EN_NEG:
            self.printUndefs(e.a)
        elif e.kind == EN_ID:
            v = self.getSymbol(e.a)
            if v is None:
                print("ERROR: {} remains undefined.".format(e.a))
            else:
                self.printUndefs(v)
        elif e.kind == EN_INT:
            """Do nothing.  Integers are always defined."""

    def pass1(self, line):
        """Perform a pass-1 assembly step on the given line of code."""
        for c in line:
            self.lexChar(c)
        self.lexEOL()

    def pass2(self):
        """Identify any symbols which remain undefined, and report them as
        errors.
        """
        for i in self.pass2todo:
            self.printUndefs(i.a) if i.a else None
            self.printUndefs(i.b) if i.b else None
            self.printUndefs(i.c) if i.c else None

    def pass3(self):
        """Once we have assembled the first pass of our program, we now ask
        each instruction in the resulting program to emit its data to a list
        of bytes.
        """
        bs = []
        for i in self.pass2todo:
            bs = bs + i.asBytes(self)
            #print("{} @ {}".format(type(i).__name__, len(bs)))

        return bs

    def main(self):
        """This implements the main user interface of Polaris.  It drives the
        assembly process.
        """
        print("This is a, the Polaris RISC-V Assembler")
        print("Version 0.0")

        if len(self.args) < 2:
            print("I need a file to assemble.")
            os.exit(1)

        source = open(self.args[1], "r").readlines()
        for line in source:
            self.pass1(line)

        self.pass2()

        bs = self.pass3()
        with open("a.out", "wb") as f:
            f.write(bytearray(bs))

# Detect if we're executed from the command-line, and if so, create a new
# assembler instance and let it massage any passed parameters.

if __name__ == "__main__":
    a = Assembler(sys.argv)
    a.main()
