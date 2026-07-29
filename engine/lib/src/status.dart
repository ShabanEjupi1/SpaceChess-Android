import 'board.dart';
import 'moves.dart';

/// Pse mbaroi loja. Ruhet si emër i shkurtër sepse i njëjti varg udhëton te
/// serveri dhe te PGN-ja.
enum EndReason {
  checkmate,
  stalemate,
  fifty,
  material,
  repetition,
  threecheck,
  koth,
  antichess,
  resign,
  timeout,
  agreement,
}

class GameStatus {
  const GameStatus.running({required this.check, required this.moveCount})
      : over = false,
        result = null,
        reason = null;

  const GameStatus.finished(this.result, this.reason)
      : over = true,
        check = false,
        moveCount = 0;

  final bool over;

  /// `1-0`, `0-1` ose `1/2-1/2`.
  final String? result;
  final EndReason? reason;
  final bool check;
  final int moveCount;
}

bool insufficientMaterial(Position p) {
  // Te antishahu edhe një ushtar i vetëm mjafton për të humbur — pra për të
  // fituar. Asnjë material nuk është «i pamjaftueshëm».
  if (p.variant == Variant.antichess) return false;

  final List<int> types = <int>[];
  final List<bool> darkSquare = <bool>[];
  for (int s = 21; s <= 98; s++) {
    final int v = p.board[s];
    if (v == empty || v == off || v.abs() == king) continue;
    types.add(v.abs());
    darkSquare.add((fileOf(s) + rankOf(s)) % 2 == 0);
  }

  if (types.isEmpty) return true; // mbret kundër mbreti
  if (types.length == 1 && (types[0] == bishop || types[0] == knight)) {
    return true;
  }
  // Sado oficerë, nëse rrinë të gjithë mbi kuti të një ngjyre, mat nuk bëhet.
  if (types.every((int t) => t == bishop) &&
      darkSquare.every((bool d) => d == darkSquare[0])) {
    return true;
  }
  return false;
}

/// Çelësi i përsëritjes: tabela + ana + rokadat + en passant, pra pikërisht
/// katër fushat e para të FEN-it. Numri i lëvizjeve NUK hyn — dy pozicione të
/// njëjta te lëvizja 20 dhe 40 janë i njëjti pozicion.
String repetitionKey(Position p) => toFen(p).split(' ').take(4).join(' ');

GameStatus gameStatus(Position p, [List<String> history = const <String>[]]) {
  final List<Move> moves = legalMoves(p);
  final bool check = inCheck(p);

  if (p.variant == Variant.threecheck) {
    if (p.whiteChecks >= 3) {
      return const GameStatus.finished('1-0', EndReason.threecheck);
    }
    if (p.blackChecks >= 3) {
      return const GameStatus.finished('0-1', EndReason.threecheck);
    }
  }

  if (p.variant == Variant.koth) {
    for (final int c in <int>[white, black]) {
      final int? k = p.kingSquare(c);
      if (k != null && hill.contains(k)) {
        return GameStatus.finished(c == white ? '1-0' : '0-1', EndReason.koth);
      }
    }
  }

  if (p.variant == Variant.antichess) {
    // Të mbetesh pa figura ose pa lëvizje FITON te antishahu.
    int count = 0;
    for (int s = 21; s <= 98; s++) {
      final int v = p.board[s];
      if (v != empty && v != off && (v > 0 ? white : black) == p.side) count++;
    }
    if (count == 0 || moves.isEmpty) {
      return GameStatus.finished(
          p.side == white ? '1-0' : '0-1', EndReason.antichess);
    }
  } else if (moves.isEmpty) {
    if (check) {
      return GameStatus.finished(
          p.side == white ? '0-1' : '1-0', EndReason.checkmate);
    }
    return const GameStatus.finished('1/2-1/2', EndReason.stalemate);
  }

  if (p.halfmove >= 100) {
    return const GameStatus.finished('1/2-1/2', EndReason.fifty);
  }
  if (insufficientMaterial(p)) {
    return const GameStatus.finished('1/2-1/2', EndReason.material);
  }

  final String key = repetitionKey(p);
  if (history.where((String h) => h == key).length >= 3) {
    return const GameStatus.finished('1/2-1/2', EndReason.repetition);
  }

  return GameStatus.running(check: check, moveCount: moves.length);
}
