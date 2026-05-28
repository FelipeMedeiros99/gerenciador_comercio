import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../dao/produto_dao.dart';

class EstoquePage extends StatefulWidget {
  const EstoquePage({Key? key}) : super(key: key);

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  final ProdutoDao _dao = ProdutoDao();
  List<Produto> _produtos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _atualizarLista();
  }

  // Busca os produtos no banco e atualiza a tela
  Future<void> _atualizarLista() async {
    final produtos = await _dao.listarTodos();
    setState(() {
      _produtos = produtos;
      _carregando = false;
    });
  }

  // Função para deletar com confirmação visual
  Future<void> _deletarProduto(int id) async {
    await _dao.deletar(id);
    _atualizarLista();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto excluído com sucesso!')),
      );
    }
  }

  // Exibe um modal (Dialog) para Criar ou Editar um produto
  void _mostrarFormularioProduto({Produto? produtoExistente}) {
    final nomeController = TextEditingController(
      text: produtoExistente?.nome ?? '',
    );
    final precoController = TextEditingController(
      text: produtoExistente?.preco.toString() ?? '',
    );
    final qtdController = TextEditingController(
      text: produtoExistente?.quantidade.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          produtoExistente == null ? 'Novo Produto' : 'Editar Produto',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Produto'),
              ),
              TextField(
                controller: precoController,
                decoration: const InputDecoration(labelText: 'Preço (R\$)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: qtdController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade em Estoque',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text;
              final preco =
                  double.tryParse(precoController.text.replaceAll(',', '.')) ??
                  0.0;
              final qtd = int.tryParse(qtdController.text) ?? 0;

              if (nome.isNotEmpty && preco > 0) {
                final novoProduto = Produto(
                  id: produtoExistente?.id,
                  nome: nome,
                  preco: preco,
                  quantidade: qtd,
                );

                if (produtoExistente == null) {
                  await _dao.inserir(novoProduto);
                } else {
                  await _dao.atualizar(novoProduto);
                }

                _atualizarLista();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Estoque')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _produtos.isEmpty
          ? const Center(child: Text('Nenhum produto cadastrado.'))
          : ListView.builder(
              itemCount: _produtos.length,
              itemBuilder: (context, index) {
                final produto = _produtos[index];
                return ListTile(
                  title: Text(produto.nome),
                  subtitle: Text(
                    'Estoque: ${produto.quantidade} | R\$ ${produto.preco.toStringAsFixed(2)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _mostrarFormularioProduto(
                          produtoExistente: produto,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletarProduto(produto.id!),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioProduto(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
