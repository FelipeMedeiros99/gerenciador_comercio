import 'package:flutter/material.dart';
// Importamos apenas a HomePage, pois ela cuidará de chamar as outras telas
import 'screens/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ComercianteApp());
}

class ComercianteApp extends StatelessWidget {
  const ComercianteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Comércio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 4,
          shadowColor: Colors.black45,
        ),
      ),
      // Apontamos o início do app para a tela de navegação
      home: const HomePage(),
    );
  }
}
