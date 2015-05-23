; Base address for console UART device.
zpUartBase              = 0
zpNumTests		= zpUartBase + 8
zpTestPtr		= zpNumTests + 8
zpasrtRunTestPC		= zpTestPtr + 8
zpasrtCallTestPC	= zpasrtRunTestPC + 8
zpasrtPrintNamePC	= zpasrtCallTestPC + 8
zpTestPC		= zpasrtPrintNamePC + 8
zpScanIndex		= zpTestPC + 8
zpLineLength		= zpScanIndex + 8
zpLineBuffer		= zpLineLength + 8
zpScanSkipWSPC		= zpLineBuffer + 8
zpWordStart		= zpScanSkipWSPC + 8
zpWordLength		= zpWordStart + 8
zpError			= zpWordLength + 8
zpCalled		= zpError + 8
zpInterpretLinePC	= zpCalled + 8
zpWordFound		= zpInterpretLinePC + 8
