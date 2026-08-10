/// Mat «Dorën e Huaj» — a mbaron loja, sa zgjat, dhe a ka i pari epërsi.
///
///     dart run tool/mat_dora.dart
///
/// 🚨 Kjo vegël ekziston sepse dizajni i një loje të re është hamendje derisa të
/// matet. E njëjta gjë u bë te Kulla (`vegla/mat.gd`), ku pragu i guximit doli
/// ~50% — një numër që askush nuk do ta kishte zgjedhur me dorë. Këtu pyetjet
/// janë tri, dhe secila mund ta vrasë lojën:
///
///   1. **A mbaron?** Rregulli i ko-së u shtua pikërisht sepse pa të përgjigjja
///      ishte «jo». Kjo vegël e mat me dhe pa të.
///   2. **Sa zgjat?** Një lojë telefoni që kërkon 150 radhë nuk luhet dy herë.
///   3. **A fiton i pari gjithmonë?** Te një lojë 6×6 pa fat, një epërsi e madhe
///      e të parit do të thoshte se gjysma e ndeshjeve janë të vendosura para se
///      të nisin.
import 'dart:math';

import 'package:spacechess_engine/spacechess_engine.dart';

/// Lojtar krejt i rastësishëm — kufiri i poshtëm i çdo matjeje.
Levizja _rastesor(Dora d, Random r) {
  final l = d.levizjet();
  return l[r.nextInt(l.length)];
}

/// Lojtar me arsye: merr fitoren po qe se ekziston, përndryshe zgjedh lëvizjen
/// që i rrit grupin e vet më shumë dhe ia zvogëlon kundërshtarit.
///
/// 🔑 Nuk është AI e lojës — është një lojtar «jo budalla», dhe pikërisht ai
/// duhet për matje: numrat e nxjerrë nga dy lojtarë krejt të rastësishëm nuk
/// thonë asgjë për lojën që do të luajë njeriu. Kjo u mësua te Kulla, ku një
/// lojtar i rastësishëm e rrëzoi kullën te 12 nga 12 raunde dhe rregulli i
/// fituesit nuk u ekzekutua asnjëherë.
Levizja _arsyeshem(Dora d, Random r) {
  final une = d.radha;
  final l = d.levizjet();
  Levizja? meMira;
  var meMiri = -1000;
  for (final m in l) {
    final pas = d.luaj(m);
    if (pas.fituesi() == une) return m;
    final pikat = pas.grupiMeIMadh(une) * 3 - pas.grupiMeIMadh(une.kundershtari);
    if (pikat > meMiri) {
      meMiri = pikat;
      meMira = m;
    }
  }
  return meMira ?? l[r.nextInt(l.length)];
}

class _Rezultati {
  int iPari = 0;
  int iDyti = 0;
  int barazim = 0;
  final List<int> gjatesite = [];

  int get sa => iPari + iDyti + barazim;
  double get mesatarja =>
      gjatesite.isEmpty ? 0 : gjatesite.reduce((a, b) => a + b) / gjatesite.length;

  @override
  String toString() {
    final p = (iPari * 100 / sa).toStringAsFixed(0);
    final d = (iDyti * 100 / sa).toStringAsFixed(0);
    final b = (barazim * 100 / sa).toStringAsFixed(0);
    return 'i pari $p% · i dyti $d% · barazim $b% · '
        'gjatësia mes. ${mesatarja.toStringAsFixed(0)} radhë';
  }
}

_Rezultati _luaj(int sa, Levizja Function(Dora, Random) lojtari, {int fara = 7}) {
  final r = Random(fara);
  final rez = _Rezultati();
  for (var n = 0; n < sa; n++) {
    var d = Dora.nisja();
    while (!d.mbaroi) {
      d = d.luaj(lojtari(d, r));
    }
    final f = d.fituesi();
    if (f == Zoti.i_pari) {
      rez.iPari++;
    } else if (f == Zoti.i_dyti) {
      rez.iDyti++;
    } else {
      rez.barazim++;
    }
    rez.gjatesite.add(d.radhet);
  }
  return rez;
}

void main() {
  const sa = 200;
  print('«Dora e Huaj» — $sa ndeshje për rresht, fushë ${Dora.ana}×${Dora.ana}, '
      'synimi ${Dora.fitorja}, kufiri ${Dora.radheMaks} radhë\n');

  final rast = _luaj(sa, _rastesor);
  print('rastësor  ↔ rastësor : $rast');

  final arsye = _luaj(sa, _arsyeshem);
  print('arsyeshëm ↔ arsyeshëm: $arsye');

  // 🚨 Sa ndeshje e prekin kufirin e radhëve? Ky është kontrolli i vërtetë i
  // rregullit të ko-së: nëse shumica e prekin, loja NUK mbaron vetë — kufiri
  // thjesht e fsheh atë.
  final prekinKufirin =
      arsye.gjatesite.where((g) => g >= Dora.radheMaks).length;
  print('\nndeshje që prekin kufirin (${Dora.radheMaks}): '
      '$prekinKufirin nga $sa (lojtarë të arsyeshëm)');
  final prekinRast = rast.gjatesite.where((g) => g >= Dora.radheMaks).length;
  print('po ashtu me lojtarë të rastësishëm: $prekinRast nga $sa');
}
