#!/usr/bin/bash
#Run with sudo
#by Tren3000 for Astar Linux 1.8 Smolensk

echo -e "\e[32mЗапускайте скрипт от sudo-пользователя\e[0m";sleep 2; echo
echo -e "\e[32mЕсли готовы, то нажмите Enter, чтобы продолжить...\e[0m"
read -p "" # pause for waiting user, to start

# Am i root ?????
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31mОшибка!\e[0m \e[33mСкрипт запущен не от имени root (error_01)\e[0m"
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
    echo -e "\e[31mВнимание! Не установлен или недоступен для редактирования syslog-ng.\e[0m"
    sleep 2
    echo -e "\e[32mИнициализация установки syslog-ng через менеджер пакетов APT...\e[0m"
    sleep 2
    sudo apt install syslog-ng -y
    # Installation syslog-ng
    if [ $? -eq 0 ]; then
        echo -e "\e[32msyslog-ng успешно установлен.\e[0m"
    else
        echo -e "\e[31mНе удалось установить syslog-ng. Обратитесь к системному администратору (error_03).\e[0m"
        exit 3
    fi
else
    echo -e "\e[32msyslog-ng уже установлен и доступен для редактирования\e[0m";sleep 2; echo
fi

#Add log directory
LOG_DIR="/var/log/remote_logs/"

if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    chmod 750 "$LOG_DIR"
    echo -e "\e[32mСоздан каталог для логов: $LOG_DIR с правами доступа 750\e[0m";sleep 2; echo
fi

# BackUp syslog.conf

if sudo cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.bak
    then 
        echo -e "\e[32mСоздаю бэкап, на всякий пожарный ... \e[0m"; sleep 2; echo
    else
        echo -e "\e[33mБэкап пошёл не по плану, хз почему, но пофиг! Продолжаем!\e[0m";sleep 2; echo
fi
echo -e "\e[32mBackUp конфигурационного файла syslog-ng успешно создан\e[0m";sleep 2; echo

# Starting to write syslog-ng conf-file

echo -e "\e[32mПроверка наличия и доступа конфигурационного файла syslog-ng ... \e[0m";sleep 2; echo
if [ ! -w "/etc/syslog-ng/syslog-ng.conf" ]
    then
        echo -e "\e[31mОшибка!\e[0m \e[33mНе хватает прав для редактирования настроек syslog-ng (error_04)\e[0m"
    exit 4
echo -e "\e[32mКонфигурационный файл существует и доступ получен \e[0m";sleep 2; echo
fi

# Check protocol
while true; do
    echo -e "\e[32mВведите протокол (udp/tcp):  \e[0m"; read protocol
        if [[ "$protocol" == "udp" || "$protocol" == "tcp" ]]; then
        break
    else
        echo -e "\e[31mОшибка!\e[0m \e[33mПожалуйста, введите\e[0m \e[32m'udp'\e[0m \e[33mили\e[0m \e[32m'tcp'\e[0m: "
    fi
done

##########################################################################////SERVER//////###################################################
# Check SERVER IP
while true; do
    echo -e "\e[32mВаш IP-адрес - $(hostname -I) Введите IP-адрес сервера логов: \e[0m"
    read ip_address

    if [[ "$ip_address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # Проверка каждого октета
        IFS='.' read -r -a octets <<< "$ip_address"
        valid_ip=true
        for octet in "${octets[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                valid_ip=false
                break
            fi
        done
        if [ "$valid_ip" = true ]; then
            break
        else
            echo -e "\e[31mОшибка!\e[0m \e[33mIP-адрес содержит недопустимые значения\e[0m"
        fi
    else
        echo -e "\e[31mОшибка!\e[0m  \e[33mНеверный формат IP-адреса\e[0m"
    fi
done
# Check port
while true; do
    echo -e "\e[32mВведите номер порта (1-65535), по умолчанию 514: \e[0m"; read port
    if [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 )); then
        break
    else
        echo -e "\e[31mОшибка!\e[0m \e[33mВведите число от 1 до 65535\e[0m"
    fi
done

echo -e "\e[32mПроизводится запись в конфигурационный файл ... \e[0m";sleep 2; echo

# If code already exist in syslog-ng-conf
if ! grep -E '^\s*source s_net' /etc/syslog-ng/syslog-ng.conf; then
    echo >> /etc/syslog-ng/syslog-ng.conf
    echo "######################################" >> /etc/syslog-ng/syslog-ng.conf
    echo "# Mikrotik logs by Tren3000" >> /etc/syslog-ng/syslog-ng.conf
    echo "######################################" >> /etc/syslog-ng/syslog-ng.conf
    echo "source s_net { $protocol(ip($ip_address) port($port)); };" >> /etc/syslog-ng/syslog-ng.conf
    echo -e "\e[32mЗапись, в конфигурационный файл, успешно добавлена! \e[0m";sleep 2; echo
else
    echo -e "\e[33mЗапись о данных сервера syslog-ng, уже присутствует в файле, добавление пропущено! \e[0m";sleep 2; echo
fi
##########################################################################////END_SERVER//////###################################################

##########################################################################////SENDER//////###################################################
#Create Mikrotik.conf
echo -e "\e[32mСоздание файла конфигурации syslog-ng для Mikrotik ... \e[0m";sleep 2; echo
touch /etc/syslog-ng/conf.d/mikrotik.conf 2>/dev/null
if [ -e /etc/syslog-ng/conf.d/mikrotik.conf ]; then
    echo -e "\e[32mФайл конфигурации syslog-ng для Mikrotik успешно создан \e[0m"
else
    echo -e "\e[33mФайл конфигурации Mikrotik уже существует. Запись будет производиться в существующий файл\e[0m"
fi

# Check SENDER ip if it is exist
function ip_exists_in_config() {
    local ip="$1"
    grep -q "netmask("$sender_ip_address/255.255.255.255")" /etc/syslog-ng/conf.d/mikrotik.conf
}
# Check first sender ip
while true; do
    echo -e "\e[32mВведите IP-адрес отправителя логов: \e[0m"
    read sender_ip_address
    if [[ "$sender_ip_address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$sender_ip_address"
        valid_ip=true
        for octet in "${octets[@]}"; do
            if ((octet < 0 || octet > 255)); then
                valid_ip=false
                break
            fi
        done
        if $valid_ip; then
            # Check if ip already exist
            if ip_exists_in_config "$sender_ip_address"; then
                echo -e "\e[31mОшибка!\e[0m \e[33mЭтот IP уже добавлен в конфигурацию.\e[0m"
            else
                break
            fi
        else
            echo -e "\e[31mОшибка!\e[0m \e[33mIP-адрес содержит недопустимые значения\e[0m"
        fi
    else
        echo -e "\e[31mОшибка!\e[0m  \e[33mНеверный формат IP-адреса\e[0m"
    fi
done


echo -e "\e[32mВносятся изменения, в файл конфигурации Mikrotik ... \e[0m"
sleep 2
echo "######################################" >> /etc/syslog-ng/conf.d/mikrotik.conf
echo "# Mikrotik logs by Tren3000" >> /etc/syslog-ng/conf.d/mikrotik.conf
echo "######################################" >> /etc/syslog-ng/conf.d/mikrotik.conf
echo "destination d_mikrotik { file("/var/log/remote_logs/mikrotik.log"); };" >> /etc/syslog-ng/conf.d/mikrotik.conf
echo "filter f_mikrotik { netmask("$sender_ip_address/255.255.255.255"); };" >> /etc/syslog-ng/conf.d/mikrotik.conf
echo "log { source(s_net); filter(f_mikrotik); destination(d_mikrotik); };" >> /etc/syslog-ng/conf.d/mikrotik.conf

# Add another sender ip, if user want
while true; do
    echo -e "\e[32mХотите добавить еще IP-адрес? (y/n):\e[0m " 
    read add_more

    if [[ "$add_more" =~ ^[Yy]$ ]]; then
        # Check new added sender ip
        while true; do
            echo -e "\e[32mВведите IP-адрес отправителя логов: \e[0m"
            read sender_ip_address
            if [[ "$sender_ip_address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                IFS='.' read -r -a octets <<< "$sender_ip_address"
                valid_ip=true
                for octet in "${octets[@]}"; do
                    if ((octet < 0 || octet > 255)); then
                        valid_ip=false
                        break
                    fi
                done
                if $valid_ip; then
                    if ip_exists_in_config "$sender_ip_address"; then
                        echo -e "\e[33mЭтот IP уже добавлен в конфигурацию.\e[0m"
                    else
                        break
                    fi
                else
                    echo -e "\e[31mОшибка!\e[0m \e[33mIP-адрес содержит недопустимые значения\e[0m"
                fi
            else
                echo -e "\e[31mОшибка!\e[0m  \e[33mНеверный формат IP-адреса\e[0m"
            fi
        done

        #Counter
        touch /tmp/mikrotik_counter.txt &>/dev/null
        COUNTER_FILE="/tmp/mikrotik_counter.txt"
        if [ ! -f "$COUNTER_FILE" ]; then
        echo 0 > "$COUNTER_FILE"
        fi
        counter=$(cat "$COUNTER_FILE")
        counter=$((counter + 1))
        echo "$counter" > "$COUNTER_FILE"
        
        # Запись новых настроек в конфигурационный файл
        echo "######################################" >> /etc/syslog-ng/conf.d/mikrotik.conf
        echo "# Mikrotik logs by Tren3000" >> /etc/syslog-ng/conf.d/mikrotik.conf
        echo "######################################" >> /etc/syslog-ng/conf.d/mikrotik.conf
        echo "destination d_mikrotik_${counter} { file("/var/log/remote_logs/mikrotik.log"); };" >> /etc/syslog-ng/conf.d/mikrotik.conf
        echo "filter f_mikrotik_${counter} { netmask("$sender_ip_address/255.255.255.255"); };" >> /etc/syslog-ng/conf.d/mikrotik.conf
        echo "log { source(s_net); filter(f_mikrotik_${counter}); destination(d_mikrotik_${counter}); };" >> /etc/syslog-ng/conf.d/mikrotik.conf
    elif [[ "$add_more" =~ ^[Nn]$ ]]; then
        echo -e "\e[32mЗавершение добавления IP-адресов\e[0m";sleep 2; echo
        break
    else
        echo "\e[33mПожалуйста, введите y или n.\e[0m"
    fi
done
##########################################################################////END_SENDER//////###################################################
echo -e "\e[32mПерезазапускаю службу syslog-ng ...\e[0m";sleep 2; echo
sudo systemctl restart syslog-ng
# Restart syslog-ng
systemctl restart syslog-ng
# Check status
echo -e "\e[32mПроверка статуса службы syslog-ng: \e[0m";sleep 2; echo
systemctl status syslog-ng --no-pager || echo -e "\e[33mПроверка статуса не удалась, но, в целом .... \e[0m"
echo -e "\e[32mУстановка завершена успешно! ... by Tren3000 ... \e[0m"

exit 0
