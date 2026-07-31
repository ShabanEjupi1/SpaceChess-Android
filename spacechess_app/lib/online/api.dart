import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/prefs.dart';

/// Klienti i serverit të SpaceChess (`chess.spacecode.tech`).
///
/// 🔑 **Tokeni dërgohet me dorë si kokë `Cookie:`.** Serveri e krijon llogarinë
/// me një `Set-Cookie` njëvjeçar dhe kjo është e gjithë llogaria — pa email, pa
/// fjalëkalim. Një shfletues e mban vetë; një aplikacion vendas jo, ndaj
/// [Prefs.token] e ruan dhe secila kërkesë e rivendos. Pikërisht kjo është
/// arsyeja pse mbështjellësi i vjetër ishte TWA e jo WebView: një WebView ka
/// depozitë të vetën, dhe lojtari do t'i humbte pikët në çdo pastrim.
class SpaceChessApi {
  SpaceChessApi(this.prefs, {http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        base = baseUrl ?? defaultBase;

  static const String defaultBase = 'https://chess.spacecode.tech';

  final Prefs prefs;
  final http.Client _client;
  final String base;

  /// Id-ja e lojtarit që rri pas këtij tokeni. Duhet për dy gjëra që s'i thotë
  /// dot asgjë tjetër: cila anë je te një lojë, dhe kë po raporton.
  String? userId;

  /// Mesazhi i fundit i gabimit që erdhi NGA serveri (jo nga rrjeti). Filtri i
  /// emrave përgjigjet me 400 dhe me një shpjegim shqip; pa e mbajtur këtu,
  /// aplikacioni do të thoshte «serveri nuk u përgjigj» për një emër të
  /// refuzuar — dhe lojtari do të provonte të njëjtin emër përjetësisht.
  String? lastError;

  Map<String, String> get _headers => <String, String>{
        'accept': 'application/json',
        'content-type': 'application/json',
        if (prefs.token != null) 'cookie': 'sc_token=${prefs.token}',
      };

  /// Hap ose rimerr sesionin. Duhet thirrur një herë para çdo gjëje tjetër:
  /// çdo rrugë tjetër përveç `/api/health`, `/api/config` dhe `/api/leaderboard`
  /// kthen 401 pa të.
  Future<Map<String, dynamic>?> session({String? name}) async {
    lastError = null;
    final http.Response r = await _client.post(
      Uri.parse('$base/api/session'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{if (name != null) 'name': name}),
    );
    if (r.statusCode != 200) {
      lastError = _errorOf(r);
      return null;
    }

    // Tokeni vjen VETËM te përgjigjja e parë, kur llogaria krijohet. Nëse humbet
    // këtu, humbet përgjithmonë — bashkë me pikët e lojtarit.
    final String? setCookie = r.headers['set-cookie'];
    if (setCookie != null) {
      final RegExpMatch? m =
          RegExp(r'sc_token=([^;]+)').firstMatch(setCookie);
      if (m != null) await prefs.setToken(m.group(1)!);
    }
    final Map<String, dynamic>? body = _decode(r);
    userId = (body?['user'] as Map<String, dynamic>?)?['id'] as String?;
    return body;
  }

  /// Raporton një lojtar tjetër. E kërkon politika e Google Play-t për
  /// përmbajtjen e krijuar nga përdoruesit: emrat shfaqen publikisht, ndaj
  /// krahas filtrit duhet edhe një rrugë me të cilën lojtarët i njoftojnë ata
  /// që filtri nuk i kap.
  ///
  /// Arsyet janë listë e mbyllur (`emri`, `sjellja`, `mashtrim`, `tjeter`) —
  /// një kuti me tekst të lirë do të ishte vetë UGC.
  Future<bool> report(String target, String reason, {String? game}) async {
    lastError = null;
    try {
      final http.Response r = await _client.post(
        Uri.parse('$base/api/report'),
        headers: _headers,
        body: jsonEncode(<String, dynamic>{
          'target': target,
          'reason': reason,
          if (game != null) 'game': game,
        }),
      );
      if (r.statusCode == 200) return true;
      lastError = _errorOf(r);
      return false;
    } catch (_) {
      return false;
    }
  }

  String? _errorOf(http.Response r) {
    try {
      final Object? decoded = jsonDecode(utf8.decode(r.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Një përgjigje pa JSON nuk ka çfarë t'i thotë lojtarit.
    }
    return null;
  }

  Future<Map<String, dynamic>?> me() async {
    final Map<String, dynamic>? r = await _get('/api/me');
    userId ??= (r?['user'] as Map<String, dynamic>?)?['id'] as String?;
    return r;
  }
  Future<Map<String, dynamic>?> config() => _get('/api/config');
  Future<Map<String, dynamic>?> lobby() => _get('/api/lobby');
  Future<Map<String, dynamic>?> leaderboard() => _get('/api/leaderboard');
  Future<Map<String, dynamic>?> myGames() => _get('/api/my-games');
  Future<Map<String, dynamic>?> game(String id) => _get('/api/games/$id');

  Future<Map<String, dynamic>?> createGame({
    required String mode,
    required String variant,
    required String tc,
    String color = 'random',
    bool rated = true,
  }) =>
      _post('/api/games', <String, dynamic>{
        'mode': mode,
        'variant': variant,
        'tc': tc,
        'color': color,
        'rated': rated,
      });

  Future<Map<String, dynamic>?> join(String id) =>
      _post('/api/games/$id/join', const <String, dynamic>{});

  Future<Map<String, dynamic>?> move(String id, String uci) =>
      _post('/api/games/$id/move', <String, dynamic>{'uci': uci});

  Future<Map<String, dynamic>?> resign(String id) =>
      _post('/api/games/$id/resign', const <String, dynamic>{});

  Future<Map<String, dynamic>?> draw(String id, String action) =>
      _post('/api/games/$id/draw', <String, dynamic>{'action': action});

  /// Fshin llogarinë te serveri. E kërkon politika e Google Play-t: një llogari
  /// e krijuar brenda aplikacionit duhet të fshihet brenda aplikacionit.
  ///
  /// 🚨 Kthen `true` edhe kur serveri përgjigjet 401, dhe kjo është me qëllim:
  /// 401 do të thotë që tokeni nuk i takon më asnjë llogarie, pra fshirja
  /// tashmë ka ndodhur. Të thuhej «dështoi» do të ishte gënjeshtër që e lë
  /// lojtarin të mendojë se të dhënat i kanë mbetur.
  Future<bool> deleteAccount() async {
    try {
      final http.Response r = await _client.delete(
        Uri.parse('$base/api/me'),
        headers: _headers,
      );
      if (r.statusCode == 200 || r.statusCode == 401 || r.statusCode == 404) {
        await prefs.clearToken();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _get(String path) async =>
      _decode(await _client.get(Uri.parse('$base$path'), headers: _headers));

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async =>
      _decode(await _client.post(Uri.parse('$base$path'),
          headers: _headers, body: jsonEncode(body)));

  /// Një përgjigje e keqe kthen null e nuk hedh përjashtim: kjo është buza ku
  /// mbërrin rrjeti, dhe një lojë që rrëzohet sepse tuneli ra për dy sekonda
  /// është më keq se një lojë që thotë «provo sërish».
  Map<String, dynamic>? _decode(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) return null;
    try {
      final Object? decoded = jsonDecode(utf8.decode(r.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close();
}
