0
DUP CONSTANT UART_TX
DUP CONSTANT UART_STATUS		1+
DUP CONSTANT UART_RX			1+
CONSTANT UART_sizeof

\ STATUS flags as follows:
\ 
\   7   6   5   4   3   2   1   0
\ +---+---+---+---+---+---+---+---+
\ |///|///|///|///|///|///|///| R |
\ +---+---+---+---+---+---+---+---+
\ 
\ R=1 if data is available to be read; 0 otherwise.

