
	// fc = 1, rate = 10000, usdt = 1     1
	// fc = 1, rate =  1000, usdt = 0.1   0.1   a2
	// fc = 1, rate =   100, usdt = 0.01  0.01  a1

	// b1 => a1 a1没,b1剩0.89
	// a1 => b1 a1没,b1剩0.99

	// usdt = 1, rate = 10000, fc = 1   1  b1
	// usdt = 1, rate =  1000, fc = 10  0.1
	// usdt = 1, rate =   100, fc = 100 0.01
	// usdt = 1, rate =     1, fc = 10000 0.0001

	// usdt * 10000 / rate = fc
	// usdt = fc * rate / 10000