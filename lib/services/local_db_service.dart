import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/lawsuit_model.dart';
import '../models/hearing_model.dart';
import '../models/attachment_model.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartjudi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS lawsuits');
      await db.execute('DROP TABLE IF EXISTS hearings');
      await db.execute('DROP TABLE IF EXISTS attachments');
      await _createDB(db, newVersion);
    } else if (oldVersion < 4) {
      // Upgrade to version 4: Recreate hearings table with new schema
      await db.execute('DROP TABLE IF EXISTS hearings');
      // Recreate hearings table with new schema
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT';
      const boolType = 'INTEGER'; // 0 for false, 1 for true
      const intType = 'INTEGER';
      
      await db.execute('''
CREATE TABLE hearings (
  local_id $idType,
  id $intType,
  lawsuit_id $intType,
  hearing_date $textType,
  hijri_date $textType,
  hearing_time $textType,
  hearing_type $textType,
  judge_name $textType,
  notes $textType,
  is_synced $boolType DEFAULT 0,
  created_at $textType,
  updated_at $textType,
  archive_status $textType,
  archive_date $textType,
  archive_reason $textType,
  is_deleted $boolType DEFAULT 0,
  deleted_at $textType
)
''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const boolType = 'INTEGER'; // 0 for false, 1 for true
    const intType = 'INTEGER';

    await db.execute('''
CREATE TABLE lawsuits (
  local_id $idType,
  id $intType,
  case_number $textType,
  case_type $textType,
  status $textType,
  case_status $textType,
  subject $textType,
  description $textType,
  facts $textType,
  legal_basis $textType,
  legal_reasons $textType,
  requests $textType,
  governorate $textType,
  notes $textType,
  filing_date $textType,
  gregorian_date $textType,
  hijri_date $textType,
  court_fk $intType,
  court_name $textType,
  judge $intType,
  judge_name $textType,
  created_at $textType,
  updated_at $textType,
  archive_status $textType,
  archive_date $textType,
  archive_reason $textType,
  is_deleted $boolType DEFAULT 0,
  deleted_at $textType,
  parent_lawsuit_id $intType,
  client_id $intType,
  client_name $textType,
  created_by_id $intType,
  created_by_name $textType,
  is_synced $boolType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE hearings (
  local_id $idType,
  id $intType,
  lawsuit_id $intType,
  hearing_date $textType,
  hijri_date $textType,
  hearing_time $textType,
  hearing_type $textType,
  judge_name $textType,
  notes $textType,
  is_synced $boolType DEFAULT 0,
  created_at $textType,
  updated_at $textType,
  archive_status $textType,
  archive_date $textType,
  archive_reason $textType,
  is_deleted $boolType DEFAULT 0,
  deleted_at $textType
)
''');

    await db.execute('''
CREATE TABLE attachments (
  local_id $idType,
  id $intType,
  lawsuit_id $intType,
  document_type $textType,
  document_type_display $textType,
  gregorian_date $textType,
  hijri_date $textType,
  page_count $intType,
  content $textType,
  evidence_basis $textType,
  file_url $textType,
  local_path $textType,
  original_filename $textType,
  file_size $intType,
  is_synced $boolType DEFAULT 0
)
''');
  }

  // --- Lawsuit CRUD ---

  Future<int> insertLawsuit(LawsuitModel lawsuit) async {
    final db = await instance.database;
    final map = lawsuit.toLocalJson();
    map['is_synced'] = lawsuit.id != null ? 1 : 0;
    
    // Conflict Resolution: Last Write Wins
    if (lawsuit.id != null) {
      final existing = await db.query('lawsuits', where: 'id = ?', whereArgs: [lawsuit.id]);
      if (existing.isNotEmpty) {
        final existingLawsuit = LawsuitModel.fromJson(existing.first);
        if (existingLawsuit.updatedAt != null && lawsuit.updatedAt != null) {
          if (existingLawsuit.updatedAt!.isAfter(lawsuit.updatedAt!)) {
            // Local version is newer, don't overwrite
            return 0;
          }
        }
      }
    }

    return await db.insert('lawsuits', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LawsuitModel>> getAllLawsuits() async {
    final db = await instance.database;
    try {
      final result = await db.query('lawsuits');
      return result
          .map((json) => LawsuitModel.fromJson(json))
          .where((lawsuit) => !lawsuit.isDeleted)
          .toList();
    } catch (e) {
      print('Error querying lawsuits: $e');
      return [];
    }
  }

  Future<List<LawsuitModel>> getUnsyncedLawsuits() async {
    final db = await instance.database;
    final result = await db.query('lawsuits', where: 'is_synced = 0');
    return result.map((json) => LawsuitModel.fromJson(json)).toList();
  }

  Future<void> updateSyncStatus(String table, int localId, int serverId) async {
    final db = await instance.database;
    await db.update(
      table,
      {'is_synced': 1, 'id': serverId},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('lawsuits');
    await db.delete('hearings');
    await db.delete('attachments');
  }

  Future<void> deleteLawsuit(int localId) async {
    final db = await instance.database;
    await db.delete('lawsuits', where: 'local_id = ?', whereArgs: [localId]);
  }

  // --- Hearing CRUD ---
  
  Future<int> insertHearing(HearingModel hearing) async {
    final db = await instance.database;
    final map = hearing.toJson();
    map['is_synced'] = hearing.id != null ? 1 : 0;
    return await db.insert('hearings', map);
  }

  Future<List<HearingModel>> getHearingsForLawsuit(int lawsuitId) async {
    final db = await instance.database;
    final result = await db.query('hearings', where: 'lawsuit_id = ?', whereArgs: [lawsuitId]);
    return result.map((json) => HearingModel.fromJson(json)).toList();
  }

  // --- Attachment CRUD ---

  Future<int> insertAttachment(AttachmentModel attachment, {String? localPath}) async {
    final db = await instance.database;
    final map = attachment.toJson();
    if (localPath != null) map['local_path'] = localPath;
    map['is_synced'] = attachment.id != null ? 1 : 0;
    return await db.insert('attachments', map);
  }

  Future<List<AttachmentModel>> getAttachmentsForLawsuit(int lawsuitId) async {
    final db = await instance.database;
    final result = await db.query('attachments', where: 'lawsuit_id = ?', whereArgs: [lawsuitId]);
    return result.map((json) => AttachmentModel.fromJson(json)).toList();
  }

  Future<void> deleteAttachment(int id) async {
    final db = await instance.database;
    await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAttachmentTitle(int id, String newTitle) async {
    final db = await instance.database;
    await db.update(
      'attachments',
      {'original_filename': newTitle, 'content': 'اسم المستند: $newTitle'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
