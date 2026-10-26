# Kde hostovat server pro UT2004

Stav k 2026-10-26. Ceny a podmínky jsou z webových zdrojů uvedených dole, většinou
z blogů a srovnávačů, ne z oficiálních ceníků (několik stránek, např. fly.io, se mi
odsud nepodařilo otevřít). Před objednávkou je ověř.

## Závěr

**Hetzner Cloud, malá x86 instance (CX23), Docker Compose podle tohoto repa. Zhruba 6 € měsíčně.**
Je to nejjednodušší cesta, která dává stabilní UDP, předvídatelnou cenu a plnou
kontrolu. Railway nepřichází v úvahu. Fly.io jde, ale je složitější a levnější nebude.

## Co UT2004 server potřebuje

| Požadavek | Detail | Zdroj / ověření |
|---|---|---|
| Příchozí UDP | hra 7777, 7778 a dotazy 7787 (viz níže) | z návodů, **v běhu neověřeno** |
| Odchozí TCP 28902 | spojení na master servery | z `Default.ini` patche (ověřeno) |
| Volitelně TCP 8075 | WebAdmin, ve výchozím stavu vypnutý, doporučuji SSH tunel | ověřeno v ini |
| CPU | engine je prakticky jednovláknový, stačí 1–2 sdílená jádra | odhad, neměřeno |
| RAM | 1–2 GB je s rezervou | odhad, neměřeno |
| Disk | obsah hry je několik GB | odhad |
| Binárky | patch 3374 má nativní amd64, ARM64 i ppc64le, nepotřebuje 32bit knihovny | ověřeno (obsah tarballu) |

Porty vycházejí z návodů a ze skriptu třetí strany. Přesný seznam zjistíš po prvním
startu příkazem `ss -ulpn | grep ucc` a případně upravíš firewall.

## Srovnání poskytovatelů

| Varianta | UDP | Cena | Stabilita | Složitost | Verdikt |
|---|---|---|---|---|---|
| **Railway** | ne (jen odchozí) | n/a | n/a | n/a | **nepoužitelné** |
| **Hetzner Cloud** CX23 | ano, plná síť | ~5,49 € + 0,50 € IPv4, 20 TB provozu | vysoká | nízká | **doporučeno** |
| **Fly.io** | ano, s dedikovanou IPv4 | ~2 $ za IPv4 + stroj, přesně neověřeno | dobrá | vyšší | druhá volba |
| **Oracle Always Free** | ano | zdarma | nízká | střední | jen na pokusy |
| Správce herních serverů | ano | neověřeno | podle firmy | nejnižší | záloha, pokud nechceš spravovat nic |
| OVH, Vultr, DigitalOcean, Lightsail, Contabo | ano | **neověřeno** | | | nezkoumal jsem |

### Railway: ne

Railway oficiálně nepřijímá příchozí UDP. Podle odpovědi jejich staff podporuje jen
odchozí UDP a požadavek na příchozí je dál „Under Review". Veřejně lze publikovat jen
TCP proxy. Obcházení přes tunel (playit.gg) existuje, ale přidává závislost na třetí
straně a latenci a se „stabilním" serverem se to nepotkává.
Zdroje: [TCP proxy](https://docs.railway.com/networking/tcp-proxy),
[UDP inbound](https://station.railway.com/feedback/udp-inboud-connections-9f036ffc),
[Pufferpanel šablona](https://railway.com/deploy/pufferpanel).

### Hetzner Cloud: doporučeno

- Obyčejný virtuální stroj s vlastní veřejnou IP, takže UDP nevyžaduje žádné triky (z obecné znalosti, ne z dnešního zdroje).
- Po zdražení v dubnu a červnu 2026 uvádějí zdroje CX23 (x86, sdílené CPU) na 5,49 € a
  CAX11 (ARM) na 5,99 €, IPv4 zvlášť 0,50 €, provoz 20 TB. Stávající servery se
  zdražením nemění, dokud je nepřeškáluješ.
- Fakturace je podle mé paměti po hodinách, takže zkouška stojí haléře (ověř při objednávce).
- Zvolil jsem x86 (CX23), protože s ním jsem binárky testoval. ARM tarball obsahuje také,
  ale ARM verzi jsem neprověřoval a Dockerfile ji nepodporuje.
- Lokace Nuremberg nebo Falkenstein má z Česka nízký ping. Falkenstein jsem ve zdrojích
  nepotvrdil, Nuremberg ano.
Zdroje: [Hetzner ceny 2026](https://agentdeals.dev/hetzner-pricing-2026),
[zdražení v červnu](https://privatedevops.com/news/hetzner-june-2026-cloud-price-increase-what-to-do),
[srovnání cloudů 2026-08](https://kimmo.suominen.com/stuff/cpc-2026-08.txt).

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
Zdroj: [Oracle komunita](https://community.oracle.com/customerconnect/discussions/tagged/arm/p1),
[BrainDetox](https://braindetox.kr/en/posts/oracle_always_free_backend_2026.html).

### Správce herních serverů

Firmy jako [Citadel Servers](https://citadelservers.com/en-us/node/417) nebo
[GameHostBros](https://www.gamehostbros.com/unreal-tournament-2004-server-hosting)
nabízejí hotový UT2004. Nic nespravuješ, ale ani neovlivníš a ceny jsem neověřoval.
Má smysl, pokud nechceš na server vůbec sahat.

## Seznam serverů (master server)

Epic master servery vypnul. Patch 3374 má v `Default.ini` už předvyplněných šest
komunitních mastrů včetně `utmaster.openspy.net` a `MasterServerLauncher`, takže
inzerce funguje, jakmile server běží.
Zdroje: [OldUnreal README](https://github.com/OldUnreal/UT2004Patches),
[Steam diskuse k OpenSpy](https://steamcommunity.com/app/13230/discussions/0/3732952112224013002).

**Neověřeno:** zda seznam OpenSpy vyžaduje platný CD key. Zdroje se liší a žádný
nepopisuje, jak ho získat. Přímé připojení přes IP funguje vždy, takže nejde o blokér
pro hraní se známými hráči. První reálný start rozhodne, zda se server v seznamu objeví.

## Rizika

- **Patch 3374 je pořád „preview"** (Preview 23, poslední před release candidate).
  Podle hostingu GameHostBros se hráči na čistém 3369 k serveru 3374 připojí, ale
  oficiálně jsem to nepotvrdil, a preview verze se může rozbít. Odkaz na patch je v `Dockerfile` připnutý
  i s kontrolním součtem, takže se nezmění pod rukama.
- **Servery s AntiTCC** vyžadovaly aktualizaci kompatibilní s 3374 (poznámka k Preview 9).
- **UDP amplifikace přes dotazovací port** (obecná znalost, ne ze zdroje): veřejné herní
  servery bývají zneužívány k odrazovým útokům. Neotvírej víc portů, než potřebuješ, a neprovozuj WebAdmin veřejně.
- **Zálohy**: jediný stav, který stojí za zálohu, je `game/System/*.ini` (nastavení
  serveru). Obsah hry máš u sebe.
