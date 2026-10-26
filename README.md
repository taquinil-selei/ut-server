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
2. **Nahraj soubory na server** (z PC, na Windows není rsync, použij `scp` s klíčem):
   ```powershell
   git clone -b claude/gifted-wozniak-ko94n7 https://github.com/taquinil-selei/ut-server.git
   cd ut-server
   scp -i $env:USERPROFILE\.ssh\ut2004 -r Dockerfile docker-compose.yml .env.example .dockerignore docker deploy root@<IP>:/opt/ut2004/
   ```
3. **Herní obsah** dostaneš na server jednou ze dvou cest, podrobně v [docs/game-files.md](docs/game-files.md):
   A) oficiální instalátor OldUnreal přímo na serveru (doporučeno, nic nenahráváš z domova),
   B) nahrání z tvé Steam/GOG kopie přes `scp`.
4. **Spusť:**
   ```sh
   cd /opt/ut2004 && cp .env.example .env && nano .env   # jméno, ADMIN_PASSWORD
   docker compose up -d --build && docker compose logs -f
   ```
   Kroky 2 až 5 lze místo ručního psaní předat agentovi na tvém PC:
   [docs/handoff-deploy.md](docs/handoff-deploy.md) a skripty v `deploy/server/`.
5. **Ověř:** `ss -ulpn | grep ucc` ukáže skutečné UDP porty, klient se připojí přes `open <IP>:7777`,
   seznam serverů a CD key: [docs/hosting-options.md](docs/hosting-options.md#seznam-serverů-master-server).

## Co je ověřeno a co ne

Ověřeno na skutečném serveru (Hetzner CPX12, Ubuntu 24.04, podle `docs/deploy-status.md`): sestavení
image, instalátor OldUnreal (po doinstalování `lbzip2`), 13 z 13 bonus map, server běží, `04-verify.sh`
skončil `RESULT: PASS`, UDP 7777, 7778, 7787 poslouchají a TCP spojení na 6 master serverů je navázáno.
Připojení ze hry přes IP funguje (potvrdil uživatel 2026-10-26 ze svého Steam klienta).

Ověřeno lokálně (Debian bookworm, x86_64): patch 3374 se stáhne a odpovídá pinovanému
sha256, server se bez displeje spustí a načte všechny enginové balíčky, entrypoint
správně instaluje patch, přejmenuje Steam `maps` na `Maps`, zapisuje ini (včetně CRLF
a speciálních znaků v heslech) a odmítne neúplný obsah nebo cizí `System`.

**Neověřeno:** zápis do seznamu serverů (OpenSpy a další) a to, zda
seznam vyžaduje CD key (server bez klíče nastartoval a uplinkuje), nahrání obsahu z vlastní
Steam/GOG kopie (cesta B) a to, že cloud-init skutečně doběhne (při prvním nasazení
server cloud-config nedostal, viz krok 0b v `docs/handoff-deploy.md`).
