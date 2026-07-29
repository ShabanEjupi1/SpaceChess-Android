import 'dart:math';

import 'board.dart';
import 'moves.dart';
import 'status.dart';

/// Kompjuteri: alfa-beta me qetësim, thellim të njëpasnjëshëm dhe një orë.
///
/// 🔑 Kërkimi bëhet NË PAJISJEN e lojtarit, kurrë te serveri. Ampere-ja ka ~13GB
/// të lirë dhe një rregull të qëndrueshëm kundër ngarkesave të reja CPU-je; një
/// kërkim shahu është pikërisht ajo — një lojtar që mendon dy sekonda do të
/// kushtonte më shumë CPU se çdo aplikacion tjetër i kutisë. Në telefon nuk na
/// kushton asgjë dhe shkallëzohet me çdo numër lojërash njëkohësisht.
const Map<int, int> pieceValue = <int, int>{
  pawn: 100,
  knight: 320,
  bishop: 330,
  rook: 500,
  queen: 900,
  king: 20000,
};

// Tabelat kuti-për-figurë, nga këndvështrimi i të bardhit, a1 i pari. Vlerat e
// njohura «simplified evaluation» — ato janë çka e ndalon motorin nga rrotullimi
// i kalorësve në buzë dhe nga lënia e mbretit në mes të fushës.
const List<int> _pawnPst = <int>[
  0, 0, 0, 0, 0, 0, 0, 0, //
  5, 10, 10, -20, -20, 10, 10, 5,
  5, -5, -10, 0, 0, -10, -5, 5,
  0, 0, 0, 20, 20, 0, 0, 0,
  5, 5, 10, 25, 25, 10, 5, 5,
  10, 10, 20, 30, 30, 20, 10, 10,
  50, 50, 50, 50, 50, 50, 50, 50,
  0, 0, 0, 0, 0, 0, 0, 0,
];
const List<int> _knightPst = <int>[
  -50, -40, -30, -30, -30, -30, -40, -50, //
  -40, -20, 0, 5, 5, 0, -20, -40,
  -30, 5, 10, 15, 15, 10, 5, -30,
  -30, 0, 15, 20, 20, 15, 0, -30,
  -30, 5, 15, 20, 20, 15, 5, -30,
  -30, 0, 10, 15, 15, 10, 0, -30,
  -40, -20, 0, 0, 0, 0, -20, -40,
  -50, -40, -30, -30, -30, -30, -40, -50,
];
const List<int> _bishopPst = <int>[
  -20, -10, -10, -10, -10, -10, -10, -20, //
  -10, 5, 0, 0, 0, 0, 5, -10,
  -10, 10, 10, 10, 10, 10, 10, -10,
  -10, 0, 10, 10, 10, 10, 0, -10,
  -10, 5, 5, 10, 10, 5, 5, -10,
  -10, 0, 5, 10, 10, 5, 0, -10,
  -10, 0, 0, 0, 0, 0, 0, -10,
  -20, -10, -10, -10, -10, -10, -10, -20,
];
const List<int> _rookPst = <int>[
  0, 0, 0, 5, 5, 0, 0, 0, //
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  5, 10, 10, 10, 10, 10, 10, 5,
  0, 0, 0, 0, 0, 0, 0, 0,
];
const List<int> _queenPst = <int>[
  -20, -10, -10, -5, -5, -10, -10, -20, //
  -10, 0, 5, 0, 0, 0, 0, -10,
  -10, 5, 5, 5, 5, 5, 0, -10,
  0, 0, 5, 5, 5, 5, 0, -5,
  -5, 0, 5, 5, 5, 5, 0, -5,
  -10, 0, 5, 5, 5, 5, 0, -10,
  -10, 0, 0, 0, 0, 0, 0, -10,
  -20, -10, -10, -5, -5, -10, -10, -20,
];
const List<int> _kingPst = <int>[
  20, 30, 10, 0, 0, 10, 30, 20, //
  20, 20, 0, 0, 0, 0, 20, 20,
  -10, -20, -20, -20, -20, -20, -20, -10,
  -20, -30, -30, -40, -40, -30, -30, -20,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
];

/// Në fundlojë mbreti duhet të marshojë drejt qendrës, jo të fshihet në qoshe.
const List<int> _kingEndgamePst = <int>[
  -50, -30, -30, -30, -30, -30, -30, -50, //
  -30, -30, 0, 0, 0, 0, -30, -30,
  -30, -10, 20, 30, 30, 20, -10, -30,
  -30, -10, 30, 40, 40, 30, -10, -30,
  -30, -10, 30, 40, 40, 30, -10, -30,
  -30, -10, 20, 30, 30, 20, -10, -30,
  -30, -20, -10, 0, 0, -10, -20, -30,
  -50, -40, -30, -20, -20, -30, -40, -50,
];

