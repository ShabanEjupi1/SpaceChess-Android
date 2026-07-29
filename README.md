# SpaceChess për Android

Mbështjellësi Android i **https://chess.spacecode.tech**, i ndërtuar si
*Trusted Web Activity*: aplikacioni hap Chrome-in e vetë telefonit, pa shirit
adrese, mbi të njëjtin kod që luan faqja.

Loja nuk ndodhet këtu. Kodi i saj është te `linux-install/spacechess/`
(Gitea). Kjo depo mban vetëm paketimin për Google Play, sepse ndërtimet
Android nuk bëhen dot në Ampere: Google nuk shpërndan `aapt2`/`d8` për
linux-aarch64. Prandaj CI-ja është këtu, mbi vrapuesit x86 falas të GitHub-it.

## Pse TWA e jo WebView

Një WebView është një shfletues i ngrirë brenda aplikacionit: pa përditësime
sigurie nga Chrome, pa të njëjtin motor JavaScript, dhe me një depozitë të
ndarë — pra lojtari do të humbte kredencialin `sc_token`, dhe bashkë me të
edhe pikët e veta. Një TWA është Chrome-i i vërtetë: i njëjti motor, e njëjta
depozitë, i njëjti lojtar në telefon dhe në shfletues.

## Lidhja me faqen

Dy gjysma që duhet të përputhen:

1. `app/src/main/res/values/strings.xml` → `asset_statements` (drejt faqes)
2. `https://chess.spacecode.tech/.well-known/assetlinks.json` (drejt paketës)

Skedari i dytë ndodhet te `linux-install/spacechess/static/.well-known/`.

🚨 **Pas ngarkimit të parë te Play, gjurma ndryshon.** Play App Signing e
rinënshkruan aplikacionin me çelësin e vet, ndaj `assetlinks.json` duhet të
përmbajë edhe gjurmën SHA-256 të *çelësit të nënshkrimit të Play-it*
(Play Console → Test and release → Setup → App integrity). Pa të, aplikacioni
hapet me shirit adrese sipër — punon, por duket si një skedë shfletuesi.

## Ndërtimi

CI-ja e bën vetë (`.github/workflows/build.yml`). Me dorë:

```
gradle :app:bundleRelease        # → app/build/outputs/bundle/release/app-release.aab
```

Nënshkrimi kërkon `key.properties` në rrënjë (i injoruar nga git):

```
storeFile=/shtegu/te/spacechess-upload.jks
storePassword=…
keyAlias=spacechess
keyPassword=…
```

Çelësi ndodhet te depoja private `spacecode-brain/keys/spacechess-upload.jks`,
dhe fjalëkalimet te `credentials.local.txt`. Nëse humbet, aplikacioni nuk
përditësohet dot më kurrë — duhet listim i ri, me paketë tjetër.

## Ngarkimi te Play

Një etiketë `v*` e ngarkon AAB-në te gjurma e brendshme:

```
git tag v1.0.0 && git push origin v1.0.0
```

Kjo kërkon sekretin `PLAY_SERVICE_ACCOUNT_JSON` dhe — më e rëndësishmja — që
aplikacioni `tech.spacecode.chess` **të ekzistojë tashmë te Play Console**:
API-ja nuk krijon dot aplikacione të reja dhe ngarkimin e parë e pranon vetëm
pas krijimit me dorë.
