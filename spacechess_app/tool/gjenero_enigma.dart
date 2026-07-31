/// Gjeneruesi i enigmave «mat në 1» dhe «mat në 2».
///
/// 🔑 Asnjë enigmë nuk shkruhet me dorë. Pozicionet ndërtohen rastësisht dhe
/// pastaj MOTORI vetë provon nëse mati është i detyruar; ruhen vetëm ato që e
/// kalojnë provën. Kjo është e njëjta zgjedhje si te gjeneruesi i niveleve të
/// Girih-it, dhe për të njëjtën arsye: një enigmë e pasaktë e bën lojtarin të
/// mendojë se ai gaboi, dhe ai ka të drejtë.
///
/// Kushtet që duhet të plotësojë një enigmë e ruajtur:
///   1. Pozicioni është i ligjshëm dhe i bardhi luan.
///   2. I bardhi NUK është tashmë duke dhënë shah — përndryshe gjysma e
///      enigmave do të ishin thjesht «merre mbretin».
///   3. Ka SAKTËSISHT NJË lëvizje të parë që çon në mat të detyruar. Pa
///      unicitet, lojtari gjen një rrugë tjetër, loja ia refuzon, dhe ankesa
///      është e drejtë.
///   4. Te «mat në 2», çdo përgjigje e të ziut duhet të lejojë mat — jo vetëm
///      njëra. «I detyruar» do të thotë pikërisht kjo.
///
/// Ekzekutimi (mbi Ampere, ku është Dart-i):
///   dart run tool/gjenero_enigma.dart --prova=40000 > lib/data/enigmat.g.dart
library;

import 'dart:io';
import 'dart:math';

import 'package:spacechess_engine/spacechess_engine.dart';

void main(List<String> args) {
  final int prova = int.parse(
      args.firstWhere((String a) => a.startsWith('--prova='), orElse: () => '--prova=40000')
          .split('=')[1]);
  // Fara e ngulur: i njëjti urdhër jep të njëjtat enigma, pra një rindërtim
  // nuk ia ndërron enigmat askujt që i ka zgjidhur tashmë.
  final Random r = Random(20260801);

  final List<_Enigma> gjetura = <_Enigma>[];
  final Set<String> pare = <String>{};

  for (int i = 0; i < prova && gjetura.length < 60; i++) {
    final Position? p = _pozicionRastesor(r);
    if (p == null) continue;
    final String fen = toFen(p);
    if (!pare.add(fen)) continue;

    final _Enigma? e = _provo(p);
    if (e != null) gjetura.add(e);
  }

  // Renditja nga më e lehta te më e vështira: mat në 1 para mat në 2, dhe
  // brenda secilës, sa më pak figura aq më herët.
  gjetura.sort((_Enigma a, _Enigma b) {
    final int c = a.hapa.compareTo(b.hapa);
    return c != 0 ? c : a.figura.compareTo(b.figura);
  });

  stderr.writeln('u gjetën ${gjetura.length} enigma '
      '(${gjetura.where((_Enigma e) => e.hapa == 1).length} me një hap)');

  final StringBuffer b = StringBuffer()
    ..writeln('// I GJENERUAR nga tool/gjenero_enigma.dart — mos e ndrysho me dorë.')
    ..writeln('//')
    ..writeln('// Çdo zë është provuar nga vetë motori: mati është i DETYRUAR dhe')
    ..writeln('// lëvizja e parë është e VETMJA që e jep. Shih komentin e gjeneruesit.')
    ..writeln('library;')
    ..writeln()
    ..writeln('/// Një enigmë: pozicioni, zgjidhja dhe sa lëvizje të bardha duhen.')
    ..writeln('class Enigma {')
    ..writeln('  const Enigma(this.fen, this.zgjidhja, this.hapa);')
    ..writeln()
    ..writeln('  /// Pozicioni i nisjes. I bardhi luan gjithmonë.')
    ..writeln('  final String fen;')
    ..writeln()
    ..writeln('  /// Lëvizja e parë e të bardhit, në UCI. Është e vetmja që fiton.')
    ..writeln('  final String zgjidhja;')
    ..writeln()
    ..writeln('  /// 1 ose 2 — sa lëvizje të bardha deri te mati.')
    ..writeln('  final int hapa;')
    ..writeln('}')
    ..writeln()
    ..writeln('const List<Enigma> enigmat = <Enigma>[');
  for (final _Enigma e in gjetura) {
    b.writeln("  Enigma('${e.fen}', '${e.zgjidhja}', ${e.hapa}),");
  }
  b.writeln('];');
  stdout.write(b);
}

