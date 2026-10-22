# Domowy serwer na Dockerze

Domowy serwer postawiony na starym komputerze Dell OptiPlex (i5-4590, 8 GB RAM, SSD na system, HDD na dane) z Linux Mint. Projekt realizowany w celach nauki administracji systemami, sieci i bezpieczeństwa.

## Usługi
- **Pi-hole** - blokowanie reklam i trackerów na poziomie DNS dla całej sieci
- **Samba** - dysk sieciowy
- **Syncthing** - synchronizacja plików (np. zdjęcia z telefonu)
- **Jellyfin** - serwer multimediów z akceleracją sprzętową (Intel Quick Sync, VAAPI)

## Architektura

    Router 4G (192.168.8.1)
        |
        +-- Serwer (192.168.8.117, rezerwacja DHCP)
        |     +-- Pi-hole   (DNS 53, panel 80, tryb host)
        |     +-- Samba     (445)
        |     +-- Syncthing (8384, 22000)
        |     +-- Jellyfin  (8096)
        +-- Komputery i telefony w sieci domowej

Pliki: konfiguracje kontenerów na SSD (`./config`), dane na HDD (`/mnt/dane`).

## Uruchomienie
1. Zainstaluj Docker i Docker Compose.
2. Skopiuj `.env.example` jako `.env` i uzupełnij hasła.
3. Wyłącz stub resolver, żeby zwolnić port 53 (`DNSStubListener=no` w systemd-resolved).
4. Utwórz foldery danych w `/mnt/dane` (filmy, udostepnione, syncthing).
5. Uruchom: `docker compose up -d`.

## Bezpieczeństwo
Zabezpieczenie serwera (SSH tylko z kluczem, zapora ufw, fail2ban, automatyczne aktualizacje, audyt Lynis) opisano w pliku [HARDENING.md](HARDENING.md).

## Napotkane problemy i rozwiązania
- **Pi-hole nie odpowiadał na DNS** - w logach błąd o braku capability NET_ADMIN. Rozwiązanie: `cap_add: NET_ADMIN` w konfiguracji kontenera.
- **Port 53 zajęty** - domyślnie nasłuchuje na nim systemd-resolved. Rozwiązanie: wyłączenie DNSStubListener.
- **Jellyfin w pętli restartów** - brak uprawnień do katalogu `/config`. Rozwiązanie: `chown` na użytkownika kontenera.
- **Hasła nie działały po przeniesieniu do `.env`** - brak znaku `$` w zapisie `${ZMIENNA}`.
- **Błąd SSL przy panelu Pi-hole** - przeglądarka używała HTTPS zamiast HTTP.

## Plany rozwoju
- VPN (WireGuard/Tailscale) do dostępu spoza domu
- Reverse proxy z HTTPS
- Monitoring (Uptime Kuma, Grafana)
- Osobny firewall (OPNsense) i segmentacja sieci
