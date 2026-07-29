import 'dart:typed_data';

/// Tabela është një «mailbox» 10×12: një varg prej 120 kutish ku kutitë jashtë
/// tabelës mbajnë [off].
///
/// 🔑 Kjo është arsyeja pse asnjë gjenerator lëvizjesh më poshtë nuk ka kontroll
/// kufijsh: një oficer që ecën në një drejtim ndalet vetë te roja [off], dhe një
/// kalorës që del nga tabela lexon [off] në vend të një kutie të gabuar në anën
/// tjetër. Me një varg 8×8, secila prej atyre rrugëve do të donte një `if` më
/// vete — dhe pikërisht ata `if`-a janë vendi ku motorët e shahut gabojnë.
///
/// a1=21, h1=28, a8=91, h8=98.
const int off = 99;

const int empty = 0;
const int pawn = 1;
const int knight = 2;
const int bishop = 3;
const int rook = 4;
const int queen = 5;
const int king = 6;

const int white = 1;
const int black = -1;

/// Variantet. Emrat janë ata që udhëtojnë te rrjeti dhe te FEN-i i serverit
/// (`Variant.koth.name == 'koth'`), ndaj mos i riemërto pa ndryshuar serverin.
enum Variant { standard, chess960, koth, threecheck, antichess }

const int _n = 10, _s = -10, _e = 1, _w = -1;
const int _ne = _n + _e, _nw = _n + _w, _se = _s + _e, _sw = _s + _w;

const List<int> knightDirs = <int>[
  _n + _ne, _n + _nw, _s + _se, _s + _sw,
  _e + _ne, _e + _se, _w + _nw, _w + _sw,
];
const List<int> bishopDirs = <int>[_ne, _nw, _se, _sw];
const List<int> rookDirs = <int>[_n, _s, _e, _w];
const List<int> kingDirs = <int>[..._rookThenBishop];
const List<int> _rookThenBishop = <int>[_n, _s, _e, _w, _ne, _nw, _se, _sw];

/// Katër kutitë që fitojnë një lojë «Mbreti i Kodrës»: d4, e4, d5, e5.
const List<int> hill = <int>[54, 55, 64, 65];

const String _files = 'abcdefgh';
const Map<int, String> pieceChar = <int, String>{
  pawn: 'p', knight: 'n', bishop: 'b', rook: 'r', queen: 'q', king: 'k',
};
const Map<String, int> charPiece = <String, int>{
  'p': pawn, 'n': knight, 'b': bishop, 'r': rook, 'q': queen, 'k': king,
};

int sq(int file, int rank) => 21 + file + 10 * rank;
int fileOf(int s) => (s % 10) - 1;
int rankOf(int s) => (s ~/ 10) - 2;
bool onBoard(int s) => s >= 21 && s <= 98 && fileOf(s) >= 0 && fileOf(s) <= 7;

String algebraic(int s) => '${_files[fileOf(s)]}${rankOf(s) + 1}';
int parseSquare(String a) => sq(_files.indexOf(a[0]), int.parse(a[1]) - 1);

/// Ana e rokadës. Ruhet gjithmonë bashkë me kutinë e NISJES së kalit të rokadës,
/// jo si `KQkq` — kjo e vetme e bën Chess960-n të punojë pa një rrugë të dytë
/// kodi, sepse te shahu standard ato kuti thjesht rastis të jenë a1/h1/a8/h8.
enum CastleSide { king, queen }

class Position {
  Position() : board = Int8List(120) {
    board.fillRange(0, 120, off);
    for (int r = 0; r < 8; r++) {
      for (int f = 0; f < 8; f++) {
        board[sq(f, r)] = empty;
      }
    }
  }

  Position._raw(this.board);

  final Int8List board;

  int side = white;

  /// Kutia e nisjes së kalit që ende mund të bëjë rokadë, ose null.
  int? whiteKingRook;
  int? whiteQueenRook;
  int? blackKingRook;
  int? blackQueenRook;

  int? ep;
  int halfmove = 0;
  int fullmove = 1;
  Variant variant = Variant.standard;

  /// Vetëm për variantin «tre shahe».
  int whiteChecks = 0;
  int blackChecks = 0;

  int? castleRook(int color, CastleSide s) => color == white
      ? (s == CastleSide.king ? whiteKingRook : whiteQueenRook)
      : (s == CastleSide.king ? blackKingRook : blackQueenRook);

