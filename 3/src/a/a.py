#!/usr/bin/env python

from __future__ import print_function

import string
import sys
import os

fileScope = 0
lexingComment = 1
lexingIdentifier = 2
lexingDecimalConstant = 3
lexingHexConstant = 4
lexingString = 5

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
endOfInputToken = 999


lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
startOfIdentifierChars = lowercaseLetters + uppercaseLetters + '_'
decimalDigits = "0123456789"
completeIdentifierCharSet = startOfIdentifierChars + decimalDigits
hexDigits = decimalDigits + uppercaseLetters[:6]

precedenceTable = {
    "*": 20, "/": 20,
    "+": 10, "-": 10,
}


def syntaxError(asm, tok):
    print("Syntax error on line {} near {}".format(asm.getLine(), tok.string))


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
    }
    return kindMap.get(s, identifierToken)


def integerExpressionHandler(asm, tok, prec):
    return tok.tokenValue


def identifierExpressionHandler(asm, tok, prec):
    return asm.getSymbol(tok.tokenValue)


def unaryOperatorHandler(asm, tok, prec):
    if tok.tokenValue == '+':
        return expression(asm, precedenceTable['+']+1)

    if tok.tokenValue == '-':
        return -expression(asm, precedenceTable['-']+1)

    if tok.tokenValue == '*':
        return asm.getLC()

    syntaxError(asm, tok)


def characterPrefixHandler(asm, tok, prec):
    if tok.tokenValue == '(':
        v = expression(asm, 0)
        t = asm.getToken()
        if t.tokenType != characterToken or t.tokenValue != ')':
            syntaxError(asm, t)
        asm.eatToken()
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


def expression(asm, prec):
    opTable = {
        '+': lambda x, y: x+y,
        '-': lambda x, y: x-y,
        '*': lambda x, y: x*y,
        '/': lambda x, y: x/y,
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


fileScopeHandlers = {
    commentToken: commentHandler,
    identifierToken: labelOrAssignmentHandler,
    dwordToken: declareConstantHandler,
    wordToken: declareConstantHandler,
    hwordToken: declareConstantHandler,
    byteToken: declareConstantHandler,
}


def fileScopeHandler(tt):
    if tt not in fileScopeHandlers:
        return syntaxError

    return fileScopeHandlers[tt]


class Assembler(object):
    def __init__(self, args):
        self.args = args
        self.lexerState = fileScope
        self.tokenStream = []
        self.cursor = 0
        self.line = 0
        self.symbols = {}
        self.section = []
        self.pass2todo = []

    def recordDWord(self, dw):
	self.pass2todo = self.pass2todo + [(dwordToken, dw)]

    def recordWord(self, w):
	self.pass2todo = self.pass2todo + [(wordToken, w)]

    def recordHWord(self, h):
	self.pass2todo = self.pass2todo + [(hwordToken, h)]

    def recordByte(self, b):
	self.pass2todo = self.pass2todo + [(byteToken, b)]

    def getLC(self):
        return len(self.section)

    def setSymbol(self, name, value):
        self.symbols[name] = value

    def getSymbol(self, name):
        return self.symbols[name]

    def tokenTransition(self, ch, token):
        self.tokenStream = self.tokenStream + [token]
        self.string = ""
        self.lexerState = fileScope
        self.lexChar(ch)

    def getToken(self):
        if self.cursor < len(self.tokenStream):
            return self.tokenStream[self.cursor]
        else:
            return Token(endOfInputToken, None)

    def eatToken(self):
        if self.cursor < len(self.tokenStream):
            self.cursor = self.cursor + 1

    def nextToken(self):
        t = self.getToken()
        self.eatToken()
        return t

    def getLine(self):
        return self.line

    def lexEOL(self):
        """Inform lexer that the end of line has been reached."""
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
        print("This is a, the Polaris RISC-V Assembler")
        print("Version 0.0")

        if len(self.args) < 2:
            print("I need a file to assemble.")
            os.exit(1)

        source = open(self.args[1], "r").readlines()
        for line in source:
            self.pass1(line)


if __name__ == "__main__":
    a = Assembler(sys.argv)
    a.main()
