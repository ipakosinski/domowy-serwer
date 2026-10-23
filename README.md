# Domowy serwer na Dockerze

Domowy serwer postawiony na starym komputerze Dell OptiPlex (i5-4590, 8 GB RAM, SSD na system, HDD na dane) z Linux Mint. Projekt realizowany w celach nauki administracji systemami, sieci i bezpieczeństwa.

## Usługi
- **Pi-hole** - blokowanie reklam i trackerów na poziomie DNS (tryb `host`)
- **Samba** - dysk sieciowy
- **Syncthing** - synchronizacja plików (np. zdjęcia z telefonu)
- **Jellyfin** - serwer multimediów z akceleracją sprzętową (Intel Quick Sync, VAAPI)
- **Tailscale** - bezpieczny dostęp zdalny (VPN)
- **Uptime Kuma** - monitoring dostępności usług, powiadomienia na Discordzie
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

## Kopie zapasowe
Kopie konfiguracji wykonuje **restic** (szyfrowane, przyrostowe, z deduplikacją).

- **Zakres:** `docker-compose.yml`, `.env`, folder `config/` (Pi-hole, Syncthing, Jellyfin), konfiguracja SSH, fail2ban, ufw, systemd-resolved, `fstab`, `authorized_keys`.
- **Poza zakresem:** dane użytkownika (filmy, zdjęcia), cache, logi, historia zapytań Pi-hole i metadane Jellyfina (pobierają się ponownie), stan Tailscale (ponowne logowanie).
- **Lokalizacja:** repozytorium na HDD (`/mnt/dane/kopie/restic`) oraz ręcznie aktualizowana kopia na zewnętrznym nośniku.
- **Harmonogram:** codziennie o 11:30 (cron). Na czas kopii kontenery są zatrzymywane, żeby bazy SQLite były spójne.
- **Retencja:** 7 kopii dziennych, 4 tygodniowe, 6 miesięcznych.
- **Weryfikacja:** `restic check` po każdej kopii oraz test odtworzenia do katalogu tymczasowego.
- **Hasło repozytorium:** plik `/root/restic-haslo` (poza Gitem) oraz zapis w menedżerze haseł.
- **Skrypt:** [backup/backup-serwera.sh](backup/backup-serwera.sh), lista wykluczeń w [backup/restic-wyklucz.txt](backup/restic-wyklucz.txt).

### Odtwarzanie po awarii
1. Zainstaluj system, Docker i restic.
2. Zamontuj HDD w `/mnt/dane` (lub podłącz nośnik z kopią).
3. Odtwórz pliki:

        sudo restic -r /mnt/dane/kopie/restic --password-file /root/restic-haslo restore latest --target /

4. Uruchom usługi: `cd ~/serwer && docker compose up -d`.
5. Zaloguj ponownie Tailscale (`sudo tailscale up`).

### Ograniczenia
- Kopia na HDD i oryginał na SSD to dwa dyski w jednym urządzeniu, dlatego potrzebna jest druga kopia na zewnętrznym nośniku (wykonywana ręcznie).
- Dane użytkownika (filmy, zdjęcia) nie są objęte tą kopią.
- Hasło do repozytorium jest niezbędne do odzyskania danych i musi być przechowywane poza serwerem.

## Monitoring
Dostępność usług monitoruje **Uptime Kuma**, a o awariach informuje powiadomieniem na Discordzie.

- **Monitorowane:** Jellyfin (HTTP `/health`), Syncthing i Samba (port TCP), Pi-hole (zapytanie DNS), router i internet (ping) oraz kopia zapasowa (monitor typu push).
- **Powiadomienia:** Discord (webhook), z dwoma powtórzeniami przed alarmem, żeby ograniczyć fałszywe alarmy.
- **Monitor kopii zapasowej:** skrypt kopii wysyła sygnał do Uptime Kuma po udanej kopii. Brak sygnału przez ponad dobę oznacza alarm, więc zepsuta lub niewykonana kopia nie pozostaje niezauważona.
- **Dostęp:** panel `http://192.168.8.117:3001` tylko z sieci domowej, konto z dwuskładnikowym logowaniem.
- **Dane:** `config/uptime-kuma`, objęte kopią zapasową.

### Dlaczego tryb sieci host
Uptime Kuma sprawdza usługi przez adres serwera. W zwykłej sieci Dockera jego zapytania miałyby adres z podsieci Dockera, a zapora ufw wpuszcza tylko ruch z sieci domowej. Tryb host omija ten problem i pozwala sprawdzać także Pi-hole (również w trybie host). Cena: panel podlega regułom ufw (reguła ograniczona do 192.168.8.0/24).

### Sekrety
Adres webhooka Discord i adres push (`/root/kuma-push-url`) są trzymane poza repozytorium.

## Napotkane problemy i rozwiązania
- **Pi-hole nie odpowiadał na DNS** - w logach błąd o braku capability NET_ADMIN. Rozwiązanie: `cap_add: NET_ADMIN` w konfiguracji kontenera.
- **Port 53 zajęty** - domyślnie nasłuchuje na nim systemd-resolved. Rozwiązanie: wyłączenie DNSStubListener.
- **Jellyfin w pętli restartów** - brak uprawnień do katalogu `/config`. Rozwiązanie: `chown` na użytkownika kontenera.
- **Hasła nie działały po przeniesieniu do `.env`** - brak znaku `$` w zapisie `${ZMIENNA}`.
- **Błąd SSL przy panelu Pi-hole** - przeglądarka używała HTTPS zamiast HTTP.
- **Dostęp zdalny przez klasyczny WireGuard niemożliwy** - adres WAN routera 4G w zakresie prywatnym (CGNAT). Rozwiązanie: Tailscale.
- **Porty Dockera omijają ufw** - Docker modyfikuje iptables bezpośrednio. Rozwiązanie: przypięcie portów do adresu serwera w `docker-compose.yml`.

## Plany rozwoju
- Rozbudowany monitoring (Prometheus, Grafana)
- Reverse proxy z HTTPS
- Osobny firewall (OPNsense) i segmentacja sieci
