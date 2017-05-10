; UART definitions.
;
; STATUS flags as follows:
; 
;   7   6   5   4   3   2   1   0
; +---+---+---+---+---+---+---+---+
; |///|///|///|///|///|///|///| R |
; +---+---+---+---+---+---+---+---+
; 
; R=1 if data is available to be read; 0 otherwise.

UART_TX		= 0
UART_STATUS	= UART_TX
UART_RX		= UART_STATUS + 1
UART_sizeof	= UART_RX + 1

