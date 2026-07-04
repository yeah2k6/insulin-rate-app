import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../db/database.dart';
import '../utils/export.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = AppDatabase();
  List<RateRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _db.getAllRecords();
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  String _formatTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(
                  child: Text('暂无记录\n点击首页"保存记录"开始', textAlign: TextAlign.center),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _records.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return _buildRecordCard(record);
                  },
                ),
    );
  }

  Widget _buildRecordCard(RateRecord record) {
    return Card(
      child: InkWell(
        onTap: () async {
          final fullRecord = await _db.getRecordWithRates(record.id!);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecordDetailScreen(record: fullRecord!),
            ),
          ).then((_) => _loadRecords());
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(record.planName),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(record.pumpPosition),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(record.timestamp),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => _deleteRecord(record.id!),
                    child: const Text('删除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRecord(int id) async {
    await _db.deleteRecord(id);
    _loadRecords();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除')),
    );
  }
}

class RecordDetailScreen extends StatelessWidget {
  final RateRecord record;
  const RecordDetailScreen({Key? key, required this.record}) : super(key: key);

  String _formatTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final rates = record.rates;
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享文本',
            onPressed: () => ExportUtil.shareText(record),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: '导出PDF',
            onPressed: () => ExportUtil.sharePdf(context, record),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('时间', _formatTime(record.timestamp)),
            _buildInfoRow('方案', record.planName),
            _buildInfoRow('泵位置', record.pumpPosition),
            const SizedBox(height: 16),
            const Text('基础率设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: rates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rate = rates[index];
                  final changed = rate.oldValue != rate.newValue;
                  return ListTile(
                    dense: true,
                    leading: Text('${rate.startTime}–${rate.endTime}', style: const TextStyle(fontSize: 13)),
                    title: changed
                        ? Text('${rate.oldValue} → ${rate.newValue}',
                            style: const TextStyle(fontWeight: FontWeight.bold))
                        : Text('${rate.newValue ?? rate.oldValue}',
                            style: const TextStyle(color: Colors.grey)),
                    trailing: changed ? const Icon(Icons.edit, size: 16, color: Colors.orange) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label：', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
