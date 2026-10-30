
import 'package:flutter/material.dart';
import 'package:cohv/core/utils/display_formatters.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';
import 'package:cohv/core/widgets/attachments/attachments_section_widget.dart';
import 'new_training_screen.dart';

const Color trainingGreen = Color(0xFF176B57);
const Color trainingBackground = Color(0xFFF3F8F6);
const Color trainingBorder = Color(0xFFDDE7E2);
const Color trainingMuted = Color(0xFF82918C);
const Color trainingText = Color(0xFF203730);

class TrainingImpartedDetailScreen extends StatefulWidget {
final TrainingImpartedRecordModel? record;
final int? trainingImpartedId;
final String? volunteerId;

const TrainingImpartedDetailScreen({
super.key,
this.record,
this.trainingImpartedId,
this.volunteerId,
});

@override
State<TrainingImpartedDetailScreen> createState() =>
_TrainingImpartedDetailScreenState();
}

class _TrainingImpartedDetailScreenState
extends State<TrainingImpartedDetailScreen> {
final CapacityBuildingApiService _apiService =
CapacityBuildingApiService();

TrainingImpartedRecordModel? _record;
bool _isLoading = false;
String? _errorMessage;

@override
void initState() {
super.initState();

_record = widget.record;

if (_record == null && widget.trainingImpartedId != null) {
_loadDetail();
}
}

Future<void> _loadDetail() async {
setState(() {
_isLoading = true;
_errorMessage = null;
});

try {
final fetched = await _apiService.fetchTrainingImpartedDetail(
widget.trainingImpartedId!,
);

if (!mounted) return;

setState(() {
_record = fetched;
_isLoading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
_errorMessage = 'Could not load training details: $e';
_isLoading = false;
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: trainingBackground,
appBar: AuthenticatedAppBar(
title: 'Training Imparted',
backgroundColor: trainingGreen,
volunteerId: widget.volunteerId ?? '',
onBackPressed: () => Navigator.pop(context),
),
body: SafeArea(
child: _buildBody(),
),
bottomNavigationBar: _buildBottomNavigation(),
);
}

Widget _buildBody() {
if (_isLoading) {
return const Center(
child: CircularProgressIndicator(
color: trainingGreen,
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
color: trainingMuted,
fontSize: 13,
),
),
const SizedBox(height: 14),
ElevatedButton(
onPressed: _loadDetail,
style: ElevatedButton.styleFrom(
backgroundColor: trainingGreen,
foregroundColor: Colors.white,
),
child: const Text(
'Retry',
style: TextStyle(fontSize: 13),
),
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
color: trainingMuted,
fontSize: 13,
),
),
);
}

final org = record.organisedBy?.isNotEmpty == true
? record.organisedBy!
    : 'Not specified';

final dur = record.duration?.isNotEmpty == true
? record.duration!
    : 'Not specified';

final rem = record.remarks?.isNotEmpty == true
? record.remarks!
    : 'None';

return SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(26),
border: Border.all(
color: trainingBorder,
width: 1,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Training title
Text(
record.trainingName,
style: const TextStyle(
fontSize: 18,
height: 1.4,
fontWeight: FontWeight.w700,
color: trainingText,
),
),

const SizedBox(height: 10),

// Training ID
Text(
record.trainingImpartedCode,
style: const TextStyle(
fontSize: 14,
letterSpacing: 0.6,
fontWeight: FontWeight.w700,
color: trainingGreen,
),
),

const SizedBox(height: 22),

// Training details
_detailRow(
label: 'Training',
value: record.trainingName,
isFirst: true,
),

_detailRow(
label: 'Date',
value: record.displayDate,
),

_detailRow(
label: 'Organised by',
value: org,
),

_detailRow(
label: 'Duration',
value: dur,
),

_detailRow(
label: 'Remarks',
value: rem,
),

_detailRow(
label: 'Verification',
value: record.verificationStatus,
),

_detailRow(
label: 'Synchronisation',
value: 'Synced',
isLast: true,
),

const SizedBox(height: 14),

const Divider(
color: trainingBorder,
height: 1,
thickness: 1,
),

const SizedBox(height: 14),

// Attachments
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

// Bottom action buttons
Row(
  children: [
    Expanded(
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: trainingGreen,
            side: const BorderSide(
              color: trainingBorder,
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
    ),
    const SizedBox(width: 12),
    Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => NewTrainingScreen(
                  volunteerId: widget.volunteerId,
                  editRecord: record,
                ),
              ),
            );
            if (updated == true) {
              _loadDetail();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: trainingGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Edit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  ],
),
],
),
);
}

// Individual detail row
static Widget _detailRow({
required String label,
dynamic value,
bool isFirst = false,
bool isLast = false,
}) {
final displayValue = cleanDisplayValue(value);
return Container(
padding: const EdgeInsets.symmetric(vertical: 13),
decoration: BoxDecoration(
border: Border(
top: BorderSide(
color: trainingBorder,
width: isFirst ? 0 : 1,
),
bottom: isLast
? const BorderSide(
color: trainingBorder,
width: 1,
)
    : BorderSide.none,
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
fontSize: 13,
color: trainingMuted,
height: 1.45,
fontWeight: FontWeight.w400,
),
),
),

const SizedBox(width: 8),

Expanded(
flex: 6,
child: Text(
displayValue,
textAlign: TextAlign.right,
style: const TextStyle(
fontSize: 13,
height: 1.45,
color: trainingText,
fontWeight: FontWeight.w600,
),
),
),
],
),
);
}

// Bottom navigation bar
Widget _buildBottomNavigation() {
return Container(
decoration: const BoxDecoration(
color: Colors.white,
border: Border(
top: BorderSide(color: trainingBorder),
),
),
child: SafeArea(
top: false,
child: Padding(
padding: const EdgeInsets.symmetric(vertical: 10),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: const [
_BottomNavItem(
icon: Icons.home,
label: 'Dashboard',
),
_BottomNavItem(
icon: Icons.grid_view_rounded,
label: 'Actions',
),
_BottomNavItem(
icon: Icons.article,
label: 'Reports',
),
_BottomNavItem(
icon: Icons.person,
label: 'Profile',
),
],
),
),
),
);
}
}

class _BottomNavItem extends StatelessWidget {
final IconData icon;
final String label;

const _BottomNavItem({
required this.icon,
required this.label,
});

@override
Widget build(BuildContext context) {
return InkWell(
onTap: () {},
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 23,
color: trainingMuted,
),
const SizedBox(height: 5),
Text(
label,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w500,
color: trainingMuted,
),
),
],
),
);
}
}
