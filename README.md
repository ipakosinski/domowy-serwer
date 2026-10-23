# Domowy serwer na Dockerze

Domowy serwer postawiony na starym komputerze Dell OptiPlex (i5-4590, 8 GB RAM, SSD na system, HDD na dane) z Linux Mint. Projekt realizowany w celach nauki administracji systemami, sieci i bezpieczeństwa.

## Usługi
- **Pi-hole** - blokowanie reklam i trackerów na poziomie DNS (tryb `host`)
- **Samba** - dysk sieciowy
- **Syncthing** - synchronizacja plików (np. zdjęcia z telefonu)
- **Jellyfin** - serwer multimediów z akceleracją sprzętową (Intel Quick Sync, VAAPI)
- **Tailscale** - bezpieczny dostęp zdalny (VPN)

## Architektura

    Internet
        |
    Router 4G (192.168.8.1, WAN w CGNAT)
        |
        +-- Serwer (192.168.8.117, rezerwacja DHCP)
        |     +-- Pi-hole   (DNS 53, panel 80)
        |     +-- Samba     (445)
        |     +-- Syncthing (8384, 22000)
        |     +-- Jellyfin  (8096)
        |     +-- Tailscale (VPN)
        +-- Komputery i telefony w sieci domowej

Konfiguracje kontenerów leżą na SSD (`./config`), a dane na HDD (`/mnt/dane`).

## Uruchomienie
1. Zainstaluj Docker i Docker Compose.
2. Skopiuj `.env.example` jako `.env` i uzupełnij hasła.
3. Wyłącz stub resolver, żeby zwolnić port 53 (`DNSStubListener=no` w systemd-resolved).
4. Utwórz foldery danych w `/mnt/dane` (filmy, udostepnione, syncthing).
5. Uruchom: `docker compose up -d`.

## Bezpieczeństwo
Zabezpieczenie serwera (SSH tylko z kluczem, zapora ufw, fail2ban, automatyczne aktualizacje, audyt Lynis) opisano w [HARDENING.md](HARDENING.md). Wynik audytu Lynis: z 60 do 64 punktów.

## Dostęp zdalny
Router korzysta z sieci komórkowej 4G, a jego adres WAN należy do zakresu prywatnego (10.x.x.x). To oznacza **CGNAT**: router nie ma własnego publicznego adresu IP, więc przekierowanie portów (np. dla klasycznego WireGuarda) nie zadziała, mimo że router oferuje taką funkcję.

Rozwiązanie: **Tailscale**. Urządzenia łączą się przez pośredniczące serwery, bez otwartych portów i bez publicznego IP. Technologia pod spodem to WireGuard.

- Serwer udostępnia przez VPN wyłącznie własny adres (`192.168.8.117/32`), a nie całą sieć domową.
- Konto Tailscale zabezpieczone dwuskładnikowo, wygasanie klucza serwera wyłączone.
- Zapora ufw dopuszcza SSH z interfejsu Tailscale.
- Panele usług (Jellyfin, Syncthing) i Samba są przypięte do adresu serwera w sieci domowej, a dostęp spoza domu odbywa się wyłącznie przez VPN.

Ograniczenia: zależność od zewnętrznego serwisu koordynującego połączenia oraz warunki jego darmowego planu.

Wynik testu z sieci komórkowej: Jellyfin otwiera się z telefonu na danych komórkowych po włączeniu Tailscale

## Napotkane problemy i rozwiązania
- **Pi-hole nie odpowiadał na DNS** - w logach błąd o braku capability NET_ADMIN. Rozwiązanie: `cap_add: NET_ADMIN` w konfiguracji kontenera.
- **Port 53 zajęty** - domyślnie nasłuchuje na nim systemd-resolved. Rozwiązanie: wyłączenie DNSStubListener.
- **Jellyfin w pętli restartów** - brak uprawnień do katalogu `/config`. Rozwiązanie: `chown` na użytkownika kontenera.
- **Hasła nie działały po przeniesieniu do `.env`** - brak znaku `$` w zapisie `${ZMIENNA}`.
- **Błąd SSL przy panelu Pi-hole** - przeglądarka używała HTTPS zamiast HTTP.
- **Dostęp zdalny przez klasyczny WireGuard niemożliwy** - adres WAN routera 4G w zakresie prywatnym (CGNAT). Rozwiązanie: Tailscale.
- **Porty Dockera omijają ufw** - Docker modyfikuje iptables bezpośrednio. Rozwiązanie: przypięcie portów do adresu serwera w `docker-compose.yml`.

## Plany rozwoju
- Kopie zapasowe konfiguracji (restic)
- Monitoring (Uptime Kuma, Grafana)
- Reverse proxy z HTTPS
- Osobny firewall (OPNsense) i segmentacja sieci
