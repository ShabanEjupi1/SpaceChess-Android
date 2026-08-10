import 'dart:math';
import 'package:spacechess_engine/spacechess_engine.dart';

Levizja _arsyeshem(Dora d, Random r) {
  final une = d.radha;
  final l = d.levizjet();
  Levizja? m0;
  var b = -1000;
  for (final m in l) {
    final p = d.luaj(m);
    if (p.fituesi() == une) return m;
    final s = p.grupiMeIMadh(une) * 3 - p.grupiMeIMadh(une.kundershtari);
    if (s > b) { b = s; m0 = m; }
  }
  return m0 ?? l[r.nextInt(l.length)];
}

void main() {
  for (final ng in [2, 3]) {
    for (final fit in [4, 5, 6]) {
      Dora.nguljes = ng;
      Dora.fitorja = fit;
      final r = Random(11);
      var a = 0, b = 0, x = 0, gj = 0;
      for (var n = 0; n < 120; n++) {
        var d = Dora.nisja();
        while (!d.mbaroi) { d = d.luaj(_arsyeshem(d, r)); }
        gj += d.radhet;
        final f = d.fituesi();
        if (f == Zoti.i_pari) a++; else if (f == Zoti.i_dyti) b++; else x++;
      }
      print('ngulje=$ng fitorja=$fit → i pari ${(a*100/120).round()}% · '
          'i dyti ${(b*100/120).round()}% · barazim ${(x*100/120).round()}% · '
          'gjatësia ${(gj/120).round()}');
    }
  }
}
