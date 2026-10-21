# Domowy serwer (Docker)

Domowy serwer na starym komputerze Dell OptiPlex SFF (i5-4590, 8 GB RAM, SSD + HDD, Linux Mint).

## Usługi
- Pi-hole: blokowanie reklam i trackerów w całej sieci (DNS)
- Samba: dysk sieciowy
- Syncthing: synchronizacja plików między urządzeniami
- Jellyfin: serwer multimediów z akceleracją sprzętową (Quick Sync)

## Uruchomienie
1. Zainstaluj Docker i Docker Compose.
2. Skopiuj `.env.example` jako `.env` i uzupełnij hasła.
3. Zwolnij port 53 (wyłącz DNSStubListener w systemd-resolved).
4. Uruchom: `docker compose up -d`

## Adresy paneli
- Pi-hole: `http://IP:8081/admin`
- Syncthing: `http://IP:8384`
- Jellyfin: `http://IP:8096`
