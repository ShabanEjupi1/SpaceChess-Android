import 'board.dart';
import 'moves.dart';

/// Numëron gjethet e pemës së lëvizjeve deri në [depth].
///
/// 🔑 **Perft-i është rrjeta e sigurisë e këtij motori, jo një stërvitje.** Një
/// motor shahu gabon te pozicionet që askush nuk i provon me dorë — en passant
/// që zbulon mbretin, rokada nëpër një kuti të sulmuar, kali i rokadës që hahet
/// mbi kutinë e vet — dhe të gjitha këto e ndryshojnë numrin e gjetheve. Një
/// numër i vetëm i gabuar e kap gabimin; asnjë test «me sy» nuk e kap.
///
/// Numrat e pritur janë të njohur publikisht (Chess Programming Wiki), pra ky
/// test nuk mat veten: mat motorin kundrejt shahut.
int perft(Position p, int depth) {
  if (depth == 0) return 1;
  final List<Move> moves = legalMoves(p);
  if (depth == 1) return moves.length;

  int total = 0;
  for (final Move m in moves) {
    total += perft(makeMove(p, m), depth - 1);
  }
  return total;
}

/// Perft i ndarë sipas lëvizjes së parë — e vetmja mënyrë praktike për të gjetur
/// KU gabon motori: krahaso këtë tabelë me atë të një motori referencë dhe
/// zbrit te dega që nuk përputhet.
Map<String, int> perftDivide(Position p, int depth) {
  final Map<String, int> out = <String, int>{};
  for (final Move m in legalMoves(p)) {
    out[m.uci] = perft(makeMove(p, m), depth - 1);
  }
  return out;
}
