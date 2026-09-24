import 'package:flutter/material.dart';

import '../../domain/schedule.dart';

class ScheduleFormDialog extends StatefulWidget {
  const ScheduleFormDialog({
    super.key,
    this.initial,
  });

  final Schedule? initial;

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;

  late ScheduleType _type;
  late int _dayOfWeek;
  late int _offset;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _locationController = TextEditingController(text: initial?.location ?? '');
    _startController = TextEditingController(text: initial?.startTime ?? '09:00');
    _endController = TextEditingController(text: initial?.endTime ?? '10:00');
    _type = initial?.type ?? ScheduleType.classType;
    _dayOfWeek = initial?.dayOfWeek ?? DateTime.now().weekday;
    _offset = initial?.alarmOffsetMinutes ?? 30;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '시간표 일정 추가' : '시간표 일정 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ScheduleType>(
              initialValue: _type,
              items: const [
                DropdownMenuItem(value: ScheduleType.classType, child: Text('CLASS')),
                DropdownMenuItem(value: ScheduleType.event, child: Text('EVENT')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _type = value;
                });
              },
              decoration: const InputDecoration(labelText: '유형'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _dayOfWeek,
              items: const [
                DropdownMenuItem(value: 1, child: Text('월')),
                DropdownMenuItem(value: 2, child: Text('화')),
                DropdownMenuItem(value: 3, child: Text('수')),
                DropdownMenuItem(value: 4, child: Text('목')),
                DropdownMenuItem(value: 5, child: Text('금')),
                DropdownMenuItem(value: 6, child: Text('토')),
                DropdownMenuItem(value: 7, child: Text('일')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _dayOfWeek = value;
                });
              },
              decoration: const InputDecoration(labelText: '요일'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _startController,
              decoration: const InputDecoration(labelText: '시작 시간 (HH:mm)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endController,
              decoration: const InputDecoration(labelText: '종료 시간 (HH:mm)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: '장소'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _offset,
              items: const [
                DropdownMenuItem(value: 30, child: Text('30분 전')),
                DropdownMenuItem(value: 60, child: Text('60분 전')),
                DropdownMenuItem(value: 90, child: Text('90분 전')),
                DropdownMenuItem(value: 120, child: Text('120분 전')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _offset = value;
                });
              },
              decoration: const InputDecoration(labelText: '알람 오프셋'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('저장'),
        ),
      ],
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final start = _startController.text.trim();
    final end = _endController.text.trim();

    final timeRegex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    if (title.isEmpty || !timeRegex.hasMatch(start) || !timeRegex.hasMatch(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 시간 형식을 확인해주세요. (HH:mm)')),
      );
      return;
    }

    Navigator.of(context).pop(
      Schedule(
        id: widget.initial?.id,
        title: title,
        type: _type,
        dayOfWeek: _dayOfWeek,
        startTime: start,
        endTime: end,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        isCompleted: widget.initial?.isCompleted ?? false,
        alarmOffsetMinutes: _offset,
      ),
    );
  }
}