const Map<int, List<int>> _pst = <int, List<int>>{
  pawn: _pawnPst,
  knight: _knightPst,
  bishop: _bishopPst,
  rook: _rookPst,
  queen: _queenPst,
  king: _kingPst,
};

const int mateScore = 100000;

int _pstIndex(int s, int color) {
  final int f = fileOf(s), r = rankOf(s);
  // I ziu e lexon të njëjtën tabelë nga fundi tjetër.
  return color == white ? r * 8 + f : (7 - r) * 8 + f;
}

/// Vlerësimi, gjithmonë nga këndvështrimi i ANËS QË LUAN. Negamax-i varet nga
/// kjo: një vlerësim nga këndvështrimi i të bardhit e përmbys shenjën në
/// thellësi tek dhe motori zgjedh me qetësi lëvizjen më të keqe.
int evaluate(Position p) {
  int score = 0;
  int material = 0;

  final List<int> squares = <int>[];
  for (int s = 21; s <= 98; s++) {
    final int v = p.board[s];
    if (v == empty || v == off) continue;
    squares.add(s);
    if (v.abs() != king) material += pieceValue[v.abs()]!;
  }
  final bool endgame = material < 2000;

  for (final int s in squares) {
    final int v = p.board[s];
    final int type = v.abs();
    final int color = v > 0 ? white : black;
    final List<int> table =
        (type == king && endgame) ? _kingEndgamePst : _pst[type]!;
    final int value = pieceValue[type]! + table[_pstIndex(s, color)];
    score += color == white ? value : -value;
  }

  if (p.variant == Variant.koth) {
    // Largësia nga katër kutitë qendrore është e gjithë loja këtu.
    for (final int color in <int>[white, black]) {
      final int? k = p.kingSquare(color);
      if (k == null) continue;
      final double d = max((fileOf(k) - 3.5).abs(), (rankOf(k) - 3.5).abs()) - 0.5;
      score += ((color == white ? 1 : -1) * (60 - d * 25)).round();
    }
  }
  if (p.variant == Variant.threecheck) {
    score += p.whiteChecks * 90 - p.blackChecks * 90;
    if (inCheck(p)) score += p.side == white ? -60 : 60;
  }
  if (p.variant == Variant.antichess) score = -score; // materiali është barrë

  // Term i vogël lëvizshmërie: kushton një gjenerim lëvizjesh dhe e pengon
  // motorin të mbyllet vetë.
  score += (p.side == white ? 1 : -1) * legalMoves(p).length * 2;

  return p.side == white ? score : -score;
}

int _scoreMove(Position p, Move m) {
  int s = 0;
  if (m.capturesPiece) {
    // MVV-LVA: kap viktimën më të majme me sulmuesin më të lirë.
    s += 10 * pieceValue[m.captured.abs()]! - pieceValue[p.board[m.from].abs()]!;
  }
  if (m.promo != 0) s += pieceValue[m.promo]!;
  if (m.castle != null) s += 60;
  return s;
}

List<Move> _ordered(Position p, List<Move> moves) {
  final List<Move> sorted = List<Move>.of(moves);
  sorted.sort((Move a, Move b) => _scoreMove(p, b).compareTo(_scoreMove(p, a)));
  return sorted;
}

int _quiesce(Position p, int alpha, int beta, int deadline, [int depth = 0]) {
  final int stand = evaluate(p);
  if (stand >= beta) return beta;
  if (stand > alpha) alpha = stand;
  if (depth > 4 || DateTime.now().millisecondsSinceEpoch > deadline) {
    return alpha;
  }

  // Vetëm të ngrënat dhe kalimet në figurë: qëllimi është të mos vlerësohet në
  // mes të një shkëmbimi, që është arsyeja pse një kërkim me thellësi fikse i
  // varros figurat.
  final List<Move> noisy = _ordered(
    p,
    legalMoves(p)
        .where((Move m) => m.capturesPiece || m.promo != 0)
        .toList(growable: false),
  );

  for (final Move m in noisy) {
    final int score =
        -_quiesce(makeMove(p, m), -beta, -alpha, deadline, depth + 1);
    if (score >= beta) return beta;
    if (score > alpha) alpha = score;
  }
  return alpha;
}

class _SearchResult {
  _SearchResult(this.score, {this.move, this.aborted = false});
  final int score;
  final Move? move;
  final bool aborted;
}

