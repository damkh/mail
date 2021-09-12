# Mail notifications to Matrix
## Dovecot
Для работы дополнений в sieve-скриптах, необходимо дописать информацию о них в конфиг-файлы dovecot:  
#### /etc/dovecot/conf.d/90-sieve.conf:  
```
sieve_extensions = +vnd.dovecot.execute
sieve_plugins = sieve_extprograms
```
#### /etc/dovecot/conf.d/90-sieve-extprograms.conf:  
```
plugin {
  sieve_execute_socket_dir = sieve-execute
  sieve_execute_bin_dir = /usr/lib/dovecot/sieve-execute
}
```
После изменений необходимо перечитать конфигурацию dovecot

## Фильтры Sieve
Для обработки писем необходимо создать фильтр, исполняющий скрипт send_msg_to_matrix.sh из директории /usr/lib/dovecot/sieve-execute (это рабочая директория dovecot).
```
require ["fileinto", "mime", "variables", "extracttext", "copy", "envelope", "vnd.dovecot.execute", "foreverypart"];
# rule:[mail_notifications_to_matrix]
if header :matches "from" "*"
{
        set "from" "${1}";
}

if header :matches "subject" "*"
{
        set "subject" "${1}";
}

if header :matches "to" "*"
{
        set "to" "${1}";
}

execute :output "notify_matrix" "send_msg_to_matrix.sh" ["${from}", "${subject}", "${to}"];
```

Если у пользователя уже есть существующие фильтры, необходимо отредактировать существующий sieve-скрипт:
 - добавить необходимые модули в поле require (данная опция должна указываться в начале скрипта только 1 раз)
 - добавить тело фильтра
Например, содержимое sieve-скрипта с 2-мя фильтрами может выглядеть так:
```
require ["fileinto","imap4flags", "mime", "variables", "extracttext", "copy", "envelope", "vnd.dovecot.execute", "foreverypart"];
# rule:[Zabbix]
if anyof (header :contains "from" "zabbix", header :contains "from" "zbx")
{
        fileinto "INBOX.zabbix";
}
# rule:[mail_notifications_to_matrix]
if header :matches "from" "*"
{
        set "from" "${1}";
}

if header :matches "subject" "*"
{
        set "subject" "${1}";
}

if header :matches "to" "*"
{
        set "to" "${1}";
}

execute :output "notify_matrix" "send_msg_to_matrix.sh" ["${from}", "${subject}", "${to}"];
```

Если пользователю необходимы уведомления в matrix только от определенных отправителей или наоборот необходимо исключить отправителей, это можно настроить через почтовые фильтры.
Например, пользователь user01@myexample.com не хочет получать уведомления в matrix от отправителей bad@domain1.com и good@domain2.com. В таком случае sieve-скрипт будет выглядеть так:
```
# rule:[mail_notifications_to_matrix]
if allof (not header :contains "from" "bad@domain1.com", not header :contains "from" "good@domain2.com", header :matches "to" "*")
{
        set "to" "${1}";
}
if header :matches "from" "*"
{
        set "from" "${1}";
}
if header :matches "subject" "*"
{
        set "subject" "${1}";
}
execute :output "notify_matrix" "send_msg_to_matrix.sh" ["${from}", "${subject}", "${to}"];
```

## Скрипт send_msg_to_matrix.sh
Данный скрипт получает и обрабатывает заголовки письма и отправляет их в определенную комнату matrix-сервера в формате:
```
От кого: ...
Кому: ...
Тема: ...
```
Для работы скрипта необходимо иметь следующие данные:
- MATRIX_SERVER - адрес matrix-сервера, например, "https://matrix.myexample.com"  
- ROOM_ID - ID комнаты, в которую будут отправляться уведомления. ID должен быть указан в формате <ID>:<SERVER>, его можно получить в Element через Room -> Settings -> Advanced. Например, Ms123455vdcBt:matrix.myexample.com  
- ACCESS_TOKEN - токен доступа к matrix-серверу, генерируется для каждой сессии аккаунта. Его можно получить в клиенте Element через Account -> All Settings -> Help & About -> Access Token. Обычно токен представляет из себя длинный набор букв и цифр.  
Скрипт может исполняться для нескольких почтовых ящиков. Для правильного выбора комнаты необходимо добавить условный блок, в котором для определенного ящика присваивается определенный ID комнаты:
```
if [ $HEADER_TO_MAIL == "user@myexample.com" ];
then
    ROOM_ID="!ZveqosTf123456hPDV:matrix.myexample.com"
fi
```

## Алгоритм внедрения
Пусть пользователь user01 имеет почтовый ящик user01@myexample.com. Он хочет получать уведомления в matrix о новых письмах.  
Для этого необходимо:
- Создать служебного пользователя на matrix-сервере (например, @mail-matrix:matrix.myexample.com) и получить его ACCESS_TOKEN
- Создать комнату со служебным пользователем и получить ID этой комнаты (ROOM_ID)
- Создать новый фильтр для вызова скрипта send_msg_to_matrix.sh на почтовом сервере (можно через Roundcube) либо добавить в набор существующих фильтров.
- Скопировать скрипт send_msg_to_matrix.sh в /usr/lib/dovecot/sieve-execute на почтовом сервер, выдать права на исполнение и вписать в него параметры:
- - MATRIX_SERVER
- - ACCESS_TOKEN
- - IF-блок с соответствием ROOM_ID почтовому ящику пользователя

## Логирование
Для логирования данных, получаемых скриптом необходимо создать файл, указанный в переменной DEBUG_LOG=/var/log/mail.debug и выдать ему полные права (`chmod 777 /var/log/mail.debug`).

