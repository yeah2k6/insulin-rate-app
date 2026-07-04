class RateEntry {
  final String startTime; // e.g. "0:00"
  final String endTime;   // e.g. "1:30"
  final double? oldValue;
  final double? newValue;

  RateEntry({
    required this.startTime,
    required this.endTime,
    this.oldValue,
    this.newValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'oldValue': oldValue,
      'newValue': newValue,
    };
  }

  factory RateEntry.fromMap(Map<String, dynamic> map) {
    return RateEntry(
      startTime: map['startTime'],
      endTime: map['endTime'],
      oldValue: map['oldValue'],
      newValue: map['newValue'],
    );
  }
}

class RateRecord {
  final int? id;
  final DateTime timestamp;
  final String pumpPosition;
  final String planName;
  final List<RateEntry> rates;

  RateRecord({
    this.id,
    required this.timestamp,
    required this.pumpPosition,
    required this.planName,
    required this.rates,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'pumpPosition': pumpPosition,
      'planName': planName,
    };
  }

  factory RateRecord.fromMap(Map<String, dynamic> map) {
    return RateRecord(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      pumpPosition: map['pumpPosition'],
      planName: map['planName'],
      rates: [],
    );
  }
}
