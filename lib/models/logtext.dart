import 'dart:ui';

class LogTextDecoration {
  LogTextDecoration(
      {required this.fgColor, required this.bgColor, required this.isBold});

  final Color fgColor;
  final Color bgColor;
  final bool isBold;
}

class LogText {
  LogText({required this.text, required this.logFormatDecoration});

  final String text;
  final LogTextDecoration logFormatDecoration;
}
