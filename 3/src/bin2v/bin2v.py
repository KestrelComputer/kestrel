#!/usr/bin/env python

import sys

DEBUG=True

def main(args):
    input_filename = None
    output_filename = None
    byte_swap = False
    bytes_at_a_time = None

    def usage():
        cmd = args[0]
        print "USAGE: %s ..." % (cmd)
        print "    (keywords optional; unmarked arguments satisfied in listed order)"
        print "          from <filename> - specifies input file.  Defaults to stdin."
        print "          to <filename>   - specifies output file.  Defaults to stdout."
        print "          bytes <n>       - specifies how many bytes per line in output file."
        print ""
        print "    (keywords required)"
        print "          (byte)swap      - Switch byte arrangement per line"
        print "          help            - Produce this message."

    i = 1
    while i < len(args):
        if (args[i] == 'from') and (len(args) > i+1):
            input_filename = args[i+1]
            i = i + 2
            continue

        if (args[i] == 'to') and (len(args) > i+1):
            output_filename = args[i+1]
            i = i + 2
            continue

        if (args[i] == 'bytes') and (len(args) > i+1):
            bytes_at_a_time = int(args[i+1])
            i = i + 2
            continue

        if (args[i] in ['from', 'to', 'bytes']) and (len(args) <= i+1):
            sys.stderr.write("Argument expected for %s parameter\n" % (args[i]))
            return 1

        if args[i] in ['swap', 'byteswap']:
            byte_swap = True
            i = i + 1
            continue

        if args[i] == 'help':
            usage()
            return 0

        if not input_filename:
            input_filename = args[i]
            i = i + 1
            continue

        if not output_filename:
            output_filename = args[i]
            i = i + 1
            continue

        if not bytes_at_a_time:
            bytes_at_a_time = int(args[i])
            i = i + 1
            continue

        sys.stderr.write("Unrecognized parameter: %s\n" % (args[i]))
        return 1

    if not bytes_at_a_time:
        bytes_at_a_time = 1

    if not input_filename:
        input_file = sys.stdin
    else:
        input_file = file(input_filename, "rb")

    if not output_filename:
        output_file = sys.stdout
    else:
        output_file = file(output_filename, "w")

    while True:
        input_data = input_file.read(bytes_at_a_time)
        if len(input_data) < 1:
            break
        input_xform = ["%02X" % (ord(x)) for x in input_data]
        if byte_swap:
            input_xform.reverse()
        output_file.write("%s\n" % (''.join(input_xform)))

    return 0


if __name__ == '__main__':
    rc = main(sys.argv)
    sys.exit(rc)
