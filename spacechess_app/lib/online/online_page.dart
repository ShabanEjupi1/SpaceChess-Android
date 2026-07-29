import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

import '../app/prefs.dart';
import '../app/theme.dart';
import '../board/board_view.dart';
import 'api.dart';

/// Loja online: një tabelë e vetme e drejtuar nga serveri.
///
/// 🔑 **Serveri është burimi i vetëm i së vërtetës.** Lëvizja luhet së pari
/// lokalisht që figura të ulet në çast — por gjendja që vizatohet vjen
/// gjithmonë nga FEN-i i fundit i serverit. Pa këtë rregull, dy pajisje me
/// vonesa të ndryshme do të shihnin dy tabela të ndryshme dhe secila do të
/// kishte të drejtë.
///
/// Përditësimet merren me sondazh çdo dy sekonda e jo me SSE: `package:http` nuk
/// mban dot një rrjedhë të gjatë pa një klient të veçantë, dhe një lojë shahu me
/// dy sekonda vonesë është plotësisht e luajtshme. Kur ora zbret nën 30 sekonda,
/// sondazhi shpejtohet.
class OnlineGamePage extends StatefulWidget {
  const OnlineGamePage({
    super.key,
    required this.api,
    required this.gameId,
    required this.prefs,
  });

  final SpaceChessApi api;
  final String gameId;
  final Prefs prefs;

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  Map<String, dynamic>? _game;
  Position? _position;
  String? _myColour;
  int? _selected;
  List<Move> _targets = const <Move>[];
  Timer? _poll;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(_refresh()));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final Map<String, dynamic>? r = await widget.api.game(widget.gameId);
    if (!mounted || r == null) return;
    final Map<String, dynamic>? g = r['game'] as Map<String, dynamic>?;
    if (g == null) return;

    setState(() {
      _game = g;
      _position = fromFen(g['fen'] as String, _variantOf(g));
      _myColour ??= _guessColour(g);
      _selected = null;
      _targets = const <Move>[];
    });
  }

  Variant _variantOf(Map<String, dynamic> g) => Variant.values.firstWhere(
        (Variant v) => v.name == g['variant'],
        orElse: () => Variant.standard,
      );

  /// Serveri nuk e thotë drejtpërdrejt se cila anë je; e thotë me emrat e
  /// lojtarëve. Kur asnjëri nuk je ti, je shikues — dhe tabela mbetet vetëm
  /// për t'u parë.
  String? _guessColour(Map<String, dynamic> g) {
    final Object? players = g['players'];
    if (players is! Map) return null;
    for (final String side in <String>['w', 'b']) {
      final Object? p = players[side];
      if (p is Map && p['me'] == true) return side;
    }
    return null;
  }

  bool get _myTurn =>
      _myColour != null && _game != null && _game!['turn'] == _myColour;

  void _onTap(int square) {
    final Position? p = _position;
    if (p == null || _sending || !_myTurn || _game!['status'] != 'active') return;

    final List<Move> chosen =
        _targets.where((Move m) => m.to == square).toList(growable: false);
    if (_selected != null && chosen.isNotEmpty) {
      unawaited(_send(chosen));
      return;
    }

    final int piece = p.pieceAt(square);
    final bool mine =
        piece != empty && piece != off && (piece > 0 ? white : black) == p.side;

    setState(() {
      if (!mine || square == _selected) {
        _selected = null;
        _targets = const <Move>[];
      } else {
        _selected = square;
        _targets = legalMoves(p)
            .where((Move m) => m.from == square)
            .toList(growable: false);
      }
    });
  }

  Future<void> _send(List<Move> candidates) async {
    Move move = candidates.first;
    if (candidates.length > 1 && candidates.any((Move m) => m.promo != 0)) {
      // Te loja online mbretëresha është parazgjedhje e heshtur vetëm kur
      // lojtari nuk zgjedh; këtu pyetet, sepse kalimi te kalorësi vendos ndeshje.
      final int? promo = await showModalBottomSheet<int>(
        context: context,
        builder: (BuildContext context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <int>[queen, rook, bishop, knight]
                .map((int t) => ListTile(
                      title: Text(<int, String>{
                        queen: 'Mbretëreshë',
                        rook: 'Kala',
                        bishop: 'Oficer',
                        knight: 'Kalorës',
                      }[t]!),
                      onTap: () => Navigator.of(context).pop(t),
                    ))
                .toList(),
          ),
        ),
      );
      if (promo == null || !mounted) return;
      move = candidates.firstWhere((Move m) => m.promo == promo,
          orElse: () => candidates.first);
    }

    setState(() {
      _sending = true;
      // Vendose figurën menjëherë — pastaj serveri e konfirmon ose e rrëzon me
      // përgjigjen e vet, që gjithsesi e mbivendos këtë tabelë.
      _position = makeMove(_position!, move);
      _selected = null;
      _targets = const <Move>[];
    });

    final Map<String, dynamic>? r =
        await widget.api.move(widget.gameId, move.uci);
    if (!mounted) return;
    setState(() => _sending = false);

    if (r == null) {
      // Refuzim ose rrjet i rënë: rikthe atë që thotë serveri, mos e lër tabelën
      // të besojë një lëvizje që nuk ndodhi kurrë.
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lëvizja nuk kaloi. Provo sërish.')),
        );
      }
      return;
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? g = _game;
    final Position? p = _position;

    if (g == null || p == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool over = g['status'] == 'ended';
    final bool waiting = g['status'] == 'waiting';

    return Scaffold(
      appBar: AppBar(
        title: Text('${g['variant']} · ${(g['tc'] as Map<String, dynamic>)['id']}'),
        actions: <Widget>[
          if (!over && _myColour != null)
            IconButton(
              tooltip: 'Dorëzohu',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () async {
                final bool? sure = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Të dorëzohesh?'),
                    actions: <Widget>[
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Jo')),
                      FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Po')),
                    ],
                  ),
                );
                if (sure ?? false) {
                  await widget.api.resign(widget.gameId);
                  await _refresh();
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _clockBar(g, _myColour == 'w' ? 'b' : 'w'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: BoardView(
                    position: p,
                    onTap: _onTap,
                    selected: _selected,
                    targets: _targets.map((Move m) => m.to).toList(growable: false),
                    flipped: _myColour == 'b',
                    interactive: _myTurn && !over,
                  ),
                ),
              ),
            ),
            _clockBar(g, _myColour ?? 'w'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                waiting
                    ? 'Duke pritur kundërshtarin…'
                    : over
                        ? 'Mbaroi: ${g['result']} (${g['reason']})'
                        : _myTurn
                            ? 'Radha jote.'
                            : 'Radha e kundërshtarit.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.textDim, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clockBar(Map<String, dynamic> g, String side) {
    final Map<String, dynamic>? players = g['players'] as Map<String, dynamic>?;
    final Object? player = players?[side];
    final String name =
        player is Map && player['name'] != null ? '${player['name']}' : 'Kundërshtari';
    final Map<String, dynamic>? clock = g['clock'] as Map<String, dynamic>?;
    final int ms = (clock?[side] as num?)?.round() ?? 0;
    final bool active = g['turn'] == side && g['status'] == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: active ? Palette.surfaceHigh : Colors.transparent,
      child: Row(
        children: <Widget>[
          Text(name,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          const Spacer(),
          if (ms > 0)
            Text(
              '${(ms ~/ 60000).toString().padLeft(2, '0')}:'
              '${((ms % 60000) ~/ 1000).toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 18,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()]),
            ),
        ],
      ),
    );
  }
}
