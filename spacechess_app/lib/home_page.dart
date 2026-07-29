import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

import 'app/prefs.dart';
import 'app/theme.dart';
import 'game/game_page.dart';
import 'online/lobby_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.prefs});

  final Prefs prefs;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Map<String, String> _variantNames = <String, String>{
    'standard': 'Standard',
    'chess960': 'Chess960',
    'koth': 'Mbreti i Kodrës',
    'threecheck': 'Tre shahe',
    'antichess': 'Antishah',
  };

  @override
  Widget build(BuildContext context) {
    final ({List<String> moves, String variant, String fen, int colour})? saved =
        widget.prefs.savedGame;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _Title(),
              const SizedBox(height: 32),

              if (saved != null) ...<Widget>[
                FilledButton.icon(
                  onPressed: () => _play(
                    level: widget.prefs.level,
                    colour: saved.colour,
                    variant: _variantOf(saved.variant),
                    fen: saved.fen.isEmpty ? null : saved.fen,
                    resume: saved.moves,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Vazhdo lojën'),
                ),
                const SizedBox(height: 12),
              ],

              FilledButton.icon(
                onPressed: () => unawaited(_chooseLevel()),
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Kundër kompjuterit'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _play(
                  level: 0,
                  colour: white,
                  variant: _variantOf(widget.prefs.variant),
                ),
                icon: const Icon(Icons.people_outline),
                label: const Text('Dy lojtarë, një pajisje'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => unawaited(Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LobbyPage(prefs: widget.prefs),
                  ),
                )),
                icon: const Icon(Icons.public),
                label: const Text('Luaj online'),
              ),

              const SizedBox(height: 32),
              _VariantPicker(
                value: widget.prefs.variant,
                names: _variantNames,
                onPick: (String v) =>
                    setState(() => unawaited(widget.prefs.setVariant(v))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Variant _variantOf(String name) => Variant.values.firstWhere(
        (Variant v) => v.name == name,
        orElse: () => Variant.standard,
      );

  void _play({
    required int level,
    required int colour,
    required Variant variant,
    String? fen,
    List<String> resume = const <String>[],
  }) {
    // Te Chess960 rreshtimi zgjidhet një herë, kur nis loja, dhe udhëton bashkë
    // me lojën si FEN. Të ruash vetëm «chess960» do të thoshte që një lojë e
    // vazhduar do të rifillonte mbi një rreshtim tjetër.
    final String? startFen = fen ??
        (variant == Variant.chess960
            ? chess960Fen(Random().nextInt(960))
            : null);

    unawaited(Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => GamePage(
            prefs: widget.prefs,
            level: level,
            humanColour: colour,
            variant: variant,
            startFen: startFen,
            resumeMoves: resume,
          ),
        ))
        .then((_) => setState(() {})));
  }

  Future<void> _chooseLevel() async {
    final int? level = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Sa i fortë ta duash?',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              ),
              for (final AiLevel l in AiLevel.all)
                ListTile(
                  title: Text(l.name),
                  subtitle: Text(l.elo,
                      style: const TextStyle(color: Palette.textDim)),
                  trailing: l.id == widget.prefs.level
                      ? const Icon(Icons.check, color: Palette.accent)
                      : null,
                  onTap: () => Navigator.of(context).pop(l.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (level == null || !mounted) return;
    await widget.prefs.setLevel(level);

    if (!mounted) return;
    final int? colour = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
                title: const Text('Luaj me të bardhët'),
                onTap: () => Navigator.of(context).pop(white)),
            ListTile(
                title: const Text('Luaj me të zinjtë'),
                onTap: () => Navigator.of(context).pop(black)),
            ListTile(
                title: const Text('Rastësisht'),
                onTap: () => Navigator.of(context)
                    .pop(Random().nextBool() ? white : black)),
          ],
        ),
      ),
    );
    if (colour == null || !mounted) return;

    _play(
      level: level,
      colour: colour,
      variant: _variantOf(widget.prefs.variant),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) => const Column(
        children: <Widget>[
          Text('SpaceChess',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          SizedBox(height: 6),
          Text('Shah pa llogari, pa reklama',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.textDim, fontSize: 15)),
        ],
      );
}

class _VariantPicker extends StatelessWidget {
  const _VariantPicker(
      {required this.value, required this.names, required this.onPick});

  final String value;
  final Map<String, String> names;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Varianti',
              style: TextStyle(color: Palette.textDim, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: names.entries
                .map((MapEntry<String, String> e) => ChoiceChip(
                      label: Text(e.value),
                      selected: value == e.key,
                      onSelected: (_) => onPick(e.key),
                    ))
                .toList(),
          ),
        ],
      );
}
