import 'package:flutter/material.dart';

/// Espaçamentos em múltiplos de 4.
abstract final class CorreSpace {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

abstract final class CorreRadius {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 22.0;
  static const pill = 999.0;
  static final smAll = BorderRadius.circular(sm);
  static final mdAll = BorderRadius.circular(md);
  static final lgAll = BorderRadius.circular(lg);
  static final pillAll = BorderRadius.circular(pill);
}

abstract final class CorreShadow {
  static const card = [BoxShadow(color: Color(0x1416202A), blurRadius: 10, offset: Offset(0, 2))];
  static const raised = [BoxShadow(color: Color(0x2416202A), blurRadius: 24, offset: Offset(0, 8))];
}

abstract final class CorreDuration {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 400);
}

/// Larguras de corte para layout responsivo.
abstract final class CorreBreakpoint {
  static const tablet = 600.0;
  static const desktop = 1024.0;
}
