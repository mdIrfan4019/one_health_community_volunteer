
import 'package:flutter/material.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';
import 'package:cohv/core/widgets/attachments/attachments_section_widget.dart';

const Color attendedGreen = Color(0xFF176B57);
const Color attendedBackground = Color(0xFFF2F7F5);
const Color attendedBorder = Color(0xFFDCE6E2);
const Color attendedMuted = Color(0xFF81918B);
const Color attendedText = Color(0xFF20372F);

class TrainingAttendedDetailScreen extends StatefulWidget {
final TrainingAttendedRecordModel? record;
final int? trainingAttendedId;
final String? volunteerId;

const TrainingAttendedDetailScreen({
super.key,
this.record,
this.trainingAttendedId,
this.volunteerId,
});

@override
State<TrainingAttendedDetailScreen> createState() =>
_TrainingAttendedDetailScreenState();
}

class _TrainingAttendedDetailScreenState
extends State<TrainingAttendedDetailScreen> {
final CapacityBuildingApiService _apiService =
CapacityBuildingApiService();

TrainingAttendedRecordModel? _record;
bool _isLoading = false;
String? _errorMessage;

@override
void initState() {
super.initState();

_record = widget.record;

if (_record == null && widget.trainingAttendedId != null) {
_loadDetail();
}
}

Future<void> _loadDetail() async {
setState(() {
_isLoading = true;
_errorMessage = null;
});

try {
final fetched = await _apiService.fetchTrainingAttendedDetail(
widget.trainingAttendedId!,
);

if (!mounted) return;

setState(() {
_record = fetched;
_isLoading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
_errorMessage = 'Could not load details: $e';
_isLoading = false;
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: attendedBackground,
appBar: AuthenticatedAppBar(
title: 'Training Attended',
backgroundColor: attendedGreen,
volunteerId: widget.volunteerId ?? '',
onBackPressed: () => Navigator.pop(context),
),
body: SafeArea(
child: _buildBody(),
),
);
}

Widget _buildBody() {
if (_isLoading) {
return const Center(
child: CircularProgressIndicator(
color: attendedGreen,
),
);
}

if (_errorMessage != null && _record == null) {
return Center(
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
size: 40,
color: Colors.red,
),
const SizedBox(height: 10),
Text(
_errorMessage!,
textAlign: TextAlign.center,
style: const TextStyle(
color: attendedMuted,
fontSize: 13,
),
),
const SizedBox(height: 14),
ElevatedButton(
onPressed: _loadDetail,
style: ElevatedButton.styleFrom(
backgroundColor: attendedGreen,
foregroundColor: Colors.white,
textStyle: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
),
),
child: const Text('Retry'),
),
],
),
),
);
}

final record = _record;

if (record == null) {
return const Center(
child: Text(
'No record found.',
style: TextStyle(
color: attendedMuted,
fontSize: 13,
),
),
);
}

final venue = record.venue?.isNotEmpty == true
? record.venue!
    : '—';

final chaired = record.chairedBy?.isNotEmpty == true
? record.chairedBy!
    : '—';

final points = record.keyPoints?.isNotEmpty == true
? record.keyPoints!
    : '—';

return SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
child: Column(
children: [
Container(
width: double.infinity,
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(22),
border: Border.all(
color: attendedBorder,
width: 1,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
record.trainingName,
style: const TextStyle(
fontSize: 18,
height: 1.35,
fontWeight: FontWeight.w700,
color: attendedText,
),
),

const SizedBox(height: 8),

Text(
record.trainingAttendedCode,
style: const TextStyle(
color: attendedGreen,
fontSize: 14,
letterSpacing: 0.6,
fontWeight: FontWeight.w700,
),
),

const SizedBox(height: 20),

_detailRow(
'Training',
record.trainingName,
),

_detailRow(
'Date',
record.displayDate,
),

_detailRow(
'Venue',
venue,
),

_detailRow(
'Chaired by',
chaired,
),

_detailRow(
'Key points / action agreed',
points,
),

_detailRow(
'Certificate issued',
record.certificateIssued ? 'Yes' : 'No',
),

_detailRow(
'Verification',
record.verificationStatus,
),

_detailRow(
'Synchronisation',
'Synced',
isLast: true,
),

const SizedBox(height: 14),

const Divider(
color: attendedBorder,
height: 1,
thickness: 1,
),

const SizedBox(height: 14),

AttachmentsSectionWidget(
attachments: record.appAttachments,
fallbackLatitude: record.latitude,
fallbackLongitude: record.longitude,
fallbackAccuracy: record.gpsAccuracyM,
fallbackDate: DateTime.tryParse(
record.capturedAt ?? record.trainingDate,
),
),
],
),
),

const SizedBox(height: 18),

SizedBox(
width: double.infinity,
height: 46,
child: OutlinedButton(
onPressed: () => Navigator.pop(context),
style: OutlinedButton.styleFrom(
foregroundColor: attendedGreen,
backgroundColor: Colors.white,
side: const BorderSide(
color: attendedBorder,
width: 1,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: const Text(
'Back',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w600,
),
),
),
),
],
),
);
}

Widget _detailRow(
String label,
String value, {
bool isLast = false,
}) {
return Container(
padding: const EdgeInsets.symmetric(vertical: 12),
decoration: BoxDecoration(
border: Border(
bottom: isLast
? BorderSide.none
    : const BorderSide(
color: attendedBorder,
width: 1,
),
),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
flex: 4,
child: Text(
label,
style: const TextStyle(
color: attendedMuted,
fontSize: 13,
height: 1.4,
fontWeight: FontWeight.w400,
),
),
),

const SizedBox(width: 10),

Expanded(
flex: 6,
child: Text(
value,
textAlign: TextAlign.right,
softWrap: true,
style: const TextStyle(
fontWeight: FontWeight.w600,
fontSize: 13,
height: 1.4,
color: attendedText,
),
),
),
],
),
);
}
}
