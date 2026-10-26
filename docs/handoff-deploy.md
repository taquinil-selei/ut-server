# Handoff: nasazení UT2004 serveru na Hetzner

Pro agenta, který běží **na PC uživatele** (Windows, PowerShell), kde leží SSH klíč a odkud
jde připojit k serveru. Dokument je samostatný: nepotřebuješ žádný další kontext.

## Cíl

Na už vytvořeném Hetzner serveru rozběhnout kontejner s UT2004 serverem. Hotovo je, když
`04-verify.sh` skončí `RESULT: PASS` a uživateli předáš report podle poslední sekce.
Že se hráči dokážou připojit, ověří člověk hrou. Tu část nedělej.

## Co už je hotové a co dostaneš od uživatele

- Server: Hetzner Cloud CPX12, Ubuntu 24.04, vytvořený s cloud-config z
  `deploy/hetzner-cloud-init.yaml` (Docker, ufw s porty 22/tcp, 7777:7778/udp, 7787/udp,
  složka `/opt/ut2004/game` vlastněná uid 1000).
- SSH klíč: soukromý `%USERPROFILE%\.ssh\ut2004`, veřejný je na serveru.
- Repo: `https://github.com/taquinil-selei/ut-server`, větev `claude/gifted-wozniak-ko94n7`.
- **Zeptej se uživatele na:** IP adresu serveru a název serveru do seznamu (bez znaků `#`, `$`, `"`).
  Nic z toho nehádej.

Na serveru jsou čtyři skripty v `deploy/server/`. Každý vypíše řádky `PASS`/`FAIL`/`INFO` a
nakonec `RESULT: …`. Při prvním `FAIL` se zastav.

## Pravidla (platí vždy)

- **Soukromý klíč `ut2004` nikdy nevypisuj, nekopíruj, nenahrávej ani neposílej.** Smíš
  ukázat jen `ut2004.pub`. Po klíči ani po passphrase se uživatele neptej v chatu.
- `ADMIN_PASSWORD` nikam nevypisuj ani do reportu. Řekni jen, že je v `/opt/ut2004/.env`
  a jak ho uživatel přečte (viz report).
- Nedělej nic mimo tyto kroky: žádné `apt upgrade`, `reboot`, `docker system prune`,
  změny `ufw`, další otevřené porty, **žádná odchozí pravidla firewallu** (shodila by
  spojení na master servery), nic v Hetzner Console, nemaž server.
- `rm -rf` jen to, co dělají samotné skripty.
- Příkazy `ssh`/`scp` vždy s `-o BatchMode=yes`. Když přihlášení selže (`Permission denied`,
  klíč s passphrase), **zastav se a napiš to uživateli**. Nezkoušej heslo ani jiný klíč.
- Pokud na tomto PC nemáš shell, ze kterého běží `ssh` s tím klíčem, zastav se a napiš to.
  Ovládání obrazovky (computer use) k psaní klíčů nebo hesel nepoužívej.
- Když něco selže, přilož doslovný výstup a **nic neimprovizuj**, pokud to není popsané
  v sekci „Když něco selže".

## Kroky

Všechny příkazy jsou pro PowerShell. Vzdálené příkazy jsou v apostrofech, aby si je
PowerShell nerozbalil.

### 0. Příprava a kontrola spojení

```powershell
$ip  = "<IP>"                                   # od uživatele
$key = "$env:USERPROFILE\.ssh\ut2004"
$sshOpts = @("-i", $key, "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=accept-new", "-o", "ServerAliveInterval=30")
Get-Command ssh, scp, git | Select-Object Name
Test-Path $key                                  # musí být True
ssh @sshOpts "root@$ip" 'echo spojeni-ok; uname -a'
```
Brána: vypíše `spojeni-ok`. (`accept-new` přijme otisk klíče nového serveru při prvním připojení.)

### 1. Nahraj soubory na server

