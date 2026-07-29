import 'board.dart';

/// Një radhë e vetme e shahut.
///
/// [captured] mban figurën e ngrënë ose [empty] kur s'u hëngër asgjë — dhe kjo
/// funksionon pikërisht sepse `empty == 0` nuk është kurrë vlerë e ligjshme
/// figure. Kështu nuk duhet asnjë fushë e dytë «a hëngri?» që mund të mos
/// përputhet me të parën.
///
/// 🔑 Te rokada, [to] është gjithmonë kutia ku përfundon MBRETI (g/c), kurrë
/// kutia e kalit. Pa këtë rregull, çdo copë tjetër e kodit — ndërfaqja, SAN-i,
/// rrjeti, AI-ja — do të duhej të dinte nëse loja është Chess960 apo jo.
class Move {
  const Move({
    required this.from,
    required this.to,
    this.promo = 0,
    this.captured = empty,
    this.isEp = false,
    this.isDouble = false,
    this.castle,
    this.rookFrom = -1,
    this.rookTo = -1,
  });

  final int from;
  final int to;
  final int promo;
  final int captured;
  final bool isEp;
  final bool isDouble;
  final CastleSide? castle;
  final int rookFrom;
  final int rookTo;

  bool get capturesPiece => captured != empty;

  /// UCI, me rokadën si «mbreti te kutia e vet e fundit» (e1g1), jo si
  /// «mbreti mbi kalin» — i njëjti rregull si te [to].
  String get uci =>
      algebraic(from) + algebraic(to) + (promo != 0 ? pieceChar[promo]! : '');

  @override
  String toString() => uci;

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.promo == promo;

  @override
  int get hashCode => Object.hash(from, to, promo);
}

// ─────────────────────────────────────────────────────────────────────────────
// Sulmi
// ─────────────────────────────────────────────────────────────────────────────

/// A e sulmon [byColor] kutinë [target]?
///
/// Lexohet mbrapsht — nga kutia drejt sulmuesve — sepse kështu kushton po aq sa
/// një gjenerim lëvizjesh për një figurë të vetme, e jo për të gjitha.
bool attacked(Position p, int target, int byColor) {
  // Ushtarët: shiko prapa nga kutia, përgjatë diagonaleve me të cilat hanë.
  final int back = byColor == white ? -10 : 10;
  if (p.at(target + back + 1) == pawn * byColor) return true;
  if (p.at(target + back - 1) == pawn * byColor) return true;

  for (final int d in knightDirs) {
    if (p.at(target + d) == knight * byColor) return true;
  }
  for (final int d in kingDirs) {
    if (p.at(target + d) == king * byColor) return true;
  }

  for (final int d in bishopDirs) {
    int s = target + d;
    while (p.at(s) == empty) {
      s += d;
    }
    final int v = p.at(s);
    if (v == bishop * byColor || v == queen * byColor) return true;
  }
  for (final int d in rookDirs) {
    int s = target + d;
    while (p.at(s) == empty) {
      s += d;
    }
    final int v = p.at(s);
    if (v == rook * byColor || v == queen * byColor) return true;
  }
  return false;
}

bool inCheck(Position p, [int? color]) {
  // Te antishahu nuk ekziston fare shahu: mbreti është figurë e zakonshme.
  if (p.variant == Variant.antichess) return false;
  final int c = color ?? p.side;
  final int? k = p.kingSquare(c);
  return k != null && attacked(p, k, -c);
}

// ─────────────────────────────────────────────────────────────────────────────
// Gjenerimi i lëvizjeve
// ─────────────────────────────────────────────────────────────────────────────

