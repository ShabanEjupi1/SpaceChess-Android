/// # 🫱 Dora e Huaj — «lëviz vetëm atë që nuk është jotja»
///
/// Loja e re që Shabani kërkoi më 2026-08-10:
///
/// > «the chess should be changed to completely new game never played before
/// > so users download it more because having problems with downloads from
/// > users in play store»
///
/// ## 🚨 Pse ky rregull dhe jo një variant tjetër shahu
///
/// Kërkesa kishte dy pjesë, dhe e dyta është ajo që e vendos dizajnin: **jo një
/// lojë e mirë — një lojë që SHKARKOHET.** Pesë variantet e shahut që ka
/// tashmë aplikacioni ([Game] me Chess960, Mbreti i Kodrës, Tre Shahe, Antishah)
/// nuk e zgjidhën atë problem, dhe arsyeja matet te
/// [[loja-e-re-viraliteti]]: kategoria e shahut është e NGOPUR. Një variant i
/// gjashtë hyn te e njëjta garë.
///
/// Prandaj kushti i parë i dizajnit ishte: **rregulli kryesor duhet të thuhet me
/// një fjali, dhe ajo fjali duhet të tingëllojë e pamundur.**
///
/// > *Lëviz vetëm gurët që NUK janë të tutë — dhe guri që lëviz bëhet yti.*
///
/// Kjo është e gjithë loja. Nuk ka figura, nuk ka hapje për të mësuar përmendsh,
/// nuk ka nevojë të dish shah, dhe pyetja e parë e çdo njeriu që e dëgjon
/// («po si fitohet, atëherë?») është pikërisht grepi.
///
/// ## 🚨🚨🚨 GJENDJA: kjo NUK është ende një lojë e gatshme
///
/// Tri dizajne u matën më 2026-08-10 dhe të tria ranë; hollësitë dhe numrat
/// rrinë te `linux-install/LOJA-DORA-MATJET.md`. Përmbledhje:
///
///   1. Grup prej 5 të lidhur → **200 barazime nga 200**. Kundërshtari
///      DETYROHET të prishë çdo formë timen, sepse s'ka çfarë tjetër të prekë.
///   2. Ngulitje grupesh (prag 2 dhe 3, synim 4/5/6) → **barazim 100%** te të
///      gjashtë kombinimet. Grupi më i madh nuk kaloi kurrë **1**.
///   3. Ngulitje-në-lëvizje (ky kod sot) → ndeshja MBARON gjithmonë te 12
///      radhë, po prapë 0–0.
///
/// ⛔ Prandaj ky modalitet **nuk lidhet ende me ndërfaqen** dhe nuk hipet te
/// Play. Provat më poshtë provojnë se rregullat sillen si shkruhen — jo se
/// loja është e luajtshme. Të dyja janë pyetje të ndryshme, dhe ngatërrimi i
/// tyre është mënyra më e shpejtë për të nxjerrë një lojë të vdekur.
///
/// ## Rregullat
///
/// - Fusha **6×6**. Dymbëdhjetë gurë: gjashtë të secilit lojtar.
/// - Me radhë: zgjedh një gur që **nuk** është i yti dhe e zhvendos **një fushë**
///   djathtas, majtas, lart ose poshtë, te një fushë **bosh**.
/// - Guri që lëvize **bëhet yti** në çast.
/// - Një grup prej [nguljes] gurësh të lidhur të të njëjtit pronar **ngulitet**:
///   ata gurë nuk lëvizen më nga askush, kurrë.
/// - **Fiton** kush arrin një grup prej [fitorja] gurësh të lidhur anash (jo
///   diagonalisht).
///
/// ## 🚨🚨 Ngulitja nuk ishte te dizajni i parë — e shtoi MATJA
///
/// Pa të, loja ishte **e pafitueshme**, dhe kjo u mat, nuk u hamendësua:
/// `tool/mat_dora.dart` luajti 200 ndeshje me lojtarë të arsyeshëm dhe
/// përfundoi **200 barazime nga 200**, të gjitha te kufiri i radhëve.
///
/// 🔑 Shkaku ishte i pashmangshëm sapo shkruhet: kundërshtari **detyrohet** të
/// lëvizë një gur TIMIN te çdo radhë e vet, sepse gurët e vet nuk i lëviz dot.
/// Pra çdo formë që unë ndërtoj, ai duhet ta prishë — jo se e zgjedh, se s'ka
/// çfarë tjetër të prekë. Numrat rrinë 6 me 6 përgjithmonë dhe asnjë grup nuk
/// mbërrin dot te pesa.
///
/// Ngulitja e zgjidh pikërisht atë: pas tri gurësh të lidhur, forma bëhet e
/// pacenueshme, dhe loja kthehet në garë ndërtimi mbi një bazë që mbetet.
/// Ajo e bën edhe ndeshjen të MBARUAJË, sepse gurët e ngulitur nuk shngulen
/// kurrë — pra pas çdo ngulitjeje bota bëhet më e vogël.
///
/// ## 🔒 Ngulitja-në-lëvizje
///
/// Guri i lëvizur nuk lëvizet më kurrë, nga askush. Kjo zëvendësoi rregullin e
/// ko-së (i cili ndalonte vetëm marrjen e menjëhershme prapa) dhe e bën
/// mbarimin e ndeshjes një **garanci**, jo një kufi: gurët e ngulitur nuk
/// shngulen kurrë, ndaj pas 12 lëvizjesh nuk mbetet asgjë për të lëvizur.
///
/// ## 🕌 Pa qenie të gjalla
///
/// Gurë të rrumbullakët dhe një rrjetë. Asnjë figurë, asnjë fytyrë, asnjë emër
/// force a shteti — shih [[workflow-pamja-pa-qenie-te-gjalla]]. Loja nuk ka as
/// bast, as fat: çdo lëvizje është e plotë dhe e dukshme, dhe nuk hidhet asnjë
/// zar.
library;

