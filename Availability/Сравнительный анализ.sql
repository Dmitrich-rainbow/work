-- http://sqlcom.ru/mirroring/high-availability/

Log Shipping::

It automatically sends transaction log backups from one database (Known as the primary database) to a database (Known as the Secondary database) on another server. An optional third server, known as the monitor server, records the history and status of backup and restore operations. The monitor server can raise alerts if these operations fail to occur as scheduled. 

Mirroring::
Database mirroring is a primarily software solution for increasing database availability.
It maintains two copies of a single database that must reside on different server instances of SQL Server Database Engine.

Replication::
It is a set of technologies for copying and distributing data and database objects from one database to another and then synchronizing between databases to maintain consistency. Using replication, you can distribute data to different locations and to remote or mobile users over local and wide area networks, dial-up connections, wireless connections, and the Internet.
Components

Log Shipping::Primary server, secondary server and monitor server (Optional).
Mirroring::Principal server, mirror server, and witness server (Optional).
Replication::Publisher, Subscribers, Distributor (Optional).
Data Transfer

Log Shipping::T-Logs are backed up and transferred to secondary server.
Mirroring::Individual T-Log records are transferred using TCP endpoints.
Replication::Replication works by tracking/detecting changes (either by triggers or by scanning the log) and shipping the changes.
Server Limitation

Log Shipping::It can be configured as One to Many. i.e one primary server and many secondary servers. Or
Secondary server can contain multiple Primary databases that are log shipped from multiple servers.
Mirroring::It is one to one. i.e. One principal server to one mirror server.
Replication::
Central publisher/distributor, multiple subscribers.
Central Distributor, multiple publishers, multiple subscribers.
Central Distributer, multiple publishers, single subscriber.
Mixed Topology.
Types Of Failover

Log Shipping::Manual.
Mirroring::Automatic or manual.
Replication::Manual.
DB Access

Log Shipping::You can use a secondary database for reporting purposes when the secondary database restore in STANDBY mode.
Mirroring::Mirrored DB can only be accessed using snapshot DB.
Replication::The Subscriber Database is open to reads and writes.
Recovery Model

Log Shipping::Log shipping supports both Bulk Logged Recovery Model and Full Recovery Model.
Mirroring::Mirroring supports only Full Recovery model.
Replication::It supports Full Recovery model.
Restoring State

Log Shipping::The restore can be completed using either the NORECOVERY or STANDBY option.
Mirroring::The restore can be completed using with NORECOVERY.
Replication::The restore can be completed using With RECOVERY.
Backup/Restore

Log Shipping::This can be done manually or
through Log Shipping options.
Mirroring::User make backup & Restore manually.
Replication::User create an empty database with the same name.
Monitor/
Distributer/ Witness

Log Shipping::The monitor server should be on a server separate from the primary or secondary servers to avoid losing critical information and disrupting monitoring if the primary or secondary server is lost. . If a monitor server is not used, alert jobs are created locally on the primary server instance and each secondary server instance.
Mirroring::Principal server can’t act as both principal server and witness server.
Replication::Publisher can be also distributer.
Types Of Servers

Log Shipping::All servers should be SQL Server.
Mirroring::All servers should be SQL Server.
Replication::Publisher can be ORACLE Server.
SQL Server Agent Dependency/Jobs

Log Shipping::Yes. Log shipping involves four jobs, which are handled by dedicated SQL Server Agent jobs. These jobs include the backup job, copy job, restore job, and alert job.
Mirroring::Independent on SQL Server agent.
Replication::Yes. Snapshot agent, log reader agent & Distribution agent (transactional replication)
Merge agent (merge replication).
Requirements

