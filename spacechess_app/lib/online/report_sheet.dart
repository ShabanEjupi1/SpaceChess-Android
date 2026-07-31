import 'package:flutter/material.dart';

import 'api.dart';

/// Fleta e raportimit të një lojtari.
///
/// Politika e Google Play-t për përmbajtjen e krijuar nga përdoruesit kërkon
/// dy gjëra: filtrim (te serveri, `moderim.mjs`) dhe një rrugë raportimi. Kjo
/// është e dyta, dhe rri pikërisht aty ku emri i huaj shihet: mbi tabelë dhe te
/// renditja.
///
/// 🔑 Arsyet janë listë e mbyllur. Një kuti me tekst të lirë do të ishte vetë
/// përmbajtje e krijuar nga përdoruesi — pra do të kërkonte të njëjtin filtër
/// mbi vete, dhe do të hapte një kanal të ri ku dikush shan të tjerët.
const Map<String, String> arsyet = <String, String>{
  'emri': 'Emër i papërshtatshëm',
  'sjellja': 'Sjellje fyese',
  'mashtrim': 'Mashtrim (ndihmë nga kompjuteri)',
  'tjeter': 'Diçka tjetër',
};

Future<void> showReportSheet({
  required BuildContext context,
  required SpaceChessApi api,
  required String targetId,
  required String targetName,
  String? gameId,
}) async {
  final String? reason = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text('Raporto «$targetName»'),
            subtitle: const Text('Raporti shkon te administratori i lojës.'),
          ),
          const Divider(height: 1),
          ...arsyet.entries.map((MapEntry<String, String> e) => ListTile(
                title: Text(e.value),
                onTap: () => Navigator.of(sheet).pop(e.key),
              )),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;

  final bool ok = await api.report(targetId, reason, game: gameId);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ok
          ? 'Faleminderit. Raporti u dërgua.'
          : api.lastError ?? 'Raporti nuk u dërgua. Provo sërish.'),
    ),
  );
}
