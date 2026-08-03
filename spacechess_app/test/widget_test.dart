import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spacechess/app/prefs.dart';
import 'package:spacechess/board/board_view.dart';
import 'package:spacechess/game/game_page.dart';
import 'package:spacechess/home_page.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

/// Testet e ndërfaqes janë të pakta me qëllim: rregullat i mbulon suita e
/// motorit (perft), dhe një test që rivizaton tabelën nuk provon asgjë për
/// shahun. Ajo që provohet këtu është pikërisht ajo që motori NUK e sheh — se
/// ekrani hapet, se prekja luan një lëvizje, dhe se tabela vizatohet në çdo fazë
/// pa u rrëzuar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<Prefs> prefs() => Prefs.open();

  testWidgets('ballina shfaqet me të tria mënyrat e lojës', (WidgetTester t) async {
    await t.pumpWidget(MaterialApp(home: HomePage(prefs: await prefs())));
    await t.pumpAndSettle();

    expect(find.text('Shah Mat'), findsOneWidget);
    expect(find.text('Luaj vetëm'), findsOneWidget);
    expect(find.text('Dy lojtarë, një pajisje'), findsOneWidget);
    expect(find.text('Luaj online'), findsOneWidget);
  });

  testWidgets('një prekje-prekje e luan lëvizjen mbi tabelë',
      (WidgetTester t) async {
    await t.pumpWidget(MaterialApp(
      home: GamePage(
        prefs: await prefs(),
        level: 0, // dy lojtarë: pa kompjuter, pa isolate te testi
        humanColour: white,
        variant: Variant.standard,
      ),
    ));
    await t.pumpAndSettle();

    expect(find.text('Radha: I bardhi.'), findsOneWidget);

    // e2 → e4. Kutitë llogariten nga qendra e tabelës, ashtu si e bën gishti.
    final Rect board = t.getRect(find.byType(BoardView));
    final double cell = board.width / 8;
    Offset at(int file, int rank) => Offset(
          board.left + (file + 0.5) * cell,
          board.top + (7 - rank + 0.5) * cell,
        );

    await t.tapAt(at(4, 1));
    await t.pumpAndSettle();
    await t.tapAt(at(4, 3));
    await t.pumpAndSettle();

    expect(find.text('Radha: I ziu.'), findsOneWidget);
  });

  testWidgets('tabela vizatohet për çdo variant pa u rrëzuar',
      (WidgetTester t) async {
    for (final Variant v in Variant.values) {
      await t.pumpWidget(MaterialApp(
        home: GamePage(
          prefs: await prefs(),
          level: 0,
          humanColour: white,
          variant: v,
          startFen: v == Variant.chess960 ? chess960Fen(42) : null,
        ),
      ));
      await t.pumpAndSettle();
      expect(find.byType(BoardView), findsOneWidget, reason: v.name);
    }
  });
}