class _Enigma {
  _Enigma(this.fen, this.zgjidhja, this.hapa, this.figura);
  final String fen;
  final String zgjidhja;
  final int hapa;
  final int figura;
}

/// Ndërton një pozicion fundloje rastësor: dy mbretër plus 1–3 figura të bardha
/// dhe 0–2 të zeza. Pa ushtarë — një ushtar e sjell promovimin, rregullin e 50
/// lëvizjeve dhe kalimin en passant në një enigmë që duhet të lexohet për dy
/// sekonda.
Position? _pozicionRastesor(Random r) {
  final Position p = Position();
  final Set<int> zena = <int>{};

  int? kuti() {
    for (int nderrimi = 0; nderrimi < 40; nderrimi++) {
      final int q = sq(r.nextInt(8), r.nextInt(8));
      if (zena.add(q)) return q;
    }
    return null;
  }

  final int? kb = kuti();
  final int? kz = kuti();
  if (kb == null || kz == null) return null;
  // Mbretërit nuk qëndrojnë dot ngjitur: pozicioni do të ishte i paligjshëm.
  if ((kb ~/ 10 - kz ~/ 10).abs() <= 1 && (kb % 10 - kz % 10).abs() <= 1) {
    return null;
  }
  p.board[kb] = king;
  p.board[kz] = -king;

  const List<int> llojet = <int>[queen, rook, bishop, knight];
  final int sasiaBardhe = 1 + r.nextInt(3);
  for (int i = 0; i < sasiaBardhe; i++) {
    final int? q = kuti();
    if (q == null) return null;
    p.board[q] = llojet[r.nextInt(llojet.length)];
  }
  final int sasiaZeze = r.nextInt(3);
  for (int i = 0; i < sasiaZeze; i++) {
    final int? q = kuti();
    if (q == null) return null;
    p.board[q] = -llojet[r.nextInt(llojet.length)];
  }

  p.side = white;
  p.halfmove = 0;
  p.fullmove = 1;
  // Asnjë rokadë: mbretërit janë vendosur kudo, ndaj çdo e drejtë rokade do të
  // ishte gënjeshtër që FEN-i do ta bartte.
  return p;
}

/// Kthen enigmën nëse [p] është mat i detyruar në një ose dy lëvizje, me
/// lëvizje të parë të vetme. Ndryshe `null`.
_Enigma? _provo(Position p) {
  // Një pozicion ku i ziu është tashmë në shah nuk është pozicion i ligjshëm me
  // të bardhin në lëvizje.
  if (inCheck(p, black)) return null;
  if (inCheck(p, white)) return null;

  final List<Move> tonat = legalMoves(p);
  if (tonat.isEmpty) return null;

  final List<Move> matNjeHap = <Move>[];
  final List<Move> matDyHapa = <Move>[];

  for (final Move m in tonat) {
    final Position pas = makeMove(p, m);
    final List<Move> pergjigjet = legalMoves(pas);

    if (pergjigjet.isEmpty) {
      // Pa përgjigje: mat nëse është shah, pat nëse jo. Pati nuk është fitore.
      if (inCheck(pas, black)) matNjeHap.add(m);
      continue;
    }

    // Mat në dy: ÇDO përgjigje e të ziut duhet të lejojë një mat.
    bool teGjitha = true;
    for (final Move pergj in pergjigjet) {
      final Position pas2 = makeMove(pas, pergj);
      final bool gjendet = legalMoves(pas2).any((Move mbyllja) {
        final Position fundi = makeMove(pas2, mbyllja);
        return legalMoves(fundi).isEmpty && inCheck(fundi, black);
      });
      if (!gjendet) {
        teGjitha = false;
        break;
      }
    }
    if (teGjitha) matDyHapa.add(m);
  }

  // Uniciteti matet brenda vështirësisë së saj: nëse ka një mat në një hap,
  // enigma është ajo, dhe çdo mat në dy hapa është thjesht një rrugë më e gjatë.
  if (matNjeHap.length == 1) {
    return _Enigma(toFen(p), matNjeHap.first.uci, 1, _sasiaEFigurave(p));
  }
  if (matNjeHap.isEmpty && matDyHapa.length == 1) {
    return _Enigma(toFen(p), matDyHapa.first.uci, 2, _sasiaEFigurave(p));
  }
  return null;
}

int _sasiaEFigurave(Position p) {
  int n = 0;
  for (int i = 0; i < 120; i++) {
    if (p.board[i] != off && p.board[i] != empty) n++;
  }
  return n;
}
