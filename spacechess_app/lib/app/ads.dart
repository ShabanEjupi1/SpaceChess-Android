import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Reklamat e «Mat!».
///
/// Të gjitha rregullat rrinë KËTU, në një skedar, e jo të shpërndara nëpër
/// ekrane — përndryshe «sa reklama ka kjo lojë» nuk ka përgjigje të lexueshme.
///
/// **Politika e zgjedhur: e lehtë.** Shahu është lojë e gjatë dhe e ngadalshme;
/// një lojtar që mendon dy minuta mbi një lëvizje dhe pastaj shikon një reklamë
/// nuk kthehet. Prandaj:
///
/// | Ku | Çfarë |
/// |---|---|
/// | menyja | banderolë poshtë |
/// | gjatë lojës | **asgjë** — tabela nuk preket kurrë |
/// | fundi i lojës | interstitial, 1 në 3 lojëra dhe s'ka dy brenda 3 minutash |
/// | kthimi i 4-t e tutje | reklamë me shpërblim, me dëshirë |
/// | hapja e aplikacionit | **e fikur** |
///
/// **Tri rregulla që nuk shkelen:**
///
/// 1. 🕌 **Filtrim halal në dy vende.** [MaxAdContentRating.g] këtu plus
///    bllokimi i kategorive te konsola e AdMob-it (bixhoz, alkool, takime,
///    kredi me kamatë). Të dyja duhen: kodi kufizon *klasifikimin*, konsola
///    kufizon *temën*, dhe një reklamë bixhozi mund të jetë fare mirë e
///    klasifikuar «G».
/// 2. **Asnjë reklamë sa kohë loja është gjallë.** Një reklamë mbi tabelën gjatë
///    radhës së lojtarit është pikërisht ajo që Play-i e quan «reklamë
///    shkatërruese» dhe që e heq aplikacionin nga dyqani.
/// 3. 🚨 **Në debug përdoren GJITHMONË njësitë e provës së Google-it.** Një
///    klikim i vetëm mbi njësinë e vërtetë nga vetë zhvilluesi është «trafik i
///    pavlefshëm»: llogaria e AdMob-it mbyllet pa paralajmërim. Kjo është shkaku
///    numër një i mbylljes së llogarive të reja, jo kujdes i tepruar.
class Ads {
  Ads._();

  /// Njësitë e vërteta të «Mat!» nga llogaria e AdMob-it
  /// (`credentials.local.txt`, ndarja «chess AdMob»). Nuk janë sekret: një
  /// identifikues njësie del në çdo kërkesë reklame dhe lexohet nga APK-ja.
  ///
  /// ⚠️ Këto NUK janë njësitë e Tokërrgjikut. Të dy aplikacionet rrinë nën të
  /// njëjtën llogari (`~1776059573171352`) por nën aplikacione të ndryshme te
  /// AdMob-i, ndaj identifikuesi i aplikacionit ndryshon: shahu e ka
  /// `~3928973421`, Tokërrgjiku `~3673667026`. Ai i dyti rri te manifesti i tij.
  static const String _bannerLive = 'ca-app-pub-1776059573171352/2863303764';
  static const String _interstitialLive = 'ca-app-pub-1776059573171352/9919666700';
  static const String _rewardedLive = 'ca-app-pub-1776059573171352/1986316301';

  // Të krijuara te AdMob-i por të PAPËRDORURA me qëllim, sipas politikës «e
  // lehtë». Rrinë të shënuara që të mos rikrijohen dhe që hapja e konsolës me
  // njësi me zero kërkesa të ketë shpjegim:
  //   app open           ca-app-pub-1776059573171352/6303021172
  //   native advanced    ca-app-pub-1776059573171352/4256276488
  //   rewarded interst.  ca-app-pub-1776059573171352/2013256521

  /// Njësitë e provës së Google-it. Kthejnë gjithmonë një reklamë, kudo, dhe
  /// klikimi mbi to nuk numërohet askund.
  static const String _bannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedTest = 'ca-app-pub-3940256099942544/5224354917';

  static String get bannerUnit => kReleaseMode ? _bannerLive : _bannerTest;
  static String get interstitialUnit =>
      kReleaseMode ? _interstitialLive : _interstitialTest;
  static String get rewardedUnit => kReleaseMode ? _rewardedLive : _rewardedTest;

  /// Reklamat ekzistojnë vetëm në Android dhe iOS. I njëjti kod ndërtohet edhe
  /// për web, Linux dhe Windows, dhe atje `MobileAds.instance` rrëzohet — ndaj
  /// çdo rrugë këtu kalon nga kjo pyetje e vetme.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool _ready = false;

  /// A janë reklamat gati. Ekranet e pyesin që të mos lënë vend bosh për diçka
  /// që mund të mos vijë kurrë.
  static bool get ready => _ready;