/// Kush e zotëron një fushë.
enum Zoti {
  bosh,
  i_pari,
  i_dyti;

  Zoti get kundershtari => switch (this) {
        Zoti.i_pari => Zoti.i_dyti,
        Zoti.i_dyti => Zoti.i_pari,
        Zoti.bosh => Zoti.bosh,
      };
}

/// Një lëvizje: nga fusha [nga] te fusha [te], të dyja si indeks 0…35.
class Levizja {
  const Levizja(this.nga, this.te);
  final int nga;
  final int te;

  @override
  bool operator ==(Object other) =>
      other is Levizja && other.nga == nga && other.te == te;

  @override
  int get hashCode => nga * 64 + te;

  @override
  String toString() => '${_emri(nga)}→${_emri(te)}';

  static String _emri(int i) =>
      '${String.fromCharCode(97 + i % Dora.ana)}${Dora.ana - i ~/ Dora.ana}';
}

/// Gjendja e një ndeshjeje të «Dorës së Huaj».
class Dora {
  /// Fusha është katrore; 6 është zgjedhur, jo trashëguar — shih [_pseGjashte].
  static const int ana = 6;
  static const int fusha = ana * ana;

  /// Sa gurë të lidhur duhen për fitore.
  static int fitorja = 5;

  /// Sa gurë të lidhur e ngulisin një grup përgjithmonë.
  ///
  /// 🚨 3 dhe jo 2: me 2, çdo çift i rastësishëm gurësh ngjitur do të ngulitej
  /// që te lëvizja e parë, dhe fusha do të ngrinte para se dikush të vendoste
  /// gjë. Me 4, ngulitja vjen kaq vonë sa kundërshtari e prish gjithmonë të
  /// tretin — pra kthehemi te loja e pafitueshme që mati matja.
  /// ⛔ I papërdorur që nga ngulitja-në-lëvizje; mbahet vetëm sa të hiqet nga
  /// provat e vjetra. Shih §🚨🚨🚨 te kreu.
  static int nguljes = 99;

  /// Pas kaq radhësh pa fitore, ndeshja quhet e barabartë.
  ///
  /// 🚨 Kufiri NUK është zbukurim. Me rregullin e ko-së ndeshjet mbarojnë, po
  /// jo të gjitha: `tool/mat_dora.dart` mati bishtin e gjatë të ndeshjeve mes dy
  /// lojtarësh krejt të rastësishëm. Pa kufi, një telefon do të rrinte duke
  /// llogaritur në një ndeshje që nuk mbaron — dhe kjo lexohet si aplikacion i
  /// ngrirë, jo si barazim.
  static int radheMaks = 200;

  Dora._(this._fushat, this.radha, this._iNdaluar, this.radhet, this._ngulitur);

  /// Cilat fusha janë ngulitur. 🚨 Kurrë nuk kthehet te `false`: monotonia është
  /// ajo që e bën ndeshjen të mbarojë, dhe një «shngulje» do ta hiqte atë
  /// garanci pa u vënë re te asnjë provë e rregullave.
  final List<bool> _ngulitur;

  bool ngulitur(int i) => _ngulitur[i];

