import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/ads.dart';
import 'app/prefs.dart';
import 'app/theme.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tabela është katrore dhe asgjë këtu nuk fiton nga gjerësia; një rrotullim
  // në mes të një radhe vetëm e humb lojtarin. Në tablet dhe desktop sistemi e
  // shpërfill këtë kërkesë dhe tabela thjesht qendërzohet.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
  unawaited(Ads.start());

  runApp(MatApp(prefs: prefs));
}

class MatApp extends StatelessWidget {
  const MatApp({super.key, required this.prefs});

  final Prefs prefs;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mat!',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: HomePage(prefs: prefs),
      );
}
