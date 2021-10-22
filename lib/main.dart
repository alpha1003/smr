import 'package:flutter/material.dart';
import 'package:smr/src/pages/medicionPage.dart';
import 'package:smr/src/theme/theme.dart' as tema;
import 'package:smr/src/pages/login_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      theme: tema.theme,
      
    );
  }
}