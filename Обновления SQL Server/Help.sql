http://www.sqlservercentral.com/blogs/pearlknows/2014/06/18/cluster-headache-applying-service-pack-and-sql-fails-to-come-on-line/

sa - владелец всех системных БД перед обновлением

При обновлении необходимо отключить возможность переезда слубы

	Stage Source: SQL Server 2012 SP2 & CU3	Active/Passive	
Check database integrity & consistency	Active	
Free space; master & tempdb	Active	
Full Backups: system and user dbs	Active	
Verify free space on nodes	Active	
Verify SQL Server build version


With SQL Server 2005, when you start installing cluster service pack (or hotfix), it must be launched on the active node (node that hosts the instance). When installing the Setup will launch simultaneously  "remote silence" on all passive nodes. All nodes in the cluster containing the SQL Server instance are updated in the same time.

With SQL Server 2008, to reduce the downtime, we have revised the method of deployment. Now if you want to apply a service pack (or hotfix), you must install in first on the passive nodes. The passive nodes are updated before the active node.