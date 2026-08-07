import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/ads.dart';
import 'app/analitika.dart';
import 'app/orientation.dart';
import 'app/prefs.dart';
import 'app/theme.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 Orientimi NUK kyçet më këtu. Supozimi i vjetër — «në tablet dhe desktop
  // sistemi e shpërfill këtë kërkesë» — ishte i pasaktë: Google Play Games on
  // PC e respekton, dhe loja dilte si shirit i ngushtë në mes të një ekrani të
  // gjerë. Vendimi merret tani sipas madhësisë së dritares, te
  // [OrientimiPershtatur], ku MediaQuery-ja është vërtet e matur.

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
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
