import 'package:flutter/material.dart';

import '../data/enigmat.g.dart';
import 'prefs.dart';
import 'theme.dart';

/// Statistikat — të gjitha nga kujtesa e vetë pajisjes.
///
/// 🔑 Asnjë numër këtu nuk vjen nga serveri dhe asnjë nuk shkon atje. Pikët
/// online janë diçka tjetër dhe rrinë te faqja «Luaj online»; kjo faqe ka
/// kuptim edhe për dikë që nuk ka luajtur kurrë online, që është shumica.
/// Prandaj ajo NUK e ndryshon deklaratën «Data safety» — shih PLAY-TE-DYJA.md.
class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.prefs});

  final Prefs prefs;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  Widget build(BuildContext context) {
    final Prefs p = widget.prefs;
    final int played = p.gamesPlayed;
    final String rate =
        played == 0 ? '—' : '${(p.wins * 100 / played).round()}%';

    return Scaffold(
      appBar: AppBar(title: const Text('Statistika')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Card(
            title: 'Lojërat në këtë pajisje',
            rows: <(String, String)>[
              ('Të luajtura', '$played'),
              ('Fitore', '${p.wins}'),
              ('Humbje', '${p.losses}'),
              ('Barazime', '${p.draws}'),
              ('Përqindja e fitoreve', rate),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Enigmat',
            rows: <(String, String)>[
              ('Të zgjidhura pa ndihmë', '${p.puzzlesSolved}'),
              ('Gjithsej enigma', '${enigmat.length}'),
              ('Ku ke mbetur', '${p.puzzleIndex + 1}'),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Këta numra rrinë vetëm në telefon. Fshirja e aplikacionit i heq '
            'të gjithë; asnjëri nuk dërgohet askund.',
            style: TextStyle(color: Palette.textDim, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.prefs.clearStats();
              if (context.mounted) setState(() {});
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Fshij statistikat'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final (String k, String v) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(k, style: const TextStyle(color: Palette.textDim)),
                    Text(v,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      );
}
