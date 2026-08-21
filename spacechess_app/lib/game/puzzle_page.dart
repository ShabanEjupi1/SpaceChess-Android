import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

import '../app/prefs.dart';
import '../app/vleresimi.dart';
import '../app/theme.dart';
import '../board/board_view.dart';
import '../data/enigmat.g.dart';

/// Enigmat: gjej matin, me të bardhët, në një ose dy lëvizje.
///
/// 🔑 Pse ekziston: pa këtë, një lojtar i vetëm dhe pa internet ka vetëm një
/// gjë për të bërë. Enigmat e mbajnë aplikacionin të dobishëm për pesë minuta
/// pritjeje pa kërkuar as kundërshtar, as rrjet, as llogari.
///
/// 🚨 Përgjigjja e të ziut NUK kërkohet nga motori i lojës: te një enigmë e
/// gjeneruar, ÇDO përgjigje e ligjshme çon në mat, ndaj luhet thjesht e para e
/// listës. Kështu faqja nuk varet nga koha e mendimit dhe testi mbetet i
/// menjëhershëm. Verifikimi që kjo është e vërtetë bëhet te gjeneruesi dhe
/// ripërsëritet te `test/enigma_test.dart`.
class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key, required this.prefs});

  final Prefs prefs;

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late int _index;
  late Game _game;
  int? _selected;
  List<int> _targets = const <int>[];
  Move? _last;
  bool _solved = false;
  bool _failed = false;
  bool _usedHint = false;

  @override
  void initState() {
    super.initState();
    _index = widget.prefs.puzzleIndex.clamp(0, enigmat.length - 1);
    _load();
  }

  Enigma get _puzzle => enigmat[_index];

  void _load() {
    _game = Game(fen: _puzzle.fen);
    _selected = null;
    _targets = const <int>[];
    _last = null;
    _solved = false;
    _failed = false;
    _usedHint = false;
  }

  void _next() {
    setState(() {
      _index = (_index + 1) % enigmat.length;
      _load();
    });
    unawaited(widget.prefs.setPuzzleIndex(_index));
  }

  void _tap(int square) {
    if (_solved) return;
    final int piece = _game.position.board[square];

    if (_selected == null) {
      if (piece == empty || piece.sign != _game.side) return;
      setState(() {
        _selected = square;
        _targets = _game.legal
            .where((Move m) => m.from == square)
            .map((Move m) => m.to)
            .toList();
      });
      return;
    }

    if (square == _selected) {
      setState(() {
        _selected = null;
        _targets = const <int>[];
      });
      return;
    }

    // Prekja e një figure tjetër tënden e zhvendos zgjedhjen — pa këtë, çdo
    // ndërrim mendjeje kërkon dy prekje.
    if (piece != empty && piece.sign == _game.side) {
      setState(() {
        _selected = square;
        _targets = _game.legal
            .where((Move m) => m.from == square)
            .map((Move m) => m.to)
            .toList();
      });
      return;
    }

    final Move? move = _game.legal
        .where((Move m) => m.from == _selected && m.to == square)
        .firstOrNull;
    if (move == null) return;
    _play(move);
  }

  void _play(Move move) {
    // Lëvizja e PARË krahasohet me zgjidhjen e ruajtur: gjeneruesi ka provuar
    // se ajo është e vetmja që fiton, ndaj çdo tjetër është gabim edhe kur
    // duket e mirë.
    if (_game.moves.isEmpty) {
      if (move.uci != _puzzle.zgjidhja) return _gabim();
      _game.apply(move);
      _last = move;
      _pastro();

      if (_mat()) return _fito();

      // Përgjigjja e të ziut. Te një enigmë e verifikuar ÇDO përgjigje e
      // ligjshme humb, ndaj e para mjafton dhe faqja nuk pret asnjë kërkim.
      final Move reply = _game.legal.first;
      _game.apply(reply);
      _last = reply;
      setState(() {});
      return;
    }

    // Lëvizja e DYTË gjykohet nga tabela e jo nga një varg i ruajtur: pas
    // përgjigjes së të ziut mund të ketë më shumë se një mat, dhe secili prej
    // tyre është zgjidhje e drejtë.
    _game.apply(move);
    if (!_mat()) {
      // E kthejmë tabelën aty ku ishte, që lojtari të provojë sërish pa e
      // rifilluar enigmën nga fillimi.
      _game.undo();
      return _gabim();
    }
    _last = move;
    _pastro();
    _fito();
  }

  bool _mat() => _game.status.reason == EndReason.checkmate;

  void _pastro() {
    _selected = null;
    _targets = const <int>[];
    _failed = false;
  }

  void _gabim() {
    setState(() {
      _failed = true;
      _selected = null;
      _targets = const <int>[];
    });
    unawaited(HapticFeedback.heavyImpact());
  }

  void _fito() {
    setState(() => _solved = true);
    unawaited(HapticFeedback.mediumImpact());
    // Numërohet vetëm ajo që u gjet vetë — përndryshe numri nuk thotë asgjë.
    if (!_usedHint) unawaited(widget.prefs.addPuzzleSolved());
    // 🔎 Enigma u zgjidh — moment i mirë po aq sa një fitore.
    unawaited(Vleresimi.momentiMire());
  }

  /// Ndihma nuk e luan lëvizjen: e ndriçon. Lojtari e shtyp vetë, ndaj e mban
  /// mend formën — dhe ylli i «pa ndihmë» humbet, si te Girihu.
  void _hint() {
    final Move? m = moveFromUci(_game.position, _puzzle.zgjidhja);
    if (m == null) return;
    setState(() {
      _usedHint = true;
      _selected = m.from;
      _targets = <int>[m.to];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enigma ${_index + 1}/${enigmat.length}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Ndihmë',
            onPressed: _solved ? null : _hint,
            icon: const Icon(Icons.lightbulb_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                _puzzle.hapa == 1
                    ? 'I bardhi lëviz dhe jep mat me një lëvizje.'
                    : 'I bardhi lëviz dhe jep mat me dy lëvizje.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Center(
                child: BoardView(
                  position: _game.position,
                  onTap: _tap,
                  selected: _selected,
                  targets: _targets,
                  lastMove: _last,
                  interactive: !_solved,
                ),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    final String text = _solved
        ? (_usedHint ? 'Mat — me ndihmë.' : 'Mat! E gjete vetë.')
        : _failed
            ? 'Jo ajo. Provoje sërish.'
            : _game.moves.isEmpty
                ? 'Radha: i bardhi.'
                : 'Mirë. Tani mbylle.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: <Widget>[
          Text(text,
              style: TextStyle(
                color: _solved
                    ? Palette.accent
                    : _failed
                        ? Colors.redAccent
                        : Palette.textDim,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(_load),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Nga fillimi'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Tjetra'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
