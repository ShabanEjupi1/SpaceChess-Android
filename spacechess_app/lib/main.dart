import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/ads.dart';
import 'app/analitika.dart';
import 'app/orientation.dart';
import 'app/prefs.dart';
import 'app/theme.dart';
import 'app/vleresimi.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 Orientimi NUK kyçet më këtu. Supozimi i vjetër — «në tablet dhe desktop
  // sistemi e shpërfill këtë kërkesë» — ishte i pasaktë: Google Play Games on
  // PC e respekton, dhe loja dilte si shirit i ngushtë në mes të një ekrani të
  // gjerë. Vendimi merret tani sipas madhësisë së dritares, te
  // [OrientimiPershtatur], ku MediaQuery-ja është vërtet e matur.

  // Nga Android 15 (API 35) çdo aplikacion vizaton **nën** shiritat e sistemit;
  // ngjyra e tyre nuk caktohet më. Kërkesa bëhet shprehimisht, që sjellja të
  // jetë e njëjtë edhe te Android 14 e poshtë, ku parazgjedhja është e kundërta.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 🚨 `statusBarColor` dhe `systemNavigationBarColor` NUK jepen më. Ato dy fusha
  // janë e vetmja gjë që e bën motorin e Flutter-it të thërrasë
  // `Window.setStatusBarColor` / `setNavigationBarColor` — të dyja të vjetruara
  // te Android 15, dhe të dyja të raportuara nga Play Console te lëshimi 2.7.0
  // (gjurma `io.flutter.plugin.platform.d.m`). Me edge-to-edge shiritat janë
  // gjithsesi të tejdukshëm, ndaj vlerat ishin edhe pa efekt.
  // ⚠️ Ndriçimi i ikonave MBETET: ai kalon nga një rrugë tjetër
  // (`WindowInsetsController`) dhe nuk është i vjetruar.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final Prefs prefs = await Prefs.open();

  // Reklamat nisen PA `await`: nisja e tyre përfshin formularin e pëlqimit dhe
  // një kërkesë rrjeti, pra do të mbante ekranin bosh sekonda të tëra në një
  // lidhje të dobët. Menyja hapet menjëherë dhe banderola shfaqet vetëm kur
  // (dhe nëse) vjen. Shih [Ads] — asnjë gabim prej tyre nuk del jashtë.
  // Matja nis PARA reklamave: një hapje që dështon te formulari i pëlqimit
  // duhet numëruar prapë, përndryshe humbasin pikërisht hapjet problematike.
  unawaited(Analitika.nis());
  // 🔎 Vetëm numëruesi i hapjeve. Kërkesa e vlerësimit shfaqet te fitorja ose
  // te enigma e zgjidhur, kurrë këtu. Shih app/vleresimi.dart.
  unawaited(Vleresimi.nis(versioni: '2.8.0+12'));
  unawaited(Ads.start());

  runApp(MatApp(prefs: prefs));
}

class MatApp extends StatelessWidget {
  const MatApp({super.key, required this.prefs});

  final Prefs prefs;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Shah Mat',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // `builder` dhe jo një mbështjellës rreth `home`-it: kështu rregulli
        // vlen edhe për faqet e hapura me Navigator, jo vetëm për të parën.
        builder: (BuildContext context, Widget? child) =>
            OrientimiPershtatur(child: child ?? const SizedBox.shrink()),
        home: HomePage(prefs: prefs),
      );
}
