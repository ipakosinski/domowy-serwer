#!/bin/bash
# Kopia zapasowa konfiguracji serwera (restic)
set -euo pipefail

REPO=/mnt/dane/kopie/restic
HASLO=/root/restic-haslo
SERWER=/home/admin1/serwer

# nie rob kopii, jesli dysk z danymi nie jest zamontowany
mountpoint -q /mnt/dane || { echo "$(date) BLAD: /mnt/dane nie jest zamontowany"; exit 1; }

echo "$(date) START"
cd "$SERWER"
trap 'cd "$SERWER" && docker compose start' EXIT
docker compose stop

restic -r "$REPO" --password-file "$HASLO" backup \
  "$SERWER/docker-compose.yml" "$SERWER/.env" "$SERWER/config" \
  /etc/ssh/sshd_config.d /etc/fail2ban/jail.d /etc/systemd/resolved.conf.d \
  /etc/ufw /etc/fstab /home/admin1/.ssh/authorized_keys \
  --exclude-file /etc/restic-wyklucz.txt --tag konfiguracja

restic -r "$REPO" --password-file "$HASLO" forget \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune

restic -r "$REPO" --password-file "$HASLO" check
echo "$(date) KONIEC"
