import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spacechess_engine/spacechess_engine.dart';

import '../app/ads.dart';
import '../app/analitika.dart';
import '../app/theme.dart';
import '../board/four_board_view.dart';
import '../board/pieces.dart';

/// Si luhet Katërshi në këtë pajisje.
enum FourMode {
  /// Katër veta, një telefon: pajisja kalon dorë më dorë.
  pass,

  /// Ti i kuq, tre kompjuterë.
  bots,
}

/// ♟️4️⃣ Katërshi — shah me katër lojtarë, në aplikacion.
///
/// # 🚨🚨 Përse ky ekran ekziston vetëm tani
///
/// Motori i Katërshit ([FourPosition], 633 rreshta, 26 prova) u shkrua më
/// 11-08-2026, dhe atë ditë titulli te Google Play u ndryshua që ta premtonte.
/// Ndërfaqja **nuk u ndërtua kurrë** — pra për një ditë të plotë dyqani
/// reklamonte një veçori që paketa nuk e përmbante, dhe i vetmi vend ku
/// Katërshi luhej ishte faqja `chess.spacecode.tech/katershi`.
///
/// Kjo është saktësisht e njëjta klasë gabimi si emri «Drive Inside City» te
/// loja tjetër, që premtoi hyrjen brenda ndërtesave gjashtë ditë para se ajo të
/// ekzistonte. Të dyja u mbyllën më 12-08-2026, dhe rregulli që mbetet është:
/// **teksti i dyqanit ndryshon pasi veçoria hipën te paketa, jo para.**
///
/// # 🔑 Përse nuk ka «kthe lëvizjen» dhe as ruajtje
///
/// Te loja dylojtarëshe të dyja janë të thjeshta sepse gjendja është një listë
/// lëvizjesh mbi një pozicion nisjeje. Këtu një kthim do të duhej të zhbënte
/// edhe eliminimet edhe pikët e dhëna nga [fourAdvance] — dhe një kthim që i
/// zhbën gabim pikët nuk duket si defekt, thjesht një lojtar «doli përpara pa
/// arsye». Derisa të ketë një provë për të, mungon me qëllim.
class FourPage extends StatefulWidget {
  const FourPage({super.key, required this.mode});

  final FourMode mode;

  @override
  State<FourPage> createState() => _FourPageState();
}

class _FourPageState extends State<FourPage> {
  FourPosition _pos = fourStart();
  final FourBot _bot = FourBot();

  int? _selected;
  List<FourMove> _targets = const <FourMove>[];
  FourMove? _last;
  bool _busy = false;
  bool _resultShown = false;

  /// Sa gjatë rri një lëvizje kompjuteri para se të vijë tjetra.
  ///
  /// 🔑 Pa këtë pauzë të tri lëvizjet ndodhin brenda një kuadri të vetëm, dhe
  /// lojtari sheh vetëm rezultatin: tabela «kërcen» dhe ai nuk e di kush çfarë
  /// luajti. Vonesa nuk është zbukurim — ajo është e vetmja gjë që e bën radhën
  /// e tre të tjerëve të lexueshme.
  static const Duration _botPause = Duration(milliseconds: 420);

