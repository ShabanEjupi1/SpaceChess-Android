// I GJENERUAR nga tool/gjenero_enigma.dart — mos e ndrysho me dorë.
//
// Çdo zë është provuar nga vetë motori: mati është i DETYRUAR dhe
// lëvizja e parë është e VETMJA që e jep. Shih komentin e gjeneruesit.
library;

/// Një enigmë: pozicioni, zgjidhja dhe sa lëvizje të bardha duhen.
class Enigma {
  const Enigma(this.fen, this.zgjidhja, this.hapa);

  /// Pozicioni i nisjes. I bardhi luan gjithmonë.
  final String fen;

  /// Lëvizja e parë e të bardhit, në UCI. Është e vetmja që fiton.
  final String zgjidhja;

  /// 1 ose 2 — sa lëvizje të bardha deri te mati.
  final int hapa;
}

const List<Enigma> enigmat = <Enigma>[
  Enigma('8/3Q4/8/8/8/7K/8/7k w - - 0 1', 'd7d1', 1),
  Enigma('8/6Q1/8/2Q5/8/5K2/8/4k3 w - - 0 1', 'c5c1', 1),
  Enigma('8/5R2/8/Q7/8/8/8/1k1K4 w - - 0 1', 'f7b7', 1),
  Enigma('6k1/8/8/8/7Q/5Q2/2KR4/8 w - - 0 1', 'd2g2', 1),
  Enigma('8/8/8/4B3/k7/8/1R4Q1/2K5 w - - 0 1', 'g2a8', 1),
  Enigma('B7/8/6Q1/8/8/5B2/k1K5/8 w - - 0 1', 'g6a6', 1),
  Enigma('4Q3/8/3N4/8/5k1K/8/8/4N3 w - - 0 1', 'e8e4', 1),
  Enigma('8/8/1Q6/8/6Q1/3K4/k5B1/8 w - - 0 1', 'g4a4', 1),
  Enigma('1Q6/8/8/8/N3R3/3K4/8/2k5 w - - 0 1', 'e4e1', 1),
  Enigma('k7/8/8/1N6/8/8/K5N1/6Q1 w - - 0 1', 'g1a7', 1),
  Enigma('K6k/8/4N2B/8/6Q1/8/8/8 w - - 0 1', 'g4g7', 1),
  Enigma('K7/1Q3N2/8/8/8/8/6Q1/4k3 w - - 0 1', 'b7b1', 1),
  Enigma('5B2/7k/5Q2/8/8/1N6/7K/8 w - - 0 1', 'f6g7', 1),
  Enigma('8/8/6B1/8/2r5/6Q1/4K3/k7 w - - 0 1', 'g3a3', 1),
  Enigma('r7/8/3Q4/8/8/8/6R1/4k1K1 w - - 0 1', 'd6d2', 1),
  Enigma('8/Q4K2/8/8/8/8/1rQ3N1/5k2 w - - 0 1', 'a7f2', 1),
  Enigma('8/2B4K/8/8/4k3/1rQ5/3Q4/8 w - - 0 1', 'd2d3', 1),
  Enigma('b7/B7/8/5Q2/2k5/R7/8/1K6 w - - 0 1', 'f5c5', 1),
  Enigma('2N5/8/4r3/2K5/8/N1k5/5Q2/8 w - - 0 1', 'f2c2', 1),
  Enigma('5B2/k2q4/b7/8/8/2K5/7B/7B w - - 0 1', 'f8c5', 1),
  Enigma('4k3/8/8/6Q1/8/B2r4/7n/K4Q2 w - - 0 1', 'g5e7', 1),
  Enigma('6R1/8/Q6b/6b1/8/3K1Q2/8/2k5 w - - 0 1', 'a6a1', 1),
  Enigma('2b4k/8/5KB1/8/8/Q1n5/R7/8 w - - 0 1', 'a3f8', 1),
  Enigma('8/8/7k/5K2/Q2q4/5b2/5NQ1/8 w - - 0 1', 'g2g6', 1),
  Enigma('8/8/8/k2K4/5Q2/8/8/8 w - - 0 1', 'd5c6', 2),
  Enigma('8/8/8/8/8/5KR1/7k/8 w - - 0 1', 'f3f2', 2),
  Enigma('8/8/8/4R3/k7/8/2K5/8 w - - 0 1', 'c2c3', 2),
  Enigma('6K1/8/7k/R7/8/8/8/8 w - - 0 1', 'g8f7', 2),
  Enigma('5Q2/8/8/8/8/1K6/8/3k4 w - - 0 1', 'f8f2', 2),
  Enigma('8/8/3K4/8/8/8/1Q6/3k3N w - - 0 1', 'h1g3', 2),
  Enigma('8/8/3N4/8/8/3K2Q1/k7/8 w - - 0 1', 'd3c2', 2),
  Enigma('1R6/8/6K1/4k3/8/3R4/8/8 w - - 0 1', 'b8b4', 2),
  Enigma('8/4Q3/8/8/k7/2R5/8/3K4 w - - 0 1', 'e7b7', 2),
  Enigma('8/2K5/8/4Q3/2B4k/8/8/8 w - - 0 1', 'e5f4', 2),
  Enigma('5R2/8/4K2k/5B2/8/8/8/8 w - - 0 1', 'e6f6', 2),
  Enigma('5k2/8/1KR5/8/8/4R3/8/8 w - - 0 1', 'c6c7', 2),
  Enigma('5R2/k7/8/8/8/4K3/N4R2/8 w - - 0 1', 'f2b2', 2),
  Enigma('k5B1/8/8/1N5R/8/3K4/8/8 w - - 0 1', 'g8d5', 2),
  Enigma('2Q3K1/8/8/8/3R4/8/8/4kB2 w - - 0 1', 'c8c2', 2),
  Enigma('8/2B5/6R1/8/1K1k4/8/8/2Q5 w - - 0 1', 'g6e6', 2),
  Enigma('N4R2/8/5K2/8/k7/8/8/4R3 w - - 0 1', 'f8b8', 2),
  Enigma('8/7k/8/2R5/8/8/Q7/3K3n w - - 0 1', 'a2f7', 2),
  Enigma('4Q3/8/7B/8/5K2/3k4/8/6R1 w - - 0 1', 'g1c1', 2),
  Enigma('7r/1k1K4/8/8/8/8/8/2QB4 w - - 0 1', 'c1c7', 2),
  Enigma('5R2/8/8/8/Q7/1RK4k/8/8 w - - 0 1', 'f8g8', 2),
  Enigma('3Q3N/8/8/8/3R4/8/2K1k3/8 w - - 0 1', 'd4f4', 2),
  Enigma('8/7N/8/k7/3RK3/8/2R5/8 w - - 0 1', 'c2b2', 2),
  Enigma('1N2kB2/8/8/8/8/2Q5/8/4K3 w - - 0 1', 'c3g7', 2),
  Enigma('8/1k3n2/3R4/2QK4/8/8/1B6/8 w - - 0 1', 'd6b6', 2),
  Enigma('6Q1/8/8/1Q6/6Nq/8/2k3K1/8 w - - 0 1', 'g8a2', 2),
  Enigma('2k5/5b2/K7/8/Q3N3/8/5B2/8 w - - 0 1', 'a4c6', 2),
  Enigma('8/7k/1K3b1r/6Q1/8/8/8/2Q5 w - - 0 1', 'g5h6', 2),
  Enigma('8/2K3b1/8/Q7/8/8/1k1n3Q/8 w - - 0 1', 'h2d2', 2),
  Enigma('2k3K1/8/1R6/6R1/8/3Q4/8/7q w - - 0 1', 'g5c5', 2),
  Enigma('4Q3/N2K4/1q6/8/8/8/R7/3k4 w - - 0 1', 'e8e2', 2),
  Enigma('5Q2/5B2/6n1/8/8/b7/3RK3/1k6 w - - 0 1', 'f7g6', 2),
  Enigma('7K/1q6/7N/5Q2/8/2R5/7q/7k w - - 0 1', 'f5f1', 2),
  Enigma('B7/4n3/6R1/2Q5/7b/5K2/8/1k6 w - - 0 1', 'g6b6', 2),
  Enigma('2K5/7k/8/8/5Q2/6B1/8/1b1b1B2 w - - 0 1', 'f4f7', 2),
  Enigma('4q3/5Q2/6Q1/8/3q4/8/B1K5/4k3 w - - 0 1', 'g6g3', 2),
];
