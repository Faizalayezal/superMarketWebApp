import 'package:button_kit/common_import.dart';

Color primaryColor=Color(0xff013d69);
Color secondaryColor=Color(0xfffe6b01);
Color backgroundColor=Color(0xffB9D9EB);
Color cardColor=Color(0xff87CEFA);

const superMarketTitle="SHIVAM SUPER MARKET";
const billAddress="Metoda GIDC,Kalawad Road,Rajkot";
const telNumber="+91 96646 43973";

var myDecoration=BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
          color: Colors.black,
          spreadRadius: 1,
          blurRadius: 1
        // offset: Offset(0, 2)
      )
    ]
);
