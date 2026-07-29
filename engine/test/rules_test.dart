import 'package:spacechess_engine/spacechess_engine.dart';
import 'package:test/test.dart';

void main() {
  group('FEN', () {
    test('shkon e vjen pa ndryshuar', () {
      for (final String fen in <String>[
        startFen,
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
        '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
        'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3',
      ]) {
        expect(toFen(fromFen(fen)), fen);
      }
    });
  });

  group('en passant', () {
    test('kutia e kalimit vendoset vetëm pas një hapi të dyfishtë', () {
      final Game g = Game();
      g.applyUci('e2e4');
      expect(g.position.ep, parseSquare('e3'));
      g.applyUci('e7e6');
      expect(g.position.ep, isNull);
    });

    test('e ha ushtarin që kaloi, jo kutinë ku ndaloi', () {
      final Position p = fromFen(
          'rnbqkbnr/pppp1ppp/8/3Pp3/8/8/PPP1PPPP/RNBQKBNR w KQkq e6 0 3');
      final Move? m = moveFromUci(p, 'd5e6');
      expect(m, isNotNull);
      expect(m!.isEp, isTrue);

      final Position after = makeMove(p, m);
      expect(after.pieceAt(parseSquare('e6')), pawn);
      expect(after.pieceAt(parseSquare('e5')), empty);
    });

    test('nuk lejohet kur zbulon mbretin', () {
      // Mbreti i bardhë te h5, kali i zi te a5: e ngrënia në kalim do të hiqte
      // TË DY ushtarët nga rreshti i 5-të dhe do ta linte mbretin nën shah.
      // Ky është saktësisht rasti që një motor pa provë ligjshmërie e lejon.
      final Position p =
          fromFen('8/8/8/K1Pp3r/8/8/8/7k w - d6 0 1');
      expect(
        legalMoves(p).where((Move m) => m.isEp),
        isEmpty,
      );
    });
  });

  group('rokada', () {
    test('e vogla dhe e madhja te pozicioni i pastruar', () {
      final Position p =
          fromFen('r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1');
      final Set<String> uci =
          legalMoves(p).where((Move m) => m.castle != null).map((Move m) => m.uci).toSet();
      expect(uci, <String>{'e1g1', 'e1c1'});
    });

    test('nuk bëhet kur mbreti kalon nëpër kuti të sulmuar', () {
      // Kali i zi te f8 mbulon f1 → rokada e vogël bie, e madhja mbetet.
      final Position p = fromFen('5r2/8/8/8/8/8/8/R3K2R w KQ - 0 1');
      final Set<String> uci = legalMoves(p)
          .where((Move m) => m.castle != null)
          .map((Move m) => m.uci)
          .toSet();
      expect(uci, <String>{'e1c1'});
    });

    test('nuk bëhet nga shahu', () {
      final Position p = fromFen('4r3/8/8/8/8/8/8/R3K2R w KQ - 0 1');
      expect(legalMoves(p).where((Move m) => m.castle != null), isEmpty);
    });

    test('e drejta vdes kur hahet kali mbi kutinë e vet', () {
      final Position p =
          fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      final Position after = makeMove(p, moveFromUci(p, 'a1a8')!);
      expect(after.blackQueenRook, isNull);
      expect(after.blackKingRook, isNotNull);
    });
  });

  group('fundi i lojës', () {
    test('mat me dy lëvizje', () {
      final Game g = Game();
      for (final String m in <String>['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
        expect(g.applyUci(m), isTrue, reason: m);
      }
      expect(g.status.over, isTrue);
      expect(g.status.result, '0-1');
      expect(g.status.reason, EndReason.checkmate);
      expect(g.sanMoves.last, 'Qh4#');
    });

    test('pat', () {
      final Position p = fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
      final GameStatus st = gameStatus(p);
      expect(st.over, isTrue);
      expect(st.result, '1/2-1/2');
      expect(st.reason, EndReason.stalemate);
    });

    test('material i pamjaftueshëm', () {
      expect(insufficientMaterial(fromFen('8/8/4k3/8/8/4K3/8/8 w - - 0 1')), isTrue);
      expect(insufficientMaterial(fromFen('8/8/4k3/8/8/4KB2/8/8 w - - 0 1')), isTrue);
      expect(insufficientMaterial(fromFen('8/8/4k3/8/8/4KN2/8/8 w - - 0 1')), isTrue);
      // Dy kalorës nuk janë «të pamjaftueshëm» sipas rregullit të FIDE-s:
      // mati është i pamundur me lojë të detyruar, por jo i pamundur fare.
      expect(insufficientMaterial(fromFen('8/8/4k3/8/8/3NKN2/8/8 w - - 0 1')), isFalse);
      expect(insufficientMaterial(fromFen('8/8/4k3/8/8/4KR2/8/8 w - - 0 1')), isFalse);
    });

    test('50 lëvizje', () {
      final Position p = fromFen('8/8/4k3/8/8/4K3/7R/8 w - - 100 60');
      expect(gameStatus(p).reason, EndReason.fifty);
    });

    test('përsëritja trefishe kërkon historinë, jo pozicionin', () {
      final Game g = Game();
      // Kalorësit shkojnë e kthehen derisa i njëjti pozicion shfaqet tri herë.
      for (final String m in <String>[
        'g1f3', 'g8f6', 'f3g1', 'f6g8', //
        'g1f3', 'g8f6', 'f3g1', 'f6g8',
      ]) {
        expect(g.applyUci(m), isTrue, reason: m);
      }
      expect(g.status.reason, EndReason.repetition);
      expect(g.status.result, '1/2-1/2');
    });
  });

  group('kalimi në figurë', () {
    test('katër zgjedhje, dhe secila jep një figurë tjetër', () {
      final Position p = fromFen('8/P6k/8/8/8/8/8/7K w - - 0 1');
      final List<Move> promos =
          legalMoves(p).where((Move m) => m.promo != 0).toList();
      expect(promos.length, 4);
      expect(
        promos.map((Move m) => makeMove(p, m).pieceAt(parseSquare('a8'))).toSet(),
        <int>{queen, rook, bishop, knight},
      );
    });
  });

  group('SAN', () {
    test('dyzimi shkruhet vetëm kur duhet', () {
      // Dy kalorës te b1 dhe f3 shkojnë të dy te d2.
      final Position p = fromFen('4k3/8/8/8/8/5N2/8/1N2K3 w - - 0 1');
      final List<String> san = legalMoves(p)
          .where((Move m) =>
              m.to == parseSquare('d2') && p.pieceAt(m.from).abs() == knight)
          .map((Move m) => toSan(p, m))
          .toList();
      expect(san.toSet(), <String>{'Nbd2', 'Nfd2'});

      // Mbreti shkon te e njëjta kuti, dhe pikërisht ai NUK dyzohet: dyzimi
      // krahason vetëm figura të të njëjtit lloj.
      final Move kingMove = legalMoves(p).firstWhere(
          (Move m) => m.to == parseSquare('d2') && p.pieceAt(m.from).abs() == king);
      expect(toSan(p, kingMove), 'Kd2');
    });

    test('shahu dhe mati marrin shenjën e vet', () {
      // Mbreti i bardhë te g6 është pjesë e matit: ai i mbyll h7/g7/g8. Pa të,
      // Qf8 do të ishte thjesht shah — dhe pikërisht kjo është arsyeja pse
      // prapashtesa duhet llogaritur nga pozicioni, jo hamendësuar.
      final Position p = fromFen('7k/8/6K1/8/8/8/5Q2/8 w - - 0 1');
      expect(toSan(p, moveFromUci(p, 'f2f8')!), 'Qf8#');
      expect(toSan(p, moveFromUci(p, 'f2f6')!), 'Qf6+');
    });

    test('rokada është O-O dhe O-O-O', () {
      final Position p =
          fromFen('r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1');
      expect(toSan(p, moveFromUci(p, 'e1g1')!), 'O-O');
      expect(toSan(p, moveFromUci(p, 'e1c1')!), 'O-O-O');
    });
  });

  group('Game', () {
    test('një lëvizje e paligjshme nuk ndryshon asgjë', () {
      final Game g = Game();
      final String before = g.fen;
      expect(g.applyUci('e2e5'), isFalse);
      expect(g.fen, before);
      expect(g.moves, isEmpty);
    });

    test('kthimi mbrapsht e rikthen pozicionin pikë për pikë', () {
      final Game g = Game();
      final String start = g.fen;
      g.applyUci('e2e4');
      g.applyUci('e7e5');
      final String after = g.fen;
      g.applyUci('g1f3');
      expect(g.undo(), isTrue);
      expect(g.fen, after);
      g.undo();
      g.undo();
      expect(g.fen, start);
      expect(g.undo(), isFalse);
    });

    test('teksti PGN numërohet nga një', () {
      final Game g = Game();
      g.applyUci('e2e4');
      g.applyUci('e7e5');
      g.applyUci('g1f3');
      expect(g.moveText, '1. e4 e5 2. Nf3');
    });
  });
}
