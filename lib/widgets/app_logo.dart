import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key}); // تم التصحيح هنا

  @override
  Widget build(BuildContext context) {
    return Image.asset("assets/check.png", height: 100);
  }
}
