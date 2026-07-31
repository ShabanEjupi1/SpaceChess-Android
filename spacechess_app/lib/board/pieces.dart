import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

import '../app/theme.dart';

/// Figurat, të vizatuara me vektorë në një kuti 100×100 dhe të shkallëzuara te
/// kutia e tabelës.
///
/// 🚨 **Pse jo glifet Unicode ♔♕♖ si te faqja.** Në shfletues ato punojnë sepse
/// sistemi ka një shkronjë simbolesh; te Flutter-i, Roboto-ja NUK i ka dhe
/// rezerva varet nga pajisja — në disa telefonë Android të gjitha figurat dalin
/// katrorë bosh. Një aplikacion shahu ku tabela mund të dalë e zbrazët nuk është
/// aplikacion shahu. Pa imazhe gjithashtu: një grup i vetëm PNG-sh do të donte
/// pesë dendësi, do të rëndonte APK-në dhe do të turbullohej te tabletët.
///
/// 🔑 Të gjitha figurat ndajnë të njëjtin bazament dhe të njëjtën gjerësi
/// vizuale, ndryshe tabela duket e shtrembër: syri e lexon bazamentin si vijë
/// bazë, dhe një ushtar më i ngushtë se një kalorës e prish rreshtin.
void drawPiece(Canvas canvas, Rect box, int piece) {
  if (piece == empty || piece == off) return;

  final bool isWhite = piece > 0;
  final Paint fill = Paint()
    ..style = PaintingStyle.fill
    ..color = isWhite ? Palette.whitePiece : Palette.blackPiece;
  final Paint stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.4
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = isWhite ? const Color(0xFF3A3733) : const Color(0xFFCFC9C0);

  canvas.save();
  canvas.translate(box.left, box.top);
  canvas.scale(box.width / 100, box.height / 100);

  // Hija: një elips i sheshtë nën bazament. Pa të, figurat rrinë "mbi" tabelën
  // si ngjitëse; me të, ato qëndrojnë mbi kuti.
  canvas.drawOval(
    const Rect.fromLTRB(26, 84, 74, 92),
    Paint()..color = const Color(0x33000000),
  );

  final Path path = switch (piece.abs()) {
    pawn => _pawn(),
    knight => _knight(),
    bishop => _bishop(),
    rook => _rook(),
    queen => _queen(),
    _ => _king(),
  };

  canvas.drawPath(path, fill);
  canvas.drawPath(path, stroke);
  _details(canvas, piece.abs(), stroke);
  canvas.restore();
}

/// Bazamenti, i njëjtë për të gjitha figurat.
void _addBase(Path p) {
  p.addRRect(RRect.fromLTRBAndCorners(
    27, 76, 73, 87,
    topLeft: const Radius.circular(5),
    topRight: const Radius.circular(5),
    bottomLeft: const Radius.circular(3),
    bottomRight: const Radius.circular(3),
  ));
}

Path _pawn() {
  final Path p = Path()
    ..addOval(Rect.fromCircle(center: const Offset(50, 27), radius: 13))
    ..moveTo(40, 42)
    ..quadraticBezierTo(41, 60, 33, 76)
    ..lineTo(67, 76)
    ..quadraticBezierTo(59, 60, 60, 42)
    ..close();
  _addBase(p);
  return p;
}

Path _rook() {
  final Path p = Path()
    // Kullëzat: tri dhëmbë dhe një brez, si te një kullë.
    ..addRect(const Rect.fromLTRB(28, 18, 39, 32))
    ..addRect(const Rect.fromLTRB(45, 18, 55, 32))
    ..addRect(const Rect.fromLTRB(61, 18, 72, 32))
    ..addRRect(RRect.fromLTRBR(28, 28, 72, 38, const Radius.circular(2)))
    ..moveTo(35, 38)
    ..lineTo(65, 38)
    ..lineTo(68, 76)
    ..lineTo(32, 76)
    ..close();
  _addBase(p);
  return p;
}

Path _bishop() {
  final Path p = Path()
    ..addOval(Rect.fromCircle(center: const Offset(50, 14), radius: 5.5))
    // Mitra.
    ..moveTo(50, 20)
    ..cubicTo(67, 31, 69, 50, 60, 62)
    ..lineTo(40, 62)
    ..cubicTo(31, 50, 33, 31, 50, 20)
    ..close()
    ..addRRect(RRect.fromLTRBR(37, 61, 63, 69, const Radius.circular(3)))
    ..moveTo(43, 69)
    ..lineTo(57, 69)
    ..lineTo(62, 76)
    ..lineTo(38, 76)
    ..close();
  _addBase(p);
  return p;
}

