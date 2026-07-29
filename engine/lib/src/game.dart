import 'board.dart';
import 'moves.dart';
import 'san.dart';
import 'status.dart';

/// Një lojë e plotë: pozicioni i tanishëm plus gjithçka që pozicioni vetë nuk e
/// mban mend.
///
/// 🔑 Përsëritja trefishe dhe rregulli i 50 lëvizjeve NUK lexohen dot nga një
/// tabelë e vetme — duhet historia. Prandaj [status] jeton këtu e jo te
/// [Position]: një pozicion i vetëm nuk e di kurrë nëse është parë tri herë,
/// dhe një motor që e pretendon këtë gabon pikërisht te fundlojët ku ka rëndësi.
class Game {
  Game({Variant variant = Variant.standard, int? chess960Id, String? fen})
      : _start = fen ?? startFenFor(variant, chess960Id),
        variant = variant,
        chess960Id = chess960Id {
    _position = fromFen(_start, variant);
    _repetitions.add(repetitionKey(_position));
  }

  final String _start;
  final Variant variant;
  final int? chess960Id;

  late Position _position;
  final List<Move> _moves = <Move>[];
  final List<String> _san = <String>[];
  final List<String> _repetitions = <String>[];

  Position get position => _position;
  String get startFen => _start;
  List<Move> get moves => List<Move>.unmodifiable(_moves);
  List<String> get sanMoves => List<String>.unmodifiable(_san);
  String get fen => toFen(_position);
  int get side => _position.side;

  GameStatus get status => gameStatus(_position, _repetitions);
  bool get isOver => status.over;
  List<Move> get legal => legalMoves(_position);

  /// Luan një lëvizje. Kthen `false` — pa ndryshuar asgjë — për çdo lëvizje që
  /// nuk është e ligjshme në këtë pozicion. Ky është kufiri ku mbërrijnë të
  /// dhëna nga rrjeti dhe nga prekja e gishtit; asnjëra s'guxon të rrëzojë asgjë.
  bool apply(Move move) {
    final Move? legalMove = legalMoves(_position).where((Move m) =>
        m.from == move.from && m.to == move.to && m.promo == move.promo).firstOrNull;
    if (legalMove == null) return false;

    _san.add(toSan(_position, legalMove));
    _position = makeMove(_position, legalMove);
    _moves.add(legalMove);
    _repetitions.add(repetitionKey(_position));
    return true;
  }

  bool applyUci(String uci) {
    final Move? m = moveFromUci(_position, uci);
    return m != null && apply(m);
  }

  /// Kthen mbrapsht një lëvizje duke e riluajtur lojën nga fillimi.
  ///
  /// Riluajtja është me qëllim: një pirg pozicionesh të ruajtura do të ishte më
  /// i shpejtë, por edhe një burim i dytë i së vërtetës, dhe pikërisht ai divergjon.
  /// Një lojë shahu ka nën 200 lëvizje — riluajtja është e paperceptueshme.
  bool undo() {
    if (_moves.isEmpty) return false;
    final List<Move> keep = _moves.sublist(0, _moves.length - 1);
    _position = fromFen(_start, variant);
    _moves.clear();
    _san.clear();
    _repetitions
      ..clear()
      ..add(repetitionKey(_position));
    for (final Move m in keep) {
      apply(m);
    }
    return true;
  }

  /// PGN — vetëm lëvizjet, pa kokë. Koka i takon atij që e ruan lojën.
  String get moveText {
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < _san.length; i++) {
      if (i.isEven) b.write('${i ~/ 2 + 1}. ');
      b.write(_san[i]);
      b.write(i == _san.length - 1 ? '' : ' ');
    }
    return b.toString();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
