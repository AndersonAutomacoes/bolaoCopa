import 'package:flutter/material.dart';

/// Espaçamentos e larguras máximas alinhados aos mockups (Direção visual v1).
abstract final class AppLayout {
  static const double authCardMaxWidth = 420;
  static const double registerCardMaxWidth = 480;
  static const double contentMaxWidth = 560;
  static const double editorialTextMaxWidth = 720;

  static const EdgeInsets pagePaddingH = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets pagePaddingHV = EdgeInsets.fromLTRB(20, 8, 20, 24);
  static const EdgeInsets pagePaddingAll = EdgeInsets.all(20);

  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets authCardPadding = EdgeInsets.all(28);
}
