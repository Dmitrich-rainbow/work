1. Скачать psexec
2. Cоздать ярлык для psexec.exe
3. В ярлык добавить psexec.exe -s -i cmd
4. Запуститить "Rus as administrator" 
5. Откроется cmd с правами системы
6. CREATE LOGIN [QUELLE\da.zaytsev] FROM WINDOWS
   GO
7. sp_addsrvrolemember  @loginame=  [QUELLE\da.zaytsev], @rolename =  'sysadmin'
   GO