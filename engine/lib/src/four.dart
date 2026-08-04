/// Shahu me KATËR lojtarë — «Katërshi».
///
/// 🔑 **Ky skedar nuk prek [Position] fare, me qëllim.** Motori dylojtarësh
/// është i lidhur me suitën e perft-it, dhe ata numra janë e vetmja gjë që
/// provon se telefoni dhe faqja luajnë ende të njëjtin shah. Të futësh një anë
/// të tretë e të katërt te `side = ±1`, te rokada me katër çifte kalash dhe te
/// `gameStatus` do të thoshte t'i rrezikosh ata numra për një variant që s'i
/// përdor. Prandaj: strukturë e vetën, kod i vetin, testet e veta.
///
/// Ajo që ndahet me motorin dylojtarësh është vetëm ideja e «mailbox»-it: një
/// varg i sheshtë me roje [fourOff] përreth, që asnjë gjenerator lëvizjesh të
/// mos ketë nevojë për kontroll kufijsh. Këtu roja bën edhe një punë të dytë —
/// mbush katër qoshet 3×3 që i mungojnë tabelës në formë kryqi. Një oficer që
/// rrëshqet drejt një qosheje ndalet vetvetiu, saktësisht si te buza e tabelës,
/// dhe asnjë rresht kodi nuk e di se qoshet ekzistojnë.
///
/// ```
///        ┌──────────┐
///        │  E KUQE  │        14×14, pa katër qoshet 3×3
///   ┌────┴──────────┴────┐
///   │                    │   radha: E kuqe → Blu → E verdhë → Jeshile
///   │  BLU        JESHILE│
///   │                    │   pengu ecën drejt QENDRËS, secili nga ana e vet
///   └────┬──────────┬────┘
///        │ E VERDHË │
///        └──────────┘
/// ```
library;

import 'dart:typed_data';

import 'board.dart' show pawn, knight, bishop, rook, queen, king, empty, pieceChar;

/// Përmasat e vargut: 16 kolona × 18 rreshta për një tabelë 14×14.
///
/// 🚨 Roja duhet të jetë **një kolonë** në secilën anë por **dy rreshta** lart e
/// poshtë, saktësisht si 10×12 te motori dylojtarësh. Arsyeja është kalorësi:
///   • ±2 KOLONA nga buza dalin te kolona-roje e rreshtit fqinj, ndaj një kolonë
///     mjafton — mbështjellja bie vetë mbi një roje;
///   • ±2 RRESHTA nga buza dalin krejt jashtë vargut, dhe një rresht i vetëm roje
///     nuk i kap. Me 16×16 kjo dilte si `RangeError … -7`, pra si defekt vargu e
///     jo si defekt gjeometrie — larg shkakut.
const int fourWidth = 16;
const int fourHeight = 18;
const int fourCells = fourWidth * fourHeight;

/// Roja. Mbulon njëkohësisht jashtë-tabelës DHE katër qoshet 3×3 që s'ekzistojnë.
const int fourOff = 99;

/// Katër ushtritë, në radhën e lojës.
const int red = 0;
const int blue = 1;
const int yellow = 2;
const int green = 3;

const List<String> fourColorNames = <String>['red', 'blue', 'yellow', 'green'];
const List<String> fourColorNamesSq = <String>['E kuqe', 'Blu', 'E verdhë', 'Jeshile'];

/// Kodimi i një kutie: `figura | (ngjyra << 3)`.
///
/// 🔑 `empty == 0` mbetet i vlefshëm sepse asnjë figurë s'ka kod 0, ndaj një
/// kuti bosh nuk ngatërrohet kurrë me «peng i kuq» (ngjyra e kuqe është 0).
int fourCode(int piece, int color) => piece | (color << 3);
int pieceOf(int code) => code & 7;
int colorOf(int code) => code >> 3;

int fourSq(int file, int rank) => (rank + 2) * fourWidth + (file + 1);
int fourFile(int s) => (s % fourWidth) - 1;
int fourRank(int s) => (s ~/ fourWidth) - 2;

/// Qoshet 3×3 janë jashtë tabelës: file dhe rank të dy nën 3 ose të dy mbi 10.
bool fourOnBoard(int file, int rank) {
  if (file < 0 || file > 13 || rank < 0 || rank > 13) return false;
  final bool fEdge = file < 3 || file > 10;
  final bool rEdge = rank < 3 || rank > 10;
  return !(fEdge && rEdge);
}

