import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Classe Singleton para gerenciar o banco de dados SQLite.
class DatabaseHelper {
  // Instância única da classe (Singleton)
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Retorna o banco de dados se já estiver aberto, caso contrário, inicializa.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('comerciante_app.db');
    return _database!;
  }

  // Inicializa o banco de dados no diretório correto do dispositivo
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Abre o banco. A versão (version: 1) é usada para futuras migrações.
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Criação das tabelas necessárias para o aplicativo
  Future _createDB(Database db, int version) async {
    // Tabela de Produtos
    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        preco REAL NOT NULL,
        quantidade INTEGER NOT NULL
      )
    ''');

    // Tabela de Vendas
    await db.execute('''
      CREATE TABLE vendas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        forma_pagamento TEXT NOT NULL,
        total REAL NOT NULL
      )
    ''');

    // Tabela de Itens da Venda (Relacionamento N:N entre vendas e produtos)
    await db.execute('''
      CREATE TABLE itens_venda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venda_id INTEGER NOT NULL,
        produto_id INTEGER NOT NULL,
        quantidade INTEGER NOT NULL,
        preco_unitario REAL NOT NULL,
        FOREIGN KEY (venda_id) REFERENCES vendas (id) ON DELETE CASCADE,
        FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE CASCADE
      )
    ''');
  }

  // Fecha o banco de dados
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