  /// Nisja. Thirret një herë, para se të hapet ekrani i parë.
  ///
  /// Nuk hidhet kurrë përjashtim jashtë: një lojë shahu që nuk hapet sepse
  /// rrjeti i reklamave nuk u përgjigj është shkëmbim absurd.
  static Future<void> start() async {
    if (!supported || _ready) return;
    try {
      await _askConsent();
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          // 🕌 «G» = e përshtatshme për të gjithë. Gjysma e filtrit; gjysma
          // tjetër janë kategoritë e ndjeshme te konsola e AdMob-it.
          maxAdContentRating: MaxAdContentRating.g,
          // Publiku i synuar te Play është 13+, pra jo fëmijë. Një «po» këtu do
          // të hiqte identifikuesin e reklamave, do të ulte mbushjen pa nevojë,
          // dhe mbi të gjitha do të ishte deklarim i pasaktë.
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        ),
      );
      _ready = true;
      preloadInterstitial();
    } catch (e) {
      debugPrint('reklamat nuk u nisën: $e');
    }
  }

  /// Pëlqimi sipas GDPR-së (UMP). Pa këtë, një lojtar në BE merr reklama pa bazë
  /// ligjore — dhe Google-i e ndalon mbushjen për atë pajisje.
  ///
  /// Për lojtarët jashtë BE-së formulari as nuk kërkohet as nuk shfaqet, pra kjo
  /// thirrje është praktikisht e menjëhershme në Kosovë.
  static Future<void> _askConsent() async {
    final Completer<void> done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) debugPrint('formulari i pëlqimit: ${error.message}');
          if (!done.isCompleted) done.complete();
        });
      },
      (FormError error) {
        debugPrint('pëlqimi: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    // Nëse UMP-ja nuk përgjigjet fare, aplikacioni vazhdon pa të: më mirë një
    // ekran fillestar pa reklama sesa një ekran fillestar që nuk mbaron kurrë.
    return done.future.timeout(const Duration(seconds: 6), onTimeout: () {});
  }

  // ── interstitial ───────────────────────────────────────────────────────────

  static InterstitialAd? _interstitial;
  static DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);
  static int _gamesSinceAd = 0;

  /// Ngarkon paraprakisht reklamën e ndërmjetme. Ngarkimi zgjat sekonda; nëse
  /// nis vetëm në çastin kur duhet shfaqur, ose vonon lojtarin ose humbet.
  static void preloadInterstitial() {
    if (!_ready || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) => _interstitial = ad,
        onAdFailedToLoad: (LoadAdError e) => _interstitial = null,
      ),
    );
  }

  /// Shfaqet pasi lojtari ka mbyllur dialogun e rezultatit — dhe jo pas çdo loje.
  ///
  /// Kufiri është i dyfishtë me qëllim: **të paktën tri lojëra** dhe **të paktën
  /// tri minuta** mes dyve. Te shahu ka një rrugë të shkurtër drejt reklamave
  /// radhazi që te lojërat e tjera nuk ekziston: mat-i i dy lëvizjeve. Një
  /// fillestar që e ha atë tri herë brenda një minute do të shihte tri reklama
  /// brenda një minute — pa kufirin e kohës, kufiri i lojërave nuk e ndal.
  static Future<void> maybeShowAfterGame() async {
    if (!_ready) return;
    _gamesSinceAd++;
    final bool tooSoon =
        DateTime.now().difference(_lastInterstitial) < const Duration(minutes: 3);
    if (_gamesSinceAd < 3 || tooSoon) {
      preloadInterstitial();
      return;
    }

    final InterstitialAd? ad = _interstitial;
    if (ad == null) {
      preloadInterstitial();
      return;
    }
    _interstitial = null;
    _gamesSinceAd = 0;
    _lastInterstitial = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError e) {
        ad.dispose();
        preloadInterstitial();
      },
    );
    await ad.show();
  }

  // ── me shpërblim ───────────────────────────────────────────────────────────

  /// Shfaq një reklamë me shpërblim dhe kthen `true` vetëm nëse lojtari e pa
  /// deri në fund.
  ///
  /// Çdo dështim kthen `false`, dhe thirrësi vendos vetë: te ky aplikacion i jep
  /// kthimet gjithsesi, sepse një lojtar që PRANOI të shohë një reklamë nuk
  /// duhet ndëshkuar për një rrjet që nuk u përgjigj.
  static Future<bool> showRewarded() async {
    if (!_ready) return false;
    final Completer<bool> done = Completer<bool>();

    unawaited(RewardedAd.load(
      adUnitId: rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          bool earned = false;
          ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              if (!done.isCompleted) done.complete(earned);
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError e) {
              ad.dispose();
              if (!done.isCompleted) done.complete(false);
            },
          );
          unawaited(ad.show(onUserEarnedReward: (AdWithoutView _, RewardItem __) {
            earned = true;
          }));
        },
        onAdFailedToLoad: (LoadAdError e) {
          if (!done.isCompleted) done.complete(false);
        },
      ),
    ));

    return done.future.timeout(const Duration(seconds: 12), onTimeout: () => false);
  }
}

/// Banderola e poshtme e menysë.
///
/// E ndarë si widget me gjendjen e vet sepse një `BannerAd` duhet ngarkuar dhe
/// hedhur bashkë me ekranin që e mban; një banderolë e vetme e përbashkët do të
/// mbetej e lidhur me një `BuildContext` të vdekur pas rrotullimit të ekranit.
///
/// Sa kohë reklama nuk është gati, widget-i zë **zero** hapësirë. Një kuti bosh
/// me lartësi 50 pikselë nën menu është vend i mbajtur për diçka që mund të mos
/// vijë kurrë (pa internet, ose me pëlqim të refuzuar).
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key});

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!Ads.ready) return;
    final BannerAd ad = BannerAd(
      adUnitId: Ads.bannerUnit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad _) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError e) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    unawaited(ad.load());
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd? ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
