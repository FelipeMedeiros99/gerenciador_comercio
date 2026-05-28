import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/produto.dart';

/// Classe responsável por gerenciar as operações de banco de dados para Produtos.
class ProdutoDao {
  final dbHelper = DatabaseHelper.instance;

  // 1. CADASTRAR PRODUTO
  Future<int> inserir(Produto produto) async {
    final db = await dbHelper.database;
    // O SQLite retorna o ID do novo item inserido
    return await db.insert(
      'produtos',
      produto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 2. LER ESTOQUE (Listar todos os produtos)
  Future<List<Produto>> listarTodos() async {
    final db = await dbHelper.database;
    // Faz um SELECT * na tabela produtos
    final List<Map<String, dynamic>> maps = await db.query('produtos');

    // Converte a lista de Maps para uma lista de objetos Produto
    return maps.map((map) => Produto.fromMap(map)).toList();
  }

  // 3. ATUALIZAR PRODUTO (Preço, nome ou quantidade)
  Future<int> atualizar(Produto produto) async {
    final db = await dbHelper.database;
    return await db.update(
      'produtos',
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id], // Evita ataques de SQL Injection
    );
  }

  // 4. DELETAR PRODUTO
  Future<int> deletar(int id) async {
    final db = await dbHelper.database;
    return await db.delete('produtos', where: 'id = ?', whereArgs: [id]);
  }
}
