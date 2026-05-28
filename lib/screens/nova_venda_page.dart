import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../models/venda.dart';
import '../models/item_venda.dart';
import '../dao/produto_dao.dart';
import '../dao/venda_dao.dart';

// --- CLASSE AUXILIAR PARA O CARRINHO ---
// Usamos esta classe apenas na memória da tela para facilitar a exibição dos dados.
class ItemCarrinho {
  final Produto produto;
  int quantidade;

  ItemCarrinho({required this.produto, required this.quantidade});

  double get subtotal => produto.preco * quantidade;
}

// --- TELA PRINCIPAL DE NOVA VENDA ---
class NovaVendaPage extends StatefulWidget {
  const NovaVendaPage({Key? key}) : super(key: key);

  @override
  State<NovaVendaPage> createState() => _NovaVendaPageState();
}

class _NovaVendaPageState extends State<NovaVendaPage> {
  final ProdutoDao _produtoDao = ProdutoDao();
  final VendaDao _vendaDao = VendaDao();

  List<Produto> _estoqueDisponivel = [];
  List<ItemCarrinho> _carrinho = [];

  Produto? _produtoSelecionado;
  final TextEditingController _qtdController = TextEditingController(text: '1');

  String _formaPagamentoSelecionada = 'Pix';
  final List<String> _formasPagamento = [
    'Pix',
    'Dinheiro',
    'Débito',
    'Crédito',
  ];

  @override
  void initState() {
    super.initState();
    _carregarEstoque();
  }

  // Busca os produtos no banco para o usuário poder selecionar
  Future<void> _carregarEstoque() async {
    final produtos = await _produtoDao.listarTodos();
    setState(() {
      _estoqueDisponivel = produtos;
    });
  }

  // Calcula o valor total da venda baseada nos itens do carrinho
  double get _totalVenda {
    return _carrinho.fold(0, (total, item) => total + item.subtotal);
  }

  // Adiciona um produto ao carrinho com validação de estoque
  void _adicionarAoCarrinho() {
    if (_produtoSelecionado == null) return;

    final qtdDesejada = int.tryParse(_qtdController.text) ?? 0;

    if (qtdDesejada <= 0) {
      _mostrarAviso('A quantidade deve ser maior que zero.');
      return;
    }

    if (qtdDesejada > _produtoSelecionado!.quantidade) {
      _mostrarAviso(
        'Estoque insuficiente! Você só tem ${_produtoSelecionado!.quantidade} unidades.',
      );
      return;
    }

    setState(() {
      // Verifica se o produto já está no carrinho para apenas somar a quantidade
      final index = _carrinho.indexWhere(
        (item) => item.produto.id == _produtoSelecionado!.id,
      );

      if (index >= 0) {
        if ((_carrinho[index].quantidade + qtdDesejada) >
            _produtoSelecionado!.quantidade) {
          _mostrarAviso('A soma das quantidades excede o estoque disponível.');
          return;
        }
        _carrinho[index].quantidade += qtdDesejada;
      } else {
        _carrinho.add(
          ItemCarrinho(produto: _produtoSelecionado!, quantidade: qtdDesejada),
        );
      }

      // Limpa os campos após adicionar
      _produtoSelecionado = null;
      _qtdController.text = '1';
    });
  }

  // Remove um item específico do carrinho
  void _removerDoCarrinho(int index) {
    setState(() {
      _carrinho.removeAt(index);
    });
  }

  // Salva a venda no banco de dados e atualiza o estoque (A mágica acontece aqui)
  Future<void> _finalizarVenda() async {
    if (_carrinho.isEmpty) {
      _mostrarAviso('Adicione pelo menos um produto ao carrinho.');
      return;
    }

    // 1. Cria o objeto da Venda principal
    final dataAtual =
        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    final novaVenda = Venda(
      data: dataAtual,
      formaPagamento: _formaPagamentoSelecionada,
      total: _totalVenda,
    );

    // 2. Converte nosso carrinho da UI para os modelos do Banco de Dados
    final itensVenda = _carrinho.map((item) {
      return ItemVenda(
        produtoId: item.produto.id!,
        quantidade: item.quantidade,
        precoUnitario: item.produto.preco,
      );
    }).toList();

    // 3. Aciona o DAO para registrar a venda e dar baixa no estoque
    await _vendaDao.registrarVenda(novaVenda, itensVenda);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Venda finalizada com sucesso!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Limpa a tela para a próxima venda e recarrega o estoque
      setState(() {
        _carrinho.clear();
        _carregarEstoque();
      });
    }
  }

  // Função auxiliar para exibir avisos rápidos (SnackBars)
  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ponto de Venda (PDV)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- ÁREA DE SELEÇÃO DE PRODUTO ---
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<Produto>(
                    decoration: const InputDecoration(
                      labelText: 'Selecione o Produto',
                    ),
                    value: _produtoSelecionado,
                    items: _estoqueDisponivel.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.nome} (Estoque: ${p.quantidade})'),
                      );
                    }).toList(),
                    onChanged: (produto) {
                      setState(() {
                        _produtoSelecionado = produto;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _qtdController,
                    decoration: const InputDecoration(labelText: 'Qtd'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _adicionarAoCarrinho,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Adicionar ao Carrinho'),
            ),
            const Divider(height: 30, thickness: 2),

            // --- LISTA DO CARRINHO ---
            const Text(
              'Carrinho de Compras',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: _carrinho.isEmpty
                  ? const Center(child: Text('O carrinho está vazio.'))
                  : ListView.builder(
                      itemCount: _carrinho.length,
                      itemBuilder: (context, index) {
                        final item = _carrinho[index];
                        return ListTile(
                          title: Text(item.produto.nome),
                          subtitle: Text(
                            '${item.quantidade}x R\$ ${item.produto.preco.toStringAsFixed(2)} = R\$ ${item.subtotal.toStringAsFixed(2)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () => _removerDoCarrinho(index),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(thickness: 2),

            // --- ÁREA DE FINALIZAÇÃO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Forma de Pagamento:',
                  style: TextStyle(fontSize: 16),
                ),
                DropdownButton<String>(
                  value: _formaPagamentoSelecionada,
                  items: _formasPagamento.map((forma) {
                    return DropdownMenuItem(value: forma, child: Text(forma));
                  }).toList(),
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() {
                        _formaPagamentoSelecionada = valor;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Total a Pagar: R\$ ${_totalVenda.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: _finalizarVenda,
              child: const Text(
                'FINALIZAR VENDA',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
