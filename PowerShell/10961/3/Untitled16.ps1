# 2. Как называется самый большой EXE-файл в каталоге C:\Windows\System32?
# 3. Сколько букв в названии этого файла?   

Dir C:\Windows | Select-Object -First 1 | ForEach-Object {$_.Name.Length}