const int _n = fourWidth, _s = -fourWidth, _e = 1, _w = -1;
const int _ne = _n + _e, _nw = _n + _w, _se = _s + _e, _sw = _s + _w;

const List<int> fourKnightDirs = <int>[
  _n + _ne, _n + _nw, _s + _se, _s + _sw,
  _e + _ne, _e + _se, _w + _nw, _w + _sw,
];
const List<int> fourBishopDirs = <int>[_ne, _nw, _se, _sw];
const List<int> fourRookDirs = <int>[_n, _s, _e, _w];
const List<int> fourKingDirs = <int>[_n, _s, _e, _w, _ne, _nw, _se, _sw];

/// Drejtimi «përpara» i secilës ushtri — gjithmonë drejt qendrës.
const List<int> forwardDir = <int>[_n, _e, _s, _w];

/// Dy diagonalet e ngrënies së pengut, sipas ushtrisë.
const List<List<int>> pawnCaptureDirs = <List<int>>[
  <int>[_ne, _nw],  // e kuqe ecën veriut
  <int>[_ne, _se],  // blu ecën lindjes
  <int>[_se, _sw],  // e verdhë ecën jugut
  <int>[_nw, _sw],  // jeshile ecën perëndimit
];

/// Vlera në pikë e figurave. Këto NUK janë pesha vlerësimi — janë rregull loje:
/// fituesi del nga pikët, jo nga mati, ndaj një ngrënie e vlen saktësisht kaq.
const List<int> piecePoints = <int>[0, 1, 3, 5, 5, 9, 20];

/// Shpërblimi për matimin e një lojtari, dhe për të mbetur i fundit në këmbë.
const int matePoints = 20;

/// Rreshti ku pengu bëhet figurë: i njëmbëdhjeti nga ana e vet.
///
/// 🚨 Jo buza e tabelës. Me promovim te buza pengu do të bënte 12 hapa dhe asnjë
/// lojë nuk do të mbaronte me promovim. Njëmbëdhjeta e mban udhëtimin nëntë hapa,
/// sa te shahu i zakonshëm plus një.
const List<int> promoLine = <int>[10, 10, 3, 3];

bool _promotes(int color, int to) =>
    (color == red || color == yellow) ? fourRank(to) == promoLine[color]
                                      : fourFile(to) == promoLine[color];

/// Një radhë te Katërshi.
class FourMove {
  const FourMove({
    required this.from,
    required this.to,
    this.promo = 0,
    this.captured = empty,
    this.isDouble = false,
    this.castleRookFrom = -1,
    this.castleRookTo = -1,
  });

  final int from;
  final int to;
  final int promo;

  /// Kodi i plotë (figurë + ngjyrë) i asaj që u hëngër, ose [empty]. Ngjyra
  /// duhet për zhbërjen dhe për të ditur kujt t'i hiqet materiali.
  final int captured;
  final bool isDouble;
  final int castleRookFrom;
  final int castleRookTo;

  bool get capturesPiece => captured != empty;
  bool get isCastle => castleRookFrom >= 0;

  /// Shënimi që udhëton te rrjeti: «f3r1-f3r3», me file dhe rank si numra,
  /// sepse 14 skedarë nuk hyjnë te `a`–`h`.
  String get code => '${fourFile(from)},${fourRank(from)}-'
      '${fourFile(to)},${fourRank(to)}'
      '${promo != 0 ? pieceChar[promo]! : ''}';

  @override
  String toString() => code;

  @override
  bool operator ==(Object other) =>
      other is FourMove && other.from == from && other.to == to && other.promo == promo;

  @override
  int get hashCode => Object.hash(from, to, promo);
}

/// Gjendja e një lojtari të vetëm.
class FourPlayer {
  FourPlayer(this.color);

  final int color;
  int points = 0;

  /// I gjallë = ende luan. Një lojtar i matuar ose i patuar del jashtë, POR
  /// figurat e tij mbeten në tabelë (shih [FourPosition.fourEliminate]).
  bool alive = true;

  /// Kutia e kalit që ende mund të bëjë rokadë, ose null.
  int? kingSideRook;
  int? queenSideRook;

  FourPlayer clone() => FourPlayer(color)
    ..points = points
    ..alive = alive
    ..kingSideRook = kingSideRook
    ..queenSideRook = queenSideRook;
}

class FourPosition {
  FourPosition() : board = Int8List(fourCells) {
    board.fillRange(0, fourCells, fourOff);
    for (int r = 0; r < 14; r++) {
      for (int f = 0; f < 14; f++) {
        if (fourOnBoard(f, r)) board[fourSq(f, r)] = empty;
      }
    }
  }

