/// Classe que representa um Produto no estoque.
class Produto {
  final int? id;
  final String nome;
  final double preco;
  int quantidade;

  Produto({
    this.id,
    required this.nome,
    required this.preco,
    required this.quantidade,
  });

  // Converte um Produto em um Map para salvar no SQLite
  Map<String, dynamic> toMap() {
    return {'id': id, 'nome': nome, 'preco': preco, 'quantidade': quantidade};
  }

  // Converte um Map vindo do SQLite de volta para um Objeto Produto
  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'],
      nome: map['nome'],
      preco: map['preco'],
      quantidade: map['quantidade'],
    );
  }
}