  /// Nisja: gjashtë gurë të secilit, te rreshtat e kundërt, të ndërthurur.
  ///
  /// 🚨 Të NDËRTHURUR, jo dy rreshta të plotë përballë njëri-tjetrit. Me rreshta
  /// të plotë, lëvizja e parë e secilit lojtar është e detyruar te i njëjti çift
  /// fushash dhe hapja është gjithmonë e njëjta — pikërisht ajo që kjo lojë
  /// synon të mos ketë. Të ndërthurur, secili gur ka fqinj të të dyja ngjyrave
  /// që nga hapi i parë.
  factory Dora.nisja() {
    final f = List<Zoti>.filled(fusha, Zoti.bosh);
    for (var k = 0; k < ana; k++) {
      f[k] = k.isEven ? Zoti.i_pari : Zoti.i_dyti;
      f[fusha - ana + k] = k.isEven ? Zoti.i_dyti : Zoti.i_pari;
    }
    return Dora._(f, Zoti.i_pari, -1, 0, List<bool>.filled(fusha, false));
  }

  /// Ndërtues për provat: fushat jepen si varg shkronjash `.`, `A`, `B`.
  factory Dora.nga(String skica, {Zoti radha = Zoti.i_pari, int iNdaluar = -1}) {
    final pastruar = skica.replaceAll(RegExp(r'\s'), '');
    if (pastruar.length != fusha) {
      throw ArgumentError('skica duhet $fusha shenja, jo ${pastruar.length}');
    }
    final f = List<Zoti>.filled(fusha, Zoti.bosh);
    for (var i = 0; i < fusha; i++) {
      f[i] = switch (pastruar[i]) {
        'A' => Zoti.i_pari,
        'B' => Zoti.i_dyti,
        _ => Zoti.bosh,
      };
    }
    final d = Dora._(f, radha, iNdaluar, 0, List<bool>.filled(fusha, false));
    return d._ngulit();
  }

  final List<Zoti> _fushat;

  /// Kush luan tani.
  final Zoti radha;

  /// Guri që kundërshtari sapo lëvizi — [Dora] nuk e lejon të lëvizet prapa.
  /// −1 do të thotë «asnjë».
  final int _iNdaluar;

  /// Sa radhë janë luajtur.
  final int radhet;

  Zoti operator [](int i) => _fushat[i];

  int get iNdaluar => _iNdaluar;

  /// Të gjitha lëvizjet e lejuara për [radha].
  ///
  /// 🔑 «E lejuar» këtu do të thotë tri gjëra bashkë, dhe secila prej tyre është
  /// një rregull i lojës, jo një kontroll teknik: guri nuk është i yti, fusha ku
  /// shkon është bosh, dhe guri nuk është ai që kundërshtari sapo e lëvizi.
  List<Levizja> levizjet() {
    final dalja = <Levizja>[];
    for (var i = 0; i < fusha; i++) {
      if (_fushat[i] == Zoti.bosh || _fushat[i] == radha) continue;
      if (i == _iNdaluar) continue;
      // 🔒 Gurët e ngulitur nuk lëvizen nga askush. Shih §🚨🚨 te kreu.
      if (_ngulitur[i]) continue;
      for (final te in _fqinjet(i)) {
        if (_fushat[te] == Zoti.bosh) dalja.add(Levizja(i, te));
      }
    }
    return dalja;
  }

  /// Zbato një lëvizje. Kthen gjendjen e re; nuk e ndryshon këtë.
  Dora luaj(Levizja l) {
    if (!levizjet().contains(l)) {
      throw ArgumentError('lëvizje e palejuar: $l');
    }
    final f = List<Zoti>.of(_fushat);
    f[l.nga] = Zoti.bosh;
    // 🔑 Këtu ndodh e gjithë loja: guri ndërron pronar duke u lëvizur.
    f[l.te] = radha;
    final ng = List<bool>.of(_ngulitur);
    // 🚨 Ngulitja e fushës nga u nis guri duhet FSHIRË. Pa këtë rresht, një
    // fushë e zbrazët mbetet «e ngulitur» dhe guri i radhës që bie aty lind i
    // palëvizshëm — një gur i ngrirë pa asnjë shkak të dukshëm te fusha.
    ng[l.nga] = false;
    // 🔒🚨 Guri i lëvizur NGULITET në çast. Ky rresht është vetë loja, dhe u
    // shtua vetëm pasi matja rrëzoi dy dizajne para tij (shih §🚨🚨🚨 te kreu).
    ng[l.te] = true;
    return Dora._(f, radha.kundershtari, l.te, radhet + 1, ng)._ngulit();
  }

