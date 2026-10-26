# UT2004 dedicated server

Dedikovaný server Unreal Tournament 2004 v Dockeru. Engine je OldUnreal patch 3374
(nativní 64bit Linux), herní obsah se připojuje zvenku, protože je pod licencí a
do image ani do gitu nepatří.

**Doporučený hosting: Hetzner Cloud, ~6 € měsíčně.** Railway nejde (nepřijímá
příchozí UDP, na kterém UT2004 běží). Důvody a srovnání: [docs/hosting-options.md](docs/hosting-options.md).

## Rychlý start

1. Na Hetzneru vytvoř server (Ubuntu 24.04, lokace Nuremberg nebo Falkenstein),
   do „Cloud config" vlož [deploy/hetzner-cloud-init.yaml](deploy/hetzner-cloud-init.yaml).
2. Z lokálního stroje nahraj repo a herní obsah (co přesně kopírovat: [docs/game-files.md](docs/game-files.md)):
   ```sh
   rsync -a --exclude game --exclude .git ./ root@<IP>:/opt/ut2004/
   rsync -avP "<cesta k UT2004>/"{Animations,KarmaData,Maps,Music,Prefabs,Sounds,Speech,StaticMeshes,Textures} root@<IP>:/opt/ut2004/game/
   ssh root@<IP> chown -R 1000:1000 /opt/ut2004/game
   ```
3. Na serveru:
   ```sh
   cd /opt/ut2004 && cp .env.example .env && nano .env   # jméno, ADMIN_PASSWORD
   docker compose up -d --build && docker compose logs -f
   ```
4. Ověř: `ss -ulpn | grep ucc` ukáže skutečné UDP porty, klient se připojí přes `open <IP>:7777`.

## Co je ověřeno a co ne

Ověřeno lokálně (Debian bookworm, x86_64): patch 3374 se stáhne a odpovídá pinovanému
sha256, server se bez displeje spustí a načte všechny enginové balíčky, entrypoint
správně instaluje patch a zapisuje ini (včetně CRLF a speciálních znaků v heslech).

**Neověřeno:** běh s opravdovým herním obsahem (ten tu nebyl), zápis do seznamu serverů
OpenSpy a to, zda server vyžaduje CD key, `apt` vrstva Dockerfile (sandbox neviděl
deb.debian.org), cloud-init a samotné nasazení na Hetzner.
