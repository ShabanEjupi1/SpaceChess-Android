import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spacechess/app/prefs.dart';
import 'package:spacechess/board/four_board_view.dart';
import 'package:spacechess/game/four_page.dart';
import 'package:spacechess/home_page.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

/// 🚨🚨 Përse ky skedar ekziston.
///
/// Motori i Katërshit ishte i provuar me 26 prova që nga 11-08-2026, dhe atë
/// ditë titulli te Google Play e premtoi veçorinë. Ndërfaqja mungonte. Pra të
/// gjitha provat ishin të gjelbra ndërsa dyqani reklamonte diçka që lojtari nuk
/// e gjente dot te aplikacioni — sepse asnjë provë nuk pyeste **a arrihet dot
/// nga ekrani i parë**. Ajo është pikërisht pyetja e provës së parë këtu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Katërshi arrihet nga ballina', (WidgetTester t) async {
    await t.pumpWidget(MaterialApp(home: HomePage(prefs: await Prefs.open())));
    await t.pumpAndSettle();

    expect(find.text('Katërshi — shah me katër'), findsOneWidget);

    await t.tap(find.text('Katërshi — shah me katër'));
    await t.pumpAndSettle();

    expect(find.text('Katër veta, një pajisje'), findsOneWidget);
    expect(find.text('Ti kundër tre kompjuterëve'), findsOneWidget);
  });

  testWidgets('tabela hapet me të katër ushtritë dhe zero pikë',
      (WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(home: FourPage(mode: FourMode.pass)));
    await t.pumpAndSettle();

    expect(find.byType(FourBoardView), findsOneWidget);
    for (final String name in fourColorNamesSq) {
      expect(find.text(name), findsWidgets, reason: name);
    }
    // Katër zero: asnjë pikë e dhënë para lëvizjes së parë.
    expect(find.text('0'), findsNWidgets(4));
  });

  testWidgets('një prekje-prekje e luan lëvizjen dhe radha kalon te blu',
      (WidgetTester t) async {
    // 🚨 Ekrani i parazgjedhur i provave është 800×600. Një tabelë 14×14 e gjerë
    // sa ekrani del 776 pikselë e LARTË, ndaj rreshtat e poshtëm — pikërisht ata
    // ku rrinë pengjet e kuqe — bien jashtë pamjes, dhe një prekje atje nuk
    // godet asgjë. Prova dështonte sikur lëvizja të mos ishte e ligjshme.
    await t.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(const MaterialApp(home: FourPage(mode: FourMode.pass)));
    await t.pumpAndSettle();

    expect(find.text('Radha: E kuqe'), findsOneWidget);

    // Kutitë llogariten nga qendra, ashtu si e bën gishti. E kuqja luan nga
    // POSHTË, ndaj rreshti 0 është rreshti i fundit i ekranit.
    final Rect board = t.getRect(find.byType(FourBoardView));
    final double cell = board.width / 14;
    Offset at(int file, int rank) => Offset(
          board.left + (file + 0.5) * cell,
          board.top + (13 - rank + 0.5) * cell,
        );

    // Pengu i kuq te 4,1 → 4,3 (dy hapa, si te shahu i zakonshëm).
    await t.tapAt(at(4, 1));
    await t.pumpAndSettle();
    await t.tapAt(at(4, 3));
    await t.pumpAndSettle();

    expect(find.text('Radha: Blu'), findsOneWidget);
  });

  testWidgets('modaliteti me kompjuterë luan vetë tri radhët e tjera',
      (WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(home: FourPage(mode: FourMode.bots)));
    await t.pump();

    // 🔑 Tri lëvizje me nga 420 ms pauzë. Pa `pump` me kohë, testi do të lexonte
    // gjendjen para se truri të kishte luajtur — dhe do të kalonte i gjelbër
    // duke provuar hiçin.
    for (int i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
    await t.pumpAndSettle();

    expect(find.text('Radha jote'), findsOneWidget);
  });
}
