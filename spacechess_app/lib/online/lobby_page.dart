import 'dart:async';

import 'package:flutter/material.dart';

import '../app/prefs.dart';
import '../app/theme.dart';
import 'api.dart';
import 'online_page.dart';
import 'report_sheet.dart';

/// Salla: hap një lojë të re ose hyr te një e hapur.
class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key, required this.prefs});

  final Prefs prefs;

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  late final SpaceChessApi _api = SpaceChessApi(widget.prefs);

  List<dynamic> _challenges = const <dynamic>[];
  List<dynamic> _board = const <dynamic>[];
  bool _busy = true;
  String? _error;

  String _variant = 'standard';
  String _tc = '10+0';

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    // Sesioni i pari: pa të, çdo rrugë tjetër kthen 401 dhe salla del bosh pa
    // asnjë shpjegim.
    final Map<String, dynamic>? me = await _api.session(
        name: widget.prefs.name.isEmpty ? null : widget.prefs.name);
    if (!mounted) return;
    if (me == null) {
      setState(() {
        _busy = false;
        // Një emër i refuzuar nga filtri kthen 400 me shpjegim shqip. Pa këtë
        // rresht do të shkruante «serveri nuk u përgjigj» — dhe lojtari do ta
        // provonte të njëjtin emër përjetësisht.
        _error = _api.lastError ?? 'Serveri nuk u përgjigj. Kontrollo internetin.';
      });
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    final Map<String, dynamic>? lobby = await _api.lobby();
    final Map<String, dynamic>? board = await _api.leaderboard();
    if (!mounted) return;
    setState(() {
      _challenges = (lobby?['challenges'] as List<dynamic>?) ?? const <dynamic>[];
      _board = (board?['players'] as List<dynamic>?) ?? const <dynamic>[];
      _busy = false;
    });
  }

  Future<void> _create(String mode) async {
    setState(() => _busy = true);
    final Map<String, dynamic>? r = await _api.createGame(
      mode: mode,
      variant: _variant,
      tc: _tc,
      rated: mode == 'random',
    );
    if (!mounted) return;
    setState(() => _busy = false);

    final Map<String, dynamic>? game = r?['game'] as Map<String, dynamic>?;
    if (game == null) {
      setState(() => _error = 'Loja nuk u hap.');
      return;
    }
    await _open(game['id'] as String);
  }

  /// Cilësimet e llogarisë. Përmban fshirjen, që Google Play e kërkon të jetë
  /// e arritshme **brenda** aplikacionit për çdo llogari të krijuar brenda tij.
  Future<void> _accountSettings() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Llogaria'),
              subtitle: Text(widget.prefs.name.isEmpty
                  ? 'Mysafir — pa emër, pa email, pa fjalëkalim'
                  : '${widget.prefs.name} — pa email, pa fjalëkalim'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Color(0xFFE05252)),
              title: const Text('Fshi llogarinë',
                  style: TextStyle(color: Color(0xFFE05252))),
              subtitle: const Text(
                  'Emri dhe vlerësimi fshihen menjëherë e nuk kthehen mbrapsht.'),
              onTap: () {
                Navigator.of(sheet).pop();
                unawaited(_confirmDelete());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (!mounted) return;
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext d) => AlertDialog(
            title: const Text('Të fshihet llogaria?'),
            content: const Text(
                'Emri, vlerësimi dhe historiku yt fshihen nga serveri dhe nuk '
                'kthehen mbrapsht.\n\n'
                'Lojërat e luajtura mbeten te kundërshtarët, por pa emrin tënd.\n\n'
                'Loja kundër kompjuterit dhe ajo në një pajisje vazhdojnë të '
                'punojnë — ato nuk kërkojnë llogari.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Jo'),
              ),
              TextButton(
                onPressed: () => Navigator.of(d).pop(true),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFE05252)),
                child: const Text('Fshi'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    final bool done = await _api.deleteAccount();
    if (!mounted) return;

    if (!done) {
      setState(() {
        _busy = false;
        _error = 'Fshirja dështoi. Kontrollo internetin dhe provo sërish.';
      });
      return;
    }
    // Llogaria s'ekziston më, ndaj salla nuk ka çfarë të tregojë. Dalja te
    // menyja është e vetmja gjendje e ndershme.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Llogaria u fshi.')),
    );
  }

  Future<void> _open(String id) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          OnlineGamePage(api: _api, gameId: id, prefs: widget.prefs),
    ));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luaj online'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Cilësimet e llogarisë',
            onPressed: _busy ? null : () => unawaited(_accountSettings()),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: <Widget>[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFE05252))),
                ),

              _chips('Varianti', const <String, String>{
                'standard': 'Standard',
                'chess960': 'Chess960',
                'koth': 'Kodra',
                'threecheck': 'Tre shahe',
                'antichess': 'Antishah',
              }, _variant, (String v) => setState(() => _variant = v)),

              const SizedBox(height: 12),
              _chips('Koha', const <String, String>{
                '1+0': '1+0',
                '3+2': '3+2',
                '5+3': '5+3',
                '10+0': '10+0',
                '15+10': '15+10',
                '0+0': 'Pa kohë',
              }, _tc, (String v) => setState(() => _tc = v)),

              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : () => unawaited(_create('random')),
                icon: const Icon(Icons.shuffle),
                label: const Text('Kundërshtar i rastësishëm'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => unawaited(_create('friend')),
                icon: const Icon(Icons.link),
                label: const Text('Hap një lojë për një shok'),
              ),

              const SizedBox(height: 28),
              const Text('Lojëra të hapura',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_challenges.isEmpty)
                const Text('Asnjë për momentin.',
                    style: TextStyle(color: Palette.textDim))
              else
                ..._challenges.map((dynamic c) {
                  final Map<String, dynamic> g = c as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${g['variant']} · ${(g['tc'] as Map<String, dynamic>)['id']}'),
                    subtitle: Text(g['rated'] == true ? 'Me pikë' : 'Pa pikë',
                        style: const TextStyle(color: Palette.textDim)),
                    trailing: const Icon(Icons.play_arrow_rounded),
                    onTap: () async {
                      await _api.join(g['id'] as String);
                      await _open(g['id'] as String);
                    },
                  );
                }),

              const SizedBox(height: 28),
              const Text('Renditja',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              // Emrat këtu janë të shkruar nga vetë lojtarët dhe shihen nga të
              // gjithë: prandaj çdo rresht mban edhe rrugën e raportimit që
              // Google Play e kërkon për përmbajtjen e krijuar nga përdoruesit.
              ..._board.take(10).map((dynamic p) {
                final Map<String, dynamic> u = p as Map<String, dynamic>;
                final String id = '${u['id'] ?? ''}';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text('${u['name'] ?? 'Anonim'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('${u['rating'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.report_outlined, size: 20),
                        tooltip: 'Raporto',
                        visualDensity: VisualDensity.compact,
                        onPressed: id.isEmpty || id == _api.userId
                            ? null
                            : () => unawaited(showReportSheet(
                                  context: context,
                                  api: _api,
                                  targetId: id,
                                  targetName: '${u['name'] ?? 'Anonim'}',
                                )),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chips(String label, Map<String, String> options, String value,
      ValueChanged<String> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: const TextStyle(color: Palette.textDim, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries
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
}
