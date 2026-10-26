# Herní obsah na server

Image obsahuje jen engine (OldUnreal patch). Mapy, textury a zvuky se dodávají zvlášť
do `/opt/ut2004/game` na serveru. Jsou dvě cesty, obě jsou na serveru **netestované**
(sandbox, ve kterém repo vzniklo, neviděl `files.oldunreal.net` ani Steam). Entrypoint
je ale otestovaný na tvaru adresářů, který obě cesty vyrobí.

Server vyžaduje tyto adresáře: `Animations KarmaData Maps Music Sounds Speech StaticMeshes Textures`.
Nekopíruj `System` (OldUnreal README: hra se pak nespustí). `Help` a `Web` už v patchi jsou
(ověřeno v tarballu), `Prefabs` na médiu není a entrypoint ho vytvoří prázdný.

## Cesta A: oficiální instalátor OldUnreal přímo na serveru (doporučeno)

Nic nenahráváš z domova. Instalátor stáhne ISO Editor's Choice + Mega Bonus Pack
(2 995 322 880 B, sha256 `43e9182a…`, kontrola je v něm) z `files.oldunreal.net`,
případně záložně z archive.org. Platí
[Epic Games ToS](https://legal.epicgames.com/en-US/epicgames/tos) (odkaz z README
instalátoru). Steam ani GOG k tomu nepotřebuješ. Vznikne kompletní strom se správným `Maps`.

Na serveru jako root (Ubuntu 24.04):

```sh
apt-get update && apt-get install -y curl jq p7zip-full unshield
cd /root
curl -fsSLO https://raw.githubusercontent.com/OldUnreal/FullGameInstallers/master/Linux/install-ut2004.sh
echo "ec5f2cd6d9f76ac108487ec8cc751ddd9120771b98402521420ff2df8cb19dad  install-ut2004.sh" | sha256sum -c -
```

Kontrolní součet je verze skriptu, kterou jsem četl (zdroje a mazání v něm jsem
prošel, všech ~3 000 řádků ne). Pokud nesedí, skript se od té doby změnil. Přečti si ho
a teprve pak pokračuj.

```sh
bash install-ut2004.sh -d /opt/ut2004/install --ui-mode none --application-entry skip --desktop-shortcut skip
ls /opt/ut2004/install        # očekávej Animations, KarmaData, Maps, Music, Sounds, ...
cd /opt/ut2004/install && mv Animations KarmaData Maps Music Sounds Speech StaticMeshes Textures /opt/ut2004/game/
chown -R 1000:1000 /opt/ut2004/game
rm -rf /opt/ut2004/install    # zbytek (System, ...) už nepotřebuješ
```

Instalátor si sám stáhne i nejnovější patch z GitHubu. Nám to nevadí, kopírujeme jen
obsah a v kontejneru se použije patch připnutý v `Dockerfile`.

Místo: ISO (3 GB) a rozbalený strom (6 GB) jsou na disku najednou, proto `mv` místo kopie.
Na 20 GB disku (CPX02) to nestačí, potřebuješ aspoň 40 GB (CPX12, CX23).

Riziko: pokud je `files.oldunreal.net` nedostupný a selže i záloha na archive.org,
použij cestu B.

## Cesta B: nahrání z tvého PC (Steam nebo GOG)

Použij **jednu** kopii, tu, která je nainstalovaná. Steam i GOG jsou Editor's Choice Edition,
ale byte-po-bytu shodu jsem neověřil.

1. **Najdi složku hry.** Nezadávej cestu z hlavy, knihovna Steamu může být na jiném disku.
   Steam: pravý klik na hru, Spravovat, Procházet místní soubory (z paměti, nepotvrzeno).
   GOG Galaxy: hra, Spravovat instalaci, Zobrazit složku (z paměti, nepotvrzeno). Správná
   složka obsahuje `System\UT2004.exe`. Ve Steamu i GOG jsou vedle sebe i hry
   Unreal Tournament 1999 a UT2003, takže si dej pozor, ať nekopíruješ špatnou.
2. **Název adresáře s mapami.** Steam má `maps` malým písmem. Entrypoint ho na serveru
   přejmenuje na `Maps`, takže nic nepřejmenovávej.
3. **SSH klíč** (jednou, PowerShell). Veřejný klíč vlož do Hetzner Console (Security, SSH keys)
   **před** vytvořením serveru, k už vytvořenému serveru ho přes Console přidat nejde:
   ```powershell
   Get-Command ssh, scp          # musí existovat, jinak: Settings > Optional features > OpenSSH Client
   ssh-keygen -t ed25519 -C "ut2004"
   Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
   ```
4. **Nahrání** (PowerShell, ze složky hry; použij názvy adresářů přesně tak, jak je vypíše `Get-ChildItem -Directory`):
   ```powershell
   Set-Location "C:\cesta\k\Unreal Tournament 2004"
   scp -o ServerAliveInterval=30 -r Animations KarmaData maps Music Sounds Speech StaticMeshes Textures root@<IP>:/opt/ut2004/game/
   ```
   Cesta je v uvozovkách jen u `Set-Location`, `scp` dostane jen relativní názvy, takže mezery
   ani závorky v cestě nevadí. `scp` se po přerušení nedá navázat, začíná se znovu (po adresářích).
   Odhad času: 5–6 GB při 20 Mbit/s asi 40 minut, při 100 Mbit/s asi 8 minut.
5. **Na serveru:** `chown -R 1000:1000 /opt/ut2004/game`.

**rsync přes WSL2** je pohodlnější (navazuje po přerušení), ale SSH klíč vytvořený v PowerShellu
WSL nepoužije, protože čte `~/.ssh` uvnitř Linuxu. Vytvoř si druhý klíč přímo ve WSL
(`ssh-keygen -t ed25519`) a jeho veřejnou část přidej do Hetzneru. Pak:
```sh
cd "/mnt/c/cesta/k/Unreal Tournament 2004"
rsync -rtP --chmod=D755,F644 -e "ssh -o ServerAliveInterval=30" Animations KarmaData maps Music Sounds Speech StaticMeshes Textures root@<IP>:/opt/ut2004/game/
```
Komprese nepomůže (hudba je `.ogg`). Git Bash nepoužívej, nemá rsync a přepisuje cesty začínající `/`.

Nestahuj hru na server přes SteamCMD. Vyžaduje to tvé Steam heslo a Steam Guard kód
na cizím stroji a zanechá tam přihlašovací token.

## Po nahrání: ověř, že máš kompletní obsah

Mapy z bonus packů musí být ve složce `Maps`. Zda je Steam/GOG kopie obsahuje, nikdo
neověřil (zdroje si odporují):

```sh
ls /opt/ut2004/game/Maps | grep -E 'ONS-(Adara|IslandHop|Tricky|Urban)|BP2'
```

Očekávej 4 mapy `ONS-*` a devět map `*-BP2-*`. Pokud chybí, použij cestu A.
Bonus vehicles mutator může chybět i u správných dat (OldUnreal issue #480, otevřené),
protože soubory `OnslaughtBP.ucl` a `BP2.ucl` jsou jen v původním `System`.
