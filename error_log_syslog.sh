#!/usr/bin/bash
#Scrips is making custom log-file, whitch contain words Error/error/Err/err
#Run with sudo
#by Tren3000 for Astar Linux 1.8 Smolensk

echo -n "Запускайте скрипт от sudo-пользователя  "

# Am i root ?????
if [ "$EUID" -ne 0 ]; then
    echo "Запустите скрипт от имени root (error_01)"
    exit 1
fi

# I am not shure, that you are really root...
if touch /root/1.txt &>/dev/null
        then
        rm /root/1.txt
        else
                echo "Сказано же, русским по белому - запускать от имени root (error_02)"
        exit 2
fi

echo -n "Введите имя лога, в виде имя_лога.log :         "; read -p log_name

echo -n "Создание log-файла ... "
touch /var/log/$log_name # making log-file
if [ ! -w "/var/log/$log_name" ]
    then
        echo "Ошибка! Нехватает прав для создания лога (error_03)"
    exit 3
fi
echo -n "Log-файл создан!"
echo -n "Введите имя именованного канала, например mypipe :         "; read -p pipe_name
echo -n "Создание именнованного канала ... "
sudo mkfifo /tmp/$pipe_name
touch /tmp/$pipe_name # making pipe
if [ ! -w "/tmp/$pipe_name" ]
    then
        echo "Ошибка! Нехватает прав для создания именованного канала (error_04)"
    exit 4
fi
echo -n "Файл именованного канала создан! "
echo -n "Запись в конфигурационный файл syslog-ng ... "
if [ ! -w "/etc/syslog-ng/syslog-ng.conf" ]
    then
        echo "Ошибка! Нехватает прав для редактирования настроек syslog-ng (error_05)"
    exit 5
fi

echo -n "Идет запись в файл конфигурации syslog-ng ... "


echo >> /etc/syslog-ng/syslog-ng.conf
echo. >> /etc/syslog-ng/syslog-ng.conf
echo "######################################" >> /etc/syslog-ng/syslog-ng.conf
echo "# My logs by Tren3000" >> /etc/syslog-ng/syslog-ng.conf
echo "######################################" >> /etc/syslog-ng/syslog-ng.conf
echo "destination d_mylog { file("/var/log/$log_name"); };" >> /etc/syslog-ng/syslog-ng.conf
echo "destination d_mypipe { pipe("/var/tmp/$pipe_name"); };" >> /etc/syslog-ng/syslog-ng.conf
echo "filter f_my { message('(\b[Ee]rr(or)?\b)'); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(s_src); filter(f_my); destination(d_mylog); destination(d_mypipe); };" >> /etc/syslog-ng/syslog-ng.conf
echo "######################################" >> /etc/syslog-ng/syslog-ng.conf

echo -n " Запись в конфигурационный файл прошла успешно! "

echo -n " Перезапускаю службу syslog-ng ... "

sudo systemctl restart syslog-ng || echo -n " Перезагрузка службы syslog-ng завершилось ошибкой, проверьте настройки системы или перезагрузите службу syslog-ng вручную ! (error_06)"; exit 6

echo " Установка скрипта прошла успешно! Наслаждайтесь результатом =) by Tren3000 "

exit 0
