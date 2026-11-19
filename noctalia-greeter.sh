#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт с помощью sudo или от имени root."
  exit 1
fi

echo "1. Создание системного пользователя greeter..."
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

echo "4. Тихий запуск Hyprland по умолчанию..."
tee /usr/local/bin/hypr-session >/dev/null <<'WRAPPER'
#!/bin/sh
mkdir -p "$HOME/.cache"
exec /usr/bin/start-hyprland >"$HOME/.cache/hyprland-session.log" 2>&1
WRAPPER
chmod +x /usr/local/bin/hypr-session

rm -f /usr/share/wayland-sessions/hyprland-quiet.desktop

sed -i 's|^Exec=.*|Exec=/usr/local/bin/hypr-session|' /usr/share/wayland-sessions/hyprland.desktop

echo "5. Хук pacman: вернуть правку после обновления hyprland..."
mkdir -p /etc/pacman.d/hooks
tee /etc/pacman.d/hooks/hyprland-quiet.hook >/dev/null <<'HOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyprland

[Action]
Description = Запуск Hyprland без логов
When = PostTransaction
Exec = /usr/bin/sed -i 's|^Exec=.*|Exec=/usr/local/bin/hypr-session|' /usr/share/wayland-sessions/hyprland.desktop
HOOK

echo "Готово!"

