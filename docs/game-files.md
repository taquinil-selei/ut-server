# Herní obsah

Image obsahuje jen engine (OldUnreal patch). Mapy, textury, zvuky a hudbu musíš dodat
z vlastní kopie hry. Postup je podle README projektu
[OldUnreal/UT2004Patches](https://github.com/OldUnreal/UT2004Patches).

## Co kopírovat

Ze složky s nainstalovanou hrou zkopíruj **jen tyto adresáře** do `game/`:

`Animations  KarmaData  Maps  Music  Prefabs  Sounds  Speech  StaticMeshes  Textures`

- Názvy jsou case-sensitive, na Linuxu musí sedět přesně takhle.
- **Nekopíruj `System`.** README OldUnreal varuje, že hra se pak nespustí. Entrypoint
  odmítne start, pokud v `game/System` najde něco, co nevytvořil sám.
- `Help` a `Web` dodá patch.
- Typické cesty: Steam `...\steamapps\common\Unreal Tournament 2004\`, GOG `C:\GOG Games\Unreal Tournament 2004\`.

## Nemám hru

- Koupě Steam/GOG verze je nejčistší cesta.
- Epic kdysi rozdával dedikovaný server zdarma (v3339 + bonus pack). Živý oficiální
  odkaz jsem nenašel a legální status kopií na zrcadlech neověřoval. Gentoo ebuild ho
  označuje jako nedistribuovatelný (`restrict bindist`).
- OldUnreal má instalátory (repo `FullGameInstallers`), ale stránku jsem odtud nemohl
  otevřít (403), takže nevím, co přesně umí.

## Neověřeno

Zda Steam/GOG kopie obsahuje bonus pack Editor's Choice Edition (OldUnreal ho pro ruční
instalaci vyžaduje) jsem neověřoval. Pokud server při startu hlásí chybějící mapy nebo
balíčky, je to první podezřelý.
