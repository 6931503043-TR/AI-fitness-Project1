import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/app_database.dart';

/// โปรไฟล์ผู้ใช้มีแถวเดียวเสมอ ใช้ id คงที่แทนการสร้างใหม่ทุกครั้ง
const _profileId = 'profile';

class ProfileRepository {
  ProfileRepository(this._db);
  final AppDatabase _db;

  Stream<UserProfile?> watch() {
    return (_db.select(_db.userProfiles)
          ..where((p) => p.id.equals(_profileId)))
        .watchSingleOrNull();
  }

  Future<UserProfile?> get() {
    return (_db.select(_db.userProfiles)
          ..where((p) => p.id.equals(_profileId)))
        .getSingleOrNull();
  }

  Future<void> save({
    required Gender gender,
    required int birthYear,
    required double heightCm,
    required ActivityLevel activityLevel,
  }) {
    return _db.into(_db.userProfiles).insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: const Value(_profileId),
            gender: gender,
            birthYear: birthYear,
            heightCm: heightCm,
            activityLevel: activityLevel,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}
