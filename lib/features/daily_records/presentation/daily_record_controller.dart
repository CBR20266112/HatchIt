import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/daily_record_dao.dart';
import '../domain/daily_record.dart';

final dailyRecordDaoProvider = Provider<DailyRecordDao>((ref) {
  return DailyRecordDao(ref.watch(appDatabaseProvider));
});

final dailyRecordControllerProvider = Provider<DailyRecordController>((ref) {
  return DailyRecordController(ref.watch(dailyRecordDaoProvider));
});

class DailyRecordController {
  DailyRecordController(this._dao);

  final DailyRecordDao _dao;

  Future<DailyRecord?> getByDateAndSlot({
    required String recordDate,
    required DailySlotType slotType,
  }) {
    return _dao.getByDateAndSlot(recordDate: recordDate, slotType: slotType);
  }

  Future<void> addRecord(DailyRecord record) async {
    await _dao.create(record);
  }
}