  void setCastleRook(int color, CastleSide s, int? value) {
    if (color == white) {
      if (s == CastleSide.king) {
        whiteKingRook = value;
      } else {
        whiteQueenRook = value;
      }
    } else {
      if (s == CastleSide.king) {
        blackKingRook = value;
      } else {
        blackQueenRook = value;
      }
    }
  }

  int checksOf(int color) => color == white ? whiteChecks : blackChecks;
  void bumpChecks(int color) =>
      color == white ? whiteChecks++ : blackChecks++;

  Position clone() {
    final Position p = Position._raw(Int8List.fromList(board))
      ..side = side
      ..whiteKingRook = whiteKingRook
      ..whiteQueenRook = whiteQueenRook
      ..blackKingRook = blackKingRook
      ..blackQueenRook = blackQueenRook
      ..ep = ep
      ..halfmove = halfmove
      ..fullmove = fullmove
      ..variant = variant
      ..whiteChecks = whiteChecks
      ..blackChecks = blackChecks;
    return p;
  }

  /// Leximi i mbrojtur i një kutie.
  ///
  /// Çdo thirrës i sotëm rri brenda 0..119 (roja e mailbox-it e siguron atë), pra
  /// kjo nuk duhet për saktësi — duhet që një gabim i ardhshëm në një drejtim të
  /// ri të kthejë «jashtë tabele» në vend të një rrëzimi te përdoruesi.
  int at(int s) => (s < 0 || s > 119) ? off : board[s];

  int pieceAt(int s) => at(s);

  int colorAt(int s) {
    final int v = at(s);
    if (v == empty || v == off) return 0;
    return v > 0 ? white : black;
  }

