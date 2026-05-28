import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/venda.dart';
import '../models/item_venda.dart';

class VendaDao {
  final dbHelper = DatabaseHelper.instance;

  // 1. REGISTRAR VENDA E DAR BAIXA NO ESTOQUE
  Future<void> registrarVenda(Venda venda, List<ItemVenda> itens) async {
    final db = await dbHelper.database;

    // O db.transaction garante que tudo dentro dele seja executado como um bloco único.
    // Se algo falhar, ele desfaz (rollback) para não corromper os dados.
    await db.transaction((txn) async {
      // Passo A: Salva a Venda e recupera o ID gerado para ela
      final vendaId = await txn.insert('vendas', venda.toMap());

      // Passo B: Para cada item no carrinho de compras...
      for (var item in itens) {
        // Vincula o item à venda recém-criada
        item.vendaId = vendaId;
        await txn.insert('itens_venda', item.toMap());

        // Passo C: Atualiza o estoque do produto (diminui a quantidade)
        await txn.rawUpdate(
          'UPDATE produtos SET quantidade = quantidade - ? WHERE id = ?',
          [item.quantidade, item.produtoId],
        );
      }
    });
  }

  // 2. LISTAR TODAS AS VENDAS (Para o histórico)
  Future<List<Venda>> listarVendas() async {
    final db = await dbHelper.database;
    // Lista as vendas ordenando pelas mais recentes (maior ID primeiro)
    final maps = await db.query('vendas', orderBy: 'id DESC');
    return maps.map((map) => Venda.fromMap(map)).toList();
  }

  // 3. DELETAR VENDA E DEVOLVER PRODUTOS AO ESTOQUE
  Future<void> deletarVenda(int vendaId) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      // Pega os itens dessa venda antes de apagar
      final itens = await txn.query(
        'itens_venda',
        where: 'venda_id = ?',
        whereArgs: [vendaId],
      );

      // Devolve a quantidade de volta pro estoque de cada produto
      for (var item in itens) {
        await txn.rawUpdate(
          'UPDATE produtos SET quantidade = quantidade + ? WHERE id = ?',
          [item['quantidade'], item['produto_id']],
        );
      }

      // Agora sim deleta a venda (o banco apaga os itens_venda automaticamente via CASCADE)
      await txn.delete('vendas', where: 'id = ?', whereArgs: [vendaId]);
    });
  }

  Future<List<Venda>> listarVendasPorData(String data) async {
    final db = await dbHelper.database;
    // Traz as vendas filtrando pela data fornecida
    final maps = await db.query('vendas', where: 'data = ?', whereArgs: [data]);
    return maps.map((map) => Venda.fromMap(map)).toList();
  }

  // 5. RESUMO DE PRODUTOS VENDIDOS NO DIA (Usando SQL avançado)
  Future<List<Map<String, dynamic>>> resumoProdutosVendidos(String data) async {
    final db = await dbHelper.database;

    final sql = '''
      SELECT p.nome, SUM(iv.quantidade) as total_quantidade 
      FROM itens_venda iv
      JOIN vendas v ON v.id = iv.venda_id
      JOIN produtos p ON p.id = iv.produto_id
      WHERE v.data = ?
      GROUP BY p.nome
    ''';

    // CORREÇÃO: Adicionamos o argumento [data] para substituir o '?' do SQL
    return await db.rawQuery(sql, [data]);
  }
}