void _addPawnMoves(Position p, int from, List<Move> out) {
  final int color = p.side;
  final int fwd = color == white ? 10 : -10;
  final int startRank = color == white ? 1 : 6;
  final int lastRank = color == white ? 7 : 0;

  // Te antishahu mbreti nuk është i shenjtë, pra një ushtar mund të bëhet mbret.
  const List<int> normalPromos = <int>[queen, rook, bishop, knight];
  const List<int> antiPromos = <int>[queen, rook, bishop, knight, king];
  final List<int> promos =
      p.variant == Variant.antichess ? antiPromos : normalPromos;

  final int one = from + fwd;
  if (p.at(one) == empty) {
    if (rankOf(one) == lastRank) {
      for (final int pr in promos) {
        out.add(Move(from: from, to: one, promo: pr));
      }
    } else {
      out.add(Move(from: from, to: one));
      final int two = one + fwd;
      if (rankOf(from) == startRank && p.at(two) == empty) {
        out.add(Move(from: from, to: two, isDouble: true));
      }
    }
  }

  for (final int d in <int>[fwd + 1, fwd - 1]) {
    final int to = from + d;
    final int t = p.at(to);
    if (t == off) continue;
    if (t != empty && p.colorAt(to) == -color) {
      if (rankOf(to) == lastRank) {
        for (final int pr in promos) {
          out.add(Move(from: from, to: to, promo: pr, captured: t));
        }
      } else {
        out.add(Move(from: from, to: to, captured: t));
      }
    } else if (to == p.ep) {
      out.add(Move(from: from, to: to, isEp: true, captured: pawn * -color));
    }
  }
}

void _addCastles(Position p, int kingSq, List<Move> out) {
  if (p.variant == Variant.antichess) return;
  final int color = p.side;
  final int rank = color == white ? 0 : 7;
  if (inCheck(p, color)) return;

  for (final CastleSide side in CastleSide.values) {
    final int? rookSq = p.castleRook(color, side);
    if (rookSq == null || p.board[rookSq] != rook * color) continue;

    final int kingTo = sq(side == CastleSide.king ? 6 : 2, rank);
    final int rookTo = sq(side == CastleSide.king ? 5 : 3, rank);

    // Çdo kuti nga kalon mbreti ose kali duhet të jetë bosh — duke shpërfillur
    // vetë mbretin dhe kalin e rokadës, që te Chess960 shpesh rrinë tashmë mbi
    // kutitë ku po shkojnë.
    bool blocked = false;
    for (final List<int> pair in <List<int>>[
      <int>[kingSq, kingTo],
      <int>[rookSq, rookTo],
    ]) {
      final int lo = pair[0] < pair[1] ? pair[0] : pair[1];
      final int hi = pair[0] < pair[1] ? pair[1] : pair[0];
      for (int s = lo; s <= hi; s++) {
        if (!onBoard(s)) {
          blocked = true;
          break;
        }
        if (s != kingSq && s != rookSq && p.board[s] != empty) {
          blocked = true;
          break;
        }
      }
      if (blocked) break;
    }
    if (blocked) continue;

    // Mbreti nuk kalon dot nëpër një kuti të sulmuar as nuk ulet mbi të. Provoje
    // me mbretin të NGRITUR nga kutia e vet: përndryshe një oficer i drejtuar
    // pikërisht drejt tij maskohet nga vetë mbreti.
    final int lo = kingSq < kingTo ? kingSq : kingTo;
    final int hi = kingSq < kingTo ? kingTo : kingSq;
    final int saveK = p.board[kingSq];
    final int saveR = p.board[rookSq];
    p.board[kingSq] = empty;
    p.board[rookSq] = empty;
    bool through = false;
    for (int s = lo; s <= hi; s++) {
      if (attacked(p, s, -color)) {
        through = true;
        break;
      }
    }
    p.board[kingSq] = saveK;
    p.board[rookSq] = saveR;
    if (through) continue;

    out.add(Move(
      from: kingSq,
      to: kingTo,
      castle: side,
      rookFrom: rookSq,
      rookTo: rookTo,
    ));
  }
}

