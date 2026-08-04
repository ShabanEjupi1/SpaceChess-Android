import 'package:spacechess_engine/spacechess_engine.dart';
import 'package:test/test.dart';

/// Ndihmës: vendos një tabelë bosh me vetëm ato figura që i duhen testit.
/// Katër mbretërit janë GJITHMONË aty — pa mbret, `fourInCheck` kthen false dhe
/// gjysma e rregullave hesht.
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

int _at(FourPosition p, int file, int rank) => p.board[fourSq(file, rank)];

void main() {
  group('Tabela', () {
    test('katër qoshet 3×3 nuk ekzistojnë', () {
      for (final List<int> c in <List<int>>[
        <int>[0, 0], <int>[2, 2], <int>[0, 13], <int>[2, 11],
        <int>[13, 0], <int>[11, 2], <int>[13, 13], <int>[11, 11],
      ]) {
        expect(fourOnBoard(c[0], c[1]), isFalse, reason: '${c[0]},${c[1]}');
      }
    });

    test('krahët e kryqit ekzistojnë', () {
      for (final List<int> c in <List<int>>[
        <int>[3, 0], <int>[10, 0], <int>[0, 3], <int>[0, 10],
        <int>[7, 7], <int>[6, 6], <int>[13, 10], <int>[10, 13],
      ]) {
        expect(fourOnBoard(c[0], c[1]), isTrue, reason: '${c[0]},${c[1]}');
      }
    });

    test('qoshet janë roje te vargu, njësoj si jashtë tabelës', () {
      final FourPosition p = fourStart();
      expect(p.board[fourSq(0, 0)], fourOff);
      expect(p.board[fourSq(13, 13)], fourOff);
    });
  });

  group('Rreshtimi fillestar', () {
    final FourPosition p = fourStart();

    test('64 figura: 16 për secilën ushtri', () {
      final List<int> count = <int>[0, 0, 0, 0];
      for (int i = 0; i < fourCells; i++) {
        final int c = p.board[i];
        if (c != fourOff && c != empty) count[colorOf(c)]++;
      }
      expect(count, <int>[16, 16, 16, 16]);
    });

    test('mbreti i kuq dhe ai i verdhë janë te i njëjti skedar', () {
      final int kr = p.kingSquareOf(red);
      final int ky = p.kingSquareOf(yellow);
      expect(fourFile(kr), fourFile(ky));
      expect(fourRank(kr), 0);
      expect(fourRank(ky), 13);
    });

    test('mbreti blu dhe ai jeshil janë te i njëjti rresht', () {
      final int kb = p.kingSquareOf(blue);
      final int kg = p.kingSquareOf(green);
      expect(fourRank(kb), fourRank(kg));
      expect(fourFile(kb), 0);
      expect(fourFile(kg), 13);
    });

    test('e kuqja ecën e para', () => expect(p.turn, red));

    test('secila ushtri ka të njëjtin numër lëvizjesh — pozicioni është simetrik', () {
      final Set<int> counts = <int>{
        for (int c = 0; c < 4; c++) fourLegalMoves(p, c).length,
      };
      expect(counts.length, 1, reason: 'të katër duhet të kenë njësoj: $counts');
    });

    test('hapja ka 20 lëvizje, jo 20+4 — qoshet e prera i hanë katër kërcime', () {
      // 8 pengje × 2 hapa = 16. Kalorësit japin vetëm 2 secili e jo 4:
      // nga (4,0) kutitë (3,2) e (5,2) janë të lira, (6,1) e zë pengu, dhe
      // (2,1) NUK EKZISTON — file<3 dhe rank<3 është qoshe e prerë. Njësoj
      // simetrikisht te (9,0). Prandaj 16 + 4 = 20.
      expect(fourLegalMoves(p, red).length, 20);
    });
  });

  group('Radha', () {
    test('e kuqe → blu → e verdhë → jeshile', () {
      FourPosition p = fourStart();
      final List<int> order = <int>[p.turn];
      for (int i = 0; i < 4; i++) {
        p = makeFourMove(p, fourLegalMoves(p).first);
        order.add(p.turn);
      }
      expect(order, <int>[red, blue, yellow, green, red]);
    });
  });

  group('Pengjet ecin drejt qendrës', () {
    test('e kuqja veriut, blu lindjes, e verdha jugut, jeshilja perëndimit', () {
      final Map<int, List<int>> nga = <int, List<int>>{
        red: <int>[5, 1], blue: <int>[1, 5], yellow: <int>[5, 12], green: <int>[12, 5],
      };
      final Map<int, List<int>> te = <int, List<int>>{
        red: <int>[5, 2], blue: <int>[2, 5], yellow: <int>[5, 11], green: <int>[11, 5],
      };
      for (final int color in <int>[red, blue, yellow, green]) {
        final FourPosition p = _empty();
        for (int c = 0; c < 4; c++) {
          _put(p, c == red ? 7 : (c == yellow ? 7 : (c == blue ? 0 : 13)),
              c == red ? 0 : (c == yellow ? 13 : 7), king, c);
        }
        _put(p, nga[color]![0], nga[color]![1], pawn, color);
        p.turn = color;
        final List<FourMove> ms = fourLegalMoves(p)
            .where((FourMove m) => m.from == fourSq(nga[color]![0], nga[color]![1]))
            .toList();
        expect(ms.map((FourMove m) => m.to),
            contains(fourSq(te[color]![0], te[color]![1])),
            reason: fourColorNames[color]);
      }
    });

    test('hapi i dyfishtë vetëm nga rreshti i vet i nisjes', () {
      final FourPosition p = fourStart();
      final List<FourMove> dyfishe =
          fourLegalMoves(p, red).where((FourMove m) => m.isDouble).toList();
      expect(dyfishe.length, 8);
      for (final FourMove m in dyfishe) {
        expect(fourRank(m.from), 1);
        expect(fourRank(m.to), 3);
      }
    });
  });

  group('Promovimi', () {
    test('pengu i kuq bëhet figurë te rreshti i 11-të, jo te buza', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 0, 7, king, blue);
      _put(p, 7, 13, king, yellow);
      _put(p, 13, 7, king, green);
      _put(p, 5, 9, pawn, red);
      p.turn = red;

      final List<FourMove> ms = fourLegalMoves(p)
          .where((FourMove m) => m.from == fourSq(5, 9))
          .toList();
      // Një hap deri te rreshti 10 → katër promovime, asnjë lëvizje e thjeshtë.
      expect(ms.length, 4);
      expect(ms.every((FourMove m) => m.promo != 0), isTrue);
      expect(ms.map((FourMove m) => m.promo).toSet(),
          <int>{queen, rook, bishop, knight});
    });

    test('nën rreshtin e promovimit është lëvizje e zakonshme', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 5, 8, pawn, red);
      p.turn = red;
      final List<FourMove> ms =
          fourLegalMoves(p).where((FourMove m) => m.from == fourSq(5, 8)).toList();
      expect(ms.length, 1);
      expect(ms.single.promo, 0);
    });
  });

  group('Qoshet ndalin rrëshqitësit', () {
    test('kali nuk kalon përtej qoshes së prerë', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      // Kala te 3,1 që shikon perëndimit: 2,1 është qoshe e prerë.
      _put(p, 3, 1, rook, red);
      p.turn = red;
      final Set<int> destinacione = fourLegalMoves(p)
          .where((FourMove m) => m.from == fourSq(3, 1))
          .map((FourMove m) => m.to)
          .toSet();
      expect(destinacione.any((int s) => fourFile(s) < 3 && fourRank(s) < 3), isFalse);
    });
  });

  group('Shahu dhe eliminimi', () {
    test('mati e nxjerr lojtarin jashtë dhe loja vazhdon me tre', () {
      // Mbreti blu te 0,3 — qoshja e brendshme e krahut të majtë. Ka SAKTËSISHT
      // tri kuti ikjeje: (0,4), (1,3), (1,4). Kutitë (0,2) dhe (1,2) nuk
      // ekzistojnë, sepse janë brenda qoshes 3×3 të prerë.
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 7, 13, king, yellow);
      _put(p, 13, 7, king, green);
      _put(p, 0, 3, king, blue);
      _put(p, 5, 4, rook, red);      // mbulon rreshtin 4 → (0,4) dhe (1,4)
      _put(p, 6, 7, rook, red);      // do të zbresë te rreshti 3
      p.turn = red;

      // Para matit blu ende luan, dhe vetëm te (1,3).
      final List<FourMove> ikjet = fourLegalMoves(p, blue).toList();
      expect(ikjet.length, 1);
      expect(ikjet.single.to, fourSq(1, 3));

      // Kala zbret te (6,3): shah te rreshti 3, dhe mbulon edhe (1,3).
      final FourMove mat = fourLegalMoves(p)
          .firstWhere((FourMove m) => m.from == fourSq(6, 7) && m.to == fourSq(6, 3));
      final FourPosition after = makeFourMove(p, mat);

      expect(after.players[blue].alive, isFalse, reason: 'blu duhej matuar');
      expect(after.players[red].points, matePoints);
      expect(after.living.length, 3);
      expect(after.turn, yellow, reason: 'radha kapërcen blunë e eliminuar');
    });

    test('mbreti i eliminuari hiqet, figurat e tij mbeten si pre', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 0, 7, king, blue);
      _put(p, 5, 5, rook, blue);
      fourEliminate(p, blue);
      expect(p.kingSquareOf(blue), -1);
      expect(_at(p, 5, 5), fourCode(rook, blue));
    });

    test('ngrënia e figurës së një lojtari të eliminuar jep prapë pikë', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 7, 13, king, yellow);
      _put(p, 13, 7, king, green);
      _put(p, 5, 5, queen, blue);
      _put(p, 5, 3, rook, red);
      fourEliminate(p, blue);
      p.turn = red;

      final FourMove hane = fourLegalMoves(p)
          .firstWhere((FourMove m) => m.to == fourSq(5, 5));
      final FourPosition after = makeFourMove(p, hane);
      expect(after.players[red].points, piecePoints[queen]);
    });
  });

  group('Pikët', () {
    test('vlerat janë rregull loje, jo pesha vlerësimi', () {
      expect(piecePoints[pawn], 1);
      expect(piecePoints[knight], 3);
      expect(piecePoints[bishop], 5);
      expect(piecePoints[rook], 5);
      expect(piecePoints[queen], 9);
    });

    test('fituesi del nga pikët', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      p.players[blue].alive = false;
      p.players[yellow].alive = false;
      p.players[green].alive = false;
      p.players[red].points = 5;
      p.players[blue].points = 40;   // u eliminua, por hëngri shumë
      final FourStatus st = fourStatus(p);
      expect(st.over, isTrue);
      expect(st.winner, blue);
    });

    test('gjendja nuk i ndryshon pikët sa herë lexohet', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      p.players[blue].alive = false;
      p.players[yellow].alive = false;
      p.players[green].alive = false;
      fourStatus(p);
      final int pas = p.players[red].points;
      fourStatus(p);
      fourStatus(p);
      expect(p.players[red].points, pas);
    });
  });

  group('Rokada', () {
    test('e kuqja bën rokadë nga të dyja anët te pozicioni i pastruar', () {
      final FourPosition p = fourStart();
      // Zbraz rreshtin e parë mes mbretit dhe të dy kalave.
      for (final int f in <int>[4, 5, 6, 8, 9]) {
        p.board[fourSq(f, 0)] = empty;
      }
      final List<FourMove> rokadat =
          fourLegalMoves(p, red).where((FourMove m) => m.isCastle).toList();
      expect(rokadat.length, 2);
    });

    test('rokada ndalet kur mbreti kalon nëpër kuti të sulmuar', () {
      final FourPosition p = fourStart();
      for (final int f in <int>[8, 9]) {
        p.board[fourSq(f, 0)] = empty;
      }
      // Kala jeshile që mbulon skedarin 8 — kutinë që kalon mbreti.
      p.board[fourSq(8, 1)] = empty;
      _put(p, 8, 6, rook, green);
      final List<FourMove> rokadat =
          fourLegalMoves(p, red).where((FourMove m) => m.isCastle).toList();
      expect(rokadat, isEmpty);
    });

    test('lëvizja e mbretit e humb të drejtën e rokadës', () {
      FourPosition p = fourStart();
      for (final int f in <int>[8, 9]) {
        p.board[fourSq(f, 0)] = empty;
      }
      final int k = p.kingSquareOf(red);
      p.board[fourSq(fourFile(k), 1)] = empty;
      p = makeFourMove(p, FourMove(from: k, to: fourSq(fourFile(k), 1)));
      expect(p.players[red].kingSideRook, isNull);
      expect(p.players[red].queenSideRook, isNull);
    });
  });

  group('Ligjshmëria', () {
    test('nuk lejohet lëvizje që e lë mbretin tënd nën shah', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 7, 3, bishop, red);      // mbulon mbretin nga kala jeshile
      _put(p, 7, 9, rook, green);
      p.turn = red;
      final bool ka = fourLegalMoves(p)
          .any((FourMove m) => m.from == fourSq(7, 3) && fourFile(m.to) != 7);
      expect(ka, isFalse, reason: 'oficeri është i lidhur');
    });

    test('sulmi vjen vetëm nga lojtarët e gjallë', () {
      final FourPosition p = _empty();
      _put(p, 7, 0, king, red);
      _put(p, 7, 9, rook, green);
      expect(fourInCheck(p, red), isTrue);
      fourEliminate(p, green);
      expect(fourInCheck(p, red), isFalse,
          reason: 'figurat e një lojtari të nxjerrë jashtë nuk sulmojnë më');
    });
  });
}
