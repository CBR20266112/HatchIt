import 'dart:convert';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../schedules/domain/schedule.dart';

@pragma('vm:entry-point')
Future<void> scheduleAlarmCallback(
  int alarmId,
  Map<String, dynamic> params,
) async {
  final title = (params['title'] as String?) ?? '수업 알림';
  final body = (params['body'] as String?) ?? '수업 시작 전 미션을 준비하세요.';

  await AlarmService.showNotification(
    alarmId: alarmId,
    title: title,
    body: body,
    payload: jsonEncode({'alarm_id': alarmId, 'kind': 'hatchit_alarm'}),
  );
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  AlarmService.handleNotificationResponse(response);
}

class AlarmService {
  static const String dismissAheadActionId = 'dismiss_ahead';
  static const String _channelId = 'hatchit_class_alarm';
  static const String _channelName = 'HatchIt Class Alarm';
  static const String _channelDescription = 'Class start relative alarms';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _notificationInitialized = false;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    if (_notificationInitialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    try {
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );

      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.createNotificationChannel(channel);

      _notificationInitialized = true;
    } on MissingPluginException {
      _notificationInitialized = false;
    }
  }

  Future<void> scheduleForSchedules(List<Schedule> schedules) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await initialize();
    if (!_notificationInitialized) {
      return;
    }

    await _clearManagedAlarms();

    final now = DateTime.now();
    for (final schedule in schedules) {
      if (schedule.id == null) {
        continue;
      }

      final alarmTime = _nextAlarmTime(schedule, now);
      if (alarmTime.isBefore(now)) {
        continue;
      }

      final alarmId = _buildAlarmId(
        schedule.id!,
        alarmTime,
        schedule.alarmOffsetMinutes,
      );
      final body =
          '${schedule.title} ${schedule.startTime} 시작 ${schedule.alarmOffsetMinutes}분 전';

      try {
        await AndroidAlarmManager.oneShotAt(
          alarmTime,
          alarmId,
          scheduleAlarmCallback,
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
          params: {'title': 'HatchIt 알람', 'body': body},
        );
      } on MissingPluginException {
        return;
      }
    }
  }

  Future<void> cancelAlarmInstance(int alarmId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await AndroidAlarmManager.cancel(alarmId);
      await _notifications.cancel(alarmId);
    } on MissingPluginException {
      return;
    }
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    if (response.actionId != dismissAheadActionId) {
      return;
    }

    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final alarmId = decoded['alarm_id'] as int?;
    if (alarmId == null) {
      return;
    }

    try {
      await AndroidAlarmManager.cancel(alarmId);
      await _notifications.cancel(alarmId);
    } on MissingPluginException {
      return;
    }
  }

  static Future<void> showNotification({
    required int alarmId,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'HatchIt Alarm',
        category: AndroidNotificationCategory.alarm,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            dismissAheadActionId,
            '미리 끄기',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
    );

    await _notifications.show(alarmId, title, body, details, payload: payload);
  }

  Future<void> _clearManagedAlarms() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final pending = await _notifications.pendingNotificationRequests();

    for (final request in pending) {
      final payload = request.payload;
      if (payload == null || !payload.contains('hatchit_alarm')) {
        continue;
      }
      await cancelAlarmInstance(request.id);
    }
  }

  DateTime _nextAlarmTime(Schedule schedule, DateTime now) {
    final startParts = schedule.startTime.split(':');
    final hour = int.parse(startParts[0]);
    final minute = int.parse(startParts[1]);

    var diff = schedule.dayOfWeek - now.weekday;
    if (diff < 0) {
      diff += 7;
    }

    var classDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: diff));

    var alarmTime = classDateTime.subtract(
      Duration(minutes: schedule.alarmOffsetMinutes),
    );

    if (alarmTime.isBefore(now)) {
      classDateTime = classDateTime.add(const Duration(days: 7));
      alarmTime = classDateTime.subtract(
        Duration(minutes: schedule.alarmOffsetMinutes),
      );
    }

    return alarmTime;
  }

  int _buildAlarmId(int scheduleId, DateTime alarmTime, int offset) {
    final key = '$scheduleId-${alarmTime.millisecondsSinceEpoch}-$offset';
    return key.hashCode & 0x7fffffff;
  }
}
