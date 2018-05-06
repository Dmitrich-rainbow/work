
<1>SELECT @@VERSION</1>
<2>SELECT CONVERT (varchar, SERVERPROPERTY('collation'));</2>
<3>SELECT name,value,value FROM sys.configurations</3>
<4>SELECT message_id,text FROM sys.messages WHERE message_id > 50000 ORDER BY message_id DESC</4>
<5>SELECT name FROM sys.servers</5>
<6>SELECT a.name, f.name as name1 FROM [sys].[assemblies] AS a INNER JOIN [sys].[assembly_files] AS f ON a.assembly_id = f.assembly_id </6>


0
