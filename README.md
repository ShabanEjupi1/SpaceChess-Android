# Mat! — aplikacioni i shahut

Shah kundër kompjuterit dhe online, në Android, iOS, web dhe desktop. **Aplikacion
vendas Flutter**, jo një faqe e mbështjellë.

> **Emri.** Produkti quhet **Mat!** nga 30-07-2026 (më parë «SpaceChess»).
> «SpaceChess» mbetet emri i *projektit* — depoja, paketa
> `tech.spacecode.chess`, kontejneri dhe `chess.spacecode.tech` — sepse asnjëri
> prej tyre nuk shihet nga lojtari dhe paketa te Play-i nuk ndryshohet dot.
> Emri i vjetër duhet të mos ndodhet **vetëm** te: etiketa e aplikacionit,
> titulli i listimit, ballina, dhe politika e privatësisë.

```
engine/           motori — Dart i pastër, pa Flutter (rregullat, variantet, AI-ja)
spacechess_app/   aplikacioni Flutter (android · ios · web · linux · windows · macos)
store/            teksti, ikonat dhe pamjet për Google Play
tools/play.mjs    Play Developer API, pa varësi
```

## Pse depo më vete nga loja

Loja në web (`chess.spacecode.tech`) rri te `linux-install/spacechess` në Gitea.
Ky aplikacion rri **këtu, në GitHub**, sepse Android-i **nuk ndërtohet dot në
Ampere**: Google nuk boton `aapt2`/`d8` për linux-aarch64. CI-ja e GitHub-it ka
runner-a x86 falas, dhe `linux-install` nuk ka remote GitHub.

## 🚨 Ç'ndryshoi më 29-07-2026

Ky ishte një **mbështjellës TWA** — një skedë Chrome-i me ikonë. U hoq i tëri.
Shkaku nuk ishte shija: një aplikacion që është një faqe e hapur me shirit
adrese nuk i jep lojtarit asgjë që faqja s'ia jep tashmë. Tani:

- **Rregullat u rishkruan në Dart** dhe janë të lidhura me suitën standarde të
  perft-it (pozicioni fillestar, Kiwipete, pozicionet 3–6, Chess960). Motori i
  JS-së i faqes mbetet aty ku ishte; **numrat e perft-it janë kontrata mes të
  dyve** — nëse njëri ndryshon dhe tjetri jo, ata numra e tregojnë.
- **Kompjuteri mendon në pajisje**, në një isolate. Ampere-ja nuk merr asnjë
  kërkim shahu.
- **Figurat vizatohen me vektorë**, jo me glife Unicode: ♞ nuk gjendet te
  Roboto-ja dhe në disa telefonë Android tabela do të dilte katrorë bosh.
- **Tokeni `sc_token` ruhet nga vetë aplikacioni** dhe dërgohet si kokë
  `Cookie:`. Ai token ËSHTË llogaria — pikët dhe historia. (Pikërisht kjo ishte
  arsyeja e TWA-së kundrejt një WebView-i; tani nuk ka më rëndësi.)

## 📣 Reklamat (nga 30-07-2026)

E gjithë politika rri te **`spacechess_app/lib/app/ads.dart`**, në një skedar të
vetëm: banderolë te menyja, një e ndërmjetme 1 në 3 lojëra (dhe jo dy brenda 3
minutash), dhe një me shpërblim — vetëm me pyetje — për kthime shtesë të
lëvizjeve pas tri të lirave. **Mbi tabelën, gjatë lojës, asgjë.**

- 🚨 Në debug përdoren **gjithmonë** njësitë e provës së Google-it. Një klikim i
  vetëm mbi njësinë e vërtetë nga vetë zhvilluesi është «trafik i pavlefshëm» dhe
  llogaria e AdMob-it mbyllet pa paralajmërim.
- 🚨 Identifikuesi i aplikacionit te manifesti është i **shahut**
  (`~3928973421`), jo i Tokërrgjikut (`~3673667026`). Pa të, aplikacioni rrëzohet
  në nisje.
- 🕌 Filtrimi halal duhet në dy vende: `MaxAdContentRating.g` te kodi (bërë) dhe
  Sensitive categories te konsola e AdMob-it (me dorë).
- ⚠️ Premtimi «pa reklama» u hoq nga **katër** vende bashkë: përshkrimi te
  `store/listimi.json`, nëntitulli te `home_page.dart`, `LISTIMI.md`, dhe
  politika e privatësisë. Nëse mbetet në një, është ankesë.

## Ndërtimi

```sh
cd engine         && dart pub get   && dart test        # perft — rrjeta e sigurisë
cd spacechess_app && flutter pub get && flutter test
flutter build appbundle --release                        # kërkon key.properties
```

Në Ampere ndërtohen **vetëm** `flutter analyze/test/build web`
(`export PATH=$PATH:/mnt/data/flutter/bin`). AAB-ja dhe APK-ja dalin nga CI-ja.

## Nënshkrimi dhe Play

- Çelësi: `spacecode-brain/keys/spacechess-upload.jks`, alias `spacechess`.
  **Kopje e vetme.** Humbja e tij = aplikacioni nuk përditësohet dot më kurrë.
- Sekretet te GitHub: `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`,
  `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`, `PLAY_SERVICE_ACCOUNT_JSON`.
- Një etiketë `v*` e ngarkon vetë AAB-në te gjurma e brendshme.

Listimi (tekst + ikonë + grafikë + pamje) ngjitet me:

```sh
node tools/play.mjs <çelësi.json> listimi tech.spacecode.chess store/listimi.json
node tools/play.mjs <çelësi.json> gjendja tech.spacecode.chess
```

⛔ Klasifikimi i përmbajtjes, «Siguria e të dhënave», publiku i synuar dhe
shtetet **nuk bëhen dot me API** — ato mbeten me dorë te Play Console.

## Ikonat dhe pamjet

Burimi i ikonës rri te `linux-install/spacechess/store/ikona.html` (i njëjti SVG
si stema e faqes). Rivizatimi kërkon një Chrome pa ekran:

```sh
node linux-install/spacechess/store/vizato.mjs http://127.0.0.1:9222 \
     store/ikona-gen linux-install/spacechess/store/grafikat.json
sh store/vendos-ikonat.sh store/ikona-gen
```

Pamjet e ekranit merren nga ndërtimi i vërtetë i web-it me
`linux-install/spacechess/store/pamje.mjs` dhe hapat te `store/hapat.json`.
