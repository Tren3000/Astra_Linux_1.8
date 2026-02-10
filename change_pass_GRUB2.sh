#!/usr/bin/bash
#Scrips fot changings/add GRUB2 password
#Run with sudo
#by Tren3000 for Astar Linux 1.8 Smolensk
if [ ! -w "/boot/grub/user.cfg" ]
    then
        echo "Ошибка! Нехватает прав для изменения user.cfg (error_01)"
    exit 1
fi
echo -n "Введите логин администратора:         "; read grub_user
echo -n "Введите новый пароль GRUB2:           "; read grub_pass1
echo -n "Повторите новый пароль GRUB2:         "; read grub_pass2
if [ $grub_pass1 != $grub_pass2 ]
    then
    echo "Ошибка: пароли не совпадают (error_02)"
    exit 2
fi

grub_hash=$( grub-mkpasswd-pbkdf2  <<- DOC
$grub_pass1
$grub_pass2
DOC
)
grub_hash=$(echo $grub_hash | awk '{print $NF}' )
cat > /boot/grub/user.cfg << DOC
GRUB2_PASSWORD=$grub_hash
GRUB2_USER=$grub_user
DOC
update-grub &>/dev/null
if [ "$?" -eq "0" ]; then
    echo "Новый пароль GRUB успешно установлен"
else
    echo "Ошибка: не удалось обновить конфигурационный файл GRUB2 (error_03)"
    exit 3
fi
exit 0
