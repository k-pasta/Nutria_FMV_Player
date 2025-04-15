import 'dart:ui';

class AppTheme {
  final Color backgroundColor;
  final Color cText;
  final Color cTextActive;
  final Color cTextInactive;
  final double dTextHeight;
  final double dOptionblurRadius;
  final double dOptionBorderRadius ;

  const AppTheme({
    this.backgroundColor = const Color(0xFF000000),
    this.cText = const Color(0x91FFFFFF),
    this.cTextActive = const Color(0xFFFFFFFF),
    this.cTextInactive = const Color(0x65FFFFFF),
    this.dTextHeight = 16,
    this.dOptionblurRadius = 15,
    this.dOptionBorderRadius = 0,
  });
}
