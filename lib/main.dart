import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'tr_TR';
  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harcama Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
