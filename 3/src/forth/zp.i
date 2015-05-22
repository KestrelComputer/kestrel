; Base address for console UART device.
zpUartBase              = 0
zpNumTests		= zpUartBase + 8
zpTestPtr		= zpNumTests + 8
zpasrtRunTestPC		= zpTestPtr + 8
zpasrtCallTestPC	= zpasrtRunTestPC + 8
zpasrtPrintNamePC	= zpasrtCallTestPC + 8
zpTestPC		= zpasrtPrintNamePC + 8