```powershell
Set-Location $env:USERPROFILE
if (Test-Path .\ut-server) { git -C .\ut-server fetch origin claude/gifted-wozniak-ko94n7; git -C .\ut-server checkout claude/gifted-wozniak-ko94n7; git -C .\ut-server pull } else { git clone -b claude/gifted-wozniak-ko94n7 https://github.com/taquinil-selei/ut-server.git }
Set-Location .\ut-server
scp @sshOpts -r Dockerfile docker-compose.yml .env.example docker deploy "root@${ip}:/opt/ut2004/"
```
`${ip}` ve složených závorkách je nutné, jinak PowerShell čte `$ip:` jako název proměnné.
Když `git clone` selže na přihlášení k GitHubu, zastav se a napiš to uživateli.

### 2. Zkontroluj server

```powershell
ssh @sshOpts "root@$ip" 'bash /opt/ut2004/deploy/server/01-check-host.sh'
```
Brána: `RESULT: PASS`. Skript čeká na doběhnutí cloud-init, může trvat pár minut.

### 3. Stáhni hru (3 GB, minuty až desítky minut)

```powershell
ssh @sshOpts "root@$ip" 'nohup bash /opt/ut2004/deploy/server/02-install-content.sh > /root/02-install.log 2>&1 < /dev/null &'
```
Pak každých ~60 s (nejdéle 45 minut):
```powershell
ssh @sshOpts "root@$ip" 'tail -n 3 /root/02-install.log; grep -E "^RESULT:" /root/02-install.log'
```
Brána: `RESULT: PASS`. V logu je řádek `INFO  bonus-pack maps found: N`. Očekává se 13. Jiné
číslo nezastavuje, jen ho uveď v reportu. Při `RESULT: FAIL` pošli posledních 40 řádků
logu (`tail -n 40 /root/02-install.log`) a zastav se.

### 4. Nastav a spusť server

```powershell
ssh @sshOpts "root@$ip" "nohup bash /opt/ut2004/deploy/server/03-configure-start.sh 'NÁZEV SERVERU' > /root/03-start.log 2>&1 < /dev/null &"
```
Dosaď název od uživatele (vnější uvozovky jsou PowerShell, vnitřní apostrofy jdou na server).
Poll stejně jako výše, ale na `/root/03-start.log` (první build trvá několik minut).
Brána: `RESULT: STARTED`. Při `RESULT: FAIL` pošli `tail -n 60 /root/03-start.log` a zastav se.

### 5. Ověř

```powershell
ssh @sshOpts "root@$ip" 'bash /opt/ut2004/deploy/server/04-verify.sh'
```
Brána: `RESULT: PASS`. Skript trvá ~30–90 s. Při `FAIL` ukaž celý výstup a ještě
`ssh @sshOpts "root@$ip" 'cd /opt/ut2004 && docker compose logs --no-color --tail 80 ut2004'`,
pak se zastav.

## Když něco selže

- **Krok 3, instalátor nejde stáhnout** (síť, ISO nedostupné): zastav se a nahlas to.
  Alternativa je nahrát hru z PC uživatele podle `docs/game-files.md`, cesta B.
  Dělej to jen s cestou ke složce hry, kterou ti uživatel sám řekne.
- **Krok 3, `the installer script changed upstream`:** upstream skript se změnil. Nespouštěj
  ho, nahlas to.
- **Krok 4, build `docker compose` selže:** přilož chybu. Dockerfile ještě nikdo nesestavil
  na skutečném serveru (krok `apt` je netestovaný).
- **Krok 5, FAIL kvůli chybějící mapě nebo balíčku:** nahlas, ukaž `ls /opt/ut2004/game`.
- **CD key:** nic nehledej, nevytahuj z registru a nevytvářej soubor `cdkey`. Jen
  přilož řádky z `04-verify.sh` o master serverech a klíči. Rozhodne uživatel.

## Report uživateli (česky, stručně)

1. U každého kroku 0–5: PASS/FAIL a jedna věta.
2. Z kroku 5: výpis UDP listenerů, zda existuje TCP spojení na port 28902, řádky o master
   serverech a klíči z logu.
3. Číslo „bonus-pack maps found" z kroku 3.
4. Co jsi nemohl ověřit nebo cokoli neočekávaného, doslovně.
5. Co zbývá na člověku: připojit se hrou na `open <IP>:7777`, a heslo adminu si přečte
   sám: `ssh -i $env:USERPROFILE\.ssh\ut2004 root@<IP> "grep ADMIN_PASSWORD /opt/ut2004/.env"`.
