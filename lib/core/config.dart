import 'package:button_kit/common_import.dart';

import 'package:flutter/material.dart';

Color primaryColor   = const Color(0xFF013D69);
Color secondaryColor = const Color(0xFFFE6B01);
Color backgroundColor = const Color(0xFFEFF4F8);
Color cardColor      = const Color(0xFFDCECF8);
Color sidebarColor   = const Color(0xFF0D2137);

const String superMarketTitle = "SHIVAM SUPER MARKET";
const String billAddress      = "Metoda GIDC, Kalawad Road, Rajkot";
const String telNumber        = "+91 96646 43973";

// Breakpoints
const double kMobileBreak  = 600;
const double kTabletBreak  = 1024;

BoxDecoration myDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.07),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ],
);
