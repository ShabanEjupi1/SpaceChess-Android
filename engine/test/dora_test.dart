import 'package:spacechess_engine/spacechess_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Dora e Huaj — rregullat', () {
    test('nisja vë gjashtë gurë të secilit, të ndërthurur', () {
      final d = Dora.nisja();
      var a = 0;
      var b = 0;
      for (var i = 0; i < Dora.fusha; i++) {
        if (d[i] == Zoti.i_pari) a++;
        if (d[i] == Zoti.i_dyti) b++;
      }
      expect(a, 6);
      expect(b, 6);
      // Të ndërthurur: dy gurë ngjitur te rreshti i parë nuk janë të njëjtit.
      expect(d[0], isNot(d[1]));
    });

    // 🚨 Rregulli që e bën lojën. Pa këtë provë, një «përmirësim» që lejon
    // lëvizjen e gurëve të vet do të kalonte pa u vënë re — dhe atëherë loja
    // bëhet një lojë e zakonshme lëvizjeje, pa asnjë gjë të re për të treguar.
    test('NUK lëvizen dot gurët e vet', () {
      final d = Dora.nisja();
      for (final l in d.levizjet()) {
        expect(d[l.nga], isNot(Zoti.i_pari),
            reason: 'i pari lëvizi një gur të vetin: $l');
      }
    });

    test('guri i lëvizur BËHET i atij që e lëvizi', () {
      final d = Dora.nga(
        '''
        ......
        ..B...
        ......
        ......
        ......
        ......
        ''',
      );
      final pas = d.luaj(const Levizja(8, 14));
      expect(pas[14], Zoti.i_pari, reason: 'guri duhet të ketë ndërruar pronar');
      expect(pas[8], Zoti.bosh);
    });

    test('nuk lëvizet te një fushë e zënë', () {
      final d = Dora.nga(
        '''
        ......
        ..BB..
        ......
        ......
        ......
        ......
        ''',
      );
      expect(d.levizjet().contains(const Levizja(8, 9)), isFalse);
    });

    // 🚨🚨 Rregulli i ko-së. Pa të, të dy lojtarët marrin pafundësisht të njëjtin
    // gur dhe asnjë ndeshje nuk mbaron — matur te tool/mat_dora.dart.
    test('guri i sapolëvizur nuk merret prapa menjëherë', () {
      final d = Dora.nga(
        '''
        ......
        ..B...
        ......
        ......
        ......
        ......
        ''',
      );
      final pas = d.luaj(const Levizja(8, 14));
      expect(pas.radha, Zoti.i_dyti);
      expect(pas.iNdaluar, 14);
      for (final l in pas.levizjet()) {
        expect(l.nga, isNot(14), reason: 'ko-ja u shkel: $l');
      }
    });

    // 🚨 Ndalimi hiqet, dhe kjo duhet katër gjysmëlëvizje për t'u treguar — jo
    // dy. Guri i marrë bëhet I YTI, ndaj ti vetë nuk e lëviz dot as pa ko;
    // rregulli i ko-së prek vetëm kundërshtarin, dhe radha e tij e ardhshme
    // vjen dy gjysmëlëvizje më vonë. Prova e parë e shkruar këtu e harroi
    // pikërisht këtë, dhe dukej sikur ko-ja nuk hiqej kurrë.
    // 🔒 Ngulitja-në-lëvizje e zëvendëson ko-në: guri i lëvizur nuk lëvizet më
    // KURRË, nga askush. Prova e vjetër «ndalimi zgjat vetëm një radhë» u hoq
    // sepse ajo mat një rregull që nuk ekziston më — dhe një provë që mat
    // rregulla të vjetra është më keq se asnjë provë.
    test('guri i lëvizur ngulitet përgjithmonë', () {
      var d = Dora.nga(
        '''
        ......
        ..B...
        ......
        .A....
        ....B.
        ......
        ''',
      );
      d = d.luaj(const Levizja(8, 14));
      expect(d.ngulitur(14), isTrue);
      expect(d.ngulitur(8), isFalse, reason: 'fusha nga u nis duhet e lirë');
      d = d.luaj(const Levizja(19, 18));
      d = d.luaj(const Levizja(28, 29));
      expect(d.levizjet().any((l) => l.nga == 14), isFalse,
          reason: 'guri i ngulitur nuk lëvizet as pas disa radhësh');
    });

    // 🚨 Kjo është garancia që e bën ndeshjen të MBAROJË: gurët e ngulitur nuk
    // shngulen kurrë, ndaj pas 12 lëvizjesh nuk mbetet asgjë për të lëvizur.
    test('ndeshja mbaron — çdo gur lëvizet vetëm një herë', () {
      var d = Dora.nisja();
      var hapa = 0;
      while (!d.mbaroi && hapa < 500) {
        d = d.luaj(d.levizjet().first);
        hapa++;
      }
      expect(d.mbaroi, isTrue);
      expect(hapa, lessThanOrEqualTo(12),
          reason: 'dymbëdhjetë gurë, secili i lëvizshëm vetëm një herë');
    });

    test('fiton kush lidh pesë gurë', () {
      // Katër të lidhur për të parin; një gur i të dytit që, kur merret, i bën pesë.
      final d = Dora.nga(
        '''
        AAAA..
        ....B.
        ......
        ......
        ......
        ......
        ''',
      );
      expect(d.fituesi(), Zoti.bosh);
      expect(d.grupiMeIMadh(Zoti.i_pari), 4);
      final pas = d.luaj(const Levizja(10, 4));
      expect(pas.grupiMeIMadh(Zoti.i_pari), 5);
      expect(pas.fituesi(), Zoti.i_pari);
      expect(pas.mbaroi, isTrue);
    });

    test('lidhja është anash, jo diagonalisht', () {
      final d = Dora.nga(
        '''
        A.....
        .A....
        ..A...
        ...A..
        ....A.
        ......
        ''',
      );
      expect(d.grupiMeIMadh(Zoti.i_pari), 1,
          reason: 'diagonalja NUK lidh — shih Dora._fqinjet');
      expect(d.fituesi(), Zoti.bosh);
    });

    test('skica shkon e vjen pa u prishur', () {
      final d = Dora.nisja();
      expect(Dora.nga(d.skica()).skica(), d.skica());
    });

    test('një lëvizje e palejuar refuzohet, jo pranohet në heshtje', () {
      final d = Dora.nisja();
      expect(() => d.luaj(const Levizja(0, 35)), throwsArgumentError);
    });
  });
}
