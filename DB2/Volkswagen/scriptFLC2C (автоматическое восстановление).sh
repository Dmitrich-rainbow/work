#!/bin/bash

# This section of script checks that restore from specified timestamp is possible
# If timestamp is not specified last backup will be used

use_last_timestamp=0 # Переменная
restore_timestamp=$1 # Передаваемое значение
matched=0
if [ "$restore_timestamp" == "" ]; then # Вызов переменной
 use_last_timestamp=1
fi # Окончание условия if
cur_date=`date +%d%m%Y%H%M` # Присвоить переменной результат выполнения команды
command="db2adutl query full db flc"
$command>full_bkp_flc_"$cur_date" # Выгрузить резльтат выполнения в файл
last_time_stamp=""
exec 6<&0 # переводим stdin в 6 дескриптор
exec < full_bkp_flc_"$cur_date" # stdin заменяется файлом
while read line # пока получаем новые строки в переменную line
do
 isbr=`expr match "$line" '.*Time:.*'` # ищем фразу .*Time:.* в $line
 if [ "$isbr" -gt 0 ]; then # проверка больше чем
  timestamp=`expr "$line" : '.*Time: \(.*\)  Oldest log'` # Ищем значение через регулярное выражение
  if [ "$timestamp" == "$restore_timestamp" ]; then
     matched=1
   fi
   if [ "$last_time_stamp" == "" ]; then
     last_time_stamp=$timestamp
   fi
 fi
 isincr=`expr match "$line" '.*INCREMENTAL.*'`
 if [ "$isincr" -gt 0 ]; then
   break
 fi
done # завершаем while read
if [ $use_last_timestamp -eq 1 ]; then # -eq equal (для чисел)
 echo "Restoring database FLC from last backup"
 echo "Timestamp is $last_time_stamp"
 rstamp=$last_time_stamp
else
 if [ $matched -eq 1 ]; then
  echo "Restoring database FLC from backup taken at specified timestamp $restore_timestamp"
  rstamp=$restore_timestamp
 else
  echo "Specified backup timestamp not found"
  exit
 fi
fi
rm -f full_bkp_flc_"$cur_date"
exec 0<&6 6<&- # вернуть всё обратно, закрыв дескриптор 6

# Database config restore SQL script generation 
exec 6>&1 # Связать дескр. #6 со stdout. Сохраняя stdout.
script_init=FLC2C.restore_init.jet."$rstamp".db2
exec > $script_init # все последубщие команды записывают свой вывод в $script_init
echo "UPDATE COMMAND OPTIONS USING" # установка параметров
echo "S ON" # останавливать выполнение при обнаружении ошибки
echo "L ON FLC2C.restore_init.$rstamp.log" # логировать процесс в указанный файл
echo "V ON;" # выводить текущую команду
echo ""
echo "RESTORE DATABASE FLC" # восстаналиваем БД
echo "  use tsm open 1 sessions options '-fromnode=fsrumosdp0001_db2i1'" # выбираем ноду tsm
echo "  taken at $rstamp" # берём нужный timestamp
echo "  ON '/mnt/flc'"
echo "  DBPATH ON '/mnt/flc'"
echo "  INTO FLC2C"
echo "  LOGTARGET '/mnt/flc/OLDLOGS/'" # куда извлечь логи из backup
echo "  NEWLOGPATH '/mnt/flc/LOGS/'" # папка для активных файлов логов
echo "  REPLACE HISTORY FILE" 
echo "  REPLACE EXISTING"
echo "  REDIRECT" # Указывает что TS будут лежать в другом месте. Если TS
echo "  WITHOUT PROMPTING" 
echo ";"
echo ""
exec 1>&6 6>&- # перенаправляем stdout обратно и закрываем 6 дескриптор
db2 -tvf $script_init
# Database containers configuration, restore & rollforward SQL script generation
exec 6>&1
script_restore=FLC2C.restore_continue.jet."$rstamp".db2
exec > $script_restore
echo "UPDATE COMMAND OPTIONS USING" 
echo "S ON"
echo "L ON FLC2C.restore_continue.$rstamp.log"
echo "V ON;"
echo ""
command=""
containers=0
canceled=0
file_or_path="file"
db2_ts="db2 get snapshot for tablespaces on FLC2C"
db2_ts_list=./flcts"$rstamp".lst
$db2_ts>$db2_ts_list
exec < $db2_ts_list

while read line  
do
 ists=`expr match "$line" 'Tablespace ID'`
 if [ "$ists" -gt 0 ]; then
   tsid=`expr  "$line" :  'Tablespace ID *\= \(.*\)'`
   #echo "tsid= " $tsid "DEBUG ##############################################"
   if [ "$command" == "" ]; then
      command="set tablespace containers for "$tsid" ignore rollforward container operations using (" # ignore rollforward  указываем для того, чтобы в момент retore не было проблем с командами ALTER TS, которые были во время backup
   else
     if [ $canceled -eq 0 ]; then
      echo $command" );"
     fi
     canceled=0
     containers=0
     command="set tablespace containers for "$tsid"  ignore rollforward container operations using ("
   fi
 fi
 iststype=`expr match "$line" 'Tablespace Type'`
 if [ "$iststype" -gt 0 ]; then
   tstype=`expr  "$line" :  'Tablespace Type *= \(.*\)'`
   #echo "tstype= " $tstype
   if [ "$tstype" == "Database managed space" ]; then
    file_or_path="file"
   else
    file_or_path="path"
   fi
 fi
 
 isas=`expr match "$line" 'Using automatic storage'`
 if [ "$isas" -gt 0 ]; then
   useas=`expr  "$line" :  'Using automatic storage *= \(.*\)'`
#   echo "storage = " $useas
   if [ "$useas" == "Yes" ]; then
    canceled=1
   fi
 fi
 

 iscont=`expr match "$line" 'Container Name'`
 if [ "$iscont" -gt 0 ]; then
   contname=`expr  "$line" :  'Container Name *= \(.*\)'`
   contname="/mnt/flc/"`expr "$contname" : '.*\/\(.*\)'`
   #echo "container = " $contname
   if [ $canceled -eq 0 ]; then
     if [ $containers -eq 0 ]; then
       command="$command""$file_or_path ""'$contname'"
       containers+=1
     else
       command="$command"" ,$file_or_path ""'$contname'"
     fi
   fi
 fi
 
 ispages=`expr match "$line" 'Total Pages in Container'`
 if [ "$ispages" -gt 0 ]; then
   pages=`expr  "$line" :  'Total Pages in Container *= \(.*\)'`
   #echo " pages = " $pages
  if [ $canceled -eq 0 ] && [ $file_or_path == 'file' ] ; then
   command=$command" $pages"  
  fi
 fi
done 

if [ $canceled -eq 0 ]; then
 echo $command");"
fi

rm $db2_ts_list
echo ""
echo "RESTORE DATABASE FLC CONTINUE;"
echo ""
echo "ROLLFORWARD DATABASE FLC2C TO END OF LOGS AND STOP OVERFLOW LOG PATH('/mnt/flc/OLDLOGS');" # Восстановить до конца логов, которые будут взяты из указанной папки
exec 1>&6 6>&-
db2 -tvf $script_restore 
