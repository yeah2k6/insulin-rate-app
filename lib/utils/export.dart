import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';

class ExportUtil {
  // 生成记录文本
  static String generateText(RateRecord record) {
    final buffer = StringBuffer();
    buffer.write('时间：${DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp)}\n');
    buffer.write('方案：${record.planName}\n');
    buffer.write('泵位置：${record.pumpPosition}\n');
    buffer.write('${'=' * 30}\n');
    for (var rate in record.rates) {
      final oldStr = rate.oldValue?.toString() ?? '-';
      final newStr = rate.newValue?.toString() ?? '-';
      if (rate.oldValue != rate.newValue && rate.oldValue != null) {
        buffer.write('${rate.startTime}–${rate.endTime}  $oldStr 调整为 $newStr\n');
      } else {
        buffer.write('${rate.startTime}–${rate.endTime}  $newStr\n');
      }
    }
    return buffer.toString();
  }

  // 生成 PDF 并分享（简化版，无中文字体）
  static Future<void> sharePdf(BuildContext context, RateRecord record) async {
    final bytes = await _generatePdfBytes(record);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'insulin_record_${record.id}.pdf',
    );
  }

  // 分享文本
  static Future<void> shareText(RateRecord record) async {
    final text = generateText(record);
    await Share.share(text, subject: '胰岛素泵基础率记录');
  }

  // 生成 PDF 字节（纯英文/数字，避免中文乱码）
  static Future<List<int>> _generatePdfBytes(RateRecord record) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Insulin Pump Basal Rate Record',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text('Time: ${DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp)}'),
              pw.Text('Plan: ${record.planName}'),
              pw.Text('Pump Position: ${record.pumpPosition}'),
              pw.Divider(),
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('Time Range', pw.Font.helveticaBold(), 11),
                      _cell('Old Value', pw.Font.helveticaBold(), 11),
                      _cell('New Value', pw.Font.helveticaBold(), 11),
                      _cell('Status', pw.Font.helveticaBold(), 11),
                    ],
                  ),
                  ...record.rates.map((rate) {
                    final changed = rate.oldValue != rate.newValue;
                    return pw.TableRow(
                      children: [
                        _cell('${rate.startTime}-${rate.endTime}', pw.Font.helvetica(), 10),
                        _cell(rate.oldValue?.toString() ?? '-', pw.Font.helvetica(), 10),
                        _cell(rate.newValue?.toString() ?? '-', pw.Font.helvetica(), 10),
                        _cell(changed ? 'CHANGED' : 'NO CHANGE', pw.Font.helvetica(), 10),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Note: Values in U/hr. Check with your doctor for adjustments.',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  static pw.Widget _cell(String text, pw.Font font, double size) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: size)),
    );
  }
}
