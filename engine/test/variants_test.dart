import 'dart:math';

import 'package:spacechess_engine/spacechess_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Mbreti i Kodrës', () {
    test('mbreti mbi një nga katër kutitë qendrore fiton menjëherë', () {
      final Position p = fromFen('8/8/8/3K4/8/8/8/7k w - - 0 1', Variant.koth);
      final GameStatus st = gameStatus(p);
      expect(st.over, isTrue);
      expect(st.result, '1-0');
      expect(st.reason, EndReason.koth);
    });

    test('një kuti ngjitur me kodrën nuk fiton', () {
      final Position p =
          fromFen("8/8/8/2K5/8/8/R7/7k w - - 0 1", Variant.koth);
      expect(gameStatus(p).over, isFalse);
    });
  });

  group('Tre shahe', () {
    test('numëruesi rritet vetëm kur lëvizja jep vërtet shah', () {
      Position p = fromFen('4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1',
          Variant.threecheck);
      p = makeMove(p, moveFromUci(p, 'a1a8')!); // Ra8+
      expect(p.whiteChecks, 1);
      p = makeMove(p, moveFromUci(p, 'e8d7')!);
      expect(p.whiteChecks, 1);
    });

    test('shahu i tretë e mbaron lojën', () {
      final Position p = fromFen('4k3/8/8/8/8/8/8/4K3 w - - 0 1',
          Variant.threecheck)
        ..whiteChecks = 3;
      final GameStatus st = gameStatus(p);
      expect(st.over, isTrue);
      expect(st.result, '1-0');
      expect(st.reason, EndReason.threecheck);
    });
  });

  group('Antishah', () {
    test('të ngrënët është i detyrueshëm', () {
      final Position p =
          fromFen('8/8/8/3p4/4P3/8/8/8 w - - 0 1', Variant.antichess);
      final List<Move> moves = legalMoves(p);
      expect(moves.length, 1);
      expect(moves.first.uci, 'e4d5');
    });

    test('nuk ka shah, dhe mbreti mund të hahet', () {
      final Position p =
          fromFen('8/8/8/3k4/4P3/8/8/8 w - - 0 1', Variant.antichess);
      expect(inCheck(p), isFalse);
      expect(legalMoves(p).map((Move m) => m.uci), contains('e4d5'));
    });

    test('të mbetesh pa figura FITON', () {
      final Position p = fromFen('8/8/8/8/8/8/8/4k3 w - - 0 1',
          Variant.antichess);
      final GameStatus st = gameStatus(p);
      expect(st.over, isTrue);
      expect(st.result, '1-0');
      expect(st.reason, EndReason.antichess);
    });

    test('një ushtar mund të bëhet mbret', () {
      final Position p = fromFen('8/P7/8/8/8/8/8/8 w - - 0 1', Variant.antichess);
      expect(
        legalMoves(p).map((Move m) => m.promo).toSet(),
        <int>{queen, rook, bishop, knight, king},
      );
    });
  });

  group('kompjuteri', () {
    test('gjen matin në një lëvizje', () {
      final Position p = fromFen("7k/8/6K1/8/8/8/5Q2/8 w - - 0 1");
      final Move? m = chooseMove(p, levelId: 6, random: Random(1));
      expect(m, isNotNull);
      expect(gameStatus(makeMove(p, m!)).reason, EndReason.checkmate);
    });

    test('merr mbretëreshën falas në vend që të rrijë', () {
      // Kali i bardhë te d1 ha mbretëreshën e zezë te d8; asgjë s'e mbron.
      final Position p = fromFen('3q3k/8/8/8/8/8/8/3R2K1 w - - 0 1');
      final Move? m = chooseMove(p, levelId: 6, random: Random(1));
      expect(m?.uci, 'd1d8');
    });

    test('i forti e mund të dobëtin te një ndeshje e shkurtër', () {
      // Testi që zë gabimin e vërtetë të negamax-it: një shenjë e përmbysur nuk
      // rrëzon asgjë dhe nuk prodhon lëvizje të paligjshme — thjesht e bën
      // motorin të luajë keq, dhe VETËM një ndeshje e tregon.
      int strongWins = 0;
      for (int game = 0; game < 2; game++) {
        final Game g = Game();
        final Random rnd = Random(game);
        while (!g.isOver && g.moves.length < 80) {
          final bool strongToPlay = g.side == white;
          final Move? m = chooseMove(g.position,
              levelId: strongToPlay ? 6 : 1, random: rnd);
          if (m == null) break;
          g.apply(m);
        }
        final String? result = g.status.result;
        if (result == '1-0') strongWins++;
        // Nëse i forti humbet, diçka është përmbysur — kjo është shenja.
        expect(result, isNot('0-1'), reason: 'loja $game: i forti humbi');
      }
      expect(strongWins, greaterThan(0));
    });
  });
}