  final Int8List board;

  final List<FourPlayer> players =
      <FourPlayer>[FourPlayer(red), FourPlayer(blue), FourPlayer(yellow), FourPlayer(green)];

  /// Kush ecën. Gjithmonë një lojtar i gjallë — [fourAdvance] e siguron këtë.
  int turn = red;

  int halfmove = 0;
  int fullmove = 1;

  /// A është dhënë tashmë shpërblimi i «të fundit në këmbë». Pa këtë flamur ai
  /// do të jepej sa herë lexohej gjendja.
  bool lastStandAwarded = false;

  FourPlayer get current => players[turn];
  Iterable<FourPlayer> get living => players.where((FourPlayer p) => p.alive);

  int kingSquareOf(int color) {
    final int want = fourCode(king, color);
    for (int i = 0; i < fourCells; i++) {
      if (board[i] == want) return i;
    }
    return -1;
  }

  FourPosition clone() {
    final FourPosition c = FourPosition._raw(Int8List.fromList(board));
    for (int i = 0; i < 4; i++) {
      c.players[i] = players[i].clone();
    }
    c.turn = turn;
    c.halfmove = halfmove;
    c.fullmove = fullmove;
    c.lastStandAwarded = lastStandAwarded;
    return c;
  }

  FourPosition._raw(this.board);
}

/// Rreshtimi fillestar.
///
/// Rendi i figurave, i lexuar nga MAJTAS-DJATHTAS SIPAS SYRIT TË ATIJ LOJTARI,
/// është `R N B Q K B N R` për të katër — pra mbreti i kuq dhe ai i verdhë ndodhen
/// te i njëjti skedar, dhe blu me jeshilin te i njëjti rresht, saktësisht si
/// mbretërit që shihen përballë te shahu i zakonshëm.
const List<int> _backRank = <int>[rook, knight, bishop, queen, king, bishop, knight, rook];

