import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _notificationService = NotificationService();
  bool _reminderEnabled = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  int _reminderIntervalDays = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _notificationService.init();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderEnabled = prefs.getBool('reminder_enabled') ?? false;
      _reminderHour = prefs.getInt('reminder_hour') ?? 9;
      _reminderMinute = prefs.getInt('reminder_minute') ?? 0;
      _reminderIntervalDays = prefs.getInt('reminder_interval_days') ?? 1;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', _reminderEnabled);
    await prefs.setInt('reminder_hour', _reminderHour);
    await prefs.setInt('reminder_minute', _reminderMinute);
    await prefs.setInt('reminder_interval_days', _reminderIntervalDays);

    if (_reminderEnabled) {
      await _notificationService.setDailyReminder(_reminderHour, _reminderMinute);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提醒已设置')),
      );
    } else {
      await _notificationService.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('提醒设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('启用提醒'),
            value: _reminderEnabled,
            onChanged: (val) {
              setState(() => _reminderEnabled = val);
              _saveSettings();
            },
          ),
          if (_reminderEnabled) ...[
            ListTile(
              title: const Text('提醒时间'),
              trailing: Text('${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}'),
              onTap: _pickTime,
            ),
            ListTile(
              title: const Text('提醒间隔'),
              trailing: Text('每 $_reminderIntervalDays 天'),
              onTap: _pickInterval,
            ),
          ],
          const Divider(height: 32),
          const Text('关于', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ListTile(
            title: Text('胰岛素泵基础率记录工具'),
            subtitle: Text('版本 1.0.0\n帮助您快速记录基础率修改\n数据仅存储在本地手机上'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (time != null) {
      setState(() {
        _reminderHour = time.hour;
        _reminderMinute = time.minute;
      });
      _saveSettings();
    }
  }

  Future<void> _pickInterval() async {
    final controller = TextEditingController(text: '$_reminderIntervalDays');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置提醒间隔'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '天数（1-30）'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 1 && val <= 30) {
                Navigator.pop(context, val);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _reminderIntervalDays = result);
      _saveSettings();
    }
  }
}
