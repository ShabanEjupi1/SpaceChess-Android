import 'dart:math';
import 'package:spacechess_engine/spacechess_engine.dart';

Levizja _arsyeshem(Dora d, Random r) {
  final une = d.radha;
  final l = d.levizjet();
  Levizja? m0; var b = -1000;
  for (final m in l) {
    final p = d.luaj(m);
    if (p.fituesi() == une) return m;
    final s = p.grupiMeIMadh(une) * 3 - p.grupiMeIMadh(une.kundershtari);
    if (s > b) { b = s; m0 = m; }
  }
  return m0 ?? l[r.nextInt(l.length)];
}

void main() {
  final r = Random(3);
  var d = Dora.nisja();
  for (final n in [0, 1, 2, 3, 10, 40, 199]) {
    while (d.radhet < n && !d.mbaroi) { d = d.luaj(_arsyeshem(d, r)); }
    var ng = 0, a = 0, b = 0;
    for (var i = 0; i < Dora.fusha; i++) {
      if (d.ngulitur(i)) ng++;
      if (d[i] == Zoti.i_pari) a++;
      if (d[i] == Zoti.i_dyti) b++;
    }
    print('radha ${d.radhet}: gurë A=$a B=$b · ngulitur=$ng · '
        'grupi A=${d.grupiMeIMadh(Zoti.i_pari)} B=${d.grupiMeIMadh(Zoti.i_dyti)} · '
        'lëvizje=${d.levizjet().length}');
  }
  print('\n${d.skica()}');
}