Log Shipping::
The servers involved in log shipping should have the same logical design and collation setting.
The databases in a log shipping configuration must use the full recovery model or bulk-logged recovery model.
The SQL server agent should be configured to start up automatically.
You must have sysadmin privileges on each computer running SQL server to configure log shipping.
Mirroring::
Verify that there are no differences in system collation settings between the principal and mirror servers.
Verify that the local windows groups and SQL Server logins definitions are the same on both servers.
Verify that external software components are installed on both the principal and the mirror servers.
Verify that the SQL Server software version is the same on both servers.
Verify that global assemblies are deployed on both the principal and mirror server.
Verify that for the certificates and keys used to access external resources, authentication and encryption match on the principal and mirror server.
Replication::
Verify that there are no differences in system collation settings between the servers.
Verify that the local windows groups and SQL Server Login definitions are the same on both servers.
Verify that external software components are installed on both servers.
Verify that CLR assemblies deployed on the publisher are also deployed on the subscriber.
Verify that SQL agent jobs and alerts are present on the subscriber server, if these are required.
Verify that for the certificates and keys used to access external resources, authentication and encryption match on the publisher and subscriber server.
Using With Other Features Or Components

Log Shipping::Log shipping can be used with Database mirroring, Replication.
Mirroring::Database mirroring can be used with
Log shipping, Database snapshots , Replication.
Replication::Replication can be used with log shipping, database mirroring.
DDL Operations

Log Shipping::DDL changes are applied automatically.
Mirroring::DDL changes are applied automatically.
Replication::only DML changes to the tables you have published will be replicated.
Database Limit

Log Shipping::No limit.
Mirroring::generally good to have 10 DB’s for one server.
Replication::No limit.
latency

Log Shipping::There will be data transfer latency. >1min.
Mirroring::There will not be data transfer latency.
Replication::Potentially as low as a few seconds.
Committed /
Uncommitted
Transactions

Log Shipping::Both committed and uncommitted transactions are transferred to the secondary database.
Mirroring::Only committed transactions are transferred to the mirror database.
Replication::Only committed transactions are transferred to the subscriber database.
Primary key

Log Shipping::Not required.
Mirroring::Not required.
Replication::All replicated table should have Primary Key.
New Created Database&
Stored Procedure

Log Shipping::Monitoring and history information is stored in tables in msdb, which can be accessed using log shipping stored procedures.
Replication::Creates new SPs ( 3 Sps of one table).
Distribution Database.
Rowguid column will be created.
Individual Articles

Log Shipping::No. Whole database must be selected.
Mirroring::No. Whole database must be selected.
Replication::Yes. Including tables, views, stored procedures, and other objects. Also filter can be used to restrict the columns and rows of the data sent to subscribers.
FILESTREAM

Log Shipping::Log shipping supports FILESTREAM.
Mirroring::Mirroring does not support FILESTREAM.
Replication::Replication supports FILESTREAM.
DB Name

Log Shipping::The secondary database can be either the same name as primary database or it may be another name.
Mirroring::It must be the same name.
Replication::It must be the same name.
DB Availability

Log Shipping::In case of standby mode: read only database.
In case of restoring with no recovery: Restoring state.
Mirroring::In Recovery state, no user can make any operation.
You can take snapshot.
Replication::Snapshot (read-only).
Other types (Database are available).
Warm/ Hot Standby Solution

Log Shipping::It provides a warm standby solution that has multiple copies of a database and require a manual failover.
Mirroring::When a database mirroring session is synchronized, database mirroring provides a hot standby server that supports rapid failover without a loss of data from committed transactions. When the session is not synchronized, the mirror server is typically available as a warm standby server (with possible data loss).
Replication::It provides a warm standby solution that has multiple copies of a database and require a manual failover.
System Data Transferred

Log Shipping::Mostly.
Mirroring::Yes.
Replication::No.
System Databases

Mirroring::You cannot mirror the Master, msdb, tempdb, or model databases.
Mode Or Types

Log Shipping::
Standby mode (read-only)-you can disconnect users when restoring backups .
No recovery mode (restoring state)-user cannot access the secondary database.
Mirroring::
high-safety mode supports synchronous operation.
high-performance mode, runs asynchronously.
High-safety mode with automatic failover.
Replication::
Snapshot replication.
Transactional replication.
Transactional publication with updatable subscriptions.
Merge publication.
Pull/Push subscription.