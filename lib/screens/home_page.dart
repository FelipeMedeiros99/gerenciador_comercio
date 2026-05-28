import 'package:flutter/material.dart';
import 'estoque_page.dart';
import 'nova_venda_page.dart';
import 'historico_vendas_page.dart';
import 'dashboard_page.dart';

/// Tela principal que gerencia a navegação inferior do aplicativo.
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variável que guarda qual aba está selecionada no momento.
  // Começamos no índice 0 (Nova Venda) pois é a ação mais comum no dia a dia.
  int _indiceAtual = 0;

  // Lista com as telas que criamos.
  // A ordem aqui deve ser a mesma dos botões na barra de navegação.
  final List<Widget> _telas = const [
    DashboardPage(),
    NovaVendaPage(),
    EstoquePage(),
    HistoricoVendasPage(),
  ];

  // Função chamada toda vez que o usuário toca em um item da barra inferior
  void _aoTocarNaAba(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O IndexedStack exibe apenas uma tela por vez, baseada no 'index',
      // mas mantém o estado das outras telas preservado em memória.
      body: IndexedStack(index: _indiceAtual, children: _telas),

      // A barra de navegação na parte inferior da tela
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: _aoTocarNaAba,
        type: BottomNavigationBarType.fixed,
        // Cores para deixar a navegação mais intuitiva
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        // Define os ícones e textos de cada aba
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), // <--- NOVO ÍCONE
            label: 'Visão Geral',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Vender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Estoque',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
