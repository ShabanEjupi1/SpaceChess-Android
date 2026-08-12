import 'package:flutter/material.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

import '../app/theme.dart';
import 'pieces.dart';

/// Ngjyrat e katër ushtrive.
///
/// 🚨 Të katërta duhet të dallohen mbi TË DYJA kutitë e tabelës, të çelëtat dhe
/// të errëtat. Blu-ja e faqes (`#4C7DF0`) mbi kutinë e errët `#9C7B4E` binte te
/// e njëjta ndriçim — pra dy ushtri të ndryshme dukeshin njësoj te gjysma e
/// tabelës. Prandaj çdo figurë ka edhe një vijë ANASJELLTAS: e çelët për
/// ushtritë e errëta, e errët për ato të çelëtat. Forma mbetet e lexueshme edhe
/// kur ngjyra nuk mjafton.
abstract final class FourPalette {
  static const List<Color> body = <Color>[
    Color(0xFFD64B4B), // e kuqe
    Color(0xFF4C7DF0), // blu
    Color(0xFFE8C64A), // e verdhë
    Color(0xFF46B25B), // jeshile
  ];

  static const List<Color> ink = <Color>[
    Color(0xFF3A0E0E),
    Color(0xFF0B1C44),
    Color(0xFF4A3B06),
    Color(0xFF0C2E14),
  ];

  /// Kutia e vogël te paneli anësor.
  static Color chip(int color) => body[color];
}

/// Tabela e Katërshit: 14×14 me katër qoshe 3×3 të prera.
///
/// 🔑 **Përse e njëjta [CustomPaint] nuk ripërdorej nga [BoardView].** Ajo
/// tabelë e di se ka 8×8 kuti, dy ngjyra dhe një [Position]; këtu asnjëra nga të
/// treja nuk qëndron. Një widget i vetëm me `if (katërsh)` te çdo rresht do të
/// ishte dy tabela të gërshetuara — dhe ndreqja e njërës do të prishte tjetrën.
/// Ajo që ndahet vërtet janë **figurat** ([drawPieceShape]), sepse ato janë e
/// vetmja gjë që lojtari e krahason mes dy modaliteteve.
class FourBoardView extends StatelessWidget {
  const FourBoardView({
    super.key,
    required this.position,
    required this.onTap,
    this.selected,
    this.targets = const <int>[],
    this.lastMove,
    this.interactive = true,
  });

  final FourPosition position;
  final ValueChanged<int> onTap;
  final int? selected;
  final List<int> targets;
  final FourMove? lastMove;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double side = c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight;
        return SizedBox(
          width: side,
          height: side,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: interactive
                ? (TapUpDetails d) {
                    final double cell = side / 14;
                    final int file = (d.localPosition.dx / cell).floor();
                    // E kuqja luan nga POSHTË, si i bardhi te shahu i zakonshëm:
                    // rreshti 0 është rreshti i fundit i ekranit.
                    final int rank = 13 - (d.localPosition.dy / cell).floor();
                    if (!fourOnBoard(file, rank)) return;
                    onTap(fourSq(file, rank));
                  }
                : null,
            child: CustomPaint(
              painter: _FourPainter(
                position: position,
                selected: selected,
                targets: targets,
                lastMove: lastMove,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FourPainter extends CustomPainter {
  _FourPainter({
    required this.position,
    required this.selected,
    required this.targets,
    required this.lastMove,
  });

  final FourPosition position;
  final int? selected;
  final List<int> targets;
  final FourMove? lastMove;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 14;

    // Mbretërit nën shah: TË GJITHË, jo vetëm ai që është në radhë. Te katër
    // lojtarë një shah mund t'i vijë edhe atij që sapo luajti, nga një i tretë —
    // dhe po të shënohej vetëm ai në radhë, lojtari do ta mësonte për sherrin e
    // vet një radhë më vonë.
    final Set<int> checked = <int>{};
    for (final FourPlayer pl in position.players) {
      if (!pl.alive) continue;
      if (fourInCheck(position, pl.color)) {
        final int k = position.kingSquareOf(pl.color);
        if (k >= 0) checked.add(k);
      }
    }

    for (int rank = 0; rank < 14; rank++) {
      for (int file = 0; file < 14; file++) {
        if (!fourOnBoard(file, rank)) continue;
        final int square = fourSq(file, rank);
        final Rect box = Rect.fromLTWH(
          file * cell,
          (13 - rank) * cell,
          cell,
          cell,
        );

        canvas.drawRect(
          box,
          Paint()
            ..color = (file + rank).isEven ? Palette.dark : Palette.light,
        );

        if (lastMove != null &&
            (square == lastMove!.from || square == lastMove!.to)) {
          canvas.drawRect(box, Paint()..color = Palette.lastMove);
        }
        if (checked.contains(square)) {
          canvas.drawRect(box, Paint()..color = Palette.check);
        }
        if (square == selected) {
          canvas.drawRect(box, Paint()..color = const Color(0x556EA8FE));
        }

        final int code = position.board[square];
        if (code != empty && code != fourOff) {
          final int color = colorOf(code);
          drawPieceShape(
            canvas,
            box.deflate(cell * 0.05),
            pieceOf(code),
            fill: FourPalette.body[color],
            ink: FourPalette.ink[color],
          );
        }

        if (targets.contains(square)) {
          final bool occupied = code != empty && code != fourOff;
          if (occupied) {
            canvas.drawCircle(
              box.center,
              cell * 0.44,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = cell * 0.09
                ..color = const Color(0xDD121821),
            );
          } else {
            canvas.drawCircle(
              box.center,
              cell * 0.16,
              Paint()..color = const Color(0xAA121821),
            );
          }
        }
      }
    }

    _armyEdges(canvas, cell);
  }

  /// Një vijë e trashë te buza e secilës ushtri.
  ///
  /// 🔑 Pa të, një lojtar i ri nuk e di nga cila anë luan: te një tabelë në
  /// formë kryqi «poshtë» nuk do të thotë asgjë derisa ta shohësh se cilat
  /// figura rrinë aty. Vija e ngjyros anën, jo figurat.
  void _armyEdges(Canvas canvas, double cell) {
    final double w = cell * 0.16;
    void edge(int color, Rect r) {
      canvas.drawRect(r, Paint()..color = FourPalette.body[color]);
    }

    final double armStart = 3 * cell;
    final double armLen = 8 * cell;
    edge(red, Rect.fromLTWH(armStart, 14 * cell - w, armLen, w));
    edge(yellow, Rect.fromLTWH(armStart, 0, armLen, w));
    edge(blue, Rect.fromLTWH(0, armStart, w, armLen));
    edge(green, Rect.fromLTWH(14 * cell - w, armStart, w, armLen));
  }

  // Rivizatohet gjithmonë — i njëjti arsyetim si te [BoardView]: një krahasim i
  // përafërt jep një tabelë që herë-herë nuk përditësohet, dhe ai është gabimi
  // më i keq i mundshëm këtu.
  @override
  bool shouldRepaint(_FourPainter old) => true;
}
