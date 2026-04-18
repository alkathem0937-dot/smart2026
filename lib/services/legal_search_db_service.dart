import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LegalSearchDbService {
  LegalSearchDbService._();

  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;

    final dbPath = p.join(await getDatabasesPath(), 'legal_search.db');

    if (!File(dbPath).existsSync()) {
      final data = await rootBundle.load('legal_search.db');
      final bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    _db = await openDatabase(dbPath, readOnly: true);
    return _db!;
  }

  static Future<List<Map<String, dynamic>>> searchSentences(String query, {int limit = 30}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final db = await _open();
    return db.rawQuery(
      '''
      SELECT s.id, s.paragraph_id, s.text,
        (SELECT d.title FROM documents d
          JOIN paragraphs p ON p.document_id = d.id
          WHERE p.id = s.paragraph_id
          LIMIT 1
        ) AS document_title
      FROM sentences s
      WHERE s.text LIKE ?
      ORDER BY s.paragraph_id, s.id
      LIMIT ?
      ''',
      ['%$q%', limit],
    );
  }

  static Future<List<String>> getParagraphSentences(int paragraphId) async {
    final db = await _open();
    final rows = await db.rawQuery(
      'SELECT text FROM sentences WHERE paragraph_id = ? ORDER BY id',
      [paragraphId],
    );
    return rows.map((r) => (r['text'] as String?) ?? '').toList();
  }
}
