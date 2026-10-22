# Zabezpieczenie serwera (hardening)

Środowisko: Linux Mint, serwer w sieci domowej za routerem 4G.

## Wynik audytu Lynis
| Moment | Hardening index |
|---|---|
| Przed zmianami | 60 |
| Po zmianach | 64 |

## Wprowadzone zmiany

### 1. Aktualizacje
Zainstalowano `unattended-upgrades`, poprawki bezpieczeństwa instalują się automatycznie.

### 2. SSH
- logowanie wyłącznie kluczem (klucz ed25519), hasło wyłączone: `PasswordAuthentication no`
- zablokowane logowanie na roota: `PermitRootLogin no`
- dostęp tylko dla jednego użytkownika: `AllowUsers`
- konfiguracja w osobnym pliku `/etc/ssh/sshd_config.d/01-hardening.conf` (pierwsza napotkana wartość wygrywa, więc plik ma niski numer)

### 3. Zapora (ufw)
- domyślnie blokowany ruch przychodzący, dozwolony wychodzący
- SSH, DNS i panel Pi-hole dostępne tylko z sieci domowej (192.168.8.0/24)

**Uwaga o Dockerze:** porty publikowane przez Dockera omijają ufw (Docker modyfikuje iptables bezpośrednio). Panele (Jellyfin, Syncthing) i Samba są dlatego przypięte w `docker-compose.yml` do adresu serwera w sieci domowej. Pi-hole działa w trybie `host`, więc podlega regułom ufw.

### 4. Fail2ban
Ochrona SSH przed zgadywaniem haseł: 5 nieudanych prób blokuje adres na godzinę.

## Weryfikacja
- logowanie hasłem jest odrzucane (`Permission denied (publickey)`)
- `ufw status verbose` pokazuje aktywną zaporę
- `fail2ban-client status sshd` pokazuje aktywny jail

## Do zrobienia
- przejrzeć pozostałe sugestie Lynisa
- ograniczyć uprawnienia kontenerów (read-only, no-new-privileges)
- kopie zapasowe konfiguracji
