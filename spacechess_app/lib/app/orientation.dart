import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kufiri i njëjtë që Android e përdor për `sw600dp`: nën të është telefon,
/// mbi të tablet, dritare desktopi ose Google Play Games on PC.
const double kGjeresiaEMadhe = 600;

/// A e ka kjo dritare hapësirën për një paraqitje me dy shtylla?
bool eshteEGjere(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= kGjeresiaEMadhe;

/// Lejon peizazhin VETËM aty ku gjerësia sjell diçka; te telefoni mban portretin.
///
/// 🚨 Deri më 05-08-2026 orientimi kyçej pa kushte te `main()`, dhe **pikërisht
/// ai kyç — jo manifesti — është shkaku pse loja del si shirit i ngushtë te
/// Google Play Games on PC.** Manifesti nuk e ka kurrë `screenOrientation`,
/// ndaj kontrolli i tij nuk zbulon asgjë: kërkesa bëhet gjatë ekzekutimit me
/// [SystemChrome.setPreferredOrientations], dhe dritarja e PC-së e respekton.
///
/// Arsyeja e kyçit të vjetër mbetet e vlefshme te telefoni — një tabelë katrore
/// që rrotullohet në mes të një radhe vetëm e humb lojtarin — prandaj kushti
/// është madhësia, jo platforma.
class OrientimiPershtatur extends StatefulWidget {
  const OrientimiPershtatur({super.key, required this.child});

  final Widget child;

  @override
  State<OrientimiPershtatur> createState() => _OrientimiPershtaturState();
}

class _OrientimiPershtaturState extends State<OrientimiPershtatur> {
  bool? _eGjere;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🚨 Matja bëhet KËTU, nga MediaQuery, jo te `main()`. Atje
    // `PlatformDispatcher.views.first.physicalSize` mund të jetë ende zero para
    // kuadrit të parë, dhe kushti do të vendosej gabim njëherë e përgjithmonë.
    final bool eGjere = eshteEGjere(context);
    if (eGjere == _eGjere) return;
    _eGjere = eGjere;

    unawaited(SystemChrome.setPreferredOrientations(
      eGjere
          // Listë bosh = pa kufizim, pra sistemi vendos. E domosdoshme që
          // dritarja e PC-së të mund të jetë e gjerë.
          ? const <DeviceOrientation>[]
          : const <DeviceOrientation>[
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    ));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
