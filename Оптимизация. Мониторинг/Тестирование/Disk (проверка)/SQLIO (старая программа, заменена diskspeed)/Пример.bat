
D:\SQLIO\sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -RD -LP -a0xf -BN > R01-b64-f1-i2000000-o1-t1.log

timeout /T 10

D:\SQLIO\sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -RD -LP -a0xf -BN > W01-b64-f1-i2000000-o1-t1.log

timeout /T 10

D:\SQLIO\sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -RF -LP -a0xf -BN > R02-b64-f1-i2000000-o1-t1.log

timeout /T 10

D:\SQLIO\sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -RF -LP -a0xf -BN > W02-b64-f1-i2000000-o1-t1.log

pause