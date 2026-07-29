import 'package:flutter/foundation.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

/// E vë kompjuterin të mendojë JASHTË fillit të ndërfaqes.
///
/// 🚨 Niveli «Maksimal» kërkon deri në katër sekonda. Në fillin e ndërfaqes kjo
/// do të thotë katër sekonda pa vizatim, pa prekje dhe pa animacion — Android-i
/// e quan aplikacionin «nuk përgjigjet» dhe i ofron përdoruesit ta mbyllë. Në
/// web, ku `compute` bie prapa te i njëjti fill, kjo është arsyeja pse nivelet e
/// larta duhen matur para se të ofrohen atje.
Future<String?> thinkMove({
  required String startFen,
  required List<String> moves,
  required String variant,
  required int level,
}) =>
    compute(_think, <String, dynamic>{
      'fen': startFen,
      'moves': moves,
      'variant': variant,
      'level': level,
    });

/// Ekzekutohet në një isolate tjetër, ndaj merr dhe kthen vetëm tekst.
///
/// 🔑 Loja rindërtohet duke riluajtur lëvizjet, jo duke dërguar tabelën: vetëm
/// kështu isolate-i sheh edhe përsëritjet edhe numëruesin e 50 lëvizjeve, dhe
/// vlerëson të njëjtën lojë që sheh lojtari. Një FEN i vetëm do t'i fshihte të
/// dyja, dhe motori do të hynte i qetë në një përsëritje të humbur.
String? _think(Map<String, dynamic> args) {
  final Variant variant = Variant.values.firstWhere(
    (Variant v) => v.name == args['variant'],
    orElse: () => Variant.standard,
  );

  final Game game = Game(variant: variant, fen: args['fen'] as String);
  for (final String uci in (args['moves'] as List<dynamic>).cast<String>()) {
    if (!game.applyUci(uci)) return null;
  }

  final Move? best = chooseMove(game.position, levelId: args['level'] as int);
  return best?.uci;
}