  @override
  void initState() {
    super.initState();
    unawaited(Analitika.ngjarje(Analitika.lojaNisi));
    if (widget.mode == FourMode.bots) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_runBots()));
    }
  }

  bool get _myTurn =>
      widget.mode == FourMode.pass ? true : _pos.turn == red;

  @override
  Widget build(BuildContext context) {
    final FourStatus st = fourStatus(_pos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katërshi'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Nis nga e para',
            onPressed: _busy ? null : _restart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  children: <Widget>[
                    _TurnLine(
                      position: _pos,
                      mode: widget.mode,
                      status: st,
                      busy: _busy,
                    ),
                    const SizedBox(height: 8),
                    FourBoardView(
                      position: _pos,
                      onTap: _onTap,
                      selected: _selected,
                      targets: _targets
                          .map((FourMove m) => m.to)
                          .toList(growable: false),
                      lastMove: _last,
                      interactive: !_busy && !st.over && _myTurn,
                    ),
                    const SizedBox(height: 12),
                    _Scoreboard(position: _pos, mode: widget.mode),
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

  void _onTap(int square) {
    final FourStatus st = fourStatus(_pos);
    if (_busy || st.over || !_myTurn) return;

    final List<FourMove> chosen =
        _targets.where((FourMove m) => m.to == square).toList(growable: false);
    if (_selected != null && chosen.isNotEmpty) {
      unawaited(_play(chosen));
      return;
    }

    final int code = _pos.board[square];
    final bool mine = code != empty &&
        code != fourOff &&
        colorOf(code) == _pos.turn;

    setState(() {
      if (!mine || square == _selected) {
        _selected = null;
        _targets = const <FourMove>[];
      } else {
        _selected = square;
        _targets = fourLegalMoves(_pos, _pos.turn)
            .where((FourMove m) => m.from == square)
            .toList(growable: false);
      }
    });
  }

  Future<void> _play(List<FourMove> candidates) async {
    FourMove move = candidates.first;
    if (candidates.length > 1 && candidates.any((FourMove m) => m.promo != 0)) {
      final int? promo = await _askPromotion();
      if (promo == null || !mounted) return;
      move = candidates.firstWhere((FourMove m) => m.promo == promo,
          orElse: () => candidates.first);
    }

    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _pos = makeFourMove(_pos, move);
      _last = move;
      _selected = null;
      _targets = const <FourMove>[];
    });

    if (widget.mode == FourMode.bots) {
      await _runBots();
    } else {
      _maybeShowResult();
    }
  }

  Future<void> _runBots() async {
    setState(() => _busy = true);
    while (mounted && !fourStatus(_pos).over && _pos.turn != red) {
      await Future<void>.delayed(_botPause);
      if (!mounted) return;
      final FourMove? m = _bot.pick(_pos);
      if (m == null) break;
      setState(() {
        _pos = makeFourMove(_pos, m);
        _last = m;
      });
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _maybeShowResult();
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
                                painter: _FourPiecePreview(
                                  type: type,
                                  colour: _pos.turn,
                                ),
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

  void _restart() {
    setState(() {
      _pos = fourStart();
      _selected = null;
      _targets = const <FourMove>[];
      _last = null;
      _resultShown = false;
    });
    if (widget.mode == FourMode.bots) unawaited(_runBots());
  }

  void _maybeShowResult() {
    final FourStatus st = fourStatus(_pos);
    if (!st.over || _resultShown || !mounted) return;
    _resultShown = true;
    unawaited(Analitika.ngjarje(Analitika.lojaMbaroi));

    final String who = st.winner == null
        ? 'Barazim në pikë'
        : '${fourColorNamesSq[st.winner!]} fiton';

    unawaited(showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(who),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(st.reason, style: const TextStyle(color: Palette.textDim)),
            const SizedBox(height: 12),
            for (final FourPlayer p in _pos.players)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${fourColorNamesSq[p.color]}: ${p.points} pikë'
                  '${p.alive ? '' : ' — jashtë'}',
                ),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restart();
            },
            child: const Text('Prapë'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Mbaro'),
          ),
        ],
      ),
    ));
  }
}

/// Kush është në radhë, me fjalë.
class _TurnLine extends StatelessWidget {
  const _TurnLine({
    required this.position,
    required this.mode,
    required this.status,
    required this.busy,
  });

  final FourPosition position;
  final FourMode mode;
  final FourStatus status;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (status.over) {
      text = status.winner == null
          ? 'Loja mbaroi — barazim në pikë'
          : 'Loja mbaroi — ${fourColorNamesSq[status.winner!]}';
    } else if (mode == FourMode.bots) {
      text = position.turn == red
          ? 'Radha jote'
          : 'Radha e ${fourColorNamesSq[position.turn].toLowerCase()}';
    } else {
      text = 'Radha: ${fourColorNamesSq[position.turn]}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: FourPalette.chip(position.turn),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        if (busy) ...<Widget>[
          const SizedBox(width: 10),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }
}

/// Pikët e të katërve.
///
/// 🔑 Te Katërshi fituesi del nga PIKËT, jo nga ai që mbetet i fundit
/// ([fourStatus]). Pra pa këtë tabelë lojtari nuk e di as si po shkon as pse
/// mbaroi loja ashtu si mbaroi — dhe një lojë ku rregulli i fitores nuk shihet
/// askund lexohet si e rastësishme.
class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.position, required this.mode});

  final FourPosition position;
  final FourMode mode;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: position.players.map((FourPlayer p) {
        final bool turn = p.color == position.turn;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: turn ? FourPalette.chip(p.color) : Palette.surfaceHigh,
              width: turn ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: FourPalette.chip(p.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                mode == FourMode.bots && p.color == red
                    ? 'Ti'
                    : fourColorNamesSq[p.color],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: p.alive ? Palette.text : Palette.textDim,
                  decoration: p.alive ? null : TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Text('${p.points}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Palette.accent)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FourPiecePreview extends CustomPainter {
  _FourPiecePreview({required this.type, required this.colour});

  final int type;
  final int colour;

  @override
  void paint(Canvas canvas, Size size) => drawPieceShape(
        canvas,
        Offset.zero & size,
        type,
        fill: FourPalette.body[colour],
        ink: FourPalette.ink[colour],
      );

  @override
  bool shouldRepaint(_FourPiecePreview old) =>
      old.type != type || old.colour != colour;
}
