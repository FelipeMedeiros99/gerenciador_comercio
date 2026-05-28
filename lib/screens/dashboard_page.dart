import 'package:flutter/material.dart';
import '../models/venda.dart';
import '../dao/venda_dao.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final VendaDao _vendaDao = VendaDao();

  // Data que está sendo exibida no momento. Começa com o dia de hoje.
  DateTime _dataSelecionada = DateTime.now();

  List<Venda> _vendasDoDia = [];
  List<Map<String, dynamic>> _produtosVendidos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosDoDia();
  }

  // Transforma o DateTime do Flutter no mesmo formato de texto que salvamos no banco
  String _formatarData(DateTime data) {
    return "${data.day}/${data.month}/${data.year}";
  }

  // Busca as vendas e os itens agrupados da data selecionada
  Future<void> _carregarDadosDoDia() async {
    setState(() => _carregando = true);

    final dataString = _formatarData(_dataSelecionada);
    final vendas = await _vendaDao.listarVendasPorData(dataString);
    final produtos = await _vendaDao.resumoProdutosVendidos(dataString);

    setState(() {
      _vendasDoDia = vendas;
      _produtosVendidos = produtos;
      _carregando = false;
    });
  }

  // Navegação de dias
  void _mudarDia(int dias) {
    setState(() {
      _dataSelecionada = _dataSelecionada.add(Duration(days: dias));
    });
    _carregarDadosDoDia();
  }

  // Calcula o total geral e os totais por forma de pagamento
  Map<String, double> _calcularFaturamento() {
    double totalGeral = 0.0;
    Map<String, double> totaisPorPagamento = {
      'Pix': 0.0,
      'Dinheiro': 0.0,
      'Débito': 0.0,
      'Crédito': 0.0,
    };

    for (var venda in _vendasDoDia) {
      totalGeral += venda.total;
      if (totaisPorPagamento.containsKey(venda.formaPagamento)) {
        totaisPorPagamento[venda.formaPagamento] =
            totaisPorPagamento[venda.formaPagamento]! + venda.total;
      }
    }

    totaisPorPagamento['Total'] = totalGeral;
    return totaisPorPagamento;
  }

  @override
  Widget build(BuildContext context) {
    final faturamento = _calcularFaturamento();

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Dashboard')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- SELETOR DE DATA ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => _mudarDia(-1), // Volta 1 dia
                      ),
                      Text(
                        _formatarData(_dataSelecionada),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () => _mudarDia(1), // Avança 1 dia
                      ),
                    ],
                  ),
                ),

                // --- CARDS DE FATURAMENTO ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: Colors.blue.shade50,
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Resumo Financeiro',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Text(
                            'Pix: R\$ ${faturamento['Pix']!.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Dinheiro: R\$ ${faturamento['Dinheiro']!.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Débito: R\$ ${faturamento['Débito']!.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Crédito: R\$ ${faturamento['Crédito']!.toStringAsFixed(2)}',
                          ),
                          const Divider(),
                          Text(
                            'Faturamento Total: R\$ ${faturamento['Total']!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Produtos Mais Vendidos no Dia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                // --- LISTA DE PRODUTOS VENDIDOS ---
                Expanded(
                  child: _produtosVendidos.isEmpty
                      ? const Center(
                          child: Text('Nenhum produto vendido neste dia.'),
                        )
                      : ListView.builder(
                          itemCount: _produtosVendidos.length,
                          itemBuilder: (context, index) {
                            final item = _produtosVendidos[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.inventory_2,
                                color: Colors.blueGrey,
                              ),
                              title: Text(item['nome']),
                              trailing: Text(
                                '${item['total_quantidade']} und.',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
