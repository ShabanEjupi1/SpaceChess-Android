import 'board.dart';
import 'moves.dart';

const String _files = 'abcdefgh';

/// Shënimi standard algjebrik — ai që lexon një njeri dhe që PGN-ja kërkon.
///
/// Duhet dhënë pozicioni PARA lëvizjes: pa të nuk dihet as cila figurë lëvizi,
/// as cilat figura të tjera mund të shkonin te e njëjta kuti (dyzimi), as nëse
/// lëvizja jep shah apo mat.
String toSan(Position p, Move m) {
  if (m.castle != null) {
    final String base = m.castle == CastleSide.king ? 'O-O' : 'O-O-O';
    return base + _suffix(p, m);
  }

  final int moving = p.board[m.from].abs();
  final StringBuffer s = StringBuffer();

  if (moving == pawn) {
    if (m.capturesPiece) {
      s.write(_files[fileOf(m.from)]);
      s.write('x');
    }
    s.write(algebraic(m.to));
    if (m.promo != 0) {
      s.write('=');
      s.write(pieceChar[m.promo]!.toUpperCase());
    }
  } else {
    s.write(pieceChar[moving]!.toUpperCase());

    // Dyzimi kundrejt çdo figure tjetër të të njëjtit lloj që MUND të shkonte
    // ligjshëm atje. «Mund të shkonte» e jo «rri diku» — një kalorës i lidhur
    // nuk krijon dyzim, dhe një `Nbd2` i panevojshëm është PGN i gabuar.
    final List<Move> rivals = legalMoves(p)
        .where((Move o) =>
            o.to == m.to &&
            o.from != m.from &&
            o.castle == null &&
            p.board[o.from].abs() == moving)
        .toList(growable: false);

    if (rivals.isNotEmpty) {
      final bool sameFile =
          rivals.any((Move o) => fileOf(o.from) == fileOf(m.from));
      final bool sameRank =
          rivals.any((Move o) => rankOf(o.from) == rankOf(m.from));
      if (!sameFile) {
        s.write(_files[fileOf(m.from)]);
      } else if (!sameRank) {
        s.write(rankOf(m.from) + 1);
      } else {
        s.write(algebraic(m.from));
      }
    }

    if (m.capturesPiece) s.write('x');
    s.write(algebraic(m.to));
  }

  return s.toString() + _suffix(p, m);
}

String _suffix(Position p, Move m) {
  final Position next = makeMove(p, m);
  if (!inCheck(next)) return '';
  return legalMoves(next).isEmpty ? '#' : '+';
}
