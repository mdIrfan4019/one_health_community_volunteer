// lib/features/reports/domain/report_models.dart

class ReportTypeModel {
  final String value;
  final String label;

  const ReportTypeModel({
    required this.value,
    required this.label,
  });

  factory ReportTypeModel.fromJson(Map<String, dynamic> json) {
    return ReportTypeModel(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
      };

  /// Fallback list matching the backend endpoint response
  static const List<ReportTypeModel> fallbackReportTypes = [
    ReportTypeModel(value: 'event', label: 'Event Report'),
    ReportTypeModel(value: 'referral', label: 'Referral'),
    ReportTypeModel(value: 'awareness', label: 'Awareness Activity'),
    ReportTypeModel(value: 'sample', label: 'Sample Support'),
    ReportTypeModel(
      value: 'training_imparted',
      label: 'Capacity Building - Training Imparted',
    ),
    ReportTypeModel(
      value: 'training_attended',
      label: 'Capacity Building - Training Attended',
    ),
    ReportTypeModel(value: 'success_story', label: 'Success Story'),
    ReportTypeModel(value: 'monthly_summary', label: 'Monthly Summary'),
  ];
}

class ReportRequest {
  final DateTime fromDate;
  final DateTime toDate;
  final String email;
  final String reportType;

  ReportRequest({
    required this.fromDate,
    required this.toDate,
    required this.email,
    required this.reportType,
  });

  static String _formatYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, dynamic> toJson() => {
        'report_type': reportType,
        'from_date': _formatYmd(fromDate),
        'to_date': _formatYmd(toDate),
        'email': email,
      };
}

class ReportItem {
  final String reportId; // e.g. RPT-26-0006
  final int? reportRequestId;
  final DateTime fromDate;
  final DateTime toDate;
  final String email;
  final String status; // 'SENT', 'sent', 'pending'
  final String? reportType;
  final String? reportTypeLabel;
  final DateTime? createdAt;
  final String? message;

  ReportItem({
    required this.reportId,
    this.reportRequestId,
    required this.fromDate,
    required this.toDate,
    required this.email,
    required this.status,
    this.reportType,
    this.reportTypeLabel,
    this.createdAt,
    this.message,
  });

  String get displayTypeLabel {
    if (reportTypeLabel != null && reportTypeLabel!.trim().isNotEmpty) {
      return reportTypeLabel!.trim();
    }
    if (reportType != null && reportType!.trim().isNotEmpty) {
      final match = ReportTypeModel.fallbackReportTypes.firstWhere(
        (t) => t.value.toLowerCase() == reportType!.trim().toLowerCase(),
        orElse: () => ReportTypeModel(value: reportType!, label: reportType!),
      );
      return match.label;
    }
    return '';
  }

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    final rawData = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final id = rawData['report_code']?.toString() ??
        rawData['report_id']?.toString() ??
        rawData['id']?.toString() ??
        'RPT-26-0001';

    final reqId = rawData['report_request_id'] is int
        ? rawData['report_request_id'] as int
        : int.tryParse(rawData['report_request_id']?.toString() ?? '');

    final type = rawData['report_type']?.toString();
    final typeLabel = rawData['report_type_name']?.toString() ??
        rawData['report_type_label']?.toString();

    return ReportItem(
      reportId: id,
      reportRequestId: reqId,
      fromDate: DateTime.tryParse(rawData['from_date']?.toString() ?? '') ??
          DateTime.now(),
      toDate: DateTime.tryParse(rawData['to_date']?.toString() ?? '') ??
          DateTime.now(),
      email: rawData['email']?.toString() ?? '',
      status: rawData['status']?.toString() ?? 'SENT',
      reportType: type,
      reportTypeLabel: typeLabel,
      createdAt: DateTime.tryParse(rawData['created_at']?.toString() ?? ''),
      message: rawData['message']?.toString() ?? json['message']?.toString(),
    );
  }
}