/// 🕌 Ishte një kokë kali, me sy. Tani është **vetë lëvizja e kalorësit**: dy
/// hapa lart, një anash — një «L» e trashë, e pjerrët nga maja.
///
/// Nuk humb asgjë. Silueta mbetet e vetmja asimetrike te tabela, ndaj lexohet
/// te 36 pikselë edhe më shpejt se koka e kalit (asnjë figurë tjetër nuk ka
/// krah anash), dhe tani forma e shpjegon lëvizjen në vend që ta zbukurojë.
Path _knight() {
  final Path p = Path()
    ..moveTo(31, 76)
    ..lineTo(31, 28)
    ..lineTo(39, 14)
    ..lineTo(52, 14)
    ..lineTo(52, 54)
    ..lineTo(71, 54)
    ..lineTo(71, 76)
    ..close();
  _addBase(p);
  return p;
}

/// Yll tetëcepësh (*shems*), i vizatuar në drejtim orar që të bashkohet me
/// nënshtigjet e tjera nën `PathFillType.nonZero` — një yll në drejtim të
/// kundërt do të hapte vrimë në vend që të mbushte.
Path _yllTetecepesh(Offset c, double jashtem, double brendshem) {
  final Path p = Path();
  const int cepa = 8;
  for (int i = 0; i < cepa * 2; i++) {
    final double r = i.isEven ? jashtem : brendshem;
    final double kend = -pi / 2 + i * pi / cepa;
    final Offset pika = Offset(c.dx + r * cos(kend), c.dy + r * sin(kend));
    i == 0 ? p.moveTo(pika.dx, pika.dy) : p.lineTo(pika.dx, pika.dy);
  }
  return p..close();
}

Path _queen() {
  final Path p = Path()
    // Pesë majat e kurorës, me nga një top secila.
    ..addOval(Rect.fromCircle(center: const Offset(24, 26), radius: 5))
    ..addOval(Rect.fromCircle(center: const Offset(37, 19), radius: 5))
    ..addOval(Rect.fromCircle(center: const Offset(50, 16), radius: 5.5))
    ..addOval(Rect.fromCircle(center: const Offset(63, 19), radius: 5))
    ..addOval(Rect.fromCircle(center: const Offset(76, 26), radius: 5))
    ..moveTo(24, 27)
    ..lineTo(31, 57)
    ..lineTo(69, 57)
    ..lineTo(76, 27)
    ..lineTo(63, 41)
    ..lineTo(50, 20)
    ..lineTo(37, 41)
    ..close()
    ..addRRect(RRect.fromLTRBR(30, 56, 70, 65, const Radius.circular(3)))
    ..moveTo(34, 65)
    ..lineTo(66, 65)
    ..lineTo(69, 76)
    ..lineTo(31, 76)
    ..close();
  _addBase(p);
  return p;
}

Path _king() {
  final Path p = Path()
    // 🕌 Mbi kurorë rrinte një KRYQ. Tani rri ylli tetëcepësh: e njëjta punë
    // vizuale — një majë e vetme, e madhe, që e dallon mbretin nga pesë topat e
    // mbretëreshës me një vështrim — pa shenjën fetare të një feje tjetër.
    // Maja e poshtme e yllit takon kupolën te y≈34, ndaj figura mbetet e tërë.
    ..addPath(_yllTetecepesh(const Offset(50, 20), 14, 6.2), Offset.zero)
    ..moveTo(31, 57)
    ..cubicTo(19, 43, 33, 27, 50, 36)
    ..cubicTo(67, 27, 81, 43, 69, 57)
    ..close()
    ..addRRect(RRect.fromLTRBR(30, 56, 70, 65, const Radius.circular(3)))
    ..moveTo(34, 65)
    ..lineTo(66, 65)
    ..lineTo(69, 76)
    ..lineTo(31, 76)
    ..close();
  _addBase(p);
  return p;
}

/// Hollësitë që vizatohen VETËM me vijë, jo me mbushje — syri i oficerit dhe
/// e çara e mitrës. Të futura te silueta, ato do të hapnin vrima në figurë.
void _details(Canvas canvas, int type, Paint stroke) {
  switch (type) {
    case bishop:
      canvas.drawLine(const Offset(50, 30), const Offset(50, 46), stroke);
    // 🕌 Kalorësi kishte një sy (një rreth te koka e kalit). U hoq bashkë me
    // kokën: forma e re është gjeometri, dhe një sy mbi të do të ishte pikërisht
    // gjëja që u hoq, e ngjitur prapa.
    default:
      break;
  }
}