  /// Kutia e mbretit, ose null — që është e ligjshme te antishahu, ku mbreti
  /// është figurë e zakonshme dhe mund të hahet.
  int? kingSquare(int color) {
    for (int s = 21; s <= 98; s++) {
      if (board[s] == king * color) return s;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEN
// ─────────────────────────────────────────────────────────────────────────────

const String startFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

Position fromFen(String fen, [Variant variant = Variant.standard]) {
  final Position p = Position()..variant = variant;
  final List<String> parts = fen.trim().split(RegExp(r'\s+'));
  final List<String> rows = parts[0].split('/');

  for (int r = 0; r < 8; r++) {
    final String row = rows[7 - r]; // FEN-i nis nga rreshti 8
    int f = 0;
    for (final String ch in row.split('')) {
      final int? digit = int.tryParse(ch);
      if (digit != null) {
        f += digit;
        continue;
      }
      final int type = charPiece[ch.toLowerCase()]!;
      p.board[sq(f, r)] = ch == ch.toLowerCase() ? -type : type;
      f++;
    }
  }

  p.side = parts.length > 1 && parts[1] == 'b' ? black : white;

  if (parts.length > 2 && parts[2] != '-') {
    for (final String ch in parts[2].split('')) {
      final int color = ch == ch.toUpperCase() ? white : black;
      final int rank = color == white ? 0 : 7;
      final int? kingSq = p.kingSquare(color);
      final String up = ch.toUpperCase();

      // Një pozicion i vërtetë Chess960 e ka mbretin mes dy kalëve, pra secila
      // anë pretendohet një herë. Çdo gjë tjetër është FEN i keq: vendose kalin
      // te ana e lirë, në vend që të humbet një e drejtë rokade në heshtje.
      void assign(CastleSide s, int rookSq) {
        if (p.castleRook(color, s) == null) {
          p.setCastleRook(color, s, rookSq);
        } else {
          final CastleSide other =
              s == CastleSide.king ? CastleSide.queen : CastleSide.king;
          if (p.castleRook(color, other) == null) {
            p.setCastleRook(color, other, rookSq);
          }
        }
      }

      if (up == 'K' || up == 'Q') {
        // Shënimi standard: gjej kalin më të jashtëm në atë anë të mbretit.
        final int dir = up == 'K' ? 1 : -1;
        int? found;
        for (int f = up == 'K' ? 7 : 0; f >= 0 && f <= 7; f -= dir) {
          final int s = sq(f, rank);
          if (p.board[s] == rook * color &&
              (kingSq == null || (dir > 0 ? s > kingSq : s < kingSq))) {
            found = s;
            break;
          }
        }
        if (found != null) {
          assign(up == 'K' ? CastleSide.king : CastleSide.queen, found);
        }
      } else {
        // Shredder-FEN (Chess960): shkronja ËSHTË skedari i kalit.
        final int f = _files.indexOf(up.toLowerCase());
        if (f >= 0) {
          final int s = sq(f, rank);
          assign(
            kingSq != null && s > kingSq ? CastleSide.king : CastleSide.queen,
            s,
          );
        }
      }
    }
  }

  p.ep = parts.length > 3 && parts[3] != '-' ? parseSquare(parts[3]) : null;
  p.halfmove = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
  p.fullmove = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;
  return p;
}

/// `KQkq` kur gjeometria nuk dallohet nga shahu standard (mbreti te e, kali te
/// a/h), shkronja-skedar Shredder përndryshe. [toFen] dhe gjeneruesi i
/// Chess960-s kalojnë të dy nga këtu, që një pozicion i gjeneruar dhe kthimi i
/// tij nga FEN-i të mos shkruajnë kurrë fusha rokade të ndryshme.
String castleLetter(int kingFile, int rookFile, CastleSide side) {
  final bool standard = kingFile == 4 &&
      ((side == CastleSide.king && rookFile == 7) ||
          (side == CastleSide.queen && rookFile == 0));
  return standard
      ? (side == CastleSide.king ? 'K' : 'Q')
      : _files[rookFile].toUpperCase();
}

String toFen(Position p) {
  final List<String> rows = <String>[];
  for (int r = 7; r >= 0; r--) {
    final StringBuffer row = StringBuffer();
    int gap = 0;
    for (int f = 0; f < 8; f++) {
      final int v = p.board[sq(f, r)];
      if (v == empty) {
        gap++;
        continue;
      }
      if (gap > 0) {
        row.write(gap);
        gap = 0;
      }
      final String ch = pieceChar[v.abs()]!;
      row.write(v > 0 ? ch.toUpperCase() : ch);
    }
    if (gap > 0) row.write(gap);
    rows.add(row.toString());
  }

  final StringBuffer castle = StringBuffer();
  for (final int color in <int>[white, black]) {
    final int? k = p.kingSquare(color);
    final int kf = k != null ? fileOf(k) : -1;
    for (final CastleSide side in CastleSide.values) {
      final int? rookSq = p.castleRook(color, side);
      if (rookSq == null) continue;
      final String ch = castleLetter(kf, fileOf(rookSq), side);
      castle.write(color == white ? ch : ch.toLowerCase());
    }
  }

  return <String>[
    rows.join('/'),
    p.side == white ? 'w' : 'b',
    castle.isEmpty ? '-' : castle.toString(),
    p.ep != null ? algebraic(p.ep!) : '-',
    '${p.halfmove}',
    '${p.fullmove}',
  ].join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Chess960
// ─────────────────────────────────────────────────────────────────────────────

/// Numërimi Scharnagl, pra pozicioni 518 është rreshtimi standard.
String chess960Fen(int id) {
  final List<String?> row = List<String?>.filled(8, null);
  int n = id;
  const List<int> light = <int>[1, 3, 5, 7];
  const List<int> dark = <int>[0, 2, 4, 6];

  row[light[n % 4]] = 'b';
  n ~/= 4;
  row[dark[n % 4]] = 'b';
  n ~/= 4;
  final int q = n % 6;
  n ~/= 6;

  int seen = -1;
  for (int i = 0; i < 8; i++) {
    if (row[i] == null && ++seen == q) {
      row[i] = 'q';
      break;
    }
  }

  const List<String> krn = <String>[
    'nnrkr', 'nrnkr', 'nrknr', 'nrkrn', 'rnnkr',
    'rnknr', 'rnkrn', 'rknnr', 'rknrn', 'rkrnn',
  ];
  final List<String> rest = krn[n].split('');
  for (int i = 0, j = 0; i < 8; i++) {
    if (row[i] == null) row[i] = rest[j++];
  }

  final String back = row.join();
  final int kingFile = back.indexOf('k');
  final List<int> rooks = <int>[];
  for (int i = 0; i < 8; i++) {
    if (back[i] == 'r') rooks.add(i);
  }

  // rooks[0] rri majtas mbretit, rooks[1] djathtas — këtë e garanton tabela KRN
  // më lart, që gjithmonë e vendos mbretin mes tyre.
  final String k = castleLetter(kingFile, rooks[1], CastleSide.king);
  final String qq = castleLetter(kingFile, rooks[0], CastleSide.queen);
  final String castle = '$k$qq${k.toLowerCase()}${qq.toLowerCase()}';

  return '$back/pppppppp/8/8/8/8/PPPPPPPP/${back.toUpperCase()} w $castle - 0 1';
}

String startFenFor(Variant variant, [int? chess960Id]) =>
    variant == Variant.chess960
        ? chess960Fen(chess960Id ?? 518)
        : startFen;
