import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

import '../app/ads.dart';
import '../app/prefs.dart';
import '../app/theme.dart';
import '../board/board_view.dart';
import '../board/pieces.dart';
import 'ai_isolate.dart';

/// Një lojë në këtë pajisje: kundër kompjuterit ose dy vetë mbi një ekran.
class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.prefs,
    required this.level,
    required this.humanColour,
    required this.variant,
    this.startFen,
    this.resumeMoves = const <String>[],
  });

  /// Niveli i kompjuterit, ose 0 për dy lojtarë në një pajisje.
  final int level;

  /// Ngjyra e njeriut kur luhet kundër kompjuterit.
  final int humanColour;

  final Variant variant;

  /// FEN-i i nisjes — i domosdoshëm te Chess960, ku çdo lojë nis ndryshe.
  final String? startFen;

  final List<String> resumeMoves;
  final Prefs prefs;

  bool get vsComputer => level > 0;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late Game _game;
  int? _selected;
  List<Move> _targets = const <Move>[];
  Move? _lastMove;
  bool _thinking = false;
  bool _dialogShown = false;

  /// Sa kthime lëvizjeje janë shfrytëzuar në këtë lojë. Tri të parat janë të
  /// lira; pas tyre lojtari mund të zgjedhë një reklamë me shpërblim për tri të
  /// tjera. Ky kufi NUK zbatohet kur reklamat nuk ekzistojnë fare (web, desktop,
  /// pëlqim i refuzuar) — atje kthimi mbetet i pakufizuar, si më parë.
  int _undosUsed = 0;
  static const int _freeUndos = 3;

  @override
  void initState() {
    super.initState();
    _game = Game(variant: widget.variant, fen: widget.startFen);
    for (final String uci in widget.resumeMoves) {
      if (!_game.applyUci(uci)) break;
      _lastMove = _game.moves.last;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_maybeThink()));
  }

  bool get _humanTurn =>
      !widget.vsComputer || _game.side == widget.humanColour;

  /// Tabela kthehet kur njeriu luan me të zinjtë, ose — te loja me dy vetë —
  /// pas çdo lëvizjeje, që secili ta shohë tabelën nga ana e vet.
  bool get _flipped => widget.vsComputer
      ? widget.humanColour == black
      : (widget.prefs.autoFlip && _game.side == black);

  Future<void> _maybeThink() async {
    if (!mounted || _game.isOver || _humanTurn || _thinking) return;
    setState(() => _thinking = true);

    final String? uci = await thinkMove(
      startFen: _game.startFen,
      moves: _game.moves.map((Move m) => m.uci).toList(),
      variant: widget.variant.name,
      level: widget.level,
    );

    if (!mounted) return;
    setState(() {
      _thinking = false;
      if (uci != null && _game.applyUci(uci)) _lastMove = _game.moves.last;
    });
    _afterMove();
  }

  void _onTap(int square) {
    if (_thinking || _game.isOver || !_humanTurn) return;

    // Prekja e dytë: nëse bie mbi një kuti të ndriçuar, luaje.
    final List<Move> chosen =
        _targets.where((Move m) => m.to == square).toList(growable: false);
    if (_selected != null && chosen.isNotEmpty) {
      unawaited(_play(chosen));
      return;
    }

    // Përndryshe zgjidh (ose çzgjidh) një figurë të kësaj ane.
    final int piece = _game.position.pieceAt(square);
    final bool mine = piece != empty &&
        piece != off &&
        (piece > 0 ? white : black) == _game.side;

    setState(() {
      if (!mine || square == _selected) {
        _selected = null;
        _targets = const <Move>[];
      } else {
        _selected = square;
        _targets = _game.legal
            .where((Move m) => m.from == square)
            .toList(growable: false);
      }
    });
  }

  Future<void> _play(List<Move> candidates) async {
    // Një kuti e vetme mund të ketë deri në katër lëvizje: kalimi në figurë.
    Move move = candidates.first;
    if (candidates.length > 1 && candidates.any((Move m) => m.promo != 0)) {
      final int? promo = await _askPromotion();
      if (promo == null || !mounted) return;
      move = candidates.firstWhere((Move m) => m.promo == promo,
          orElse: () => candidates.first);
    }

    if (!_game.apply(move)) return;
    unawaited(HapticFeedback.selectionClick());

    setState(() {
      _lastMove = move;
      _selected = null;
      _targets = const <Move>[];
    });
    _afterMove();
  }

  Future<int?> _askPromotion() => showModalBottomSheet<int>(
        context: context,
        builder: (BuildContext context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Në çfarë ta kthesh ushtarin?',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <int>[queen, rook, bishop, knight]
                      .map((int type) => InkWell(
                            onTap: () => Navigator.of(context).pop(type),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: CustomPaint(
                                painter: _PiecePreview(type * _game.side),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      );

  void _afterMove() {
    if (_game.isOver) {
      unawaited(widget.prefs.clearSavedGame());
      // Numëruesi vendës i faqes «Statistika». Vetëm lojërat vetëm — te dy
      // lojtarë mbi një ekran nuk ka «ti», ndaj një fitore s'i takon askujt.
      if (widget.vsComputer) {
        final String? r = _game.status.result;
        unawaited(widget.prefs.recordResult(
          outcome: r == '1/2-1/2'
              ? 0
              : (r == '1-0' ? white : black) == widget.humanColour
                  ? 1
                  : -1,
        ));
      }
      _showResult();
      return;
    }
    if (widget.vsComputer) {
      unawaited(widget.prefs.saveGame(
        moves: _game.moves.map((Move m) => m.uci).toList(),
        variant: widget.variant.name,
        fen: _game.startFen,
        colour: widget.humanColour,
      ));
    }
    unawaited(_maybeThink());
  }

  void _showResult() {
    if (_dialogShown) return;
    _dialogShown = true;
    final GameStatus st = _game.status;

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(_title(st), style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(_explain(st)),
        // 🔑 Reklama e ndërmjetme shfaqet vetëm PASI lojtari e mbyll këtë
        // dialog, jo mbi të: një reklamë që zë vendin e rezultatit e fsheh
        // pikërisht atë që lojtari po pret. [Ads.maybeShowAfterGame] vendos
        // vetë a ka mbushur kufiri (1 në 3 lojëra, jo dy brenda 3 minutash) —
        // ky ekran nuk mban asnjë numërues reklamash.
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              unawaited(Ads.maybeShowAfterGame());
            },
            child: const Text('Dil'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _game = Game(variant: widget.variant, fen: widget.startFen);
                _lastMove = null;
                _selected = null;
                _targets = const <Move>[];
                _dialogShown = false;
                _undosUsed = 0;
              });
              unawaited(Ads.maybeShowAfterGame());
              unawaited(_maybeThink());
            },
            child: const Text('Përsëri'),
          ),
        ],
      ),
    ));
  }

  String _title(GameStatus st) {
    if (st.result == '1/2-1/2') return 'Barazim';
    final int winner = st.result == '1-0' ? white : black;
    if (!widget.vsComputer) {
      return winner == white ? 'Fitoi i bardhi' : 'Fitoi i ziu';
    }
    return winner == widget.humanColour ? 'Fitove!' : 'Humbe';
  }

  String _explain(GameStatus st) => switch (st.reason) {
        EndReason.checkmate => 'Mat.',
        EndReason.stalemate => 'Pat — pa lëvizje të ligjshme, por pa shah.',
        EndReason.fifty => 'Pesëdhjetë lëvizje pa ngrënie dhe pa ushtar.',
        EndReason.material => 'Material i pamjaftueshëm për mat.',
        EndReason.repetition => 'I njëjti pozicion tri herë.',
        EndReason.threecheck => 'Tre shahe.',
        EndReason.koth => 'Mbreti arriti kodrën.',
        EndReason.antichess => 'Pa figura, pa lëvizje — dhe kjo fiton këtu.',
        _ => '',
      };

  /// Kthimi i një lëvizjeje.
  ///
  /// Tri të parat janë të lira. Pas tyre kërkohet një reklamë me shpërblim, dhe
  /// vetëm me pyetje: lojtari mund të thotë «jo» dhe loja vazhdon normalisht.
  ///
  /// 🔑 Nëse reklama nuk vjen ose dështon, kthimet **jepen gjithsesi**. Një
  /// lojtar që pranoi të shohë një reklamë nuk duhet ndëshkuar për një rrjet që
  /// nuk u përgjigj — dhe pa internet (ku loja kundër kompjuterit punon fare
  /// mirë) përndryshe kthimi do të bllokohej përgjithmonë pas lëvizjes së tretë.
  /// Lëvizjet si PGN, në kujtesë.
  ///
  /// Trupi (`moveText`) vjen nga motori, që e mban SAN-in vetë; këtu shtohen
  /// vetëm shtatë etiketat e detyrueshme të «Seven Tag Roster», pa të cilat
  /// teksti hapet te disa vegla shahu dhe te të tjerat jo. Data shkruhet me
  /// pikat e PGN-së (`2026.07.31`), jo me vija.
  Future<void> _kopjoPgn() async {
    final DateTime tani = DateTime.now();
    String dy(int n) => n.toString().padLeft(2, '0');
    final String kunder = widget.vsComputer
        ? 'Mat! (${AiLevel.byId(widget.level).name})'
        : 'Lojtari 2';
    final bool bardhNjeriu = !widget.vsComputer || widget.humanColour == white;
    final String pgn = <String>[
      '[Event "Shah Mat"]',
      '[Site "chess.spacecode.tech"]',
      '[Date "${tani.year}.${dy(tani.month)}.${dy(tani.day)}"]',
      '[Round "-"]',
      '[White "${bardhNjeriu ? 'Lojtari' : kunder}"]',
      '[Black "${bardhNjeriu ? kunder : 'Lojtari'}"]',
      '[Result "${_pgnResult()}"]',
      '',
      '${_game.moveText} ${_pgnResult()}',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: pgn));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Lëvizjet u kopjuan')));
  }

  /// `*` do të thotë «e papërfunduar» te PGN-ja dhe është përgjigjja e saktë
  /// për një lojë që vazhdon — jo barazim. Kur loja ka mbaruar, vargu vjen
  /// gati nga motori (`1-0` / `0-1` / `1/2-1/2`).
  String _pgnResult() => _game.status.result ?? '*';

  Future<void> _undo() async {
    if (_game.moves.isEmpty || _thinking) return;

    if (Ads.ready && _undosUsed >= _freeUndos) {
      final bool? watch = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Kthime të tjera?'),
          content: const Text(
              'Tri kthimet e lira të kësaj loje mbaruan. Një reklamë e shkurtër '
              'të jep tri të tjera.'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Jo, faleminderit')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Shiko reklamën')),
          ],
        ),
      );
      if (watch != true || !mounted) return;
      await Ads.showRewarded();
      if (!mounted) return;
      _undosUsed = 0;
    }

    _undosUsed++;
    setState(() {
      // Kundër kompjuterit kthen ÇIFTIN: të kthesh vetëm lëvizjen e kompjuterit
      // do të thoshte t'ia jepje radhën atij dy herë radhazi.
      _game.undo();
      if (widget.vsComputer && _game.moves.isNotEmpty) _game.undo();
      _lastMove = _game.moves.isEmpty ? null : _game.moves.last;
      _selected = null;
      _targets = const <Move>[];
      _dialogShown = false;
    });
  }

  Future<void> _confirmLeave() async {
    if (_game.isOver || _game.moves.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Ta lëmë lojën?'),
        content: Text(widget.vsComputer
            ? 'Loja ruhet dhe mund ta vazhdosh më vonë.'
            : 'Loja me dy lojtarë nuk ruhet.'),
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
    if ((leave ?? false) && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final GameStatus st = _game.status;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back), onPressed: _confirmLeave),
          title: Text(widget.vsComputer
              ? AiLevel.byId(widget.level).name
              : 'Dy lojtarë'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Kopjo lëvizjet (PGN)',
              icon: const Icon(Icons.content_copy_outlined),
              onPressed:
                  _game.moves.isEmpty ? null : () => unawaited(_kopjoPgn()),
            ),
            IconButton(
              tooltip: 'Kthe një lëvizje',
              icon: const Icon(Icons.undo),
              onPressed: _game.moves.isEmpty || _thinking
                  ? null
                  : () => unawaited(_undo()),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              // 🔑 Të tria rrinë si një bllok i vetëm i qendërzuar, jo si dy
              // rreshta të ngjitura te skajet me tabelën në mes: përndryshe në
              // një ekran të gjatë emri i kundërshtarit del larg tabelës së tij
              // dhe syri nuk i lidh më me njëri-tjetrin.
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    // 🚨 Përmasa e tabelës llogaritet KËTU, nga hapësira e
                    // vërtetë. Brenda një `Column`-i lartësia është e pakufizuar,
                    // pra një tabelë që merr thjesht gjerësinë del jashtë ekranit
                    // sapo dritarja të jetë më e gjerë se e lartë — çdo tablet i
                    // kthyer, çdo desktop. Barra e dy rreshtave zbritet me një
                    // lartësi FIKSE ([_Bar.height]) pikërisht që kjo llogari të
                    // mos varet nga ajo që sapo është matur.
                    const double gaps = 16;
                    final double side = <double>[
                      c.maxWidth - gaps,
                      c.maxHeight - 2 * _Bar.height - gaps,
                    ].reduce((double a, double b) => a < b ? a : b).clamp(0, 4096);

                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _Bar(
                            game: _game,
                            colour: _flipped ? white : black,
                            label: _nameFor(_flipped ? white : black),
                            thinking: _thinking && !_humanTurn,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(gaps / 2),
                            child: SizedBox.square(
                              dimension: side,
                              child: BoardView(
                                position: _game.position,
                                onTap: _onTap,
                                selected: _selected,
                                targets: _targets
                                    .map((Move m) => m.to)
                                    .toList(growable: false),
                                lastMove: _lastMove,
                                flipped: _flipped,
                                interactive: _humanTurn && !_game.isOver,
                              ),
                            ),
                          ),
                          _Bar(
                            game: _game,
                            colour: _flipped ? black : white,
                            label: _nameFor(_flipped ? black : white),
                            thinking: false,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Text(
                  _hint(st),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.textDim, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _nameFor(int colour) {
    if (!widget.vsComputer) return colour == white ? 'I bardhi' : 'I ziu';
    return colour == widget.humanColour
        ? (widget.prefs.name.isEmpty ? 'Ti' : widget.prefs.name)
        // 🕌 Kundërshtari nuk quhet «Kompjuteri»: emri i jep pajisjes rolin e
        // një vetjeje që luan. Ajo vetëm zbaton rregullat, ndaj rreshti mban
        // atë që lojtari ka zgjedhur vërtet — shkallën e vështirësisë.
        : AiLevel.byId(widget.level).name;
  }

  String _hint(GameStatus st) {
    if (st.over) return _title(st);
    // «Po mendon» është veprim njeriu; ajo që ndodh është llogaritje.
    if (_thinking) return 'Po llogaritet lëvizja…';
    final String side = _game.side == white ? 'I bardhi' : 'I ziu';
    if (st.check) return '$side është në shah.';
    if (widget.variant == Variant.antichess) return '$side duhet të hajë nëse mundet.';
    return 'Radha: $side.';
  }
}

/// Rreshti i një lojtari: emri, figurat e ngrëna dhe përparësia materiale.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.game,
    required this.colour,
    required this.label,
    required this.thinking,
  });

  /// Lartësi FIKSE: llogaria e përmasës së tabelës e zbret dhe nuk mund të
  /// presë matjen e këtij widget-i.
  static const double height = 44;

  final Game game;
  final int colour;
  final String label;
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    final bool active = game.side == colour && !game.isOver;
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: active ? Palette.surfaceHigh : Colors.transparent,
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colour == white ? Palette.whitePiece : Palette.blackPiece,
              border: Border.all(color: Palette.textDim),
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          const Spacer(),
          if (thinking)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}

class _PiecePreview extends CustomPainter {
  _PiecePreview(this.piece);
  final int piece;

  @override
  void paint(Canvas canvas, Size size) =>
      drawPiece(canvas, Offset.zero & size, piece);

  @override
  bool shouldRepaint(_PiecePreview old) => old.piece != piece;
}