  /// Kush ka fituar, ose [Zoti.bosh] nëse askush ende.
  Zoti fituesi() {
    for (final z in [Zoti.i_pari, Zoti.i_dyti]) {
      if (_grupiMeIMadh(z) >= fitorja) return z;
    }
    return Zoti.bosh;
  }

  /// A ka mbaruar ndeshja — me fitore, pa lëvizje, ose me kufirin e radhëve.
  bool get mbaroi =>
      fituesi() != Zoti.bosh || radhet >= radheMaks || levizjet().isEmpty;

  /// Sa i madh është grupi më i madh i lidhur i [z]. Lexohet edhe nga ndërfaqja.
  int grupiMeIMadh(Zoti z) => _grupiMeIMadh(z);

  int _grupiMeIMadh(Zoti z) {
    final pare = List<bool>.filled(fusha, false);
    var meIMadhi = 0;
    for (var i = 0; i < fusha; i++) {
      if (_fushat[i] != z || pare[i]) continue;
      var sa = 0;
      final radhitja = <int>[i];
      pare[i] = true;
      while (radhitja.isNotEmpty) {
        final k = radhitja.removeLast();
        sa++;
        for (final fq in _fqinjet(k)) {
          if (!pare[fq] && _fushat[fq] == z) {
            pare[fq] = true;
            radhitja.add(fq);
          }
        }
      }
      if (sa > meIMadhi) meIMadhi = sa;
    }
    return meIMadhi;
  }

  /// Ngulit çdo grup që ka arritur [nguljes]. Kthen të njëjtën gjendje.
  ///
  /// 🔑 Thirret pas ÇDO lëvizjeje dhe pas ndërtimit nga skica, jo vetëm te
  /// [luaj]: një pozicion prove i shkruar me dorë duhet t'i ketë të njëjtat
  /// rregulla si një i arritur duke luajtur, përndryshe provat matin një lojë
  /// tjetër nga ajo që luan njeriu.
  Dora _ngulit() {
    for (final z in [Zoti.i_pari, Zoti.i_dyti]) {
      final pare = List<bool>.filled(fusha, false);
      for (var i = 0; i < fusha; i++) {
        if (_fushat[i] != z || pare[i]) continue;
        final grupi = <int>[];
        final radhitja = <int>[i];
        pare[i] = true;
        while (radhitja.isNotEmpty) {
          final k = radhitja.removeLast();
          grupi.add(k);
          for (final fq in _fqinjet(k)) {
            if (!pare[fq] && _fushat[fq] == z) {
              pare[fq] = true;
              radhitja.add(fq);
            }
          }
        }
        if (grupi.length >= nguljes) {
          for (final k in grupi) {
            _ngulitur[k] = true;
          }
        }
      }
    }
    return this;
  }

  /// Fqinjët anash — jo diagonalisht.
  ///
  /// 🚨 Jo diagonalisht, dhe kjo është vendim i matur me `tool/mat_dora.dart`:
  /// me tetë fqinjë, pesë gurë të lidhur mblidhen shumë lehtë dhe ndeshjet
  /// mbaruan mesatarisht te 14 radhë — shumë shkurt për të pasur vendime.
  static Iterable<int> _fqinjet(int i) sync* {
    final rr = i ~/ ana;
    final kol = i % ana;
    if (rr > 0) yield i - ana;
    if (rr < ana - 1) yield i + ana;
    if (kol > 0) yield i - 1;
    if (kol < ana - 1) yield i + 1;
  }

  /// Pamja si skicë — e njëjta gjuhë si [Dora.nga], që provat të lexohen.
  String skica() {
    final b = StringBuffer();
    for (var rr = 0; rr < ana; rr++) {
      for (var kol = 0; kol < ana; kol++) {
        b.write(switch (_fushat[rr * ana + kol]) {
          Zoti.i_pari => 'A',
          Zoti.i_dyti => 'B',
          Zoti.bosh => '.',
        });
      }
      if (rr < ana - 1) b.write('\n');
    }
    return b.toString();
  }

  /// Pse 6×6 dhe pse 5 gurë — të dyja u MATËN, nuk u zgjodhën.
  ///
  /// Te 5×5 fusha mbytet: gurët zënë 12 nga 25 fusha, lëvizjet e lejuara bien
  /// nën katër dhe ndeshja bëhet e detyruar. Te 7×7 gurët humbin njëri-tjetrin
  /// dhe ndeshjet shkuan mbi 120 radhë. Te 6×6 me synim 5, matja jep ndeshje
  /// 30–70 radhë mes lojtarësh që luajnë me arsye — shih `tool/mat_dora.dart`.
  static const String _pseGjashte = 'shih dokumentimin e kësaj klase';
}
