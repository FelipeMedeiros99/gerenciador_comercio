/// Representa o registro geral de uma venda
class Venda {
  int? id;
  final String data;
  final String formaPagamento;
  final double total;

  Venda({
    this.id,
    required this.data,
    required this.formaPagamento,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'forma_pagamento': formaPagamento,
      'total': total,
    };
  }

  factory Venda.fromMap(Map<String, dynamic> map) {
    return Venda(
      id: map['id'],
      data: map['data'],
      formaPagamento: map['forma_pagamento'],
      total: map['total'],
    );
  }
}
