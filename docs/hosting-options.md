# Kde hostovat server pro UT2004

Stav k 2026-10-26. Ceny a podmínky jsou z webových zdrojů uvedených dole, většinou
z blogů a srovnávačů. Stránky Hetzneru, Fly.io a dalších se odsud nepodařilo otevřít,
takže oficiální ceníky a status stránky jsem nečetl. Před objednávkou je ověř.

## Závěr

**Hetzner Cloud, malá x86 instance, Docker Compose podle tohoto repa. Zhruba 6 € měsíčně
bez DPH, pokud je ta nejlevnější instance (CX23) k objednání.**
Hetzner od 2026-06-26 omezuje zakládání nových cloud serverů novým zákazníkům a řada
CX/CAX je podle sledovačů nedostupná (viz níže). Jestli se to týká právě tvého účtu,
zjistíš jen pokusem o objednávku. Pokud ano, jsou k dispozici dražší typy nebo jiný
poskytovatel (ten jsem nezkoumal).
Railway nepřichází v úvahu. Fly.io jde, ale je složitější a levnější nebude.

## Co UT2004 server potřebuje

| Požadavek | Detail | Zdroj / ověření |
|---|---|---|
| Příchozí UDP | hra 7777, dotazy 7778 (hra+1) a 7787 (hra+10, GameSpy dotaz) | návody a README image PhasecoreX. Na běžícím serveru poslouchá 7777, 7778, 7787 a 10777 (LAN, ufw ho neotevírá); přístup zvenku neověřen |
| Odchozí TCP 28902 | spojení na master servery | `Default.ini` patche, na běžícím serveru navázáno spojení se všemi 6 master servery (ověřeno) |
| Volitelně TCP 8075 | WebAdmin, ve výchozím stavu vypnutý, doporučuji SSH tunel | ověřeno v ini |
| CPU | engine je prakticky jednovláknový, stačí 1–2 sdílená jádra | odhad, neměřeno |
| RAM | 1–2 GB je s rezervou | odhad, neměřeno |
| Disk | obsah hry 5,7 GB, na CX23 i CPX12 je 40 GB | 5,7 GB změřeno na serveru (ověřeno) |
| Binárky | patch 3374 má nativní amd64, ARM64 i ppc64le, nepotřebuje 32bit knihovny | ověřeno (obsah tarballu) |

Přesný seznam portů zjistíš po prvním startu příkazem `ss -ulpn | grep ucc`. Steam diskuse
a jeden skript uvádějí i UDP 7788 (hlasový chat?), neověřeno. Jedno pravidlo UDP 7777–7788
je bezpečná nadmnožina.

## Srovnání poskytovatelů

| Varianta | UDP | Cena | Stabilita | Složitost | Verdikt |
|---|---|---|---|---|---|
| **Railway** | ne (jen odchozí) | n/a | n/a | n/a | **nepoužitelné** |
| **Hetzner Cloud** CX23 | ano, plná síť | 5,49 € + 0,50 € IPv4, 20 TB provozu | vysoká | nízká | **doporučeno, pokud jde objednat** |
| **Hetzner CPX12** (1 vCPU, 2 GB, 40 GB) | ano | 11,99 € měsíčně podle konzole | vysoká | nízká | **doporučeno, když CX23 chybí** |
| Hetzner CPX02 (1 vCPU, 1 GB, 20 GB) | ano | 6,49 € měsíčně podle konzole | vysoká | nízká | jde, ale 20 GB disku a 1 GB RAM je těsné |
| **Fly.io** | ano, s dedikovanou IPv4 | ~2 $ za IPv4 + stroj, přesně neověřeno | dobrá | vyšší | druhá volba |
| **Oracle Always Free** | ano | zdarma | nízká | střední | jen na pokusy |
| Správce herních serverů | ano | neověřeno | podle firmy | nejnižší | záloha, pokud nechceš spravovat nic |
| OVH, Vultr, DigitalOcean, Lightsail, Contabo, Netcup | ano | **neověřeno** | | | nezkoumal jsem |