FourPosition fourStart() {
  final FourPosition p = FourPosition();

  for (int i = 0; i < 8; i++) {
    final int f = 3 + i;
    // E kuqe poshtë, e verdhë lart: të njëjtët skedarë, pra mbretërit përballë.
    p.board[fourSq(f, 0)] = fourCode(_backRank[i], red);
    p.board[fourSq(f, 1)] = fourCode(pawn, red);
    p.board[fourSq(f, 13)] = fourCode(_backRank[i], yellow);
    p.board[fourSq(f, 12)] = fourCode(pawn, yellow);

    final int r = 3 + i;
    p.board[fourSq(0, r)] = fourCode(_backRank[i], blue);
    p.board[fourSq(1, r)] = fourCode(pawn, blue);
    p.board[fourSq(13, r)] = fourCode(_backRank[i], green);
    p.board[fourSq(12, r)] = fourCode(pawn, green);
  }

  // Kalat e rokadës. Ruhen si kuti nisjeje — i njëjti model si te motori
  // dylojtarësh, ku kjo e vetme e bën Chess960-n të punojë pa kod të dytë.
  p.players[red].queenSideRook = fourSq(3, 0);
  p.players[red].kingSideRook = fourSq(10, 0);
  p.players[yellow].queenSideRook = fourSq(3, 13);
  p.players[yellow].kingSideRook = fourSq(10, 13);
  p.players[blue].queenSideRook = fourSq(0, 3);
  p.players[blue].kingSideRook = fourSq(0, 10);
  p.players[green].queenSideRook = fourSq(13, 3);
  p.players[green].kingSideRook = fourSq(13, 10);

  return p;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sulmi
// ─────────────────────────────────────────────────────────────────────────────

/// A e sulmon [byColor] kutinë [target]?
///
/// 🚨 Lexohet edhe për ushtritë e VDEKURA kur pyetet drejtpërdrejt, ndaj thirrësi
/// duhet ta kufizojë vetë te lojtarët e gjallë. Figurat e një lojtari të nxjerrë
/// jashtë rrinë në tabelë, por nuk sulmojnë më asgjë — shih [fourAttackedByLiving].
bool fourAttackedBy(FourPosition p, int target, int byColor) {
  // Pengjet: kërkohet mbrapsht nga kutia e synuar.
  for (final int d in pawnCaptureDirs[byColor]) {
    final int from = target - d;
    if (p.board[from] == fourCode(pawn, byColor)) return true;
  }
  for (final int d in fourKnightDirs) {
    if (p.board[target + d] == fourCode(knight, byColor)) return true;
  }
  for (final int d in fourKingDirs) {
    if (p.board[target + d] == fourCode(king, byColor)) return true;
  }
  for (final int d in fourBishopDirs) {
    for (int s = target + d;; s += d) {
      final int c = p.board[s];
      if (c == fourOff) break;
      if (c != empty) {
        if (colorOf(c) == byColor && (pieceOf(c) == bishop || pieceOf(c) == queen)) {
          return true;
        }
        break;
      }
    }
  }
  for (final int d in fourRookDirs) {
    for (int s = target + d;; s += d) {
      final int c = p.board[s];
      if (c == fourOff) break;
      if (c != empty) {
        if (colorOf(c) == byColor && (pieceOf(c) == rook || pieceOf(c) == queen)) {
          return true;
        }
        break;
      }
    }
  }
  return false;
}

/// A e sulmon ndonjë lojtar i GJALLË (veç [exceptColor]) kutinë [target]?
bool fourAttackedByLiving(FourPosition p, int target, int exceptColor) {
  for (final FourPlayer pl in p.players) {
    if (!pl.alive || pl.color == exceptColor) continue;
    if (fourAttackedBy(p, target, pl.color)) return true;
  }
  return false;
}

bool fourInCheck(FourPosition p, int color) {
  final int k = p.kingSquareOf(color);
  if (k < 0) return false;
  return fourAttackedByLiving(p, k, color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Gjenerimi i lëvizjeve
// ─────────────────────────────────────────────────────────────────────────────

List<FourMove> fourPseudoMoves(FourPosition p, int color) {
  final List<FourMove> out = <FourMove>[];
  if (!p.players[color].alive) return out;

  for (int s = 0; s < fourCells; s++) {
    final int c = p.board[s];
    if (c == fourOff || c == empty || colorOf(c) != color) continue;
    switch (pieceOf(c)) {
      case pawn:
        _pawnMoves(p, s, color, out);
      case knight:
        _stepMoves(p, s, color, fourKnightDirs, out);
      case king:
        _stepMoves(p, s, color, fourKingDirs, out);
        _castleMoves(p, s, color, out);
      case bishop:
        _slideMoves(p, s, color, fourBishopDirs, out);
      case rook:
        _slideMoves(p, s, color, fourRookDirs, out);
      case queen:
        _slideMoves(p, s, color, fourKingDirs, out);
    }
  }
  return out;
}

void _pawnMoves(FourPosition p, int from, int color, List<FourMove> out) {
  final int d = forwardDir[color];
  final int one = from + d;
  if (p.board[one] == empty) {
    _addPawn(from, one, color, empty, out, isDouble: false);
    // Hapi i dyfishtë vetëm nga rreshti i vet i nisjes.
    final bool atStart = (color == red && fourRank(from) == 1) ||
        (color == yellow && fourRank(from) == 12) ||
        (color == blue && fourFile(from) == 1) ||
        (color == green && fourFile(from) == 12);
    final int two = one + d;
    if (atStart && p.board[two] == empty) {
      _addPawn(from, two, color, empty, out, isDouble: true);
    }
  }
  for (final int cd in pawnCaptureDirs[color]) {
    final int to = from + cd;
    final int t = p.board[to];
    if (t == fourOff || t == empty) continue;
    if (colorOf(t) == color) continue;
    _addPawn(from, to, color, t, out, isDouble: false);
  }
}

void _addPawn(int from, int to, int color, int captured, List<FourMove> out,
    {required bool isDouble}) {
  if (_promotes(color, to)) {
    for (final int promo in <int>[queen, rook, bishop, knight]) {
      out.add(FourMove(from: from, to: to, promo: promo, captured: captured));
    }
  } else {
    out.add(FourMove(from: from, to: to, captured: captured, isDouble: isDouble));
  }
}

void _stepMoves(FourPosition p, int from, int color, List<int> dirs, List<FourMove> out) {
  for (final int d in dirs) {
    final int to = from + d;
    final int t = p.board[to];
    if (t == fourOff) continue;
    if (t != empty && colorOf(t) == color) continue;
    out.add(FourMove(from: from, to: to, captured: t));
  }
}

void _slideMoves(FourPosition p, int from, int color, List<int> dirs, List<FourMove> out) {
  for (final int d in dirs) {
    for (int to = from + d;; to += d) {
      final int t = p.board[to];
      if (t == fourOff) break;
      if (t == empty) {
        out.add(FourMove(from: from, to: to));
        continue;
      }
      if (colorOf(t) != color) out.add(FourMove(from: from, to: to, captured: t));
      break;
    }
  }
}

/// Rokada: mbreti dy kuti drejt kalit, kali kërcen përtej tij.
///
/// 🚨 Të tri kushtet e shahut duhen matur ndaj ÇDO lojtari të gjallë, jo ndaj
/// një kundërshtari të vetëm: te Katërshi kutia që kalon mbreti mund të jetë
/// nën sulm nga dikush që s'është radha e tij.
void _castleMoves(FourPosition p, int from, int color, List<FourMove> out) {
  final FourPlayer pl = p.players[color];
  if (fourInCheck(p, color)) return;

  // Boshti i rreshtit të fundit: horizontal për të kuqen/të verdhën.
  final bool horizontal = color == red || color == yellow;
  final int step = horizontal ? _e : _n;

  for (final int? rookSq in <int?>[pl.kingSideRook, pl.queenSideRook]) {
    if (rookSq == null) continue;
    if (p.board[rookSq] != fourCode(rook, color)) continue;

    final int dir = rookSq > from ? step : -step;
    // Rruga mes mbretit dhe kalit duhet bosh.
    bool clear = true;
    for (int s = from + dir; s != rookSq; s += dir) {
      if (p.board[s] != empty) {
        clear = false;
        break;
      }
    }
    if (!clear) continue;

    final int kingTo = from + 2 * dir;
    final int rookTo = from + dir;
    if (p.board[kingTo] == fourOff) continue;

    // Mbreti nuk kalon dot nëpër shah, as nuk ndalon në të.
    if (fourAttackedByLiving(p, from + dir, color)) continue;
    if (fourAttackedByLiving(p, kingTo, color)) continue;

    out.add(FourMove(
      from: from,
      to: kingTo,
      castleRookFrom: rookSq,
      castleRookTo: rookTo,
    ));
  }
}

/// Lëvizjet e ligjshme: pseudo-lëvizjet pa ato që e lënë mbretin tënd nën sulm.
List<FourMove> fourLegalMoves(FourPosition p, [int? color]) {
  final int c = color ?? p.turn;
  final List<FourMove> out = <FourMove>[];
  for (final FourMove m in fourPseudoMoves(p, c)) {
    final FourPosition after = p.clone();
    _apply(after, m);
    if (!fourInCheck(after, c)) out.add(m);
  }
  return out;
}

// ─────────────────────────────────────────────────────────────────────────────
// Zbatimi
// ─────────────────────────────────────────────────────────────────────────────

/// Zbaton radhën pa prekur radhën e lojtarit apo pikët — vetëm tabelën.
/// Përdoret nga [fourLegalMoves], ku e vetmja pyetje është «a mbetet mbreti nën sulm».
void _apply(FourPosition p, FourMove m) {
  final int moving = p.board[m.from];
  p.board[m.from] = empty;
  p.board[m.to] = m.promo != 0 ? fourCode(m.promo, colorOf(moving)) : moving;
  if (m.isCastle) {
    p.board[m.castleRookTo] = p.board[m.castleRookFrom];
    p.board[m.castleRookFrom] = empty;
  }
}

/// Luaj një radhë dhe kthe pozicionin e ri. Pozicioni hyrës nuk preket.
FourPosition makeFourMove(FourPosition p, FourMove m) {
  final FourPosition n = p.clone();
  final int moving = n.board[m.from];
  final int color = colorOf(moving);

  if (m.capturesPiece) {
    // 🔑 Pikët shkojnë te ai që hëngri, edhe kur e ngrëna i përkiste një lojtari
    // të nxjerrë tashmë jashtë: figurat e tij mbeten në tabelë pikërisht që të
    // ketë çfarë të hahet.
    n.players[color].points += piecePoints[pieceOf(m.captured)];
    _revokeCastleIfRook(n, m.to);
  }

  _apply(n, m);

  // Mbreti ose kali që lëviz e humb të drejtën e rokadës.
  final int moved = pieceOf(moving);
  if (moved == king) {
    n.players[color].kingSideRook = null;
    n.players[color].queenSideRook = null;
  } else if (moved == rook) {
    _revokeCastleIfRook(n, m.from);
  }

  n.halfmove = (m.capturesPiece || moved == pawn) ? 0 : n.halfmove + 1;
  if (color == green) n.fullmove++;

  fourAdvance(n);
  return n;
}

void _revokeCastleIfRook(FourPosition p, int square) {
  for (final FourPlayer pl in p.players) {
    if (pl.kingSideRook == square) pl.kingSideRook = null;
    if (pl.queenSideRook == square) pl.queenSideRook = null;
  }
}

/// Kalo te lojtari tjetër i gjallë, duke nxjerrë jashtë këdo që s'ka lëvizje.
///
/// 🚨 Kjo është zemra e ndryshimit nga shahu dylojtarësh dhe vendi ku është më
/// e lehtë të gabohet: mati NUK e mbaron lojën, ai heq një lojtar. Loja
/// vazhdon me tre, pastaj me dy. Nëse kjo lidhje nuk bëhet, një lojtar i matuar
/// mbetet «në radhë» pa asnjë lëvizje dhe loja ngec përgjithmonë.
void fourAdvance(FourPosition p) {
  // Kush sapo luajti. Duhet mbajtur para se cikli ta lëvizë [FourPosition.turn]:
  // shpërblimi i matit i takon atij, dhe vetëm atij.
  final int mover = p.turn;

  for (int hop = 0; hop < 4; hop++) {
    p.turn = (p.turn + 1) % 4;
    final FourPlayer next = p.players[p.turn];
    if (!next.alive) continue;
    if (fourLegalMoves(p, p.turn).isNotEmpty) break;

    // Pa asnjë lëvizje: mat nëse është nën shah, pat nëse jo. Të dyja e nxjerrin
    // jashtë — ndryshe nga shahu dylojtarësh, ku pati është barazim.
    if (fourInCheck(p, p.turn) && p.players[mover].alive) {
      p.players[mover].points += matePoints;
    }
    fourEliminate(p, p.turn);
  }

  // Shpërblimi i të fundit në këmbë jepet KËTU, një herë të vetme. Te
  // [fourStatus] do të jepej sa herë lexohej gjendja — dhe pikët do të rriteshin
  // pa fund vetëm duke parë tabelën.
  final List<FourPlayer> alive = p.living.toList();
  if (alive.length == 1 && !p.lastStandAwarded) {
    p.lastStandAwarded = true;
    alive.first.points += matePoints;
  }
}

/// Nxirr një lojtar jashtë.
///
/// 🔑 Figurat e tij MBETEN në tabelë dhe mund të hahen për pikë; vetëm mbreti
/// hiqet. Kështu një lojtar i eliminuar nuk zhduket nga loja si të mos kishte
/// qenë kurrë — pozicioni i tij mbetet pengesë dhe pre për të tjerët, dhe kjo
/// është ajo që e bën Katërshin lojë aleancash e jo tri duele njëkohësisht.
void fourEliminate(FourPosition p, int color) {
  p.players[color].alive = false;
  p.players[color].kingSideRook = null;
  p.players[color].queenSideRook = null;
  final int k = p.kingSquareOf(color);
  if (k >= 0) p.board[k] = empty;
}

// ─────────────────────────────────────────────────────────────────────────────
// Fundi i lojës
// ─────────────────────────────────────────────────────────────────────────────

class FourStatus {
  const FourStatus({required this.over, this.winner, this.reason = ''});

  final bool over;

  /// Ngjyra që fitoi, ose null kur pikët janë të barabarta.
  final int? winner;
  final String reason;
}

/// 🔑 Fituesi del nga PIKËT, jo nga ai që mbetet i fundit. I fundit merr edhe
/// [matePoints], ndaj zakonisht fiton — por një lojtar që hëngri gjithçka dhe u
/// matua i fundit mund të dalë prapë përpara, dhe kjo është me qëllim: përndryshe
/// të tre do të prisnin thjesht që të tjerët të shuheshin.
FourStatus fourStatus(FourPosition p) {
  final List<FourPlayer> alive = p.living.toList();

  if (alive.length <= 1) {
    return FourStatus(over: true, winner: _bestByPoints(p), reason: 'i fundit në këmbë');
  }
  if (p.halfmove >= 100) {
    return FourStatus(over: true, winner: _bestByPoints(p), reason: '50 lëvizje pa ngrënie');
  }
  return const FourStatus(over: false);
}

int? _bestByPoints(FourPosition p) {
  int best = -1;
  int? who;
  bool tie = false;
  for (final FourPlayer pl in p.players) {
    if (pl.points > best) {
      best = pl.points;
      who = pl.color;
      tie = false;
    } else if (pl.points == best) {
      tie = true;
    }
  }
  return tie ? null : who;
}
