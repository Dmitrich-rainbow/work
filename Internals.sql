-- Log
	- https://technet.microsoft.com/ru-ru/library/2009.02.logging.aspx
	- в режиме SIMPLE усекается после CHECKPOINT (авто или ручной)

-- Log Buffer
	- The log cache contains up to 128 entries on 64-bit systems or 32 entries on 32-bit systems. Each entry can maintain a buffer to store the log records before they get written to disk as a single block. The block can be anywhere from 512 bytes to 60 KB
	- Сбрасывается
		1. CHECKPOINT
		2. До COMMIT
		3. Заполнение 60 кб
		4. Если будут большие транзакции, то будет сбрасываться большими блоками по 4 Мб
-- lazywriter
	- http://blog.sqlxdetails.com/checkpoint-vs-lazy-writer/
	- Every hardware NUMA memory node has its own lazywriter
