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


class ExprNode(object):
    def __init__(self, kind, a=None, b=None):
        self.kind = kind
        self.a = a
        self.b = b

class Advance(object):
    def __init__(self, target, fill):
        self.target = target
        self.fill = fill


class Declaration(object):
    def __init__(self, value, size):
        self.value = value
        self.size = size


class IInsn(object):
    def __init__(self, insn, rd, rs, imm12):
        self.insn = insn
        self.rd = rd
        self.rs = rs
        self.imm12 = imm12

class UInsn(object):
    def __init__(self, insn, rd, imm20):
        self.insn = insn
        self.rd = rd
        self.imm20 = imm20

class UJInsn(object):
    def __init__(self, insn, rd, disp):
        self.insn = insn
        self.rd = rd
        self.disp = disp

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
    }
    return kindMap.get(s, identifierToken)


def integerExpressionHandler(asm, tok, prec):
    return ExprNode(EN_INT, tok.tokenValue)


def identifierExpressionHandler(asm, tok, prec):
    v = asm.getSymbol(tok.tokenValue)
    if v is not None:
        return ExprNode(EN_INT, v)
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
    stringToken: lambda x, y, z: y.tokenValue,
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
            return ExprNode(EN_INT, l.a + r.a)
        else:
            return root
    elif root.kind == EN_MUL:
        l = evalExpression(asm, root.a)
        r = evalExpression(asm, root.b)
        if l.kind == EN_INT and r.kind == EN_INT:
            return ExprNode(EN_INT, l.a + r.a)
        else:
            return root
    elif root.kind == EN_DIV:
        l = evalExpression(asm, root.a)
        r = evalExpression(asm, root.b)
        if l.kind == EN_INT and r.kind == EN_INT:
            return ExprNode(EN_INT, l.a + r.a)
        else:
            return root
    elif root.kind == EN_NEG:
        e = evalExpression(asm, root.a)
        if e.kind == EN_INT:
            return ExprNode(EN_INT, -e.n)
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
        asm.setSymbol(tok.tokenValue, v)

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
        e = expression(asm, 0)
        te = type(e).__name__
        if te == "int":
            recorder(e)
        elif te == "str":
            for c in e:
                recorder(ord(c))
        t = asm.getToken()
        if t.tokenType != characterToken:
            break
        if t.tokenValue != ',':
            break
        asm.eatToken()


def advanceHandler(asm, tok):
    eTarget = constantExpression(asm, 0)
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
        self.lc = self.lc + 8

    def recordWord(self, w):
        """Records an arbitrary, 32-bit quantity to the object file.
        Note that this method does NOT align the generated bytes to an 4-byte
        boundary first.
        """
        self._defer(Declaration(w, 4))
        self.lc = self.lc + 4

    def recordHWord(self, h):
        """Records an arbitrary, 16-bit quantity to the object file.
        Note that this method does NOT align the generated bytes to an 2-byte
        boundary first.
        """
        self._defer(Declaration(h, 2))
        self.lc = self.lc + 2

    def recordByte(self, b):
        """Records an arbitrary, 8-bit quantity to the object file."""
        self._defer(Declaration(b, 1))
        self.lc = self.lc + 1

    def recordAdvance(self, target, fill):
        """When the programmer specifies the ADV mnemonic, this method is
        called to record its behavior for pass two.
        """
        self._defer(Advance(target, fill))
        if self.lc < target:
            self.lc = target

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
        self._defer(UJInsn(insn, rd, disp))
        self.lc = self.lc + 4

    def getLC(self):
        """Retrieves the current location counter."""
        return self.lc

    def setSymbol(self, name, value):
        """Sets a global symbol."""
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

    def pass1(self, line):
        """Perform a pass-1 assembly step on the given line of code."""
        for c in line:
            self.lexChar(c)
        self.lexEOL()

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


# Detect if we're executed from the command-line, and if so, create a new
# assembler instance and let it massage any passed parameters.

if __name__ == "__main__":
    a = Assembler(sys.argv)
    a.main()
