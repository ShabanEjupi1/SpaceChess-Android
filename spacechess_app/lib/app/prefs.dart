import 'package:shared_preferences/shared_preferences.dart';

/// Gjithçka që aplikacioni mban mend mes nisjeve.
///
/// 🔑 [token] është e gjithë llogaria: serveri i SpaceChess nuk ka as email as
/// fjalëkalim, vetëm një kredencial të rastësishëm që mban pikët dhe historinë.
/// Te shfletuesi ai është një cookie; këtu duhet ruajtur vetë dhe dërguar si
/// kokë `Cookie:` — prandaj një WebView do t'i kishte humbur pikët e lojtarit
/// (depozitë tjetër), dhe pikërisht kjo ishte arsyeja e mbështjellësit TWA.
/// Tani që aplikacioni është vendas, tokeni rri këtu dhe nuk humbet më.
class Prefs {
  Prefs._(this._p);

  static const String _kToken = 'sc_token';
  static const String _kName = 'name';
  static const String _kLevel = 'level';
  static const String _kVariant = 'variant';
  static const String _kFlip = 'flip';
  static const String _kSaved = 'saved_game';
  static const String _kSavedVariant = 'saved_variant';
  static const String _kSavedFen = 'saved_fen';
  static const String _kSavedColor = 'saved_colour';

  final SharedPreferences _p;

  static Future<Prefs> open() async => Prefs._(await SharedPreferences.getInstance());

  String? get token => _p.getString(_kToken);
  Future<void> setToken(String v) => _p.setString(_kToken, v);

  /// Pas fshirjes së llogarisë. Heq edhe emrin: po të mbetej, kërkesa e parë e
  /// radhës do ta rikrijonte menjëherë të njëjtin lojtar dhe fshirja do të
  /// dukej sikur nuk ndodhi.
  Future<void> clearToken() async {
    await _p.remove(_kToken);
    await _p.remove(_kName);
  }

  String get name => _p.getString(_kName) ?? '';
  Future<void> setName(String v) => _p.setString(_kName, v.trim());

  int get level => _p.getInt(_kLevel) ?? 4;
  Future<void> setLevel(int v) => _p.setInt(_kLevel, v);

  String get variant => _p.getString(_kVariant) ?? 'standard';
  Future<void> setVariant(String v) => _p.setString(_kVariant, v);

  /// A e mban lojtari tabelën të kthyer (i ziu poshtë) te loja në një pajisje.
  bool get autoFlip => _p.getBool(_kFlip) ?? true;
  Future<void> setAutoFlip(bool v) => _p.setBool(_kFlip, v);

  /// Loja e lënë përgjysmë kundër kompjuterit: lëvizjet, varianti, FEN-i i
  /// nisjes (Chess960 e ka të vetin) dhe ngjyra e njeriut.
  ({List<String> moves, String variant, String fen, int colour})? get savedGame {
    final String? moves = _p.getString(_kSaved);
    if (moves == null || moves.isEmpty) return null;
    return (
      moves: moves.split(','),
      variant: _p.getString(_kSavedVariant) ?? 'standard',
      fen: _p.getString(_kSavedFen) ?? '',
      colour: _p.getInt(_kSavedColor) ?? 1,
    );
  }

  Future<void> saveGame({
    required List<String> moves,
    required String variant,
    required String fen,
    required int colour,
  }) async {
    await _p.setString(_kSaved, moves.join(','));
    await _p.setString(_kSavedVariant, variant);
    await _p.setString(_kSavedFen, fen);
    await _p.setInt(_kSavedColor, colour);
  }

  Future<void> clearSavedGame() async {
    await _p.remove(_kSaved);
    await _p.remove(_kSavedVariant);
    await _p.remove(_kSavedFen);
    await _p.remove(_kSavedColor);
  }
}
