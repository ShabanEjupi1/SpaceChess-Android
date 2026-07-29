import 'package:flutter/material.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

import '../app/theme.dart';
import 'pieces.dart';

/// Tabela.
///
/// 🔑 **Prekje-prekje, jo tërheqje.** Me një gisht mbi një ekran 6-inçësh,
/// tërheqja e fsheh figurën nën vetë gishtin pikërisht kur duhet parë ku po
/// shkon. Prekja e parë zgjedh, e dyta luan — dhe kutitë e ligjshme ndriçohen
/// mes tyre, që lojtari fillestar të mësojë lëvizjet duke luajtur.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.position,
    required this.onTap,
    this.selected,
    this.targets = const <int>[],
    this.lastMove,
    this.flipped = false,
    this.interactive = true,
  });

  final Position position;
  final ValueChanged<int> onTap;

  /// Kutia e zgjedhur, ose null.
  final int? selected;

  /// Kutitë ku figura e zgjedhur mund të shkojë.
  final List<int> targets;

  final Move? lastMove;
  final bool flipped;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double side =
            c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight;
        return SizedBox(
          width: side,
          height: side,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: interactive
                ? (TapUpDetails d) {
                    final double cell = side / 8;
                    int file = (d.localPosition.dx / cell).floor();
                    int rank = 7 - (d.localPosition.dy / cell).floor();
                    if (flipped) {
                      file = 7 - file;
                      rank = 7 - rank;
                    }
                    if (file < 0 || file > 7 || rank < 0 || rank > 7) return;
                    onTap(sq(file, rank));
                  }
                : null,
            child: CustomPaint(
              painter: _BoardPainter(
                position: position,
                selected: selected,
                targets: targets,
                lastMove: lastMove,
                flipped: flipped,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.position,
    required this.selected,
    required this.targets,
    required this.lastMove,
    required this.flipped,
  });

  final Position position;
  final int? selected;
  final List<int> targets;
  final Move? lastMove;
  final bool flipped;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 8;
    final int? checkedKing = inCheck(position)
        ? position.kingSquare(position.side)
        : null;

    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final int square = sq(file, rank);
        final int col = flipped ? 7 - file : file;
        final int row = flipped ? rank : 7 - rank;
        final Rect box =
            Rect.fromLTWH(col * cell, row * cell, cell, cell);

        canvas.drawRect(
          box,
          Paint()
            ..color = (file + rank).isEven ? Palette.dark : Palette.light,
        );

        if (lastMove != null &&
            (square == lastMove!.from || square == lastMove!.to)) {
          canvas.drawRect(box, Paint()..color = Palette.lastMove);
        }
        if (square == checkedKing) {
          canvas.drawRect(box, Paint()..color = Palette.check);
        }
        if (square == selected) {
          canvas.drawRect(box, Paint()..color = const Color(0x556EA8FE));
        }

        // Koordinatat vetëm te buza, si te një tabelë e vërtetë: brenda kutive
        // ato konkurrojnë me figurat.
        if (row == 7 || col == 0) {
          _label(canvas, box, cell, file, rank, row == 7, col == 0);
        }

        drawPiece(canvas, box.deflate(cell * 0.06), position.pieceAt(square));

        if (targets.contains(square)) {
          final bool occupied = position.pieceAt(square) != empty;
          if (occupied) {
            // Një unazë mbi figurë do të thotë «hahet»; një pikë do të humbiste
            // nën të.
            canvas.drawCircle(
              box.center,
              cell * 0.44,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = cell * 0.07
                ..color = const Color(0xAA6EA8FE),
            );
          } else {
            canvas.drawCircle(
              box.center,
              cell * 0.15,
              Paint()..color = const Color(0x886EA8FE),
            );
          }
        }
      }
    }
  }

  void _label(Canvas canvas, Rect box, double cell, int file, int rank,
      bool bottom, bool left) {
    final Color ink =
        (file + rank).isEven ? Palette.light : Palette.dark;
    void write(String text, Offset at) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: ink,
            fontSize: cell * 0.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at);
    }

    if (bottom) {
      write('abcdefgh'[file],
          Offset(box.right - cell * 0.22, box.bottom - cell * 0.26));
    }
    if (left) {
      write('${rank + 1}',
          Offset(box.left + cell * 0.06, box.top + cell * 0.04));
    }
  }

  // Rivizatohet gjithmonë. Krahasimi i saktë do të donte një çelës të tërë
  // pozicioni (FEN), që kushton më shumë se vetë vizatimi — dhe një krahasim i
  // përafërt (p.sh. vetëm gjatësia e [targets]) jep një tabelë që herë-herë nuk
  // përditësohet, gabimi më i keq i mundshëm këtu. `paint` thirret vetëm pas
  // një `setState`, jo në çdo kuadër.
  @override
  bool shouldRepaint(_BoardPainter old) => true;
}
