# Stav nasazení: UT2004 server na Hetzneru (2026-10-26)

Zápis z běhu `docs/handoff-deploy.md`. Agent běžel na PC uživatele (Windows, PowerShell, SSH klíč
`ut2004`). Cloudová session k serveru přístup nemá, klíč je jen na PC uživatele. Všechno, co
vyžaduje SSH na server, musí spustit uživatel nebo agent na jeho PC.

## Výsledek

Server běží a `04-verify.sh` skončil `RESULT: PASS`. Připojení ze hry zatím nikdo neověřil.

- Server: Hetzner CPX12, Ubuntu 24.04.4, IP `2.28.199.6`, hostname `game-server`
- Název serveru v seznamu: `game-server`
- Nasazený commit: `fbcd60cf2662e87dec2fd85c2a1eb0de1cc6ee27`
- `.env` vytvořen nově s vygenerovaným `ADMIN_PASSWORD` (nastaveno, hodnota není v repu ani tady)
- Bonus-pack mapy: 13 z 13, velikost hry 5,7 GB
- Docker 29.1.3, Docker Compose 2.40.3 (balíčky z Ubuntu)
- UDP listenery: 7777, 7778, 7787, 10777
- TCP spojení na 28902: 6 master serverů (333networks, gonespy, errorist, frag-net, noccer, openspy)
- V logu je `master0.gamespy.com HOST_NOT_FOUND`. Je to neškodné, GameSpy už neexistuje.
- O CD key v logu nic není.

| Krok | Stav | Poznámka |
|---|---|---|
| 0 | PASS po ručním zásahu | viz Odchylka 1 |
| 1 | PASS | |
| 2 | PASS | `01-check-host.sh` |
| 3 | PASS napodruhé | viz Odchylka 2 |
| 4 | PASS | `RESULT: STARTED` |
| 5 | PASS | `04-verify.sh` |

## Odchylky od handoffu

### 1. Server nedostal cloud-config

`/var/lib/cloud/instance/user-data.txt` měl 0 bajtů a cloud-init doběhl za 15 s. Na serveru
nebyl Docker ani `/opt/ut2004`. Uživatel server nechtěl mazat a zakládat znovu, a proto schválil
ruční postup. Agent ručně provedl totéž co `deploy/hetzner-cloud-init.yaml`:

```sh
apt-get update && apt-get install -y docker.io docker-compose-v2 ufw rsync curl jq p7zip-full unshield
systemctl enable --now docker
ufw default deny incoming; ufw default allow outgoing
ufw allow 22/tcp; ufw allow 7777:7778/udp; ufw allow 7787/udp; ufw --force enable
mkdir -p /opt/ut2004/game; chown -R 1000:1000 /opt/ut2004/game
```

Log apt je na serveru v `/root/prep.log`.

### 2. Instalátoru OldUnreal chyběl `lbzip2`

První běh `02-install-content.sh` stáhl a rozbalil hru, ale spadl v kroku „Extract Latest Patch“:

```
tar (child): lbzip2: Cannot exec: No such file or directory
Error: Failed to extract Latest Patch. Installation aborted.
RESULT: FAIL (exit 1)
```

Agent doinstaloval `lbzip2` a `bzip2` a skript spustil znovu. Druhý běh skončil `RESULT: PASS`.

## Co zbývá dořešit (v repu)

1. **Přidat `lbzip2` do `packages` v `deploy/hetzner-cloud-init.yaml`.** Bez něj krok 3 na čistém
   serveru vždy selže. Zvážit i kontrolu v `01-check-host.sh` (`command -v lbzip2`), aby to
   chytil už krok 2.
2. **Do `docs/handoff-deploy.md` doplnit sekci pro případ prázdného cloud-configu.** Brána kroku 0
   vypíše `status: done`, ale bez `dir-ok`, a `user-data.txt` má 0 bajtů. Postup výše (bez mazání
   serveru) zapsat jako povolenou záložní cestu.
3. Případně do `docs/hosting-options.md` / `docs/game-files.md` poznamenat, že build Dockerfile
   na skutečném serveru prošel (dosud byl netestovaný) a že instalátor OldUnreal potřebuje `lbzip2`.
4. Upstream instalátor měl stále očekávané SHA256 (`ec5f2cd6…`), nic tam není potřeba měnit.

## Co zbývá na člověku

- Připojit se hrou: v konzoli `open 2.28.199.6:7777`.
- Heslo admina si přečíst na PC:
  `ssh -i $env:USERPROFILE\.ssh\ut2004 root@2.28.199.6 "grep ADMIN_PASSWORD /opt/ut2004/.env"`
