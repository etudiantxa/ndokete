import 'package:hive_flutter/hive_flutter.dart';

/// Service Hive centralisé pour le stockage offline-first.
/// Chaque box = une entité métier synchronisable avec le serveur.
class HiveService {
  static const String ordersBox = 'orders';
  static const String customersBox = 'customers';
  static const String transactionsBox = 'transactions';
  static const String stockBox = 'stock';
  static const String syncQueueBox = 'sync_queue';
  static const String notificationsBox = 'notifications';
  static const String userBox = 'user';

  // Appelé par setupDependencies() via getIt
  Future<void> init() async {
    await Hive.initFlutter();
    await registerAdapters();
    await openBoxes();
  }

  static Future<void> registerAdapters() async {
    // Les adaptateurs sont générés par build_runner + hive_generator.
    // Après avoir annoté vos models avec @HiveType / @HiveField, lancez :
    //   flutter pub run build_runner build --delete-conflicting-outputs
    // puis décommentez et importez les adapters générés ici.
  }

  static Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox<dynamic>(ordersBox),
      Hive.openBox<dynamic>(customersBox),
      Hive.openBox<dynamic>(transactionsBox),
      Hive.openBox<dynamic>(stockBox),
      Hive.openBox<dynamic>(syncQueueBox),
      Hive.openBox<dynamic>(notificationsBox),
      Hive.openBox<dynamic>(userBox),
    ]);
  }

  // ── Opérations offline génériques ────────────────────────────────────────

  static Future<void> saveItem(
      String boxName, String key, Map<String, dynamic> data) async {
    final box = Hive.box<dynamic>(boxName);
    await box.put(key, data);
  }

  static Map<String, dynamic>? getItem(String boxName, String key) {
    final box = Hive.box<dynamic>(boxName);
    final raw = box.get(key);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  static List<Map<String, dynamic>> getAllItems(String boxName) {
    final box = Hive.box<dynamic>(boxName);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> deleteItem(String boxName, String key) async {
    final box = Hive.box<dynamic>(boxName);
    await box.delete(key);
  }

  // ── Queue de synchronisation offline ─────────────────────────────────────

  static Future<void> addToSyncQueue({
    required String entity,
    required String action,
    required String localId,
    required Map<String, dynamic> payload,
  }) async {
    final box = Hive.box<dynamic>(syncQueueBox);
    final key =
        '${entity}_${localId}_${DateTime.now().millisecondsSinceEpoch}';
    await box.put(key, {
      'entity': entity,
      'action': action,
      'localId': localId,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
  }

  static List<Map<String, dynamic>> getPendingSyncItems() {
    final box = Hive.box<dynamic>(syncQueueBox);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) => e['status'] == 'pending')
        .toList();
  }

  static List<String> getPendingSyncKeys() {
    final box = Hive.box<dynamic>(syncQueueBox);
    return box.keys
        .where((k) =>
            (box.get(k) as Map?)?['status'] == 'pending')
        .map((k) => k.toString())
        .toList();
  }

  static Future<void> markSyncItemProcessed(String key) async {
    final box = Hive.box<dynamic>(syncQueueBox);
    final item = box.get(key) as Map?;
    if (item != null) {
      await box.put(key, {...Map<String, dynamic>.from(item), 'status': 'synced'});
    }
  }

  static Future<void> clearSyncedItems() async {
    final box = Hive.box<dynamic>(syncQueueBox);
    final keysToDelete = box.keys
        .where((k) => (box.get(k) as Map?)?['status'] == 'synced')
        .toList();
    await box.deleteAll(keysToDelete);
  }
}
