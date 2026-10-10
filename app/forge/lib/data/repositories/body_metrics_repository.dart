import 'package:drift/drift.dart';

import '../db/app_database.dart';

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class BodyMetricsRepository {
  BodyMetricsRepository(this._db);
  final AppDatabase _db;

  Stream<List<BodyMetric>> watchRecent({int limit = 30}) {
    return (_db.select(_db.bodyMetrics)
          ..orderBy([(m) => OrderingTerm.desc(m.measuredOn)])
          ..limit(limit))
        .watch();
  }

  Future<BodyMetric?> latest() {
    return (_db.select(_db.bodyMetrics)
          ..orderBy([(m) => OrderingTerm.desc(m.measuredOn)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// บันทึกน้ำหนัก ถ้าวันนั้นมีบันทึกอยู่แล้วจะอัปเดตค่าเดิมแทนการเพิ่มแถวซ้ำ
  Future<void> logWeight({
    required double weightKg,
    double? bodyFatPct,
    DateTime? on,
  }) async {
    final day = _dayOnly(on ?? DateTime.now());
    final existing = await (_db.select(_db.bodyMetrics)
          ..where((m) => m.measuredOn.equals(day)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.bodyMetrics).insert(
            BodyMetricsCompanion.insert(
              measuredOn: day,
              weightKg: weightKg,
              bodyFatPct: Value(bodyFatPct),
            ),
          );
    } else {
      await (_db.update(_db.bodyMetrics)..where((m) => m.id.equals(existing.id)))
          .write(
        BodyMetricsCompanion(
          weightKg: Value(weightKg),
          bodyFatPct: Value(bodyFatPct),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.bodyMetrics)..where((m) => m.id.equals(id))).go();
  }
}
