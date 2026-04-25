import 'common_import.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: superMarketTitle,
      // darkTheme: ThemeData(
      //   colorScheme: ColorScheme.dark(
      //     primary: Color(0xFF10B981),
      //     secondary: Color(0xFFFBBF24),
      //     surface: Color(0xFF1F2937),
      //     background: Color(0xFF111827),
      //   )
      // ),
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color(0xFF10B981),
          secondary: Color(0xFFF59E0B),
          surface: Colors.white,
          background: Color(0xFFF9FAFB),
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
        ),
      ),
      home: Splash(),
    );
  }
}