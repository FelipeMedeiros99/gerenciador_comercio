import 'package:flutter/material.dart';
import '../models/venda.dart';
import '../dao/venda_dao.dart';

/// Tela responsável por exibir o histórico de todas as vendas realizadas.
class HistoricoVendasPage extends StatefulWidget {
  const HistoricoVendasPage({Key? key}) : super(key: key);

  @override
  State<HistoricoVendasPage> createState() => _HistoricoVendasPageState();
}

class _HistoricoVendasPageState extends State<HistoricoVendasPage> {
  // Instanciamos o DAO para acessar as operações de banco de dados das vendas
  final VendaDao _vendaDao = VendaDao();

  // Lista que vai armazenar as vendas carregadas do banco
  List<Venda> _vendas = [];

  // Variável de controle para mostrar um indicador de carregamento na tela
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    // Assim que a tela é iniciada, chamamos a função para buscar os dados
    _carregarVendas();
  }

  /// Função que se comunica com o banco de dados para buscar o histórico
  Future<void> _carregarVendas() async {
    // Busca a lista de vendas de forma assíncrona
    final vendas = await _vendaDao.listarVendas();

    // Atualiza o estado da tela com os novos dados e remove o loading
    setState(() {
      _vendas = vendas;
      _carregando = false;
    });
  }

  /// Função para deletar uma venda e devolver os itens ao estoque
  Future<void> _deletarVenda(int id) async {
    // Mostra um diálogo de confirmação para evitar exclusões acidentais
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Venda?'),
        content: const Text('Os produtos desta venda retornarão ao estoque.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancela
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), // Confirma
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // Se o usuário confirmou a exclusão
    if (confirmar == true) {
      // Deleta a venda no banco de dados (isso aciona a nossa transação do DAO)
      await _vendaDao.deletarVenda(id);

      // Recarrega a lista para a venda sumir da tela
      _carregarVendas();

      // Mostra um aviso visual (SnackBar) de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda excluída e estoque restaurado!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Vendas')),
      // Construção do corpo da tela com base no estado do carregamento
      body: _carregando
          ? const Center(child: CircularProgressIndicator()) // Mostra loading
          : _vendas.isEmpty
          ? const Center(
              child: Text('Nenhuma venda registrada ainda.'),
            ) // Mostra se estiver vazio
          : ListView.builder(
              // ListView.builder cria a lista sob demanda (otimiza a memória)
              padding: const EdgeInsets.all(8.0),
              itemCount: _vendas.length,
              itemBuilder: (context, index) {
                final venda = _vendas[index];

                // Card é usado para dar um visual agradável a cada item da lista
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      // Formata o valor total com duas casas decimais
                      'Total: R\$ ${venda.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Data: ${venda.data}\nPagamento: ${venda.formaPagamento}',
                    ),
                    // Botão de lixeira à direita
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deletarVenda(venda.id!),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
