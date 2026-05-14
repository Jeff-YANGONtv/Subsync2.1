import 'package:flutter/widgets.dart';

enum Breakpoint { mobile, tablet, desktop }

class Breakpoints {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static Breakpoint of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileMax) return Breakpoint.mobile;
    if (w < tabletMax) return Breakpoint.tablet;
    return Breakpoint.desktop;
  }
}
