import 'package:flutter_test/flutter_test.dart';
import 'package:spacechess/data/enigmat.g.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

/// Provimi i enigmave — i pavarur nga gjeneruesi.
///
/// 🔑 Gjeneruesi dhe ky test e kontrollojnë të njëjtën gjë me dy rrugë të
/// ndryshme, dhe kjo është me qëllim: `enigmat.g.dart` është skedar i
/// gjeneruar që hyn te depoja, pra dikush mund ta ndryshojë me dorë ose ta
/// bashkojë gabim. Nëse ky test bie, enigma është e prishur dhe lojtari do të
/// mendonte se gaboi ai.
void main() {
  group('Enigmat', () {
    test('lista nuk është bosh dhe nuk ka pozicione të dyfishta', () {
      expect(enigmat.length, greaterThanOrEqualTo(20));
      final Set<String> pare = <String>{};
      for (final Enigma e in enigmat) {
        expect(pare.add(e.fen), isTrue, reason: 'pozicion i dyfishtë: ${e.fen}');
      }
    });

    test('çdo enigmë nis me të bardhin në lëvizje dhe pa shah', () {
      for (final Enigma e in enigmat) {
        final Position p = fromFen(e.fen);
        expect(p.side, white, reason: e.fen);
        expect(inCheck(p, black), isFalse,
            reason: 'i ziu është tashmë në shah te ${e.fen}');
        expect(inCheck(p, white), isFalse,
            reason: 'i bardhi është në shah te ${e.fen}');
      }
    });

    test('zgjidhja është e ligjshme dhe e VETMJA që jep mat të detyruar', () {
      for (final Enigma e in enigmat) {
        final Position p = fromFen(e.fen);
        final List<Move> fituese = <Move>[
          for (final Move m in legalMoves(p))
            if (_maton(p, m, e.hapa)) m,
        ];
        expect(fituese.map((Move m) => m.uci).toList(), <String>[e.zgjidhja],
            reason: 'te ${e.fen} zgjidhja duhet të jetë e vetme');
      }
    });

    test('luajtja e zgjidhjes e çon lojën te mat-i, pa asnjë degë të lirë', () {
      for (final Enigma e in enigmat) {
        final Game g = Game(fen: e.fen);
        expect(g.applyUci(e.zgjidhja), isTrue, reason: e.fen);

        if (e.hapa == 1) {
          expect(g.status.reason, EndReason.checkmate, reason: e.fen);
          continue;
        }

        // Mat në dy: pas çdo përgjigjeje të mundshme të të ziut duhet të mbetet
        // një lëvizje e bardhë që jep mat. Kontrollohen TË GJITHA përgjigjet —
        // «i detyruar» do të thotë pikërisht kjo.
        expect(g.isOver, isFalse, reason: '${e.fen} mbaroi që te hapi i parë');
        for (final Move pergjigjja in g.legal) {
          final Position pas = makeMove(g.position, pergjigjja);
          final bool gjendet = legalMoves(pas).any((Move mbyllja) {
            final Position fundi = makeMove(pas, mbyllja);
            return legalMoves(fundi).isEmpty && inCheck(fundi, black);
          });
          expect(gjendet, isTrue,
              reason: 'te ${e.fen}, pas ${pergjigjja.uci} i ziu shpëton');
        }
      }
    });

    test('nuk ka enigma me më shumë se dy hapa', () {
      for (final Enigma e in enigmat) {
        expect(e.hapa, anyOf(1, 2), reason: e.fen);
      }
    });
  });
}

/// A e jep [m] matin brenda [hapa] lëvizjesh të bardha, sido që të luajë i ziu?
bool _maton(Position p, Move m, int hapa) {
  final Position pas = makeMove(p, m);
  final List<Move> pergjigjet = legalMoves(pas);

  if (pergjigjet.isEmpty) {
    // Pa përgjigje: mat vetëm nëse është shah. Pati nuk fiton.
    return hapa == 1 && inCheck(pas, black);
  }
  if (hapa == 1) return false;

  for (final Move pergj in pergjigjet) {
    final Position pas2 = makeMove(pas, pergj);
    final bool gjendet = legalMoves(pas2).any((Move mbyllja) {
      final Position fundi = makeMove(pas2, mbyllja);
      return legalMoves(fundi).isEmpty && inCheck(fundi, black);
    });
    if (!gjendet) return false;
  }
  return true;
}
