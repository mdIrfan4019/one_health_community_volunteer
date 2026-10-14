// Create file: lib/features/reports/domain/report_models.dart

class ReportRequest {
  final DateTime fromDate;
  final DateTime toDate;
  final String email;

  ReportRequest({
    required this.fromDate,
    required this.toDate,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'from_date': fromDate.toIso8601String(),
    'to_date': toDate.toIso8601String(),
    'email': email,
  };
}

class ReportItem {
  final String reportId; // e.g. RPT-26-0004
  final DateTime fromDate;
  final DateTime toDate;
  final String email;
  final String status; // 'sent', 'pending', 'generating'

  ReportItem({
    required this.reportId,
    required this.fromDate,
    required this.toDate,
    required this.email,
    required this.status,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      reportId: json['report_id'] ?? 'RPT-26-0001',
      fromDate: DateTime.parse(json['from_date']),
      toDate: DateTime.parse(json['to_date']),
      email: json['email'] ?? '',
      status: json['status'] ?? 'sent',
    );
  }
}
