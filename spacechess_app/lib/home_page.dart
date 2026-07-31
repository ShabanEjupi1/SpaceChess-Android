import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

import 'app/ads.dart';
import 'app/prefs.dart';
import 'app/stats_page.dart';
import 'app/theme.dart';
import 'game/game_page.dart';
import 'game/puzzle_page.dart';
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
        // 🔑 Banderola rri JASHTË rrëshqitësit, e ngjitur poshtë. Brenda tij ajo
        // do të ndodhej nën variantet, pra e padukshme derisa lojtari të
        // rrëshqiste — një reklamë që nuk shihet paguhet zero — dhe, më keq, do
        // të lëvizte bashkë me gishtin mbi butonat. Kur nuk është gati zë ZERO
        // hapësirë, ndaj menyja nuk ka vend bosh kur reklama nuk vjen.
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
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

                    // 🕌 Ikonat e kësaj menyje nuk kanë qenie të gjalla dhe as
                    // sende që zëvendësojnë një qenie. Historiku, që të mos
                    // kthehet asnjë hap prapa:
                    //   `smart_toy` (fytyrë roboti me sy e gojë) → `memory`
                    //   (çip) → sot vetëm numri i lojtarëve.
                    //   `people` (dy bysta njerëzish) → `swap_horiz` → «2».
                    // Modaliteti nuk quhet më «Kundër kompjuterit»: emri e
                    // ngrinte pajisjen në kundërshtar, kurse ajo vetëm zbaton
                    // rregullat. Tani thotë thjesht sa veta luajnë.
                    FilledButton.icon(
                      onPressed: () => unawaited(_chooseLevel()),
                      icon: const Icon(Icons.looks_one_rounded),
                      label: const Text('Luaj vetëm'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _play(
                        level: 0,
                        colour: white,
                        variant: _variantOf(widget.prefs.variant),
                      ),
                      icon: const Icon(Icons.looks_two_rounded),
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
                    const SizedBox(height: 12),
                    // Enigmat: e vetmja gjë këtu që nuk kërkon as kundërshtar
                    // as rrjet. Prandaj rri mbi tabelën e varianteve dhe jo në
                    // ndonjë meny të fshehur.
                    OutlinedButton.icon(
                      onPressed: () => unawaited(Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PuzzlePage(prefs: widget.prefs),
                        ),
                      ).then((_) => setState(() {}))),
                      icon: const Icon(Icons.extension_outlined),
                      label: const Text('Enigma — gjej matin'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => unawaited(Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StatsPage(prefs: widget.prefs),
                        ),
                      )),
                      icon: const Icon(Icons.bar_chart_rounded),
                      label: const Text('Statistika'),
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
            const BannerSlot(),
          ],
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
          Text('Mat!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1)),
          SizedBox(height: 6),
          // ⚠️ Ky rresht thoshte «pa llogari, pa reklama». Reklamat u shtuan më
          // 2026-07-30, ndaj gjysma e dytë u hoq edhe këtu edhe te listimi i
          // Play-it. Një premtim i mbetur në ekran është gënjeshtër e shkruar,
          // dhe te Play-i është shkak ankese.
          Text('Shah pa llogari, edhe pa internet',
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
