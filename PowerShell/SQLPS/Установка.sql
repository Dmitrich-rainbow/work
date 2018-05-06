PowerShell and related scripts for SQL Server administration

The scripts here make extensive use of sqlps by importing that module. In addition, due to the tight integration between SQL Server and ActiveDirectory, a number of functions use modules related to ActiveDirectory. So these are the installation prerequisites before using the functions here.

To install the sqlps module (independent of the sqlps utility inside of Management Studio), please go to:

https://www.microsoft.com/en-us/download/details.aspx?id=29065

and install the following:

Microsoft System CLR Types for Microsoft SQL Server 2012
Microsoft SQL Server 2012 Shared Management Objects
Microsoft Windows PowerShell Extensions for Microsoft SQL Server 2012
To install ActiveDirectory related modules, please do the following (This applies to Windows Server 2008 R2 and Windows 2012. Instructions for Windows XP, 7, and 8 will be provided as I come across them. Or you can provide a patch to this documentation!):

Run PowerShell as administrator. You need to specifically pick "Run as Administrator", even if the account you logged in as has local admin privileges.
Import-Module ServerManager
Add-WindowsFeature RSAT-AD-PowerShell
Add-WindowsFeature RSAT-AD-AdminCenter
baseFunctions.ps1

Base functions that we source into and exposes commonly used functions. For instance, it has functions for:

Get instance version
Get a list of user (non-system) databases
Get a list of data files for a given database
Get a list of log files for a given database
Generate database attach scripts given a database name
Get data and index sizes given a database name
The rest of the PowerShell scripts mostly use the functions exposed inside baseFunctions.ps1. It's purpose is explained by its name. You may need to modify two places to run those scripts:

The path to where baseFunction.ps1. Normally this is the second line in the file;
The $fileName and, if present, the $savedScriptPath parameter. They decide where the generated files will be saved.


-- Скопировать SQLPS в C:\Windows\System32\WindowsPowerShell\v1.0\Modules