_SearchResult _search(
  Position p,
  int depth,
  int alpha,
  int beta,
  int deadline, [
  int ply = 0,
]) {
  if (DateTime.now().millisecondsSinceEpoch > deadline) {
    return _SearchResult(evaluate(p), aborted: true);
  }

  final List<Move> moves = legalMoves(p);
  if (moves.isEmpty || p.halfmove >= 100) {
    final GameStatus st = gameStatus(p);
    if (st.over) {
      if (st.result == '1/2-1/2') return _SearchResult(0);
      final int winner = st.result == '1-0' ? white : black;
      // Preferon të japë mat më shpejt dhe ta marrë matin më vonë.
      return _SearchResult(
          winner == p.side ? mateScore - ply : -mateScore + ply);
    }
  }
  if (depth <= 0) {
    return _SearchResult(_quiesce(p, alpha, beta, deadline));
  }

  _SearchResult? best;
  bool aborted = false;

  for (final Move m in _ordered(p, moves)) {
    final _SearchResult r =
        _search(makeMove(p, m), depth - 1, -beta, -alpha, deadline, ply + 1);
    if (r.aborted) aborted = true;
    final int score = -r.score;

    if (best == null || score > best.score) {
      best = _SearchResult(score, move: m);
    }
    if (score > alpha) alpha = score;
    if (alpha >= beta) break; // kjo degë u përgënjeshtrua, mos kërko më
    if (aborted) break;
  }

  return best == null
      ? _SearchResult(evaluate(p), aborted: aborted)
      : _SearchResult(best.score, move: best.move, aborted: aborted);
}

/// Vështirësia është një kurbë, jo thjesht një numër thellësie: nivelet e ulëta
/// duhet të ndihen të mundshme për një fillestar pa qenë dukshëm të prishura,
/// ndaj gabojnë **me qëllim** në vend që të kërkojnë keq. Një kërkim i cekët
/// luan *pa shije*, jo *dobët* — dhe fillestari prapë humb çdo herë.
class AiLevel {
  const AiLevel(this.id, this.name, this.elo, this.depth, this.ms, this.blunder);

  final int id;
  final String name;
  final String elo;
  final int depth;
  final int ms;
  final double blunder;

  static const List<AiLevel> all = <AiLevel>[
    AiLevel(1, 'Fillestar', '~250', 1, 100, 0.60),
    AiLevel(2, 'Lehtë', '~500', 1, 150, 0.35),
    AiLevel(3, 'Rehatshëm', '~800', 2, 300, 0.20),
    AiLevel(4, 'Mesatar', '~1100', 3, 600, 0.08),
    AiLevel(5, 'Sfidues', '~1400', 3, 1000, 0.03),
    AiLevel(6, 'I fortë', '~1650', 4, 1600, 0),
    AiLevel(7, 'Ekspert', '~1850', 5, 2500, 0),
    AiLevel(8, 'Maksimal', '~2000+', 6, 4000, 0),
  ];

  static AiLevel byId(int id) =>
      all.firstWhere((AiLevel l) => l.id == id, orElse: () => all[3]);
}

/// Zgjedh një lëvizje. [random] jepet nga testet që gabimi i qëllimshëm të mos
/// e bëjë suitën të paparashikueshme.
Move? chooseMove(Position p, {int levelId = 4, Random? random}) {
  final AiLevel level = AiLevel.byId(levelId);
  final Random rnd = random ?? Random();
  final List<Move> moves = legalMoves(p);
  if (moves.isEmpty) return null;
  if (moves.length == 1) return moves.first;

  if (level.blunder > 0 && rnd.nextDouble() < level.blunder) {
    final List<Move> caps =
        moves.where((Move m) => m.capturesPiece).toList(growable: false);
    final List<Move> pool =
        (caps.isNotEmpty && rnd.nextDouble() < 0.5) ? caps : moves;
    return pool[rnd.nextInt(pool.length)];
  }

  final int deadline = DateTime.now().millisecondsSinceEpoch + level.ms;
  Move best = _ordered(p, moves).first;

  // Thellim i njëpasnjëshëm: gjithmonë të kesh një lëvizje të përdorshme në dorë
  // kur mbaron ora, dhe rezultati më i cekët e rendit kërkimin më të thellë.
  for (int d = 1; d <= level.depth; d++) {
    final _SearchResult r =
        _search(p, d, -mateScore * 2, mateScore * 2, deadline);
    if (r.move != null) best = r.move!;
    if (r.aborted || DateTime.now().millisecondsSinceEpoch > deadline) break;
  }
  return best;
}
