#!/usr/bin/bash
#Scrips is making custom log-file, whitch contain words Error/error/Err/err
#Run with sudo
#by Tren3000 for Astar Linux 1.8 Smolensk

echo -e "\e[32mЗапускайте скрипт от sudo-пользователя\e[0m"

# Am i root ?????
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mЗапустите скрипт от имени root (error_01)\e[0m"
    exit 1
fi

# I am not shure, that you are really root...
if touch /root/1.txt &>/dev/null
        then
        rm /root/1.txt
        else
                echo -e "\e[31mСказано же, русским по белому - запускать от имени root (error_02)\e[0m"
        exit 2
fi

# Is it OS Astra Linux? Or is the syslog-ng installed ?
if [ ! -w "/etc/syslog-ng/syslog-ng.conf" ]; then
    echo -e "\e[31mОшибка! Не установлен syslog-ng, либо, у Вас не OS Astra Linux (error_03)\e[0m"
        exit 3
fi

# BackUp syslog.conf

if sudo cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.bak
    then 
        echo -e "\e[32mСоздаю бэкап, на всякий пожарный ... \e[0m"
    else
        echo -e "\e[33mБэкап пошёл не по плану, хз почему, но пофиг! Продолжаем!\e[0m"
fi

echo -e "\e[32mВведите имя лога, в виде имя_лога.log :\e[0m         "; read log_name

echo -e "\e[32mСоздание log-файла ...\e[0m  "
touch /var/log/$log_name # making log-file
if [ ! -w "/var/log/$log_name" ]
    then
        echo -e "\e[31mОшибка! Нехватает прав для создания лога (error_03)\e[0m"
    exit 3
fi
echo -e "\e[32mLog-файл создан!\e[0m"
echo -e "\e[32mВведите имя именованного канала, например mypipe :\e[0m         "; read pipe_name
echo -e "\e[32mСоздание именнованного канала ...\e[0m"
sudo mkfifo /tmp/$pipe_name
touch /tmp/$pipe_name # making pipe
if [ ! -w "/tmp/$pipe_name" ]
    then
        echo -e "\e[31mОшибка! Нехватает прав для создания именованного канала (error_05)\e[0m"
    exit 5
fi
echo -e "\e[32mФайл именованного канала создан! \e[0m"
echo -e "\e[32mЗапись в конфигурационный файл syslog-ng ... \e[0m"
if [ ! -w "/etc/syslog-ng/syslog-ng.conf" ]
    then
        echo -e "\e[31mОшибка! Нехватает прав для редактирования настроек syslog-ng (error_06)\e[0m"
    exit 6
fi

echo -e "\e[32mИдет запись в файл конфигурации syslog-ng ... \e[0m"


echo >> /etc/syslog-ng/syslog-ng.conf
echo "######################################" >> /etc/syslog-ng/syslog-ng.conf
echo "# My logs by Tren3000" >> /etc/syslog-ng/syslog-ng.conf
echo "######################################" >> /etc/syslog-ng/syslog-ng.conf
echo "destination d_mylog { file("/var/log/$log_name"); };" >> /etc/syslog-ng/syslog-ng.conf
echo "destination d_mypipe { pipe("/var/tmp/$pipe_name"); };" >> /etc/syslog-ng/syslog-ng.conf
echo "filter f_my { message('(\b[Ee]rr(or)?\b)'); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(s_src); filter(f_my); destination(d_mylog); destination(d_mypipe); };" >> /etc/syslog-ng/syslog-ng.conf
echo "######################################" >> /etc/syslog-ng/syslog-ng.conf

echo -e "\e[32m Запись в конфигурационный файл прошла успешно! \e[0m"

echo -e "\e[32m Перезапускаю службу syslog-ng ... \e[0m"

sudo systemctl restart syslog-ng || echo -e "\e[31m Перезагрузка службы syslog-ng завершилось ошибкой, проверьте настройки системы или перезагрузите службу syslog-ng вручную ! (error_07)\e[0m"; exit 7

echo -e "\e[32m Установка скрипта прошла успешно! Наслаждайтесь результатом =) by Tren3000 \e[0m"

exit 0
