import 'package:flutter/material.dart';
import '../models/record.dart';
import '../db/database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = AppDatabase();
  final _planController = TextEditingController();
  final _positionController = TextEditingController();

  // 时间区间配置（基于用户示例）
  final List<_TimeSlot> _timeSlots = [
    _TimeSlot('0:00', '1:30'),
    _TimeSlot('1:30', '3:00'),
    _TimeSlot('3:00', '6:00'),
    _TimeSlot('6:00', '10:00'),
    _TimeSlot('10:00', '12:00'),
    _TimeSlot('12:00', '15:00'),
    _TimeSlot('15:00', '18:30'),
    _TimeSlot('18:30', '20:30'),
    _TimeSlot('20:30', '24:00'),
  ];

  // 存储每个时间段的输入
  final Map<int, TextEditingController> _oldValueControllers = {};
  final Map<int, TextEditingController> _newValueControllers = {};

  @override
  void initState() {
    super.initState();
    _planController.text = '基础率1';
    _positionController.text = '肚子位置';
  }

  @override
  void dispose() {
    _planController.dispose();
    _positionController.dispose();
    for (var c in _oldValueControllers.values) c.dispose();
    for (var c in _newValueControllers.values) c.dispose();
    super.dispose();
  }

  TextEditingController _getOldController(int index) {
    return _oldValueControllers.putIfAbsent(index, () => TextEditingController());
  }

  TextEditingController _getNewController(int index) {
    return _newValueControllers.putIfAbsent(index, () => TextEditingController());
  }

  Future<void> _saveRecord() async {
    List<RateEntry> rates = [];
    for (int i = 0; i < _timeSlots.length; i++) {
      final oldVal = double.tryParse(_getOldController(i).text);
      final newVal = double.tryParse(_getNewController(i).text);
      // 只有填写了新值才记录
      if (newVal != null || oldVal != null) {
        rates.add(RateEntry(
          startTime: _timeSlots[i].start,
          endTime: _timeSlots[i].end,
          oldValue: oldVal,
          newValue: newVal,
        ));
      }
    }

    if (rates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少填写一个时间段的数据')),
      );
      return;
    }

    final record = RateRecord(
      timestamp: DateTime.now(),
      pumpPosition: _positionController.text,
      planName: _planController.text,
      rates: rates,
    );

    await _db.insertRecord(record, rates);

    // 清空输入
    for (var c in _oldValueControllers.values) c.clear();
    for (var c in _newValueControllers.values) c.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('记录已保存！')),
    );
  }

  void _fillSampleData() {
    // 用用户示例数据填充
    final sampleData = [
      {'old': '0.4', 'new': '0.4'},
      {'old': '0.9', 'new': '0.95'},
      {'old': '0.7', 'new': '0.7'},
      {'old': '0.625', 'new': '0.625'},
      {'old': '0.2', 'new': '0.2'},
      {'old': '0.65', 'new': '0.65'},
      {'old': '0.2', 'new': '0.2'},
      {'old': '0.45', 'new': '0.45'},
      {'old': '0.35', 'new': '0.35'},
    ];
    for (int i = 0; i < sampleData.length && i < _timeSlots.length; i++) {
      _getOldController(i).text = sampleData[i]['old']!;
      _getNewController(i).text = sampleData[i]['new']!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基础率记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            tooltip: '填充示例',
            onPressed: _fillSampleData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildRateList()),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _planController,
                  decoration: const InputDecoration(
                    labelText: '方案名称',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: '泵位置',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _timeSlots.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final slot = _timeSlots[index];
        return _buildRateRow(index, slot);
      },
    );
  }

  Widget _buildRateRow(int index, _TimeSlot slot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 时间区间
          SizedBox(
            width: 80,
            child: Text(
              '${slot.start}\n${slot.end}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          // 旧值
          Expanded(
            child: TextField(
              controller: _getOldController(index),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '旧值',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 6),
          const Text('→', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          // 新值
          Expanded(
            child: TextField(
              controller: _getNewController(index),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '新值',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _saveRecord,
        icon: const Icon(Icons.save),
        label: const Text('保存记录', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _TimeSlot {
  final String start;
  final String end;
  _TimeSlot(this.start, this.end);
}
