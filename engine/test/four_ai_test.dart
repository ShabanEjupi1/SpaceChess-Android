import 'dart:math';

import 'package:spacechess_engine/spacechess_engine.dart';
import 'package:test/test.dart';

/// Një tabelë bosh me katër mbretër, si te `four_test.dart`: pa mbret,
/// `fourInCheck` hesht dhe gjysma e vlerësimit të trurit nuk provohet dot.
FourPosition _empty() {
  final FourPosition p = FourPosition();
  for (int i = 0; i < 4; i++) {
    p.players[i].kingSideRook = null;
    p.players[i].queenSideRook = null;
  }
  return p;
}

void _put(FourPosition p, int file, int rank, int piece, int color) {
  p.board[fourSq(file, rank)] = fourCode(piece, color);
}

/// 🚨 Fara e ngulur. Truri ka zhurmë me qëllim ([FourBot.noise]) që dy ndeshje
/// të mos jenë e njëjta ndeshje — dhe pikërisht ajo zhurmë do t'i bënte këto
/// prova të binin një herë në njëzet, pra do të lexoheshin si «CI e prishur».
FourBot _bot() => FourBot(random: Random(7));

void main() {
  group('Truri i Katërshit', () {
    test('nuk kthen lëvizje kur nuk ka asnjë të ligjshme', () {
      final FourPosition p = _empty();
      // Vetëm mbretërit e të tjerëve; i kuqi nuk ka asnjë figurë.
      _put(p, 7, 13, king, yellow);
      _put(p, 0, 7, king, blue);
      _put(p, 13, 7, king, green);
      expect(_bot().pick(p), isNull);
    });

    test('ha figurën e madhe kur e ka falas', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 6, 6, rook, red);
      _put(p, 6, 10, queen, yellow);   // 9 pikë, e pambrojtur
      _put(p, 3, 6, pawn, blue);       //  1 pikë, po ashtu e pambrojtur
      _put(p, 7, 13, king, yellow);
      _put(p, 0, 7, king, blue);
      _put(p, 13, 7, king, green);

      final FourMove? m = _bot().pick(p);
      expect(m, isNotNull);
      expect(fourFile(m!.to), 6);
      expect(fourRank(m.to), 10, reason: 'mbretëresha vlen nëntë, pengu një');
    });

    test('nuk e fal ngrënien që e kthen menjëherë një i TRETË', () {
      // 🔑 Kjo është prova që e ndan Katërshin nga shahu dylojtarësh. Kalorësi
      // im mund të hajë një peng të verdhë — po te ajo kuti e pret një peng
      // JESHIL. Te një lojë dylojtarëshe kjo do të ishte thjesht «e mbrojtur»;
      // këtu mbrojtësi është një palë e tretë krejt tjetër.
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 6, 5, knight, red);
      _put(p, 7, 7, pawn, yellow);     // caku: 1 pikë
      _put(p, 8, 8, pawn, green);      // e mbron kutinë 7,7 (pengu jeshil ha nga lindja→perëndim)
      _put(p, 7, 13, king, yellow);
      _put(p, 0, 7, king, blue);
      _put(p, 13, 7, king, green);

      final FourMove? m = _bot().pick(p);
      expect(m, isNotNull);
      final bool hengri = fourFile(m!.to) == 7 && fourRank(m.to) == 7;
      expect(hengri, isFalse,
          reason: 'kalorësi (3 pikë) për një peng (1 pikë) nën një të tretin');
    });

    test('nuk e lë mbretin nën shah kur ka rrugëdalje', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 7, 5, rook, blue);       // shah te shtylla e mbretit të kuq
      _put(p, 7, 13, king, yellow);
      _put(p, 0, 7, king, blue);
      _put(p, 13, 7, king, green);

      final FourMove? m = _bot().pick(p);
      expect(m, isNotNull);
      final FourPosition after = makeFourMove(p, m!);
      expect(fourInCheck(after, red), isFalse);
    });

    test('një ndeshje e plotë mbaron dhe asnjë radhë nuk ngec', () {
      // Kjo është rrjeta e vërtetë: truri luan të katër anët derisa loja të
      // mbarojë. Nëse `pick` kthen një lëvizje të paligjshme, `makeFourMove`
      // e prish tabelën dhe `fourStatus` nuk mbaron kurrë — ndaj kufiri.
      FourPosition p = fourStart();
      final FourBot bot = _bot();
      int turns = 0;
      while (!fourStatus(p).over && turns < 600) {
        final FourMove? m = bot.pick(p);
        if (m == null) break;
        expect(fourLegalMoves(p, p.turn), contains(m));
        p = makeFourMove(p, m);
        turns++;
      }
      expect(fourStatus(p).over, isTrue,
          reason: 'ndeshja duhet të mbarojë brenda 600 radhësh');
    });
  });
}
