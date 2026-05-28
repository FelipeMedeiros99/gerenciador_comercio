/// Representa cada produto individual que foi adicionado dentro de uma venda
class ItemVenda {
  int? id;
  int? vendaId; // Ficará vazio até a venda ser salva no banco
  final int produtoId;
  final int quantidade;
  final double precoUnitario;

  ItemVenda({
    this.id,
    this.vendaId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitario,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venda_id': vendaId,
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
    };
  }
}
