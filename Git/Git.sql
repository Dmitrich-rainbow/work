-- Основное
	- https://try.github.io/ -- Тренировка базовых команд в web 
	- https://git-scm.com/book/en/v2 -- Книга, важные первые 3 главы
	- https://github.com/gitextensions/gitextensions -- Основной GUI
	- https://git-scm.com/download/gui/win -- скачать GUI
	- https://ru.hexlet.io/courses/bash/lessons/pagers/theory_unit -- Основы bash
	- http://sqlserver-kit.org/en/contribute -- Инструкция upstream
	https://git-for-windows.github.io/ -- Git on Win

-- Состояние проекта
	Commited
	Stage
	Modified
	
-- Состояние файла 
	tracked
		unmodified
		modified
		stage
	untracked. 
	
	
-- Команды
	git config -- Настройка конфигурации
		git config --global user.name "John Doe"
		git config --global user.email johndoe@example.com
		git config --list
		
	git help
	
	cd /c/git/sqlcom -- Перейти в проект

	
	git init -- Создать репозиторий в текущей папке
	
	git add * -- Добавить все файлы в stage
		git reset HEAD CONTRIBUTING.md -- Убрать из stage конкретный файл
		-- all - Добавить всё
		
	git status -- Получить статус
		-s -- Короткий вывод
		
	git diff -- Выполнить сравнение того что изменилось
		--staged
		
	git commit -- Закрепить изменения. После этого откроется окно, где нужно будет указать комментарий, сохранить и закрыть его.
		-v -- Дополнительно покажет что изменилось		
		-m "Comment" -- Короткая форма закрепления изменения
		-a -- Пропустить git add и закрепить все изменения, но только в старых файлах, что уже прошли через COMMIT
		--amend -- Заменить описание последнего коммита		
		
	git remote -v -- Посмотреть к чему сейчас подключён (URL)
		add upstream https://github.com/ktaranov/sqlserver-kit -- Подключить upstream. Нужно чтобы можно было кроме своей разработки, слать обновления и на владельца
		add pb https://github.com/paulboone/ticgit -- Добавить новый проект переименовав в pb
		rename pb paul -- переименовать локальный проект pb в paul
		remote remove paul -- Удаление удалённой ветки paul
		
	git fetch pb -- запросить изменения, которых нет у вас в проекте pb. При этом не происходит merge, только скачивание изменений, merge необходимо сделать самостоятельно
		git fetch --all -- Запросить все изменения
		
	git pull -- Скачать изменения из основной ветки и сделать merge
		
	git clone https://github.com/libgit2/libgit2 -- забрать весь репозиторий и привязаться к нему. Если через пробел добавить название, то локальная папка будет называться иначе	

	git push origin master -- Отправить ветку master в оригинальный Гит
		git push origin [tagname] -- Изначально тэги не уходят на издателя, поэтому приходится выгружать их отдельно
		git push origin --delete serverfix -- Удалить удалённую ветку
	
	git remote show origin -- Дополнительная информация о оригинальной ветке
	
	git rm Name -- удалить из Гита файл
	git mv Name New_Name -- Переименовать/переместить файл. Если мы переименуем файл без Гита, то он подумает что это новый файл, а старый удалился
		rm '*.txt' удалить все txt файлы
	
	git log -- Посмотреть историю
		-p -2 -- Более подробно о каждом COMMIT
		--stat -- Информация со статистикой
		--pretty=oneline -- Изменяет вывод. Доступны и другие параметры вместо online - short, full, and fuller. Можно так же создавать свой формат вывода =format:"%h - %an, %ar : %s"
		--since=2.weeks -- ограничить вывод логов последними 2 неделями
			-(n) --	Show only the last n commits
			--since, --after --Limit the commits to those made after the specified date.
			--until, --before --Limit the commits to those made before the specified date.
			--author --Only show commits in which the author entry matches the specified string.
			--committer --Only show commits in which the committer entry matches the specified string.
			--grep --Only show commits with a commit message containing the string
			-S --Only show commits adding or removing code matching the string
		git log --oneline --decorate --graph --all -- Полный список в удобном виде
				
	git tag -- получить список тэгов
		-l "some" -- найти что-то конкретное
		-а some -m "describe" -- Создать большой тэг с описанием
		git tag someNameOfTag -- Создать легковесный тэг
	
	git show nameOfTag -- прочитать подробности тэга
	
	git config --global alias.co checkout (создать алиас)
		--global alias.br branch
		--global alias.ci commit
		--global alias.st status
	
	git branch -- Показать ветки
	git branch -d dev -- Удалить ветку dev	
	git branch testing -- Создать новую ветку testing
		-v -- Последние коммиты
		--merged
		--no-merged
		-u origin/serverfix -- Добавить к ветке автоматическое отслеживание хоста
		-vv -- Посмотреть есть ли автоматическое отслеживание у веток
	
	git checkout testing -- Переключиться на новую ветку, если ветка отличается от последней, то будет произведена работа по откату проекта
	git checkout -- CONTRIBUTING.md -- Откатить файл к прошлой версии
	-b <new-branch-name> -- откатиться и создать новую ветку
	git checkout --track origin/serverfix -- Автоматическое получение обновлений с хоста (автоматический pull). Только если ветки ещё нет
	
	
	git merge branchName -- Слить текущую ветку с веткой branchName
	git mergetool -- Запустить программу для устранение конфликтов слияния

	
	git rebase origin/master -- Нагнать оригинальную ветку. Берёт активную ветку и выполняет все команды, которые были выполнены на origin/master
		git rebase --onto master server client -- Взять ветку client, которая пошла от server, который пошёл от main и прогнать client, пропустим дальнейшее развитие ветки server
		- Отличия от merge:
			- Более чистая история и накатка только вперёд
			- Заменяет предыдущие изменения текущими
			- Do not rebase commits that exist outside your repository -- Инача будут сложности с забором новой информации у вас
	
	