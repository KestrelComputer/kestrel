; Base address for console UART device.
zpUartBase			= 0
zpNumTests			= zpUartBase + 8
zpTestPtr			= zpNumTests + 8
zpV				= zpTestPtr + 8
zpWordBody			= zpV + 8
zpValue				= zpWordBody + 8
zpTestPC			= zpValue + 8
zpScanIndex			= zpTestPC + 8
zpLineLength			= zpScanIndex + 8
zpLineBuffer			= zpLineLength + 8
zpBase				= zpLineBuffer + 8
zpWordStart			= zpBase + 8
zpWordLength			= zpWordStart + 8
zpError				= zpWordLength + 8
zpCalled			= zpError + 8
zpReserved0			= zpCalled + 8
zpWordFound			= zpReserved0 + 8
zpRP0				= zpWordFound + 8
zpDP0				= zpRP0 + 8
zpRPL				= zpDP0 + 8
zpDPL				= zpRPL + 8