### Railway: ne

Railway oficiálně nepřijímá příchozí UDP. Podle odpovědi jejich staff podporuje jen
odchozí UDP a požadavek na příchozí je dál „Under Review". Veřejně lze publikovat jen
TCP proxy. Obcházení přes tunel (playit.gg) existuje, ale přidává závislost na třetí
straně a latenci a se „stabilním" serverem se to nepotkává.
Zdroje: [TCP proxy](https://docs.railway.com/networking/tcp-proxy),
[UDP inbound](https://station.railway.com/feedback/udp-inboud-connections-9f036ffc),
[Pufferpanel šablona](https://railway.com/deploy/pufferpanel).

### Hetzner Cloud

**Omezení pro nové zákazníky.** Podle stránky stavu Hetzneru, citované v GitHub issue
z ~2026-10-21, od 2026-06-26 omezují zakládání nových cloud serverů novým zákazníkům
(a náhodně vybraným stávajícím). Řada CX/CAX je podle několika nezávislých sledovačů
„not available" přes říjen 2026, zatímco CPX šel objednat. Že se to týká tvého účtu,
nevím, a veřejný katalog o tom nic neříká. Postup:

1. Založ projekt v **Hetzner Console** (`console.hetzner.com`, dřív Cloud Console) a
   zkus objednat. Stránku obnov, dostupnost typů se načítá jednou za zobrazení.
2. Při chybě zkus **jiný typ a lokaci** (Helsinki), omezení je podle Hetzneru po lokacích
   a dočasné („zkuste to další den"). Podpora podle Hetzneru jednotlivé žádosti
   neprioritizuje.
3. Objednávej **nejmenší dostupný typ**. Hetzner doporučuje novým zákazníkům malou první
   objednávku. Může chtít doklad totožnosti nebo předplatbu vlastní kartou, bez VPN a
   s kompletními údaji, první fakturu zaplať hned.
4. Pokud zůstane jen CPX (v konzoli 2026-10-26 byly vidět CPX02 6,49 €, CPX12 11,99 € a
   CPX22 19,99 €, CX nebyly v seznamu vůbec): vyber **CPX12**. Má 2 GB RAM a 40 GB disku, což
   pohodlně pojme hru (~6 GB), Docker i dočasné soubory instalátoru. CPX02 je o 5,50 € levnější,
   ale 20 GB disku nestačí na cestu A z `docs/game-files.md` a 1 GB RAM s Dockerem jsem nezměřil.
   Ceny v tabulce konzole nejspíš zahrnují IPv4 (sedí 11,49 + 0,50), potvrď v souhrnu před objednávkou.
   Starší CPX11, CPX21 a vyšší jsou dražší za méně, nevybírej je.

**Parametry a cena (CX23).** 2 sdílené vCPU, 4 GB RAM, 40 GB, 20 TB provozu v EU.
5,49 € + 0,50 € za IPv4 = 5,99 € měsíčně bez DPH (~7,25 € s českou DPH, firma s platným
DIČ platí bez DPH přes reverse charge). Ceny po zdražení k 2026-06-15 potvrdily nezávisle
tři zdroje. IPv4 nech zapnutou, UT2004 je hra z doby IPv4. Hetzner účtuje server, dokud ho
nesmažeš (vypnutý se platí), a pak zkontroluj i primární IP, volumes, snapshoty a zálohy.

**Lokace.** Nuremberg (`nbg1`), Falkenstein (`fsn1`) a Helsinki (`hel1`) jsou v jedné
zóně a za stejnou cenu. Z Česka je blíž Německo.

**Postup v konzoli** (názvy tlačítek jsou z dokumentace přes vyhledávač, ne z živé konzole):
Security > SSH Keys > přidej veřejný klíč. Servers > Add server > lokace, image Ubuntu 24.04,
typ, IPv4/IPv6, vyber SSH klíč, do „Cloud config" vlož `deploy/hetzner-cloud-init.yaml`, název.
**Před potvrzením zkontroluj, že pole „Cloud config" není prázdné:** při prvním nasazení server
cloud-config nedostal a Docker na něm nebyl (záloha: `docs/handoff-deploy.md`, krok 0b).
SSH klíč se dá přidat jen při vytvoření serveru, dodatečně přes rescue systém. Alternativa
je image `docker-ce` (Ubuntu 24.04 s Dockerem), ale cloud-init v repu instaluje Docker sám.
První připojení: `ssh root@<IP>`, potvrď otisk klíče.

**Firewall.** Stačí `ufw` z cloud-init, protože compose používá `network_mode: host` a
publikované porty Dockeru tak `ufw` neobchází. Navíc můžeš v konzoli vytvořit Cloud
Firewall: příchozí TCP 22, UDP 7777–7778 a UDP 7787. **Nepřidávej žádná odchozí pravidla.**
Jakmile existuje jedno, odchozí provoz se změní na allowlist a odchozí TCP 28902 na master
servery přestane fungovat.

Zdroje: [Hetzner ceny 2026](https://agentdeals.dev/hetzner-pricing-2026),
[zdražení v červnu](https://privatedevops.com/news/hetzner-june-2026-cloud-price-increase-what-to-do),
[srovnání cloudů 2026-08](https://kimmo.suominen.com/stuff/cpc-2026-08.txt),
[nedostupnost levných typů](https://www.vincentschmalbach.com/hetzner-cheap-cloud-unavailable-price-increases/),
[fraud-prevention FAQ](https://docs.hetzner.com/general/security-and-identify/fraud-prevention-faq/).

### Fly.io: jde, ale nevýhodné

- UDP vyžaduje **dedikovanou IPv4** (~2 $ měsíčně) a aplikace musí poslouchat na
  speciální adrese `fly-global-services` a odpovídat z ní. UT2004 má parametr
  `-multihome=<IP>`, ale zda s adresou `fly-global-services` funguje, jsem neověřil.
- Herní obsah musí na persistentní volume a nahrát se tam musí ručně.
- Cenově vyjde podobně nebo hůř než Hetzner a přidá složitost, takže bych ho volil, jen
  pokud už na Fly něco provozuješ.
Zdroje: [UDP a TCP na Fly](https://fly.io/docs/networking/udp-and-tcp),
[ceny](https://costbench.com/software/developer-tools/flyio).

### Oracle Always Free: jen na pokusy

- Zdarma, ale ARM instance (A1) bývají „out of capacity" a získání může trvat dny.
- Jeden blog tvrdí, že se limit od 15. 6. 2026 snížil na polovinu (2 OCPU, 12 GB).
  Neověřeno.
- Podle jednoho korejského zdroje Oracle může reclaimnout instanci s využitím pod 20 % po
  dobu sedmi dní, což u málo vytíženého herního serveru hrozí. Neověřeno u Oracle.
Zdroje: [Oracle komunita](https://community.oracle.com/customerconnect/discussions/tagged/arm/p1),
[BrainDetox](https://braindetox.kr/en/posts/oracle_always_free_backend_2026.html).

### Správce herních serverů

Firmy jako [Citadel Servers](https://citadelservers.com/en-us/node/417) nebo
[GameHostBros](https://www.gamehostbros.com/unreal-tournament-2004-server-hosting)
nabízejí hotový UT2004. Nic nespravuješ, ale ani neovlivníš a ceny jsem neověřoval.
Má smysl, pokud nechceš na server vůbec sahat.

## Seznam serverů (master server)

Epic master servery vypnul. `Default.ini` v patchi 3374 má předvyplněných šest komunitních
masterů (333networks, gonespy, errorist, frag-net, noccer.de a `utmaster.openspy.net`),
všechny na portu 28902, a `ServerActors=IpDrv.MasterServerLauncher`. Ověřeno přímo v tarballu.
Inzerce se tedy zapne sama, jakmile server běží.
Zdroje: [OldUnreal README](https://github.com/OldUnreal/UT2004Patches),
[Steam diskuse k OpenSpy](https://steamcommunity.com/app/13230/discussions/0/3732952112224013002).

**CD key.** Co je zjištěno:
- Veřejný zdrojový kód master serveru OpenSpy ([openspy-core](https://github.com/openspy/openspy-core),
  `code/utmaster/server/commands/handle_challenge.cpp`) klíč jen zaloguje a schválí každého
  známého klienta. Produkční nasazení jsem neviděl.
- Linuxová binárka 3374 čte klíč ze souboru `cdkey` (OldUnreal issue #35). Adresář (`System/`
  vs. `~/.ut2004/System/`) a formát obsahu nejsou nikde potvrzené: image PhasecoreX (3369)
  zapisuje `"CDKey"="<hodnota>"`, jiný návod holý klíč.
- Zda 3374 server bez souboru `cdkey` nastartuje a uplinkuje, nikdo nezdokumentoval. **První
  nasazení:** server bez `cdkey` nastartoval a navázal TCP spojení na port 28902 se všemi
  šesti master servery, v logu o klíči nic není. Že se server objevil v seznamu, nikdo neověřil.
  U 333networks, gonespy, errorist, frag-net a noccer.de žádný zdroj o kontrole klíčů nic neříká.
- Z patche: 3374 si automaticky detekuje GOG klíč a nahradí ho jedinečným.

Postup: **nastartuj bez klíče** a přečti log (`docker compose logs | grep -iE 'master|uplink|cd ?key'`).
Pokud server neuplinkuje nebo si stěžuje na klíč, vytvoř `game/System/cdkey` z vlastní kopie
(Steam: hodnota `CDKey` v registru `HKLM\SOFTWARE\Wow6432Node\Unreal Technology\Installed Apps\UT2004`,
objeví se podle komunity až po spuštění hry; GOG: zdroj jsem nenašel) a zkus oba formáty. Klíče odjinud nepoužívej.
Při potížích zeptej se na OldUnreal Discordu nebo v issues UT2004Patches.

**Ověření seznamu.** Listing na OpenSpy zmizí, když server ztratí TCP spojení na master
(restart kontejneru ho smaže, než se uplink obnoví), 333networks uvádí až 15 minut, než se
nový server objeví. Filtry v herním prohlížeči mohou správně uvedený server skrýt (OldUnreal
issues #378, #171, #91), takže se nespoléhej na GUI. Použij `pip install pyut2serverlist`
(`PrincipalServer('utmaster.openspy.net', 28902, Game.UT2004, '<libovolný řetězec>').get_servers()`,
`Server('<IP>', 7778).get_info()` ověří dotazovací port), používání jsem nespouštěl.

## Rizika

- **Patch 3374 je pořád „preview"** (Preview 23, poslední před release candidate).
  Podle hostingu GameHostBros se hráči na čistém 3369 k serveru 3374 připojí, ale
  oficiálně jsem to nepotvrdil, a preview verze se může rozbít. Odkaz na patch je v `Dockerfile` připnutý
  i s kontrolním součtem, takže se nezmění pod rukama.
- **Servery s AntiTCC** vyžadovaly aktualizaci kompatibilní s 3374 (poznámka k Preview 9).
- **NAT a Docker bridge:** OldUnreal issue #90 (otevřené, reprodukované na 3374p17 v březnu 2026):
  při `ServerBehindNAT` a síti typu bridge se server nemusí zaregistrovat nebo se zapíše
  s nesprávným portem. Compose proto používá `network_mode: host` a `ServerBehindNAT=False`
  z výchozího ini. Že to problém opravdu obchází, jsem neověřil.
- **UDP amplifikace přes dotazovací port** (obecná znalost, ne ze zdroje): veřejné herní
  servery bývají zneužívány k odrazovým útokům. Neotvírej víc portů, než potřebuješ, a neprovozuj WebAdmin veřejně.
- **Zálohy**: jediný stav, který stojí za zálohu, je `game/System/*.ini` (nastavení
  serveru). Obsah hry máš u sebe.
