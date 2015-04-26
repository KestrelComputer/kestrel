#!/usr/bin/env python

from __future__ import print_function

import sys
import os

fileScope = 0

lexingComment = 1
lexingIdentifier = 2
lexingDecimalConstant = 3

commentToken = 1
identifierToken = 2
integerConstantToken = 3
characterToken = 4
expressionToken = 100
endOfInput = 999


lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
startOfIdentifierChars = lowercaseLetters + uppercaseLetters + '_'
decimalDigits = "0123456789"
completeIdentifierCharSet = startOfIdentifierChars + decimalDigits

precedenceTable = {
    "*": 20, "/": 20,
    "+": 10, "-": 10,
}


def identity(x):
    return x

class Assembler(object):
    def __init__(self, args):
        self.args = args
        self.lexerState = fileScope
        self.parserState = fileScope
        self.string = ""
        self.stack = []
        self.labels = {}

    def is_binary_operator(self, op):
        a, b, c, d = self.stack[-4:]

        return (
            a[0] == expressionToken and
            b[0] == characterToken and b[1] == op and
            c[0] == expressionToken and
            (
                d[0] != characterToken or
                (
                d[0] == characterToken and d[1] in precedenceTable and
                precedenceTable[b[1]] >= precedenceTable[d[1]]
                )
            )
        )

    def perform_binary_op(self, f):
        a, _, c, d = self.stack[-4:]
        self.stack = (
            self.stack[:-4] + [(expressionToken, f(a[1], c[1]))] + [d]
        )
        return True

    def simplify_step(self):
	print("STEP={}".format(self.stack))
        if len(self.stack) >= 4:
            a, b, c, d = self.stack[-4:]
            if self.is_binary_operator("+"):
                return self.perform_binary_op(lambda x, y: x + y)

            elif self.is_binary_operator("-"):
                return self.perform_binary_op(lambda x, y: x - y)

            elif self.is_binary_operator("*"):
                return self.perform_binary_op(lambda x, y: x * y)

            elif self.is_binary_operator("/"):
                return self.perform_binary_op(lambda x, y: x / y)

            elif (
                a[0] == identifierToken and
                b[0] == characterToken and b[1] == "=" and
                c[0] == expressionToken and
                d[0] == endOfInput
            ):
                self.labels[a[1]] = c[1]
                self.stack = self.stack[:-4]+[d]
                return True


        if len(self.stack) >= 1:
            a = self.stack[-1]

            if a[0] == commentToken:
                self.stack = self.stack[:-1]
                return True

            elif a[0] == integerConstantToken:
                self.stack = self.stack[:-1] + [(expressionToken, a[1])]
                return True

            elif a[0] == identifierToken and a[1] in self.labels:
                self.stack = (
                    self.stack[:-1] + [(expressionToken, self.labels[a[1]])]
                )
                return True

            elif a[0] == endOfInput:
                self.stack = []
                return True

        return False

    def simplify(self):
        while self.simplify_step():
            pass

    def onToken(self, tokenType, tokenValue):
        self.stack = self.stack + [(tokenType, tokenValue)]
	print("SHIFT={}".format(self.stack))
        self.simplify()

    def tokenTransition(self, ch, tokenType, converter=identity):
        self.onToken(tokenType, converter(self.string))
        self.string = ""
        self.lexerState = fileScope
        self.lexChar(ch)

    def lexEOL(self):
        """Inform lexer that the end of line has been reached."""
        self.onToken(endOfInput, None)
        
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

            # Otherwise, just return the random character as-is.
            # Maybe the parser knows what to do with it.
            self.onToken(characterToken, ch)

        elif self.lexerState == lexingComment:
            # Any character is valid inside a comment except for \n, \r.
            if ch in ['\n', '\r']:
                return self.tokenTransition(ch, commentToken)

            self.string = self.string + ch
            return

        elif self.lexerState == lexingIdentifier:
            if ch not in completeIdentifierCharSet:
                return self.tokenTransition(ch, identifierToken)

            self.string = self.string + ch
            return

        elif self.lexerState == lexingDecimalConstant:
            if ch not in decimalDigits:
                return self.tokenTransition(ch, integerConstantToken, converter=int)

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
