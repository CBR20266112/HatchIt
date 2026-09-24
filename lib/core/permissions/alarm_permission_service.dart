import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmPermissionService {
  Future<void> ensureAlarmPermissions(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await _requestNotificationPermission(context);
    if (!context.mounted) {
      return;
    }

    await _requestExactAlarmPermission(context);
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        return;
      }

      if (!context.mounted) {
        return;
      }

      final shouldRequest = await _showGuideDialog(
        context,
        title: '알림 권한이 필요해요',
        message: '수업 시작 전 미션 알람을 정확히 받으려면 알림 권한을 허용해주세요.',
      );

      if (!shouldRequest || !context.mounted) {
        return;
      }

      final result = await Permission.notification.request();
      if (result.isPermanentlyDenied && context.mounted) {
        await _showOpenSettingsDialog(context);
      }
    } on MissingPluginException {
      return;
    }
  }

  Future<void> _requestExactAlarmPermission(BuildContext context) async {
    try {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isGranted) {
        return;
      }

      if (!context.mounted) {
        return;
      }

      final shouldRequest = await _showGuideDialog(
        context,
        title: '정확한 알람 권한이 필요해요',
        message: '30/60/90/120분 전 알람은 정확한 알람 권한이 있어야 제시간에 울려요.',
      );

      if (!shouldRequest || !context.mounted) {
        return;
      }

      final result = await Permission.scheduleExactAlarm.request();
      if (result.isPermanentlyDenied && context.mounted) {
        await _showOpenSettingsDialog(context);
      }
    } on MissingPluginException {
      return;
    }
  }

  Future<bool> _showGuideDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('나중에'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('권한 요청'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _showOpenSettingsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('설정에서 권한을 켜주세요'),
          content: const Text('이미 거절된 권한은 시스템 설정에서 직접 허용해야 합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('설정 열기'),
            ),
          ],
        );
      },
    );
  }
}
