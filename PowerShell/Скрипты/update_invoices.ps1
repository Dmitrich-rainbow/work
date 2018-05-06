Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100

[string]$login = (Read-Host "Введите логин") 

[string]$password = (Read-Host "Введите пароль") 

[string]$inumber_before = (Read-Host "Введите Inumber который следует изменить") 

[string]$inumber_after = (Read-Host 'Введите Inumber на который будет изменено')
 
[decimal]$rubSum_before = (Read-Host 'Введите RubSum который следует изменить')

[decimal]$rubSum_after = (Read-Host 'Введите RubSum на который будет изменено')


$query = "set nocount OFF
UPDATE invoices 
SET rubsum = "+$rubSum_after+", inumber = '"+$inumber_after+"' OUTPUT inserted.id
WHERE rubsum = "+$rubSum_before+" and inumber = '"+$inumber_before+"'"


invoke-sqlcmd -ServerInstance 10.0.1.22 -Username $login -Password $password -Database InvoicesForBank -query $query

sleep 60