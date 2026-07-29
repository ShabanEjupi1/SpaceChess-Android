import 'package:spacechess_engine/spacechess_engine.dart';
import 'package:test/test.dart';

/// Pozicionet standarde të perft-it. Numrat NUK janë llogaritur nga ky motor —
/// janë vlerat publike të Chess Programming Wiki-t, të njëjtat që përdor çdo
/// motor tjetër. Kjo është e gjithë pika: testi mat motorin kundrejt shahut, jo
/// kundrejt vetes.
void main() {
  group('perft — pozicioni fillestar', () {
    final Position start = fromFen(startFen);

    test('thellësia 1 = 20', () => expect(perft(start, 1), 20));
    test('thellësia 2 = 400', () => expect(perft(start, 2), 400));
    test('thellësia 3 = 8902', () => expect(perft(start, 3), 8902));
    test('thellësia 4 = 197281', () => expect(perft(start, 4), 197281));
  });

  group('perft — Kiwipete', () {
    // Pozicioni klasik i gabimeve: rokadë të dyja anët, ushtarë të lidhur,
    // en passant. Nëse rokada apo shahu i zbuluar janë të gabuara, bien këtu.
    final Position p = fromFen(
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1');

    test('thellësia 1 = 48', () => expect(perft(p, 1), 48));
    test('thellësia 2 = 2039', () => expect(perft(p, 2), 2039));
    test('thellësia 3 = 97862', () => expect(perft(p, 3), 97862));
  });

  group('perft — pozicioni 3 (fundlojë me en passant)', () {
    final Position p = fromFen('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1');

    test('thellësia 1 = 14', () => expect(perft(p, 1), 14));
    test('thellësia 3 = 2812', () => expect(perft(p, 3), 2812));
    test('thellësia 4 = 43238', () => expect(perft(p, 4), 43238));
  });

  group('perft — pozicioni 4 (kalim në figurë me shah)', () {
    final Position p = fromFen(
        'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1');

    test('thellësia 1 = 6', () => expect(perft(p, 1), 6));
    test('thellësia 3 = 9467', () => expect(perft(p, 3), 9467));
  });

  group('perft — pozicioni 5', () {
    final Position p = fromFen(
        'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8');

    test('thellësia 1 = 44', () => expect(perft(p, 1), 44));
    test('thellësia 3 = 62379', () => expect(perft(p, 3), 62379));
  });

  group('perft — pozicioni 6', () {
    final Position p = fromFen(
        'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10');

    test('thellësia 1 = 46', () => expect(perft(p, 1), 46));
    test('thellësia 3 = 89890', () => expect(perft(p, 3), 89890));
  });

  group('perft — Chess960', () {
    // Rokada te Chess960 është vendi ku ky motor ndryshon më shumë nga një motor
    // i zakonshëm, ndaj i duhet numri i vet. Pozicioni 518 është shahu standard,
    // pra duhet të japë saktësisht numrat e fillimit — dhe kjo e provon se rruga
    // e Chess960-s nuk e prish shahun e zakonshëm.
    test('id 518 është rreshtimi standard', () {
      expect(chess960Fen(518).split(' ').first,
          startFen.split(' ').first);
    });

    test('perft 4 te id 518 = 197281', () {
      expect(perft(fromFen(chess960Fen(518), Variant.chess960), 4), 197281);
    });

    test('të 960 pozicionet janë të ligjshme dhe kanë 8 figura për rresht', () {
      for (int id = 0; id < 960; id++) {
        final String back = chess960Fen(id).split('/').first;
        expect(back.length, 8, reason: 'id $id');
        // Mbreti duhet të rrijë MES dy kalëve, ndryshe rokada nuk ka kuptim.
        final int k = back.indexOf('k');
        final int r1 = back.indexOf('r');
        final int r2 = back.lastIndexOf('r');
        expect(r1 < k && k < r2, isTrue, reason: 'id $id: $back');
        // Oficerët në kuti me ngjyra të kundërta.
        final int b1 = back.indexOf('b');
        final int b2 = back.lastIndexOf('b');
        expect(b1.isEven, isNot(b2.isEven), reason: 'id $id: $back');
      }
    });
  });
}
