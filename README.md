# UT2004 dedicated server

Dedikovaný server Unreal Tournament 2004 v Dockeru. Engine je OldUnreal patch 3374
(nativní 64bit Linux), herní obsah se připojuje zvenku, protože je pod licencí a
do image ani do gitu nepatří.

**Doporučený hosting: Hetzner Cloud, ~6 € měsíčně bez DPH, pokud ho jde pro nový účet objednat.**
Railway nejde (nepřijímá příchozí UDP, na kterém UT2004 běží). Hetzner od června 2026
omezuje nové zákazníky, viz [docs/hosting-options.md](docs/hosting-options.md), kde je i srovnání.

## Rychlý start

1. **Zkus objednat server** v Hetzner Console, než začneš cokoli nahrávat: Ubuntu 24.04,
   nejmenší dostupný typ (CX23 má být nejlevnější, může být nedostupný), lokace Nuremberg
   nebo Falkenstein, IPv4 zapnutá, SSH klíč vybraný **při vytvoření**, do „Cloud config"
   obsah [deploy/hetzner-cloud-init.yaml](deploy/hetzner-cloud-init.yaml).
2. **Nahraj repo:**
   ```sh
   rsync -a --exclude game --exclude .git ./ root@<IP>:/opt/ut2004/
   ```
   (z Windows: `scp -r` po souborech nebo `git clone` na serveru).
3. **Herní obsah** dostaneš na server jednou ze dvou cest, podrobně v [docs/game-files.md](docs/game-files.md):
   A) oficiální instalátor OldUnreal přímo na serveru (doporučeno, nic nenahráváš z domova),
   B) nahrání z tvé Steam/GOG kopie přes `scp`.
4. **Spusť:**
   ```sh
   cd /opt/ut2004 && cp .env.example .env && nano .env   # jméno, ADMIN_PASSWORD
   docker compose up -d --build && docker compose logs -f
   ```
5. **Ověř:** `ss -ulpn | grep ucc` ukáže skutečné UDP porty, klient se připojí přes `open <IP>:7777`,
   seznam serverů a CD key: [docs/hosting-options.md](docs/hosting-options.md#seznam-serverů-master-server).

## Co je ověřeno a co ne

Ověřeno lokálně (Debian bookworm, x86_64): patch 3374 se stáhne a odpovídá pinovanému
sha256, server se bez displeje spustí a načte všechny enginové balíčky, entrypoint
správně instaluje patch, přejmenuje Steam `maps` na `Maps`, zapisuje ini (včetně CRLF
a speciálních znaků v heslech) a odmítne neúplný obsah nebo cizí `System`.

**Neověřeno:** běh s opravdovým herním obsahem (ten tu nebyl), instalátor OldUnreal
a nahrání obsahu, zápis do seznamu serverů OpenSpy a to, zda server vyžaduje CD key,
`apt` vrstva Dockerfile (sandbox neviděl deb.debian.org), cloud-init a samotné nasazení
na Hetzner (včetně toho, zda se nový účet vůbec dostane k objednávce).
