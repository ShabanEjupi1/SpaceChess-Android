import 'dart:math';

import 'board.dart' show empty;
import 'four.dart';

/// Kundërshtari i Katërshit.
///
/// # 🚨 Përse NUK është minimax
///
/// Te shahu dylojtarësh minimaxi është i saktë sepse fitimi im është saktësisht
/// humbja jote. Me katër lojtarë kjo nuk qëndron: dëmi që i bëj njërit u shkon
/// dobi dy të tjerëve njësoj, ndaj një pemë «max–min» do të llogariste një lojë
/// që nuk po luhet. Algoritmi i duhur (`max^n`) rritet 4^d dhe kërkon supozime
/// për aleancat — pra do të ishte njëkohësisht i ngadaltë dhe i pambështetur.
///
/// 🔑 Prandaj truri këtu kërkon një radhë përpara dhe vlerëson me ATË që vetë
/// loja e shpall fitues: **pikët** ([FourPlayer.points]). Ai ha kur ia vlen, nuk
/// e lë figurën ku hahet falas, dhe ruan mbretin. Kjo mjafton për një kundërshtar
/// që lojtari e ndien si lojtar, dhe kushton rreth 20 ms.
///
/// 🚨🚨 Ky është **i njëjti tru** si te faqja (`static/katershi.js`). Nëse
/// ndryshon njëri pa tjetrin, i njëjti modalitet luan dy lojëra të ndryshme te
/// dy pajisjet e të njëjtit person — dhe atë askush nuk e sheh si defekt, vetëm
/// si «kompjuteri këtu është më i lehtë».
class FourBot {
  FourBot({Random? random}) : _rnd = random ?? Random();

  final Random _rnd;

  /// Sa peshon një pikë e fituar drejtpërdrejt.
  static const double gainWeight = 10;

  /// Sa peshon rreziku i figurës që sapo u luajt.
  static const double hangWeight = 7;

  /// Dënimi kur mbreti im mbetet nën sulm pas lëvizjes.
  static const double kingRisk = 60;

  /// Dënimi kur lëvizja më nxjerr jashtë loje.
  static const double death = 1000;

  /// Sa e mirë është qendra në vetvete.
  static const double centreWeight = 0.4;

  /// Zhurma që i ndan dy ndeshje nga njëra-tjetra.
  static const double noise = 0.9;

  /// Lëvizja që do të luante kompjuteri për [FourPosition.turn], ose null kur
  /// nuk ka asnjë të ligjshme.
  FourMove? pick(FourPosition p) {
    final List<FourMove> moves = fourLegalMoves(p, p.turn);
    if (moves.isEmpty) return null;

    final int me = p.turn;
    FourMove? best;
    double bestScore = double.negativeInfinity;

    for (final FourMove m in moves) {
      final double s = _score(p, m, me);
      if (s > bestScore) {
        bestScore = s;
        best = m;
      }
    }
    return best;
  }

  double _score(FourPosition p, FourMove m, int me) {
    final FourPosition after = makeFourMove(p, m);
    double s = 0;

    // Ç'fitova drejtpërdrejt.
    s += (after.players[me].points - p.players[me].points) * gainWeight;

    // Sa rrezikohet figura që sapo luajta. Pyetja bëhet për të TRE të tjerët së
    // bashku: te Katërshi nuk ka «kundërshtarin», ka tre.
    final int landed = after.board[m.to];
    if (landed != empty && landed != fourOff) {
      if (fourAttackedByLiving(after, m.to, me)) {
        s -= piecePoints[pieceOf(landed)] * hangWeight;
      }
    }

    // Dhe sa mbrojtje ka ende mbreti im.
    final int k = after.kingSquareOf(me);
    if (k >= 0 && fourAttackedByLiving(after, k, me)) s -= kingRisk;
    if (!after.players[me].alive) s -= death;

    // Qendra është e mirë në vetvete: te tabela në formë kryqi ajo është e vetmja
    // zonë ku shihen të katër anët.
    final double dc = 13 -
        ((fourFile(m.to) - 6.5).abs() + (fourRank(m.to) - 6.5).abs());
    s += dc * centreWeight;

    return s + _rnd.nextDouble() * noise;
  }
}