List<Move> pseudoMoves(Position p) {
  final List<Move> out = <Move>[];
  final int color = p.side;

  for (int from = 21; from <= 98; from++) {
    final int v = p.board[from];
    if (v == empty || v == off) continue;
    if ((v > 0 ? white : black) != color) continue;

    final int type = v.abs();
    if (type == pawn) {
      _addPawnMoves(p, from, out);
      continue;
    }

    final bool sliding = type == bishop || type == rook || type == queen;
    final List<int> dirs = type == knight
        ? knightDirs
        : type == bishop
            ? bishopDirs
            : type == rook
                ? rookDirs
                : kingDirs;

    for (final int d in dirs) {
      int to = from + d;
      while (true) {
        final int t = p.at(to);
        if (t == off) break;
        if (t == empty) {
          out.add(Move(from: from, to: to));
        } else {
          if ((t > 0 ? white : black) != color) {
            out.add(Move(from: from, to: to, captured: t));
          }
          break;
        }
        if (!sliding) break;
        to += d;
      }
    }

    if (type == king) _addCastles(p, from, out);
  }
  return out;
}

List<Move> legalMoves(Position p) {
  final List<Move> pseudo = pseudoMoves(p);

  if (p.variant == Variant.antichess) {
    // Pa siguri mbreti, por të ngrënët është i detyrueshëm.
    final List<Move> caps =
        pseudo.where((Move m) => m.capturesPiece).toList(growable: false);
    return caps.isNotEmpty ? caps : pseudo;
  }

  final List<Move> out = <Move>[];
  for (final Move m in pseudo) {
    if (!inCheck(makeMove(p, m), p.side)) out.add(m);
  }
  return out;
}

Position makeMove(Position p, Move m) {
  final Position n = p.clone();
  final int color = p.side;
  final int moving = n.board[m.from];

  n.board[m.from] = empty;
  if (m.isEp) n.board[m.to + (color == white ? -10 : 10)] = empty;
  n.board[m.to] = m.promo != 0 ? m.promo * color : moving;

  if (m.castle != null) {
    // 🚨 Rendi ka rëndësi te Chess960: kutia e nisjes së kalit mund të jetë
    // pikërisht kutia ku shkon mbreti. Pastro kalin i pari, vendose i fundit.
    n.board[m.rookFrom] = empty;
    n.board[m.to] = moving;
    n.board[m.rookTo] = rook * color;
  }

  // Të drejtat e rokadës vdesin kur lëviz mbreti, kur kali largohet nga kutia e
  // vet e nisjes, ose kur kali hahet mbi të.
  if (moving.abs() == king) {
    n.setCastleRook(color, CastleSide.king, null);
    n.setCastleRook(color, CastleSide.queen, null);
  }
  for (final int c in <int>[white, black]) {
    for (final CastleSide side in CastleSide.values) {
      final int? rs = n.castleRook(c, side);
      if (rs != null && (rs == m.from || rs == m.to)) {
        n.setCastleRook(c, side, null);
      }
    }
  }

  n.ep = m.isDouble ? m.from + (color == white ? 10 : -10) : null;
  n.halfmove =
      (moving.abs() == pawn || m.capturesPiece) ? 0 : p.halfmove + 1;
  if (color == black) n.fullmove = p.fullmove + 1;
  n.side = -color;

  if (p.variant == Variant.threecheck && inCheck(n, -color)) {
    n.bumpChecks(color);
  }
  return n;
}

/// Gjen lëvizjen e ligjshme që i përgjigjet një vargu UCI, ose null.
///
/// Kalon gjithmonë nga [legalMoves]: kështu një varg i ardhur nga rrjeti nuk
/// mund të prodhojë kurrë një lëvizje që motori vetë nuk do ta lejonte.
Move? moveFromUci(Position p, String uci) {
  if (uci.length < 4) return null;
  final int from = parseSquare(uci.substring(0, 2));
  final int to = parseSquare(uci.substring(2, 4));
  final int promo = uci.length > 4 ? (charPiece[uci[4]] ?? 0) : 0;
  for (final Move m in legalMoves(p)) {
    if (m.from == from && m.to == to && m.promo == promo) return m;
  }
  return null;
}
