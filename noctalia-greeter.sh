#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт с помощью sudo или от имени root."
  exit 1
fi

echo "1. Создание системного пользователя..."
useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter greeter 2>/dev/null || true

echo "2. Конфиг greetd..."
mkdir -p /etc/greetd
tee /etc/greetd/config.toml >/dev/null <<'GREETD_CONFIG'
[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "greeter"
GREETD_CONFIG

echo "3. Авторазблокировка gnome-keyring через PAM..."
cp -n /etc/pam.d/greetd /etc/pam.d/greetd.bak
grep -q 'pam_gnome_keyring.so$' /etc/pam.d/greetd || \
  echo 'auth       optional     pam_gnome_keyring.so' >> /etc/pam.d/greetd
grep -q 'pam_gnome_keyring.so auto_start' /etc/pam.d/greetd || \
  echo 'session    optional     pam_gnome_keyring.so auto_start' >> /etc/pam.d/greetd

echo "Готово!"
